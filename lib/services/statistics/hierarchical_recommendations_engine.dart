// lib/services/statistics/hierarchical_recommendations_engine.dart

import 'audit_finding.dart';
import 'canonical_defect_category_registry.dart';
import 'mission_statistics.dart';

/// Niveaux de priorité pour les recommandations hiérarchisées
enum RecommendationPriorityLevel {
  priority1Immediate, // Critique -> Priorité 1 — Action Immédiate
  priority2ShortTerm,  // Majeure -> Priorité 2 — Court Terme
  priority3MediumTerm, // Mineure -> Priorité 3 — Moyen Terme
}

/// Modèle d'une recommandation élémentaire contextualisée (niveau analytique interne)
class HierarchicalRecommendation {
  final String id;
  final RecommendationPriorityLevel priorityLevel;
  final String priorityLabel;       // ex: "Priorité 1 — Action Immédiate"
  final String criticalityLabel;   // ex: "Critique", "Majeure", "Mineure"
  final TensionDomain domain;       // TensionDomain.mt ou TensionDomain.bt
  final String domainLabel;         // "HTA" ou "BT"
  final String issueTitle;          // Problématique / Point de vérification identifié
  final int occurrenceCount;        // Nombre exact d'occurrences réelles
  final double percentageOfDomain;  // Part dans le total des NC du domaine
  final String recommendedAction;   // Action corrective technique concrète
  final List<String> impactedEquipments; // Noms/repères des équipements concernés
  final List<String> impactedLocations;  // Locaux ou zones concernés
  final List<String> normativeReferences;// Références normatives réelles
  final List<AuditFinding> sourceFindings;// Traçabilité 100% avec les constats réels

  const HierarchicalRecommendation({
    required this.id,
    required this.priorityLevel,
    required this.priorityLabel,
    required this.criticalityLabel,
    required this.domain,
    required this.domainLabel,
    required this.issueTitle,
    required this.occurrenceCount,
    required this.percentageOfDomain,
    required this.recommendedAction,
    required this.impactedEquipments,
    required this.impactedLocations,
    required this.normativeReferences,
    required this.sourceFindings,
  });

  /// Chaîne formatée du pourcentage (ex: "18,5")
  String get percentageStr => percentageOfDomain.toStringAsFixed(1).replaceAll('.', ',');

  /// Synthèse textuelle du contexte technique et des équipements impactés
  String get contextSummary {
    final parts = <String>[];
    if (impactedEquipments.isNotEmpty) {
      if (impactedEquipments.length <= 3) {
        parts.add(impactedEquipments.join(', '));
      } else {
        final sample = impactedEquipments.take(3).join(', ');
        parts.add('$sample (+${impactedEquipments.length - 3} autres)');
      }
    }
    if (impactedLocations.isNotEmpty && impactedLocations.any((l) => l.isNotEmpty)) {
      final locs = impactedLocations.where((l) => l.isNotEmpty).toSet().take(2).join(', ');
      if (locs.isNotEmpty) {
        parts.add('Localisation : $locs');
      }
    }
    return parts.isNotEmpty ? parts.join(' — ') : 'Ensemble des installations';
  }
}

/// Modèle d'une action corrective agrégée par criticité pour la cellule finale du tableau synthétique
class DomainCriticalityAggregatedAction {
  final TensionDomain domain;
  final String criticalityLabel; // "Critique", "Majeure", "Mineure"
  final RecommendationPriorityLevel priorityLevel;
  final String priorityLabel; // "Priorité 1 — Action Immédiate", etc.
  final int occurrenceCount; // Nombre total d'occurrences pour cette criticité
  final List<String> actionBullets; // Actions intelligemment regroupées et généralisées sans déformation
  final List<HierarchicalRecommendation> sourceRecommendations; // Traçabilité intermédiaire
  final List<AuditFinding> sourceFindings; // Traçabilité amont directe

  const DomainCriticalityAggregatedAction({
    required this.domain,
    required this.criticalityLabel,
    required this.priorityLevel,
    required this.priorityLabel,
    required this.occurrenceCount,
    required this.actionBullets,
    required this.sourceRecommendations,
    required this.sourceFindings,
  });

  bool get hasActions => occurrenceCount > 0 && actionBullets.isNotEmpty;
}

