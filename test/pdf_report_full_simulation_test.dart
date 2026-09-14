import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/builders/pdf_sommaire_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_equipements_synthesis_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_audit_installations_builder.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';

import 'package:inspec_app/services/pdf/builders/pdf_mesures_essais_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_photos_schemas_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_executive_summary_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_statistics_builder.dart';
import 'package:inspec_app/services/ai/executive_summary_snapshot.dart';
import 'package:inspec_app/services/ai/mission_executive_summary_service.dart';

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
    PdfMesuresEssaisBuilder.fontRegular = robotoRegular;
    PdfMesuresEssaisBuilder.fontBold = robotoBold;
    PdfPhotosSchemasBuilder.fontRegular = robotoRegular;
    PdfPhotosSchemasBuilder.fontBold = robotoBold;
    PdfExecutiveSummaryBuilder.fontRegular = robotoRegular;
    PdfExecutiveSummaryBuilder.fontBold = robotoBold;
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

    test('Résumé Exécutif 100% local et déterministe généré sans appel réseau ni IA', () async {
      final mission = Mission(
        id: 'M-EXEC-TEST',
        nomClient: 'KES ENERGIE AFRICA',
        nomSite: 'SITE YAOUNDE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
      );

      final snapshot = ExecutiveSummarySnapshot(
        missionId: mission.id,
        clientName: mission.nomClient,
        siteName: mission.nomSite ?? 'SITE YAOUNDE',
        natureMission: 'Vérification Périodique',
        dateRangeText: 'du 01 au 05/09/2026',
        domainTension: 'Basse Tension (BT)',
        companyName: 'KES Africa',
        reportNumber: 'KES-2026-001',
        reportDateStr: '06/09/2026',
        officialStats: {
          'totalNC': 5,
          'critique': 2,
          'majeure': 2,
          'mineure': 1,
          'pctCritique': '40,0',
          'pctMajeure': '40,0',
          'pctMineure': '20,0',
        },
        categoryStats: [
          {
            'categoryName': 'Armoires et Coffrets BT',
            'ncCount': 3,
            'pctOfTotalNc': '60,0',
            'equipmentCount': 8,
            'pctOfTotalEquipment': '66,7',
            'densityStr': '0,38',
          },
          {
            'categoryName': 'Prises de terre',
            'ncCount': 2,
            'pctOfTotalNc': '40,0',
            'equipmentCount': 4,
            'pctOfTotalEquipment': '33,3',
            'densityStr': '0,50',
          },
        ],
        topDefects: [
          {'defectName': 'Absence repérage départs', 'count': 2, 'pct': '40,0'},
          {'defectName': 'Section conducteur PE sous-calibrée', 'count': 2, 'pct': '40,0'},
          {'defectName': 'Défaut de continuité terre', 'count': 1, 'pct': '20,0'},
        ],
        riskFamilies: [
          {
            'natureRisque': 'Choc électrique par contact indirect',
            'constats': 3,
            'partPct': '60 %',
            'observation': 'Éléments de protection à vérifier d’urgence.',
          },
        ],
        equipmentCount: 12,
        installationsCount: 2,
        globalDensityStr: '0,42',
      );

      // Appel direct et déterministe (zéro réseau, zéro IA)
      final summaryData = MissionExecutiveSummaryService.buildDeterministicFallback(
        mission.id,
        snapshot,
      );

      expect(summaryData, isNotNull);
      expect(summaryData.isFallback, isTrue);
      expect(summaryData.syntheseResultats.tableTotalRow.nombre, equals(5));
      expect(summaryData.syntheseResultats.tableRows.length, equals(3));
      expect(summaryData.concentrationRisque.title, contains('Concentration du risque'));

      // Génération PDF du Résumé Exécutif avec PdfExecutiveSummaryBuilder
      final trackedPages = <String, int>{};
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            theme: pw.ThemeData.withFont(
              base: PdfExecutiveSummaryBuilder.fontRegular,
              bold: PdfExecutiveSummaryBuilder.fontBold,
            ),
          ),
          build: (ctx) => PdfExecutiveSummaryBuilder.buildResumeExecutif(
            mission,
            trackedPages,
            'KES/IP/VE/2025/001',
            summaryData: summaryData,
            offset: 0,
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);
      expect(trackedPages['resume_executif'], equals(1));
    });

    test('Alignement dynamique du Sommaire avec le Résumé Exécutif et l\'Analyse Statistique', () async {
      final mission = Mission(
        id: 'M-SOMMAIRE-ALIGN-TEST',
        nomClient: 'KES ENERGIE AFRICA',
        nomSite: 'SITE YAOUNDE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
      );

      final snapshot = ExecutiveSummarySnapshot.fromMission(mission.id);
      final summaryData = MissionExecutiveSummaryService.buildDeterministicFallback(
        mission.id,
        snapshot,
      );

      final trackedPages = <String, int>{};
      const initialOffset = 3; // Simule Couverture (p.1) + Intervenants (p.2) + Sommaire (p.3)

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            theme: pw.ThemeData.withFont(
              base: robotoRegular,
              bold: robotoBold,
            ),
          ),
          build: (ctx) => [
            ...PdfExecutiveSummaryBuilder.buildResumeExecutif(
              mission,
              trackedPages,
              'KES-2026-001',
              summaryData: summaryData,
              offset: initialOffset,
            ),
            pw.NewPage(),
            ...PdfStatisticsBuilder.buildAnalyseStatistique(
              mission,
              trackedPages,
              'KES-2026-001',
              offset: initialOffset,
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);

      // 1. Vérification que Résumé Exécutif a bien renseigné ses pages
      expect(trackedPages['resume_executif'], isNotNull);
      expect(trackedPages['resume_executif'], greaterThanOrEqualTo(4));
      expect(trackedPages['resume_executif_1_1'], isNotNull);
      expect(trackedPages['resume_executif_1_12'], isNotNull);

      // 2. Vérification que l'Analyse Statistique est bien renseignée et commence APRES le résumé
      expect(trackedPages['analyse_statistique'], isNotNull);
      expect(trackedPages['analyse_statistique']!, greaterThan(trackedPages['resume_executif']!));
      expect(trackedPages['stat_tension'], isNotNull);
      expect(trackedPages['stat_croisee_mt'], isNotNull);
      expect(trackedPages['stat_croisee_bt'], isNotNull);
      expect(trackedPages['stat_securite_bt'], isNotNull);
      expect(trackedPages['stat_sources_alim'], isNotNull);
      expect(trackedPages['stat_coupure_tete'], isNotNull);
      expect(trackedPages['stat_parafoudres'], isNotNull);
      expect(trackedPages['stat_pareto'], isNotNull);
      expect(trackedPages['stat_synthese'], isNotNull);
      expect(trackedPages['stat_formation'], isNotNull);

      // 3. Vérification que toutes les entrées du Sommaire pour ces sections sont résolues sans '--'
      final sommaireEntries = PdfSommaireBuilder.collectSommaireEntries(
        mission: mission,
        rg: null,
        desc: null,
        audit: null,
        mesures: null,
        foudres: [],
      );

      final execEntries = sommaireEntries.where((e) => e.key.startsWith('resume_executif')).toList();
      final statEntries = sommaireEntries.where((e) => e.key.startsWith('stat_') || e.key == 'analyse_statistique').toList();

      expect(execEntries, isNotEmpty);
      expect(statEntries, isNotEmpty);

      for (final entry in execEntries) {
        final pageNum = trackedPages[entry.key];
        expect(pageNum, isNotNull, reason: 'La clé de résumé exécutif ${entry.key} (${entry.titre}) doit être présente dans trackedPages');
      }

      for (final entry in statEntries) {
        final pageNum = trackedPages[entry.key];
        expect(pageNum, isNotNull, reason: 'La clé d\'analyse statistique ${entry.key} (${entry.titre}) doit être présente dans trackedPages');
      }
    });
  });
}
