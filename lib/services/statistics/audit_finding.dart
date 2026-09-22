// lib/services/statistics/audit_finding.dart

import 'canonical_defect_category_registry.dart';
import 'canonical_risk_family_registry.dart';
import 'mission_domain_inventory_engine.dart';

/// Modèle d'item d'inventaire chiffré des installations et équipements
class EquipmentInventoryItem {
  final String label;
  final int count;

  EquipmentInventoryItem({
    required this.label,
    required this.count,
  });
}

/// Domaine de tension d'un constat d'audit.
enum TensionDomain { mt, bt }

/// Modèle d'occurrence individuelle d'inventaire représentant une ligne non conforme constatée.
class AuditFinding {
  final String id;
  final String missionId;

  // Localisation & Contexte
  final TensionDomain tensionDomain; // Domaine de tension (MT vs BT)
  final String origin;           // "Local MT", "Local BT", "Zone MT", "Zone BT", "Groupe Électrogène", "Foudre"
  final String objectType;       // "Local MT", "Local BT", "Cellule MT", "Transformateur MT/BT", "Coffret", "Armoire", "TGBT", "Inverseur", "Foudre"
  final String objectName;       // Nom de l'équipement ou du local
  final String? objectRepere;    // Repère équipement ou numéro de série
  final String tableName;        // "Dispositions constructives", "Conditions d'exploitation", "Points de vérification", "Cellule audit", etc.

  // Constat & Normes
  final String verificationPoint;// Libellé du point de contrôle
  final String observationText;  // Description détaillée de la non-conformité
  final String conformity;       // "non", "non conforme", "false"
  final String criticality;      // "Critique", "Majeure", "Mineure", "Non spécifiée"
  final int? priority;           // Priorité d'intervention (1, 2, 3)
  final String? riskFamily;      // Famille de risque
  final String? normativeReference; // Référence normée
  final List<String> photos;

  AuditFinding({
    required this.id,
    required this.missionId,
    required this.tensionDomain,
    required this.origin,
    required this.objectType,
    required this.objectName,
    this.objectRepere,
    required this.tableName,
    required this.verificationPoint,
    required this.observationText,
    required this.conformity,
    required this.criticality,
    this.priority,
    this.riskFamily,
    this.normativeReference,
    List<String>? photos,
  }) : photos = photos ?? [];

  /// Indique si la non-conformité est assortie d'une référence normative valide.
  bool get hasValidNormativeReference =>
      normativeReference != null && normativeReference!.trim().isNotEmpty;
}

/// Modèle d'item d'analyse de Pareto par catégorie de défaut
class TopDefectItem {
  final String title;
  final int count;
  final double percentage;
  final double cumulativePercentage;
  final int critiqueCount;
  final int majeureCount;
  final int mineureCount;
  final String classeAbc; // 'A', 'B', 'C'
  final bool isOtherAggregate; // true si c'est la ligne/barre récapitulative "Autres"

  TopDefectItem({
    required this.title,
    required this.count,
    required this.percentage,
    this.cumulativePercentage = 0.0,
    this.critiqueCount = 0,
    this.majeureCount = 0,
    this.mineureCount = 0,
    this.classeAbc = 'C',
    this.isOtherAggregate = false,
  });
}

/// Résultat de la sélection dynamique des 2 catégories d'équipements générant le plus de non-conformités.
class TopNonConformityCategoriesResult {
  final String label;
  final String cat1Name;
  final String? cat2Name;
  final int combinedNC;
  final double pctTotalNC;
  final int combinedEquipments;
  final double pctParc;
  final String formattedValue;

  TopNonConformityCategoriesResult({
    required this.label,
    required this.cat1Name,
    this.cat2Name,
    required this.combinedNC,
    required this.pctTotalNC,
    required this.combinedEquipments,
    required this.pctParc,
    required this.formattedValue,
  });
}

/// Profils de concentration statistique de Pareto réels
enum ParetoConcentrationProfile {
  noData,
  singleDominant,
  breakPointConcentration, // Cassure nette (ex. 2 catégories font > 40%)
  highConcentration,
  moderateConcentration,
  homogeneousOrDispersed,
  thresholdNotReached,
}

