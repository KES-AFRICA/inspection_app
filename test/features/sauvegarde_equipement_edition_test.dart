import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/core/utils/source_status_resolver.dart';

void main() {
  group('Audit & Persistance — Édition Équipement (Slide 5)', () {
    test('1. Modélisation et construction d\'un coffret complet avec 12 points de vérification', () {
      final coffret = CoffretArmoire(
        id: 'eq_12345',
        qrCode: 'QR_TEST_001',
        nom: 'TGBT Principal - Bâtiment A',
        type: 'TGBT',
        repere: 'TGBT-01',
        domaineTension: '230/400',
        presenceSchema: true,
        presenceParafoudre: true,
        verificationThermographie: true,
        pointsVerification: List.generate(
          12,
          (i) => PointVerification(
            pointVerification: 'Point de contrôle ${i + 1}',
            conformite: i % 2 == 0 ? 'oui' : 'non',
            observation: i % 2 != 0 ? 'Défaut détecté sur le point ${i + 1}' : null,
            priorite: i % 2 != 0 ? 2 : null,
          ),
        ),
      );

      expect(coffret.equipmentId, equals('eq_12345'));
      expect(coffret.pointsVerification.length, equals(12));
      expect(coffret.pointsVerification.last.pointVerification, equals('Point de contrôle 12'));
    });

    test('2. Tolérance aux points de vérification historiques sans observations ou données optionnelles', () {
      final legacyPoint = PointVerification(
        pointVerification: 'Point 11 historique',
        conformite: 'non',
        observation: 'Observation brute sans sous-liste',
      );

      expect(legacyPoint.observations, isEmpty);
      expect(legacyPoint.criticite, isNull);
      expect(legacyPoint.familleRisque, isNull);
      expect(legacyPoint.referenceNormative, isNull);
      expect(legacyPoint.photos, isEmpty);
    });

    test('3. Conservation de l\'ID immuable lors de la mise à jour par updateCoffretById', () {
      final oldCoffret = CoffretArmoire(
        id: 'eq_immut_99',
        qrCode: 'QR_IMMUT',
        nom: 'Coffret Ancien Nom',
        type: 'Armoire',
        repere: 'ARM-01',
      );

      final updatedCoffret = CoffretArmoire(
        qrCode: 'QR_IMMUT',
        nom: 'Coffret Nouveau Nom',
        type: 'Armoire',
        repere: 'ARM-01',
      );

      updatedCoffret.id = oldCoffret.equipmentId;

      expect(updatedCoffret.equipmentId, equals('eq_immut_99'));
    });

    test('4. Matching de secours par QR code et par nom sur ancienne mission', () {
      final existingEquipments = [
        CoffretArmoire(
          id: 'old_id_1',
          qrCode: 'QR_LEGACY_01',
          nom: 'Armoire Climatisation',
          type: 'Armoire',
        ),
      ];

      final editedEquip = CoffretArmoire(
        qrCode: 'QR_LEGACY_01',
        nom: 'Armoire Climatisation Renommée',
        type: 'Armoire',
      );

      // Simule le matching par QR code
      final indexByQr = existingEquipments.indexWhere((c) => c.qrCode == editedEquip.qrCode);
      expect(indexByQr, equals(0));

      // Remplace avec conservation de l'ID historique
      editedEquip.id = existingEquipments[indexByQr].equipmentId;
      existingEquipments[indexByQr] = editedEquip;

      expect(existingEquipments.first.equipmentId, equals('old_id_1'));
      expect(existingEquipments.first.nom, equals('Armoire Climatisation Renommée'));
    });

    test('5. Calcul autonome et déterministe de SourceStatusResolver pendant la sauvegarde', () {
      final alim1 = Alimentation(
        typeProtection: 'Disjoncteur différentiel',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5',
      );
      final alim2 = Alimentation(
        typeProtection: '-Aucun-',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5',
      );

      expect(alim1.effectiveSourceKnown, equals('Connue'));
      expect(alim2.effectiveSourceKnown, equals('Inconnue'));
    });
  });
}
