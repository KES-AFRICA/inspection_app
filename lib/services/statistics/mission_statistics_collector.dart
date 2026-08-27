// lib/services/statistics/mission_statistics_collector.dart

import 'audit_finding_inventory_engine.dart';
import 'audit_finding.dart';
import 'unified_observation.dart';
import 'mission_statistics.dart';
import 'mission_domain_inventory_engine.dart';

/// Façade Principale du Moteur d'Inventaire et de Statistiques.
/// 
/// 1. Appelle `AuditFindingInventoryEngine.buildInventory(missionId)` pour recenser 100% des occurrences réelles.
/// 2. Imprime le diagnostic certifié d'inventaire dans la console de debug (totaux par criticité).
/// 3. Convertit l'inventaire certifié en `MissionStatistics` pour le PDF et les graphiques.
class MissionStatisticsCollector {
  static final Map<String, AuditFindingInventory> _inventoryCache = {};
  static final Map<String, DateTime> _inventoryCacheTime = {};
  static final Map<String, MissionStatisticsSummary> _summaryCache = {};
  static final Map<String, MissionStatistics> _statsCache = {};
  static const Duration _cacheTtl = Duration(seconds: 10);

  /// Invalide le cache pour une mission (à appeler lors d'une modification d'équipement/point).
  static void invalidateCache(String missionId) {
    _inventoryCache.remove(missionId);
    _inventoryCacheTime.remove(missionId);
    _summaryCache.remove(missionId);
    _statsCache.remove(missionId);
  }

  /// Point d'entrée principal. Génère l'inventaire et les statistiques d'une mission.
  static MissionStatistics collect(String missionId, {bool forceRefresh = false}) {
    if (!forceRefresh && _statsCache.containsKey(missionId)) {
      final cacheTime = _inventoryCacheTime[missionId];
      if (cacheTime != null && DateTime.now().difference(cacheTime) < _cacheTtl) {
        return _statsCache[missionId]!;
      }
    }

    // 1. Phase Inventaire Brut Exhaustif
    final inventory = getInventory(missionId, forceRefresh: forceRefresh);

    // 2. Conversion de l'inventaire en UnifiedObservation pour rétrocompatibilité totale
    final unifiedObsList = inventory.findings.map((finding) {
      return UnifiedObservation(
        id: finding.id,
        missionId: finding.missionId,
        localisation: finding.objectName,
        zoneNom: finding.origin,
        itemNom: finding.verificationPoint,
        texteObservation: finding.observationText,
        criticite: UnifiedObservation.stringToCriticality(finding.criticality),
        prioriteInt: finding.priority,
        referenceNormative: finding.normativeReference,
        familleRisque: finding.riskFamily,
        sourceCategory: AuditSourceCategory.equipement,
        tableType: AuditTableType.pointsVerification,
        typeObjet: finding.objectType,
        repere: finding.objectRepere,
        photos: finding.photos,
      );
    }).toList();

    // 3. Phase Calcul Statistique
    final stats = MissionStatistics.compute(missionId, unifiedObsList);
    _statsCache[missionId] = stats;
    return stats;
  }

  /// Génère directement l'inventaire brut AuditFindingInventory avec cache mémoire.
  static AuditFindingInventory getInventory(String missionId, {bool forceRefresh = false}) {
    if (!forceRefresh && _inventoryCache.containsKey(missionId)) {
      final cacheTime = _inventoryCacheTime[missionId];
      if (cacheTime != null && DateTime.now().difference(cacheTime) < _cacheTtl) {
        return _inventoryCache[missionId]!;
      }
    }

    final inventory = AuditFindingInventoryEngine.buildInventory(missionId);
    _inventoryCache[missionId] = inventory;
    _inventoryCacheTime[missionId] = DateTime.now();
    return inventory;
  }

  /// Génère le résumé statistique unifié Néo-Natif avec cache mémoire.
  static MissionStatisticsSummary collectSummary(String missionId, {bool forceRefresh = false}) {
    if (!forceRefresh && _summaryCache.containsKey(missionId)) {
      final cacheTime = _inventoryCacheTime[missionId];
      if (cacheTime != null && DateTime.now().difference(cacheTime) < _cacheTtl) {
        return _summaryCache[missionId]!;
      }
    }

    final inventory = getInventory(missionId, forceRefresh: forceRefresh);
    final domainInventory = MissionDomainInventoryEngine.buildInventory(missionId);
    final summary = MissionStatisticsSummary.fromDomainInventory(inventory, domainInventory);
    _summaryCache[missionId] = summary;
    return summary;
  }
}
