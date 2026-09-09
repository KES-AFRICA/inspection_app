import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/builders/pdf_audit_installations_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_sommaire_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_mesures_essais_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_photos_schemas_builder.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  setUpAll(() {
    final regularData = File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync();
    final boldData = File('assets/fonts/Roboto-Bold.ttf').readAsBytesSync();

    final robotoRegular = pw.Font.ttf(regularData.buffer.asByteData());
    final robotoBold = pw.Font.ttf(boldData.buffer.asByteData());

    PdfReportStyles.fontRegular = robotoRegular;
    PdfReportStyles.fontBold = robotoBold;
    PdfAuditInstallationsBuilder.fontRegular = robotoRegular;
    PdfAuditInstallationsBuilder.fontBold = robotoBold;
    PdfSommaireBuilder.fontRegular = robotoRegular;
    PdfSommaireBuilder.fontBold = robotoBold;
    PdfMesuresEssaisBuilder.fontRegular = robotoRegular;
    PdfMesuresEssaisBuilder.fontBold = robotoBold;
    PdfPhotosSchemasBuilder.fontRegular = robotoRegular;
    PdfPhotosSchemasBuilder.fontBold = robotoBold;
  });

  group('PDF Character Encoding & Unicode Rendering', () {
    const testChars = [
      "'", '’', '-', '–', '—', 'É', 'È', 'À', 'Ç', 'é', 'è', 'à', 'ç',
      'Ω', 'Δ', '≤', '≥', '×', '°', '±', 'µ', '²', '³', 'ₙ',
      "d'isolement", "d’isolement", "lorsqu'elle", "lorsqu’elle", "lorsque",
      "0,5 MΩ", "IΔn", "Iₙ", "courant différentiel résiduel",
      "Les mesures de résistance d’isolement par rapport à la terre sont réalisées sous une tension continue de 500 V.",
      "La valeur mesurée est considérée comme satisfaisante lorsqu’elle est supérieure à 0,5 M ohms.",
      "Le seuil de déclenchement est considéré comme satisfaisant lorsque la valeur mesurée est comprise entre 0,5 IΔn et IΔn, où IΔn représente le courant différentiel résiduel assigné du dispositif.",
    ];

    test('Tous les 27+ caractères et chaînes métier sont supportés dans Roboto sans erreur', () async {
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            theme: pw.ThemeData.withFont(
              base: PdfReportStyles.fontRegular,
              bold: PdfReportStyles.fontBold,
            ),
          ),
          build: (ctx) => testChars.map((s) => pw.Text(s)).toList(),
        ),
      );

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);
    });

    test('normalizeText préserve les caractères Unicode natifs de Roboto sans substitution indésirable', () {
      expect(PdfReportStyles.normalizeText("0,5 MΩ"), equals("0,5 MΩ"));
      expect(PdfReportStyles.normalizeText("IΔn"), equals("IΔn"));
      expect(PdfReportStyles.normalizeText("d’isolement"), equals("d’isolement"));
      expect(PdfReportStyles.normalizeText("lorsqu’elle"), equals("lorsqu’elle"));
      expect(PdfReportStyles.normalizeText("10 m²"), equals("10 m²"));
      expect(PdfReportStyles.normalizeText("± 5%"), equals("± 5%"));
      expect(PdfReportStyles.normalizeText("≥ 100 kΩ"), equals("≥ 100 kΩ"));
    });

    test('PdfMesuresEssaisBuilder utilise Roboto et génère la section Conditions de mesure', () async {
      expect(PdfMesuresEssaisBuilder.fontRegular, isNotNull);
      expect(PdfMesuresEssaisBuilder.fontBold, isNotNull);

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            theme: pw.ThemeData.withFont(
              base: PdfMesuresEssaisBuilder.fontRegular,
              bold: PdfMesuresEssaisBuilder.fontBold,
            ),
          ),
          build: (ctx) => pw.Column(
            children: [
              PdfMesuresEssaisBuilder.buildBlueBoxBanner("Mesure de la résistance d’isolement"),
              PdfMesuresEssaisBuilder.para([
                const pw.TextSpan(
                  text: "Les mesures de résistance d’isolement par rapport à la terre sont réalisées sous une tension continue de 500 V.",
                ),
              ]),
              PdfMesuresEssaisBuilder.para([
                const pw.TextSpan(
                  text: "La valeur mesurée est considérée comme satisfaisante lorsqu’elle est supérieure à 0,5 M ohms.",
                ),
              ]),
              PdfMesuresEssaisBuilder.para([
                const pw.TextSpan(
                  text: "Le seuil de déclenchement est considéré comme satisfaisant lorsque la valeur mesurée est comprise entre 0,5 IΔn et IΔn, où IΔn représente le courant différentiel résiduel assigné du dispositif.",
                ),
              ]),
            ],
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);
    });
  });

  group('Résumé Exécutif - Titre 3 formatConcentrationTitle', () {
    test('Gère les cas vide, préfixé et non-préfixé sans perdre le titre', () {
      expect(
        PdfReportStyles.formatConcentrationTitle(''),
        equals('3. Concentration du risque'),
      );
      expect(
        PdfReportStyles.formatConcentrationTitle('   '),
        equals('3. Concentration du risque'),
      );
      expect(
        PdfReportStyles.formatConcentrationTitle('3. Concentration du risque'),
        equals('3. Concentration du risque'),
      );
      expect(
        PdfReportStyles.formatConcentrationTitle('3. Concentration du risque : TGBT et Armoires'),
        equals('3. Concentration du risque : TGBT et Armoires'),
      );
      expect(
        PdfReportStyles.formatConcentrationTitle('Concentration du risque : analyse par catégorie'),
        equals('3. Concentration du risque : analyse par catégorie'),
      );
    });
  });

  group('Audit BT - Cellule Type de protection et Marque', () {
    test('Génère un widget Column sur 2 lignes quand type et marque sont présents', () {
      final cellWidget = PdfAuditInstallationsBuilder.buildProtectionCell(
        'Disjoncteur',
        'Schneider',
      );
      expect(cellWidget, isA<pw.Container>());
      final container = cellWidget as pw.Container;
      expect(container.child, isA<pw.Column>());
      final column = container.child as pw.Column;
      expect(column.children.length, equals(2));
      final text1 = column.children[0] as pw.Text;
      final text2 = column.children[1] as pw.Text;
      expect(text1.text.toPlainText(), equals('Disjoncteur'));
      expect(text2.text.toPlainText(), equals('(Schneider)'));
    });

    test('Génère un widget mono-ligne quand la marque est absente', () {
      final cellWidget = PdfAuditInstallationsBuilder.buildProtectionCell(
        'Disjoncteur',
        null,
      );
      expect(cellWidget, isA<pw.Container>());
      final container = cellWidget as pw.Container;
      expect(container.child, isA<pw.Text>());
      final text = container.child as pw.Text;
      expect(text.text.toPlainText(), equals('Disjoncteur'));
    });

    test('Génère absent quand le type est vide ou aucun', () {
      final cellWidget = PdfAuditInstallationsBuilder.buildProtectionCell(
        '-aucun-',
        'Schneider',
      );
      expect(cellWidget, isA<pw.Container>());
      final container = cellWidget as pw.Container;
      final text = container.child as pw.Text;
      expect(text.text.toPlainText(), equals('absent'));
    });
  });

  group('Sommaire & Gestion des clés de pagination', () {
    test('Contient bien les clés pour MT, BT et Signature du rapport', () {
      final mission = Mission(
        id: 'M-TEST',
        nomClient: 'CLIENT TEST',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
      );
      final audit = AuditInstallationsElectriques(
        missionId: 'M-TEST',
        updatedAt: DateTime.now(),
      );

      final entries = PdfSommaireBuilder.collectSommaireEntries(
        mission: mission,
        rg: null,
        desc: null,
        audit: audit,
        mesures: null,
        foudres: [],
      );

      final keys = entries.map((e) => e.key).toSet();
      expect(keys.contains('liste_recap_equipements_mt'), isTrue);
      expect(keys.contains('liste_recap_equipements_bt'), isTrue);
      expect(keys.contains('signature_rapport'), isTrue);
    });
  });
}
