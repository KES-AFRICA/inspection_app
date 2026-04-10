// lib/pages/missions/sequence/sequence_progress_service.dart
import 'package:hive/hive.dart';

class SequenceProgressService {
  static const String _progressBox = 'mission_progress';
  
  // Structure de progression pour une mission
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
  
  // Sauvegarder l'étape courante
  static Future<void> saveCurrentStep(String missionId, int stepIndex) async {
    final box = await Hive.openBox(_progressBox);
    final progress = await getProgress(missionId);
    progress['currentStep'] = stepIndex;
    progress['lastUpdated'] = DateTime.now().toIso8601String();
    await box.put(missionId, progress);
  }
  
  // Marquer une étape comme complétée
  static Future<void> markStepCompleted(String missionId, int stepIndex) async {
    final box = await Hive.openBox(_progressBox);
    final progress = await getProgress(missionId);
    if (!progress['completedSteps'].contains(stepIndex)) {
      progress['completedSteps'].add(stepIndex);
    }
    progress['lastUpdated'] = DateTime.now().toIso8601String();
    await box.put(missionId, progress);
  }
  
  // Sauvegarder les données d'une étape
  static Future<void> saveStepData(String missionId, String stepKey, dynamic data) async {
    final box = await Hive.openBox(_progressBox);
    final progress = await getProgress(missionId);
    progress['stepData'][stepKey] = data;
    progress['lastUpdated'] = DateTime.now().toIso8601String();
    await box.put(missionId, progress);
  }
  
  // Récupérer les données d'une étape
  static Future<dynamic> getStepData(String missionId, String stepKey) async {
    final progress = await getProgress(missionId);
    return progress['stepData'][stepKey];
  }
  
  // Vérifier si une étape est complétée
  static Future<bool> isStepCompleted(String missionId, int stepIndex) async {
    final progress = await getProgress(missionId);
    return progress['completedSteps'].contains(stepIndex);
  }
  
  // Réinitialiser la progression d'une mission
  static Future<void> resetProgress(String missionId) async {
    final box = await Hive.openBox(_progressBox);
    await box.delete(missionId);
  }
  
  // Obtenir le pourcentage de complétion
  static Future<int> getCompletionPercentage(String missionId, int totalSteps) async {
    final progress = await getProgress(missionId);
    final completedCount = progress['completedSteps'].length;
    return totalSteps > 0 ? (completedCount / totalSteps * 100).round() : 0;
  }
}