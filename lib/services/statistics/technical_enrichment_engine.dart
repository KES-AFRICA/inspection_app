// lib/services/statistics/technical_enrichment_engine.dart

import '../../models/audit_installations_electriques.dart';
import '../../models/classement_locaux.dart';
import '../../models/classement_zone.dart';
import '../../models/mesures_essais.dart';
import '../hive_service.dart';
import '../ip_ik_evaluator_service.dart';
import 'audit_finding.dart';
import 'canonical_defect_category_registry.dart';
import 'canonical_risk_family_registry.dart';
import 'domain_entity_instance.dart';
import 'mission_domain_inventory_engine.dart';

/// Indicateur de sécurité pour les organes de coupure de tête par catégorie de tableau BT.
class CoupureTeteStats {
  final DomainObjectType category;
  final int totalEquipments;
  final int presents;
  final int absents;

  const CoupureTeteStats({
    required this.category,
    required this.totalEquipments,
    required this.presents,
    required this.absents,
  });

  double get percentage =>
      totalEquipments > 0 ? (presents / totalEquipments) * 100.0 : 0.0;

  String get ratioStr => '$presents / $totalEquipments';
  String get formattedPercentage =>
      '${percentage.toStringAsFixed(1).replaceAll('.', ',')} %';
}

/// Indicateur de traçabilité des sources d'alimentation par catégorie de tableau BT.
class SourceAlimentationStats {
  final DomainObjectType category;
  final int totalEquipments;
  final int identifiees;
  final int nonIdentifiees;

  const SourceAlimentationStats({
    required this.category,
    required this.totalEquipments,
    required this.identifiees,
    required this.nonIdentifiees,
  });

  double get percentage =>
      totalEquipments > 0 ? (identifiees / totalEquipments) * 100.0 : 0.0;

  String get ratioStr => '$identifiees / $totalEquipments';
  String get formattedPercentage =>
      '${percentage.toStringAsFixed(1).replaceAll('.', ',')} %';
}

/// Indicateur de présence de parafoudre par catégorie de tableau BT.
class ParafoudreStats {
  final DomainObjectType category;
  final int totalEquipments;
  final int avecParafoudre;
  final int sansParafoudre;

  const ParafoudreStats({
    required this.category,
    required this.totalEquipments,
    required this.avecParafoudre,
    required this.sansParafoudre,
  });

  double get percentage =>
      totalEquipments > 0 ? (avecParafoudre / totalEquipments) * 100.0 : 0.0;

  String get ratioStr => '$avecParafoudre / $totalEquipments';
  String get formattedPercentage =>
      '${percentage.toStringAsFixed(1).replaceAll('.', ',')} %';
}

/// Résultat d'adéquation entre le Pouvoir de Coupure (Pdc) et le courant de court-circuit (Icc).
class AdequationIccPdcStats {
  final DomainObjectType? category;
  final int totalElements;
  final int evaluables;
  final int conformes;
  final int nonConformes;
  final int nonRenseignes;

  const AdequationIccPdcStats({
    this.category,
    required this.totalElements,
    required this.evaluables,
    required this.conformes,
    required this.nonConformes,
    required this.nonRenseignes,
  });

  double get complianceRate =>
      evaluables > 0 ? (conformes / evaluables) * 100.0 : 0.0;

  String get formattedComplianceRate => evaluables > 0
      ? '${complianceRate.toStringAsFixed(1).replaceAll('.', ',')} %'
      : 'Non évaluable';

  String get summaryStr => evaluables > 0
      ? '$conformes / $evaluables ($formattedComplianceRate)'
      : 'Non renseigné';
}

/// Ligne de distribution des marques pour une catégorie de tableau BT.
class MarquesMatrixRow {
  final DomainObjectType category;
  final Map<String, int> organeDeTete;
  final Map<String, int> departs;
  final Map<String, int> circuitsTerminaux;

  const MarquesMatrixRow({
    required this.category,
    required this.organeDeTete,
    required this.departs,
    required this.circuitsTerminaux,
  });
}

/// Ligne de distribution des courbes de protection pour une catégorie de tableau BT.
class CourbesMatrixRow {
  final DomainObjectType category;
  final Map<String, int> organeDeTete;
  final Map<String, int> departs;
  final Map<String, int> circuitsTerminaux;

  const CourbesMatrixRow({
    required this.category,
    required this.organeDeTete,
    required this.departs,
    required this.circuitsTerminaux,
  });
}

/// Synthèse des câbles par matériau conducteur (Alu vs Cuivre) et sections.
class CablesSectionBreakdown {
  final String metal;
  final int count;
  final double percentageOfTotal;
  final Map<String, int> sectionsCount;

  const CablesSectionBreakdown({
    required this.metal,
    required this.count,
    required this.percentageOfTotal,
    required this.sectionsCount,
  });
}

/// Ligne de distribution des câbles pour une catégorie de tableau BT.
class CablesMatrixRow {
  final DomainObjectType category;
  final Map<String, CablesSectionBreakdown> departsBreakdown;
  final Map<String, CablesSectionBreakdown> circuitsTerminauxBreakdown;

  const CablesMatrixRow({
    required this.category,
    required this.departsBreakdown,
    required this.circuitsTerminauxBreakdown,
  });
}

/// Ligne de conformité IP/IK par zone ou emplacement classé.
class IpIkZoneItem {
  final String zoneNom;
  final String? ipRequis;
  final String? ikRequis;
  final int totalEquipements;
  final int conformes;
  final int nonConformes;
  final int nonRenseignes;

  const IpIkZoneItem({
    required this.zoneNom,
    this.ipRequis,
    this.ikRequis,
    required this.totalEquipements,
    required this.conformes,
    required this.nonConformes,
    required this.nonRenseignes,
  });

  int get evaluables => conformes + nonConformes;
  double get complianceRate =>
      evaluables > 0 ? (conformes / evaluables) * 100.0 : 0.0;

