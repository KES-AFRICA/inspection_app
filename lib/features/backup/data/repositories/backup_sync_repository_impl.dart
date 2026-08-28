// lib/features/backup/data/repositories/backup_sync_repository_impl.dart

import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inspec_app/services/backup_service.dart';
import 'package:inspec_app/services/hive_service.dart';
import '../../domain/models/cloud_backup_manifest.dart';
import '../../domain/models/microsoft_user_profile.dart';
import '../../domain/models/mission_sync_state.dart';
import '../../domain/repositories/backup_sync_repository.dart';
import '../datasources/local_backup_store.dart';
import '../datasources/microsoft_auth_service.dart';
import '../datasources/microsoft_graph_storage_service.dart';

class BackupSyncRepositoryImpl implements BackupSyncRepository {
  final MicrosoftAuthService authService;
  final MicrosoftGraphStorageService storageService;
  final LocalBackupStore localStore;

  BackupSyncRepositoryImpl({
    required this.authService,
    required this.storageService,
    LocalBackupStore? localStore,
  }) : localStore = localStore ?? LocalBackupStore();

  @override
  Future<MicrosoftUserProfile?> checkAuthStatus() async {
    return await authService.getSavedUserProfile();
  }

  @override
  Future<MicrosoftUserProfile?> loginWithMicrosoft({
    required String authCode,
    required String codeVerifier,
  }) async {
    return await authService.exchangeCodeForToken(
      authCode: authCode,
      codeVerifier: codeVerifier,
    );
  }

  @override
  Future<void> logout() async {
    await authService.logout();
  }

  @override
  Future<Map<String, MissionSyncState>> getCachedSyncStates(String matricule) async {
    final missions = HiveService.getMissionsByMatricule(matricule);
    if (missions.isEmpty) return {};

    final cacheBox = Hive.isBoxOpen('sync_cache')
        ? Hive.box('sync_cache')
        : await Hive.openBox('sync_cache');

    final map = <String, MissionSyncState>{};

    for (final mission in missions) {
      final latestLocal = await localStore.getLatestLocalBackup(mission.id);

      final cachedRaw = cacheBox.get(mission.id);
      if (cachedRaw != null) {
        try {
          final Map<String, dynamic> json = Map<String, dynamic>.from(cachedRaw as Map);
          final cachedState = MissionSyncState.fromJson(json);

          final hasLocal = latestLocal != null;
          final lastLocal = latestLocal?.createdAt;
          final localSize = latestLocal?.fileSizeBytes;

          if (cachedState.lastBackupDate != null) {
            final isModifiedLocally = mission.updatedAt.isAfter(cachedState.lastBackupDate!);
            map[mission.id] = cachedState.copyWith(
              hasLocalBackup: hasLocal,
              lastLocalBackupDate: lastLocal,
              localSizeBytes: localSize,
              localChecksum: latestLocal?.sha256Checksum,
              status: isModifiedLocally
                  ? SyncStatus.localModifications
                  : SyncStatus.upToDate,
              statusMessage: isModifiedLocally
                  ? (hasLocal ? 'Protégée localement • Modifications à envoyer sur le Cloud' : 'Modifications locales en attente')
                  : 'Protégée (Cloud & Local)',
            );
          } else if (hasLocal) {
            map[mission.id] = cachedState.copyWith(
              hasLocalBackup: true,
              lastLocalBackupDate: lastLocal,
              localSizeBytes: localSize,
              localChecksum: latestLocal.sha256Checksum,
              status: SyncStatus.localOnly,
              statusMessage: 'Sauvegardée localement (En attente de connexion Cloud)',
            );
          } else {
            map[mission.id] = cachedState;
          }
        } catch (_) {
          map[mission.id] = MissionSyncState(
            missionId: mission.id,
            status: latestLocal != null ? SyncStatus.localOnly : SyncStatus.neverBackedUp,
            hasLocalBackup: latestLocal != null,
            lastLocalBackupDate: latestLocal?.createdAt,
            localSizeBytes: latestLocal?.fileSizeBytes,
            statusMessage: latestLocal != null ? 'Sauvegardée localement (Offline)' : 'Jamais sauvegardée',
          );
        }
      } else {
        map[mission.id] = MissionSyncState(
          missionId: mission.id,
          status: latestLocal != null ? SyncStatus.localOnly : SyncStatus.neverBackedUp,
          hasLocalBackup: latestLocal != null,
          lastLocalBackupDate: latestLocal?.createdAt,
          localSizeBytes: latestLocal?.fileSizeBytes,
          statusMessage: latestLocal != null ? 'Sauvegardée localement (Offline)' : 'Jamais sauvegardée',
        );
      }
    }

    return map;
  }

