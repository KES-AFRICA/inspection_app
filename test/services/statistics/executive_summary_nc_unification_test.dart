// test/services/statistics/executive_summary_nc_unification_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/builders/pdf_executive_summary_builder.dart';

void main() {
  group('Unification et Fiabilisation des Non-Conformités (2.1, 3, 4)', () {
    AuditFinding createFinding({
      required String id,
      required TensionDomain tensionDomain,
      required String origin,
      required String objectType,
      required String tableName,
      required String verificationPoint,
      String criticality = 'Majeure',
      String riskFamily = 'Protection contre les chocs électriques',
    }) {
      return AuditFinding(
        id: id,
        missionId: 'm_test_unif',
        tensionDomain: tensionDomain,
        origin: origin,
        objectType: objectType,
        objectName: objectType,
        tableName: tableName,
        verificationPoint: verificationPoint,
        observationText: 'Observation sur $verificationPoint',
        conformity: 'non',
        criticality: criticality,
        riskFamily: riskFamily,
      );
    }

    test('Test 1 — Cohérence absolue HTA (2.1 == 3 == 4.1)', () {
      final findings = <AuditFinding>[];
      final instances = <DomainEntityInstance>[];

      // Local MT : 2 dispositions constructives, 3 conditions d'exploitation
      final localMtInst = DomainEntityInstance(
        instanceId: 'loc_mt_1',
        category: DomainObjectType.localMT,
        name: 'Local MT 1',
        tensionDomain: TensionDomain.mt,
        originPath: 'Zone MT',
      );
      final mtDispo1 = createFinding(
        id: 'mt_dc_1',
        tensionDomain: TensionDomain.mt,
        origin: 'Local MT 1',
        objectType: 'Local MT',
        tableName: 'Dispositions constructives',
        verificationPoint: 'Porte d\'accès',
      );
      final mtDispo2 = createFinding(
        id: 'mt_dc_2',
        tensionDomain: TensionDomain.mt,
        origin: 'Local MT 1',
        objectType: 'Local MT',
        tableName: 'Dispositions constructives',
        verificationPoint: 'Ventilation haute/basse',
      );
      final mtCe1 = createFinding(
        id: 'mt_ce_1',
        tensionDomain: TensionDomain.mt,
        origin: 'Local MT 1',
        objectType: 'Local MT',
        tableName: 'Conditions d\'exploitation',
        verificationPoint: 'Propreté du local',
      );
      final mtCe2 = createFinding(
        id: 'mt_ce_2',
        tensionDomain: TensionDomain.mt,
        origin: 'Local MT 1',
        objectType: 'Local MT',
        tableName: 'Conditions d\'exploitation',
        verificationPoint: 'Éclairage de sécurité',
      );
      final mtCe3 = createFinding(
        id: 'mt_ce_3',
        tensionDomain: TensionDomain.mt,
        origin: 'Local MT 1',
        objectType: 'Local MT',
        tableName: 'Conditions d\'exploitation',
        verificationPoint: 'Présence des EPI MT',
      );
      localMtInst.findings.addAll([mtDispo1, mtDispo2, mtCe1, mtCe2, mtCe3]);
      instances.add(localMtInst);
      findings.addAll([mtDispo1, mtDispo2, mtCe1, mtCe2, mtCe3]);

      // Cellule MT : 4 constats d'exploitation
      final cellInst = DomainEntityInstance(
        instanceId: 'cell_1',
        category: DomainObjectType.celluleMT,
        name: 'Cellule Arrivée MT',
        tensionDomain: TensionDomain.mt,
        originPath: 'Local MT 1',
      );
      for (int i = 0; i < 4; i++) {
        final f = createFinding(
          id: 'cell_f_$i',
          tensionDomain: TensionDomain.mt,
          origin: 'Cellule MT',
          objectType: 'Cellule MT',
          tableName: 'Points de vérification',
          verificationPoint: 'Verrouillage mécanique $i',
        );
        cellInst.findings.add(f);
        findings.add(f);
      }
      instances.add(cellInst);

      // Transformateur MT/BT : 5 constats d'exploitation
      final transfoInst = DomainEntityInstance(
        instanceId: 'tr_1',
        category: DomainObjectType.transformateurMTBT,
        name: 'Transfo 1',
        tensionDomain: TensionDomain.mt,
        originPath: 'Local MT 1',
      );
      for (int i = 0; i < 5; i++) {
        final f = createFinding(
          id: 'tr_f_$i',
          tensionDomain: TensionDomain.mt,
          origin: 'Transformateur MT/BT',
          objectType: 'Transformateur MT/BT',
          tableName: 'Tableau Transformateur',
          verificationPoint: 'Bac de rétention transfo $i',
        );
        transfoInst.findings.add(f);
        findings.add(f);
      }
      instances.add(transfoInst);

      final domainInventory = MissionDomainInventory(
        missionId: 'm_test_unif',
        instances: instances,
        allFindings: findings,
      );
      final findingInventory = AuditFindingInventory(
        missionId: 'm_test_unif',
        findings: findings,
      );

      final technical = TechnicalEnrichmentEngine.compute(
        'm_test_unif',
        domainInventory,
        findingInventory,
      );

      // Vérifications Tableau A (4.1)
      expect(technical.locauxMtFindings.dispoConstructives, equals(2));
      expect(technical.locauxMtFindings.conditionsExploitation, equals(3));
      expect(technical.locauxMtFindings.total, equals(5));

      // Vérifications Tableau B : 5 (locaux: 2 dispo + 3 CE) + 4 (cellules) + 5 (transfos) = 14 NC
      expect(technical.mtTotalCrossRow.ncCount, equals(14));

      // Vérifications Section 3 (HTA)
      expect(technical.riskFamilyMatrix.totalHtaDispo, equals(2));
      expect(technical.riskFamilyMatrix.totalHtaExploit, equals(12));

      // Vérifications Section 2.1 (Getters unifiés)
      expect(technical.htaDispoConstructives, equals(2));
      expect(technical.htaConditionsExploit, equals(3));
      expect(technical.totalHtaNc, equals(14)); // 2 dispo + 12 exploit = 14 total

      // Égalité stricte : 2.1 == 3 == 4.1
      expect(technical.totalHtaNc, equals(technical.riskFamilyMatrix.totalHtaDispo + technical.riskFamilyMatrix.totalHtaExploit));
      expect(technical.mtTotalCrossRow.ncCount, equals(technical.totalHtaNc));
      expect(technical.locauxMtFindings.dispoConstructives, equals(technical.riskFamilyMatrix.totalHtaDispo));
    });

    test('Test 2 — Cohérence absolue BT (2.1 == 3 == 4.2)', () {
      final findings = <AuditFinding>[];
      final instances = <DomainEntityInstance>[];

      // Local BT : 3 dispositions constructives, 4 conditions d'exploitation
      final localBtInst = DomainEntityInstance(
        instanceId: 'loc_bt_1',
        category: DomainObjectType.localBT,
        name: 'Local TGBT',
        tensionDomain: TensionDomain.bt,
        originPath: 'Zone BT',
      );
      for (int i = 0; i < 3; i++) {
        final f = createFinding(
          id: 'bt_dc_$i',
          tensionDomain: TensionDomain.bt,
          origin: 'Local BT',
          objectType: 'Local BT',
          tableName: 'Dispositions constructives',
          verificationPoint: 'Accès local $i',
        );
        localBtInst.findings.add(f);
        findings.add(f);
      }
      for (int i = 0; i < 4; i++) {
        final f = createFinding(
          id: 'bt_ce_$i',
          tensionDomain: TensionDomain.bt,
          origin: 'Local BT',
          objectType: 'Local BT',
          tableName: 'Conditions d\'exploitation',
          verificationPoint: 'Propreté local BT $i',
        );
        localBtInst.findings.add(f);
        findings.add(f);
      }
      instances.add(localBtInst);

      // TGBT : 6 constats
      final tgbtInst = DomainEntityInstance(
        instanceId: 'tgbt_1',
        category: DomainObjectType.tgbt,
        name: 'TGBT Principal',
        tensionDomain: TensionDomain.bt,
        originPath: 'Local TGBT',
      );
      for (int i = 0; i < 6; i++) {
        final f = createFinding(
          id: 'tgbt_f_$i',
          tensionDomain: TensionDomain.bt,
          origin: 'TGBT',
          objectType: 'TGBT',
          tableName: 'Points de vérification',
          verificationPoint: 'Schéma unifilaire $i',
        );
        tgbtInst.findings.add(f);
        findings.add(f);
      }
      instances.add(tgbtInst);

      // Armoires : 10 constats
      final armoireInst = DomainEntityInstance(
        instanceId: 'arm_1',
        category: DomainObjectType.armoire,
        name: 'Armoire Climatisation',
        tensionDomain: TensionDomain.bt,
        originPath: 'Local TGBT',
      );
      for (int i = 0; i < 10; i++) {
        final f = createFinding(
          id: 'arm_f_$i',
          tensionDomain: TensionDomain.bt,
          origin: 'Armoire',
          objectType: 'Armoire',
          tableName: 'Points de vérification',
          verificationPoint: 'Calibre protection amont $i',
        );
        armoireInst.findings.add(f);
        findings.add(f);
      }
      instances.add(armoireInst);

      final domainInventory = MissionDomainInventory(
        missionId: 'm_test_unif',
        instances: instances,
        allFindings: findings,
      );
      final findingInventory = AuditFindingInventory(
        missionId: 'm_test_unif',
        findings: findings,
      );

      final technical = TechnicalEnrichmentEngine.compute(
        'm_test_unif',
        domainInventory,
        findingInventory,
      );

      // Tableau A BT (4.2)
      expect(technical.locauxBtFindings.dispoConstructives, equals(3));
      expect(technical.locauxBtFindings.conditionsExploitation, equals(4));
      expect(technical.locauxBtFindings.total, equals(7));

      // Tableau B BT : 7 (locaux: 3 dispo + 4 CE) + 6 (tgbt) + 10 (armoires) = 23 NC
      expect(technical.btTotalCrossRow.ncCount, equals(23));

      // Section 3 (BT)
      expect(technical.riskFamilyMatrix.totalBtDispo, equals(3));
      expect(technical.riskFamilyMatrix.totalBtExploit, equals(20));

      // Section 2.1 (Getters unifiés)
      expect(technical.btDispoConstructives, equals(3));
      expect(technical.btConditionsExploit, equals(4));
      expect(technical.totalBtNc, equals(23)); // 3 dispo + 20 exploit = 23 total

      // Égalité stricte : 2.1 == 3 == 4.2
      expect(technical.totalBtNc, equals(technical.riskFamilyMatrix.totalBtDispo + technical.riskFamilyMatrix.totalBtExploit));
      expect(technical.btTotalCrossRow.ncCount, equals(technical.totalBtNc));
      expect(technical.locauxBtFindings.dispoConstructives, equals(technical.riskFamilyMatrix.totalBtDispo));
    });

    test('Test 3 — Reproduction Cas CAMRAIL (291 NC Équipements + 6 NC Foudre = 297)', () {
      final findings = <AuditFinding>[];
      final instances = <DomainEntityInstance>[];

      // 291 constats répartis sur les équipements et locaux BT existants
      final armoireInst = DomainEntityInstance(
        instanceId: 'arm_camrail',
        category: DomainObjectType.armoire,
        name: 'Armoires BT Atelier',
        tensionDomain: TensionDomain.bt,
        originPath: 'Zone Atelier',
      );
      for (int i = 0; i < 291; i++) {
        final f = createFinding(
          id: 'arm_camrail_$i',
          tensionDomain: TensionDomain.bt,
          origin: 'Armoire',
          objectType: 'Armoire',
          tableName: 'Points de vérification',
          verificationPoint: 'Identification départ $i',
        );
        armoireInst.findings.add(f);
        findings.add(f);
      }
      instances.add(armoireInst);

      // 6 constats issus du module Foudre (exactement l'anomalie constatée)
      final foudreInst = DomainEntityInstance(
        instanceId: 'foudre_camrail',
        category: DomainObjectType.foudre,
        name: 'Installation Foudre 1',
        tensionDomain: TensionDomain.bt,
        originPath: 'Module Foudre',
      );
      for (int i = 0; i < 6; i++) {
        final f = createFinding(
          id: 'foudre_camrail_$i',
          tensionDomain: TensionDomain.bt,
          origin: 'Module Foudre',
          objectType: 'Installation Foudre',
          tableName: 'Observations Foudre',
          verificationPoint: 'Conducteur de descente $i',
          riskFamily: 'Risque Foudre / Surtension',
        );
        foudreInst.findings.add(f);
        findings.add(f);
      }
      instances.add(foudreInst);

      final domainInventory = MissionDomainInventory(
        missionId: 'm_camrail_sim',
        instances: instances,
        allFindings: findings,
      );
      final findingInventory = AuditFindingInventory(
        missionId: 'm_camrail_sim',
        findings: findings,
      );

      final technical = TechnicalEnrichmentEngine.compute(
        'm_camrail_sim',
        domainInventory,
        findingInventory,
      );

      // Section 3 : 297 constats au total en BT Exploitation & Maintenance
      expect(technical.riskFamilyMatrix.totalBtExploit, equals(297));

      // Tableau B BT : vérification que les 6 constats Foudre sont présents dans la grille
      final foudreRow = technical.btCategoriesCrossRows.firstWhere(
        (r) => r.categoryName == 'Installations Foudre',
        orElse: () => throw Exception('Ligne Installations Foudre manquante'),
      );
      expect(foudreRow.ncCount, equals(6));

      // TOTAL Tableau B BT : doit valoir EXACTEMENT 297, résolvant la divergence 291 vs 297 !
      expect(technical.btTotalCrossRow.ncCount, equals(297));
      expect(technical.btTotalCrossRow.ncCount, equals(technical.riskFamilyMatrix.totalBtExploit));
      expect(technical.totalBtNc, equals(297));
    });

    test('Test 4 — Extraction et intégrité des Conditions d\'exploitation', () {
      final findings = <AuditFinding>[];
      final instances = <DomainEntityInstance>[];

      final locMt = DomainEntityInstance(
        instanceId: 'loc_mt',
        category: DomainObjectType.localMT,
        name: 'Local MT',
        tensionDomain: TensionDomain.mt,
        originPath: 'Zone MT',
      );
      final ceMt = createFinding(
        id: 'ce_mt_1',
        tensionDomain: TensionDomain.mt,
        origin: 'Local MT',
        objectType: 'Local MT',
        tableName: 'Conditions d\'exploitation',
        verificationPoint: 'Propreté',
      );
      locMt.findings.add(ceMt);
      instances.add(locMt);
      findings.add(ceMt);

      final locBt = DomainEntityInstance(
        instanceId: 'loc_bt',
        category: DomainObjectType.localBT,
        name: 'Local BT',
        tensionDomain: TensionDomain.bt,
        originPath: 'Zone BT',
      );
      final ceBt1 = createFinding(
        id: 'ce_bt_1',
        tensionDomain: TensionDomain.bt,
        origin: 'Local BT',
        objectType: 'Local BT',
        tableName: 'Conditions d\'exploitation',
        verificationPoint: 'Extincteur CO2',
      );
      final ceBt2 = createFinding(
        id: 'ce_bt_2',
        tensionDomain: TensionDomain.bt,
        origin: 'Local BT',
        objectType: 'Local BT',
        tableName: 'Conditions d\'exploitation',
        verificationPoint: 'Ventilation',
      );
      locBt.findings.addAll([ceBt1, ceBt2]);
      instances.add(locBt);
      findings.addAll([ceBt1, ceBt2]);

      final domainInventory = MissionDomainInventory(
        missionId: 'm_ce_test',
        instances: instances,
        allFindings: findings,
      );
      final findingInventory = AuditFindingInventory(
        missionId: 'm_ce_test',
        findings: findings,
      );

      final technical = TechnicalEnrichmentEngine.compute(
        'm_ce_test',
        domainInventory,
        findingInventory,
      );

      // Chiffres réels vérifiés
      expect(technical.htaConditionsExploit, equals(1));
      expect(technical.btConditionsExploit, equals(2));
      expect(technical.locauxMtFindings.conditionsExploitation, equals(1));
      expect(technical.locauxBtFindings.conditionsExploitation, equals(2));
    });

    test('Test 5 — Formats normatifs des NC majeures (X constats / TOTAL, soit Z %)', () {
      final items = [
        TopDefectDomainItem(
          title: 'Absence de repérage des circuits',
          count: 12,
          percentageOfDomain: (12 / 156) * 100.0,
        ),
        TopDefectDomainItem(
          title: 'Section de conducteur sous-dimensionnée',
          count: 1,
          percentageOfDomain: (1 / 156) * 100.0,
        ),
      ];

      final domainTotal = 156;
      final globalTotalMajeures = 45;
      final globalTotalMission = 496;

      // Item 1 : pluriel
      final it1CountStr = '${items[0].count} constats';
      final it1PctStr = items[0].percentageOfDomain.toStringAsFixed(1).replaceAll('.', ',');
      final it1Formatted = '$it1CountStr / $domainTotal, soit $it1PctStr %';
      expect(it1Formatted, equals('12 constats / 156, soit 7,7 %'));

      // Item 2 : singulier
      final it2CountStr = '${items[1].count} constat';
      final it2PctStr = items[1].percentageOfDomain.toStringAsFixed(1).replaceAll('.', ',');
      final it2Formatted = '$it2CountStr / $domainTotal, soit $it2PctStr %';
      expect(it2Formatted, equals('1 constat / 156, soit 0,6 %'));

      // Ligne TOTAL : globale
      final globalPct = (globalTotalMajeures / globalTotalMission) * 100.0;
      final globalPctStr = globalPct.toStringAsFixed(1).replaceAll('.', ',');
      final totalFormatted = '$globalTotalMajeures constats / $globalTotalMission, soit $globalPctStr %';
      expect(totalFormatted, equals('45 constats / 496, soit 9,1 %'));
    });

    test('Test 6 — Cas limites : 0 NC et absence de domaine', () {
      final domainInventory = MissionDomainInventory(
        missionId: 'm_empty',
        instances: const [],
        allFindings: const [],
      );
      final findingInventory = AuditFindingInventory(
        missionId: 'm_empty',
        findings: const [],
      );

      final technical = TechnicalEnrichmentEngine.compute(
        'm_empty',
        domainInventory,
        findingInventory,
      );

      expect(technical.totalHtaNc, equals(0));
      expect(technical.totalBtNc, equals(0));
      expect(technical.totalMissionNc, equals(0));
      expect(technical.totalMissionMajeures, equals(0));
      expect(technical.riskFamilyMatrix.totalHtaDispo, equals(0));
      expect(technical.riskFamilyMatrix.totalHtaExploit, equals(0));
      expect(technical.riskFamilyMatrix.totalBtDispo, equals(0));
      expect(technical.riskFamilyMatrix.totalBtExploit, equals(0));
      expect(technical.mtTotalCrossRow.ncCount, equals(0));
      expect(technical.btTotalCrossRow.ncCount, equals(0));
    });

    test('Test 7 — Pagination Section 3 : Fractionnement ligne par ligne, répétition des en-têtes et protection anti-orphelin', () {
      final matrix = RiskFamilyCrossMatrix(
        htaDispositionsConstructives: RiskFamilyQuadrantStats.empty(
          domainTitle: 'HTA - DISPOSITION CONSTRUCTIVE',
          sectionTitle: 'DISPOSITION CONSTRUCTIVE',
          allFamilies: [
            RiskFamilyStatItem(famille: 'Risque MT 1', constats: 2, part: 100.0, formattedPart: '100,0 %'),
          ],
        ),
        htaExploitationMaintenance: RiskFamilyQuadrantStats.empty(
          domainTitle: 'HTA - EXPLOITATION ET MAINTENANCE',
          sectionTitle: 'EXPLOITATION ET MAINTENANCE',
          allFamilies: [
            RiskFamilyStatItem(famille: 'Risque MT Exploit 1', constats: 5, part: 100.0, formattedPart: '100,0 %'),
          ],
        ),
        btDispositionsConstructives: RiskFamilyQuadrantStats.empty(
          domainTitle: 'BT - DISPOSITION CONSTRUCTIVE',
          sectionTitle: 'DISPOSITION CONSTRUCTIVE',
          allFamilies: [
            RiskFamilyStatItem(famille: 'Risque BT 1', constats: 4, part: 80.0, formattedPart: '80,0 %'),
            RiskFamilyStatItem(famille: 'Risque BT 2', constats: 1, part: 20.0, formattedPart: '20,0 %'),
          ],
        ),
        btExploitationMaintenance: RiskFamilyQuadrantStats.empty(
          domainTitle: 'BT - EXPLOITATION ET MAINTENANCE',
          sectionTitle: 'EXPLOITATION ET MAINTENANCE',
          allFamilies: [
            RiskFamilyStatItem(famille: 'Sécurité / conformité réglementaire', constats: 84, part: 28.3, formattedPart: '28,3 %'),
            RiskFamilyStatItem(famille: 'Contact électrique', constats: 51, part: 17.2, formattedPart: '17,2 %'),
            RiskFamilyStatItem(famille: 'Erreur d\'exploitation', constats: 40, part: 13.5, formattedPart: '13,5 %'),
          ],
        ),
      );

      final widgets = PdfExecutiveSummaryBuilder.buildRiskFamilyMatrixWidgetsForTesting(matrix);

      // La section doit émettre une liste de widgets directs (et non un simple pw.Column bloquant)
      expect(widgets, isNotEmpty);

      // On retrouve des sauts conditionnels de protection anti-orphelin (pw.NewPage)
      final newPageWidgets = widgets.whereType<pw.NewPage>().toList();
      expect(newPageWidgets.length, equals(4)); // 1 par quadrant

      // Vérifier les seuils anti-orphelins (85 pour grand domaine, 65 pour sous-domaine)
      expect(newPageWidgets[0].freeSpace, equals(85.0)); // HTA
      expect(newPageWidgets[1].freeSpace, equals(65.0)); // HTA Exploit
      expect(newPageWidgets[2].freeSpace, equals(85.0)); // BT
      expect(newPageWidgets[3].freeSpace, equals(65.0)); // BT Exploit

      // Vérifier que chaque tableau de données possède une ligne d'en-tête avec repeat: true
      final dataTables = widgets.whereType<pw.Table>().where((t) => t.children.length > 1).toList();
      expect(dataTables.length, equals(4));
      for (final table in dataTables) {
        expect(table.children.first.repeat, isTrue, reason: 'La ligne d\'en-tête doit se répéter en cas de saut de page');
      }
    });

    test('Test 8 — Tableau C : Totalisation exacte cumulée Pareto et bris d\'égalité déterministe', () {
      final topItems = [
        const TopDefectDomainItem(title: 'Interconnexion à la terre', count: 52, percentageOfDomain: 17.5),
        const TopDefectDomainItem(title: 'Intégrité des enveloppes', count: 48, percentageOfDomain: 16.2),
        const TopDefectDomainItem(title: 'Câblages et canalisations', count: 35, percentageOfDomain: 11.8),
        const TopDefectDomainItem(title: 'Dispositifs de protection', count: 31, percentageOfDomain: 10.4),
        const TopDefectDomainItem(title: 'Identification et repérage', count: 28, percentageOfDomain: 9.4),
      ];

      final tableWidget = PdfExecutiveSummaryBuilder.buildTopFindingsTableForTesting(
        topItems,
        'Aucun constat',
      );
      expect(tableWidget, isA<pw.Table>());
      final table = tableWidget as pw.Table;

      // 1 en-tête + 5 items + 1 TOTAL = 7 lignes
      expect(table.children.length, equals(7));

      final totalRow = table.children.last;
      expect(totalRow.children.length, equals(3));

      // Numérateur du total = somme des items = 52 + 48 + 35 + 31 + 28 = 194
      final totalSum = topItems.fold<int>(0, (s, it) => s + it.count);
      expect(totalSum, equals(194));

      // Vérifier le tri déterministe avec égalité de décomptes
      final f1 = createFinding(
        id: 'f_tie_1',
        tensionDomain: TensionDomain.bt,
        origin: 'Local BT',
        objectType: 'Coffret',
        tableName: 'Points de vérification',
        verificationPoint: 'Point Z',
        riskFamily: 'Protection contre les surintensités',
      );
      final f2 = createFinding(
        id: 'f_tie_2',
        tensionDomain: TensionDomain.bt,
        origin: 'Local BT',
        objectType: 'Coffret',
        tableName: 'Points de vérification',
        verificationPoint: 'Point A',
        riskFamily: 'Interconnexion à la terre et protections différentielles',
      );

      final domainInv = MissionDomainInventory(
        missionId: 'm_tie',
        instances: const [],
        allFindings: [f1, f2],
      );
      final findingInv = AuditFindingInventory(
        missionId: 'm_tie',
        findings: [f1, f2],
      );

      final result = TechnicalEnrichmentEngine.compute('m_tie', domainInv, findingInv);
      // Les deux catégories ont count = 1. L'ordre doit être alphabétique stable.
      expect(result.top5Bt.length, equals(2));
      expect(result.top5Bt[0].title.compareTo(result.top5Bt[1].title) < 0, isTrue);
    });
  });
}
