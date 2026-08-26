import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/services/equipment_number_service.dart';

void main() {
  group('Audit Metadata createdAt / updatedAt & Retrocompatibility Tests', () {
    test('1. Old objects with null createdAt stay null without crashing or fake dates', () {
      final oldCoffret = CoffretArmoire(
        qrCode: 'QR_OLD_123',
        nom: 'Armoire Ancienne',
        type: 'TGBT',
      );

      // Verify nullability and non-destruction
      expect(oldCoffret.createdAt, isNull, reason: 'Old equipments must NOT invent fake dates');
      expect(oldCoffret.updatedAt, isNull);
      expect(oldCoffret.equipmentId, startsWith('equip_'), reason: 'Immutable ID auto-generates on demand');

      final oldLocal = MoyenneTensionLocal(
        nom: 'Local Vielle Mission',
        type: 'LOCAL_TGBT',
      );

      expect(oldLocal.createdAt, isNull);
      expect(oldLocal.updatedAt, isNull);
      expect(oldLocal.localId, startsWith('local_'));
    });

    test('2. New entity instantiations populate createdAt and updatedAt with UTC timestamps', () {
      final now = DateTime.now().toUtc();
      
      final audit = AuditInstallationsElectriques.create('MISSION_2026_NEW');
      expect(audit.createdAt, isNotNull);
      expect(audit.updatedAt, isNotNull);

      final newCoffret = CoffretArmoire(
        qrCode: 'QR_NEW_456',
        nom: 'Coffret Neuf',
        type: 'COFFRET_PRISES',
        createdAt: now,
        updatedAt: now,
      );

      expect(newCoffret.createdAt, equals(now));
      expect(newCoffret.updatedAt, equals(now));

      final desc = DescriptionInstallations.create('MISSION_2026_NEW');
      expect(desc.createdAt, isNotNull);
      expect(desc.updatedAt, isNotNull);

      final mes = MesuresEssais.create('MISSION_2026_NEW');
      expect(mes.createdAt, isNotNull);
      expect(mes.updatedAt, isNotNull);

      final jsa = JSA.create('MISSION_2026_NEW');
      expect(jsa.createdAt, isNotNull);
      expect(jsa.updatedAt, isNotNull);

      final rg = RenseignementsGeneraux.create('MISSION_2026_NEW');
      expect(rg.createdAt, isNotNull);
      expect(rg.updatedAt, isNotNull);
    });

    test('3. Edition preserves original createdAt and updates updatedAt to new time', () async {
      final originalCreatedAt = DateTime.utc(2026, 1, 15, 10, 0, 0);
      final initialUpdatedAt = DateTime.utc(2026, 1, 15, 10, 0, 0);

      final existingCoffret = CoffretArmoire(
        qrCode: 'QR_EDIT_789',
        nom: 'Armoire initiale',
        type: 'TGBT',
        createdAt: originalCreatedAt,
        updatedAt: initialUpdatedAt,
      );

      final updateTime = DateTime.utc(2026, 8, 26, 14, 30, 0);

      final updatedCoffret = CoffretArmoire(
        id: existingCoffret.equipmentId,
        qrCode: existingCoffret.qrCode,
        nom: 'Armoire Modifiée',
        type: 'TGBT',
        createdAt: existingCoffret.createdAt,
        updatedAt: updateTime,
      );

      expect(updatedCoffret.equipmentId, equals(existingCoffret.equipmentId));
      expect(updatedCoffret.createdAt, equals(originalCreatedAt), reason: 'Original creation date preserved');
      expect(updatedCoffret.updatedAt, equals(updateTime), reason: 'Updated timestamp refreshed');
    });

    test('4. EquipmentNumberService sorts missing numbers deterministically using createdAt', () {
      final t1 = DateTime.utc(2026, 2, 1, 10, 0, 0);
      final t2 = DateTime.utc(2026, 2, 2, 10, 0, 0);

      final cOld = CoffretArmoire(
        qrCode: 'QR_1',
        nom: 'Equipement 1',
        type: 'ARMOIRE',
        createdAt: t1,
        numeroEquipement: null, // missing number
      );

      final cNew = CoffretArmoire(
        qrCode: 'QR_2',
        nom: 'Equipement 2',
        type: 'ARMOIRE',
        createdAt: t2,
        numeroEquipement: null, // missing number
      );

      final cUnstamped = CoffretArmoire(
        qrCode: 'QR_3',
        nom: 'Equipement 3',
        type: 'ARMOIRE',
        createdAt: null, // legacy no timestamp
        numeroEquipement: null,
      );

      final audit = AuditInstallationsElectriques.create('MISSION_SORT_TEST');
      audit.basseTensionZones.add(BasseTensionZone(
        nom: 'Zone 1',
        coffretsDirects: [cNew, cUnstamped, cOld], // Unsorted order
      ));

      final report = EquipmentNumberService.auditAndFixMissionNumbers(audit);
      expect(report.hasChanges, isTrue);

      // Verify that cOld (t1) got assigned #1, cNew (t2) got #2, and cUnstamped got #3
      expect(cOld.numeroEquipement, equals('1'));
      expect(cNew.numeroEquipement, equals('2'));
      expect(cUnstamped.numeroEquipement, equals('3'));
    });
  });
}
