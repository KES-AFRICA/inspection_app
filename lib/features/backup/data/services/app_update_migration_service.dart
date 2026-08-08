// lib/features/backup/data/services/app_update_migration_service.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'backup_scheduler_service.dart';

class AppUpdateMigrationService {
  static const String currentAppVersion = '1.0.0+1'; // Version actuelle de l'application
  static const String _boxName = 'backup_preferences';

  final BackupSchedulerService schedulerService;

  AppUpdateMigrationService({required this.schedulerService});

  Future<Box> _getBox() async {
    return Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
  }

  // Détecter si l'application vient d'être mise à jour et déclencher la sauvegarde initiale post-update
  Future<void> checkAndTriggerPostUpdateMigration(String matricule) async {
    final box = await _getBox();
    final lastMigration = box.get('lastMigrationVersion') as String?;

    if (lastMigration != currentAppVersion) {
      debugPrint('[AppUpdateMigrationService] Nouvelle version d\'app détectée ($currentAppVersion). Déclenchement de la sauvegarde initiale post-mise-à-jour...');

      // 1. Inventaire et enrôlement immédiat des missions modifiées / non-sauvegardées
      final enrolled = await schedulerService.inventoryAndEnrollMissions(matricule);

      if (enrolled > 0) {
        // 2. Exécution de la file de sauvegarde en arrière-plan sans attendre 17h10
        await schedulerService.processQueue(matricule);
      }

      // 3. Enregistrer que la migration de cette version a été exécutée
      await box.put('lastMigrationVersion', currentAppVersion);
      debugPrint('[AppUpdateMigrationService] Migration post-mise-à-jour $currentAppVersion finalisée avec succès.');
    }
  }
}
