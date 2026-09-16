// lib/services/statistics/competency_needs_engine.dart

import 'audit_finding.dart';
import 'canonical_risk_family_registry.dart';
import 'mission_statistics.dart';

/// Modèle d'un axe dynamique de renforcement des compétences.
///
/// Directement dérivé des constats réels et de la distribution statistique de la mission.
class CompetencyNeed {
  /// Identifiant technique unique de l'axe (ex: 'identification_documentation')
  final String id;

  /// Lettre de repérage dans le rapport : "a)", "b)", "c)", etc.
  final String letter;

  /// Intitulé métier clair, intelligible et professionnel de l'axe de compétence
  final String title;

  /// Description / Savoir-faire concrets à développer lors des formations
  final String recommendedSkills;

  /// Justification factuelle basée sur les constats réels relevés lors de la mission
  final String rationale;

  /// Résultat opérationnel concret attendu pour l'exploitation et la maintenance
  final String operationalObjective;

  /// Nombre exact d'occurrences de non-conformités rattachées à cet axe
  final int occurrenceCount;

  /// Part relative en pourcentage par rapport au total des non-conformités pertinentes (%)
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

  /// Texte narratif complet prêt pour le rendu documentaire
  String get fullNarrative {
    final buffer = StringBuffer();
    buffer.write(recommendedSkills.trim());
    if (!recommendedSkills.trim().endsWith('.')) {
      buffer.write('. ');
    } else {
      buffer.write(' ');
    }

    buffer.write(rationale.trim());
    if (!rationale.trim().endsWith('.')) {
      buffer.write('. ');
    } else {
      buffer.write(' ');
    }

    if (topEquipmentTypes.isNotEmpty || topLocations.isNotEmpty) {
      final locParts = <String>[];
      if (topEquipmentTypes.isNotEmpty) {
        locParts.add('sur les ${topEquipmentTypes.take(2).join(" et ")}');
      }
      if (topLocations.isNotEmpty) {
        locParts.add('au sein de : ${topLocations.take(2).join(", ")}');
      }
      buffer.write('Ces constats ont été observés principalement ${locParts.join(" ")}. ');
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

  /// Nombre total de non-conformités normatives analysées
  final int totalOccurrences;

  /// Texte d'introduction dynamique contextualisé à la mission
  final String introNarrative;

  /// Liste dynamique des axes de compétences prioritaires retenus, classés par ordre décroissant
  final List<CompetencyNeed> axes;

  /// Indique si la distribution présente une forte concentration sur 1 ou 2 thématiques
  final bool isConcentrated;

  /// Indique si la distribution est étalée / homogène sur de nombreuses thématiques
  final bool isDispersed;

  /// Indique s'il n'y a aucune non-conformité recensée
  final bool hasNoDefects;

  CompetencyNeedsAnalysisResult({
    required this.missionId,
    required this.totalOccurrences,
    required this.introNarrative,
    required this.axes,
    required this.isConcentrated,
    required this.isDispersed,
    required this.hasNoDefects,
  });
}

/// Définition canonique d'un domaine / thématique de compétences.
class _CompetencyThemeDefinition {
  final String id;
  final String title;
  final String recommendedSkills;
  final String operationalObjective;
  final List<String> keywords;

  const _CompetencyThemeDefinition({
    required this.id,
    required this.title,
    required this.recommendedSkills,
    required this.operationalObjective,
    required this.keywords,
  });

  /// Score de pertinence pour un constat donné
  int matchScore(String text) {
    int score = 0;
    for (final kw in keywords) {
      if (text.contains(kw)) {
        score += kw.length > 5 ? 2 : 1;
      }
    }
    return score;
  }
}

/// Moteur expert déterministe d'analyse des besoins de renforcement des compétences.
///
/// Entièrement local, sans IA externe, strictement fondé sur les données statistiques réelles.
class CompetencyNeedsEngine {
  /// Bibliothèque canonique des thématiques de renforcement des compétences
  static const List<_CompetencyThemeDefinition> _themes = [
    _CompetencyThemeDefinition(
      id: 'identification_documentation',
      title: 'Identification, repérage et documentation des installations',
      recommendedSkills:
          'Former les équipes à l’identification systématique des circuits, au repérage normalisé des départs et borniers, à la tenue à jour des schémas unifilaires et à la traçabilité immédiate de toute modification apportée aux tableaux',
      operationalObjective:
          'Cet axe vise à fiabiliser l’exploitation courante, à réduire les temps de localisation en cas d’avarie et à prévenir les erreurs de manœuvre lors des interventions',
      keywords: [
        'repérage',
        'reperage',
        'identification',
        'étiquetage',
        'etiquetage',
        'schéma',
        'schema',
        'unifilaire',
        'marquage',
        'signalisation',
        'code couleur',
        'pictogramme',
        'dossier technique',
        'désignation',
        'designation',
      ],
    ),
    _CompetencyThemeDefinition(
      id: 'cablage_connexions_maintenance',
      title: 'Câblage, raccordement et maintenance préventive',
      recommendedSkills:
          'Renforcer les compétences relatives aux règles de l’art du câblage, au contrôle périodique des couples de serrage des connexions, à la pose et à la protection mécanique des canalisations ainsi qu’à la détection précoce des échauffements et dégradations',
      operationalObjective:
          'L’objectif est de prévenir les défaillances de contact, d’éliminer les risques de surchauffe et de préserver l’intégrité des isolants et canalisations électriques',
      keywords: [
        'câblage',
        'cablage',
        'canalisation',
        'raccordement',
        'connexion',
        'serrage',
        'échauffement',
        'echauffement',
        'gaine',
        'cheminement',
        'passage de câble',
        'passage de cable',
        'protection mécanique',
        'protection mecanique',
        'bornier',
        'peigne',
        'cosse',
        'détérioré',
        'deteriore',
      ],
    ),
    _CompetencyThemeDefinition(
      id: 'consignation_securite',
      title: 'Consignation, déconsignation et sécurité électrique',
      recommendedSkills:
          'Renforcer la maîtrise des procédures réglementaires de consignation en 5 étapes, de déconsignation, de manœuvre des organes de coupure d’urgence, de vérification d’absence de tension (VAT) et de contrôle systématique de l’état des équipements de protection individuelle (EPI)',
      operationalObjective:
          'Ce renforcement est indispensable pour garantir la protection physique des intervenants et éliminer tout risque d’électrisation lors des opérations de maintenance',
      keywords: [
        'consignation',
        'déconsignation',
        'deconsignation',
        'vat',
        'absence de tension',
        'coupure d\'urgence',
        'coupure d’urgence',
        'arrêt d\'urgence',
        'arret d\'urgence',
        'organe de coupure',
        'sectionneur',
        'cadenas',
        'condamnation',
        'epi',
        'habilitation',
        'gant isolant',
        'nfc 18-510',
        'matériel de sécurité',
      ],
    ),
    _CompetencyThemeDefinition(
      id: 'protections_selectivite',
      title: 'Protections électriques, calibres et sélectivité',
      recommendedSkills:
          'Développer les compétences des équipes sur le dimensionnement et le fonctionnement des dispositifs de protection, la coordination et la sélectivité amont/aval, ainsi que sur l’interprétation des caractéristiques des appareillages et leur adéquation avec les sections de conducteurs',
      operationalObjective:
          'Cette démarche assure une élimination rapide et ciblée des défauts de surintensité sans déclenchement intempestif étendu à l’ensemble de l’installation',
      keywords: [
        'surintensité',
        'surintensite',
        'calibre',
        'disjoncteur',
        'fusible',
        'pouvoir de coupure',
        'sélectivité',
        'selectivite',
        'court-circuit',
        'coordination',
        'déclencheur',
        'declencheur',
        'inadéquation',
        'inadequation',
      ],
    ),
    _CompetencyThemeDefinition(
      id: 'terre_equipotentialite_surtensions',
      title: 'Mise à la terre, liaisons équipotentielles et parafoudres',
      recommendedSkills:
          'Former les intervenants aux principes de mise à la terre des masses, au contrôle périodique de la continuité des conducteurs de protection (PE) et des liaisons équipotentielles, ainsi qu’à la surveillance de l’état fonctionnel des parafoudres',
      operationalObjective:
          'L’enjeu est d’évacuer en toute sécurité les courants de défaut et de protéger les équipements sensibles contre les surtensions transitoires d’origine atmosphérique ou industrielle',
      keywords: [
        'mise à la terre',
        'mise a la terre',
        'prise de terre',
        'équipotentiel',
        'equipotentiel',
        'conducteur de protection',
        'barrette de coupure',
        'parafoudre',
        'surtension',
        'foudre',
        'liaison équipotentielle',
      ],
    ),
    _CompetencyThemeDefinition(
      id: 'differentiels_isolement',
      title: 'Dispositifs différentiels et surveillance d’isolement',
      recommendedSkills:
          'Perfectionner la pratique des essais périodiques des dispositifs différentiels à courant résiduel (DDR), la vérification des seuils et temps de déclenchement au contrôleur d’installation, ainsi que la méthode de recherche des défauts d’isolement',
      operationalObjective:
          'Cette compétence est essentielle pour prévenir les risques de contact indirect et éviter les départs d’incendie consécutifs à des courants de fuite permanents',
      keywords: [
        'différentiel',
        'differentiel',
        'ddr',
        'isolement',
        'courant de fuite',
        '30ma',
        '300ma',
        'sensibilité',
        'sensibilite',
        'cpi',
        'régime de neutre',
        'regime de neutre',
      ],
    ),
    _CompetencyThemeDefinition(
      id: 'enveloppes_etancheite_ip',
      title: 'Intégrité des enveloppes, plastrons et adéquation des indices IP/IK',
      recommendedSkills:
          'Sensibiliser les techniciens au maintien rigoureux de l’intégrité mécanique des enveloppes, à la pose systématique d’obturateurs sur les modules de réserve, au respect des degrés d’étanchéité IP/IK et à la prévention des infiltrations d’eau ou de poussière',
      operationalObjective:
          'L’objectif est d’éviter tout contact direct fortuit avec des pièces sous tension et de préserver les tableaux contre les dégradations liées à leur environnement',
      keywords: [
        'enveloppe',
        'plastron',
        'obturation',
        'obturateur',
        'ip',
        'ik',
        'étanchéité',
        'etancheite',
        'contact direct',
        'porte',
        'serrure',
        'corrosion',
        'indice de protection',
      ],
    ),
    _CompetencyThemeDefinition(
      id: 'poste_haute_tension_mt',
      title: 'Postes HTA, appareillages Moyenne Tension et manœuvres',
      recommendedSkills:
          'Renforcer les compétences spécifiques nécessaires à l’exploitation des postes de transformation et de livraison HTA, au respect des séquences d’interverrouillage mécanique, à la surveillance des transformateurs (DGPT2, diélectrique) et à la réalisation des manœuvres de mise à la terre',
      operationalObjective:
          'Cet axe garantit une exploitation sécurisée sur le domaine HTA et fiabilise les organes d’alimentation amont stratégiques du site',
      keywords: [
        'cellule mt',
        'cellule hta',
        'moyenne tension',
        'transformateur',
        'transfo',
        'interrupteur mt',
        'disjoncteur mt',
        'verrouillage',
        'gaep',
        'dgpt2',
        'manœuvre mt',
        'manoeuvre mt',
      ],
    ),
    _CompetencyThemeDefinition(
      id: 'groupes_secours_inverseurs',
      title: 'Groupes électrogènes, inverseurs de source et alimentations de secours',
      recommendedSkills:
          'Développer les savoir-faire sur la maintenance préventive des groupes électrogènes de secours (contrôle des batteries de démarrage, circuits carburant, réchauffage, tests périodiques en charge) et la manœuvre des inverseurs de source Normal/Secours',
      operationalObjective:
          'L’enjeu est d’assurer une reprise de secours fiable et instantanée sans risque de retour de tension vers le réseau amont',
      keywords: [
        'groupe électrogène',
        'groupe electrogene',
        'inverseur',
        'secours',
        'batterie de démarrage',
        'batterie de demarrage',
        'fioul',
        'carburant',
        'cuve',
        'démarrage automatique',
      ],
    ),
    _CompetencyThemeDefinition(
      id: 'eclairage_securite_evacuation',
      title: 'Éclairage de sécurité et blocs autonomes d’évacuation',
      recommendedSkills:
          'Former les intervenants aux procédures de contrôle réglementaire périodique des blocs autonomes d’éclairage de sécurité (BAES/BAEH), à la vérification de leur autonomie sur batterie et à la gestion du registre de sécurité associé',
      operationalObjective:
          'Cet axe garantit le balisage des cheminements et l’évacuation du personnel en toute circonstance en cas de perte de tension',
      keywords: [
        'éclairage de sécurité',
        'eclairage de securite',
        'baes',
        'baeh',
        'bloc autonome',
        'évacuation',
        'evacuation',
        'autonomie batterie',
      ],
    ),
    _CompetencyThemeDefinition(
      id: 'thermographie_points_chauds',
      title: 'Thermographie infrarouge et diagnostic prédictif',
      recommendedSkills:
          'Former les équipes à l’utilisation de la caméra thermique infrarouge comme outil de maintenance préventive, pour la détection méthodique des échauffements anormaux au niveau des connexions, départs et appareillages en charge',
      operationalObjective:
          'L’objectif est de déceler les points chauds avant dégradation irrémédiable des composants et d’éviter les départs d’incendie',
      keywords: [
        'thermographie',
        'infrarouge',
        'caméra thermique',
        'camera thermique',
        'point chaud',
        'échauffement anormal',
        'delta t',
      ],
    ),
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
    final pertinent = findings.where(AuditFindingInventory.isNormativeNonConformity).toList();
    final totalOccurrences = totalNC ?? pertinent.length;

    // Cas 0 non-conformité
    if (totalOccurrences == 0 || pertinent.isEmpty) {
      return CompetencyNeedsAnalysisResult(
        missionId: missionId,
        totalOccurrences: 0,
        introNarrative:
            'L’audit n’a relevé aucun constat de non-conformité sur les installations contrôlées. '
            'Le niveau de conformité technique est optimal. Il convient de maintenir les compétences actuelles '
            'des équipes par des recyclages réguliers sur les procédures de sécurité et d’habilitation électrique.',
        axes: [],
        isConcentrated: false,
        isDispersed: false,
        hasNoDefects: true,
      );
    }

    // 1. Regroupement sémantique de chaque non-conformité dans les thématiques
    final themeBuckets = <String, List<AuditFinding>>{};
    for (final th in _themes) {
      themeBuckets[th.id] = [];
    }

    final unclassified = <AuditFinding>[];

    for (final f in pertinent) {
      final matchedTheme = _matchFindingToTheme(f);
      if (matchedTheme != null) {
        themeBuckets[matchedTheme.id]!.add(f);
      } else {
        unclassified.add(f);
      }
    }

    // Si certains constats n'ont pas matché de façon évidente, les affecter selon leur famille de risque
    for (final f in unclassified) {
      final fallbackTheme = _fallbackThemeFromRiskFamily(f);
      themeBuckets[fallbackTheme.id]!.add(f);
    }

    // 2. Construction des objets intermédiaires pour chaque thématique active
    final activeThemeResults = <_ThemeAccumulator>[];

    for (final th in _themes) {
      final bucket = themeBuckets[th.id]!;
      if (bucket.isEmpty) continue; // RÈGLE ABSOLUE : aucun thème avec 0 constat n'est retenu

      final count = bucket.length;
      final pct = (count / totalOccurrences) * 100.0;
      final critiques = bucket.where((f) => f.criticality.trim().toLowerCase() == 'critique').length;
      final majeures = bucket.where((f) => f.criticality.trim().toLowerCase() == 'majeure').length;
      final mineures = bucket.where((f) => f.criticality.trim().toLowerCase() == 'mineure').length;

      // Points de contrôle uniques
      final pts = bucket.map((f) => f.verificationPoint.trim()).where((p) => p.isNotEmpty).toSet().toList();

      // Familles de risques
      final rfs = bucket.map((f) => f.riskFamily?.trim() ?? '').where((r) => r.isNotEmpty).toSet().toList();

      // Équipements touchés
      final eqCounts = <String, int>{};
      for (final f in bucket) {
        final eq = f.objectType.trim().isNotEmpty ? f.objectType.trim() : 'Équipements';
        eqCounts[eq] = (eqCounts[eq] ?? 0) + 1;
      }
      final sortedEqs = eqCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topEqs = sortedEqs.take(3).map((e) => e.key).toList();

      // Locaux / origines touchés
      final locCounts = <String, int>{};
      for (final f in bucket) {
        final loc = f.origin.trim().isNotEmpty ? f.origin.trim() : f.objectName.trim();
        if (loc.isNotEmpty && !loc.toLowerCase().contains('inconnu')) {
          locCounts[loc] = (locCounts[loc] ?? 0) + 1;
        }
      }
      final sortedLocs = locCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topLocs = sortedLocs.take(2).map((e) => e.key).toList();

      final hasMt = bucket.any((f) => f.tensionDomain == TensionDomain.mt);
      final hasBt = bucket.any((f) => f.tensionDomain == TensionDomain.bt);

      activeThemeResults.add(
        _ThemeAccumulator(
          themeDef: th,
          findings: bucket,
          count: count,
          percentage: pct,
          critiqueCount: critiques,
          majeureCount: majeures,
          mineureCount: mineures,
          sourceVerificationPoints: pts,
          riskFamilies: rfs,
          topEquipmentTypes: topEqs,
          topLocations: topLocs,
          hasMtDomain: hasMt,
          hasBtDomain: hasBt,
        ),
      );
    }

    // 3. Classement strict par nombre d'occurrences décroissant (puis criticité)
    activeThemeResults.sort((a, b) {
      final cmp = b.count.compareTo(a.count);
      if (cmp != 0) return cmp;
      return b.critiqueCount.compareTo(a.critiqueCount);
    });

    // 4. Sélection dynamique du nombre d'axes
    // Le nombre d'axes s'adapte à la distribution réelle sans inventer ni forcer de quotas
    final selectedAccumulators = _selectRelevantThemes(activeThemeResults, totalOccurrences);

    // 5. Attribution des lettres dynamiques a), b), c)...
    final letters = ['a)', 'b)', 'c)', 'd)', 'e)', 'f)', 'g)', 'h)', 'i)', 'j)', 'k)'];
    final axes = <CompetencyNeed>[];

    for (int i = 0; i < selectedAccumulators.length; i++) {
      final acc = selectedAccumulators[i];
      final letter = i < letters.length ? letters[i] : '${i + 1})';

      // Construction de la justification factuelle chiffrée
      final rationale = _buildRationale(acc, totalOccurrences);

      axes.add(
        CompetencyNeed(
          id: acc.themeDef.id,
          letter: letter,
          title: acc.themeDef.title,
          recommendedSkills: acc.themeDef.recommendedSkills,
          rationale: rationale,
          operationalObjective: acc.themeDef.operationalObjective,
          occurrenceCount: acc.count,
          percentage: acc.percentage,
          critiqueCount: acc.critiqueCount,
          majeureCount: acc.majeureCount,
          mineureCount: acc.mineureCount,
          sourceVerificationPoints: acc.sourceVerificationPoints,
          riskFamilies: acc.riskFamilies,
          topEquipmentTypes: acc.topEquipmentTypes,
          topLocations: acc.topLocations,
          hasMtDomain: acc.hasMtDomain,
          hasBtDomain: acc.hasBtDomain,
        ),
      );
    }

    // 6. Diagnostic de concentration et génération de l'introduction narrative
    final top2Share = selectedAccumulators.take(2).fold<double>(0.0, (s, e) => s + e.percentage);
    final isConcentrated = selectedAccumulators.length <= 3 || (top2Share >= 55.0 && totalOccurrences >= 10);
    final isDispersed = !isConcentrated && selectedAccumulators.length >= 4;

    final introNarrative = _buildIntroNarrative(
      totalOccurrences: totalOccurrences,
      axes: axes,
      isConcentrated: isConcentrated,
      top2Share: top2Share,
      tensionStats: tensionDomainStats,
      riskStats: riskFamilyStats,
    );

    return CompetencyNeedsAnalysisResult(
      missionId: missionId,
      totalOccurrences: totalOccurrences,
      introNarrative: introNarrative,
      axes: axes,
      isConcentrated: isConcentrated,
      isDispersed: isDispersed,
      hasNoDefects: false,
    );
  }

  /// Associe un constat au thème le plus pertinent selon un scoring sémantique
  static _CompetencyThemeDefinition? _matchFindingToTheme(AuditFinding f) {
    final text = '${f.verificationPoint} ${f.observationText} ${f.tableName} ${f.objectType} ${f.origin} ${f.riskFamily ?? ""}'
        .toLowerCase();

    _CompetencyThemeDefinition? bestTheme;
    int maxScore = 0;

    for (final th in _themes) {
      int score = th.matchScore(text);
      // Si constat sur équipement MT (Cellule MT, Transformateur MT/BT) ou domaine MT
      if (th.id == 'poste_haute_tension_mt' &&
          (f.tensionDomain == TensionDomain.mt ||
           f.objectType.toLowerCase().contains('cellule') ||
           f.objectType.toLowerCase().contains('transformateur') ||
           text.contains('hta') ||
           text.contains('moyenne tension'))) {
        score += 5;
      }

      if (score > maxScore) {
        maxScore = score;
        bestTheme = th;
      }
    }

    return maxScore > 0 ? bestTheme : null;
  }

  /// Thème de repli déterministe en fonction de la famille de risque canonique
  static _CompetencyThemeDefinition _fallbackThemeFromRiskFamily(AuditFinding f) {
    final rf = CanonicalRiskFamilyRegistry.mapToCanonical(f.riskFamily, verificationPoint: f.verificationPoint);
    switch (rf) {
      case CanonicalRiskFamilyRegistry.erreurExploitation:
        return _themes.firstWhere((t) => t.id == 'identification_documentation');
      case CanonicalRiskFamilyRegistry.degradationCanalisations:
      case CanonicalRiskFamilyRegistry.echauffementSurcharge:
        return _themes.firstWhere((t) => t.id == 'cablage_connexions_maintenance');
      case CanonicalRiskFamilyRegistry.surintensiteCourtCircuit:
        return _themes.firstWhere((t) => t.id == 'protections_selectivite');
      case CanonicalRiskFamilyRegistry.electrissationElectrocution:
      default:
        return _themes.firstWhere((t) => t.id == 'terre_equipotentialite_surtensions');
    }
  }

  /// Sélectionne dynamiquement les thèmes pertinents
  static List<_ThemeAccumulator> _selectRelevantThemes(
    List<_ThemeAccumulator> allActive,
    int totalOccurrences,
  ) {
    if (allActive.isEmpty) return [];

    // Si peu de non-conformités (<= 5), ne garder que les thèmes ayant effectivement des constats
    if (totalOccurrences <= 5) {
      return allActive;
    }

    // Si plusieurs thématiques, on retient celles qui ont une part significative (>= 3% ou au moins 2 constats)
    // ou les thématiques du Pareto couvrant la majorité des défauts
    final selected = <_ThemeAccumulator>[];
    double cumulativePct = 0.0;

    for (final item in allActive) {
      // Retenir systématiquement les thèmes ayant au moins 4 % des défauts ou au moins 3 constats
      // ou tant qu'on n'a pas couvert 85% des constats
      final isSignificant = item.percentage >= 4.0 || item.count >= 3;
      final needsCoverage = cumulativePct < 85.0 || selected.length < 2;

      if (isSignificant || needsCoverage) {
        selected.add(item);
        cumulativePct += item.percentage;
      }
    }

    // Garantir au moins 1 thème si disponible
    if (selected.isEmpty && allActive.isNotEmpty) {
      selected.add(allActive.first);
    }

    return selected;
  }

  /// Construit la justification factuelle chiffrée pour un axe
  static String _buildRationale(_ThemeAccumulator acc, int totalOccurrences) {
    final count = acc.count;
    final pctStr = acc.percentage.toStringAsFixed(1).replaceAll('.', ',');

    final buffer = StringBuffer();
    if (acc.percentage >= 25.0) {
      buffer.write('Cet axe constitue une priorité absolue de la mission, rassemblant $count constats ');
      buffer.write('(soit $pctStr % de l’ensemble des non-conformités recensées)');
    } else if (acc.percentage >= 15.0) {
      buffer.write('Cette thématique représente un volume majeur d’écarts avec $count constats ');
      buffer.write('(soit $pctStr % du total de la mission)');
    } else {
      buffer.write('Cette thématique totalise $count constat${count > 1 ? "s" : ""} ');
      buffer.write('($pctStr % des écarts identifiés)');
    }

    if (acc.critiqueCount > 0) {
      buffer.write(', dont ${acc.critiqueCount} non-conformité${acc.critiqueCount > 1 ? "s" : ""} critique${acc.critiqueCount > 1 ? "s" : ""} ');
      buffer.write('exigeant une vigilance accrue');
    } else if (acc.majeureCount > 0) {
      buffer.write(', dont ${acc.majeureCount} non-conformité${acc.majeureCount > 1 ? "s" : ""} majeure${acc.majeureCount > 1 ? "s" : ""}');
    }

    return buffer.toString();
  }

  /// Construit le paragraphe introductif d'analyse dynamique de la section 10
  static String _buildIntroNarrative({
    required int totalOccurrences,
    required List<CompetencyNeed> axes,
    required bool isConcentrated,
    required double top2Share,
    TensionDomainStats? tensionStats,
    List<RiskFamilyItem>? riskStats,
  }) {
    if (axes.isEmpty) {
      return 'L’analyse des non-conformités ne met en évidence aucun besoin de renforcement particulier.';
    }

    final top1 = axes.first;
    final top2 = axes.length > 1 ? axes[1] : null;

    final buffer = StringBuffer();
    buffer.write('L’analyse des non-conformités de la mission ');

    // 1. Analyse de la distribution statistique (Concentration vs Dispersion)
    if (isConcentrated && top2 != null) {
      buffer.write('met en évidence une forte concentration des écarts autour de deux thématiques prépondérantes : ');
      buffer.write('« ${top1.title} » (${top1.occurrenceCount} constats, soit ${top1.percentageStr} %) et ');
      buffer.write('« ${top2.title} » (${top2.occurrenceCount} constats, soit ${top2.percentageStr} %), ');
      buffer.write('qui cumulent à elles seules ${top2Share.toStringAsFixed(1).replaceAll('.', ',')} % des défaillances. ');
    } else if (isConcentrated && top2 == null) {
      buffer.write('révèle une prédominance marquée de la thématique « ${top1.title} », ');
      buffer.write('qui rassemble ${top1.occurrenceCount} des $totalOccurrences non-conformités identifiées (${top1.percentageStr} %). ');
    } else {
      buffer.write('révèle une répartition des écarts sur plusieurs registres techniques, ');
      buffer.write('menée principalement par « ${top1.title} » (${top1.occurrenceCount} constats, ${top1.percentageStr} %) ');
      if (top2 != null) {
        buffer.write('et « ${top2.title} » (${top2.occurrenceCount} constats, ${top2.percentageStr} %), ');
      }
      buffer.write('traduisant des besoins de consolidation diversifiés au sein des équipes. ');
    }

    // 2. Contexte tension HTA / BT si disponible
    if (tensionStats != null && tensionStats.totalCount > 0) {
      if (tensionStats.btPct >= 70.0) {
        buffer.write('Ces constats concernent très majoritairement le réseau Basse Tension (${tensionStats.btPercentageStr} des non-conformités), ');
        buffer.write('qui concentre les opérations d’exploitation quotidienne et de maintenance de premier niveau. ');
      } else if (tensionStats.mtPct >= 40.0) {
        buffer.write('Une part significative des écarts (${tensionStats.mtPercentageStr}) intéresse directement les installations Moyenne Tension (HTA), ');
        buffer.write('ce qui nécessite des compétences spécifiques de manœuvre et de consignation haute sécurité. ');
      }
    }

    // 3. Conclusion opérationnelle sur les compétences
    buffer.write(
      'Ces résultats traduisent la nécessité de structurer le programme de formation autour des pratiques réelles '
      'du terrain afin de sécuriser durablement l’exploitation des installations électriques.',
    );

    return buffer.toString();
  }
}

/// Structure temporaire pour l'accumulation et le tri
class _ThemeAccumulator {
  final _CompetencyThemeDefinition themeDef;
  final List<AuditFinding> findings;
  final int count;
  final double percentage;
  final int critiqueCount;
  final int majeureCount;
  final int mineureCount;
  final List<String> sourceVerificationPoints;
  final List<String> riskFamilies;
  final List<String> topEquipmentTypes;
  final List<String> topLocations;
  final bool hasMtDomain;
  final bool hasBtDomain;

  _ThemeAccumulator({
    required this.themeDef,
    required this.findings,
    required this.count,
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
  });
}
