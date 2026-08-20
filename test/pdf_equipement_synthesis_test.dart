import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/cellule_types_registry.dart';

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

    test('2. Préservation des références normatives sur ObservationLibre', () {
      final obs = ObservationLibre(
        texte: 'Présence d\'une porte pleine munie d\'anti-panique',
        referenceNormative: 'NF C 15-100-1:2024 art 462',
        criticite: 'Haute',
        isAutoLinked: true,
      );

      expect(obs.hasNormativeReference, isTrue);
      expect(obs.referenceNormative, equals('NF C 15-100-1:2024 art 462'));
      expect(obs.criticite, equals('Haute'));
      expect(obs.isAutoLinked, isTrue);
    });

    test('3. Registre autonome des types de cellule & proprietes de cellule', () {
      final typesOfficiels = CelluleTypesRegistry.typesOfficiels;
      expect(typesOfficiels.length, equals(14));
      expect(typesOfficiels.contains('DM1 : Disjoncteur + protection'), isTrue);

      final legacyTypes = CelluleTypesRegistry.getAvailableTypes('AncienTypeRM6');
      expect(legacyTypes.contains('AncienTypeRM6'), isTrue);

      final cellule = Cellule(
        fonction: 'Arrivée HTA',
        type: 'DM1 : Disjoncteur + protection',
        marqueModeleAnnee: 'Schneider 2024',
        tensionAssignee: '24',
        pouvoirCoupure: '16',
        numerotation: 'CEL-01',
        parafoudres: 'Non',
        tensionService: '20',
        calibreDisjoncteur: '630',
        elementsVerifies: [],
      );

      expect(cellule.tensionService, equals('20'));
      expect(cellule.calibreDisjoncteur, equals('630'));
    });
  });
}
