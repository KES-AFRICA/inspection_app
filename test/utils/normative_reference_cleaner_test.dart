import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/utils/normative_reference_cleaner.dart';

void main() {
  group('NormativeReferenceCleaner', () {
    test('cleans explanatory parenthetical notes', () {
      expect(
        NormativeReferenceCleaner.clean('NF C 18-510 (complémentaire, non fournie)'),
        'NF C 18-510',
      );
      expect(
        NormativeReferenceCleaner.clean('NF C 15-100-1:2024 – art 6.5.1.2 ; NF C 18-510 (complémentaire, non fournie)'),
        'NF C 15-100-1:2024 – art 6.5.1.2 ; NF C 18-510',
      );
    });

    test('removes trailing non-normative comments preceded by semicolon', () {
      expect(
        NormativeReferenceCleaner.clean(
          'NF C 15-100-1:2024 – art 421, art 422 et art 513 ; exigences détaillées de porte coupe-feu à compléter par le référentiel bâtiment applicable',
        ),
        'NF C 15-100-1:2024 – art 421, art 422 et art 513',
      );
      expect(
        NormativeReferenceCleaner.clean(
          'NF C 15-100-1:2024 – art 421, art 422 et art 551 ; moyens d\'extinction à adapter au risque',
        ),
        'NF C 15-100-1:2024 – art 421, art 422 et art 551',
      );
      expect(
        NormativeReferenceCleaner.clean(
          'NF C 15-100-1:2024 – art 551 ; prescriptions du fabricant',
        ),
        'NF C 15-100-1:2024 – art 551',
      );
    });

    test('preserves legitimate multi-norm references separated by semicolon', () {
      expect(
        NormativeReferenceCleaner.clean(
          'NF C 13-100:2015 – art 722 et art 723 ; NF C 13-200:2009 – art 711',
        ),
        'NF C 13-100:2015 – art 722 et art 723 ; NF C 13-200:2009 – art 711',
      );
      expect(
        NormativeReferenceCleaner.clean(
          'NF C 15-100-1:2024 – art 514 ; NF C 18-510',
        ),
        'NF C 15-100-1:2024 – art 514 ; NF C 18-510',
      );
    });

    test('handles null, empty and clean references gracefully', () {
      expect(NormativeReferenceCleaner.clean(null), '-');
      expect(NormativeReferenceCleaner.clean(''), '-');
      expect(
        NormativeReferenceCleaner.clean('NF C 15-100-1:2024 – art 512.2'),
        'NF C 15-100-1:2024 – art 512.2',
      );
    });
  });
}
