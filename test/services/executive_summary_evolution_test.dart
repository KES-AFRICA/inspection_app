import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/services/ai/executive_summary_snapshot.dart';
import 'package:inspec_app/services/ai/mission_executive_summary_service.dart';
import 'package:inspec_app/services/pdf/builders/pdf_executive_summary_builder.dart';
import 'package:inspec_app/services/statistics/mission_statistics.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Axe I — Contexte et Catégories Réelles Dynamiques', () {
    test('Formatage avec 0 catégorie', () {
      final snapshot = ExecutiveSummarySnapshot(
        missionId: 'm0',
        clientName: 'Client Test',
        siteName: 'Site Test',
        natureMission: 'Audit',
        dateRangeText: 'du 01/01/2026 au 02/01/2026',
        domainTension: 'Basse Tension (BT)',
        companyName: 'KES',
        reportNumber: 'KES/01',
        reportDateStr: '02/01/2026',
        officialStats: {'totalNC': 0, 'critique': 0, 'majeure': 0, 'mineure': 0, 'pctCritique': '0,0', 'pctMajeure': '0,0', 'pctMineure': '0,0'},
        categoryStats: [],
        topDefects: [],
        riskFamilies: [],
        equipmentCount: 0,
        installationsCount: 0,
        globalDensityStr: '0,00',
        activeCategoryLabels: const [],
      );

      final summary = MissionExecutiveSummaryService.buildDeterministicFallback('m0', snapshot);
      expect(summary.contexte.paragraph, contains('soit un total de 0 installation et équipement.'));
      expect(summary.contexte.paragraph, isNot(contains('()')));
    });

    test('Formatage avec 1 seule catégorie active (accord singulier)', () {
      final snapshot = ExecutiveSummarySnapshot(
        missionId: 'm1',
        clientName: 'Client Test',
        siteName: 'Site Test',
        natureMission: 'Audit',
        dateRangeText: 'le 01/01/2026',
        domainTension: 'Basse Tension (BT)',
        companyName: 'KES',
        reportNumber: 'KES/01',
        reportDateStr: '01/01/2026',
        officialStats: {'totalNC': 2, 'critique': 1, 'majeure': 1, 'mineure': 0, 'pctCritique': '50,0', 'pctMajeure': '50,0', 'pctMineure': '0,0'},
        categoryStats: [],
        topDefects: [],
        riskFamilies: [],
        equipmentCount: 5,
        installationsCount: 1,
        globalDensityStr: '0,40',
        activeCategoryLabels: ['Armoires'],
      );

      final summary = MissionExecutiveSummaryService.buildDeterministicFallback('m1', snapshot);
      expect(summary.contexte.paragraph, contains('soit un total de 5 installations et équipements répartis en 1 catégorie (Armoires).'));
    });

    test('Formatage avec 2 catégories actives (conjonction et)', () {
      final snapshot = ExecutiveSummarySnapshot(
        missionId: 'm2',
        clientName: 'Client Test',
        siteName: 'Site Test',
        natureMission: 'Audit',
        dateRangeText: 'le 01/01/2026',
        domainTension: 'Basse Tension (BT)',
        companyName: 'KES',
        reportNumber: 'KES/01',
        reportDateStr: '01/01/2026',
        officialStats: {'totalNC': 4, 'critique': 2, 'majeure': 2, 'mineure': 0, 'pctCritique': '50,0', 'pctMajeure': '50,0', 'pctMineure': '0,0'},
        categoryStats: [],
        topDefects: [],
        riskFamilies: [],
        equipmentCount: 12,
        installationsCount: 2,
        globalDensityStr: '0,33',
        activeCategoryLabels: ['TGBT', 'Armoires'],
      );

      final summary = MissionExecutiveSummaryService.buildDeterministicFallback('m2', snapshot);
      expect(summary.contexte.paragraph, contains('soit un total de 12 installations et équipements répartis en 2 catégories (TGBT et Armoires).'));
    });

    test('Formatage avec 3 catégories ou plus (virgules et conjonction et finale)', () {
      final snapshot = ExecutiveSummarySnapshot(
        missionId: 'm3',
        clientName: 'Client Test',
        siteName: 'Site Test',
        natureMission: 'Audit',
        dateRangeText: 'du 01/01/2026 au 05/01/2026',
        domainTension: 'Moyenne et Basse Tension (HTA/BT)',
        companyName: 'KES',
        reportNumber: 'KES/01',
        reportDateStr: '05/01/2026',
        officialStats: {'totalNC': 10, 'critique': 4, 'majeure': 5, 'mineure': 1, 'pctCritique': '40,0', 'pctMajeure': '50,0', 'pctMineure': '10,0'},
        categoryStats: [],
        topDefects: [],
        riskFamilies: [],
        equipmentCount: 25,
        installationsCount: 4,
        globalDensityStr: '0,40',
        activeCategoryLabels: ['Locaux MT (HTA)', 'Transformateurs MT/BT', 'TGBT', 'Coffrets'],
      );

      final summary = MissionExecutiveSummaryService.buildDeterministicFallback('m3', snapshot);
      expect(summary.contexte.paragraph, contains('soit un total de 25 installations et équipements répartis en 4 catégories (Locaux MT (HTA), Transformateurs MT/BT, TGBT et Coffrets).'));
    });
  });

  group('Axe II — Indicateurs Clés de la Mission', () {
    test('A - Essais Sans objet vs Applicables', () {
      // 1. Mission sans GE, sans régime IT, et avec arrêt d'urgence déclaré absent
      final mesuresSansObjet = MesuresEssais.create('m_so');
      mesuresSansObjet.testArretUrgence.presence = false; // Absent
      final descSansObjet = DescriptionInstallations.create('m_so');
      descSansObjet.regimeNeutre = 'TT'; // Pas IT, pas de GE

      final statsSo = EssaisCoverageStats(
        prisesTerreCount: 2,
        testDdrCount: 4,
        mesureIsolementCount: 1,
        testCpiCount: 0,
        continuitePeCount: 3,
        demarrageGeCount: 0,
        arretUrgenceCount: 0,
        isArretUrgenceApplicable: false,
        isDemarrageGeApplicable: false,
        isCpiApplicable: false,
      );

      expect(statsSo.isArretUrgenceApplicable, isFalse);
      expect(statsSo.isDemarrageGeApplicable, isFalse);
      expect(statsSo.isCpiApplicable, isFalse);
      expect(statsSo.totalEssais, equals(10)); // 2 + 4 + 1 + 3

      // 2. Mission avec GE et avec régime IT
      final statsApplicable = EssaisCoverageStats(
        prisesTerreCount: 2,
        testDdrCount: 4,
        mesureIsolementCount: 1,
        testCpiCount: 2,
        continuitePeCount: 3,
        demarrageGeCount: 1,
        arretUrgenceCount: 1,
        isArretUrgenceApplicable: true,
        isDemarrageGeApplicable: true,
        isCpiApplicable: true,
      );

      expect(statsApplicable.isArretUrgenceApplicable, isTrue);
      expect(statsApplicable.isDemarrageGeApplicable, isTrue);
      expect(statsApplicable.isCpiApplicable, isTrue);
      expect(statsApplicable.totalEssais, equals(14));

      // 3. Rendu textuel CPI : Sans objet si inerte (0) ou non applicable
      String formatCpi(EssaisCoverageStats s) {
        return (!s.isCpiApplicable || s.testCpiCount == 0)
            ? "Sans objet"
            : s.testCpiCount.toString();
      }
      expect(formatCpi(statsSo), equals("Sans objet"));
      expect(
        formatCpi(const EssaisCoverageStats(
          prisesTerreCount: 1,
          testDdrCount: 1,
          mesureIsolementCount: 1,
          testCpiCount: 0,
          continuitePeCount: 1,
          demarrageGeCount: 0,
          arretUrgenceCount: 0,
          isCpiApplicable: true,
        )),
        equals("Sans objet"),
      );
      expect(formatCpi(statsApplicable), equals("2"));
    });

    test('C - Équipements classés IP/IK & Adéquation globale arithmétique 3 populations', () {
      // 2 zones (1 classée -> 50%)
      // 4 locaux (3 classés -> 75%)
      // 10 équipements éligibles : 5 TGBT, 2 Inverseurs, 2 Armoires, 1 Coffret
      // 7 avec indice IP/IK valide -> 70%
      final result = TechnicalEnrichmentResult(
        missionId: 'm_ipik',
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
        ipIkZoneItems: const [],
        riskFamilyMatrix: const RiskFamilyCrossMatrix(
          htaDispositionsConstructives: RiskFamilyQuadrantStats.empty(),
          htaExploitationMaintenance: RiskFamilyQuadrantStats.empty(),
          btDispositionsConstructives: RiskFamilyQuadrantStats.empty(),
          btExploitationMaintenance: RiskFamilyQuadrantStats.empty(),
        ),
        top5Hta: const [],
        top5Bt: const [],
        totalZonesClassees: 1,
        totalLocauxMt: 1,
        totalLocauxBt: 2,
        totalLocauxGe: 1,
        locauxMtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        locauxBtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        mtCategoriesCrossRows: const [],
        btCategoriesCrossRows: const [],
        mtTotalCrossRow: const CategoryCrossAuditRow(categoryName: 'TOTAL MT', equipementsCount: 0, ncCount: 0, critiquesCount: 0, majeuresCount: 0, pctOfTotalNc: 0, tauxCritique: 0, densite: 0),
        btTotalCrossRow: const CategoryCrossAuditRow(categoryName: 'TOTAL BT', equipementsCount: 0, ncCount: 0, critiquesCount: 0, majeuresCount: 0, pctOfTotalNc: 0, tauxCritique: 0, densite: 0),
        totalZonesAudit: 2,
        totalZonesClasseesCount: 1, // 50%
        totalLocauxAudit: 4,
        totalLocauxClassesCount: 3, // 75%
        totalEquipementsEligiblesIpIk: 10,
        totalEquipementsClassesIpIk: 7, // 70%
      );

      expect(result.totalEquipementsEligiblesIpIk, equals(10));
      expect(result.totalEquipementsClassesIpIk, equals(7));
      expect(result.equipementsIpIkAdequationRate, closeTo(70.0, 0.01));
      expect(result.equipementsIpIkAdequationRateStr, equals('70 %'));

      // Adéquation globale = (50% + 75% + 70%) / 3 = 195 / 3 = 65.0%
      expect(result.globalIpIkAdequationRate, closeTo(65.0, 0.01));
      expect(result.globalIpIkAdequationRateStr, equals('65 %'));
    });

    test('C - Cas limites IP/IK (dénominateurs nuls, pas de division par zéro)', () {
      final resultEmpty = TechnicalEnrichmentResult(
        missionId: 'm_empty',
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
        ipIkZoneItems: const [],
        riskFamilyMatrix: const RiskFamilyCrossMatrix(
          htaDispositionsConstructives: RiskFamilyQuadrantStats.empty(),
          htaExploitationMaintenance: RiskFamilyQuadrantStats.empty(),
          btDispositionsConstructives: RiskFamilyQuadrantStats.empty(),
          btExploitationMaintenance: RiskFamilyQuadrantStats.empty(),
        ),
        top5Hta: const [],
        top5Bt: const [],
        totalZonesClassees: 0,
        totalLocauxMt: 0,
        totalLocauxBt: 0,
        totalLocauxGe: 0,
        locauxMtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        locauxBtFindings: const LocauxFindingsStats(dispoConstructives: 0, conditionsExploitation: 0),
        mtCategoriesCrossRows: const [],
        btCategoriesCrossRows: const [],
        mtTotalCrossRow: const CategoryCrossAuditRow(categoryName: 'TOTAL MT', equipementsCount: 0, ncCount: 0, critiquesCount: 0, majeuresCount: 0, pctOfTotalNc: 0, tauxCritique: 0, densite: 0),
        btTotalCrossRow: const CategoryCrossAuditRow(categoryName: 'TOTAL BT', equipementsCount: 0, ncCount: 0, critiquesCount: 0, majeuresCount: 0, pctOfTotalNc: 0, tauxCritique: 0, densite: 0),
        totalZonesAudit: 0,
        totalZonesClasseesCount: 0,
        totalLocauxAudit: 0,
        totalLocauxClassesCount: 0,
        totalEquipementsEligiblesIpIk: 0,
        totalEquipementsClassesIpIk: 0,
      );

      expect(resultEmpty.equipementsIpIkAdequationRate, equals(0.0));
      expect(resultEmpty.globalIpIkAdequationRate, equals(0.0));
      expect(resultEmpty.globalIpIkAdequationRateStr, equals('0 %'));
    });
  });

  CriticalityStats makeCriticalityStats(int critique, int majeure, int mineure) {
    final total = critique + majeure + mineure;
    return CriticalityStats(
      critique: critique,
      majeure: majeure,
      mineure: mineure,
      total: total,
      pctCritique: total > 0 ? (critique / total) * 100.0 : 0.0,
      pctMajeure: total > 0 ? (majeure / total) * 100.0 : 0.0,
      pctMineure: total > 0 ? (mineure / total) * 100.0 : 0.0,
    );
  }

  group('Axe III — Criticité : Moteur Textuel Dynamique et Pédagogique', () {
    test('Cas 0 non-conformité (installation entièrement conforme)', () {
      final cStats = makeCriticalityStats(0, 0, 0);
      final text = PdfExecutiveSummaryBuilder.generateCriticalityExplanationForTesting(cStats, 0);

      expect(text, contains("L'ensemble des vérifications n'a révélé aucune non-conformité"));
      expect(text, isNot(contains('NaN')));
      expect(text, isNot(contains('10 à 15 %')));
    });

    test('Cas 100% Critique (aucun écart majeur ni mineur)', () {
      final cStats = makeCriticalityStats(5, 0, 0);
      final text = PdfExecutiveSummaryBuilder.generateCriticalityExplanationForTesting(cStats, 5);

      expect(text, contains("Sur l'ensemble des 5 non-conformités recensées, la totalité des écarts relève de la criticité Critique, soit 100,0 % du total."));
      expect(text, contains("L'intégralité des non-conformités (100,0 %) relève des niveaux de gravité les plus élevés (Critique et Majeure)"));
      expect(text, isNot(contains('10 à 15 %')));
    });

    test('Cas 100% Mineure', () {
      final cStats = makeCriticalityStats(0, 0, 8);
      final text = PdfExecutiveSummaryBuilder.generateCriticalityExplanationForTesting(cStats, 8);

      expect(text, contains("Sur l'ensemble des 8 non-conformités recensées, la totalité des écarts relève de la criticité Mineure, soit 100,0 % du total."));
      expect(text, contains("L'ensemble des écarts constatés relève exclusivement de la criticité Mineure, concernant principalement des dispositions constructives secondaires"));
    });

    test('Cas Répartition Critique dominante avec Majeures (0 mineure)', () {
      // 10 Critiques (71.4%), 4 Majeures (28.6%), 0 Mineure
      final cStats = makeCriticalityStats(10, 4, 0);
      final text = PdfExecutiveSummaryBuilder.generateCriticalityExplanationForTesting(cStats, 14);

      expect(text, contains("10 relèvent de la criticité Critique (71,4 %) et 4 relèvent de la criticité Majeure (28,6 %)"));
      expect(text, contains("La répartition est dominée par la criticité Critique (71,4 %), qui constitue la part prépondérante des observations."));
      expect(text, contains("L'intégralité des non-conformités (100,0 %) relève des niveaux de gravité les plus élevés"));
      expect(text, isNot(contains('10 à 15 %')));
    });

    test('Cas 3 niveaux présents avec Majeure dominante', () {
      // 2 Critiques (20%), 5 Majeures (50%), 3 Mineures (30%)
      final cStats = makeCriticalityStats(2, 5, 3);
      final text = PdfExecutiveSummaryBuilder.generateCriticalityExplanationForTesting(cStats, 10);

      expect(text, contains("2 relèvent de la criticité Critique (20,0 %), 5 relèvent de la criticité Majeure (50,0 %) et 3 relèvent de la criticité Mineure (30,0 %)"));
      expect(text, contains("La répartition est dominée par la criticité Majeure (50,0 %)"));
      expect(text, contains("Les écarts à niveau de gravité élevé (criticités Critique et Majeure) regroupent au total 7 non-conformités, soit 70,0 % de l'ensemble des observations"));
    });

    test('Cas Égalité parfaite entre deux niveaux prépondérants', () {
      // 6 Majeures (50%), 6 Mineures (50%), 0 Critique
      final cStats = makeCriticalityStats(0, 6, 6);
      final text = PdfExecutiveSummaryBuilder.generateCriticalityExplanationForTesting(cStats, 12);

      expect(text, contains("6 relèvent de la criticité Majeure (50,0 %) et 6 relèvent de la criticité Mineure (50,0 %)"));
      expect(text, contains("Les criticités Majeure (50,0 %) et Mineure (50,0 %) représentent des volumes équivalents et prépondérants."));
    });
  });

  group('Axe IV — Facteurs de Risque Prépondérants : Toutes Familles sans « Autres »', () {
    test('Quadrant avec plusieurs familles : suppression de Autres et conservation de allFamilies', () {
      final families = [
        const RiskFamilyStatItem(famille: 'Contact direct', constats: 15, part: 50.0, formattedPart: '50,0 %'),
        const RiskFamilyStatItem(famille: 'Surcharge thermique', constats: 9, part: 30.0, formattedPart: '30,0 %'),
        const RiskFamilyStatItem(famille: 'Protection contre les surintensités', constats: 3, part: 10.0, formattedPart: '10,0 %'),
        const RiskFamilyStatItem(famille: 'Repérage et identification', constats: 2, part: 6.7, formattedPart: '6,7 %'),
        const RiskFamilyStatItem(famille: 'Mise à la terre', constats: 1, part: 3.3, formattedPart: '3,3 %'),
        const RiskFamilyStatItem(famille: 'Isolement dégradé', constats: 1, part: 3.3, formattedPart: '3,3 %'),
      ];

      final quadrant = RiskFamilyQuadrantStats(
        domainTitle: 'BT',
        sectionTitle: 'EXPLOITATION ET MAINTENANCE',
        totalConstats: 31,
        counts: {
          'Contact direct': 15,
          'Surcharge thermique': 9,
          'Protection contre les surintensités': 3,
          'Repérage et identification': 2,
          'Mise à la terre': 1,
          'Isolement dégradé': 1,
        },
        topFamilies: families.take(5).toList(),
        allFamilies: families,
      );

      expect(quadrant.allFamilies.length, equals(6));
      expect(quadrant.sumAllOccurrences, equals(31));

      // Création de la table PDF
      final matrix = RiskFamilyCrossMatrix(
        htaDispositionsConstructives: const RiskFamilyQuadrantStats.empty(),
        htaExploitationMaintenance: const RiskFamilyQuadrantStats.empty(),
        btDispositionsConstructives: const RiskFamilyQuadrantStats.empty(),
        btExploitationMaintenance: quadrant,
      );

      final widget = PdfExecutiveSummaryBuilder.buildRiskFamilyMatrixTableForTesting(matrix);
      expect(widget, isA<pw.Widget>());
    });

    test('Quadrant vide : affichage propre sans crash', () {
      const quadrantEmpty = RiskFamilyQuadrantStats.empty();
      final matrixEmpty = RiskFamilyCrossMatrix(
        htaDispositionsConstructives: quadrantEmpty,
        htaExploitationMaintenance: quadrantEmpty,
        btDispositionsConstructives: quadrantEmpty,
        btExploitationMaintenance: quadrantEmpty,
      );

      final widget = PdfExecutiveSummaryBuilder.buildRiskFamilyMatrixTableForTesting(matrixEmpty);
      expect(widget, isA<pw.Widget>());
    });
  });
}
