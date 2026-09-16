// lib/services/statistics/statistical_synthesis_engine.dart

import 'audit_finding.dart';
import 'mission_statistics.dart';
import 'technical_enrichment_engine.dart';

/// Bloc d'enseignement statistique typé pour la synthèse de la section 6.
enum StatisticalSynthesisBlockType {
  perimeterAndCriticality,
  tensionAndCategoryVulnerabilities,
  riskFamiliesDistribution,
  paretoAndDefectTypology,
  technicalDeficitAndTraceability,
  strategicConclusion,
  zeroDefectConfirmation,
}

/// Élément structuré de la synthèse statistique.
class StatisticalSynthesisBlock {
  final StatisticalSynthesisBlockType type;
  final String title;
  final String content;

  const StatisticalSynthesisBlock({
    required this.type,
    required this.title,
    required this.content,
  });
}

/// Profil statistique pivot consolidé avant génération narrative.
/// Il centralise l'ensemble des faits établis par les sous-sections précédentes.
class StatisticalSynthesisProfile {
  final int totalFindings;
  final int totalEquipments;
  final double globalDensity;
  final String globalDensityStr;

  // Criticité
  final int critiqueCount;
  final int majeureCount;
  final int mineureCount;
  final double pctCritique;
  final double pctMajeure;
  final double pctMineure;

  // Domaine de tension
  final int mtCount;
  final int btCount;
  final double mtPct;
  final double btPct;
  final bool isBtDominant;
  final bool isMtDominant;
  final bool isTensionBalanced;

  // Vulnérabilités catégorielles
  final List<CategoryCrossAuditRow> notableHighCritCategories;

  // Familles de risque
  final List<RiskFamilyItem> sortedRiskFamilies;

  // Pareto & Concentration
  final int top10Count;
  final int top10Sum;
  final double top10Pct;
  final ParetoConcentrationProfile paretoProfile;
  final List<TopDefectItem> topParetoItems;

  // Déficit technique & documentaire
  final int unidentifiedSourcesCount;
  final int missingCoupureTeteCount;
  final int unrecordedIpIkCount;
  final bool hasTechnicalDeficit;

  const StatisticalSynthesisProfile({
    required this.totalFindings,
    required this.totalEquipments,
    required this.globalDensity,
    required this.globalDensityStr,
    required this.critiqueCount,
    required this.majeureCount,
    required this.mineureCount,
    required this.pctCritique,
    required this.pctMajeure,
    required this.pctMineure,
    required this.mtCount,
    required this.btCount,
    required this.mtPct,
    required this.btPct,
    required this.isBtDominant,
    required this.isMtDominant,
    required this.isTensionBalanced,
    required this.notableHighCritCategories,
    required this.sortedRiskFamilies,
    required this.top10Count,
    required this.top10Sum,
    required this.top10Pct,
    required this.paretoProfile,
    required this.topParetoItems,
    required this.unidentifiedSourcesCount,
    required this.missingCoupureTeteCount,
    required this.unrecordedIpIkCount,
    required this.hasTechnicalDeficit,
  });
}

/// Résultat complet de la synthèse analytique de la section 6.
class StatisticalSynthesisResult {
  final StatisticalSynthesisProfile profile;
  final List<String> paragraphs;
  final List<StatisticalSynthesisBlock> blocks;

  const StatisticalSynthesisResult({
    required this.profile,
    required this.paragraphs,
    required this.blocks,
  });

  /// Texte intégral assemblé avec double saut de ligne
  String get fullNarrativeText => paragraphs.join('\n\n');
}

/// Moteur d'analyse statistique transversale déterministe et adaptatif.
/// Construit la sous-section « 6. Synthèse de l’analyse statistique ».
class StatisticalSynthesisEngine {
  /// Point d'entrée analytique principal
  static StatisticalSynthesisResult analyze({
    required MissionStatisticsSummary summary,
    TechnicalEnrichmentResult? technical,
  }) {
    final tech = technical ?? summary.technical;
    final profile = _buildProfile(summary, tech);

    if (profile.totalFindings == 0) {
      return _buildZeroDefectResult(profile);
    }

    if (profile.totalFindings <= 3) {
      return _buildLowVolumeResult(profile);
    }

    return _buildStandardNarrativeResult(profile);
  }