/// Résultat complet et certifié de l'analyse de Pareto dynamique sur les points de vérification.
class ParetoAnalysisResult {
  final List<TopDefectItem> items;
  final TopDefectItem? otherCategoryItem; // Agrégat "Autres typologies (M catégories)"
  final int totalOccurrences;
  final int paretoCategoryCount;
  final double paretoCumulativePercentage;
  final String summaryText;
  final int totalDistinctCategories;
  final bool isThresholdReached;

  // Détection de rupture de distribution et classification ABC
  final bool hasBreakPoint;
  final int breakPointCategoryCount;
  final double breakPointPercentage;
  final int classeACount;
  final double classeAPct;
  final int classeBCount;
  final double classeBPct;
  final int classeCCount;
  final double classeCPct;
  final int totalCritiques;
  final int totalMajeures;

  ParetoAnalysisResult({
    required this.items,
    this.otherCategoryItem,
    required this.totalOccurrences,
    required this.paretoCategoryCount,
    required this.paretoCumulativePercentage,
    required this.summaryText,
    int? totalDistinctCategories,
    bool? isThresholdReached,
    this.hasBreakPoint = false,
    this.breakPointCategoryCount = 0,
    this.breakPointPercentage = 0.0,
    this.classeACount = 0,
    this.classeAPct = 0.0,
    this.classeBCount = 0,
    this.classeBPct = 0.0,
    this.classeCCount = 0,
    this.classeCPct = 0.0,
    this.totalCritiques = 0,
    this.totalMajeures = 0,
  })  : totalDistinctCategories = totalDistinctCategories ?? items.length,
        isThresholdReached = isThresholdReached ?? (paretoCumulativePercentage >= 80.0);

  /// Liste complète des items à afficher graphiquement (Top catégories + Autres éventuel)
  List<TopDefectItem> get allDisplayItems =>
      otherCategoryItem != null ? [...items, otherCategoryItem!] : items;

  /// Nombre d'occurrences cumulées concentrées par les 10 premières catégories de défauts.
  int get top10Count => items.take(10).fold(0, (sum, e) => sum + e.count);

  /// Pourcentage cumulé représenté par les 10 premières catégories de défauts.
  double get top10Percentage =>
      totalOccurrences > 0 ? (top10Count / totalOccurrences) * 100.0 : 0.0;

  /// Ratio de concentration : proportion de catégories nécessaires pour atteindre le seuil de 80%
  double get k80Ratio => totalDistinctCategories > 0
      ? (paretoCategoryCount / totalDistinctCategories)
      : 0.0;

  /// Profil de concentration objectivement observé (sans forcer le 80/20)
  ParetoConcentrationProfile get profile {
    if (totalOccurrences == 0 || items.isEmpty) {
      return ParetoConcentrationProfile.noData;
    }
    if (items.length == 1 || (paretoCategoryCount == 1 && items.first.percentage >= 80.0)) {
      return ParetoConcentrationProfile.singleDominant;
    }
    if (isThresholdReached && (k80Ratio <= 0.25 || (totalDistinctCategories <= 4 && paretoCategoryCount <= 1))) {
      return ParetoConcentrationProfile.highConcentration;
    }
    if (hasBreakPoint && breakPointCategoryCount <= 2 && breakPointPercentage >= 40.0) {
      return ParetoConcentrationProfile.breakPointConcentration;
    }
    if (!isThresholdReached) {
      return ParetoConcentrationProfile.thresholdNotReached;
    }
    if (k80Ratio <= 0.50) {
      return ParetoConcentrationProfile.moderateConcentration;
    }
    return ParetoConcentrationProfile.homogeneousOrDispersed;
  }
}

/// Item de Pareto par catégorie d'équipement / d'installation
class CategoryParetoItem {
  final String categoryName;
  final String categoryKey;
  final int nonConformitiesCount;
  final int equipmentCount;
  final double percentage;
  final double cumulativePercentage;

  CategoryParetoItem({
    required this.categoryName,
    required this.categoryKey,
    required this.nonConformitiesCount,
    required this.equipmentCount,
    required this.percentage,
    required this.cumulativePercentage,
  });
}

/// Résultat de l'analyse de Pareto (80/20) appliquée aux 10 catégories d'équipements
class CategoryParetoResult {
  final List<CategoryParetoItem> items;
  final int totalNonConformities;
  final int paretoCategoryCount;
  final double paretoCumulativePercentage;
  final String summaryText;

