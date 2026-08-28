// lib/features/backup/data/datasources/local_backup_store.dart

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inspec_app/services/backup_service.dart';
import '../../domain/models/local_backup_item.dart';

/// Gestionnaire du Niveau 1 : Sauvegarde Locale Automatique & Permanente
class LocalBackupStore {
  static const String _boxName = 'local_backups_metadata';

  Future<Box> _getBox() async {
    return Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
  }

  /// Répertoire racine des sauvegardes locales permanentes pour une mission
  Future<Directory> getMissionBackupDir(String missionId) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDocDir.path}/sauvegardes_locales/$missionId');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Sauvegarde locale automatique (Offline-First Level 1)
  /// Export `.inspec` -> Stockage permanent dans `/sauvegardes_locales/{missionId}/` -> Checksum SHA-256
  Future<LocalBackupItem?> saveLocalBackup({
    required String missionId,
    required String matricule,
  }) async {
    try {
      // 1. Exécuter l'exportateur .inspec
      final exportResult = await BackupService.exporterMission(
        missionId,
        openShareSheet: false,
        isCloudBackup: false,
      );

      if (!exportResult.success || exportResult.filePath == null) {
        if (kDebugMode) {
          print('❌ Échec génération export .inspec local: ${exportResult.message}');
        }
        return null;
      }

      final exportedFile = File(exportResult.filePath!);
      if (!exportedFile.existsSync()) return null;

      // 2. Déplacer / Copier de manière permanente dans /sauvegardes_locales/{missionId}/
      final targetDir = await getMissionBackupDir(missionId);
      final ts = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-').substring(0, 19);
      final fileName = 'local_backup_${missionId}_$ts.inspec';
      final permanentFile = File('${targetDir.path}/$fileName');

      await exportedFile.copy(permanentFile.path);

      // Supprimer le fichier temporaire de travail initial
      try {
        if (exportedFile.existsSync()) await exportedFile.delete();
      } catch (_) {}

      // 3. Calculer l'empreinte SHA-256 et la taille
      final fileBytes = await permanentFile.readAsBytes();
      final checksum = sha256.convert(fileBytes).toString();
      final fileSize = fileBytes.length;

      final backupItem = LocalBackupItem(
        missionId: missionId,
        filePath: permanentFile.path,
        fileName: fileName,
        fileSizeBytes: fileSize,
        sha256Checksum: checksum,
        createdAt: DateTime.now(),
        appVersion: '4.0.0',
        isSyncedToCloud: false,
      );

      // 4. Enregistrer dans Hive (indexation par missionId + timestamp)
      final box = await _getBox();
      final key = '${missionId}_${backupItem.createdAt.millisecondsSinceEpoch}';
      await box.put(key, backupItem.toJson());
      await box.put('latest_$missionId', backupItem.toJson());

      if (kDebugMode) {
        print('✅ Sauvegarde locale NIVEAU 1 créée avec succès: ${permanentFile.path} ($fileSize octets)');
      }

      return backupItem;
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Erreur saveLocalBackup pour mission $missionId: $e\n$st');
      }
      return null;
    }
  }

  /// Récupérer la dernière sauvegarde locale pour une mission
  Future<LocalBackupItem?> getLatestLocalBackup(String missionId) async {
    try {
      final box = await _getBox();
      final raw = box.get('latest_$missionId');
      if (raw != null) {
        final json = Map<String, dynamic>.from(raw as Map);
        final item = LocalBackupItem.fromJson(json);
        if (File(item.filePath).existsSync()) {
          return item;
        }
      }

      // Fallback: chercher le plus récent dans tous les enregistrements
      final items = await getLocalBackupsForMission(missionId);
      if (items.isNotEmpty) {
        return items.first;
      }
    } catch (_) {}
    return null;
  }

  /// Obtenir l'historique complet des sauvegardes locales pour une mission
  Future<List<LocalBackupItem>> getLocalBackupsForMission(String missionId) async {
    final items = <LocalBackupItem>[];
    try {
      final box = await _getBox();
      for (final entry in box.toMap().entries) {
        if (entry.key.toString().startsWith('${missionId}_') && !entry.key.toString().startsWith('latest_')) {
          try {
            final json = Map<String, dynamic>.from(entry.value as Map);
            final item = LocalBackupItem.fromJson(json);
            if (File(item.filePath).existsSync()) {
              items.add(item);
            }
          } catch (_) {}
        }
      }
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {}
    return items;
  }

  /// Marquer une sauvegarde locale comme synchronisée avec le cloud
  Future<void> markSyncedToCloud(String missionId, String checksum) async {
    try {
      final box = await _getBox();
      final latestRaw = box.get('latest_$missionId');
      if (latestRaw != null) {
        final json = Map<String, dynamic>.from(latestRaw as Map);
        final item = LocalBackupItem.fromJson(json);
        if (item.sha256Checksum == checksum) {
          final updated = item.copyWith(
            isSyncedToCloud: true,
            syncedAt: DateTime.now(),
          );
          await box.put('latest_$missionId', updated.toJson());
        }
      }
    } catch (_) {}
  }
}
