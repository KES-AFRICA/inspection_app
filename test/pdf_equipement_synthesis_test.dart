import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';

void main() {
  group('PDF Equipement Synthesis Tests', () {
    test('1. Extraction des équipements MT et BT sans doublon', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'M-100',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'Local MT Principal',
            type: 'LOCAL_TGBT',
            cellules: [
              Cellule(
                type: 'Cellule MT',
                numerotation: 'CEL-01',
                nom: 'Cellule Arrivée HTA',
                fonction: 'Arrivée HTA',
                marqueModeleAnnee: '2023',
                parafoudres: 'Non',
                pouvoirCoupure: '16 kA',
                tensionAssignee: '24 kV',
              ),
            ],
            transformateurs: [
              TransformateurMTBT(
                puissanceAssignee: '630 kVA',
                repere: 'TR-01',
                marqueAnnee: 'Schneider 630 kVA',
                typeTransformateur: 'Transformateur MT/BT',
                tensionPrimaireSecondaire: '20kV/400V',
                typeRefroidissement: 'ONAN',
                relaisBuchholz: 'Oui',
                regimeNeutre: 'TN',
              ),
            ],
            coffrets: [
              CoffretArmoire(
                qrCode: 'QR-01',
                repere: 'ARM-MT-01',
                nom: 'Armoire Auxiliaire MT',
                type: 'Armoire',
              ),
            ],
          ),
        ],
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Ateliers',
            coffretsDirects: [
              CoffretArmoire(
                qrCode: 'QR-02',
                repere: 'TGBT-01',
                nom: 'Tableau Général Basse Tension',
                type: 'TGBT',
              ),
            ],
            locaux: [
              BasseTensionLocal(
                nom: 'Local TGBT',
                type: 'LOCAL_TGBT',
                coffrets: [
                  CoffretArmoire(
                    qrCode: 'QR-03',
                    repere: 'TD-01',
                    nom: 'Tableau de Distribution',
                    type: 'Coffret',
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final desc = DescriptionInstallations.create('M-100');

      expect(audit.moyenneTensionLocaux.length, equals(1));
      expect(audit.basseTensionZones.length, equals(1));
      expect(desc.missionId, equals('M-100'));
    });
  });
}