/// Modèle de tableau synthétique d'un domaine (MT ou BT) comportant les 3 lignes de criticité
class DomainTableData {
  final TensionDomain domain;
  final String domainTitle; // "ACTIONS À RÉALISER EN MOYENNE TENSION (HTA)" ou "ACTIONS À RÉALISER EN BASSE TENSION (BT)"
  final DomainCriticalityAggregatedAction critiqueAction;
  final DomainCriticalityAggregatedAction majeureAction;
  final DomainCriticalityAggregatedAction mineureAction;

  const DomainTableData({
    required this.domain,
    required this.domainTitle,
    required this.critiqueAction,
    required this.majeureAction,
    required this.mineureAction,
  });

  List<DomainCriticalityAggregatedAction> get rows => [critiqueAction, majeureAction, mineureAction];
  bool get hasAnyAction => critiqueAction.hasActions || majeureAction.hasActions || mineureAction.hasActions;
  int get totalOccurrences => critiqueAction.occurrenceCount + majeureAction.occurrenceCount + mineureAction.occurrenceCount;
}

/// Résultat complet de l'analyse hiérarchique des recommandations
class HierarchicalRecommendationsResult {
  final List<HierarchicalRecommendation> mtRecommendations;
  final List<HierarchicalRecommendation> btRecommendations;
  final List<HierarchicalRecommendation> allRecommendations;
  final DomainTableData mtTable;
  final DomainTableData btTable;
  final int totalCritique;
  final int totalMajeure;
  final int totalMineure;
  final int totalOccurrences;

  const HierarchicalRecommendationsResult({
    required this.mtRecommendations,
    required this.btRecommendations,
    required this.allRecommendations,
    required this.mtTable,
    required this.btTable,
    required this.totalCritique,
    required this.totalMajeure,
    required this.totalMineure,
    required this.totalOccurrences,
  });

  bool get isEmpty => totalOccurrences == 0;
  bool get hasMt => mtRecommendations.isNotEmpty;
  bool get hasBt => btRecommendations.isNotEmpty;

  int get countImmediate => allRecommendations.where((r) => r.priorityLevel == RecommendationPriorityLevel.priority1Immediate).length;
  int get countShortTerm => allRecommendations.where((r) => r.priorityLevel == RecommendationPriorityLevel.priority2ShortTerm).length;
  int get countMediumTerm => allRecommendations.where((r) => r.priorityLevel == RecommendationPriorityLevel.priority3MediumTerm).length;
}

/// Moteur expert déterministe de déduction et hiérarchisation des recommandations
class HierarchicalRecommendationsEngine {
  /// Génère les recommandations à partir des constats réels du snapshot statistique
  static HierarchicalRecommendationsResult analyze(MissionStatisticsSummary summary) {
    final findings = summary.inventory.pertinentFindings;
    return analyzeFindings(findings);
  }

