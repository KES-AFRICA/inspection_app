import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  group('Départ pris sans protection - Logique automatique', () {
    test('Par défaut, si le type de protection est vide ou "-aucun-", isDepartPrisAvecProtection est false (Départ sans protection = Oui)', () {
      final protData = Alimentation(
        typeProtection: '',
        pdcKA: '',
        calibre: '',
        sectionCable: '',
      );

      final coffret = CoffretArmoire(
        qrCode: 'COFFRET_TEST',
        nom: 'Coffret Test',
        type: 'COFFRET',
        protectionTete: protData,
        departPrisAvecProtection: false,
      );

      expect(coffret.isDepartPrisAvecProtection, isFalse);
      expect(coffret.protectionTete!.typeProtection, isEmpty);
    });

    test('Sélection d\'un type de protection valide fait passer isDepartPrisAvecProtection à true (Départ sans protection = Non)', () {
      final protData = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5 mm²',
      );

      final coffret = CoffretArmoire(
        qrCode: 'COFFRET_TEST',
        nom: 'Coffret Test',
        type: 'COFFRET',
        protectionTete: protData,
        departPrisAvecProtection: true,
      );

      expect(coffret.isDepartPrisAvecProtection, isTrue);
      expect(coffret.protectionTete!.typeProtection, 'Disjoncteur');
    });

    test('Changement du type de protection vers "-aucun-" remet isDepartPrisAvecProtection à false (Départ sans protection = Oui)', () {
      final protData = Alimentation(
        typeProtection: '-aucun-',
        pdcKA: '',
        calibre: '',
        sectionCable: '',
      );

      final coffret = CoffretArmoire(
        qrCode: 'COFFRET_TEST',
        nom: 'Coffret Test',
        type: 'COFFRET',
        protectionTete: protData,
        departPrisAvecProtection: false,
      );

      expect(coffret.isDepartPrisAvecProtection, isFalse);
      expect(coffret.protectionTete!.typeProtection, '-aucun-');
    });
  });
}
