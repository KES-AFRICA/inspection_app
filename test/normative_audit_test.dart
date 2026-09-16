import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/utils/normative_reference_cleaner.dart';

void main() {
  test('Test NormativeReferenceCleaner on real user and registry cases', () {
    // 1. The exact case from user photo
    expect(
      NormativeReferenceCleaner.clean('NF C 15-100-1:2024 - art 411, selon la mesure de protection retenue'),
      equals('NF C 15-100-1:2024 - art 411'),
    );

    // 2. Case with multiple parts and explanatory clauses
    expect(
      NormativeReferenceCleaner.clean('NF C 15-100-1:2024 – art 411, selon la mesure de protection retenue ; art 512.2 pour les influences externes'),
      equals('NF C 15-100-1:2024 – art 411 ; art 512.2'),
    );

    // 3. Parenthetical comment
    expect(
      NormativeReferenceCleaner.clean('NF C 15-100-1:2024 – art 434 et art 533 (pouvoir de coupure à vérifier par rapport au courant de court-circuit présumé)'),
      equals('NF C 15-100-1:2024 – art 434 et art 533'),
    );

    // 4. Prescriptions du fabricant
    expect(
      NormativeReferenceCleaner.clean('NF C 15-100-1:2024 – art 551 et prescriptions du fabricant'),
      equals('NF C 15-100-1:2024 – art 551'),
    );

    // 5. Norme prefix and parenthetical MT comment
    expect(
      NormativeReferenceCleaner.clean('Norme NF C 13-200 (règles de distances de sécurité MT)'),
      equals('NF C 13-200'),
    );

    // 6. Norme prefix with article
    expect(
      NormativeReferenceCleaner.clean('Norme NF C 13-100 art 412'),
      equals('NF C 13-100 – art 412'),
    );

    // 7. Legitimate complex reference preserved
    expect(
      NormativeReferenceCleaner.clean('NF C 13-100:2015 – art 624 ; NF C 13-200:2009 – art 624 ; NF C 18-510'),
      equals('NF C 13-100:2015 – art 624 ; NF C 13-200:2009 – art 624 ; NF C 18-510'),
    );

    // 8. Trailing comma with general descriptive commentary
    expect(
      NormativeReferenceCleaner.clean('NF C 15-100-1:2024 – art 411, avec coupure automatique'),
      equals('NF C 15-100-1:2024 – art 411'),
    );

    // 9. Pure explanatory text string should result in '-'
    expect(
      NormativeReferenceCleaner.clean('les exigences détaillées de la notice technique'),
      equals('-'),
    );
  });
}
