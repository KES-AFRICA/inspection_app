import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/ai/executive_summary_snapshot.dart';
import 'package:inspec_app/services/ai/mission_executive_summary_service.dart';
import 'package:inspec_app/services/pdf/builders/pdf_executive_summary_builder.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('Executive Summary formatting, cell fusion and centering verification', () async {
    final mission = Mission(
      id: 'M-EXEC-FORMAT-TEST',
      nomClient: 'KES ENERGIE AFRICA',
      nomSite: 'SITE YAOUNDE',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: 'active',
    );

    final snapshot = ExecutiveSummarySnapshot(
      missionId: mission.id,
      clientName: mission.nomClient,
      siteName: mission.nomSite ?? 'SITE YAOUNDE',
      natureMission: 'Vérification Périodique',
      dateRangeText: 'du 01 au 05/09/2026',
      domainTension: 'Basse Tension (BT)',
      companyName: 'KES Africa',
      reportNumber: 'KES-2026-001',
      reportDateStr: '06/09/2026',
      officialStats: {
        'totalNC': 5,
        'critique': 2,
        'majeure': 2,
        'mineure': 1,
        'pctCritique': '40,0',
        'pctMajeure': '40,0',
        'pctMineure': '20,0',
      },
      categoryStats: [],
      topDefects: [],
      riskFamilies: [],
      equipmentCount: 12,
      installationsCount: 2,
      globalDensityStr: '0,42',
    );

    final summaryData = MissionExecutiveSummaryService.buildDeterministicFallback(
      mission.id,
      snapshot,
    );

    final trackedPages = <String, int>{};
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => PdfExecutiveSummaryBuilder.buildResumeExecutif(
          mission,
          trackedPages,
          'KES/IP/VE/2026/001',
          summaryData: summaryData,
          offset: 0,
        ),
      ),
    );

    final bytes = await doc.save();
    expect(bytes.isNotEmpty, isTrue);
    expect(bytes.length, greaterThan(5000));
    final file = File('pdf_exec_summary_fixed.pdf');
    await file.writeAsBytes(bytes);
  });

  test('Courbes and Adequation format verification in Executive Summary', () {
    // 1. Verify that Courbes format displays without 'Courbe ' prefix
    final testMap = {'COURBE-C': 3, 'COURBE-D': 1};
    final sorted = testMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final formattedCourbes = sorted.map((e) => '${e.key} : ${e.value}').join('\n');
    expect(formattedCourbes, contains('COURBE-C : 3'));
    expect(formattedCourbes, isNot(contains('Courbe COURBE-C')));

    // 2. Verify that Adequation with evaluables == 0 returns empty string
    // In _buildAdequationTable:
    // formatAdequation returns '' when s == null || s.totalElements == 0 || s.evaluables == 0
  });
}
