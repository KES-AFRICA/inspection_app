import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/builders/pdf_executive_summary_builder.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';
import 'package:inspec_app/services/statistics/risk_family_normalizer.dart';
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

  AuditFinding createFinding({
    required String id,
    required TensionDomain tensionDomain,
    required String objectType,
    required String riskFamily,
  }) {
    return AuditFinding(
      id: id,
      missionId: 'M-FORENSIC-TEST',
      tensionDomain: tensionDomain,
      origin: objectType,
      objectType: objectType,
      objectName: 'Equip-$id',
      tableName: 'Audit',
      verificationPoint: 'Point-$id',
      observationText: 'Observation-$id',
      conformity: 'non',
      criticality: 'Majeure',
      riskFamily: riskFamily,
    );
  }

  group('RiskFamilyNormalizer Forensic Tests', () {
    test('Normalizes typographic apostrophes and whitespace correctly', () {
      expect(
        RiskFamilyNormalizer.normalize("Erreur d’exploitation / maintenance"),
        "Erreur d'exploitation / maintenance",
      );
      expect(
        RiskFamilyNormalizer.normalize("Échauffement / conditions d’environnement"),
        "Échauffement / conditions d'environnement",
      );
      expect(
        RiskFamilyNormalizer.normalize("   Sécurité des interventions   "),
        "Sécurité des interventions",
      );
    });

    test('Preserves distinct safety/fire risk families without grouping them artificially', () {
      final f1 = RiskFamilyNormalizer.normalize("Incendie / propagation du feu");
      final f2 = RiskFamilyNormalizer.normalize("Incendie / brûlure / fuite de combustible");
      final f3 = RiskFamilyNormalizer.normalize("Incendie / échauffement / surcharge des conducteurs");
      expect(f1, isNot(equals(f2)));
      expect(f2, isNot(equals(f3)));
      expect(f1, isNot(equals(f3)));
    });
  });

  group('RiskFamilyQuadrantStats Forensic Calculations', () {
    test('Correctly computes Top 5, Autres, and dynamic unforced sum for > 5 families', () {
      final top = [
        const RiskFamilyStatItem(famille: 'F1', constats: 65, part: 65 / 211 * 100.0, formattedPart: '30,8 %'),
        const RiskFamilyStatItem(famille: 'F2', constats: 54, part: 54 / 211 * 100.0, formattedPart: '25,6 %'),
        const RiskFamilyStatItem(famille: 'F3', constats: 27, part: 27 / 211 * 100.0, formattedPart: '12,8 %'),
        const RiskFamilyStatItem(famille: 'F4', constats: 21, part: 21 / 211 * 100.0, formattedPart: '10,0 %'),
        const RiskFamilyStatItem(famille: 'F5', constats: 14, part: 14 / 211 * 100.0, formattedPart: '6,6 %'),
      ];
      final all = [
        ...top,
        const RiskFamilyStatItem(famille: 'F6', constats: 18, part: 18 / 211 * 100.0, formattedPart: '8,5 %'),
        const RiskFamilyStatItem(famille: 'F7', constats: 12, part: 12 / 211 * 100.0, formattedPart: '5,7 %'),
      ];

      final quadrant = RiskFamilyQuadrantStats(
        domainTitle: 'BT',
        sectionTitle: 'EXPLOITATION ET MAINTENANCE',
        totalConstats: 211,
        counts: {'F1': 65, 'F2': 54, 'F3': 27, 'F4': 21, 'F5': 14, 'F6': 18, 'F7': 12},
        topFamilies: top,
        allFamilies: all,
      );

      expect(quadrant.sumTopOccurrences, 181);
      expect(quadrant.partTopSum, closeTo(85.78, 0.1));
      expect(quadrant.formattedPartTopSum, '85,8 %');
      expect(quadrant.autresConstats, 30);
      expect(quadrant.formattedAutresPart, '14,2 %');
      expect(quadrant.sumDisplayedOccurrences, 211);
      expect(quadrant.formattedSumDisplayedParts, '100,0 %');
    });

    test('Quadrant with <= 5 families sets Autres to 0 and sum to 100%', () {
      final top = [
        const RiskFamilyStatItem(famille: 'F1', constats: 27, part: 27 / 47 * 100.0, formattedPart: '57,4 %'),
        const RiskFamilyStatItem(famille: 'F2', constats: 8, part: 8 / 47 * 100.0, formattedPart: '17,0 %'),
        const RiskFamilyStatItem(famille: 'F3', constats: 8, part: 8 / 47 * 100.0, formattedPart: '17,0 %'),
        const RiskFamilyStatItem(famille: 'F4', constats: 4, part: 4 / 47 * 100.0, formattedPart: '8,5 %'),
      ];

      final quadrant = RiskFamilyQuadrantStats(
        domainTitle: 'HTA',
        sectionTitle: 'DISPOSITION CONSTRUCTIVE',
        totalConstats: 47,
        counts: {'F1': 27, 'F2': 8, 'F3': 8, 'F4': 4},
        topFamilies: top,
        allFamilies: top,
      );

      expect(quadrant.sumTopOccurrences, 47);
      expect(quadrant.partTopSum, 100.0);
      expect(quadrant.formattedPartTopSum, '100,0 %');
      expect(quadrant.autresConstats, 0);
      expect(quadrant.formattedAutresPart, '0,0 %');
      expect(quadrant.sumDisplayedOccurrences, 47);
      expect(quadrant.formattedSumDisplayedParts, '100,0 %');
    });
  });

  group('Equipment Brand Population & Sector Statistics Tests', () {
    test('EquipmentBrandPopulationStats handles percentages and missing brands cleanly', () {
      final stats = EquipmentBrandPopulationStats(
        populationTitle: 'Protections de tête',
        totalEligibles: 93,
        withProtectionCount: 45,
        protectionRate: 45 / 93 * 100.0,
        formattedProtectionRate: '48,4 %',
        brandCounts: {
          'Schneider Electric': 37,
          'Non définie': 6,
          'ABB': 2,
        },
        brandPercentages: {
          'Schneider Electric': 37 / 45 * 100.0,
          'Non définie': 6 / 45 * 100.0,
          'ABB': 2 / 45 * 100.0,
        },
      );

      expect(stats.totalEligibles, 93);
      expect(stats.withProtectionCount, 45);
      expect(stats.formattedProtectionRate, '48,4 %');
      expect(stats.hasProtections, isTrue);
      expect(stats.brandCounts['Schneider Electric'], 37);
      expect(stats.brandPercentages['Schneider Electric']!, closeTo(82.2, 0.1));
      expect(stats.brandCounts['Non définie'], 6);
      expect(stats.brandPercentages['Non définie']!, closeTo(13.3, 0.1));
      expect(stats.brandCounts['ABB'], 2);
      expect(stats.brandPercentages['ABB']!, closeTo(4.4, 0.1));
    });

    test('Zero population stats handles empty and zero gracefully', () {
      final stats = EquipmentBrandPopulationStats(
        populationTitle: 'Départs',
        totalEligibles: 0,
        withProtectionCount: 0,
        protectionRate: 0.0,
        formattedProtectionRate: '0,0 %',
        brandCounts: {},
        brandPercentages: {},
      );

      expect(stats.totalEligibles, 0);
      expect(stats.withProtectionCount, 0);
      expect(stats.hasProtections, isFalse);
      expect(stats.formattedProtectionRate, '0,0 %');
    });
  });

  group('Full Engine Integration & PDF Generation', () {
    test('TechnicalEnrichmentEngine calculates risk matrix with normalization and separation', () {
      final localMT = DomainEntityInstance(
        instanceId: 'loc-mt-1',
        category: DomainObjectType.localMT,
        name: 'Poste MT',
        tensionDomain: TensionDomain.mt,
        originPath: 'Locaux MT',
        findings: [
          createFinding(id: '1', tensionDomain: TensionDomain.mt, objectType: 'Local MT', riskFamily: 'Erreur d’exploitation / maintenance'),
          createFinding(id: '2', tensionDomain: TensionDomain.mt, objectType: 'Local MT', riskFamily: 'Erreur d\'exploitation / maintenance'),
        ],
      );

      final domainInventory = MissionDomainInventory(
        missionId: 'M-FORENSIC-TEST',
        instances: [localMT],
        allFindings: localMT.findings,
      );

      final findingInventory = AuditFindingInventory(
        missionId: 'M-FORENSIC-TEST',
        findings: domainInventory.allFindings,
      );

      final result = TechnicalEnrichmentEngine.compute(
        'M-FORENSIC-TEST',
        domainInventory,
        findingInventory,
      );

      // Verify that apostrophe variants were merged into normalized form
      final htaDispo = result.riskFamilyMatrix.htaDispositionsConstructives;
      expect(htaDispo.totalConstats, 2);
      expect(htaDispo.topFamilies.length, 1);
      expect(htaDispo.topFamilies.first.famille, "Erreur d'exploitation / maintenance");
      expect(htaDispo.topFamilies.first.constats, 2);
    });

    test('PDF Executive Summary Builder generates table cleanly with dynamic data', () async {
      final mission = Mission(
        id: 'M-PDF-DYNAMIC-FORENSIC-TEST',
        nomClient: 'TEST CLIENT CIMENCAM',
        nomSite: 'USINE DE FIGUIL',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
      );

      final trackedPages = <String, int>{};
      final doc = pw.Document();

      final widgets = PdfExecutiveSummaryBuilder.buildResumeExecutif(
        mission,
        trackedPages,
        'KES-2026-TEST-RAPPORT',
      );

      expect(widgets, isNotEmpty);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => widgets,
        ),
      );

      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
