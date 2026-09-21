// lib/services/statistics/global_assessment_engine.dart

import 'audit_finding.dart';
import 'hierarchical_recommendations_engine.dart';
import 'mission_statistics.dart';
import 'technical_enrichment_engine.dart';
import '../ai/executive_summary_snapshot.dart';

/// Profil de diagnostic global de la mission
enum GlobalRiskProfileLevel {
  excellentOrZeroDefect,
  controlledWithMinorDeviations,
  moderateRiskNeedingAction,
  significantImprovementRequired,
  criticalHighRisk,
}

/// Éléments structurés résultant de l'analyse globale de la mission
class GlobalAssessmentResult {
  final GlobalRiskProfileLevel riskLevel;
  final String perimeterAndCriticalityText;
  final String? riskFamiliesText;
  final List<String> technicalWeaknessesBullets;
  final String? technicalDeficitText;
  final String? paretoOrTensionText;
  final String operationalPrioritiesText;
  final String finalAppreciationText;

  const GlobalAssessmentResult({
    required this.riskLevel,
    required this.perimeterAndCriticalityText,
    this.riskFamiliesText,
    this.technicalWeaknessesBullets = const [],
    this.technicalDeficitText,
    this.paretoOrTensionText,
    required this.operationalPrioritiesText,
    required this.finalAppreciationText,
  });

  /// Retourne l'ensemble des blocs de contenu ordonnés pour le rendu
  List<GlobalAssessmentBlock> get blocks {
    final list = <GlobalAssessmentBlock>[];

    // 1. Périmètre & Criticité
    list.add(GlobalAssessmentBlock(
      type: GlobalAssessmentBlockType.paragraph,
      content: perimeterAndCriticalityText,
    ));

    // 2. Familles de risques dominantes (si non-conformités)
    if (riskFamiliesText != null && riskFamiliesText!.trim().isNotEmpty) {
      list.add(GlobalAssessmentBlock(
        type: GlobalAssessmentBlockType.paragraph,
        content: riskFamiliesText!,
      ));
    }

    // 3. Faiblesses techniques réelles (sous forme de puces)
    if (technicalWeaknessesBullets.isNotEmpty) {
      list.add(GlobalAssessmentBlock(
        type: GlobalAssessmentBlockType.bulletsIntro,
        content: 'Sur le plan technique, les principales faiblesses concernent notamment :',
      ));
      for (final bullet in technicalWeaknessesBullets) {
        list.add(GlobalAssessmentBlock(
          type: GlobalAssessmentBlockType.bulletItem,
          content: bullet,
        ));
      }
    }

    // 4. Déficit documentaire et technique
    if (technicalDeficitText != null && technicalDeficitText!.trim().isNotEmpty) {
      list.add(GlobalAssessmentBlock(
        type: GlobalAssessmentBlockType.paragraph,
        content: technicalDeficitText!,
      ));
    }

    // 5. Asymétrie HTA/BT ou analyse Pareto spécifique (si remarquable)
    if (paretoOrTensionText != null && paretoOrTensionText!.trim().isNotEmpty) {
      list.add(GlobalAssessmentBlock(
        type: GlobalAssessmentBlockType.paragraph,
        content: paretoOrTensionText!,
      ));
    }

    // 6. Enjeux opérationnels & priorisation chiffrée
    list.add(GlobalAssessmentBlock(
      type: GlobalAssessmentBlockType.paragraph,
      content: operationalPrioritiesText,
    ));

    // 7. Conclusion & Appréciation finale
    list.add(GlobalAssessmentBlock(
      type: GlobalAssessmentBlockType.conclusion,
      content: finalAppreciationText,
    ));

    return list;
  }
}

enum GlobalAssessmentBlockType {
  paragraph,
  bulletsIntro,
  bulletItem,
  conclusion,
}

class GlobalAssessmentBlock {
  final GlobalAssessmentBlockType type;
  final String content;

