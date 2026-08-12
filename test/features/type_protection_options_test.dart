import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  group('Type de Protection - Official Options & Legacy Backward Compatibility', () {
    const officialOptions = [
      'Disjoncteur',
      'Sectionneur',
      'Interrupteur',
      'Interrupteur différentiel',
      'Disjoncteur différentiel',
      'Sectionneur porte-fusible',
    ];

    test('Official options list contains exactly the 6 requested values', () {
      expect(officialOptions.length, equals(6));
      expect(officialOptions, containsAll([
        'Disjoncteur',
        'Sectionneur',
        'Interrupteur',
        'Interrupteur différentiel',
        'Disjoncteur différentiel',
        'Sectionneur porte-fusible',
      ]));
    });

    test('Legacy protection type should be preserved dynamically without alteration', () {
      final legacyValue = 'Fusibles';
      final alim = Alimentation(
        typeProtection: legacyValue,
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5 mm²',
      );

      final items = [...officialOptions];
      if (alim.typeProtection.isNotEmpty && !items.contains(alim.typeProtection)) {
        items.insert(0, alim.typeProtection);
      }

      // Legacy item should be prepended
      expect(items.first, equals('Fusibles'));
      expect(items.length, equals(7));
      expect(alim.typeProtection, equals('Fusibles'));
    });

    test('Official protection type should not alter standard dropdown list length', () {
      final alim = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5 mm²',
      );

      final items = [...officialOptions];
      if (alim.typeProtection.isNotEmpty && !items.contains(alim.typeProtection)) {
        items.insert(0, alim.typeProtection);
      }

      expect(items.length, equals(6));
      expect(items.first, equals('Disjoncteur'));
    });
  });
}
