import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/statistics/risk_family_normalizer.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/mission_statistics.dart';
import 'package:inspec_app/services/ai/executive_summary_snapshot.dart';
import 'package:inspec_app/services/pdf/builders/pdf_executive_summary_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RiskFamilyNormalizer Forensic Tests', () {
    test('Normalizes curved apostrophes to straight apostrophes without altering text', () {
      expect(
        RiskFamilyNormalizer.normalize("Conditions d’exploitation"),
        equals("Conditions d'exploitation"),
      );
      expect(
        RiskFamilyNormalizer.normalize("Erreur d’exploitation / maintenance"),
        equals("Erreur d'exploitation / maintenance"),
      );
      expect(
        RiskFamilyNormalizer.normalize("Sécurité / conformité réglementaire"),
        equals("Sécurité / conformité réglementaire"),
      );
    });

    test('Handles multiple spaces, empty strings, and null gracefully', () {
      expect(RiskFamilyNormalizer.normalize(""), equals('Non spécifiée'));
      expect(RiskFamilyNormalizer.normalize("   "), equals('Non spécifiée'));
      expect(RiskFamilyNormalizer.normalize(null), equals('Non spécifiée'));
      expect(
        RiskFamilyNormalizer.normalize("  Contact  électrique  /   influences  externes  "),
        equals("Contact électrique / influences externes"),
      );
    });
  });

  group('Forensic TechnicalEnrichmentEngine & Dynamic Risk Blocks Tests', () {
    late MissionDomainInventory domainInventory;
    late AuditFindingInventory findingInventory;

    setUp(() {
      // Construction d'un jeu d'essais simulant fidèlement la répartition Cimencam Figuil :
      // 156 constats MT (47 DC local + 80 CE local + 23 cellules + 4 transfos + 2 armoire MT)
      // 340 constats BT (6 DC GE + 24 CE GE + 29 DC BT + 23 CE BT + 5 inv + 174 armoire + 79 coffret)
      // Total = 496 constats

      final findings = <AuditFinding>[];

      // 1. HTA Dispositions constructives (47 constats)
      // 27 Sécurité / conformité, 8 Sécurité des interventions, 8 Évacuation, 4 Échauffement
      for (int i = 0; i < 27; i++) {
        findings.add(AuditFinding(
          id: 'hta_dc_sec_$i',
          missionId: 'test_m',
          tensionDomain: TensionDomain.mt,
          origin: 'Poste MT',
          objectType: 'Local MT',
          objectName: 'Poste 1',
          tableName: 'Dispositions constructives',
          verificationPoint: 'Accès et conformité',
          observationText: 'Non conformité $i',
          conformity: 'non',
          criticality: 'Majeure',
          riskFamily: "Sécurité / conformité réglementaire",
        ));
      }
      for (int i = 0; i < 8; i++) {
        findings.add(AuditFinding(
          id: 'hta_dc_interv_$i',
          missionId: 'test_m',
          tensionDomain: TensionDomain.mt,
          origin: 'Poste MT',
          objectType: 'Local MT',
          objectName: 'Poste 1',
          tableName: 'Dispositions constructives',
          verificationPoint: 'Intervention',
          observationText: 'Non conformité $i',
          conformity: 'non',
          criticality: 'Critique',
          riskFamily: "Sécurité des interventions",
        ));
      }
      for (int i = 0; i < 8; i++) {
        findings.add(AuditFinding(
          id: 'hta_dc_evac_$i',
          missionId: 'test_m',
          tensionDomain: TensionDomain.mt,
          origin: 'Poste MT',
          objectType: 'Local MT',
          objectName: 'Poste 1',
          tableName: 'Dispositions constructives',
          verificationPoint: 'Issue de secours',
          observationText: 'Non conformité $i',
          conformity: 'non',
          criticality: 'Majeure',
          riskFamily: "Évacuation / continuité des installations de sécurité",
        ));
      }
      for (int i = 0; i < 4; i++) {
        findings.add(AuditFinding(
          id: 'hta_dc_echauff_$i',
          missionId: 'test_m',
          tensionDomain: TensionDomain.mt,
          origin: 'Poste MT',
          objectType: 'Local MT',
          objectName: 'Poste 1',
          tableName: 'Dispositions constructives',
          verificationPoint: 'Ventilation',
          observationText: 'Non conformité $i',
          conformity: 'non',
          criticality: 'Majeure',
          riskFamily: "Échauffement / conditions d’environnement", // avec apostrophe courbe exprès
        ));
      }

      // 2. HTA Exploitation et maintenance (109 constats)
      // 80 CE local (67 interventions, 12 maintenance, 1 contact)
      // 23 cellules (2 évacuation, 21 interventions)
      // 4 transformateurs
      // 2 armoire MT
      for (int i = 0; i < 67; i++) {
        findings.add(AuditFinding(
          id: 'hta_ce_loc_$i',
          missionId: 'test_m',
          tensionDomain: TensionDomain.mt,
          origin: 'Poste MT',
          objectType: 'Local MT',
          objectName: 'Poste 1',
          tableName: "Conditions d'exploitation",
          verificationPoint: 'Point CE $i',
          observationText: 'Obs $i',
          conformity: 'non',
          criticality: 'Critique',
          riskFamily: "Sécurité des interventions / risque électrique",
        ));
      }
      for (int i = 0; i < 12; i++) {
        findings.add(AuditFinding(
          id: 'hta_ce_maint_$i',
          missionId: 'test_m',
          tensionDomain: TensionDomain.mt,
          origin: 'Poste MT',
          objectType: 'Local MT',
          objectName: 'Poste 1',
          tableName: "Conditions d'exploitation",
          verificationPoint: 'Point CE maint $i',
          observationText: 'Obs $i',
          conformity: 'non',
          criticality: 'Majeure',
          riskFamily: "Erreur d’exploitation / maintenance",
        ));
      }
      findings.add(AuditFinding(
        id: 'hta_ce_contact_1',
        missionId: 'test_m',
        tensionDomain: TensionDomain.mt,
        origin: 'Poste MT',
        objectType: 'Local MT',
        objectName: 'Poste 1',
        tableName: "Conditions d'exploitation",
        verificationPoint: 'Contact',
        observationText: 'Obs contact',
        conformity: 'non',
        criticality: 'Majeure',
        riskFamily: "Contact électrique / influences externes / protection mécanique",
      ));

      // 23 cellules
      for (int i = 0; i < 2; i++) {
        findings.add(AuditFinding(
          id: 'hta_cel_evac_$i',
          missionId: 'test_m',
          tensionDomain: TensionDomain.mt,
          origin: 'Poste MT',
          objectType: 'Cellule MT',
          objectName: 'Cellule $i',
          tableName: 'Cellules',
          verificationPoint: 'Evacuation',
          observationText: 'Obs $i',
          conformity: 'non',
          criticality: 'Majeure',
          riskFamily: "Évacuation / sécurité incendie",
        ));
      }
      for (int i = 0; i < 21; i++) {
        findings.add(AuditFinding(
          id: 'hta_cel_interv_$i',
          missionId: 'test_m',
          tensionDomain: TensionDomain.mt,
          origin: 'Poste MT',
          objectType: 'Cellule MT',
          objectName: 'Cellule $i',
          tableName: 'Cellules',
          verificationPoint: 'Intervention',
          observationText: 'Obs $i',
          conformity: 'non',
          criticality: 'Critique',
          riskFamily: "Sécurité des interventions / risque électrique",
        ));
      }

      // 4 transformateurs
      for (int i = 0; i < 4; i++) {
        findings.add(AuditFinding(
          id: 'hta_tr_$i',
          missionId: 'test_m',
          tensionDomain: TensionDomain.mt,
          origin: 'Poste MT',
          objectType: 'Transformateur',
          objectName: 'Transfo $i',
          tableName: 'Transformateur',
          verificationPoint: 'Point $i',
          observationText: 'Obs $i',
          conformity: 'non',
          criticality: 'Majeure',
          riskFamily: "Erreur d'exploitation / maintenance",
        ));
      }

      // 2 transformateurs additionnels (total 6 constats transfos MT)
      for (int i = 4; i < 6; i++) {
        findings.add(AuditFinding(
          id: 'hta_tr_$i',
          missionId: 'test_m',
          tensionDomain: TensionDomain.mt,
          origin: 'Poste MT',
          objectType: 'Transformateur',
          objectName: 'Transfo $i',
          tableName: 'Transformateur',
          verificationPoint: 'Point $i',
          observationText: 'Obs $i',
          conformity: 'non',
          criticality: 'Majeure',
          riskFamily: "Sécurité des interventions / risque électrique",
        ));
      }

      // Total MT = 47 + 109 = 156.
      expect(findings.length, equals(156));

      // 3. BT Dispositions constructives (35 constats : 6 GE + 29 BT)
      // 10 Sécurité / conformité, 7 Erreur exploitation, 6 Incendie/fuite, 3 Accès non autorisé, 2 Incendie propagation, 7 autres
      final btDcRiskFamilies = [
        ...List.filled(10, "Sécurité / conformité réglementaire"),
        ...List.filled(7, "Erreur d’exploitation / maintenance"),
        ...List.filled(6, "Incendie / brûlure / fuite de combustible"),
        ...List.filled(3, "Accès non autorisé / risque électrique"),
        ...List.filled(2, "Incendie / propagation du feu"),
        ...List.generate(7, (idx) => "Autre risque constructif $idx"), // 7 familles distinctes de 1 constat hors TOP 5
      ];
      expect(btDcRiskFamilies.length, equals(35));
      for (int i = 0; i < 35; i++) {
        final isGe = i < 6;
        findings.add(AuditFinding(
          id: 'bt_dc_$i',
          missionId: 'test_m',
          tensionDomain: TensionDomain.bt,
          origin: 'Zone BT',
          objectType: isGe ? 'Groupe Électrogène' : 'Local BT',
          objectName: isGe ? 'Local GE 1' : 'Local BT 1',
          tableName: 'Dispositions constructives',
          verificationPoint: 'Point DC BT $i',
          observationText: 'Obs $i',
          conformity: 'non',
          criticality: 'Majeure',
          riskFamily: btDcRiskFamilies[i],
        ));
      }

      // 4. BT Exploitation et maintenance (305 constats)
      // 24 CE GE, 23 CE BT, 5 inv, 174 armoires, 79 coffrets
      // 65 Contact électrique, 54 Erreur exploitation, 27 Sécurité interventions, 21 Sécurité conformité, 14 Incendie surcharge, 124 autres
      final btCeRiskFamilies = [
        ...List.filled(65, "Contact électrique / influences externes / protection mécanique"),
        ...List.filled(54, "Erreur d’exploitation / maintenance"),
        ...List.filled(27, "Sécurité des interventions / risque électrique"),
        ...List.filled(21, "Sécurité / conformité réglementaire"),
        ...List.filled(14, "Incendie / échauffement / surcharge des conducteurs"),
        ...List.generate(124, (idx) => "Autre risque exploitation $idx"), // 124 familles distinctes de 1 constat hors TOP 5 (181 TOP 5 + 124 = 305)
      ];
      expect(btCeRiskFamilies.length, equals(305));
      for (int i = 0; i < 305; i++) {
        final String objType;
        final String objName;
        final String tbl;
        if (i < 24) {
          objType = 'Groupe Électrogène';
          objName = 'Local GE 1';
          tbl = "Conditions d'exploitation";
        } else if (i < 47) {
          objType = 'Local BT';
          objName = 'Local BT 1';
          tbl = "Conditions d'exploitation";
        } else if (i < 52) {
          objType = 'Inverseur';
          objName = 'Inverseur 1';
          tbl = 'Inverseur';
        } else if (i < 226) {
          objType = 'Armoire';
          objName = 'Armoire BT 1';
          tbl = 'Armoire';
        } else {
          objType = 'Coffret';
          objName = 'Coffret BT 1';
          tbl = 'Coffret';
        }

        findings.add(AuditFinding(
          id: 'bt_ce_$i',
          missionId: 'test_m',
          tensionDomain: TensionDomain.bt,
          origin: 'Zone BT',
          objectType: objType,
          objectName: objName,
          tableName: tbl,
          verificationPoint: 'Point CE BT $i',
          observationText: 'Obs $i',
          conformity: 'non',
          criticality: 'Majeure',
          riskFamily: btCeRiskFamilies[i],
        ));
      }

      expect(findings.length, equals(496));

      final instances = <DomainEntityInstance>[
        DomainEntityInstance(
          instanceId: 'loc_mt_1',
          name: 'Poste MT 1',
          category: DomainObjectType.localMT,
          tensionDomain: TensionDomain.mt,
          originPath: 'MT',
          findings: findings.where((f) => f.objectType == 'Local MT').toList(),
        ),
        DomainEntityInstance(
          instanceId: 'cel_mt_1',
          name: 'Cellule MT 1',
          category: DomainObjectType.celluleMT,
          tensionDomain: TensionDomain.mt,
          originPath: 'MT',
          findings: findings.where((f) => f.objectType == 'Cellule MT').toList(),
        ),
        DomainEntityInstance(
          instanceId: 'tr_mt_1',
          name: 'Transfo MT 1',
          category: DomainObjectType.transformateurMTBT,
          tensionDomain: TensionDomain.mt,
          originPath: 'MT',
          findings: findings.where((f) => f.objectType == 'Transformateur').toList(),
        ),
        DomainEntityInstance(
          instanceId: 'loc_ge_1',
          name: 'Local GE 1',
          category: DomainObjectType.localGE,
          tensionDomain: TensionDomain.bt,
          originPath: 'BT',
          findings: findings.where((f) => f.objectType == 'Groupe Électrogène').toList(),
        ),
        DomainEntityInstance(
          instanceId: 'loc_bt_1',
          name: 'Local BT 1',
          category: DomainObjectType.localBT,
          tensionDomain: TensionDomain.bt,
          originPath: 'BT',
          findings: findings.where((f) => f.objectType == 'Local BT').toList(),
        ),
        DomainEntityInstance(
          instanceId: 'inv_bt_1',
          name: 'Inverseur 1',
          category: DomainObjectType.inverseur,
          tensionDomain: TensionDomain.bt,
          originPath: 'BT',
          findings: findings.where((f) => f.objectType == 'Inverseur').toList(),
        ),
        DomainEntityInstance(
          instanceId: 'arm_bt_1',
          name: 'Armoire BT 1',
          category: DomainObjectType.armoire,
          tensionDomain: TensionDomain.bt,
          originPath: 'BT',
          findings: findings.where((f) => f.objectType == 'Armoire' && f.tensionDomain == TensionDomain.bt).toList(),
        ),
        DomainEntityInstance(
          instanceId: 'cof_bt_1',
          name: 'Coffret BT 1',
          category: DomainObjectType.coffret,
          tensionDomain: TensionDomain.bt,
          originPath: 'BT',
          findings: findings.where((f) => f.objectType == 'Coffret').toList(),
        ),
      ];

      domainInventory = MissionDomainInventory(
        missionId: 'test_m',
        allFindings: findings,
        instances: instances,
      );

      findingInventory = AuditFindingInventory(
        missionId: 'test_m',
        findings: findings,
      );
    });

    test('Section 3 Risk Blocks: Strict separation of HTA and BT without mixing', () {
      final result = TechnicalEnrichmentEngine.compute('test_m', domainInventory, findingInventory);
      final matrix = result.riskFamilyMatrix;

      // ─── BLOC 1 : DISPOSITION CONSTRUCTIVE ───
      final bloc1Hta = matrix.dispositionsConstructives.hta;
      final bloc1Bt = matrix.dispositionsConstructives.bt;

      expect(bloc1Hta.totalConstats, equals(47));
      expect(bloc1Hta.items.length, equals(4)); // Exactement 4 familles pour HTA
      expect(bloc1Hta.sumTopOccurrences, equals(47));
      expect(bloc1Hta.formattedPartTopSum, equals('100,0 %'));

      expect(bloc1Bt.totalConstats, equals(35));
      expect(bloc1Bt.items.length, equals(5)); // TOP 5
      expect(bloc1Bt.sumTopOccurrences, equals(28)); // 10 + 7 + 6 + 3 + 2 = 28
      // IMPORTANT : Ne JAMAIS forcer 100% !
      expect(bloc1Bt.formattedPartTopSum, equals('80,0 %'));

      // ─── BLOC 2 : EXPLOITATION ET MAINTENANCE ───
      final bloc2Hta = matrix.exploitationMaintenance.hta;
      final bloc2Bt = matrix.exploitationMaintenance.bt;

      expect(bloc2Hta.totalConstats, equals(109));
      expect(bloc2Hta.items.length, equals(4)); // 4 familles
      expect(bloc2Hta.sumTopOccurrences, equals(109));
      expect(bloc2Hta.formattedPartTopSum, equals('100,0 %'));

      expect(bloc2Bt.totalConstats, equals(305));
      expect(bloc2Bt.items.length, equals(5)); // TOP 5
      expect(bloc2Bt.sumTopOccurrences, equals(181)); // 65 + 54 + 27 + 21 + 14 = 181
      // IMPORTANT : Ne JAMAIS forcer 100% !
      expect(bloc2Bt.formattedPartTopSum, equals('59,3 %')); // 181 / 305 = 59.34%
    });

    test('Contrôle croisé obligatoire : Tableau 3 vs Tableaux 4.1 & 4.2', () {
      final result = TechnicalEnrichmentEngine.compute('test_m', domainInventory, findingInventory);
      final matrix = result.riskFamilyMatrix;

      // TOTAL DISPOSITION CONSTRUCTIVE MT tableau 3 = tableau 4.1 A
      expect(
        matrix.dispositionsConstructives.hta.totalConstats,
        equals(result.locauxMtFindings.dispoConstructives),
      );
      expect(matrix.dispositionsConstructives.hta.totalConstats, equals(47));

      // TOTAL DISPOSITIONS CONSTRUCTIVES MT dans la matrice
      expect(
        matrix.dispositionsConstructives.hta.totalConstats,
        equals(result.locauxMtFindings.dispoConstructives),
      );
      expect(matrix.dispositionsConstructives.hta.totalConstats, equals(47));

      // TOTAL EXPLOITATION ET MAINTENANCE MT dans la matrice (hors dispo constructives)
      expect(matrix.exploitationMaintenance.hta.totalConstats, equals(109));

      // TOTAL TABLEAU MT (Locaux techniques = dispo constructives + conditions d'exploitation = 47 + 80 = 127)
      final mtLocauxRow = result.mtCategoriesCrossRows.firstWhere((r) => r.categoryName.contains('Locaux'));
      expect(mtLocauxRow.ncCount, equals(127));
      final mtCrossTotal = result.mtCategoriesCrossRows.fold<int>(0, (s, r) => s + r.ncCount);
      expect(mtCrossTotal, equals(156));
      expect(result.mtTotalCrossRow.ncCount, equals(156));

      // TOTAL DISPOSITION CONSTRUCTIVE BT dans la matrice
      expect(
        matrix.dispositionsConstructives.bt.totalConstats,
        equals(result.locauxBtFindings.dispoConstructives),
      );
      expect(matrix.dispositionsConstructives.bt.totalConstats, equals(35));

      // TOTAL EXPLOITATION ET MAINTENANCE BT dans la matrice (hors dispo constructives)
      expect(matrix.exploitationMaintenance.bt.totalConstats, equals(305));

      // TOTAL TABLEAU BT (Locaux techniques GE et BT = dispo constructives + conditions d'exploitation)
      final btLocauxGeRow = result.btCategoriesCrossRows.firstWhere((r) => r.categoryName.contains('GE'));
      final btLocauxBtRow = result.btCategoriesCrossRows.firstWhere((r) => r.categoryName.contains('BT') && r.categoryName.contains('Locaux'));
      expect(btLocauxGeRow.ncCount, equals(30)); // 6 dispo + 24 conditions exploitation
      expect(btLocauxBtRow.ncCount, equals(52)); // 29 dispo + 23 conditions exploitation
      final btCrossTotal = result.btCategoriesCrossRows.fold<int>(0, (s, r) => s + r.ncCount);
      expect(btCrossTotal, equals(340));
      expect(result.btTotalCrossRow.ncCount, equals(340));

      // TOTAL TABLEAUX EXPLOITATION ET MAINTENANCE (Section 3.1 B & Section 3.2 B)
      // Doivent être en cohérence absolue avec la Section 4
      expect(result.mtExploitationTotalCrossRow.ncCount, equals(109));
      expect(result.mtExploitationTotalCrossRow.ncCount, equals(result.htaExploitationMaintenance));
      expect(result.btExploitationTotalCrossRow.ncCount, equals(305));
      expect(result.btExploitationTotalCrossRow.ncCount, equals(result.btExploitationMaintenance));

      // Cohérence mathématique stricte Section 2.1 : Dispo constructives + Exploitation = 100%
      expect(result.htaDispoConstructives + result.htaExploitationMaintenance, equals(result.totalHtaNc));
      expect(result.btDispoConstructives + result.btExploitationMaintenance, equals(result.totalBtNc));
      final htaDispoRate = result.htaDispoConstructives / result.totalHtaNc;
      final htaExploitRate = result.htaExploitationMaintenance / result.totalHtaNc;
      expect((htaDispoRate + htaExploitRate) * 100, closeTo(100.0, 0.0001));

      final btDispoRate = result.btDispoConstructives / result.totalBtNc;
      final btExploitRate = result.btExploitationMaintenance / result.totalBtNc;
      expect((btDispoRate + btExploitRate) * 100, closeTo(100.0, 0.0001));

      // Réconciliation globale des 496 constats
      expect(mtCrossTotal + btCrossTotal, equals(496));
    });

    test('Section 2.1 PDF Indicators Table & Section 3 Risk Blocks Table Render Without Error', () {
      final result = TechnicalEnrichmentEngine.compute('test_m', domainInventory, findingInventory);
      final summary = MissionStatisticsSummary.fromInventory(findingInventory);
      final snapshot = ExecutiveSummarySnapshot(
        missionId: 'test_m',
        clientName: 'Cimencam',
        siteName: 'Figuil',
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
        equipmentCount: 132,
        installationsCount: 496,
        globalDensityStr: '3,76',
      );

      // 1. Rendu du Tableau 2.1
      final table21 = PdfExecutiveSummaryBuilder.build12IndicateursTableForTesting(
        summary,
        snapshot,
        result,
      );
      expect(table21, isA<pw.Widget>());

      // 2. Rendu du Tableau 3
      final table3 = PdfExecutiveSummaryBuilder.buildRiskFamilyMatrixTableForTesting(
        result.riskFamilyMatrix,
      );
      expect(table3, isA<pw.Widget>());

      // Build dans un vrai document PDF pour valider l'absence de crash
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => pw.Column(
            children: [
              table21,
              pw.SizedBox(height: 10),
              table3,
            ],
          ),
        ),
      );

      final pdfBytes = doc.save();
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.then((b) => b.length), completion(greaterThan(1000)));
    });
  });
}
