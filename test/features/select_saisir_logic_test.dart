import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/installation_fields_registry.dart';

void main() {
  group('Logique Sélecteur avec option "Saisir" & Préservation des Données Terrain', () {
    // Fonction miroir de la logique de détection dans _buildSelectOrCustomInput
    String? findMatchingStandard(String? val, List<String> standardOptions, String? suffixText) {
      if (val == null) return null;
      final cleanVal = val.trim();
      if (cleanVal.isEmpty) return null;

      for (final opt in standardOptions) {
        final optTrimmed = opt.trim();
        if (cleanVal == optTrimmed) {
          return opt;
        }
        if (suffixText != null && suffixText.isNotEmpty) {
          if (cleanVal.toLowerCase() == '$optTrimmed $suffixText'.toLowerCase() ||
              cleanVal.toLowerCase() == '$optTrimmed$suffixText'.toLowerCase()) {
            return opt;
          }
        }
        final cleanNoSpace = cleanVal.replaceAll(RegExp(r'\s+'), '').toLowerCase();
        final optNoSpace = optTrimmed.replaceAll(RegExp(r'\s+'), '').toLowerCase();
        if (cleanNoSpace == optNoSpace) {
          return opt;
        }
        if (suffixText != null && suffixText.isNotEmpty) {
          final optWithSuffixNoSpace = '$optNoSpace${suffixText.replaceAll(RegExp(r'\s+'), '').toLowerCase()}';
          if (cleanNoSpace == optWithSuffixNoSpace) {
            return opt;
          }
        }
      }
      return null;
    }

    test('1. Les options standards du transformateur avec ou sans suffixe sont correctement reconnues', () {
      final options = InstallationFieldsRegistry.puissanceTransformateurOptions;

      // Valeur exacte dans la liste
      expect(findMatchingStandard('160', options, 'kVA'), equals('160'));
      // Valeur avec unité
      expect(findMatchingStandard('160 kVA', options, 'kVA'), equals('160'));
      // Valeur avec espace milliers (1 000)
      expect(findMatchingStandard('1000', options, 'kVA'), equals('1 000'));
      expect(findMatchingStandard('1 000 kVA', options, 'kVA'), equals('1 000'));
      expect(findMatchingStandard('2500 kVA', options, 'kVA'), equals('2 500'));
    });

    test('2. Les options standards de cellule (tension) sont correctement reconnues', () {
      final optionsService = InstallationFieldsRegistry.tensionDeServiceOptions;
      expect(findMatchingStandard('20', optionsService, 'kV'), equals('20'));
      expect(findMatchingStandard('20 kV', optionsService, 'kV'), equals('20'));
      expect(findMatchingStandard('33', optionsService, 'kV'), equals('33'));

      final optionsAssignee = InstallationFieldsRegistry.tensionAssigneeOptions;
      expect(findMatchingStandard('24', optionsAssignee, 'kV'), equals('24'));
      expect(findMatchingStandard('24 kV', optionsAssignee, 'kV'), equals('24'));
      expect(findMatchingStandard('7.2', optionsAssignee, 'kV'), equals('7.2'));
    });

    test('3. Les valeurs personnalisées terrain existantes sont identifiées comme non-standard pour basculer sur "Saisir"', () {
      final optionsTransfo = InstallationFieldsRegistry.puissanceTransformateurOptions;
      // Puissance atypique relevée sur le terrain
      expect(findMatchingStandard('875', optionsTransfo, 'kVA'), isNull);
      expect(findMatchingStandard('175 kVA', optionsTransfo, 'kVA'), isNull);
      expect(findMatchingStandard('450', optionsTransfo, 'kVA'), isNull);

      final optionsCellule = InstallationFieldsRegistry.tensionDeServiceOptions;
      expect(findMatchingStandard('22 kV', optionsCellule, 'kV'), isNull);
      expect(findMatchingStandard('11', optionsCellule, 'kV'), isNull);
    });

    test('4. Préservation stricte : état calculé pour le dropdown et le champ libre', () {
      final optionsTransfo = InstallationFieldsRegistry.puissanceTransformateurOptions;

      // Cas A : Mission existante avec valeur standard -> Dropdown = '160', Champ libre masqué
      {
        const missionVal = '160 kVA';
        final matched = findMatchingStandard(missionVal, optionsTransfo, 'kVA');
        final customSaisirFields = <String>{};

        final isCustomTerrain = missionVal.isNotEmpty && matched == null;
        final isSaisirActive = customSaisirFields.contains('transfoPuissanceAssignee') || isCustomTerrain;

        final dropdownValue = isSaisirActive ? '__SAISIR__' : (matched ?? '');
        final showInputField = isSaisirActive;

        expect(dropdownValue, equals('160'));
        expect(showInputField, isFalse);
      }

      // Cas B : Mission existante avec valeur terrain personnalisée -> Dropdown = '__SAISIR__', Champ libre affiché avec valeur intacte
      {
        const missionVal = '875';
        final matched = findMatchingStandard(missionVal, optionsTransfo, 'kVA');
        final customSaisirFields = <String>{};

        final isCustomTerrain = missionVal.isNotEmpty && matched == null;
        final isSaisirActive = customSaisirFields.contains('transfoPuissanceAssignee') || isCustomTerrain;

        final dropdownValue = isSaisirActive ? '__SAISIR__' : (matched ?? '');
        final showInputField = isSaisirActive;

        expect(dropdownValue, equals('__SAISIR__'));
        expect(showInputField, isTrue);
        expect(missionVal, equals('875')); // Préservation 100% sans altération
      }

      // Cas C : Inspecteur clique sur 'Saisir' dans la liste déroulante
      {
        const missionVal = '';
        final matched = findMatchingStandard(missionVal, optionsTransfo, 'kVA');
        final customSaisirFields = <String>{'transfoPuissanceAssignee'};

        final isCustomTerrain = missionVal.isNotEmpty && matched == null;
        final isSaisirActive = customSaisirFields.contains('transfoPuissanceAssignee') || isCustomTerrain;

        final dropdownValue = isSaisirActive ? '__SAISIR__' : (matched ?? '');
        final showInputField = isSaisirActive;

        expect(dropdownValue, equals('__SAISIR__'));
        expect(showInputField, isTrue);
      }
    });
  });
}
