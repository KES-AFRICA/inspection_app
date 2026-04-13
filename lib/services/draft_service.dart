// lib/services/draft_service.dart
import 'package:hive/hive.dart';
import 'dart:convert';

class DraftService {
  static const String _draftBox = 'drafts';
  
  // Types d'entités supportés
  static const String TYPE_ZONE = 'zone';
  static const String TYPE_LOCAL = 'local';
  static const String TYPE_COFFRET = 'coffret';
  static const String TYPE_FOUDRE = 'foudre';
  static const String TYPE_ESSAI = 'essai';
  static const String TYPE_PRISE_TERRE = 'prise_terre';
  static const String TYPE_CONTINUITE = 'continuite';
  static const String TYPE_CLASSEMENT = 'classement';
  static const String TYPE_OBSERVATION = 'observation';

  /// Initialiser la box des brouillons
  static Future<void> init() async {
    await Hive.openBox(_draftBox);
  }

  /// Générer une clé unique pour le brouillon
  static String _generateKey({
    required String missionId,
    required String type,
    String? entityId,
    bool isEdition = false,
  }) {
    if (isEdition && entityId != null) {
      return '${missionId}_${type}_${entityId}';
    } else {
      return '${missionId}_${type}_nouveau';
    }
  }

  /// Sauvegarder un brouillon
  static Future<void> saveDraft({
    required String missionId,
    required String type,
    required Map<String, dynamic> data,
    String? entityId,
    bool isEdition = false,
  }) async {
    try {
      final box = Hive.box(_draftBox);
      final key = _generateKey(
        missionId: missionId,
        type: type,
        entityId: entityId,
        isEdition: isEdition,
      );
      
      final draftData = {
        ...data,
        '_savedAt': DateTime.now().toIso8601String(),
        '_type': type,
        '_missionId': missionId,
        '_entityId': entityId,
        '_isEdition': isEdition,
      };
      
      await box.put(key, jsonEncode(draftData));
      print('✅ Brouillon sauvegardé: $key');
    } catch (e) {
      print('❌ Erreur sauvegarde brouillon: $e');
    }
  }

  /// Charger un brouillon
  static Future<Map<String, dynamic>?> loadDraft({
    required String missionId,
    required String type,
    String? entityId,
    bool isEdition = false,
  }) async {
    try {
      final box = Hive.box(_draftBox);
      final key = _generateKey(
        missionId: missionId,
        type: type,
        entityId: entityId,
        isEdition: isEdition,
      );
      
      final String? draftJson = box.get(key);
      if (draftJson != null) {
        final draftData = jsonDecode(draftJson) as Map<String, dynamic>;
        print('✅ Brouillon chargé: $key');
        return draftData;
      }
      return null;
    } catch (e) {
      print('❌ Erreur chargement brouillon: $e');
      return null;
    }
  }

  /// Supprimer un brouillon
  static Future<void> deleteDraft({
    required String missionId,
    required String type,
    String? entityId,
    bool isEdition = false,
  }) async {
    try {
      final box = Hive.box(_draftBox);
      final key = _generateKey(
        missionId: missionId,
        type: type,
        entityId: entityId,
        isEdition: isEdition,
      );
      
      await box.delete(key);
      print('✅ Brouillon supprimé: $key');
    } catch (e) {
      print('❌ Erreur suppression brouillon: $e');
    }
  }

  /// Vérifier si un brouillon existe
  static Future<bool> hasDraft({
    required String missionId,
    required String type,
    String? entityId,
    bool isEdition = false,
  }) async {
    try {
      final box = Hive.box(_draftBox);
      final key = _generateKey(
        missionId: missionId,
        type: type,
        entityId: entityId,
        isEdition: isEdition,
      );
      return box.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  /// Obtenir la date de dernière sauvegarde du brouillon
  static Future<DateTime?> getDraftSavedAt({
    required String missionId,
    required String type,
    String? entityId,
    bool isEdition = false,
  }) async {
    final draft = await loadDraft(
      missionId: missionId,
      type: type,
      entityId: entityId,
      isEdition: isEdition,
    );
    
    if (draft != null && draft['_savedAt'] != null) {
      return DateTime.parse(draft['_savedAt'] as String);
    }
    return null;
  }

  /// Supprimer tous les brouillons d'une mission
  static Future<void> deleteAllDraftsForMission(String missionId) async {
    try {
      final box = Hive.box(_draftBox);
      final keysToDelete = box.keys.where((key) => key.toString().startsWith(missionId)).toList();
      
      for (var key in keysToDelete) {
        await box.delete(key);
      }
      print('✅ ${keysToDelete.length} brouillons supprimés pour mission $missionId');
    } catch (e) {
      print('❌ Erreur suppression brouillons: $e');
    }
  }

  /// Formater l'heure de sauvegarde pour affichage
  static String formatSavedTime(DateTime? savedAt) {
    if (savedAt == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(savedAt);
    
    if (difference.inSeconds < 60) {
      return 'Enregistré à l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Enregistré il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Enregistré il y a ${difference.inHours} h';
    } else {
      return 'Enregistré le ${savedAt.day}/${savedAt.month}';
    }
  }
}