  /// 1. Construction du profil statistique consolidé
  static StatisticalSynthesisProfile _buildProfile(
    MissionStatisticsSummary summary,
    TechnicalEnrichmentResult technical,
  ) {
    final totalFindings = summary.totalNC > 0 ? summary.totalNC : summary.criticalityStats.total;
    final totalEquipments = summary.totalEquipments;
    final density = totalEquipments > 0 ? totalFindings / totalEquipments : 0.0;
    final densityStr = density.toStringAsFixed(2).replaceAll('.', ',');

    final cStats = summary.criticalityStats;
    final tStats = summary.tensionDomainStats;

    final mtCount = tStats.mtCount;
    final btCount = tStats.btCount;
    final totalTension = (mtCount + btCount) > 0 ? (mtCount + btCount) : totalFindings;
    final mtPct = totalTension > 0 ? (mtCount / totalTension * 100) : 0.0;
    final btPct = totalTension > 0 ? (btCount / totalTension * 100) : 0.0;

    final isBtDominant = btCount >= (mtCount * 2) && btCount > 0;
    final isMtDominant = mtCount >= (btCount * 2) && mtCount > 0;
    final isTensionBalanced = !isBtDominant && !isMtDominant && mtCount > 0 && btCount > 0;

    // Catégories à sévérité remarquable (taux critique le plus élevé avec volume significatif)
    final allRows = <CategoryCrossAuditRow>[
      ...technical.mtCategoriesCrossRows,
      ...technical.btCategoriesCrossRows,
    ];

    // Seuil minimal d'anomalies pour considérer le taux de criticité comme représentatif
    final minNcThreshold = totalFindings >= 50 ? 5 : (totalFindings >= 10 ? 2 : 1);
    final sortedByCrit = List<CategoryCrossAuditRow>.from(allRows.where((r) => r.ncCount >= minNcThreshold))
      ..sort((a, b) => b.tauxCritique.compareTo(a.tauxCritique));

    final notableCats = sortedByCrit.where((r) => r.tauxCritique >= 20.0).take(2).toList();
    if (notableCats.isEmpty && sortedByCrit.isNotEmpty && sortedByCrit.first.tauxCritique > 0) {
      notableCats.add(sortedByCrit.first);
    }

    // Familles de risque triées par fréquence
    final sortedFamilies = List<RiskFamilyItem>.from(summary.riskFamilyStats)
      ..sort((a, b) => b.count.compareTo(a.count));

    // Pareto & concentration
    final paretoItems = summary.paretoResult.items;
    final top10Items = paretoItems.take(10).toList();
    final top10Sum = top10Items.fold<int>(0, (s, e) => s + e.count);
    final top10Pct = totalFindings > 0 ? (top10Sum / totalFindings * 100) : 0.0;

    // Déficit technique & traçabilité
    int unidentifiedSources = 0;
    for (final s in technical.sourceStats.values) {
      unidentifiedSources += s.nonIdentifiees;
    }

    int missingCoupure = 0;
    for (final c in technical.coupureTeteStats.values) {
      missingCoupure += c.absents;
    }

    int unrecordedIpIk = 0;
    for (final ip in technical.ipIkZoneItems) {
      unrecordedIpIk += ip.nonRenseignes;
    }

    final hasDeficit = unidentifiedSources > 0 || missingCoupure > 0 || unrecordedIpIk > 0;

    return StatisticalSynthesisProfile(
      totalFindings: totalFindings,
      totalEquipments: totalEquipments,
      globalDensity: density,
      globalDensityStr: densityStr,
      critiqueCount: cStats.critique,
      majeureCount: cStats.majeure,
      mineureCount: cStats.mineure,
      pctCritique: cStats.pctCritique,
      pctMajeure: cStats.pctMajeure,
      pctMineure: cStats.pctMineure,
      mtCount: mtCount,
      btCount: btCount,
      mtPct: mtPct,
      btPct: btPct,
      isBtDominant: isBtDominant,
      isMtDominant: isMtDominant,
      isTensionBalanced: isTensionBalanced,
      notableHighCritCategories: notableCats,
      sortedRiskFamilies: sortedFamilies,
      top10Count: top10Items.length,
      top10Sum: top10Sum,
      top10Pct: top10Pct,
      paretoProfile: summary.paretoResult.profile,
      topParetoItems: top10Items,
      unidentifiedSourcesCount: unidentifiedSources,
      missingCoupureTeteCount: missingCoupure,
      unrecordedIpIkCount: unrecordedIpIk,
      hasTechnicalDeficit: hasDeficit,
    );
  }

