import 'dart:convert';

/// Modèle de données structurées de l'analyse du « RÉSUMÉ EXÉCUTIF » (7 sous-sections).
///
/// Ce modèle contient la synthèse officielle structurée (IA ou Fallback déterministe)
/// consommée directement par le moteur de génération PDF `PdfReportService`.

class CriticalityRowData {
  final String criticite;
  final int nombre;
  final String partPct;
  final String densiteStr;

  CriticalityRowData({
    required this.criticite,
    required this.nombre,
    required this.partPct,
    required this.densiteStr,
  });

  Map<String, dynamic> toJson() => {
        'criticite': criticite,
        'nombre': nombre,
        'partPct': partPct,
        'densiteStr': densiteStr,
      };

  factory CriticalityRowData.fromJson(Map<String, dynamic> json) => CriticalityRowData(
        criticite: json['criticite'] as String? ?? '',
        nombre: (json['nombre'] as num?)?.toInt() ?? 0,
        partPct: json['partPct'] as String? ?? '0,0 %',
        densiteStr: json['densiteStr'] as String? ?? '-',
      );
}

class RiskFactorRowData {
  final String natureRisque;
  final String constats;
  final String partPct;
  final String observation;

  RiskFactorRowData({
    required this.natureRisque,
    required this.constats,
    required this.partPct,
    required this.observation,
  });

  Map<String, dynamic> toJson() => {
        'natureRisque': natureRisque,
        'constats': constats,
        'partPct': partPct,
        'observation': observation,
      };

  factory RiskFactorRowData.fromJson(Map<String, dynamic> json) => RiskFactorRowData(
        natureRisque: json['natureRisque'] as String? ?? '',
        constats: json['constats']?.toString() ?? '0',
        partPct: json['partPct'] as String? ?? '0,0 %',
        observation: json['observation'] as String? ?? '',
      );
}

class SectionContexte {
  final String paragraph;
  SectionContexte({required this.paragraph});
  Map<String, dynamic> toJson() => {'paragraph': paragraph};
  factory SectionContexte.fromJson(Map<String, dynamic> json) =>
      SectionContexte(paragraph: json['paragraph'] as String? ?? '');
}

class SectionSyntheseResultats {
  final String introParagraph;
  final List<CriticalityRowData> tableRows;
  final CriticalityRowData tableTotalRow;
  final String commentaryParagraph;

  SectionSyntheseResultats({
    required this.introParagraph,
    required this.tableRows,
    required this.tableTotalRow,
    required this.commentaryParagraph,
  });

  Map<String, dynamic> toJson() => {
        'introParagraph': introParagraph,
        'tableRows': tableRows.map((e) => e.toJson()).toList(),
        'tableTotalRow': tableTotalRow.toJson(),
        'commentaryParagraph': commentaryParagraph,
      };

  factory SectionSyntheseResultats.fromJson(Map<String, dynamic> json) =>
      SectionSyntheseResultats(
        introParagraph: json['introParagraph'] as String? ?? '',
        tableRows: (json['tableRows'] as List<dynamic>?)
                ?.map((e) => CriticalityRowData.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        tableTotalRow: json['tableTotalRow'] != null
            ? CriticalityRowData.fromJson(Map<String, dynamic>.from(json['tableTotalRow'] as Map))
            : CriticalityRowData(criticite: 'TOTAL', nombre: 0, partPct: '100 %', densiteStr: '-'),
        commentaryParagraph: json['commentaryParagraph'] as String? ?? '',
      );
}

class SectionConcentrationRisque {
  final String title;
  final String primaryConcentrationParagraph;
  final String highestDensityParagraph;

  SectionConcentrationRisque({
    required this.title,
    required this.primaryConcentrationParagraph,
    required this.highestDensityParagraph,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'primaryConcentrationParagraph': primaryConcentrationParagraph,
        'highestDensityParagraph': highestDensityParagraph,
      };

  factory SectionConcentrationRisque.fromJson(Map<String, dynamic> json) =>
      SectionConcentrationRisque(
        title: json['title'] as String? ?? 'Concentration du risque : analyse par catégorie',
        primaryConcentrationParagraph: json['primaryConcentrationParagraph'] as String? ?? '',
        highestDensityParagraph: json['highestDensityParagraph'] as String? ?? '',
      );
}

class SectionFacteursRisque {
  final String introParagraph;
  final List<RiskFactorRowData> tableRows;
  final String commentaryParagraph;

  SectionFacteursRisque({
    required this.introParagraph,
    required this.tableRows,
    required this.commentaryParagraph,
  });

  Map<String, dynamic> toJson() => {
        'introParagraph': introParagraph,
        'tableRows': tableRows.map((e) => e.toJson()).toList(),
        'commentaryParagraph': commentaryParagraph,
      };

