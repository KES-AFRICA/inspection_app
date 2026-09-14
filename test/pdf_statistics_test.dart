import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/builders/pdf_statistics_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_statistics_charts.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';
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

  test('Verify PdfStatisticsBuilder and all Charts generate PDF cleanly', () async {
    final mission = Mission(
      id: 'M-STAT-TEST-001',
      nomClient: 'CIMENCAM - FIGUIL',
      nomSite: 'USINE DE FIGUIL',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: 'active',
    );

    final trackedPages = <String, int>{};
    final doc = pw.Document();

    // 1. Page avec la section complète via le Builder
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(1.5 * 28.35),
        build: (ctx) => PdfStatisticsBuilder.buildAnalyseStatistique(
          mission,
          trackedPages,
          'KES-2026-RAPPORT-001',
        ),
      ),
    );

    // 2. Page dédiée validant les graphiques avec les données exactes du document de référence
    final mtRows = [
      const CategoryCrossAuditRow(categoryName: 'Locaux MT', equipementsCount: 16, ncCount: 127, critiquesCount: 19, majeuresCount: 108, pctOfTotalNc: 25.6, tauxCritique: 15.0, densite: 7.9),
      const CategoryCrossAuditRow(categoryName: 'Cellules MT', equipementsCount: 29, ncCount: 23, critiquesCount: 0, majeuresCount: 23, pctOfTotalNc: 4.6, tauxCritique: 0.0, densite: 0.8),
      const CategoryCrossAuditRow(categoryName: 'Transfo MT/BT', equipementsCount: 9, ncCount: 4, critiquesCount: 0, majeuresCount: 4, pctOfTotalNc: 0.8, tauxCritique: 0.0, densite: 0.4),
    ];

    final btRows = [
      const CategoryCrossAuditRow(categoryName: 'Armoires', equipementsCount: 75, ncCount: 176, critiquesCount: 36, majeuresCount: 140, pctOfTotalNc: 35.5, tauxCritique: 20.5, densite: 2.3),
      const CategoryCrossAuditRow(categoryName: 'Coffrets', equipementsCount: 19, ncCount: 79, critiquesCount: 23, majeuresCount: 56, pctOfTotalNc: 15.9, tauxCritique: 29.1, densite: 4.2),
      const CategoryCrossAuditRow(categoryName: 'Locaux GE', equipementsCount: 4, ncCount: 45, critiquesCount: 13, majeuresCount: 32, pctOfTotalNc: 9.1, tauxCritique: 28.9, densite: 11.2),
      const CategoryCrossAuditRow(categoryName: 'Locaux BT', equipementsCount: 14, ncCount: 37, critiquesCount: 1, majeuresCount: 36, pctOfTotalNc: 7.5, tauxCritique: 2.7, densite: 2.6),
      const CategoryCrossAuditRow(categoryName: 'Inverseurs', equipementsCount: 1, ncCount: 5, critiquesCount: 0, majeuresCount: 5, pctOfTotalNc: 1.0, tauxCritique: 0.0, densite: 5.0),
      const CategoryCrossAuditRow(categoryName: 'Prises de terre', equipementsCount: 11, ncCount: 0, critiquesCount: 0, majeuresCount: 0, pctOfTotalNc: 0.0, tauxCritique: 0.0, densite: 0.0),
    ];

    final technicalMock = TechnicalEnrichmentResult(
      missionId: mission.id,
      essaisCoverage: const EssaisCoverageStats(
        prisesTerreCount: 11,
        testDdrCount: 0,
        mesureIsolementCount: 0,
        testCpiCount: 0,
        continuitePeCount: 0,
        demarrageGeCount: 0,
        arretUrgenceCount: 0,
      ),
      coupureTeteStats: {
        DomainObjectType.armoire: const CoupureTeteStats(category: DomainObjectType.armoire, totalEquipments: 75, presents: 38, absents: 37),
        DomainObjectType.coffret: const CoupureTeteStats(category: DomainObjectType.coffret, totalEquipments: 18, presents: 7, absents: 11),
      },
      sourceStats: {
        DomainObjectType.armoire: const SourceAlimentationStats(category: DomainObjectType.armoire, totalEquipments: 75, identifiees: 7, nonIdentifiees: 68),
        DomainObjectType.coffret: const SourceAlimentationStats(category: DomainObjectType.coffret, totalEquipments: 18, identifiees: 0, nonIdentifiees: 18),
      },
      parafoudreStats: {
        DomainObjectType.armoire: const ParafoudreStats(category: DomainObjectType.armoire, totalEquipments: 74, avecParafoudre: 23, sansParafoudre: 51),
        DomainObjectType.coffret: const ParafoudreStats(category: DomainObjectType.coffret, totalEquipments: 19, avecParafoudre: 2, sansParafoudre: 17),
        DomainObjectType.inverseur: const ParafoudreStats(category: DomainObjectType.inverseur, totalEquipments: 1, avecParafoudre: 0, sansParafoudre: 1),
      },
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
      totalLocauxMt: 16,
      totalLocauxBt: 14,
      totalLocauxGe: 4,
      locauxMtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
      locauxBtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
      mtCategoriesCrossRows: mtRows,
      mtTotalCrossRow: const CategoryCrossAuditRow(categoryName: 'TOTAL MT', equipementsCount: 54, ncCount: 154, critiquesCount: 19, majeuresCount: 135, pctOfTotalNc: 31.0, tauxCritique: 12.3, densite: 2.85),
      btCategoriesCrossRows: btRows,
      btTotalCrossRow: const CategoryCrossAuditRow(categoryName: 'TOTAL BT', equipementsCount: 124, ncCount: 342, critiquesCount: 73, majeuresCount: 269, pctOfTotalNc: 69.0, tauxCritique: 21.3, densite: 2.76),
    );

    final paretoItems = [
      TopDefectItem(title: 'Identification / repérage circuits', count: 112, percentage: 22.6, cumulativePercentage: 22.6),
      TopDefectItem(title: 'Câblages, raccordements et canalisations', count: 107, percentage: 21.6, cumulativePercentage: 44.2),
      TopDefectItem(title: 'Continuité du conducteur PE', count: 22, percentage: 4.4, cumulativePercentage: 48.6),
      TopDefectItem(title: 'EPI électriques (gants, visière, tapis)', count: 22, percentage: 4.4, cumulativePercentage: 53.0),
      TopDefectItem(title: 'Plan d\'intervention et consignation', count: 21, percentage: 4.2, cumulativePercentage: 57.3),
      TopDefectItem(title: 'Revêtement diélectrique au sol', count: 20, percentage: 4.0, cumulativePercentage: 61.3),
      TopDefectItem(title: 'Dispositifs de protection', count: 17, percentage: 3.4, cumulativePercentage: 64.7),
      TopDefectItem(title: 'Matériel de consignation', count: 16, percentage: 3.2, cumulativePercentage: 67.9),
      TopDefectItem(title: 'Coupure générale identifiée', count: 14, percentage: 2.8, cumulativePercentage: 70.8),
      TopDefectItem(title: 'Procédure de consignation', count: 14, percentage: 2.8, cumulativePercentage: 73.6),
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(1.5 * 28.35),
        build: (ctx) => [
          pw.Header(level: 1, text: 'VALIDATION DES GRAPHIQUES DE REFERENCE'),
          pw.SizedBox(height: 10),
          PdfStatisticsCharts.buildTensionDomainChart(321, 175),
          pw.SizedBox(height: 10),
          PdfStatisticsCharts.buildMtCategoryStackedBarChart(mtRows),
          pw.SizedBox(height: 10),
          PdfStatisticsCharts.buildBtCategoryStackedBarChart(btRows),
          pw.SizedBox(height: 10),
          PdfStatisticsCharts.buildBtSourceStackedBarChart(technicalMock),
          pw.SizedBox(height: 10),
          PdfStatisticsCharts.buildDisjoncteurTeteDonutChart(technicalMock),
          pw.SizedBox(height: 10),
          PdfStatisticsCharts.buildBtParafoudreStackedBarChart(technicalMock),
          pw.SizedBox(height: 10),
          PdfStatisticsCharts.buildParetoDualAxisChart(paretoItems, 496),
        ],
      ),
    );

    final bytes = await doc.save();
    expect(bytes, isNotEmpty);

    final file = File('scratch/test_statistics_full_output.pdf');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    print('Saved full generated PDF to ${file.path}, size: ${bytes.length} bytes');
  });
}
