import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/features/audit_installations/domain/entities/audit_installations_entities.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';
import 'package:inspec_app/services/backup_service.dart';

void main() {
  group('Évolution Équipements — Source connue/inconnue & Départ sans protection', () {
    test('1. Source connue/inconnue : Rétrocompatibilité (null -> Connue)', () {
      final legacyAlim = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5 mm²',
        source: 'TGBT RDC',
        sourceKnown: null,
      );

      expect(legacyAlim.sourceKnown, isNull);
      expect(legacyAlim.effectiveSourceKnown, equals('Connue'));
    });

    test('2. Source connue/inconnue : Modification et persistance de Inconnue', () {
      final unknownAlim = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '6',
        calibre: '10',
        sectionCable: '1.5 mm²',
        sourceKnown: 'Inconnue',
      );

      expect(unknownAlim.sourceKnown, equals('Inconnue'));
      expect(unknownAlim.effectiveSourceKnown, equals('Inconnue'));

      // Test Mapper Clean Architecture
      final entity = AuditInstallationsMapper.toAlimentationEntity(unknownAlim);
      expect(entity.sourceKnown, equals('Inconnue'));

      final remapModel = AuditInstallationsMapper.toAlimentationModel(entity);
      expect(remapModel.sourceKnown, equals('Inconnue'));
      expect(remapModel.effectiveSourceKnown, equals('Inconnue'));
    });

    test('3. Départ pris avec protection : Rétrocompatibilité (null -> true)', () {
      final legacyCoffret = CoffretArmoire(
        qrCode: 'COFF_001',
        nom: 'Coffret Éclairage',
        type: 'COFFRET',
        departPrisAvecProtection: null,
      );

      expect(legacyCoffret.departPrisAvecProtection, isNull);
      expect(legacyCoffret.isDepartPrisAvecProtection, isTrue);
    });

    test('4. Départ pris avec protection : Inverseur toujours avec protection (true)', () {
      final inverseur = CoffretArmoire(
        qrCode: 'INV_001',
        nom: 'Inverseur Normal/Secours',
        type: 'INVERSEUR',
        departPrisAvecProtection: false, // Même si mis à false, l'Inverseur doit rester isDepartPrisAvecProtection == true
      );

      expect(inverseur.isDepartPrisAvecProtection, isTrue);
    });

    test('5. Non-destruction des données lors du passage à sans protection', () {
      final protData = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '15',
        calibre: '32',
        sectionCable: '6 mm²',
      );

      final coffret = CoffretArmoire(
        qrCode: 'ARM_100',
        nom: 'Armoire Climatisation',
        type: 'ARMOIRE',
        protectionTete: protData,
        departPrisAvecProtection: true,
      );

      expect(coffret.isDepartPrisAvecProtection, isTrue);
      expect(coffret.protectionTete, isNotNull);
      expect(coffret.protectionTete!.calibre, equals('32'));

      // Desactivation du switch "Départ pris avec protection"
      coffret.departPrisAvecProtection = false;

      expect(coffret.isDepartPrisAvecProtection, isFalse);
      // Les données de protection doivent TOUJOURS subsister intactes dans le modèle
      expect(coffret.protectionTete, isNotNull);
      expect(coffret.protectionTete!.calibre, equals('32'));
      expect(coffret.protectionTete!.pdcKA, equals('15'));

      // Reactivation du switch
      coffret.departPrisAvecProtection = true;
      expect(coffret.isDepartPrisAvecProtection, isTrue);
      expect(coffret.protectionTete!.calibre, equals('32'));
    });

    test('6. Backup JSON Import/Export Roundtrip de sourceKnown & departPrisAvecProtection', () {
      final alim = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '25',
        calibre: '63',
        sectionCable: '16 mm²',
        sourceKnown: 'Inconnue',
      );

      final coffret = CoffretArmoire(
        qrCode: 'TGBT_MAIN',
        nom: 'TGBT Principal',
        type: 'TGBT',
        alimentations: [alim],
        protectionTete: Alimentation(
          typeProtection: 'Interrupteur sectionneur',
          pdcKA: '50',
          calibre: '250',
          sectionCable: '95 mm²',
        ),
        departPrisAvecProtection: false,
      );

      final serialized = {
        'typeProtection': alim.typeProtection,
        'courbe': alim.courbe,
        'ddr': alim.ddr,
        'pdcKA': alim.pdcKA,
        'calibre': alim.calibre,
        'sectionCable': alim.sectionCable,
        'source': alim.source,
        'sourceKnown': alim.sourceKnown,
        'photos': alim.photos,
      };

      expect(serialized['sourceKnown'], equals('Inconnue'));

      final entity = AuditInstallationsMapper.toCoffretEntity(coffret);
      expect(entity.departPrisAvecProtection, isFalse);
      expect(entity.alimentations.first.sourceKnown, equals('Inconnue'));
    });
  });
}
