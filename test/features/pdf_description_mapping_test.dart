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

    test('Direct extraction from TransformateurMTBT real entities into InstallationDescriptionPdfData', () {
      final audit = AuditInstallationsElectriques.create('mission_direct_transfos');
      final localBT = MoyenneTensionLocal(
        nom: 'Local TGBT',
        type: 'LOCAL_TGBT',
        transformateurs: [
          TransformateurMTBT(
            typeTransformateur: 'SEC',
            marqueAnnee: 'France Transfo 2020',
            puissanceAssignee: '400',
            tensionPrimaireSecondaire: '15kV/400V',
            relaisBuchholz: 'Absent',
            typeRefroidissement: 'AN',
            regimeNeutre: 'TN-S',
            calibreDisjoncteur: '630',
            sectionCables: '95',
            intensiteNominale: '577',
            couplage: 'Dyn11',
            typeReseau: 'Réseau urbain',
            pccAmont: '500',
            puissanceUcc: '4 %',
            ik3Max: '13.92 kA',
          ),
          TransformateurMTBT(
            typeTransformateur: 'IMMERGÉ',
            marqueAnnee: 'Schneider 2022',
            puissanceAssignee: '630',
            tensionPrimaireSecondaire: '20kV/400V',
            relaisBuchholz: 'Présent',
            typeRefroidissement: 'ONAN',
            regimeNeutre: 'TT',
            calibreDisjoncteur: '1000',
            sectionCables: '240',
            intensiteNominale: '909.3',
            couplage: 'Dyn11',
            typeReseau: 'Poste source',
            pccAmont: '1000',
            puissanceUcc: '4 %',
            ik3Max: '21.55 kA',
          ),
        ],
      );
      audit.moyenneTensionLocaux.add(localBT);

      final pdfData = InstallationDescriptionPdfData.fromDescription(desc: null, audit: audit);

      // Vérifier les 2 transformateurs BT extraits directement depuis les entités réelles
      expect(pdfData.btRows.length, 2);

      final row1 = pdfData.btRows[0];
      expect(row1.getValueForColumn('PUISSANCE TRANSFORMATEUR (KVA)', 'BT'), '400');
      expect(row1.getValueForColumn('TYPE DE TRANSFORMATEUR', 'BT'), 'SEC');
      expect(row1.getValueForColumn('INTENSITE NOMINALE', 'BT'), '577');
      expect(row1.getValueForColumn('CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', 'BT'), '630');
      expect(row1.getValueForColumn('SECTION DU CABLE', 'BT'), '95');
      expect(row1.getValueForColumn('TENSION MT/BT', 'BT'), '15kV/400V');
      expect(row1.getValueForColumn('COUPLAGE', 'BT'), 'Dyn11');
      expect(row1.getValueForColumn('PCC AMONT EN MVA', 'BT'), '500');
      expect(row1.getValueForColumn('UCC EN %', 'BT'), '4 %');
      expect(row1.getValueForColumn('IK3 MAX(KA)', 'BT'), '13.92 kA');

      final row2 = pdfData.btRows[1];
      expect(row2.getValueForColumn('PUISSANCE TRANSFORMATEUR (KVA)', 'BT'), '630');
      expect(row2.getValueForColumn('TYPE DE TRANSFORMATEUR', 'BT'), 'IMMERGÉ');
      expect(row2.getValueForColumn('INTENSITE NOMINALE', 'BT'), '909.3');
      expect(row2.getValueForColumn('CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR', 'BT'), '1000');
      expect(row2.getValueForColumn('SECTION DU CABLE', 'BT'), '240');
      expect(row2.getValueForColumn('TENSION MT/BT', 'BT'), '20kV/400V');
      expect(row2.getValueForColumn('COUPLAGE', 'BT'), 'Dyn11');
      expect(row2.getValueForColumn('PCC AMONT EN MVA', 'BT'), '1000');
      expect(row2.getValueForColumn('UCC EN %', 'BT'), '4 %');
      expect(row2.getValueForColumn('IK3 MAX(KA)', 'BT'), '21.55 kA');
    });

    test('Fallback to manual / legacy DescriptionInstallations items', () {
      final desc = DescriptionInstallations.create('mission_legacy');
      desc.alimentationMoyenneTension = [
        InstallationItem(
          data: {
            'Type De Cellule': 'IM',
            'Tension de service': '15',
            'Tension assignée': '17.5',
            'Pouvoir de coupure assigné': '16',
            'Section Du Cable': '70',
            'Nature Du Reseau': 'Aérien',
          },
          createdAt: DateTime.now(),
        ),
      ];

      final pdfData = InstallationDescriptionPdfData.fromDescription(desc: desc, audit: null);

      expect(pdfData.mtRows.length, 1);
      final row = pdfData.mtRows[0];
      expect(row.getValueForColumn('TYPE DE CELLULE', 'MT'), 'IM');
      expect(row.getValueForColumn('TENSION DE SERVICE (kV)', 'MT'), '15');
      expect(row.getValueForColumn('TENSION ASSIGNEE(KV)', 'MT'), '17.5');
      expect(row.getValueForColumn('POUVOIR DE COUPURE ASSIGNE(KA)', 'MT'), '16');
      expect(row.getValueForColumn('SECTION DU CABLE(mm2)', 'MT'), '70');
    });
  });
}
