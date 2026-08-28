// lib/features/backup/data/datasources/backup_job_store.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/backup_job.dart';

/// Gestionnaire de stockage persistant Hive pour la machine à états BackupJob
class BackupJobStore {
  static const String _boxName = 'backup_jobs_store';

  Future<Box> _getBox() async {
    return Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
  }

  /// Sauvegarde ou met à jour un BackupJob dans Hive
  Future<void> saveJob(BackupJob job) async {
    try {
      final box = await _getBox();
      await box.put(job.id, job.toJson());
      await box.put('active_${job.missionId}', job.id);

      if (kDebugMode) {
        print('💾 BackupJob [${job.id}] persistant sauvegardé: ${job.status.name} (${(job.progress * 100).toInt()}%)');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur saveJob Hive: $e');
    }
  }

  /// Récupère un BackupJob par son ID unique
  Future<BackupJob?> getJob(String jobId) async {
    try {
      final box = await _getBox();
      final raw = box.get(jobId);
      if (raw != null) {
        final json = Map<String, dynamic>.from(raw as Map);
        return BackupJob.fromJson(json);
      }
    } catch (_) {}
    return null;
  }

  /// Récupère le BackupJob actif pour une mission
  Future<BackupJob?> getActiveJobForMission(String missionId) async {
    try {
      final box = await _getBox();
      final activeId = box.get('active_$missionId') as String?;
      if (activeId != null) {
        final job = await getJob(activeId);
        if (job != null && !job.isFinished) {
          return job;
        }
      }

      // Recherche de secours parmi tous les enregistrements
      for (final raw in box.values) {
        if (raw is Map) {
          try {
            final json = Map<String, dynamic>.from(raw);
            final job = BackupJob.fromJson(json);
            if (job.missionId == missionId && !job.isFinished) {
              return job;
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    return null;
  }

  /// Récupère la liste de tous les BackupJobs incomplets (à reprendre au démarrage)
  Future<List<BackupJob>> getIncompleteJobs() async {
    final jobs = <BackupJob>[];
    try {
      final box = await _getBox();
      for (final key in box.keys) {
        if (!key.toString().startsWith('active_')) {
          final raw = box.get(key);
          if (raw is Map) {
            try {
              final json = Map<String, dynamic>.from(raw);
              final job = BackupJob.fromJson(json);
              if (!job.isFinished) {
                jobs.add(job);
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    return jobs;
  }

  /// Supprime un BackupJob
  Future<void> deleteJob(String jobId) async {
    try {
      final box = await _getBox();
      final job = await getJob(jobId);
      if (job != null) {
        await box.delete('active_${job.missionId}');
      }
      await box.delete(jobId);
    } catch (_) {}
  }
}
