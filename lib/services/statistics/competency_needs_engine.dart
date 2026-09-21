// lib/services/statistics/competency_needs_engine.dart

import 'audit_finding.dart';
import 'mission_statistics.dart';

/// Modèle d'un axe dynamique de renforcement des compétences.
///
/// Dérivé strictement des non-conformités majeures réelles et de leur contexte technique.
class CompetencyNeed {
  /// Identifiant technique unique de l'axe
  final String id;

  /// Lettre majuscule de repérage dans le rapport : "A.", "B.", "C.", etc.
  final String letter;

  /// Intitulé métier clair, intelligible et professionnel de l'axe de compétence
  final String title;

  /// Description / Savoir-faire concrets à développer lors des formations
  final String recommendedSkills;

  /// Justification factuelle basée sur les constats réels relevés lors de la mission
  final String rationale;

  /// Résultat opérationnel concret attendu pour l'exploitation et la maintenance
  final String operationalObjective;

  /// Nombre exact d'occurrences de non-conformités majeures rattachées à cet axe
  final int occurrenceCount;

  /// Part relative en pourcentage par rapport au total des non-conformités majeures (%)
  final double percentage;

  /// Nombre de non-conformités critiques rattachées
  final int critiqueCount;

  /// Nombre de non-conformités majeures rattachées
  final int majeureCount;

  /// Nombre de non-conformités mineures rattachées
  final int mineureCount;

  /// Libellés canoniques ou bruts des points de vérification rattachés à cet axe
  final List<String> sourceVerificationPoints;

  /// Familles de risques associées à ces constats
  final List<String> riskFamilies;

  /// Types d'équipements principalement concernés (ex: "Armoires", "Coffrets", "Cellules MT")
  final List<String> topEquipmentTypes;

  /// Locaux ou zones physiques les plus impactés par ces constats (si identifiés)
  final List<String> topLocations;

  /// Présence de constats en Moyenne Tension (HTA)
  final bool hasMtDomain;

  /// Présence de constats en Basse Tension (BT)
  final bool hasBtDomain;

  /// Domaine de tension prépondérant
  final TensionDomain domain;

  /// Texte narratif concis personnalisé (environ 2 lignes visuelles)
  final String? customNarrative;

  CompetencyNeed({
    required this.id,
    required this.letter,
    required this.title,
    required this.recommendedSkills,
    required this.rationale,
    required this.operationalObjective,
    required this.occurrenceCount,
    required this.percentage,
    required this.critiqueCount,
    required this.majeureCount,
    required this.mineureCount,
    required this.sourceVerificationPoints,
    required this.riskFamilies,
    required this.topEquipmentTypes,
    required this.topLocations,
    required this.hasMtDomain,
    required this.hasBtDomain,
    this.domain = TensionDomain.bt,
    this.customNarrative,
  });

  /// Chaîne formatée du pourcentage (ex: "22,6")
  String get percentageStr => percentage.toStringAsFixed(1).replaceAll('.', ',');

  /// Résumé synthétique de la localisation (équipements / locaux)
  String get contextSummary {
    final parts = <String>[];
    if (topEquipmentTypes.isNotEmpty) {
      final eqText = topEquipmentTypes.take(2).join(' et ');
      parts.add('équipements concernés : $eqText');
    }
    if (topLocations.isNotEmpty) {
      final locText = topLocations.take(2).join(' et ');
      parts.add('secteurs : $locText');
    }
    return parts.join(' — ');
  }

  /// Texte narratif concis prêt pour le rendu documentaire (~2 lignes visuelles)
  String get fullNarrative {
    if (customNarrative != null && customNarrative!.trim().isNotEmpty) {
      return customNarrative!.trim();
    }
    final buffer = StringBuffer();
    buffer.write(recommendedSkills.trim());
    if (!recommendedSkills.trim().endsWith('.')) {
      buffer.write('. ');
    } else {
      buffer.write(' ');
    }

    buffer.write(operationalObjective.trim());
    if (!operationalObjective.trim().endsWith('.')) {
      buffer.write('.');
    }

    return buffer.toString();
  }
}

/// Résultat complet de l'analyse dynamique des besoins en compétences.
class CompetencyNeedsAnalysisResult {
  final String missionId;

