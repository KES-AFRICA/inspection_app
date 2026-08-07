// lib/features/backup/domain/repositories/backup_sync_repository.dart

import '../models/microsoft_user_profile.dart';
import '../models/mission_sync_state.dart';

abstract class BackupSyncRepository {
  Future<MicrosoftUserProfile?> checkAuthStatus();
  Future<MicrosoftUserProfile?> loginWithMicrosoft({
    required String authCode,
    required String codeVerifier,
  });
  Future<void> logout();

  Future<Map<String, MissionSyncState>> checkSyncStateForAllMissions(String matricule);
  
  Future<bool> backupSingleMission({
    required String missionId,
    required String matricule,
    void Function(double progress, String statusMessage)? onProgress,
  });

  Future<bool> restoreSingleMission({
    required String missionId,
    required String remoteFileName,
    required String remoteFolderPath,
    void Function(double progress, String statusMessage)? onProgress,
  });
}
