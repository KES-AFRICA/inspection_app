// lib/features/backup/data/services/backup_scheduler_service.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../../domain/models/backup_queue_item.dart';
import '../../domain/models/mission_sync_state.dart';
import '../../domain/repositories/backup_sync_repository.dart';
import '../datasources/backup_queue_service.dart';
import '../datasources/local_backup_store.dart';
import '../datasources/microsoft_auth_service.dart';
import 'mission_activity_tracker.dart';

const String kAutoBackupTask = 'com.kes.inspection.autobackup';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('[WorkManager] Exécution de la tâche planifiée d\'arrière-plan : $task');
      return true;
    } catch (e) {
      debugPrint('[WorkManager] Erreur tâche d\'arrière-plan: $e');
      return false;
    }
  });
}

class BackupSchedulerService {
  final BackupSyncRepository repository;
  final MicrosoftAuthService authService;
  final BackupQueueService queueService;
  final LocalBackupStore localStore;

  bool _isProcessing = false;
  Timer? _daily17h30Timer;

  BackupSchedulerService({
    required this.repository,
    required this.authService,
    required this.queueService,
    LocalBackupStore? localStore,
  }) : localStore = localStore ?? LocalBackupStore();

  /// Initialiser le WorkManager natif et programmer la surveillance quotidienne de 17h30
  Future<void> initializeWorkManager(String matricule) async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      await Workmanager().registerPeriodicTask(
        '1',
        kAutoBackupTask,
        frequency: const Duration(hours: 24),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );
    } catch (e) {
      debugPrint('[WorkManager] Initialisation ignorée sur cette plateforme : $e');
    }

    _scheduleDaily17h30Timer(matricule);
  }

  /// Déclencher la planification du minuteur de 17h30
  void _scheduleDaily17h30Timer(String matricule) {
    _daily17h30Timer?.cancel();
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 17, 30);
    if (now.isAfter(scheduledTime)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    final duration = scheduledTime.difference(now);

    _daily17h30Timer = Timer(duration, () async {
      await triggerDailyAutoBackup(matricule);
      _scheduleDaily17h30Timer(matricule); // Re-planifier pour le lendemain
    });
  }

  /// Exécution de la Sauvegarde Automatique Quotidienne de 17h30
  /// 1. Détecte les missions modifiées aujourd'hui
  /// 2. Niveau 1 : Génère et scelle la sauvegarde locale .inspec
  /// 3. Niveau 2 : Enrôle dans la file cloud pour upload
  Future<int> triggerDailyAutoBackup(String matricule) async {
    final modifiedMissions = await MissionActivityTracker.getMissionsModifiedToday();
    if (modifiedMissions.isEmpty) {
      if (kDebugMode) {
        print('ℹ️ AutoBackup 17h30 : Aucune mission modifiée aujourd\'hui.');
      }
      return 0;
    }

    int backedUpLocallyCount = 0;

    for (final missionId in modifiedMissions) {
      // 1. Sauvegarde Locale Absolue (Niveau 1 - Offline First)
      final localItem = await localStore.saveLocalBackup(
        missionId: missionId,
        matricule: matricule,
      );

      if (localItem != null) {
        backedUpLocallyCount++;
        // 2. Enrôler dans la file Cloud pour la synchronisation distante (Niveau 2)
        await queueService.enqueueOrUpdate(
          BackupQueueItem(
            missionId: missionId,
            matricule: matricule,
            status: BackupQueueStatus.pending,
            addedAt: DateTime.now(),
          ),
        );
      }
    }

    // Tenter de dépiler et d'envoyer vers le Cloud immédiatement si le réseau est actif
    unawaited(processQueue(matricule));

    return backedUpLocallyCount;
  }

  // Effectuer l'inventaire des missions et enrôler les missions modifiées/non-sauvegardées
  Future<int> inventoryAndEnrollMissions(String matricule) async {
    final user = await authService.getSavedUserProfile();
    if (user == null) return 0;

    final syncStates = await repository.checkSyncStateForAllMissions(matricule);
    int enrolledCount = 0;

    for (final entry in syncStates.entries) {
      final missionId = entry.key;
      final syncState = entry.value;

      if (syncState.status == SyncStatus.localModifications ||
          syncState.status == SyncStatus.neverBackedUp ||
          syncState.status == SyncStatus.localOnly) {
        await queueService.enqueueOrUpdate(
          BackupQueueItem(
            missionId: missionId,
            matricule: matricule,
            status: BackupQueueStatus.pending,
            addedAt: DateTime.now(),
          ),
        );
        enrolledCount++;
      }
    }

    return enrolledCount;
  }

  // Vérifications Pre-Flight (MSAL connecté, Réseau disponible, Pas de blocage)
  Future<bool> checkPreFlightConditions() async {
    final user = await authService.getSavedUserProfile();
    if (user == null) return false;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      return false;
    }

    return true;
  }

  // Exécuter la file de sauvegarde de façon séquentielle (FIFO)
  Future<void> processQueue(
    String matricule, {
    void Function(String missionId, double progress, String message)? onProgress,
  }) async {
    if (_isProcessing) return;

    final isEligible = await checkPreFlightConditions();
    if (!isEligible) return;

    _isProcessing = true;

    try {
      await inventoryAndEnrollMissions(matricule);

      while (true) {
        final item = await queueService.getNextEligibleItem();
        if (item == null) break;

        await queueService.markProcessing(item.missionId);

        // 1. S'assurer que le snapshot local Niveau 1 existe avant l'upload Cloud
        final latestLocal = await localStore.getLatestLocalBackup(item.missionId);
        if (latestLocal == null) {
          await localStore.saveLocalBackup(missionId: item.missionId, matricule: matricule);
        }

        // 2. Transférer vers le Cloud (Niveau 2)
        final success = await repository.backupSingleMission(
          missionId: item.missionId,
          matricule: matricule,
          onProgress: (progress, message) {
            if (onProgress != null) {
              onProgress(item.missionId, progress, message);
            }
          },
        );

        if (success) {
          await queueService.removeFromQueue(item.missionId);
          await MissionActivityTracker.clearActivityForMission(item.missionId);
        } else {
          await queueService.markFailed(
            item.missionId,
            'Échec du transfert OneDrive. Nouvelle tentative programmée.',
          );
        }
      }
    } catch (e) {
      debugPrint('[BackupSchedulerService] Erreur lors du traitement de la file: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void dispose() {
    _daily17h30Timer?.cancel();
  }
}