  const GlobalAssessmentBlock({
    required this.type,
    required this.content,
  });
}

/// Moteur d'analyse globale et de synthèse de la section « 12. Appréciation globale »
class GlobalAssessmentEngine {
  /// Analyse complète de la mission et construction de la synthèse dynamique
  static GlobalAssessmentResult analyze({
    required MissionStatisticsSummary summary,
    required ExecutiveSummarySnapshot snapshot,
    TechnicalEnrichmentResult? technical,
    HierarchicalRecommendationsResult? recommendationsResult,
  }) {
    final tech = technical ?? summary.technical;
    final recoResult = recommendationsResult ?? HierarchicalRecommendationsEngine.analyze(summary);
    final totalNc = summary.totalNC > 0 ? summary.totalNC : summary.criticalityStats.total;
    final cStats = summary.criticalityStats;
    final densityStr = summary.globalDensityStr;

    // Nom du client / site
    final client = snapshot.clientName.trim();
    final site = snapshot.siteName.trim();
    final String clientSiteLabel;
    if (site.isEmpty || site.toLowerCase() == client.toLowerCase()) {
      clientSiteLabel = client.isNotEmpty ? client : 'l\'établissement';
    } else if (site.toLowerCase().contains(client.toLowerCase())) {
      clientSiteLabel = site;
    } else {
      clientSiteLabel = '$client – $site';
    }

    // 1. Détermination du niveau de risque global
    final riskLevel = _evaluateRiskLevel(summary);

    // 2. PARAGRAPHE 1 : Contexte périmètre, volume global et criticité
    final p1 = _buildPerimeterAndCriticalityParagraph(
      clientSiteLabel: clientSiteLabel,
      summary: summary,
      totalNc: totalNc,
      densityStr: densityStr,
      cStats: cStats,
      riskLevel: riskLevel,
    );

    // Si aucune non-conformité (mission 100 % conforme)
    if (totalNc == 0) {
      return GlobalAssessmentResult(
        riskLevel: riskLevel,
        perimeterAndCriticalityText: p1,
        operationalPrioritiesText:
            'En l\'absence de non-conformité constatée lors des vérifications, l\'enjeu opérationnel principal réside dans la **préservation de ce haut niveau d\'exigence et de conformité**. Il est recommandé de maintenir rigoureusement la périodicité des contrôles réglementaires et de poursuivre les démarches de maintenance préventive.',
        finalAppreciationText:
            '**Appréciation finale :** l\'installation présente un **excellent niveau de conformité technique et réglementaire**. La pérennité de cette situation repose sur la continuité des bonnes pratiques d\'exploitation et le maintien de la vigilance des équipes techniques.',
      );
    }

    // 3. PARAGRAPHE 2 : Vulnérabilités humaines/organisationnelles vs physiques
    final p2 = _buildRiskFamiliesParagraph(summary);

    // 4. BULLETS : Faiblesses techniques réelles identifiées
    final technicalBullets = _extractTechnicalWeaknesses(summary, tech);

    // 5. PARAGRAPHE 3 : Déficit de données techniques et documentaires
    final p3 = _buildTechnicalDeficitParagraph(tech);

    // 6. PARAGRAPHE 4 : Asymétrie HTA/BT ou dispersion Pareto
    final p4TensionOrPareto = _buildTensionOrParetoObservation(summary);

    // 7. PARAGRAPHE 5 : Enjeux opérationnels chiffrés et alignés sur les recommandations de la Section 11
    final p5Operational = _buildOperationalPrioritiesParagraph(summary, cStats, recoResult);

    // 8. PARAGRAPHE FINAL : Appréciation finale proportionnée
    final p6Final = _buildFinalAppreciationParagraph(summary, riskLevel);

    return GlobalAssessmentResult(
      riskLevel: riskLevel,
      perimeterAndCriticalityText: p1,
      riskFamiliesText: p2,
      technicalWeaknessesBullets: technicalBullets,
      technicalDeficitText: p3,
      paretoOrTensionText: p4TensionOrPareto,
      operationalPrioritiesText: p5Operational,
      finalAppreciationText: p6Final,
    );
  }

