import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

void main() {
  group('PDF Electrical Verification Filename Format Test', () {
    test('generate exact expected format Rapport_Verif_elec_<site>_<année>_<timestamp>.pdf', () {
      final site = 'CAMRAIL BESSENGUE';
      final testDate = DateTime(2026, 8, 23);
      final timestamp = 1787326459575;

      final fileName = PdfReportService.buildElectricalReportFileName(
        site,
        date: testDate,
        timestamp: timestamp,
      );

      expect(
        fileName,
        equals('Rapport_Verif_elec_CAMRAIL BESSENGUE_2026_1787326459575.pdf'),
      );
    });

    test('supports future years dynamically without hardcoding', () {
      final site = 'TOTAL AKWA';
      final testDate2027 = DateTime(2027, 3, 15);
      final timestamp = 1787326499999;

      final fileName2027 = PdfReportService.buildElectricalReportFileName(
        site,
        date: testDate2027,
        timestamp: timestamp,
      );

      expect(
        fileName2027,
        equals('Rapport_Verif_elec_TOTAL AKWA_2027_1787326499999.pdf'),
      );
    });

    test('sanitizes forbidden filename characters cleanly', () {
      final site = 'SITE / TEST : <ALPHA> *';
      final testDate = DateTime(2026, 1, 1);
      final timestamp = 1234567890;

      final fileName = PdfReportService.buildElectricalReportFileName(
        site,
        date: testDate,
        timestamp: timestamp,
      );

      expect(
        fileName,
        equals('Rapport_Verif_elec_SITE _ TEST _ _ALPHA_ __2026_1234567890.pdf'),
      );
    });
  });
}
