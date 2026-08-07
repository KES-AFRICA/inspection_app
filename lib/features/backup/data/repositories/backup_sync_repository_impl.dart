// lib/features/backup/data/repositories/backup_sync_repository_impl.dart

import 'dart:io';
import 'package:crypto/crypto.dart';
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
    final token = await authService.getValidAccessToken();
    if (token != null) {
      return await authService.getSavedUserProfile();
    }
    return null;
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
  Future<Map<String, MissionSyncState>> checkSyncStateForAllMissions(String matricule) async {
    final result = <String, MissionSyncState>{};
    final missions = HiveService.getMissionsByMatricule(matricule);
    final user = await authService.getSavedUserProfile();
    final accessToken = await authService.getValidAccessToken();

    for (final mission in missions) {
      if (accessToken == null || user == null) {
        result[mission.id] = MissionSyncState(
          missionId: mission.id,
          status: SyncStatus.neverBackedUp,
          statusMessage: 'Non connecté à Microsoft Cloud',
        );
        continue;
      }

      final remoteFolderPath = 'Apps/KES Inspection/Sauvegardes/${user.displayName}/Mission_${mission.nomClient}_${mission.id}';
      final manifest = await storageService.fetchRemoteManifest(
        accessToken: accessToken,
        remoteFolderPath: remoteFolderPath,
      );

      if (manifest == null) {
        result[mission.id] = MissionSyncState(
          missionId: mission.id,
          status: SyncStatus.neverBackedUp,
          statusMessage: 'Jamais sauvegardée sur le Cloud',
        );
      } else {
        // Détecter si la mission locale a été modifiée après la date de sauvegarde
        final lastModifiedDate = mission.updatedAt;
        final isModifiedLocally = lastModifiedDate.isAfter(manifest.backupCreatedAt);

        result[mission.id] = MissionSyncState(
          missionId: mission.id,
          status: isModifiedLocally ? SyncStatus.localModifications : SyncStatus.upToDate,
          lastBackupDate: manifest.backupCreatedAt,
          remoteSizeBytes: manifest.fileSizeBytes,
          statusMessage: isModifiedLocally
              ? 'Modifications locales depuis la dernière sauvegarde'
              : 'Sauvegarde Cloud à jour (${(manifest.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} Mo)',
        );
      }
    }

    return result;
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