  /// Évalue le niveau global de maîtrise des risques
  static GlobalRiskProfileLevel _evaluateRiskLevel(MissionStatisticsSummary summary) {
    final totalNc = summary.totalNC > 0 ? summary.totalNC : summary.criticalityStats.total;
    if (totalNc == 0) return GlobalRiskProfileLevel.excellentOrZeroDefect;

    final cStats = summary.criticalityStats;
    final density = summary.globalDensity;

    if (cStats.critique == 0 && cStats.pctMajeure <= 20 && density < 1.0) {
      return GlobalRiskProfileLevel.controlledWithMinorDeviations;
    }
    if (cStats.critique == 0 && cStats.pctMajeure > 20) {
      return GlobalRiskProfileLevel.moderateRiskNeedingAction;
    }
    if (cStats.pctCritique >= 35 || density >= 6.0 || (cStats.critique >= 150)) {
      return GlobalRiskProfileLevel.criticalHighRisk;
    }
    return GlobalRiskProfileLevel.significantImprovementRequired;
  }

  /// Construction du paragraphe 1 : Périmètre, volume et criticité
  static String _buildPerimeterAndCriticalityParagraph({
    required String clientSiteLabel,
    required MissionStatisticsSummary summary,
    required int totalNc,
    required String densityStr,
    required CriticalityStats cStats,
    required GlobalRiskProfileLevel riskLevel,
  }) {
    if (totalNc == 0) {
      return 'La vérification périodique des installations électriques de **$clientSiteLabel** met en évidence un **niveau de maîtrise du risque électrique très satisfaisant**. Sur l\'ensemble du périmètre contrôlé, aucune non-conformité n\'a été recensée, attestant d\'un suivi régulier des installations.';
    }

    final String riskQualification;
    switch (riskLevel) {
      case GlobalRiskProfileLevel.excellentOrZeroDefect:
        riskQualification = 'un **niveau de maîtrise du risque électrique très satisfaisant**';
        break;
      case GlobalRiskProfileLevel.controlledWithMinorDeviations:
        riskQualification = 'un **niveau de maîtrise du risque électrique globalement satisfaisant avec des écarts mineurs ponctuels**';
        break;
      case GlobalRiskProfileLevel.moderateRiskNeedingAction:
        riskQualification = 'un **niveau de risque modéré nécessitant des actions correctives planifiées**';
        break;
      case GlobalRiskProfileLevel.significantImprovementRequired:
        riskQualification = 'un **niveau de maîtrise du risque électrique nécessitant une amélioration significative**';
        break;
      case GlobalRiskProfileLevel.criticalHighRisk:
        riskQualification = 'un **niveau de risque électrique particulièrement élevé nécessitant des mesures correctives urgentes**';
        break;
    }

    final pctCritStr = cStats.pctCritique.toStringAsFixed(1).replaceAll('.', ',');
    final pctMajStr = cStats.pctMajeure.toStringAsFixed(1).replaceAll('.', ',');
    final pctMinStr = cStats.pctMineure.toStringAsFixed(1).replaceAll('.', ',');

    final String critDistributionText;
    if (cStats.mineure == 0) {
      if (cStats.critique > 0 && cStats.majeure > 0) {
        critDistributionText = 'La répartition par criticité montre que **$pctCritStr % des écarts sont critiques et $pctMajStr % majeurs**, aucune non-conformité mineure n’ayant été recensée.';
      } else if (cStats.critique > 0) {
        critDistributionText = 'L\'intégralité des écarts constatés (**100 %**) relève d\'une criticité **critique**, aucune anomalie majeure ou mineure n’ayant été relevée.';
      } else {
        critDistributionText = 'L\'intégralité des écarts constatés (**100 %**) relève d\'une criticité **majeure**, sans dérive critique immédiate ni écart mineur.';
      }
    } else if (cStats.critique == 0 && cStats.majeure == 0) {
      critDistributionText = 'L\'intégralité des écarts constatés (**100 %**) relève d\'une criticité **mineure**, sans dérive critique ni majeure.';
    } else {
      critDistributionText = 'La répartition par criticité s\'établit à **$pctCritStr % d\'écarts critiques**, **$pctMajStr % majeurs** et **$pctMinStr % mineurs**.';
    }

    final String perimeterDetails;
    if (summary.htaEquipmentsCount > 0 && summary.btEquipmentsCount > 0) {
      perimeterDetails = 'Sur le périmètre vérifié (**${summary.totalEquipments} équipements contrôlés**, dont **${summary.htaEquipmentsCount} en Moyenne Tension** et **${summary.btEquipmentsCount} en Basse Tension**), **$totalNc non-conformités** ont été recensées, correspondant à une densité moyenne de **$densityStr non-conformités par équipement**';
    } else if (summary.htaEquipmentsCount > 0) {
      perimeterDetails = 'Sur le périmètre vérifié (**${summary.htaEquipmentsCount} équipements contrôlés en Moyenne Tension**), **$totalNc non-conformités** ont été recensées, correspondant à une densité moyenne de **$densityStr non-conformités par équipement**';
    } else if (summary.btEquipmentsCount > 0) {
      perimeterDetails = 'Sur le périmètre vérifié (**${summary.btEquipmentsCount} équipements contrôlés en Basse Tension**), **$totalNc non-conformités** ont été recensées, correspondant à une densité moyenne de **$densityStr non-conformités par équipement**';
    } else {
      perimeterDetails = 'Sur le périmètre vérifié, **$totalNc non-conformités** ont été recensées, correspondant à une densité moyenne de **$densityStr non-conformités par équipement**';
    }

    return 'La vérification périodique des installations électriques de **$clientSiteLabel** met en évidence $riskQualification. $perimeterDetails. $critDistributionText';
  }

