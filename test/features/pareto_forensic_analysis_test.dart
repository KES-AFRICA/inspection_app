import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/canonical_defect_category_registry.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';

AuditFinding _makeFinding({
  required String id,
  required String verificationPoint,
  required String observationText,
  String criticality = 'Majeure',
}) {
  return AuditFinding(
    id: id,
    missionId: 'mission_test',
    tensionDomain: TensionDomain.bt,
    origin: 'Audit',
    objectType: 'Coffret',
    objectName: 'Coffret 1',
    tableName: 'BT',
    verificationPoint: verificationPoint,
    observationText: observationText,
    conformity: 'non',
    criticality: criticality,
  );
}

void main() {
  group('Audit Forensique — Section 4 : Analyse de Pareto & Normalisation Canonique', () {
    test('1. Normalisation canonique : les libellés synonymes sont résolus vers les 14 familles', () {
      expect(
        CanonicalDefectCategoryRegistry.mapToCanonical('Manque repérage circuits départ'),
        equals(CanonicalDefectCategoryRegistry.identificationEtReperage),
      );
      expect(
        CanonicalDefectCategoryRegistry.mapToCanonical('EPI absents dans le local'),
        equals(CanonicalDefectCategoryRegistry.consignationEtEpi),
      );
      expect(
        CanonicalDefectCategoryRegistry.mapToCanonical('Défaut continuité PE carcasse'),
        equals(CanonicalDefectCategoryRegistry.terreEtDifferentiel),
      );
      expect(
        CanonicalDefectCategoryRegistry.mapToCanonical('Absence de tapis diélectrique au sol'),
        equals(CanonicalDefectCategoryRegistry.revetementDielectrique),
      );
      expect(
        CanonicalDefectCategoryRegistry.mapToCanonical('Bloc de secours BAES hors service'),
        equals(CanonicalDefectCategoryRegistry.eclairageSecurite),
      );
      expect(
        CanonicalDefectCategoryRegistry.mapToCanonical('Défaut cellule MT disjoncteur'),
        equals(CanonicalDefectCategoryRegistry.posteMoyenneTension),
      );
      expect(
        CanonicalDefectCategoryRegistry.mapToCanonical('Câble détérioré ou mal fixé'),
        equals(CanonicalDefectCategoryRegistry.cablagesEtCanalisations),
      );
    });

    test('2. Bouclage 100 % avec plus de 10 catégories (> 10) et barre "Autres anomalies"', () {
      final findings = <AuditFinding>[];

      // 1: 30 constats
      for (int i = 0; i < 30; i++) {
        findings.add(_makeFinding(
          id: 'F1_$i',
          verificationPoint: 'Repérage circuits $i',
          observationText: 'Non repéré',
          criticality: 'Majeure',
        ));
      }
      // 2: 20 constats
      for (int i = 0; i < 20; i++) {
        findings.add(_makeFinding(
          id: 'F2_$i',
          verificationPoint: 'Câblage $i',
          observationText: 'Câble dénudé',
          criticality: 'Critique',
        ));
      }
      // 3 à 12: 10 catégories distinctes * 5 constats = 50 constats
      final otherLabels = [
        'Continuité PE',
        'EPI électriques',
        'Plan intervention consignation',
        'Revêtement diélectrique sol',
        'Dispositifs protection surintensité',
        'Coupure générale coupure d\'urgence',
        'Poste MT cellule transfo',
        'Éclairage secours BAES',
        'Bornes répartiteurs répartition',
        'Parafoudre foudre',
      ];
      for (int c = 0; c < otherLabels.length; c++) {
        for (int i = 0; i < 5; i++) {
          findings.add(_makeFinding(
            id: 'F_${c}_$i',
            verificationPoint: '${otherLabels[c]} $i',
            observationText: 'Défaut ${otherLabels[c]}',
            criticality: i % 2 == 0 ? 'Mineure' : 'Majeure',
          ));
        }
      }

      final totalOccurrences = findings.length; // 30 + 20 + 50 = 100 constats
      expect(totalOccurrences, equals(100));

      final inventory = MissionDomainInventory(
        missionId: 'mission_test',
        instances: [],
        allFindings: findings,
      );

      final pareto = inventory.getParetoAnalysis(limit: 10);

      expect(pareto.totalOccurrences, equals(100));
      expect(pareto.items.length, equals(10));
      expect(pareto.otherCategoryItem, isNotNull);
      expect(pareto.allDisplayItems.length, equals(11));

      // Vérification du cumul final de la barre Autres à 100 %
      expect(pareto.otherCategoryItem!.cumulativePercentage, equals(100.0));
      expect(pareto.allDisplayItems.last.cumulativePercentage, equals(100.0));

      // Somme exacte de toutes les occurrences dans allDisplayItems
      final sumOccurrences = pareto.allDisplayItems.fold<int>(0, (s, e) => s + e.count);
      expect(sumOccurrences, equals(100));

      // Somme exacte des pourcentages = 100 %
      final sumPercentages = pareto.allDisplayItems.fold<double>(0.0, (s, e) => s + e.percentage);
      expect(sumPercentages, closeTo(100.0, 0.01));
    });

    test('3. Bouclage 100 % avec moins de 10 catégories (<= 10) sans barre "Autres anomalies"', () {
      final findings = <AuditFinding>[];
      // 4 catégories
      for (int i = 0; i < 40; i++) {
        findings.add(_makeFinding(
          id: 'F1_$i',
          verificationPoint: 'Repérage',
          observationText: 'NC',
          criticality: 'Critique',
        ));
      }
      for (int i = 0; i < 30; i++) {
        findings.add(_makeFinding(
          id: 'F2_$i',
          verificationPoint: 'Câblages canalisations',
          observationText: 'NC',
          criticality: 'Majeure',
        ));
      }
      for (int i = 0; i < 20; i++) {
        findings.add(_makeFinding(
          id: 'F3_$i',
          verificationPoint: 'Terre conducteur PE',
          observationText: 'NC',
          criticality: 'Mineure',
        ));
      }
      for (int i = 0; i < 10; i++) {
        findings.add(_makeFinding(
          id: 'F4_$i',
          verificationPoint: 'EPI et habilitation',
          observationText: 'NC',
          criticality: 'Majeure',
        ));
      }

      final inventory = MissionDomainInventory(
        missionId: 'mission_test',
        instances: [],
        allFindings: findings,
      );

      final pareto = inventory.getParetoAnalysis(limit: 10);

      expect(pareto.totalOccurrences, equals(100));
      expect(pareto.items.length, equals(4));
      expect(pareto.otherCategoryItem, isNull);
      expect(pareto.allDisplayItems.length, equals(4));
      expect(pareto.allDisplayItems.last.cumulativePercentage, equals(100.0));
      expect(pareto.paretoCategoryCount, equals(3)); // 40 + 30 + 20 = 90% >= 80% au rang 3
    });

    test('4. Détection de cassure structurelle (Break Point à 2 catégories concentrant 45 %)', () {
      final findings = <AuditFinding>[];
      // Catégorie 1 : 25 constats
      for (int i = 0; i < 25; i++) {
        findings.add(_makeFinding(
          id: 'F1_$i',
          verificationPoint: 'Repérage identification',
          observationText: 'NC',
          criticality: 'Critique',
        ));
      }
      // Catégorie 2 : 20 constats
      for (int i = 0; i < 20; i++) {
        findings.add(_makeFinding(
          id: 'F2_$i',
          verificationPoint: 'Câblages canalisations',
          observationText: 'NC',
          criticality: 'Majeure',
        ));
      }
      // 11 catégories à 5 constats chacune = 55 constats (Total 100 constats)
      final dummyPoints = [
        'Terre PE',
        'EPI',
        'Plans intervention',
        'Revêtement diélectrique',
        'Protection surintensité disjoncteur',
        'Coupure générale arrêt',
        'Poste MT cellule',
        'Éclairage secours BAES',
        'Bornes répartiteurs',
        'Parafoudre foudre',
        'Ambiance ventilation',
      ];
      for (int c = 0; c < dummyPoints.length; c++) {
        for (int i = 0; i < 5; i++) {
          findings.add(_makeFinding(
            id: 'F_other_${c}_$i',
            verificationPoint: '${dummyPoints[c]} $i',
            observationText: 'NC',
            criticality: 'Mineure',
          ));
        }
      }

      final inventory = MissionDomainInventory(
        missionId: 'mission_test',
        instances: [],
        allFindings: findings,
      );

      final pareto = inventory.getParetoAnalysis(limit: 10);

      expect(pareto.hasBreakPoint, isTrue);
      expect(pareto.breakPointCategoryCount, equals(2));
      expect(pareto.breakPointPercentage, equals(45.0));
      expect(pareto.profile, equals(ParetoConcentrationProfile.breakPointConcentration));
    });

    test('5. Classification ABC et ventilation de criticité par catégorie', () {
      final findings = <AuditFinding>[];
      // Catégorie 1: 50 constats (dont 10 critiques, 30 majeures, 10 mineures) -> Classe A (50%)
      for (int i = 0; i < 50; i++) {
        findings.add(_makeFinding(
          id: 'F1_$i',
          verificationPoint: 'Repérage',
          observationText: 'NC',
          criticality: i < 10 ? 'Critique' : (i < 40 ? 'Majeure' : 'Mineure'),
        ));
      }
      // Catégorie 2: 35 constats (dont 5 critiques) -> Cumul 85% -> Classe A (franchit 80%)
      for (int i = 0; i < 35; i++) {
        findings.add(_makeFinding(
          id: 'F2_$i',
          verificationPoint: 'Câblages',
          observationText: 'NC',
          criticality: i < 5 ? 'Critique' : 'Majeure',
        ));
      }
      // Catégorie 3: 10 constats -> Cumul 95% -> Classe B
      for (int i = 0; i < 10; i++) {
        findings.add(_makeFinding(
          id: 'F3_$i',
          verificationPoint: 'Terre PE',
          observationText: 'NC',
          criticality: 'Mineure',
        ));
      }
      // Catégorie 4: 5 constats -> Cumul 100% -> Classe C
      for (int i = 0; i < 5; i++) {
        findings.add(_makeFinding(
          id: 'F4_$i',
          verificationPoint: 'EPI',
          observationText: 'NC',
          criticality: 'Mineure',
        ));
      }

      final inventory = MissionDomainInventory(
        missionId: 'mission_test',
        instances: [],
        allFindings: findings,
      );

      final pareto = inventory.getParetoAnalysis(limit: 10);

      expect(pareto.totalCritiques, equals(15));
      expect(pareto.items[0].critiqueCount, equals(10));
      expect(pareto.items[0].majeureCount, equals(30));
      expect(pareto.items[0].classeAbc, equals('A'));

      expect(pareto.items[1].critiqueCount, equals(5));
      expect(pareto.items[1].classeAbc, equals('A'));

      expect(pareto.items[2].classeAbc, equals('B'));
      expect(pareto.items[3].classeAbc, equals('C'));
    });

    test('6. Cas limite : 0 constat', () {
      final inventory = MissionDomainInventory(
        missionId: 'mission_test',
        instances: [],
        allFindings: [],
      );

      final pareto = inventory.getParetoAnalysis(limit: 10);

      expect(pareto.totalOccurrences, equals(0));
      expect(pareto.items, isEmpty);
      expect(pareto.otherCategoryItem, isNull);
      expect(pareto.allDisplayItems, isEmpty);
      expect(pareto.profile, equals(ParetoConcentrationProfile.noData));
    });
  });
}
