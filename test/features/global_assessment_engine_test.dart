// test/features/global_assessment_engine_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/ai/executive_summary_snapshot.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/global_assessment_engine.dart';
import 'package:inspec_app/services/statistics/mission_statistics.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';
import 'package:inspec_app/services/pdf/builders/pdf_executive_summary_builder.dart';

void main() {
  group('GlobalAssessmentEngine — Tests unitaires et multi-scénarios', () {
    test('Scénario A : Mission type industrie lourde (CIMENCAM - FIGUIL, 496 NC, 93 Critiques, 403 Majeures)', () {
      final findings = <AuditFinding>[];

      // 93 critiques
      for (int i = 0; i < 93; i++) {
        findings.add(AuditFinding(
          id: 'crit_$i',
          missionId: 'miss_cimencam',
          tensionDomain: TensionDomain.bt,
          origin: 'Local BT',
          objectType: 'Coffret',
          objectName: 'Armoire A$i',
          tableName: 'Points de vérification',
          verificationPoint: i % 2 == 0
              ? 'L’identification et le repérage des circuits'
              : 'La mise à la terre et parafoudre',
          observationText: 'Observation critique $i',
          conformity: 'non',
          criticality: 'Critique',
          riskFamily: 'Erreurs d\'exploitation et de maintenance',
          photos: const [],
        ));
      }

      // 403 majeures
      for (int i = 0; i < 403; i++) {
        final fam = (i < 214)
            ? 'Erreurs d\'exploitation et de maintenance'
            : (i < 339
                ? 'Dégradation des canalisations et matériels'
                : 'Absence ou inefficacité de la protection contre les contacts indirects');

        findings.add(AuditFinding(
          id: 'maj_$i',
          missionId: 'miss_cimencam',
          tensionDomain: TensionDomain.bt,
          origin: 'Local BT',
          objectType: 'Coffret',
          objectName: 'Armoire B$i',
          tableName: 'Points de vérification',
          verificationPoint: (i % 3 == 0)
              ? 'Câblages et serrages des connexions'
              : ((i % 3 == 1)
                  ? 'Protection IP/IK et enveloppes'
                  : 'Présence des EPI et tapis isolant diélectrique'),
          observationText: 'Observation majeure $i',
          conformity: 'non',
          criticality: 'Majeure',
          riskFamily: fam,
          photos: const [],
        ));
      }

      final inventory = AuditFindingInventory(
        missionId: 'miss_cimencam',
        findings: findings,
      );

      // 168 équipements -> densité 496 / 168 = 2.952 -> 2,95
      final eqItems = [
        EquipmentInventoryItem(label: 'Armoires BT', count: 168),
      ];

      final summary = MissionStatisticsSummary(
        missionId: 'miss_cimencam',
        inventory: inventory,
        criticalityStats: CriticalityStats(
          critique: 93,
          majeure: 403,
          mineure: 0,
          total: 496,
          pctCritique: 18.75, // 18,8 %
          pctMajeure: 81.25, // 81,3 %
          pctMineure: 0.0,
        ),
        topDefects: const [],
        paretoResult: ParetoAnalysisResult(
          items: const [],
          totalOccurrences: 496,
          paretoCategoryCount: 5,
          paretoCumulativePercentage: 82.0,
          summaryText: 'Pareto summary',
        ),
        topTwoCategoriesResult: TopNonConformityCategoriesResult(
          label: 'Armoires BT',
          cat1Name: 'Armoires BT',
          cat2Name: 'Locaux',
          combinedNC: 496,
          pctTotalNC: 100.0,
          combinedEquipments: 168,
          pctParc: 100.0,
          formattedValue: '496 NC',
        ),
        riskFamilyStats: [
          RiskFamilyItem(
            name: 'Erreurs d\'exploitation et de maintenance',
            count: 307,
            percentage: 61.9,
          ),
          RiskFamilyItem(
            name: 'Dégradation des canalisations et matériels',
            count: 125,
            percentage: 25.3,
          ),
          RiskFamilyItem(
            name: 'Absence ou inefficacité de la protection contre les contacts indirects',
            count: 64,
            percentage: 12.8,
          ),
        ],
        tensionDomainStats: TensionDomainStats(mtCount: 0, btCount: 496, totalCount: 496, mtPct: 0.0, btPct: 100.0),
        installationTypeStats: const [],
        crossCategoryItems: const [],
        crossAnalysisText: '',
        equipmentInventory: eqItems,
      );

      final snapshot = ExecutiveSummarySnapshot(
        missionId: 'miss_cimencam',
        clientName: 'CIMENCAM',
        siteName: 'FIGUIL',
        natureMission: 'Vérification périodique réglementaire',
        dateRangeText: '10/02/2026 au 14/02/2026',
        domainTension: 'Basse Tension (BT)',
        companyName: 'KES',
        reportNumber: 'KES/2026/001',
        reportDateStr: '16/09/2026',
        officialStats: const {},
        categoryStats: const [],
        topDefects: const [],
        riskFamilies: const [],
        equipmentCount: 168,
        installationsCount: 168,
        globalDensityStr: '2,95',
      );

      // Simulation du TechnicalEnrichmentResult avec déficits documentaires
      final technical = TechnicalEnrichmentResult(
        missionId: 'miss_cimencam',
        essaisCoverage: const EssaisCoverageStats(
          prisesTerreCount: 10,
          testDdrCount: 20,
          mesureIsolementCount: 15,
          testCpiCount: 0,
          continuitePeCount: 30,
          demarrageGeCount: 0,
          arretUrgenceCount: 5,
        ),
        coupureTeteStats: {
          DomainObjectType.armoire: const CoupureTeteStats(
            category: DomainObjectType.armoire,
            totalEquipments: 100,
            presents: 60,
            absents: 40,
          ),
        },
        sourceStats: {
          DomainObjectType.armoire: const SourceAlimentationStats(
            category: DomainObjectType.armoire,
            totalEquipments: 100,
            identifiees: 50,
            nonIdentifiees: 50,
          ),
        },
        parafoudreStats: const {},
        adequationIccPdcStats: {},
        marquesMatrix: [],
        courbesMatrix: [],
        pdcDepartStats: {},
        pdcTerminalStats: {},
        cablesMatrix: [],
        ipIkZoneItems: [],
        riskFamilyMatrix: const RiskFamilyCrossMatrix.empty(),
        top5Hta: [],
        top5Bt: [],
        totalZonesClassees: 0,
        totalLocauxMt: 0,
        totalLocauxBt: 2,
        totalLocauxGe: 0,
        locauxMtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        locauxBtFindings: const LocauxFindingsStats(dispoConstructives: 10, conditionsExploitation: 10),
        mtCategoriesCrossRows: const [],
        btCategoriesCrossRows: const [],
        mtTotalCrossRow: const CategoryCrossAuditRow(
          categoryName: 'MT',
          equipementsCount: 0,
          ncCount: 0,
          critiquesCount: 0,
          majeuresCount: 0,
          pctOfTotalNc: 0.0,
          tauxCritique: 0.0,
          densite: 0.0,
        ),
        btTotalCrossRow: const CategoryCrossAuditRow(
          categoryName: 'BT',
          equipementsCount: 168,
          ncCount: 496,
          critiquesCount: 93,
          majeuresCount: 403,
          pctOfTotalNc: 100.0,
          tauxCritique: 18.8,
          densite: 2.95,
        ),
      );

      final result = GlobalAssessmentEngine.analyze(
        summary: summary,
        snapshot: snapshot,
        technical: technical,
      );

      // Vérifications rigoureuses
      expect(result.riskLevel, equals(GlobalRiskProfileLevel.significantImprovementRequired));

      // Paragraphe 1 : Contexte et chiffres
      expect(result.perimeterAndCriticalityText, contains('CIMENCAM – FIGUIL'));
      expect(result.perimeterAndCriticalityText, contains('496 non-conformités'));
      expect(result.perimeterAndCriticalityText, contains('2,95 non-conformités par équipement'));
      expect(result.perimeterAndCriticalityText, contains('18,8 % des écarts sont critiques et 81,3 % majeurs'));
      expect(result.perimeterAndCriticalityText, contains('aucune non-conformité mineure n’ayant été recensée'));

      // Paragraphe 2 : Familles de risques
      expect(result.riskFamiliesText, contains('maîtrise des opérations d’exploitation et de maintenance'));
      expect(result.riskFamiliesText, contains('61,9 % des occurrences'));
      expect(result.riskFamiliesText, contains('25,3 %'));

      // Puces de faiblesses techniques
      expect(result.technicalWeaknessesBullets.isNotEmpty, isTrue);
      expect(result.technicalWeaknessesBullets.any((b) => b.contains('repérage')), isTrue);
      expect(result.technicalWeaknessesBullets.any((b) => b.contains('câblages')), isTrue);

      // Paragraphe 3 : Déficit documentaire
      expect(result.technicalDeficitText, contains('déficit important de données techniques nécessaires à la maîtrise du parc électrique'));
      expect(result.technicalDeficitText, contains('sources d’alimentation'));

      // Paragraphe 4 : Enjeux opérationnels chiffrés
      expect(result.operationalPrioritiesText, contains('93 non-conformités critiques'));
      expect(result.operationalPrioritiesText, contains('403 non-conformités majeures'));

      // Conclusion
      expect(result.finalAppreciationText, contains('plan d’actions correctives structuré, priorisé et suivi dans le temps'));
    });

    test('Scénario B : Mission 100% conforme (Zéro non-conformité)', () {
      final summary = MissionStatisticsSummary(
        missionId: 'miss_zero',
        inventory: AuditFindingInventory(missionId: 'miss_zero', findings: const []),
        criticalityStats: CriticalityStats(
          critique: 0,
          majeure: 0,
          mineure: 0,
          total: 0,
          pctCritique: 0.0,
          pctMajeure: 0.0,
          pctMineure: 0.0,
        ),
        topDefects: const [],
        paretoResult: ParetoAnalysisResult(
          items: const [],
          totalOccurrences: 0,
          paretoCategoryCount: 0,
          paretoCumulativePercentage: 0.0,
          summaryText: '',
        ),
        topTwoCategoriesResult: TopNonConformityCategoriesResult(
          label: '',
          cat1Name: 'N/A',
          combinedNC: 0,
          pctTotalNC: 0.0,
          combinedEquipments: 0,
          pctParc: 0.0,
          formattedValue: '',
        ),
        riskFamilyStats: const [],
        tensionDomainStats: TensionDomainStats(mtCount: 0, btCount: 0, totalCount: 0, mtPct: 0.0, btPct: 0.0),
        installationTypeStats: const [],
        crossCategoryItems: const [],
        crossAnalysisText: '',
        equipmentInventory: [EquipmentInventoryItem(label: 'TGBT', count: 5)],
      );

      final snapshot = ExecutiveSummarySnapshot(
        missionId: 'miss_zero',
        clientName: 'TOTAL ENERGIES',
        siteName: 'SIEGE',
        natureMission: 'Audit Périodique',
        dateRangeText: '05/01/2026',
        domainTension: 'BT',
        companyName: 'KES',
        reportNumber: 'KES/002',
        reportDateStr: '16/09/2026',
        officialStats: const {},
        categoryStats: const [],
        topDefects: const [],
        riskFamilies: const [],
        equipmentCount: 5,
        installationsCount: 5,
        globalDensityStr: '0,00',
      );

      final result = GlobalAssessmentEngine.analyze(
        summary: summary,
        snapshot: snapshot,
      );

      expect(result.riskLevel, equals(GlobalRiskProfileLevel.excellentOrZeroDefect));
      expect(result.perimeterAndCriticalityText, contains('aucune non-conformité'));
      expect(result.technicalWeaknessesBullets.isEmpty, isTrue);
      expect(result.operationalPrioritiesText, contains('préservation de ce haut niveau'));
      expect(result.finalAppreciationText, contains('excellent niveau de conformité'));
    });

    test('Scénario C : Parc avec anomalies purement mineures', () {
      final findings = [
        AuditFinding(
          id: 'min_1',
          missionId: 'miss_low',
          tensionDomain: TensionDomain.bt,
          origin: 'Local BT',
          objectType: 'Armoire',
          objectName: 'Coffret C1',
          tableName: 'Points de vérification',
          verificationPoint: 'Propreté du local',
          observationText: 'Poussière légère en partie basse',
          conformity: 'non',
          criticality: 'Mineure',
          riskFamily: 'Conditions environnementales',
          photos: const [],
        ),
      ];

      final summary = MissionStatisticsSummary(
        missionId: 'miss_low',
        inventory: AuditFindingInventory(missionId: 'miss_low', findings: findings),
        criticalityStats: CriticalityStats(
          critique: 0,
          majeure: 0,
          mineure: 1,
          total: 1,
          pctCritique: 0.0,
          pctMajeure: 0.0,
          pctMineure: 100.0,
        ),
        topDefects: const [],
        paretoResult: ParetoAnalysisResult(items: const [], totalOccurrences: 1, paretoCategoryCount: 1, paretoCumulativePercentage: 100.0, summaryText: ''),
        topTwoCategoriesResult: TopNonConformityCategoriesResult(
          label: '',
          cat1Name: 'N/A',
          combinedNC: 0,
          pctTotalNC: 0.0,
          combinedEquipments: 0,
          pctParc: 0.0,
          formattedValue: '',
        ),
        riskFamilyStats: [RiskFamilyItem(name: 'Conditions environnementales', count: 1, percentage: 100.0)],
        tensionDomainStats: TensionDomainStats(mtCount: 0, btCount: 1, totalCount: 1, mtPct: 0.0, btPct: 100.0),
        installationTypeStats: const [],
        crossCategoryItems: const [],
        crossAnalysisText: '',
        equipmentInventory: [EquipmentInventoryItem(label: 'Coffret', count: 10)],
      );

      final snapshot = ExecutiveSummarySnapshot(
        missionId: 'miss_low',
        clientName: 'SOCIÉTÉ CIVILE',
        siteName: 'BUREAUX',
        natureMission: 'Vérification',
        dateRangeText: '12/05/2026',
        domainTension: 'BT',
        companyName: 'KES',
        reportNumber: 'KES/003',
        reportDateStr: '16/09/2026',
        officialStats: const {},
        categoryStats: const [],
        topDefects: const [],
        riskFamilies: const [],
        equipmentCount: 10,
        installationsCount: 10,
        globalDensityStr: '0,10',
      );

      final result = GlobalAssessmentEngine.analyze(
        summary: summary,
        snapshot: snapshot,
      );

      expect(result.riskLevel, equals(GlobalRiskProfileLevel.controlledWithMinorDeviations));
      expect(result.perimeterAndCriticalityText, contains('niveau de maîtrise du risque électrique globalement satisfaisant'));
      expect(result.operationalPrioritiesText, contains('gravité mineur'));
      expect(result.finalAppreciationText, contains('niveau de risque maîtrisé'));
    });

    test('Scénario D : Asymétrie HTA dominante', () {
      final summary = MissionStatisticsSummary(
        missionId: 'miss_hta',
        inventory: AuditFindingInventory(missionId: 'miss_hta', findings: const []),
        criticalityStats: CriticalityStats(
          critique: 5,
          majeure: 15,
          mineure: 0,
          total: 20,
          pctCritique: 25.0,
          pctMajeure: 75.0,
          pctMineure: 0.0,
        ),
        topDefects: const [],
        paretoResult: ParetoAnalysisResult(items: const [], totalOccurrences: 20, paretoCategoryCount: 2, paretoCumulativePercentage: 80.0, summaryText: ''),
        topTwoCategoriesResult: TopNonConformityCategoriesResult(
          label: '',
          cat1Name: 'N/A',
          combinedNC: 0,
          pctTotalNC: 0.0,
          combinedEquipments: 0,
          pctParc: 0.0,
          formattedValue: '',
        ),
        riskFamilyStats: [RiskFamilyItem(name: 'Sécurité réglementaire', count: 20, percentage: 100.0)],
        tensionDomainStats: TensionDomainStats(mtCount: 15, btCount: 5, totalCount: 20, mtPct: 75.0, btPct: 25.0),
        installationTypeStats: const [],
        crossCategoryItems: const [],
        crossAnalysisText: '',
        equipmentInventory: [EquipmentInventoryItem(label: 'Poste MT', count: 4)],
      );

      final snapshot = ExecutiveSummarySnapshot(
        missionId: 'miss_hta',
        clientName: 'ENEO',
        siteName: 'POSTE SOURCE',
        natureMission: 'Audit HTA',
        dateRangeText: '10/01/2026',
        domainTension: 'HTA',
        companyName: 'KES',
        reportNumber: 'KES/004',
        reportDateStr: '16/09/2026',
        officialStats: const {},
        categoryStats: const [],
        topDefects: const [],
        riskFamilies: const [],
        equipmentCount: 4,
        installationsCount: 4,
        globalDensityStr: '5,00',
      );

      final result = GlobalAssessmentEngine.analyze(summary: summary, snapshot: snapshot);

      expect(result.paretoOrTensionText, contains('Moyenne Tension (HTA)'));
      expect(result.paretoOrTensionText, contains('75,0 % des non-conformités'));
    });

    test('Scénario E : Intégration PDF complète via PdfExecutiveSummaryBuilder', () {
      final mission = Mission(
        id: 'miss_pdf_test',
        nomClient: 'CIMENCAM',
        natureMission: 'Audit Périodique',
        dateIntervention: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'en_cours',
      );

      final pdfDoc = pw.Document();
      final widgets = PdfExecutiveSummaryBuilder.buildResumeExecutif(
        mission,
        {},
        'KES/2026/001',
      );

      expect(widgets.isNotEmpty, isTrue);

      pdfDoc.addPage(
        pw.MultiPage(
          build: (context) => widgets,
        ),
      );

      final bytes = pdfDoc.save();
      expect(bytes, isNotNull);
    });
  });
}
