import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/builders/pdf_executive_summary_builder.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';
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
      missionId: 'M-RISK-TEST',
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

  group('TechnicalEnrichmentEngine - Dynamic Risk Family Matrix', () {
    test('Correct quadrant assignment, ranking, tie-breaking and top 5 capping', () {
      // 1. Locaux MT (HTA Dispositions Constructives): 2 families only (< 5)
      final localMT = DomainEntityInstance(
        instanceId: 'loc-mt-1',
        category: DomainObjectType.localMT,
        name: 'Poste MT 1',
        tensionDomain: TensionDomain.mt,
        originPath: 'Locaux MT',
        findings: [
          createFinding(id: '1', tensionDomain: TensionDomain.mt, objectType: 'Local MT', riskFamily: 'Électrisation'),
          createFinding(id: '2', tensionDomain: TensionDomain.mt, objectType: 'Local MT', riskFamily: 'Électrisation'),
          createFinding(id: '3', tensionDomain: TensionDomain.mt, objectType: 'Local MT', riskFamily: 'Électrisation'),
          createFinding(id: '4', tensionDomain: TensionDomain.mt, objectType: 'Local MT', riskFamily: 'Incendie'),
        ],
      );

      // 2. Équipements MT (HTA Exploitation et Maintenance): 0 findings (empty quadrant)
      final celluleMT = DomainEntityInstance(
        instanceId: 'cel-mt-1',
        category: DomainObjectType.celluleMT,
        name: 'Cellule Arrivée',
        tensionDomain: TensionDomain.mt,
        originPath: 'Cellules MT',
        findings: [],
      );

      // 3. Locaux BT / GE (BT Dispositions Constructives): 3 families with a tie
      // Tie between "Risque A" (2) and "Risque B" (2) -> alphabetical order: Risque A before Risque B
      final localBT = DomainEntityInstance(
        instanceId: 'loc-bt-1',
        category: DomainObjectType.localBT,
        name: 'Local TGBT',
        tensionDomain: TensionDomain.bt,
        originPath: 'Locaux BT',
        findings: [
          createFinding(id: '10', tensionDomain: TensionDomain.bt, objectType: 'Local BT', riskFamily: 'Risque B'),
          createFinding(id: '11', tensionDomain: TensionDomain.bt, objectType: 'Local BT', riskFamily: 'Risque B'),
          createFinding(id: '12', tensionDomain: TensionDomain.bt, objectType: 'Local BT', riskFamily: 'Risque A'),
          createFinding(id: '13', tensionDomain: TensionDomain.bt, objectType: 'Local BT', riskFamily: 'Risque A'),
          createFinding(id: '14', tensionDomain: TensionDomain.bt, objectType: 'Local BT', riskFamily: 'Risque C'),
        ],
      );

      // 4. Équipements BT (BT Exploitation et Maintenance): 7 distinct families (> 5)
      // Fam1: 10, Fam2: 8, Fam3: 6, Fam4: 4, Fam5: 3, Fam6: 2, Fam7: 1 -> Total = 34
      final armoireFindings = <AuditFinding>[];
      for (int i = 0; i < 10; i++) {
        armoireFindings.add(createFinding(id: 'f1_$i', tensionDomain: TensionDomain.bt, objectType: 'Armoire', riskFamily: 'Famille 1'));
      }
      for (int i = 0; i < 8; i++) {
        armoireFindings.add(createFinding(id: 'f2_$i', tensionDomain: TensionDomain.bt, objectType: 'Armoire', riskFamily: 'Famille 2'));
      }
      for (int i = 0; i < 6; i++) {
        armoireFindings.add(createFinding(id: 'f3_$i', tensionDomain: TensionDomain.bt, objectType: 'Armoire', riskFamily: 'Famille 3'));
      }
      for (int i = 0; i < 4; i++) {
        armoireFindings.add(createFinding(id: 'f4_$i', tensionDomain: TensionDomain.bt, objectType: 'Armoire', riskFamily: 'Famille 4'));
      }
      for (int i = 0; i < 3; i++) {
        armoireFindings.add(createFinding(id: 'f5_$i', tensionDomain: TensionDomain.bt, objectType: 'Armoire', riskFamily: 'Famille 5'));
      }
      for (int i = 0; i < 2; i++) {
        armoireFindings.add(createFinding(id: 'f6_$i', tensionDomain: TensionDomain.bt, objectType: 'Armoire', riskFamily: 'Famille 6'));
      }
      armoireFindings.add(createFinding(id: 'f7_0', tensionDomain: TensionDomain.bt, objectType: 'Armoire', riskFamily: 'Famille 7'));

      final armoireBT = DomainEntityInstance(
        instanceId: 'arm-1',
        category: DomainObjectType.armoire,
        name: 'Armoire Distribution',
        tensionDomain: TensionDomain.bt,
        originPath: 'Armoires BT',
        findings: armoireFindings,
      );

      final domainInventory = MissionDomainInventory(
        missionId: 'M-RISK-TEST',
        instances: [localMT, celluleMT, localBT, armoireBT],
        allFindings: [
          ...localMT.findings,
          ...celluleMT.findings,
          ...localBT.findings,
          ...armoireBT.findings,
        ],
      );

      final findingInventory = AuditFindingInventory(
        missionId: 'M-RISK-TEST',
        findings: domainInventory.allFindings,
      );

      final technicalStats = TechnicalEnrichmentEngine.compute(
        'M-RISK-TEST',
        domainInventory,
        findingInventory,
      );
      final matrix = technicalStats.riskFamilyMatrix;

      // --- Quadrant 1: HTA Dispositions Constructives (< 5 families) ---
      final qHtaDispo = matrix.htaDispositionsConstructives;
      expect(qHtaDispo.totalConstats, 4);
      expect(qHtaDispo.items.length, 2); // strictly 2 items, no dummy filler
      expect(qHtaDispo.items[0].famille, 'Électrisation');
      expect(qHtaDispo.items[0].constats, 3);
      expect(qHtaDispo.items[0].partStr, '75,0 %');
      expect(qHtaDispo.items[1].famille, 'Incendie');
      expect(qHtaDispo.items[1].constats, 1);
      expect(qHtaDispo.items[1].partStr, '25,0 %');

      // --- Quadrant 2: HTA Exploitation et Maintenance (0 findings) ---
      final qHtaExploit = matrix.htaExploitationMaintenance;
      expect(qHtaExploit.totalConstats, 0);
      expect(qHtaExploit.items.isEmpty, isTrue);

      // --- Quadrant 3: BT Dispositions Constructives (Tie-breaker test) ---
      final qBtDispo = matrix.btDispositionsConstructives;
      expect(qBtDispo.totalConstats, 5);
      expect(qBtDispo.items.length, 3);
      // Risque A (2) and Risque B (2) tie -> Risque A must come first
      expect(qBtDispo.items[0].famille, 'Risque A');
      expect(qBtDispo.items[0].constats, 2);
      expect(qBtDispo.items[0].partStr, '40,0 %');
      expect(qBtDispo.items[1].famille, 'Risque B');
      expect(qBtDispo.items[1].constats, 2);
      expect(qBtDispo.items[1].partStr, '40,0 %');
      expect(qBtDispo.items[2].famille, 'Risque C');
      expect(qBtDispo.items[2].constats, 1);
      expect(qBtDispo.items[2].partStr, '20,0 %');

      // --- Quadrant 4: BT Exploitation et Maintenance (Top 5 cap test) ---
      final qBtExploit = matrix.btExploitationMaintenance;
      expect(qBtExploit.totalConstats, 34);
      expect(qBtExploit.items.length, 5); // Strictly top 5 of the 7 families
      expect(qBtExploit.items[0].famille, 'Famille 1');
      expect(qBtExploit.items[0].constats, 10);
      // 10 / 34 * 100 = 29.41% -> '29,4 %'
      expect(qBtExploit.items[0].partStr, '29,4 %');
      expect(qBtExploit.items[1].famille, 'Famille 2');
      expect(qBtExploit.items[1].constats, 8);
      // 8 / 34 * 100 = 23.53% -> '23,5 %'
      expect(qBtExploit.items[1].partStr, '23,5 %');
      expect(qBtExploit.items[2].famille, 'Famille 3');
      expect(qBtExploit.items[2].constats, 6);
      expect(qBtExploit.items[3].famille, 'Famille 4');
      expect(qBtExploit.items[3].constats, 4);
      expect(qBtExploit.items[4].famille, 'Famille 5');
      expect(qBtExploit.items[4].constats, 3);

      // Backward compatible totals
      expect(matrix.totalHtaDispo, 4);
      expect(matrix.totalHtaExploit, 0);
      expect(matrix.totalBtDispo, 5);
      expect(matrix.totalBtExploit, 34);
      expect(matrix.totalHta, 4);
      expect(matrix.totalBt, 39);
      expect(matrix.totalGlobal, 43);
    });

    test('PDF Executive Summary Builder generates table cleanly with dynamic data', () async {
      final mission = Mission(
        id: 'M-PDF-DYNAMIC-RISK-TEST',
        nomClient: 'TEST CLIENT SARL',
        nomSite: 'SITE YAOUNDE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
      );

      final trackedPages = <String, int>{};
      final doc = pw.Document();

      // Ensure PdfExecutiveSummaryBuilder.buildResumeExecutif executes without error
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
