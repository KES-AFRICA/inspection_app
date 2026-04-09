import 'package:hive/hive.dart';

class SequenceProgressService {
  static const String _progressBox = 'mission_progress';
  
  // ============================================================
  // GESTION DE LA PROGRESSION GLOBALE
  // ============================================================
  
  /// Récupérer la progression complète d'une mission
  static Future<Map<String, dynamic>> getProgress(String missionId) async {
    final box = await Hive.openBox(_progressBox);
    final progress = box.get(missionId, defaultValue: {
      'currentStep': 0,
      'completedSteps': <int>[],
      'stepData': <String, dynamic>{},
      'lastUpdated': DateTime.now().toIso8601String(),
    });
    return Map<String, dynamic>.from(progress);
  }
  
  /// Sauvegarder la progression complète
  static Future<void> saveProgress(String missionId, Map<String, dynamic> progress) async {
    final box = await Hive.openBox(_progressBox);
    progress['lastUpdated'] = DateTime.now().toIso8601String();
    await box.put(missionId, progress);
    print('✅ Progression sauvegardée pour mission $missionId');
  }
  
  /// Sauvegarder l'étape courante uniquement
  static Future<void> saveCurrentStep(String missionId, int stepIndex) async {
    final progress = await getProgress(missionId);
    progress['currentStep'] = stepIndex;
    await saveProgress(missionId, progress);
  }
  
  /// Marquer une étape comme complétée
  static Future<void> markStepCompleted(String missionId, int stepIndex) async {
    final progress = await getProgress(missionId);
    if (!progress['completedSteps'].contains(stepIndex)) {
      progress['completedSteps'].add(stepIndex);
    }
    await saveProgress(missionId, progress);
  }
  
  // ============================================================
  // GESTION DES DONNÉES PAR ÉTAPE
  // ============================================================
  
  /// Sauvegarder les données d'une étape spécifique
  static Future<void> saveStepData(String missionId, String stepKey, dynamic data) async {
    final progress = await getProgress(missionId);
    progress['stepData'][stepKey] = data;
    await saveProgress(missionId, progress);
    print('✅ Données étape "$stepKey" sauvegardées');
  }
  
  /// Récupérer les données d'une étape spécifique
  static Future<dynamic> getStepData(String missionId, String stepKey) async {
    final progress = await getProgress(missionId);
    return progress['stepData'][stepKey];
  }
  
  /// Vérifier si une étape a des données
  static Future<bool> hasStepData(String missionId, String stepKey) async {
    final data = await getStepData(missionId, stepKey);
    return data != null;
  }
  
  // ============================================================
  // UTILITAIRES
  // ============================================================
  
  /// Réinitialiser la progression d'une mission
  static Future<void> resetProgress(String missionId) async {
    final box = await Hive.openBox(_progressBox);
    await box.delete(missionId);
    print('✅ Progression réinitialisée pour mission $missionId');
  }
  
  /// Supprimer toutes les progressions (debug)
  static Future<void> clearAllProgress() async {
    final box = await Hive.openBox(_progressBox);
    await box.clear();
    print('✅ Toutes les progressions supprimées');
  }
}