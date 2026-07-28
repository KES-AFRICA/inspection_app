import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic Sommaire Sub-Sections Tests', () {
    test('Sommaire entries should contain all statistical sub-sections', () {
      final entries = PdfReportService.getSommaireEntriesForTesting();
      expect(entries, isNotEmpty);

      final titles = entries.map((e) => e.titre).toList();
      expect(titles, contains("ANALYSE STATISTIQUE"));
      expect(titles, contains("Statistique par type de défaut"));
      expect(titles, contains("Répartition par domaine de tension"));
      expect(titles, contains("Non-conformités croisées par catégorie d'équipement"));
      expect(titles, contains("Inventaire chiffré des installations et équipements"));
    });
  });
}