  CategoryParetoResult({
    required this.items,
    required this.totalNonConformities,
    required this.paretoCategoryCount,
    required this.paretoCumulativePercentage,
    required this.summaryText,
  });
}

/// Modèle d'analyse par domaine de tension (MT vs BT)
class TensionDomainStats {
  final int mtCount;
  final int btCount;
  final int totalCount;
  final double mtPct;
  final double btPct;

  TensionDomainStats({
    required this.mtCount,
    required this.btCount,
    required this.totalCount,
    required this.mtPct,
    required this.btPct,
  });

  String get mtPercentageStr => '${mtPct.toStringAsFixed(1).replaceAll('.', ',')} %';
  String get btPercentageStr => '${btPct.toStringAsFixed(1).replaceAll('.', ',')} %';
}

/// Modèle d'item d'analyse par famille de risque
class RiskFamilyItem {
  final String name;
  final int count;
  final double percentage;

  RiskFamilyItem({
    required this.name,
    required this.count,
    required this.percentage,
  });
}

/// Modèle d'item d'analyse par type d'installation / d'équipement
class InstallationTypeItem {
  final String name;
  final int count;
  final double percentage;

  InstallationTypeItem({
    required this.name,
    required this.count,
    required this.percentage,
  });
}

/// Modèle d'item d'analyse croisée par catégorie d'équipement
class CategoryCrossItem {
  final String categoryKey;
  final String categoryName;
  final int equipmentCount;
  final int totalPointsEvaluated;
  final int compliantPointsCount;
  final int nonCompliantPointsCount;
  final int naPointsCount;
  final int critiqueCount;
  final int majeureCount;
  final int mineureCount;
  final double complianceRate;
  final double density; // nonConformitiesCount / equipmentCount

  int get nonConformitiesCount => nonCompliantPointsCount;

  CategoryCrossItem({
    required this.categoryKey,
    required this.categoryName,
    required this.equipmentCount,
    required this.totalPointsEvaluated,
    required this.compliantPointsCount,
    required this.nonCompliantPointsCount,
    required this.naPointsCount,
    required this.critiqueCount,
    required this.majeureCount,
    required this.mineureCount,
    required this.complianceRate,
    required this.density,
  });
}

/// Générateur dynamique de synthèse textuelle de la lecture croisée par catégorie.
class CategoryCrossAnalysisTextGenerator {
  static String generate(List<CategoryCrossItem> items) {
    final activeItems = items.where((it) => it.equipmentCount > 0 || it.totalPointsEvaluated > 0).toList();
    if (activeItems.isEmpty) {
      return "L'analyse croisée des installations ne révèle aucun équipement ou local évalué pour cette mission.";
    }

    final totalEquipments = activeItems.fold<int>(0, (sum, it) => sum + it.equipmentCount);

    // 1. Catégorie la plus critique
    final sortedByCritique = List<CategoryCrossItem>.from(activeItems)
      ..sort((a, b) {
        final compC = b.critiqueCount.compareTo(a.critiqueCount);
        if (compC != 0) return compC;
        return b.nonConformitiesCount.compareTo(a.nonConformitiesCount);
      });
    final mostCritical = sortedByCritique.first;

    // 2. Catégorie avec le plus grand nombre de NC
    final sortedByNC = List<CategoryCrossItem>.from(activeItems)
      ..sort((a, b) => b.nonConformitiesCount.compareTo(a.nonConformitiesCount));
    final highestNC = sortedByNC.first;

    // 3. Catégorie avec la meilleure conformité
    final sortedByBestComp = List<CategoryCrossItem>.from(activeItems)
      ..sort((a, b) => b.complianceRate.compareTo(a.complianceRate));
    final bestComp = sortedByBestComp.first;

    // 4. Catégorie avec le taux de conformité le plus bas
    final sortedByWorstComp = List<CategoryCrossItem>.from(activeItems)
      ..sort((a, b) => a.complianceRate.compareTo(b.complianceRate));
    final worstComp = sortedByWorstComp.first;

    final buffer = StringBuffer();
    buffer.write(
      "L'analyse croisée réalisée sur l'ensemble des $totalEquipments installations et équipements "
      "de la mission fait ressortir la catégorie « ${mostCritical.categoryName} » comme le secteur le plus critique"
    );

    if (mostCritical.critiqueCount > 0) {
      buffer.write(" avec ${mostCritical.critiqueCount} non-conformité(s) critique(s). ");
    } else if (mostCritical.nonConformitiesCount > 0) {
      buffer.write(" avec un total de ${mostCritical.nonConformitiesCount} constat(s) de non-conformité. ");
    } else {
      buffer.write(". ");
    }

    if (highestNC.categoryKey != mostCritical.categoryKey && highestNC.nonConformitiesCount > 0) {
      buffer.write(
        "La catégorie « ${highestNC.categoryName} » concentre également un volume important de défaillances "
        "(${highestNC.nonConformitiesCount} non-conformité(s)). "
      );
    }

    if (worstComp.complianceRate < 100 && worstComp.categoryKey != mostCritical.categoryKey) {
      buffer.write(
        "Le taux de conformité le plus faible est observé sur les « ${worstComp.categoryName} » (${worstComp.complianceRate.toStringAsFixed(1)} %). "
      );
    }

    if (bestComp.complianceRate > 0) {
      buffer.write(
        "À l'inverse, la catégorie « ${bestComp.categoryName} » présente le meilleur taux de conformité globale (${bestComp.complianceRate.toStringAsFixed(1)} %)."
      );
    }

    return buffer.toString();
  }
}