  String get formattedRate => evaluables > 0
      ? '${complianceRate.toStringAsFixed(1).replaceAll('.', ',')} %'
      : (nonRenseignes > 0 ? 'Non renseigné' : 'Aucun équipement');
}

/// Décompte unitaire exhaustif des essais et mesures métrologiques.
class EssaisCoverageStats {
  final int prisesTerreCount;
  final int testDdrCount;
  final int mesureIsolementCount;
  final int testCpiCount;
  final int continuitePeCount;
  final int demarrageGeCount;
  final int arretUrgenceCount;

  const EssaisCoverageStats({
    required this.prisesTerreCount,
    required this.testDdrCount,
    required this.mesureIsolementCount,
    required this.testCpiCount,
    required this.continuitePeCount,
    required this.demarrageGeCount,
    required this.arretUrgenceCount,
  });

  int get totalEssais =>
      prisesTerreCount +
      testDdrCount +
      mesureIsolementCount +
      testCpiCount +
      continuitePeCount +
      demarrageGeCount +
      arretUrgenceCount;
}

/// Matrice à 4 quadrants croisant Domaine de tension x Nature de contrôle avec les 5 familles de risques canoniques.
class RiskFamilyCrossMatrix {
  final Map<String, int> htaDispositionsConstructives;
  final Map<String, int> htaExploitationMaintenance;
  final Map<String, int> btDispositionsConstructives;
  final Map<String, int> btExploitationMaintenance;

  const RiskFamilyCrossMatrix({
    required this.htaDispositionsConstructives,
    required this.htaExploitationMaintenance,
    required this.btDispositionsConstructives,
    required this.btExploitationMaintenance,
  });

  int get totalHtaDispo =>
      htaDispositionsConstructives.values.fold(0, (s, e) => s + e);
  int get totalHtaExploit =>
      htaExploitationMaintenance.values.fold(0, (s, e) => s + e);
  int get totalBtDispo =>
      btDispositionsConstructives.values.fold(0, (s, e) => s + e);
  int get totalBtExploit =>
      btExploitationMaintenance.values.fold(0, (s, e) => s + e);

  int get totalHta => totalHtaDispo + totalHtaExploit;
  int get totalBt => totalBtDispo + totalBtExploit;
  int get totalGlobal => totalHta + totalBt;
}

/// Élément du Top des défaillances pour un domaine donné.
class TopDefectDomainItem {
  final String title;
  final int count;
  final double percentageOfDomain;

  const TopDefectDomainItem({
    required this.title,
    required this.count,
    required this.percentageOfDomain,
  });
}

/// Décompte des constats sur les locaux d'un domaine (Dispositions constructives vs Conditions d'exploitation).
class LocauxFindingsStats {
  final int dispoConstructives;
  final int conditionsExploitation;

  const LocauxFindingsStats({
    required this.dispoConstructives,
    required this.conditionsExploitation,
  });

  int get total => dispoConstructives + conditionsExploitation;
  String get dispoConstructivesPctStr =>
      total > 0 ? '${(dispoConstructives / total * 100).toStringAsFixed(1).replaceAll('.', ',')} %' : '0,0 %';
  String get conditionsExploitationPctStr =>
      total > 0 ? '${(conditionsExploitation / total * 100).toStringAsFixed(1).replaceAll('.', ',')} %' : '0,0 %';
}

/// Ligne de synthèse d'une catégorie d'équipements pour les tableaux de conformité croisée.
class CategoryCrossAuditRow {
  final String categoryName;
  final int equipementsCount;
  final int ncCount;
  final int critiquesCount;
  final int majeuresCount;
  final double pctOfTotalNc;
  final double tauxCritique;
  final double densite;

  const CategoryCrossAuditRow({
    required this.categoryName,
    required this.equipementsCount,
    required this.ncCount,
    required this.critiquesCount,
    required this.majeuresCount,
    required this.pctOfTotalNc,
    required this.tauxCritique,
    required this.densite,
  });

  String get pctOfTotalNcStr => '${pctOfTotalNc.toStringAsFixed(1).replaceAll('.', ',')} %';
  String get tauxCritiqueStr => ncCount > 0 ? '${tauxCritique.toStringAsFixed(1).replaceAll('.', ',')} %' : '0,0 %';
  String get densiteStr => densite.toStringAsFixed(1).replaceAll('.', ',');
}

/// Résultat complet de l'enrichissement technique et analytique d'une mission.
class TechnicalEnrichmentResult {
  final String missionId;
  final EssaisCoverageStats essaisCoverage;
  final Map<DomainObjectType, CoupureTeteStats> coupureTeteStats;
  final Map<DomainObjectType, SourceAlimentationStats> sourceStats;
  final Map<DomainObjectType, ParafoudreStats> parafoudreStats;
  final Map<DomainObjectType, AdequationIccPdcStats> adequationIccPdcStats;
  final List<MarquesMatrixRow> marquesMatrix;
  final List<CourbesMatrixRow> courbesMatrix;
  final Map<DomainObjectType, AdequationIccPdcStats> pdcDepartStats;
  final Map<DomainObjectType, AdequationIccPdcStats> pdcTerminalStats;
  final List<CablesMatrixRow> cablesMatrix;
  final List<IpIkZoneItem> ipIkZoneItems;
  final RiskFamilyCrossMatrix riskFamilyMatrix;
  final List<TopDefectDomainItem> top5Hta;
  final List<TopDefectDomainItem> top5Bt;
  final int totalZonesClassees;
  final int totalLocauxMt;
  final int totalLocauxBt;
  final int totalLocauxGe;
  final LocauxFindingsStats locauxMtFindings;
  final LocauxFindingsStats locauxBtFindings;
  final List<CategoryCrossAuditRow> mtCategoriesCrossRows;
  final List<CategoryCrossAuditRow> btCategoriesCrossRows;
  final CategoryCrossAuditRow mtTotalCrossRow;
  final CategoryCrossAuditRow btTotalCrossRow;

