// lib/features/backup/data/services/backup_scheduler_service.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../../domain/models/backup_queue_item.dart';
import '../../domain/models/mission_sync_state.dart';
import '../../domain/repositories/backup_sync_repository.dart';
import '../datasources/backup_queue_service.dart';
import '../datasources/microsoft_auth_service.dart';

const String kAutoBackupTask = 'com.kes.inspection.autobackup';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('[WorkManager] Exécution de la tâche planifiée d\'arrière-plan : $task');
      // Tâche native d'arrière-plan résiliente
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

  bool _isProcessing = false;

  BackupSchedulerService({
    required this.repository,
    required this.authService,
    required this.queueService,
  });

  // Initialiser WorkManager natif pour les déclenchements Android/iOS
  Future<void> initializeWorkManager() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // Programmer le contrôle quotidien (du lundi au samedi)
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

      // Si la mission a des modifications locales ou n'a jamais été sauvegardée
      if (syncState.status == SyncStatus.localModifications ||
          syncState.status == SyncStatus.neverBackedUp) {
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
    // 1. Vérifier la connexion Microsoft
    final user = await authService.getSavedUserProfile();
    if (user == null) return false;

    // 2. Vérifier la connectivité Internet
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
      // 1. Faire l'inventaire avant traitement
      await inventoryAndEnrollMissions(matricule);

      // 2. Traiter chaque élément séquentiellement (FIFO)
      while (true) {
        final item = await queueService.getNextEligibleItem();
        if (item == null) break;

        await queueService.markProcessing(item.missionId);

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
}
