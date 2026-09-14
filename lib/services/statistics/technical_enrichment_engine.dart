// lib/services/statistics/technical_enrichment_engine.dart

import '../../models/audit_installations_electriques.dart';
import '../../models/classement_locaux.dart';
import '../../models/classement_zone.dart';
import '../../models/mesures_essais.dart';
import '../dispositions_constructives_registry.dart';
import '../hive_service.dart';
import 'audit_finding.dart';
import 'canonical_defect_category_registry.dart';
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
  final int totalTete;
  final int totalDeparts;
  final int totalTerminaux;

  const MarquesMatrixRow({
    required this.category,
    required this.organeDeTete,
    required this.departs,
    required this.circuitsTerminaux,
    this.totalTete = 0,
    this.totalDeparts = 0,
    this.totalTerminaux = 0,
  });
}

/// Ligne de distribution des courbes de protection pour une catégorie de tableau BT.
class CourbesMatrixRow {
  final DomainObjectType category;
  final Map<String, int> organeDeTete;
  final Map<String, int> departs;
  final Map<String, int> circuitsTerminaux;
  final int totalTete;
  final int totalDeparts;
  final int totalTerminaux;

  const CourbesMatrixRow({
    required this.category,
    required this.organeDeTete,
    required this.departs,
    required this.circuitsTerminaux,
    this.totalTete = 0,
    this.totalDeparts = 0,
    this.totalTerminaux = 0,
  });
}

/// Synthèse des câbles par matériau conducteur (Alu vs Cuivre) et sections.
class CablesSectionBreakdown {
  final String metal;
  final int count;
  final int totalCables;
  final double percentageOfTotal;
  final Map<String, int> sectionsCount;

  const CablesSectionBreakdown({
    required this.metal,
    required this.count,
    this.totalCables = 0,
    required this.percentageOfTotal,
    required this.sectionsCount,
  });
}

/// Ligne de distribution des câbles pour une catégorie de tableau BT.
class CablesMatrixRow {
  final DomainObjectType category;
  final Map<String, CablesSectionBreakdown> departsBreakdown;
  final Map<String, CablesSectionBreakdown> circuitsTerminauxBreakdown;
  final int totalDepartsCables;
  final int totalTerminauxCables;