  const TechnicalEnrichmentResult({
    required this.missionId,
    required this.essaisCoverage,
    required this.coupureTeteStats,
    required this.sourceStats,
    required this.parafoudreStats,
    required this.adequationIccPdcStats,
    required this.marquesMatrix,
    required this.courbesMatrix,
    required this.pdcDepartStats,
    required this.pdcTerminalStats,
    required this.cablesMatrix,
    required this.ipIkZoneItems,
    required this.riskFamilyMatrix,
    required this.top5Hta,
    required this.top5Bt,
    required this.totalZonesClassees,
    required this.totalLocauxMt,
    required this.totalLocauxBt,
    required this.totalLocauxGe,
    required this.locauxMtFindings,
    required this.locauxBtFindings,
    required this.mtCategoriesCrossRows,
    required this.btCategoriesCrossRows,
    required this.mtTotalCrossRow,
    required this.btTotalCrossRow,
  });

  int get globalCoupureTetePresents =>
      coupureTeteStats.values.fold(0, (s, e) => s + e.presents);
  int get globalCoupureTeteTotal =>
      coupureTeteStats.values.fold(0, (s, e) => s + e.totalEquipments);
  double get globalCoupureTetePct => globalCoupureTeteTotal > 0
      ? (globalCoupureTetePresents / globalCoupureTeteTotal) * 100.0
      : 0.0;
  String get globalCoupureTeteRatio =>
      '$globalCoupureTetePresents / $globalCoupureTeteTotal';

  int get globalSourceIdentified =>
      sourceStats.values.fold(0, (s, e) => s + e.identifiees);
  int get globalSourceTotal =>
      sourceStats.values.fold(0, (s, e) => s + e.totalEquipments);
  double get globalSourcePct => globalSourceTotal > 0
      ? (globalSourceIdentified / globalSourceTotal) * 100.0
      : 0.0;
  String get globalSourceRatio =>
      '$globalSourceIdentified / $globalSourceTotal';

  int get globalParafoudrePresents =>
      parafoudreStats.values.fold(0, (s, e) => s + e.avecParafoudre);
  int get globalParafoudreTotal =>
      parafoudreStats.values.fold(0, (s, e) => s + e.totalEquipments);
  double get globalParafoudrePct => globalParafoudreTotal > 0
      ? (globalParafoudrePresents / globalParafoudreTotal) * 100.0
      : 0.0;
  String get globalParafoudreRatio =>
      '$globalParafoudrePresents / $globalParafoudreTotal';

  int get globalAdequationTeteConformes =>
      adequationIccPdcStats.values.fold(0, (s, e) => s + e.conformes);
  int get globalAdequationTeteEvalues =>
      adequationIccPdcStats.values.fold(0, (s, e) => s + e.evaluables);
  int get globalAdequationTeteNonEvalues =>
      adequationIccPdcStats.values.fold(0, (s, e) => s + e.nonRenseignes);
  double get globalAdequationTetePct => globalAdequationTeteEvalues > 0
      ? (globalAdequationTeteConformes / globalAdequationTeteEvalues) * 100.0
      : 0.0;
  String get globalAdequationTeteRatio =>
      '$globalAdequationTeteConformes / $globalAdequationTeteEvalues';

  int get totalTgbt => coupureTeteStats[DomainObjectType.tgbt]?.totalEquipments ?? 0;
  int get totalArmoires => coupureTeteStats[DomainObjectType.armoire]?.totalEquipments ?? 0;
  int get totalCoffrets => coupureTeteStats[DomainObjectType.coffret]?.totalEquipments ?? 0;
  int get totalInverseurs => coupureTeteStats[DomainObjectType.inverseur]?.totalEquipments ?? 0;

  String get globalIpIkAdequationRateStr {
    final totalConformes = ipIkZoneItems.fold(0, (s, e) => s + e.conformes);
    final totalEvaluables = ipIkZoneItems.fold(0, (s, e) => s + e.evaluables);
    if (totalEvaluables > 0) {
      final pct = (totalConformes / totalEvaluables) * 100.0;
      return '${pct.toStringAsFixed(1).replaceAll('.', ',')} %';
    }
    return '0,0 % (Déficit de données terrain : 100 % non renseignés)';
  }

  Map<String, int> get globalMarquesDeTete {
    final res = <String, int>{};
    for (final row in marquesMatrix) {
      for (final e in row.organeDeTete.entries) {
        res[e.key] = (res[e.key] ?? 0) + e.value;
      }
    }
    return res;
  }
}