/// Collection certifiée d'inventaire brut d'une mission.
class AuditFindingInventory {
  final String missionId;
  final List<AuditFinding> findings;
  final List<CategoryCrossItem> crossCategoryItems;

  AuditFindingInventory({
    required this.missionId,
    required this.findings,
    List<CategoryCrossItem>? crossCategoryItems,
  }) : crossCategoryItems = crossCategoryItems ?? [];

  /// Règle métier stricte : une non-conformité doit obligatoirement être catégorisée
  /// en Critique, Majeure ou Mineure. Les observations libres ou constats non catégorisés sont exclus.
  static bool isNormativeNonConformity(AuditFinding f) {
    final table = f.tableName.trim().toLowerCase();
    final point = f.verificationPoint.trim().toLowerCase();
    if (table.contains('libre') || point.contains('observation libre')) {
      return false;
    }
    final crit = f.criticality.trim().toLowerCase();
    return crit == 'critique' || crit == 'majeure' || crit == 'mineure';
  }

  /// Non-conformités exhaustives et certifiées pour l'ensemble du Résumé Exécutif et des Analyses Statistiques.
  List<AuditFinding> get pertinentFindings => findings.where(isNormativeNonConformity).toList();

  int get totalFindings => pertinentFindings.length;
  int get totalEquipments => crossCategoryItems.fold<int>(0, (sum, e) => sum + e.equipmentCount);

  int get critiqueCount => pertinentFindings.where((f) => f.criticality.trim().toLowerCase() == 'critique').length;
  int get majeureCount => pertinentFindings.where((f) => f.criticality.trim().toLowerCase() == 'majeure').length;
  int get mineureCount => pertinentFindings.where((f) => f.criticality.trim().toLowerCase() == 'mineure').length;
  int get unspecifiedCount => 0;

  /// Nombre de findings possédant une criticité normative résolue (Critique, Majeure ou Mineure).
  int get classifiedCount => critiqueCount + majeureCount + mineureCount;

  /// Findings possédant une criticité normative résolue.
  List<AuditFinding> get classifiedFindings => pertinentFindings;

  double get pctCritique => classifiedCount > 0 ? (critiqueCount / classifiedCount) * 100 : 0.0;
  double get pctMajeure => classifiedCount > 0 ? (majeureCount / classifiedCount) * 100 : 0.0;
  double get pctMineure => classifiedCount > 0 ? (mineureCount / classifiedCount) * 100 : 0.0;

