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
  /// Point d'entrée principal. Génère l'inventaire et les statistiques d'une mission.
  static MissionStatistics collect(String missionId) {
    // 1. Phase Inventaire Brut Exhaustif
    final inventory = AuditFindingInventoryEngine.buildInventory(missionId);

    // 2. Affichage automatique du diagnostic dans la console de debug
    inventory.printDiagnostic();

    // 3. Conversion de l'inventaire en UnifiedObservation pour rétrocompatibilité totale
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

    // 4. Phase Calcul Statistique
    return MissionStatistics.compute(missionId, unifiedObsList);
  }

  /// Génère directement l'inventaire brut AuditFindingInventory pour inspection et diagnostic.
  static AuditFindingInventory getInventory(String missionId) {
    final inventory = AuditFindingInventoryEngine.buildInventory(missionId);
    inventory.printDiagnostic();
    return inventory;
  }

  /// Génère le résumé statistique unifié Néo-Natif (`MissionStatisticsSummary`).
  ///
  /// Utilise `MissionDomainInventoryEngine` comme source unique de vérité pour
  /// l'inventaire physique (comptes d'instances), et `AuditFindingInventoryEngine`
  /// pour le diagnostic des non-conformités et les statistiques de criticité.
  static MissionStatisticsSummary collectSummary(String missionId) {
    final inventory = AuditFindingInventoryEngine.buildInventory(missionId);
    inventory.printDiagnostic();

    // Utiliser MissionDomainInventoryEngine pour les cross-category et l'inventaire chiffré.
    final domainInventory = MissionDomainInventoryEngine.buildInventory(missionId);
    return MissionStatisticsSummary.fromDomainInventory(inventory, domainInventory);
  }
}