  /// Construction du paragraphe 2 : Analyse des familles de risques dominantes
  static String? _buildRiskFamiliesParagraph(MissionStatisticsSummary summary) {
    final total = summary.totalNC > 0 ? summary.totalNC : summary.criticalityStats.total;
    if (total == 0 || summary.riskFamilyStats.isEmpty) return null;

    final sorted = List.from(summary.riskFamilyStats)
      ..sort((a, b) => b.count.compareTo(a.count));
    if (sorted.isEmpty) return null;

    final top1 = sorted.first;
    final top1Pct = top1.percentage.toStringAsFixed(1).replaceAll('.', ',');

    // Détection de la présence d'une prépondérance exploitation/maintenance
    final isExploitationTop = top1.name.toLowerCase().contains('exploitation') ||
        top1.name.toLowerCase().contains('maintenance');

    final fam1 = _formatFamilyWithArticle(top1.name);

    if (sorted.length >= 2) {
      final top2 = sorted[1];
      final top2Pct = top2.percentage.toStringAsFixed(1).replaceAll('.', ',');
      final fam2 = _formatFamilyWithArticle(top2.name);

      if (isExploitationTop) {
        return 'Les résultats montrent que les principales vulnérabilités ne sont pas uniquement liées à l’état physique des équipements, mais également à la **maîtrise des opérations d’exploitation et de maintenance**. Ainsi, **$fam1** constituent la première famille de risques identifiée, avec **$top1Pct % des occurrences**, devant **$fam2**, qui représente **$top2Pct %**.';
      } else {
        return 'L’analyse de criticité met en évidence une concentration des risques sur **$fam1**, représentant à elle seule **$top1Pct % des occurrences**, suivie par **$fam2** avec **$top2Pct % des constats**.';
      }
    } else {
      return 'L’analyse des facteurs de risque démontre une prépondérance absolue de la famille **${top1.name}**, qui regroupe **$top1Pct % des défaillances recensées**.';
    }
  }

