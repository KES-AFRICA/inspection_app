import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/features/audit_installations/domain/entities/audit_installations_entities.dart';

void main() {
  group('Évolution « Départ pris avec protection » — Tests de conformité métier', () {
    test('1. Nouvelle mission: Type de protection renseigné (Disjoncteur) -> Avec protection (true)', () {
      final coffret = CoffretArmoire(
        qrCode: 'QR_001',
        nom: 'TGBT Principal',
        type: 'TGBT',
        protectionTete: Alimentation(
          typeProtection: 'Disjoncteur',
          pdcKA: '25',
          calibre: '100',
          sectionCable: '35mm²',
        ),
      );

      expect(coffret.isDepartPrisAvecProtection, isTrue);
    });

    test('2. Nouvelle mission: Type de protection = "-Aucun-" -> Sans protection (false)', () {
      final coffret = CoffretArmoire(
        qrCode: 'QR_002',
        nom: 'Coffret Secondaire',
        type: 'Coffret',
        protectionTete: Alimentation(
          typeProtection: '-Aucun-',
          pdcKA: '',
          calibre: '',
          sectionCable: '10mm²',
        ),
      );

      expect(coffret.isDepartPrisAvecProtection, isFalse);
    });

    test('3. Nouvelle mission: Type de protection vide -> Sans protection (false)', () {
      final coffret = CoffretArmoire(
        qrCode: 'QR_003',
        nom: 'Armoire Machine',
        type: 'Armoire',
        protectionTete: Alimentation(
          typeProtection: '',
          pdcKA: '',
          calibre: '',
          sectionCable: '',
        ),
      );

      expect(coffret.isDepartPrisAvecProtection, isFalse);
    });

    test('4. Ancienne mission (departPrisAvecProtection == null): Type protection renseigné -> Avec protection (true)', () {
      final legacyCoffret = CoffretArmoire(
        qrCode: 'QR_LEGACY_1',
        nom: 'Ancien Coffret 1',
        type: 'Coffret',
        departPrisAvecProtection: null,
        protectionTete: Alimentation(
          typeProtection: 'Interrupteur',
          pdcKA: '',
          calibre: '',
          sectionCable: '16mm²',
        ),
      );

      expect(legacyCoffret.departPrisAvecProtection, isNull);
      expect(legacyCoffret.isDepartPrisAvecProtection, isTrue);
    });

    test('5. Ancienne mission: Type protection vide + Section de câble renseignée -> Sans protection (false - ne pas inventer de protection)', () {
      final legacyCoffret = CoffretArmoire(
        qrCode: 'QR_LEGACY_2',
        nom: 'Ancien Coffret 2',
        type: 'Coffret',
        departPrisAvecProtection: null,
        protectionTete: Alimentation(
          typeProtection: '',
          pdcKA: '',
          calibre: '',
          sectionCable: '25mm²',
        ),
      );

      expect(legacyCoffret.departPrisAvecProtection, isNull);
      expect(legacyCoffret.isDepartPrisAvecProtection, isFalse);
      expect(legacyCoffret.protectionTete?.sectionCable, equals('25mm²'));
    });

    test('6. Ancienne mission: Type protection = "-Aucun-" -> Sans protection (false)', () {
      final legacyCoffret = CoffretArmoire(
        qrCode: 'QR_LEGACY_3',
        nom: 'Ancien Coffret 3',
        type: 'Armoire',
        departPrisAvecProtection: null,
        protectionTete: Alimentation(
          typeProtection: '-Aucun-',
          pdcKA: '',
          calibre: '',
          sectionCable: '10mm²',
        ),
      );

      expect(legacyCoffret.isDepartPrisAvecProtection, isFalse);
    });

    test('7. Override manuel: Inspecteur force à Sans protection (false) sur Type protection = Disjoncteur', () {
      final coffret = CoffretArmoire(
        qrCode: 'QR_OVERRIDE_1',
        nom: 'Coffret Override',
        type: 'Coffret',
        departPrisAvecProtection: false, // Override manuel explicite
        protectionTete: Alimentation(
          typeProtection: 'Disjoncteur',
          pdcKA: '10',
          calibre: '63',
          sectionCable: '16mm²',
        ),
      );

      expect(coffret.departPrisAvecProtection, isFalse);
      expect(coffret.isDepartPrisAvecProtection, isFalse);
      expect(coffret.protectionTete?.typeProtection, equals('Disjoncteur'));
    });

    test('8. Override manuel: Inspecteur force à Avec protection (true) sur Type protection = "-Aucun-"', () {
      final coffret = CoffretArmoire(
        qrCode: 'QR_OVERRIDE_2',
        nom: 'Coffret Force True',
        type: 'Coffret',
        departPrisAvecProtection: true, // Override manuel explicite
        protectionTete: Alimentation(
          typeProtection: '-Aucun-',
          pdcKA: '',
          calibre: '',
          sectionCable: '',
        ),
      );

      expect(coffret.departPrisAvecProtection, isTrue);
      expect(coffret.isDepartPrisAvecProtection, isTrue);
    });

    test('9. Règle de l\'Inverseur: Toujours évalué à Avec protection (true) quelles que soient les valeurs', () {
      final inverseur1 = CoffretArmoire(
        qrCode: 'QR_INV_1',
        nom: 'Inverseur Normal',
        type: 'INVERSEUR',
        departPrisAvecProtection: false,
      );

      final inverseur2 = CoffretArmoire(
        qrCode: 'QR_INV_2',
        nom: 'Inverseur Legacy',
        type: 'INVERSEUR',
        departPrisAvecProtection: null,
      );

      expect(inverseur1.isDepartPrisAvecProtection, isTrue);
      expect(inverseur2.isDepartPrisAvecProtection, isTrue);
    });

    test('10. Entité Domain (CoffretArmoireEntity) conserve la même logique déterministe', () {
      const entityTrue = CoffretArmoireEntity(
        qrCode: 'QR_ENT_1',
        nom: 'Entity 1',
        type: 'TGBT',
        departPrisAvecProtection: null,
        protectionTete: AlimentationEntity(
          typeProtection: 'Disjoncteur',
          pdcKA: '',
          calibre: '',
          sectionCable: '',
        ),
      );

      const entityFalse = CoffretArmoireEntity(
        qrCode: 'QR_ENT_2',
        nom: 'Entity 2',
        type: 'TGBT',
        departPrisAvecProtection: null,
        protectionTete: AlimentationEntity(
          typeProtection: '',
          pdcKA: '',
          calibre: '',
          sectionCable: '',
        ),
      );

      expect(entityTrue.isDepartPrisAvecProtection, isTrue);
      expect(entityFalse.isDepartPrisAvecProtection, isFalse);
    });
  });
}
