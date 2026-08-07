import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/microsoft_auth_service.dart';
import '../../data/datasources/microsoft_graph_storage_service.dart';
import '../../data/repositories/backup_sync_repository_impl.dart';
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

// State Notifier pour le profil Microsoft
class MicrosoftAuthNotifier extends StateNotifier<AsyncValue<MicrosoftUserProfile?>> {
  final BackupSyncRepository repository;

  MicrosoftAuthNotifier(this.repository) : super(const AsyncValue.loading()) {
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
  return MicrosoftAuthNotifier(ref.watch(backupSyncRepositoryProvider));
});

// State Notifier pour l'état des sauvegardes des missions
class BackupSyncStateNotifier extends StateNotifier<Map<String, MissionSyncState>> {
  final BackupSyncRepository repository;
  final Ref ref;

  BackupSyncStateNotifier(this.repository, this.ref) : super({});

  Future<void> refreshAll(String matricule) async {
    final map = await repository.checkSyncStateForAllMissions(matricule);
    state = map;
  }

  Future<bool> backupMission(String missionId, String matricule) async {
    state = {
      ...state,
      missionId: MissionSyncState(
        missionId: missionId,
        status: SyncStatus.syncing,
        progress: 0.05,
        statusMessage: 'Initialisation de la sauvegarde...',
      ),
    };

    final success = await repository.backupSingleMission(
      missionId: missionId,
      matricule: matricule,
      onProgress: (progress, message) {
        state = {
          ...state,
          missionId: MissionSyncState(
            missionId: missionId,
            status: SyncStatus.syncing,
            progress: progress,
            statusMessage: message,
          ),
        };
      },
    );

    if (success) {
      state = {
        ...state,
        missionId: MissionSyncState(
          missionId: missionId,
          status: SyncStatus.upToDate,
          progress: 1.0,
          lastBackupDate: DateTime.now(),
          statusMessage: 'Sauvegarde Cloud à jour !',
        ),
      };
    } else {
      state = {
        ...state,
        missionId: MissionSyncState(
          missionId: missionId,
          status: SyncStatus.failed,
          progress: 0.0,
          errorMessage: 'Échec de la sauvegarde vers le Cloud',
        ),
      };
    }

    return success;
  }
}

final backupSyncNotifierProvider =
    StateNotifierProvider<BackupSyncStateNotifier, Map<String, MissionSyncState>>((ref) {
  return BackupSyncStateNotifier(
    ref.watch(backupSyncRepositoryProvider),
    ref,
  );
});
