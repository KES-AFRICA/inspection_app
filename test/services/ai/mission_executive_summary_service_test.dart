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
  "overview": "Synthèse IA générée avec succès pour le test.",
  "keyFindings": ["Point fort 1", "Point fort 2"],
  "criticalRisksSummary": "Synthèse des risques critiques générée par l'IA.",
  "recommendations": ["Action 1", "Action 2"],
  "conclusion": "Conclusion IA de la mission."
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
        officialStats: {
          'totalNC': 10,
          'critique': 2,
          'majeure': 5,
          'mineure': 3,
        },
        topDefects: [
          {'label': 'Prise de terre', 'count': 4}
        ],
        riskFamilies: [
          {'family': 'Choc électrique', 'count': 6}
        ],
        equipmentCount: 12,
        installationsCount: 3,
      );

      final hash1 = snapshot.computeHash();
      final hash2 = snapshot.computeHash();

      expect(hash1, isNotEmpty);
      expect(hash1, equals(hash2));
    });
  });

  group('ExecutiveSummaryData Tests', () {
    test('Sérialisation et Décodage JSON', () {
      final data = ExecutiveSummaryData(
        overview: 'Overview test',
        keyFindings: ['Observation 1'],
        criticalRisksSummary: 'Risks test',
        recommendations: ['Recommandation 1'],
        conclusion: 'Conclusion test',
        isFallback: false,
      );

      final jsonStr = data.encodeJson();
      final decoded = ExecutiveSummaryData.decodeJson(jsonStr);

      expect(decoded.overview, equals('Overview test'));
      expect(decoded.keyFindings, contains('Observation 1'));
      expect(decoded.isFallback, isFalse);
    });
  });

  group('MissionExecutiveSummaryService - Fallback 3 Niveaux', () {
    test('Niveau 1 : Génération IA réussie et mise en cache', () async {
      final summary = await MissionExecutiveSummaryService.getOrGenerateSummary(
        'm_test_suite_1',
        customProvider: MockSuccessfulAiProvider(),
      );

      expect(summary.overview, contains('Synthèse IA générée avec succès'));
      expect(summary.isFallback, isFalse);
    });

    test('Niveau 2 : Si appel API échoue, réutiliser le dernier résumé en cache', () async {
      final summary = await MissionExecutiveSummaryService.getOrGenerateSummary(
        'm_test_suite_1',
        customProvider: MockFailingAiProvider(),
      );

      // Doit réutiliser le résumé IA généré dans le test précédent (Hit Cache Niveau 2)
      expect(summary.overview, contains('Synthèse IA générée avec succès'));
      expect(summary.isFallback, isFalse);
    });

    test('Niveau 3 : Si API échoue et aucun cache n\'existe, basculer sur le fallback déterministe', () async {
      final summary = await MissionExecutiveSummaryService.getOrGenerateSummary(
        'm_test_suite_2_no_cache',
        customProvider: MockFailingAiProvider(),
      );

      expect(summary.isFallback, isTrue);
      expect(summary.overview, contains('Dans le cadre de'));
    });
  });
}
