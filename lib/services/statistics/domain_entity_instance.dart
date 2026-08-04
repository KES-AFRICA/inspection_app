// lib/services/statistics/domain_entity_instance.dart

import '../../models/audit_installations_electriques.dart';
import 'audit_finding.dart';

/// Catégories métiers canoniques des équipements et installations électriques.
enum DomainObjectType {
  localMT,
  localBT,
  localGE,
  celluleMT,
  transformateurMTBT,
  tgbt,
  armoire,
  coffret,
  inverseur,
  foudre,
}

extension DomainObjectTypeExtension on DomainObjectType {
  String get categoryKey {
    switch (this) {
      case DomainObjectType.localMT:
        return 'local_mt';
      case DomainObjectType.localBT:
        return 'local_bt';
      case DomainObjectType.localGE:
        return 'local_ge';
      case DomainObjectType.celluleMT:
        return 'cellule_mt';
      case DomainObjectType.transformateurMTBT:
        return 'transfo_mt_bt';
      case DomainObjectType.tgbt:
        return 'tgbt';
      case DomainObjectType.armoire:
        return 'armoire';
      case DomainObjectType.coffret:
        return 'coffret';
      case DomainObjectType.inverseur:
        return 'inverseur';
      case DomainObjectType.foudre:
        return 'foudre';
    }
  }

  String get label {
    switch (this) {
      case DomainObjectType.localMT:
        return 'Locaux techniques Moyenne Tension';
      case DomainObjectType.localBT:
        return 'Locaux techniques Basse Tension';
      case DomainObjectType.localGE:
        return 'Locaux techniques Groupe Électrogène';
      case DomainObjectType.celluleMT:
        return 'Cellules Moyenne Tension';
      case DomainObjectType.transformateurMTBT:
        return 'Transformateurs MT/BT';
      case DomainObjectType.tgbt:
        return 'TGBT';
      case DomainObjectType.armoire:
        return 'Armoires';
      case DomainObjectType.coffret:
        return 'Coffrets';
      case DomainObjectType.inverseur:
        return 'Inverseurs';
      case DomainObjectType.foudre:
        return 'Prises de terre / Foudre';
    }
  }

  String get shortLabel {
    switch (this) {
      case DomainObjectType.localMT:
        return 'Local MT';
      case DomainObjectType.localBT:
        return 'Local BT';
      case DomainObjectType.localGE:
        return 'Local GE';
      case DomainObjectType.celluleMT:
        return 'Cellule MT';
      case DomainObjectType.transformateurMTBT:
        return 'Transfo MT/BT';
      case DomainObjectType.tgbt:
        return 'TGBT';
      case DomainObjectType.armoire:
        return 'Armoire';
      case DomainObjectType.coffret:
        return 'Coffret';
      case DomainObjectType.inverseur:
        return 'Inverseur';
      case DomainObjectType.foudre:
        return 'Terre/Foudre';
    }
  }
}

/// Classificateur d'Équipements Électriques (`EquipmentClassifier`).
///
/// Résout de façon déterministe la véritable nature d'un [CoffretArmoire]
/// (TGBT, Armoire, Inverseur, Coffret) en analysant son type, nom, repère et domaine.
class EquipmentClassifier {
  static DomainObjectType classify(CoffretArmoire coffret) {
    final typeStr = coffret.type.trim().toLowerCase();
    final nomStr = coffret.nom.trim().toLowerCase();
    final repereStr = (coffret.repere ?? '').trim().toLowerCase();

    // 1. INVERSEUR (Source Normal/Secours)
    if (typeStr.contains('inverseur') ||
        typeStr.contains('inv') ||
        nomStr.contains('inverseur') ||
        repereStr.contains('inverseur') ||
        typeStr.contains('source secours') ||
        typeStr.contains('ge/secteur')) {
      return DomainObjectType.inverseur;
    }

    // 2. TGBT (Tableau Général Basse Tension)
    if (typeStr.contains('tgbt') ||
        typeStr.contains('t.g.b.t') ||
        nomStr.contains('tgbt') ||
        nomStr.contains('t.g.b.t') ||
        nomStr.contains('tableau general') ||
        nomStr.contains('tableau général') ||
        repereStr.contains('tgbt')) {
      return DomainObjectType.tgbt;
    }

    // 3. ARMOIRE / TUR
    if (typeStr.contains('armoire') ||
        typeStr.contains('tur') ||
        nomStr.contains('armoire') ||
        repereStr.contains('armoire')) {
      return DomainObjectType.armoire;
    }

    // 4. COFFRET (Par défaut pour les coffrets de distribution)
    return DomainObjectType.coffret;
  }
}

/// Représentation unifiée d'une instance physique d'équipement ou de local (`DomainEntityInstance`).
class DomainEntityInstance {
  final String instanceId;
  final DomainObjectType category;
  final String name;
  final String? repere;
  final TensionDomain tensionDomain;
  final String originPath;
  final String? parentZone;
  final String? parentLocal;

  int compliantCheckpoints;
  int nonCompliantCheckpoints;
  int naCheckpoints;

  int critiqueCount;
  int majeureCount;
  int mineureCount;

  final List<AuditFinding> findings;
  final dynamic rawModelRef;

  DomainEntityInstance({
    required this.instanceId,
    required this.category,
    required this.name,
    this.repere,
    required this.tensionDomain,
    required this.originPath,
    this.parentZone,
    this.parentLocal,
    this.compliantCheckpoints = 0,
    this.nonCompliantCheckpoints = 0,
    this.naCheckpoints = 0,
    this.critiqueCount = 0,
    this.majeureCount = 0,
    this.mineureCount = 0,
    List<AuditFinding>? findings,
    this.rawModelRef,
  }) : findings = findings ?? [];

  int get totalCheckpoints => compliantCheckpoints + nonCompliantCheckpoints + naCheckpoints;

  double get complianceRate {
    final valid = compliantCheckpoints + nonCompliantCheckpoints;
    if (valid > 0) {
      return (compliantCheckpoints / valid) * 100.0;
    }
    if (totalCheckpoints > 0) {
      return (compliantCheckpoints / totalCheckpoints) * 100.0;
    }
    return 100.0;
  }

  double get density => nonCompliantCheckpoints.toDouble();

  void registerCheckpoint({
    required String conformity,
    String? criticality,
  }) {
    final conf = conformity.trim().toLowerCase();
    if (conf == 'na' || conf == 's.o.' || conf == 'so' || conf == 'non_acquis') {
      naCheckpoints++;
    } else if (conf == 'oui' || conf == 'true' || conf == 'conforme') {
      compliantCheckpoints++;
    } else {
      nonCompliantCheckpoints++;
      if (criticality != null) {
        final c = criticality.trim().toLowerCase();
        if (c.contains('critique')) {
          critiqueCount++;
        } else if (c.contains('majeur')) {
          majeureCount++;
        } else if (c.contains('mineur')) {
          mineureCount++;
        }
      }
    }
  }

  CategoryCrossItem toCategoryCrossItem() {
    return CategoryCrossItem(
      categoryKey: category.categoryKey,
      categoryName: category.label,
      equipmentCount: 1,
      totalPointsEvaluated: totalCheckpoints,
      compliantPointsCount: compliantCheckpoints,
      nonCompliantPointsCount: nonCompliantCheckpoints,
      naPointsCount: naCheckpoints,
      critiqueCount: critiqueCount,
      majeureCount: majeureCount,
      mineureCount: mineureCount,
      complianceRate: complianceRate,
      density: density,
    );
  }
}
