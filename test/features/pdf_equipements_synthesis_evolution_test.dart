// test/features/pdf_equipements_synthesis_evolution_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_report_service.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  setUp(() {
    PdfReportService.initFontsForTesting();
  });

  group('Évolution Synthèse des Équipements — Validation des Nouvelles Règles MT/BT', () {
    test('TEST 1 — MT pur : Cellules et Transformateurs apparaissent uniquement en MT avec Nom réel et Type générique', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'm_mt_pur',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'LOCAL TRANSFO 01',
            type: 'Local MT',
            dispositionsConstructives: [],
            conditionsExploitation: [],
            cellules: [
              Cellule(
                fonction: 'Arrivée IM',
                type: 'IM',
                marqueModeleAnnee: 'Schneider',
                tensionAssignee: '20kV',
                pouvoirCoupure: '16kA',
                numerotation: 'C01',
                parafoudres: 'Oui',
                nom: 'Cellule Arrivée',
              ),
            ],
            transformateurs: [
              TransformateurMTBT(
                typeTransformateur: 'Triphasé',
                marqueAnnee: 'France Transfo',
                puissanceAssignee: '630kVA',
                tensionPrimaireSecondaire: '20kV/400V',
                relaisBuchholz: 'Oui',
                typeRefroidissement: 'ONAN',
                regimeNeutre: 'TN-S',
                nom: 'Transfo T1',
              ),
            ],
          ),
        ],
      );

      final mtItems = PdfReportService.collectEquipementsMTForTesting(audit);
      final btItems = PdfReportService.getEquipementsBTForTesting(audit, null);

      expect(mtItems.length, equals(2));
      // Équipement = Nom réel enregistré
      expect(mtItems[0].nom, equals('Cellule Arrivée'));
      expect(mtItems[0].localName, equals('LOCAL TRANSFO 01'));
      // Type = Catégorie générique 'Cellule'
      expect(mtItems[0].type, equals('Cellule'));

      // Équipement = Nom réel enregistré
      expect(mtItems[1].nom, equals('Transfo T1'));
      expect(mtItems[1].localName, equals('LOCAL TRANSFO 01'));
      // Type = Catégorie générique 'Transformateur'
      expect(mtItems[1].type, equals('Transformateur'));

      expect(btItems.isEmpty, isTrue);
    });

    test('TEST 2 — BT pur : TGBT, Inverseur, Armoire, Coffret apparaissent uniquement en BT', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'm_bt_pur',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Atelier',
            locaux: [
              BasseTensionLocal(
                nom: 'TGBT Local',
                type: 'Local Technique',
                dispositionsConstructives: [],
                conditionsExploitation: [],
                coffrets: [
                  CoffretArmoire(qrCode: 'Q1', repere: 'TGBT-01', nom: 'TGBT Principal', type: 'TGBT'),
                  CoffretArmoire(qrCode: 'Q2', repere: 'INV-01', nom: 'Inverseur Normal/Secours', type: 'INVERSEUR'),
                  CoffretArmoire(qrCode: 'Q3', repere: 'ARM-01', nom: 'Armoire Atelier', type: 'ARMOIRE_ELECTRIQUE'),
                  CoffretArmoire(qrCode: 'Q4', repere: 'COF-01', nom: 'Coffret Prises', type: 'COFFRET_ELECTRIQUE'),
                ],
              ),
            ],
          ),
        ],
      );

      final mtItems = PdfReportService.collectEquipementsMTForTesting(audit);
      final btItems = PdfReportService.getEquipementsBTForTesting(audit, null);

      expect(mtItems.isEmpty, isTrue);
      expect(btItems.length, equals(4));
      expect(btItems[0].type, equals('TGBT'));
      expect(btItems[1].type, equals('Inverseur'));
      expect(btItems[2].type, equals('Armoire'));
      expect(btItems[3].type, equals('Coffret'));
    });

    test('TEST 3 — Local MT mixte (MT + BT) : Cellule/Transfo vont en MT, TGBT/Armoire vont en BT avec le même local', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'm_mixte',
        updatedAt: DateTime.now(),
        moyenneTensionZones: [
          MoyenneTensionZone(
            nom: 'Poste Électrique',
            locaux: [
              MoyenneTensionLocal(
                nom: 'LOCAL MT 01',
                type: 'Poste HT',
                dispositionsConstructives: [],
                conditionsExploitation: [],
                cellules: [
                  Cellule(
                    fonction: 'Protection Transfo',
                    type: 'QM',
                    marqueModeleAnnee: 'Schneider',
                    tensionAssignee: '20kV',
                    pouvoirCoupure: '16kA',
                    numerotation: 'C1',
                    parafoudres: 'Non',
                    nom: 'Cellule MT',
                  ),
                ],
                transformateurs: [
                  TransformateurMTBT(
                    typeTransformateur: 'Sec',
                    marqueAnnee: 'ABB',
                    puissanceAssignee: '1000kVA',
                    tensionPrimaireSecondaire: '20kV/400V',
                    relaisBuchholz: 'Non',
                    typeRefroidissement: 'AN',
                    regimeNeutre: 'TT',
                    nom: 'Transformateur 1',
                  ),
                ],
                coffrets: [
                  CoffretArmoire(qrCode: 'Q10', repere: 'TGBT-01', nom: 'TGBT Général', type: 'TGBT'),
                  CoffretArmoire(qrCode: 'Q11', repere: 'ARM-01', nom: 'Armoire Services Auxiliaires', type: 'ARMOIRE_ELECTRIQUE'),
                ],
              ),
            ],
          ),
        ],
      );

      final mtItems = PdfReportService.collectEquipementsMTForTesting(audit);
      final btItems = PdfReportService.getEquipementsBTForTesting(audit, null);

      // MT : Cellule et Transformateur
      expect(mtItems.length, equals(2));
      expect(mtItems[0].nom, equals('Cellule MT'));
      expect(mtItems[0].type, equals('Cellule'));
      expect(mtItems[0].localName, equals('LOCAL MT 01'));
      expect(mtItems[0].zoneName, equals('Poste Électrique'));
      expect(mtItems[1].nom, equals('Transformateur 1'));
      expect(mtItems[1].type, equals('Transformateur'));
      expect(mtItems[1].localName, equals('LOCAL MT 01'));
      expect(mtItems[1].zoneName, equals('Poste Électrique'));

      // BT : TGBT et Armoire du local MT !
      expect(btItems.length, equals(2));
      expect(btItems[0].nom, equals('TGBT Général'));
      expect(btItems[0].localName, equals('LOCAL MT 01'));
      expect(btItems[0].zoneName, equals('Poste Électrique'));
      expect(btItems[1].nom, equals('Armoire Services Auxiliaires'));
      expect(btItems[1].localName, equals('LOCAL MT 01'));
      expect(btItems[1].zoneName, equals('Poste Électrique'));
    });

    test('TEST 4 — Local MT ne contenant que des équipements BT (POSTE MT 02)', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'm_local_mt_only_bt',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'POSTE MT 02',
            type: 'Poste HT',
            dispositionsConstructives: [],
            conditionsExploitation: [],
            coffrets: [
              CoffretArmoire(qrCode: 'Q20', repere: 'TGBT-02', nom: 'TGBT 2', type: 'TGBT'),
              CoffretArmoire(qrCode: 'Q21', repere: 'ARM-02', nom: 'Armoire 2', type: 'ARMOIRE_ELECTRIQUE'),
            ],
          ),
        ],
      );

      final mtItems = PdfReportService.collectEquipementsMTForTesting(audit);
      final btItems = PdfReportService.getEquipementsBTForTesting(audit, null);

      expect(mtItems.isEmpty, isTrue); // Pas de lignes vides en MT !
      expect(btItems.length, equals(2));
      expect(btItems[0].localName, equals('POSTE MT 02'));
      expect(btItems[1].localName, equals('POSTE MT 02'));
    });
  });
}
