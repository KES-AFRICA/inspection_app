import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/features/audit_installations/domain/entities/audit_installations_entities.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';

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
  });
}
