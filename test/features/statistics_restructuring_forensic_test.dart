import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/pdf/builders/pdf_executive_summary_builder.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';
import 'package:inspec_app/services/statistics/risk_family_normalizer.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_stats_forensic_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('RiskFamilyNormalizer — Rigueur Typographique et Sémantique', () {
    test('Unifie les apostrophes courbes et droites sans créer de super-famille artificielle', () {
      expect(
        RiskFamilyNormalizer.normalize('Erreur d’exploitation / maintenance'),
        equals("Erreur d'exploitation / maintenance"),
      );
      expect(
        RiskFamilyNormalizer.normalize("Erreur d'exploitation / maintenance"),
        equals("Erreur d'exploitation / maintenance"),
      );
      expect(
        RiskFamilyNormalizer.normalize("Conditions d’environnement"),
        equals("Conditions d'environnement"),
      );
      expect(
        RiskFamilyNormalizer.normalize("Conditions d'environnement"),
        equals("Conditions d'environnement"),
      );
    });

    test('Normalise les espaces et les slashes correctement', () {
      expect(
        RiskFamilyNormalizer.normalize('Sécurité/conformité réglementaire'),
        equals('Sécurité / conformité réglementaire'),
      );
      expect(
        RiskFamilyNormalizer.normalize('Sécurité   /   conformité réglementaire'),
        equals('Sécurité / conformité réglementaire'),
      );
    });

    test('Gère les entrées vides ou nulles de manière sécurisée', () {
      expect(RiskFamilyNormalizer.normalize(null), equals('Non spécifiée'));
      expect(RiskFamilyNormalizer.normalize(''), equals('Non spécifiée'));
      expect(RiskFamilyNormalizer.normalize('   '), equals('Non spécifiée'));
    });
  });

  group('TechnicalEnrichmentEngine — Séparation Stricte HTA / BT et Totaux Réels', () {
    AuditFinding makeFinding({
      required String id,
      required TensionDomain tension,
      required String table,
      required String objType,
      required String riskFamily,
    }) {
      return AuditFinding(
        id: id,
        missionId: 'M-FORENSIC-TEST',
        tensionDomain: tension,
        origin: 'Test Origin',
        objectType: objType,
        objectName: 'Equip-$id',
        tableName: table,
        verificationPoint: 'Point-$id',
        observationText: 'Obs-$id',
        conformity: 'non',
        criticality: 'Majeure',
        riskFamily: riskFamily,
      );
    }

    test('Les 4 quadrants séparent rigoureusement HTA et BT avec les totaux réels', () {
      // Construction synthétique miroir de la structure Cimencam :
      // 1. HTA Dispositions constructives : 47 constats (4 familles)
      final htaDispoFindings = <AuditFinding>[];
      for (int i = 0; i < 27; i++) {
        htaDispoFindings.add(makeFinding(id: 'hd1_$i', tension: TensionDomain.mt, table: 'Dispositions constructives', objType: 'Local MT', riskFamily: 'Sécurité / conformité réglementaire'));
      }
      for (int i = 0; i < 8; i++) {
        htaDispoFindings.add(makeFinding(id: 'hd2_$i', tension: TensionDomain.mt, table: 'Dispositions constructives', objType: 'Local MT', riskFamily: 'Sécurité des interventions'));
      }
      for (int i = 0; i < 8; i++) {
        htaDispoFindings.add(makeFinding(id: 'hd3_$i', tension: TensionDomain.mt, table: 'Dispositions constructives', objType: 'Local MT', riskFamily: 'Évacuation / continuité des installations de sécurité'));
      }
      for (int i = 0; i < 4; i++) {
        htaDispoFindings.add(makeFinding(id: 'hd4_$i', tension: TensionDomain.mt, table: 'Dispositions constructives', objType: 'Local MT', riskFamily: "Échauffement / conditions d'environnement"));
      }

      // 2. BT Dispositions constructives : 35 constats (7 familles, Top 5 = 28 / 35 -> 80,0 %)
      final btDispoFindings = <AuditFinding>[];
      for (int i = 0; i < 10; i++) {
        btDispoFindings.add(makeFinding(id: 'bd1_$i', tension: TensionDomain.bt, table: 'Dispositions constructives', objType: 'Local BT', riskFamily: 'Sécurité / conformité réglementaire'));
      }
      for (int i = 0; i < 7; i++) {
        btDispoFindings.add(makeFinding(id: 'bd2_$i', tension: TensionDomain.bt, table: 'Dispositions constructives', objType: 'Local BT', riskFamily: 'Erreur d’exploitation / maintenance'));
      }
      for (int i = 0; i < 6; i++) {
        btDispoFindings.add(makeFinding(id: 'bd3_$i', tension: TensionDomain.bt, table: 'Dispositions constructives', objType: 'Local BT', riskFamily: 'Incendie / brûlure / fuite de combustible'));
      }
      for (int i = 0; i < 3; i++) {
        btDispoFindings.add(makeFinding(id: 'bd4_$i', tension: TensionDomain.bt, table: 'Dispositions constructives', objType: 'Local BT', riskFamily: 'Accès non autorisé / risque électrique'));
      }
      for (int i = 0; i < 2; i++) {
        btDispoFindings.add(makeFinding(id: 'bd5_$i', tension: TensionDomain.bt, table: 'Dispositions constructives', objType: 'Local BT', riskFamily: 'Incendie / propagation du feu'));
      }
      // Hors Top 5 (7 constats unitaires dans 7 familles distinctes) :
      for (int i = 0; i < 7; i++) {
        btDispoFindings.add(makeFinding(id: 'bd6_$i', tension: TensionDomain.bt, table: 'Dispositions constructives', objType: 'Local BT', riskFamily: 'Risque Mineur Divers $i'));
      }

      // 3. HTA Exploitation et maintenance : 82 constats (4 familles)
      final htaExploitFindings = <AuditFinding>[];
      for (int i = 0; i < 67; i++) {
        htaExploitFindings.add(makeFinding(id: 'he1_$i', tension: TensionDomain.mt, table: "Conditions d'exploitation", objType: 'Local MT', riskFamily: 'Sécurité des interventions / risque électrique'));
      }
      for (int i = 0; i < 12; i++) {
        htaExploitFindings.add(makeFinding(id: 'he2_$i', tension: TensionDomain.mt, table: 'Cellule MT', objType: 'Cellule MT', riskFamily: "Erreur d'exploitation / maintenance"));
      }
      for (int i = 0; i < 2; i++) {
        htaExploitFindings.add(makeFinding(id: 'he3_$i', tension: TensionDomain.mt, table: 'Transformateur MT/BT', objType: 'Transformateur MT/BT', riskFamily: 'Évacuation / sécurité incendie'));
      }
      for (int i = 0; i < 1; i++) {
        htaExploitFindings.add(makeFinding(id: 'he4_$i', tension: TensionDomain.mt, table: 'Points de contrôle', objType: 'Coffret', riskFamily: 'Contact électrique / influences externes / protection mécanique'));
      }

      // 4. BT Exploitation et maintenance : 211 constats (6 familles, Top 5 = 181 / 211 -> 85,8 %)
      final btExploitFindings = <AuditFinding>[];
      for (int i = 0; i < 65; i++) {
        btExploitFindings.add(makeFinding(id: 'be1_$i', tension: TensionDomain.bt, table: 'Points de contrôle', objType: 'Coffret', riskFamily: 'Contact électrique / influences externes / protection mécanique'));
      }
      for (int i = 0; i < 54; i++) {
        btExploitFindings.add(makeFinding(id: 'be2_$i', tension: TensionDomain.bt, table: 'Points de contrôle', objType: 'Coffret', riskFamily: 'Erreur d’exploitation / maintenance'));
      }
      for (int i = 0; i < 27; i++) {
        btExploitFindings.add(makeFinding(id: 'be3_$i', tension: TensionDomain.bt, table: 'Points de contrôle', objType: 'Coffret', riskFamily: 'Sécurité des interventions / risque électrique'));
      }
      for (int i = 0; i < 21; i++) {
        btExploitFindings.add(makeFinding(id: 'be4_$i', tension: TensionDomain.bt, table: 'Points de contrôle', objType: 'Coffret', riskFamily: 'Sécurité / conformité réglementaire'));
      }
      for (int i = 0; i < 14; i++) {
        btExploitFindings.add(makeFinding(id: 'be5_$i', tension: TensionDomain.bt, table: 'Points de contrôle', objType: 'Coffret', riskFamily: 'Incendie / échauffement / surcharge des conducteurs'));
      }
      // Hors Top 5 (30 constats unitaires dans 30 familles distinctes) :
      for (int i = 0; i < 30; i++) {
        btExploitFindings.add(makeFinding(id: 'be6_$i', tension: TensionDomain.bt, table: "Conditions d'exploitation", objType: 'Local BT', riskFamily: 'Défaut Exploitation Autre $i'));
      }

      final allFindings = [
        ...htaDispoFindings,
        ...btDispoFindings,
        ...htaExploitFindings,
        ...btExploitFindings,
      ];

      final domainInventory = MissionDomainInventory(
        missionId: 'M-FORENSIC-TEST',
        instances: [
          DomainEntityInstance(
            instanceId: 'inst-mt',
            category: DomainObjectType.localMT,
            name: 'Poste MT',
            tensionDomain: TensionDomain.mt,
            originPath: 'Locaux MT',
            findings: [...htaDispoFindings, ...htaExploitFindings],
          ),
          DomainEntityInstance(
            instanceId: 'inst-bt',
            category: DomainObjectType.localBT,
            name: 'Local BT',
            tensionDomain: TensionDomain.bt,
            originPath: 'Locaux BT',
            findings: [...btDispoFindings, ...btExploitFindings],
          ),
        ],
        allFindings: allFindings,
      );

      final findingInventory = AuditFindingInventory(
        missionId: 'M-FORENSIC-TEST',
        findings: allFindings,
      );

      final technical = TechnicalEnrichmentEngine.compute(
        'M-FORENSIC-TEST',
        domainInventory,
        findingInventory,
      );
      final matrix = technical.riskFamilyMatrix;

      // ─── BLOC 1 : DISPOSITION CONSTRUCTIVE ───
      // MT à part et comptée : 47 constats, 4 familles, 100,0 %
      final htaDispo = matrix.htaDispositionsConstructives;
      expect(htaDispo.totalConstats, equals(47));
      expect(htaDispo.topFamilies.length, equals(4));
      expect(htaDispo.sumTopOccurrences, equals(47));
      expect(htaDispo.formattedPartTopSum, equals('100,0 %'));
      expect(htaDispo.topFamilies[0].famille, equals('Sécurité / conformité réglementaire'));
      expect(htaDispo.topFamilies[0].constats, equals(27));

      // BT à part et comptée : 35 constats éligibles, Top 5 = 28 constats, 80,0 % (JAMAIS 100 %)
      final btDispo = matrix.btDispositionsConstructives;
      expect(btDispo.totalConstats, equals(35));
      expect(btDispo.topFamilies.length, equals(5));
      expect(btDispo.sumTopOccurrences, equals(28));
      expect(btDispo.formattedPartTopSum, equals('80,0 %'));
      expect(btDispo.topFamilies[0].famille, equals('Sécurité / conformité réglementaire'));
      expect(btDispo.topFamilies[0].constats, equals(10));
      expect(btDispo.topFamilies[1].famille, equals("Erreur d'exploitation / maintenance"));
      expect(btDispo.topFamilies[1].constats, equals(7));

      // ─── BLOC 2 : EXPLOITATION ET MAINTENANCE ───
      // MT à part et comptée : 82 constats, 4 familles, 100,0 %
      final htaExploit = matrix.htaExploitationMaintenance;
      expect(htaExploit.totalConstats, equals(82));
      expect(htaExploit.topFamilies.length, equals(4));
      expect(htaExploit.sumTopOccurrences, equals(82));
      expect(htaExploit.formattedPartTopSum, equals('100,0 %'));
      expect(htaExploit.topFamilies[0].famille, equals('Sécurité des interventions / risque électrique'));
      expect(htaExploit.topFamilies[0].constats, equals(67));

      // BT à part et comptée : 211 constats éligibles, Top 5 = 181 constats, 85,8 % (JAMAIS 100 %)
      final btExploit = matrix.btExploitationMaintenance;
      expect(btExploit.totalConstats, equals(211));
      expect(btExploit.topFamilies.length, equals(5));
      expect(btExploit.sumTopOccurrences, equals(181));
      expect(btExploit.formattedPartTopSum, equals('85,8 %'));
      expect(btExploit.topFamilies[0].famille, equals('Contact électrique / influences externes / protection mécanique'));
      expect(btExploit.topFamilies[0].constats, equals(65));
      expect(btExploit.topFamilies[1].famille, equals("Erreur d'exploitation / maintenance"));
      expect(btExploit.topFamilies[1].constats, equals(54));

      // Vérification qu'aucune famille MT n'est polluée par la BT et inversement
      expect(htaDispo.counts.containsKey('Incendie / brûlure / fuite de combustible'), isFalse);
      expect(btDispo.counts.containsKey('Évacuation / continuité des installations de sécurité'), isFalse);
    });
  });

  group('PDF Executive Summary Builder — Rendu Visuel et Non-Régression', () {
    test('Génère le document PDF complet avec Tableaux 2.1 et 3 restructurés', () async {
      PdfReportStyles.fontRegular = pw.Font.helvetica();
      PdfReportStyles.fontBold = pw.Font.helveticaBold();
      PdfExecutiveSummaryBuilder.fontRegular = pw.Font.helvetica();
      PdfExecutiveSummaryBuilder.fontBold = pw.Font.helveticaBold();

      final mission = Mission(
        id: 'M-PDF-TEST',
        nomClient: 'CIMENCAM FIGUIL',
        nomSite: 'USINE FIGUIL',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
      );

      final trackedPages = <String, int>{};
      final pdfDoc = pw.Document();

      final widgets = PdfExecutiveSummaryBuilder.buildResumeExecutif(
        mission,
        trackedPages,
        'KES-2026-TEST-RAPPORT',
      );

      expect(widgets, isNotEmpty);

      pdfDoc.addPage(
        pw.MultiPage(
          build: (ctx) => widgets,
        ),
      );

      final bytes = await pdfDoc.save();
      expect(bytes, isNotNull);
      expect(bytes.length, greaterThan(1000));
    });
  });
}
