// test/features/statistics_enrichment_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/canonical_risk_family_registry.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';

void main() {
  group('TechnicalEnrichmentEngine Unit Tests', () {
    test('Test 1 — Adéquation Icc / Pdc : parsing et conformité Pdc >= Icc', () {
      final coffret1 = CoffretArmoire(
        qrCode: 'QR_TEST',
        nom: 'TGBT 1',
        type: 'TGBT',
        statut: 'terminé',
        currentStep: 3,
        protectionTete: Alimentation(
          typeProtection: 'Disjoncteur',
          pdcKA: '25 kA',
          icc3Max: '18.4 kA',
          calibre: '400 A',
          sectionCable: '3x240 mm²',
          source: 'Transfo 1',
        ),
      );

      final coffret2 = CoffretArmoire(
        qrCode: 'QR_TEST',
        nom: 'Armoire 1',
        type: 'Armoire',
        statut: 'terminé',
        currentStep: 3,
        protectionTete: Alimentation(
          typeProtection: 'Disjoncteur',
          pdcKA: '10 kA',
          icc3Max: '15 kA', // Non conforme : 10 < 15
          calibre: '160 A',
          sectionCable: '4x35 mm²',
          source: 'TGBT 1',
        ),
      );

      final coffret3 = CoffretArmoire(
        qrCode: 'QR_TEST',
        nom: 'Coffret 1',
        type: 'Coffret',
        statut: 'terminé',
        currentStep: 3,
        protectionTete: Alimentation(
          typeProtection: 'Disjoncteur',
          pdcKA: 'Non renseigné',
          icc3Max: 'NC',
          calibre: '32 A',
          sectionCable: '4x6 mm²',
          source: 'Armoire 1',
        ),
      );

      final instances = [
        DomainEntityInstance(
          instanceId: '1',
          category: DomainObjectType.tgbt,
          name: 'TGBT 1',
          tensionDomain: TensionDomain.bt,
          originPath: 'Local TGBT',
          rawModelRef: coffret1,
        ),
        DomainEntityInstance(
          instanceId: '2',
          category: DomainObjectType.armoire,
          name: 'Armoire 1',
          tensionDomain: TensionDomain.bt,
          originPath: 'Atelier',
          rawModelRef: coffret2,
        ),
        DomainEntityInstance(
          instanceId: '3',
          category: DomainObjectType.coffret,
          name: 'Coffret 1',
          tensionDomain: TensionDomain.bt,
          originPath: 'Bureaux',
          rawModelRef: coffret3,
        ),
      ];

      final domainInv = MissionDomainInventory(
        missionId: 'm1',
        instances: instances,
        allFindings: [],
      );

      final findingInv = AuditFindingInventory(
        missionId: 'm1',
        findings: [],
        crossCategoryItems: [],
      );

      final result = TechnicalEnrichmentEngine.compute('m1', domainInv, findingInv);

      // TGBT : 1 conforme sur 1 évaluable
      final tgbtPdc = result.adequationIccPdcStats[DomainObjectType.tgbt]!;
      expect(tgbtPdc.evaluables, 1);
      expect(tgbtPdc.conformes, 1);
      expect(tgbtPdc.nonConformes, 0);
      expect(tgbtPdc.complianceRate, 100.0);

      // Armoire : 0 conforme sur 1 évaluable (10 < 15)
      final armPdc = result.adequationIccPdcStats[DomainObjectType.armoire]!;
      expect(armPdc.evaluables, 1);
      expect(armPdc.conformes, 0);
      expect(armPdc.nonConformes, 1);
      expect(armPdc.complianceRate, 0.0);

      // Coffret : 0 évaluable, 1 non renseigné
      final cofPdc = result.adequationIccPdcStats[DomainObjectType.coffret]!;
      expect(cofPdc.evaluables, 0);
      expect(cofPdc.nonRenseignes, 1);
      expect(cofPdc.complianceRate, 0.0);
    });

    test('Test 2 — Organe de coupure en tête, Source d\'alimentation et Parafoudre', () {
      final inv1 = CoffretArmoire(
        qrCode: 'QR_TEST',
        nom: 'Inverseur Normal/Secours',
        type: 'Inverseur',
        statut: 'terminé',
        currentStep: 3,
        presenceParafoudre: true,
        sourceNomComplet: 'Poste MT et Groupe 1',
        protectionTete: Alimentation(
          typeProtection: 'Interrupteur-Sectionneur',
          pdcKA: '',
          calibre: '630 A',
          sectionCable: '',
          source: '',
        ),
      );

      final cofSansTete = CoffretArmoire(
        qrCode: 'QR_TEST',
        nom: 'Coffret Secondaire',
        type: 'Coffret',
        statut: 'terminé',
        currentStep: 3,
        presenceParafoudre: false,
        protectionTete: null,
        departPrisAvecProtection: false, // Départ direct sur répartiteurs
      );

      final instances = [
        DomainEntityInstance(
          instanceId: '1',
          category: DomainObjectType.inverseur,
          name: 'Inverseur',
          tensionDomain: TensionDomain.bt,
          originPath: 'Local TGBT',
          rawModelRef: inv1,
        ),
        DomainEntityInstance(
          instanceId: '2',
          category: DomainObjectType.coffret,
          name: 'Coffret Secondaire',
          tensionDomain: TensionDomain.bt,
          originPath: 'Zone Atelier',
          rawModelRef: cofSansTete,
        ),
      ];

      final domainInv = MissionDomainInventory(
        missionId: 'm1',
        instances: instances,
        allFindings: [],
      );

      final result = TechnicalEnrichmentEngine.compute(
        'm1',
        domainInv,
        AuditFindingInventory(missionId: 'm1', findings: [], crossCategoryItems: []),
      );

      // Inverseur : Coupure tête présente, Source identifiée, Parafoudre présent
      final invCoupure = result.coupureTeteStats[DomainObjectType.inverseur]!;
      expect(invCoupure.presents, 1);
      expect(invCoupure.percentage, 100.0);

      final invSource = result.sourceStats[DomainObjectType.inverseur]!;
      expect(invSource.identifiees, 1);
      expect(invSource.percentage, 100.0);

      final invPara = result.parafoudreStats[DomainObjectType.inverseur]!;
      expect(invPara.avecParafoudre, 1);
      expect(invPara.percentage, 100.0);

      // Coffret sans tête : Absent, Source non identifiée, Sans parafoudre
      final cofCoupure = result.coupureTeteStats[DomainObjectType.coffret]!;
      expect(cofCoupure.absents, 1);
      expect(cofCoupure.percentage, 0.0);

      final cofSource = result.sourceStats[DomainObjectType.coffret]!;
      expect(cofSource.nonIdentifiees, 1);

      final cofPara = result.parafoudreStats[DomainObjectType.coffret]!;
      expect(cofPara.sansParafoudre, 1);
    });

    test('Test 3 — Distribution des câbles (Alu vs Cuivre et Sections)', () {
      final armoire = CoffretArmoire(
        qrCode: 'QR_TEST',
        nom: 'Armoire Distribution',
        type: 'Armoire',
        statut: 'terminé',
        currentStep: 3,
        departures: [
          DepartEquipement(
            id: 'd1',
            protectionTete: 'Disjoncteur',
            identification: 'Départ 1',
            typeProtection: 'Disjoncteur',
            marque: 'Schneider',
            courbe: 'C',
            pdcKA: '15',
            icc3Max: '10',
            calibre: '63A',
            sectionCable: '10 mm²',
            ddr: '',
            natureCable: 'Cuivre',
          ),
          DepartEquipement(
            id: 'd2',
            protectionTete: 'Disjoncteur',
            identification: 'Départ 2',
            typeProtection: 'Disjoncteur',
            marque: 'Schneider',
            courbe: 'C',
            pdcKA: '25',
            icc3Max: '10',
            calibre: '160A',
            sectionCable: '70 mm²',
            ddr: '',
            natureCable: 'Aluminium',
          ),
        ],
      );

      final instances = [
        DomainEntityInstance(
          instanceId: '1',
          category: DomainObjectType.armoire,
          name: 'Armoire Distribution',
          tensionDomain: TensionDomain.bt,
          originPath: 'Local',
          rawModelRef: armoire,
        ),
      ];

      final domainInv = MissionDomainInventory(
        missionId: 'm1',
        instances: instances,
        allFindings: [],
      );

      final result = TechnicalEnrichmentEngine.compute(
        'm1',
        domainInv,
        AuditFindingInventory(missionId: 'm1', findings: [], crossCategoryItems: []),
      );

      final armoireCables = result.cablesMatrix.firstWhere((r) => r.category == DomainObjectType.armoire);
      expect(armoireCables.departsBreakdown.containsKey('Cuivre'), true);
      expect(armoireCables.departsBreakdown.containsKey('Aluminium'), true);
      expect(armoireCables.departsBreakdown['Cuivre']!.count, 1);
      expect(armoireCables.departsBreakdown['Aluminium']!.count, 1);
    });

    test('Test 4 — Matrice 4 quadrants des Familles de Risque et non-redondance', () {
      final f1 = AuditFinding(
        id: 'f1',
        missionId: 'm1',
        tensionDomain: TensionDomain.mt,
        origin: 'Poste MT',
        objectType: 'Local MT',
        objectName: 'Local MT',
        tableName: 'Dispositions constructives',
        verificationPoint: 'Accès et portes coupe-feu',
        observationText: 'Porte détériorée',
        conformity: 'non',
        criticality: 'Majeure',
        riskFamily: CanonicalRiskFamilyRegistry.degradationCanalisations,
      );

      final f2 = AuditFinding(
        id: 'f2',
        missionId: 'm1',
        tensionDomain: TensionDomain.bt,
        origin: 'TGBT',
        objectType: 'TGBT',
        objectName: 'TGBT Principal',
        tableName: 'Points de vérification',
        verificationPoint: 'Repérage des départs',
        observationText: 'Absence de repérage',
        conformity: 'non',
        criticality: 'Critique',
        riskFamily: CanonicalRiskFamilyRegistry.erreurExploitation,
      );

      final matrix = TechnicalEnrichmentEngine.compute(
        'm1',
        MissionDomainInventory(missionId: 'm1', instances: [], allFindings: [f1, f2]),
        AuditFindingInventory(missionId: 'm1', findings: [f1, f2], crossCategoryItems: []),
      ).riskFamilyMatrix;

      expect(matrix.htaDispositionsConstructives[CanonicalRiskFamilyRegistry.degradationCanalisations], 1);
      expect(matrix.btExploitationMaintenance[CanonicalRiskFamilyRegistry.erreurExploitation], 1);
      expect(matrix.totalGlobal, 2);
    });
  });
}