  /// Formate une famille de risques avec son article naturel et son intitulé propre
  static String _formatFamilyWithArticle(String name) {
    final lower = name.trim().toLowerCase();
    if (lower.contains('exploitation') || lower.contains('maintenance')) {
      return 'les pratiques d’exploitation et de maintenance';
    }
    if (lower.contains('dégradation') || lower.contains('degradation')) {
      return 'la dégradation des canalisations et matériels';
    }
    if (lower.contains('conformité') || lower.contains('conformite')) {
      return 'la non-conformité de conception ou d’installation';
    }
    return 'la catégorie « ${name.trim()} »';
  }

  /// Cartographie des faiblesses techniques réelles (basée STRICTEMENT sur les constats de la mission)
  static List<String> _extractTechnicalWeaknesses(
    MissionStatisticsSummary summary,
    TechnicalEnrichmentResult technical,
  ) {
    final findings = summary.inventory.pertinentFindings;
    if (findings.isEmpty) return const [];

    final scores = <String, int>{};

    void matchWeakness(String key, bool Function(AuditFinding f) predicate) {
      final count = findings.where(predicate).length;
      if (count > 0) scores[key] = count;
    }

    // 1. Identification & repérage
    matchWeakness(
      'L’identification, le repérage et la documentation des circuits électriques ;',
      (f) =>
          f.verificationPoint.toLowerCase().contains('repérage') ||
          f.verificationPoint.toLowerCase().contains('identification') ||
          f.verificationPoint.toLowerCase().contains('schéma') ||
          f.verificationPoint.toLowerCase().contains('unifilaire') ||
          f.observationText.toLowerCase().contains('non repéré') ||
          f.observationText.toLowerCase().contains('schéma manquant'),
    );

    // 2. Câblages et canalisations
    matchWeakness(
      'Les câblages, raccordements et canalisations ;',
      (f) =>
          f.verificationPoint.toLowerCase().contains('câbl') ||
          f.verificationPoint.toLowerCase().contains('serrage') ||
          f.verificationPoint.toLowerCase().contains('connexion') ||
          f.verificationPoint.toLowerCase().contains('canalisation') ||
          f.verificationPoint.toLowerCase().contains('presse-étoupe') ||
          f.observationText.toLowerCase().contains('câble') ||
          f.observationText.toLowerCase().contains('mauvais serrage'),
    );

    // 3. Intégrité des enveloppes et armoires
    matchWeakness(
      'L’intégrité des enveloppes, armoires et coffrets ;',
      (f) =>
          f.verificationPoint.toLowerCase().contains('ip') ||
          f.verificationPoint.toLowerCase().contains('ik') ||
          f.verificationPoint.toLowerCase().contains('plastron') ||
          f.verificationPoint.toLowerCase().contains('obturat') ||
          f.verificationPoint.toLowerCase().contains('enveloppe') ||
          f.verificationPoint.toLowerCase().contains('porte') ||
          f.observationText.toLowerCase().contains('ip2x') ||
          f.observationText.toLowerCase().contains('plastron manquant'),
    );

    // 4. EPI électriques
    matchWeakness(
      'La disponibilité et l’accessibilité des EPI électriques ;',
      (f) =>
          f.verificationPoint.toLowerCase().contains('epi') ||
          f.verificationPoint.toLowerCase().contains('gant') ||
          f.verificationPoint.toLowerCase().contains('tabouret') ||
          f.verificationPoint.toLowerCase().contains('visière') ||
          f.observationText.toLowerCase().contains('epi'),
    );

    // 5. Consignation et coupure d'urgence
    matchWeakness(
      'Les dispositifs et procédures de consignation ;',
      (f) =>
          f.verificationPoint.toLowerCase().contains('consignation') ||
          f.verificationPoint.toLowerCase().contains('condamnation') ||
          f.verificationPoint.toLowerCase().contains('coupure d’urgence') ||
          f.verificationPoint.toLowerCase().contains('arrêt d’urgence') ||
          f.observationText.toLowerCase().contains('consignation'),
    );

    // 6. Revêtements diélectriques
    matchWeakness(
      'Les revêtements diélectriques au sol ;',
      (f) =>
          f.verificationPoint.toLowerCase().contains('diélectrique') ||
          f.verificationPoint.toLowerCase().contains('isolant au sol') ||
          f.verificationPoint.toLowerCase().contains('tapis isolant') ||
          f.observationText.toLowerCase().contains('diélectrique') ||
          f.observationText.toLowerCase().contains('tapis isolant'),
    );

    // 7. Terre et protection contre les surtensions
    matchWeakness(
      'La mise à la terre et les dispositifs de protection contre les surtensions.',
      (f) =>
          f.verificationPoint.toLowerCase().contains('parafoudre') ||
          f.verificationPoint.toLowerCase().contains('terre') ||
          f.verificationPoint.toLowerCase().contains('équipotentielle') ||
          f.verificationPoint.toLowerCase().contains('continuité de masse') ||
          f.observationText.toLowerCase().contains('parafoudre') ||
          f.observationText.toLowerCase().contains('mise à la terre'),
    );

    // 8. Conditions d'environnement, éclairage et ventilation
    matchWeakness(
      'Les conditions de ventilation, d’éclairage de sécurité et de dégagement des locaux.',
      (f) =>
          f.verificationPoint.toLowerCase().contains('ventilation') ||
          f.verificationPoint.toLowerCase().contains('dégagement') ||
          f.verificationPoint.toLowerCase().contains('éclairage') ||
          f.verificationPoint.toLowerCase().contains('encombrement') ||
          f.observationText.toLowerCase().contains('ventilation') ||
          f.observationText.toLowerCase().contains('encombré'),
    );

    // Trier les faiblesses par ordre d'importance réelle dans la mission
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final resultList = sortedEntries.map((e) => e.key).toList();
    if (resultList.isNotEmpty) {
      // Ajuster la ponctuation du dernier élément
      final last = resultList.last;
      if (last.endsWith(' ;')) {
        resultList[resultList.length - 1] = '${last.substring(0, last.length - 2)}.';
      }
    }
    return resultList;
  }

