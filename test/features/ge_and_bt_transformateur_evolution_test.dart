import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/features/audit_installations/domain/entities/audit_installations_entities.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/builders/pdf_description_builder.dart';
import 'package:inspec_app/models/description_installations.dart';

void main() {
  group('Évolution GE et Liaison BT -> Transformateur MT', () {
    test('CoffretArmoire model supporte transformateurId et transformateurNomComplet', () {
      final coffret = CoffretArmoire(
        qrCode: 'QR123',
        nom: 'TGBT PRINCIPAL',
        type: 'TGBT',
        alimenteeParTransformateur: true,
        transformateurId: 'transfo_uuid_001',
        transformateurNomComplet: 'TR1 — 630 kVA',
      );

      expect(coffret.alimenteeParTransformateur, isTrue);
      expect(coffret.transformateurId, equals('transfo_uuid_001'));
      expect(coffret.transformateurNomComplet, equals('TR1 — 630 kVA'));
    });

    test('CoffretArmoireEntity et Mapper convertissent fidèlement transformateurId et transformateurNomComplet', () {
      final model = CoffretArmoire(
        qrCode: 'QR456',
        nom: 'ARMOIRE TD1',
        type: 'ARMOIRE',
        alimenteeParTransformateur: true,
        transformateurId: 'transfo_uuid_002',
        transformateurNomComplet: 'TR2 — 1000 kVA',
      );

      final entity = AuditInstallationsMapper.toCoffretEntity(model);
      expect(entity.alimenteeParTransformateur, isTrue);
      expect(entity.transformateurId, equals('transfo_uuid_002'));
      expect(entity.transformateurNomComplet, equals('TR2 — 1000 kVA'));

      final backToModel = AuditInstallationsMapper.toCoffretModel(entity);
      expect(backToModel.alimenteeParTransformateur, isTrue);
      expect(backToModel.transformateurId, equals('transfo_uuid_002'));
      expect(backToModel.transformateurNomComplet, equals('TR2 — 1000 kVA'));
    });

    test('MissionTransformateurOption formate correctement dropdownLabel (local - nom) et transformerName (nom seul)', () {
      final tWithNom = TransformateurMTBT(
        typeTransformateur: 'HUILE',
        marqueAnnee: 'SCHNEIDER 2020',
        puissanceAssignee: '630',
        tensionPrimaireSecondaire: '20kV / 400V',
        relaisBuchholz: 'Oui',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'TN-S',
        nom: 'TRANSFO USINE 1',
      );

      final optWithNom = MissionTransformateurOption(
        transformateur: tWithNom,
        localNom: 'POSTE MT PRINCIPAL',
        orderIndex: 1,
      );

      // Dans la liste déroulante : "le local - le nom du transfo"
      expect(optWithNom.dropdownLabel, equals('POSTE MT PRINCIPAL - TRANSFO USINE 1'));
      // Une fois sélectionné dans le champ : JUSTE le nom du transfo (pas le chemin)
      expect(optWithNom.transformerName, equals('TRANSFO USINE 1'));

      // Cas où le nom n'est PAS rempli : "transformateur x(numero d'ordre du transfo)+ sa tension KVA"
      final tWithoutNom = TransformateurMTBT(
        typeTransformateur: 'SEC',
        marqueAnnee: 'ABB 2018',
        puissanceAssignee: '1000 kVA',
        tensionPrimaireSecondaire: '20kV / 400V',
        relaisBuchholz: 'Non',
        typeRefroidissement: 'AN',
        regimeNeutre: 'IT',
        nom: null,
      );

      final optWithoutNom = MissionTransformateurOption(
        transformateur: tWithoutNom,
        localNom: 'POSTE SECONDAIRE',
        orderIndex: 2,
      );

      // Dans la liste déroulante : "le local - Transformateur x puissance"
      expect(optWithoutNom.dropdownLabel, equals('POSTE SECONDAIRE - Transformateur 2 1000 kVA'));
      // Dans le champ sélectionné : JUSTE "Transformateur 2 1000 kVA"
      expect(optWithoutNom.transformerName, equals('Transformateur 2 1000 kVA'));
    });

    test('PDF styles colonnes description des installations intègrent IDENTIFICATION et IDENTIFICATION DU GE', () {
      final groupeCols = PdfReportStyles.columnOrderBySection['GROUPE']!;
      expect(groupeCols.contains('IDENTIFICATION'), isTrue);
      expect(groupeCols.indexOf('IDENTIFICATION'), equals(1)); // Juste après N°

      final carbCols = PdfReportStyles.columnOrderBySection['CARBURANT']!;
      expect(carbCols.contains('IDENTIFICATION DU GE'), isTrue);
      expect(carbCols.indexOf('IDENTIFICATION DU GE'), equals(1)); // Juste après N°

      final invCols = PdfReportStyles.columnOrderBySection['INVERSEUR']!;
      expect(invCols.contains('IDENTIFICATION DU GE'), isTrue);
      expect(invCols.indexOf('IDENTIFICATION DU GE'), equals(1)); // Juste après N°
    });

    test('PDF tableaux des équipements BT ne sont PAS modifiés (exigence utilisateur)', () {
      // Les colonnes des tableaux d'équipements BT (TGBT, Armoire, etc.) dans l'audit doivent rester intactes
      expect(PdfReportStyles.columnOrderBySection.containsKey('TGBT'), isFalse);
      expect(PdfReportStyles.columnOrderBySection.containsKey('COFFRET'), isFalse);
    });

    test('PdfDescriptionBuilder résout dynamiquement le libellé du GE pour alimentation_carburant et inverseur', () {
      final ge1 = InstallationItem(
        id: 'ge_123',
        data: {
          'N°': '1',
          'Identification': 'GROUPE PRINCIPAL 800kVA',
          'Marque': 'CAT',
          'Puissance (Kva)': '800',
        },
      );

      final fuelItem = InstallationItem(
        id: 'fuel_1',
        data: {
          'N°': '1',
          'geId': 'ge_123',
          'Identification du GE': 'Historique fallback',
          'Capacité': '1000',
        },
      );

      final valResolved = PdfDescriptionBuilder.resolveInstallationValue(
        fuelItem,
        'IDENTIFICATION DU GE',
        'alimentation_carburant',
        allGes: [ge1],
      );

      expect(valResolved, equals('GROUPE PRINCIPAL 800kVA'));

      // Fallback si le GE est orphelin / supprimé
      final fuelItemOrphan = InstallationItem(
        id: 'fuel_2',
        data: {
          'N°': '2',
          'geId': 'ge_unknown',
          'Identification du GE': 'GE Ancien Libellé',
        },
      );

      final valFallback = PdfDescriptionBuilder.resolveInstallationValue(
        fuelItemOrphan,
        'IDENTIFICATION DU GE',
        'alimentation_carburant',
        allGes: [ge1],
      );

      expect(valFallback, equals('GE Ancien Libellé'));
    });
  });
}
