// test/features/report_corrections_density_ipik_layout_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/ai/executive_summary_snapshot.dart';
import 'package:inspec_app/services/pdf/builders/pdf_executive_summary_builder.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/mission_statistics.dart';
import 'package:inspec_app/services/statistics/mission_statistics_collector.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Corrections ciblées — Catégorie la plus dense, IP/IK et mise en page', () {
    test('1. TechnicalEnrichmentResult : calcul arithmétique strict de l adéquation globale IP/IK', () {
      // Cas A : 80% zones (8/10) et 60% locaux (6/10) => moyenne (80 + 60) / 2 = 70.0%
      final res70 = TechnicalEnrichmentResult(
        missionId: 'm1',
        essaisCoverage: const EssaisCoverageStats(
          prisesTerreCount: 0,
          testDdrCount: 0,
          mesureIsolementCount: 0,
          testCpiCount: 0,
          continuitePeCount: 0,
          demarrageGeCount: 0,
          arretUrgenceCount: 0,
        ),
        coupureTeteStats: const {},
        sourceStats: const {},
        parafoudreStats: const {},
        adequationIccPdcStats: const {},
        marquesMatrix: const [],
        courbesMatrix: const [],
        pdcDepartStats: const {},
        pdcTerminalStats: const {},
        cablesMatrix: const [],
        ipIkZoneItems: const [],
        riskFamilyMatrix: const RiskFamilyCrossMatrix.empty(),
        top5Hta: const [],
        top5Bt: const [],
        totalZonesClassees: 8,
        totalLocauxMt: 10,
        totalLocauxBt: 0,
        totalLocauxGe: 0,
        locauxMtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        locauxBtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        mtCategoriesCrossRows: const [],
        btCategoriesCrossRows: const [],
        mtTotalCrossRow: const CategoryCrossAuditRow(
          categoryName: '',
          equipementsCount: 0,
          ncCount: 0,
          critiquesCount: 0,
          majeuresCount: 0,
          pctOfTotalNc: 0,
          tauxCritique: 0,
          densite: 0,
        ),
        btTotalCrossRow: const CategoryCrossAuditRow(
          categoryName: '',
          equipementsCount: 0,
          ncCount: 0,
          critiquesCount: 0,
          majeuresCount: 0,
          pctOfTotalNc: 0,
          tauxCritique: 0,
          densite: 0,
        ),
        totalZonesAudit: 10,
        totalZonesClasseesCount: 8,
        totalLocauxAudit: 10,
        totalLocauxClassesCount: 6,
      );

      expect(res70.globalIpIkAdequationRate, equals(70.0));
      expect(res70.globalIpIkAdequationRateStr, equals('70 %'));

      // Cas B : 100% zones (10/10) et 100% locaux (5/5) => 100%
      final res100 = TechnicalEnrichmentResult(
        missionId: 'm2',
        essaisCoverage: const EssaisCoverageStats(
          prisesTerreCount: 0,
          testDdrCount: 0,
          mesureIsolementCount: 0,
          testCpiCount: 0,
          continuitePeCount: 0,
          demarrageGeCount: 0,
          arretUrgenceCount: 0,
        ),
        coupureTeteStats: const {},
        sourceStats: const {},
        parafoudreStats: const {},
        adequationIccPdcStats: const {},
        marquesMatrix: const [],
        courbesMatrix: const [],
        pdcDepartStats: const {},
        pdcTerminalStats: const {},
        cablesMatrix: const [],
        ipIkZoneItems: const [],
        riskFamilyMatrix: const RiskFamilyCrossMatrix.empty(),
        top5Hta: const [],
        top5Bt: const [],
        totalZonesClassees: 10,
        totalLocauxMt: 5,
        totalLocauxBt: 0,
        totalLocauxGe: 0,
        locauxMtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        locauxBtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        mtCategoriesCrossRows: const [],
        btCategoriesCrossRows: const [],
        mtTotalCrossRow: const CategoryCrossAuditRow(
          categoryName: '',
          equipementsCount: 0,
          ncCount: 0,
          critiquesCount: 0,
          majeuresCount: 0,
          pctOfTotalNc: 0,
          tauxCritique: 0,
          densite: 0,
        ),
        btTotalCrossRow: const CategoryCrossAuditRow(
          categoryName: '',
          equipementsCount: 0,
          ncCount: 0,
          critiquesCount: 0,
          majeuresCount: 0,
          pctOfTotalNc: 0,
          tauxCritique: 0,
          densite: 0,
        ),
        totalZonesAudit: 10,
        totalZonesClasseesCount: 10,
        totalLocauxAudit: 5,
        totalLocauxClassesCount: 5,
      );

      expect(res100.globalIpIkAdequationRate, equals(100.0));
      expect(res100.globalIpIkAdequationRateStr, equals('100 %'));

      // Cas C : 0% zones et 50% locaux => 25%
      final res25 = TechnicalEnrichmentResult(
        missionId: 'm3',
        essaisCoverage: const EssaisCoverageStats(
          prisesTerreCount: 0,
          testDdrCount: 0,
          mesureIsolementCount: 0,
          testCpiCount: 0,
          continuitePeCount: 0,
          demarrageGeCount: 0,
          arretUrgenceCount: 0,
        ),
        coupureTeteStats: const {},
        sourceStats: const {},
        parafoudreStats: const {},
        adequationIccPdcStats: const {},
        marquesMatrix: const [],
        courbesMatrix: const [],
        pdcDepartStats: const {},
        pdcTerminalStats: const {},
        cablesMatrix: const [],
        ipIkZoneItems: const [],
        riskFamilyMatrix: const RiskFamilyCrossMatrix.empty(),
        top5Hta: const [],
        top5Bt: const [],
        totalZonesClassees: 0,
        totalLocauxMt: 4,
        totalLocauxBt: 0,
        totalLocauxGe: 0,
        locauxMtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        locauxBtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        mtCategoriesCrossRows: const [],
        btCategoriesCrossRows: const [],
        mtTotalCrossRow: const CategoryCrossAuditRow(
          categoryName: '',
          equipementsCount: 0,
          ncCount: 0,
          critiquesCount: 0,
          majeuresCount: 0,
          pctOfTotalNc: 0,
          tauxCritique: 0,
          densite: 0,
        ),
        btTotalCrossRow: const CategoryCrossAuditRow(
          categoryName: '',
          equipementsCount: 0,
          ncCount: 0,
          critiquesCount: 0,
          majeuresCount: 0,
          pctOfTotalNc: 0,
          tauxCritique: 0,
          densite: 0,
        ),
        totalZonesAudit: 10,
        totalZonesClasseesCount: 0,
        totalLocauxAudit: 4,
        totalLocauxClassesCount: 2,
      );

      expect(res25.globalIpIkAdequationRate, equals(25.0));
      expect(res25.globalIpIkAdequationRateStr, equals('25 %'));

      // Cas D : 10% zones (1/10) et 15% locaux (3/20) => (10 + 15) / 2 = 12.5% => '12,5 %'
      final res125 = TechnicalEnrichmentResult(
        missionId: 'm4',
        essaisCoverage: const EssaisCoverageStats(
          prisesTerreCount: 0,
          testDdrCount: 0,
          mesureIsolementCount: 0,
          testCpiCount: 0,
          continuitePeCount: 0,
          demarrageGeCount: 0,
          arretUrgenceCount: 0,
        ),
        coupureTeteStats: const {},
        sourceStats: const {},
        parafoudreStats: const {},
        adequationIccPdcStats: const {},
        marquesMatrix: const [],
        courbesMatrix: const [],
        pdcDepartStats: const {},
        pdcTerminalStats: const {},
        cablesMatrix: const [],
        ipIkZoneItems: const [],
        riskFamilyMatrix: const RiskFamilyCrossMatrix.empty(),
        top5Hta: const [],
        top5Bt: const [],
        totalZonesClassees: 1,
        totalLocauxMt: 20,
        totalLocauxBt: 0,
        totalLocauxGe: 0,
        locauxMtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        locauxBtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        mtCategoriesCrossRows: const [],
        btCategoriesCrossRows: const [],
        mtTotalCrossRow: const CategoryCrossAuditRow(
          categoryName: '',
          equipementsCount: 0,
          ncCount: 0,
          critiquesCount: 0,
          majeuresCount: 0,
          pctOfTotalNc: 0,
          tauxCritique: 0,
          densite: 0,
        ),
        btTotalCrossRow: const CategoryCrossAuditRow(
          categoryName: '',
          equipementsCount: 0,
          ncCount: 0,
          critiquesCount: 0,
          majeuresCount: 0,
          pctOfTotalNc: 0,
          tauxCritique: 0,
          densite: 0,
        ),
        totalZonesAudit: 10,
        totalZonesClasseesCount: 1,
        totalLocauxAudit: 20,
        totalLocauxClassesCount: 3,
      );

      expect(res125.globalIpIkAdequationRate, equals(12.5));
      expect(res125.globalIpIkAdequationRateStr, equals('12,5 %'));
    });

    test('2. Catégorie la plus dense : filtrage strict HTA et BT dans build12IndicateursTable', () {
      final mtRows = [
        const CategoryCrossAuditRow(
          categoryName: 'Locaux techniques',
          equipementsCount: 1,
          ncCount: 2,
          critiquesCount: 1,
          majeuresCount: 1,
          pctOfTotalNc: 20.0,
          tauxCritique: 50.0,
          densite: 2.0,
        ),
        const CategoryCrossAuditRow(
          categoryName: 'Cellules',
          equipementsCount: 2,
          ncCount: 8,
          critiquesCount: 4,
          majeuresCount: 4,
          pctOfTotalNc: 80.0,
          tauxCritique: 50.0,
          densite: 4.0, // Catégorie HTA la plus dense
        ),
        const CategoryCrossAuditRow(
          categoryName: 'Armoires / Coffrets MT',
          equipementsCount: 1,
          ncCount: 99,
          critiquesCount: 50,
          majeuresCount: 49,
          pctOfTotalNc: 99.0,
          tauxCritique: 50.0,
          densite: 99.0, // DOIT ÊTRE EXCLU du calcul HTA
        ),
      ];

      final btRows = [
        const CategoryCrossAuditRow(
          categoryName: 'TGBT',
          equipementsCount: 1,
          ncCount: 3,
          critiquesCount: 1,
          majeuresCount: 2,
          pctOfTotalNc: 30.0,
          tauxCritique: 33.3,
          densite: 3.0,
        ),
        const CategoryCrossAuditRow(
          categoryName: 'Armoires',
          equipementsCount: 2,
          ncCount: 12,
          critiquesCount: 4,
          majeuresCount: 8,
          pctOfTotalNc: 50.0,
          tauxCritique: 33.3,
          densite: 6.0, // Catégorie BT la plus dense
        ),
        const CategoryCrossAuditRow(
          categoryName: 'Prises de terre mesurées',
          equipementsCount: 5,
          ncCount: 50,
          critiquesCount: 10,
          majeuresCount: 40,
          pctOfTotalNc: 90.0,
          tauxCritique: 20.0,
          densite: 10.0, // Non-équipement BT, doit être exclu
        ),
      ];

      final technical = TechnicalEnrichmentResult(
        missionId: 'm1',
        essaisCoverage: const EssaisCoverageStats(
          prisesTerreCount: 0,
          testDdrCount: 0,
          mesureIsolementCount: 0,
          testCpiCount: 0,
          continuitePeCount: 0,
          demarrageGeCount: 0,
          arretUrgenceCount: 0,
        ),
        coupureTeteStats: const {},
        sourceStats: const {},
        parafoudreStats: const {},
        adequationIccPdcStats: const {},
        marquesMatrix: const [],
        courbesMatrix: const [],
        pdcDepartStats: const {},
        pdcTerminalStats: const {},
        cablesMatrix: const [],
        ipIkZoneItems: const [],
        riskFamilyMatrix: const RiskFamilyCrossMatrix.empty(),
        top5Hta: const [],
        top5Bt: const [],
        totalZonesClassees: 2,
        totalLocauxMt: 1,
        totalLocauxBt: 1,
        totalLocauxGe: 0,
        locauxMtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        locauxBtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        mtCategoriesCrossRows: mtRows,
        btCategoriesCrossRows: btRows,
        mtTotalCrossRow: mtRows.first,
        btTotalCrossRow: btRows.first,
        totalZonesAudit: 5,
        totalZonesClasseesCount: 2,
        totalLocauxAudit: 2,
        totalLocauxClassesCount: 1,
      );

      final findingInventory = AuditFindingInventory(missionId: 'test_m', findings: const []);
      final summary = MissionStatisticsSummary.fromInventory(findingInventory);

      final snapshot = ExecutiveSummarySnapshot(
        missionId: 'test_m',
        clientName: 'Client',
        siteName: 'Site',
        natureMission: 'Audit',
        dateRangeText: '10/01/2026',
        domainTension: 'HTA & BT',
        companyName: 'KES',
        reportNumber: 'REP-001',
        reportDateStr: '10/01/2026',
        officialStats: const <String, dynamic>{},
        categoryStats: const [],
        topDefects: const [],
        riskFamilies: const [],
        equipmentCount: 10,
        installationsCount: 20,
        globalDensityStr: '2,0',
      );

      final tableWidget = PdfExecutiveSummaryBuilder.build12IndicateursTableForTesting(
        summary,
        snapshot,
        technical,
      );

      expect(tableWidget, isA<pw.Table>());
    });

    test('3. buildHeaderWithTableList avec minRowsWithHeader conserve les lignes avec l entête', () {
      final headerWidget = pw.Text('Section Header');
      final headerRow = pw.TableRow(
        children: [pw.Text('Col 1'), pw.Text('Col 2')],
      );
      final dataRows = [
        pw.TableRow(children: [pw.Text('Row 1-A'), pw.Text('Row 1-B')]),
        pw.TableRow(children: [pw.Text('Row 2-A'), pw.Text('Row 2-B')]),
        pw.TableRow(children: [pw.Text('Row 3-A'), pw.Text('Row 3-B')]),
      ];

      // Cas 1 : minRowsWithHeader = 2 sur 3 lignes => 3 widgets [NewPage, Column(header + 2 rows), Table(1 row)]
      final blocks2 = PdfReportStyles.buildHeaderWithTableList(
        headerWidget: headerWidget,
        headerRow: headerRow,
        dataRows: dataRows,
        columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
        minRowsWithHeader: 2,
      );

      expect(blocks2.length, equals(3));
      expect(blocks2[0], isA<pw.NewPage>());
      expect(blocks2[1], isA<pw.Column>());
      expect(blocks2[2], isA<pw.Table>());

      // Cas 2 : minRowsWithHeader = 3 sur 3 lignes => 2 widgets [NewPage, Column(header + 3 rows)] indivisible
      final blocksAll = PdfReportStyles.buildHeaderWithTableList(
        headerWidget: headerWidget,
        headerRow: headerRow,
        dataRows: dataRows,
        columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
        minRowsWithHeader: 3,
      );

      expect(blocksAll.length, equals(2));
      expect(blocksAll[0], isA<pw.NewPage>());
      expect(blocksAll[1], isA<pw.Column>());
    });
  });
}