  @override
  Future<Map<String, MissionSyncState>> checkSyncStateForAllMissions(String matricule) async {
    final missions = HiveService.getMissionsByMatricule(matricule);
    if (missions.isEmpty) return {};

    final user = await authService.getSavedUserProfile();
    final accessToken = await authService.getValidAccessToken();

    final futures = missions.map((mission) async {
      final latestLocal = await localStore.getLatestLocalBackup(mission.id);
      final hasLocal = latestLocal != null;

      if (accessToken == null || user == null) {
        return MapEntry(
          mission.id,
          MissionSyncState(
            missionId: mission.id,
            status: hasLocal ? SyncStatus.localOnly : SyncStatus.neverBackedUp,
            hasLocalBackup: hasLocal,
            lastLocalBackupDate: latestLocal?.createdAt,
            localSizeBytes: latestLocal?.fileSizeBytes,
            localChecksum: latestLocal?.sha256Checksum,
            statusMessage: hasLocal
                ? 'Sauvegardée localement (En attente de connexion Cloud)'
                : 'Jamais sauvegardée',
          ),
        );
      }

      try {
        final remoteFolderPath =
            'Apps/KES Inspection/Sauvegardes/${user.displayName}/Mission_${mission.nomClient}_${mission.id}';
        final manifest = await storageService.fetchRemoteManifest(
          accessToken: accessToken,
          remoteFolderPath: remoteFolderPath,
        );

        if (manifest == null) {
          return MapEntry(
            mission.id,
            MissionSyncState(
              missionId: mission.id,
              status: hasLocal ? SyncStatus.localOnly : SyncStatus.neverBackedUp,
              hasLocalBackup: hasLocal,
              lastLocalBackupDate: latestLocal?.createdAt,
              localSizeBytes: latestLocal?.fileSizeBytes,
              localChecksum: latestLocal?.sha256Checksum,
              statusMessage: hasLocal
                  ? 'Sauvegardée localement (En attente de synchronisation Cloud)'
                  : 'Jamais sauvegardée sur le Cloud',
            ),
          );
        } else {
          final isModifiedLocally = mission.updatedAt.isAfter(manifest.backupCreatedAt);
          final isMatchChecksum = hasLocal && latestLocal.sha256Checksum == manifest.sha256Checksum;

          return MapEntry(
            mission.id,
            MissionSyncState(
              missionId: mission.id,
              status: (isModifiedLocally && !isMatchChecksum)
                  ? SyncStatus.localModifications
                  : SyncStatus.upToDate,
              lastBackupDate: manifest.backupCreatedAt,
              remoteSizeBytes: manifest.fileSizeBytes,
              hasLocalBackup: hasLocal,
              lastLocalBackupDate: latestLocal?.createdAt,
              localSizeBytes: latestLocal?.fileSizeBytes,
              localChecksum: latestLocal?.sha256Checksum,
              statusMessage: (isModifiedLocally && !isMatchChecksum)
                  ? 'Modifications locales depuis la dernière sauvegarde Cloud'
                  : 'Protégée (Cloud & Local à jour)',
            ),
          );
        }
      } catch (e) {
        return MapEntry(
          mission.id,
          MissionSyncState(
            missionId: mission.id,
            status: hasLocal ? SyncStatus.localOnly : SyncStatus.interrupted,
            hasLocalBackup: hasLocal,
            lastLocalBackupDate: latestLocal?.createdAt,
            localSizeBytes: latestLocal?.fileSizeBytes,
            localChecksum: latestLocal?.sha256Checksum,
            statusMessage: hasLocal
                ? 'Sauvegardée localement • Cloud temporairement indisponible'
                : 'Cloud temporairement inaccessible (Hors-ligne)',
          ),
        );
      }
    });

    final entries = await Future.wait(futures);
    final resultMap = Map<String, MissionSyncState>.fromEntries(entries);

    final cacheBox = Hive.isBoxOpen('sync_cache')
        ? Hive.box('sync_cache')
        : await Hive.openBox('sync_cache');

    resultMap.forEach((missionId, state) {
      cacheBox.put(missionId, state.toJson());
    });

    return resultMap;
  }

