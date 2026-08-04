import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MissionDomainInventoryEngine & EquipmentClassifier Tests', () {
    test('EquipmentClassifier should correctly classify equipment types', () {
      final coffretTGBT = CoffretArmoire(
        qrCode: 'qr1',
        nom: 'TGBT Principal Usine',
        type: 'TGBT',
        repere: 'TGBT-01',
      );

      final coffretArmoire = CoffretArmoire(
        qrCode: 'qr2',
        nom: 'Armoire TUR Atelier',
        type: 'Armoire',
        repere: 'ARM-01',
      );

      final coffretInverseur = CoffretArmoire(
        qrCode: 'qr3',
        nom: 'Inverseur Normal / Secours',
        type: 'Inverseur de source',
        repere: 'INV-GE',
      );

      final coffretDistribution = CoffretArmoire(
        qrCode: 'qr4',
        nom: 'Coffret Éclairage Hall',
        type: 'Coffret',
        repere: 'COFF-01',
      );

      expect(EquipmentClassifier.classify(coffretTGBT), equals(DomainObjectType.tgbt));
      expect(EquipmentClassifier.classify(coffretArmoire), equals(DomainObjectType.armoire));
      expect(EquipmentClassifier.classify(coffretInverseur), equals(DomainObjectType.inverseur));
      expect(EquipmentClassifier.classify(coffretDistribution), equals(DomainObjectType.coffret));
    });

    test('DomainEntityInstance should correctly compute checkpoints and compliance rates', () {
      final instance = DomainEntityInstance(
        instanceId: 'inst_1',
        category: DomainObjectType.localMT,
        name: 'Poste HTA principal',
        tensionDomain: TensionDomain.mt,
        originPath: 'Zone Industrielle > Local HTA',
      );

      instance.registerCheckpoint(conformity: 'oui');
      instance.registerCheckpoint(conformity: 'oui');
      instance.registerCheckpoint(conformity: 'non', criticality: 'Critique');
      instance.registerCheckpoint(conformity: 'na');

      expect(instance.totalCheckpoints, equals(4));
      expect(instance.compliantCheckpoints, equals(2));
      expect(instance.nonCompliantCheckpoints, equals(1));
      expect(instance.naCheckpoints, equals(1));
      expect(instance.critiqueCount, equals(1));
      expect(instance.complianceRate, closeTo(66.66, 0.1));
    });

    test('MissionDomainInventory should generate unified cross category summaries and inventory counts', () {
      final instMT = DomainEntityInstance(
        instanceId: 'mt_1',
        category: DomainObjectType.localMT,
        name: 'Local HTA 1',
        tensionDomain: TensionDomain.mt,
        originPath: 'Local MT HTA 1',
        compliantCheckpoints: 8,
        nonCompliantCheckpoints: 2,
        critiqueCount: 1,
        majeureCount: 1,
      );

      final instCell = DomainEntityInstance(
        instanceId: 'cell_1',
        category: DomainObjectType.celluleMT,
        name: 'Cellule 1 (Arrivée)',
        tensionDomain: TensionDomain.mt,
        originPath: 'Local MT HTA 1 > Cellule 1',
        compliantCheckpoints: 5,
        nonCompliantCheckpoints: 0,
      );

      final instTGBT = DomainEntityInstance(
        instanceId: 'tgbt_1',
        category: DomainObjectType.tgbt,
        name: 'TGBT Principal',
        tensionDomain: TensionDomain.bt,
        originPath: 'Local BT 1 > TGBT',
        compliantCheckpoints: 10,
        nonCompliantCheckpoints: 1,
        majeureCount: 1,
      );

      final inventory = MissionDomainInventory(
        missionId: 'test_m1',
        instances: [instMT, instCell, instTGBT],
        allFindings: [],
      );

      final crossSummaries = inventory.getCrossCategoryAnalysis();
      expect(crossSummaries.length, equals(3));

      final mtSummary = inventory.getCategorySummary(DomainObjectType.localMT);
      expect(mtSummary.equipmentCount, equals(1));
      expect(mtSummary.totalPointsEvaluated, equals(10));
      expect(mtSummary.nonConformitiesCount, equals(2));
      expect(mtSummary.critiqueCount, equals(1));
      expect(mtSummary.complianceRate, equals(80.0));

      final equipmentCounts = inventory.getEquipmentInventorySummary();
      expect(equipmentCounts.firstWhere((e) => e.label == 'Locaux techniques Moyenne Tension').count, equals(1));
      expect(equipmentCounts.firstWhere((e) => e.label == 'Cellules Moyenne Tension').count, equals(1));
      expect(equipmentCounts.firstWhere((e) => e.label == 'TGBT').count, equals(1));
      expect(equipmentCounts.firstWhere((e) => e.label == 'Armoires').count, equals(0));
    });
  });
}
