// lib/features/backup/data/datasources/backup_queue_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/backup_queue_item.dart';

class BackupQueueService {
  static const String _boxName = 'backup_queue';

  Future<Box> _getBox() async {
    return Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
  }

  // Obtenir toute la file d'attente
  Future<List<BackupQueueItem>> getQueue() async {
    final box = await _getBox();
    final items = <BackupQueueItem>[];
    for (final raw in box.values) {
      if (raw != null) {
        try {
          final json = Map<String, dynamic>.from(raw as Map);
          items.add(BackupQueueItem.fromJson(json));
        } catch (_) {}
      }
    }
    // Trier FIFO : les plus anciennes en premier
    items.sort((a, b) => a.addedAt.compareTo(b.addedAt));
    return items;
  }

  // Ajouter ou mettre à jour un élément dans la file
  Future<void> enqueueOrUpdate(BackupQueueItem item) async {
    final box = await _getBox();
    await box.put(item.missionId, item.toJson());
  }

  // Supprimer un élément de la file (ex: sauvegarde terminée avec succès)
  Future<void> removeFromQueue(String missionId) async {
    final box = await _getBox();
    await box.delete(missionId);
  }

  // Obtenir le prochain élément éligible pour la sauvegarde (non-en cours, non-en pause, délai backoff dépassé)
  Future<BackupQueueItem?> getNextEligibleItem() async {
    final items = await getQueue();
    final now = DateTime.now();

    for (final item in items) {
      if (item.status == BackupQueueStatus.paused) continue;
      if (item.status == BackupQueueStatus.processing) continue;

      if (item.status == BackupQueueStatus.failed) {
        // Trop de tentatives (max 5) -> ignorer temporairement
        if (item.attemptCount >= 5) continue;

        // Calcul du backoff exponentiel : 5 min * 2^(tentative-1)
        if (item.nextRetryAt != null && now.isBefore(item.nextRetryAt!)) {
          continue;
        }
      }

      return item;
    }

    return null;
  }

  // Marquer un élément comme en cours de traitement
  Future<void> markProcessing(String missionId) async {
    final box = await _getBox();
    final raw = box.get(missionId);
    if (raw != null) {
      final json = Map<String, dynamic>.from(raw as Map);
      final item = BackupQueueItem.fromJson(json).copyWith(
        status: BackupQueueStatus.processing,
      );
      await box.put(missionId, item.toJson());
    }
  }

  // Marquer un échec avec calcul du backoff exponentiel
  Future<void> markFailed(String missionId, String errorMessage) async {
    final box = await _getBox();
    final raw = box.get(missionId);
    if (raw != null) {
      final json = Map<String, dynamic>.from(raw as Map);
      final item = BackupQueueItem.fromJson(json);
      final newAttempt = item.attemptCount + 1;

      // Calcul du délai exponentiel : 5 min * 2^(tentative - 1)
      final backoffMinutes = 5 * (1 << (newAttempt - 1));
      final nextRetry = DateTime.now().add(Duration(minutes: backoffMinutes));

      final updated = item.copyWith(
        status: BackupQueueStatus.failed,
        attemptCount: newAttempt,
        nextRetryAt: nextRetry,
        lastError: errorMessage,
      );
      await box.put(missionId, updated.toJson());
    }
  }

  // Mettre une mission en pause ou la reprendre
  Future<void> setMissionPaused(String missionId, String matricule, bool isPaused) async {
    final box = await _getBox();
    final raw = box.get(missionId);
    if (raw != null) {
      final json = Map<String, dynamic>.from(raw as Map);
      final item = BackupQueueItem.fromJson(json).copyWith(
        status: isPaused ? BackupQueueStatus.paused : BackupQueueStatus.pending,
      );
      await box.put(missionId, item.toJson());
    } else if (isPaused) {
      final item = BackupQueueItem(
        missionId: missionId,
        matricule: matricule,
        status: BackupQueueStatus.paused,
        addedAt: DateTime.now(),
      );
      await box.put(missionId, item.toJson());
    }
  }

  // Purger la file
  Future<void> clearQueue() async {
    final box = await _getBox();
    await box.clear();
  }
}