  /// Récupère le Top N des points de vérification les plus fréquemment non conformes.
  List<TopDefectItem> getTopDefects({int limit = 10}) {
    if (pertinentFindings.isEmpty) return [];

    final counts = <String, int>{};
    for (final f in pertinentFindings) {
      final point = CanonicalDefectCategoryRegistry.mapToCanonical(
        f.verificationPoint,
        riskFamily: f.riskFamily,
      );
      if (point.isNotEmpty) {
        counts[point] = (counts[point] ?? 0) + 1;
      }
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sortedEntries.take(limit).toList();
    final tot = totalFindings;

    return topEntries.map((e) {
      final pct = tot > 0 ? (e.value / tot) * 100 : 0.0;
      return TopDefectItem(
        title: e.key,
        count: e.value,
        percentage: pct,
      );
    }).toList();
  }

  /// Calcule la répartition des non-conformités par famille de risque.
  List<RiskFamilyItem> getRiskFamilyStats() {
    if (pertinentFindings.isEmpty) return [];

    final counts = <String, int>{};
    for (final f in pertinentFindings) {
      if (CanonicalRiskFamilyRegistry.hasValidRiskFamily(f.riskFamily, verificationPoint: f.verificationPoint)) {
        final family = CanonicalRiskFamilyRegistry.mapToCanonical(f.riskFamily, verificationPoint: f.verificationPoint);
        counts[family] = (counts[family] ?? 0) + 1;
      }
    }

    for (final family in CanonicalRiskFamilyRegistry.canonicalFamilies) {
      counts.putIfAbsent(family, () => 0);
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return CanonicalRiskFamilyRegistry.canonicalFamilies.indexOf(a.key)
            .compareTo(CanonicalRiskFamilyRegistry.canonicalFamilies.indexOf(b.key));
      });
    final totValid = counts.values.fold<int>(0, (sum, count) => sum + count);

    return sortedEntries.map((e) {
      final pct = totValid > 0 ? (e.value / totValid) * 100 : 0.0;
      return RiskFamilyItem(
        name: e.key,
        count: e.value,
        percentage: pct,
      );
    }).toList();
  }