  /// Nombre total de non-conformités majeures analysées
  final int totalOccurrences;

  /// Texte d'introduction dynamique contextualisé à la mission (structuré en paragraphes)
  final String introNarrative;

  /// Liste dynamique des axes prioritaires (TOP 5 MT + TOP 5 BT fusionnés, triés par occurrences décroissantes)
  final List<CompetencyNeed> axes;

  /// Indique si la distribution présente une forte concentration sur 1 ou 2 thématiques majeures
  final bool isConcentrated;

  /// Indique si la distribution est étalée / homogène sur de nombreuses défaillances
  final bool isDispersed;

  /// Indique s'il n'y a aucune non-conformité majeure recensée
  final bool hasNoDefects;

  /// Nombre de non-conformités majeures MT
  final int topMajeuresMtCount;

  /// Nombre de non-conformités majeures BT
  final int topMajeuresBtCount;

  CompetencyNeedsAnalysisResult({
    required this.missionId,
    required this.totalOccurrences,
    required this.introNarrative,
    required this.axes,
    required this.isConcentrated,
    required this.isDispersed,
    required this.hasNoDefects,
    this.topMajeuresMtCount = 0,
    this.topMajeuresBtCount = 0,
  });
}

/// Moteur expert déterministe d'analyse des besoins de renforcement des compétences.
///
/// Fondé exclusivement sur l'identification des non-conformités majeures réelles,
/// la sélection du TOP 5 MT + TOP 5 BT, et un classement global décroissant A. à J.
class CompetencyNeedsEngine {
  /// Lettres officielles de numérotation des axes (A. à J.)
  static const List<String> axisLetters = [
    'A.', 'B.', 'C.', 'D.', 'E.', 'F.', 'G.', 'H.', 'I.', 'J.'
  ];

  /// Analyse les données statistiques d'une mission et construit le résultat complet
  static CompetencyNeedsAnalysisResult analyzeFromSummary(MissionStatisticsSummary summary) {
    return analyze(
      missionId: summary.missionId,
      findings: summary.inventory.pertinentFindings,
      totalNC: summary.totalNC,
      riskFamilyStats: summary.riskFamilyStats,
      tensionDomainStats: summary.tensionDomainStats,
      crossCategoryItems: summary.crossCategoryItems,
    );
  }

