import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/pdf/installation_description_pdf_data.dart';
import 'package:inspec_app/services/installation_description_sync_service.dart';

void main() {
  group('Audit & Resolution PDF Table Mapping (MT & BT)', () {
    test('Direct extraction from Cellule real entities into InstallationDescriptionPdfData', () {
      final audit = AuditInstallationsElectriques.create('mission_direct_cellules');
      final localMT = MoyenneTensionLocal(
        nom: 'Poste MT 1',
        type: 'LOCAL_TRANSFORMATEUR',
        cellules: [
          Cellule(
            fonction: 'Arrivée',
            type: 'IMB : interrupteur',
            marqueModeleAnnee: 'Schneider 2022',
            tensionAssignee: '24',
            pouvoirCoupure: '12.5',
            numerotation: 'C1',
            parafoudres: 'Non',
            sectionCables: '95',
            natureReseau: 'Souterrain',
            tensionService: '20',
            syncId: 'c1',
          ),
          Cellule(
            fonction: 'Protection',
            type: 'IM',
            marqueModeleAnnee: 'Schneider 2021',
            tensionAssignee: '17.5',
            pouvoirCoupure: '16',
            numerotation: 'C2',
            parafoudres: 'Oui',
            sectionCables: '70',
            natureReseau: 'Aérien',
            tensionService: '15',
            syncId: 'c2',
          ),
          Cellule(
            fonction: 'Comptage',
            type: 'QM',
            marqueModeleAnnee: 'ABB 2023',
            tensionAssignee: '36',
            pouvoirCoupure: '25',
            numerotation: 'C3',
            parafoudres: 'Non',
            sectionCables: '120',
            natureReseau: 'Souterrain',
            tensionService: '30',
            syncId: 'c3',
          ),
        ],
      );
      audit.moyenneTensionLocaux.add(localMT);

      final pdfData = InstallationDescriptionPdfData.fromDescription(desc: null, audit: audit);

      // Vérifier les 3 cellules MT extraites directement depuis l'entité audit
      expect(pdfData.mtRows.length, 3);

      final row1 = pdfData.mtRows[0];
      expect(row1.getValueForColumn('TYPE DE CELLULE', 'MT'), 'IMB : interrupteur');
      expect(row1.getValueForColumn('TENSION ASSIGNEE(KV)', 'MT'), '24');
      expect(row1.getValueForColumn('POUVOIR DE COUPURE ASSIGNE(KA)', 'MT'), '12.5');
      expect(row1.getValueForColumn('SECTION DU CABLE(mm2)', 'MT'), '95');
      expect(row1.getValueForColumn('NATURE DU RESEAU', 'MT'), 'Souterrain');
      expect(row1.getValueForColumn('TENSION DE SERVICE (kV)', 'MT'), '20');

      final row2 = pdfData.mtRows[1];
      expect(row2.getValueForColumn('TYPE DE CELLULE', 'MT'), 'IM');
      expect(row2.getValueForColumn('TENSION ASSIGNEE(KV)', 'MT'), '17.5');
      expect(row2.getValueForColumn('POUVOIR DE COUPURE ASSIGNE(KA)', 'MT'), '16');
      expect(row2.getValueForColumn('SECTION DU CABLE(mm2)', 'MT'), '70');
      expect(row2.getValueForColumn('NATURE DU RESEAU', 'MT'), 'Aérien');
      expect(row2.getValueForColumn('TENSION DE SERVICE (kV)', 'MT'), '15');

      final row3 = pdfData.mtRows[2];
      expect(row3.getValueForColumn('TYPE DE CELLULE', 'MT'), 'QM');
      expect(row3.getValueForColumn('TENSION ASSIGNEE(KV)', 'MT'), '36');
      expect(row3.getValueForColumn('POUVOIR DE COUPURE ASSIGNE(KA)', 'MT'), '25');
      expect(row3.getValueForColumn('SECTION DU CABLE(mm2)', 'MT'), '120');
      expect(row3.getValueForColumn('NATURE DU RESEAU', 'MT'), 'Souterrain');
      expect(row3.getValueForColumn('TENSION DE SERVICE (kV)', 'MT'), '30');
    });

    test('Strict filtering out of orphan items: 3 active cellules produce 3 PDF rows', () {
      final audit = AuditInstallationsElectriques.create('mission_strict_filter');
      final c1 = Cellule(fonction: 'Arrivée', type: 'IM', marqueModeleAnnee: 'Schneider', numerotation: '1', parafoudres: 'Non', syncId: 'cell_active_1', tensionAssignee: '24', pouvoirCoupure: '12.5');
      final c2 = Cellule(fonction: 'Départ', type: 'QM', marqueModeleAnnee: 'Schneider', numerotation: '2', parafoudres: 'Non', syncId: 'cell_active_2', tensionAssignee: '17.5', pouvoirCoupure: '16');
      final c3 = Cellule(fonction: 'Protection', type: 'DM1', marqueModeleAnnee: 'Schneider', numerotation: '3', parafoudres: 'Non', syncId: 'cell_active_3', tensionAssignee: '36', pouvoirCoupure: '25');

      audit.moyenneTensionLocaux.add(
        MoyenneTensionLocal(nom: 'Local MT', type: 'LOCAL_MT', cellules: [c1, c2, c3]),
      );

      final desc = DescriptionInstallations.create('mission_strict_filter');
      desc.alimentationMoyenneTension = [
        // 3 synced items linked to active cellules
        InstallationItem(
          data: {'auditCelluleId': 'cell_active_1', 'TYPE DE CELLULE': 'IM'},
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        InstallationItem(
          data: {'auditCelluleId': 'cell_active_2', 'TYPE DE CELLULE': 'QM'},
          createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
        InstallationItem(
          data: {'auditCelluleId': 'cell_active_3', 'TYPE DE CELLULE': 'DM1'},
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        // 2 orphan items (deleted equipment or manual)
        InstallationItem(
          data: {'auditCelluleId': 'cell_orphan_old_1', 'TYPE DE CELLULE': 'OLD_1'},
          createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
        ),
        InstallationItem(
          data: {'auditCelluleId': 'cell_orphan_old_2', 'TYPE DE CELLULE': 'OLD_2'},
          createdAt: DateTime.now().subtract(const Duration(minutes: 50)),
        ),
      ];

      final pdfData = InstallationDescriptionPdfData.fromDescription(desc: desc, audit: audit);

      // PDF must render EXACTLY 3 rows for active equipment, ignoring orphan items!
      expect(pdfData.mtRows.length, 3);
      expect(pdfData.mtRows[0].getValueForColumn('TYPE DE CELLULE', 'MT'), 'IM');
      expect(pdfData.mtRows[1].getValueForColumn('TYPE DE CELLULE', 'MT'), 'QM');
      expect(pdfData.mtRows[2].getValueForColumn('TYPE DE CELLULE', 'MT'), 'DM1');
    });

    test('Strict ordering in PDF matching desc list order (oldest to newest)', () {
      final audit = AuditInstallationsElectriques.create('mission_ordering');
      final c1 = Cellule(fonction: 'Arrivée', type: 'IM', marqueModeleAnnee: 'Schneider', numerotation: '1', parafoudres: 'Non', syncId: 'cell_1', tensionAssignee: '24', pouvoirCoupure: '12.5');
      final c2 = Cellule(fonction: 'Protection', type: 'QM', marqueModeleAnnee: 'Schneider', numerotation: '2', parafoudres: 'Non', syncId: 'cell_2', tensionAssignee: '17.5', pouvoirCoupure: '16');

      audit.moyenneTensionLocaux.add(
        MoyenneTensionLocal(nom: 'Local MT', type: 'LOCAL_MT', cellules: [c1, c2]),
      );

      final desc = DescriptionInstallations.create('mission_ordering');
      final t1 = DateTime.now().subtract(const Duration(hours: 2));
      final t2 = DateTime.now().subtract(const Duration(hours: 1));

      desc.alimentationMoyenneTension = [
        InstallationItem(data: {'auditCelluleId': 'cell_1', 'TYPE DE CELLULE': 'IM'}, createdAt: t1),
        InstallationItem(data: {'auditCelluleId': 'cell_2', 'TYPE DE CELLULE': 'QM'}, createdAt: t2),
      ];

      final pdfData = InstallationDescriptionPdfData.fromDescription(desc: desc, audit: audit);

      expect(pdfData.mtRows.length, 2);
      expect(pdfData.mtRows[0].getValueForColumn('TYPE DE CELLULE', 'MT'), 'IM');
      expect(pdfData.mtRows[1].getValueForColumn('TYPE DE CELLULE', 'MT'), 'QM');
    });
  });
}