  /// Paragraphe 3 : Déficit de données techniques et documentaires
  static String? _buildTechnicalDeficitParagraph(TechnicalEnrichmentResult technical) {
    final deficitItems = <String>[];

    // 1. Sources d'alimentation
    int totalSourcesNonId = 0;
    for (final s in technical.sourceStats.values) {
      totalSourcesNonId += s.nonIdentifiees;
    }
    if (totalSourcesNonId > 0) {
      deficitItems.add('l’identification des sources d’alimentation');
    }

    // 2. Protections de tête / caractéristiques
    int totalCoupureAbsents = 0;
    for (final c in technical.coupureTeteStats.values) {
      totalCoupureAbsents += c.absents;
    }
    if (totalCoupureAbsents > 0 || technical.courbesMatrix.isNotEmpty) {
      deficitItems.add('les caractéristiques des protections');
    }

    // 3. Indices IP/IK
    int totalIpIkNonRenseignes = 0;
    for (final ip in technical.ipIkZoneItems) {
      totalIpIkNonRenseignes += ip.nonRenseignes;
    }
    if (totalIpIkNonRenseignes > 0) {
      deficitItems.add('les indices de protection IP/IK');
    }

    if (deficitItems.isEmpty) return null;

    final String deficitDetails;
    if (deficitItems.length == 1) {
      deficitDetails = deficitItems.first;
    } else if (deficitItems.length == 2) {
      deficitDetails = '${deficitItems[0]} et ${deficitItems[1]}';
    } else {
      deficitDetails = '${deficitItems.sublist(0, deficitItems.length - 1).join(', ')} et ${deficitItems.last}';
    }

    return 'L’analyse met également en évidence un **déficit important de données techniques nécessaires à la maîtrise du parc électrique**, notamment concernant $deficitDetails.\n\nCe déficit documentaire limite la capacité des équipes à assurer une maintenance préventive pleinement maîtrisée et à intervenir rapidement et en sécurité.';
  }

