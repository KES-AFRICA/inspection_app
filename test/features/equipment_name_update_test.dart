import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/equipment_number_service.dart';

void main() {
  group('Audit & Persistance - Modification du nom des équipements', () {
    test('1. Getter equipmentId est déterministe pour un équipement legacy sans ID persistant', () {
      final now = DateTime.now();
      final coffret = CoffretArmoire(
        qrCode: 'COFFRET_100',
        nom: 'Coffret Local Technique',
        type: 'COFFRET',
        createdAt: now,
      );

      // Simulation d'un équipement legacy relu depuis Hive avec id == null
      coffret.id = null;
      expect(coffret.id, isNull);

      // Première évaluation du getter equipmentId
      final id1 = coffret.equipmentId;
      expect(id1, startsWith('equip_'));

      // Deuxième évaluation (doit être STRICTEMENT identique)
      final id2 = coffret.equipmentId;
      expect(id2, equals(id1));
      expect(coffret.id, equals(id1));
    });

    test('2. ensureEquipmentIdentityAndNumber fixe un ID immuable de manière permanente', () {
      final coffret = CoffretArmoire(
        qrCode: 'ARM_100',
        nom: 'Armoire Climatisation',
        type: 'ARMOIRE',
      );

      EquipmentNumberService.ensureEquipmentIdentityAndNumber('mission_123', coffret);

      expect(coffret.id, isNotNull);
      expect(coffret.equipmentId, equals(coffret.id));
      expect(coffret.numeroEquipement, equals('1'));
    });

    test('3. Modification du nom conserve 100% des autres champs métier intacts', () {
      final alim = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5 mm²',
        marqueDisjoncteur: 'Schneider',
      );

      final original = CoffretArmoire(
        id: 'equip_fixed_999',
        qrCode: 'TGBT_01',
        nom: 'TGBT Ancien',
        type: 'TGBT',
        numeroEquipement: '42',
        repere: 'REP-01',
        accessible: true,
        presenceParafoudre: true,
        verificationThermographie: true,
        presenceDefautThermo: 'Non',
        alimentations: [alim],
      );

      // Modification uniquement du nom
      final updated = CoffretArmoire(
        id: original.equipmentId,
        qrCode: original.qrCode,
        nom: 'TGBT Nouveau Nom',
        type: original.type,
        numeroEquipement: original.numeroEquipement,
        repere: original.repere,
        accessible: original.accessible,
        presenceParafoudre: original.presenceParafoudre,
        verificationThermographie: original.verificationThermographie,
        presenceDefautThermo: original.presenceDefautThermo,
        alimentations: original.alimentations,
      );

      expect(updated.equipmentId, equals('equip_fixed_999'));
      expect(updated.nom, equals('TGBT Nouveau Nom'));
      expect(updated.numeroEquipement, equals('42'));
      expect(updated.repere, equals('REP-01'));
      expect(updated.type, equals('TGBT'));
      expect(updated.alimentations.first.marqueDisjoncteur, equals('Schneider'));
    });

    test('4. Non-régression pour le type Inverseur lors de la modification du nom', () {
      final inverseur = CoffretArmoire(
        id: 'inv_100',
        qrCode: 'INV_01',
        nom: 'Inverseur Normal/Secours',
        type: 'INVERSEUR',
        numeroEquipement: '5',
      );

      expect(inverseur.isDepartPrisAvecProtection, isTrue);

      inverseur.nom = 'Inverseur N/S Modifié';

      expect(inverseur.nom, equals('Inverseur N/S Modifié'));
      expect(inverseur.isDepartPrisAvecProtection, isTrue);
      expect(inverseur.equipmentId, equals('inv_100'));
    });
  });
}
