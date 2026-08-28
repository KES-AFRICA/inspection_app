// lib/features/backup/data/services/mission_activity_tracker.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service de suivi d'activité de la journée d'inspection (08:00 - 18:00)
class MissionActivityTracker {
  static const String _boxName = 'mission_activity_tracker';

  static Future<Box> _getBox() async {
    return Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
  }

  /// Clé unique du jour au format YYYY-MM-DD
  static String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Marque une mission comme ayant été modifiée aujourd'hui dans la fenêtre d'inspection
  static Future<void> markMissionModifiedToday(String missionId) async {
    try {
      final box = await _getBox();
      final today = _getTodayKey();
      final key = '${today}_$missionId';
      
      await box.put(key, {
        'missionId': missionId,
        'date': today,
        'lastModifiedAt': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('📌 Mission $missionId marquée comme modifiée aujourd\'hui ($today)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur markMissionModifiedToday: $e');
      }
    }
  }

  /// Vérifie si une mission a été modifiée aujourd'hui
  static Future<bool> isMissionModifiedToday(String missionId) async {
    try {
      final box = await _getBox();
      final today = _getTodayKey();
      final key = '${today}_$missionId';
      return box.containsKey(key);
    } catch (_) {
      return false;
    }
  }

  /// Récupère la liste de toutes les IDs de missions modifiées aujourd'hui
  static Future<List<String>> getMissionsModifiedToday() async {
    final List<String> missionIds = [];
    try {
      final box = await _getBox();
      final today = _getTodayKey();

      for (final key in box.keys) {
        final keyStr = key.toString();
        if (keyStr.startsWith('${today}_')) {
          final missionId = keyStr.substring(today.length + 1);
          missionIds.add(missionId);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur getMissionsModifiedToday: $e');
      }
    }
    return missionIds;
  }

  /// Efface les marquages d'activité pour une mission après la sauvegarde réussie de 17h30
  static Future<void> clearActivityForMission(String missionId) async {
    try {
      final box = await _getBox();
      final today = _getTodayKey();
      final key = '${today}_$missionId';
      await box.delete(key);
    } catch (_) {}
  }
}
