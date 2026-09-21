// test/features/competency_needs_engine_test.dart

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/builders/pdf_executive_summary_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_statistics_builder.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/competency_needs_engine.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  setUpAll(() {
    final regularFile = File('assets/fonts/Roboto-Regular.ttf');
    final boldFile = File('assets/fonts/Roboto-Bold.ttf');
    if (regularFile.existsSync() && boldFile.existsSync()) {
      final regularData = regularFile.readAsBytesSync();
      final boldData = boldFile.readAsBytesSync();
      PdfReportStyles.fontRegular = pw.Font.ttf(regularData.buffer.asByteData());
      PdfReportStyles.fontBold = pw.Font.ttf(boldData.buffer.asByteData());
    }
  });

  group('CompetencyNeedsEngine — Refonte Section 10 « Renforcement des compétences »', () {
    // Cas 1 : 5 NC majeures MT + 5 NC majeures BT → 10 axes maximum, classement global décroissant A. à J.
    test('Cas 1 : 5 NC majeures MT + 5 NC majeures BT → 10 axes maximum, classement global A. à J.', () {
      final findings = <AuditFinding>[];

      // MT : 5 défaillances avec fréquences 50, 40, 30, 20, 10
      final mtTopics = [
        ('Verrouillage mécanique cellule HTA', 50),
        ('Surveillance relais DGPT2 transfo', 40),
        ('Niveau diélectrique transformateur', 30),
        ('Sectionneur de terre MT', 20),
        ('Éclairage de sécurité local MT', 10),
      ];
      for (final t in mtTopics) {
        for (int i = 0; i < t.$2; i++) {
          findings.add(
            AuditFinding(
              id: 'mt_${t.$1}_$i',
              missionId: 'M-1',
              tensionDomain: TensionDomain.mt,
              origin: 'Poste MT',
              objectType: 'Cellule MT',
              objectName: 'Cellule $i',
              tableName: 'Cellule audit',
              verificationPoint: t.$1,
              observationText: 'Non-conformité sur ${t.$1}',
              conformity: 'non',
              criticality: 'Majeure',
            ),
          );
        }
      }

      // BT : 5 défaillances avec fréquences 45, 35, 25, 15, 5
      final btTopics = [
        ('Repérage des circuits et schémas unifilaires', 45),
        ('Continuité des liaisons équipotentielles', 35),
        ('Calibre protection disjoncteur', 25),
        ('Obturation des plages du plastron', 15),
        ('Serrage des connexions et borniers', 5),
      ];
      for (final t in btTopics) {
        for (int i = 0; i < t.$2; i++) {
          findings.add(
            AuditFinding(
              id: 'bt_${t.$1}_$i',
              missionId: 'M-1',
              tensionDomain: TensionDomain.bt,
              origin: 'Atelier',
              objectType: 'Armoire',
              objectName: 'Armoire $i',
              tableName: 'Points de vérification',
              verificationPoint: t.$1,
              observationText: 'Défaut majeur ${t.$1}',
              conformity: 'non',
              criticality: 'Majeure',
            ),
          );
        }
      }

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-1',
        findings: findings,
      );

      // Exactement 10 axes produits
      expect(result.axes.length, equals(10));

      // Les lettres doivent être A. à J.
      expect(result.axes[0].letter, equals('A.'));
      expect(result.axes[1].letter, equals('B.'));
      expect(result.axes[2].letter, equals('C.'));
      expect(result.axes[3].letter, equals('D.'));
      expect(result.axes[4].letter, equals('E.'));
      expect(result.axes[5].letter, equals('F.'));
      expect(result.axes[6].letter, equals('G.'));
      expect(result.axes[7].letter, equals('H.'));
      expect(result.axes[8].letter, equals('I.'));
      expect(result.axes[9].letter, equals('J.'));

      // Vérification du tri global décroissant absolu :
      // 50 (MT), 45 (BT), 40 (MT), 35 (BT), 30 (MT), 25 (BT), 20 (MT), 15 (BT), 10 (MT), 5 (BT)
      expect(result.axes[0].occurrenceCount, equals(50));
      expect(result.axes[1].occurrenceCount, equals(45));
      expect(result.axes[2].occurrenceCount, equals(40));
      expect(result.axes[3].occurrenceCount, equals(35));
      expect(result.axes[4].occurrenceCount, equals(30));
      expect(result.axes[5].occurrenceCount, equals(25));
      expect(result.axes[6].occurrenceCount, equals(20));
      expect(result.axes[7].occurrenceCount, equals(15));
      expect(result.axes[8].occurrenceCount, equals(10));
      expect(result.axes[9].occurrenceCount, equals(5));

      // Vérification de la concision (~2 lignes, entre 80 et 260 caractères)
      for (final axis in result.axes) {
        expect(axis.fullNarrative.length, greaterThan(60));
        expect(axis.fullNarrative.length, lessThan(300));
      }
    });

    // Cas 2 : 2 NC majeures MT + 3 NC majeures BT → Exactement 5 axes (A. à E.)
    test('Cas 2 : 2 NC majeures MT + 3 NC majeures BT → Exactement 5 axes', () {
      final findings = <AuditFinding>[];
      // MT : 2 types
      for (int i = 0; i < 8; i++) {
        findings.add(AuditFinding(
          id: 'mt1_$i',
          missionId: 'M-2',
          tensionDomain: TensionDomain.mt,
          origin: 'Poste',
          objectType: 'Cellule MT',
          objectName: 'C1',
          tableName: 'Cellules',
          verificationPoint: 'Interverrouillage HTA',
          observationText: 'Défaut verrou',
          conformity: 'non',
          criticality: 'Majeure',
        ));
      }
      for (int i = 0; i < 4; i++) {
        findings.add(AuditFinding(
          id: 'mt2_$i',
          missionId: 'M-2',
          tensionDomain: TensionDomain.mt,
          origin: 'Poste',
          objectType: 'Transfo',
          objectName: 'T1',
          tableName: 'Transfos',
          verificationPoint: 'DGPT2 transfo',
          observationText: 'Défaut relais',
          conformity: 'non',
          criticality: 'Majeure',
        ));
      }

      // BT : 3 types
      for (int i = 0; i < 15; i++) {
        findings.add(AuditFinding(
          id: 'bt1_$i',
          missionId: 'M-2',
          tensionDomain: TensionDomain.bt,
          origin: 'Atelier',
          objectType: 'Coffret',
          objectName: 'C1',
          tableName: 'Points',
          verificationPoint: 'Repérage des départs',
          observationText: 'Absence repérage',
          conformity: 'non',
          criticality: 'Majeure',
        ));
      }
      for (int i = 0; i < 10; i++) {
        findings.add(AuditFinding(
          id: 'bt2_$i',
          missionId: 'M-2',
          tensionDomain: TensionDomain.bt,
          origin: 'Atelier',
          objectType: 'Armoire',
          objectName: 'A1',
          tableName: 'Points',
          verificationPoint: 'Obturation des plages',
          observationText: 'Plastron ouvert',
          conformity: 'non',
          criticality: 'Majeure',
        ));
      }
      for (int i = 0; i < 6; i++) {
        findings.add(AuditFinding(
          id: 'bt3_$i',
          missionId: 'M-2',
          tensionDomain: TensionDomain.bt,
          origin: 'TGBT',
          objectType: 'TGBT',
          objectName: 'TG',
          tableName: 'Points',
          verificationPoint: 'Liaisons équipotentielles',
          observationText: 'Terre coupée',
          conformity: 'non',
          criticality: 'Majeure',
        ));
      }

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-2',
        findings: findings,
      );

      expect(result.axes.length, equals(5));
      expect(result.axes[0].letter, equals('A.'));
      expect(result.axes[4].letter, equals('E.'));

      // Ordre décroissant global : 15 (BT), 10 (BT), 8 (MT), 6 (BT), 4 (MT)
      expect(result.axes[0].occurrenceCount, equals(15));
      expect(result.axes[1].occurrenceCount, equals(10));
      expect(result.axes[2].occurrenceCount, equals(8));
      expect(result.axes[3].occurrenceCount, equals(6));
      expect(result.axes[4].occurrenceCount, equals(4));
    });

    // Cas 3 : 5 MT + 0 BT → Exactement 5 axes
    test('Cas 3 : 5 MT + 0 BT → Exactement 5 axes', () {
      final findings = <AuditFinding>[];
      for (int t = 0; t < 5; t++) {
        for (int i = 0; i < (t + 1) * 3; i++) {
          findings.add(AuditFinding(
            id: 'mt_${t}_$i',
            missionId: 'M-3',
            tensionDomain: TensionDomain.mt,
            origin: 'Poste',
            objectType: 'Cellule MT',
            objectName: 'C$t',
            tableName: 'Cellule',
            verificationPoint: 'Point MT $t',
            observationText: 'Observation $t',
            conformity: 'non',
            criticality: 'Majeure',
          ));
        }
      }

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-3',
        findings: findings,
      );

      expect(result.axes.length, equals(5));
      expect(result.introNarrative, contains('Moyenne Tension (HTA)'));
    });

    // Cas 4 : 0 MT + 5 BT → Exactement 5 axes
    test('Cas 4 : 0 MT + 5 BT → Exactement 5 axes', () {
      final findings = <AuditFinding>[];
      for (int t = 0; t < 5; t++) {
        for (int i = 0; i < (t + 1) * 4; i++) {
          findings.add(AuditFinding(
            id: 'bt_${t}_$i',
            missionId: 'M-4',
            tensionDomain: TensionDomain.bt,
            origin: 'Usine',
            objectType: 'Coffret',
            objectName: 'COF$t',
            tableName: 'Coffret',
            verificationPoint: 'Point BT $t',
            observationText: 'Observation $t',
            conformity: 'non',
            criticality: 'Majeure',
          ));
        }
      }

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-4',
        findings: findings,
      );

      expect(result.axes.length, equals(5));
      expect(result.introNarrative, contains('Basse Tension (BT)'));
    });

    // Cas 5 : Une seule NC majeure → Exactement 1 axe A.
    test('Cas 5 : Une seule NC majeure → 1 axe A.', () {
      final findings = [
        AuditFinding(
          id: 'single_1',
          missionId: 'M-5',
          tensionDomain: TensionDomain.bt,
          origin: 'Atelier',
          objectType: 'Coffret',
          objectName: 'C1',
          tableName: 'Points',
          verificationPoint: 'Obturation des plages du plastron',
          observationText: 'Absence d’obturateurs',
          conformity: 'non',
          criticality: 'Majeure',
        ),
      ];

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-5',
        findings: findings,
      );

      expect(result.axes.length, equals(1));
      expect(result.axes.first.letter, equals('A.'));
      expect(result.axes.first.occurrenceCount, equals(1));
    });

    // Cas 6 : Aucune NC majeure → 0 axe artificiel, texte professionnel propre
    test('Cas 6 : Aucune NC majeure → 0 axe artificiel, message professionnel', () {
      final findings = [
        AuditFinding(
          id: 'min_1',
          missionId: 'M-6',
          tensionDomain: TensionDomain.bt,
          origin: 'Local',
          objectType: 'Coffret',
          objectName: 'C1',
          tableName: 'Points',
          verificationPoint: 'Propreté du coffret',
          observationText: 'Légère poussière',
          conformity: 'non',
          criticality: 'Mineure',
        ),
      ];

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-6',
        findings: findings,
      );

      expect(result.axes, isEmpty);
      expect(result.hasNoDefects, isTrue);
      expect(result.introNarrative, contains('aucune non-conformité majeure'));
    });

    // Cas 7 : Fréquences très proches → rédaction équilibrée
    test('Cas 7 : Fréquences très proches (35, 34, 33, 32, 31) → rédaction équilibrée', () {
      final findings = <AuditFinding>[];
      final counts = [35, 34, 33, 32, 31];
      for (int c = 0; c < counts.length; c++) {
        for (int i = 0; i < counts[c]; i++) {
          findings.add(AuditFinding(
            id: 'close_${c}_$i',
            missionId: 'M-7',
            tensionDomain: TensionDomain.bt,
            origin: 'Usine',
            objectType: 'Coffret',
            objectName: 'C_$c',
            tableName: 'Points',
            verificationPoint: 'Défaut équilibré $c',
            observationText: 'Obs $c',
            conformity: 'non',
            criticality: 'Majeure',
          ));
        }
      }

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-7',
        findings: findings,
      );

      expect(result.isConcentrated, isFalse);
      expect(result.introNarrative, contains('de manière homogène'));
      expect(result.introNarrative.contains('priorité absolue'), isFalse);
    });

    // Cas 8 : Une NC très dominante (70 vs 10, 8, 4, 2) → mise en évidence de la priorité
    test('Cas 8 : Une NC très dominante (70 vs 10, 8, 4, 2) → priorité marquée', () {
      final findings = <AuditFinding>[];
      final counts = [70, 10, 8, 4, 2];
      for (int c = 0; c < counts.length; c++) {
        for (int i = 0; i < counts[c]; i++) {
          findings.add(AuditFinding(
            id: 'dom_${c}_$i',
            missionId: 'M-8',
            tensionDomain: TensionDomain.bt,
            origin: 'Usine',
            objectType: 'Coffret',
            objectName: 'C_$c',
            tableName: 'Points',
            verificationPoint: c == 0 ? 'Repérage et schémas' : 'Autre défaut $c',
            observationText: 'Obs $c',
            conformity: 'non',
            criticality: 'Majeure',
          ));
        }
      }

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-8',
        findings: findings,
      );

      expect(result.isConcentrated, isTrue);
      expect(result.introNarrative, contains('priorité technique prépondérante'));
      expect(result.axes.first.fullNarrative, contains('Priorité immédiate'));
    });

    // Cas 9 : Nouveau point de vérification non prévu historiquement → intégration dynamique sans erreur
    test('Cas 9 : Nouveau point de vérification non répertorié → inclusion automatique', () {
      final findings = [
        AuditFinding(
          id: 'new_point_1',
          missionId: 'M-9',
          tensionDomain: TensionDomain.bt,
          origin: 'Local Onduleur',
          objectType: 'Système Solaire Hybride',
          objectName: 'Onduleur Photovoltaïque 50kVA',
          tableName: 'Contrôle ENR',
          verificationPoint: 'Synchronisation onduleur et découplage réseau',
          observationText: 'Absence de relais de découplage normalisé VDE',
          conformity: 'non',
          criticality: 'Majeure',
        ),
      ];

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-9',
        findings: findings,
      );

      expect(result.axes.length, equals(1));
      expect(result.axes.first.title, contains('Synchronisation onduleur et découplage réseau'));
      expect(result.axes.first.fullNarrative, contains('Renforcer la maîtrise des règles de l’art'));
      expect(result.axes.first.fullNarrative, contains('Basse Tension'));
    });

    // Cas 10 : Égalité entre plusieurs fréquences → classement déterministe et reproductible
    test('Cas 10 : Égalité parfaite entre plusieurs fréquences → ordre déterministe', () {
      final findings = <AuditFinding>[];
      // 3 points avec exactement 10 constats chacun
      final pts = ['Point Zèbre', 'Point Alpha', 'Point Delta'];
      for (final p in pts) {
        for (int i = 0; i < 10; i++) {
          findings.add(AuditFinding(
            id: 'eq_${p}_$i',
            missionId: 'M-10',
            tensionDomain: TensionDomain.bt,
            origin: 'Local',
            objectType: 'Coffret',
            objectName: 'C',
            tableName: 'Points',
            verificationPoint: p,
            observationText: 'Obs',
            conformity: 'non',
            criticality: 'Majeure',
          ));
        }
      }

      final result1 = CompetencyNeedsEngine.analyze(
        missionId: 'M-10',
        findings: findings,
      );
      final result2 = CompetencyNeedsEngine.analyze(
        missionId: 'M-10',
        findings: findings,
      );

      // Reproductibilité parfaite
      expect(result1.axes.length, equals(3));
      expect(result1.axes[0].title, equals(result2.axes[0].title));
      expect(result1.axes[1].title, equals(result2.axes[1].title));
      expect(result1.axes[2].title, equals(result2.axes[2].title));

      // L'ordre alphabétique secondaire place "Point Alpha" avant "Point Delta", puis "Point Zèbre"
      expect(result1.axes[0].sourceVerificationPoints.first, equals('Point Alpha'));
      expect(result1.axes[1].sourceVerificationPoints.first, equals('Point Delta'));
      expect(result1.axes[2].sourceVerificationPoints.first, equals('Point Zèbre'));
    });
  });

  group('Intégration Documentaire PDF — Section 10 Résumé Exécutif & Section 7 Stats', () {
    test('Génération PDF réussie avec PdfExecutiveSummaryBuilder et sous-section 10 dynamique', () async {
      final mission = Mission(
        id: 'M-TEST-PDF',
        nomClient: 'INDUSTRIE CAMEROUN',
        nomSite: 'SITE DOUALA',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
      );

      final trackedPages = <String, int>{};
      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(1.5 * 28.35),
          build: (ctx) => PdfExecutiveSummaryBuilder.buildResumeExecutif(
            mission,
            trackedPages,
            'KES-2026-RAPPORT-TEST',
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);
      expect(trackedPages.containsKey('resume_executif_1_10'), isTrue);
    });

    test('Génération PDF réussie avec PdfStatisticsBuilder et section 7 harmonisée', () async {
      final mission = Mission(
        id: 'M-TEST-STAT',
        nomClient: 'INDUSTRIE CAMEROUN',
        nomSite: 'SITE DOUALA',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
      );

      final trackedPages = <String, int>{};
      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(1.5 * 28.35),
          build: (ctx) => PdfStatisticsBuilder.buildAnalyseStatistique(
            mission,
            trackedPages,
            'KES-2026-RAPPORT-STAT',
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);
      expect(trackedPages.containsKey('stat_synthese'), isTrue);
    });
  });
}