  @override
  Future<bool> backupSingleMission({
    required String missionId,
    required String matricule,
    void Function(double progress, String statusMessage)? onProgress,
  }) async {
    final mission = HiveService.getMissionById(missionId);
    if (mission == null) {
      onProgress?.call(0, 'Erreur: Mission introuvable');
      return false;
    }

    // 1. NIVEAU 1 : Sauvegarde Locale Automatique & Permanente
    onProgress?.call(0.05, 'Création et scellage de la sauvegarde locale (Niveau 1)...');
    var localBackupItem = await localStore.getLatestLocalBackup(missionId);
    if (localBackupItem == null || mission.updatedAt.isAfter(localBackupItem.createdAt)) {
      localBackupItem = await localStore.saveLocalBackup(missionId: missionId, matricule: matricule);
    }

    if (localBackupItem == null) {
      onProgress?.call(0, 'Erreur lors de la sauvegarde locale (Niveau 1)');
      return false;
    }

    final localFile = File(localBackupItem.filePath);
    if (!localFile.existsSync()) {
      onProgress?.call(0, 'Erreur: Fichier de sauvegarde locale introuvable');
      return false;
    }

    // 2. NIVEAU 2 : Synchronisation Cloud Microsoft 365 / OneDrive
    final accessToken = await authService.getValidAccessToken();
    final user = await authService.getSavedUserProfile();

    if (accessToken == null || user == null) {
      onProgress?.call(1.0, 'Sauvegardée localement avec succès (Cloud hors-ligne)');
      return true; // Le Niveau 1 a réussi !
    }

    final remoteFolderPath = 'Apps/KES Inspection/Sauvegardes/${user.displayName}/Mission_${mission.nomClient}_$missionId';
    final remoteFileName = 'sauvegarde_${mission.nomClient}_${DateTime.now().millisecondsSinceEpoch}.inspec';

    // A. Déduplication par checksum SHA-256
    final remoteManifest = await storageService.fetchRemoteManifest(
      accessToken: accessToken,
      remoteFolderPath: remoteFolderPath,
    );

    if (remoteManifest != null && remoteManifest.sha256Checksum == localBackupItem.sha256Checksum) {
      onProgress?.call(1.0, 'Sauvegarde Cloud à jour (Déduplication No-Op)');
      await localStore.markSyncedToCloud(missionId, localBackupItem.sha256Checksum);
      return true;
    }

    // B. Créer le dossier distant
    await storageService.ensureFolderExists(accessToken, remoteFolderPath);

    // C. Téléverser par morceaux (Resumable Chunked Upload)
    onProgress?.call(0.2, 'Connexion au Cloud Microsoft...');
    final uploadSuccess = await storageService.uploadBackupFileChunked(
      accessToken: accessToken,
      file: localFile,
      remoteFolderPath: remoteFolderPath,
      remoteFileName: remoteFileName,
      onProgress: onProgress,
    );

    if (!uploadSuccess) {
      onProgress?.call(0.5, 'Sauvegardée localement sur le téléphone (Upload Cloud temporairement échoué)');
      return false;
    }

    // D. Écrire le manifest.json de métadonnées
    final manifest = CloudBackupManifest(
      missionId: missionId,
      missionName: mission.nomClient,
      clientName: mission.nomClient,
      fileName: remoteFileName,
      fileSizeBytes: localBackupItem.fileSizeBytes,
      sha256Checksum: localBackupItem.sha256Checksum,
      backupCreatedAt: DateTime.now(),
      inspectorMatricule: matricule,
      inspectorName: user.displayName,
      photoCount: 0,
      observationCount: 0,
    );

    await storageService.uploadManifest(
      accessToken: accessToken,
      manifest: manifest,
      remoteFolderPath: remoteFolderPath,
    );

    // Marquer la sauvegarde locale comme synchronisée
    await localStore.markSyncedToCloud(missionId, localBackupItem.sha256Checksum);

    onProgress?.call(1.0, 'Sauvegarde terminée avec succès (Local + Cloud)');
    return true;
  }

  @override
  Future<bool> restoreSingleMission({
    required String missionId,
    required String remoteFileName,
    required String remoteFolderPath,
    void Function(double progress, String statusMessage)? onProgress,
  }) async {
    final accessToken = await authService.getValidAccessToken();
    if (accessToken == null) {
      onProgress?.call(0, 'Erreur: Non connecté à Microsoft 365');
      return false;
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_restore_$remoteFileName');

    onProgress?.call(0.1, 'Téléchargement depuis le Cloud Microsoft...');

    final downloadedFile = await storageService.downloadBackupFile(
      accessToken: accessToken,
      remoteFolderPath: remoteFolderPath,
      remoteFileName: remoteFileName,
      targetFile: tempFile,
      onProgress: onProgress,
    );

    if (downloadedFile == null || !downloadedFile.existsSync()) {
      onProgress?.call(0, 'Échec du téléchargement depuis le Cloud');
      return false;
    }

    onProgress?.call(0.9, 'Restauration de la mission dans l\'application...');

    final user = await authService.getSavedUserProfile();
    final importResult = await BackupService.importerSauvegardeFichier(
      filePath: downloadedFile.path,
      ecraser: true,
      importeurMatricule: user?.id ?? 'ADMIN',
      importeurNom: user?.displayName ?? 'Inspecteur',
      importeurPrenom: '',
    );

    try {
      if (downloadedFile.existsSync()) await downloadedFile.delete();
    } catch (_) {}

    if (importResult.success) {
      onProgress?.call(1.0, 'Restauration réussie !');
      return true;
    } else {
      onProgress?.call(0, 'Erreur de restauration: ${importResult.message}');
      return false;
    }
  }
}