  /// Paragraphe 4 : Observation Pareto ou Asymétrie HTA/BT
  static String? _buildTensionOrParetoObservation(MissionStatisticsSummary summary) {
    final tension = summary.tensionDomainStats;
    final total = summary.totalNC > 0 ? summary.totalNC : summary.criticalityStats.total;
    if (total == 0) return null;

    // Si un seul domaine est audité
    if (tension.mtCount > 0 && tension.btCount == 0) {
      return 'L’ensemble des non-conformités recensées (**100 %**) relève exclusivement du domaine de la **Moyenne Tension (HTA)**, les vérifications ayant été concentrées sur les postes de transformation et cellules de distribution.';
    }
    if (tension.btCount > 0 && tension.mtCount == 0) {
      return 'L’ensemble des non-conformités recensées (**100 %**) relève exclusivement du domaine de la **Basse Tension (BT)**, aucun écart n’ayant été constaté ou audité sur le réseau Moyenne Tension.';
    }

    // Répartition HTA vs BT
    if (tension.mtCount > 0 && tension.btCount > 0) {
      final htaPct = ((tension.mtCount / total) * 100).toStringAsFixed(1).replaceAll('.', ',');
      final btPct = ((tension.btCount / total) * 100).toStringAsFixed(1).replaceAll('.', ',');

      if (tension.mtCount > tension.btCount) {
        return 'Sur le plan de la distribution par niveau de tension, le domaine de la **Moyenne Tension (HTA)** concentre **$htaPct % des non-conformités**, contre **$btPct % en Basse Tension (BT)**, traduisant une vulnérabilité accrue sur les postes de distribution principale.';
      } else if (tension.btCount > tension.mtCount) {
        return 'La répartition par niveau de tension met en exergue une prépondérance des constats en **Basse Tension (BT)** avec **$btPct % des anomalies**, contre **$htaPct % en Moyenne Tension (HTA)**, soulignant que les postes HTA conservent un niveau d\'intégrité globalement supérieur aux armoires divisionnaires.';
      } else {
        return 'La répartition par niveau de tension présente un équilibre parfait entre le domaine **Moyenne Tension (HTA)** (**$htaPct %**) et la **Basse Tension (BT)** (**$btPct %**).';
      }
    }

    return null;
  }

