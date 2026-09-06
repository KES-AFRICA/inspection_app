import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/builders/pdf_sommaire_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_equipements_synthesis_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_audit_installations_builder.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';

void main() {
  late pw.Font robotoRegular;
  late pw.Font robotoBold;

  setUpAll(() {
    final regularData = File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync();
    final boldData = File('assets/fonts/Roboto-Bold.ttf').readAsBytesSync();

    robotoRegular = pw.Font.ttf(regularData.buffer.asByteData());
    robotoBold = pw.Font.ttf(boldData.buffer.asByteData());

    PdfReportStyles.fontRegular = robotoRegular;
    PdfReportStyles.fontBold = robotoBold;
    PdfAuditInstallationsBuilder.fontRegular = robotoRegular;
    PdfAuditInstallationsBuilder.fontBold = robotoBold;
    PdfSommaireBuilder.fontRegular = robotoRegular;
    PdfSommaireBuilder.fontBold = robotoBold;
    PdfEquipementsSynthesisBuilder.fontRegular = robotoRegular;
    PdfEquipementsSynthesisBuilder.fontBold = robotoBold;
  });

  group('Simulation de génération PDF & Résolution Sommaire', () {
    test('Scénario Mission SANS équipements MT : la page vide est bien traquée et numérotée dans le Sommaire', () async {
      final mission = Mission(
        id: 'M-SANS-MT',
        nomClient: 'CLIENT SANS MT',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
      );

      // Audit avec uniquement de la Basse Tension (aucun équipement MT)
      final audit = AuditInstallationsElectriques(
        missionId: 'M-SANS-MT',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [],
        moyenneTensionZones: [],
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Principale',
            coffretsDirects: [
              CoffretArmoire(
                qrCode: 'QR-01',
                repere: 'TGBT-01',
                nom: 'TGBT Bâtiment A',
                type: 'TGBT',
                alimentations: [
                  Alimentation(
                    source: 'Transformateur 1',
                    typeProtection: 'Disjoncteur',
                    marqueDisjoncteur: 'Schneider',
                    calibre: '400',
                    pdcKA: '25 kA',
                    sectionCable: '4x95 mm²',
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final trackedPages = <String, int>{};
      int currentOffset = 1;

      // 1. Simulation du Sommaire
      trackedPages['sommaire'] = currentOffset;
      currentOffset += 1;

      // 2. Simulation Synthèse Équipements MT (VIDE)
      final equipementsMT = PdfEquipementsSynthesisBuilder.collectEquipementsMT(audit);
      expect(equipementsMT.isEmpty, isTrue);

      // Simulation de notre _renderEquipementsSubBatches pour MT vide
      final docMtEmpty = pw.Document();
      docMtEmpty.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            theme: pw.ThemeData.withFont(base: robotoRegular, bold: robotoBold),
          ),
          build: (ctx) => [
            PageTracker(
              key: 'liste_recap_equipements_mt',
              registry: trackedPages,
              offset: currentOffset,
              child: pw.Text('1. Équipements moyenne tension'),
            ),
            pw.Text('Aucun équipement répertorié'),
          ],
        ),
      );
      final bytesMt = await docMtEmpty.save();
      expect(bytesMt.isNotEmpty, isTrue);
      currentOffset += docMtEmpty.document.pdfPageList.pages.length;

      // 3. Simulation Synthèse Équipements BT (NON VIDE)
      final equipementsBT = PdfEquipementsSynthesisBuilder.collectEquipementsBT(audit, null);
      expect(equipementsBT.isNotEmpty, isTrue);

      final docBt = pw.Document();
      docBt.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            theme: pw.ThemeData.withFont(base: robotoRegular, bold: robotoBold),
          ),
          build: (ctx) => [
            PageTracker(
              key: 'liste_recap_equipements_bt',
              registry: trackedPages,
              offset: currentOffset,
              child: pw.Text('2. Équipements basse tension'),
            ),
            pw.Text('Tableau BT'),
          ],
        ),
      );
      final bytesBt = await docBt.save();
      expect(bytesBt.isNotEmpty, isTrue);
      currentOffset += docBt.document.pdfPageList.pages.length;

      // 4. Simulation de la Page Signature
      final docSig = pw.Document();
      docSig.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            theme: pw.ThemeData.withFont(base: robotoRegular, bold: robotoBold),
          ),
          build: (ctx) => [
            PageTracker(
              key: 'signature_rapport',
              registry: trackedPages,
              offset: currentOffset,
              child: pw.Column(
                children: [
                  pw.Text('LA DIRECTION'),
                  pw.Text('Patrick ESSAME ESSAME'),
                  pw.Text('Fait à Douala le 06/09/2026'),
                ],
              ),
            ),
          ],
        ),
      );
      final bytesSig = await docSig.save();
      expect(bytesSig.isNotEmpty, isTrue);
      currentOffset += docSig.document.pdfPageList.pages.length;

      // VÉRIFICATION DU SOMMAIRE
      expect(trackedPages['liste_recap_equipements_mt'], equals(3));
      expect(trackedPages['liste_recap_equipements_bt'], equals(4));
      expect(trackedPages['signature_rapport'], equals(5));

      // Vérification que le builder de sommaire peut résoudre toutes les entrées sans '--'
      final sommaireEntries = PdfSommaireBuilder.collectSommaireEntries(
        mission: mission,
        rg: null,
        desc: null,
        audit: audit,
        mesures: null,
        foudres: [],
      );

      final mtEntry = sommaireEntries.firstWhere((e) => e.key == 'liste_recap_equipements_mt');
      final btEntry = sommaireEntries.firstWhere((e) => e.key == 'liste_recap_equipements_bt');
      final sigEntry = sommaireEntries.firstWhere((e) => e.key == 'signature_rapport');

      expect(trackedPages[mtEntry.key], isNotNull);
      expect(trackedPages[btEntry.key], isNotNull);
      expect(trackedPages[sigEntry.key], isNotNull);

      expect(trackedPages[mtEntry.key], equals(3));
      expect(trackedPages[btEntry.key], equals(4));
      expect(trackedPages[sigEntry.key], equals(5));
    });
  });
}
