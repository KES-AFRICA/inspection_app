// lib/features/backup/data/services/msal_recommendation_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/backup_preferences.dart';

class MsalRecommendationService {
  static const String _boxName = 'backup_preferences';
  static const String _prefKey = 'prefs';

  Future<Box> _getBox() async {
    return Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
  }

  Future<BackupPreferences> getPreferences() async {
    final box = await _getBox();
    final raw = box.get(_prefKey);
    if (raw != null) {
      try {
        final json = Map<String, dynamic>.from(raw as Map);
        return BackupPreferences.fromJson(json);
      } catch (_) {}
    }
    return const BackupPreferences();
  }

  Future<void> savePreferences(BackupPreferences prefs) async {
    final box = await _getBox();
    await box.put(_prefKey, prefs.toJson());
  }

  // Déterminer intelligemment si la recommandation MSAL doit être affichée (anti-harcèlement)
  Future<bool> shouldShowRecommendation(bool isConnectedToMicrosoft) async {
    if (isConnectedToMicrosoft) return false;

    final prefs = await getPreferences();
    final now = DateTime.now();

    // Si rejeté plus de 5 fois -> ne plus harceler
    if (prefs.recommendationDismissCount >= 5) return false;

    if (prefs.recommendationLastShown != null) {
      // Attendre au moins 3 jours entre 2 affichages de recommandation
      final minIntervalDays = 3 * (prefs.recommendationDismissCount + 1);
      final nextAllowedDate = prefs.recommendationLastShown!.add(Duration(days: minIntervalDays));
      if (now.isBefore(nextAllowedDate)) {
        return false;
      }
    }

    return true;
  }

  // Enregistrer le rejet par l'utilisateur de la recommandation
  Future<void> dismissRecommendation() async {
    final prefs = await getPreferences();
    final updated = prefs.copyWith(
      recommendationLastShown: DateTime.now(),
      recommendationDismissCount: prefs.recommendationDismissCount + 1,
    );
    await savePreferences(updated);
  }
}
