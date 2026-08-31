import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/pdf/installation_description_pdf_data.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

void main() {
  group('PDF Description des installations Tests', () {
    test('Test 1 — Validation des zones et locaux dans les lignes de description PDF', () {
      final audit = AuditInstallationsElectriques.create('mission_test_1');

      // Local MT direct (hors zone)
      final localMTDirect = MoyenneTensionLocal(
        nom: 'Poste HT 1',
        type: 'LOCAL',
        cellules: [
          Cellule(
            syncId: 'cell_1',
            fonction: 'ARRIVEE',
            type: 'Interrupteur',
            marqueModeleAnnee: 'Schneider 2020',
            tensionAssignee: '24',
            pouvoirCoupure: '16',
            numerotation: '1',
            parafoudres: 'Non',
          ),
        ],
      );

      // Zone MT avec local
      final zoneMT = MoyenneTensionZone(
        nom: 'Zone Transfo MT',
        locaux: [
          MoyenneTensionLocal(
            nom: 'Cellule 1A',
            type: 'LOCAL',
            cellules: [
              Cellule(
                syncId: 'cell_2',
                fonction: 'PROTECTION',
                type: 'Disjoncteur',
                marqueModeleAnnee: 'ABB 2021',
                tensionAssignee: '24',
                pouvoirCoupure: '25',
                numerotation: '2',
                parafoudres: 'Non',
              ),
            ],
          ),
        ],
      );

      // Zone BT avec local et transformateur
      final zoneBT = BasseTensionZone(
        nom: 'Zone Production BT',
        locaux: [
          BasseTensionLocal(
            nom: 'Local TGBT',
            type: 'LOCAL_TGBT',
            transformateurs: [
              TransformateurMTBT(
                syncId: 'transfo_1',
                marqueAnnee: 'France Transfo 2020',
                puissanceAssignee: '1000',
                typeTransformateur: 'Sec',
                tensionPrimaireSecondaire: '20/0.4',
                relaisBuchholz: 'Non',
                typeRefroidissement: 'AN',
                regimeNeutre: 'TN-S',
              ),
            ],
          ),
        ],
      );

      audit.moyenneTensionLocaux.add(localMTDirect);
      audit.moyenneTensionZones.add(zoneMT);
      audit.basseTensionZones.add(zoneBT);

      final pdfData = InstallationDescriptionPdfData.fromDescription(
        desc: null,
        audit: audit,
      );

      // Vérifier les lignes MT
      expect(pdfData.mtRows.length, equals(2));

      final rowDirect = pdfData.mtRows.firstWhere((r) => r.localName == 'Poste HT 1');
      expect(rowDirect.zoneName, equals('')); // Hors zone !

      final rowInZoneMT = pdfData.mtRows.firstWhere((r) => r.localName == 'Cellule 1A');
      expect(rowInZoneMT.zoneName, equals('Zone Transfo MT'));

      // Vérifier les lignes BT (Transformateurs)
      expect(pdfData.btRows.length, equals(1));
      final transfoRow = pdfData.btRows.first;
      expect(transfoRow.localName, equals('Local TGBT'));
      expect(transfoRow.zoneName, equals('Zone Production BT'));
      expect(transfoRow.getValueForColumn('REGIME DE NEUTRE', 'BT'), equals('TN-S'));
    });

    test('Test 2 — Hiérarchie visuelle structurée de la sous-section Zones et Locaux à risque', () {
      final audit = AuditInstallationsElectriques.create('mission_risk_test');

      // Local MT direct à risque
      final localMTDirectRisk = MoyenneTensionLocal(
        nom: 'Poste HT Risque Direct',
        type: 'LOCAL',
        isRiskZone: true,
      );

      // Zone MT à risque avec locaux à risque et sans risque
      final zoneMTRisk = MoyenneTensionZone(
        nom: 'Zone MT Risque A',
        isRiskZone: true,
        locaux: [
          MoyenneTensionLocal(nom: 'Local A1', type: 'LOCAL', isRiskZone: true),
          MoyenneTensionLocal(nom: 'Local A2 Normal', type: 'LOCAL', isRiskZone: false),
        ],
      );

      audit.moyenneTensionLocaux.add(localMTDirectRisk);
      audit.moyenneTensionZones.add(zoneMTRisk);

      final riskItems = PdfReportService.collectRiskZonesAndLocauxForTesting(audit);

      expect(riskItems.contains('Local Poste HT Risque Direct'), isTrue);
      expect(riskItems.contains('Zone MT Risque A'), isTrue);
      expect(riskItems.contains('Local A1'), isTrue);
      expect(riskItems.contains('Local A2 Normal'), isFalse);
    });
  });
}