  /// Analyse directement une liste d'AuditFinding
  static CompetencyNeedsAnalysisResult analyze({
    required String missionId,
    required List<AuditFinding> findings,
    int? totalNC,
    List<RiskFamilyItem>? riskFamilyStats,
    TensionDomainStats? tensionDomainStats,
    List<CategoryCrossItem>? crossCategoryItems,
  }) {
    // 1. Filtrer les non-conformités normatives réelles
    final pertinent = findings.where(AuditFindingInventory.isNormativeNonConformity).toList();

    // 2. Extraire la population stricte des NC majeures
    final majeures = pertinent.where(_isMajeureFinding).toList();
    final totalMajeuresCount = majeures.length;

    // Cas limite : aucune NC majeure
    if (totalMajeuresCount == 0) {
      return CompetencyNeedsAnalysisResult(
        missionId: missionId,
        totalOccurrences: 0,
        introNarrative:
            'L’audit ne met en évidence aucune non-conformité majeure sur les installations contrôlées selon le référentiel normatif applicable.\n\n'
            'Les écarts éventuellement constatés relèvent de dysfonctionnements mineurs ne justifiant pas d’action prioritaire de formation. '
            'Il convient de maintenir le niveau actuel des compétences par des actions régulières de sensibilisation et de recyclage des habilitations électriques.',
        axes: const [],
        isConcentrated: false,
        isDispersed: false,
        hasNoDefects: true,
        topMajeuresMtCount: 0,
        topMajeuresBtCount: 0,
      );
    }

    // 3. Séparation stricte Domaine MT / Domaine BT
    final mtMajeures = majeures.where((f) => f.tensionDomain == TensionDomain.mt).toList();
    final btMajeures = majeures.where((f) => f.tensionDomain == TensionDomain.bt).toList();

    // 4. Regroupement par point de défaillance dans chaque domaine
    final mtGroups = _groupMajeuresByPoint(mtMajeures, TensionDomain.mt);
    final btGroups = _groupMajeuresByPoint(btMajeures, TensionDomain.bt);

    // 5. Sélection TOP 5 MT et TOP 5 BT (max 5 chacun)
    final top5Mt = mtGroups.take(5).toList();
    final top5Bt = btGroups.take(5).toList();

    // 6. Fusion des deux populations et classement global décroissant
    final combinedGroups = <_FindingPointGroup>[...top5Mt, ...top5Bt];
    combinedGroups.sort((a, b) {
      final cmpCount = b.findings.length.compareTo(a.findings.length);
      if (cmpCount != 0) return cmpCount;
      return a.verificationPoint.compareTo(b.verificationPoint);
    });

    // 7. Analyse des variances et de la concentration
    final top1Count = combinedGroups.isNotEmpty ? combinedGroups.first.findings.length : 0;
    final top2Count = combinedGroups.length > 1 ? combinedGroups[1].findings.length : 0;

    final isSingleDominant = combinedGroups.length == 1 ||
        (combinedGroups.length >= 2 && top1Count >= 2 * top2Count && top1Count >= 5);
    final top2Share = totalMajeuresCount > 0 ? ((top1Count + top2Count) / totalMajeuresCount) * 100.0 : 0.0;
    final isConcentrated = isSingleDominant || (top2Share >= 50.0 && totalMajeuresCount >= 6);
    final isDispersed = !isConcentrated && combinedGroups.length >= 4;

    // 8. Génération dynamique des axes A. à J.
    final axes = <CompetencyNeed>[];
    for (int i = 0; i < combinedGroups.length; i++) {
      final group = combinedGroups[i];
      final letter = i < axisLetters.length ? axisLetters[i] : '${i + 1}.';
      final isTopDominant = (i == 0 && isSingleDominant);

      final interpretation = _deriveTechnicalCompetency(
        group: group,
        totalMajeures: totalMajeuresCount,
        isTopDominant: isTopDominant,
      );

      final pct = totalMajeuresCount > 0
          ? (group.findings.length / totalMajeuresCount) * 100.0
          : 0.0;

      axes.add(
        CompetencyNeed(
          id: 'axis_${group.domain.name}_${i + 1}',
          letter: letter,
          title: interpretation.title,
          recommendedSkills: interpretation.skills,
          rationale: interpretation.rationale,
          operationalObjective: interpretation.objective,
          occurrenceCount: group.findings.length,
          percentage: pct,
          critiqueCount: 0,
          majeureCount: group.findings.length,
          mineureCount: 0,
          sourceVerificationPoints: [group.verificationPoint],
          riskFamilies: group.riskFamilies.toList(),
          topEquipmentTypes: group.topEquipmentTypes,
          topLocations: group.topLocations,
          hasMtDomain: group.domain == TensionDomain.mt,
          hasBtDomain: group.domain == TensionDomain.bt,
          domain: group.domain,
          customNarrative: interpretation.fullNarrative,
        ),
      );
    }

    // 9. Rédaction de l'introduction narrative structurée en paragraphes
    final introNarrative = _buildStructuredIntroNarrative(
      totalMajeures: totalMajeuresCount,
      mtCount: mtMajeures.length,
      btCount: btMajeures.length,
      axes: axes,
      isConcentrated: isConcentrated,
      isSingleDominant: isSingleDominant,
      isDispersed: isDispersed,
    );

    return CompetencyNeedsAnalysisResult(
      missionId: missionId,
      totalOccurrences: totalMajeuresCount,
      introNarrative: introNarrative,
      axes: axes,
      isConcentrated: isConcentrated,
      isDispersed: isDispersed,
      hasNoDefects: false,
      topMajeuresMtCount: mtMajeures.length,
      topMajeuresBtCount: btMajeures.length,
    );
  }

  /// Détecte si un constat correspond à une non-conformité majeure
  static bool _isMajeureFinding(AuditFinding f) {
    final crit = f.criticality.trim().toLowerCase();
    if (crit.contains('majeur')) return true;
    if (f.priority == 2) return true;
    return false;
  }

