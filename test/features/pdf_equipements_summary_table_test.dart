// test/features/pdf_equipements_summary_table_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_report_service.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  setUp(() {
    PdfReportService.initFontsForTesting();
  });

  group('Synthèse récapitulative des équipements — Ordre des colonnes & Numérotation continue', () {
    test('1. Tableau MT (7 colonnes : ZONE | REPÈRE | N° | ÉQUIPEMENT | TYPE | VÉRIFIÉ | OBSERVATION)', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'mission_summary_test_mt',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'Local MT 1',
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
                nom: 'Cellule 1',
              ),
            ],
            transformateurs: [
              TransformateurMTBT(
                typeTransformateur: 'Sec',
                marqueAnnee: 'ABB',
                puissanceAssignee: '630kVA',
                tensionPrimaireSecondaire: '20kV/400V',
                relaisBuchholz: 'Non',
                typeRefroidissement: 'AN',
                regimeNeutre: 'TN-S',
                nom: 'Transfo 1',
              ),
            ],
          ),
        ],
      );

      final equipementsMT = PdfReportService.collectEquipementsMTForTesting(audit);
      expect(equipementsMT.length, equals(2));

      final tableWidget = PdfReportService.buildEquipementsTableForTesting(equipementsMT, isMT: true);
      expect(tableWidget, isNotNull);
      expect(tableWidget, isA<pw.Column>());
    });

    test('2. Tableau BT (9 colonnes : ZONE | REPÈRE | N° | ÉQUIPEMENT | TYPE | VÉRIFIÉ | PRÉSENCE PARAFOUDRE | THERMO | OBSERVATION)', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'mission_summary_test_bt',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'Local MT 1',
            type: 'Poste HT',
            dispositionsConstructives: [],
            conditionsExploitation: [],
            coffrets: [
              CoffretArmoire(
                qrCode: 'QR1',
                repere: 'REP-A',
                nom: 'Armoire Principale BT',
                type: 'ARMOIRE_ELECTRIQUE',
              ),
              CoffretArmoire(
                qrCode: 'QR2',
                repere: 'REP-A',
                nom: 'Coffret Secondaire BT',
                type: 'COFFRET_ELECTRIQUE',
              ),
              CoffretArmoire(
                qrCode: 'QR3',
                repere: 'REP-B',
                nom: 'TGBT BT',
                type: 'TGBT',
              ),
            ],
          ),
        ],
      );

      final equipementsBT = PdfReportService.getEquipementsBTForTesting(audit, null);
      expect(equipementsBT.length, equals(3));
      expect(equipementsBT[0].localName, 'Local MT 1');
      expect(equipementsBT[0].repere, 'REP-A');

      final tableWidget = PdfReportService.buildEquipementsTableForTesting(equipementsBT, isMT: false);
      expect(tableWidget, isNotNull);
      expect(tableWidget, isA<pw.Column>());
    });
  });
}
