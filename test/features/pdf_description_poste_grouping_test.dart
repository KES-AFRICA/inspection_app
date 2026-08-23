import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/pdf/installation_description_pdf_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Description des Installations — Poste / Local Grouping Tests', () {
    test('Should associate MT cellules with their parent local name properly', () {
      final cellule1 = Cellule(
        syncId: 'cell_001',
        type: 'Arrivée',
        fonction: 'Arrivée MT',
        marqueModeleAnnee: 'SCHNEIDER 2020',
        tensionAssignee: '24',
        pouvoirCoupure: '12.5',
        numerotation: '1',
        parafoudres: 'Non',
      );
      final cellule2 = Cellule(
        syncId: 'cell_002',
        type: 'Protection',
        fonction: 'Protection Transfo',
        marqueModeleAnnee: 'SCHNEIDER 2020',
        tensionAssignee: '24',
        pouvoirCoupure: '12.5',
        numerotation: '2',
        parafoudres: 'Non',
      );
      final cellule3 = Cellule(
        syncId: 'cell_003',
        type: 'Départ',
        fonction: 'Départ Boucle',
        marqueModeleAnnee: 'SCHNEIDER 2020',
        tensionAssignee: '24',
        pouvoirCoupure: '12.5',
        numerotation: '3',
        parafoudres: 'Non',
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'mission_group_mt_test',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'POSTE MT PRINCIPAL',
            type: 'Local MT',
            cellules: [cellule1, cellule2],
          ),
          MoyenneTensionLocal(
            nom: 'POSTE SECONDAIRE USINE',
            type: 'Local MT',
            cellules: [cellule3],
          ),
        ],
      );

      final pdfData = InstallationDescriptionPdfData.fromDescription(desc: null, audit: audit);

      expect(pdfData.mtRows.length, equals(3));

      // 1. Cellule 1 dans POSTE MT PRINCIPAL
      expect(pdfData.mtRows[0].rawId, equals('cell_001'));
      expect(pdfData.mtRows[0].localName, equals('POSTE MT PRINCIPAL'));

      // 2. Cellule 2 dans POSTE MT PRINCIPAL
      expect(pdfData.mtRows[1].rawId, equals('cell_002'));
      expect(pdfData.mtRows[1].localName, equals('POSTE MT PRINCIPAL'));

      // 3. Cellule 3 dans POSTE SECONDAIRE USINE
      expect(pdfData.mtRows[2].rawId, equals('cell_003'));
      expect(pdfData.mtRows[2].localName, equals('POSTE SECONDAIRE USINE'));
    });

    test('Should associate BT transformateurs with their parent local name properly', () {
      final transfo1 = TransformateurMTBT(
        syncId: 'transfo_001',
        marqueAnnee: 'SCHNEIDER 2020',
        puissanceAssignee: '630',
        typeTransformateur: 'Huile',
        tensionPrimaireSecondaire: '20/0.4',
        relaisBuchholz: 'Non',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'TN-S',
      );
      final transfo2 = TransformateurMTBT(
        syncId: 'transfo_002',
        marqueAnnee: 'FRANCE TRANSFO 2022',
        puissanceAssignee: '1000',
        typeTransformateur: 'Sec',
        tensionPrimaireSecondaire: '20/0.4',
        relaisBuchholz: 'Non',
        typeRefroidissement: 'AN',
        regimeNeutre: 'TN-S',
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'mission_group_bt_test',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'LOCAL TRANSFO 1',
            type: 'Local MT/BT',
            transformateurs: [transfo1],
          ),
          MoyenneTensionLocal(
            nom: 'LOCAL TRANSFO 2',
            type: 'Local MT/BT',
            transformateurs: [transfo2],
          ),
        ],
      );

      final pdfData = InstallationDescriptionPdfData.fromDescription(desc: null, audit: audit);

      expect(pdfData.btRows.length, equals(2));

      expect(pdfData.btRows[0].rawId, equals('transfo_001'));
      expect(pdfData.btRows[0].localName, equals('LOCAL TRANSFO 1'));

      expect(pdfData.btRows[1].rawId, equals('transfo_002'));
      expect(pdfData.btRows[1].localName, equals('LOCAL TRANSFO 2'));
    });

    test('Should preserve original creation order when building pdfData from DescriptionInstallations', () {
      final desc = DescriptionInstallations.create('mission_order_test');

      final date1 = DateTime(2026, 1, 10);
      final date2 = DateTime(2026, 1, 12);

      desc.alimentationMoyenneTension = [
        InstallationItem(
          createdAt: date2,
          data: {
            'auditCelluleId': 'cell_b',
            'TYPE DE CELLULE': 'Protection',
          },
        ),
        InstallationItem(
          createdAt: date1,
          data: {
            'auditCelluleId': 'cell_a',
            'TYPE DE CELLULE': 'Arrivée',
          },
        ),
      ];

      final audit = AuditInstallationsElectriques(
        missionId: 'mission_order_test',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'POSTE MT',
            type: 'Local MT',
            cellules: [
              Cellule(
                syncId: 'cell_a',
                type: 'Arrivée',
                fonction: 'Arrivée MT',
                marqueModeleAnnee: 'SCHNEIDER 2020',
                tensionAssignee: '24',
                pouvoirCoupure: '12.5',
                numerotation: '1',
                parafoudres: 'Non',
              ),
              Cellule(
                syncId: 'cell_b',
                type: 'Protection',
                fonction: 'Protection Transfo',
                marqueModeleAnnee: 'SCHNEIDER 2020',
                tensionAssignee: '24',
                pouvoirCoupure: '12.5',
                numerotation: '2',
                parafoudres: 'Non',
              ),
            ],
          ),
        ],
      );

      final pdfData = InstallationDescriptionPdfData.fromDescription(desc: desc, audit: audit);

      expect(pdfData.mtRows.length, equals(2));
      // First row must be cell_a (date1), second must be cell_b (date2)
      expect(pdfData.mtRows[0].rawId, equals('cell_a'));
      expect(pdfData.mtRows[1].rawId, equals('cell_b'));
      expect(pdfData.mtRows[0].localName, equals('POSTE MT'));
      expect(pdfData.mtRows[1].localName, equals('POSTE MT'));
    });
  });
}
