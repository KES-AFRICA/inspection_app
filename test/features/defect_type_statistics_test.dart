import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/mission_statistics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Statistique par type de défaut — Unit Tests', () {
    test('getTopDefects should aggregate identical verification points from multiple equipments', () {
      final findings = [
        AuditFinding(
          id: 'f1', missionId: 'm1', origin: 'Local MT > Cellule 1', objectType: 'Cellule MT', objectName: 'Arrivée',
          tableName: 'Tableau Cellule', verificationPoint: 'Canalisations et câbles d\'arrivée / départ',
          observationText: 'Défaut 1', conformity: 'non', criticality: 'Majeure',
        ),
        AuditFinding(
          id: 'f2', missionId: 'm1', origin: 'Local MT > Cellule 2', objectType: 'Cellule MT', objectName: 'Départ',
          tableName: 'Tableau Cellule', verificationPoint: 'Canalisations et câbles d\'arrivée / départ',
          observationText: 'Défaut 2', conformity: 'non', criticality: 'Majeure',
        ),
        AuditFinding(
          id: 'f3', missionId: 'm1', origin: 'Local BT', objectType: 'Coffret', objectName: 'TGBT',
          tableName: 'Points de vérification', verificationPoint: 'Identification complète des circuits',
          observationText: 'Incomplet', conformity: 'non', criticality: 'Critique',
        ),
      ];

      final inventory = AuditFindingInventory(missionId: 'm1', findings: findings);
      final topDefects = inventory.getTopDefects(limit: 10);

      expect(inventory.totalFindings, equals(3));
      expect(inventory.classifiedCount, equals(3));

      // The 2 Cellule findings share the EXACT same verification point and must be grouped into 1 defect item with count = 2
      expect(topDefects.length, equals(2));
      expect(topDefects.first.title, equals('Canalisations et câbles d\'arrivée / départ'));
      expect(topDefects.first.count, equals(2));
      expect(topDefects.first.percentage, closeTo(66.66, 0.1));

      expect(topDefects.last.title, equals('Identification complète des circuits'));
      expect(topDefects.last.count, equals(1));
      expect(topDefects.last.percentage, closeTo(33.33, 0.1));
    });

    test('Sum of occurrences across all defect types MUST equal classifiedCount', () {
      final findings = [
        AuditFinding(
          id: 'f1', missionId: 'm1', origin: 'Local MT', objectType: 'Local MT', objectName: 'Poste HTA',
          tableName: 'Dispositions constructives', verificationPoint: 'Dimensions',
          observationText: 'Inconforme', conformity: 'non', criticality: 'Majeure',
        ),
        AuditFinding(
          id: 'f2', missionId: 'm1', origin: 'Local MT', objectType: 'Local MT', objectName: 'Poste HTA',
          tableName: 'Dispositions constructives', verificationPoint: 'Éclairage normal',
          observationText: 'Défaillant', conformity: 'non', criticality: 'Critique',
        ),
        AuditFinding(
          id: 'f3', missionId: 'm1', origin: 'Local BT', objectType: 'Local BT', objectName: 'TGBT',
          tableName: 'Conditions d\'exploitation', verificationPoint: 'Plan d\'intervention',
          observationText: 'Absent', conformity: 'non', criticality: 'Mineure',
        ),
      ];

      final inventory = AuditFindingInventory(missionId: 'm1', findings: findings);
      final allDefects = inventory.getTopDefects(limit: 100);

      final totalOccurrences = allDefects.fold<int>(0, (sum, item) => sum + item.count);
      expect(totalOccurrences, equals(inventory.classifiedCount));
    });
  });
}
