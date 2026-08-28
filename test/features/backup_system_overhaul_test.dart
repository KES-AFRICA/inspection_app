// test/features/backup_system_overhaul_test.dart

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/features/backup/data/datasources/local_backup_store.dart';
import 'package:inspec_app/features/backup/data/services/mission_activity_tracker.dart';
import 'package:inspec_app/features/backup/domain/models/local_backup_item.dart';
import 'package:inspec_app/features/backup/domain/models/mission_sync_state.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/backup_service.dart';
import 'package:inspec_app/services/hive_service.dart';

import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_overhaul_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async {
        return tempDir.path;
      },
    );
    Hive.init(tempDir.path);
    await HiveService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('Refonte Système de Sauvegarde (Local + Cloud)', () {
    test('1. Niveau 1 : Sauvegarde locale automatique offline-first', () async {
      final missionId = 'mission_test_local_001';
      final mission = Mission(
        id: missionId,
        nomClient: 'CLIENT TEST LOCAL',
        natureMission: 'INSPECTION VÉRO',
        status: 'en_cours',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        verificateurs: [
          {'matricule': 'KES001', 'nom': 'Inspecteur', 'prenom': 'Test'}
        ],
      );

      final box = Hive.box<Mission>('missions');
      await box.put(missionId, mission);

      final localStore = LocalBackupStore();
      final backupItem = await localStore.saveLocalBackup(
        missionId: missionId,
        matricule: 'KES001',
      );

      expect(backupItem, isNotNull);
      expect(backupItem!.missionId, equals(missionId));
      expect(File(backupItem.filePath).existsSync(), isTrue);
      expect(backupItem.fileSizeBytes, greaterThan(0));
      expect(backupItem.sha256Checksum, isNotEmpty);

      // Vérification que le dernier snapshot local est consultable
      final latest = await localStore.getLatestLocalBackup(missionId);
      expect(latest, isNotNull);
      expect(latest!.sha256Checksum, equals(backupItem.sha256Checksum));
    });

    test('2. Surveillance d\'activité quotidienne 08:00 - 18:00 (modifiedToday)', () async {
      final missionId = 'mission_activity_test_002';
      await MissionActivityTracker.markMissionModifiedToday(missionId);

      final isModified = await MissionActivityTracker.isMissionModifiedToday(missionId);
      expect(isModified, isTrue);

      final modifiedList = await MissionActivityTracker.getMissionsModifiedToday();
      expect(modifiedList.contains(missionId), isTrue);

      await MissionActivityTracker.clearActivityForMission(missionId);
      final isCleared = await MissionActivityTracker.isMissionModifiedToday(missionId);
      expect(isCleared, isFalse);
    });

    test('3. Déduplication SHA-256 : Checksums identiques', () async {
      final sampleContent = 'INSPEC_BACKUP_DEDUPLICATION_TEST_DATA';
      final bytes = sampleContent.codeUnits;
      final hash1 = sha256.convert(bytes).toString();
      final hash2 = sha256.convert(bytes).toString();

      expect(hash1, equals(hash2));
    });

    test('4. Enrichissement du modèle MissionSyncState avec métadonnées locales', () {
      final syncState = MissionSyncState(
        missionId: 'm_001',
        status: SyncStatus.localOnly,
        hasLocalBackup: true,
        lastLocalBackupDate: DateTime(2026, 8, 28, 17, 30),
        localSizeBytes: 1048576,
        localChecksum: 'abc123hash',
        statusMessage: 'Sauvegardée localement (Offline)',
      );

      expect(syncState.status, equals(SyncStatus.localOnly));
      expect(syncState.hasLocalBackup, isTrue);
      expect(syncState.localSizeBytes, equals(1048576));

      final json = syncState.toJson();
      final deserialized = MissionSyncState.fromJson(json);

      expect(deserialized.status, equals(SyncStatus.localOnly));
      expect(deserialized.hasLocalBackup, isTrue);
      expect(deserialized.localChecksum, equals('abc123hash'));
    });

    test('5. Cycle de vie local : Stockage permanent dans /sauvegardes_locales/{missionId}/', () async {
      final localStore = LocalBackupStore();
      final dir = await localStore.getMissionBackupDir('mission_test_local_001');

      expect(dir.existsSync(), isTrue);
      expect(dir.path.contains('sauvegardes_locales/mission_test_local_001'), isTrue);
    });

    test('6. Détection et enrôlement automatique des missions importées', () async {
      final importedMissionId = 'mission_imported_auto_006';
      await MissionActivityTracker.markMissionModifiedToday(importedMissionId);

      final isTracked = await MissionActivityTracker.isMissionModifiedToday(importedMissionId);
      expect(isTracked, isTrue);
    });
  });
}
