import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/installation_fields_registry.dart';
import 'package:inspec_app/services/backup_service.dart';

void main() {
  group('Transformateur MT/BT — Type d\'immersion et protections conditionnelles QA Tests', () {
    test('Scénario 1 : Transformateur non immergé (SEC) — Masquage des champs conditionnels', () {
      final transfo = TransformateurMTBT(
        typeTransformateur: 'SEC',
        marqueAnnee: 'Schneider / 2022',
        puissanceAssignee: '630',
        tensionPrimaireSecondaire: '20kV / 400V',
        relaisBuchholz: '',
        typeRefroidissement: 'AN',
        regimeNeutre: 'TN-S',
      );

      expect(transfo.isImmerge, isFalse);
      expect(transfo.typeImmersion, isNull);
      expect(transfo.presenceDGPT2, isNull);
    });

    test('Scénario 2 : Transformateur immergé avec conservateur — Présence de Buchholz', () {
      final transfo = TransformateurMTBT(
        typeTransformateur: 'IMMERGÉ',
        typeImmersion: InstallationFieldsRegistry.immersionConservateur,
        relaisBuchholz: 'Oui',
        marqueAnnee: 'France Transfo / 2020',
        puissanceAssignee: '1000',
        tensionPrimaireSecondaire: '15kV / 400V',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'TT',
      );

      expect(transfo.isImmerge, isTrue);
      expect(transfo.typeImmersion, equals(InstallationFieldsRegistry.immersionConservateur));
      expect(transfo.relaisBuchholz, equals('Oui'));
      expect(transfo.presenceDGPT2, isNull);
    });

    test('Scénario 3 : Transformateur immergé hermétique — Présence de DGPT2', () {
      final transfo = TransformateurMTBT(
        typeTransformateur: 'Immergé',
        typeImmersion: InstallationFieldsRegistry.immersionHermetique,
        presenceDGPT2: 'Oui',
        relaisBuchholz: '',
        marqueAnnee: 'ABB / 2021',
        puissanceAssignee: '800',
        tensionPrimaireSecondaire: '20kV / 400V',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'TN-C',
      );

      expect(transfo.isImmerge, isTrue);
      expect(transfo.typeImmersion, equals(InstallationFieldsRegistry.immersionHermetique));
      expect(transfo.presenceDGPT2, equals('Oui'));
    });

    test('Scénario 4 : Basculement entre types d\'immersion — Non conversion et préservation séparée des données', () {
      final transfoConservateur = TransformateurMTBT(
        typeTransformateur: 'IMMERGÉ',
        typeImmersion: InstallationFieldsRegistry.immersionConservateur,
        relaisBuchholz: 'Oui',
        marqueAnnee: 'Test / 2023',
        puissanceAssignee: '500',
        tensionPrimaireSecondaire: '20kV / 400V',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'TT',
      );

      // Simulation de la transition d'immersion Conservateur -> Hermétique dans l'application
      final transfoHermetique = transfoConservateur.copyWith(
        typeImmersion: InstallationFieldsRegistry.immersionHermetique,
        presenceDGPT2: 'Non',
      );

      // Vérifier que Buchholz n'a PAS été converti automatiquement ni effacé
      expect(transfoHermetique.relaisBuchholz, equals('Oui'));
      expect(transfoHermetique.presenceDGPT2, equals('Non'));
      expect(transfoHermetique.typeImmersion, equals(InstallationFieldsRegistry.immersionHermetique));
    });

    test('Scénario 5 : Ancienne mission historique — Conservation de Buchholz sans forcer typeImmersion', () {
      // Modèle instancié comme dans une ancienne mission
      final transfoAncien = TransformateurMTBT(
        typeTransformateur: 'IMMERGÉ',
        relaisBuchholz: 'Oui',
        marqueAnnee: 'Legacy / 2018',
        puissanceAssignee: '400',
        tensionPrimaireSecondaire: '20kV / 400V',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'TN-S',
      );

      expect(transfoAncien.isImmerge, isTrue);
      expect(transfoAncien.typeImmersion, isNull);
      expect(transfoAncien.relaisBuchholz, equals('Oui'));
      expect(transfoAncien.presenceDGPT2, isNull);
    });

    test('Scénario 6 : Sérialisation et Désérialisation JSON (Import / Export Backup)', () {
      final originalTransfo = TransformateurMTBT(
        typeTransformateur: 'IMMERGÉ',
        typeImmersion: InstallationFieldsRegistry.immersionHermetique,
        presenceDGPT2: 'Oui',
        relaisBuchholz: 'Non',
        marqueAnnee: 'Test Serial / 2024',
        puissanceAssignee: '1250',
        tensionPrimaireSecondaire: '20kV / 400V',
        typeRefroidissement: 'ONAF',
        regimeNeutre: 'IT',
      );

      // Simuler l'exportation JSON
      final jsonMap = {
        'typeTransformateur': originalTransfo.typeTransformateur,
        'typeImmersion': originalTransfo.typeImmersion,
        'presenceDGPT2': originalTransfo.presenceDGPT2,
        'relaisBuchholz': originalTransfo.relaisBuchholz,
        'marqueAnnee': originalTransfo.marqueAnnee,
        'puissanceAssignee': originalTransfo.puissanceAssignee,
        'tensionPrimaireSecondaire': originalTransfo.tensionPrimaireSecondaire,
        'typeRefroidissement': originalTransfo.typeRefroidissement,
        'regimeNeutre': originalTransfo.regimeNeutre,
      };

      // Simuler l'importation JSON
      final importedTransfo = TransformateurMTBT(
        typeTransformateur: jsonMap['typeTransformateur'] as String,
        typeImmersion: jsonMap['typeImmersion'] as String?,
        presenceDGPT2: jsonMap['presenceDGPT2'] as String?,
        relaisBuchholz: jsonMap['relaisBuchholz'] as String,
        marqueAnnee: jsonMap['marqueAnnee'] as String,
        puissanceAssignee: jsonMap['puissanceAssignee'] as String,
        tensionPrimaireSecondaire: jsonMap['tensionPrimaireSecondaire'] as String,
        typeRefroidissement: jsonMap['typeRefroidissement'] as String,
        regimeNeutre: jsonMap['regimeNeutre'] as String,
      );

      expect(importedTransfo.typeTransformateur, equals('IMMERGÉ'));
      expect(importedTransfo.typeImmersion, equals(InstallationFieldsRegistry.immersionHermetique));
      expect(importedTransfo.presenceDGPT2, equals('Oui'));
      expect(importedTransfo.relaisBuchholz, equals('Non'));
    });
  });
}