  /// Regroupe les non-conformités d'un domaine par point de défaillance
  static List<_FindingPointGroup> _groupMajeuresByPoint(
    List<AuditFinding> findings,
    TensionDomain domain,
  ) {
    if (findings.isEmpty) return const [];

    final map = <String, List<AuditFinding>>{};
    for (final f in findings) {
      final key = _canonicalizeVerificationPoint(f.verificationPoint);
      map.putIfAbsent(key, () => []).add(f);
    }

    final groups = map.entries.map((e) {
      final list = e.value;
      final repFinding = list.first;

      // Collecte des équipements
      final eqCounts = <String, int>{};
      for (final f in list) {
        final eq = f.objectType.trim().isNotEmpty ? f.objectType.trim() : 'Équipement';
        eqCounts[eq] = (eqCounts[eq] ?? 0) + 1;
      }
      final sortedEqs = eqCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topEqs = sortedEqs.take(2).map((x) => x.key).toList();

      // Collecte des locaux
      final locCounts = <String, int>{};
      for (final f in list) {
        final loc = f.origin.trim().isNotEmpty ? f.origin.trim() : f.objectName.trim();
        if (loc.isNotEmpty && !loc.toLowerCase().contains('inconnu')) {
          locCounts[loc] = (locCounts[loc] ?? 0) + 1;
        }
      }
      final sortedLocs = locCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topLocs = sortedLocs.take(2).map((x) => x.key).toList();

      final riskFamilies = list.map((f) => f.riskFamily?.trim() ?? '').where((r) => r.isNotEmpty).toSet();

      return _FindingPointGroup(
        verificationPoint: e.key,
        representativeFinding: repFinding,
        findings: list,
        domain: domain,
        topEquipmentTypes: topEqs,
        topLocations: topLocs,
        riskFamilies: riskFamilies,
      );
    }).toList();

    // Tri décroissant par fréquence avec bris d'égalité déterministe
    groups.sort((a, b) {
      final cmp = b.findings.length.compareTo(a.findings.length);
      if (cmp != 0) return cmp;
      return a.verificationPoint.compareTo(b.verificationPoint);
    });

    return groups;
  }

  /// Normalisation propre du point de vérification pour regroupement déterministe
  static String _canonicalizeVerificationPoint(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Anomalie non spécifiée';
    return trimmed;
  }

