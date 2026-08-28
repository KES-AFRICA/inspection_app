// lib/features/backup/presentation/providers/backup_providers.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/backup_job_store.dart';
import '../../data/datasources/backup_queue_service.dart';
import '../../data/services/backup_job_manager.dart';
import '../../data/services/backup_scheduler_service.dart';
import '../../data/services/msal_recommendation_service.dart';
import '../../data/services/app_update_migration_service.dart';
import '../../data/services/backup_orchestrator.dart';
import '../../data/datasources/microsoft_auth_service.dart';
import '../../data/datasources/microsoft_graph_storage_service.dart';
import '../../data/repositories/backup_sync_repository_impl.dart';
import '../../domain/models/backup_job.dart';
import '../../domain/models/microsoft_user_profile.dart';
import '../../domain/models/mission_sync_state.dart';
import '../../domain/repositories/backup_sync_repository.dart';

// Service DI
final microsoftAuthServiceProvider = Provider<MicrosoftAuthService>((ref) {
  return MicrosoftAuthService();
});

final microsoftGraphStorageServiceProvider = Provider<MicrosoftGraphStorageService>((ref) {
  return MicrosoftGraphStorageService();
});

final backupSyncRepositoryProvider = Provider<BackupSyncRepository>((ref) {
  return BackupSyncRepositoryImpl(
    authService: ref.watch(microsoftAuthServiceProvider),
    storageService: ref.watch(microsoftGraphStorageServiceProvider),
  );
});

final backupQueueServiceProvider = Provider<BackupQueueService>((ref) {
  return BackupQueueService();
});

final backupJobStoreProvider = Provider<BackupJobStore>((ref) {
  return BackupJobStore();
});

final backupJobManagerProvider = Provider<BackupJobManager>((ref) {
  return BackupJobManager(
    jobStore: ref.watch(backupJobStoreProvider),
    authService: ref.watch(microsoftAuthServiceProvider),
    storageService: ref.watch(microsoftGraphStorageServiceProvider),
  );
});

final backupJobStreamProvider = StreamProvider<Map<String, BackupJob>>((ref) {
  return ref.watch(backupJobManagerProvider).jobsStream;
});

final msalRecommendationServiceProvider = Provider<MsalRecommendationService>((ref) {
  return MsalRecommendationService();
});

final backupSchedulerServiceProvider = Provider<BackupSchedulerService>((ref) {
  return BackupSchedulerService(
    repository: ref.watch(backupSyncRepositoryProvider),
    authService: ref.watch(microsoftAuthServiceProvider),
    queueService: ref.watch(backupQueueServiceProvider),
  );
});

final appUpdateMigrationServiceProvider = Provider<AppUpdateMigrationService>((ref) {
  return AppUpdateMigrationService(
    schedulerService: ref.watch(backupSchedulerServiceProvider),
  );
});

final backupOrchestratorProvider = Provider<BackupOrchestrator>((ref) {
  return BackupOrchestrator(
    repository: ref.watch(backupSyncRepositoryProvider),
    authService: ref.watch(microsoftAuthServiceProvider),
    queueService: ref.watch(backupQueueServiceProvider),
    schedulerService: ref.watch(backupSchedulerServiceProvider),
    migrationService: ref.watch(appUpdateMigrationServiceProvider),
    backupDelegate: ({required missionId, required matricule, required onProgress}) async {
      final manager = ref.read(backupJobManagerProvider);
      final job = await manager.startBackup(missionId: missionId, matricule: matricule);
      return job.status == BackupJobStatus.completed;
    },
  );
});

final backupOrchestratorStateProvider = StreamProvider<BackupOrchestratorState>((ref) {
  return ref.watch(backupOrchestratorProvider).stateStream;
});

// State Notifier pour le profil Microsoft
class MicrosoftAuthNotifier extends StateNotifier<AsyncValue<MicrosoftUserProfile?>> {
  final BackupSyncRepository repository;
  final Ref ref;

  MicrosoftAuthNotifier(this.repository, this.ref) : super(const AsyncValue.loading()) {
    checkStatus();
  }

