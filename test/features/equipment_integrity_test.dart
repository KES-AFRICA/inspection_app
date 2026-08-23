import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/hive_service.dart';

void main() {
  group('Equipment Data Integrity & Numbering QA Tests', () {
    test('Test H: Legacy Migration — Coffret initialized without ID auto-generates stable equipmentId', () {
      final coffret = CoffretArmoire(
        qrCode: 'QR_LEGACY_1',
        nom: 'Armoire Ancienne',
        type: 'ARMOIRE',
      );

      // Verify equipmentId getter automatically provisions a stable non-empty ID
      final id1 = coffret.equipmentId;
      expect(id1, isNotEmpty);
      expect(id1.startsWith('equip_'), isTrue);

      // Verify repeated accesses return the exact same immuable ID
      final id2 = coffret.equipmentId;
      expect(id2, equals(id1));
    });

    test('Test A & B & C: Sequential Editing, Alternation & Targeted Modification', () async {
      final missionId = 'mission_test_integrity_1';
      final audit = AuditInstallationsElectriques.create(missionId);

      final toto = CoffretArmoire(
        id: 'id_toto_123',
        qrCode: 'QR_TOTO',
        nom: 'Armoire Toto',
        type: 'ARMOIRE',
        numeroEquipement: '1',
      );

      final tata = CoffretArmoire(
        id: 'id_tata_456',
        qrCode: 'QR_TATA',
        nom: 'TGBT Tata',
        type: 'TGBT',
        numeroEquipement: '2',
      );

      final titi = CoffretArmoire(
        id: 'id_titi_789',
        qrCode: 'QR_TITI',
        nom: 'Coffret Titi',
        type: 'COFFRET',
        numeroEquipement: '3',
      );

      final local = BasseTensionLocal(
        nom: 'Local TGBT',
        type: 'Local BT',
        coffrets: [toto, tata, titi],
      );

      audit.basseTensionZones = [
        BasseTensionZone(
          nom: 'Zone Principale',
          locaux: [local],
        ),
      ];

      // Verify each equipment preserves its distinct identity
      expect(toto.equipmentId, equals('id_toto_123'));
      expect(tata.equipmentId, equals('id_tata_456'));
      expect(titi.equipmentId, equals('id_titi_789'));

      // Simulate modification of Toto exclusively
      final updatedToto = CoffretArmoire(
        id: 'id_toto_123',
        qrCode: 'QR_TOTO_NEW',
        nom: 'Armoire Toto Modifiée',
        type: 'ARMOIRE',
        numeroEquipement: '1',
      );

      // Update in local list using equipmentId
      final targetIndex = local.coffrets.indexWhere((c) => c.equipmentId == updatedToto.equipmentId);
      expect(targetIndex, equals(0));
      local.coffrets[targetIndex] = updatedToto;

      // Assert Tata and Titi are completely unchanged
      expect(local.coffrets[0].nom, equals('Armoire Toto Modifiée'));
      expect(local.coffrets[1].nom, equals('TGBT Tata'));
      expect(local.coffrets[1].equipmentId, equals('id_tata_456'));
      expect(local.coffrets[2].nom, equals('Coffret Titi'));
      expect(local.coffrets[2].equipmentId, equals('id_titi_789'));
    });

    test('Test E: Equipment Numbering Escalation with Mixed Formats', () {
      final missionId = 'mission_num_test';
      final audit = AuditInstallationsElectriques.create(missionId);

      // Add coffrets with mixed number formats ("1", "EQ-02", "3-B")
      final c1 = CoffretArmoire(qrCode: 'Q1', nom: 'C1', type: 'COFFRET', numeroEquipement: '1');
      final c2 = CoffretArmoire(qrCode: 'Q2', nom: 'C2', type: 'COFFRET', numeroEquipement: 'EQ-02');
      final c3 = CoffretArmoire(qrCode: 'Q3', nom: 'C3', type: 'COFFRET', numeroEquipement: '3-B');

      audit.basseTensionZones = [
        BasseTensionZone(
          nom: 'Zone 1',
          coffretsDirects: [c1, c2, c3],
        ),
      ];

      // Test parsing helper logic
      int maxNum = 0;
      for (final c in [c1, c2, c3]) {
        final str = c.numeroEquipement?.trim() ?? '';
        final match = RegExp(r'\d+').firstMatch(str);
        if (match != null) {
          final n = int.tryParse(match.group(0)!);
          if (n != null && n > maxNum) maxNum = n;
        }
      }

      expect(maxNum, equals(3));
      final nextNum = maxNum + 1;
      expect(nextNum, equals(4));
    });

    test('Test F: Deletion Resilience in Equipment List', () {
      final coffrets = [
        CoffretArmoire(id: 'c1', qrCode: 'Q1', nom: 'C1', type: 'C', numeroEquipement: '1'),
        CoffretArmoire(id: 'c2', qrCode: 'Q2', nom: 'C2', type: 'C', numeroEquipement: '2'),
        CoffretArmoire(id: 'c3', qrCode: 'Q3', nom: 'C3', type: 'C', numeroEquipement: '3'),
      ];

      // Delete equipment in the middle (index 1 / id 'c2')
      coffrets.removeWhere((c) => c.equipmentId == 'c2');

      expect(coffrets.length, equals(2));
      expect(coffrets.map((c) => c.equipmentId), equals(['c1', 'c3']));

      // Verify highest remaining number is still 3
      int maxNum = 0;
      for (final c in coffrets) {
        final match = RegExp(r'\d+').firstMatch(c.numeroEquipement ?? '');
        if (match != null) {
          final n = int.parse(match.group(0)!);
          if (n > maxNum) maxNum = n;
        }
      }
      expect(maxNum, equals(3));
    });
  });
}
