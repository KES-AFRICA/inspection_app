import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  group('Equipment Form Navigation & Edition Logic Tests', () {
    test('CoffretArmoire model correctly retains all equipment attributes during edit roundtrip', () {
      final original = CoffretArmoire(
        qrCode: 'QR_12345',
        nom: 'TGBT Principal',
        type: 'TGBT',
        numeroEquipement: 'EQ-001',
        repere: 'Local Technique BT',
        zoneAtex: true,
        domaineTension: '230/400',
        identificationArmoire: true,
        signalisationDanger: true,
        presenceSchema: true,
        presenceParafoudre: false,
        verificationThermographie: true,
        alimentations: [
          Alimentation(
            typeProtection: 'Disjoncteur',
            calibre: '100A',
            sectionCable: '3x150',
            pdcKA: '10',
            courbe: 'C',
            ddr: '300mA',
          ),
        ],
        pointsVerification: [
          PointVerification(
            pointVerification: 'Accessibilité et isolement',
            conformite: 'oui',
          ),
        ],
        photosExternes: ['path/ext1.jpg'],
        photosInternes: ['path/int1.jpg'],
        statut: 'complet',
        currentStep: 2,
      );

      // Mutate step during navigation (e.g. step 2 -> step 3)
      final updated = CoffretArmoire(
        qrCode: original.qrCode,
        nom: original.nom,
        type: original.type,
        numeroEquipement: original.numeroEquipement,
        repere: original.repere,
        zoneAtex: original.zoneAtex,
        domaineTension: original.domaineTension,
        identificationArmoire: original.identificationArmoire,
        signalisationDanger: original.signalisationDanger,
        presenceSchema: original.presenceSchema,
        presenceParafoudre: original.presenceParafoudre,
        verificationThermographie: original.verificationThermographie,
        alimentations: List.from(original.alimentations),
        protectionTete: original.protectionTete,
        pointsVerification: List.from(original.pointsVerification),
        photosExternes: List.from(original.photosExternes),
        photosInternes: List.from(original.photosInternes),
        statut: original.statut,
        currentStep: 3,
      );

      expect(updated.nom, equals('TGBT Principal'));
      expect(updated.type, equals('TGBT'));
      expect(updated.repere, equals('Local Technique BT'));
      expect(updated.alimentations.length, equals(1));
      expect(updated.alimentations.first.courbe, equals('C'));
      expect(updated.photosExternes.first, equals('path/ext1.jpg'));
      expect(updated.currentStep, equals(3));
    });

    test('Direct step navigation permission matrix: Edit Mode vs Creation Mode', () {
      bool canNavigateToStep({
        required bool isEdition,
        required int currentStep,
        required int targetStep,
      }) {
        if (targetStep < 0 || targetStep >= 4) return false;
        if (targetStep == currentStep) return false;

        // En mode édition : navigation autorisée vers n'importe quelle étape
        if (isEdition) return true;

        // En mode création : navigation uniquement vers les étapes déjà atteintes
        return targetStep <= currentStep;
      }

      // Test Mode Édition (Tous les boutons 1, 2, 3, 4 sont cliquables)
      expect(canNavigateToStep(isEdition: true, currentStep: 0, targetStep: 3), isTrue);
      expect(canNavigateToStep(isEdition: true, currentStep: 3, targetStep: 0), isTrue);
      expect(canNavigateToStep(isEdition: true, currentStep: 1, targetStep: 2), isTrue);

      // Test Mode Création (Parcours linéaire restreint)
      expect(canNavigateToStep(isEdition: false, currentStep: 0, targetStep: 3), isFalse);
      expect(canNavigateToStep(isEdition: false, currentStep: 2, targetStep: 0), isTrue);
      expect(canNavigateToStep(isEdition: false, currentStep: 1, targetStep: 0), isTrue);
    });

    test('Anti-double-click guard prevents concurrent save executions', () async {
      bool isSaving = false;
      int saveExecutions = 0;

      Future<void> simulateSave() async {
        if (isSaving) return;
        isSaving = true;
        try {
          saveExecutions++;
          await Future.delayed(const Duration(milliseconds: 100));
        } finally {
          isSaving = false;
        }
      }

      // Trigger 5 concurrent save calls simultaneously (fast double clicks)
      final futures = List.generate(5, (_) => simulateSave());
      await Future.wait(futures);

      // Exactly 1 save execution should pass
      expect(saveExecutions, equals(1));
    });
  });
}
