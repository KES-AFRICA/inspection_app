// lib/services/statistics/mission_statistics.dart

import 'audit_finding.dart';
import 'unified_observation.dart';
import 'mission_domain_inventory_engine.dart';

class CriticalityStats {
  final int critique;
  final int majeure;
  final int mineure;
  final int total;
  final double pctCritique;
  final double pctMajeure;
  final double pctMineure;

  CriticalityStats({
    required this.critique,
    required this.majeure,
    required this.mineure,
    required this.total,
    required this.pctCritique,
    required this.pctMajeure,
    required this.pctMineure,
  });

  factory CriticalityStats.fromObservations(List<UnifiedObservation> observations) {
    int c = 0;
    int m = 0;
    int min = 0;

    for (final obs in observations) {
      switch (obs.criticite) {
        case CriticalityLevel.critique:
          c++;
          break;
        case CriticalityLevel.majeure:
          m++;
          break;
        case CriticalityLevel.mineure:
          min++;
          break;
        case CriticalityLevel.none:
          break;
      }
    }

    final tot = c + m + min;
    if (tot == 0) {
      return CriticalityStats(
        critique: 0,
        majeure: 0,
        mineure: 0,
        total: 0,
        pctCritique: 0.0,
        pctMajeure: 0.0,
        pctMineure: 0.0,
      );
    }

    return CriticalityStats(
      critique: c,
      majeure: m,
      mineure: min,
      total: tot,
      pctCritique: (c / tot) * 100,
      pctMajeure: (m / tot) * 100,
      pctMineure: (min / tot) * 100,
    );
  }
}

class MissionStatistics {
  final String missionId;
  final List<UnifiedObservation> allNonConformities;
  final CriticalityStats criticalityStats;
  final Map<String, int> statsByFamilleRisque;
  final Map<String, int> statsByRefNormative;
  final Map<String, int> statsByLocalisation;
  final Map<String, int> statsByTypeObjet;

  MissionStatistics({
    required this.missionId,
    required this.allNonConformities,
    required this.criticalityStats,
    required this.statsByFamilleRisque,
    required this.statsByRefNormative,
    required this.statsByLocalisation,
    required this.statsByTypeObjet,
  });

  factory MissionStatistics.compute(String missionId, List<UnifiedObservation> observations) {
    final criticality = CriticalityStats.fromObservations(observations);

    final byRisk = <String, int>{};
    final byNorm = <String, int>{};
    final byLoc = <String, int>{};
    final byType = <String, int>{};

    for (final obs in observations) {
      if (obs.familleRisque != null && obs.familleRisque!.isNotEmpty) {
        byRisk[obs.familleRisque!] = (byRisk[obs.familleRisque!] ?? 0) + 1;
      }
      if (obs.referenceNormative != null && obs.referenceNormative!.isNotEmpty) {
        byNorm[obs.referenceNormative!] = (byNorm[obs.referenceNormative!] ?? 0) + 1;
      }
      byLoc[obs.localisation] = (byLoc[obs.localisation] ?? 0) + 1;
      byType[obs.typeObjet] = (byType[obs.typeObjet] ?? 0) + 1;
    }

    return MissionStatistics(
      missionId: missionId,
      allNonConformities: observations,
      criticalityStats: criticality,
      statsByFamilleRisque: byRisk,
      statsByRefNormative: byNorm,
      statsByLocalisation: byLoc,
      statsByTypeObjet: byType,
    );
  }
}

/// Modèle conteneur unifié et certifié de l'analyse statistique d'une mission (`MissionStatisticsSummary`).
class MissionStatisticsSummary {
  final String missionId;
  final AuditFindingInventory inventory;
  final MissionDomainInventory? domainInventory;
  final CriticalityStats criticalityStats;
  final List<TopDefectItem> topDefects;
  final ParetoAnalysisResult paretoResult;
  final TopNonConformityCategoriesResult topTwoCategoriesResult;
  final List<RiskFamilyItem> riskFamilyStats;
  final TensionDomainStats tensionDomainStats;
  final List<InstallationTypeItem> installationTypeStats;
  final List<CategoryCrossItem> crossCategoryItems;
  final String crossAnalysisText;
  final List<EquipmentInventoryItem> equipmentInventory;

  MissionStatisticsSummary({
    required this.missionId,
    required this.inventory,
    this.domainInventory,
    required this.criticalityStats,
    required this.topDefects,
    required this.paretoResult,
    required this.topTwoCategoriesResult,
    required this.riskFamilyStats,
    required this.tensionDomainStats,
    required this.installationTypeStats,
    required this.crossCategoryItems,
    required this.crossAnalysisText,
    required this.equipmentInventory,
  });