  /// Analyse une liste brute de constats pertinents
  static HierarchicalRecommendationsResult analyzeFindings(List<AuditFinding> findings) {
    if (findings.isEmpty) {
      final emptyMtTable = DomainTableData(
        domain: TensionDomain.mt,
        domainTitle: 'ACTIONS À RÉALISER EN MOYENNE TENSION (HTA)',
        critiqueAction: _buildEmptyAction(TensionDomain.mt, RecommendationPriorityLevel.priority1Immediate, 'Critique', 'Priorité 1 — Action Immédiate'),
        majeureAction: _buildEmptyAction(TensionDomain.mt, RecommendationPriorityLevel.priority2ShortTerm, 'Majeure', 'Priorité 2 — Court Terme'),
        mineureAction: _buildEmptyAction(TensionDomain.mt, RecommendationPriorityLevel.priority3MediumTerm, 'Mineure', 'Priorité 3 — Moyen Terme'),
      );
      final emptyBtTable = DomainTableData(
        domain: TensionDomain.bt,
        domainTitle: 'ACTIONS À RÉALISER EN BASSE TENSION (BT)',
        critiqueAction: _buildEmptyAction(TensionDomain.bt, RecommendationPriorityLevel.priority1Immediate, 'Critique', 'Priorité 1 — Action Immédiate'),
        majeureAction: _buildEmptyAction(TensionDomain.bt, RecommendationPriorityLevel.priority2ShortTerm, 'Majeure', 'Priorité 2 — Court Terme'),
        mineureAction: _buildEmptyAction(TensionDomain.bt, RecommendationPriorityLevel.priority3MediumTerm, 'Mineure', 'Priorité 3 — Moyen Terme'),
      );

      return HierarchicalRecommendationsResult(
        mtRecommendations: const [],
        btRecommendations: const [],
        allRecommendations: const [],
        mtTable: emptyMtTable,
        btTable: emptyBtTable,
        totalCritique: 0,
        totalMajeure: 0,
        totalMineure: 0,
        totalOccurrences: 0,
      );
    }

    // 1. Séparation stricte et étanche MT / BT à partir de la donnée source
    final mtFindings = findings.where((f) => f.tensionDomain == TensionDomain.mt).toList();
    final btFindings = findings.where((f) => f.tensionDomain == TensionDomain.bt).toList();

    // 2. Traitement des recommandations par domaine (niveau analytique élémentaire)
    final mtRecommendations = _buildDomainRecommendations(mtFindings, TensionDomain.mt);
    final btRecommendations = _buildDomainRecommendations(btFindings, TensionDomain.bt);

    // 3. Synthèse globale ordonnée
    final allRecommendations = [...mtRecommendations, ...btRecommendations]
      ..sort(_compareRecommendations);

    // 4. Construction des tables synthétiques à 3 lignes (Critique, Majeure, Mineure)
    final mtTable = _buildDomainTableData(TensionDomain.mt, mtRecommendations, mtFindings);
    final btTable = _buildDomainTableData(TensionDomain.bt, btRecommendations, btFindings);

    int critCount = 0;
    int majCount = 0;
    int minCount = 0;
    for (final f in findings) {
      final c = f.criticality.toLowerCase();
      if (c == 'critique') {
        critCount++;
      } else if (c == 'majeure') {
        majCount++;
      } else if (c == 'mineure') {
        minCount++;
      }
    }

    return HierarchicalRecommendationsResult(
      mtRecommendations: mtRecommendations,
      btRecommendations: btRecommendations,
      allRecommendations: allRecommendations,
      mtTable: mtTable,
      btTable: btTable,
      totalCritique: critCount,
      totalMajeure: majCount,
      totalMineure: minCount,
      totalOccurrences: findings.length,
    );
  }

  /// Construit un tableau synthétique pour un domaine de tension donné (3 lignes fixes : Critique, Majeure, Mineure)
  static DomainTableData _buildDomainTableData(
    TensionDomain domain,
    List<HierarchicalRecommendation> domainRecos,
    List<AuditFinding> domainFindings,
  ) {
    final domainTitle = domain == TensionDomain.mt
        ? 'ACTIONS À RÉALISER EN MOYENNE TENSION (HTA)'
        : 'ACTIONS À RÉALISER EN BASSE TENSION (BT)';

    final critiqueAction = _buildAggregatedAction(
      domain: domain,
      priorityLevel: RecommendationPriorityLevel.priority1Immediate,
      criticalityLabel: 'Critique',
      priorityLabel: 'Priorité 1 — Action Immédiate',
      domainRecos: domainRecos,
      domainFindings: domainFindings,
    );

    final majeureAction = _buildAggregatedAction(
      domain: domain,
      priorityLevel: RecommendationPriorityLevel.priority2ShortTerm,
      criticalityLabel: 'Majeure',
      priorityLabel: 'Priorité 2 — Court Terme',
      domainRecos: domainRecos,
      domainFindings: domainFindings,
    );

    final mineureAction = _buildAggregatedAction(
      domain: domain,
      priorityLevel: RecommendationPriorityLevel.priority3MediumTerm,
      criticalityLabel: 'Mineure',
      priorityLabel: 'Priorité 3 — Moyen Terme',
      domainRecos: domainRecos,
      domainFindings: domainFindings,
    );

    return DomainTableData(
      domain: domain,
      domainTitle: domainTitle,
      critiqueAction: critiqueAction,
      majeureAction: majeureAction,
      mineureAction: mineureAction,
    );
  }