/// Moteur principal d'analyse technique et d'enrichissement statistique.
class TechnicalEnrichmentEngine {
  /// Calcule l'intégralité des indicateurs et matrices techniques pour la mission.
  static TechnicalEnrichmentResult compute(
    String missionId,
    MissionDomainInventory domainInventory,
    AuditFindingInventory findingInventory,
  ) {
    // 1. Décompte unitaire des Essais et Mesures
    MesuresEssais? mesures;
    try {
      mesures = HiveService.getMesuresEssaisByMissionId(missionId);
    } catch (_) {
      mesures = null;
    }
    final essaisCoverage = _computeEssaisCoverage(mesures);

    // 2. Décompte des locaux par typologie
    int locauxMt = domainInventory
        .getInstancesByCategory(DomainObjectType.localMT)
        .length;
    int locauxBt = domainInventory
        .getInstancesByCategory(DomainObjectType.localBT)
        .length;
    int locauxGe = domainInventory
        .getInstancesByCategory(DomainObjectType.localGE)
        .length;

    // 3. Indicateurs de sécurité BT (Inverseur, TGBT, Armoire, Coffret)
    final btCategories = [
      DomainObjectType.inverseur,
      DomainObjectType.tgbt,
      DomainObjectType.armoire,
      DomainObjectType.coffret,
    ];

    final coupureMap = <DomainObjectType, CoupureTeteStats>{};
    final sourceMap = <DomainObjectType, SourceAlimentationStats>{};
    final parafoudreMap = <DomainObjectType, ParafoudreStats>{};
    final adequationTeteMap = <DomainObjectType, AdequationIccPdcStats>{};
    final pdcDepartMap = <DomainObjectType, AdequationIccPdcStats>{};
    final pdcTerminalMap = <DomainObjectType, AdequationIccPdcStats>{};
    final marquesRows = <MarquesMatrixRow>[];
    final courbesRows = <CourbesMatrixRow>[];
    final cablesRows = <CablesMatrixRow>[];

    for (final cat in btCategories) {
      final instances = domainInventory.getInstancesByCategory(cat);
      final coffrets = instances
          .map((i) => i.rawModelRef)
          .whereType<CoffretArmoire>()
          .toList();

      final total = coffrets.length;

      // A. Coupure de tête
      int coupurePres = 0;
      for (final c in coffrets) {
        if (_hasOrganeCoupureTete(c)) {
          coupurePres++;
        }
      }
      coupureMap[cat] = CoupureTeteStats(
        category: cat,
        totalEquipments: total,
        presents: coupurePres,
        absents: total - coupurePres,
      );

      // B. Identification source
      int sourceIdent = 0;
      for (final c in coffrets) {
        if (_hasSourceIdentifiee(c)) {
          sourceIdent++;
        }
      }
      sourceMap[cat] = SourceAlimentationStats(
        category: cat,
        totalEquipments: total,
        identifiees: sourceIdent,
        nonIdentifiees: total - sourceIdent,
      );

      // C. Présence parafoudre
      int paraCount = 0;
      for (final c in coffrets) {
        if (c.presenceParafoudre == true) {
          paraCount++;
        }
      }
      parafoudreMap[cat] = ParafoudreStats(
        category: cat,
        totalEquipments: total,
        avecParafoudre: paraCount,
        sansParafoudre: total - paraCount,
      );

      // D. Adéquation Icc / Pdc sur organe de tête
      adequationTeteMap[cat] = _computeAdequationTete(cat, coffrets);

      // E. Adéquation Icc / Pdc sur départs et circuits terminaux
      pdcDepartMap[cat] = _computeAdequationDeparts(cat, coffrets);
      pdcTerminalMap[cat] = _computeAdequationTerminaux(cat, coffrets);

      // F. Diversification des marques (Tête, Départs, Terminaux)
      final tMarques = <String, int>{};
      final dMarques = <String, int>{};
      final ctMarques = <String, int>{};

      for (final c in coffrets) {
        final tm = _normalizeBrand(c.protectionTete?.marqueDisjoncteur);
        if (tm != null) tMarques[tm] = (tMarques[tm] ?? 0) + 1;

        if (c.departures != null) {
          for (final dep in c.departures!) {
            final dm = _normalizeBrand(dep.marque);
            if (dm != null) dMarques[dm] = (dMarques[dm] ?? 0) + 1;
          }
        }

        if (c.terminalCircuits != null) {
          for (final ct in c.terminalCircuits!) {
            final ctm = _normalizeBrand(ct.marque);
            if (ctm != null) ctMarques[ctm] = (ctMarques[ctm] ?? 0) + 1;
          }
        }
      }

      marquesRows.add(
        MarquesMatrixRow(
          category: cat,
          organeDeTete: tMarques,
          departs: dMarques,
          circuitsTerminaux: ctMarques,
        ),
      );

      // G. Courbes de protection (Tête, Départs, Terminaux)
      final tCourbes = <String, int>{};
      final dCourbes = <String, int>{};
      final ctCourbes = <String, int>{};

      for (final c in coffrets) {
        final tc = _normalizeCourbe(c.protectionTete?.courbe);
        if (tc != null) tCourbes[tc] = (tCourbes[tc] ?? 0) + 1;

        if (c.departures != null) {
          for (final dep in c.departures!) {
            final dc = _normalizeCourbe(dep.courbe);
            if (dc != null) dCourbes[dc] = (dCourbes[dc] ?? 0) + 1;
          }
        }

        if (c.terminalCircuits != null) {
          for (final ct in c.terminalCircuits!) {
            final ctc = _normalizeCourbe(ct.courbe);
            if (ctc != null) ctCourbes[ctc] = (ctCourbes[ctc] ?? 0) + 1;
          }
        }
      }

      courbesRows.add(
        CourbesMatrixRow(
          category: cat,
          organeDeTete: tCourbes,
          departs: dCourbes,
          circuitsTerminaux: ctCourbes,
        ),
      );

      // H. Câbles (Alu vs Cuivre et Sections)
      final dCables = _computeCablesBreakdown(
        coffrets
            .expand((c) => c.departures ?? <DepartEquipement>[])
            .map((d) => _CableData(d.natureCable, d.sectionCable)),
      );
      final ctCables = _computeCablesBreakdown(
        coffrets
            .expand((c) => c.terminalCircuits ?? <CircuitTerminalEquipement>[])
            .map((ct) => _CableData(ct.natureCable, ct.sectionCable)),
      );

      cablesRows.add(
        CablesMatrixRow(
          category: cat,
          departsBreakdown: dCables,
          circuitsTerminauxBreakdown: ctCables,
        ),
      );
    }

    // 4. Adéquation Classement des zones vs Indice IP/IK des équipements
    final ipIkZones = _computeIpIkZones(missionId, domainInventory);
    int totalZonesCount = 0;
    try {
      totalZonesCount =
          HiveService.getClassementsZonesByMissionId(missionId).length +
          HiveService.getEmplacementsByMissionId(missionId).length;
    } catch (_) {
      totalZonesCount = 0;
    }

    // 5. Matrice 4 quadrants des Familles de risques
    final riskMatrix = _computeRiskFamilyMatrix(findingInventory.findings);

    // 6. Top 5 des défaillances HTA et BT
    final top5Hta = _computeTopDefectsForDomain(
      findingInventory.findings,
      TensionDomain.mt,
    );
    final top5Bt = _computeTopDefectsForDomain(
      findingInventory.findings,
      TensionDomain.bt,
    );

    // 7. Décompte des constats sur les locaux (Dispositions constructives vs Conditions d'exploitation)
    int mtLocauxDispo = 0;
    int mtLocauxExploit = 0;
    for (final inst in domainInventory.getInstancesByCategory(DomainObjectType.localMT)) {
      for (final f in inst.findings) {
        if (_isDispositionConstructiveFinding(f)) {
          mtLocauxDispo++;
        } else {
          mtLocauxExploit++;
        }
      }
    }
    final locauxMtFindings = LocauxFindingsStats(
      dispoConstructives: mtLocauxDispo,
      conditionsExploitation: mtLocauxExploit,
    );

    int btLocauxDispo = 0;
    int btLocauxExploit = 0;
    final btLocauxInstances = [
      ...domainInventory.getInstancesByCategory(DomainObjectType.localBT),
      ...domainInventory.getInstancesByCategory(DomainObjectType.localGE),
    ];
    for (final inst in btLocauxInstances) {
      for (final f in inst.findings) {
        if (_isDispositionConstructiveFinding(f)) {
          btLocauxDispo++;
        } else {
          btLocauxExploit++;
        }
      }
    }
    final locauxBtFindings = LocauxFindingsStats(
      dispoConstructives: btLocauxDispo,
      conditionsExploitation: btLocauxExploit,
    );

    // 8. Lignes de conformité croisée par catégorie pour Moyenne Tension
    final totalNcMt = findingInventory.findings.where((f) => f.tensionDomain == TensionDomain.mt).length;
    final totalMissionNc = findingInventory.classifiedCount > 0 ? findingInventory.classifiedCount : findingInventory.totalFindings;
    final mtCatRows = <CategoryCrossAuditRow>[];

    CategoryCrossAuditRow buildCategoryRow(
      String name,
      List<DomainEntityInstance> instances,
      int totalNcDenominator,
    ) {
      final eqCount = instances.length;
      final findings = instances.expand((i) => i.findings).toList();
      final ncCount = findings.length;
      final critCount = findings.where((f) => f.criticality.toLowerCase().contains('critique')).length;
      final majCount = findings.where((f) => f.criticality.toLowerCase().contains('majeur')).length;
      final pctOfTotal = totalNcDenominator > 0 ? (ncCount / totalNcDenominator) * 100.0 : 0.0;
      final tauxCrit = ncCount > 0 ? (critCount / ncCount) * 100.0 : 0.0;
      final densite = eqCount > 0 ? (ncCount / eqCount) : 0.0;

      return CategoryCrossAuditRow(
        categoryName: name,
        equipementsCount: eqCount,
        ncCount: ncCount,
        critiquesCount: critCount,
        majeuresCount: majCount,
        pctOfTotalNc: pctOfTotal,
        tauxCritique: tauxCrit,
        densite: densite,
      );
    }

    mtCatRows.add(
      buildCategoryRow(
        'Locaux techniques',
        domainInventory.getInstancesByCategory(DomainObjectType.localMT),
        totalMissionNc,
      ),
    );
    mtCatRows.add(
      buildCategoryRow(
        'Cellules',
        domainInventory.getInstancesByCategory(DomainObjectType.celluleMT),
        totalMissionNc,
      ),
    );
    mtCatRows.add(
      buildCategoryRow(
        'Transformateurs',
        domainInventory.getInstancesByCategory(DomainObjectType.transformateurMTBT),
        totalMissionNc,
      ),
    );

    final mtTotalEq = mtCatRows.fold(0, (s, r) => s + r.equipementsCount);
    final mtTotalCrit = mtCatRows.fold(0, (s, r) => s + r.critiquesCount);
    final mtTotalMaj = mtCatRows.fold(0, (s, r) => s + r.majeuresCount);
    final mtTotalNc = mtCatRows.fold(0, (s, r) => s + r.ncCount);
    final mtTotalCrossRow = CategoryCrossAuditRow(
      categoryName: 'TOTAL MOYENNE TENSION',
      equipementsCount: mtTotalEq,
      ncCount: mtTotalNc,
      critiquesCount: mtTotalCrit,
      majeuresCount: mtTotalMaj,
      pctOfTotalNc: totalMissionNc > 0 ? (mtTotalNc / totalMissionNc) * 100.0 : 0.0,
      tauxCritique: mtTotalNc > 0 ? (mtTotalCrit / mtTotalNc) * 100.0 : 0.0,
      densite: mtTotalEq > 0 ? (mtTotalNc / mtTotalEq) : 0.0,
    );

    // 9. Lignes de conformité croisée par catégorie pour Basse Tension
    final btCatRows = <CategoryCrossAuditRow>[];

    btCatRows.add(
      buildCategoryRow(
        'Locaux techniques GE',
        domainInventory.getInstancesByCategory(DomainObjectType.localGE),
        totalMissionNc,
      ),
    );
    btCatRows.add(
      buildCategoryRow(
        'Locaux techniques BT',
        domainInventory.getInstancesByCategory(DomainObjectType.localBT),
        totalMissionNc,
      ),
    );
    btCatRows.add(
      buildCategoryRow(
        'Inverseur',
        domainInventory.getInstancesByCategory(DomainObjectType.inverseur),
        totalMissionNc,
      ),
    );
    btCatRows.add(
      buildCategoryRow(
        'TGBT',
        domainInventory.getInstancesByCategory(DomainObjectType.tgbt),
        totalMissionNc,
      ),
    );
    btCatRows.add(
      buildCategoryRow(
        'Armoires',
        domainInventory.getInstancesByCategory(DomainObjectType.armoire),
        totalMissionNc,
      ),
    );
    btCatRows.add(
      buildCategoryRow(
        'Coffrets',
        domainInventory.getInstancesByCategory(DomainObjectType.coffret),
        totalMissionNc,
      ),
    );
    btCatRows.add(
      buildCategoryRow(
        'Prises de terre mesurées',
        domainInventory.getInstancesByCategory(DomainObjectType.priseTerre),
        totalMissionNc,
      ),
    );

    final btTotalEq = btCatRows.fold(0, (s, r) => s + r.equipementsCount);
    final btTotalCrit = btCatRows.fold(0, (s, r) => s + r.critiquesCount);
    final btTotalMaj = btCatRows.fold(0, (s, r) => s + r.majeuresCount);
    final btTotalNc = btCatRows.fold(0, (s, r) => s + r.ncCount);
    final btTotalCrossRow = CategoryCrossAuditRow(
      categoryName: 'TOTAL BASSE TENSION',
      equipementsCount: btTotalEq,
      ncCount: btTotalNc,
      critiquesCount: btTotalCrit,
      majeuresCount: btTotalMaj,
      pctOfTotalNc: totalMissionNc > 0 ? (btTotalNc / totalMissionNc) * 100.0 : 0.0,
      tauxCritique: btTotalNc > 0 ? (btTotalCrit / btTotalNc) * 100.0 : 0.0,
      densite: btTotalEq > 0 ? (btTotalNc / btTotalEq) : 0.0,
    );

    return TechnicalEnrichmentResult(
      missionId: missionId,
      essaisCoverage: essaisCoverage,
      coupureTeteStats: coupureMap,
      sourceStats: sourceMap,
      parafoudreStats: parafoudreMap,
      adequationIccPdcStats: adequationTeteMap,
      marquesMatrix: marquesRows,
      courbesMatrix: courbesRows,
      pdcDepartStats: pdcDepartMap,
      pdcTerminalStats: pdcTerminalMap,
      cablesMatrix: cablesRows,
      ipIkZoneItems: ipIkZones,
      riskFamilyMatrix: riskMatrix,
      top5Hta: top5Hta,
      top5Bt: top5Bt,
      totalZonesClassees: totalZonesCount,
      totalLocauxMt: locauxMt,
      totalLocauxBt: locauxBt,
      totalLocauxGe: locauxGe,
      locauxMtFindings: locauxMtFindings,
      locauxBtFindings: locauxBtFindings,
      mtCategoriesCrossRows: mtCatRows,
      btCategoriesCrossRows: btCatRows,
      mtTotalCrossRow: mtTotalCrossRow,
      btTotalCrossRow: btTotalCrossRow,
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  MÉTHODES INTERNES DE CALCUL
  // ──────────────────────────────────────────────────────────────

  static EssaisCoverageStats _computeEssaisCoverage(MesuresEssais? m) {
    if (m == null) {
      return const EssaisCoverageStats(
        prisesTerreCount: 0,
        testDdrCount: 0,
        mesureIsolementCount: 0,
        testCpiCount: 0,
        continuitePeCount: 0,
        demarrageGeCount: 0,
        arretUrgenceCount: 0,
      );
    }

    final hasDemarrage =
        m.essaiDemarrageAuto.observation?.trim().isNotEmpty == true;
    final hasArretUrg =
        m.testArretUrgence.observation?.trim().isNotEmpty == true;

    return EssaisCoverageStats(
      prisesTerreCount: m.prisesTerre.length,
      testDdrCount: m.essaisDeclenchement.length,
      mesureIsolementCount: m.essaisIsolement.length,
      testCpiCount: m.cpiTests.length,
      continuitePeCount: m.continuiteResistances.length,
      demarrageGeCount: hasDemarrage ? 1 : 0,
      arretUrgenceCount: hasArretUrg ? 1 : 0,
    );
  }

  static bool _hasOrganeCoupureTete(CoffretArmoire c) {
    if (c.protectionTete != null) {
      final t = c.protectionTete!.typeProtection.trim().toLowerCase();
      if (t.isNotEmpty &&
          t != 'aucun' &&
          t != 'sans' &&
          t != '-' &&
          t != 'non') {
        return true;
      }
      if (c.protectionTete!.calibre.trim().isNotEmpty &&
          c.protectionTete!.calibre.trim() != '-') {
        return true;
      }
      if (c.protectionTete!.pdcKA.trim().isNotEmpty &&
          c.protectionTete!.pdcKA.trim() != '-') {
        return true;
      }
    }
    return c.departPrisAvecProtection == true;
  }

  static bool _hasSourceIdentifiee(CoffretArmoire c) {
    if (c.sourceNomComplet != null && c.sourceNomComplet!.trim().isNotEmpty) {
      return true;
    }
    if (c.sourceEquipementId != null &&
        c.sourceEquipementId!.trim().isNotEmpty) {
      return true;
    }
    if (c.protectionTete?.sourceKnown?.trim().toLowerCase() == 'oui') {
      return true;
    }
    final pt = c.protectionTete;
    if (pt != null) {
      final src = pt.source.trim().toUpperCase();
      if (src.isNotEmpty &&
          src != '-' &&
          src != 'NC' &&
          src != 'INCONNU' &&
          src != 'NON RENSEIGNÉ') {
        return true;
      }
    }
    return false;
  }

  static double? _parseKA(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final clean = raw
        .trim()
        .toLowerCase()
        .replaceAll(',', '.')
        .replaceAll('ka', '')
        .replaceAll('a', '')
        .trim();
    return double.tryParse(clean);
  }

  static AdequationIccPdcStats _computeAdequationTete(
    DomainObjectType cat,
    List<CoffretArmoire> coffrets,
  ) {
    int total = coffrets.length;
    int evaluables = 0;
    int conformes = 0;
    int nonConformes = 0;
    int nonRenseignes = 0;

    for (final c in coffrets) {
      final pdc = _parseKA(c.protectionTete?.pdcKA);
      final icc = _parseKA(c.protectionTete?.icc3Max);

      if (pdc != null && icc != null) {
        evaluables++;
        if (pdc >= icc) {
          conformes++;
        } else {
          nonConformes++;
        }
      } else {
        nonRenseignes++;
      }
    }

    return AdequationIccPdcStats(
      category: cat,
      totalElements: total,
      evaluables: evaluables,
      conformes: conformes,
      nonConformes: nonConformes,
      nonRenseignes: nonRenseignes,
    );
  }

  static AdequationIccPdcStats _computeAdequationDeparts(
    DomainObjectType cat,
    List<CoffretArmoire> coffrets,
  ) {
    final deps =
        coffrets.expand((c) => c.departures ?? <DepartEquipement>[]).toList();
    int total = deps.length;
    int evaluables = 0;
    int conformes = 0;
    int nonConformes = 0;
    int nonRenseignes = 0;

    for (final d in deps) {
      final pdc = _parseKA(d.pdcKA);
      final icc = _parseKA(d.icc3Max);

      if (pdc != null && icc != null) {
        evaluables++;
        if (pdc >= icc) {
          conformes++;
        } else {
          nonConformes++;
        }
      } else {
        nonRenseignes++;
      }
    }

    return AdequationIccPdcStats(
      category: cat,
      totalElements: total,
      evaluables: evaluables,
      conformes: conformes,
      nonConformes: nonConformes,
      nonRenseignes: nonRenseignes,
    );
  }

  static AdequationIccPdcStats _computeAdequationTerminaux(
    DomainObjectType cat,
    List<CoffretArmoire> coffrets,
  ) {
    final cts = coffrets
        .expand((c) => c.terminalCircuits ?? <CircuitTerminalEquipement>[])
        .toList();
    int total = cts.length;
    int evaluables = 0;
    int conformes = 0;
    int nonConformes = 0;
    int nonRenseignes = 0;

    for (final ct in cts) {
      final pdc = _parseKA(ct.pdcKA);
      final icc = _parseKA(ct.icc3Max);

      if (pdc != null && icc != null) {
        evaluables++;
        if (pdc >= icc) {
          conformes++;
        } else {
          nonConformes++;
        }
      } else {
        nonRenseignes++;
      }
    }

    return AdequationIccPdcStats(
      category: cat,
      totalElements: total,
      evaluables: evaluables,
      conformes: conformes,
      nonConformes: nonConformes,
      nonRenseignes: nonRenseignes,
    );
  }

  static String? _normalizeBrand(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw.trim() == '-') return null;
    final s = raw.trim().toUpperCase();
    if (s.contains('SCHNEIDER') || s.contains('MERLIN')) return 'Schneider';
    if (s.contains('ABB')) return 'ABB';
    if (s.contains('LEGRAND')) return 'Legrand';
    if (s.contains('HAGER')) return 'Hager';
    if (s.contains('SIEMENS')) return 'Siemens';
    if (s.contains('EATON')) return 'Eaton';
    return raw.trim();
  }

  static String? _normalizeCourbe(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw.trim() == '-') return null;
    final s = raw.trim().toUpperCase();
    if (s.startsWith('COURBE ')) return s;
    if (s == 'B' || s == 'C' || s == 'D' || s == 'Z' || s == 'MA') {
      return 'Courbe $s';
    }
    return s;
  }

