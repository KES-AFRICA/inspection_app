// test/features/statistical_synthesis_engine_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/mission_statistics.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';
import 'package:inspec_app/services/statistics/statistical_synthesis_engine.dart';
import 'package:inspec_app/services/pdf/builders/pdf_statistics_builder.dart';

void main() {
  group('StatisticalSynthesisEngine — Tests Unitaires & Multi-Scénarios', () {
    test('Scénario A : Mission 100% conforme (0 non-conformité)', () {
      final summary = MissionStatisticsSummary(
        missionId: 'miss_zero',
        inventory: AuditFindingInventory(missionId: 'miss_zero', findings: const []),
        criticalityStats: CriticalityStats(
          critique: 0,
          majeure: 0,
          mineure: 0,
          total: 0,
          pctCritique: 0.0,
          pctMajeure: 0.0,
          pctMineure: 0.0,
        ),
        topDefects: const [],
        paretoResult: ParetoAnalysisResult(
          items: const [],
          totalOccurrences: 0,
          paretoCategoryCount: 0,
          paretoCumulativePercentage: 0.0,
          summaryText: '',
        ),
        topTwoCategoriesResult: TopNonConformityCategoriesResult(
          label: '',
          cat1Name: 'N/A',
          combinedNC: 0,
          pctTotalNC: 0.0,
          combinedEquipments: 0,
          pctParc: 0.0,
          formattedValue: '',
        ),
        riskFamilyStats: const [],
        tensionDomainStats: TensionDomainStats(mtCount: 0, btCount: 0, totalCount: 0, mtPct: 0.0, btPct: 0.0),
        installationTypeStats: const [],
        crossCategoryItems: const [],
        crossAnalysisText: '',
        equipmentInventory: [EquipmentInventoryItem(label: 'TGBT', count: 5)],
      );

      final result = StatisticalSynthesisEngine.analyze(summary: summary);

      expect(result.paragraphs.length, equals(2));
      expect(result.paragraphs[0], contains('excellent niveau global de maîtrise du risque électrique'));
      expect(result.paragraphs[0], contains('0,00 non-conformité par équipement'));
      expect(result.paragraphs[1], contains('En conclusion'));
      expect(result.paragraphs[1], contains('reconduction régulière des vérifications'));
      expect(result.profile.hasTechnicalDeficit, isFalse);
    });

    test('Scénario B : Très faible volume (1 à 3 NCs purement mineures)', () {
      final findings = [
        AuditFinding(
          id: 'min_1',
          missionId: 'miss_low',
          tensionDomain: TensionDomain.bt,
          origin: 'Local BT',
          objectType: 'Coffret',
          objectName: 'Coffret 1',
          tableName: 'Points de vérification',
          verificationPoint: 'Propreté du local',
          observationText: 'Poussière légère',
          conformity: 'non',
          criticality: 'Mineure',
          riskFamily: 'Conditions environnementales',
          photos: const [],
        ),
        AuditFinding(
          id: 'min_2',
          missionId: 'miss_low',
          tensionDomain: TensionDomain.bt,
          origin: 'Local BT',
          objectType: 'Coffret',
          objectName: 'Coffret 2',
          tableName: 'Points de vérification',
          verificationPoint: 'Signalisation',
          observationText: 'Pictogramme usé',
          conformity: 'non',
          criticality: 'Mineure',
          riskFamily: 'Conditions environnementales',
          photos: const [],
        ),
      ];

      final summary = MissionStatisticsSummary(
        missionId: 'miss_low',
        inventory: AuditFindingInventory(missionId: 'miss_low', findings: findings),
        criticalityStats: CriticalityStats(
          critique: 0,
          majeure: 0,
          mineure: 2,
          total: 2,
          pctCritique: 0.0,
          pctMajeure: 0.0,
          pctMineure: 100.0,
        ),
        topDefects: const [],
        paretoResult: ParetoAnalysisResult(
          items: const [],
          totalOccurrences: 2,
          paretoCategoryCount: 1,
          paretoCumulativePercentage: 100.0,
          summaryText: '',
        ),
        topTwoCategoriesResult: TopNonConformityCategoriesResult(
          label: '',
          cat1Name: 'Coffrets',
          combinedNC: 2,
          pctTotalNC: 100.0,
          combinedEquipments: 10,
          pctParc: 100.0,
          formattedValue: '2 NC',
        ),
        riskFamilyStats: [RiskFamilyItem(name: 'Conditions environnementales', count: 2, percentage: 100.0)],
        tensionDomainStats: TensionDomainStats(mtCount: 0, btCount: 2, totalCount: 2, mtPct: 0.0, btPct: 100.0),
        installationTypeStats: const [],
        crossCategoryItems: const [],
        crossAnalysisText: '',
        equipmentInventory: [EquipmentInventoryItem(label: 'Coffret', count: 10)],
      );

      final result = StatisticalSynthesisEngine.analyze(summary: summary);

      expect(result.paragraphs.length, equals(2));
      expect(result.paragraphs[0], contains('niveau global de maîtrise du risque électrique satisfaisant'));
      expect(result.paragraphs[0], contains('2 non-conformités'));
      expect(result.paragraphs[0], contains('gravité mineure'));
      expect(result.paragraphs[1], contains('tournées de maintenance courantes'));
    });

    test('Scénario C : Industrie lourde type CIMENCAM - FIGUIL (496 NC, 93 Critiques, 403 Majeures, 2,95 NC/équipement)', () {
      final findings = <AuditFinding>[];
      for (int i = 0; i < 496; i++) {
        findings.add(AuditFinding(
          id: 'nc_$i',
          missionId: 'miss_cimencam',
          tensionDomain: (i < 344) ? TensionDomain.bt : TensionDomain.mt,
          origin: (i < 344) ? 'Local BT' : 'Local MT',
          objectType: (i < 344) ? 'Armoire' : 'Cellule MT',
          objectName: 'Équipement $i',
          tableName: 'Points de vérification',
          verificationPoint: (i % 2 == 0)
              ? 'Identification et repérage des circuits'
              : 'Câblages et serrages des connexions',
          observationText: 'Constat $i',
          conformity: 'non',
          criticality: (i < 93) ? 'Critique' : 'Majeure',
          riskFamily: (i < 307)
              ? 'Pratiques d\'exploitation et de maintenance'
              : 'Dégradation des canalisations et des matériels',
          photos: const [],
        ));
      }

      final summary = MissionStatisticsSummary(
        missionId: 'miss_cimencam',
        inventory: AuditFindingInventory(missionId: 'miss_cimencam', findings: findings),
        criticalityStats: CriticalityStats(
          critique: 93,
          majeure: 403,
          mineure: 0,
          total: 496,
          pctCritique: 18.75, // 18,8 %
          pctMajeure: 81.25, // 81,3 %
          pctMineure: 0.0,
        ),
        topDefects: const [],
        paretoResult: ParetoAnalysisResult(
          items: [
            TopDefectItem(title: 'Identification, repérage et documentation des circuits', count: 184, percentage: 37.1),
            TopDefectItem(title: 'Câblages, raccordements et canalisations', count: 183, percentage: 36.9),
            TopDefectItem(title: 'Intégrité des enveloppes et armoires', count: 50, percentage: 10.1),
          ],
          totalOccurrences: 496,
          paretoCategoryCount: 3,
          paretoCumulativePercentage: 84.1,
          summaryText: '',
        ),
        topTwoCategoriesResult: TopNonConformityCategoriesResult(
          label: 'Armoires BT',
          cat1Name: 'Armoires BT',
          combinedNC: 496,
          pctTotalNC: 100.0,
          combinedEquipments: 168,
          pctParc: 100.0,
          formattedValue: '496 NC',
        ),
        riskFamilyStats: [
          RiskFamilyItem(name: 'Pratiques d\'exploitation et de maintenance', count: 307, percentage: 61.9),
          RiskFamilyItem(name: 'Dégradation des canalisations et des matériels', count: 125, percentage: 25.3),
        ],
        tensionDomainStats: TensionDomainStats(
          mtCount: 152,
          btCount: 344,
          totalCount: 496,
          mtPct: 30.65, // 30,7 %
          btPct: 69.35, // 69,3 %
        ),
        installationTypeStats: const [],
        crossCategoryItems: const [],
        crossAnalysisText: '',
        equipmentInventory: [EquipmentInventoryItem(label: 'Armoires', count: 168)],
      );

      final technical = TechnicalEnrichmentResult(
        missionId: 'miss_cimencam',
        essaisCoverage: const EssaisCoverageStats(
          prisesTerreCount: 10,
          testDdrCount: 20,
          mesureIsolementCount: 15,
          testCpiCount: 0,
          continuitePeCount: 30,
          demarrageGeCount: 0,
          arretUrgenceCount: 5,
        ),
        coupureTeteStats: {
          DomainObjectType.armoire: const CoupureTeteStats(
            category: DomainObjectType.armoire,
            totalEquipments: 100,
            presents: 60,
            absents: 40,
          ),
        },
        sourceStats: {
          DomainObjectType.armoire: const SourceAlimentationStats(
            category: DomainObjectType.armoire,
            totalEquipments: 100,
            identifiees: 50,
            nonIdentifiees: 50,
          ),
        },
        parafoudreStats: const {},
        adequationIccPdcStats: {},
        marquesMatrix: [],
        courbesMatrix: [],
        pdcDepartStats: {},
        pdcTerminalStats: {},
        cablesMatrix: [],
        ipIkZoneItems: [
          const IpIkZoneItem(
            zoneNom: 'Zone Usine',
            totalEquipements: 50,
            conformes: 20,
            nonConformes: 10,
            nonRenseignes: 20,
            indicesPresents: 30,
          ),
        ],
        riskFamilyMatrix: const RiskFamilyCrossMatrix.empty(),
        top5Hta: [],
        top5Bt: [],
        totalZonesClassees: 0,
        totalLocauxMt: 0,
        totalLocauxBt: 2,
        totalLocauxGe: 0,
        locauxMtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        locauxBtFindings: const LocauxFindingsStats(dispoConstructives: 10, conditionsExploitation: 10),
        mtCategoriesCrossRows: [
          const CategoryCrossAuditRow(
            categoryName: 'Locaux techniques GE',
            equipementsCount: 4,
            ncCount: 38,
            critiquesCount: 11,
            majeuresCount: 27,
            pctOfTotalNc: 7.7,
            tauxCritique: 28.9,
            densite: 9.5,
          ),
        ],
        btCategoriesCrossRows: [
          const CategoryCrossAuditRow(
            categoryName: 'Coffrets',
            equipementsCount: 18,
            ncCount: 67,
            critiquesCount: 19,
            majeuresCount: 48,
            pctOfTotalNc: 13.5,
            tauxCritique: 28.4,
            densite: 3.7,
          ),
        ],
        mtTotalCrossRow: const CategoryCrossAuditRow(
          categoryName: 'MT',
          equipementsCount: 4,
          ncCount: 38,
          critiquesCount: 11,
          majeuresCount: 27,
          pctOfTotalNc: 7.7,
          tauxCritique: 28.9,
          densite: 9.5,
        ),
        btTotalCrossRow: const CategoryCrossAuditRow(
          categoryName: 'BT',
          equipementsCount: 164,
          ncCount: 458,
          critiquesCount: 82,
          majeuresCount: 376,
          pctOfTotalNc: 92.3,
          tauxCritique: 17.9,
          densite: 2.8,
        ),
      );

      final result = StatisticalSynthesisEngine.analyze(summary: summary, technical: technical);

      expect(result.paragraphs.length, equals(6));

      // Paragraphe 1 : Périmètre, volume, densité, criticité
      expect(result.paragraphs[0], contains('niveau global de maîtrise du risque électrique qui demeure insuffisant'));
      expect(result.paragraphs[0], contains('2,95 non-conformités par équipement'));
      expect(result.paragraphs[0], contains('18,8 % de non-conformités critiques et 81,3 % de non-conformités majeures'));
      expect(result.paragraphs[0], contains('sans aucune non-conformité classée mineure'));

      // Paragraphe 2 : Tension & Vulnérabilités catégorielles
      expect(result.paragraphs[1], contains('Basse Tension (69,4 %)'));
      expect(result.paragraphs[1], contains('30,6 % en HTA'));
      expect(result.paragraphs[1], contains('locaux techniques ge'));
      expect(result.paragraphs[1], contains('coffrets'));
      expect(result.paragraphs[1], contains('28,9 % et 28,4 % de non-conformités critiques'));

      // Paragraphe 3 : Familles de risques
      expect(result.paragraphs[2], contains('pratiques d’exploitation et de maintenance'));
      expect(result.paragraphs[2], contains('61,9 % des occurrences'));
      expect(result.paragraphs[2], contains('dégradation des canalisations et des matériels'));
      expect(result.paragraphs[2], contains('25,3 %'));

      // Paragraphe 4 : Pareto
      expect(result.paragraphs[3], contains('identification, repérage et documentation des circuits'));
      expect(result.paragraphs[3], contains('câblages, raccordements et canalisations'));

      // Paragraphe 5 : Déficit technique
      expect(result.paragraphs[4], contains('déficit important de données techniques et de traçabilité'));
      expect(result.paragraphs[4], contains('sources d’alimentation'));
      expect(result.paragraphs[4], contains('indices IP/IK'));
      expect(result.paragraphs[4], contains('dispositifs de coupure'));

      // Paragraphe 6 : Conclusion
      expect(result.paragraphs[5], contains('En conclusion'));
      expect(result.paragraphs[5], contains('plan d’actions vers la fiabilisation des installations'));
    });

    test('Scénario D : Distribution Pareto homogène et dispersée', () {
      final summary = MissionStatisticsSummary(
        missionId: 'miss_dispersed',
        inventory: AuditFindingInventory(missionId: 'miss_dispersed', findings: const []),
        criticalityStats: CriticalityStats(
          critique: 5,
          majeure: 15,
          mineure: 10,
          total: 30,
          pctCritique: 16.7,
          pctMajeure: 50.0,
          pctMineure: 33.3,
        ),
        topDefects: const [],
        paretoResult: ParetoAnalysisResult(
          items: List.generate(
            15,
            (i) => TopDefectItem(
              title: 'Point de vérification $i',
              count: 2,
              percentage: 6.7,
            ),
          ),
          totalOccurrences: 30,
          paretoCategoryCount: 12,
          paretoCumulativePercentage: 80.0,
          summaryText: '',
          isThresholdReached: true,
        ),
        topTwoCategoriesResult: TopNonConformityCategoriesResult(
          label: '',
          cat1Name: 'Armoires',
          combinedNC: 10,
          pctTotalNC: 33.3,
          combinedEquipments: 15,
          pctParc: 100.0,
          formattedValue: '10 NC',
        ),
        riskFamilyStats: [
          RiskFamilyItem(name: 'Conditions environnementales', count: 15, percentage: 50.0),
          RiskFamilyItem(name: 'Sécurité réglementaire', count: 15, percentage: 50.0),
        ],
        tensionDomainStats: TensionDomainStats(mtCount: 0, btCount: 30, totalCount: 30, mtPct: 0.0, btPct: 100.0),
        installationTypeStats: const [],
        crossCategoryItems: const [],
        crossAnalysisText: '',
        equipmentInventory: [EquipmentInventoryItem(label: 'Armoires', count: 15)],
      );

      final result = StatisticalSynthesisEngine.analyze(summary: summary);

      // Paragraphe 4 doit expliciter la dispersion
      expect(result.paragraphs.any((p) => p.contains('distribution relativement dispersée')), isTrue);
    });

    test('Scénario E : Moyenne Tension dominante (HTA > 75 %)', () {
      final summary = MissionStatisticsSummary(
        missionId: 'miss_hta',
        inventory: AuditFindingInventory(missionId: 'miss_hta', findings: const []),
        criticalityStats: CriticalityStats(
          critique: 8,
          majeure: 22,
          mineure: 0,
          total: 30,
          pctCritique: 26.7,
          pctMajeure: 73.3,
          pctMineure: 0.0,
        ),
        topDefects: const [],
        paretoResult: ParetoAnalysisResult(items: const [], totalOccurrences: 30, paretoCategoryCount: 2, paretoCumulativePercentage: 80.0, summaryText: ''),
        topTwoCategoriesResult: TopNonConformityCategoriesResult(
          label: '',
          cat1Name: 'Postes MT',
          combinedNC: 24,
          pctTotalNC: 80.0,
          combinedEquipments: 4,
          pctParc: 100.0,
          formattedValue: '24 NC',
        ),
        riskFamilyStats: [
          RiskFamilyItem(name: 'Sécurité réglementaire', count: 30, percentage: 100.0),
        ],
        tensionDomainStats: TensionDomainStats(
          mtCount: 24,
          btCount: 6,
          totalCount: 30,
          mtPct: 80.0,
          btPct: 20.0,
        ),
        installationTypeStats: const [],
        crossCategoryItems: const [],
        crossAnalysisText: '',
        equipmentInventory: [EquipmentInventoryItem(label: 'Poste MT', count: 4)],
      );

      final result = StatisticalSynthesisEngine.analyze(summary: summary);

      // Paragraphe 2 doit indiquer la forte prépondérance Moyenne Tension
      expect(result.paragraphs[1], contains('Moyenne Tension (80,0 %)'));
      expect(result.paragraphs[1], contains('20,0 % en Basse Tension'));
    });

    test('Scénario F : Intégration PDF complète via PdfStatisticsBuilder', () {
      final mission = Mission(
        id: 'miss_pdf_stat',
        nomClient: 'CIMENCAM',
        natureMission: 'Audit Périodique',
        dateIntervention: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'en_cours',
      );

      final widgets = PdfStatisticsBuilder.buildAnalyseStatistique(
        mission,
        {},
        'KES/2026/001',
      );

      expect(widgets.isNotEmpty, isTrue);

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          build: (context) => widgets,
        ),
      );

      final bytes = doc.save();
      expect(bytes, isNotNull);
    });
  });
}
