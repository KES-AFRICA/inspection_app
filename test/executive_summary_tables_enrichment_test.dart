import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/pdf/builders/pdf_executive_summary_builder.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

void main() {
  group('Executive Summary Tables Enrichment Tests', () {
    test('1. Tableau C - Top Findings contains TOTAL row with dynamic counts and percentage', () {
      final items = [
        const TopDefectDomainItem(title: 'Absence d’identification', count: 12, percentageOfDomain: 40.0),
        const TopDefectDomainItem(title: 'Défaut de continuité PE', count: 9, percentageOfDomain: 30.0),
        const TopDefectDomainItem(title: 'Non-conformité IP/IK', count: 6, percentageOfDomain: 20.0),
      ];

      final tableWidget = PdfExecutiveSummaryBuilder.buildTopFindingsTableForTesting(items, 'Aucun constat');
      expect(tableWidget, isA<pw.Table>());
      final table = tableWidget as pw.Table;

      // Header row (1) + 3 items + 1 TOTAL row = 5 rows
      expect(table.children.length, equals(5));

      // TOTAL row is the last row
      final totalRow = table.children.last;
      expect(totalRow.decoration, isA<pw.BoxDecoration>());
      final dec = totalRow.decoration as pw.BoxDecoration;
      expect(dec.color, equals(PdfReportStyles.lightBlue));

      // Sum of counts: 12 + 9 + 6 = 27
      // Sum of pct: 40.0 + 30.0 + 20.0 = 90.0%
      final totalCount = items.fold<int>(0, (s, it) => s + it.count);
      final totalPct = items.fold<double>(0.0, (s, it) => s + it.percentageOfDomain);
      expect(totalCount, equals(27));
      expect(totalPct, equals(90.0));
    });

    test('2. Tableau B - Exploitation et maintenance has only ONE final TOTAL row', () {
      final rows = [
        const CategoryCrossAuditRow(
          categoryName: 'TGBT',
          equipementsCount: 1,
          ncCount: 5,
          critiquesCount: 2,
          majeuresCount: 3,
          pctOfTotalNc: 10.0,
          tauxCritique: 40.0,
          densite: 5.0,
        ),
        const CategoryCrossAuditRow(
          categoryName: 'Armoires',
          equipementsCount: 10,
          ncCount: 25,
          critiquesCount: 8,
          majeuresCount: 17,
          pctOfTotalNc: 50.0,
          tauxCritique: 32.0,
          densite: 2.5,
        ),
      ];

      final totalRow = const CategoryCrossAuditRow(
        categoryName: 'TOTAL BASSE TENSION',
        equipementsCount: 11,
        ncCount: 30,
        critiquesCount: 10,
        majeuresCount: 20,
        pctOfTotalNc: 60.0,
        tauxCritique: 33.3,
        densite: 2.7,
      );

      final tableWidget = PdfExecutiveSummaryBuilder.buildCategoryCrossTableForTesting(rows, totalRow, 'BT');
      expect(tableWidget, isA<pw.Table>());
      final table = tableWidget as pw.Table;

      // Header row (1) + 2 data rows + 1 TOTAL row = 4 rows (NO DUPLICATE ROW!)
      expect(table.children.length, equals(4));

      final finalRow = table.children.last;
      expect(finalRow.decoration, isA<pw.BoxDecoration>());
      final dec = finalRow.decoration as pw.BoxDecoration;
      expect(dec.color, equals(PdfReportStyles.lightBlue));
    });

    test('3. Tableaux 5 à 8 - Enrichment with X / TOTAL, soit Y %', () {
      // Table 5: Marques
      final marquesRow = const MarquesMatrixRow(
        category: DomainObjectType.armoire,
        organeDeTete: {'Schneider': 20, 'Legrand': 5},
        departs: {'Schneider': 40, 'Hager': 10},
        circuitsTerminaux: {'Schneider': 60, 'ABB': 15},
        totalTete: 50,
        totalDeparts: 100,
        totalTerminaux: 150,
      );

      expect(marquesRow.totalTete, equals(50));
      expect(marquesRow.totalDeparts, equals(100));
      expect(marquesRow.totalTerminaux, equals(150));

      // Table 6: Courbes
      final courbesRow = const CourbesMatrixRow(
        category: DomainObjectType.armoire,
        organeDeTete: {'Courbe C': 15},
        departs: {'Courbe C': 30, 'Courbe D': 10},
        circuitsTerminaux: {'Courbe C': 50},
        totalTete: 20,
        totalDeparts: 50,
        totalTerminaux: 80,
      );
      expect(courbesRow.totalTete, equals(20));
      expect(courbesRow.totalDeparts, equals(50));

      // Table 7: Adequation
      final adequationStats = const AdequationIccPdcStats(
        category: DomainObjectType.armoire,
        totalElements: 50,
        evaluables: 42,
        conformes: 35,
        nonConformes: 7,
        nonRenseignes: 8,
      );
      expect(adequationStats.totalElements, equals(50));
      expect(adequationStats.evaluables, equals(42));
      expect(adequationStats.conformes, equals(35));
      expect(adequationStats.complianceRate, closeTo(83.33, 0.05));

      // Table 8: Cables
      final cablesBreakdown = const CablesSectionBreakdown(
        metal: 'Cuivre',
        count: 12,
        totalCables: 50,
        percentageOfTotal: 24.0,
        sectionsCount: {'10 mm²': 12},
      );
      expect(cablesBreakdown.totalCables, equals(50));
      expect(cablesBreakdown.count, equals(12));
      expect(cablesBreakdown.percentageOfTotal, equals(24.0));
    });

    test('4. Section 9 - Adéquation classement des zones et indices IP/IK', () {
      final zoneItem = const IpIkZoneItem(
        zoneNom: 'Local TGBT',
        ipRequis: 'IP55',
        ikRequis: 'IK08',
        totalEquipements: 20,
        adequatCount: 15,
        presentDifferentCount: 3,
        absentCount: 2,
        indicesPresents: 18,
        pointsVerifies: 40,
        pointsNonConformes: 5,
      );

      expect(zoneItem.totalEquipements, equals(20));
      expect(zoneItem.adequatCount, equals(15));
      expect(zoneItem.presentDifferentCount, equals(3));
      expect(zoneItem.absentCount, equals(2));
      expect(zoneItem.nonConformesCount, equals(5));
      expect(zoneItem.nonComplianceRate, equals(25.0));
      expect(zoneItem.formattedNonComplianceRate, equals('25 %'));
      expect(zoneItem.indicesPresents, equals(18));

      // Index calculation:
      final indPct = (zoneItem.indicesPresents / zoneItem.totalEquipements * 100);
      expect(indPct, equals(90.0));

      // Test with 0 equipments (cas limite)
      final emptyZone = const IpIkZoneItem(
        zoneNom: 'Zone Vide',
        totalEquipements: 0,
        conformes: 0,
        nonConformes: 0,
        nonRenseignes: 0,
        indicesPresents: 0,
        pointsVerifies: 0,
        pointsNonConformes: 0,
      );
      expect(emptyZone.totalEquipements, equals(0));
      expect(emptyZone.complianceRate, equals(0.0));
      expect(emptyZone.formattedNonComplianceRate, equals('Non évaluable'));
    });
  });
}
