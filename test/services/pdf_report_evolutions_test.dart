// test/services/pdf_report_evolutions_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/canonical_risk_family_registry.dart';
import 'package:inspec_app/services/statistics/competency_needs_engine.dart';
import 'package:inspec_app/services/statistics/global_assessment_engine.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';
import 'package:inspec_app/services/pdf/builders/pdf_final_page_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_statistics_charts.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Targeted PDF & Statistics Report Evolutions Tests', () {
    test('1. BrandDistributionSnapshot calculation and editorial summary', () {
      final entries = [
        const BrandDistributionEntry(rank: 1, brand: 'Schneider Electric', count: 45, percentage: 60.0, formattedPercentage: '60,0 %'),
        const BrandDistributionEntry(rank: 2, brand: 'Legrand', count: 20, percentage: 26.67, formattedPercentage: '26,7 %'),
        const BrandDistributionEntry(rank: 3, brand: 'Hager', count: 10, percentage: 13.33, formattedPercentage: '13,3 %'),
      ];

      final snapshot = BrandDistributionSnapshot(
        totalProtections: 75,
        totalEligibles: 75,
        entries: entries,
      );

      expect(snapshot.totalProtections, equals(75));
      expect(snapshot.entries.length, equals(3));
      expect(snapshot.dominantBrand?.brand, equals('Schneider Electric'));

      final summary = snapshot.generateEditorialSummary();
      expect(summary, contains('Schneider Electric'));
      expect(summary, contains('60,0 %'));
      expect(summary, contains('Legrand'));
      expect(summary, contains('Hager'));
      expect(summary.endsWith('.'), isTrue);
    });

    test('2. buildBrandPieChart generates valid CustomPaint widget', () {
      const snapshot = BrandDistributionSnapshot(
        totalProtections: 50,
        totalEligibles: 50,
        entries: [
          BrandDistributionEntry(rank: 1, brand: 'Schneider Electric', count: 30, percentage: 60.0, formattedPercentage: '60,0 %'),
          BrandDistributionEntry(rank: 2, brand: 'Legrand', count: 20, percentage: 40.0, formattedPercentage: '40,0 %'),
        ],
      );

      final chart = PdfStatisticsCharts.buildBrandPieChart(snapshot);
      expect(chart, isNotNull);
    });

    test('3. CompetencyNeedsEngine - Partie 1 canonical NCs and Partie 2 risk families', () {
      final findings = <AuditFinding>[
        AuditFinding(
          id: 'f1',
          missionId: 'mission_test_evolutions',
          objectType: 'Coffret',
          objectName: 'Coffret 1',
          origin: 'Atelier',
          tableName: 'coffrets',
          conformity: 'Non conforme',
          observationText: 'Repérage manquant sur les départs',
          verificationPoint: 'Repérage des départs',
          criticality: 'Majeure',
          priority: 2,
          tensionDomain: TensionDomain.bt,
          riskFamily: 'Erreur d\'exploitation',
        ),
        AuditFinding(
          id: 'f2',
          missionId: 'mission_test_evolutions',
          objectType: 'Armoire',
          objectName: 'Armoire TGBT',
          origin: 'Local TGBT',
          tableName: 'armoires',
          conformity: 'Non conforme',
          observationText: 'Schéma unifilaire absent',
          verificationPoint: 'Schéma unifilaire',
          criticality: 'Majeure',
          priority: 2,
          tensionDomain: TensionDomain.bt,
          riskFamily: 'Erreur d\'exploitation',
        ),
        AuditFinding(
          id: 'f3',
          missionId: 'mission_test_evolutions',
          objectType: 'Coffret',
          objectName: 'Coffret 2',
          origin: 'Zone Stockage',
          tableName: 'coffrets',
          conformity: 'Non conforme',
          observationText: 'Continuité de masse rompue',
          verificationPoint: 'Prise de terre et PE',
          criticality: 'Majeure',
          priority: 2,
          tensionDomain: TensionDomain.bt,
          riskFamily: 'Électrisation / électrocution',
        ),
      ];

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'mission_test_evolutions',
        findings: findings,
      );

      expect(result.totalOccurrences, equals(3));
      expect(result.hasNoDefects, isFalse);

      // Partie 1 : Grouped by canonical category
      expect(result.axes.isNotEmpty, isTrue);
      // Both "Repérage des départs" and "Schéma unifilaire" map to identificationEtReperage
      final repGroup = result.axes.where((a) => a.title.contains('Identification, repérage')).toList();
      expect(repGroup.length, equals(1));
      expect(repGroup.first.occurrenceCount, equals(2));

      // Partie 2 : Grouped by canonical risk family
      expect(result.riskFamilyAxes.isNotEmpty, isTrue);
      final exploRisk = result.riskFamilyAxes.where((r) => r.title == CanonicalRiskFamilyRegistry.erreurExploitation).toList();
      expect(exploRisk.length, equals(1));
      expect(exploRisk.first.occurrenceCount, equals(2));

      final elecRisk = result.riskFamilyAxes.where((r) => r.title == CanonicalRiskFamilyRegistry.electrissationElectrocution).toList();
      expect(elecRisk.length, equals(1));
      expect(elecRisk.first.occurrenceCount, equals(1));
    });

    test('4. GlobalAssessmentResult.blocks omits bullet points list', () {
      final result = GlobalAssessmentResult(
        riskLevel: GlobalRiskProfileLevel.significantImprovementRequired,
        perimeterAndCriticalityText: 'Périmètre et criticité test.',
        riskFamiliesText: 'Familles de risques test.',
        technicalWeaknessesBullets: [
          'Faiblesse technique 1 ;',
          'Faiblesse technique 2 ;',
        ],
        technicalDeficitText: 'Déficit technique test.',
        operationalPrioritiesText: 'Priorités opérationnelles test.',
        finalAppreciationText: 'Appréciation finale test.',
      );

      final blocks = result.blocks;
      // Ensure no block has bulletsIntro or bulletItem type
      final hasBulletsIntro = blocks.any((b) => b.type == GlobalAssessmentBlockType.bulletsIntro);
      final hasBulletItem = blocks.any((b) => b.type == GlobalAssessmentBlockType.bulletItem);

      expect(hasBulletsIntro, isFalse);
      expect(hasBulletItem, isFalse);
      expect(blocks.length, equals(5)); // paragraph x 4 + conclusion x 1
    });

    test('5. PdfFinalPageBuilder creates valid PDF page', () async {
      PdfFinalPageBuilder.fontRegular = pw.Font.helvetica();
      PdfFinalPageBuilder.fontBold = pw.Font.helveticaBold();

      final doc = pw.Document();
      doc.addPage(PdfFinalPageBuilder.buildPage());

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);
      expect(doc.document.pdfPageList.pages.length, equals(1));
    });
  });
}
