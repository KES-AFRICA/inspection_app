// lib/features/backup/data/datasources/microsoft_graph_storage_service.dart
// ============================================================
// SERVICE DE STOCKAGE CLOUD MICROSOFT GRAPH
// Support Resumable Upload (Chunks de 3.2 Mo) & Gestion OneDrive
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/models/cloud_backup_manifest.dart';

typedef OnProgressCallback = void Function(double progress, String statusMessage);

class MicrosoftGraphStorageService {
  static const String _graphBaseUrl = 'https://graph.microsoft.com/v1.0';
  static const int _chunkSize = 3276800; // 3.2 Mo (multiple de 320 Ko requis par Microsoft Graph)

  final http.Client _client;

  MicrosoftGraphStorageService({http.Client? client})
      : _client = client ?? http.Client();

  // ─────────────────────────────────────────────────────────────
  // 1. CRÉATION OU VÉRIFICATION D'UN DOSSIER SUR ONEDRIVE
  // ─────────────────────────────────────────────────────────────

  Future<String?> ensureFolderExists(String accessToken, String folderPath) async {
    try {
      final encodedPath = Uri.encodeComponent(folderPath);
      final checkUrl = Uri.parse('$_graphBaseUrl/me/drive/root:/$encodedPath');

      final checkResp = await _client.get(
        checkUrl,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (checkResp.statusCode == 200) {
        final data = json.decode(checkResp.body);
        return data['id'] as String?;
      }

      // Si le dossier n'existe pas, le créer récursivement
      final createUrl = Uri.parse('$_graphBaseUrl/me/drive/root/children');
      final createResp = await _client.post(
        createUrl,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': folderPath,
          'folder': {},
          '@microsoft.graph.conflictBehavior': 'open',
        }),
      );

      if (createResp.statusCode == 201 || createResp.statusCode == 200) {
        final data = json.decode(createResp.body);
        return data['id'] as String?;
      }
    } catch (_) {}
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // 2. TÉLÉVERSEMENT RÉSILIENT PAR CHUNKS (Resumable Upload)
  // ─────────────────────────────────────────────────────────────

  Future<bool> uploadBackupFileChunked({
    required String accessToken,
    required File file,
    required String remoteFolderPath,
    required String remoteFileName,
    OnProgressCallback? onProgress,
  }) async {
    try {
      final fileSize = await file.length();
      final encodedPath = Uri.encodeComponent('$remoteFolderPath/$remoteFileName');
      
      onProgress?.call(0.05, 'Initialisation du canal sécurisé Microsoft...');

      // A. Créer la session d'upload Microsoft Graph
      final sessionUrl = Uri.parse(
        '$_graphBaseUrl/me/drive/root:/$encodedPath:/createUploadSession',
      );

      final sessionResp = await _client.post(
        sessionUrl,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'item': {
            '@microsoft.graph.conflictBehavior': 'replace',
            'name': remoteFileName,
          }
        }),
      );

      if (sessionResp.statusCode != 200) {
        return false;
      }

      final sessionData = json.decode(sessionResp.body);
      final uploadUrlStr = sessionData['uploadUrl'] as String?;
      if (uploadUrlStr == null) return false;

      final uploadUrl = Uri.parse(uploadUrlStr);

      // B. Envoi du fichier par tranches (Chunks)
      final randomAccess = await file.open(mode: FileMode.read);
      int bytesUploaded = 0;

      while (bytesUploaded < fileSize) {
        final int currentChunkSize =
            (fileSize - bytesUploaded < _chunkSize)
                ? (fileSize - bytesUploaded)
                : _chunkSize;

        final chunkData = await randomAccess.read(currentChunkSize);
        final startByte = bytesUploaded;
        final endByte = bytesUploaded + currentChunkSize - 1;

        final chunkResp = await _client.put(
          uploadUrl,
          headers: {
            'Content-Length': '$currentChunkSize',
            'Content-Range': 'bytes $startByte-$endByte/$fileSize',
          },
          body: chunkData,
        );

        bytesUploaded += currentChunkSize;
        final progress = (bytesUploaded / fileSize).clamp(0.0, 1.0);
        
        final mbUploaded = (bytesUploaded / (1024 * 1024)).toStringAsFixed(1);
        final mbTotal = (fileSize / (1024 * 1024)).toStringAsFixed(1);
        
        onProgress?.call(
          progress,
          'Téléversement Cloud: $mbUploaded Mo / $mbTotal Mo (${(progress * 100).toInt()}%)',
        );

        if (chunkResp.statusCode != 202 &&
            chunkResp.statusCode != 201 &&
            chunkResp.statusCode != 200) {
          await randomAccess.close();
          return false;
        }
      }

      await randomAccess.close();
      onProgress?.call(1.0, 'Sauvegarde Cloud finalisée avec succès !');
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3. ÉCRITURE DU MANIFEST.JSON DE SYNC SUR LE CLOUD
  // ─────────────────────────────────────────────────────────────

  Future<bool> uploadManifest({
    required String accessToken,
    required CloudBackupManifest manifest,
    required String remoteFolderPath,
  }) async {
    try {
      final jsonStr = json.encode(manifest.toJson());
      final jsonBytes = utf8.encode(jsonStr);
      final encodedPath = Uri.encodeComponent('$remoteFolderPath/manifest.json');

      final url = Uri.parse('$_graphBaseUrl/me/drive/root:/$encodedPath:/content');
      final resp = await _client.put(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonBytes,
      );

      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 4. RÉCUPÉRATION DU MANIFEST DISTANT
  // ─────────────────────────────────────────────────────────────

  Future<CloudBackupManifest?> fetchRemoteManifest({
    required String accessToken,
    required String remoteFolderPath,
  }) async {
    try {
      final encodedPath = Uri.encodeComponent('$remoteFolderPath/manifest.json');
      final url = Uri.parse('$_graphBaseUrl/me/drive/root:/$encodedPath:/content');

      final resp = await _client.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        return CloudBackupManifest.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // 5. TÉLÉCHARGEMENT D'UNE SAUVEGARDE DISTANTE (.inspec)
  // ─────────────────────────────────────────────────────────────

  Future<File?> downloadBackupFile({
    required String accessToken,
    required String remoteFolderPath,
    required String remoteFileName,
    required File targetFile,
    OnProgressCallback? onProgress,
  }) async {
    try {
      final encodedPath = Uri.encodeComponent('$remoteFolderPath/$remoteFileName');
      final url = Uri.parse('$_graphBaseUrl/me/drive/root:/$encodedPath:/content');

      onProgress?.call(0.1, 'Connexion au serveur Microsoft...');

      final request = http.Request('GET', url);
      request.headers['Authorization'] = 'Bearer $accessToken';

      final response = await _client.send(request);

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        int downloadedBytes = 0;

        final sink = targetFile.openWrite();

        await response.stream.forEach((chunk) {
          sink.add(chunk);
          downloadedBytes += chunk.length;
          if (contentLength > 0) {
            final progress = (downloadedBytes / contentLength).clamp(0.0, 1.0);
            final mbDown = (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
            final mbTotal = (contentLength / (1024 * 1024)).toStringAsFixed(1);
            onProgress?.call(
              progress,
              'Téléchargement: $mbDown Mo / $mbTotal Mo (${(progress * 100).toInt()}%)',
            );
          }
        });

        await sink.flush();
        await sink.close();

        onProgress?.call(1.0, 'Téléchargement terminé.');
        return targetFile;
      }
    } catch (_) {}
    return null;
  }
}
