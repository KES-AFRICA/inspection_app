import 'package:flutter/foundation.dart';

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
import 'risk_family_normalizer.dart';

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

  int get evaluables =>
      pointsVerifies > 0 ? pointsVerifies : (conformes + nonConformes);
  double get complianceRate => evaluables > 0
      ? ((evaluables - pointsNonConformes) / evaluables) * 100.0
      : 0.0;

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
  int? operator [](String family) => counts[family];

  int get sumTopOccurrences => topFamilies.fold(0, (s, i) => s + i.constats);
  double get partTopSum =>
      totalConstats > 0 ? (sumTopOccurrences / totalConstats) * 100.0 : 0.0;
  String get formattedPartTopSum =>
      '${partTopSum.toStringAsFixed(1).replaceAll('.', ',')} %';
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

  RiskFamilyQuadrantStats get dispoHta => htaDispositionsConstructives;
  RiskFamilyQuadrantStats get dispoBt => btDispositionsConstructives;
  RiskFamilyQuadrantStats get exploitHta => htaExploitationMaintenance;
  RiskFamilyQuadrantStats get exploitBt => btExploitationMaintenance;

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
  String get dispoConstructivesPctStr => total > 0
      ? '${(dispoConstructives / total * 100).toStringAsFixed(1).replaceAll('.', ',')} %'
      : '0,0 %';
  String get conditionsExploitationPctStr => total > 0
      ? '${(conditionsExploitation / total * 100).toStringAsFixed(1).replaceAll('.', ',')} %'
      : '0,0 %';
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

  String get pctOfTotalNcStr =>
      '${pctOfTotalNc.toStringAsFixed(1).replaceAll('.', ',')} %';
  String get tauxCritiqueStr => ncCount > 0
      ? '${tauxCritique.toStringAsFixed(1).replaceAll('.', ',')} %'
      : '0,0 %';
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

  final int totalZonesAudit;
  final int totalZonesClasseesCount;
  final int totalLocauxAudit;
  final int totalLocauxClassesCount;
  final int totalDepartsAudit;
  final int totalDepartsAvecProtection;
  final int totalCircuitsAudit;
  final int totalCircuitsAvecProtection;

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
    this.totalZonesAudit = 0,
    this.totalZonesClasseesCount = 0,
    this.totalLocauxAudit = 0,
    this.totalLocauxClassesCount = 0,
    this.totalDepartsAudit = 0,
    this.totalDepartsAvecProtection = 0,
    this.totalCircuitsAudit = 0,
    this.totalCircuitsAvecProtection = 0,
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

  int get totalCellules => mtCategoriesCrossRows
      .where((r) => r.categoryName.toLowerCase().contains('cellule'))
      .fold(0, (s, r) => s + r.equipementsCount);
  int get totalTransformateurs => mtCategoriesCrossRows
      .where((r) => r.categoryName.toLowerCase().contains('transformateur'))
      .fold(0, (s, r) => s + r.equipementsCount);

  int get totalTgbt =>
      coupureTeteStats[DomainObjectType.tgbt]?.totalEquipments ?? 0;
  int get totalArmoires =>
      coupureTeteStats[DomainObjectType.armoire]?.totalEquipments ?? 0;
  int get totalCoffrets =>
      coupureTeteStats[DomainObjectType.coffret]?.totalEquipments ?? 0;
  int get totalInverseurs =>
      coupureTeteStats[DomainObjectType.inverseur]?.totalEquipments ?? 0;

  int get totalEquipementsMT => totalCellules + totalTransformateurs;
  int get totalEquipementsBT =>
      totalTgbt + totalArmoires + totalCoffrets + totalInverseurs;
  int get totalEquipementsElectriques =>
      totalEquipementsMT + totalEquipementsBT;

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

    int totalDepartsAuditAll = 0;
    int totalDepartsAvecProtAll = 0;
    int totalCircuitsAuditAll = 0;
    int totalCircuitsAvecProtAll = 0;

    for (final cat in btCategories) {
      final instances = domainInventory.getInstancesByCategory(cat);
      final coffrets = instances
          .map((i) => i.rawModelRef)
          .whereType<CoffretArmoire>()
          .toList();

      final total = instances.length;

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
      final totalDeparts = coffrets.fold<int>(
        0,
        (s, c) => s + (c.departures?.length ?? 0),
      );
      final totalTerminaux = coffrets.fold<int>(
        0,
        (s, c) => s + (c.terminalCircuits?.length ?? 0),
      );

      int departsAvecProt = 0;
      for (final c in coffrets) {
        if (c.departures != null) {
          for (final dep in c.departures!) {
            final t = dep.typeProtection.trim().toLowerCase();
            if (t.isNotEmpty && t != 'aucun' && t != 'sans' && t != '-' && t != 'non') {
              departsAvecProt++;
            }
          }
        }
      }

      int circuitsAvecProt = 0;
      for (final c in coffrets) {
        if (c.terminalCircuits != null) {
          for (final ct in c.terminalCircuits!) {
            final t = ct.typeProtection.trim().toLowerCase();
            if (t.isNotEmpty && t != 'aucun' && t != 'sans' && t != '-' && t != 'non') {
              circuitsAvecProt++;
            }
          }
        }
      }

      totalDepartsAuditAll += totalDeparts;
      totalDepartsAvecProtAll += departsAvecProt;
      totalCircuitsAuditAll += totalTerminaux;
      totalCircuitsAvecProtAll += circuitsAvecProt;

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

    // Calcul strict et indépendant des populations de Zones et de Locaux
    int totalZonesAudit = 0;
    int totalZonesClasseesCount = 0;
    int totalLocauxAudit = 0;
    int totalLocauxClassesCount = 0;

    try {
      final audit = HiveService.getAuditInstallationsByMissionId(missionId);
      final zonesClassees = HiveService.getClassementsZonesByMissionId(missionId);
      final emplacements = HiveService.getEmplacementsByMissionId(missionId);

      // 1. Population des zones (MT + BT)
      final allAuditZoneNames = <String>[];
      final allAuditZoneClassementIds = <String?>[];
      if (audit != null) {
        for (final z in audit.moyenneTensionZones) {
          allAuditZoneNames.add(z.nom);
          allAuditZoneClassementIds.add(z.classementZoneId);
        }
        for (final z in audit.basseTensionZones) {
          allAuditZoneNames.add(z.nom);
          allAuditZoneClassementIds.add(z.classementZoneId);
        }
      }

      if (allAuditZoneNames.isNotEmpty) {
        totalZonesAudit = allAuditZoneNames.length;
        int count = 0;
        for (int i = 0; i < allAuditZoneNames.length; i++) {
          final cId = allAuditZoneClassementIds[i];
          if (cId != null && cId.trim().isNotEmpty) {
            count++;
            continue;
          }
          final zNom = allAuditZoneNames[i].trim().toLowerCase();
          if (zonesClassees.any((cz) => cz.nomZone.trim().toLowerCase() == zNom)) {
            count++;
          }
        }
        totalZonesClasseesCount = count;
      } else {
        final parentZones = domainInventory.instances
            .map((i) => i.parentZone?.trim())
            .where((z) => z != null && z.isNotEmpty)
            .toSet();
        totalZonesAudit = parentZones.length;
        totalZonesClasseesCount = parentZones.where((pz) {
          return zonesClassees.any((cz) => cz.nomZone.trim().toLowerCase() == pz!.toLowerCase());
        }).length;
      }

      // 2. Population des locaux (MT + BT + GE)
      final localInstances = [
        ...domainInventory.getInstancesByCategory(DomainObjectType.localMT),
        ...domainInventory.getInstancesByCategory(DomainObjectType.localBT),
        ...domainInventory.getInstancesByCategory(DomainObjectType.localGE),
      ];
      totalLocauxAudit = localInstances.length;
      totalLocauxClassesCount = localInstances.where((l) {
        final lNom = l.name.trim().toLowerCase();
        return emplacements.any((e) => e.localisation.trim().toLowerCase() == lNom);
      }).length;
    } catch (_) {
      totalZonesAudit = 0;
      totalZonesClasseesCount = 0;
      totalLocauxAudit = 0;
      totalLocauxClassesCount = 0;
    }

    // 5. Matrice 4 quadrants des Familles de risques
    final riskMatrix = _computeRiskFamilyMatrix(domainInventory);

    // 6. Top 5 des défaillances HTA et BT
    final top5Hta = _computeTopDefectsForDomain(
      findingInventory.pertinentFindings,
      TensionDomain.mt,
    );
    final top5Bt = _computeTopDefectsForDomain(
      findingInventory.pertinentFindings,
      TensionDomain.bt,
    );

    // 7. Décompte des constats sur les locaux (Dispositions constructives vs Conditions d'exploitation)
    int mtLocauxDispo = 0;
    int mtLocauxExploit = 0;
    for (final inst in domainInventory.getInstancesByCategory(
      DomainObjectType.localMT,
    )) {
      for (final f in inst.pertinentFindings) {
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
      for (final f in inst.pertinentFindings) {
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
    final totalMissionNc = findingInventory.pertinentFindings.length;
    final mtCatRows = <CategoryCrossAuditRow>[];

    CategoryCrossAuditRow buildCategoryRow(
      String name,
      List<DomainEntityInstance> instances,
      int totalNcDenominator,
    ) {
      final eqCount = instances.length;
      final findings = instances.expand((i) => i.pertinentFindings).toList();
      final ncCount = findings.length;
      final critCount = findings
          .where((f) => f.criticality.toLowerCase().contains('critique'))
          .length;
      final majCount = findings
          .where((f) => f.criticality.toLowerCase().contains('majeur'))
          .length;
      final pctOfTotal = totalNcDenominator > 0
          ? (ncCount / totalNcDenominator) * 100.0
          : 0.0;
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
        domainInventory.getInstancesByCategory(
          DomainObjectType.transformateurMTBT,
        ),
        totalMissionNc,
      ),
    );

    final mtCoffrets = domainInventory.instances
        .where(
          (i) =>
              i.tensionDomain == TensionDomain.mt &&
              (i.category == DomainObjectType.armoire ||
                  i.category == DomainObjectType.coffret),
        )
        .toList();
    if (mtCoffrets.isNotEmpty) {
      mtCatRows.add(
        buildCategoryRow('Armoires / Coffrets MT', mtCoffrets, totalMissionNc),
      );
    }

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
      pctOfTotalNc: totalMissionNc > 0
          ? (mtTotalNc / totalMissionNc) * 100.0
          : 0.0,
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
        domainInventory
            .getInstancesByCategory(DomainObjectType.armoire)
            .where((i) => i.tensionDomain == TensionDomain.bt)
            .toList(),
        totalMissionNc,
      ),
    );
    btCatRows.add(
      buildCategoryRow(
        'Coffrets',
        domainInventory
            .getInstancesByCategory(DomainObjectType.coffret)
            .where((i) => i.tensionDomain == TensionDomain.bt)
            .toList(),
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
      pctOfTotalNc: totalMissionNc > 0
          ? (btTotalNc / totalMissionNc) * 100.0
          : 0.0,
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
      totalZonesClassees: totalZonesClasseesCount,
      totalLocauxMt: locauxMt,
      totalLocauxBt: locauxBt,
      totalLocauxGe: locauxGe,
      locauxMtFindings: locauxMtFindings,
      locauxBtFindings: locauxBtFindings,
      mtCategoriesCrossRows: mtCatRows,
      btCategoriesCrossRows: btCatRows,
      mtTotalCrossRow: mtTotalCrossRow,
      btTotalCrossRow: btTotalCrossRow,
      totalZonesAudit: totalZonesAudit,
      totalZonesClasseesCount: totalZonesClasseesCount,
      totalLocauxAudit: totalLocauxAudit,
      totalLocauxClassesCount: totalLocauxClassesCount,
      totalDepartsAudit: totalDepartsAuditAll,
      totalDepartsAvecProtection: totalDepartsAvecProtAll,
      totalCircuitsAudit: totalCircuitsAuditAll,
      totalCircuitsAvecProtection: totalCircuitsAvecProtAll,
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
    final deps = coffrets
        .expand((c) => c.departures ?? <DepartEquipement>[])
        .toList();
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

  @visibleForTesting
  static List<IpIkZoneItem> computeIpIkZones(
    String missionId,
    MissionDomainInventory domainInventory,
  ) => _computeIpIkZones(missionId, domainInventory);

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

    // ─── Filtre brouillons & éléments non finalisés ─────────────────
    // On ne retient que les équipements finalisés (pas les brouillons / incomplets).
    // Pour CoffretArmoire : on exclut explicitement 'incomplet' et 'brouillon'.
    // Les enregistrements sans statut ou 'complet' sont conservés (rétrocompatibilité).
    // Les cellules MT et transformateurs persistés dans l'audit sont retenus.
    final allEquipmentInstances = domainInventory.instances.where((i) {
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

    final result = <IpIkZoneItem>[];

    // ─── 1. Zones classifiées ──────────────────────────────────────
    // Hiérarchie stricte : Mission -> Zone -> Local -> Équipement.
    // Tous les équipements rattachés à une zone (qu'ils soient enregistrés
    // directement dans la zone, ou dans un local situé au sein de cette zone)
    // appartiennent indirectement à la zone et doivent être comptabilisés dans son total.
    for (final z in zones) {
      final zoneName = z.nomZone.trim();
      final equipInZone = allEquipmentInstances.where((i) {
        final pZone = i.parentZone?.trim();
        return pZone != null && pZone.toLowerCase() == zoneName.toLowerCase();
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
          final hasIp =
              ipVal != null &&
              ipVal.isNotEmpty &&
              ipVal != '-' &&
              ipVal.toLowerCase() != 'absent';
          final hasRep =
              repVal != null &&
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

    // ─── 2. Locaux / emplacements classifiés ────────────────────────
    // Un équipement appartient au local dans lequel il est enregistré.
    // Un local classifié évalue précisément les équipements rattachés à ce local.
    final processedLocalKeys = <String>{};
    for (final emp in emplacements) {
      final empName = emp.localisation.trim();
      if (empName.isEmpty) continue;

      // Si l'emplacement est de type 'zone' et correspond déjà à une zone classifiée,
      // on évite le doublon pour ne pas polluer l'agrégation.
      if (emp.isZone &&
          zones.any(
            (z) => z.nomZone.trim().toLowerCase() == empName.toLowerCase(),
          )) {
        continue;
      }

      // Clé unique pour éviter les doublons accidentels d'emplacements
      final empKey =
          '${emp.typeEmplacement}_${emp.zone?.trim().toLowerCase() ?? ""}_${empName.toLowerCase()}';
      if (processedLocalKeys.contains(empKey)) continue;
      processedLocalKeys.add(empKey);

      final equipInEmp = allEquipmentInstances.where((i) {
        final pLocal = i.parentLocal?.trim();
        if (pLocal == null || pLocal.toLowerCase() != empName.toLowerCase()) {
          return false;
        }
        // Si l'emplacement a une zone parente spécifiée et que l'instance a une parentZone,
        // vérifier la concordance de zone pour éviter toute attribution croisée homonyme.
        if (emp.zone != null &&
            emp.zone!.trim().isNotEmpty &&
            i.parentZone != null &&
            i.parentZone!.trim().isNotEmpty) {
          return i.parentZone!.trim().toLowerCase() ==
              emp.zone!.trim().toLowerCase();
        }
        return true;
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
          final hasIp =
              ipVal != null &&
              ipVal.isNotEmpty &&
              ipVal != '-' &&
              ipVal.toLowerCase() != 'absent';
          final hasRep =
              repVal != null &&
              repVal.isNotEmpty &&
              repVal != '-' &&
              repVal.toLowerCase() != 'absent';
          if (hasIp || hasRep) {
            indPresents++;
          }
        }
      }

      final label =
          (emp.zone != null && emp.zone!.trim().isNotEmpty && !emp.isZone)
          ? '$empName (${emp.zone!.trim()})'
          : empName;

      result.add(
        IpIkZoneItem(
          zoneNom: label,
          ipRequis: emp.ipEffective ?? emp.ip,
          ikRequis: emp.ikEffective ?? emp.ik,
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
          ? RiskFamilyNormalizer.normalize(rawFamily)
          : RiskFamilyNormalizer.normalize(
              DispositionsConstructivesRegistry.getMetadata(
                    f.verificationPoint,
                  )?.familleRisque ??
                  DispositionsConstructivesRegistry.getCoffretMetadata(
                    f.verificationPoint,
                  )?.familleRisque ??
                  'Non spécifiée',
            );
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
    // 1. HTA — DISPOSITION CONSTRUCTIVE : Dispositions constructives MT
    final htaDispoFindings = domainInventory.pertinentFindings
        .where(
          (f) =>
              f.tensionDomain == TensionDomain.mt &&
              _isDispositionConstructiveFinding(f),
        )
        .toList();

    // 2. HTA — EXPLOITATION ET MAINTENANCE : Cellules MT + Transformateurs MT/BT + Conditions exploitation MT + Coffrets MT
    final htaExploitFindings = domainInventory.pertinentFindings
        .where(
          (f) =>
              f.tensionDomain == TensionDomain.mt &&
              !_isDispositionConstructiveFinding(f),
        )
        .toList();

    // 3. BT — DISPOSITION CONSTRUCTIVE : Dispositions constructives BT
    final btDispoFindings = domainInventory.pertinentFindings
        .where(
          (f) =>
              f.tensionDomain == TensionDomain.bt &&
              _isDispositionConstructiveFinding(f),
        )
        .toList();

    // 4. BT — EXPLOITATION ET MAINTENANCE : TGBT + Armoires + Coffrets + Inverseurs + Conditions exploitation BT
    final btExploitFindings = domainInventory.pertinentFindings
        .where(
          (f) =>
              f.tensionDomain == TensionDomain.bt &&
              !_isDispositionConstructiveFinding(f),
        )
        .toList();

    return RiskFamilyCrossMatrix(
      htaDispositionsConstructives: _computeQuadrantStats(
        domainTitle: 'HTA',
        sectionTitle: 'DISPOSITION CONSTRUCTIVE',
        findings: htaDispoFindings,
      ),
      htaExploitationMaintenance: _computeQuadrantStats(
        domainTitle: 'HTA',
        sectionTitle: 'EXPLOITATION ET MAINTENANCE',
        findings: htaExploitFindings,
      ),
      btDispositionsConstructives: _computeQuadrantStats(
        domainTitle: 'BT',
        sectionTitle: 'DISPOSITION CONSTRUCTIVE',
        findings: btDispoFindings,
      ),
      btExploitationMaintenance: _computeQuadrantStats(
        domainTitle: 'BT',
        sectionTitle: 'EXPLOITATION ET MAINTENANCE',
        findings: btExploitFindings,
      ),
    );
  }

  static bool _isDispositionConstructiveFinding(AuditFinding f) {
    final tbl = f.tableName.toLowerCase();
    if (tbl.contains('disposition') || tbl.contains('constructive')) {
      return true;
    }
    if (tbl.contains('exploitation')) {
      return false;
    }
    if (f.objectType.toLowerCase().contains('local')) {
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