  /// 2. Cas particulier : 0 Non-Conformité (100 % conforme)
  static StatisticalSynthesisResult _buildZeroDefectResult(StatisticalSynthesisProfile p) {
    final p1 = 'L’analyse statistique des constats met en évidence un **excellent niveau global de maîtrise du risque électrique et de conformité réglementaire**. Sur l’ensemble du périmètre audité (${p.totalEquipments} équipement${p.totalEquipments > 1 ? "s" : ""} recensé${p.totalEquipments > 1 ? "s" : ""}), aucune non-conformité n’a été relevée, ce qui correspond à une densité nulle de **0,00 non-conformité par équipement**.';
    final p2 = 'Cette situation témoigne d’une rigueur soutenue dans les opérations d’exploitation et de maintenance préventive. **En conclusion**, les préconisations portent sur la préservation active de ce niveau d’exigence à travers la reconduction régulière des vérifications périodiques réglementaires.';

    final blocks = [
      StatisticalSynthesisBlock(
        type: StatisticalSynthesisBlockType.zeroDefectConfirmation,
        title: 'Maîtrise globale du risque',
        content: p1,
      ),
      StatisticalSynthesisBlock(
        type: StatisticalSynthesisBlockType.strategicConclusion,
        title: 'Orientation du plan d’actions',
        content: p2,
      ),
    ];

    return StatisticalSynthesisResult(
      profile: p,
      paragraphs: [p1, p2],
      blocks: blocks,
    );
  }

  /// 3. Cas particulier : Très faible volume (1 à 3 NC)
  static StatisticalSynthesisResult _buildLowVolumeResult(StatisticalSynthesisProfile p) {
    final critStr = p.pctCritique.toStringAsFixed(1).replaceAll('.', ',');
    final majStr = p.pctMajeure.toStringAsFixed(1).replaceAll('.', ',');
    final minStr = p.pctMineure.toStringAsFixed(1).replaceAll('.', ',');

    final String critText;
    if (p.critiqueCount == 0 && p.majeureCount == 0) {
      critText = 'L’intégralité des écarts constatés relève exclusivement du niveau de **gravité mineure** ($minStr %), sans incidence directe sur la sécurité immédiate des biens ou des personnes.';
    } else if (p.critiqueCount > 0) {
      critText = 'Bien que le volume global soit très restreint, il convient de noter la présence de **${p.critiqueCount} écart(s) critique(s)** ($critStr %), exigeant une intervention corrective prioritaire sans délai.';
    } else {
      critText = 'Les défaillances constatées relèvent d’une criticité **majeure** ($majStr %), sans dérive critique immédiate.';
    }

    final p1 = 'L’analyse statistique des constats met en évidence un **niveau global de maîtrise du risque électrique satisfaisant**, caractérisé par un volume très limité de **${p.totalFindings} non-conformité${p.totalFindings > 1 ? "s" : ""}** sur l’ensemble du parc (${p.globalDensityStr} non-conformité par équipement). $critText';

    final p2 = '**En conclusion**, le profil statistique très circonscrit de la mission permet d’orienter le plan d’actions vers une résolution ciblée et rapide des points relevés, tout en intégrant leur suivi dans les tournées de maintenance courantes.';

    final blocks = [
      StatisticalSynthesisBlock(
        type: StatisticalSynthesisBlockType.perimeterAndCriticality,
        title: 'Périmètre et criticité restreints',
        content: p1,
      ),
      StatisticalSynthesisBlock(
        type: StatisticalSynthesisBlockType.strategicConclusion,
        title: 'Conclusion opérationnelle',
        content: p2,
      ),
    ];

    return StatisticalSynthesisResult(
      profile: p,
      paragraphs: [p1, p2],
      blocks: blocks,
    );
  }