  const CablesMatrixRow({
    required this.category,
    required this.departsBreakdown,
    required this.circuitsTerminauxBreakdown,
    this.totalDepartsCables = 0,
    this.totalTerminauxCables = 0,
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
  final int indicesPresents;

  final int pointsVerifies;
  final int pointsNonConformes;

  const IpIkZoneItem({
    required this.zoneNom,
    this.ipRequis,
    this.ikRequis,
    required this.totalEquipements,
    required this.conformes,
    required this.nonConformes,
    required this.nonRenseignes,
    this.indicesPresents = 0,
    this.pointsVerifies = 0,
    this.pointsNonConformes = 0,
  });

  int get evaluables => pointsVerifies > 0 ? pointsVerifies : (conformes + nonConformes);
  double get complianceRate =>
      evaluables > 0 ? ((evaluables - pointsNonConformes) / evaluables) * 100.0 : 0.0;

  double get nonComplianceRate =>
      pointsVerifies > 0 ? (pointsNonConformes / pointsVerifies) * 100.0 : 0.0;

  String get formattedNonComplianceRate => pointsVerifies > 0
      ? '${nonComplianceRate.toStringAsFixed(1).replaceAll('.', ',')} %'
      : 'Non évaluable';

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

/// Élément statistique unitaire pour une famille de risque réelle.
class RiskFamilyStatItem {
  final String famille;
  final int constats;
  final double part;
  final String formattedPart;

  const RiskFamilyStatItem({
    required this.famille,
    required this.constats,
    required this.part,
    required this.formattedPart,
  });

  String get partStr => formattedPart;
}

/// Synthèse statistique d'un quadrant (HTA/BT x Dispo/Exploit).
class RiskFamilyQuadrantStats {
  final String domainTitle;
  final String sectionTitle;
  final int totalConstats;
  final Map<String, int> counts;
  final List<RiskFamilyStatItem> topFamilies;
  final List<RiskFamilyStatItem> allFamilies;

  const RiskFamilyQuadrantStats({
    required this.domainTitle,
    required this.sectionTitle,
    required this.totalConstats,
    required this.counts,
    required this.topFamilies,
    required this.allFamilies,
  });

  const RiskFamilyQuadrantStats.empty({
    this.domainTitle = '',
    this.sectionTitle = '',
    this.totalConstats = 0,
    this.counts = const {},
    this.topFamilies = const [],
    this.allFamilies = const [],
  });

  int get total => totalConstats;
  List<RiskFamilyStatItem> get items => topFamilies;
}

/// Matrice à 4 quadrants croisant Domaine de tension x Nature de contrôle avec les familles de risques réelles.
class RiskFamilyCrossMatrix {
  final RiskFamilyQuadrantStats htaDispositionsConstructives;
  final RiskFamilyQuadrantStats htaExploitationMaintenance;
  final RiskFamilyQuadrantStats btDispositionsConstructives;
  final RiskFamilyQuadrantStats btExploitationMaintenance;

  const RiskFamilyCrossMatrix({
    required this.htaDispositionsConstructives,
    required this.htaExploitationMaintenance,
    required this.btDispositionsConstructives,
    required this.btExploitationMaintenance,
  });

  const RiskFamilyCrossMatrix.empty()
      : htaDispositionsConstructives = const RiskFamilyQuadrantStats.empty(),
        htaExploitationMaintenance = const RiskFamilyQuadrantStats.empty(),
        btDispositionsConstructives = const RiskFamilyQuadrantStats.empty(),
        btExploitationMaintenance = const RiskFamilyQuadrantStats.empty();

  int get totalHtaDispo => htaDispositionsConstructives.totalConstats;
  int get totalHtaExploit => htaExploitationMaintenance.totalConstats;
  int get totalBtDispo => btDispositionsConstructives.totalConstats;
  int get totalBtExploit => btExploitationMaintenance.totalConstats;

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

      final totalTete = total;
      final totalDeparts = coffrets.fold<int>(0, (s, c) => s + (c.departures?.length ?? 0));
      final totalTerminaux = coffrets.fold<int>(0, (s, c) => s + (c.terminalCircuits?.length ?? 0));

      marquesRows.add(
        MarquesMatrixRow(
          category: cat,
          organeDeTete: tMarques,
          departs: dMarques,
          circuitsTerminaux: ctMarques,
          totalTete: totalTete,
          totalDeparts: totalDeparts,
          totalTerminaux: totalTerminaux,
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
          totalTete: totalTete,
          totalDeparts: totalDeparts,
          totalTerminaux: totalTerminaux,
        ),
      );

      // H. Câbles (Alu vs Cuivre et Sections)
      final dCablesList = coffrets
          .expand((c) => c.departures ?? <DepartEquipement>[])
          .map((d) => _CableData(d.natureCable, d.sectionCable))
          .toList();
      final dCables = _computeCablesBreakdown(dCablesList);

      final ctCablesList = coffrets
          .expand((c) => c.terminalCircuits ?? <CircuitTerminalEquipement>[])
          .map((ct) => _CableData(ct.natureCable, ct.sectionCable))
          .toList();
      final ctCables = _computeCablesBreakdown(ctCablesList);

      cablesRows.add(
        CablesMatrixRow(
          category: cat,
          departsBreakdown: dCables,
          circuitsTerminauxBreakdown: ctCables,
          totalDepartsCables: dCablesList.length,
          totalTerminauxCables: ctCablesList.length,
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
    final riskMatrix = _computeRiskFamilyMatrix(domainInventory);

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
        totalCables: total,
        percentageOfTotal: (aluCount / total) * 100.0,
        sectionsCount: aluSections,
      );
    }
    if (cuCount > 0) {
      result['Cuivre'] = CablesSectionBreakdown(
        metal: 'Cuivre',
        count: cuCount,
        totalCables: total,
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

    const equipmentCategories = {
      DomainObjectType.celluleMT,
      DomainObjectType.transformateurMTBT,
      DomainObjectType.tgbt,
      DomainObjectType.armoire,
      DomainObjectType.coffret,
      DomainObjectType.inverseur,
    };

    // ─── Filtre brouillons ────────────────────────────────────────
    // On ne retient que les équipements "complets" (pas les brouillons /
    // incomplets). Pour les CoffretArmoire, la règle est statut == 'complet'.
    // Les cellules MT et transformateurs ne portent pas de champ statut :
    // ils sont toujours retenus.
    final allEquipmentInstances = domainInventory.instances.where((i) {
      if (!equipmentCategories.contains(i.category)) return false;
      final raw = i.rawModelRef;
      if (raw is CoffretArmoire) {
        return raw.statut == 'complet';
      }
      return true;
    }).toList();

    final result = <IpIkZoneItem>[];

    // ─── Zones classifiées ────────────────────────────────────────
    // Règle hiérarchique : un équipement appartient à la ZONE uniquement s'il
    // y est directement rattaché (parentLocal == null). S'il est dans un local
    // lui-même contenu dans la zone (parentLocal != null), il est comptabilisé
    // sous ce local et non sous la zone.
    for (final z in zones) {
      final zoneName = z.nomZone.trim();
      final equipInZone = allEquipmentInstances.where((i) {
        return i.parentZone?.trim().toLowerCase() == zoneName.toLowerCase() &&
            i.parentLocal == null;
      }).toList();

      int totalPoints = 0;
      int nonConformesPoints = 0;
      int indPresents = 0;

      for (final inst in equipInZone) {
        final comp = inst.compliantCheckpoints;
        final nonComp = inst.findings.isNotEmpty
            ? inst.findings.length
            : inst.nonCompliantCheckpoints;
        totalPoints += (comp + nonComp);
        nonConformesPoints += nonComp;

        final raw = inst.rawModelRef;
        if (raw is CoffretArmoire) {
          final ipVal = raw.indiceIpIk?.trim();
          final repVal = raw.indiceIpIkRepere?.trim();
          final hasIp = ipVal != null &&
              ipVal.isNotEmpty &&
              ipVal != '-' &&
              ipVal.toLowerCase() != 'absent';
          final hasRep = repVal != null &&
              repVal.isNotEmpty &&
              repVal != '-' &&
              repVal.toLowerCase() != 'absent';
          if (hasIp || hasRep) {
            indPresents++;
          }
        }
      }

      result.add(
        IpIkZoneItem(
          zoneNom: zoneName,
          ipRequis: z.ip,
          ikRequis: z.ik,
          totalEquipements: equipInZone.length,
          conformes: totalPoints > 0 ? (totalPoints - nonConformesPoints) : 0,
          nonConformes: nonConformesPoints,
          nonRenseignes: 0,
          indicesPresents: indPresents,
          pointsVerifies: totalPoints,
          pointsNonConformes: nonConformesPoints,
        ),
      );
    }

    // ─── Locaux / emplacements classifiés ────────────────────────
    // Règle hiérarchique : un équipement appartient à ce local uniquement si
    // son parentLocal correspond exactement à ce local. On ne se replie PAS
    // sur parentZone : cela évite d'attribuer par erreur des équipements de
    // zone à un emplacement homonyme, et empêche tout double-comptage.
    for (final emp in emplacements) {
      final empName = emp.localisation.trim();
      if (result.any((r) => r.zoneNom.toLowerCase() == empName.toLowerCase())) {
        continue;
      }

      final equipInEmp = allEquipmentInstances.where((i) {
        return i.parentLocal?.trim().toLowerCase() == empName.toLowerCase();
      }).toList();

      int totalPoints = 0;
      int nonConformesPoints = 0;
      int indPresents = 0;

      for (final inst in equipInEmp) {
        final comp = inst.compliantCheckpoints;
        final nonComp = inst.findings.isNotEmpty
            ? inst.findings.length
            : inst.nonCompliantCheckpoints;
        totalPoints += (comp + nonComp);
        nonConformesPoints += nonComp;

        final raw = inst.rawModelRef;
        if (raw is CoffretArmoire) {
          final ipVal = raw.indiceIpIk?.trim();
          final repVal = raw.indiceIpIkRepere?.trim();
          final hasIp = ipVal != null &&
              ipVal.isNotEmpty &&
              ipVal != '-' &&
              ipVal.toLowerCase() != 'absent';
          final hasRep = repVal != null &&
              repVal.isNotEmpty &&
              repVal != '-' &&
              repVal.toLowerCase() != 'absent';
          if (hasIp || hasRep) {
            indPresents++;
          }
        }
      }

      result.add(
        IpIkZoneItem(
          zoneNom: empName,
          ipRequis: emp.ip,
          ikRequis: emp.ik,
          totalEquipements: equipInEmp.length,
          conformes: totalPoints > 0 ? (totalPoints - nonConformesPoints) : 0,
          nonConformes: nonConformesPoints,
          nonRenseignes: 0,
          indicesPresents: indPresents,
          pointsVerifies: totalPoints,
          pointsNonConformes: nonConformesPoints,
        ),
      );
    }

    return result;
  }

  static RiskFamilyQuadrantStats _computeQuadrantStats({
    required String domainTitle,
    required String sectionTitle,
    required List<AuditFinding> findings,
  }) {
    final totalConstats = findings.length;
    if (totalConstats == 0) {
      return RiskFamilyQuadrantStats(
        domainTitle: domainTitle,
        sectionTitle: sectionTitle,
        totalConstats: 0,
        counts: const {},
        topFamilies: const [],
        allFamilies: const [],
      );
    }

    final counts = <String, int>{};
    for (final f in findings) {
      final rawFamily = f.riskFamily?.trim();
      final family = (rawFamily != null && rawFamily.isNotEmpty)
          ? rawFamily
          : (DispositionsConstructivesRegistry.getMetadata(f.verificationPoint)?.familleRisque ??
             DispositionsConstructivesRegistry.getCoffretMetadata(f.verificationPoint)?.familleRisque ??
             'Non spécifiée');
      counts[family] = (counts[family] ?? 0) + 1;
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });

    final allFamilies = sortedEntries.map((e) {
      final part = totalConstats > 0 ? (e.value / totalConstats) * 100.0 : 0.0;
      final formattedPart = '${part.toStringAsFixed(1).replaceAll('.', ',')} %';
      return RiskFamilyStatItem(
        famille: e.key,
        constats: e.value,
        part: part,
        formattedPart: formattedPart,
      );
    }).toList();

    final topFamilies = allFamilies.take(5).toList();

    return RiskFamilyQuadrantStats(
      domainTitle: domainTitle,
      sectionTitle: sectionTitle,
      totalConstats: totalConstats,
      counts: counts,
      topFamilies: topFamilies,
      allFamilies: allFamilies,
    );
  }

  static RiskFamilyCrossMatrix _computeRiskFamilyMatrix(
    MissionDomainInventory domainInventory,
  ) {
    // 1. HTA — DISPOSITION CONSTRUCTIVE : Locaux MT / HTA
    final htaLocauxFindings = domainInventory
        .getInstancesByCategory(DomainObjectType.localMT)
        .expand((i) => i.findings)
        .toList();

    // 2. HTA — EXPLOITATION ET MAINTENANCE : Cellules MT + Transformateurs MT/BT
    final htaEquipFindings = [
      ...domainInventory.getInstancesByCategory(DomainObjectType.celluleMT),
      ...domainInventory.getInstancesByCategory(DomainObjectType.transformateurMTBT),
    ].expand((i) => i.findings).toList();

    // 3. BT — DISPOSITION CONSTRUCTIVE : Locaux BT + Locaux GE
    final btLocauxFindings = [
      ...domainInventory.getInstancesByCategory(DomainObjectType.localBT),
      ...domainInventory.getInstancesByCategory(DomainObjectType.localGE),
    ].expand((i) => i.findings).toList();

    // 4. BT — EXPLOITATION ET MAINTENANCE : TGBT + Armoires + Coffrets + Inverseurs
    final btEquipFindings = [
      ...domainInventory.getInstancesByCategory(DomainObjectType.tgbt),
      ...domainInventory.getInstancesByCategory(DomainObjectType.armoire),
      ...domainInventory.getInstancesByCategory(DomainObjectType.coffret),
      ...domainInventory.getInstancesByCategory(DomainObjectType.inverseur),
    ].expand((i) => i.findings).toList();

    return RiskFamilyCrossMatrix(
      htaDispositionsConstructives: _computeQuadrantStats(
        domainTitle: 'HTA',
        sectionTitle: 'DISPOSITION CONSTRUCTIVE',
        findings: htaLocauxFindings,
      ),
      htaExploitationMaintenance: _computeQuadrantStats(
        domainTitle: 'HTA',
        sectionTitle: 'EXPLOITATION ET MAINTENANCE',
        findings: htaEquipFindings,
      ),
      btDispositionsConstructives: _computeQuadrantStats(
        domainTitle: 'BT',
        sectionTitle: 'DISPOSITION CONSTRUCTIVE',
        findings: btLocauxFindings,
      ),
      btExploitationMaintenance: _computeQuadrantStats(
        domainTitle: 'BT',
        sectionTitle: 'EXPLOITATION ET MAINTENANCE',
        findings: btEquipFindings,
      ),
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