  Future<void> checkStatus() async {
    state = const AsyncValue.loading();
    try {
      final profile = await repository.checkAuthStatus();
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> loginWithCode({required String code, required String verifier}) async {
    state = const AsyncValue.loading();
    try {
      final profile = await repository.loginWithMicrosoft(authCode: code, codeVerifier: verifier);
      state = AsyncValue.data(profile);
      if (profile != null) {
        unawaited(ref.read(backupOrchestratorProvider).triggerCatchUpSyncIfPending(profile.displayName));
      }
      return profile != null;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await repository.logout();
    state = const AsyncValue.data(null);
  }
}

final microsoftAuthNotifierProvider =
    StateNotifierProvider<MicrosoftAuthNotifier, AsyncValue<MicrosoftUserProfile?>>((ref) {
  return MicrosoftAuthNotifier(ref.watch(backupSyncRepositoryProvider), ref);
});

// State Notifier pour l'état des sauvegardes des missions
class BackupSyncStateNotifier extends StateNotifier<Map<String, MissionSyncState>> {
  final BackupSyncRepository repository;
  final Ref ref;
  StreamSubscription? _jobSubscription;

  BackupSyncStateNotifier(this.repository, this.ref) : super({}) {
    // Écouter le stream des BackupJobs pour mettre à jour en temps réel l'UI des cartes
    final manager = ref.read(backupJobManagerProvider);
    _jobSubscription = manager.jobsStream.listen((jobsMap) {
      final newState = Map<String, MissionSyncState>.from(state);
      jobsMap.forEach((missionId, job) {
        newState[missionId] = MissionSyncState(
          missionId: missionId,
          status: _mapJobStatusToSyncStatus(job.status),
          progress: job.progress,
          statusMessage: job.statusMessage,
          lastBackupDate: job.completedAt,
          remoteSizeBytes: job.totalBytes,
          errorMessage: job.lastError,
          hasLocalBackup: job.localFilePath != null,
          localSizeBytes: job.totalBytes,
          localChecksum: job.sha256Checksum,
        );
      });
      state = newState;
    });
  }

  SyncStatus _mapJobStatusToSyncStatus(BackupJobStatus jobStatus) {
    switch (jobStatus) {
      case BackupJobStatus.idle:
        return SyncStatus.neverBackedUp;
      case BackupJobStatus.preparing:
      case BackupJobStatus.queued:
      case BackupJobStatus.uploading:
      case BackupJobStatus.waitingForAuthentication:
      case BackupJobStatus.retrying:
        return SyncStatus.syncing;
      case BackupJobStatus.paused:
        return SyncStatus.paused;
      case BackupJobStatus.waitingForNetwork:
        return SyncStatus.localOnly;
      case BackupJobStatus.completed:
        return SyncStatus.upToDate;
      case BackupJobStatus.failed:
        return SyncStatus.failed;
      case BackupJobStatus.cancelled:
        return SyncStatus.interrupted;
    }
  }

  Future<void> loadCachedStates(String matricule) async {
    final cached = await repository.getCachedSyncStates(matricule);
    if (cached.isNotEmpty) {
      state = cached;
    }
  }

  Future<void> refreshAll(String matricule) async {
    if (state.isEmpty) {
      await loadCachedStates(matricule);
    }
    final map = await repository.checkSyncStateForAllMissions(matricule);
    final newState = Map<String, MissionSyncState>.from(state);
    map.forEach((key, value) {
      newState[key] = value;
    });
    state = newState;
  }

  Future<bool> backupMission(String missionId, String matricule) async {
    try {
      final manager = ref.read(backupJobManagerProvider);
      final job = await manager.startBackup(missionId: missionId, matricule: matricule);
      return job.status == BackupJobStatus.completed;
    } catch (_) {
      return false;
    }
  }

  Future<void> pauseBackup(String jobId) async {
    await ref.read(backupJobManagerProvider).pauseBackup(jobId);
  }

  Future<void> resumeBackup(String jobId, String matricule) async {
    await ref.read(backupJobManagerProvider).resumeBackup(jobId, matricule);
  }

  Future<void> cancelBackup(String jobId) async {
    await ref.read(backupJobManagerProvider).cancelBackup(jobId);
  }

  @override
  void dispose() {
    _jobSubscription?.cancel();
    super.dispose();
  }
}

final backupSyncNotifierProvider =
    StateNotifierProvider<BackupSyncStateNotifier, Map<String, MissionSyncState>>((ref) {
  return BackupSyncStateNotifier(
    ref.watch(backupSyncRepositoryProvider),
    ref,
  );
});