  /// 4. Cas général : Synthèse narrative complète et adaptative
  static StatisticalSynthesisResult _buildStandardNarrativeResult(StatisticalSynthesisProfile p) {
    final paragraphs = <String>[];
    final blocks = <StatisticalSynthesisBlock>[];

    // ── PARAGRAPHE 1 : Périmètre, volume, densité et ventilation de criticité ──
    final p1 = _buildParagraph1PerimeterAndCriticality(p);
    paragraphs.add(p1);
    blocks.add(StatisticalSynthesisBlock(
      type: StatisticalSynthesisBlockType.perimeterAndCriticality,
      title: 'Périmètre, densité et criticité',
      content: p1,
    ));

    // ── PARAGRAPHE 2 : Domaine de tension et vulnérabilités catégorielles ──
    final p2 = _buildParagraph2TensionAndCategories(p);
    paragraphs.add(p2);
    blocks.add(StatisticalSynthesisBlock(
      type: StatisticalSynthesisBlockType.tensionAndCategoryVulnerabilities,
      title: 'Domaine de tension et vulnérabilités catégorielles',
      content: p2,
    ));

    // ── PARAGRAPHE 3 : Analyse des familles de risques ──
    if (p.sortedRiskFamilies.isNotEmpty) {
      final p3 = _buildParagraph3RiskFamilies(p);
      paragraphs.add(p3);
      blocks.add(StatisticalSynthesisBlock(
        type: StatisticalSynthesisBlockType.riskFamiliesDistribution,
        title: 'Répartition par familles de risques',
        content: p3,
      ));
    }

    // ── PARAGRAPHE 4 : Pareto et typologie des défaillances ──
    if (p.topParetoItems.isNotEmpty) {
      final p4 = _buildParagraph4Pareto(p);
      paragraphs.add(p4);
      blocks.add(StatisticalSynthesisBlock(
        type: StatisticalSynthesisBlockType.paretoAndDefectTypology,
        title: 'Concentration et typologie des défaillances',
        content: p4,
      ));
    }

    // ── PARAGRAPHE 5 : Déficit de données techniques et traçabilité ──
    if (p.hasTechnicalDeficit) {
      final p5 = _buildParagraph5TechnicalDeficit(p);
      paragraphs.add(p5);
      blocks.add(StatisticalSynthesisBlock(
        type: StatisticalSynthesisBlockType.technicalDeficitAndTraceability,
        title: 'Déficit documentaire et traçabilité',
        content: p5,
      ));
    }

    // ── PARAGRAPHE 6 : Conclusion stratégique et plan d'actions ──
    final p6 = _buildParagraph6StrategicConclusion(p);
    paragraphs.add(p6);
    blocks.add(StatisticalSynthesisBlock(
      type: StatisticalSynthesisBlockType.strategicConclusion,
      title: 'Conclusion statistique et orientations',
      content: p6,
    ));

    return StatisticalSynthesisResult(
      profile: p,
      paragraphs: paragraphs,
      blocks: blocks,
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  MÉTHODES DE CONSTRUCTION NARRATIVE DÉTAILLÉES
  // ──────────────────────────────────────────────────────────────

  /// Construction du paragraphe 1 : Périmètre, volume, densité et criticité
  static String _buildParagraph1PerimeterAndCriticality(StatisticalSynthesisProfile p) {
    // Qualification du niveau global
    final String levelQualification;
    if (p.critiqueCount == 0 && p.pctMajeure <= 20.0 && p.globalDensity < 1.0) {
      levelQualification = 'un **niveau global de maîtrise du risque électrique satisfaisant avec des dérives mineures ponctuelles**';
    } else if (p.critiqueCount == 0 && p.pctMajeure > 20.0) {
      levelQualification = 'un **niveau global de risque électrique modéré nécessitant des interventions planifiées**';
    } else if (p.pctCritique >= 35.0 || p.globalDensity >= 6.0 || p.critiqueCount >= 150) {
      levelQualification = 'un **niveau global de risque électrique particulièrement élevé nécessitant des mesures correctives urgentes**';
    } else {
      levelQualification = 'un **niveau global de maîtrise du risque électrique qui demeure insuffisant**';
    }

    final pctCritStr = p.pctCritique.toStringAsFixed(1).replaceAll('.', ',');
    final pctMajStr = p.pctMajeure.toStringAsFixed(1).replaceAll('.', ',');
    final pctMinStr = p.pctMineure.toStringAsFixed(1).replaceAll('.', ',');

    final String critDistributionText;
    if (p.mineureCount == 0) {
      if (p.critiqueCount > 0 && p.majeureCount > 0) {
        critDistributionText = 'La totalité des écarts recensés relève des deux niveaux de criticité les plus élevés : **$pctCritStr % de non-conformités critiques et $pctMajStr % de non-conformités majeures**, sans aucune non-conformité classée mineure.';
      } else if (p.critiqueCount > 0) {
        critDistributionText = 'La totalité des écarts recensés (**100 %**) relève exclusivement d’une criticité **critique**, sans aucune non-conformité majeure ou mineure.';
      } else {
        critDistributionText = 'La totalité des écarts recensés (**100 %**) relève d’une criticité **majeure**, sans non-conformité critique immédiate.';
      }
    } else {
      critDistributionText = 'La ventilation par criticité s’établit à **$pctCritStr % de non-conformités critiques**, **$pctMajStr % de non-conformités majeures** et **$pctMinStr % d’écarts classés mineurs**.';
    }

    return 'L’analyse statistique des constats met en évidence $levelQualification, avec une densité moyenne de **${p.globalDensityStr} non-conformités par équipement**. $critDistributionText';
  }

  /// Construction du paragraphe 2 : Domaine de tension et vulnérabilités catégorielles
  static String _buildParagraph2TensionAndCategories(StatisticalSynthesisProfile p) {
    final btPctStr = p.btPct.toStringAsFixed(1).replaceAll('.', ',');
    final mtPctStr = p.mtPct.toStringAsFixed(1).replaceAll('.', ',');

    String tensionPart;
    if (p.mtCount > 0 && p.btCount > 0) {
      if (p.isBtDominant) {
        tensionPart = 'La répartition par domaine de tension montre une prédominance des écarts en **Basse Tension ($btPctStr %)** contre **$mtPctStr % en HTA**.';
      } else if (p.isMtDominant) {
        tensionPart = 'La répartition par domaine de tension met en exergue une forte prépondérance des anomalies sur le réseau **Moyenne Tension ($mtPctStr %)** contre **$btPctStr % en Basse Tension**.';
      } else {
        tensionPart = 'La répartition par domaine de tension met en évidence une distribution équilibrée entre la **Basse Tension ($btPctStr %)** et la **Moyenne Tension ($mtPctStr %)**.';
      }
    } else if (p.btCount > 0) {
      tensionPart = 'L’intégralité des non-conformités recensées (**100 %**) concerne le domaine de la **Basse Tension (BT)**.';
    } else {
      tensionPart = 'L’intégralité des non-conformités recensées (**100 %**) concerne le domaine de la **Moyenne Tension (HTA)**.';
    }

    // Analyse des catégories aux taux de criticité remarquables
    String categoryPart = '';
    if (p.notableHighCritCategories.isNotEmpty) {
      if (p.notableHighCritCategories.length >= 2) {
        final cat1 = p.notableHighCritCategories[0];
        final cat2 = p.notableHighCritCategories[1];
        categoryPart = ' Toutefois, l’analyse par densité et par criticité révèle que certaines catégories présentent un niveau de vulnérabilité particulièrement important, notamment les **${cat1.categoryName.toLowerCase()}** et les **${cat2.categoryName.toLowerCase()}**, avec respectivement **${cat1.tauxCritiqueStr} et ${cat2.tauxCritiqueStr} de non-conformités critiques**.';
      } else {
        final cat1 = p.notableHighCritCategories.first;
        categoryPart = ' Toutefois, l’analyse par criticité fait ressortir une vulnérabilité particulièrement marquée sur les **${cat1.categoryName.toLowerCase()}**, affichant un taux de criticité de **${cat1.tauxCritiqueStr} d’écarts critiques**.';
      }
    }

    return '$tensionPart$categoryPart';
  }

  /// Construction du paragraphe 3 : Analyse des familles de risques
  static String _buildParagraph3RiskFamilies(StatisticalSynthesisProfile p) {
    final top1 = p.sortedRiskFamilies.first;
    final top1PctStr = top1.percentage.toStringAsFixed(1).replaceAll('.', ',');

    final isExploitationTop = top1.name.toLowerCase().contains('exploitation') ||
        top1.name.toLowerCase().contains('maintenance');

    if (p.sortedRiskFamilies.length >= 2) {
      final top2 = p.sortedRiskFamilies[1];
      final top2PctStr = top2.percentage.toStringAsFixed(1).replaceAll('.', ',');

      if (isExploitationTop) {
        return 'L’analyse par familles de risques confirme que les écarts sont principalement associés aux **pratiques d’exploitation et de maintenance**, qui représentent **$top1PctStr % des occurrences**, suivies par la **${top2.name.toLowerCase()}**, à hauteur de **$top2PctStr %**. Ces deux familles concentrent ainsi l’essentiel des situations nécessitant une action corrective et préventive.';
      } else {
        return 'L’analyse par familles de risques met en évidence une concentration des anomalies sur la **${top1.name.toLowerCase()}**, représentant **$top1PctStr % des occurrences**, suivie par la **${top2.name.toLowerCase()}** avec **$top2PctStr % des constats**. Ces deux axes constituent les priorités d’action pour l’intégrité des installations.';
      }
    } else {
      return 'L’analyse par familles de risques démontre une prépondérance absolue de la famille **${top1.name.toLowerCase()}**, qui regroupe **$top1PctStr % des défaillances recensées** sur le site.';
    }
  }

  /// Construction du paragraphe 4 : Pareto et typologie des défaillances
  static String _buildParagraph4Pareto(StatisticalSynthesisProfile p) {
    final top10PctStr = p.top10Pct.toStringAsFixed(1).replaceAll('.', ',');
    final items = p.topParetoItems;

    // 1. Profil mono-défaut dominant
    if (p.paretoProfile == ParetoConcentrationProfile.singleDominant && items.isNotEmpty) {
      final mainItem = items.first;
      final pctStr = mainItem.percentage.toStringAsFixed(1).replaceAll('.', ',');
      return 'L’analyse de Pareto fait ressortir une prédominance nette de l’anomalie **« ${mainItem.title} »**, qui totalise à elle seule **${mainItem.count} constats ($pctStr %)**, constituant la priorité technique immédiate.';
    }

    // 2. Profil concentré : calculé par Pareto ou si les 2 premiers items pèsent lourd (>= 40%)
    final isConcentrated = p.paretoProfile == ParetoConcentrationProfile.highConcentration ||
        p.paretoProfile == ParetoConcentrationProfile.moderateConcentration ||
        (items.length >= 2 && (items[0].percentage + items[1].percentage) >= 40.0);

    if (isConcentrated && items.length >= 2) {
      final cat1Name = items[0].title.toLowerCase();
      final cat2Name = items[1].title.toLowerCase();
      return 'L’analyse de Pareto confirme par ailleurs que les **${p.top10Count} principales catégories de non-conformités représentent ${p.top10Sum} constats, soit $top10PctStr % du total**. Les deux premières catégories — **$cat1Name** et **$cat2Name** — représentent à elles seules une part importante des écarts recensés.';
    }

    // 3. Profil dispersé ou seuil non atteint
    if (p.paretoProfile == ParetoConcentrationProfile.homogeneousOrDispersed ||
        p.paretoProfile == ParetoConcentrationProfile.thresholdNotReached) {
      return 'L’analyse de Pareto met en évidence une **distribution relativement dispersée des non-conformités** entre les points de vérification, traduisant l’absence de cause unique prépondérante. Les ${p.top10Count} principales catégories regroupent **${p.top10Sum} constats ($top10PctStr % du total)**, ce qui implique une démarche de remise à niveau globale plutôt qu’une intervention circonscrite.';
    }

    if (items.isNotEmpty) {
      final mainItem = items.first;
      final pctStr = mainItem.percentage.toStringAsFixed(1).replaceAll('.', ',');
      return 'L’analyse de Pareto fait ressortir une prédominance nette de l’anomalie **« ${mainItem.title} »**, qui totalise à elle seule **${mainItem.count} constats ($pctStr %)**, constituant la priorité technique immédiate.';
    }

    return 'L’analyse de la distribution des défaillances met en évidence une concentration des écarts sur les ${p.top10Count} premières catégories de vérification (${p.top10Sum} constats, soit $top10PctStr % du total).';
  }

  /// Construction du paragraphe 5 : Déficit de données techniques et traçabilité
  static String _buildParagraph5TechnicalDeficit(StatisticalSynthesisProfile p) {
    final deficitItems = <String>[];
    if (p.unidentifiedSourcesCount > 0) {
      deficitItems.add('les sources d’alimentation');
    }
    if (p.unrecordedIpIkCount > 0) {
      deficitItems.add('les indices IP/IK');
    }
    if (p.missingCoupureTeteCount > 0) {
      deficitItems.add('l’identification des dispositifs de coupure');
    }

    final String deficitText;
    if (deficitItems.isEmpty) {
      deficitText = 'la documentation technique';
    } else if (deficitItems.length == 1) {
      deficitText = deficitItems.first;
    } else if (deficitItems.length == 2) {
      deficitText = '${deficitItems[0]} et ${deficitItems[1]}';
    } else {
      deficitText = '${deficitItems.sublist(0, deficitItems.length - 1).join(', ')} et ${deficitItems.last}';
    }

    return 'Enfin, l’analyse met en évidence un **déficit important de données techniques et de traçabilité**, notamment concernant $deficitText. Cette situation constitue non seulement une faiblesse documentaire, mais également un **facteur de risque pour les opérations d’exploitation, de dépannage et de maintenance**.';
  }

  /// Construction du paragraphe 6 : Conclusion stratégique et plan d'actions
  static String _buildParagraph6StrategicConclusion(StatisticalSynthesisProfile p) {
    if (p.critiqueCount > 0) {
      return '**En conclusion**, les résultats orientent prioritairement le plan d’actions vers la fiabilisation des installations, l’amélioration des pratiques d’exploitation et de maintenance, la remise à niveau du câblage et des protections, ainsi que la reconstruction d’une documentation technique fiable et tenue à jour.';
    } else {
      return '**En conclusion**, l’effort doit être concentré sur la résorption ordonnée des non-conformités majeures, l’harmonisation des pratiques d’entretien préventif et la fiabilisation continue du dossier technique des installations.';
    }
  }
}
