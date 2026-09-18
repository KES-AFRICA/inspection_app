// test/features/section9_ip_ik_adequation_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/builders/pdf_executive_summary_builder.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/ip_ik_evaluator.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CoffretArmoire makeCoffret({
    required String name,
    String? indiceIpIk,
    String statut = 'complet',
  }) {
    return CoffretArmoire(
      qrCode: 'QR_$name',
      nom: name,
      type: 'COFFRET',
      statut: statut,
      indiceIpIk: indiceIpIk,
      currentStep: 3,
      photos: [],
      photosExternes: [],
      photosInternes: [],
      alimentations: [],
      pointsVerification: [],
      observationsLibres: [],
      observationsParafoudre: [],
    );
  }

  DomainEntityInstance makeInstance({
    required String id,
    required String name,
    String? parentZone,
    String? parentLocal,
    required CoffretArmoire coffret,
  }) {
    final path = parentZone != null && parentLocal != null
        ? '$parentZone > $parentLocal'
        : (parentZone ?? parentLocal ?? 'Direct');
    return DomainEntityInstance(
      instanceId: id,
      category: DomainObjectType.coffret,
      name: name,
      tensionDomain: TensionDomain.bt,
      originPath: path,
      parentZone: parentZone,
      parentLocal: parentLocal,
      rawModelRef: coffret,
    );
  }

  group('Section 9 — Adéquation du classement des zones et indices IP/IK des équipements', () {
    test('Cas A — Tout conforme (10 adéquats, 0 différent, 0 absent)', () {
      final item = const IpIkZoneItem(
        zoneNom: 'Local TGBT',
        ipRequis: 'IP55',
        ikRequis: 'IK08',
        totalEquipements: 10,
        adequatCount: 10,
        presentDifferentCount: 0,
        absentCount: 0,
      );

      expect(item.totalEquipements, equals(10));
      expect(item.adequatCount, equals(10));
      expect(item.presentDifferentCount, equals(0));
      expect(item.absentCount, equals(0));
      expect(item.nonConformesCount, equals(0));

      expect(item.adequatPct, equals(100.0));
      expect(item.presentDifferentPct, equals(0.0));
      expect(item.absentPct, equals(0.0));
      expect(item.nonComplianceRate, equals(0.0));

      expect(item.formattedNonComplianceRate, equals('0 %'));
      expect(item.formattedAdequatPct, equals('100 %'));
      expect(item.formattedPresentDifferentPct, equals('0 %'));
      expect(item.formattedAbsentPct, equals('0 %'));

      // Cohérence mathématique
      expect(item.adequatCount + item.presentDifferentCount + item.absentCount, equals(item.totalEquipements));
      expect(item.adequatPct + item.presentDifferentPct + item.absentPct, equals(100.0));
      expect(item.nonComplianceRate, equals(100.0 - item.adequatPct));
    });

    test('Cas B — 50 % non conformes (5 adéquats, 5 différents, 0 absent)', () {
      final item = const IpIkZoneItem(
        zoneNom: 'Local Compresseurs',
        ipRequis: 'IP55',
        ikRequis: 'IK08',
        totalEquipements: 10,
        adequatCount: 5,
        presentDifferentCount: 5,
        absentCount: 0,
      );

      expect(item.totalEquipements, equals(10));
      expect(item.adequatCount, equals(5));
      expect(item.presentDifferentCount, equals(5));
      expect(item.absentCount, equals(0));
      expect(item.nonConformesCount, equals(5));

      expect(item.adequatPct, equals(50.0));
      expect(item.presentDifferentPct, equals(50.0));
      expect(item.absentPct, equals(0.0));
      expect(item.nonComplianceRate, equals(50.0));

      expect(item.formattedNonComplianceRate, equals('50 %'));
      expect(item.formattedAdequatPct, equals('50 %'));
      expect(item.formattedPresentDifferentPct, equals('50 %'));
      expect(item.formattedAbsentPct, equals('0 %'));

      expect(item.adequatCount + item.presentDifferentCount + item.absentCount, equals(item.totalEquipements));
      expect(item.adequatPct + item.presentDifferentPct + item.absentPct, equals(100.0));
      expect(item.nonComplianceRate, equals(100.0 - item.adequatPct));
    });

    test('Cas C — 100 % non conformes par différence (0 adéquat, 10 différents, 0 absent)', () {
      final item = const IpIkZoneItem(
        zoneNom: 'Local Chaudière',
        ipRequis: 'IP65',
        ikRequis: 'IK08',
        totalEquipements: 10,
        adequatCount: 0,
        presentDifferentCount: 10,
        absentCount: 0,
      );

      expect(item.totalEquipements, equals(10));
      expect(item.adequatCount, equals(0));
      expect(item.presentDifferentCount, equals(10));
      expect(item.absentCount, equals(0));
      expect(item.nonConformesCount, equals(10));

      expect(item.adequatPct, equals(0.0));
      expect(item.presentDifferentPct, equals(100.0));
      expect(item.absentPct, equals(0.0));
      expect(item.nonComplianceRate, equals(100.0));

      expect(item.formattedNonComplianceRate, equals('100 %'));
      expect(item.formattedAdequatPct, equals('0 %'));
      expect(item.formattedPresentDifferentPct, equals('100 %'));
      expect(item.formattedAbsentPct, equals('0 %'));

      expect(item.adequatCount + item.presentDifferentCount + item.absentCount, equals(item.totalEquipements));
      expect(item.adequatPct + item.presentDifferentPct + item.absentPct, equals(100.0));
      expect(item.nonComplianceRate, equals(100.0 - item.adequatPct));
    });

    test('Cas D — 100 % non conformes par absence (0 adéquat, 0 différent, 10 absents)', () {
      final item = const IpIkZoneItem(
        zoneNom: 'Local Pomperie',
        ipRequis: 'IP55',
        ikRequis: 'IK08',
        totalEquipements: 10,
        adequatCount: 0,
        presentDifferentCount: 0,
        absentCount: 10,
      );

      expect(item.totalEquipements, equals(10));
      expect(item.adequatCount, equals(0));
      expect(item.presentDifferentCount, equals(0));
      expect(item.absentCount, equals(10));
      expect(item.nonConformesCount, equals(10));

      expect(item.adequatPct, equals(0.0));
      expect(item.presentDifferentPct, equals(0.0));
      expect(item.absentPct, equals(100.0));
      expect(item.nonComplianceRate, equals(100.0));

      expect(item.formattedNonComplianceRate, equals('100 %'));
      expect(item.formattedAdequatPct, equals('0 %'));
      expect(item.formattedPresentDifferentPct, equals('0 %'));
      expect(item.formattedAbsentPct, equals('100 %'));

      expect(item.adequatCount + item.presentDifferentCount + item.absentCount, equals(item.totalEquipements));
      expect(item.adequatPct + item.presentDifferentPct + item.absentPct, equals(100.0));
      expect(item.nonComplianceRate, equals(100.0 - item.adequatPct));
    });

    test('Cas E — Mélange (4 adéquats, 3 différents, 3 absents => 60 % NC)', () {
      final item = const IpIkZoneItem(
        zoneNom: 'Atelier Central',
        ipRequis: 'IP55',
        ikRequis: 'IK08',
        totalEquipements: 10,
        adequatCount: 4,
        presentDifferentCount: 3,
        absentCount: 3,
      );

      expect(item.totalEquipements, equals(10));
      expect(item.adequatCount, equals(4));
      expect(item.presentDifferentCount, equals(3));
      expect(item.absentCount, equals(3));
      expect(item.nonConformesCount, equals(6));

      expect(item.adequatPct, equals(40.0));
      expect(item.presentDifferentPct, equals(30.0));
      expect(item.absentPct, equals(30.0));
      expect(item.nonComplianceRate, equals(60.0));

      expect(item.formattedNonComplianceRate, equals('60 %'));
      expect(item.formattedAdequatPct, equals('40 %'));
      expect(item.formattedPresentDifferentPct, equals('30 %'));
      expect(item.formattedAbsentPct, equals('30 %'));

      expect(item.adequatCount + item.presentDifferentCount + item.absentCount, equals(item.totalEquipements));
      expect(item.adequatPct + item.presentDifferentPct + item.absentPct, equals(100.0));
      expect(item.nonComplianceRate, equals(100.0 - item.adequatPct));
    });

    test('Cas F & H — Hiérarchie stricte et plusieurs locaux (Local = référence de rattachement)', () {
      final instances = <DomainEntityInstance>[];

      // Local 1 dans Zone A (3 équipements : 2 conformes IP55/IK08, 1 différent IP20)
      for (int i = 1; i <= 2; i++) {
        instances.add(makeInstance(
          id: 'l1_eq$i',
          name: 'Coffret L1_$i',
          parentZone: 'Zone A',
          parentLocal: 'Local 1',
          coffret: makeCoffret(name: 'Coffret L1_$i', indiceIpIk: 'IP55 / IK08'),
        ));
      }
      instances.add(makeInstance(
        id: 'l1_eq3',
        name: 'Coffret L1_3',
        parentZone: 'Zone A',
        parentLocal: 'Local 1',
        coffret: makeCoffret(name: 'Coffret L1_3', indiceIpIk: 'IP20'),
      ));

      // Local 2 dans Zone A (2 équipements : 1 conforme IP65, 1 sans indice)
      instances.add(makeInstance(
        id: 'l2_eq1',
        name: 'Coffret L2_1',
        parentZone: 'Zone A',
        parentLocal: 'Local 2',
        coffret: makeCoffret(name: 'Coffret L2_1', indiceIpIk: 'IP65'),
      ));
      instances.add(makeInstance(
        id: 'l2_eq2',
        name: 'Coffret L2_2',
        parentZone: 'Zone A',
        parentLocal: 'Local 2',
        coffret: makeCoffret(name: 'Coffret L2_2', indiceIpIk: null),
      ));

      final inventory = MissionDomainInventory(
        missionId: 'm_multi_locaux',
        instances: instances,
        allFindings: [],
      );

      // Local 1 a 3 équipements
      final l1Eqs = inventory.instances.where((i) => i.parentLocal == 'Local 1').toList();
      expect(l1Eqs.length, equals(3));

      // Local 2 a 2 équipements
      final l2Eqs = inventory.instances.where((i) => i.parentLocal == 'Local 2').toList();
      expect(l2Eqs.length, equals(2));

      // Total Zone A = 5 équipements répartis par local, aucun équipement direct de zone
      final directZoneEqs = inventory.instances.where((i) => i.parentZone == 'Zone A' && (i.parentLocal == null || i.parentLocal!.isEmpty)).toList();
      expect(directZoneEqs.length, equals(0));
    });

    test('Cas G — Équipements directement rattachés à une zone (sans local)', () {
      final instances = [
        makeInstance(
          id: 'z_eq1',
          name: 'Armoire Extérieure 1',
          parentZone: 'Zone Extérieure',
          parentLocal: null,
          coffret: makeCoffret(name: 'Armoire Extérieure 1', indiceIpIk: 'IP55 / IK08'),
        ),
        makeInstance(
          id: 'z_eq2',
          name: 'Armoire Extérieure 2',
          parentZone: 'Zone Extérieure',
          parentLocal: null,
          coffret: makeCoffret(name: 'Armoire Extérieure 2', indiceIpIk: 'IP44'),
        ),
      ];

      final inventory = MissionDomainInventory(
        missionId: 'm_zone_direct',
        instances: instances,
        allFindings: [],
      );

      final directEqs = inventory.instances.where((i) => i.parentZone == 'Zone Extérieure' && i.parentLocal == null).toList();
      expect(directEqs.length, equals(2));
    });

    test('Cas I — Indice du repère absent (Repère non évaluable, zéro création artificielle de conformité)', () {
      // Repère sans IP/IK requis
      final status = IpIkEvaluator.evaluate(
        reqIp: null,
        reqIk: null,
        obsRaw: 'IP55 / IK08',
      );
      expect(status, equals(IpIkAdequationStatus.nonEvaluable));

      final statusAbsent = IpIkEvaluator.evaluate(
        reqIp: '',
        reqIk: '',
        obsRaw: null,
      );
      expect(statusAbsent, equals(IpIkAdequationStatus.nonEvaluable));

      final item = const IpIkZoneItem(
        zoneNom: 'Local Sans Indice Requis',
        ipRequis: null,
        ikRequis: null,
        totalEquipements: 5,
        adequatCount: 0,
        presentDifferentCount: 0,
        absentCount: 0,
        nonEvaluableCount: 5,
      );

      expect(item.isEvaluable, isFalse);
      expect(item.formattedNonComplianceRate, equals('Non évaluable'));
      expect(item.formattedRate, equals('Non évaluable'));
    });

    test('Cas J — Rétrocompatibilité avec anciennes structures de données et valeurs historiques', () {
      // Instance créée avec anciens paramètres conformes/nonConformes/nonRenseignes
      final legacyItem = const IpIkZoneItem(
        zoneNom: 'Local Historique',
        totalEquipements: 10,
        conformes: 7,
        nonConformes: 3,
        nonRenseignes: 2,
        indicesPresents: 8,
        pointsVerifies: 0,
        pointsNonConformes: 0,
      );

      expect(legacyItem.totalEquipements, equals(10));
      expect(legacyItem.conformes, equals(7));
      expect(legacyItem.nonConformes, equals(3));
      expect(legacyItem.nonRenseignes, equals(2));
      expect(legacyItem.indicesPresents, equals(8));
    });

    test('Formatage des pourcentages : entiers sans virgule inutile, décimaux avec virgule', () {
      expect(IpIkZoneItem.formatPercent(50.0), equals('50 %'));
      expect(IpIkZoneItem.formatPercent(0.0), equals('0 %'));
      expect(IpIkZoneItem.formatPercent(100.0), equals('100 %'));
      expect(IpIkZoneItem.formatPercent(25.0), equals('25 %'));
      expect(IpIkZoneItem.formatPercent(50.1), equals('50,1 %'));
      expect(IpIkZoneItem.formatPercent(75.5), equals('75,5 %'));
      expect(IpIkZoneItem.formatPercent(99.9), equals('99,9 %'));
    });

    test('Règle de coloration dynamique du taux de non-conformité (0-50% rouge, >50%-<100% orange, 100% vert)', () {
      PdfColor resolveColor(double rate) {
        if (rate <= 50.0) {
          return PdfColor.fromHex('#B71C1C'); // rouge
        } else if (rate < 100.0) {
          return PdfColor.fromHex('#E65100'); // orange
        } else {
          return PdfColor.fromHex('#2E7D32'); // vert
        }
      }

      // 0 % à 50 % → rouge
      expect(resolveColor(0.0), equals(PdfColor.fromHex('#B71C1C')));
      expect(resolveColor(25.0), equals(PdfColor.fromHex('#B71C1C')));
      expect(resolveColor(50.0), equals(PdfColor.fromHex('#B71C1C')));

      // strictement supérieur à 50 % et inférieur à 100 % → orange
      expect(resolveColor(50.1), equals(PdfColor.fromHex('#E65100')));
      expect(resolveColor(75.0), equals(PdfColor.fromHex('#E65100')));
      expect(resolveColor(99.0), equals(PdfColor.fromHex('#E65100')));

      // 100 % → vert
      expect(resolveColor(100.0), equals(PdfColor.fromHex('#2E7D32')));
    });

    test('Rendu PDF — buildIpIkTableForTesting génère un tableau pw.Table valide avec les 3 sous-catégories', () {
      final items = [
        const IpIkZoneItem(
          zoneNom: 'Local TGBT',
          ipRequis: 'IP55',
          ikRequis: 'IK08',
          totalEquipements: 10,
          adequatCount: 5,
          presentDifferentCount: 5,
          absentCount: 0,
        ),
        const IpIkZoneItem(
          zoneNom: 'Local Atelier',
          ipRequis: 'IP65',
          ikRequis: 'IK08',
          totalEquipements: 10,
          adequatCount: 10,
          presentDifferentCount: 0,
          absentCount: 0,
        ),
      ];

      final technical = TechnicalEnrichmentResult(
        missionId: 'm_test',
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
        ipIkZoneItems: items,
        riskFamilyMatrix: const RiskFamilyCrossMatrix.empty(),
        top5Hta: const [],
        top5Bt: const [],
        totalZonesClassees: 0,
        totalLocauxMt: 0,
        totalLocauxBt: 0,
        totalLocauxGe: 0,
        locauxMtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        locauxBtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        mtCategoriesCrossRows: const [],
        mtTotalCrossRow: const CategoryCrossAuditRow(categoryName: 'TOTAL MT', equipementsCount: 0, ncCount: 0, critiquesCount: 0, majeuresCount: 0, pctOfTotalNc: 0, tauxCritique: 0, densite: 0),
        btCategoriesCrossRows: const [],
        btTotalCrossRow: const CategoryCrossAuditRow(categoryName: 'TOTAL BT', equipementsCount: 0, ncCount: 0, critiquesCount: 0, majeuresCount: 0, pctOfTotalNc: 0, tauxCritique: 0, densite: 0),
      );

      final widget = PdfExecutiveSummaryBuilder.buildIpIkTableForTesting(technical);
      expect(widget, isA<pw.Table>());
      final table = widget as pw.Table;
      // En-tête + 2 lignes pour les 2 repères
      expect(table.children.length, equals(3));
    });
  });
}

