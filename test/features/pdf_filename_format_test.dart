import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

void main() {
  group('PDF Electrical Verification Filename Format Test', () {
    test('generate exact expected format Rapport_Verif_elec_<client>_<site>_<année>_<timestamp>.pdf', () {
      final client = 'CAMRAIL';
      final site = 'BESSENGUE';
      final testDate = DateTime(2026, 8, 23);
      final timestamp = 1787326459575;

      final fileName = PdfReportService.buildElectricalReportFileName(
        client,
        nomSite: site,
        date: testDate,
        timestamp: timestamp,
      );

      expect(
        fileName,
        equals('Rapport_Verif_elec_CAMRAIL_BESSENGUE_2026_1787326459575.pdf'),
      );
    });

    test('supports future years dynamically without hardcoding', () {
      final client = 'TOTAL';
      final site = 'AKWA';
      final testDate2027 = DateTime(2027, 3, 15);
      final timestamp = 1787326499999;

      final fileName2027 = PdfReportService.buildElectricalReportFileName(
        client,
        nomSite: site,
        date: testDate2027,
        timestamp: timestamp,
      );

      expect(
        fileName2027,
        equals('Rapport_Verif_elec_TOTAL_AKWA_2027_1787326499999.pdf'),
      );
    });

    test('sanitizes forbidden filename characters cleanly on both client and site', () {
      final client = 'CLIENT / KES : <PRO>';
      final site = 'SITE / TEST : <ALPHA> *';
      final testDate = DateTime(2026, 1, 1);
      final timestamp = 1234567890;

      final fileName = PdfReportService.buildElectricalReportFileName(
        client,
        nomSite: site,
        date: testDate,
        timestamp: timestamp,
      );

      expect(
        fileName,
        equals('Rapport_Verif_elec_CLIENT _ KES _ _PRO__SITE _ TEST _ _ALPHA_ __2026_1234567890.pdf'),
      );
    });

    test('falls back gracefully when site is null or empty without producing "null"', () {
      final client = 'ENEO CAMEROUN';
      final testDate = DateTime(2026, 5, 10);
      final timestamp = 1234567890;

      final fileNameNullSite = PdfReportService.buildElectricalReportFileName(
        client,
        nomSite: null,
        date: testDate,
        timestamp: timestamp,
      );

      final fileNameEmptySite = PdfReportService.buildElectricalReportFileName(
        client,
        nomSite: '   ',
        date: testDate,
        timestamp: timestamp,
      );

      expect(
        fileNameNullSite,
        equals('Rapport_Verif_elec_ENEO CAMEROUN_2026_1234567890.pdf'),
      );
      expect(
        fileNameEmptySite,
        equals('Rapport_Verif_elec_ENEO CAMEROUN_2026_1234567890.pdf'),
      );
    });
  });
}
