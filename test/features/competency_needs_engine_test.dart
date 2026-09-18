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

  group('CompetencyNeedsEngine — Tests Unitaires & Profils Statistiques', () {
    test('Scénario A : Forte concentration — 2 thématiques majeures (ex: Identification 112 et Câblage 107)', () {
      final findings = <AuditFinding>[];
      // 112 constats Identification & Schémas
      for (int i = 0; i < 112; i++) {
        findings.add(
          AuditFinding(
            id: 'id_$i',
            missionId: 'M-001',
            tensionDomain: TensionDomain.bt,
            origin: 'Local TGBT',
            objectType: 'Armoire',
            objectName: 'Armoire Climatisation $i',
            tableName: 'Points de vérification',
            verificationPoint: 'Repérage et étiquetage des départs et circuits',
            observationText: 'Absence de repérage et schéma unifilaire non disponible',
            conformity: 'non',
            criticality: i < 10 ? 'Critique' : 'Majeure',
            riskFamily: 'Erreur d\'exploitation / maintenance',
          ),
        );
      }
      // 107 constats Câblage & Serrage
      for (int i = 0; i < 107; i++) {
        findings.add(
          AuditFinding(
            id: 'cab_$i',
            missionId: 'M-001',
            tensionDomain: TensionDomain.bt,
            origin: 'Atelier',
            objectType: 'Coffret',
            objectName: 'Coffret Prises $i',
            tableName: 'Points de vérification',
            verificationPoint: 'Serrage des connexions et passage de câbles',
            observationText: 'Connexions lâches et absence de protection mécanique sur câblage',
            conformity: 'non',
            criticality: i < 5 ? 'Critique' : 'Majeure',
            riskFamily: 'Dégradation des canalisations et matériels',
          ),
        );
      }
      // 10 constats Terre
      for (int i = 0; i < 10; i++) {
        findings.add(
          AuditFinding(
            id: 'terre_$i',
            missionId: 'M-001',
            tensionDomain: TensionDomain.bt,
            origin: 'Local TGBT',
            objectType: 'TGBT',
            objectName: 'TGBT Principal',
            tableName: 'Points de vérification',
            verificationPoint: 'Continuité des liaisons équipotentielles',
            observationText: 'Liaison équipotentielle non raccordée',
            conformity: 'non',
            criticality: 'Majeure',
            riskFamily: 'Électrisation / électrocution',
          ),
        );
      }

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-001',
        findings: findings,
        totalNC: findings.length,
      );

      expect(result.totalOccurrences, equals(229));
      expect(result.isConcentrated, isTrue);
      expect(result.axes.isNotEmpty, isTrue);

      // Le premier axe doit être l'axe le plus fréquent (112 constats)
      final top1 = result.axes.first;
      expect(top1.letter, equals('a)'));
      expect(top1.title, contains('Identification'));
      expect(top1.occurrenceCount, equals(112));
      expect(top1.percentageStr, equals('48,9'));
      expect(top1.critiqueCount, equals(10));

      // Le deuxième axe doit être le second plus fréquent (107 constats)
      final top2 = result.axes[1];
      expect(top2.letter, equals('b)'));
      expect(top2.title, contains('Câblage'));
      expect(top2.occurrenceCount, equals(107));
      expect(top2.percentageStr, equals('46,7'));
      expect(top2.critiqueCount, equals(5));

      // Le troisième axe : Terre
      final top3 = result.axes[2];
      expect(top3.letter, equals('c)'));
      expect(top3.title, contains('terre'));
      expect(top3.occurrenceCount, equals(10));

      // Vérifier le texte narratif d'introduction dynamique
      expect(result.introNarrative, contains('forte concentration des écarts autour de deux thématiques'));
      expect(result.introNarrative, contains('112 constats'));
      expect(result.introNarrative, contains('107 constats'));
    });

    test('Scénario B : Distribution homogène / dispersée sur plusieurs domaines', () {
      final findings = <AuditFinding>[];
      final topics = [
        ('Repérage des départs', 'Schéma unifilaire manquant', 'Armoire', 15),
        ('Vérification des disjoncteurs', 'Calibre inadapté et pouvoir de coupure', 'TGBT', 14),
        ('Contrôle de mise à la terre', 'Prise de terre non mesurée', 'Local MT', 13),
        ('Câblage et serrage', 'Connexions lâches sur bornier', 'Coffret', 12),
        ('Plastron et obturateur', 'Ouverture béante sans plastron IP', 'Armoire', 11),
        ('Bloc autonome BAES', 'Batterie d\'éclairage de sécurité déchargée', 'Local BT', 10),
      ];

      int id = 0;
      for (final t in topics) {
        for (int i = 0; i < t.$4; i++) {
          findings.add(
            AuditFinding(
              id: 'f_${id++}',
              missionId: 'M-DISP',
              tensionDomain: TensionDomain.bt,
              origin: 'Site Industriel',
              objectType: t.$3,
              objectName: '${t.$3} $i',
              tableName: 'Points de vérification',
              verificationPoint: t.$1,
              observationText: t.$2,
              conformity: 'non',
              criticality: 'Majeure',
            ),
          );
        }
      }

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-DISP',
        findings: findings,
        totalNC: findings.length,
      );

      expect(result.totalOccurrences, equals(75));
      expect(result.isDispersed, isTrue);
      // Les axes doivent être triés par nombre d'occurrences décroissant
      for (int i = 0; i < result.axes.length - 1; i++) {
        expect(
          result.axes[i].occurrenceCount >= result.axes[i + 1].occurrenceCount,
          isTrue,
          reason: 'Les axes doivent être strictement classés par occurrences décroissantes',
        );
      }
      expect(result.introNarrative, contains('répartition des écarts sur plusieurs registres techniques'));
    });

    test('Scénario C : Très peu de non-conformités (2 constats) — Ne force PAS 8 axes', () {
      final findings = [
        AuditFinding(
          id: 'single_1',
          missionId: 'M-FEW',
          tensionDomain: TensionDomain.bt,
          origin: 'Local Technique',
          objectType: 'Coffret',
          objectName: 'Coffret Éclairage',
          tableName: 'Points de vérification',
          verificationPoint: 'Serrage des bornes',
          observationText: 'Connexion mal serrée',
          conformity: 'non',
          criticality: 'Majeure',
        ),
        AuditFinding(
          id: 'single_2',
          missionId: 'M-FEW',
          tensionDomain: TensionDomain.bt,
          origin: 'Local Technique',
          objectType: 'Coffret',
          objectName: 'Coffret Éclairage',
          tableName: 'Points de vérification',
          verificationPoint: 'Repérage du circuit',
          observationText: 'Étiquette absente',
          conformity: 'non',
          criticality: 'Mineure',
        ),
      ];

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-FEW',
        findings: findings,
        totalNC: 2,
      );

      expect(result.totalOccurrences, equals(2));
      // RÈGLE ABSOLUE : exactement 2 axes produits, PAS 8 axes inventés !
      expect(result.axes.length, equals(2));
      expect(result.axes[0].letter, equals('a)'));
      expect(result.axes[1].letter, equals('b)'));
      expect(result.axes[0].occurrenceCount, equals(1));
      expect(result.axes[1].occurrenceCount, equals(1));
    });

    test('Scénario D : Zéro non-conformité (Mission 100% conforme)', () {
      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-ZERO',
        findings: [],
        totalNC: 0,
      );

      expect(result.totalOccurrences, equals(0));
      expect(result.hasNoDefects, isTrue);
      expect(result.axes, isEmpty);
      expect(result.introNarrative, contains('aucun constat de non-conformité'));
    });

    test('Scénario E : Mission avec forte composante HTA (Poste Moyenne Tension)', () {
      final findings = <AuditFinding>[
        AuditFinding(
          id: 'hta_1',
          missionId: 'M-HTA',
          tensionDomain: TensionDomain.mt,
          origin: 'Poste Livraison HTA',
          objectType: 'Cellule MT',
          objectName: 'Cellule Arrivée 01',
          tableName: 'Cellule audit',
          verificationPoint: 'Interverrouillage et mise à la terre MT',
          observationText: 'Séquence de verrouillage mécanique défectueuse sur sectionneur MT',
          conformity: 'non',
          criticality: 'Critique',
        ),
        AuditFinding(
          id: 'hta_2',
          missionId: 'M-HTA',
          tensionDomain: TensionDomain.mt,
          origin: 'Poste Livraison HTA',
          objectType: 'Transformateur MT/BT',
          objectName: 'Transformateur 630kVA',
          tableName: 'Transformateur audit',
          verificationPoint: 'Surveillance relais DGPT2 et diélectrique',
          observationText: 'Fuite légère sur joint de cuve diélectrique transfo',
          conformity: 'non',
          criticality: 'Majeure',
        ),
      ];

      final tensionStats = TensionDomainStats(
        mtCount: 2,
        btCount: 0,
        totalCount: 2,
        mtPct: 100.0,
        btPct: 0.0,
      );

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-HTA',
        findings: findings,
        totalNC: 2,
        tensionDomainStats: tensionStats,
      );

      expect(result.axes.first.id, equals('poste_haute_tension_mt'));
      expect(result.axes.first.hasMtDomain, isTrue);
      expect(result.introNarrative, contains('Moyenne Tension (HTA)'));
    });

    test('Scénario F : Cohérence statistique stricte', () {
      final findings = <AuditFinding>[
        AuditFinding(
          id: 'f1',
          missionId: 'M-COH',
          tensionDomain: TensionDomain.bt,
          origin: 'TGBT',
          objectType: 'TGBT',
          objectName: 'TGBT',
          tableName: 'Points de vérification',
          verificationPoint: 'Disjoncteur calibre',
          observationText: 'Calibre non conforme',
          conformity: 'non',
          criticality: 'Critique',
        ),
        AuditFinding(
          id: 'f2',
          missionId: 'M-COH',
          tensionDomain: TensionDomain.bt,
          origin: 'TGBT',
          objectType: 'TGBT',
          objectName: 'TGBT',
          tableName: 'Points de vérification',
          verificationPoint: 'Repérage',
          observationText: 'Repérage absent',
          conformity: 'non',
          criticality: 'Majeure',
        ),
      ];

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-COH',
        findings: findings,
        totalNC: 2,
      );

      int sumOccurrences = 0;
      for (final a in result.axes) {
        expect(a.occurrenceCount, greaterThan(0));
        expect(a.percentage, greaterThan(0.0));
        expect(a.percentage, lessThanOrEqualTo(100.0));
        sumOccurrences += a.occurrenceCount;
      }
      expect(sumOccurrences, equals(2));
    });

    test('Scénario G : Synthèse épurée sans informations de localisation détaillées (Règle Sous-section 10)', () {
      final findings = <AuditFinding>[
        AuditFinding(
          id: 'g1',
          missionId: 'M-SYNTH',
          tensionDomain: TensionDomain.mt,
          origin: 'Zone MT "Zone PETCOKE" / Local "Local transformateur 1600 KVA"',
          objectType: 'Cellule MT',
          objectName: 'Cellule Arrivée HTA 01',
          tableName: 'Cellule audit',
          verificationPoint: 'Interverrouillage et mise à la terre MT',
          observationText: 'Séquence mécanique bloquée',
          conformity: 'non',
          criticality: 'Critique',
        ),
        AuditFinding(
          id: 'g2',
          missionId: 'M-SYNTH',
          tensionDomain: TensionDomain.bt,
          origin: 'Zone BT "Zone locaux transformateurs VRM. RAW MILL" / Local "Local électrique VRM Raw Mill"',
          objectType: 'Local MT',
          objectName: 'Local Électrique',
          tableName: 'Points de vérification',
          verificationPoint: 'DGPT2 et diélectrique',
          observationText: 'Fuite diélectrique',
          conformity: 'non',
          criticality: 'Majeure',
        ),
      ];

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'M-SYNTH',
        findings: findings,
        totalNC: 2,
      );

      expect(result.axes.isNotEmpty, isTrue);
      for (final axis in result.axes) {
        final narrative = axis.fullNarrative;

        // 1. Structure attendue : compétence, besoin factuel/chiffré, finalité opérationnelle
        expect(narrative, contains(axis.recommendedSkills.trim()));
        expect(narrative, contains(axis.rationale.trim()));
        expect(narrative, contains(axis.operationalObjective.trim()));

        // 2. Suppression stricte de toutes informations de localisation ou descriptions d'installations
        expect(narrative.contains('Ces constats ont été observés principalement'), isFalse);
        expect(narrative.contains('Zone PETCOKE'), isFalse);
        expect(narrative.contains('VRM. RAW MILL'), isFalse);
        expect(narrative.contains('VRM Raw Mill'), isFalse);
        expect(narrative.contains('Local transformateur 1600 KVA'), isFalse);
        expect(narrative.contains('au sein de :'), isFalse);
        expect(narrative.contains('sur les Local MT et Cellule MT'), isFalse);
      }
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
