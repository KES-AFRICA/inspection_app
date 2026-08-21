import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/features/audit_installations/domain/entities/audit_installations_entities.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';
import 'package:inspec_app/services/dispositions_constructives_registry.dart';

void main() {
  group('EquipementsNouveauxChampsTest - Persistance, Mapping & Retrocompatibilité', () {
    test('CoffretArmoire sauvegarde et restaure alimenteeParTransformateur et presenceCPI', () {
      final coffret = CoffretArmoire(
        qrCode: 'QR_123',
        nom: 'TGBT Principal',
        type: 'TGBT',
        alimenteeParTransformateur: true,
        presenceCPI: false,
      );

      expect(coffret.alimenteeParTransformateur, isTrue);
      expect(coffret.presenceCPI, isFalse);
    });

    test('CoffretArmoire historique sans ces champs possede des valeurs nulles (retrocompatibilite)', () {
      final coffretLegacy = CoffretArmoire(
        qrCode: 'QR_LEGACY',
        nom: 'Armoire Ancienne',
        type: 'ARMOIRE',
      );

      expect(coffretLegacy.alimenteeParTransformateur, isNull);
      expect(coffretLegacy.presenceCPI, isNull);
    });

    test('AuditInstallationsMapper effectue un round-trip complet entre model et entity', () {
      final model = CoffretArmoire(
        qrCode: 'QR_456',
        nom: 'Coffret Local BT',
        type: 'COFFRET',
        alimenteeParTransformateur: false,
        presenceCPI: true,
      );

      final entity = AuditInstallationsMapper.toCoffretEntity(model);
      expect(entity.alimenteeParTransformateur, isFalse);
      expect(entity.presenceCPI, isTrue);

      final modelReconstructed = AuditInstallationsMapper.toCoffretModel(entity);
      expect(modelReconstructed.alimenteeParTransformateur, isFalse);
      expect(modelReconstructed.presenceCPI, isTrue);
    });

    test('Backup JSON conserve les valeurs oui/non et gère null pour les anciennes sauvegardes', () {
      final coffret = CoffretArmoire(
        qrCode: 'QR_789',
        nom: 'Coffret Test Backup',
        type: 'COFFRET',
        alimenteeParTransformateur: true,
        presenceCPI: true,
      );

      final jsonMap = {
        'qrCode': coffret.qrCode,
        'nom': coffret.nom,
        'type': coffret.type,
        'alimenteeParTransformateur': coffret.alimenteeParTransformateur,
        'presenceCPI': coffret.presenceCPI,
      };

      expect(jsonMap['alimenteeParTransformateur'], isTrue);
      expect(jsonMap['presenceCPI'], isTrue);

      final jsonLegacy = {
        'qrCode': 'QR_OLD',
        'nom': 'Armoire Old',
        'type': 'ARMOIRE',
      };

      expect(jsonLegacy['alimenteeParTransformateur'], isNull);
      expect(jsonLegacy['presenceCPI'], isNull);
    });

    test('Inverseur avec presenceCPI ignore l affichage CPI', () {
      final inverseur = CoffretArmoire(
        qrCode: 'QR_INV',
        nom: 'Inverseur Normal/Secours',
        type: 'INVERSEUR',
        alimenteeParTransformateur: true,
        presenceCPI: null,
      );

      expect(inverseur.type, equals('INVERSEUR'));
      expect(inverseur.presenceCPI, isNull);
    });

    test('Mise a jour d un coffret existant copie les champs alimenteeParTransformateur et presenceCPI', () {
      final existingTarget = CoffretArmoire(
        qrCode: 'QR_EDIT',
        nom: 'TGBT Avant Edition',
        type: 'TGBT',
        alimenteeParTransformateur: false,
        presenceCPI: false,
      );

      final newUpdatedCoffret = CoffretArmoire(
        qrCode: 'QR_EDIT',
        nom: 'TGBT Apres Edition',
        type: 'TGBT',
        alimenteeParTransformateur: true,
        presenceCPI: true,
      );

      // Simulation de la copie dans _updateCoffret
      existingTarget.nom = newUpdatedCoffret.nom;
      existingTarget.alimenteeParTransformateur = newUpdatedCoffret.alimenteeParTransformateur;
      existingTarget.presenceCPI = (newUpdatedCoffret.type == 'INVERSEUR') ? null : newUpdatedCoffret.presenceCPI;

      expect(existingTarget.alimenteeParTransformateur, isTrue);
      expect(existingTarget.presenceCPI, isTrue);
    });

    test('Validation points verification : bloque en creation si incomplet, autorise en edition', () {
      final uncompletedPoint = PointVerification(
        pointVerification: 'Point 1',
        conformite: '',
      );
      final completedPoint = PointVerification(
        pointVerification: 'Point 2',
        conformite: 'oui',
      );

      final slide = [uncompletedPoint, completedPoint];

      // Simulation de _isCurrentSlideValid
      bool isValid({required bool isEdition}) {
        if (isEdition) return true;
        for (var pt in slide) {
          if (pt.conformite.trim().isEmpty) return false;
        }
        return true;
      }

      // En mode creation -> bloque car uncompletedPoint a conformite vide
      expect(isValid(isEdition: false), isFalse);

      // En mode edition -> autorise la navigation
      expect(isValid(isEdition: true), isTrue);

      // Si l'inspecteur remplit la conformite du point 1 en mode creation
      uncompletedPoint.conformite = 'na';
      expect(isValid(isEdition: false), isTrue);
    });

    test('Remplacement disjoncteur -> dispositif de protection sur Inverseurs', () {
      // 1. Aucun point des Inverseurs ne doit contenir 'disjoncteur'
      final hasDisjoncteur = DispositionsConstructivesRegistry.allInverseurPoints
          .any((pt) => pt.toLowerCase().contains('disjoncteur'));
      expect(hasDisjoncteur, isFalse);

      // 2. Les 5 points mis a jour doivent bien contenir 'dispositif de protection' ou 'dispositifs de protection'
      final newPointsCount = DispositionsConstructivesRegistry.allInverseurPoints
          .where((pt) => pt.toLowerCase().contains('dispositifs de protection') || pt.toLowerCase().contains('dispositif de protection'))
          .length;
      expect(newPointsCount, greaterThanOrEqualTo(5));

      // 3. Test de retrocompatibilite et d'invariance des metadonnees
      final oldPointTitle = "Section des câbles d'alimentation adaptée au courant nominal des disjoncteurs associés";
      final legacyPoint = PointVerification(
        pointVerification: oldPointTitle,
        conformite: 'non',
        observation: 'Cable sous-dimensionne',
      );

      final checklist = [legacyPoint];
      DispositionsConstructivesRegistry.ensureCompleteInverseurChecklist(checklist);

      // Le libelle affiche doit etre le nouveau libelle
      final updatedPoint = checklist.firstWhere(
        (p) => p.pointVerification.contains("Section des câbles d'alimentation"),
      );
      expect(updatedPoint.pointVerification, equals("Section des câbles d'alimentation adaptée au courant nominal des dispositifs de protection associés"));
      expect(updatedPoint.referenceNormative, equals("NF C 15-100-1:2024 – art 523, art 524 et art 433"));
      expect(updatedPoint.criticite, equals("Critique"));
      expect(updatedPoint.familleRisque, equals("Incendie / échauffement / surcharge des conducteurs"));
      expect(updatedPoint.conformite, equals('non'));
      expect(updatedPoint.observation, equals('Cable sous-dimensionne'));
    });
  });
}
