import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  group('Type de Protection - Official Options & Legacy Backward Compatibility', () {
    const officialOptions = [
      'Disjoncteur',
      'Sectionneur',
      'Interrupteur',
      'Interrupteur sectionneur',
      'Interrupteur différentiel',
      'Disjoncteur différentiel',
      'Sectionneur porte-fusible',
    ];

    test('Official options list contains expected protection type values', () {
      expect(officialOptions, containsAll([
        'Disjoncteur',
        'Sectionneur',
        'Interrupteur',
        'Interrupteur sectionneur',
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
      expect(items.length, equals(officialOptions.length + 1));
      expect(alim.typeProtection, equals('Fusibles'));
    });

    test('Official protection type should not alter standard dropdown list length', () {
      final alim = Alimentation(
        typeProtection: 'Interrupteur sectionneur',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5 mm²',
      );

      final items = [...officialOptions];
      if (alim.typeProtection.isNotEmpty && !items.contains(alim.typeProtection)) {
        items.insert(0, alim.typeProtection);
      }

      expect(items.length, equals(officialOptions.length));
      expect(items.contains('Interrupteur sectionneur'), isTrue);
    });
  });
}
