import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/hive_service.dart';

void main() {
  group('CAMRAIL Equipment Resolution & Saveguard Tests', () {
    test('1. Multiple equipments with empty QR code retain distinct stable equipmentIds', () {
      final armoire1 = CoffretArmoire(
        qrCode: 'chj vjjjk',
        nom: 'bkjjjj nnkk jjk',
        type: 'ARMOIRE',
        numeroEquipement: '49',
      );

      final inverseur = CoffretArmoire(
        qrCode: '', // Empty QR code (CAMRAIL reproduction case)
        nom: 'nj',
        type: 'INVERSEUR',
        numeroEquipement: '51',
      );

      final armoire2 = CoffretArmoire(
        qrCode: '', // Empty QR code (CAMRAIL reproduction case)
        nom: 'kdlf dk dif',
        type: 'ARMOIRE',
        numeroEquipement: '52',
      );

      expect(armoire1.equipmentId, isNotEmpty);
      expect(inverseur.equipmentId, isNotEmpty);
      expect(armoire2.equipmentId, isNotEmpty);

      expect(inverseur.equipmentId, isNot(equals(armoire2.equipmentId)));
      expect(inverseur.equipmentId, isNot(equals(armoire1.equipmentId)));
    });

    test('2. Searching by equipmentId correctly distinguishes Armoire 2 from Inverseur with identical empty QR codes', () {
      final inverseur = CoffretArmoire(
        qrCode: '',
        nom: 'nj',
        type: 'INVERSEUR',
        numeroEquipement: '51',
      );

      final armoire2 = CoffretArmoire(
        qrCode: '',
        nom: 'kdlf dk dif',
        type: 'ARMOIRE',
        numeroEquipement: '52',
      );

      final coffretsList = [inverseur, armoire2];

      // Defective historical search by qrCode:
      final defectiveMatch = coffretsList.indexWhere((c) => c.qrCode == armoire2.qrCode);
      expect(defectiveMatch, equals(0)); // Returns Index 0 (Inverseur)!

      // Correct architectural search by equipmentId:
      final correctMatch = coffretsList.indexWhere((c) => c.equipmentId == armoire2.equipmentId);
      expect(correctMatch, equals(1)); // Returns Index 1 (Armoire 2)!
      expect(coffretsList[correctMatch].nom, equals('kdlf dk dif'));
      expect(coffretsList[correctMatch].type, equals('ARMOIRE'));
    });

    test('3. Saveguard check prevents mismatched equipment modification', () {
      final inverseur = CoffretArmoire(
        qrCode: '',
        nom: 'nj',
        type: 'INVERSEUR',
      );

      final armoire = CoffretArmoire(
        qrCode: '',
        nom: 'kdlf dk dif',
        type: 'ARMOIRE',
      );

      final loadedEquipmentId = armoire.equipmentId;
      final targetInDatabase = inverseur;

      // Saveguard logic: loadedEquipmentId must equal targetInDatabase.equipmentId
      final isSaveAllowed = (loadedEquipmentId == targetInDatabase.equipmentId);
      expect(isSaveAllowed, isFalse);
    });

    test('4. Update and alternation between multiple equipments preserves individual data', () {
      final inverseur = CoffretArmoire(
        qrCode: '',
        nom: 'nj',
        type: 'INVERSEUR',
        domaineTension: '230V',
      );

      final armoire = CoffretArmoire(
        qrCode: '',
        nom: 'kdlf dk dif',
        type: 'ARMOIRE',
        domaineTension: '400V',
      );

      final coffretsList = [inverseur, armoire];

      // Edit Armoire
      final armoireIndex = coffretsList.indexWhere((c) => c.equipmentId == armoire.equipmentId);
      coffretsList[armoireIndex].domaineTension = '400V Triphasé';

      // Verify Inverseur remains untouched
      final invIndex = coffretsList.indexWhere((c) => c.equipmentId == inverseur.equipmentId);
      expect(coffretsList[invIndex].type, equals('INVERSEUR'));
      expect(coffretsList[invIndex].domaineTension, equals('230V'));

      // Verify Armoire was updated
      expect(coffretsList[armoireIndex].type, equals('ARMOIRE'));
      expect(coffretsList[armoireIndex].domaineTension, equals('400V Triphasé'));
    });
  });
}
