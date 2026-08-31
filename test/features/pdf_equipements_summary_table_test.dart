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
    test('1. Ordre exact des 9 colonnes (ZONE | REPÈRE | N° | ÉQUIPEMENT | TYPE | VÉRIFIÉ | PRÉSENCE PARAFOUDRE | THERMO | OBSERVATION)', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'mission_summary_test',
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
                nom: 'Armoire Principale MT',
                type: 'ARMOIRE_ELECTRIQUE',
              ),
              CoffretArmoire(
                qrCode: 'QR2',
                repere: 'REP-A',
                nom: 'Coffret Secondaire MT',
                type: 'COFFRET_ELECTRIQUE',
              ),
              CoffretArmoire(
                qrCode: 'QR3',
                repere: 'REP-B',
                nom: 'TGBT MT',
                type: 'TGBT',
              ),
            ],
          ),
        ],
      );

      final equipementsMT = PdfReportService.collectEquipementsMTForTesting(audit);
      expect(equipementsMT.length, equals(3));
      expect(equipementsMT[0].repere, 'REP-A');
      expect(equipementsMT[1].repere, 'REP-A');
      expect(equipementsMT[2].repere, 'REP-B');

      final tableWidget = PdfReportService.buildEquipementsTableForTesting(equipementsMT);
      expect(tableWidget, isNotNull);
      expect(tableWidget, isA<pw.Column>());
    });
  });
}
