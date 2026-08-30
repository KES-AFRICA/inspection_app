import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:inspec_app/services/hive_service.dart';
import '../../domain/models/backup_cancel_token.dart';
import '../../domain/models/backup_job.dart';
import '../../domain/models/cloud_backup_manifest.dart';
import '../datasources/backup_job_store.dart';
import '../datasources/local_backup_store.dart';
import '../datasources/microsoft_auth_service.dart';
import '../datasources/microsoft_graph_storage_service.dart';

class BackupJobManager {
  final BackupJobStore jobStore;
  final LocalBackupStore localStore;
  final MicrosoftAuthService authService;
  final MicrosoftGraphStorageService storageService;

  final Map<String, BackupCancelToken> _cancelTokens = {};
  final Set<String> _processingMissionIds = {};
  final StreamController<Map<String, BackupJob>> _jobsController =
      StreamController<Map<String, BackupJob>>.broadcast();

  StreamSubscription? _connectivitySubscription;
  bool _isInitialized = false;

  BackupJobManager({
    BackupJobStore? jobStore,
    LocalBackupStore? localStore,
    MicrosoftAuthService? authService,
    MicrosoftGraphStorageService? storageService,
  })  : jobStore = jobStore ?? BackupJobStore(),
        localStore = localStore ?? LocalBackupStore(),
        authService = authService ?? MicrosoftAuthService(),
        storageService = storageService ?? MicrosoftGraphStorageService();

  Stream<Map<String, BackupJob>> get jobsStream => _jobsController.stream;

