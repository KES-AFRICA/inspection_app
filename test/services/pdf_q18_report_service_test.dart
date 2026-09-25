// test/services/pdf_q18_report_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/services/pdf/builders/pdf_photos_schemas_builder.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_conclusion_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_dangers_synthesis_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_identification_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_perimetre_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_photos_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_regulatory_builder.dart';
import 'package:inspec_app/services/pdf/q18/pdf_q18_report_service.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_snapshot.dart';

void main() {
  group('Q18 Report Service & Builders Tests (APSAD D18)', () {
    late Mission sampleMission;
    late RenseignementsGeneraux sampleRg;
    late Q18DataSnapshot sampleSnapshot;

    setUp(() {
      sampleMission = Mission(
        id: 'mission_q18_test_001',
        nomClient: 'CIMENCAM',
        nomSite: 'Usine de Nomayos',
        status: 'en_cours',
        createdAt: DateTime(2026, 2, 10),
        updatedAt: DateTime(2026, 2, 10),
        dateIntervention: DateTime(2026, 2, 10),
      );

      sampleRg = RenseignementsGeneraux(
        missionId: 'mission_q18_test_001',
        etablissement: 'CIMENCAM S.A.',
        installation: 'Usine de broyage et ensachage',
        activite: 'Production de ciments industriels',
        nomSite: 'Site Industriel de Nomayos',
        dateDebut: DateTime(2026, 2, 10),
        dateFin: DateTime(2026, 2, 12),
        dureeJours: 3,
        registreControle: 'Présenté',
        compteRendu: [],
        accompagnateurs: [],
        verificateurs: [],
        updatedAt: DateTime(2026, 2, 12),
      );

      const quantities = Q18InstallationsQuantities(
        nbLocauxTechniquesHTA: 2,
        nbTransformateurs: 3,
        transformateursPuissanceText: '1250 kVA, 1600 kVA',
        nbCellules: 6,
        nbLocauxGE: 1,
        nbGroupesElectrogenes: 1,
        groupesPuissanceText: '800 kVA',
        nbInverseurs: 1,
        nbLocauxTechniquesBT: 4,
        nbTGBT: 2,
        nbArmoires: 12,
        nbCoffrets: 35,
        presenceParatonnerre: true,
        presenceParafoudreInverseur: 'Présent (1/1)',
        presenceParafoudreTGBT: 'Présent (2/2)',
        presenceParafoudreArmoire: 'Partiel (8/12)',
        presenceParafoudreCoffret: 'Absent (0/35)',
        presenceCentralePhotovoltaique: 'Sans objet (0)',
      );

      final perimetreCouverts = [
        const Q18PerimetreItem(
          zone: 'Poste HT/BT Principal',
          repere: 'Local Transfo 1 & 2',
          equipements: 'Cellules HTA, 2 Transfos 1250kVA, TGBT Normal',
          isCouvert: true,
        ),
        const Q18PerimetreItem(
          zone: 'Bâtiment Broyage',
          repere: 'Salle électrique Broyeur',
          equipements: 'Armoires départs moteurs, Coffrets de commande',
          isCouvert: true,
        ),
      ];

      final exclusions = [
        const Q18PerimetreItem(
          zone: 'Silo Ciment 4',
          repere: 'Passerelle supérieure',
          equipements: 'Coffret dépoussiéreur',
          isCouvert: false,
          motifExclusion: 'Travaux en hauteur en cours, accès consigné',
        ),
      ];

      final documents = [
        const Q18DocumentConsulteItem(index: 1, titre: 'Schémas unifilaires des tableaux généraux', isDisponible: true),
        const Q18DocumentConsulteItem(index: 2, titre: 'Registre de sécurité et carnet d\'entretien', isDisponible: true),
        const Q18DocumentConsulteItem(index: 3, titre: 'Rapport de vérification périodique N-1', isDisponible: true),
        const Q18DocumentConsulteItem(index: 4, titre: 'Compte-rendu Q18 de l\'exercice précédent', isDisponible: false),
        const Q18DocumentConsulteItem(index: 5, titre: 'Plans de zonage ATEX / BE2', isDisponible: false),
        const Q18DocumentConsulteItem(index: 6, titre: 'Fiches techniques et notices de conformité', isDisponible: true),
      ];

      final dangers = [
        const Q18DangerItem(
          index: 1,
          zone: 'Poste HTA',
          repere: 'TGBT-N',
          designation: 'Jeu de barres principal',
          dangerConstate: 'Échauffement anormal constaté sur la connexion Phase 2 (78°C sous 350A)',
          familleDeRisque: 'Échauffement et connexions défectueuses',
          niveau: Q18DangerLevel.dangerAvere,
        ),
        const Q18DangerItem(
          index: 2,
          zone: 'Bâtiment Broyage',
          repere: 'ARM-BR01',
          designation: 'Armoire broyeur',
          dangerConstate: 'Presse-étoupes manquants sur arrivée câble puissance, pénétration de poussières',
          familleDeRisque: 'Protection contre les contacts directs / IP',
          niveau: Q18DangerLevel.degradation,
        ),
        const Q18DangerItem(
          index: 3,
          zone: 'Atelier Mécanique',
          repere: 'COF-AT02',
          designation: 'Coffret prises',
          dangerConstate: 'Repérage des départs effacé sur plastron',
          familleDeRisque: 'Identification et repérage',
          niveau: Q18DangerLevel.horsPerimetreApsad,
        ),
      ];

      sampleSnapshot = Q18DataSnapshot(
        mission: sampleMission,
        renseignements: sampleRg,
        numeroRapportQ18: 'KES/IP/Q18/2026/001',
        numeroRapportVerifElec: 'KES/IP/VE/2026/001',
        dateRapportEffective: DateTime(2026, 2, 15),
        dateProchaineVisite: DateTime(2027, 2, 12),
        lieuIntervention: 'Nomayos (Yaoundé)',
        intervenantsNoms: ['André FOUDA (KES - Vérificateur)', 'Jean ETOUNDI (KES - Ingénieur)'],
        dateVisiteLabel: 'Dates des visites de vérification',
        dateVisiteValue: 'Du 10/02/2026 au 12/02/2026',
        clientName: 'CIMENCAM',
        siteName: 'Usine de Nomayos',
        adresseSite: 'Nomayos (Yaoundé)',
        typeMission: 'Vérification périodique',
        quantities: quantities,
        perimetreCouverts: perimetreCouverts,
        exclusionsPerimetre: exclusions,
        documentsConsultes: documents,
        dangers: dangers,
        countDangerAvere: 1,
        countDegradation: 1,
        countHorsPerimetre: 1,
        countPointSensible: 0,
        hasDangerAvere: true,
        appreciationGlobale: 'Insuffisant',
        avisSyntheseText: 'Présence d\'un échauffement critique sur jeu de barres TGBT nécessitant intervention immédiate.',
        photoEntries: [
          PdfPhotoEntry(
            filePath: '',
            description: 'Échauffement connexion TGBT',
            repere: 'TGBT-N',
            isObservation: true,
            badgeLabel: 'Danger avéré',
          ),
        ],
      );
    });

    test('1. Nomenclature officielle des noms de fichier Q18', () {
      final fileName = PdfQ18ReportService.buildQ18ReportFileName(sampleMission);
      expect(fileName, startsWith('Rapport_Q18_'));
      expect(fileName, contains('CIMENCAM'));
      expect(fileName, contains('Usine_de_Nomayos'));
      expect(fileName, contains('2026'));
      expect(fileName, endsWith('.pdf'));
    });

    test('2. Niveaux de gravité normalisés APSAD D18', () {
      expect(Q18DangerLevel.dangerAvere.label, equals('Danger avéré'));
      expect(Q18DangerLevel.degradation.label, equals('Dégradation'));
      expect(Q18DangerLevel.horsPerimetreApsad.label, equals('Non-conformité hors périmètre APSAD'));
      expect(Q18DangerLevel.pointSensible.label, equals('Point sensible / observation'));
    });

    test('3. Q18IdentificationBuilder - Sections 1 (10 lignes) et 4 (4.1 & 4.2)', () {
      final tracked = <String, int>{};
      final s1Widgets = Q18IdentificationBuilder.buildSection1Identification(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s1Widgets.isNotEmpty, isTrue);

      // Vérification des 10 lignes de données du tableau de la Section 1 (1 en-tête + 10 données = 11)
      final s1Table = s1Widgets.whereType<pw.Table>().first;
      expect(s1Table.children.length, equals(11));

      final s4Widgets = Q18IdentificationBuilder.buildSection4Presentation(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
        trackedPages: tracked,
        pageOffset: 0,
      );
      expect(s4Widgets.isNotEmpty, isTrue);

      // Section 4 contient les tableaux pour 4.1 et 4.2
      final s4Tables = s4Widgets.whereType<pw.Table>().toList();
      expect(s4Tables.length, equals(2));
      // Tableau 4.1 : 5 lignes (en-tête + 4 rubriques)
      expect(s4Tables[0].children.length, equals(5));
      // Tableau 4.2 : 17 lignes (en-tête + 16 postes)
      expect(s4Tables[1].children.length, equals(17));
    });

    test('4. Q18RegulatoryBuilder - Sections 2, 3 (8 textes), 7 (9 points), 8 (4 niveaux), 9 (9 typologies)', () {
      final s2 = Q18RegulatoryBuilder.buildSection2ObjetCadre(
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s2.isNotEmpty, isTrue);
      // Section 2 est épurée aux 2 paragraphes de référence (pas de pavé d'alerte orange)
      expect(s2.whereType<pw.Paragraph>().length, equals(2));

      final s3 = Q18RegulatoryBuilder.buildSection3CadreReglementaire(
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s3.isNotEmpty, isTrue);
      final s3Table = s3.whereType<pw.Table>().first;
      // 1 en-tête + 8 textes de référence = 9 lignes
      expect(s3Table.children.length, equals(9));

      final s7 = Q18RegulatoryBuilder.buildSection7Methodologie(
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s7.isNotEmpty, isTrue);
      final s7Table = s7.whereType<pw.Table>().first;
      // 1 en-tête + 9 points de contrôle = 10 lignes
      expect(s7Table.children.length, equals(10));

      final s8 = Q18RegulatoryBuilder.buildSection8ClassificationDangers(
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s8.isNotEmpty, isTrue);
      final s8Table = s8.whereType<pw.Table>().first;
      // 1 en-tête + 4 niveaux de danger = 5 lignes
      expect(s8Table.children.length, equals(5));

      final s9 = Q18RegulatoryBuilder.buildSection9TypologieDangers(
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s9.isNotEmpty, isTrue);
      final s9Table = s9.whereType<pw.Table>().first;
      // 1 en-tête + 9 typologies de danger = 10 lignes
      expect(s9Table.children.length, equals(10));
    });

    test('5. Q18PerimetreBuilder - Section 5 (4 colonnes & Sans Objet) et Section 6 (6 documents)', () {
      final tracked = <String, int>{};
      final s5 = Q18PerimetreBuilder.buildSection5Perimetre(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
        trackedPages: tracked,
        pageOffset: 2,
      );
      expect(s5.isNotEmpty, isTrue);
      // Section 5.1 a un tableau avec 4 colonnes et alignement vertical complet
      final s51Table = s5.whereType<pw.Table>().first;
      expect(s51Table.children.length, equals(3)); // En-tête + 2 items
      expect(s51Table.defaultVerticalAlignment, equals(pw.TableCellVerticalAlignment.full));

      // Test de Section 5.2 avec liste d'exclusions vide => Affiche simplement "- Sans Objet"
      final emptyExclusionsSnapshot = Q18DataSnapshot(
        mission: sampleMission,
        renseignements: sampleRg,
        numeroRapportQ18: 'KES/IP/Q18/2026/001',
        numeroRapportVerifElec: 'KES/IP/VE/2026/001',
        dateRapportEffective: DateTime(2026, 2, 15),
        dateProchaineVisite: DateTime(2027, 2, 12),
        lieuIntervention: 'Nomayos (Yaoundé)',
        quantities: sampleSnapshot.quantities,
        perimetreCouverts: sampleSnapshot.perimetreCouverts,
        exclusionsPerimetre: const [], // Vide !
        documentsConsultes: sampleSnapshot.documentsConsultes,
        dangers: sampleSnapshot.dangers,
        countDangerAvere: 0,
        countDegradation: 0,
        countHorsPerimetre: 0,
        countPointSensible: 0,
        hasDangerAvere: false,
        appreciationGlobale: 'Satisfaisant',
        avisSyntheseText: '',
        photoEntries: const [],
      );
      final s5Empty = Q18PerimetreBuilder.buildSection5Perimetre(
        emptyExclusionsSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s5Empty.isNotEmpty, isTrue);
      final hasSansObjet = s5Empty.any(
        (w) => w is pw.Padding && w.child is pw.Text && (w.child as pw.Text).text.toPlainText().contains('- Sans Objet'),
      );
      expect(hasSansObjet, isTrue);

      final s6 = Q18PerimetreBuilder.buildSection6DocumentsConsultes(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s6.isNotEmpty, isTrue);
      final s6Table = s6.whereType<pw.Table>().first;
      // 1 en-tête + 6 documents consultés = 7 lignes
      expect(s6Table.children.length, equals(7));
      expect(s6Table.defaultVerticalAlignment, equals(pw.TableCellVerticalAlignment.full));
    });

    test('6. Q18DangersSynthesisBuilder - Sections 10 et 11', () {
      final s10 = Q18DangersSynthesisBuilder.buildSection10Dangers(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s10.isNotEmpty, isTrue);

      final s11 = Q18DangersSynthesisBuilder.buildSection11Statistiques(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s11.isNotEmpty, isTrue);
    });

    test('7. Q18ConclusionBuilder - Sections 12, 13, 14, 15', () {
      final s12 = Q18ConclusionBuilder.buildSection12AvisGlobal(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s12.isNotEmpty, isTrue);

      final s13 = Q18ConclusionBuilder.buildSection13LeveeDangers(
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s13.isNotEmpty, isTrue);

      final s14 = Q18ConclusionBuilder.buildSection14ProchaineEcheance(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s14.isNotEmpty, isTrue);

      final s15 = Q18ConclusionBuilder.buildSection15Signature(
        sampleSnapshot,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(s15.isNotEmpty, isTrue);
    });

    test('8. Q18PhotosBuilder - Section 16', () {
      final emptyWidgets = Q18PhotosBuilder.buildSection16Photos(
        [],
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(emptyWidgets.isNotEmpty, isTrue);

      final populatedWidgets = Q18PhotosBuilder.buildSection16Photos(
        sampleSnapshot.photoEntries,
        fontBold: pw.Font.helveticaBold(),
        fontRegular: pw.Font.helvetica(),
      );
      expect(populatedWidgets.isNotEmpty, isTrue);
    });

    test('9. Génération PDF binaire complète du rapport Q18 (Pass 1 et 2)', () async {
      final pdf = pw.Document();

      // Page de garde
      pdf.addPage(
        pw.Page(
          pageTheme: PdfReportStyles.buildCoverPageTheme(
            pw.Font.helvetica(),
            pw.Font.helveticaBold(),
          ),
          build: (ctx) => pw.Center(
            child: pw.Text(
              'RAPPORT Q18 TEST',
              style: pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 20),
            ),
          ),
        ),
      );

      // MultiPage avec toutes les sections
      pdf.addPage(
        pw.MultiPage(
          pageTheme: PdfReportStyles.buildInnerPageTheme(
            fontRegular: pw.Font.helvetica(),
            fontBold: pw.Font.helveticaBold(),
            overrideTotalPages: 5,
            showWatermark: false,
          ),
          build: (ctx) => [
            ...Q18IdentificationBuilder.buildSection1Identification(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            pw.NewPage(),
            ...Q18RegulatoryBuilder.buildSection2ObjetCadre(
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18RegulatoryBuilder.buildSection3CadreReglementaire(
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            pw.NewPage(),
            ...Q18IdentificationBuilder.buildSection4Presentation(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            pw.NewPage(),
            ...Q18PerimetreBuilder.buildSection5Perimetre(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18PerimetreBuilder.buildSection6DocumentsConsultes(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            pw.NewPage(),
            ...Q18RegulatoryBuilder.buildSection7Methodologie(
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18RegulatoryBuilder.buildSection8ClassificationDangers(
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18RegulatoryBuilder.buildSection9TypologieDangers(
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            pw.NewPage(),
            ...Q18DangersSynthesisBuilder.buildSection10Dangers(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18DangersSynthesisBuilder.buildSection11Statistiques(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            pw.NewPage(),
            ...Q18ConclusionBuilder.buildSection12AvisGlobal(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18ConclusionBuilder.buildSection13LeveeDangers(
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18ConclusionBuilder.buildSection14ProchaineEcheance(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
            ...Q18ConclusionBuilder.buildSection15Signature(
              sampleSnapshot,
              fontBold: pw.Font.helveticaBold(),
              fontRegular: pw.Font.helvetica(),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      expect(bytes.isNotEmpty, isTrue);
      // Signature PDF standard : %PDF-
      expect(bytes.length, greaterThan(1000));
      final headerStr = String.fromCharCodes(bytes.sublist(0, 5));
      expect(headerStr, equals('%PDF-'));
    });

    test('10. MultiPage avec plus de 20 pages sans TooManyPagesException', () async {
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          maxPages: 10000,
          pageTheme: PdfReportStyles.buildInnerPageTheme(
            fontRegular: pw.Font.helvetica(),
            fontBold: pw.Font.helveticaBold(),
            showWatermark: false,
          ),
          build: (ctx) => [
            for (int i = 0; i < 30; i++) ...[
              pw.Text('Page $i'),
              if (i < 29) pw.NewPage(),
            ],
          ],
        ),
      );

      final bytes = await pdf.save();
      expect(pdf.document.pdfPageList.pages.length, equals(30));
      expect(bytes.isNotEmpty, isTrue);
    });

    test('11. Intégration complète : buildDocumentForTesting avec Sommaire en page 2 et PageTracker', () async {
      final trackedPages = <String, int>{};
      final fonts = (
        regular: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );
      final assets = (
        logoKes: null as pw.MemoryImage?,
        watermark: null as pw.MemoryImage?,
      );

      // Passe 1 : peuplement de trackedPages
      final doc1 = PdfQ18ReportService.buildDocumentForTesting(
        data: sampleSnapshot,
        fonts: fonts,
        assets: assets,
        overrideTotalPages: null,
        trackedPages: trackedPages,
      );
      final bytes1 = await doc1.save();
      expect(bytes1.isNotEmpty, isTrue);

      // Vérifie la présence des clés de traçage de pages
      expect(trackedPages.containsKey('q18_s1'), isTrue);
      expect(trackedPages.containsKey('q18_s2'), isTrue);
      expect(trackedPages.containsKey('q18_s3'), isTrue);
      expect(trackedPages.containsKey('q18_s4'), isTrue);
      expect(trackedPages.containsKey('q18_s4_1'), isTrue);
      expect(trackedPages.containsKey('q18_s4_2'), isTrue);
      expect(trackedPages.containsKey('q18_s5'), isTrue);
      expect(trackedPages.containsKey('q18_s5_1'), isTrue);
      expect(trackedPages.containsKey('q18_s6'), isTrue);
      expect(trackedPages.containsKey('q18_s7'), isTrue);
      expect(trackedPages.containsKey('q18_s8'), isTrue);
      expect(trackedPages.containsKey('q18_s9'), isTrue);
      expect(trackedPages.containsKey('q18_s10'), isTrue);
      expect(trackedPages.containsKey('q18_s11'), isTrue);
      expect(trackedPages.containsKey('q18_s12'), isTrue);
      expect(trackedPages.containsKey('q18_s13'), isTrue);
      expect(trackedPages.containsKey('q18_s14'), isTrue);
      expect(trackedPages.containsKey('q18_s15'), isTrue);
      expect(trackedPages.containsKey('q18_s16'), isTrue);

      // Section 1 démarre en page 3 (Page 1 = Couverture, Page 2 = Sommaire)
      expect(trackedPages['q18_s1'], equals(3));

      // Passe 2 : document final avec totalPages et trackedPages résolu
      final totalPages = doc1.document.pdfPageList.pages.length;
      expect(totalPages, greaterThanOrEqualTo(5));

      final doc2 = PdfQ18ReportService.buildDocumentForTesting(
        data: sampleSnapshot,
        fonts: fonts,
        assets: assets,
        overrideTotalPages: totalPages,
        trackedPages: trackedPages,
      );
      final bytes2 = await doc2.save();
      expect(bytes2.isNotEmpty, isTrue);
      expect(bytes2.length, greaterThan(2000));
    });
  });
}
