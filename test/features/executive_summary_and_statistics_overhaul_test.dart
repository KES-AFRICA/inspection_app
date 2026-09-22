import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/builders/pdf_statistics_charts.dart';
import 'package:inspec_app/services/pdf/builders/pdf_statistics_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_sommaire_builder.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';
import 'package:inspec_app/services/statistics/mission_statistics.dart';
import 'package:inspec_app/models/mission.dart';

TechnicalEnrichmentResult _createMockTechnical() {
  return const TechnicalEnrichmentResult(
    missionId: 'mock_m',
    essaisCoverage: EssaisCoverageStats(
      prisesTerreCount: 0,
      testDdrCount: 0,
      mesureIsolementCount: 0,
      testCpiCount: 0,
      continuitePeCount: 0,
      demarrageGeCount: 0,
      arretUrgenceCount: 0,
    ),
    coupureTeteStats: {},
    sourceStats: {},
    parafoudreStats: {},
    adequationIccPdcStats: {},
    marquesMatrix: [],
    courbesMatrix: [],
    pdcDepartStats: {},
    pdcTerminalStats: {},
    cablesMatrix: [],
    ipIkZoneItems: [],
    riskFamilyMatrix: RiskFamilyCrossMatrix.empty(),
    top5Hta: [],
    top5Bt: [],
    totalZonesClassees: 0,
    totalLocauxMt: 0,
    totalLocauxBt: 0,
    totalLocauxGe: 0,
    locauxMtFindings: LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
    locauxBtFindings: LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
    mtCategoriesCrossRows: [],
    btCategoriesCrossRows: [],
    mtTotalCrossRow: CategoryCrossAuditRow(
      categoryName: '',
      equipementsCount: 0,
      ncCount: 0,
      critiquesCount: 0,
      majeuresCount: 0,
      pctOfTotalNc: 0,
      tauxCritique: 0,
      densite: 0,
    ),
    btTotalCrossRow: CategoryCrossAuditRow(
      categoryName: '',
      equipementsCount: 0,
      ncCount: 0,
      critiquesCount: 0,
      majeuresCount: 0,
      pctOfTotalNc: 0,
      tauxCritique: 0,
      densite: 0,
    ),
  );
}

MissionStatisticsSummary _createMockSummary(TensionDomainStats tensionStats) {
  return MissionStatisticsSummary(
    missionId: 'mock_m',
    inventory: AuditFindingInventory(missionId: 'mock_m', findings: const []),
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
    tensionDomainStats: tensionStats,
    installationTypeStats: const [],
    crossCategoryItems: const [],
    crossAnalysisText: '',
    equipmentInventory: const [],
  );
}

