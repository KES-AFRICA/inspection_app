// lib/features/backup/data/datasources/microsoft_graph_storage_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/backup_cancel_token.dart';
import '../../domain/models/cloud_backup_manifest.dart';

typedef OnProgressCallback = void Function(double progress, String statusMessage);
typedef OnProgressBytesCallback = void Function(int uploadedBytes, int totalBytes, String statusMessage);

class UploadSessionInfo {
  final String uploadUrl;
  final DateTime? expirationDateTime;
  final int nextExpectedByte;

  UploadSessionInfo({
    required this.uploadUrl,
    this.expirationDateTime,
    required this.nextExpectedByte,
  });
}

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
  // 2. GESTION DES SESSIONS D'UPLOAD MICROSOFT GRAPH (CREATE/GET/DELETE)
  // ─────────────────────────────────────────────────────────────

  /// Créer une nouvelle session d'upload resumable Microsoft Graph
  Future<UploadSessionInfo?> createUploadSession({
    required String accessToken,
    required String remoteFolderPath,
    required String remoteFileName,
  }) async {
    try {
      final encodedPath = Uri.encodeComponent('$remoteFolderPath/$remoteFileName');
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

      if (sessionResp.statusCode == 200) {
        final sessionData = json.decode(sessionResp.body);
        final uploadUrlStr = sessionData['uploadUrl'] as String?;
        if (uploadUrlStr != null) {
          final expStr = sessionData['expirationDateTime'] as String?;
          final expDate = expStr != null ? DateTime.tryParse(expStr) : null;
          return UploadSessionInfo(
            uploadUrl: uploadUrlStr,
            expirationDateTime: expDate,
            nextExpectedByte: 0,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur createUploadSession: $e');
    }
    return null;
  }

  /// Interroger l'état d'une session d'upload distante (GET uploadUrl)
  /// Détermine nextExpectedRanges pour reprendre l'upload sans doublon
  Future<UploadSessionInfo?> getUploadSessionState(String uploadUrl) async {
    try {
      final resp = await _client.get(Uri.parse(uploadUrl));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final ranges = data['nextExpectedRanges'] as List<dynamic>?;
        int nextByte = 0;
        if (ranges != null && ranges.isNotEmpty) {
          final rangeStr = ranges.first.toString(); // ex: "10485760-"
          final parts = rangeStr.split('-');
          nextByte = int.tryParse(parts[0]) ?? 0;
        }

        final expStr = data['expirationDateTime'] as String?;
        final expDate = expStr != null ? DateTime.tryParse(expStr) : null;

        return UploadSessionInfo(
          uploadUrl: uploadUrl,
          expirationDateTime: expDate,
          nextExpectedByte: nextByte,
        );
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Impossible d\'interroger uploadSessionState: $e');
    }
    return null;
  }

  /// Annuler réellement une session d'upload côté serveur Microsoft Graph (DELETE uploadUrl)
  Future<bool> cancelUploadSession(String uploadUrl) async {
    try {
      if (kDebugMode) print('🗑️ Annulation serveur de la session Microsoft Graph: $uploadUrl');
      final resp = await _client.delete(Uri.parse(uploadUrl));
      return resp.statusCode == 204 || resp.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('⚠️ Erreur cancelUploadSession: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3. TÉLÉVERSEMENT RÉSILIENT PAR CHUNKS (Résumable, Annulable, Reprenable)
  // ─────────────────────────────────────────────────────────────

  Future<bool> uploadBackupFileChunkedResumable({
    required String accessToken,
    required File file,
    required String remoteFolderPath,
    required String remoteFileName,
    required String uploadUrl,
    int startFromByte = 0,
    BackupCancelToken? cancelToken,
    Future<String?> Function()? onTokenExpired,
    OnProgressBytesCallback? onProgressBytes,
    void Function(String uploadUrl, DateTime? expiration)? onSessionCreated,
  }) async {
    RandomAccessFile? randomAccess;

    try {
      final fileSize = await file.length();
      if (fileSize == 0) return false;

      cancelToken?.throwIfCancelled();

      int bytesUploaded = startFromByte;
      randomAccess = await file.open(mode: FileMode.read);
      if (bytesUploaded > 0) {
        await randomAccess.setPosition(bytesUploaded);
      }

      while (bytesUploaded < fileSize) {
        cancelToken?.throwIfCancelled();

        final int currentChunkSize = (fileSize - bytesUploaded < _chunkSize)
            ? (fileSize - bytesUploaded)
            : _chunkSize;

        final chunkData = await randomAccess.read(currentChunkSize);
        final startByte = bytesUploaded;
        final endByte = bytesUploaded + currentChunkSize - 1;

        http.Response? chunkResp;
        bool chunkSuccess = false;

        // Boucle de retry avec backoff exponentiel pour 5xx / 429
        for (int attempt = 0; attempt < 5; attempt++) {
          cancelToken?.throwIfCancelled();

          try {
            chunkResp = await _client.put(
              Uri.parse(uploadUrl),
              headers: {
                'Content-Length': '$currentChunkSize',
                'Content-Range': 'bytes $startByte-$endByte/$fileSize',
              },
              body: chunkData,
            );

            // Gestion 401 Unauthorized (Jeton expiré)
            if (chunkResp.statusCode == 401 && onTokenExpired != null) {
              if (kDebugMode) print('🔑 Jeton OAuth expiré pendant l\'upload. Rafraîchissement...');
              final newToken = await onTokenExpired();
              if (newToken != null) {
                continue;
              }
            }

            // En cas d'erreur serveur 5xx ou 429
            if (chunkResp.statusCode >= 500 || chunkResp.statusCode == 429) {
              final delayMs = pow(2, attempt).toInt() * 1000 + Random().nextInt(500);
              if (kDebugMode) {
                print('⚠️ Serveur Microsoft occupé (${chunkResp.statusCode}). Récompte dans ${delayMs}ms (Tentative ${attempt + 1}/5)');
              }
              await Future.delayed(Duration(milliseconds: delayMs));
              continue;
            }

            // Validation de la réponse HTTP de fragment (200, 201 ou 202 Accepted)
            if (chunkResp.statusCode == 200 || chunkResp.statusCode == 201 || chunkResp.statusCode == 202) {
              chunkSuccess = true;
              break;
            } else {
              if (kDebugMode) print('❌ Code HTTP upload non attendu: ${chunkResp.statusCode} body: ${chunkResp.body}');
              break;
            }
          } catch (e) {
            cancelToken?.throwIfCancelled();
            final delayMs = pow(2, attempt).toInt() * 1000;
            await Future.delayed(Duration(milliseconds: delayMs));
          }
        }

        if (!chunkSuccess) {
          await randomAccess.close();
          return false;
        }

        bytesUploaded += currentChunkSize;
        final progress = (bytesUploaded / fileSize).clamp(0.0, 1.0);
        final mbUploaded = (bytesUploaded / (1024 * 1024)).toStringAsFixed(1);
        final mbTotal = (fileSize / (1024 * 1024)).toStringAsFixed(1);

        onProgressBytes?.call(
          bytesUploaded,
          fileSize,
          'Sauvegarde Cloud: $mbUploaded Mo / $mbTotal Mo (${(progress * 100).toInt()}%)',
        );
      }

      await randomAccess.close();
      onProgressBytes?.call(fileSize, fileSize, 'Sauvegarde Cloud terminée avec succès !');
      return true;
    } on BackupCancelledException catch (_) {
      try {
        await randomAccess?.close();
      } catch (_) {}
      rethrow;
    } catch (e) {
      try {
        await randomAccess?.close();
      } catch (_) {}
      if (kDebugMode) print('❌ Exception lors de l\'upload resumable: $e');
      return false;
    }
  }

  /// Méthode d'upload legacy conservée pour rétrocompatibilité
  Future<bool> uploadBackupFileChunked({
    required String accessToken,
    required File file,
    required String remoteFolderPath,
    required String remoteFileName,
    OnProgressCallback? onProgress,
  }) async {
    final session = await createUploadSession(
      accessToken: accessToken,
      remoteFolderPath: remoteFolderPath,
      remoteFileName: remoteFileName,
    );
    if (session == null) return false;

    return uploadBackupFileChunkedResumable(
      accessToken: accessToken,
      file: file,
      remoteFolderPath: remoteFolderPath,
      remoteFileName: remoteFileName,
      uploadUrl: session.uploadUrl,
      onProgressBytes: (uploaded, total, message) {
        final progress = total > 0 ? (uploaded / total).clamp(0.0, 1.0) : 0.0;
        onProgress?.call(progress, message);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4. ÉCRITURE DU MANIFEST.JSON DE SYNC SUR LE CLOUD
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
  // 5. RÉCUPÉRATION DU MANIFEST DISTANT
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
  // 6. TÉLÉCHARGEMENT D'UNE SAUVEGARDE DISTANTE (.inspec)
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
