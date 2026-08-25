import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/services/backup_service.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/statistics/mission_statistics_collector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_14_subsections_test_');
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

  test('Audit Exhaustif des 14 Sous-Sections (RÉSUMÉ EXÉCUTIF & ANALYSE STATISTIQUE)', () async {
    final backupFile = File('/home/andelson-teufack/Téléchargements/backup_CAMRAIL_BESSENGUE_CAMRAIL_BESSENGUE_KES__26_INSP_010_2026-08-25T11-48-03.inspec');
    expect(backupFile.existsSync(), isTrue);

    final result = await BackupService.importerSauvegardeFichier(
      filePath: backupFile.path,
      ecraser: true,
      importeurMatricule: 'AUDIT',
      importeurNom: 'AUDIT',
      importeurPrenom: 'AUDIT',
    );
    expect(result.success, isTrue);

    const missionId = '1783501230919';
    final summary = MissionStatisticsCollector.collectSummary(missionId);
    final domainInventory = summary.domainInventory!;

    print('\n================================================================');
    print('  AUDIT SYSTEMATIQUE DES 14 SOUS-SECTIONS (CAMRAIL BESSENGUE)');
    print('================================================================');

    // ─────────────────────────────────────────────────────────────
    // SECTION A — RÉSUMÉ EXÉCUTIF
    // ─────────────────────────────────────────────────────────────
    print('\n--- [A.2] Synthèse des résultats ---');
    print('Total NC: ${summary.criticalityStats.total}');
    print('Part Critique: ${summary.criticalityStats.critique} (${summary.criticalityStats.pctCritique.toStringAsFixed(1)}%)');
    print('Part Majeure: ${summary.criticalityStats.majeure} (${summary.criticalityStats.pctMajeure.toStringAsFixed(1)}%)');
    print('Part Mineure: ${summary.criticalityStats.mineure} (${summary.criticalityStats.pctMineure.toStringAsFixed(1)}%)');

    print('\n--- [A.3] Concentration du risque ---');
    final top2 = summary.topTwoCategoriesResult;
    print('Titre dynamique: ${top2.label}');
    print('Catégorie 1: ${top2.cat1Name}, Catégorie 2: ${top2.cat2Name}');
    print('Concentration NCs: ${top2.combinedNC} (${top2.pctTotalNC.toStringAsFixed(1)}% du total)');
    print('Concentration Équipements: ${top2.combinedEquipments} (${top2.pctParc.toStringAsFixed(1)}% du parc)');

    print('\n--- [A.4] Facteurs de risque prépondérants ---');
    for (final rf in summary.riskFamilyStats) {
      print('  • ${rf.name}: ${rf.count} NC (${rf.percentage.toStringAsFixed(1)}%)');
    }

    print('\n--- [A.5 & A.6] Top Défaillances & Recommandations ---');
    for (var i = 0; i < summary.paretoResult.items.length && i < 5; i++) {
      final p = summary.paretoResult.items[i];
      print('  Top ${i + 1}: ${p.title} -> ${p.count} NC (${p.percentage.toStringAsFixed(1)}%)');
    }

    // ─────────────────────────────────────────────────────────────
    // SECTION B — ANALYSE STATISTIQUE
    // ─────────────────────────────────────────────────────────────
    print('\n--- [B.1] Indicateurs clés de la mission ---');
    print('Nombre d\'instances dans l\'inventaire: ${domainInventory.instances.length}');
    final crossList = domainInventory.getCrossCategoryAnalysis();
    print('Nombre de catégories actives représentées: ${crossList.length}');
    final densestStr = domainInventory.getDensestCategoryFormatted();
    print('Catégorie la plus dense: $densestStr');

    print('\n--- [B.2.1] Non-conformités par catégorie d\'installation / d\'équipement ---');
    for (final item in crossList) {
      print('  • ${item.categoryName}: Équip: ${item.equipmentCount}, NC: ${item.nonConformitiesCount}, Crit: ${item.critiqueCount}, Maj: ${item.majeureCount}, Min: ${item.mineureCount}, Densité: ${item.density.toStringAsFixed(2)} NC/équip');
    }

    print('\n--- [B.2.2] Analyse de la criticité des non-conformités ---');
    print('Total classifiées: ${summary.criticalityStats.total}');
    print('Critiques + Majeures: ${summary.criticalityStats.critique + summary.criticalityStats.majeure} (${((summary.criticalityStats.critique + summary.criticalityStats.majeure) / summary.criticalityStats.total * 100).toStringAsFixed(1)}%)');

    print('\n--- [B.3] Répartition par domaine de tension (MT vs BT) ---');
    print('MT: ${summary.tensionDomainStats.mtCount} NC (${summary.tensionDomainStats.mtPct.toStringAsFixed(1)}%)');
    print('BT: ${summary.tensionDomainStats.btCount} NC (${summary.tensionDomainStats.btPct.toStringAsFixed(1)}%)');

    print('\n--- [B.4] Statistique par type de défaut — Analyse de Pareto (80/20) ---');
    print('Nombre de catégories Pareto pour 80%: ${summary.paretoResult.paretoCategoryCount}');
    print('Pourcentage cumulé Pareto: ${summary.paretoResult.paretoCumulativePercentage.toStringAsFixed(1)}%');
    for (var i = 0; i < summary.paretoResult.items.length; i++) {
      final p = summary.paretoResult.items[i];
      print('  Rank ${i + 1}: ${p.title} -> ${p.count} (${p.percentage.toStringAsFixed(1)}%, cumul: ${p.cumulativePercentage.toStringAsFixed(1)}%)');
    }

    print('\n================================================================');
    print('  AUDIT DES 14 SOUS-SECTIONS TERMINÉ AVEC SUCCÈS');
    print('================================================================');
  });
}
