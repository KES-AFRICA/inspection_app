// test/features/backup_job_manager_test.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/features/backup/data/datasources/backup_job_store.dart';
import 'package:inspec_app/features/backup/data/datasources/local_backup_store.dart';
import 'package:inspec_app/features/backup/data/services/backup_job_manager.dart';
import 'package:inspec_app/features/backup/domain/models/backup_cancel_token.dart';
import 'package:inspec_app/features/backup/domain/models/backup_job.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_job_manager_test_');
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

  group('Machine à États & Orchestrateur BackupJobManager', () {
    test('1. Modèle BackupJob et sérialisation JSON', () {
      final job = BackupJob(
        id: 'job_m001_123',
        missionId: 'm001',
        matricule: 'KES001',
        status: BackupJobStatus.uploading,
        progress: 0.64,
        uploadedBytes: 67108864,
        totalBytes: 104857600,
        uploadSessionUrl: 'https://graph.microsoft.com/v1.0/uploadSession/test',
        createdAt: DateTime(2026, 8, 28, 15, 0),
        updatedAt: DateTime(2026, 8, 28, 15, 5),
      );

      expect(job.isActive, isTrue);
      expect(job.isPaused, isFalse);
      expect(job.isFinished, isFalse);

      final json = job.toJson();
      final deserialized = BackupJob.fromJson(json);

      expect(deserialized.id, equals('job_m001_123'));
      expect(deserialized.status, equals(BackupJobStatus.uploading));
      expect(deserialized.progress, equals(0.64));
      expect(deserialized.uploadedBytes, equals(67108864));
      expect(deserialized.uploadSessionUrl, contains('uploadSession/test'));
    });

    test('2. Token d\'annulation filaire BackupCancelToken', () {
      final token = BackupCancelToken();
      expect(token.isCancelled, isFalse);

      bool listenerCalled = false;
      token.onCancel((reason) {
        listenerCalled = true;
        expect(reason, equals('Annulation explicite de test'));
      });

      token.cancel('Annulation explicite de test');
      expect(token.isCancelled, isTrue);
      expect(listenerCalled, isTrue);
      expect(() => token.throwIfCancelled(), throwsA(isA<BackupCancelledException>()));
    });

    test('3. Stockage persistant Hive via BackupJobStore', () async {
      final jobStore = BackupJobStore();
      final job = BackupJob(
        id: 'job_store_test_001',
        missionId: 'mission_store_001',
        matricule: 'KES001',
        status: BackupJobStatus.paused,
        progress: 0.45,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await jobStore.saveJob(job);

      final fetched = await jobStore.getJob('job_store_test_001');
      expect(fetched, isNotNull);
      expect(fetched!.status, equals(BackupJobStatus.paused));

      final active = await jobStore.getActiveJobForMission('mission_store_001');
      expect(active, isNotNull);
      expect(active!.id, equals('job_store_test_001'));
    });

    test('4. Unicité du job actif par mission (1 job max par mission)', () async {
      final jobStore = BackupJobStore();
      final missionId = 'mission_unique_job_004';
      final activeJob = BackupJob(
        id: 'job_active_004',
        missionId: missionId,
        matricule: 'KES001',
        status: BackupJobStatus.uploading,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await jobStore.saveJob(activeJob);

      final fetched = await jobStore.getActiveJobForMission(missionId);
      expect(fetched, isNotNull);
      expect(fetched!.id, equals('job_active_004'));
    });

    test('5. Commande de Mise en Pause & Reprise', () async {
      final jobStore = BackupJobStore();
      final jobId = 'job_pause_resume_005';
      final job = BackupJob(
        id: jobId,
        missionId: 'mission_pause_005',
        matricule: 'KES001',
        status: BackupJobStatus.uploading,
        progress: 0.50,
        uploadedBytes: 5000,
        totalBytes: 10000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await jobStore.saveJob(job);

      final manager = BackupJobManager(jobStore: jobStore);
      await manager.pauseBackup(jobId);

      final pausedJob = await jobStore.getJob(jobId);
      expect(pausedJob, isNotNull);
      expect(pausedJob!.status, equals(BackupJobStatus.paused));
    });

    test('6. Commande d\'Annulation explicite avec état cancelled', () async {
      final jobStore = BackupJobStore();
      final jobId = 'job_cancel_006';
      final job = BackupJob(
        id: jobId,
        missionId: 'mission_cancel_006',
        matricule: 'KES001',
        status: BackupJobStatus.uploading,
        progress: 0.30,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await jobStore.saveJob(job);

      final manager = BackupJobManager(jobStore: jobStore);
      await manager.cancelBackup(jobId);

      final cancelledJob = await jobStore.getJob(jobId);
      expect(cancelledJob, isNotNull);
      expect(cancelledJob!.status, equals(BackupJobStatus.cancelled));
    });

    test('7. Préservation stricte de l\'état paused (Non écrasé par la levée du BackupCancelToken)', () async {
      final jobStore = BackupJobStore();
      final jobId = 'job_pause_preservation_007';
      final job = BackupJob(
        id: jobId,
        missionId: 'mission_pause_007',
        matricule: 'KES001',
        status: BackupJobStatus.uploading,
        progress: 0.55,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await jobStore.saveJob(job);
      final manager = BackupJobManager(jobStore: jobStore);
      await manager.pauseBackup(jobId);

      final stateAfterPause = await jobStore.getJob(jobId);
      expect(stateAfterPause!.status, equals(BackupJobStatus.paused));
      expect(stateAfterPause.isPaused, isTrue);
    });
  });
}
