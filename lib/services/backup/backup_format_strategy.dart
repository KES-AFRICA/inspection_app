import 'dart:io';
import 'package:flutter/foundation.dart';

/// Formats de sauvegardes supportés par l'application
enum BackupFileFormat {
  /// Nouveau format binaire / zip bundle (V4+, .bin, .inspec, .zip)
  zipBin,

  /// Ancien format JSON brut (V1, V2, V3, .json)
  jsonLegacy,

  /// Format inconnu ou non supporté
  unknown,
}

/// Informations sur le format détecté
class BackupFormatInfo {
  final BackupFileFormat format;
  final String extension;
  final bool isZipHeader;
  final bool isJsonHeader;
  final String? rawHeaderSnippet;

  const BackupFormatInfo({
    required this.format,
    required this.extension,
    required this.isZipHeader,
    required this.isJsonHeader,
    this.rawHeaderSnippet,
  });

  bool get isSupported => format != BackupFileFormat.unknown;
}

/// Détecteur central du format de sauvegarde
class BackupFormatDetector {
  /// Inspecte le fichier sur le disque en lisant ses octets d'en-tête (Magic bytes)
  static Future<BackupFormatInfo> detectFormat(File file) async {
    try {
      if (!await file.exists()) {
        return const BackupFormatInfo(
          format: BackupFileFormat.unknown,
          extension: '',
          isZipHeader: false,
          isJsonHeader: false,
        );
      }

      final path = file.path.toLowerCase();
      String ext = '';
      if (path.contains('.')) {
        ext = path.split('.').last;
      }

      final length = await file.length();
      if (length < 4) {
        return BackupFormatInfo(
          format: BackupFileFormat.unknown,
          extension: ext,
          isZipHeader: false,
          isJsonHeader: false,
        );
      }

      // Lecture des 64 premiers octets pour analyser le Magic Header
      final stream = file.openRead(0, 64);
      final bytes = await stream.fold<List<int>>(<int>[], (p, e) {
        p.addAll(e);
        return p;
      });

      // 1. Détection du header ZIP / BIN (Magic bytes: 0x50 0x4B 0x03 0x04 'PK\x03\x04')
      final bool isZipHeader = bytes.length >= 4 &&
          bytes[0] == 0x50 &&
          bytes[1] == 0x4B &&
          bytes[2] == 0x03 &&
          bytes[3] == 0x04;

      if (isZipHeader) {
        return BackupFormatInfo(
          format: BackupFileFormat.zipBin,
          extension: ext,
          isZipHeader: true,
          isJsonHeader: false,
        );
      }

      // 2. Détection du header JSON (Contient '{' ou 'magic' / 'INSPEC_BACKUP')
      String headerStr = '';
      try {
        headerStr = String.fromCharCodes(bytes);
      } catch (_) {}

      final bool isJsonHeader = headerStr.trimLeft().startsWith('{') ||
          headerStr.contains('magic') ||
          headerStr.contains('INSPEC_BACKUP');

      if (isJsonHeader || ext == 'json') {
        return BackupFormatInfo(
          format: BackupFileFormat.jsonLegacy,
          extension: ext,
          isZipHeader: false,
          isJsonHeader: isJsonHeader,
          rawHeaderSnippet: headerStr,
        );
      }

      // 3. Fallback sur l'extension si le header est ambigu
      if (ext == 'bin' || ext == 'inspec' || ext == 'zip') {
        return BackupFormatInfo(
          format: BackupFileFormat.zipBin,
          extension: ext,
          isZipHeader: isZipHeader,
          isJsonHeader: false,
        );
      }

      return BackupFormatInfo(
        format: BackupFileFormat.unknown,
        extension: ext,
        isZipHeader: false,
        isJsonHeader: false,
      );
    } catch (e) {
      if (kDebugMode) print('⚠️ BackupFormatDetector error: $e');
      return const BackupFormatInfo(
        format: BackupFileFormat.unknown,
        extension: '',
        isZipHeader: false,
        isJsonHeader: false,
      );
    }
  }
}