  static Map<String, CablesSectionBreakdown> _computeCablesBreakdown(
    Iterable<_CableData> cables,
  ) {
    final list = cables.toList();
    final total = list.length;
    if (total == 0) return {};

    final aluSections = <String, int>{};
    final cuSections = <String, int>{};
    int aluCount = 0;
    int cuCount = 0;

    for (final c in list) {
      final isAlu = _isAluminium(c.nature);
      final sec = _normalizeSection(c.section);

      if (isAlu) {
        aluCount++;
        aluSections[sec] = (aluSections[sec] ?? 0) + 1;
      } else {
        cuCount++;
        cuSections[sec] = (cuSections[sec] ?? 0) + 1;
      }
    }

    final result = <String, CablesSectionBreakdown>{};
    if (aluCount > 0) {
      result['Aluminium'] = CablesSectionBreakdown(
        metal: 'Aluminium',
        count: aluCount,
        percentageOfTotal: (aluCount / total) * 100.0,
        sectionsCount: aluSections,
      );
    }
    if (cuCount > 0) {
      result['Cuivre'] = CablesSectionBreakdown(
        metal: 'Cuivre',
        count: cuCount,
        percentageOfTotal: (cuCount / total) * 100.0,
        sectionsCount: cuSections,
      );
    }
    return result;
  }

