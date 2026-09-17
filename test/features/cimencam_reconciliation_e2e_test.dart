import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';

void main() {
  group('Forensic Reconciliation & Local/Equipment Type Authority', () {
    test('Equipment type authority: Coffret with repère containing "armoire" remains Coffret if type == coffret', () {
      final coffret7 = CoffretArmoire(
        qrCode: 'QR_007',
        nom: 'Coffret N°7',
        repere: 'local électrique armoire des groupes électrogènes',
        type: 'coffret',
      );

      final armoire1 = CoffretArmoire(
        qrCode: 'QR_001',
        nom: 'Armoire Principale',
        repere: 'Armoire T1',
        type: 'armoire',
      );

      final inverseur1 = CoffretArmoire(
        qrCode: 'QR_INV',
        nom: 'Inverseur Normal/Secours',
        repere: 'INV-01',
        type: 'inverseur',
      );

      final classifiedC7 = EquipmentClassifier.classify(coffret7);
      final classifiedA1 = EquipmentClassifier.classify(armoire1);
      final classifiedInv1 = EquipmentClassifier.classify(inverseur1);

      expect(classifiedC7, equals(DomainObjectType.coffret));
      expect(classifiedA1, equals(DomainObjectType.armoire));
      expect(classifiedInv1, equals(DomainObjectType.inverseur));
    });

    test('Local type authority in inventory: Local named with "groupe" but type LOCAL_ELECTRIQUE remains Local BT', () {
      final localGE = DomainEntityInstance(
        instanceId: 'lge_1',
        category: DomainObjectType.localGE,
        name: 'Local groupe électrogène 66 KVA',
        tensionDomain: TensionDomain.bt,
        originPath: 'Zone BT / Local GE',
      );

      final localBTWithGroupeInName = DomainEntityInstance(
        instanceId: 'lbt_1',
        category: DomainObjectType.localBT,
        name: 'local électrique armoire des groupes électrogènes',
        tensionDomain: TensionDomain.bt,
        originPath: 'Zone BT / Local BT',
      );

      final localBTRegular = DomainEntityInstance(
        instanceId: 'lbt_2',
        category: DomainObjectType.localBT,
        name: 'Local Basse Tension Usine',
        tensionDomain: TensionDomain.bt,
        originPath: 'Zone BT / Local BT',
      );

      final domainInventory = MissionDomainInventory(
        missionId: 'test_mission',
        instances: [localGE, localBTWithGroupeInName, localBTRegular],
        allFindings: [],
      );

      // Local GE count must be strictly 1
      final geLocaux = domainInventory.getInstancesByCategory(DomainObjectType.localGE);
      expect(geLocaux.length, equals(1));
      expect(geLocaux.first.name, equals('Local groupe électrogène 66 KVA'));

      // Local BT count must be strictly 2
      final btLocaux = domainInventory.getInstancesByCategory(DomainObjectType.localBT);
      expect(btLocaux.length, equals(2));
      expect(btLocaux.map((l) => l.name), contains('local électrique armoire des groupes électrogènes'));
      expect(btLocaux.map((l) => l.name), contains('Local Basse Tension Usine'));
    });

    test('TechnicalEnrichmentEngine calculates correct equipment totals and cross rows matching 496 findings', () {
      // 156 MT findings distributed:
      // 127 local MT, 23 cellules MT, 4 transformateurs MT, 2 armoire MT
      final mtLocFindings = List.generate(127, (i) => AuditFinding(
        id: 'mt_loc_$i',
        missionId: 'cimencam',
        tensionDomain: TensionDomain.mt,
        origin: 'Poste MT',
        objectType: 'Local MT',
        objectName: 'Poste MT 1',
        tableName: 'Table MT',
        verificationPoint: 'Point $i',
        observationText: 'Defaut $i',
        conformity: 'non',
        criticality: 'Majeure',
      ));

      final mtCellFindings = List.generate(23, (i) => AuditFinding(
        id: 'mt_cel_$i',
        missionId: 'cimencam',
        tensionDomain: TensionDomain.mt,
        origin: 'Poste MT',
        objectType: 'Cellule MT',
        objectName: 'Cellule MT 1',
        tableName: 'Table MT',
        verificationPoint: 'Point $i',
        observationText: 'Defaut $i',
        conformity: 'non',
        criticality: 'Majeure',
      ));

      final mtTransFindings = List.generate(4, (i) => AuditFinding(
        id: 'mt_tr_$i',
        missionId: 'cimencam',
        tensionDomain: TensionDomain.mt,
        origin: 'Poste MT',
        objectType: 'Transformateur',
        objectName: 'Transfo MT 1',
        tableName: 'Table MT',
        verificationPoint: 'Point $i',
        observationText: 'Defaut $i',
        conformity: 'non',
        criticality: 'Majeure',
      ));

      final mtArmFindings = List.generate(2, (i) => AuditFinding(
        id: 'mt_arm_$i',
        missionId: 'cimencam',
        tensionDomain: TensionDomain.mt,
        origin: 'Poste MT',
        objectType: 'Armoire',
        objectName: 'Armoire MT 1',
        tableName: 'Table MT',
        verificationPoint: 'Point $i',
        observationText: 'Defaut $i',
        conformity: 'non',
        criticality: 'Majeure',
      ));

      // 340 BT findings distributed:
      // 30 local GE, 52 local BT, 5 inverseur, 174 armoire BT, 79 coffret BT
      final btGeFindings = List.generate(30, (i) => AuditFinding(
        id: 'bt_ge_$i',
        missionId: 'cimencam',
        tensionDomain: TensionDomain.bt,
        origin: 'Zone BT',
        objectType: 'Groupe Électrogène',
        objectName: 'Local GE',
        tableName: 'Table BT',
        verificationPoint: 'Point $i',
        observationText: 'Defaut $i',
        conformity: 'non',
        criticality: 'Majeure',
      ));

      final btLocFindings = List.generate(52, (i) => AuditFinding(
        id: 'bt_loc_$i',
        missionId: 'cimencam',
        tensionDomain: TensionDomain.bt,
        origin: 'Zone BT',
        objectType: 'Local BT',
        objectName: 'Local BT',
        tableName: 'Table BT',
        verificationPoint: 'Point $i',
        observationText: 'Defaut $i',
        conformity: 'non',
        criticality: 'Majeure',
      ));

      final btInvFindings = List.generate(5, (i) => AuditFinding(
        id: 'bt_inv_$i',
        missionId: 'cimencam',
        tensionDomain: TensionDomain.bt,
        origin: 'Zone BT',
        objectType: 'Inverseur',
        objectName: 'Inverseur',
        tableName: 'Table BT',
        verificationPoint: 'Point $i',
        observationText: 'Defaut $i',
        conformity: 'non',
        criticality: 'Majeure',
      ));

      final btArmFindings = List.generate(174, (i) => AuditFinding(
        id: 'bt_arm_$i',
        missionId: 'cimencam',
        tensionDomain: TensionDomain.bt,
        origin: 'Zone BT',
        objectType: 'Armoire',
        objectName: 'Armoire BT',
        tableName: 'Table BT',
        verificationPoint: 'Point $i',
        observationText: 'Defaut $i',
        conformity: 'non',
        criticality: 'Majeure',
      ));

      final btCofFindings = List.generate(79, (i) => AuditFinding(
        id: 'bt_cof_$i',
        missionId: 'cimencam',
        tensionDomain: TensionDomain.bt,
        origin: 'Zone BT',
        objectType: 'Coffret',
        objectName: 'Coffret BT',
        tableName: 'Table BT',
        verificationPoint: 'Point $i',
        observationText: 'Defaut $i',
        conformity: 'non',
        criticality: 'Majeure',
      ));

      final allFindings = [
        ...mtLocFindings,
        ...mtCellFindings,
        ...mtTransFindings,
        ...mtArmFindings,
        ...btGeFindings,
        ...btLocFindings,
        ...btInvFindings,
        ...btArmFindings,
        ...btCofFindings,
      ];
      expect(allFindings.length, equals(496));

      // Domain inventory instances
      final instances = <DomainEntityInstance>[
        // 16 MT Locaux (local 0 holds the 127 MT local findings)
        ...List.generate(16, (i) => DomainEntityInstance(
          instanceId: 'lmt_$i',
          name: 'Poste MT $i',
          category: DomainObjectType.localMT,
          tensionDomain: TensionDomain.mt,
          originPath: 'MT',
          findings: i == 0 ? mtLocFindings : [],
        )),
        // 2 GE Locaux (local 0 holds the 30 GE findings)
        ...List.generate(2, (i) => DomainEntityInstance(
          instanceId: 'lge_$i',
          name: 'Local GE $i',
          category: DomainObjectType.localGE,
          tensionDomain: TensionDomain.bt,
          originPath: 'BT',
          findings: i == 0 ? btGeFindings : [],
        )),
        // 7 BT Locaux (local 0 holds the 52 BT local findings)
        ...List.generate(7, (i) => DomainEntityInstance(
          instanceId: 'lbt_$i',
          name: 'Local BT $i',
          category: DomainObjectType.localBT,
          tensionDomain: TensionDomain.bt,
          originPath: 'BT',
          findings: i == 0 ? btLocFindings : [],
        )),
        // 29 Cellules (cellule 0 holds 23 cell findings)
        ...List.generate(29, (i) => DomainEntityInstance(
          instanceId: 'cel_$i',
          name: 'Cellule $i',
          category: DomainObjectType.celluleMT,
          tensionDomain: TensionDomain.mt,
          originPath: 'MT',
          findings: i == 0 ? mtCellFindings : [],
        )),
        // 9 Transfos (transfo 0 holds 4 transfo findings)
        ...List.generate(9, (i) => DomainEntityInstance(
          instanceId: 'tr_$i',
          name: 'Transfo $i',
          category: DomainObjectType.transformateurMTBT,
          tensionDomain: TensionDomain.mt,
          originPath: 'MT',
          findings: i == 0 ? mtTransFindings : [],
        )),
        // 74 Armoires (armoire 0 is MT with 2 findings, armoire 1 is BT with 174 findings)
        ...List.generate(74, (i) => DomainEntityInstance(
          instanceId: 'arm_$i',
          name: 'Armoire $i',
          category: DomainObjectType.armoire,
          tensionDomain: i == 0 ? TensionDomain.mt : TensionDomain.bt,
          originPath: i == 0 ? 'MT' : 'BT',
          findings: i == 0 ? mtArmFindings : (i == 1 ? btArmFindings : []),
        )),
        // 19 Coffrets (coffret 0 holds 79 findings)
        ...List.generate(19, (i) => DomainEntityInstance(
          instanceId: 'cof_$i',
          name: 'Coffret $i',
          category: DomainObjectType.coffret,
          tensionDomain: TensionDomain.bt,
          originPath: 'BT',
          findings: i == 0 ? btCofFindings : [],
        )),
        // 1 Inverseur (BT with 5 findings)
        DomainEntityInstance(
          instanceId: 'inv_1',
          name: 'Inverseur 1',
          category: DomainObjectType.inverseur,
          tensionDomain: TensionDomain.bt,
          originPath: 'BT',
          findings: btInvFindings,
        ),
      ];

      final domainInventory = MissionDomainInventory(
        missionId: 'cimencam',
        allFindings: allFindings,
        instances: instances,
      );

      final findingInventory = AuditFindingInventory(
        missionId: 'cimencam',
        findings: allFindings,
      );

      final result = TechnicalEnrichmentEngine.compute('cimencam', domainInventory, findingInventory);

      // Verify equipment counts
      expect(result.totalCellules, equals(29));
      expect(result.totalTransformateurs, equals(9));
      expect(result.totalArmoires, equals(74));
      expect(result.totalCoffrets, equals(19));
      expect(result.totalInverseurs, equals(1));
      expect(result.totalEquipementsMT, equals(29 + 9)); // 38 MT specific
      expect(result.totalEquipementsBT, equals(74 + 19 + 1)); // 94 BT specific
      expect(result.totalEquipementsElectriques, equals(38 + 94)); // 132

      // Verify cross rows
      final mtRowsNcSum = result.mtCategoriesCrossRows.fold<int>(0, (s, r) => s + r.ncCount);
      final btRowsNcSum = result.btCategoriesCrossRows.fold<int>(0, (s, r) => s + r.ncCount);

      expect(mtRowsNcSum, equals(156));
      expect(btRowsNcSum, equals(340));
      expect(mtRowsNcSum + btRowsNcSum, equals(496));
    });
  });
}
