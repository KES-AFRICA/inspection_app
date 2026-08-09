// lib/features/backup/data/services/backup_orchestrator.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/backup_sync_repository.dart';
import '../datasources/backup_queue_service.dart';
import '../datasources/microsoft_auth_service.dart';
import 'backup_scheduler_service.dart';
import 'app_update_migration_service.dart';

enum BackupEngineStatus {
  idle,
  checking,
  syncing,
  completed,
  offline,
  error,
}

class BackupOrchestratorState {
  final BackupEngineStatus status;
  final int totalMissions;
  final int completedMissions;
  final String? currentMissionName;
  final double currentProgress;
  final String? statusMessage;

  const BackupOrchestratorState({
    this.status = BackupEngineStatus.idle,
    this.totalMissions = 0,
    this.completedMissions = 0,
    this.currentMissionName,
    this.currentProgress = 0.0,
    this.statusMessage,
  });

  bool get isActive => status == BackupEngineStatus.checking || status == BackupEngineStatus.syncing;
}

typedef BackupMissionDelegate = Future<bool> Function({
  required String missionId,
  required String matricule,
  required void Function(double progress, String message) onProgress,
});

class BackupOrchestrator {
  final BackupSyncRepository repository;
  final MicrosoftAuthService authService;
  final BackupQueueService queueService;
  final BackupSchedulerService schedulerService;
  final AppUpdateMigrationService migrationService;
  final BackupMissionDelegate? backupDelegate;

  final Set<String> _syncingMissionIds = {};
  final _stateController = StreamController<BackupOrchestratorState>.broadcast();

  BackupOrchestratorState _currentState = const BackupOrchestratorState();

  BackupOrchestrator({
    required this.repository,
    required this.authService,
    required this.queueService,
    required this.schedulerService,
    required this.migrationService,
    this.backupDelegate,
  });

  StreamSubscription? _connectivitySubscription;

  Stream<BackupOrchestratorState> get stateStream => _stateController.stream;
  BackupOrchestratorState get currentState => _currentState;

  void _updateState(BackupOrchestratorState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  // Initialiser le moteur d'auto-sync au démarrage de l'app (main.dart)
  Future<void> initAutoSyncEngine(String matricule) async {
    // 1. Écouter la connectivité réseau pour auto-reprendre les sauvegardes si hors-ligne
    _connectivitySubscription ??= Connectivity().onConnectivityChanged.listen((results) async {
      if (!results.contains(ConnectivityResult.none)) {
        // Réseau rétabli -> déclencher immédiatement le rattrapage s'il y a des missions en attente
        await runOrchestration(matricule);
      }
    });

    // 2. Déclencher immédiatement la vérification et sauvegarde de rattrapage
    await runOrchestration(matricule);
  }

  // Déclencher immédiatement le rattrapage après une connexion MSAL réussie
  Future<void> triggerCatchUpSyncIfPending(String matricule) async {
    await runOrchestration(matricule);
  }

  // Lancer l'orchestration complète (migration post-update + traitement de la file)
  Future<void> runOrchestration(String matricule) async {
    if (_currentState.isActive) return;

    _updateState(const BackupOrchestratorState(
      status: BackupEngineStatus.checking,
      statusMessage: 'Vérification de l\'état des sauvegardes...',
    ));

    try {
      // 1. Détecter et exécuter la migration post-mise-à-jour si nécessaire
      await migrationService.checkAndTriggerPostUpdateMigration(matricule);

      // 2. Récupérer la file d'attente
      final queue = await queueService.getQueue();
      if (queue.isEmpty) {
        _updateState(const BackupOrchestratorState(
          status: BackupEngineStatus.idle,
          statusMessage: 'Toutes les missions sont à jour',
        ));
        return;
      }

      final total = queue.length;
      int completed = 0;

      for (int i = 0; i < total; i++) {
        final item = queue[i];

        // Éviter le doublonnage de transfert
        if (_syncingMissionIds.contains(item.missionId)) continue;
        _syncingMissionIds.add(item.missionId);

        _updateState(BackupOrchestratorState(
          status: BackupEngineStatus.syncing,
          totalMissions: total,
          completedMissions: completed,
          currentMissionName: 'Mission ${item.missionId}',
          currentProgress: 0.05,
          statusMessage: 'Sauvegarde de la mission ${i + 1}/$total...',
        ));

        void onProgress(double progress, String message) {
          _updateState(BackupOrchestratorState(
            status: BackupEngineStatus.syncing,
            totalMissions: total,
            completedMissions: completed,
            currentMissionName: 'Mission ${item.missionId}',
            currentProgress: progress,
            statusMessage: message,
          ));
        }

        final success = backupDelegate != null
            ? await backupDelegate!(
                missionId: item.missionId,
                matricule: item.matricule,
                onProgress: onProgress,
              )
            : await repository.backupSingleMission(
                missionId: item.missionId,
                matricule: item.matricule,
                onProgress: onProgress,
              );

        _syncingMissionIds.remove(item.missionId);

        if (success) {
          completed++;
          await queueService.removeFromQueue(item.missionId);
        } else {
          await queueService.markFailed(item.missionId, 'Échec de transfert');
        }
      }

      _updateState(BackupOrchestratorState(
        status: BackupEngineStatus.completed,
        totalMissions: total,
        completedMissions: completed,
        statusMessage: '$completed/$total missions sauvegardées sur le Cloud',
      ));

      // Revenir à l'état idle après 4 secondes
      Future.delayed(const Duration(seconds: 4), () {
        if (_currentState.status == BackupEngineStatus.completed) {
          _updateState(const BackupOrchestratorState(status: BackupEngineStatus.idle));
        }
      });
    } catch (e) {
      debugPrint('[BackupOrchestrator] Erreur orchestration: $e');
      _updateState(BackupOrchestratorState(
        status: BackupEngineStatus.error,
        statusMessage: 'Erreur de sauvegarde: $e',
      ));
    }
  }

  void dispose() {
    _stateController.close();
  }
}
