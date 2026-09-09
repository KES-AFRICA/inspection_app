import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/pdf/installation_description_pdf_data.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/pdf/builders/pdf_description_builder.dart';

void main() {
  group('PdfDescriptionBuilder - Tableaux et pagination anti-orphelin', () {
    test('buildInstallationTableFromRows retourne un tableau unique avec en-tête répétable', () {
      final rows = [
        InstallationDescriptionPdfRow(
          index: 1,
          rawId: 'cell-1',
          zoneName: 'Zone 1',
          localName: 'Local A',
          normalizedFields: {'Type De Cellule': 'DM1', 'Tension De Service': '30'},
        ),
        InstallationDescriptionPdfRow(
          index: 2,
          rawId: 'cell-2',
          zoneName: 'Zone 1',
          localName: 'Local A',
          normalizedFields: {'Type De Cellule': 'DM2', 'Tension De Service': '30'},
        ),
        InstallationDescriptionPdfRow(
          index: 3,
          rawId: 'cell-3',
          zoneName: 'Zone 2',
          localName: 'Local B',
          normalizedFields: {'Type De Cellule': 'DM3', 'Tension De Service': '7.2'},
        ),
      ];

      final widgets = PdfDescriptionBuilder.buildInstallationTableFromRows(
        rows,
        sectionKey: 'MT',
      );

      // 1. Doit retourner exactement 1 table (pas de séparation en plusieurs tables)
      expect(widgets.length, equals(1));
      expect(widgets.first, isA<pw.Table>());

      final table = widgets.first as pw.Table;
      // 2. Le premier rang est l'en-tête (repeat: false selon le choix utilisateur pour cette section)
      expect(table.children.isNotEmpty, isTrue);
      expect(table.children.first.repeat, isFalse);

      // 3. Doit contenir 1 rang d'en-tête + 3 rangs de données = 4 rangs
      expect(table.children.length, equals(4));
    });

    test('buildInstallationTableFromRows avec liste vide a repeat: false sur l\'en-tête', () {
      final widgets = PdfDescriptionBuilder.buildInstallationTableFromRows(
        [],
        sectionKey: 'MT',
      );

      expect(widgets.length, equals(1));
      final table = widgets.first as pw.Table;
      expect(table.children.first.repeat, isFalse);
    });

    test('buildInstallationTable a repeat: false sur l\'en-tête', () {
      final items = [
        InstallationItem(data: {'Marque': 'CAT', 'Puissance (Kva)': '500'}),
        InstallationItem(data: {'Marque': 'Volvo', 'Puissance (Kva)': '800'}),
      ];

      final widget = PdfDescriptionBuilder.buildInstallationTable(
        items,
        sectionKey: 'GROUPE',
      );

      expect(widget, isA<pw.Table>());
      final table = widget as pw.Table;
      expect(table.children.first.repeat, isFalse);
      expect(table.children.length, equals(3)); // 1 header + 2 items
    });

    test('buildAlimentationSiteMtTable a repeat: false sur l\'en-tête', () {
      final desc = DescriptionInstallations.create('mission-1');
      final widget = PdfDescriptionBuilder.buildAlimentationSiteMtTable(desc);

      expect(widget, isA<pw.Table>());
      final table = widget as pw.Table;
      expect(table.children.first.repeat, isFalse);
    });

    test('buildCpiTable a repeat: false sur l\'en-tête', () {
      final cpiItems = [
        InstallationItem(data: {'MARQUE': 'Bender', 'TYPE': 'ISOMETER'}),
      ];
      final widget = PdfDescriptionBuilder.buildCpiTable(cpiItems);

      expect(widget, isA<pw.Table>());
      final table = widget as pw.Table;
      expect(table.children.first.repeat, isFalse);
    });

    test('buildDescriptionInstallationsMulti intègre des NewPage avec freeSpace anti-orphelin et génère un PDF valide', () async {
      final desc = DescriptionInstallations.create('mission-1');
      final trackedPages = <String, int>{};

      final widgets = PdfDescriptionBuilder.buildDescriptionInstallationsMulti(
        desc,
        null,
        trackedPages,
      );

      // Vérifier la présence de NewPage avec freeSpace pour protéger les sections
      final newPageWidgets = widgets.whereType<pw.NewPage>().toList();
      expect(newPageWidgets.isNotEmpty, isTrue);
      expect(newPageWidgets.any((np) => (np.freeSpace ?? 0) >= 100), isTrue);

      // Vérifier que l'intégration dans un MultiPage génère un PDF valide sans exception
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => widgets,
        ),
      );

      final bytes = await pdf.save();
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}
