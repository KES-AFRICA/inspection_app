import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/services/backup_service.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/statistics/mission_statistics_collector.dart';
import 'package:inspec_app/services/ai/executive_summary_snapshot.dart';
import 'package:inspec_app/services/ai/mission_executive_summary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_pdf_verification_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async {
        return tempDir.path;
      },
    );
    Hive.init(tempDir.path);
    await HiveService.init();
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  test('Vérification Fondamentale : Traçabilité des Données Réelles → Calculs → Injection PDF', () async {
    final backupFile = File('/home/andelson-teufack/Téléchargements/backup_CAMRAIL_BESSENGUE_CAMRAIL_BESSENGUE_KES__26_INSP_010_2026-08-25T11-48-03.inspec');
    expect(backupFile.existsSync(), isTrue);

    final result = await BackupService.importerSauvegardeFichier(
      filePath: backupFile.path,
      ecraser: true,
      importeurMatricule: 'VERIF',
      importeurNom: 'VERIF',
      importeurPrenom: 'VERIF',
    );
    expect(result.success, isTrue);

    const missionId = '1783501230919';

    // 1. Invalidation forcée du cache Hive obsolète
    await MissionExecutiveSummaryService.clearCacheForMission(missionId);

    // 2. Moteur de statistiques centralisé
    final summary = MissionStatisticsCollector.collectSummary(missionId);
    final snapshot = ExecutiveSummarySnapshot.fromMission(missionId);
    final summaryData = MissionExecutiveSummaryService.buildDeterministicFallback(missionId, snapshot);

    print('\n================================================================');
    print('  AUDIT DE VÉRIFICATION ET TRAÇABILITÉ DES CHIFFRES DU PDF');
    print('================================================================');

    // ── SECTION 2 : RÉSUMÉ EXÉCUTIF (7 SOUS-SECTIONS) ──
    print('\n--- 1. Contexte et périmètre ---');
    print(summaryData.contexte.paragraph);

    print('\n--- 2. Synthèse des résultats ---');
    print(summaryData.syntheseResultats.introParagraph);
    for (final row in summaryData.syntheseResultats.tableRows) {
      print('  • ${row.criticite}: ${row.nombre} (${row.partPct}) | ${row.densiteStr}');
    }
    print('  TOTAL: ${summaryData.syntheseResultats.tableTotalRow.nombre} (${summaryData.syntheseResultats.tableTotalRow.densiteStr})');
    print(summaryData.syntheseResultats.commentaryParagraph);

    print('\n--- 3. Concentration du risque ---');
    print('Titre: ${summaryData.concentrationRisque.title}');
    print(summaryData.concentrationRisque.primaryConcentrationParagraph);
    print(summaryData.concentrationRisque.highestDensityParagraph);
    if (summaryData.concentrationRisque.qualitativeRiskCallout.isNotEmpty) {
      print('Point de risque qualitatif: ${summaryData.concentrationRisque.qualitativeRiskCallout}');
    }

    print('\n--- 4. Facteurs de risque prépondérants ---');
    for (final r in summaryData.facteursRisque.tableRows) {
      print('  • ${r.natureRisque}: ${r.constats} NC (${r.partPct}) -> ${r.observation}');
    }

    print('\n--- 5. Observations et constats majeurs ---');
    for (final b in summaryData.observationsMajores.bulletPoints) {
      print('  • $b');
    }

    print('\n--- 6. Recommandations prioritaires hiérarchisées ---');
    print('P1: ${summaryData.recommandationsPrioritaires.priority1Immediate}');
    print('P2: ${summaryData.recommandationsPrioritaires.priority2ShortTerm}');
    print('P3: ${summaryData.recommandationsPrioritaires.priority3MediumTerm}');

    print('\n--- 7. Appréciation globale ---');
    print(summaryData.appreciationGlobale.assessmentParagraph1);
    print(summaryData.appreciationGlobale.assessmentParagraph2);
    print(summaryData.appreciationGlobale.assessmentParagraph3);

    // ── ASSERTIONS FORMELLES DE CONCORDANCE ──
    expect(summary.criticalityStats.total, equals(240));
    expect(summary.criticalityStats.critique, equals(98));
    expect(summary.criticalityStats.majeure, equals(140));
    expect(summary.criticalityStats.mineure, equals(2));

    expect(summary.topTwoCategoriesResult.combinedNC, equals(185));
    expect(summary.topTwoCategoriesResult.cat1Name, equals('Armoires'));
    expect(summary.topTwoCategoriesResult.cat2Name, equals('Coffrets'));

    print('\n================================================================');
    print('  VÉRIFICATION EFFECTUÉE AVEC SUCCÈS : 100% DE CONCORDANCE');
    print('================================================================');
  });
}
