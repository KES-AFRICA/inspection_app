// lib/services/statistics/domain_entity_instance.dart

import '../../models/audit_installations_electriques.dart';
import 'audit_finding.dart';

/// Catégories métiers canoniques des équipements et installations électriques.
/// Chaque valeur représente un type d'objet physique réel dans une mission d'inspection.
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
  priseTerre,
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
      case DomainObjectType.priseTerre:
        return 'prise_terre';
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
      case DomainObjectType.priseTerre:
        return 'Prises de terre mesurées';
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
      case DomainObjectType.priseTerre:
        return 'Prise de terre';
    }
  }

  /// Retourne le label normalisé à utiliser comme `objectType` dans les AuditFinding.
  /// Ce label est déterministe et indépendant du champ brut `coffret.type`.
  String get normalizedObjectType {
    switch (this) {
      case DomainObjectType.localMT:
        return 'Local MT';
      case DomainObjectType.localBT:
        return 'Local BT';
      case DomainObjectType.localGE:
        return 'Groupe Électrogène';
      case DomainObjectType.celluleMT:
        return 'Cellule MT';
      case DomainObjectType.transformateurMTBT:
        return 'Transformateur MT/BT';
      case DomainObjectType.tgbt:
        return 'TGBT';
      case DomainObjectType.armoire:
        return 'Armoire';
      case DomainObjectType.coffret:
        return 'Coffret';
      case DomainObjectType.inverseur:
        return 'Inverseur';
      case DomainObjectType.foudre:
        return 'Foudre';
      case DomainObjectType.priseTerre:
        return 'Prise de terre';
    }
  }
}

/// Classificateur d'Équipements Électriques (`EquipmentClassifier`).
///
/// Résout de façon déterministe la véritable nature d'un [CoffretArmoire]
/// (TGBT, Armoire, Inverseur, Coffret) en analysant conjointement
/// son type, son nom, son repère et son domaine de tension.
///
/// Gère aussi bien les types courts modernes ('TGBT', 'ARMOIRE', 'INVERSEUR')
/// que les anciens types longs ('Tableau urbain réduit (TUR)', etc.) des missions legacy.
class EquipmentClassifier {
  static DomainObjectType classify(CoffretArmoire coffret) {
    final typeStr = coffret.type.trim().toLowerCase();
    final nomStr = coffret.nom.trim().toLowerCase();
    final repereStr = (coffret.repere ?? '').trim().toLowerCase();

    // 1. INVERSEUR (Source Normal/Secours)
    if (_matchesInverseur(typeStr, nomStr, repereStr)) {
      return DomainObjectType.inverseur;
    }

    // 2. TGBT (Tableau Général Basse Tension)
    if (_matchesTGBT(typeStr, nomStr, repereStr)) {
      return DomainObjectType.tgbt;
    }

    // 3. ARMOIRE / TUR (inclut les anciens types "Tableau urbain réduit (TUR)")
    if (_matchesArmoire(typeStr, nomStr, repereStr)) {
      return DomainObjectType.armoire;
    }

    // 4. COFFRET (catégorie par défaut pour les coffrets de distribution)
    return DomainObjectType.coffret;
  }

  static bool _matchesInverseur(String typeStr, String nomStr, String repereStr) {
    return typeStr.contains('inverseur') ||
        typeStr == 'inv' ||
        typeStr.startsWith('inv ') ||
        nomStr.contains('inverseur') ||
        repereStr.contains('inverseur') ||
        repereStr.startsWith('inv') ||
        typeStr.contains('source secours') ||
        typeStr.contains('ge/secteur') ||
        typeStr.contains('normal/secours') ||
        nomStr.contains('normal/secours') ||
        nomStr.contains('normal / secours');
  }

  static bool _matchesTGBT(String typeStr, String nomStr, String repereStr) {
    return typeStr == 'tgbt' ||
        typeStr.contains('tgbt') ||
        typeStr.contains('t.g.b.t') ||
        typeStr.contains('tableau general') ||
        typeStr.contains('tableau général') ||
        nomStr.contains('tgbt') ||
        nomStr.contains('t.g.b.t') ||
        nomStr.contains('tableau general') ||
        nomStr.contains('tableau général') ||
        repereStr.contains('tgbt');
  }

  static bool _matchesArmoire(String typeStr, String nomStr, String repereStr) {
    return typeStr == 'armoire' ||
        typeStr.contains('armoire') ||
        typeStr == 'tur' ||
        typeStr.contains('tur') ||          // Ancien format "Tableau urbain réduit (TUR)"
        typeStr.contains('tableau urbain') ||
        nomStr.contains('armoire') ||
        nomStr.contains('tur') ||
        repereStr.contains('armoire') ||
        repereStr.contains('tur');
  }
}

/// Représentation unifiée d'une instance physique d'équipement ou de local (`DomainEntityInstance`).
///
/// Chaque objet métier découvert lors du parcours unique de la mission est encapsulé
/// dans cette structure, avec ses bilans de conformité et ses constats rattachés.
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
    if (conf == 'na' || conf == 's.o.' || conf == 'so' || conf == 'non_acquis' || conf == 'sans objet') {
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
