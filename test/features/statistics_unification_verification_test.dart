import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';
import 'package:inspec_app/services/statistics/mission_statistics.dart';
import 'package:inspec_app/services/pdf/builders/pdf_statistics_builder.dart';

void main() {
  group('Mission Statistics Unification & Normative Findings (496 source of truth)', () {
    test('AuditFindingInventory filters out observations libres and unclassified findings', () {
      final findings = <AuditFinding>[
        // 3 Critique
        AuditFinding(
          id: '1',
          missionId: 'm1',
          tensionDomain: TensionDomain.mt,
          origin: 'Local MT',
          objectType: 'Local MT',
          objectName: 'Local 1',
          tableName: 'Dispositions constructives',
          verificationPoint: 'Porte coupe-feu',
          observationText: 'Porte non coupe-feu',
          conformity: 'non',
          criticality: 'Critique',
        ),
        AuditFinding(
          id: '2',
          missionId: 'm1',
          tensionDomain: TensionDomain.bt,
          origin: 'TGBT',
          objectType: 'TGBT',
          objectName: 'TGBT 1',
          tableName: 'Tableau BT',
          verificationPoint: 'Plastron',
          observationText: 'Plastron manquant',
          conformity: 'non',
          criticality: 'Critique',
        ),
        // 2 Majeure
        AuditFinding(
          id: '3',
          missionId: 'm1',
          tensionDomain: TensionDomain.bt,
          origin: 'Armoire',
          objectType: 'Armoire',
          objectName: 'Armoire 1',
          tableName: 'Tableau BT',
          verificationPoint: 'Repérage',
          observationText: 'Repérage incomplet',
          conformity: 'non',
          criticality: 'Majeure',
        ),
        AuditFinding(
          id: '4',
          missionId: 'm1',
          tensionDomain: TensionDomain.mt,
          origin: 'Cellule MT',
          objectType: 'Cellule MT',
          objectName: 'Cellule 1',
          tableName: 'Cellules',
          verificationPoint: 'Verrouillage',
          observationText: 'Verrouillage absent',
          conformity: 'non',
          criticality: 'Majeure',
        ),
        // 1 Mineure
        AuditFinding(
          id: '5',
          missionId: 'm1',
          tensionDomain: TensionDomain.bt,
          origin: 'Coffret',
          objectType: 'Coffret',
          objectName: 'Coffret 1',
          tableName: 'Tableau BT',
          verificationPoint: 'Étiquetage',
          observationText: 'Étiquette sale',
          conformity: 'non',
          criticality: 'Mineure',
        ),
        // 1 Observation libre (MUST BE EXCLUDED)
        AuditFinding(
          id: '6',
          missionId: 'm1',
          tensionDomain: TensionDomain.bt,
          origin: 'Coffret',
          objectType: 'Coffret',
          objectName: 'Coffret 1',
          tableName: 'Observations libres',
          verificationPoint: 'Observation libre diverse',
          observationText: 'Remarque visuelle',
          conformity: 'non',
          criticality: 'Mineure',
        ),
        // 1 Unclassified / Non spécifiée (MUST BE EXCLUDED)
        AuditFinding(
          id: '7',
          missionId: 'm1',
          tensionDomain: TensionDomain.mt,
          origin: 'Local MT',
          objectType: 'Local MT',
          objectName: 'Local 1',
          tableName: 'Dispositions constructives',
          verificationPoint: 'Accès',
          observationText: 'Accès encombré',
          conformity: 'non',
          criticality: 'Non spécifiée',
        ),
      ];

      final inventory = AuditFindingInventory(
        missionId: 'm1',
        findings: findings,
      );

      // Raw total is 7
      expect(findings.length, equals(7));

      // Normative pertinent non-conformities MUST be strictly 5 (2 critique + 2 majeure + 1 mineure)
      expect(inventory.pertinentFindings.length, equals(5));
      expect(inventory.totalFindings, equals(5));
      expect(inventory.critiqueCount, equals(2));
      expect(inventory.majeureCount, equals(2));
      expect(inventory.mineureCount, equals(1));
      expect(inventory.unspecifiedCount, equals(0));
      expect(inventory.classifiedCount, equals(5));

      // Tension domain sum must strictly equal totalFindings (5)
      final tensionStats = inventory.getTensionDomainStats();
      expect(tensionStats.mtCount + tensionStats.btCount, equals(5));
      expect(tensionStats.totalCount, equals(5));
    });

    test('MissionDomainInventory with 496 normative findings guarantees exact coherence across all indicators', () {
      final allFindings = <AuditFinding>[];

      // Simulate 496 normative findings (e.g. 131 MT, 365 BT)
      for (int i = 0; i < 131; i++) {
        allFindings.add(AuditFinding(
          id: 'mt_$i',
          missionId: 'm496',
          tensionDomain: TensionDomain.mt,
          origin: 'Poste MT',
          objectType: 'Cellule MT',
          objectName: 'Cellule ${i % 10}',
          tableName: 'Cellules MT',
          verificationPoint: 'Défaut MT ${i % 5}',
          observationText: 'Obs MT $i',
          conformity: 'non',
          criticality: i % 2 == 0 ? 'Critique' : 'Majeure',
        ));
      }
      for (int i = 0; i < 365; i++) {
        allFindings.add(AuditFinding(
          id: 'bt_$i',
          missionId: 'm496',
          tensionDomain: TensionDomain.bt,
          origin: 'Tableau BT',
          objectType: 'Armoire',
          objectName: 'Armoire ${i % 20}',
          tableName: 'Tableaux BT',
          verificationPoint: 'Défaut BT ${i % 15}',
          observationText: 'Obs BT $i',
          conformity: 'non',
          criticality: i % 3 == 0 ? 'Critique' : 'Majeure',
        ));
      }

      // Add 5 unclassified/free observation items that must be filtered out
      for (int i = 0; i < 5; i++) {
        allFindings.add(AuditFinding(
          id: 'free_$i',
          missionId: 'm496',
          tensionDomain: TensionDomain.bt,
          origin: 'Divers',
          objectType: 'Armoire',
          objectName: 'Armoire',
          tableName: 'Observations libres',
          verificationPoint: 'Observation libre $i',
          observationText: 'Remarque libre $i',
          conformity: 'non',
          criticality: 'Non spécifiée',
        ));
      }

      expect(allFindings.length, equals(501));

      final domainInventory = MissionDomainInventory(
        missionId: 'm496',
        allFindings: allFindings,
        instances: [],
      );

      // Core rule: pertinentFindings MUST equal 496!
      expect(domainInventory.pertinentFindings.length, equals(496));

      // Tension domain stats
      final tensionStats = domainInventory.getTensionDomainStats();
      expect(tensionStats.totalCount, equals(496));
      expect(tensionStats.mtCount, equals(131));
      expect(tensionStats.btCount, equals(365));
      expect(tensionStats.mtCount + tensionStats.btCount, equals(496));

      // Pareto analysis
      final pareto = domainInventory.getParetoAnalysis(limit: 10);
      expect(pareto.totalOccurrences, equals(496));
      expect(pareto.totalDistinctCategories, greaterThan(0));

      final top10Sum = pareto.items.take(10).fold<int>(0, (s, e) => s + e.count);
      final top10Pct = (top10Sum / 496) * 100;
      expect(pareto.top10Percentage, closeTo(top10Pct, 0.05));

      // Criticality stats
      expect(domainInventory.critiqueCount + domainInventory.majeureCount + domainInventory.mineureCount, equals(496));
    });

    test('Pareto explanation does not contain bug or internal tool error phrases', () {
      final paretoResult = ParetoAnalysisResult(
        items: [
          TopDefectItem(title: 'Repérage des circuits', count: 112, percentage: 22.6),
          TopDefectItem(title: 'Serrage des connexions', count: 107, percentage: 21.6),
        ],
        totalOccurrences: 496,
        paretoCategoryCount: 38,
        paretoCumulativePercentage: 80.0,
        summaryText: 'Test summary',
        totalDistinctCategories: 60,
      );

      // Incohérence alert box text must no longer exist in code or output
      expect(paretoResult.summaryText.contains('incohérence relevée'), isFalse);
      expect(paretoResult.summaryText.contains('outil'), isFalse);
    });
  });
}
