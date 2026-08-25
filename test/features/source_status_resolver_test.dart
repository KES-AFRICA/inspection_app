import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/core/utils/source_status_resolver.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/features/audit_installations/domain/entities/audit_installations_entities.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';

void main() {
  group('SourceStatusResolver — Tests fonctionnels & Rétrocompatibilité', () {
    test('1. Type de protection non renseigné (null ou vide) -> Source = Inconnue', () {
      expect(SourceStatusResolver.resolve(null), equals('Inconnue'));
      expect(SourceStatusResolver.resolve(''), equals('Inconnue'));
      expect(SourceStatusResolver.resolve('   '), equals('Inconnue'));
    });

    test('2. Type de protection = "-Aucun-" / "- Aucun -" / "aucun" -> Source = Inconnue', () {
      expect(SourceStatusResolver.resolve('-Aucun-'), equals('Inconnue'));
      expect(SourceStatusResolver.resolve('- Aucun -'), equals('Inconnue'));
      expect(SourceStatusResolver.resolve('aucun'), equals('Inconnue'));
      expect(SourceStatusResolver.resolve('-'), equals('Inconnue'));
      expect(SourceStatusResolver.resolve('N/A'), equals('Inconnue'));
    });

    test('3. Type de protection valide -> Source = Connue', () {
      expect(SourceStatusResolver.resolve('Disjoncteur'), equals('Connue'));
      expect(SourceStatusResolver.resolve('Sectionneur'), equals('Connue'));
      expect(SourceStatusResolver.resolve('Interrupteur'), equals('Connue'));
      expect(SourceStatusResolver.resolve('Interrupteur sectionneur'), equals('Connue'));
      expect(SourceStatusResolver.resolve('Interrupteur différentiel'), equals('Connue'));
      expect(SourceStatusResolver.resolve('Disjoncteur différentiel'), equals('Connue'));
      expect(SourceStatusResolver.resolve('Sectionneur porte-fusible'), equals('Connue'));
      expect(SourceStatusResolver.resolve('Coupe-circuit(porte-fusible)'), equals('Connue'));
    });

    test('4. Type de protection ancien ou non reconnu -> Source = Inconnue (pas de faux positif)', () {
      expect(SourceStatusResolver.resolve('invalide_test'), equals('Inconnue'));
      expect(SourceStatusResolver.resolve('xxx'), equals('Inconnue'));
      expect(SourceStatusResolver.resolve('???'), equals('Inconnue'));
    });

    test('5. Modèle Alimentation.effectiveSourceKnown dérive dynamiquement de typeProtection', () {
      final alim = Alimentation(
        typeProtection: '',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5',
      );

      // Initialement vide -> Inconnue
      expect(alim.effectiveSourceKnown, equals('Inconnue'));

      // Sélection d'un type de protection -> Connue
      alim.typeProtection = 'Disjoncteur différentiel';
      expect(alim.effectiveSourceKnown, equals('Connue'));

      // Retour à -Aucun- -> Inconnue
      alim.typeProtection = '-Aucun-';
      expect(alim.effectiveSourceKnown, equals('Inconnue'));
    });

    test('6. Entity AlimentationEntity.effectiveSourceKnown dérive dynamiquement de typeProtection', () {
      const entityNone = AlimentationEntity(
        typeProtection: '-Aucun-',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5',
      );
      expect(entityNone.effectiveSourceKnown, equals('Inconnue'));

      const entityKnown = AlimentationEntity(
        typeProtection: 'Disjoncteur',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5',
      );
      expect(entityKnown.effectiveSourceKnown, equals('Connue'));
    });

    test('7. Inverseur: Alimentation 1 et Alimentation 2 sont indépendantes', () {
      final coffretInverseur = CoffretArmoire(
        nom: 'Inverseur Normal/Secours',
        type: 'INVERSEUR',
        qrCode: 'QR_INV_01',
        alimentations: [
          Alimentation(
            typeProtection: 'Disjoncteur',
            pdcKA: '10',
            calibre: '32',
            sectionCable: '6',
          ),
          Alimentation(
            typeProtection: '-Aucun-',
            pdcKA: '10',
            calibre: '32',
            sectionCable: '6',
          ),
        ],
      );

      // Alimentation 1 a un disjoncteur -> Connue
      expect(coffretInverseur.alimentations[0].effectiveSourceKnown, equals('Connue'));
      // Alimentation 2 n'a aucune protection -> Inconnue
      expect(coffretInverseur.alimentations[1].effectiveSourceKnown, equals('Inconnue'));
    });

    test('8. Rétrocompatibilité ancienne mission: Protection renseignée + ancienne Source = Inconnue -> déduit Connue', () {
      final legacyAlim = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5',
        sourceKnown: 'Inconnue', // Ancienne valeur incohérente
      );

      // La nouvelle règle déduit 'Connue' d'après le type de protection récurant
      expect(legacyAlim.effectiveSourceKnown, equals('Connue'));
    });

    test('9. Rétrocompatibilité ancienne mission: Protection vide + ancienne Source = Connue -> déduit Inconnue', () {
      final legacyAlim = Alimentation(
        typeProtection: '',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5',
        sourceKnown: 'Connue', // Ancienne valeur incohérente
      );

      // La nouvelle règle déduit 'Inconnue' car aucune protection n'est présente
      expect(legacyAlim.effectiveSourceKnown, equals('Inconnue'));
    });

    test('10. Mapper AuditInstallationsMapper préserve et synchronise effectiveSourceKnown', () {
      final model = Alimentation(
        typeProtection: 'Sectionneur',
        pdcKA: '20',
        calibre: '63',
        sectionCable: '16',
      );

      final entity = AuditInstallationsMapper.toAlimentationEntity(model);
      expect(entity.effectiveSourceKnown, equals('Connue'));

      final convertedModel = AuditInstallationsMapper.toAlimentationModel(entity);
      expect(convertedModel.effectiveSourceKnown, equals('Connue'));
    });
  });
}
