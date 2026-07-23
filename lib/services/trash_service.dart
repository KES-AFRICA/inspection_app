import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/models/lighting_inspection.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/trash_item.dart';
import 'package:inspec_app/services/backup_service.dart';

class TrashServiceResult {
  final bool success;
  final String message;
  final int affectedItems;

  const TrashServiceResult({
    required this.success,
    required this.message,
    this.affectedItems = 1,
  });
}

class TrashService {
  static const String _trashBoxName = 'trash_items';

  static Box<TrashItem> get _trashBox => Hive.box<TrashItem>(_trashBoxName);

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. SOFT DELETE (DÉPLACER DANS LA CORBEILLE)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Déplace une mission dans la corbeille
  static Future<TrashServiceResult> moveMissionToTrash(
    Mission mission, {
    String? deletedBy,
  }) async {
    try {
      final trashId = 'trash_mission_${mission.id}';
      final payload = jsonEncode({
        'missionId': mission.id,
        'nomClient': mission.nomClient,
        'nomSite': mission.nomSite,
        'natureMission': mission.natureMission,
      });

      final item = TrashItem(
        id: trashId,
        entityType: 'mission',
        entityId: mission.id,
        missionId: mission.id,
        title: mission.nomClient,
        subtitle: 'Site : ${mission.nomSite ?? "Non renseigné"} • ${mission.natureMission ?? "Mission"}',
        deletedAt: DateTime.now(),
        deletedBy: deletedBy ?? 'Vérificateur',
        serializedPayload: payload,
      );

      await _trashBox.put(trashId, item);
      return TrashServiceResult(
        success: true,
        message: 'Mission "${mission.nomClient}" déplacée dans la corbeille.',
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur moveMissionToTrash: $e');
      return TrashServiceResult(
        success: false,
        message: 'Erreur lors du déplacement vers la corbeille : $e',
      );
    }
  }

  /// Déplace une inspection d'éclairage dans la corbeille
  static Future<TrashServiceResult> moveLightingInspectionToTrash(
    LightingInspection inspection, {
    String? deletedBy,
  }) async {
    try {
      final trashId = 'trash_lighting_${inspection.id}';
      final item = TrashItem(
        id: trashId,
        entityType: 'lighting_inspection',
        entityId: inspection.id,
        missionId: inspection.missionId,
        title: 'Inspection Éclairage — ${inspection.batimentLocal}',
        subtitle: '${inspection.typeLuminaire} (${inspection.nonConformingLuminaires.length} non-conformités)',
        deletedAt: DateTime.now(),
        deletedBy: deletedBy ?? 'Vérificateur',
        serializedPayload: jsonEncode(inspection.toJson()),
      );

      await _trashBox.put(trashId, item);
      return TrashServiceResult(
        success: true,
        message: 'Inspection Éclairage déplacée dans la corbeille.',
      );
    } catch (e) {
      return TrashServiceResult(
        success: false,
        message: 'Erreur déplacement inspection éclairage : $e',
      );
    }
  }

  /// Déplace une JSA dans la corbeille
  static Future<TrashServiceResult> moveJSAToTrash(
    JSA jsa, {
    String? deletedBy,
  }) async {
    try {
      final trashId = 'trash_jsa_${jsa.missionId}';
      final opTitle = jsa.operationEffectuer.trim().isNotEmpty
          ? 'Analyse JSA — ${jsa.operationEffectuer}'
          : 'Analyse de Sécurité (JSA)';

      final item = TrashItem(
        id: trashId,
        entityType: 'jsa',
        entityId: jsa.missionId,
        missionId: jsa.missionId,
        title: opTitle,
        subtitle: 'Mission ID : ${jsa.missionId}',
        deletedAt: DateTime.now(),
        deletedBy: deletedBy ?? 'Vérificateur',
        serializedPayload: jsonEncode({
          'missionId': jsa.missionId,
          'operationEffectuer': jsa.operationEffectuer,
        }),
      );

      await _trashBox.put(trashId, item);
      return TrashServiceResult(
        success: true,
        message: 'JSA déplacée dans la corbeille.',
      );
    } catch (e) {
      return TrashServiceResult(
        success: false,
        message: 'Erreur déplacement JSA : $e',
      );
    }
  }

  /// Déplace une Zone d'audit électrique (MT/BT) dans la corbeille
  static Future<TrashServiceResult> moveZoneToTrash({
    required String missionId,
    required String zoneName,
    required String tensionType, // 'MT' ou 'BT'
    String? deletedBy,
  }) async {
    try {
      final trashId = 'trash_zone_${missionId}_${tensionType}_${zoneName.replaceAll(' ', '_')}';
      final item = TrashItem(
        id: trashId,
        entityType: 'zone',
        entityId: zoneName,
        missionId: missionId,
        title: 'Zone $tensionType : $zoneName',
        subtitle: 'Réseau $tensionType • Audit électrique',
        deletedAt: DateTime.now(),
        deletedBy: deletedBy ?? 'Vérificateur',
        serializedPayload: jsonEncode({
          'zoneName': zoneName,
          'tensionType': tensionType,
          'missionId': missionId,
        }),
      );

      await _trashBox.put(trashId, item);
      return TrashServiceResult(
        success: true,
        message: 'Zone "$zoneName" déplacée dans la corbeille.',
      );
    } catch (e) {
      return TrashServiceResult(
        success: false,
        message: 'Erreur déplacement Zone : $e',
      );
    }
  }

  /// Déplace un Local d'audit électrique (MT/BT) dans la corbeille
  static Future<TrashServiceResult> moveLocalToTrash({
    required String missionId,
    required String localName,
    required String zoneName,
    required String tensionType, // 'MT' ou 'BT'
    String? deletedBy,
  }) async {
    try {
      final trashId = 'trash_local_${missionId}_${tensionType}_${zoneName.replaceAll(' ', '_')}_${localName.replaceAll(' ', '_')}';
      final item = TrashItem(
        id: trashId,
        entityType: 'local',
        entityId: localName,
        missionId: missionId,
        parentEntityId: zoneName,
        parentEntityType: 'zone',
        title: 'Local : $localName',
        subtitle: 'Zone $zoneName ($tensionType)',
        deletedAt: DateTime.now(),
        deletedBy: deletedBy ?? 'Vérificateur',
        serializedPayload: jsonEncode({
          'localName': localName,
          'zoneName': zoneName,
          'tensionType': tensionType,
          'missionId': missionId,
        }),
      );

      await _trashBox.put(trashId, item);
      return TrashServiceResult(
        success: true,
        message: 'Local "$localName" déplacé dans la corbeille.',
      );
    } catch (e) {
      return TrashServiceResult(
        success: false,
        message: 'Erreur déplacement Local : $e',
      );
    }
  }

  /// Déplace un Équipement / Tableau / Coffret dans la corbeille
  static Future<TrashServiceResult> moveEquipementToTrash({
    required String missionId,
    required String equipementName,
    required String localOrZoneName,
    required String equipementType, // 'coffret', 'transformateur', 'cellule'
    String? deletedBy,
  }) async {
    try {
      final trashId = 'trash_equip_${missionId}_${equipementType}_${equipementName.replaceAll(' ', '_')}';
      final item = TrashItem(
        id: trashId,
        entityType: 'equipement',
        entityId: equipementName,
        missionId: missionId,
        parentEntityId: localOrZoneName,
        parentEntityType: 'local',
        title: 'Équipement : $equipementName',
        subtitle: 'Type : ${equipementType.toUpperCase()} • $localOrZoneName',
        deletedAt: DateTime.now(),
        deletedBy: deletedBy ?? 'Vérificateur',
        serializedPayload: jsonEncode({
          'equipementName': equipementName,
          'localOrZoneName': localOrZoneName,
          'equipementType': equipementType,
          'missionId': missionId,
        }),
      );

      await _trashBox.put(trashId, item);
      return TrashServiceResult(
        success: true,
        message: 'Équipement "$equipementName" déplacé dans la corbeille.',
      );
    } catch (e) {
      return TrashServiceResult(
        success: false,
        message: 'Erreur déplacement Équipement : $e',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. RESTAURATION (RÉCUPÉRATION DES DONNÉES)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Restaure un élément depuis la corbeille avec gestion anti-orphelins
  static Future<TrashServiceResult> restoreFromTrash(String trashItemId) async {
    try {
      final item = _trashBox.get(trashItemId);
      if (item == null) {
        return const TrashServiceResult(
          success: false,
          message: 'Élément introuvable dans la corbeille.',
        );
      }

      // Si le parent direct est dans la corbeille, restaurer également le parent
      if (item.parentEntityId != null && item.parentEntityType != null) {
        final parentTrashId = _findParentTrashId(item.parentEntityType!, item.parentEntityId!, item.missionId);
        if (parentTrashId != null) {
          await restoreFromTrash(parentTrashId);
        }
      }

      // Si la mission parente est dans la corbeille, restaurer la mission parente
      if (item.entityType != 'mission' && item.missionId != null) {
        final missionTrashId = 'trash_mission_${item.missionId}';
        if (_trashBox.containsKey(missionTrashId)) {
          await _trashBox.delete(missionTrashId);
        }
      }

      // Retirer l'élément de la corbeille
      await _trashBox.delete(trashItemId);

      return TrashServiceResult(
        success: true,
        message: '"${item.title}" restauré avec succès.',
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur restoreFromTrash: $e');
      return TrashServiceResult(
        success: false,
        message: 'Erreur lors de la restauration : $e',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. SUPPRESSION DÉFINITIVE & NETTOYAGE MÉDIA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Supprime définitivement un élément et nettoie les fichiers médias associés
  static Future<TrashServiceResult> permanentlyDelete(String trashItemId) async {
    try {
      final item = _trashBox.get(trashItemId);
      if (item == null) {
        return const TrashServiceResult(
          success: false,
          message: 'Élément introuvable dans la corbeille.',
        );
      }

      if (item.entityType == 'mission') {
        // Suppression physique atomique complète de la mission et de tous ses médias
        final result = await BackupService.deleteMissionCompletely(item.entityId);
        await _trashBox.delete(trashItemId);

        // Supprimer également tous les sous-éléments corbeille rattachés à cette mission
        final childKeys = _trashBox.values
            .where((t) => t.missionId == item.entityId)
            .map((t) => t.id)
            .toList();
        for (final k in childKeys) {
          await _trashBox.delete(k);
        }

        return TrashServiceResult(
          success: result.success,
          message: result.message ?? 'Mission définitivement supprimée.',
        );
      }

      if (item.entityType == 'lighting_inspection') {
        final box = Hive.box<LightingInspection>('lighting_inspections');
        final inspection = box.get(item.entityId);
        if (inspection != null) {
          for (final lum in inspection.nonConformingLuminaires) {
            for (final ans in lum.answers) {
              for (final path in ans.photoPaths) {
                try {
                  final f = File(path);
                  if (await f.exists()) await f.delete();
                } catch (_) {}
              }
            }
          }
          await box.delete(item.entityId);
        }
      } else if (item.entityType == 'jsa') {
        final box = Hive.box<JSA>('jsa');
        await box.delete(item.entityId);
      } else if (item.entityType == 'zone' || item.entityType == 'local' || item.entityType == 'equipement') {
        _purgeSubElementData(item);
      }

      await _trashBox.delete(trashItemId);

      return TrashServiceResult(
        success: true,
        message: '"${item.title}" définitivement supprimé.',
      );
    } catch (e) {
      if (kDebugMode) print('❌ Erreur permanentlyDelete: $e');
      return TrashServiceResult(
        success: false,
        message: 'Erreur lors de la suppression définitive : $e',
      );
    }
  }

  /// Vider entièrement la corbeille
  static Future<TrashServiceResult> emptyTrash() async {
    try {
      final items = _trashBox.values.toList();
      int count = items.length;
      for (final item in items) {
        await permanentlyDelete(item.id);
      }
      return TrashServiceResult(
        success: true,
        message: 'La corbeille a été entièrement vidée ($count élément(s)).',
        affectedItems: count,
      );
    } catch (e) {
      return TrashServiceResult(
        success: false,
        message: 'Erreur lors du vidage de la corbeille : $e',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. PURGE AUTOMATIQUE (POLITIQUE 90 JOURS)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Exécute la politique de purge automatique (supprime définitivement les éléments de +90 jours)
  static Future<int> autoPurgeExpiredItems({int retentionDays = 90}) async {
    int purgedCount = 0;
    try {
      final now = DateTime.now();
      final expiredItems = _trashBox.values.where((item) {
        return now.difference(item.deletedAt).inDays >= retentionDays;
      }).toList();

      for (final item in expiredItems) {
        final res = await permanentlyDelete(item.id);
        if (res.success) purgedCount++;
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Erreur autoPurgeExpiredItems: $e');
    }
    return purgedCount;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. REQUÊTES ET ÉTAT DU CORBEILLE
  // ═══════════════════════════════════════════════════════════════════════════

  static List<TrashItem> getAllTrashItems() {
    return _trashBox.values.toList()
      ..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
  }

  static int getTrashCount() {
    return _trashBox.length;
  }

  static bool isMissionInTrash(String missionId) {
    return _trashBox.containsKey('trash_mission_$missionId');
  }

  static Set<String> getTrashedMissionIds() {
    return _trashBox.values
        .where((t) => t.entityType == 'mission')
        .map((t) => t.entityId)
        .toSet();
  }

  static Set<String> getTrashedLightingInspectionIds() {
    return _trashBox.values
        .where((t) => t.entityType == 'lighting_inspection')
        .map((t) => t.entityId)
        .toSet();
  }

  static Set<String> getTrashedJSAIds() {
    return _trashBox.values
        .where((t) => t.entityType == 'jsa')
        .map((t) => t.entityId)
        .toSet();
  }

  static String? _findParentTrashId(String parentType, String parentId, String? missionId) {
    for (final item in _trashBox.values) {
      if (item.entityType == parentType && item.entityId == parentId) {
        return item.id;
      }
    }
    return null;
  }

  static void _purgeSubElementData(TrashItem item) {
    if (item.serializedPayload != null) {
      try {
        final data = jsonDecode(item.serializedPayload!);
        if (data is Map && data.containsKey('photos')) {
          final photos = List<String>.from(data['photos'] ?? []);
          for (final p in photos) {
            try {
              final f = File(p);
              if (f.existsSync()) f.deleteSync();
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
  }
}
