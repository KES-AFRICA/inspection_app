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
    tempDir = await Directory.systemTemp.createTemp('hive_camrail_test_');
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

  test('Audit complet de CAMRAIL BESSENGUE via la logique applicative réelle', () async {
    final backupFile = File('/home/andelson-teufack/Téléchargements/backup_CAMRAIL_BESSENGUE_CAMRAIL_BESSENGUE_KES__26_INSP_010_2026-08-25T11-48-03.inspec');
    expect(backupFile.existsSync(), isTrue, reason: 'Fichier backup inexistant');

    final result = await BackupService.importerSauvegardeFichier(
      filePath: backupFile.path,
      ecraser: true,
      importeurMatricule: 'AUDIT',
      importeurNom: 'AUDIT',
      importeurPrenom: 'AUDIT',
    );
    expect(result.success, isTrue, reason: 'Importation backup échouée: ${result.message}');

    const missionId = '1783501230919';
    print('\n======================================================');
    print('   TEST DIAGNOSTIC AUDIT CAMRAIL BESSENGUE');
    print('======================================================');
    print('Mission ID restauré: $missionId');

    final summary = MissionStatisticsCollector.collectSummary(missionId);
    final domainInventory = summary.domainInventory;
    final inventory = summary.inventory;

    print('\n--- 1. INVENTAIRE PHYSIQUE PAR DOMAIN_INVENTORY ---');
    if (domainInventory != null) {
      print('Total instances enregistrées dans DomainInventory: ${domainInventory.instances.length}');
      for (final cat in domainInventory.getCrossCategoryAnalysis()) {
        print('  • ${cat.categoryName} (${cat.categoryKey}) -> Équip: ${cat.equipmentCount}, NC: ${cat.nonConformitiesCount}, Crit: ${cat.critiqueCount}, Maj: ${cat.majeureCount}, Min: ${cat.mineureCount}, Densité: ${cat.density.toStringAsFixed(2)}');
      }
    }

    print('\n--- 2. NON-CONFORMITÉS PAR CRITICITÉ (AuditFindingInventoryEngine) ---');
    print('Total findings dans AuditFindingInventory: ${inventory.findings.length}');
    print('Total NCs dans summary.criticalityStats: ${summary.criticalityStats.total}');
    print('  - Critique: ${summary.criticalityStats.critique} (${summary.criticalityStats.pctCritique.toStringAsFixed(1)}%)');
    print('  - Majeure: ${summary.criticalityStats.majeure} (${summary.criticalityStats.pctMajeure.toStringAsFixed(1)}%)');
    print('  - Mineure: ${summary.criticalityStats.mineure} (${summary.criticalityStats.pctMineure.toStringAsFixed(1)}%)');

    print('\n--- 3. RÉPARTITION PAR DOMAINE DE TENSION ---');
    print('Total TensionDomainStats: ${summary.tensionDomainStats.totalCount}');
    print('  - MT: ${summary.tensionDomainStats.mtCount} NC (${summary.tensionDomainStats.mtPct.toStringAsFixed(1)}%)');
    print('  - BT: ${summary.tensionDomainStats.btCount} NC (${summary.tensionDomainStats.btPct.toStringAsFixed(1)}%)');

    print('\n--- 4. ANALYSE DE PARETO (TOP DÉFAUTS) ---');
    print('Total Pareto Occurrences: ${summary.paretoResult.totalOccurrences}');
    print('Nombre de catégories Pareto pour atteindre 80%: ${summary.paretoResult.paretoCategoryCount}');
    for (var i = 0; i < summary.paretoResult.items.length; i++) {
      final item = summary.paretoResult.items[i];
      print('  ${i + 1}. ${item.title} -> ${item.count} (${item.percentage.toStringAsFixed(1)}%, cumul: ${item.cumulativePercentage.toStringAsFixed(1)}%)');
    }

    print('\n--- 5. TOP 2 CATÉGORIES LES PLUS SENSIBLES ---');
    print('Label: ${summary.topTwoCategoriesResult.label}');
    print('Cat1: ${summary.topTwoCategoriesResult.cat1Name}, Cat2: ${summary.topTwoCategoriesResult.cat2Name}');
    print('Combined NC: ${summary.topTwoCategoriesResult.combinedNC} (${summary.topTwoCategoriesResult.pctTotalNC.toStringAsFixed(1)}% du total)');
    print('Formatted value: ${summary.topTwoCategoriesResult.formattedValue}');

    print('\n--- 6. FAMILLES DE RISQUES ---');
    for (final rf in summary.riskFamilyStats) {
      print('  • ${rf.name}: ${rf.count} NC (${rf.percentage.toStringAsFixed(1)}%)');
    }
  });
}
