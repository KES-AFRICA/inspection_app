import 'package:flutter/foundation.dart';

import '../../models/audit_installations_electriques.dart';
import '../../models/classement_locaux.dart';
import '../../models/classement_zone.dart';
import '../../models/description_installations.dart';
import '../../models/mesures_essais.dart';
import '../dispositions_constructives_registry.dart';
import '../hive_service.dart';
import '../installation_description_sync_service.dart';
import 'audit_finding.dart';
import 'canonical_defect_category_registry.dart';
import 'domain_entity_instance.dart';
import 'ip_ik_evaluator.dart';
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

/// Ligne de conformité IP/IK par zone ou emplacement classé (Section 9).
class IpIkZoneItem {
  final String zoneNom;
  final String? parentZoneNom;
  final bool isLocal;
  final String? ipRequis;
  final String? ikRequis;
  final int totalEquipements;

  // 3 Catégories canoniques de la Section 9
  final int adequatCount;
  final int presentDifferentCount;
  final int absentCount;
  final int nonEvaluableCount;

  // Rétrocompatibilité
  final int conformes;
  final int nonConformes;
  final int nonRenseignes;
  final int indicesPresents;
  final int pointsVerifies;
  final int pointsNonConformes;

  const IpIkZoneItem({
    required this.zoneNom,
    this.parentZoneNom,
    this.isLocal = false,
    this.ipRequis,
    this.ikRequis,
    required this.totalEquipements,
    this.adequatCount = 0,
    this.presentDifferentCount = 0,
    this.absentCount = 0,
    this.nonEvaluableCount = 0,
    int? conformes,
    int? nonConformes,
    int? nonRenseignes,
    int? indicesPresents,
    this.pointsVerifies = 0,
    this.pointsNonConformes = 0,
  })  : conformes = conformes ?? adequatCount,
        nonConformes = nonConformes ?? (presentDifferentCount + absentCount),
        nonRenseignes = nonRenseignes ?? absentCount,
        indicesPresents = indicesPresents ?? (adequatCount + presentDifferentCount);

  /// Indique si ce repère est évaluable (au moins 1 équipement et indice requis défini)
  bool get isEvaluable =>
      totalEquipements > 0 &&
      nonEvaluableCount == 0 &&
      ((ipRequis != null && ipRequis!.trim().isNotEmpty) ||
          (ikRequis != null && ikRequis!.trim().isNotEmpty));

  int get nonConformesCount => presentDifferentCount + absentCount;

  double get adequatPct =>
      totalEquipements > 0 ? (adequatCount / totalEquipements) * 100.0 : 0.0;
  double get presentDifferentPct =>
      totalEquipements > 0 ? (presentDifferentCount / totalEquipements) * 100.0 : 0.0;
  double get absentPct =>
      totalEquipements > 0 ? (absentCount / totalEquipements) * 100.0 : 0.0;
  double get nonEvaluablePct =>
      totalEquipements > 0 ? (nonEvaluableCount / totalEquipements) * 100.0 : 0.0;

  double get nonComplianceRate =>
      isEvaluable ? (nonConformesCount / totalEquipements) * 100.0 : 0.0;

  double get complianceRate =>
      isEvaluable ? (adequatCount / totalEquipements) * 100.0 : 0.0;

  String get formattedEquipmentCount => totalEquipements <= 1
      ? '$totalEquipements équipement'
      : '$totalEquipements équipements';

  static String formatPercent(double val) {
    if (val == val.roundToDouble()) {
      return '${val.toInt()} %';
    }
    return '${val.toStringAsFixed(1).replaceAll('.', ',')} %';
  }

  String get formattedNonComplianceRate =>
      isEvaluable ? formatPercent(nonComplianceRate) : "Absence d'indice IP/IK, repère non classé.";

  String get formattedComplianceRate =>
      isEvaluable ? formatPercent(complianceRate) : "Absence d'indice IP/IK, repère non classé.";

  String get formattedAdequatPct => formatPercent(adequatPct);
  String get formattedPresentDifferentPct => formatPercent(presentDifferentPct);
  String get formattedAbsentPct => formatPercent(absentPct);
  String get formattedNonEvaluablePct => formatPercent(nonEvaluablePct);

  String get formattedRate => isEvaluable
      ? formatPercent(complianceRate)
      : (totalEquipements == 0
          ? '0 équipement'
          : "Absence d'indice IP/IK, repère non classé.");

  int get evaluables =>
      pointsVerifies > 0 ? pointsVerifies : (totalEquipements - nonEvaluableCount);
}

/// Statistiques d'équipements pour une population donnée (zone directe ou local).
class IpIkEquipmentStats {
  final int totalEquipements;
  final int conformes;
  final int differents;
  final int absents;
  final bool isEvaluable;

  const IpIkEquipmentStats({
    required this.totalEquipements,
    required this.conformes,
    required this.differents,
    required this.absents,
    required this.isEvaluable,
  });

  const IpIkEquipmentStats.empty()
      : totalEquipements = 0,
        conformes = 0,
        differents = 0,
        absents = 0,
        isEvaluable = false;

  double get complianceRate =>
      isEvaluable && totalEquipements > 0 ? (conformes / totalEquipements) * 100.0 : 0.0;
  double get differentsRate =>
      isEvaluable && totalEquipements > 0 ? (differents / totalEquipements) * 100.0 : 0.0;
  double get absentsRate =>
      isEvaluable && totalEquipements > 0 ? (absents / totalEquipements) * 100.0 : 0.0;

  String get formattedEquipmentCount =>
      totalEquipements <= 1 ? '$totalEquipements équipement' : '$totalEquipements équipements';

  String get formattedComplianceRate =>
      isEvaluable ? IpIkZoneItem.formatPercent(complianceRate) : "Absence d'indice IP/IK, local non classé.";
  String get formattedDifferentsPct => IpIkZoneItem.formatPercent(differentsRate);
  String get formattedAbsentsPct => IpIkZoneItem.formatPercent(absentsRate);

  /// Représentation des trois états :
  /// "Conformes : Y/X, soit Z %. Différents : Y/X, soit Z %. Absents : Y/X, soit Z %"
  String get formattedTrioBreakdown =>
      'Conformes : $conformes/$totalEquipements, soit ${IpIkZoneItem.formatPercent(complianceRate)}. '
      'Différents : $differents/$totalEquipements, soit ${IpIkZoneItem.formatPercent(differentsRate)}. '
      'Absents : $absents/$totalEquipements, soit ${IpIkZoneItem.formatPercent(absentsRate)}';
}

/// Représentation d'un local et de ses équipements pour la sous-section 9.
class IpIkLocalHierarchyItem {
  final String localNom;
  final String? localId;
  final bool isClasse;
  final String? ipRequis;
  final String? ikRequis;
  final IpIkEquipmentStats stats;

  const IpIkLocalHierarchyItem({
    required this.localNom,
    this.localId,
    required this.isClasse,
    this.ipRequis,
    this.ikRequis,
    required this.stats,
  });

  String get indiceFormatted {
    final parts = [ipRequis, ikRequis]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(' / ') : "Absence d'indice IP/IK, local non classé";
  }
}

/// Représentation d'une ligne de zone (ou local hors zone) dans la sous-section 9.
class IpIkZoneHierarchyItem {
  final String? zoneNom;
  final String? zoneId;
  final bool isHorsZone;
  final bool isClasse;
  final String? classementDescription;
  final String? ipRequis;
  final String? ikRequis;
  final IpIkEquipmentStats directEquipmentStats;
  final List<IpIkLocalHierarchyItem> locals;

  const IpIkZoneHierarchyItem({
    this.zoneNom,
    this.zoneId,
    this.isHorsZone = false,
    required this.isClasse,
    this.classementDescription,
    this.ipRequis,
    this.ikRequis,
    required this.directEquipmentStats,
    required this.locals,
  });

  String get indiceZoneFormatted {
    final parts = [ipRequis, ikRequis]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(' / ') : "Absence d'indice IP/IK, zone non classée";
  }
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

  final bool isArretUrgenceApplicable;
  final bool isDemarrageGeApplicable;
  final bool isCpiApplicable;

  const EssaisCoverageStats({
    required this.prisesTerreCount,
    required this.testDdrCount,
    required this.mesureIsolementCount,
    required this.testCpiCount,
    required this.continuitePeCount,
    required this.demarrageGeCount,
    required this.arretUrgenceCount,
    this.isArretUrgenceApplicable = true,
    this.isDemarrageGeApplicable = true,
    this.isCpiApplicable = true,
  });

