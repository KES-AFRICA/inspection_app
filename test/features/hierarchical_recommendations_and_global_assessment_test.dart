// test/features/hierarchical_recommendations_and_global_assessment_test.dart

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/hierarchical_recommendations_engine.dart';
import 'package:inspec_app/services/statistics/global_assessment_engine.dart';
import 'package:inspec_app/services/statistics/mission_statistics.dart';
import 'package:inspec_app/services/ai/executive_summary_snapshot.dart';
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

  AuditFinding createFinding({
    required String id,
    required TensionDomain domain,
    required String criticality,
    required String verificationPoint,
    String observation = 'Constat non conforme',
    String objectType = 'Coffret',
    String objectName = 'Armoire 1',
    String origin = 'Local BT',
    String tableName = 'Dispositions constructives',
    String? normativeRef,
  }) {
    return AuditFinding(
      id: id,
      missionId: 'MISSION_TEST',
      tensionDomain: domain,
      origin: origin,
      objectType: objectType,
      objectName: objectName,
      tableName: tableName,
      verificationPoint: verificationPoint,
      observationText: observation,
      conformity: 'non',
      criticality: criticality,
      normativeReference: normativeRef,
    );
  }

  MissionStatisticsSummary createSummaryFromFindings(
    List<AuditFinding> findings, {
    int htaEquipments = 2,
    int btEquipments = 8,
  }) {
    final inv = AuditFindingInventory(
      missionId: 'MISSION_TEST',
      findings: findings,
      crossCategoryItems: [
        if (htaEquipments > 0)
          CategoryCrossItem(
            categoryKey: 'mt',
            categoryName: 'Poste et équipements Moyenne Tension',
            equipmentCount: htaEquipments,
            totalPointsEvaluated: htaEquipments * 10,
            compliantPointsCount: htaEquipments * 8,
            nonCompliantPointsCount: findings.where((f) => f.tensionDomain == TensionDomain.mt).length,
            naPointsCount: 0,
            critiqueCount: findings.where((f) => f.tensionDomain == TensionDomain.mt && f.criticality.toLowerCase() == 'critique').length,
            majeureCount: findings.where((f) => f.tensionDomain == TensionDomain.mt && f.criticality.toLowerCase() == 'majeure').length,
            mineureCount: findings.where((f) => f.tensionDomain == TensionDomain.mt && f.criticality.toLowerCase() == 'mineure').length,
            complianceRate: 80.0,
            density: findings.where((f) => f.tensionDomain == TensionDomain.mt).length / htaEquipments,
          ),
        if (btEquipments > 0)
          CategoryCrossItem(
            categoryKey: 'bt',
            categoryName: 'Intégrité des enveloppes, armoires et coffrets',
            equipmentCount: btEquipments,
            totalPointsEvaluated: btEquipments * 15,
            compliantPointsCount: btEquipments * 12,
            nonCompliantPointsCount: findings.where((f) => f.tensionDomain == TensionDomain.bt).length,
            naPointsCount: 0,
            critiqueCount: findings.where((f) => f.tensionDomain == TensionDomain.bt && f.criticality.toLowerCase() == 'critique').length,
            majeureCount: findings.where((f) => f.tensionDomain == TensionDomain.bt && f.criticality.toLowerCase() == 'majeure').length,
            mineureCount: findings.where((f) => f.tensionDomain == TensionDomain.bt && f.criticality.toLowerCase() == 'mineure').length,
            complianceRate: 85.0,
            density: findings.where((f) => f.tensionDomain == TensionDomain.bt).length / btEquipments,
          ),
      ],
    );
    return MissionStatisticsSummary.fromInventory(inv);
  }

  ExecutiveSummarySnapshot createDummySnapshot() {
    return ExecutiveSummarySnapshot(
      missionId: 'MISSION_TEST',
      clientName: 'KES Client Industriel',
      siteName: 'Site Principal Bassa',
      natureMission: 'Vérification périodique réglementaire',
      dateRangeText: '21/09/2026',
      domainTension: 'HTA / BT',
      companyName: 'KES Inspections & Projects',
      reportNumber: 'KES/IP/VE/2026/001',
      reportDateStr: '21/09/2026',
      officialStats: const {},
      categoryStats: const [],
      topDefects: const [],
      riskFamilies: const [],
      equipmentCount: 10,
      installationsCount: 1,
      globalDensityStr: '2,5',
    );
  }

  group('Refonte Sections 11 & 12 — Suite des 16 Cas Obligatoires', () {
    // Cas 1 : Mission avec MT + BT + plusieurs criticités
    test('Cas 1 : Mission avec MT + BT + plusieurs criticités', () {
      final findings = [
        createFinding(id: '1', domain: TensionDomain.mt, criticality: 'Critique', verificationPoint: 'Verrouillage cellule MT', objectType: 'Cellule MT'),
        createFinding(id: '2', domain: TensionDomain.mt, criticality: 'Majeure', verificationPoint: 'Surveillance transfo MT', objectType: 'Transfo'),
        createFinding(id: '3', domain: TensionDomain.bt, criticality: 'Critique', verificationPoint: 'Obturation plastron armoire', objectType: 'Armoire'),
        createFinding(id: '4', domain: TensionDomain.bt, criticality: 'Majeure', verificationPoint: 'Repérage des départs', objectType: 'Coffret'),
        createFinding(id: '5', domain: TensionDomain.bt, criticality: 'Mineure', verificationPoint: 'Nettoyage poussière coffret', objectType: 'Coffret'),
      ];

      final res = HierarchicalRecommendationsEngine.analyzeFindings(findings);

      expect(res.hasMt, isTrue);
      expect(res.hasBt, isTrue);
      expect(res.mtRecommendations.length, 2);
      expect(res.btRecommendations.length, 3);
      expect(res.allRecommendations.length, 5);

      // Vérifier la stricte étanchéité MT/BT
      for (final r in res.mtRecommendations) {
        expect(r.domain, TensionDomain.mt);
        expect(r.domainLabel, 'HTA');
      }
      for (final r in res.btRecommendations) {
        expect(r.domain, TensionDomain.bt);
        expect(r.domainLabel, 'BT');
      }

      // Vérifier les priorités
      expect(res.countImmediate, 2);
      expect(res.countShortTerm, 2);
      expect(res.countMediumTerm, 1);

      // Vérifier la nouvelle structure à 3 lignes par tableau MT et BT
      expect(res.mtTable.rows.length, 3);
      expect(res.mtTable.critiqueAction.hasActions, isTrue);
      expect(res.mtTable.majeureAction.hasActions, isTrue);
      expect(res.mtTable.mineureAction.hasActions, isFalse);
      expect(res.mtTable.mineureAction.actionBullets, isEmpty);

      expect(res.btTable.rows.length, 3);
      expect(res.btTable.critiqueAction.hasActions, isTrue);
      expect(res.btTable.majeureAction.hasActions, isTrue);
      expect(res.btTable.mineureAction.hasActions, isTrue);
      expect(res.btTable.mineureAction.actionBullets, isNotEmpty);

      // Vérifier l'évaluation globale Section 12
      final summary = createSummaryFromFindings(findings);
      final assess = GlobalAssessmentEngine.analyze(
        summary: summary,
        snapshot: createDummySnapshot(),
        recommendationsResult: res,
      );

      expect(assess.operationalPrioritiesText, contains('Priorité 1'));
      expect(assess.operationalPrioritiesText, contains('Priorité 2'));
      expect(assess.operationalPrioritiesText, contains('Priorité 3'));
      expect(assess.operationalPrioritiesText, contains('Moyenne Tension (2 recommandations)'));
      expect(assess.operationalPrioritiesText, contains('Basse Tension (3 recommandations)'));
    });

    // Cas 2 : Mission uniquement MT
    test('Cas 2 : Mission uniquement MT', () {
      final findings = [
        createFinding(id: '1', domain: TensionDomain.mt, criticality: 'Critique', verificationPoint: 'Verrouillage cellule MT'),
        createFinding(id: '2', domain: TensionDomain.mt, criticality: 'Majeure', verificationPoint: 'Relais de protection MT'),
      ];

      final res = HierarchicalRecommendationsEngine.analyzeFindings(findings);

      expect(res.hasMt, isTrue);
      expect(res.hasBt, isFalse);
      expect(res.btRecommendations, isEmpty);
      expect(res.mtTable.critiqueAction.hasActions, isTrue);
      expect(res.mtTable.majeureAction.hasActions, isTrue);
      expect(res.mtTable.mineureAction.hasActions, isFalse);
      expect(res.btTable.hasAnyAction, isFalse);

      final summary = createSummaryFromFindings(findings, htaEquipments: 5, btEquipments: 0);
      final assess = GlobalAssessmentEngine.analyze(
        summary: summary,
        snapshot: createDummySnapshot(),
        recommendationsResult: res,
      );

      expect(assess.paretoOrTensionText, contains('exclusivement du domaine de la **Moyenne Tension (HTA)**'));
      expect(assess.operationalPrioritiesText, contains('Moyenne Tension (HTA)'));
    });

    // Cas 3 : Mission uniquement BT
    test('Cas 3 : Mission uniquement BT', () {
      final findings = [
        createFinding(id: '1', domain: TensionDomain.bt, criticality: 'Majeure', verificationPoint: 'Mise à la terre TGBT'),
        createFinding(id: '2', domain: TensionDomain.bt, criticality: 'Majeure', verificationPoint: 'Coupure d\'urgence inverseur'),
      ];

      final res = HierarchicalRecommendationsEngine.analyzeFindings(findings);

      expect(res.hasMt, isFalse);
      expect(res.hasBt, isTrue);
      expect(res.mtRecommendations, isEmpty);
      expect(res.mtTable.hasAnyAction, isFalse);
      expect(res.btTable.majeureAction.hasActions, isTrue);
      expect(res.btTable.critiqueAction.hasActions, isFalse);
      expect(res.btTable.mineureAction.hasActions, isFalse);

      final summary = createSummaryFromFindings(findings, htaEquipments: 0, btEquipments: 12);
      final assess = GlobalAssessmentEngine.analyze(
        summary: summary,
        snapshot: createDummySnapshot(),
        recommendationsResult: res,
      );

      expect(assess.paretoOrTensionText, contains('exclusivement du domaine de la **Basse Tension (BT)**'));
      expect(assess.operationalPrioritiesText, contains('Basse Tension (BT)'));
    });

    // Cas 4 : Aucune NC mineure (0 NC mineure -> 0 recommandation Priorité 3)
    test('Cas 4 : Aucune NC mineure (zéro recommandation Priorité 3 inventée)', () {
      final findings = [
        createFinding(id: '1', domain: TensionDomain.bt, criticality: 'Critique', verificationPoint: 'Contact direct IP2X'),
        createFinding(id: '2', domain: TensionDomain.bt, criticality: 'Majeure', verificationPoint: 'Disjoncteur non calibré'),
      ];

      final res = HierarchicalRecommendationsEngine.analyzeFindings(findings);

      expect(res.totalMineure, 0);
      expect(res.countMediumTerm, 0);
      expect(res.allRecommendations.any((r) => r.priorityLevel == RecommendationPriorityLevel.priority3MediumTerm), isFalse);

      // Vérification absolue du tableau synthétique : ZÉRO action inventée pour la ligne Mineure
      expect(res.btTable.mineureAction.hasActions, isFalse);
      expect(res.btTable.mineureAction.occurrenceCount, 0);
      expect(res.btTable.mineureAction.actionBullets, isEmpty);
      expect(res.btTable.critiqueAction.hasActions, isTrue);
      expect(res.btTable.majeureAction.hasActions, isTrue);

      final summary = createSummaryFromFindings(findings);
      final assess = GlobalAssessmentEngine.analyze(
        summary: summary,
        snapshot: createDummySnapshot(),
        recommendationsResult: res,
      );

      expect(assess.perimeterAndCriticalityText, contains('aucune non-conformité mineure n’ayant été recensée'));
      expect(assess.operationalPrioritiesText, isNot(contains('Priorité 3')));
    });

    // Cas 5 : Aucune NC majeure
    test('Cas 5 : Aucune NC majeure', () {
      final findings = [
        createFinding(id: '1', domain: TensionDomain.bt, criticality: 'Critique', verificationPoint: 'Contact direct'),
        createFinding(id: '2', domain: TensionDomain.bt, criticality: 'Mineure', verificationPoint: 'Étiquette décollée'),
      ];

      final res = HierarchicalRecommendationsEngine.analyzeFindings(findings);

      expect(res.totalMajeure, 0);
      expect(res.countShortTerm, 0);
      expect(res.allRecommendations.any((r) => r.priorityLevel == RecommendationPriorityLevel.priority2ShortTerm), isFalse);
    });

    // Cas 6 : Aucune NC critique
    test('Cas 6 : Aucune NC critique', () {
      final findings = [
        createFinding(id: '1', domain: TensionDomain.bt, criticality: 'Majeure', verificationPoint: 'Défaut différentiel DDR'),
        createFinding(id: '2', domain: TensionDomain.bt, criticality: 'Mineure', verificationPoint: 'Éclairage voyant'),
      ];

      final res = HierarchicalRecommendationsEngine.analyzeFindings(findings);

      expect(res.totalCritique, 0);
      expect(res.countImmediate, 0);
      expect(res.allRecommendations.any((r) => r.priorityLevel == RecommendationPriorityLevel.priority1Immediate), isFalse);
    });

    // Cas 7 : Très forte concentration sur un défaut
    test('Cas 7 : Très forte concentration sur un défaut (obturation IP2X)', () {
      final findings = <AuditFinding>[];
      // 20 occurrences du même défaut IP2X
      for (int i = 0; i < 20; i++) {
        findings.add(createFinding(
          id: 'ip2x_$i',
          domain: TensionDomain.bt,
          criticality: 'Critique',
          verificationPoint: 'Obturation alvéole IP2X',
          objectName: 'Coffret $i',
        ));
      }
      // 1 occurrence isolée
      findings.add(createFinding(
        id: 'autre_1',
        domain: TensionDomain.bt,
        criticality: 'Critique',
        verificationPoint: 'Arrêt d\'urgence défectueux',
        objectName: 'Armoire A',
      ));

      final res = HierarchicalRecommendationsEngine.analyzeFindings(findings);

      expect(res.btRecommendations.length, 2);
      expect(res.btRecommendations.first.issueTitle, contains('Obturation'));
      expect(res.btRecommendations.first.occurrenceCount, 20);
      expect(res.btRecommendations.first.impactedEquipments.length, 20);
    });

    // Cas 8 : NC très dispersées (10 défauts distincts)
    test('Cas 8 : NC très dispersées (aucune fusion abusive)', () {
      final points = [
        'Point A', 'Point B', 'Point C', 'Point D', 'Point E',
        'Point F', 'Point G', 'Point H', 'Point I', 'Point J'
      ];
      final findings = points.map((p) => createFinding(
        id: p,
        domain: TensionDomain.bt,
        criticality: 'Majeure',
        verificationPoint: p,
      )).toList();

      final res = HierarchicalRecommendationsEngine.analyzeFindings(findings);

      expect(res.btRecommendations.length, 10);
      for (final r in res.btRecommendations) {
        expect(r.occurrenceCount, 1);
      }
    });

    // Cas 9 : Égalité de fréquence entre plusieurs défauts (départage déterministe)
    test('Cas 9 : Égalité de fréquence entre défauts (départage stable alphabétique)', () {
      final findings = [
        createFinding(id: '1', domain: TensionDomain.bt, criticality: 'Majeure', verificationPoint: 'Zebra point'),
        createFinding(id: '2', domain: TensionDomain.bt, criticality: 'Majeure', verificationPoint: 'Alpha point'),
        createFinding(id: '3', domain: TensionDomain.bt, criticality: 'Majeure', verificationPoint: 'Beta point'),
      ];

      final res1 = HierarchicalRecommendationsEngine.analyzeFindings(findings);
      final res2 = HierarchicalRecommendationsEngine.analyzeFindings(findings);

      expect(res1.btRecommendations.map((r) => r.issueTitle).toList(),
          res2.btRecommendations.map((r) => r.issueTitle).toList());
      expect(res1.btRecommendations.first.issueTitle, 'Alpha point');
      expect(res1.btRecommendations.last.issueTitle, 'Zebra point');
    });

    // Cas 10 : Aucun équipement MT
    test('Cas 10 : Aucun équipement MT', () {
      final findings = [
        createFinding(id: '1', domain: TensionDomain.bt, criticality: 'Majeure', verificationPoint: 'Terre PE'),
      ];
      final summary = createSummaryFromFindings(findings, htaEquipments: 0, btEquipments: 10);
      final assess = GlobalAssessmentEngine.analyze(
        summary: summary,
        snapshot: createDummySnapshot(),
      );

      expect(assess.perimeterAndCriticalityText, contains('10 équipements contrôlés en Basse Tension'));
      expect(assess.perimeterAndCriticalityText, isNot(contains('Moyenne Tension')));
    });

    // Cas 11 : Aucun équipement BT
    test('Cas 11 : Aucun équipement BT', () {
      final findings = [
        createFinding(id: '1', domain: TensionDomain.mt, criticality: 'Majeure', verificationPoint: 'Cellule MT'),
      ];
      final summary = createSummaryFromFindings(findings, htaEquipments: 4, btEquipments: 0);
      final assess = GlobalAssessmentEngine.analyze(
        summary: summary,
        snapshot: createDummySnapshot(),
      );

      expect(assess.perimeterAndCriticalityText, contains('4 équipements contrôlés en Moyenne Tension'));
      expect(assess.perimeterAndCriticalityText, isNot(contains('Basse Tension')));
    });

    // Cas 12 : Nouveaux points de vérification (libellé inédit)
    test('Cas 12 : Nouveaux points de vérification (libellé inédit)', () {
      final findings = [
        createFinding(
          id: 'inedit_1',
          domain: TensionDomain.bt,
          criticality: 'Majeure',
          verificationPoint: 'Capteur optique thermique de tableau',
          observation: 'Capteur défaillant',
        ),
      ];

      final res = HierarchicalRecommendationsEngine.analyzeFindings(findings);

      expect(res.btRecommendations.length, 1);
      expect(res.btRecommendations.first.issueTitle, 'Capteur optique thermique de tableau');
      expect(res.btRecommendations.first.recommendedAction, contains('Capteur optique thermique de tableau'));
    });

    // Cas 13 : Mission très volumineuse (150+ NC)
    test('Cas 13 : Mission très volumineuse (150+ NC)', () {
      final findings = <AuditFinding>[];
      for (int i = 0; i < 160; i++) {
        findings.add(createFinding(
          id: 'finding_$i',
          domain: i % 4 == 0 ? TensionDomain.mt : TensionDomain.bt,
          criticality: i % 3 == 0 ? 'Critique' : (i % 3 == 1 ? 'Majeure' : 'Mineure'),
          verificationPoint: 'Point de vérification N°${i % 15}',
          objectName: 'Équipement $i',
        ));
      }

      final res = HierarchicalRecommendationsEngine.analyzeFindings(findings);

      expect(res.totalOccurrences, 160);
      expect(res.mtRecommendations, isNotEmpty);
      expect(res.btRecommendations, isNotEmpty);
      expect(res.totalCritique + res.totalMajeure + res.totalMineure, 160);
    });

    // Cas 14 : Mission avec très peu de données (1 seule NC)
    test('Cas 14 : Mission avec très peu de données (1 seule NC)', () {
      final findings = [
        createFinding(
          id: 'single_1',
          domain: TensionDomain.bt,
          criticality: 'Majeure',
          verificationPoint: 'Serrage bornier départ D1',
          objectName: 'Coffret C1',
        ),
      ];

      final res = HierarchicalRecommendationsEngine.analyzeFindings(findings);

      expect(res.totalOccurrences, 1);
      expect(res.allRecommendations.length, 1);
      expect(res.btRecommendations.first.impactedEquipments, ['Coffret C1']);
      expect(res.hasMt, isFalse);
    });

    // Cas 15 : Mission 100 % conforme (0 NC)
    test('Cas 15 : Mission 100 % conforme (0 NC)', () {
      final findings = <AuditFinding>[];
      final res = HierarchicalRecommendationsEngine.analyzeFindings(findings);

      expect(res.isEmpty, isTrue);
      expect(res.allRecommendations, isEmpty);
      expect(res.mtTable.hasAnyAction, isFalse);
      expect(res.btTable.hasAnyAction, isFalse);
      expect(res.mtTable.critiqueAction.actionBullets, isEmpty);
      expect(res.mtTable.majeureAction.actionBullets, isEmpty);
      expect(res.mtTable.mineureAction.actionBullets, isEmpty);
      expect(res.btTable.critiqueAction.actionBullets, isEmpty);
      expect(res.btTable.majeureAction.actionBullets, isEmpty);
      expect(res.btTable.mineureAction.actionBullets, isEmpty);

      final summary = createSummaryFromFindings(findings, htaEquipments: 2, btEquipments: 5);
      final assess = GlobalAssessmentEngine.analyze(
        summary: summary,
        snapshot: createDummySnapshot(),
        recommendationsResult: res,
      );

      expect(assess.riskLevel, GlobalRiskProfileLevel.excellentOrZeroDefect);
      expect(assess.perimeterAndCriticalityText, contains('très satisfaisant'));
      expect(assess.operationalPrioritiesText, contains('absence de non-conformité constatée'));
      expect(assess.finalAppreciationText, contains('excellent niveau'));
    });

    // Cas 16 : Cohérence croisée absolue des chiffres
    test('Cas 16 : Cohérence croisée absolue des chiffres (Totaux, Domaines, Criticités)', () {
      final findings = [
        createFinding(id: '1', domain: TensionDomain.mt, criticality: 'Critique', verificationPoint: 'A'),
        createFinding(id: '2', domain: TensionDomain.mt, criticality: 'Majeure', verificationPoint: 'B'),
        createFinding(id: '3', domain: TensionDomain.bt, criticality: 'Critique', verificationPoint: 'C'),
        createFinding(id: '4', domain: TensionDomain.bt, criticality: 'Majeure', verificationPoint: 'D'),
        createFinding(id: '5', domain: TensionDomain.bt, criticality: 'Majeure', verificationPoint: 'E'),
        createFinding(id: '6', domain: TensionDomain.bt, criticality: 'Mineure', verificationPoint: 'F'),
      ];

      final res = HierarchicalRecommendationsEngine.analyzeFindings(findings);
      final summary = createSummaryFromFindings(findings);

      final totFindings = findings.length;
      final mtFindings = findings.where((f) => f.tensionDomain == TensionDomain.mt).length;
      final btFindings = findings.where((f) => f.tensionDomain == TensionDomain.bt).length;

      expect(res.totalOccurrences, totFindings);
      expect(summary.totalNC, totFindings);
      expect(summary.tensionDomainStats.mtCount, mtFindings);
      expect(summary.tensionDomainStats.btCount, btFindings);
      expect(res.totalCritique, summary.criticalityStats.critique);
      expect(res.totalMajeure, summary.criticalityStats.majeure);
      expect(res.totalMineure, summary.criticalityStats.mineure);
    });

    // Cas 17 : Regroupement intelligent par famille technique au sein de la même cellule
    test('Cas 17 : Regroupement par famille technique dans la même cellule (sans doublon ni invention)', () {
      final findings = [
        createFinding(id: '1', domain: TensionDomain.bt, criticality: 'Majeure', verificationPoint: 'Repérage des départs', objectName: 'Armoire TGBT'),
        createFinding(id: '2', domain: TensionDomain.bt, criticality: 'Majeure', verificationPoint: 'Étiquetage des circuits', objectName: 'Coffret C1'),
        createFinding(id: '3', domain: TensionDomain.bt, criticality: 'Majeure', verificationPoint: 'Absence de schéma unifilaire', objectName: 'Coffret C2'),
        createFinding(id: '4', domain: TensionDomain.bt, criticality: 'Majeure', verificationPoint: 'Continuité de terre PE interrompue', objectName: 'Armoire TGBT'),
      ];

      final res = HierarchicalRecommendationsEngine.analyzeFindings(findings);

      expect(res.btTable.majeureAction.hasActions, isTrue);
      expect(res.btTable.majeureAction.occurrenceCount, 4);

      // Repérage/étiquetage/schéma unifilaire doivent être regroupés dans une même famille technique
      // Continuité PE forme sa propre famille distincte
      // On doit donc avoir 2 puces d'actions pour la cellule Majeure BT
      expect(res.btTable.majeureAction.actionBullets.length, 2);

      final repBullet = res.btTable.majeureAction.actionBullets.firstWhere((b) => b.toLowerCase().contains('repérage'));
      final peBullet = res.btTable.majeureAction.actionBullets.firstWhere((b) => b.toLowerCase().contains('continuité'));

      expect(repBullet, isNotEmpty);
      expect(peBullet, isNotEmpty);
      expect(repBullet, isNot(contains('Concerne')));
      expect(repBullet, isNot(contains('NF C')));
      expect(peBullet, isNot(contains('Concerne')));
      expect(peBullet, isNot(contains('NF C')));
    });
  });
}