  /// Construit une action agrégée pour une criticité donnée.
  /// RÈGLE ABSOLUE : Si 0 non-conformité constatée pour cette criticité, actionBullets est vide (ZÉRO invention) !
  static DomainCriticalityAggregatedAction _buildAggregatedAction({
    required TensionDomain domain,
    required RecommendationPriorityLevel priorityLevel,
    required String criticalityLabel,
    required String priorityLabel,
    required List<HierarchicalRecommendation> domainRecos,
    required List<AuditFinding> domainFindings,
  }) {
    final critNorm = criticalityLabel.toLowerCase();
    final critFindings = domainFindings.where((f) => _normalizeCriticality(f.criticality) == critNorm).toList();
    final critRecos = domainRecos.where((r) => r.priorityLevel == priorityLevel).toList();

    if (critFindings.isEmpty || critRecos.isEmpty) {
      return _buildEmptyAction(domain, priorityLevel, criticalityLabel, priorityLabel);
    }

    final bullets = _synthesizeAggregatedBullets(critRecos, domain, critNorm);

    return DomainCriticalityAggregatedAction(
      domain: domain,
      criticalityLabel: criticalityLabel,
      priorityLevel: priorityLevel,
      priorityLabel: priorityLabel,
      occurrenceCount: critFindings.length,
      actionBullets: bullets,
      sourceRecommendations: critRecos,
      sourceFindings: critFindings,
    );
  }

  static DomainCriticalityAggregatedAction _buildEmptyAction(
    TensionDomain domain,
    RecommendationPriorityLevel priorityLevel,
    String criticalityLabel,
    String priorityLabel,
  ) {
    return DomainCriticalityAggregatedAction(
      domain: domain,
      criticalityLabel: criticalityLabel,
      priorityLevel: priorityLevel,
      priorityLabel: priorityLabel,
      occurrenceCount: 0,
      actionBullets: const [],
      sourceRecommendations: const [],
      sourceFindings: const [],
    );
  }

  /// Construit les recommandations d'un domaine de tension donné
  static List<HierarchicalRecommendation> _buildDomainRecommendations(
    List<AuditFinding> domainFindings,
    TensionDomain domain,
  ) {
    if (domainFindings.isEmpty) return const [];

    final totalDomain = domainFindings.length;
    final domainLabel = domain == TensionDomain.mt ? 'HTA' : 'BT';

    // Regroupement par clé unique (criticité + point de vérification normalisé)
    final grouped = <String, List<AuditFinding>>{};
    for (final f in domainFindings) {
      final critNorm = _normalizeCriticality(f.criticality);
      final keyNorm = _normalizeIssueKey(f.verificationPoint, f.tableName);
      final groupKey = '$critNorm|$keyNorm';
      grouped.putIfAbsent(groupKey, () => []).add(f);
    }

    final recommendations = <HierarchicalRecommendation>[];

    for (final entry in grouped.entries) {
      final groupFindings = entry.value;
      if (groupFindings.isEmpty) continue;

      final first = groupFindings.first;
      final critNorm = _normalizeCriticality(first.criticality);

      // Détermination du niveau de priorité
      final RecommendationPriorityLevel priorityLevel;
      final String priorityLabel;
      final String criticalityLabel;

      if (critNorm == 'critique') {
        priorityLevel = RecommendationPriorityLevel.priority1Immediate;
        priorityLabel = 'Priorité 1 — Action Immédiate';
        criticalityLabel = 'Critique';
      } else if (critNorm == 'majeure') {
        priorityLevel = RecommendationPriorityLevel.priority2ShortTerm;
        priorityLabel = 'Priorité 2 — Court Terme';
        criticalityLabel = 'Majeure';
      } else {
        priorityLevel = RecommendationPriorityLevel.priority3MediumTerm;
        priorityLabel = 'Priorité 3 — Moyen Terme';
        criticalityLabel = 'Mineure';
      }

      final issueTitle = _buildCleanIssueTitle(first.verificationPoint, first.tableName);
      final occurrenceCount = groupFindings.length;
      final percentage = totalDomain > 0 ? (occurrenceCount / totalDomain) * 100.0 : 0.0;

      // Collecte des équipements impactés (dédoublonnés)
      final equipmentsSet = <String>{};
      for (final f in groupFindings) {
        final name = f.objectName.trim();
        final rep = f.objectRepere?.trim() ?? '';
        if (name.isNotEmpty) {
          if (rep.isNotEmpty && !name.contains(rep)) {
            equipmentsSet.add('$name ($rep)');
          } else {
            equipmentsSet.add(name);
          }
        }
      }

      // Collecte des localisations impactées
      final locationsSet = <String>{};
      for (final f in groupFindings) {
        final orig = f.origin.trim();
        if (orig.isNotEmpty) locationsSet.add(orig);
      }

      // Collecte des références normatives réelles
      final normSet = <String>{};
      for (final f in groupFindings) {
        final norm = f.normativeReference?.trim() ?? '';
        if (norm.isNotEmpty) normSet.add(norm);
      }

      // Action corrective technique concrète déduite
      final action = _generateActionText(
        issueTitle: issueTitle,
        verificationPoint: first.verificationPoint,
        criticality: critNorm,
        domain: domain,
        sampleObservations: groupFindings.map((f) => f.observationText).toList(),
        normativeRefs: normSet.toList(),
      );

      final id = '${domainLabel.toLowerCase()}_${critNorm}_${recommendations.length + 1}';

      recommendations.add(HierarchicalRecommendation(
        id: id,
        priorityLevel: priorityLevel,
        priorityLabel: priorityLabel,
        criticalityLabel: criticalityLabel,
        domain: domain,
        domainLabel: domainLabel,
        issueTitle: issueTitle,
        occurrenceCount: occurrenceCount,
        percentageOfDomain: percentage,
        recommendedAction: action,
        impactedEquipments: equipmentsSet.toList(),
        impactedLocations: locationsSet.toList(),
        normativeReferences: normSet.toList(),
        sourceFindings: groupFindings,
      ));
    }

    // Tri déterministe
    recommendations.sort(_compareRecommendations);
    return recommendations;
  }