  int get totalEssais =>
      prisesTerreCount +
      testDdrCount +
      mesureIsolementCount +
      (isCpiApplicable ? testCpiCount : 0) +
      continuitePeCount +
      (isDemarrageGeApplicable ? demarrageGeCount : 0) +
      (isArretUrgenceApplicable ? arretUrgenceCount : 0);
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

  /// Nombre d'occurrences pour toutes les familles hors Top 5
  int get autresConstats =>
      allFamilies.length > 5
          ? allFamilies.skip(5).fold(0, (s, i) => s + i.constats)
          : 0;

  /// Part relative des familles hors Top 5 par rapport au total du quadrant
  double get autresPart =>
      totalConstats > 0 ? (autresConstats / totalConstats) * 100.0 : 0.0;

  String get formattedAutresPart =>
      '${autresPart.toStringAsFixed(1).replaceAll('.', ',')} %';

  /// Somme réelle des occurrences affichées (Top 5 + Autres)
  int get sumDisplayedOccurrences => sumTopOccurrences + autresConstats;

  /// Somme réelle de toutes les occurrences du quadrant (toutes familles)
  int get sumAllOccurrences => allFamilies.fold(0, (s, i) => s + i.constats);

  /// Somme réelle des pourcentages affichés (Top 5 + Autres), sans forcer 100%
  double get sumDisplayedParts {
    final topParts = topFamilies.fold(0.0, (s, i) => s + i.part);
    return topParts + autresPart;
  }

  String get formattedSumDisplayedParts {
    if (totalConstats == 0) return '0,0 %';
    return '${sumDisplayedParts.toStringAsFixed(1).replaceAll('.', ',')} %';
  }
}

/// Statistiques d'appareillage et diversification de marque pour une population donnée
/// (Protections de tête, Départs, Circuits).
class EquipmentBrandPopulationStats {
  final String populationTitle;
  final int totalEligibles; // X
  final int withProtectionCount; // Y
  final double protectionRate; // Z
  final String formattedProtectionRate;
  final Map<String, int> brandCounts; // Décroissant
  final Map<String, double> brandPercentages; // Calculé sur Y

  const EquipmentBrandPopulationStats({
    required this.populationTitle,
    required this.totalEligibles,
    required this.withProtectionCount,
    required this.protectionRate,
    required this.formattedProtectionRate,
    required this.brandCounts,
    required this.brandPercentages,
  });

  const EquipmentBrandPopulationStats.empty({this.populationTitle = ''})
      : totalEligibles = 0,
        withProtectionCount = 0,
        protectionRate = 0.0,
        formattedProtectionRate = '0,0 %',
        brandCounts = const {},
        brandPercentages = const {};

  bool get hasEligibles => totalEligibles > 0;
  bool get hasProtections => withProtectionCount > 0;
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

  ({RiskFamilyQuadrantStats hta, RiskFamilyQuadrantStats bt})
  get dispositionsConstructives =>
      (hta: htaDispositionsConstructives, bt: btDispositionsConstructives);

  ({RiskFamilyQuadrantStats hta, RiskFamilyQuadrantStats bt})
  get exploitationMaintenance =>
      (hta: htaExploitationMaintenance, bt: btExploitationMaintenance);

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
  final List<IpIkZoneHierarchyItem> ipIkHierarchy;
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
  final List<CategoryCrossAuditRow> mtExploitationCrossRows;
  final List<CategoryCrossAuditRow> btExploitationCrossRows;
  final CategoryCrossAuditRow mtExploitationTotalCrossRow;
  final CategoryCrossAuditRow btExploitationTotalCrossRow;

  final int totalZonesAudit;
  final int totalZonesClasseesCount;
  final int totalLocauxAudit;
  final int totalLocauxClassesCount;
  final int totalDepartsAudit;
  final int totalDepartsAvecProtection;
  final int totalCircuitsAudit;
  final int totalCircuitsAvecProtection;

  final int totalEquipementsEligiblesIpIk;
  final int totalEquipementsClassesIpIk;

  final EquipmentBrandPopulationStats protectionsTeteBrandStats;
  final EquipmentBrandPopulationStats departsBrandStats;
  final EquipmentBrandPopulationStats circuitsBrandStats;