  static bool _isAluminium(String? nature) {
    if (nature == null) return false;
    final s = nature.trim().toLowerCase();
    return s.contains('alu') || s.contains('aluminium');
  }

  static String _normalizeSection(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw.trim() == '-') {
      return 'Non spécifiée';
    }
    final s = raw
        .trim()
        .replaceAll('mm²', '')
        .replaceAll('mm2', '')
        .replaceAll(',', '.')
        .trim();
    return '$s mm²';
  }

  static List<IpIkZoneItem> _computeIpIkZones(
    String missionId,
    MissionDomainInventory domainInventory,
  ) {
    List<ClassementZone> zones = [];
    List<ClassementEmplacement> emplacements = [];
    try {
      zones = HiveService.getClassementsZonesByMissionId(missionId);
      emplacements = HiveService.getEmplacementsByMissionId(missionId);
    } catch (_) {
      zones = [];
      emplacements = [];
    }

    final allEquipments = domainInventory.instances
        .map((i) => i.rawModelRef)
        .whereType<CoffretArmoire>()
        .toList();

    final result = <IpIkZoneItem>[];

    // Pour chaque zone
    for (final z in zones) {
      final zoneName = z.nomZone.trim();
      final equipInZone = allEquipments.where((c) {
        final pz = domainInventory.instances
            .firstWhere(
              (i) => identical(i.rawModelRef, c),
              orElse: () => domainInventory.instances.first,
            )
            .parentZone;
        return pz?.trim().toLowerCase() == zoneName.toLowerCase();
      }).toList();

      int conf = 0;
      int nonConf = 0;
      int nonRens = 0;

      final reqIpIk = ParsedIpIk(
        ip: z.ip?.trim().isNotEmpty == true ? z.ip!.trim() : null,
        ik: z.ik?.trim().isNotEmpty == true ? z.ik!.trim() : null,
      );

      for (final eq in equipInZone) {
        if (eq.indiceIpIk == null || eq.indiceIpIk!.trim().isEmpty) {
          nonRens++;
          continue;
        }
        if (reqIpIk.hasIpOrIk) {
          final isOk = IpIkEvaluatorService.comparerIndicesIpIk(
            eq.indiceIpIk,
            reqIpIk.toString(),
          );
          if (isOk) {
            conf++;
          } else {
            nonConf++;
          }
        } else {
          nonRens++;
        }
      }

      result.add(
        IpIkZoneItem(
          zoneNom: zoneName,
          ipRequis: z.ip,
          ikRequis: z.ik,
          totalEquipements: equipInZone.length,
          conformes: conf,
          nonConformes: nonConf,
          nonRenseignes: nonRens,
        ),
      );
    }

    // Pour chaque local / emplacement classé s'il n'a pas déjà été couvert
    for (final emp in emplacements) {
      final empName = emp.localisation.trim();
      if (result.any((r) => r.zoneNom.toLowerCase() == empName.toLowerCase())) {
        continue;
      }

      final equipInEmp = allEquipments.where((c) {
        final pl = domainInventory.instances
            .firstWhere(
              (i) => identical(i.rawModelRef, c),
              orElse: () => domainInventory.instances.first,
            )
            .parentLocal;
        return pl?.trim().toLowerCase() == empName.toLowerCase();
      }).toList();

      if (equipInEmp.isEmpty) continue;

      int conf = 0;
      int nonConf = 0;
      int nonRens = 0;

      final reqIpIk = ParsedIpIk(
        ip: emp.ip?.trim().isNotEmpty == true ? emp.ip!.trim() : null,
        ik: emp.ik?.trim().isNotEmpty == true ? emp.ik!.trim() : null,
      );

      for (final eq in equipInEmp) {
        if (eq.indiceIpIk == null || eq.indiceIpIk!.trim().isEmpty) {
          nonRens++;
          continue;
        }
        if (reqIpIk.hasIpOrIk) {
          final isOk = IpIkEvaluatorService.comparerIndicesIpIk(
            eq.indiceIpIk,
            reqIpIk.toString(),
          );
          if (isOk) {
            conf++;
          } else {
            nonConf++;
          }
        } else {
          nonRens++;
        }
      }

      result.add(
        IpIkZoneItem(
          zoneNom: empName,
          ipRequis: emp.ip,
          ikRequis: emp.ik,
          totalEquipements: equipInEmp.length,
          conformes: conf,
          nonConformes: nonConf,
          nonRenseignes: nonRens,
        ),
      );
    }

    return result;
  }

  static RiskFamilyCrossMatrix _computeRiskFamilyMatrix(
    List<AuditFinding> findings,
  ) {
    final htaDispo = <String, int>{};
    final htaExploit = <String, int>{};
    final btDispo = <String, int>{};
    final btExploit = <String, int>{};

    for (final fam in CanonicalRiskFamilyRegistry.canonicalFamilies) {
      htaDispo[fam] = 0;
      htaExploit[fam] = 0;
      btDispo[fam] = 0;
      btExploit[fam] = 0;
    }

    for (final f in findings) {
      final canonRisk = CanonicalRiskFamilyRegistry.mapToCanonical(
        f.riskFamily,
        verificationPoint: f.verificationPoint,
      );

      final isDispo = _isDispositionConstructiveFinding(f);
      final isHta = f.tensionDomain == TensionDomain.mt;

      if (isHta) {
        if (isDispo) {
          htaDispo[canonRisk] = (htaDispo[canonRisk] ?? 0) + 1;
        } else {
          htaExploit[canonRisk] = (htaExploit[canonRisk] ?? 0) + 1;
        }
      } else {
        if (isDispo) {
          btDispo[canonRisk] = (btDispo[canonRisk] ?? 0) + 1;
        } else {
          btExploit[canonRisk] = (btExploit[canonRisk] ?? 0) + 1;
        }
      }
    }

    return RiskFamilyCrossMatrix(
      htaDispositionsConstructives: htaDispo,
      htaExploitationMaintenance: htaExploit,
      btDispositionsConstructives: btDispo,
      btExploitationMaintenance: btExploit,
    );
  }

  static bool _isDispositionConstructiveFinding(AuditFinding f) {
    final tbl = f.tableName.toLowerCase();
    final point = f.verificationPoint.toLowerCase();
    if (tbl.contains('disposition') || tbl.contains('constructive')) {
      return true;
    }
    if (f.objectType.toLowerCase().contains('local') &&
        !tbl.contains('exploitation')) {
      return true;
    }
    if (point.contains('accès') ||
        point.contains('porte') ||
        point.contains('ventilation') ||
        point.contains('éclairage de sécurité') ||
        point.contains('extincteur')) {
      return true;
    }
    return false;
  }

  static List<TopDefectDomainItem> _computeTopDefectsForDomain(
    List<AuditFinding> findings,
    TensionDomain domain,
  ) {
    final domainFindings = findings
        .where((f) => f.tensionDomain == domain)
        .toList();
    final total = domainFindings.length;
    if (total == 0) return [];

    final counts = <String, int>{};
    for (final f in domainFindings) {
      final cat = CanonicalDefectCategoryRegistry.mapToCanonical(
        f.verificationPoint,
        riskFamily: f.riskFamily,
      );
      counts[cat] = (counts[cat] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) {
      return TopDefectDomainItem(
        title: e.key,
        count: e.value,
        percentageOfDomain: (e.value / total) * 100.0,
      );
    }).toList();
  }
}

class _CableData {
  final String? nature;
  final String? section;

  _CableData(this.nature, this.section);
}
