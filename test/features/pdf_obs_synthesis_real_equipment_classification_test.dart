import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

void main() {
  setUp(() {
    PdfReportService.initFontsForTesting();
  });

  group('Classification des observations de la synthèse récapitulative par type réel d\'équipement', () {
    test('1. Local MT contenant à la fois des équipements MT et BT (ex: Poste électrique A)', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'm_mixed_local',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'Poste électrique A',
            type: 'Technique',
            cellules: [
              Cellule(
                type: 'Arrivée',
                fonction: 'Arrivée 20kV',
                marqueModeleAnnee: 'Schneider 2020',
                tensionAssignee: '24kV',
                pouvoirCoupure: '25kA',
                numerotation: '1',
                parafoudres: 'Non',
                elementsVerifies: [
                  ElementControle(elementControle: 'Propreté cellule', conforme: false, observation: 'Cellule à nettoyer'),
                ],
              ),
            ],
            transformateurs: [
              TransformateurMTBT(
                typeTransformateur: 'Huile',
                marqueAnnee: 'France Transfo 2018',
                puissanceAssignee: '1000kVA',
                tensionPrimaireSecondaire: '20kV/400V',
                relaisBuchholz: 'Oui',
                typeRefroidissement: 'ONAN',
                regimeNeutre: 'TN-S',
                elementsVerifies: [
                  ElementControle(elementControle: 'Niveau huile', conforme: false, observation: 'Fuite huile transfo'),
                ],
              ),
            ],
            coffrets: [
              CoffretArmoire(
                nom: 'TGBT 1',
                type: 'TGBT',
                qrCode: 'QR_TGBT_1',
                pointsVerification: [
                  PointVerification(
                    pointVerification: 'Serrage bornes',
                    conformite: 'Non conforme',
                    observation: 'Serrage TGBT à revoir',
                  ),
                ],
              ),
              CoffretArmoire(
                nom: 'Inverseur 1',
                type: 'Inverseur',
                qrCode: 'QR_INV_1',
                pointsVerification: [
                  PointVerification(
                    pointVerification: 'Commutation auto',
                    conformite: 'Non conforme',
                    observation: 'Défaut inverseur',
                  ),
                ],
              ),
              CoffretArmoire(
                nom: 'Armoire Éclairage',
                type: 'Armoire',
                qrCode: 'QR_ARM_1',
                pointsVerification: [
                  PointVerification(
                    pointVerification: 'Etiquetage',
                    conformite: 'Non conforme',
                    observation: 'Armoire sans étiquette',
                  ),
                ],
              ),
              CoffretArmoire(
                nom: 'Coffret Prises',
                type: 'Coffret',
                qrCode: 'QR_COF_1',
                pointsVerification: [
                  PointVerification(
                    pointVerification: 'Obturateur',
                    conformite: 'Non conforme',
                    observation: 'Coffret sans obturateur',
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final obsMT = PdfReportService.collectObservationsMTForTesting(audit);
      final obsBT = PdfReportService.collectObservationsBTForTesting(audit);

      // Moyenne tension doit contenir uniquement la Cellule et le Transformateur
      final mtEquipmentNames = obsMT.map((o) => o.coffret).toList();
      expect(mtEquipmentNames, contains('Cellule 1 — Arrivée 20kV'));
      expect(mtEquipmentNames, contains('Transformateur 1'));
      expect(mtEquipmentNames, isNot(contains('TGBT 1')));
      expect(mtEquipmentNames, isNot(contains('Inverseur 1')));
      expect(mtEquipmentNames, isNot(contains('Armoire Éclairage')));
      expect(mtEquipmentNames, isNot(contains('Coffret Prises')));

      // Basse tension doit contenir le TGBT, l'Inverseur, l'Armoire et le Coffret sous 'Poste électrique A'
      final btEquipmentNames = obsBT.map((o) => o.coffret).toList();
      expect(btEquipmentNames, contains('TGBT 1'));
      expect(btEquipmentNames, contains('Inverseur 1'));
      expect(btEquipmentNames, contains('Armoire Éclairage'));
      expect(btEquipmentNames, contains('Coffret Prises'));
      expect(btEquipmentNames, isNot(contains('Cellule 1 — Arrivée 20kV')));
      expect(btEquipmentNames, isNot(contains('Transformateur 1')));

      // Les deux sous-sections référencent 'Poste électrique A'
      expect(obsMT.first.localisation, equals('Poste électrique A'));
      expect(obsBT.first.localisation, equals('Poste électrique A'));
    });
  });
}