  final int totalMissionNc;
  final int totalMissionMajeures;
  final int totalHtaMajeures;
  final int totalBtMajeures;

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
    this.ipIkHierarchy = const [],
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
    this.mtExploitationCrossRows = const [],
    this.btExploitationCrossRows = const [],
    this.mtExploitationTotalCrossRow = const CategoryCrossAuditRow(
      categoryName: 'TOTAL MOYENNE TENSION (HTA)',
      equipementsCount: 0,
      ncCount: 0,
      critiquesCount: 0,
      majeuresCount: 0,
      pctOfTotalNc: 0.0,
      tauxCritique: 0.0,
      densite: 0.0,
    ),
    this.btExploitationTotalCrossRow = const CategoryCrossAuditRow(
      categoryName: 'TOTAL BASSE TENSION (BT)',
      equipementsCount: 0,
      ncCount: 0,
      critiquesCount: 0,
      majeuresCount: 0,
      pctOfTotalNc: 0.0,
      tauxCritique: 0.0,
      densite: 0.0,
    ),
    this.totalZonesAudit = 0,
    this.totalZonesClasseesCount = 0,
    this.totalLocauxAudit = 0,
    this.totalLocauxClassesCount = 0,
    this.totalDepartsAudit = 0,
    this.totalDepartsAvecProtection = 0,
    this.totalCircuitsAudit = 0,
    this.totalCircuitsAvecProtection = 0,
    this.totalEquipementsEligiblesIpIk = 0,
    this.totalEquipementsClassesIpIk = 0,
    this.protectionsTeteBrandStats = const EquipmentBrandPopulationStats.empty(populationTitle: 'Protections de tête'),
    this.departsBrandStats = const EquipmentBrandPopulationStats.empty(populationTitle: 'Départs'),
    this.circuitsBrandStats = const EquipmentBrandPopulationStats.empty(populationTitle: 'Circuits'),
    this.totalMissionNc = 0,
    this.totalMissionMajeures = 0,
    this.totalHtaMajeures = 0,
    this.totalBtMajeures = 0,
  });

  /// Getters canoniques de totalisation et sous-ensembles (Source de vérité unique)
  int get htaConditionsExploit => locauxMtFindings.conditionsExploitation;
  int get btConditionsExploit => locauxBtFindings.conditionsExploitation;
  int get htaDispoConstructives => locauxMtFindings.dispoConstructives;
  int get btDispoConstructives => locauxBtFindings.dispoConstructives;
  int get htaExploitationMaintenance =>
      riskFamilyMatrix.htaExploitationMaintenance.totalConstats;
  int get btExploitationMaintenance =>
      riskFamilyMatrix.btExploitationMaintenance.totalConstats;
  int get totalHtaNc => mtTotalCrossRow.ncCount;
  int get totalBtNc => btTotalCrossRow.ncCount;

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

  /// % d'équipements classés IP/IK (TGBT, inverseurs, armoires, coffrets)
  double get equipementsIpIkAdequationRate => totalEquipementsEligiblesIpIk > 0
      ? (totalEquipementsClassesIpIk / totalEquipementsEligiblesIpIk) * 100.0
      : 0.0;

  String get equipementsIpIkAdequationRateStr {
    final rate = equipementsIpIkAdequationRate;
    if (rate.truncateToDouble() == rate) {
      return '${rate.toInt()} %';
    }
    return '${rate.toStringAsFixed(1).replaceAll('.', ',')} %';
  }

  /// Adéquation globale IP/IK = (% zones classées + % locaux classés + % équipements classés) / 3
  double get globalIpIkAdequationRate {
    final zonesPct = totalZonesAudit > 0
        ? (totalZonesClasseesCount / totalZonesAudit) * 100.0
        : 0.0;
    final totalLocaux = totalLocauxAudit > 0
        ? totalLocauxAudit
        : (totalLocauxMt + totalLocauxBt + totalLocauxGe);
    final locauxPct = totalLocaux > 0
        ? (totalLocauxClassesCount / totalLocaux) * 100.0
        : 0.0;
    final equipementsPct = equipementsIpIkAdequationRate;
    return (zonesPct + locauxPct + equipementsPct) / 3.0;
  }

  String get globalIpIkAdequationRateStr {
    final rate = globalIpIkAdequationRate;
    if (rate.truncateToDouble() == rate) {
      return '${rate.toInt()} %';
    }
    return '${rate.toStringAsFixed(1).replaceAll('.', ',')} %';
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
    DescriptionInstallations? description;
    try {
      description =
          HiveService.getDescriptionInstallationsByMissionId(missionId);
    } catch (_) {
      description = null;
    }

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

    final transfos = domainInventory
        .getInstancesByCategory(DomainObjectType.transformateurMTBT)
        .map((i) => i.rawModelRef)
        .toList();

    final essaisCoverage = _computeEssaisCoverage(
      mesures,
      desc: description,
      locauxGe: locauxGe,
      transfos: transfos,
    );

    // 2.bis Équipements éligibles IP/IK : strictement TGBT, inverseurs, armoires, coffrets
    final eligibleEquipments = [
      ...domainInventory.getInstancesByCategory(DomainObjectType.tgbt),
      ...domainInventory.getInstancesByCategory(DomainObjectType.inverseur),
      ...domainInventory.getInstancesByCategory(DomainObjectType.armoire),
      ...domainInventory.getInstancesByCategory(DomainObjectType.coffret),
    ];
    final totalEquipementsEligiblesIpIk = eligibleEquipments.length;
    int totalEquipementsClassesIpIk = 0;
    for (final eq in eligibleEquipments) {
      final raw = eq.rawModelRef;
      if (raw is CoffretArmoire) {
        final ipVal = raw.indiceIpIk?.trim();
        final hasExploitableIp = ipVal != null &&
            ipVal.isNotEmpty &&
            ipVal != '-' &&
            ipVal.toLowerCase() != 'absent';
        if (hasExploitableIp) {
          totalEquipementsClassesIpIk++;
        }
      }
    }

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
    final ipIkHierarchy = _computeIpIkHierarchy(missionId, domainInventory);

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
      int totalNcDenominator, {
      List<AuditFinding>? customFindings,
    }) {
      final eqCount = instances.length;
      final findings =
          customFindings ?? instances.expand((i) => i.pertinentFindings).toList();
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

    final mtLocauxFindings = domainInventory
        .getInstancesByCategory(DomainObjectType.localMT)
        .expand((i) => i.pertinentFindings)
        .toList();

    mtCatRows.add(
      buildCategoryRow(
        'Locaux techniques',
        domainInventory.getInstancesByCategory(DomainObjectType.localMT),
        totalMissionNc,
        customFindings: mtLocauxFindings,
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

    // Sécurité de couverture absolue MT : aucune occurrence ne peut être omise
    final accountedMtFindingIds = <String>{
      ...mtLocauxFindings.map((f) => f.id),
      ...domainInventory.getInstancesByCategory(DomainObjectType.celluleMT).expand((i) => i.pertinentFindings).map((f) => f.id),
      ...domainInventory.getInstancesByCategory(DomainObjectType.transformateurMTBT).expand((i) => i.pertinentFindings).map((f) => f.id),
    };
    final htaFindings = domainInventory.pertinentFindings
        .where((f) => f.tensionDomain == TensionDomain.mt)
        .toList();
    final orphanMtFindings = htaFindings
        .where((f) => !accountedMtFindingIds.contains(f.id))
        .toList();
    if (orphanMtFindings.isNotEmpty) {
      mtCatRows.add(
        buildCategoryRow(
          'Autres équipements MT',
          const [],
          totalMissionNc,
          customFindings: orphanMtFindings,
        ),
      );
    }

    final mtTotalEq = mtCatRows.fold(0, (s, r) => s + r.equipementsCount);
    final mtTotalCrit = mtCatRows.fold(0, (s, r) => s + r.critiquesCount);
    final mtTotalMaj = mtCatRows.fold(0, (s, r) => s + r.majeuresCount);
    final mtTotalNc = mtCatRows.fold(0, (s, r) => s + r.ncCount);
    final mtTotalCrossRow = CategoryCrossAuditRow(
      categoryName: 'TOTAL MOYENNE TENSION (HTA)',
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

    // Lignes d'exploitation et maintenance MT (excluant les dispositions constructives)
    final mtExploitationCatRows = <CategoryCrossAuditRow>[];
    final mtExploitationLocauxFindings = mtLocauxFindings
        .where((f) => !_isDispositionConstructiveFinding(f))
        .toList();
    mtExploitationCatRows.add(
      buildCategoryRow(
        'Locaux techniques',
        domainInventory.getInstancesByCategory(DomainObjectType.localMT),
        totalMissionNc,
        customFindings: mtExploitationLocauxFindings,
      ),
    );
    final cellulesInstances = domainInventory.getInstancesByCategory(DomainObjectType.celluleMT);
    final cellulesExploitFindings = cellulesInstances
        .expand((i) => i.pertinentFindings)
        .where((f) => !_isDispositionConstructiveFinding(f))
        .toList();
    mtExploitationCatRows.add(
      buildCategoryRow(
        'Cellules',
        cellulesInstances,
        totalMissionNc,
        customFindings: cellulesExploitFindings,
      ),
    );
    final transfoInstances = domainInventory.getInstancesByCategory(DomainObjectType.transformateurMTBT);
    final transfoExploitFindings = transfoInstances
        .expand((i) => i.pertinentFindings)
        .where((f) => !_isDispositionConstructiveFinding(f))
        .toList();
    mtExploitationCatRows.add(
      buildCategoryRow(
        'Transformateurs',
        transfoInstances,
        totalMissionNc,
        customFindings: transfoExploitFindings,
      ),
    );
    final accountedMtExploitFindingIds = <String>{
      ...mtExploitationLocauxFindings.map((f) => f.id),
      ...cellulesExploitFindings.map((f) => f.id),
      ...transfoExploitFindings.map((f) => f.id),
    };
    final orphanMtExploitFindings = htaFindings
        .where((f) => !_isDispositionConstructiveFinding(f) && !accountedMtExploitFindingIds.contains(f.id))
        .toList();
    if (orphanMtExploitFindings.isNotEmpty) {
      mtExploitationCatRows.add(
        buildCategoryRow(
          'Autres équipements MT',
          const [],
          totalMissionNc,
          customFindings: orphanMtExploitFindings,
        ),
      );
    }
    final mtExploitTotalEq = mtExploitationCatRows.fold(0, (s, r) => s + r.equipementsCount);
    final mtExploitTotalCrit = mtExploitationCatRows.fold(0, (s, r) => s + r.critiquesCount);
    final mtExploitTotalMaj = mtExploitationCatRows.fold(0, (s, r) => s + r.majeuresCount);
    final mtExploitTotalNc = mtExploitationCatRows.fold(0, (s, r) => s + r.ncCount);
    final mtExploitationTotalCrossRow = CategoryCrossAuditRow(
      categoryName: 'TOTAL MOYENNE TENSION (HTA)',
      equipementsCount: mtExploitTotalEq,
      ncCount: mtExploitTotalNc,
      critiquesCount: mtExploitTotalCrit,
      majeuresCount: mtExploitTotalMaj,
      pctOfTotalNc: totalMissionNc > 0
          ? (mtExploitTotalNc / totalMissionNc) * 100.0
          : 0.0,
      tauxCritique: mtExploitTotalNc > 0 ? (mtExploitTotalCrit / mtExploitTotalNc) * 100.0 : 0.0,
      densite: mtExploitTotalEq > 0 ? (mtExploitTotalNc / mtExploitTotalEq) : 0.0,
    );

    // 9. Lignes de conformité croisée par catégorie pour Basse Tension
    final btCatRows = <CategoryCrossAuditRow>[];

    final btLocauxGeFindings = domainInventory
        .getInstancesByCategory(DomainObjectType.localGE)
        .expand((i) => i.pertinentFindings)
        .toList();
    final btLocauxBtFindings = domainInventory
        .getInstancesByCategory(DomainObjectType.localBT)
        .expand((i) => i.pertinentFindings)
        .toList();

    btCatRows.add(
      buildCategoryRow(
        'Locaux techniques GE',
        domainInventory.getInstancesByCategory(DomainObjectType.localGE),
        totalMissionNc,
        customFindings: btLocauxGeFindings,
      ),
    );
    btCatRows.add(
      buildCategoryRow(
        'Locaux techniques BT',
        domainInventory.getInstancesByCategory(DomainObjectType.localBT),
        totalMissionNc,
        customFindings: btLocauxBtFindings,
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
    final ptInstances = domainInventory.getInstancesByCategory(DomainObjectType.priseTerre);
    if (ptInstances.isNotEmpty) {
      btCatRows.add(
        buildCategoryRow(
          'Prises de terre mesurées',
          ptInstances,
          totalMissionNc,
        ),
      );
    }
    final foudreInstances = domainInventory.getInstancesByCategory(DomainObjectType.foudre);
    if (foudreInstances.isNotEmpty) {
      btCatRows.add(
        buildCategoryRow(
          'Installations Foudre',
          foudreInstances,
          totalMissionNc,
        ),
      );
    }

    // Sécurité de couverture absolue BT : aucune occurrence ne peut être omise
    final accountedBtFindingIds = <String>{
      ...btLocauxGeFindings.map((f) => f.id),
      ...btLocauxBtFindings.map((f) => f.id),
      ...domainInventory.getInstancesByCategory(DomainObjectType.inverseur).expand((i) => i.pertinentFindings).map((f) => f.id),
      ...domainInventory.getInstancesByCategory(DomainObjectType.tgbt).expand((i) => i.pertinentFindings).map((f) => f.id),
      ...domainInventory.getInstancesByCategory(DomainObjectType.armoire).expand((i) => i.pertinentFindings).map((f) => f.id),
      ...domainInventory.getInstancesByCategory(DomainObjectType.coffret).expand((i) => i.pertinentFindings).map((f) => f.id),
      ...ptInstances.expand((i) => i.pertinentFindings).map((f) => f.id),
      ...foudreInstances.expand((i) => i.pertinentFindings).map((f) => f.id),
    };
    final btFindings = domainInventory.pertinentFindings
        .where((f) => f.tensionDomain == TensionDomain.bt)
        .toList();
    final orphanBtFindings = btFindings
        .where((f) => !accountedBtFindingIds.contains(f.id))
        .toList();
    if (orphanBtFindings.isNotEmpty) {
      btCatRows.add(
        buildCategoryRow(
          'Autres équipements BT',
          const [],
          totalMissionNc,
          customFindings: orphanBtFindings,
        ),
      );
    }

    final btTotalEq = btCatRows.fold(0, (s, r) => s + r.equipementsCount);
    final btTotalCrit = btCatRows.fold(0, (s, r) => s + r.critiquesCount);
    final btTotalMaj = btCatRows.fold(0, (s, r) => s + r.majeuresCount);
    final btTotalNc = btCatRows.fold(0, (s, r) => s + r.ncCount);
    final btTotalCrossRow = CategoryCrossAuditRow(
      categoryName: 'TOTAL BASSE TENSION (BT)',
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

    // Lignes d'exploitation et maintenance BT (excluant les dispositions constructives)
    final btExploitationCatRows = <CategoryCrossAuditRow>[];
    final btExploitLocauxGeFindings = btLocauxGeFindings
        .where((f) => !_isDispositionConstructiveFinding(f))
        .toList();
    final btExploitLocauxBtFindings = btLocauxBtFindings
        .where((f) => !_isDispositionConstructiveFinding(f))
        .toList();
    btExploitationCatRows.add(
      buildCategoryRow(
        'Locaux techniques GE',
        domainInventory.getInstancesByCategory(DomainObjectType.localGE),
        totalMissionNc,
        customFindings: btExploitLocauxGeFindings,
      ),
    );
    btExploitationCatRows.add(
      buildCategoryRow(
        'Locaux techniques BT',
        domainInventory.getInstancesByCategory(DomainObjectType.localBT),
        totalMissionNc,
        customFindings: btExploitLocauxBtFindings,
      ),
    );
    final invInstances = domainInventory.getInstancesByCategory(DomainObjectType.inverseur);
    final invExploitFindings = invInstances
        .expand((i) => i.pertinentFindings)
        .where((f) => !_isDispositionConstructiveFinding(f))
        .toList();
    btExploitationCatRows.add(
      buildCategoryRow(
        'Inverseur',
        invInstances,
        totalMissionNc,
        customFindings: invExploitFindings,
      ),
    );
    final tgbtInstances = domainInventory.getInstancesByCategory(DomainObjectType.tgbt);
    final tgbtExploitFindings = tgbtInstances
        .expand((i) => i.pertinentFindings)
        .where((f) => !_isDispositionConstructiveFinding(f))
        .toList();
    btExploitationCatRows.add(
      buildCategoryRow(
        'TGBT',
        tgbtInstances,
        totalMissionNc,
        customFindings: tgbtExploitFindings,
      ),
    );
    final armoireInstances = domainInventory.getInstancesByCategory(DomainObjectType.armoire);
    final armoireExploitFindings = armoireInstances
        .expand((i) => i.pertinentFindings)
        .where((f) => !_isDispositionConstructiveFinding(f))
        .toList();
    btExploitationCatRows.add(
      buildCategoryRow(
        'Armoires',
        armoireInstances,
        totalMissionNc,
        customFindings: armoireExploitFindings,
      ),
    );
    final coffretInstances = domainInventory.getInstancesByCategory(DomainObjectType.coffret);
    final coffretExploitFindings = coffretInstances
        .expand((i) => i.pertinentFindings)
        .where((f) => !_isDispositionConstructiveFinding(f))
        .toList();
    btExploitationCatRows.add(
      buildCategoryRow(
        'Coffrets',
        coffretInstances,
        totalMissionNc,
        customFindings: coffretExploitFindings,
      ),
    );
    if (ptInstances.isNotEmpty) {
      final ptExploitFindings = ptInstances
          .expand((i) => i.pertinentFindings)
          .where((f) => !_isDispositionConstructiveFinding(f))
          .toList();
      btExploitationCatRows.add(
        buildCategoryRow(
          'Prises de terre mesurées',
          ptInstances,
          totalMissionNc,
          customFindings: ptExploitFindings,
        ),
      );
    }
    if (foudreInstances.isNotEmpty) {
      final foudreExploitFindings = foudreInstances
          .expand((i) => i.pertinentFindings)
          .where((f) => !_isDispositionConstructiveFinding(f))
          .toList();
      btExploitationCatRows.add(
        buildCategoryRow(
          'Installations Foudre',
          foudreInstances,
          totalMissionNc,
          customFindings: foudreExploitFindings,
        ),
      );
    }
    final accountedBtExploitFindingIds = <String>{
      ...btExploitLocauxGeFindings.map((f) => f.id),
      ...btExploitLocauxBtFindings.map((f) => f.id),
      ...invExploitFindings.map((f) => f.id),
      ...tgbtExploitFindings.map((f) => f.id),
      ...armoireExploitFindings.map((f) => f.id),
      ...coffretExploitFindings.map((f) => f.id),
      if (ptInstances.isNotEmpty)
        ...ptInstances.expand((i) => i.pertinentFindings).where((f) => !_isDispositionConstructiveFinding(f)).map((f) => f.id),
      if (foudreInstances.isNotEmpty)
        ...foudreInstances.expand((i) => i.pertinentFindings).where((f) => !_isDispositionConstructiveFinding(f)).map((f) => f.id),
    };
    final orphanBtExploitFindings = btFindings
        .where((f) => !_isDispositionConstructiveFinding(f) && !accountedBtExploitFindingIds.contains(f.id))
        .toList();
    if (orphanBtExploitFindings.isNotEmpty) {
      btExploitationCatRows.add(
        buildCategoryRow(
          'Autres équipements BT',
          const [],
          totalMissionNc,
          customFindings: orphanBtExploitFindings,
        ),
      );
    }
    final btExploitTotalEq = btExploitationCatRows.fold(0, (s, r) => s + r.equipementsCount);
    final btExploitTotalCrit = btExploitationCatRows.fold(0, (s, r) => s + r.critiquesCount);
    final btExploitTotalMaj = btExploitationCatRows.fold(0, (s, r) => s + r.majeuresCount);
    final btExploitTotalNc = btExploitationCatRows.fold(0, (s, r) => s + r.ncCount);
    final btExploitationTotalCrossRow = CategoryCrossAuditRow(
      categoryName: 'TOTAL BASSE TENSION (BT)',
      equipementsCount: btExploitTotalEq,
      ncCount: btExploitTotalNc,
      critiquesCount: btExploitTotalCrit,
      majeuresCount: btExploitTotalMaj,
      pctOfTotalNc: totalMissionNc > 0
          ? (btExploitTotalNc / totalMissionNc) * 100.0
          : 0.0,
      tauxCritique: btExploitTotalNc > 0 ? (btExploitTotalCrit / btExploitTotalNc) * 100.0 : 0.0,
      densite: btExploitTotalEq > 0 ? (btExploitTotalNc / btExploitTotalEq) : 0.0,
    );

    // 10. Populations d'appareillages et diversification de marque
    final allCoffrets = [
      DomainObjectType.tgbt,
      DomainObjectType.armoire,
      DomainObjectType.coffret,
      DomainObjectType.inverseur,
    ]
        .expand((cat) => domainInventory.getInstancesByCategory(cat))
        .map((i) => i.rawModelRef)
        .whereType<CoffretArmoire>()
        .toList();

    // A. Protections de tête (bloc de saisie protectionTete des coffrets/armoires)
    final eligibleTete =
        allCoffrets.where((c) => c.protectionTete != null).toList();
    final totalEligiblesTete = eligibleTete.length;
    final withProtectionTete = eligibleTete.where((c) {
      final t = c.protectionTete!.typeProtection.trim().toLowerCase();
      return t.isNotEmpty &&
          t != 'aucun' &&
          t != 'sans' &&
          t != '-' &&
          t != 'non';
    }).toList();
    final withProtectionCountTete = withProtectionTete.length;
    final protectionRateTete = totalEligiblesTete > 0
        ? (withProtectionCountTete / totalEligiblesTete) * 100.0
        : 0.0;
    final formattedProtectionRateTete =
        '${protectionRateTete.toStringAsFixed(1).replaceAll('.', ',')} %';

    final brandCountsTete = <String, int>{};
    for (final c in withProtectionTete) {
      final rawM = c.protectionTete!.marqueDisjoncteur?.trim();
      final brand = _normalizeBrandExplicit(rawM);
      brandCountsTete[brand] = (brandCountsTete[brand] ?? 0) + 1;
    }
    final sortedBrandsTete = brandCountsTete.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });
    final sortedBrandCountsTete = {
      for (final e in sortedBrandsTete) e.key: e.value,
    };
    final brandPercentagesTete = <String, double>{};
    for (final e in sortedBrandsTete) {
      brandPercentagesTete[e.key] = withProtectionCountTete > 0
          ? (e.value / withProtectionCountTete) * 100.0
          : 0.0;
    }

    final protectionsTeteBrandStats = EquipmentBrandPopulationStats(
      populationTitle: 'Protections de tête',
      totalEligibles: totalEligiblesTete,
      withProtectionCount: withProtectionCountTete,
      protectionRate: protectionRateTete,
      formattedProtectionRate: formattedProtectionRateTete,
      brandCounts: sortedBrandCountsTete,
      brandPercentages: brandPercentagesTete,
    );

    // B. Départs
    final allDepartures = <DepartEquipement>[];
    for (final c in allCoffrets) {
      if (c.departures != null) {
        allDepartures.addAll(c.departures!);
      }
    }
    final totalEligiblesDep = allDepartures.length;
    final withProtectionDep = allDepartures.where((d) {
      final t = d.typeProtection.trim().toLowerCase();
      return t.isNotEmpty &&
          t != 'aucun' &&
          t != 'sans' &&
          t != '-' &&
          t != 'non';
    }).toList();
    final withProtectionCountDep = withProtectionDep.length;
    final protectionRateDep = totalEligiblesDep > 0
        ? (withProtectionCountDep / totalEligiblesDep) * 100.0
        : 0.0;
    final formattedProtectionRateDep =
        '${protectionRateDep.toStringAsFixed(1).replaceAll('.', ',')} %';

    final brandCountsDep = <String, int>{};
    for (final d in withProtectionDep) {
      final brand = _normalizeBrandExplicit(d.marque);
      brandCountsDep[brand] = (brandCountsDep[brand] ?? 0) + 1;
    }
    final sortedBrandsDep = brandCountsDep.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });
    final sortedBrandCountsDep = {
      for (final e in sortedBrandsDep) e.key: e.value,
    };
    final brandPercentagesDep = <String, double>{};
    for (final e in sortedBrandsDep) {
      brandPercentagesDep[e.key] = withProtectionCountDep > 0
          ? (e.value / withProtectionCountDep) * 100.0
          : 0.0;
    }

    final departsBrandStats = EquipmentBrandPopulationStats(
      populationTitle: 'Départs',
      totalEligibles: totalEligiblesDep,
      withProtectionCount: withProtectionCountDep,
      protectionRate: protectionRateDep,
      formattedProtectionRate: formattedProtectionRateDep,
      brandCounts: sortedBrandCountsDep,
      brandPercentages: brandPercentagesDep,
    );

    // C. Circuits terminaux
    final allCircuits = <CircuitTerminalEquipement>[];
    for (final c in allCoffrets) {
      if (c.terminalCircuits != null) {
        allCircuits.addAll(c.terminalCircuits!);
      }
    }
    final totalEligiblesCirc = allCircuits.length;
    final withProtectionCirc = allCircuits.where((ct) {
      final t = ct.typeProtection.trim().toLowerCase();
      return t.isNotEmpty &&
          t != 'aucun' &&
          t != 'sans' &&
          t != '-' &&
          t != 'non';
    }).toList();
    final withProtectionCountCirc = withProtectionCirc.length;
    final protectionRateCirc = totalEligiblesCirc > 0
        ? (withProtectionCountCirc / totalEligiblesCirc) * 100.0
        : 0.0;
    final formattedProtectionRateCirc =
        '${protectionRateCirc.toStringAsFixed(1).replaceAll('.', ',')} %';

    final brandCountsCirc = <String, int>{};
    for (final ct in withProtectionCirc) {
      final brand = _normalizeBrandExplicit(ct.marque);
      brandCountsCirc[brand] = (brandCountsCirc[brand] ?? 0) + 1;
    }
    final sortedBrandsCirc = brandCountsCirc.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });
    final sortedBrandCountsCirc = {
      for (final e in sortedBrandsCirc) e.key: e.value,
    };
    final brandPercentagesCirc = <String, double>{};
    for (final e in sortedBrandsCirc) {
      brandPercentagesCirc[e.key] = withProtectionCountCirc > 0
          ? (e.value / withProtectionCountCirc) * 100.0
          : 0.0;
    }

    final circuitsBrandStats = EquipmentBrandPopulationStats(
      populationTitle: 'Circuits',
      totalEligibles: totalEligiblesCirc,
      withProtectionCount: withProtectionCountCirc,
      protectionRate: protectionRateCirc,
      formattedProtectionRate: formattedProtectionRateCirc,
      brandCounts: sortedBrandCountsCirc,
      brandPercentages: brandPercentagesCirc,
    );

    final totalMajeuresHta = domainInventory.pertinentFindings
        .where((f) => f.tensionDomain == TensionDomain.mt && f.criticality.trim().toLowerCase().contains('majeur'))
        .length;
    final totalMajeuresBt = domainInventory.pertinentFindings
        .where((f) => f.tensionDomain == TensionDomain.bt && f.criticality.trim().toLowerCase().contains('majeur'))
        .length;
    final totalMissionMajeures = findingInventory.majeureCount;

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
      ipIkHierarchy: ipIkHierarchy,
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
      mtExploitationCrossRows: mtExploitationCatRows,
      btExploitationCrossRows: btExploitationCatRows,
      mtExploitationTotalCrossRow: mtExploitationTotalCrossRow,
      btExploitationTotalCrossRow: btExploitationTotalCrossRow,
      totalZonesAudit: totalZonesAudit,
      totalZonesClasseesCount: totalZonesClasseesCount,
      totalLocauxAudit: totalLocauxAudit,
      totalLocauxClassesCount: totalLocauxClassesCount,
      totalDepartsAudit: totalDepartsAuditAll,
      totalDepartsAvecProtection: totalDepartsAvecProtAll,
      totalCircuitsAudit: totalCircuitsAuditAll,
      totalCircuitsAvecProtection: totalCircuitsAvecProtAll,
      protectionsTeteBrandStats: protectionsTeteBrandStats,
      departsBrandStats: departsBrandStats,
      circuitsBrandStats: circuitsBrandStats,
      totalEquipementsEligiblesIpIk: totalEquipementsEligiblesIpIk,
      totalEquipementsClassesIpIk: totalEquipementsClassesIpIk,
      totalMissionNc: totalMissionNc,
      totalMissionMajeures: totalMissionMajeures,
      totalHtaMajeures: totalMajeuresHta,
      totalBtMajeures: totalMajeuresBt,
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  MÉTHODES INTERNES DE CALCUL
  // ──────────────────────────────────────────────────────────────

  static EssaisCoverageStats _computeEssaisCoverage(
    MesuresEssais? m, {
    DescriptionInstallations? desc,
    int locauxGe = 0,
    List<dynamic> transfos = const [],
  }) {
    if (m == null) {
      return const EssaisCoverageStats(
        prisesTerreCount: 0,
        testDdrCount: 0,
        mesureIsolementCount: 0,
        testCpiCount: 0,
        continuitePeCount: 0,
        demarrageGeCount: 0,
        arretUrgenceCount: 0,
        isArretUrgenceApplicable: false,
        isDemarrageGeApplicable: false,
        isCpiApplicable: false,
      );
    }

    final hasDemarrage =
        m.essaiDemarrageAuto.observation?.trim().isNotEmpty == true;
    final hasArretUrg =
        m.testArretUrgence.observation?.trim().isNotEmpty == true;

    // Détermination de l'applicabilité :
    // 1. Arrêt d'urgence : sans objet si explicitement non présent (presence == false)
    final bool isArretUrgenceApplicable = m.testArretUrgence.presence != false;

    // 2. Démarrage GE : applicable si un GE est renseigné ou si un local GE existe
    final bool hasGeOnSite =
        (desc != null && desc.groupeElectrogene.isNotEmpty) || locauxGe > 0;
    final bool isDemarrageGeApplicable = hasGeOnSite || hasDemarrage;

    // 3. CPI : applicable uniquement en régime IT (description ou transformateurs) et si un CPI est recensé ou testé
    final Set<String> descRegimes = desc != null
        ? InstallationDescriptionSyncService.extractRegimesFromText(
            desc.regimeNeutre,
            detail: desc.regimeNeutreDetail,
          )
        : <String>{};
    final bool hasItRegime = descRegimes.contains('IT') ||
        transfos.any((t) {
          if (t is TransformateurMTBT) {
            return t.regimeNeutre.trim().toUpperCase() == 'IT';
          }
          return false;
        });

    final bool hasValidCpiInDesc = desc != null &&
        desc.cpi.any((item) {
          final d = item.data;
          final res = d['RESULTAT_TEST']?.trim().toLowerCase();
          if (res == 'sans objet' || res == 'néant' || res == 'neant') {
            return false;
          }
          return (d['MARQUE']?.trim().isNotEmpty == true) ||
              (d['TYPE']?.trim().isNotEmpty == true) ||
              (d['SEUIL DE RÉGLAGE (kΩ)']?.trim().isNotEmpty == true);
        });

    final bool isCpiApplicable =
        (hasItRegime && hasValidCpiInDesc) || m.cpiTests.isNotEmpty;

    return EssaisCoverageStats(
      prisesTerreCount: m.prisesTerre.length,
      testDdrCount: m.essaisDeclenchement.length,
      mesureIsolementCount: m.essaisIsolement.length,
      testCpiCount: m.cpiTests.length,
      continuitePeCount: m.continuiteResistances.length,
      demarrageGeCount: hasDemarrage ? 1 : 0,
      arretUrgenceCount: hasArretUrg ? 1 : 0,
      isArretUrgenceApplicable: isArretUrgenceApplicable,
      isDemarrageGeApplicable: isDemarrageGeApplicable,
      isCpiApplicable: isCpiApplicable,
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

  static String _normalizeBrandExplicit(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Non définie';
    final s = raw.trim();
    final sUpper = s.toUpperCase();
    if (s == '-' ||
        sUpper == 'AUCUN' ||
        sUpper == 'AUCUNE' ||
        sUpper == 'SANS' ||
        sUpper.contains('NON RENSEIGN') ||
        sUpper.contains('INCONNU')) {
      return 'Non définie';
    }
    if (sUpper.contains('SCHNEIDER') ||
        sUpper.contains('MERLIN') ||
        sUpper.contains('TELEMECANIQUE')) {
      return 'Schneider Electric';
    }
    if (sUpper.contains('ABB')) return 'ABB';
    if (sUpper.contains('LEGRAND')) return 'Legrand';
    if (sUpper.contains('HAGER')) return 'Hager';
    if (sUpper.contains('SIEMENS')) return 'Siemens';
    if (sUpper.contains('EATON')) return 'Eaton';
    return s;
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

    // Filtre brouillons & éléments non finalisés et dédoublonnage strict par instanceId
    final seenInstanceIds = <String>{};
    final allEquipmentInstances = <DomainEntityInstance>[];
    for (final i in domainInventory.instances) {
      if (!equipmentCategories.contains(i.category)) continue;
      final raw = i.rawModelRef;
      if (raw is CoffretArmoire) {
        final st = raw.statut.trim().toLowerCase();
        if (st == 'incomplet' || st == 'brouillon') {
          continue;
        }
      }
      if (seenInstanceIds.add(i.instanceId)) {
        allEquipmentInstances.add(i);
      }
    }

    // Regroupement hiérarchique strict des équipements par repère d'affectation
    // Structure : Local si présent, sinon Zone directe.
    // Garantit l'absence totale de doublons et le respect de la population réelle.
    final groupedEquipments = <String, List<DomainEntityInstance>>{};
    final locationMeta =
        <String, ({bool isLocal, String? localName, String? zoneName, String label})>{};

    for (final inst in allEquipmentInstances) {
      final pLocal = inst.parentLocal?.trim();
      final pZone = inst.parentZone?.trim();

      final String key;
      if (pLocal != null && pLocal.isNotEmpty) {
        key = 'LOCAL:${pZone?.toLowerCase() ?? ""}:${pLocal.toLowerCase()}';
        locationMeta.putIfAbsent(
          key,
          () => (
            isLocal: true,
            localName: pLocal,
            zoneName: pZone,
            label: (pZone != null && pZone.isNotEmpty) ? '$pLocal ($pZone)' : pLocal,
          ),
        );
      } else {
        final zName =
            (pZone != null && pZone.isNotEmpty) ? pZone : 'Zone non spécifiée';
        key = 'ZONE:${zName.toLowerCase()}';
        locationMeta.putIfAbsent(
          key,
          () => (
            isLocal: false,
            localName: null,
            zoneName: pZone,
            label: zName,
          ),
        );
      }
      groupedEquipments.putIfAbsent(key, () => []).add(inst);
    }

    final result = <IpIkZoneItem>[];

    for (final entry in groupedEquipments.entries) {
      final key = entry.key;
      final equipList = entry.value;
      final meta = locationMeta[key]!;

      String? reqIp;
      String? reqIk;

      if (meta.isLocal) {
        // 1. Recherche dans les classements de locaux (ClassementEmplacement)
        ClassementEmplacement? matchedEmp;
        for (final emp in emplacements) {
          if (emp.localisation.trim().toLowerCase() ==
              meta.localName!.toLowerCase()) {
            if (emp.zone != null &&
                emp.zone!.trim().isNotEmpty &&
                meta.zoneName != null &&
                meta.zoneName!.trim().isNotEmpty) {
              if (emp.zone!.trim().toLowerCase() ==
                  meta.zoneName!.toLowerCase()) {
                matchedEmp = emp;
                break;
              }
            } else {
              matchedEmp = emp;
            }
          }
        }

        if (matchedEmp != null) {
          reqIp = matchedEmp.ipEffective ?? matchedEmp.ip;
          reqIk = matchedEmp.ikEffective ?? matchedEmp.ik;
        }
        // Strict : Si le local n'a pas d'indice IP/IK requis spécifié dans ClassementEmplacement,
        // on n'invente AUCUN indice attendu (pas de fallback sur la zone) afin de ne pas fausser l'évaluation.
      } else {
        // 2. Recherche dans les classements de zones (ClassementZone)
        if (meta.zoneName != null) {
          for (final z in zones) {
            if (z.nomZone.trim().toLowerCase() ==
                meta.zoneName!.toLowerCase()) {
              reqIp = z.ip;
              reqIk = z.ik;
              break;
            }
          }
        }
      }

      int adequatCount = 0;
      int presentDifferentCount = 0;
      int absentCount = 0;
      int nonEvaluableCount = 0;

      for (final inst in equipList) {
        String? obsIpIk;
        final raw = inst.rawModelRef;
        if (raw is CoffretArmoire) {
          final ipVal = raw.indiceIpIk?.trim();
          obsIpIk = (ipVal != null &&
                  ipVal.isNotEmpty &&
                  ipVal != '-' &&
                  ipVal.toLowerCase() != 'absent')
              ? ipVal
              : null;
        }

        final status = IpIkEvaluator.evaluate(
          reqIp: reqIp,
          reqIk: reqIk,
          obsRaw: obsIpIk,
        );

        switch (status) {
          case IpIkAdequationStatus.adequat:
            adequatCount++;
            break;
          case IpIkAdequationStatus.presentDifferent:
            presentDifferentCount++;
            break;
          case IpIkAdequationStatus.absent:
            absentCount++;
            break;
          case IpIkAdequationStatus.nonEvaluable:
            nonEvaluableCount++;
            break;
        }
      }

      result.add(
        IpIkZoneItem(
          zoneNom: meta.label,
          parentZoneNom: meta.zoneName,
          isLocal: meta.isLocal,
          ipRequis: reqIp,
          ikRequis: reqIk,
          totalEquipements: equipList.length,
          adequatCount: adequatCount,
          presentDifferentCount: presentDifferentCount,
          absentCount: absentCount,
          nonEvaluableCount: nonEvaluableCount,
          indicesPresents: adequatCount + presentDifferentCount,
        ),
      );
    }

    result.sort(
      (a, b) => a.zoneNom.toLowerCase().compareTo(b.zoneNom.toLowerCase()),
    );

    return result;
  }

  @visibleForTesting
  static List<IpIkZoneHierarchyItem> computeIpIkHierarchy(
    String missionId,
    MissionDomainInventory domainInventory,
  ) => _computeIpIkHierarchy(missionId, domainInventory);

  static List<IpIkZoneHierarchyItem> _computeIpIkHierarchy(
    String missionId,
    MissionDomainInventory domainInventory,
  ) {
    AuditInstallationsElectriques? audit;
    List<ClassementZone> zones = [];
    List<ClassementEmplacement> emplacements = [];
    try {
      audit = HiveService.getAuditInstallationsByMissionId(missionId);
      zones = HiveService.getClassementsZonesByMissionId(missionId);
      emplacements = HiveService.getEmplacementsByMissionId(missionId);
    } catch (_) {
      audit = null;
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

    // Filtre brouillons & dédoublonnage strict par instanceId
    final seenInstanceIds = <String>{};
    final allEquipmentInstances = <DomainEntityInstance>[];
    for (final i in domainInventory.instances) {
      if (!equipmentCategories.contains(i.category)) continue;
      final raw = i.rawModelRef;
      if (raw is CoffretArmoire) {
        final st = raw.statut.trim().toLowerCase();
        if (st == 'incomplet' || st == 'brouillon') {
          continue;
        }
      }
      if (seenInstanceIds.add(i.instanceId)) {
        allEquipmentInstances.add(i);
      }
    }

    // 1. Recenser toutes les Zones de la mission
    final orderedZoneNames = <String>[];
    final zoneLocalsMap = <String, List<String>>{}; // zoneKey -> list of local names
    final zoneLocalsOriginalMap = <String, Map<String, String>>{}; // zoneKey -> {localKey: localOriginal}

    if (audit != null) {
      for (final z in audit.moyenneTensionZones) {
        final zNom = z.nom.trim();
        if (zNom.isNotEmpty && !orderedZoneNames.any((name) => name.toLowerCase() == zNom.toLowerCase())) {
          orderedZoneNames.add(zNom);
        }
        final zKey = zNom.toLowerCase();
        zoneLocalsMap.putIfAbsent(zKey, () => []);
        zoneLocalsOriginalMap.putIfAbsent(zKey, () => {});
        for (final l in z.locaux) {
          final lNom = l.nom.trim();
          if (lNom.isNotEmpty) {
            final lKey = lNom.toLowerCase();
            if (!zoneLocalsOriginalMap[zKey]!.containsKey(lKey)) {
              zoneLocalsOriginalMap[zKey]![lKey] = lNom;
              zoneLocalsMap[zKey]!.add(lNom);
            }
          }
        }
      }

      for (final z in audit.basseTensionZones) {
        final zNom = z.nom.trim();
        if (zNom.isNotEmpty && !orderedZoneNames.any((name) => name.toLowerCase() == zNom.toLowerCase())) {
          orderedZoneNames.add(zNom);
        }
        final zKey = zNom.toLowerCase();
        zoneLocalsMap.putIfAbsent(zKey, () => []);
        zoneLocalsOriginalMap.putIfAbsent(zKey, () => {});
        for (final l in z.locaux) {
          final lNom = l.nom.trim();
          if (lNom.isNotEmpty) {
            final lKey = lNom.toLowerCase();
            if (!zoneLocalsOriginalMap[zKey]!.containsKey(lKey)) {
              zoneLocalsOriginalMap[zKey]![lKey] = lNom;
              zoneLocalsMap[zKey]!.add(lNom);
            }
          }
        }
      }
    }

    // Intégrer les zones déclarées dans ClassementZone
    for (final cz in zones) {
      final czNom = cz.nomZone.trim();
      if (czNom.isNotEmpty && !orderedZoneNames.any((name) => name.toLowerCase() == czNom.toLowerCase())) {
        orderedZoneNames.add(czNom);
        zoneLocalsMap.putIfAbsent(czNom.toLowerCase(), () => []);
        zoneLocalsOriginalMap.putIfAbsent(czNom.toLowerCase(), () => {});
      }
    }

    // Intégrer les zones trouvées dans domainInventory instances
    for (final inst in allEquipmentInstances) {
      final pZone = inst.parentZone?.trim();
      if (pZone != null && pZone.isNotEmpty) {
        final zKey = pZone.toLowerCase();
        if (!orderedZoneNames.any((name) => name.toLowerCase() == zKey)) {
          orderedZoneNames.add(pZone);
          zoneLocalsMap.putIfAbsent(zKey, () => []);
          zoneLocalsOriginalMap.putIfAbsent(zKey, () => {});
        }
        final pLocal = inst.parentLocal?.trim();
        if (pLocal != null && pLocal.isNotEmpty) {
          final lKey = pLocal.toLowerCase();
          zoneLocalsMap.putIfAbsent(zKey, () => []);
          zoneLocalsOriginalMap.putIfAbsent(zKey, () => {});
          if (!zoneLocalsOriginalMap[zKey]!.containsKey(lKey)) {
            zoneLocalsOriginalMap[zKey]![lKey] = pLocal;
            zoneLocalsMap[zKey]!.add(pLocal);
          }
        }
      }
    }

    // Intégrer les locaux déclarés dans ClassementEmplacement rattachés à une zone
    for (final emp in emplacements) {
      if (emp.isLocal && emp.zone != null && emp.zone!.trim().isNotEmpty) {
        final zKey = emp.zone!.trim().toLowerCase();
        if (zoneLocalsOriginalMap.containsKey(zKey)) {
          final lNom = emp.localisation.trim();
          if (lNom.isNotEmpty) {
            final lKey = lNom.toLowerCase();
            if (!zoneLocalsOriginalMap[zKey]!.containsKey(lKey)) {
              zoneLocalsOriginalMap[zKey]![lKey] = lNom;
              zoneLocalsMap[zKey]!.add(lNom);
            }
          }
        }
      }
    }

    // 2. Identifier les locaux autonomes hors zone (standalone locals)
    final standaloneLocalNames = <String>[];
    final standaloneLocalOriginalMap = <String, String>{};

    if (audit != null) {
      for (final l in audit.moyenneTensionLocaux) {
        final lNom = l.nom.trim();
        if (lNom.isNotEmpty) {
          final lKey = lNom.toLowerCase();
          if (!standaloneLocalOriginalMap.containsKey(lKey)) {
            standaloneLocalOriginalMap[lKey] = lNom;
            standaloneLocalNames.add(lNom);
          }
        }
      }
    }

    for (final inst in allEquipmentInstances) {
      final pZone = inst.parentZone?.trim();
      final pLocal = inst.parentLocal?.trim();
      if ((pZone == null || pZone.isEmpty) && pLocal != null && pLocal.isNotEmpty) {
        final lKey = pLocal.toLowerCase();
        if (!standaloneLocalOriginalMap.containsKey(lKey)) {
          standaloneLocalOriginalMap[lKey] = pLocal;
          standaloneLocalNames.add(pLocal);
        }
      }
    }

    for (final emp in emplacements) {
      if (emp.isLocal && (emp.zone == null || emp.zone!.trim().isEmpty)) {
        final lNom = emp.localisation.trim();
        if (lNom.isNotEmpty) {
          final lKey = lNom.toLowerCase();
          if (!standaloneLocalOriginalMap.containsKey(lKey)) {
            standaloneLocalOriginalMap[lKey] = lNom;
            standaloneLocalNames.add(lNom);
          }
        }
      }
    }

    // Helper d'évaluation d'une population d'équipements
    IpIkEquipmentStats evaluatePopulation({
      required List<DomainEntityInstance> population,
      required String? reqIp,
      required String? reqIk,
    }) {
      final hasReference = (reqIp != null && reqIp.trim().isNotEmpty) ||
          (reqIk != null && reqIk.trim().isNotEmpty);

      if (population.isEmpty) {
        return const IpIkEquipmentStats.empty();
      }

      if (!hasReference) {
        return IpIkEquipmentStats(
          totalEquipements: population.length,
          conformes: 0,
          differents: 0,
          absents: 0,
          isEvaluable: false,
        );
      }

      int conformes = 0;
      int differents = 0;
      int absents = 0;

      for (final inst in population) {
        String? obsIpIk;
        final raw = inst.rawModelRef;
        if (raw is CoffretArmoire) {
          final ipVal = raw.indiceIpIk?.trim();
          obsIpIk = (ipVal != null &&
                  ipVal.isNotEmpty &&
                  ipVal != '-' &&
                  ipVal.toLowerCase() != 'absent')
              ? ipVal
              : null;
        }

        final status = IpIkEvaluator.evaluate(
          reqIp: reqIp,
          reqIk: reqIk,
          obsRaw: obsIpIk,
        );

        switch (status) {
          case IpIkAdequationStatus.adequat:
            conformes++;
            break;
          case IpIkAdequationStatus.presentDifferent:
            differents++;
            break;
          case IpIkAdequationStatus.absent:
            absents++;
            break;
          case IpIkAdequationStatus.nonEvaluable:
            absents++;
            break;
        }
      }

      return IpIkEquipmentStats(
        totalEquipements: population.length,
        conformes: conformes,
        differents: differents,
        absents: absents,
        isEvaluable: true,
      );
    }

    final hierarchyResults = <IpIkZoneHierarchyItem>[];

    // 3. Traitement des Zones
    // Tri alphabétique des zones
    orderedZoneNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    for (final zoneNom in orderedZoneNames) {
      final zKey = zoneNom.toLowerCase();

      // Résolution du classement de la zone (formulaire de classement - influences externes)
      ClassementZone? matchedCz;
      for (final cz in zones) {
        if (cz.nomZone.trim().toLowerCase() == zKey) {
          matchedCz = cz;
          break;
        }
      }

      ClassementEmplacement? matchedZoneEmp;
      if (matchedCz == null) {
        for (final emp in emplacements) {
          if (emp.isZone && emp.localisation.trim().toLowerCase() == zKey) {
            matchedZoneEmp = emp;
            break;
          }
        }
      }

      final List<String> influences;
      if (matchedCz != null) {
        influences = [matchedCz.af, matchedCz.be, matchedCz.ae, matchedCz.ad, matchedCz.ag]
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (matchedZoneEmp != null) {
        influences = [matchedZoneEmp.af, matchedZoneEmp.be, matchedZoneEmp.ae, matchedZoneEmp.ad, matchedZoneEmp.ag]
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else {
        influences = [];
      }

      final String? reqZoneIp = matchedCz?.ip ?? matchedZoneEmp?.ipEffective ?? matchedZoneEmp?.ip;
      final String? reqZoneIk = matchedCz?.ik ?? matchedZoneEmp?.ikEffective ?? matchedZoneEmp?.ik;
      final bool isZoneClasse = influences.isNotEmpty ||
          (reqZoneIp != null && reqZoneIp.trim().isNotEmpty) ||
          (reqZoneIk != null && reqZoneIk.trim().isNotEmpty);

      final String classementDesc = influences.isNotEmpty
          ? influences.join(', ')
          : 'Zone non classée';

      // Équipements directement rattachés à la zone (hors local)
      final directEquipments = allEquipmentInstances.where((inst) {
        final pz = inst.parentZone?.trim().toLowerCase();
        final pl = inst.parentLocal?.trim();
        return pz == zKey && (pl == null || pl.isEmpty);
      }).toList();

      final directStats = evaluatePopulation(
        population: directEquipments,
        reqIp: reqZoneIp,
        reqIk: reqZoneIk,
      );

      // Locaux de la zone
      final localNamesInZone = (zoneLocalsMap[zKey] ?? [])..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final localHierarchyItems = <IpIkLocalHierarchyItem>[];

      for (final localNom in localNamesInZone) {
        final lKey = localNom.toLowerCase();

        // Résolution du classement du local dans ClassementEmplacement
        ClassementEmplacement? matchedEmp;
        for (final emp in emplacements) {
          if (emp.localisation.trim().toLowerCase() == lKey) {
            if (emp.zone != null && emp.zone!.trim().isNotEmpty) {
              if (emp.zone!.trim().toLowerCase() == zKey) {
                matchedEmp = emp;
                break;
              }
            } else {
              matchedEmp = emp;
            }
          }
        }

        final reqLocalIp = matchedEmp?.ipEffective ?? matchedEmp?.ip;
        final reqLocalIk = matchedEmp?.ikEffective ?? matchedEmp?.ik;
        final isLocalClasse = (reqLocalIp != null && reqLocalIp.trim().isNotEmpty) ||
            (reqLocalIk != null && reqLocalIk.trim().isNotEmpty);

        final localEquipments = allEquipmentInstances.where((inst) {
          final pl = inst.parentLocal?.trim().toLowerCase();
          final pz = inst.parentZone?.trim().toLowerCase();
          if (pl != lKey) return false;
          if (pz != null && pz.isNotEmpty && pz != zKey) return false;
          return true;
        }).toList();

        final localStats = evaluatePopulation(
          population: localEquipments,
          reqIp: reqLocalIp,
          reqIk: reqLocalIk,
        );

        localHierarchyItems.add(
          IpIkLocalHierarchyItem(
            localNom: localNom,
            isClasse: isLocalClasse,
            ipRequis: reqLocalIp,
            ikRequis: reqLocalIk,
            stats: localStats,
          ),
        );
      }

      hierarchyResults.add(
        IpIkZoneHierarchyItem(
          zoneNom: zoneNom,
          isHorsZone: false,
          isClasse: isZoneClasse,
          classementDescription: classementDesc,
          ipRequis: reqZoneIp,
          ikRequis: reqZoneIk,
          directEquipmentStats: directStats,
          locals: localHierarchyItems,
        ),
      );
    }

    // 4. Traitement des locaux hors zone (standalone locals)
    standaloneLocalNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    for (final localNom in standaloneLocalNames) {
      final lKey = localNom.toLowerCase();

      ClassementEmplacement? matchedEmp;
      for (final emp in emplacements) {
        if (emp.localisation.trim().toLowerCase() == lKey &&
            (emp.zone == null || emp.zone!.trim().isEmpty)) {
          matchedEmp = emp;
          break;
        }
      }
      matchedEmp ??= emplacements.firstWhere(
        (emp) => emp.localisation.trim().toLowerCase() == lKey,
        orElse: () => ClassementEmplacement(
          missionId: missionId,
          localisation: localNom,
          updatedAt: DateTime.now(),
        ),
      );

      final reqLocalIp = matchedEmp.ipEffective ?? matchedEmp.ip;
      final reqLocalIk = matchedEmp.ikEffective ?? matchedEmp.ik;
      final isLocalClasse = (reqLocalIp != null && reqLocalIp.trim().isNotEmpty) ||
          (reqLocalIk != null && reqLocalIk.trim().isNotEmpty);

      final localEquipments = allEquipmentInstances.where((inst) {
        final pl = inst.parentLocal?.trim().toLowerCase();
        final pz = inst.parentZone?.trim();
        return pl == lKey && (pz == null || pz.isEmpty);
      }).toList();

      final localStats = evaluatePopulation(
        population: localEquipments,
        reqIp: reqLocalIp,
        reqIk: reqLocalIk,
      );

      final localItem = IpIkLocalHierarchyItem(
        localNom: localNom,
        isClasse: isLocalClasse,
        ipRequis: reqLocalIp,
        ikRequis: reqLocalIk,
        stats: localStats,
      );

      hierarchyResults.add(
        IpIkZoneHierarchyItem(
          zoneNom: null,
          isHorsZone: true,
          isClasse: isLocalClasse,
          classementDescription: null,
          ipRequis: null,
          ikRequis: null,
          directEquipmentStats: const IpIkEquipmentStats.empty(),
          locals: [localItem],
        ),
      );
    }

    return hierarchyResults;
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
    final vp = f.verificationPoint.toLowerCase();
    if (vp.contains('disposition') || vp.contains('constructive')) {
      return true;
    }
    if (vp.contains('exploitation')) {
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
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });

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
