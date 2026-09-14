import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/equipment_number_service.dart';
import 'package:inspec_app/services/installation_fields_registry.dart';

void main() {
  group('Equipment Audit & Numbering Tests', () {
    test('EquipmentNumberService preserves existing numbers without renumbering', () {
      final audit = AuditInstallationsElectriques.create('mission_400');

      final local = BasseTensionLocal(
        nom: 'Local TGBT',
        type: 'Technique',
        coffrets: [
          CoffretArmoire(
            qrCode: 'QR_TGBT_1',
            id: 'eq_1',
            nom: 'TGBT 1',
            type: 'TGBT',
            numeroEquipement: '1',
          ),
          CoffretArmoire(
            qrCode: 'QR_INV_2',
            id: 'eq_2',
            nom: 'Inverseur Normal/Secours',
            type: 'INVERSEUR',
            numeroEquipement: '2',
          ),
          CoffretArmoire(
            qrCode: 'QR_COFF_50',
            id: 'eq_50',
            nom: 'Coffret Pompe',
            type: 'COFFRET',
            numeroEquipement: '50',
          ),
        ],
      );

      final zone1 = BasseTensionZone(
        nom: 'Zone Principale',
        locaux: [local],
      );
      audit.basseTensionZones.add(zone1);

      final zone2 = BasseTensionZone(
        nom: 'Zone Usine',
        coffretsDirects: [
          CoffretArmoire(
            qrCode: 'QR_ARM_399',
            id: 'eq_399',
            nom: 'Armoire Atelier',
            type: 'ARMOIRE',
            numeroEquipement: '399',
          ),
        ],
      );
      audit.basseTensionZones.add(zone2);

      // Audit and fix numbers should NOT renumber existing valid numbers
      final report = EquipmentNumberService.auditAndFixMissionNumbers(audit);
      expect(report.hasChanges, false);

      // Verify the numbers were not remapped to 1, 2, 3, 4
      expect(audit.basseTensionZones[0].locaux[0].coffrets[0].numeroEquipement, '1');
      expect(audit.basseTensionZones[0].locaux[0].coffrets[1].numeroEquipement, '2');
      expect(audit.basseTensionZones[0].locaux[0].coffrets[2].numeroEquipement, '50');
      expect(audit.basseTensionZones[1].coffretsDirects[0].numeroEquipement, '399');

      // Next number should be 400 (max 399 + 1)
      final nextNum = EquipmentNumberService.getNextEquipmentNumber(
        'mission_400',
        audit: audit,
      );
      expect(nextNum, 400);
    });

    test('EquipmentNumberService assigns missing numbers above max without collision', () {
      final audit = AuditInstallationsElectriques.create('mission_collision');

      final local = BasseTensionLocal(
        nom: 'Local 1',
        type: 'Technique',
        coffrets: [
          CoffretArmoire(
            qrCode: 'QR_EQ_1',
            id: 'eq_1',
            nom: 'Eq 1',
            type: 'COFFRET',
            numeroEquipement: '10',
          ),
          CoffretArmoire(
            qrCode: 'QR_INV_NEW',
            id: 'eq_missing',
            nom: 'Inverseur Nouveau',
            type: 'INVERSEUR',
            numeroEquipement: null, // missing
          ),
        ],
      );
      audit.basseTensionZones.add(BasseTensionZone(nom: 'Zone 1', locaux: [local]));

      final report = EquipmentNumberService.auditAndFixMissionNumbers(audit);
      expect(report.missingNumbersFixed, 1);
      // Existing number 10 remains 10, new assigned is 11
      expect(audit.basseTensionZones[0].locaux[0].coffrets[0].numeroEquipement, '10');
      expect(audit.basseTensionZones[0].locaux[0].coffrets[1].numeroEquipement, '11');
    });

    test('Transformateur UCC and Refroidissement custom values and calculations', () {
      // 1. CalculateIk3Max with custom UCC formatting
      final ik3Standard = InstallationFieldsRegistry.calculateIk3Max(
        puissanceKva: '1000',
        uccPercent: '6 %',
      );
      expect(ik3Standard, isNotEmpty);

      final ik3WithoutPercent = InstallationFieldsRegistry.calculateIk3Max(
        puissanceKva: '1000',
        uccPercent: '6',
      );
      expect(ik3WithoutPercent, ik3Standard);

      // 2. Transformateur model accepts custom Puissance UCC and custom Refroidissement
      final transfo = TransformateurMTBT(
        nom: 'Transfo Custom 01',
        typeTransformateur: 'IMMERGÉ',
        puissanceAssignee: '1250',
        tensionPrimaireSecondaire: '20kV / 400V',
        puissanceUcc: '5.5 %',
        typeRefroidissement: 'ONAN/AF Custom Air',
        regimeNeutre: 'TN-S',
        marqueAnnee: 'SCHNEIDER 2022',
        relaisBuchholz: 'Présent',
      );

      expect(transfo.puissanceUcc, '5.5 %');
      expect(transfo.typeRefroidissement, 'ONAN/AF Custom Air');
    });
  });
}