  /// Moteur d'interprétation technique dynamique
  ///
  /// Analyse les attributs techniques réels (point de contrôle, objet technique, défaillance)
  /// pour produire un texte extrêmement concis (~2 lignes visuelles) orienté compétence.
  static _DerivedCompetency _deriveTechnicalCompetency({
    required _FindingPointGroup group,
    required int totalMajeures,
    required bool isTopDominant,
  }) {
    final f = group.representativeFinding;
    final pointLower = group.verificationPoint.toLowerCase();
    final obsLower = f.observationText.toLowerCase();
    final combinedText = '$pointLower $obsLower ${f.objectType.toLowerCase()} ${f.normativeReference ?? ""}';

    String title;
    String skills;
    String objective;

    // 1. Repérage, identification, schémas unifilaires
    if (combinedText.contains('repérage') ||
        combinedText.contains('reperage') ||
        combinedText.contains('identification') ||
        combinedText.contains('schéma') ||
        combinedText.contains('unifilaire') ||
        combinedText.contains('étiquetage') ||
        combinedText.contains('marquage')) {
      title = 'Identification, repérage et tenue à jour des schémas unifilaires';
      skills = 'Renforcer la rigueur du repérage normalisé des circuits et la mise à jour documentaire des tableaux';
      objective = 'afin de fiabiliser l’exploitation courante et de sécuriser les consignations';
    }
    // 2. Prises de terre, équipotentialité, continuité PE
    else if (combinedText.contains('terre') ||
        combinedText.contains('équipotentielle') ||
        combinedText.contains('equipotentiel') ||
        combinedText.contains('continuité de masse') ||
        combinedText.contains('barrette de coupure') ||
        combinedText.contains('prise de terre') ||
        RegExp(r'\bpe\b').hasMatch(combinedText)) {
      title = 'Raccordement à la terre et continuité des conducteurs de protection';
      skills = 'Développer la maîtrise des contrôles de continuité PE et du raccordement des liaisons équipotentielles';
      objective = 'afin de garantir l’écoulement des courants de défaut et de prévenir le risque d’électrisation';
    }
    // 3. Dispositifs différentiels, DDR, isolement
    else if (combinedText.contains('différentiel') ||
        combinedText.contains('differentiel') ||
        combinedText.contains('ddr') ||
        combinedText.contains('isolement') ||
        combinedText.contains('courant de fuite')) {
      title = 'Protections différentielles et surveillance de l’isolement';
      skills = 'Former aux essais périodiques des DDR, à la vérification des seuils de déclenchement et à la mesure d’isolement';
      objective = 'afin d’assurer la protection contre les contacts indirects et d’éliminer les risques de départ de feu';
    }
    // 4. Protections contre les surintensités, calibres, sélectivité
    else if (combinedText.contains('surintensité') ||
        combinedText.contains('calibre') ||
        combinedText.contains('disjoncteur') ||
        combinedText.contains('fusible') ||
        combinedText.contains('pouvoir de coupure') ||
        combinedText.contains('sélectivité')) {
      title = 'Coordination et calibre des dispositifs de protection amont/aval';
      skills = 'Consolider les compétences de dimensionnement des calibres et de vérification de l’adéquation protection/câble';
      objective = 'afin d’assurer la coupure instantanée des surintensités sans déclenchement généralisé';
    }
    // 5. Enveloppes, plastrons, obturateurs, degrés IP/IK
    else if (combinedText.contains('enveloppe') ||
        combinedText.contains('plastron') ||
        combinedText.contains('obturat') ||
        combinedText.contains('étanchéité') ||
        combinedText.contains('etancheite') ||
        combinedText.contains('ip') ||
        combinedText.contains('ik') ||
        combinedText.contains('contact direct') ||
        combinedText.contains('porte')) {
      title = 'Intégrité des enveloppes, plastrons et obturation des réserves';
      skills = 'Sensibiliser à la pose systématique d’obturateurs sur les modules de réserve et au maintien de l’étanchéité IP';
      objective = 'afin d’éliminer tout risque de contact direct avec des pièces sous tension';
    }
    // 6. Câblage, raccordements, connexions, échauffement, serrage
    else if (combinedText.contains('câblage') ||
        combinedText.contains('cablage') ||
        combinedText.contains('serrage') ||
        combinedText.contains('connexion') ||
        combinedText.contains('raccordement') ||
        combinedText.contains('bornier') ||
        combinedText.contains('échauffement') ||
        combinedText.contains('canalisation')) {
      title = 'Règles de l’art du câblage, raccordements et couples de serrage';
      skills = 'Renforcer les pratiques de vérification des couples de serrage et de protection mécanique des conducteurs';
      objective = 'afin d’éviter les échauffements anormaux et la détérioration prématurée des isolants';
    }
    // 7. Organes de coupure d'urgence, arrêt d'urgence
    else if (combinedText.contains('coupure d’urgence') ||
        combinedText.contains('coupure d\'urgence') ||
        combinedText.contains('arrêt d’urgence') ||
        combinedText.contains('arret d\'urgence') ||
        combinedText.contains('sectionneur')) {
      title = 'Organes de coupure d’urgence et dispositifs de sectionnement';
      skills = 'Former au contrôle de l’accessibilité, de la manœuvrabilité et du fonctionnement des organes de coupure d’urgence';
      objective = 'afin de garantir une mise hors tension immédiate en cas de situation de danger';
    }
    // 8. Cellules HTA, interverrouillage, mise à la terre MT
    else if (group.domain == TensionDomain.mt &&
        (combinedText.contains('cellule') ||
         combinedText.contains('interverrouillage') ||
         combinedText.contains('sectionneur') ||
         combinedText.contains('gaep') ||
         combinedText.contains('manœuvre'))) {
      title = 'Exploitation et manœuvres des cellules Moyenne Tension (HTA)';
      skills = 'Renforcer la stricte application des séquences d’interverrouillage mécanique et de mise à la terre des cellules MT';
      objective = 'afin d’éliminer tout risque d’arc électrique lors des opérations d’exploitation en poste HTA';
    }
    // 9. Transformateurs MT/BT, diélectrique, DGPT2
    else if (group.domain == TensionDomain.mt &&
        (combinedText.contains('transformateur') ||
         combinedText.contains('transfo') ||
         combinedText.contains('diélectrique') ||
         combinedText.contains('dgpt2') ||
         combinedText.contains('rétention'))) {
      title = 'Surveillance et protection des transformateurs HTA/BT';
      skills = 'Perfectionner la surveillance de l’état du diélectrique, le contrôle des relais DGPT2 et des dispositifs de rétention';
      objective = 'afin de prévenir les défaillances diélectriques majeures et d’assurer la continuité de service amont';
    }
    // 10. Groupes électrogènes, inverseurs de source
    else if (combinedText.contains('groupe électrogène') ||
        combinedText.contains('groupe electrogene') ||
        combinedText.contains('inverseur') ||
        combinedText.contains('secours')) {
      title = 'Maintenance des groupes électrogènes et inverseurs Normal/Secours';
      skills = 'Développer les savoir-faire de maintenance préventive des groupes de secours et de contrôle des batteries de démarrage';
      objective = 'afin de garantir une reprise automatique et fiable de l’alimentation en cas de perte secteur';
    }
    // 11. Éclairage de sécurité, blocs autonomes BAES
    else if (combinedText.contains('éclairage de sécurité') ||
        combinedText.contains('eclairage de securite') ||
        combinedText.contains('baes') ||
        combinedText.contains('bloc autonome') ||
        combinedText.contains('évacuation')) {
      title = 'Vérification et maintenance de l’éclairage de sécurité (BAES)';
      skills = 'Former au contrôle périodique de l’autonomie des blocs autonomes d’éclairage de sécurité et à leur traçabilité';
      objective = 'afin d’assurer le balisage permanent des cheminements d’évacuation en cas d’urgence';
    }
    // 12. Consignation, EPI, sécurité réglementaire
    else if (combinedText.contains('consignation') ||
        combinedText.contains('vat') ||
        combinedText.contains('epi') ||
        combinedText.contains('habilitation') ||
        combinedText.contains('gant')) {
      title = 'Procédures de consignation électrique, VAT et port des EPI';
      skills = 'Renforcer la pratique rigoureuse de la consignation en 5 étapes, de la vérification d’absence de tension et du contrôle des EPI';
      objective = 'afin de préserver l’intégrité physique des intervenants lors des opérations de maintenance';
    }
    // 13. Protection foudre
    else if (combinedText.contains('foudre') ||
        combinedText.contains('parafoudre') ||
        combinedText.contains('descente')) {
      title = 'Protection contre la foudre et conformité des descentes';
      skills = 'Former au contrôle de l’état physique des conducteurs de descente et à la surveillance des modules parafoudres';
      objective = 'afin d’assurer l’écoulement direct des décharges atmosphériques sans détérioration des récepteurs';
    }
    // 14. Fallback dynamique universel (tout point de contrôle inconnu / futur)
    else {
      title = _formatCleanTitle(group.verificationPoint);
      final cleanPointLower = group.verificationPoint.trim().toLowerCase();
      final domainLabel = group.domain == TensionDomain.mt ? 'Moyenne Tension' : 'Basse Tension';
      skills = 'Renforcer la maîtrise des règles de l’art et des contrôles relatifs à « $cleanPointLower »';
      objective = 'afin d’éliminer les écarts récurrents constatés sur les installations $domainLabel';
    }

    // Construction du texte narratif concis (~2 lignes visuelles)
    final narrativeBuffer = StringBuffer();
    if (isTopDominant) {
      narrativeBuffer.write('Priorité immédiate : ');
    }
    narrativeBuffer.write(skills);
    narrativeBuffer.write(', ');
    narrativeBuffer.write(objective);
    narrativeBuffer.write('.');

    final rationale = '${group.findings.length} constat${group.findings.length > 1 ? "s" : ""} '
        'relevé${group.findings.length > 1 ? "s" : ""} en ${group.domain == TensionDomain.mt ? "HTA" : "BT"}';

    return _DerivedCompetency(
      title: title,
      skills: skills,
      objective: objective,
      rationale: rationale,
      fullNarrative: narrativeBuffer.toString(),
    );
  }

