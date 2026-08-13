import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/services/ai/ai_provider.dart';
import 'package:inspec_app/services/ai/executive_summary_data.dart';
import 'package:inspec_app/services/ai/executive_summary_snapshot.dart';
import 'package:inspec_app/services/ai/mission_executive_summary_service.dart';

class MockFailingAiProvider implements AiProvider {
  @override
  String get providerName => 'mock_failing';

  @override
  String get modelName => 'mock-model';

  @override
  Future<String> generateStructuredText({
    required String prompt,
    required Map<String, dynamic> responseSchema,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    throw SocketException('Réseau indisponible (Test Mock)');
  }
}

class MockSuccessfulAiProvider implements AiProvider {
  @override
  String get providerName => 'mock_success';

  @override
  String get modelName => 'mock-model';

  @override
  Future<String> generateStructuredText({
    required String prompt,
    required Map<String, dynamic> responseSchema,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return '''
{
  "contexte": {
    "paragraph": "Synthèse IA générée avec succès pour le test du contexte 1.1."
  },
  "syntheseResultats": {
    "introParagraph": "Introduction chiffrée de la synthèse 1.2.",
    "tableRows": [
      {"criticite": "Critique", "nombre": 2, "partPct": "20,0 %", "densiteStr": "0,20"},
      {"criticite": "Majeure", "nombre": 5, "partPct": "50,0 %", "densiteStr": "0,50"},
      {"criticite": "Mineure", "nombre": 3, "partPct": "30,0 %", "densiteStr": "0,30"}
    ],
    "tableTotalRow": {"criticite": "TOTAL", "nombre": 10, "partPct": "100 %", "densiteStr": "1,00"},
    "commentaryParagraph": "Commentaire d'analyse de la synthèse des résultats."
  },
  "concentrationRisque": {
    "title": "1.3 Concentration du risque : les armoires concentrent l'essentiel des écarts",
    "primaryConcentrationParagraph": "Paragraphe de concentration sur les armoires.",
    "highestDensityParagraph": "Paragraphe sur la densité unitaire des locaux MT."
  },
  "facteursRisque": {
    "introParagraph": "Introduction aux facteurs de risques.",
    "tableRows": [
      {"natureRisque": "Erreur de maintenance", "constats": "6", "partPct": "60,0 %", "observation": "Sensible"}
    ],
    "commentaryParagraph": "Commentaire sur les facteurs de risques."
  },
  "observationsMajores": {
    "bulletPoints": ["Point d'observation 1", "Point d'observation 2"],
    "summaryParagraph": "Part cumulée concentrée."
  },
  "recommandationsPrioritaires": {
    "introParagraph": "Introduction des recommandations.",
    "priority1Immediate": "Priorité 1 : Action immédiate sur non-conformités critiques.",
    "priority2ShortTerm": "Priorité 2 : Action court terme sur protections.",
    "priority3MediumTerm": "Priorité 3 : Action moyen terme sur repérage."
  },
  "appreciationGlobale": {
    "assessmentParagraph1": "Constat global sur le niveau de maîtrise du risque.",
    "assessmentParagraph2": "Synthèse du nombre de NCs.",
    "assessmentParagraph3": "Synthèse des équipements sensibles.",
    "actionPlanHeader": "Plan d'actions recommandées :",
    "actionPlanSteps": [
      "1. Action 1",
      "2. Action 2",
      "3. Action 3",
      "4. Action 4",
      "5. Action 5",
      "6. Action 6"
    ],
    "counterVisitParagraph": "Une contre-visite devra être programmée."
  }
}
''';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test_ai_');
    Hive.init(tempDir.path);
    await Hive.openBox('executive_summary_cache');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  group('ExecutiveSummarySnapshot Tests', () {
    test('Calcul déterministe du hash SHA-256', () {
      final snapshot = ExecutiveSummarySnapshot(
        missionId: 'm_test_1',
        clientName: 'CAMRAIL',
        siteName: 'Gare Centrale',
        natureMission: 'Inspection Périodique',
        dateRangeText: 'du 01/01/2026 au 05/01/2026',
        domainTension: 'Basse Tension (BT)',
        companyName: 'KES INSPECTIONS AND PROJECTS',
        reportNumber: 'KES/IP/VE/2026/001',
        reportDateStr: '10/08/2026',
        officialStats: {
          'totalNC': 10,
          'critique': 2,
          'majeure': 5,
          'mineure': 3,
        },
        categoryStats: [
          {'categoryName': 'Armoires', 'equipmentCount': 5, 'ncCount': 8, 'densityStr': '1.60', 'pctOfTotalEquipment': '50.0', 'pctOfTotalNc': '80.0'}
        ],
        topDefects: [
          {'title': 'Prise de terre', 'count': 4, 'percentage': '40,0'}
        ],
        riskFamilies: [
          {'name': 'Choc électrique', 'count': 6, 'percentage': '60,0'}
        ],
        equipmentCount: 12,
        installationsCount: 3,
        globalDensityStr: '0,83',
      );

      final hash1 = snapshot.computeHash();
      final hash2 = snapshot.computeHash();

      expect(hash1, isNotEmpty);
      expect(hash1, equals(hash2));
    });
  });

  group('ExecutiveSummaryData Tests', () {
    test('Sérialisation et Décodage JSON (7 sous-sections)', () {
      final data = ExecutiveSummaryData(
        contexte: SectionContexte(paragraph: 'Contexte test'),
        syntheseResultats: SectionSyntheseResultats(
          introParagraph: 'Intro synthé test',
          tableRows: [CriticalityRowData(criticite: 'Critique', nombre: 1, partPct: '100 %', densiteStr: '1.0')],
          tableTotalRow: CriticalityRowData(criticite: 'TOTAL', nombre: 1, partPct: '100 %', densiteStr: '1.0'),
          commentaryParagraph: 'Commentaire test',
        ),
        concentrationRisque: SectionConcentrationRisque(
          title: 'Concentration du risque',
          primaryConcentrationParagraph: 'Conc 1',
          highestDensityParagraph: 'Conc 2',
        ),
        facteursRisque: SectionFacteursRisque(
          introParagraph: 'Intro FR',
          tableRows: [RiskFactorRowData(natureRisque: 'Risque A', constats: '2', partPct: '50 %', observation: 'Obs A')],
          commentaryParagraph: 'Comm FR',
        ),
        observationsMajores: SectionObservationsMajores(
          bulletPoints: ['Point 1'],
          summaryParagraph: 'Summary obs',
        ),
        recommandationsPrioritaires: SectionRecommandationsPrioritaires(
          introParagraph: 'Intro recs',
          priority1Immediate: 'P1',
          priority2ShortTerm: 'P2',
          priority3MediumTerm: 'P3',
        ),
        appreciationGlobale: SectionAppreciationGlobale(
          assessmentParagraph1: 'App 1',
          assessmentParagraph2: 'App 2',
          assessmentParagraph3: 'App 3',
          actionPlanHeader: 'Plan :',
          actionPlanSteps: ['1. Etape 1'],
          counterVisitParagraph: 'Contre-visite',
        ),
        isFallback: false,
      );

      final jsonStr = data.encodeJson();
      final decoded = ExecutiveSummaryData.decodeJson(jsonStr);

      expect(decoded.contexte.paragraph, equals('Contexte test'));
      expect(decoded.syntheseResultats.tableRows.length, equals(1));
      expect(decoded.observationsMajores.bulletPoints, contains('Point 1'));
      expect(decoded.isFallback, isFalse);
    });
  });

  group('MissionExecutiveSummaryService - Moteur IA + Hash + Offline', () {
    test('Génération IA réussie et mise en cache avec hash', () async {
      final summary = await MissionExecutiveSummaryService.getOrGenerateSummary(
        'm_test_suite_1',
        customProvider: MockSuccessfulAiProvider(),
      );

      expect(summary.contexte.paragraph, contains('Synthèse IA générée avec succès'));
      expect(summary.isFallback, isFalse);
    });

    test('Mission inchangée (même hash) + API hors-ligne : restitution immédiate du cache', () async {
      final summary = await MissionExecutiveSummaryService.getOrGenerateSummary(
        'm_test_suite_1',
        customProvider: MockFailingAiProvider(),
      );

      expect(summary.contexte.paragraph, contains('Synthèse IA générée avec succès'));
      expect(summary.isFallback, isFalse);
    });

    test('Mission sans cache + API hors-ligne : génération déterministe hors-ligne', () async {
      final summary = await MissionExecutiveSummaryService.getOrGenerateSummary(
        'm_test_suite_2_no_cache',
        customProvider: MockFailingAiProvider(),
      );

      expect(summary.isFallback, isTrue);
      expect(summary.contexte.paragraph, contains('La vérification périodique réglementaire'));
    });
  });
}