  /// Paragraphe 5 : Enjeux opérationnels et priorisation chiffrée alignée sur la Section 11
  static String _buildOperationalPrioritiesParagraph(
    MissionStatisticsSummary summary,
    CriticalityStats cStats,
    HierarchicalRecommendationsResult recoResult,
  ) {
    final critique = cStats.critique;
    final majeure = cStats.majeure;
    final mineure = cStats.mineure;
    final countImmediate = recoResult.countImmediate;
    final countShortTerm = recoResult.countShortTerm;
    final countMediumTerm = recoResult.countMediumTerm;

    final parts = <String>[];

    if (critique > 0) {
      final recoText = countImmediate > 0 ? ' ($countImmediate recommandation${countImmediate > 1 ? 's' : ''} d\'action immédiate)' : '';
      parts.add('une **action immédiate (Priorité 1)** sur les **$critique non-conformités critiques** recensées$recoText afin d’éliminer tout risque direct d’électrisation ou d\'incendie');
    }

    if (majeure > 0) {
      final recoText = countShortTerm > 0 ? ' ($countShortTerm recommandation${countShortTerm > 1 ? 's' : ''} structurante${countShortTerm > 1 ? 's' : ''})' : '';
      parts.add('un **traitement à court terme (Priorité 2)** des **$majeure non-conformités majeures**$recoText pour rétablir la conformité normative des équipements');
    }

    if (mineure > 0) {
      final recoText = countMediumTerm > 0 ? ' ($countMediumTerm recommandation${countMediumTerm > 1 ? 's' : ''})' : '';
      parts.add('une intégration à **moyen terme (Priorité 3)** des **$mineure écarts mineurs**$recoText dans le cadre des opérations courantes de maintenance');
    }

    if (parts.isEmpty) {
      return 'Aucune action corrective d’urgence n’est requise, la priorité résidant dans la surveillance régulière et la maintenance préventive du réseau.';
    }

    final String prioritiesSequence;
    if (parts.length == 1) {
      prioritiesSequence = parts.first;
    } else if (parts.length == 2) {
      prioritiesSequence = '${parts[0]}, complétée par ${parts[1]}';
    } else {
      prioritiesSequence = '${parts[0]}, suivie par ${parts[1]}, et enfin ${parts[2]}';
    }

    final String mtBtBreakdown;
    if (recoResult.hasMt && recoResult.hasBt) {
      mtBtBreakdown = ' Ces actions sont réparties entre les domaines **Moyenne Tension (${recoResult.mtRecommendations.length} recommandation${recoResult.mtRecommendations.length > 1 ? 's' : ''})** et **Basse Tension (${recoResult.btRecommendations.length} recommandation${recoResult.btRecommendations.length > 1 ? 's' : ''})**.';
    } else if (recoResult.hasMt) {
      mtBtBreakdown = ' L’intégralité des recommandations concerne le domaine de la **Moyenne Tension (HTA)**.';
    } else if (recoResult.hasBt) {
      mtBtBreakdown = ' L’intégralité des recommandations concerne le domaine de la **Basse Tension (BT)**.';
    } else {
      mtBtBreakdown = '';
    }

    return 'En conséquence, le plan d’actions hiérarchisé préconise $prioritiesSequence.$mtBtBreakdown';
  }

  /// Paragraphe final : Conclusion et appréciation finale calibrée
  static String _buildFinalAppreciationParagraph(
    MissionStatisticsSummary summary,
    GlobalRiskProfileLevel riskLevel,
  ) {
    switch (riskLevel) {
      case GlobalRiskProfileLevel.criticalHighRisk:
      case GlobalRiskProfileLevel.significantImprovementRequired:
        return '**Appréciation finale :** l’installation présente un niveau de risque nécessitant la mise en œuvre d’un **plan d’actions correctives structuré, priorisé et suivi dans le temps**. La réduction durable du risque reposera autant sur la remise en conformité technique des installations que sur l’amélioration des pratiques d’exploitation, et le renforcement des compétences des agents en charge du maintien en bon état de fonctionnement.';

      case GlobalRiskProfileLevel.moderateRiskNeedingAction:
        return '**Appréciation finale :** l’installation présente un niveau de risque modéré. La sécurisation durable des installations nécessitera la résorption progressive des écarts relevés dans le cadre d’un calendrier priorisé, adossée à une consolidation de la documentation technique de distribution.';

      case GlobalRiskProfileLevel.controlledWithMinorDeviations:
        return '**Appréciation finale :** l’installation se situe à un niveau de risque maîtrisé. Les quelques observations recensées appellent des ajustements ciblés qui permettront de consolider la sécurité globale sans remettre en cause l’intégrité générale du réseau électrique.';

      case GlobalRiskProfileLevel.excellentOrZeroDefect:
        return '**Appréciation finale :** l’installation présente un **très haut degré de conformité et de sécurité**. Il convient d’entretenir cette dynamique positive par la poursuite rigoureuse des contrôles périodiques et de la maintenance préventive.';
    }
  }
}