  /// Nettoie et capitalise un titre de point de vérification
  static String _formatCleanTitle(String raw) {
    var t = raw.trim();
    if (t.endsWith('.')) t = t.substring(0, t.length - 1).trim();
    if (t.isEmpty) return 'Non-conformité technique majeure';
    return t[0].toUpperCase() + t.substring(1);
  }

  /// Construit le paragraphe d'introduction structuré et concis
  static String _buildStructuredIntroNarrative({
    required int totalMajeures,
    required int mtCount,
    required int btCount,
    required List<CompetencyNeed> axes,
    required bool isConcentrated,
    required bool isSingleDominant,
    required bool isDispersed,
  }) {
    final buffer = StringBuffer();

    // ── Paragraphe 1 : Constat général factuel issu des données réelles
    buffer.write(
      'L’analyse des résultats de la mission met en évidence $totalMajeures non-conformité'
      '${totalMajeures > 1 ? "s" : ""} majeure${totalMajeures > 1 ? "s" : ""}, ',
    );

    if (mtCount > 0 && btCount > 0) {
      if (btCount >= 3 * mtCount) {
        buffer.write(
          'fortement concentrées sur les installations Basse Tension ($btCount constats) '
          'tout en impactant des équipements amont en Moyenne Tension ($mtCount constats).',
        );
      } else if (mtCount >= 2 * btCount) {
        buffer.write(
          'avec une prépondérance marquée sur les installations Moyenne Tension ($mtCount constats), '
          'complétées par des écarts sur les départs Basse Tension ($btCount constats).',
        );
      } else {
        buffer.write(
          'réparties entre le domaine Moyenne Tension ($mtCount constats) et '
          'le réseau Basse Tension ($btCount constats).',
        );
      }
    } else if (mtCount > 0) {
      buffer.write(
        'concernant exclusivement le domaine Moyenne Tension (HTA), '
        'au niveau des postes de livraison et transformateurs.',
      );
    } else {
      buffer.write(
        'intéressant l’ensemble des tableaux et armoires de distribution du réseau Basse Tension (BT).',
      );
    }

    buffer.write('\n\n');

    // ── Paragraphe 2 : Diagnostic de concentration vs dispersion
    if (axes.isNotEmpty) {
      final top1 = axes.first;
      final top2 = axes.length > 1 ? axes[1] : null;

      if (isSingleDominant) {
        buffer.write(
          'Les défaillances révèlent une priorité technique prépondérante sur « ${top1.title} » '
          '(${top1.occurrenceCount} constats), qui nécessite une action de mise à niveau ciblée et immédiate.',
        );
      } else if (isConcentrated && top2 != null) {
        buffer.write(
          'Les écarts majeurs se concentrent principalement sur deux problématiques dominantes : '
          '« ${top1.title} » (${top1.occurrenceCount} constats) et « ${top2.title} » (${top2.occurrenceCount} constats).',
        );
      } else {
        buffer.write(
          'Les non-conformités se distribuent de manière homogène sur plusieurs volets techniques distincts, '
          'traduisant un besoin de consolidation transverse des gestes professionnels et des procédures de contrôle.',
        );
      }

      buffer.write('\n\n');

      // ── Paragraphe 3 : Orientation opérationnelle du plan de compétences
      final axisCount = axes.length;
      buffer.write(
        'Afin d’assurer une réduction durable du risque d’exploitation, le plan de renforcement des compétences '
        'doit prioritairement porter sur les $axisCount axe${axisCount > 1 ? "s" : ""} d’intervention ci-dessous.',
      );
    }

    return buffer.toString();
  }
}

/// Structure de regroupement par point de défaillance
class _FindingPointGroup {
  final String verificationPoint;
  final AuditFinding representativeFinding;
  final List<AuditFinding> findings;
  final TensionDomain domain;
  final List<String> topEquipmentTypes;
  final List<String> topLocations;
  final Set<String> riskFamilies;

  _FindingPointGroup({
    required this.verificationPoint,
    required this.representativeFinding,
    required this.findings,
    required this.domain,
    required this.topEquipmentTypes,
    required this.topLocations,
    required this.riskFamilies,
  });
}

/// DTO d'interprétation d'un groupe
class _DerivedCompetency {
  final String title;
  final String skills;
  final String objective;
  final String rationale;
  final String fullNarrative;

  _DerivedCompetency({
    required this.title,
    required this.skills,
    required this.objective,
    required this.rationale,
    required this.fullNarrative,
  });
}