  /// Initialise le gestionnaire au démarrage de l'app (Restauration des jobs après redémarrage)
  Future<void> initialize(String matricule) async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Écouter les changements réseau pour auto-reprendre les sauvegardes suspendues
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline) {
        await resumeAllPendingOrWaitingJobs(matricule);
      } else {
        await _handleNetworkLoss();
      }
    });

    // Restaurer les jobs incomplets après redémarrage de l'application
    await _recoverIncompleteJobsOnAppStart(matricule);
  }

  /// Récupérer le job actif d'une mission
  Future<BackupJob?> getActiveJobForMission(String missionId) async {
    return await jobStore.getActiveJobForMission(missionId);
  }

  /// Démarrer une nouvelle sauvegarde de mission (ou reprendre si déjà active)
  Future<BackupJob> startBackup({
    required String missionId,
    required String matricule,
  }) async {
    // 1. Vérifier si un job est déjà actif pour cette mission (1 seul job actif max par mission)
    final existingJob = await jobStore.getActiveJobForMission(missionId);
    if (existingJob != null) {
      if (existingJob.isPaused || existingJob.isWaitingNetwork) {
        return resumeBackup(existingJob.id, matricule);
      }
      return existingJob; // Job déjà en cours
    }

    final mission = HiveService.getMissionById(missionId);
    if (mission == null) {
      throw Exception('Mission $missionId introuvable');
    }

    final jobId = 'job_${missionId}_${DateTime.now().millisecondsSinceEpoch}';
    final initialJob = BackupJob(
      id: jobId,
      missionId: missionId,
      matricule: matricule,
      status: BackupJobStatus.preparing,
      statusMessage: 'Création et scellage de la sauvegarde locale (Niveau 1)...',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _updateAndPublishJob(initialJob);

    // Démarrer l'exécution asynchrone du workflow
    unawaited(_executeBackupJobWorkflow(initialJob));

    return initialJob;
  }

  /// Exécution séquentielle du Workflow de Sauvegarde (Niveau 1 -> Niveau 2)
  Future<void> _executeBackupJobWorkflow(BackupJob initialJob) async {
    final jobId = initialJob.id;
    final missionId = initialJob.missionId;
    final matricule = initialJob.matricule;

    if (_processingMissionIds.contains(missionId)) {
      _cancelTokens[jobId]?.cancel('Remplacement par nouvelle exécution');
      _processingMissionIds.remove(missionId);
    }
    _processingMissionIds.add(missionId);

    final cancelToken = BackupCancelToken();
    _cancelTokens[jobId] = cancelToken;

    try {
      final mission = HiveService.getMissionById(missionId);
      if (mission == null) throw Exception('Mission introuvable');

      // NIVEAU 1 : Sauvegarde Locale Automatique sur disque
      var localItem = await localStore.getLatestLocalBackup(missionId);
      if (localItem == null || mission.updatedAt.isAfter(localItem.createdAt)) {
        localItem = await localStore.saveLocalBackup(missionId: missionId, matricule: matricule);
      }

      cancelToken.throwIfCancelled();

      if (localItem == null) {
        throw Exception('Échec de la génération de la sauvegarde locale Niveau 1');
      }

      final localFile = File(localItem.filePath);
      final fileSize = localItem.fileSizeBytes;

      var currentJob = initialJob.copyWith(
        status: BackupJobStatus.queued,
        localFilePath: localItem.filePath,
        localFileName: localItem.fileName,
        totalBytes: fileSize,
        sha256Checksum: localItem.sha256Checksum,
        statusMessage: 'En file d\'attente cloud...',
      );
      await _updateAndPublishJob(currentJob);

      // NIVEAU 2 : Téléversement Cloud (Microsoft Graph)
      final user = await authService.getSavedUserProfile();
      var accessToken = await authService.getValidAccessToken();

      // Si hors ligne ou non connecté MSAL
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none) || user == null || accessToken == null) {
        currentJob = currentJob.copyWith(
          status: BackupJobStatus.waitingForNetwork,
          statusMessage: 'Sauvegardée localement • En attente de connexion Cloud',
        );
        await _updateAndPublishJob(currentJob);
        return;
      }

      // Créer la session d'upload distante
      final remoteFolderPath = 'Apps/KES Inspection/Sauvegardes/${user.displayName}/Mission_${mission.nomClient}_$missionId';
      final remoteFileName = 'sauvegarde_${mission.nomClient}_${DateTime.now().millisecondsSinceEpoch}.inspec';

      // Déduplication SHA-256
      final remoteManifest = await storageService.fetchRemoteManifest(
        accessToken: accessToken,
        remoteFolderPath: remoteFolderPath,
      );

      if (remoteManifest != null && remoteManifest.sha256Checksum == localItem.sha256Checksum) {
        currentJob = currentJob.copyWith(
          status: BackupJobStatus.completed,
          progress: 1.0,
          uploadedBytes: fileSize,
          completedAt: DateTime.now(),
          statusMessage: 'Sauvegarde Cloud à jour (Déduplication No-Op)',
        );
        await _updateAndPublishJob(currentJob);
        await localStore.markSyncedToCloud(missionId, localItem.sha256Checksum);
        return;
      }

      await storageService.ensureFolderExists(accessToken, remoteFolderPath);
      cancelToken.throwIfCancelled();

      // Obtenir ou réutiliser l'uploadSessionUrl
      String? uploadUrl = currentJob.uploadSessionUrl;
      int startByte = 0;

      if (uploadUrl != null) {
        final sessionState = await storageService.getUploadSessionState(uploadUrl);
        if (sessionState != null) {
          startByte = sessionState.nextExpectedByte;
        } else {
          uploadUrl = null; // Session expirée
        }
      }

      if (uploadUrl == null) {
        final sessionInfo = await storageService.createUploadSession(
          accessToken: accessToken,
          remoteFolderPath: remoteFolderPath,
          remoteFileName: remoteFileName,
        );
        if (sessionInfo == null) {
          throw Exception('Impossible de créer la session d\'upload Microsoft Graph');
        }
        uploadUrl = sessionInfo.uploadUrl;
        currentJob = currentJob.copyWith(
          uploadSessionUrl: uploadUrl,
          sessionExpiration: sessionInfo.expirationDateTime,
        );
        await _updateAndPublishJob(currentJob);
      }

      currentJob = currentJob.copyWith(
        status: BackupJobStatus.uploading,
        uploadedBytes: startByte,
        progress: fileSize > 0 ? (startByte / fileSize).clamp(0.0, 1.0) : 0.0,
        statusMessage: 'Téléversement vers le Cloud Microsoft...',
      );
      await _updateAndPublishJob(currentJob);

      // Lancer le transfert de chunks resumable avec CancelToken
      final uploadSuccess = await storageService.uploadBackupFileChunkedResumable(
        accessToken: accessToken,
        file: localFile,
        remoteFolderPath: remoteFolderPath,
        remoteFileName: remoteFileName,
        uploadUrl: uploadUrl,
        startFromByte: startByte,
        cancelToken: cancelToken,
        onTokenExpired: () async => await authService.getValidAccessToken(),
        onProgressBytes: (uploadedBytes, totalBytes, message) async {
          final progress = totalBytes > 0 ? (uploadedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
          currentJob = currentJob.copyWith(
            uploadedBytes: uploadedBytes,
            totalBytes: totalBytes,
            progress: progress,
            statusMessage: message,
          );
          await _updateAndPublishJob(currentJob);
        },
      );

      if (!uploadSuccess) {
        currentJob = currentJob.copyWith(
          status: BackupJobStatus.retrying,
          statusMessage: 'Échec de transfert. Nouvelle tentative automatique...',
          retryCount: currentJob.retryCount + 1,
        );
        await _updateAndPublishJob(currentJob);
        return;
      }

      // Écrire le manifest.json distant
      final manifest = CloudBackupManifest(
        missionId: missionId,
        missionName: mission.nomClient,
        clientName: mission.nomClient,
        fileName: remoteFileName,
        fileSizeBytes: fileSize,
        sha256Checksum: localItem.sha256Checksum,
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

      await localStore.markSyncedToCloud(missionId, localItem.sha256Checksum);

      currentJob = currentJob.copyWith(
        status: BackupJobStatus.completed,
        progress: 1.0,
        uploadedBytes: fileSize,
        completedAt: DateTime.now(),
        statusMessage: 'Sauvegarde Cloud & Locale terminée avec succès !',
      );
      await _updateAndPublishJob(currentJob);
    } on BackupCancelledException catch (e) {
      if (kDebugMode) print('🛑 Job [$jobId] interrompu / annulé: ${e.message}');
      final job = await jobStore.getJob(jobId);
      if (job != null &&
          job.status != BackupJobStatus.paused &&
          job.status != BackupJobStatus.waitingForNetwork &&
          job.status != BackupJobStatus.cancelled) {
        final cancelledJob = job.copyWith(
          status: BackupJobStatus.cancelled,
          statusMessage: 'Sauvegarde annulée',
          cancelledAt: DateTime.now(),
        );
        await _updateAndPublishJob(cancelledJob);
      }
    } catch (e, st) {
      if (kDebugMode) print('❌ Exception workflow BackupJob [$jobId]: $e\n$st');
      final job = await jobStore.getJob(jobId);
      if (job != null) {
        final failedJob = job.copyWith(
          status: BackupJobStatus.failed,
          lastError: e.toString(),
          statusMessage: 'Échec de la sauvegarde: $e',
        );
        await _updateAndPublishJob(failedJob);
      }
    } finally {
      _processingMissionIds.remove(missionId);
      _cancelTokens.remove(jobId);
    }
  }

  /// Mettre en pause une sauvegarde active par missionId
  Future<void> pauseBackupForMission(String missionId) async {
    final job = await jobStore.getActiveJobForMission(missionId);
    if (job != null) {
      await pauseBackup(job.id);
    }
  }

  /// Reprendre une sauvegarde mise en pause ou suspendue par missionId
  Future<BackupJob> resumeBackupForMission(String missionId, String matricule) async {
    final job = await jobStore.getActiveJobForMission(missionId);
    if (job != null) {
      return await resumeBackup(job.id, matricule);
    }
    return await startBackup(missionId: missionId, matricule: matricule);
  }

  /// Annuler définitivement une sauvegarde par missionId
  Future<void> cancelBackupForMission(String missionId) async {
    final job = await jobStore.getActiveJobForMission(missionId);
    if (job != null) {
      await cancelBackup(job.id);
    }
  }

  /// Mettre en pause une sauvegarde active
  Future<void> pauseBackup(String jobId) async {
    final token = _cancelTokens[jobId];
    token?.cancel('Mise en pause par l\'inspecteur');

    final job = await jobStore.getJob(jobId);
    if (job != null) {
      _processingMissionIds.remove(job.missionId);
      _cancelTokens.remove(jobId);
      final pausedJob = job.copyWith(
        status: BackupJobStatus.paused,
        pausedAt: DateTime.now(),
        statusMessage: 'Sauvegarde en pause (${(job.progress * 100).toInt()}%)',
      );
      await _updateAndPublishJob(pausedJob);
    }
  }

  /// Reprendre une sauvegarde mise en pause ou suspendue
  Future<BackupJob> resumeBackup(String jobId, String matricule) async {
    var job = await jobStore.getJob(jobId);
    if (job == null) {
      throw Exception('Job $jobId introuvable');
    }

    _processingMissionIds.remove(job.missionId);
    _cancelTokens.remove(jobId);

    if (job.status == BackupJobStatus.uploading) return job;

    job = job.copyWith(
      status: BackupJobStatus.preparing,
      statusMessage: 'Vérification de la session serveur pour reprise...',
      updatedAt: DateTime.now(),
    );
    await _updateAndPublishJob(job);

    unawaited(_executeBackupJobWorkflow(job));
    return job;
  }

  /// Annuler définitivement une sauvegarde (Annulation filaire + DELETE uploadSession Graph)
  Future<void> cancelBackup(String jobId) async {
    final token = _cancelTokens[jobId];
    token?.cancel('Annulation par l\'inspecteur');

    final job = await jobStore.getJob(jobId);
    if (job != null) {
      _processingMissionIds.remove(job.missionId);
      _cancelTokens.remove(jobId);
      // Si une URL de session Graph existe, envoyer la requête DELETE au serveur Microsoft
      if (job.uploadSessionUrl != null) {
        unawaited(storageService.cancelUploadSession(job.uploadSessionUrl!));
      }

      final cancelledJob = job.copyWith(
        status: BackupJobStatus.cancelled,
        cancelledAt: DateTime.now(),
        statusMessage: 'Sauvegarde annulée',
      );
      await _updateAndPublishJob(cancelledJob);
    }
  }

  /// Gérer la perte de connexion réseau (waitingForNetwork)
  Future<void> _handleNetworkLoss() async {
    final incomplete = await jobStore.getIncompleteJobs();
    for (final job in incomplete) {
      if (job.status == BackupJobStatus.uploading || job.status == BackupJobStatus.queued) {
        final token = _cancelTokens[job.id];
        token?.cancel('Connexion réseau perdue');

        final networkWaitingJob = job.copyWith(
          status: BackupJobStatus.waitingForNetwork,
          statusMessage: 'Connexion interrompue • La sauvegarde reprendra automatiquement',
        );
        await _updateAndPublishJob(networkWaitingJob);
      }
    }
  }

  /// Reprendre automatiquement toutes les sauvegardes en attente de réseau dès le rétablissement d'Internet
  Future<void> resumeAllPendingOrWaitingJobs(String matricule) async {
    final incomplete = await jobStore.getIncompleteJobs();
    for (final job in incomplete) {
      if (job.status == BackupJobStatus.waitingForNetwork || job.status == BackupJobStatus.retrying) {
        unawaited(resumeBackup(job.id, matricule));
      }
    }
  }

  /// Restauration au démarrage de l'application après redémarrage du téléphone / app
  Future<void> _recoverIncompleteJobsOnAppStart(String matricule) async {
    final incomplete = await jobStore.getIncompleteJobs();
    if (incomplete.isEmpty) return;

    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = !connectivity.contains(ConnectivityResult.none);

    for (final job in incomplete) {
      if (isOnline && (job.status == BackupJobStatus.uploading || job.status == BackupJobStatus.waitingForNetwork)) {
        unawaited(resumeBackup(job.id, matricule));
      } else if (!isOnline) {
        final waitingJob = job.copyWith(
          status: BackupJobStatus.waitingForNetwork,
          statusMessage: 'Connexion interrompue • Reprise automatique dès le retour du réseau',
        );
        await _updateAndPublishJob(waitingJob);
      }
    }
  }

  /// Publier la mise à jour d'un job vers les écouteurs de la boîte Hive et des providers Riverpod
  Future<void> _updateAndPublishJob(BackupJob job) async {
    await jobStore.saveJob(job);
    final allIncomplete = await jobStore.getIncompleteJobs();
    final map = <String, BackupJob>{};
    for (final j in allIncomplete) {
      map[j.missionId] = j;
    }
    _jobsController.add(map);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _jobsController.close();
  }
}