  factory SectionFacteursRisque.fromJson(Map<String, dynamic> json) =>
      SectionFacteursRisque(
        introParagraph: json['introParagraph'] as String? ?? '',
        tableRows: (json['tableRows'] as List<dynamic>?)
                ?.map((e) => RiskFactorRowData.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
        commentaryParagraph: json['commentaryParagraph'] as String? ?? '',
      );
}

class SectionObservationsMajores {
  final List<String> bulletPoints;
  final String summaryParagraph;

  SectionObservationsMajores({
    required this.bulletPoints,
    required this.summaryParagraph,
  });

  Map<String, dynamic> toJson() => {
        'bulletPoints': bulletPoints,
        'summaryParagraph': summaryParagraph,
      };

  factory SectionObservationsMajores.fromJson(Map<String, dynamic> json) =>
      SectionObservationsMajores(
        bulletPoints: (json['bulletPoints'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        summaryParagraph: json['summaryParagraph'] as String? ?? '',
      );
}

class SectionRecommandationsPrioritaires {
  final String introParagraph;
  final String priority1Immediate;
  final String priority2ShortTerm;
  final String priority3MediumTerm;

  SectionRecommandationsPrioritaires({
    required this.introParagraph,
    required this.priority1Immediate,
    required this.priority2ShortTerm,
    required this.priority3MediumTerm,
  });

  Map<String, dynamic> toJson() => {
        'introParagraph': introParagraph,
        'priority1Immediate': priority1Immediate,
        'priority2ShortTerm': priority2ShortTerm,
        'priority3MediumTerm': priority3MediumTerm,
      };

  factory SectionRecommandationsPrioritaires.fromJson(Map<String, dynamic> json) =>
      SectionRecommandationsPrioritaires(
        introParagraph: json['introParagraph'] as String? ?? '',
        priority1Immediate: json['priority1Immediate'] as String? ?? '',
        priority2ShortTerm: json['priority2ShortTerm'] as String? ?? '',
        priority3MediumTerm: json['priority3MediumTerm'] as String? ?? '',
      );
}

class SectionAppreciationGlobale {
  final String assessmentParagraph1;
  final String assessmentParagraph2;
  final String assessmentParagraph3;
  final String actionPlanHeader;
  final List<String> actionPlanSteps;
  final String counterVisitParagraph;

  SectionAppreciationGlobale({
    required this.assessmentParagraph1,
    required this.assessmentParagraph2,
    required this.assessmentParagraph3,
    required this.actionPlanHeader,
    required this.actionPlanSteps,
    required this.counterVisitParagraph,
  });

  Map<String, dynamic> toJson() => {
        'assessmentParagraph1': assessmentParagraph1,
        'assessmentParagraph2': assessmentParagraph2,
        'assessmentParagraph3': assessmentParagraph3,
        'actionPlanHeader': actionPlanHeader,
        'actionPlanSteps': actionPlanSteps,
        'counterVisitParagraph': counterVisitParagraph,
      };

  factory SectionAppreciationGlobale.fromJson(Map<String, dynamic> json) =>
      SectionAppreciationGlobale(
        assessmentParagraph1: json['assessmentParagraph1'] as String? ?? '',
        assessmentParagraph2: json['assessmentParagraph2'] as String? ?? '',
        assessmentParagraph3: json['assessmentParagraph3'] as String? ?? '',
        actionPlanHeader: json['actionPlanHeader'] as String? ??
            'Au regard de ces constats, il est recommandé de mettre en œuvre sans délai un plan d\'actions correctives structuré :',
        actionPlanSteps: (json['actionPlanSteps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        counterVisitParagraph: json['counterVisitParagraph'] as String? ?? '',
      );
}

class ExecutiveSummaryData {
  final SectionContexte contexte;
  final SectionSyntheseResultats syntheseResultats;
  final SectionConcentrationRisque concentrationRisque;
  final SectionFacteursRisque facteursRisque;
  final SectionObservationsMajores observationsMajores;
  final SectionRecommandationsPrioritaires recommandationsPrioritaires;
  final SectionAppreciationGlobale appreciationGlobale;

  final bool isFallback;
  final DateTime generatedAt;

  ExecutiveSummaryData({
    required this.contexte,
    required this.syntheseResultats,
    required this.concentrationRisque,
    required this.facteursRisque,
    required this.observationsMajores,
    required this.recommandationsPrioritaires,
    required this.appreciationGlobale,
    this.isFallback = false,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  // ── RÉTROCOMPATIBILITÉ AVEC L'ANCIEN FORMAT ──
  String get overview => contexte.paragraph;
  List<String> get keyFindings => observationsMajores.bulletPoints;
  String get criticalRisksSummary => syntheseResultats.commentaryParagraph;
  List<String> get recommendations => [
        recommandationsPrioritaires.priority1Immediate,
        recommandationsPrioritaires.priority2ShortTerm,
        recommandationsPrioritaires.priority3MediumTerm,
      ].where((s) => s.isNotEmpty).toList();
  String get conclusion => appreciationGlobale.assessmentParagraph1;

  Map<String, dynamic> toJson() {
    return {
      'contexte': contexte.toJson(),
      'syntheseResultats': syntheseResultats.toJson(),
      'concentrationRisque': concentrationRisque.toJson(),
      'facteursRisque': facteursRisque.toJson(),
      'observationsMajores': observationsMajores.toJson(),
      'recommandationsPrioritaires': recommandationsPrioritaires.toJson(),
      'appreciationGlobale': appreciationGlobale.toJson(),
      'isFallback': isFallback,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory ExecutiveSummaryData.fromJson(Map<String, dynamic> json) {
    // Si le JSON provient de l'ancien format simple (5 champs texte)
    if (!json.containsKey('contexte') && json.containsKey('overview')) {
      final oldOverview = json['overview'] as String? ?? '';
      final oldFindings = (json['keyFindings'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final oldRisks = json['criticalRisksSummary'] as String? ?? '';
      final oldRecs = (json['recommendations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final oldConclusion = json['conclusion'] as String? ?? '';

      return ExecutiveSummaryData(
        contexte: SectionContexte(paragraph: oldOverview),
        syntheseResultats: SectionSyntheseResultats(
          introParagraph: 'Analyse synthétique des résultats de vérification.',
          tableRows: [],
          tableTotalRow: CriticalityRowData(criticite: 'TOTAL', nombre: 0, partPct: '100 %', densiteStr: '-'),
          commentaryParagraph: oldRisks,
        ),
        concentrationRisque: SectionConcentrationRisque(
          title: 'Concentration du risque',
          primaryConcentrationParagraph: '',
          highestDensityParagraph: '',
        ),
        facteursRisque: SectionFacteursRisque(
          introParagraph: '',
          tableRows: [],
          commentaryParagraph: '',
        ),
        observationsMajores: SectionObservationsMajores(
          bulletPoints: oldFindings,
          summaryParagraph: '',
        ),
        recommandationsPrioritaires: SectionRecommandationsPrioritaires(
          introParagraph: 'Les actions correctives recommandées sont les suivantes :',
          priority1Immediate: oldRecs.isNotEmpty ? oldRecs[0] : '',
          priority2ShortTerm: oldRecs.length > 1 ? oldRecs[1] : '',
          priority3MediumTerm: oldRecs.length > 2 ? oldRecs[2] : '',
        ),
        appreciationGlobale: SectionAppreciationGlobale(
          assessmentParagraph1: oldConclusion,
          assessmentParagraph2: '',
          assessmentParagraph3: '',
          actionPlanHeader: 'Plan d\'actions recommandées :',
          actionPlanSteps: oldRecs,
          counterVisitParagraph: '',
        ),
        isFallback: json['isFallback'] as bool? ?? false,
        generatedAt: json['generatedAt'] != null
            ? DateTime.tryParse(json['generatedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    }

    return ExecutiveSummaryData(
      contexte: SectionContexte.fromJson(Map<String, dynamic>.from(json['contexte'] as Map? ?? {})),
      syntheseResultats: SectionSyntheseResultats.fromJson(Map<String, dynamic>.from(json['syntheseResultats'] as Map? ?? {})),
      concentrationRisque: SectionConcentrationRisque.fromJson(Map<String, dynamic>.from(json['concentrationRisque'] as Map? ?? {})),
      facteursRisque: SectionFacteursRisque.fromJson(Map<String, dynamic>.from(json['facteursRisque'] as Map? ?? {})),
      observationsMajores: SectionObservationsMajores.fromJson(Map<String, dynamic>.from(json['observationsMajores'] as Map? ?? {})),
      recommandationsPrioritaires: SectionRecommandationsPrioritaires.fromJson(Map<String, dynamic>.from(json['recommandationsPrioritaires'] as Map? ?? {})),
      appreciationGlobale: SectionAppreciationGlobale.fromJson(Map<String, dynamic>.from(json['appreciationGlobale'] as Map? ?? {})),
      isFallback: json['isFallback'] as bool? ?? false,
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String encodeJson() => jsonEncode(toJson());

  factory ExecutiveSummaryData.decodeJson(String source) {
    return ExecutiveSummaryData.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }
}