  /// Comparateur déterministe : Priorité (1 > 2 > 3), puis Occurrences (desc), puis Titre alphabétique
  static int _compareRecommendations(HierarchicalRecommendation a, HierarchicalRecommendation b) {
    // 1. Ordre de priorité (Immédiate avant Court terme avant Moyen terme)
    final priorityComp = a.priorityLevel.index.compareTo(b.priorityLevel.index);
    if (priorityComp != 0) return priorityComp;

    // 2. Fréquence / nombre d'occurrences décroissant
    final countComp = b.occurrenceCount.compareTo(a.occurrenceCount);
    if (countComp != 0) return countComp;

    // 3. Départage stable alphabétique sur le titre
    return a.issueTitle.toLowerCase().compareTo(b.issueTitle.toLowerCase());
  }

  /// Normalisation de la criticité en minuscules
  static String _normalizeCriticality(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('critique')) return 'critique';
    if (lower.contains('majeure') || lower.contains('majeur')) return 'majeure';
    return 'mineure';
  }

  /// Normalisation d'une clé de regroupement pour les constats
  static String _normalizeIssueKey(String rawPoint, String tableName) {
    final point = rawPoint.trim().toLowerCase();
    if (point.isEmpty) return tableName.trim().toLowerCase();
    return CanonicalDefectCategoryRegistry.mapToCanonical(rawPoint);
  }

  /// Titre propre et professionnel pour le constat
  static String _buildCleanIssueTitle(String rawPoint, String tableName) {
    final trimmed = rawPoint.trim();
    if (trimmed.isNotEmpty) {
      // Nettoyer les préfixes éventuels
      var clean = trimmed;
      if (clean.startsWith('•') || clean.startsWith('-')) {
        clean = clean.substring(1).trim();
      }
      return clean;
    }
    return tableName.isNotEmpty ? tableName : 'Point de contrôle non spécifié';
  }

  /// Génère une action corrective précise, technique et reliée aux normes
  static String _generateActionText({
    required String issueTitle,
    required String verificationPoint,
    required String criticality,
    required TensionDomain domain,
    required List<String> sampleObservations,
    required List<String> normativeRefs,
  }) {
    final lower = '$issueTitle $verificationPoint'.toLowerCase();
    final isMt = domain == TensionDomain.mt;
    final normRefStr = normativeRefs.isNotEmpty ? ' (${normativeRefs.first})' : (isMt ? ' (NF C 13-100 / 13-200)' : ' (NF C 15-100)');

    // 1. Obturation / Passages de câbles / Plastrons / IP2X
    if (lower.contains('obturation') || lower.contains('plastron') || lower.contains('ip2x') || lower.contains('enveloppe')) {
      return 'Obturer immédiatement toutes les réservations, passages de câbles et alvéoles ouvertes au moyen d\'obturateurs et plastrons coupe-feu adaptés garantissant le degré de protection IP2X requis$normRefStr.';
    }

    // 2. Prises de terre / Continuité / PE / Liaisons équipotentielles
    if (lower.contains('terre') || lower.contains('équipotentielle') || lower.contains('continuité') || lower.contains('liaison')) {
      return 'Rétablir la continuité des conducteurs de protection (PE) et des liaisons équipotentielles principales et supplémentaires sur l\'ensemble des masses métalliques, avec vérification des seuils de résistance réglementaires$normRefStr.';
    }

    // 3. Protection différentielle / DDR / Isolement
    if (lower.contains('différentiel') || lower.contains('ddr') || lower.contains('isolement') || lower.contains('déclenchement')) {
      return 'Remplacer ou recalibrer les dispositifs différentiels défaillants et corriger les défauts d\'isolement identifiés afin de garantir le déclenchement automatique et instantané en cas de courant de fuite$normRefStr.';
    }

    // 4. Repérage des circuits / Schémas unifilaires / Documentation
    if (lower.contains('repérage') || lower.contains('identification') || lower.contains('étiquetage') || lower.contains('schéma') || lower.contains('unifilaire')) {
      return 'Mettre à jour et apposer les repérages normalisés sur l\'ensemble des départs, appareillages et borniers, et afficher les schémas unifilaires conformes à l\'intérieur des enveloppes$normRefStr.';
    }

    // 5. Câblages / Serrages / Échauffements / Connexions
    if (lower.contains('câble') || lower.contains('serrage') || lower.contains('connexion') || lower.contains('raccordement')) {
      return 'Procéder au resserrage au couple dynamométrique prescrit de toutes les connexions électriques, reprendre les raccordements détériorés et remplacer les conducteurs présentant des traces de surchauffe$normRefStr.';
    }

    // 6. Calibre / Protection contre les surintensités / Pouvoir de coupure
    if (lower.contains('calibre') || lower.contains('disjoncteur') || lower.contains('fusible') || lower.contains('surintensité') || lower.contains('pouvoir de coupure')) {
      return 'Mettre en adéquation les calibres et pouvoirs de coupure des dispositifs de protection amont avec les sections de câbles protégées et les courants de court-circuit présumés$normRefStr.';
    }

    // 7. Parafoudre / Protection contre la foudre
    if (lower.contains('parafoudre') || lower.contains('foudre') || lower.contains('surtension')) {
      return 'Installer ou remplacer les cartouches de parafoudres en tête d\'installation, raccorder leur déconnecteur associé et vérifier la liaison directe au collecteur principal de terre$normRefStr.';
    }

    // 8. Coupure d'urgence / Arrêt d'urgence
    if (lower.contains('coupure d\'urgence') || lower.contains('arrêt d\'urgence') || lower.contains('organe de coupure')) {
      return 'Installer ou remettre en état fonctionnel les organes de coupure d\'urgence identifiés, en assurant leur accessibilité permanente et leur action directe sur les sources d\'alimentation$normRefStr.';
    }

    // 9. Équipements de protection individuelle (EPI) / Outillage
    if (lower.contains('epi') || lower.contains('gant') || lower.contains('tabouret') || lower.contains('visière') || lower.contains('tapis')) {
      return 'Approvisionner et mettre à disposition immédiate dans les locaux techniques les équipements de protection individuelle (EPI) et collectifs conformes, contrôlés et en cours de validité (gants isolants, écran facial, tabouret/tapis isolant, perche de sauvetage)$normRefStr.';
    }

    // 10. Cellules MT / Transformateurs / Verrouillage
    if (isMt && (lower.contains('cellule') || lower.contains('transfo') || lower.contains('verrouillage') || lower.contains('poste'))) {
      return 'Effectuer la révision complète des cellules HTA et transformateurs : contrôle des asservissements et verrouillages mécaniques, vérification des diélectriques et dépoussiérage approfondi$normRefStr.';
    }

    // 11. Éclairage de sécurité / Blocs autonomes (BAES)
    if (lower.contains('éclairage') || lower.contains('baes') || lower.contains('secours')) {
      return 'Remettre en service les blocs autonomes d\'éclairage de sécurité (BAES) défectueux et tester leur autonomie réglementaire d\'une heure$normRefStr.';
    }

    // 12. Ventilation / Température / Encombrement des locaux
    if (lower.contains('ventilation') || lower.contains('encombrement') || lower.contains('dégagement') || lower.contains('température')) {
      return 'Dégager intégralement les allées de circulation et accès aux armoires électriques, et rétablir une ventilation efficace des locaux pour éviter toute montée anormale en température$normRefStr.';
    }

    // Formule technique contextuelle par défaut (dérivée du point et de la criticité)
    if (criticality == 'critique') {
      return 'Consigner sans délai le circuit concerné et procéder aux travaux de mise en conformité immédiate sur le point « $verificationPoint »$normRefStr.';
    } else if (criticality == 'majeure') {
      return 'Planifier à court terme la remise en conformité technique de l\'installation sur le point « $verificationPoint » selon les prescriptions normatives applicables$normRefStr.';
    } else {
      return 'Intégrer la régularisation du point « $verificationPoint » dans le programme de maintenance préventive courante$normRefStr.';
    }
  }

  /// Synthétise des puces d'actions pour une criticité donnée en regroupant les constats par famille technique.
  /// RÈGLE ABSOLUE : ZÉRO invention ! Seuls les écarts réels sont transformés en puces.
  static List<String> _synthesizeAggregatedBullets(
    List<HierarchicalRecommendation> recos,
    TensionDomain domain,
    String criticality,
  ) {
    if (recos.isEmpty) return const [];

    // Regroupement par famille technique
    final familyGroups = <String, List<HierarchicalRecommendation>>{};
    for (final r in recos) {
      final family = _detectTechnicalFamily(r);
      familyGroups.putIfAbsent(family, () => []).add(r);
    }

    final bullets = <String>[];

    for (final entry in familyGroups.entries) {
      final group = entry.value;
      if (group.isEmpty) continue;

      // Rassembler les équipements et normes concernés
      final equipmentsSet = <String>{};
      final normSet = <String>{};
      for (final r in group) {
        equipmentsSet.addAll(r.impactedEquipments);
        normSet.addAll(r.normativeReferences);
      }

      final normSuffix = normSet.isNotEmpty
          ? ' (${normSet.first})'
          : (domain == TensionDomain.mt ? ' (NF C 13-100 / 13-200)' : ' (NF C 15-100)');

      final String actionText;
      if (group.length == 1) {
        // Une seule recommandation dans la famille
        actionText = group.first.recommendedAction;
      } else {
        // Plusieurs recommandations dans la même famille : formulation synthétique unifiée
        actionText = _synthesizeClusterAction(
          familyKey: entry.key,
          domain: domain,
          criticality: criticality,
          sampleActions: group.map((r) => r.recommendedAction).toList(),
          sampleTitles: group.map((r) => r.issueTitle).toList(),
          normSuffix: normSuffix,
        );
      }

      // Contexte des équipements si disponible et pertinent
      String finalBullet = actionText;
      if (equipmentsSet.isNotEmpty) {
        final equipSummary = equipmentsSet.length <= 3
            ? equipmentsSet.join(', ')
            : '${equipmentsSet.take(3).join(', ')} (+${equipmentsSet.length - 3} autres)';
        // Vérifier si l'équipement n'est pas déjà mentionné dans le texte
        if (!actionText.toLowerCase().contains(equipmentsSet.first.toLowerCase())) {
          finalBullet = '$actionText [Concerne : $equipSummary]';
        }
      }

      bullets.add(finalBullet);
    }

    return bullets;
  }

  /// Détecte la famille technique d'une recommandation pour regroupement intelligent
  static String _detectTechnicalFamily(HierarchicalRecommendation reco) {
    final text = '${reco.issueTitle} ${reco.recommendedAction}'.toLowerCase();
    if (text.contains('obturation') || text.contains('plastron') || text.contains('ip2x') || text.contains('contact direct') || text.contains('enveloppe')) {
      return 'ip2x_contacts_directs';
    }
    if (text.contains('terre') || text.contains('équipotentielle') || text.contains('continuité') || text.contains('conducteur de protection') || text.contains(' pe')) {
      return 'pe_terre_equipotentialite';
    }
    if (text.contains('différentiel') || text.contains('ddr') || text.contains('isolement') || text.contains('déclenchement')) {
      return 'ddr_isolement';
    }
    if (text.contains('repérage') || text.contains('identification') || text.contains('étiquetage') || text.contains('schéma') || text.contains('unifilaire')) {
      return 'reperage_schema_documentation';
    }
    if (text.contains('serrage') || text.contains('échauffement') || text.contains('connexion') || text.contains('raccordement') || text.contains('câble')) {
      return 'connexions_serrage_cables';
    }
    if (text.contains('calibre') || text.contains('disjoncteur') || text.contains('fusible') || text.contains('surintensité') || text.contains('pouvoir de coupure')) {
      return 'protections_calibres';
    }
    if (text.contains('parafoudre') || text.contains('foudre') || text.contains('surtension')) {
      return 'parafoudres_foudre';
    }
    if (text.contains('coupure d\'urgence') || text.contains('arrêt d\'urgence') || text.contains('organe de coupure')) {
      return 'coupure_urgence';
    }
    if (text.contains('epi') || text.contains('gant') || text.contains('tabouret') || text.contains('visière') || text.contains('perche')) {
      return 'epi_securite';
    }
    if (text.contains('cellule') || text.contains('transfo') || text.contains('verrouillage') || text.contains('poste')) {
      return 'cellules_transfos_verrouillage';
    }
    if (text.contains('éclairage') || text.contains('baes') || text.contains('secours')) {
      return 'eclairage_securite';
    }
    if (text.contains('ventilation') || text.contains('encombrement') || text.contains('dégagement') || text.contains('température')) {
      return 'locaux_ventilation';
    }
    return reco.id;
  }

  /// Synthétise une action unifiée pour un groupe de recommandations de même famille
  static String _synthesizeClusterAction({
    required String familyKey,
    required TensionDomain domain,
    required String criticality,
    required List<String> sampleActions,
    required List<String> sampleTitles,
    required String normSuffix,
  }) {
    switch (familyKey) {
      case 'ip2x_contacts_directs':
        return 'Obturer l\'ensemble des réservations, passages de câbles et alvéoles ouvertes au moyen d\'obturateurs coupe-feu et plastrons conformes pour garantir l\'indice IP2X et prévenir tout risque de contact direct$normSuffix.';
      case 'pe_terre_equipotentialite':
        return 'Rétablir la continuité des conducteurs de protection (PE) et des liaisons équipotentielles sur l\'ensemble des masses métalliques avec vérification des seuils de résistance réglementaires$normSuffix.';
      case 'ddr_isolement':
        return 'Remplacer ou recalibrer les dispositifs différentiels (DDR) défaillants et remédier aux défauts d\'isolement identifiés pour assurer le déclenchement automatique instantané$normSuffix.';
      case 'reperage_schema_documentation':
        return 'Généraliser le repérage normalisé sur l\'ensemble des départs, appareillages et borniers, et afficher les schémas unifilaires conformes à l\'intérieur des enveloppes$normSuffix.';
      case 'connexions_serrage_cables':
        return 'Procéder au contrôle du couple de serrage dynamométrique de toutes les connexions électriques, reprendre les raccordements et remplacer les conducteurs présentant des traces d\'échauffement$normSuffix.';
      case 'protections_calibres':
        return 'Mettre en conformité les calibres et pouvoirs de coupure des dispositifs de protection amont avec les sections de câbles protégées et les contraintes thermiques présumées$normSuffix.';
      case 'parafoudres_foudre':
        return 'Installer ou remplacer les cartouches de parafoudres en tête d\'installation avec leurs déconnecteurs associés et vérifier leur raccordement au collecteur principal de terre$normSuffix.';
      case 'coupure_urgence':
        return 'Installer ou remettre en état fonctionnel les organes de coupure d\'urgence identifiés, en assurant leur accessibilité immédiate et leur action directe sur l\'alimentation$normSuffix.';
      case 'epi_securite':
        return 'Approvisionner et mettre à disposition immédiate dans les locaux techniques les équipements de protection individuelle et collectifs réglementaires vérifiés et valides$normSuffix.';
      case 'cellules_transfos_verrouillage':
        return 'Effectuer la révision complète des cellules HTA et transformateurs : asservissements, verrouillages mécaniques, contrôle diélectrique et dépoussiérage approfondi$normSuffix.';
      case 'eclairage_securite':
        return 'Remettre en service les blocs autonomes d\'éclairage de sécurité (BAES) défectueux et tester leur autonomie réglementaire d\'une heure$normSuffix.';
      case 'locaux_ventilation':
        return 'Dégager intégralement les allées de circulation et accès aux armoires, et rétablir une ventilation efficace des locaux pour prévenir tout échauffement anormal$normSuffix.';
      default:
        if (sampleActions.isNotEmpty) return sampleActions.first;
        return 'Mettre en conformité l\'ensemble des écarts constatés selon les prescriptions normatives applicables$normSuffix.';
    }
  }
}
