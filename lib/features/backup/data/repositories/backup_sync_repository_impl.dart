// lib/features/backup/data/repositories/backup_sync_repository_impl.dart

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inspec_app/services/backup_service.dart';
import 'package:inspec_app/services/hive_service.dart';
import '../../domain/models/cloud_backup_manifest.dart';
import '../../domain/models/microsoft_user_profile.dart';
import '../../domain/models/mission_sync_state.dart';
import '../../domain/repositories/backup_sync_repository.dart';
import '../datasources/microsoft_auth_service.dart';
import '../datasources/microsoft_graph_storage_service.dart';

class BackupSyncRepositoryImpl implements BackupSyncRepository {
  final MicrosoftAuthService authService;
  final MicrosoftGraphStorageService storageService;

  BackupSyncRepositoryImpl({
    required this.authService,
    required this.storageService,
  });

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
      final cachedRaw = cacheBox.get(mission.id);
      if (cachedRaw != null) {
        try {
          final Map<String, dynamic> json = Map<String, dynamic>.from(cachedRaw as Map);
          final cachedState = MissionSyncState.fromJson(json);

          if (cachedState.lastBackupDate != null) {
            // Comparer l'horodatage local actuel de la mission avec la date de sauvegarde enregistrée
            final isModifiedLocally = mission.updatedAt.isAfter(cachedState.lastBackupDate!);
            map[mission.id] = cachedState.copyWith(
              status: isModifiedLocally ? SyncStatus.localModifications : SyncStatus.upToDate,
              statusMessage: isModifiedLocally
                  ? 'Modifications locales depuis la dernière sauvegarde'
                  : 'Sauvegarde Cloud à jour (${((cachedState.remoteSizeBytes ?? 0) / (1024 * 1024)).toStringAsFixed(1)} Mo)',
            );
          } else {
            map[mission.id] = cachedState;
          }
        } catch (_) {
          map[mission.id] = MissionSyncState(
            missionId: mission.id,
            status: SyncStatus.neverBackedUp,
            statusMessage: 'Vérification en cours...',
          );
        }
      } else {
        map[mission.id] = MissionSyncState(
          missionId: mission.id,
          status: SyncStatus.neverBackedUp,
          statusMessage: 'Vérification en cours...',
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

    if (accessToken == null || user == null) {
      final map = <String, MissionSyncState>{};
      for (final mission in missions) {
        map[mission.id] = MissionSyncState(
          missionId: mission.id,
          status: SyncStatus.neverBackedUp,
          statusMessage: 'Non connecté à Microsoft Cloud',
        );
      }
      return map;
    }

    // Exécution parallèle accélérée (Future.wait) pour toutes les missions de l'inspecteur
    final futures = missions.map((mission) async {
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
              status: SyncStatus.neverBackedUp,
              statusMessage: 'Jamais sauvegardée sur le Cloud',
            ),
          );
        } else {
          final lastModifiedDate = mission.updatedAt;
          final isModifiedLocally = lastModifiedDate.isAfter(manifest.backupCreatedAt);

          return MapEntry(
            mission.id,
            MissionSyncState(
              missionId: mission.id,
              status: isModifiedLocally ? SyncStatus.localModifications : SyncStatus.upToDate,
              lastBackupDate: manifest.backupCreatedAt,
              remoteSizeBytes: manifest.fileSizeBytes,
              statusMessage: isModifiedLocally
                  ? 'Modifications locales depuis la dernière sauvegarde'
                  : 'Sauvegarde Cloud à jour (${(manifest.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} Mo)',
            ),
          );
        }
      } catch (e) {
        // En cas d'échec réseau / hors-ligne, ne pas réinitialiser l'état
        return MapEntry(
          mission.id,
          MissionSyncState(
            missionId: mission.id,
            status: SyncStatus.interrupted,
            statusMessage: 'Cloud temporairement inaccessible (Hors-ligne)',
          ),
        );
      }
    });

    final entries = await Future.wait(futures);
    final resultMap = Map<String, MissionSyncState>.fromEntries(entries);

    // Mettre à jour le cache persistant Hive
    final cacheBox = Hive.isBoxOpen('sync_cache')
        ? Hive.box('sync_cache')
        : await Hive.openBox('sync_cache');

    resultMap.forEach((missionId, state) {
      if (state.status == SyncStatus.upToDate ||
          state.status == SyncStatus.localModifications ||
          state.status == SyncStatus.neverBackedUp) {
        cacheBox.put(missionId, state.toJson());
      }
    });

    return resultMap;
  }

  @override
  Future<bool> backupSingleMission({
    required String missionId,
    required String matricule,
    void Function(double progress, String statusMessage)? onProgress,
  }) async {
    final accessToken = await authService.getValidAccessToken();
    final user = await authService.getSavedUserProfile();

    if (accessToken == null || user == null) {
      onProgress?.call(0, 'Erreur: Non connecté à Microsoft 365');
      return false;
    }

    final mission = HiveService.getMissionById(missionId);
    if (mission == null) {
      onProgress?.call(0, 'Erreur: Mission introuvable');
      return false;
    }

    onProgress?.call(0.05, 'Génération du bundle .inspec local en arrière-plan...');

    // 1. Appeler l'exportateur BackupService en mode silencieux (sans feuille de partage OS)
    final exportResult = await BackupService.exporterMission(
      missionId,
      openShareSheet: false,
    );
    if (!exportResult.success || exportResult.filePath == null) {
      onProgress?.call(0, 'Erreur d\'exportation: ${exportResult.message}');
      return false;
    }

    final localFile = File(exportResult.filePath!);
    if (!localFile.existsSync()) {
      onProgress?.call(0, 'Erreur: Fichier de sauvegarde introuvable sur le disque');
      return false;
    }

    final fileSize = await localFile.length();
    final fileBytes = await localFile.readAsBytes();
    final checksumHex = sha256.convert(fileBytes).toString();

    final remoteFolderPath = 'Apps/KES Inspection/Sauvegardes/${user.displayName}/Mission_${mission.nomClient}_$missionId';
    final remoteFileName = 'sauvegarde_${mission.nomClient}_${DateTime.now().millisecondsSinceEpoch}.inspec';

    // 2. Créer le dossier distant
    await storageService.ensureFolderExists(accessToken, remoteFolderPath);

    // 3. Téléverser par morceaux (Resumable Chunked Upload)
    final uploadSuccess = await storageService.uploadBackupFileChunked(
      accessToken: accessToken,
      file: localFile,
      remoteFolderPath: remoteFolderPath,
      remoteFileName: remoteFileName,
      onProgress: onProgress,
    );

    if (!uploadSuccess) {
      onProgress?.call(0, 'Échec du téléversement vers le Cloud Microsoft');
      return false;
    }

    // 4. Écrire le manifest.json de métadonnées
    final manifest = CloudBackupManifest(
      missionId: missionId,
      missionName: mission.nomClient,
      clientName: mission.nomClient,
      fileName: remoteFileName,
      fileSizeBytes: fileSize,
      sha256Checksum: checksumHex,
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

    // Nettoyage temporaire du fichier d'export local
    try {
      if (localFile.existsSync()) await localFile.delete();
    } catch (_) {}

    onProgress?.call(1.0, 'Sauvegarde terminée avec succès !');
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

    // Appeler l'importateur BackupService existant
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
