import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/mission_statistics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Statistical Engine Architecture & Aggregations Tests', () {
    test('AuditFindingInventory should compute accurate criticality counts and percentages', () {
      final findings = [
        AuditFinding(
          id: 'f1',
          missionId: 'm1',
          origin: 'Local MT 1',
          objectType: 'Local MT',
          objectName: 'Poste HTA',
          tableName: 'Dispositions constructives',
          verificationPoint: 'Signalisation',
          observationText: 'Signalisation absente',
          conformity: 'non',
          criticality: 'Critique',
          riskFamily: 'Risque Électrique',
        ),
        AuditFinding(
          id: 'f2',
          missionId: 'm1',
          origin: 'Local MT 1',
          objectType: 'Cellule MT',
          objectName: 'Cellule Arrivée',
          tableName: 'Tableau Cellule',
          verificationPoint: 'Verrouillage mécanique',
          observationText: 'Verrouillage défectueux',
          conformity: 'non',
          criticality: 'Majeure',
          riskFamily: 'Risque Mécanique',
        ),
        AuditFinding(
          id: 'f3',
          missionId: 'm1',
          origin: 'Local BT 1',
          objectType: 'Coffret',
          objectName: 'Coffret Divisionnaire',
          tableName: 'Points de vérification',
          verificationPoint: 'Signalisation',
          observationText: 'Plaque d\'avertissement manquante',
          conformity: 'non',
          criticality: 'Mineure',
          riskFamily: 'Risque Électrique',
        ),
      ];

      final inventory = AuditFindingInventory(missionId: 'm1', findings: findings);

      expect(inventory.totalFindings, equals(3));
      expect(inventory.critiqueCount, equals(1));
      expect(inventory.majeureCount, equals(1));
      expect(inventory.mineureCount, equals(1));
      expect(inventory.pctCritique, closeTo(33.33, 0.1));
      expect(inventory.pctMajeure, closeTo(33.33, 0.1));
      expect(inventory.pctMineure, closeTo(33.33, 0.1));
    });

    test('getTopDefects should correctly group and rank verification points', () {
      final findings = [
        AuditFinding(
          id: 'f1', missionId: 'm1', origin: 'Local MT', objectType: 'Local MT', objectName: 'Poste',
          tableName: 'DC', verificationPoint: 'Signalisation', observationText: 'Obs 1', conformity: 'non', criticality: 'Majeure',
        ),
        AuditFinding(
          id: 'f2', missionId: 'm1', origin: 'Local BT', objectType: 'Local BT', objectName: 'TGBT',
          tableName: 'DC', verificationPoint: 'Signalisation', observationText: 'Obs 2', conformity: 'non', criticality: 'Mineure',
        ),
        AuditFinding(
          id: 'f3', missionId: 'm1', origin: 'Local BT', objectType: 'Coffret', objectName: 'Coffret A',
          tableName: 'PV', verificationPoint: 'Mise à la terre', observationText: 'Obs 3', conformity: 'non', criticality: 'Critique',
        ),
      ];

      final inventory = AuditFindingInventory(missionId: 'm1', findings: findings);
      final topDefects = inventory.getTopDefects(limit: 5);

      expect(topDefects.length, equals(2));
      expect(topDefects.first.title, equals('Signalisation'));
      expect(topDefects.first.count, equals(2));
      expect(topDefects.first.percentage, closeTo(66.66, 0.1));

      expect(topDefects.last.title, equals('Mise à la terre'));
      expect(topDefects.last.count, equals(1));
    });

    test('getRiskFamilyStats should compute risk family counts and percentages', () {
      final findings = [
        AuditFinding(
          id: 'f1', missionId: 'm1', origin: 'Local MT', objectType: 'Local MT', objectName: 'Poste',
          tableName: 'DC', verificationPoint: 'Point 1', observationText: 'Obs 1', conformity: 'non', criticality: 'Majeure', riskFamily: 'Risque Électrique',
        ),
        AuditFinding(
          id: 'f2', missionId: 'm1', origin: 'Local BT', objectType: 'Local BT', objectName: 'TGBT',
          tableName: 'DC', verificationPoint: 'Point 2', observationText: 'Obs 2', conformity: 'non', criticality: 'Critique', riskFamily: 'Risque Incendie',
        ),
        AuditFinding(
          id: 'f3', missionId: 'm1', origin: 'Local BT', objectType: 'Coffret', objectName: 'Coffret A',
          tableName: 'PV', verificationPoint: 'Point 3', observationText: 'Obs 3', conformity: 'non', criticality: 'Mineure', riskFamily: 'Risque Électrique',
        ),
      ];

      final inventory = AuditFindingInventory(missionId: 'm1', findings: findings);
      final riskStats = inventory.getRiskFamilyStats();

      expect(riskStats.length, equals(2));
      expect(riskStats.first.name, equals('Risque Électrique'));
      expect(riskStats.first.count, equals(2));
      expect(riskStats.first.percentage, closeTo(66.66, 0.1));

      expect(riskStats.last.name, equals('Risque Incendie'));
      expect(riskStats.last.count, equals(1));
    });

    test('getTensionDomainStats should distinguish MT vs BT findings', () {
      final findings = [
        AuditFinding(
          id: 'f1', missionId: 'm1', origin: 'Local MT 1', objectType: 'Cellule MT', objectName: 'Cellule A',
          tableName: 'Tableau Cellule', verificationPoint: 'Point MT', observationText: 'Obs MT', conformity: 'non', criticality: 'Majeure',
        ),
        AuditFinding(
          id: 'f2', missionId: 'm1', origin: 'Local BT 1', objectType: 'Coffret', objectName: 'Coffret BT',
          tableName: 'Points de vérification', verificationPoint: 'Point BT', observationText: 'Obs BT', conformity: 'non', criticality: 'Mineure',
        ),
      ];

      final inventory = AuditFindingInventory(missionId: 'm1', findings: findings);
      final domainStats = inventory.getTensionDomainStats();

      expect(domainStats.totalCount, equals(2));
      expect(domainStats.mtCount, equals(1));
      expect(domainStats.btCount, equals(1));
      expect(domainStats.mtPct, equals(50.0));
      expect(domainStats.btPct, equals(50.0));
    });

    test('MissionStatisticsSummary.fromInventory should generate a complete summary container', () {
      final findings = [
        AuditFinding(
          id: 'f1', missionId: 'm_test', origin: 'Local MT', objectType: 'Local MT', objectName: 'Poste',
          tableName: 'DC', verificationPoint: 'Signalisation', observationText: 'Obs', conformity: 'non', criticality: 'Critique', riskFamily: 'Risque Électrique',
        ),
      ];

      final inventory = AuditFindingInventory(missionId: 'm_test', findings: findings);
      final summary = MissionStatisticsSummary.fromInventory(inventory);

      expect(summary.missionId, equals('m_test'));
      expect(summary.criticalityStats.critique, equals(1));
      expect(summary.topDefects.length, equals(1));
      expect(summary.riskFamilyStats.length, equals(1));
      expect(summary.tensionDomainStats.mtCount, equals(1));
      expect(summary.installationTypeStats.length, equals(1));
    });
  });
}
