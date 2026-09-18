import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';

void main() {
  group('1. Hiérarchie & Rattachement Section 9 (Zone -> Local -> Équipement)', () {
    test('Cas 1 : Zone A -> Local A1 -> 2 équipements (Local A1 = 2 équipements)', () {
      final coffret1 = CoffretArmoire(
        qrCode: 'QR1',
        nom: 'Coffret 1',
        type: 'COFFRET',
        statut: 'complet',
        currentStep: 3,
        photos: [],
        photosExternes: [],
        photosInternes: [],
        alimentations: [],
        pointsVerification: [],
        observationsLibres: [],
        observationsParafoudre: [],
      );
      final coffret2 = CoffretArmoire(
        qrCode: 'QR2',
        nom: 'Coffret 2',
        type: 'COFFRET',
        statut: 'complet',
        currentStep: 3,
        photos: [],
        photosExternes: [],
        photosInternes: [],
        alimentations: [],
        pointsVerification: [],
        observationsLibres: [],
        observationsParafoudre: [],
      );

      final instances = [
        DomainEntityInstance(
          instanceId: 'inst_c1',
          category: DomainObjectType.coffret,
          name: 'Coffret 1',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone A > Local A1',
          parentZone: 'Zone A',
          parentLocal: 'Local A1',
          rawModelRef: coffret1,
        ),
        DomainEntityInstance(
          instanceId: 'inst_c2',
          category: DomainObjectType.coffret,
          name: 'Coffret 2',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone A > Local A1',
          parentZone: 'Zone A',
          parentLocal: 'Local A1',
          rawModelRef: coffret2,
        ),
      ];

      final inventory = MissionDomainInventory(
        missionId: 'm1',
        instances: instances,
        allFindings: [],
      );

      final localA1Equipments = inventory.instances
          .where((i) => i.parentLocal == 'Local A1' && i.category == DomainObjectType.coffret)
          .toList();
      expect(localA1Equipments.length, equals(2));

      final zoneAEquipments = inventory.instances
          .where((i) => i.parentZone == 'Zone A' && i.category == DomainObjectType.coffret)
          .toList();
      expect(zoneAEquipments.length, equals(2));
    });

    test('Cas 2 : Zone A -> Local A1 (2 éq) + Local A2 (3 éq) => Zone A total = 5 équipements', () {
      CoffretArmoire makeCoffret(String name) => CoffretArmoire(
            qrCode: 'QR_$name',
            nom: name,
            type: 'COFFRET',
            statut: 'complet',
            currentStep: 3,
            photos: [],
            photosExternes: [],
            photosInternes: [],
            alimentations: [],
            pointsVerification: [],
            observationsLibres: [],
            observationsParafoudre: [],
          );

      final instances = [
        // Local A1 (2 éq)
        DomainEntityInstance(
          instanceId: 'c1',
          category: DomainObjectType.coffret,
          name: 'C1',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone A > Local A1',
          parentZone: 'Zone A',
          parentLocal: 'Local A1',
          rawModelRef: makeCoffret('C1'),
        ),
        DomainEntityInstance(
          instanceId: 'c2',
          category: DomainObjectType.coffret,
          name: 'C2',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone A > Local A1',
          parentZone: 'Zone A',
          parentLocal: 'Local A1',
          rawModelRef: makeCoffret('C2'),
        ),
        // Local A2 (3 éq)
        DomainEntityInstance(
          instanceId: 'c3',
          category: DomainObjectType.coffret,
          name: 'C3',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone A > Local A2',
          parentZone: 'Zone A',
          parentLocal: 'Local A2',
          rawModelRef: makeCoffret('C3'),
        ),
        DomainEntityInstance(
          instanceId: 'c4',
          category: DomainObjectType.coffret,
          name: 'C4',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone A > Local A2',
          parentZone: 'Zone A',
          parentLocal: 'Local A2',
          rawModelRef: makeCoffret('C4'),
        ),
        DomainEntityInstance(
          instanceId: 'c5',
          category: DomainObjectType.coffret,
          name: 'C5',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone A > Local A2',
          parentZone: 'Zone A',
          parentLocal: 'Local A2',
          rawModelRef: makeCoffret('C5'),
        ),
      ];

      final inventory = MissionDomainInventory(
        missionId: 'm2',
        instances: instances,
        allFindings: [],
      );

      final zoneAEquipments = inventory.instances
          .where((i) => i.parentZone == 'Zone A' && i.category == DomainObjectType.coffret)
          .toList();
      expect(zoneAEquipments.length, equals(5));

      final localA1Equipments = inventory.instances
          .where((i) => i.parentLocal == 'Local A1' && i.category == DomainObjectType.coffret)
          .toList();
      expect(localA1Equipments.length, equals(2));

      final localA2Equipments = inventory.instances
          .where((i) => i.parentLocal == 'Local A2' && i.category == DomainObjectType.coffret)
          .toList();
      expect(localA2Equipments.length, equals(3));
    });

    test('Cas 3 : Deux zones (Zone A et Zone B) -> aucun équipement attribué à la mauvaise zone', () {
      CoffretArmoire makeCoffret(String name) => CoffretArmoire(
            qrCode: 'QR_$name',
            nom: name,
            type: 'COFFRET',
            statut: 'complet',
            currentStep: 3,
            photos: [],
            photosExternes: [],
            photosInternes: [],
            alimentations: [],
            pointsVerification: [],
            observationsLibres: [],
            observationsParafoudre: [],
          );

      final instances = [
        DomainEntityInstance(
          instanceId: 'ca1',
          category: DomainObjectType.coffret,
          name: 'C_A1',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone Production > Local A1',
          parentZone: 'Zone Production',
          parentLocal: 'Local A1',
          rawModelRef: makeCoffret('C_A1'),
        ),
        DomainEntityInstance(
          instanceId: 'ca2',
          category: DomainObjectType.coffret,
          name: 'C_A2',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone Production > Local A1',
          parentZone: 'Zone Production',
          parentLocal: 'Local A1',
          rawModelRef: makeCoffret('C_A2'),
        ),
        DomainEntityInstance(
          instanceId: 'cb1',
          category: DomainObjectType.coffret,
          name: 'C_B1',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone Stockage > Local B1',
          parentZone: 'Zone Stockage',
          parentLocal: 'Local B1',
          rawModelRef: makeCoffret('C_B1'),
        ),
        DomainEntityInstance(
          instanceId: 'cb2',
          category: DomainObjectType.coffret,
          name: 'C_B2',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone Stockage > Local B1',
          parentZone: 'Zone Stockage',
          parentLocal: 'Local B1',
          rawModelRef: makeCoffret('C_B2'),
        ),
        DomainEntityInstance(
          instanceId: 'cb3',
          category: DomainObjectType.coffret,
          name: 'C_B3',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone Stockage > Local B1',
          parentZone: 'Zone Stockage',
          parentLocal: 'Local B1',
          rawModelRef: makeCoffret('C_B3'),
        ),
      ];

      final inventory = MissionDomainInventory(
        missionId: 'm3',
        instances: instances,
        allFindings: [],
      );

      final inZoneA = inventory.instances
          .where((i) => i.parentZone == 'Zone Production' && i.category == DomainObjectType.coffret)
          .map((i) => i.name)
          .toList();
      expect(inZoneA, equals(['C_A1', 'C_A2']));

      final inZoneB = inventory.instances
          .where((i) => i.parentZone == 'Zone Stockage' && i.category == DomainObjectType.coffret)
          .map((i) => i.name)
          .toList();
      expect(inZoneB, equals(['C_B1', 'C_B2', 'C_B3']));

      // Vérifier stricte disjonction
      expect(inZoneA.any((name) => inZoneB.contains(name)), isFalse);
    });

    test('Cas 4 : Brouillons et équipements incomplets -> exclus de la sélection Section 9', () {
      final complet = CoffretArmoire(
        qrCode: 'QRC',
        nom: 'Coffret Complet',
        type: 'COFFRET',
        statut: 'complet',
        currentStep: 3,
        photos: [],
        photosExternes: [],
        photosInternes: [],
        alimentations: [],
        pointsVerification: [],
        observationsLibres: [],
        observationsParafoudre: [],
      );
      final brouillon = CoffretArmoire(
        qrCode: 'QRB',
        nom: 'Coffret Brouillon',
        type: 'COFFRET',
        statut: 'brouillon',
        currentStep: 1,
        photos: [],
        photosExternes: [],
        photosInternes: [],
        alimentations: [],
        pointsVerification: [],
        observationsLibres: [],
        observationsParafoudre: [],
      );
      final incomplet = CoffretArmoire(
        qrCode: 'QRI',
        nom: 'Coffret Incomplet',
        type: 'COFFRET',
        statut: 'incomplet',
        currentStep: 2,
        photos: [],
        photosExternes: [],
        photosInternes: [],
        alimentations: [],
        pointsVerification: [],
        observationsLibres: [],
        observationsParafoudre: [],
      );

      final instances = [
        DomainEntityInstance(
          instanceId: 'c_comp',
          category: DomainObjectType.coffret,
          name: 'Coffret Complet',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone Test > Local Test',
          parentZone: 'Zone Test',
          parentLocal: 'Local Test',
          rawModelRef: complet,
        ),
        DomainEntityInstance(
          instanceId: 'c_brouillon',
          category: DomainObjectType.coffret,
          name: 'Coffret Brouillon',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone Test > Local Test',
          parentZone: 'Zone Test',
          parentLocal: 'Local Test',
          rawModelRef: brouillon,
        ),
        DomainEntityInstance(
          instanceId: 'c_incomplet',
          category: DomainObjectType.coffret,
          name: 'Coffret Incomplet',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone Test > Local Test',
          parentZone: 'Zone Test',
          parentLocal: 'Local Test',
          rawModelRef: incomplet,
        ),
      ];

      final inventory = MissionDomainInventory(
        missionId: 'm4',
        instances: instances,
        allFindings: [],
      );

      const equipmentCategories = {
        DomainObjectType.celluleMT,
        DomainObjectType.transformateurMTBT,
        DomainObjectType.tgbt,
        DomainObjectType.armoire,
        DomainObjectType.coffret,
        DomainObjectType.inverseur,
      };

      final eligible = inventory.instances.where((i) {
        if (!equipmentCategories.contains(i.category)) return false;
        final raw = i.rawModelRef;
        if (raw is CoffretArmoire) {
          final st = raw.statut.trim().toLowerCase();
          if (st == 'incomplet' || st == 'brouillon') {
            return false;
          }
        }
        return true;
      }).toList();

      expect(eligible.length, equals(1));
      expect(eligible.first.name, equals('Coffret Complet'));
    });
  });

  group('2. Analyse statistique de Pareto — Non-forçage de la loi des 80/20', () {
    test('Distribution fortement concentrée (Pareto 80/20 vérifié)', () {
      final findings = <AuditFinding>[];
      // 100 non-conformités au total
      // Cat 1 : 50
      // Cat 2 : 32 -> Top 2 = 82% (sur 10 catégories au total)
      for (int i = 0; i < 50; i++) {
        findings.add(AuditFinding(
          id: 'f1_$i',
          missionId: 'm',
          tensionDomain: TensionDomain.bt,
          origin: 'o',
          objectType: 'Coffret',
          objectName: 'C1',
          tableName: 't',
          verificationPoint: 'Défaut majeur A',
          observationText: 'obs',
          conformity: 'non',
          criticality: 'Critique',
        ));
      }
      for (int i = 0; i < 32; i++) {
        findings.add(AuditFinding(
          id: 'f2_$i',
          missionId: 'm',
          tensionDomain: TensionDomain.bt,
          origin: 'o',
          objectType: 'Coffret',
          objectName: 'C1',
          tableName: 't',
          verificationPoint: 'Défaut majeur B',
          observationText: 'obs',
          conformity: 'non',
          criticality: 'Majeure',
        ));
      }
      // 8 catégories à 2-3 occurrences
      for (int c = 3; c <= 10; c++) {
        final count = (c <= 4) ? 3 : 2;
        for (int i = 0; i < count; i++) {
          findings.add(AuditFinding(
            id: 'f${c}_$i',
            missionId: 'm',
            tensionDomain: TensionDomain.bt,
            origin: 'o',
            objectType: 'Coffret',
            objectName: 'C1',
            tableName: 't',
            verificationPoint: 'Défaut mineur $c',
            observationText: 'obs',
            conformity: 'non',
            criticality: 'Mineure',
          ));
        }
      }

      final inventory = MissionDomainInventory(
        missionId: 'm',
        instances: [],
        allFindings: findings,
      );

      final pareto = inventory.getParetoAnalysis(limit: 10);
      expect(pareto.totalOccurrences, equals(findings.length));
      expect(pareto.paretoCategoryCount, equals(2));
      expect(pareto.paretoCumulativePercentage, greaterThanOrEqualTo(80.0));
      expect(pareto.isThresholdReached, isTrue);
      expect(pareto.profile, equals(ParetoConcentrationProfile.highConcentration));
      expect(pareto.summaryText, contains('forte concentration compatible avec la loi de Pareto (80/20)'));
    });

    test('Distribution homogène et dispersée -> absence de Pareto signalée objectivement', () {
      final findings = <AuditFinding>[];
      // 10 catégories avec 10 occurrences chacune (parfaitement homogène)
      final categoryKeywords = [
        'Défaut de terre et différentiel',
        'Défaut surintensité disjoncteur',
        'Défaut répartiteur et bornier',
        'Défaut repérage et schéma',
        'Défaut câblage et raccordement',
        'Défaut enveloppe et armoire',
        'Défaut coupure et sectionneur',
        'Défaut éclairage et baes secours',
        'Défaut poste cellule HT',
        'Autre défaut divers',
      ];

      for (int c = 0; c < categoryKeywords.length; c++) {
        for (int i = 0; i < 10; i++) {
          findings.add(AuditFinding(
            id: 'fh_${c}_$i',
            missionId: 'm_homo',
            tensionDomain: TensionDomain.bt,
            origin: 'o',
            objectType: 'Coffret',
            objectName: 'C1',
            tableName: 't',
            verificationPoint: categoryKeywords[c],
            observationText: 'obs',
            conformity: 'non',
            criticality: 'Majeure',
          ));
        }
      }

      final inventory = MissionDomainInventory(
        missionId: 'm_homo',
        instances: [],
        allFindings: findings,
      );

      final pareto = inventory.getParetoAnalysis(limit: 10);
      expect(pareto.totalOccurrences, equals(100));
      expect(pareto.paretoCategoryCount, equals(8));
      expect(pareto.k80Ratio, equals(0.8));
      expect(pareto.profile, equals(ParetoConcentrationProfile.homogeneousOrDispersed));
      expect(pareto.summaryText, contains('Contrairement à une distribution de Pareto classique'));
      expect(pareto.summaryText, contains('relativement homogène et dispersée'));
    });

    test('Catégorie unique dominante (> 80% dès le 1er rang)', () {
      final findings = <AuditFinding>[];
      for (int i = 0; i < 90; i++) {
        findings.add(AuditFinding(
          id: 'fd1_$i',
          missionId: 'm_single',
          tensionDomain: TensionDomain.bt,
          origin: 'o',
          objectType: 'Coffret',
          objectName: 'C1',
          tableName: 't',
          verificationPoint: 'Absence totale de schéma unifilaire',
          observationText: 'obs',
          conformity: 'non',
          criticality: 'Critique',
        ));
      }
      for (int i = 0; i < 10; i++) {
        findings.add(AuditFinding(
          id: 'fd2_$i',
          missionId: 'm_single',
          tensionDomain: TensionDomain.bt,
          origin: 'o',
          objectType: 'Coffret',
          objectName: 'C1',
          tableName: 't',
          verificationPoint: 'Défaut repérage câbles',
          observationText: 'obs',
          conformity: 'non',
          criticality: 'Majeure',
        ));
      }

      final inventory = MissionDomainInventory(
        missionId: 'm_single',
        instances: [],
        allFindings: findings,
      );

      final pareto = inventory.getParetoAnalysis(limit: 10);
      expect(pareto.paretoCategoryCount, equals(1));
      expect(pareto.profile, equals(ParetoConcentrationProfile.singleDominant));
      expect(pareto.summaryText, contains('monopole critique de défaillance'));
    });

    test('Mission sans non-conformité (cas limite 0 NC)', () {
      final inventory = MissionDomainInventory(
        missionId: 'm_zero',
        instances: [],
        allFindings: [],
      );

      final pareto = inventory.getParetoAnalysis(limit: 10);
      expect(pareto.totalOccurrences, equals(0));
      expect(pareto.profile, equals(ParetoConcentrationProfile.noData));
      expect(pareto.summaryText, contains('Aucune non-conformité recensée'));
    });
  });
}
