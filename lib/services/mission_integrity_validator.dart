import 'package:flutter/foundation.dart';
import 'package:inspec_app/services/sequence_progress_service.dart';

/// Service de validation et d'assainissement non destructif des données de mission.
/// Garantit qu'aucun état incohérent (ex: currentStep négatif ou hors-bornes) ne provoque de crash UI.
class MissionIntegrityValidator {
  /// Valide et assainit la progression d'une mission.
  static Future<void> sanitizeSequenceProgress(String missionId) async {
    try {
      final progress = await SequenceProgressService.getProgress(missionId);
      final rawStep = progress['currentStep'] as int?;
      if (rawStep == null || rawStep < 0 || rawStep >= 6) {
        if (kDebugMode) {
          print('🛡️ [MissionIntegrityValidator] Normalisation de currentStep ($rawStep -> 0) pour la mission $missionId');
        }
        await SequenceProgressService.saveCurrentStep(missionId, 0);
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [MissionIntegrityValidator] Erreur lors de la vérification de l\'intégrité: $e');
      }
    }
  }
}