  /// Calcule la répartition des non-conformités par type d'installation / d'équipement.
  List<InstallationTypeItem> getInstallationTypeStats() {
    if (pertinentFindings.isEmpty) return [];

    final counts = <String, int>{};
    for (final f in pertinentFindings) {
      final typeStr = f.objectType.trim().isNotEmpty ? f.objectType.trim() : 'Installation';
      counts[typeStr] = (counts[typeStr] ?? 0) + 1;
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final tot = totalFindings;

    return sortedEntries.map((e) {
      final pct = tot > 0 ? (e.value / tot) * 100 : 0.0;
      return InstallationTypeItem(
        name: e.key,
        count: e.value,
        percentage: pct,
      );
    }).toList();
  }

  /// Calcule la répartition des non-conformités par domaine de tension (MT vs BT).
  TensionDomainStats getTensionDomainStats() {
    int mt = 0;
    int bt = 0;

    for (final f in pertinentFindings) {
      if (f.tensionDomain == TensionDomain.mt) {
        mt++;
      } else {
        bt++;
      }
    }

    final tot = pertinentFindings.length;
    final mtPct = tot > 0 ? (mt / tot) * 100 : 0.0;
    final btPct = tot > 0 ? (bt / tot) * 100 : 0.0;

    return TensionDomainStats(
      mtCount: mt,
      btCount: bt,
      totalCount: tot,
      mtPct: mtPct,
      btPct: btPct,
    );
  }

  /// Calcule l'analyse croisée par catégorie d'installation / d'équipement.
  List<CategoryCrossItem> getCrossCategoryAnalysis() {
    if (crossCategoryItems.isNotEmpty) {
      return crossCategoryItems;
    }

    // Fallback dynamique
    final items = <CategoryCrossItem>[];
    final mtLocauxFindings = findings.where((f) => f.objectType == 'Local MT').toList();
    final celluleFindings = findings.where((f) => f.objectType == 'Cellule MT').toList();
    final transfoFindings = findings.where((f) => f.objectType == 'Transformateur MT/BT').toList();
    final geLocauxFindings = findings.where((f) => f.objectType == 'Local BT' && (f.objectName.toLowerCase().contains('groupe') || f.origin.toLowerCase().contains('groupe'))).toList();
    final btLocauxFindings = findings.where((f) => f.objectType == 'Local BT' && !(f.objectName.toLowerCase().contains('groupe') || f.origin.toLowerCase().contains('groupe'))).toList();
    final tgbtFindings = findings.where((f) => f.objectType == 'TGBT').toList();
    final armoireFindings = findings.where((f) => f.objectType == 'Armoire').toList();
    final coffretFindings = findings.where((f) => f.objectType == 'Coffret').toList();
    final inverseurFindings = findings.where((f) => f.objectType == 'Inverseur').toList();

    CategoryCrossItem buildItem(String key, String catName, List<AuditFinding> list) {
      final ncCount = list.length;
      final cCount = list.where((f) => f.criticality == 'Critique').length;
      final mCount = list.where((f) => f.criticality == 'Majeure').length;
      final minCount = list.where((f) => f.criticality == 'Mineure').length;
      return CategoryCrossItem(
        categoryKey: key,
        categoryName: catName,
        equipmentCount: 1,
        totalPointsEvaluated: ncCount,
        compliantPointsCount: 0,
        nonCompliantPointsCount: ncCount,
        naPointsCount: 0,
        critiqueCount: cCount,
        majeureCount: mCount,
        mineureCount: minCount,
        complianceRate: 0.0,
        density: ncCount.toDouble(),
      );
    }

    if (mtLocauxFindings.isNotEmpty) items.add(buildItem('local_mt', 'Locaux techniques Moyenne Tension', mtLocauxFindings));
    if (btLocauxFindings.isNotEmpty) items.add(buildItem('local_bt', 'Locaux techniques Basse Tension', btLocauxFindings));
    if (geLocauxFindings.isNotEmpty) items.add(buildItem('local_ge', 'Locaux techniques Groupe Électrogène', geLocauxFindings));
    if (celluleFindings.isNotEmpty) items.add(buildItem('cellule_mt', 'Cellules MT', celluleFindings));
    if (transfoFindings.isNotEmpty) items.add(buildItem('transfo_mt_bt', 'Transformateurs MT/BT', transfoFindings));
    if (tgbtFindings.isNotEmpty) items.add(buildItem('tgbt', 'TGBT', tgbtFindings));
    if (armoireFindings.isNotEmpty) items.add(buildItem('armoire', 'Armoires', armoireFindings));
    if (coffretFindings.isNotEmpty) items.add(buildItem('coffret', 'Coffrets', coffretFindings));
    if (inverseurFindings.isNotEmpty) items.add(buildItem('inverseur', 'Inverseurs', inverseurFindings));

    return items;
  }

  /// Affiche le diagnostic certifié d'inventaire dans la console système stdout (print).
  void printDiagnostic() {
    print('================================================================================');
    print('📊 INVENTAIRE EXHAUSTIF DES NON-CONFORMITÉS — MISSION: $missionId');
    print('================================================================================');
    print('🔍 Total des non-conformités recensées : $totalFindings');
    print('--------------------------------------------------------------------------------');
    print('🔴 CRITIQUE  : $critiqueCount (${pctCritique.toStringAsFixed(1)}%)');
    print('🟠 MAJEURE   : $majeureCount (${pctMajeure.toStringAsFixed(1)}%)');
    print('🔵 MINEURE   : $mineureCount (${pctMineure.toStringAsFixed(1)}%)');
    if (unspecifiedCount > 0) {
      print('⚪ AUTRES    : $unspecifiedCount (Observations sans criticité normée)');
    }
    print('================================================================================');
  }

  /// Imprime l'inventaire complet ligne par ligne dans la console système.
  void printFullInventoryDetails() {
    printDiagnostic();
    print('--- DÉTAIL LIGNE PAR LIGNE DES $totalFindings OCCURRENCES ---');
    for (var i = 0; i < findings.length; i++) {
      final f = findings[i];
      print('[#${i + 1}] [${f.criticality.toUpperCase()}] ${f.origin} > ${f.objectType} "${f.objectName}" > ${f.tableName} | Point: ${f.verificationPoint} | Constat: ${f.observationText}');
    }
    print('================================================================================');
  }

  /// Calcule l'inventaire chiffré de toutes les installations et équipements enregistrés dans la mission.
  static List<EquipmentInventoryItem> computeEquipmentInventory(String missionId) {
    try {
      final domainInventory = MissionDomainInventoryEngine.buildInventory(missionId);
      return domainInventory.getEquipmentInventorySummary();
    } catch (_) {
      return [];
    }
  }
}