  int get totalEquipments => domainInventory?.instances.length ?? equipmentInventory.fold<int>(0, (sum, e) => sum + e.count);

  factory MissionStatisticsSummary.fromInventory(AuditFindingInventory inventory) {
    final cStats = CriticalityStats(
      critique: inventory.critiqueCount,
      majeure: inventory.majeureCount,
      mineure: inventory.mineureCount,
      total: inventory.classifiedCount,
      pctCritique: inventory.pctCritique,
      pctMajeure: inventory.pctMajeure,
      pctMineure: inventory.pctMineure,
    );

    final crossItems = inventory.getCrossCategoryAnalysis();
    final crossText = CategoryCrossAnalysisTextGenerator.generate(crossItems);

    final eqInventory = crossItems.map((ci) => EquipmentInventoryItem(
      label: ci.categoryName,
      count: ci.equipmentCount,
    )).toList();

    final topDefectsList = inventory.getTopDefects(limit: 10);
    final pareto = ParetoAnalysisResult(
      items: topDefectsList,
      totalOccurrences: inventory.classifiedCount,
      paretoCategoryCount: topDefectsList.length,
      paretoCumulativePercentage: topDefectsList.fold(0.0, (s, e) => s + e.percentage),
      summaryText: 'Analyse des principaux défauts.',
    );

    final defaultTopTwo = TopNonConformityCategoriesResult(
      label: 'Concentration Équipements',
      cat1Name: 'Équipements',
      combinedNC: inventory.classifiedCount,
      pctTotalNC: 100.0,
      combinedEquipments: eqInventory.fold(0, (s, e) => s + e.count),
      pctParc: 100.0,
      formattedValue: '${inventory.classifiedCount} NC',
    );

    return MissionStatisticsSummary(
      missionId: inventory.missionId,
      inventory: inventory,
      domainInventory: null,
      criticalityStats: cStats,
      topDefects: topDefectsList,
      paretoResult: pareto,
      topTwoCategoriesResult: defaultTopTwo,
      riskFamilyStats: inventory.getRiskFamilyStats(),
      tensionDomainStats: inventory.getTensionDomainStats(),
      installationTypeStats: inventory.getInstallationTypeStats(),
      crossCategoryItems: crossItems,
      crossAnalysisText: crossText,
      equipmentInventory: eqInventory.isNotEmpty
          ? eqInventory
          : AuditFindingInventory.computeEquipmentInventory(inventory.missionId),
    );
  }

  /// Factory principale utilisant le `MissionDomainInventoryEngine` comme source unique de vérité
  /// pour l'inventaire physique (comptes d'instances, analyse croisée, inventaire chiffré).
  /// Les statistiques de criticité et les findings proviennent de `AuditFindingInventory`.
  factory MissionStatisticsSummary.fromDomainInventory(
    AuditFindingInventory inventory,
    MissionDomainInventory domainInventory,
  ) {
    final cStats = CriticalityStats(
      critique: inventory.critiqueCount,
      majeure: inventory.majeureCount,
      mineure: inventory.mineureCount,
      total: inventory.classifiedCount,
      pctCritique: inventory.pctCritique,
      pctMajeure: inventory.pctMajeure,
      pctMineure: inventory.pctMineure,
    );

    // Source unique de vérité : MissionDomainInventoryEngine
    final crossItems = domainInventory.getCrossCategoryAnalysis();
    final crossText = CategoryCrossAnalysisTextGenerator.generate(crossItems);
    final eqInventory = domainInventory.getEquipmentInventorySummary();
    final pareto = domainInventory.getParetoAnalysis(limit: 10);
    final topTwo = domainInventory.getTopTwoNonConformityCategories();

    return MissionStatisticsSummary(
      missionId: inventory.missionId,
      inventory: inventory,
      domainInventory: domainInventory,
      criticalityStats: cStats,
      topDefects: pareto.items,
      paretoResult: pareto,
      topTwoCategoriesResult: topTwo,
      riskFamilyStats: inventory.getRiskFamilyStats(),
      tensionDomainStats: inventory.getTensionDomainStats(),
      installationTypeStats: inventory.getInstallationTypeStats(),
      crossCategoryItems: crossItems,
      crossAnalysisText: crossText,
      equipmentInventory: eqInventory,
    );
  }
}