void main() {
  group('Overhaul Executive Summary & Statistical Analysis Tests', () {
    test('Sommaire entries reflect inverted sections 3 and 4', () {
      final entries = PdfSommaireBuilder.getSommaireEntriesForTesting();

      final entry1_3 = entries.firstWhere((e) => e.key == 'resume_executif_1_3');
      expect(entry1_3.titre, equals('3. Répartition des non-conformités'));
      expect(entry1_3.level, equals(1));

      final entry1_3_1 = entries.firstWhere((e) => e.key == 'resume_executif_1_3_1');
      expect(entry1_3_1.titre, equals('3.1. Analyse Moyenne Tension (HTA)'));
      expect(entry1_3_1.level, equals(2));

      final entry1_3_2 = entries.firstWhere((e) => e.key == 'resume_executif_1_3_2');
      expect(entry1_3_2.titre, equals('3.2. Analyse Basse Tension (BT)'));
      expect(entry1_3_2.level, equals(2));

      final entry1_4 = entries.firstWhere((e) => e.key == 'resume_executif_1_4');
      expect(entry1_4.titre, equals('4. Facteurs de risque prépondérants'));
      expect(entry1_4.level, equals(1));

      final index1_3 = entries.indexOf(entry1_3);
      final index1_4 = entries.indexOf(entry1_4);
      expect(index1_3, lessThan(index1_4), reason: 'Section 3 must precede Section 4');
    });

    test('Tension Domain Chart renders cleanly across all edge cases', () {
      // Cas 1 : 50 / 50
      expect(() => PdfStatisticsCharts.buildTensionDomainChart(50, 50), returnsNormally);

      // Cas 2 : 80 / 20
      expect(() => PdfStatisticsCharts.buildTensionDomainChart(80, 20), returnsNormally);

      // Cas 3 : 95 / 5 (petite bande pour MT)
      expect(() => PdfStatisticsCharts.buildTensionDomainChart(95, 5), returnsNormally);

      // Cas 4 : 99 / 1 (très petite bande pour MT)
      expect(() => PdfStatisticsCharts.buildTensionDomainChart(99, 1), returnsNormally);

      // Cas 5 : 100 % BT (0 MT)
      expect(() => PdfStatisticsCharts.buildTensionDomainChart(40, 0), returnsNormally);

      // Cas 6 : 100 % MT (0 BT)
      expect(() => PdfStatisticsCharts.buildTensionDomainChart(0, 30), returnsNormally);

      // Cas 7 : 0 / 0 (aucune NC)
      expect(() => PdfStatisticsCharts.buildTensionDomainChart(0, 0), returnsNormally);
    });

    test('Section 1 Dynamic Analysis Text covers all distribution scenarios', () {
      final doc = pw.Document();
      final technical = _createMockTechnical();

      // Scénario A : 0 NC
      final statsA = TensionDomainStats(btCount: 0, mtCount: 0, totalCount: 0, btPct: 0.0, mtPct: 0.0);
      final widgetA = PdfStatisticsBuilder.buildTensionDomainSectionForTesting(statsA, technical);
      expect(widgetA, isNotNull);

      // Scénario B : 100% BT
      final statsB = TensionDomainStats(btCount: 45, mtCount: 0, totalCount: 45, btPct: 100.0, mtPct: 0.0);
      final widgetB = PdfStatisticsBuilder.buildTensionDomainSectionForTesting(statsB, technical);
      expect(widgetB, isNotNull);

      // Scénario C : 100% MT
      final statsC = TensionDomainStats(btCount: 0, mtCount: 20, totalCount: 20, btPct: 0.0, mtPct: 100.0);
      final widgetC = PdfStatisticsBuilder.buildTensionDomainSectionForTesting(statsC, technical);
      expect(widgetC, isNotNull);

      // Scénario D : Équilibré (52% BT, 48% MT -> diff <= 10%)
      final statsD = TensionDomainStats(btCount: 52, mtCount: 48, totalCount: 100, btPct: 52.0, mtPct: 48.0);
      final widgetD = PdfStatisticsBuilder.buildTensionDomainSectionForTesting(statsD, technical);
      expect(widgetD, isNotNull);

      // Scénario E : BT Dominant (85% BT, 15% MT)
      final statsE = TensionDomainStats(btCount: 85, mtCount: 15, totalCount: 100, btPct: 85.0, mtPct: 15.0);
      final widgetE = PdfStatisticsBuilder.buildTensionDomainSectionForTesting(statsE, technical);
      expect(widgetE, isNotNull);

      // Scénario F : MT Dominant (20% BT, 80% MT)
      final statsF = TensionDomainStats(btCount: 20, mtCount: 80, totalCount: 100, btPct: 20.0, mtPct: 80.0);
      final widgetF = PdfStatisticsBuilder.buildTensionDomainSectionForTesting(statsF, technical);
      expect(widgetF, isNotNull);

      doc.addPage(
        pw.MultiPage(
          build: (ctx) => [
            widgetA,
            widgetB,
            widgetC,
            widgetD,
            widgetE,
            widgetF,
          ],
        ),
      );
      expect(doc.save(), completes);
    });

    test('Section 2 Cross Audit Commentaries & Intro Text render cleanly', () {
      final doc = pw.Document();

      final intro = PdfStatisticsBuilder.buildCrossAuditIntroTextForTesting();
      expect(intro, isNotNull);

      final mtRows = [
        const CategoryCrossAuditRow(
          categoryName: 'Cellules',
          equipementsCount: 4,
          ncCount: 6,
          critiquesCount: 1,
          majeuresCount: 2,
          pctOfTotalNc: 60.0,
          tauxCritique: 16.7,
          densite: 1.5,
        ),
        const CategoryCrossAuditRow(
          categoryName: 'Transformateurs',
          equipementsCount: 2,
          ncCount: 0,
          critiquesCount: 0,
          majeuresCount: 0,
          pctOfTotalNc: 0.0,
          tauxCritique: 0.0,
          densite: 0.0,
        ),
      ];
      final mtTotal = const CategoryCrossAuditRow(
        categoryName: 'TOTAL MT',
        equipementsCount: 6,
        ncCount: 6,
        critiquesCount: 1,
        majeuresCount: 2,
        pctOfTotalNc: 60.0,
        tauxCritique: 16.7,
        densite: 1.0,
      );

      final mtCommentary = PdfStatisticsBuilder.buildMtCrossAuditCommentaryForTesting(
        mtRows,
        mtTotal,
      );
      expect(mtCommentary, isNotNull);

      final btRows = [
        const CategoryCrossAuditRow(
          categoryName: 'Armoires',
          equipementsCount: 10,
          ncCount: 15,
          critiquesCount: 3,
          majeuresCount: 5,
          pctOfTotalNc: 60.0,
          tauxCritique: 20.0,
          densite: 1.5,
        ),
        const CategoryCrossAuditRow(
          categoryName: 'Coffrets',
          equipementsCount: 5,
          ncCount: 10,
          critiquesCount: 2,
          majeuresCount: 4,
          pctOfTotalNc: 40.0,
          tauxCritique: 20.0,
          densite: 2.0,
        ),
      ];
      final btTotal = const CategoryCrossAuditRow(
        categoryName: 'TOTAL BT',
        equipementsCount: 15,
        ncCount: 25,
        critiquesCount: 5,
        majeuresCount: 9,
        pctOfTotalNc: 100.0,
        tauxCritique: 20.0,
        densite: 1.67,
      );

      final btCommentary = PdfStatisticsBuilder.buildBtCrossAuditCommentaryForTesting(
        btRows,
        btTotal,
      );
      expect(btCommentary, isNotNull);

      doc.addPage(
        pw.MultiPage(
          build: (ctx) => [
            intro,
            mtCommentary,
            btCommentary,
          ],
        ),
      );
      expect(doc.save(), completes);
    });

    test('Section 3 is preceded by pw.NewPage() in PdfStatisticsBuilder', () {
      final mission = Mission(
        id: 'test-mission-p3',
        nomClient: 'Client Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
      );
      final stats = TensionDomainStats(btCount: 10, mtCount: 5, totalCount: 15, btPct: 66.7, mtPct: 33.3);
      final summary = _createMockSummary(stats);
      final technical = _createMockTechnical();
      final trackedPages = <String, int>{};

      final widgets = PdfStatisticsBuilder.buildStatisticsWidgets(
        mission: mission,
        summary: summary,
        technical: technical,
        trackedPages: trackedPages,
        offset: 0,
      );

      // Trouver l'index du PageTracker avec la clé 'stat_securite_bt'
      final trackerIndex = widgets.indexWhere(
        (w) => w is PageTracker && w.key == 'stat_securite_bt',
      );
      expect(trackerIndex, greaterThan(0), reason: 'stat_securite_bt must be found');

      // L'élément immédiatement précédent doit être un pw.NewPage
      final precedingWidget = widgets[trackerIndex - 1];
      expect(
        precedingWidget is pw.NewPage,
        isTrue,
        reason: 'Section 3. Sécurité et traçabilité des tableaux Basse Tension must start on a new page',
      );

      // Trouver l'index du PageTracker avec la clé 'stat_croisee_mt' (2.1 Moyenne tension)
      final mtIndex = widgets.indexWhere(
        (w) => w is PageTracker && w.key == 'stat_croisee_mt',
      );
      expect(mtIndex, greaterThan(0), reason: 'stat_croisee_mt must be found');
      final precedingMtWidget = widgets[mtIndex - 1];
      expect(
        precedingMtWidget is pw.NewPage,
        isTrue,
        reason: 'Section 2.1 Moyenne tension must start on a new page',
      );
    });
  });
}
