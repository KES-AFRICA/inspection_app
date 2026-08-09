// lib/services/statistics/analytics_engine.dart

import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'audit_finding.dart';
import 'domain_entity_instance.dart';
import 'mission_domain_inventory_engine.dart';

/// Item de localisation des installations à risque
class RiskInstallationItem {
  final String id;
  final String name;
  final String type; // "Local MT", "Local BT", "Zone", etc.
  final bool isRisque;
  final int critiqueCount;
  final int nonConformitiesCount;

  RiskInstallationItem({
    required this.id,
    required this.name,
    required this.type,
    required this.isRisque,
    required this.critiqueCount,
    required this.nonConformitiesCount,
  });
}

/// Item de statistiques pour les Références Normatives
class NormativeRefStatItem {
  final String reference;
  final int count;
  final double percentage;

  NormativeRefStatItem({
    required this.reference,
    required this.count,
    required this.percentage,
  });
}

/// Statistiques de photographies et d'observations (distinction stricte photo != NC)
class PhotoStats {
  final int totalPhotos;
  final int equipmentPhotos;
  final int localPhotos;
  final int zonePhotos;
  final int observationPhotos;
  final int totalObservations;

  PhotoStats({
    required this.totalPhotos,
    required this.equipmentPhotos,
    required this.localPhotos,
    required this.zonePhotos,
    required this.observationPhotos,
    required this.totalObservations,
  });
}

/// Statistiques de progression des missions
class MissionProgressStats {
  final int totalMissions;
  final int inProgressMissions;
  final int pendingMissions;
  final int completedMissions;
  final double completionRate;

  MissionProgressStats({
    required this.totalMissions,
    required this.inProgressMissions,
    required this.pendingMissions,
    required this.completedMissions,
    required this.completionRate,
  });
}

/// Statistiques globales de sauvegardes M365
class BackupStats {
  final int totalMissions;
  final int backedUpMissions;
  final int pendingBackupMissions;
  final int failedBackupMissions;

  BackupStats({
    required this.totalMissions,
    required this.backedUpMissions,
    required this.pendingBackupMissions,
    required this.failedBackupMissions,
  });
}

/// Modèle immutable de données du Dashboard Analytique unifié avec le rapport PDF
class AnalyticsDashboardData {
  final List<Mission> missions;

  // Vue globale & compteurs
  final int totalZones;
  final int totalLocaux;
  final int locauxMTCount;
  final int locauxBTCount;
  final int locauxGECount;
  final int totalEquipments;
  final int cellulesMTCount;
  final int transformateursCount;
  final int groupesElectrogenesCount;
  final int tgbtCount;
  final int armoiresCount;
  final int coffretsCount;
  final int inverseursCount;
  final int prisesTerreCount;

  // Points de vérification & Conformité
  final int totalPointsEvaluated;
  final int compliantPointsCount;
  final int nonCompliantPointsCount;
  final int naPointsCount;
  final double complianceRate;

  // Criticités
  final int critiqueCount;
  final int majeureCount;
  final int mineureCount;
  final int nonSpecifieesCount;

  // Listes analytiques métiers
  final List<TopDefectItem> topDefects;
  final List<CategoryCrossItem> crossCategoryAnalysis;
  final TensionDomainStats tensionDomainStats;
  final List<RiskInstallationItem> riskInstallations;
  final List<NormativeRefStatItem> normativeReferencesStats;
  final List<RiskFamilyItem> riskFamiliesStats;
  final PhotoStats photoStats;
  final MissionProgressStats progressStats;
  final BackupStats backupStats;

  AnalyticsDashboardData({
    required this.missions,
    required this.totalZones,
    required this.totalLocaux,
    required this.locauxMTCount,
    required this.locauxBTCount,
    required this.locauxGECount,
    required this.totalEquipments,
    required this.cellulesMTCount,
    required this.transformateursCount,
    required this.groupesElectrogenesCount,
    required this.tgbtCount,
    required this.armoiresCount,
    required this.coffretsCount,
    required this.inverseursCount,
    required this.prisesTerreCount,
    required this.totalPointsEvaluated,
    required this.compliantPointsCount,
    required this.nonCompliantPointsCount,
    required this.naPointsCount,
    required this.complianceRate,
    required this.critiqueCount,
    required this.majeureCount,
    required this.mineureCount,
    required this.nonSpecifieesCount,
    required this.topDefects,
    required this.crossCategoryAnalysis,
    required this.tensionDomainStats,
    required this.riskInstallations,
    required this.normativeReferencesStats,
    required this.riskFamiliesStats,
    required this.photoStats,
    required this.progressStats,
    required this.backupStats,
  });

  factory AnalyticsDashboardData.empty() {
    return AnalyticsDashboardData(
      missions: [],
      totalZones: 0,
      totalLocaux: 0,
      locauxMTCount: 0,
      locauxBTCount: 0,
      locauxGECount: 0,
      totalEquipments: 0,
      cellulesMTCount: 0,
      transformateursCount: 0,
      groupesElectrogenesCount: 0,
      tgbtCount: 0,
      armoiresCount: 0,
      coffretsCount: 0,
      inverseursCount: 0,
      prisesTerreCount: 0,
      totalPointsEvaluated: 0,
      compliantPointsCount: 0,
      nonCompliantPointsCount: 0,
      naPointsCount: 0,
      complianceRate: 100.0,
      critiqueCount: 0,
      majeureCount: 0,
      mineureCount: 0,
      nonSpecifieesCount: 0,
      topDefects: [],
      crossCategoryAnalysis: [],
      tensionDomainStats: TensionDomainStats(mtCount: 0, btCount: 0, totalCount: 0, mtPct: 0, btPct: 0),
      riskInstallations: [],
      normativeReferencesStats: [],
      riskFamiliesStats: [],
      photoStats: PhotoStats(
        totalPhotos: 0,
        equipmentPhotos: 0,
        localPhotos: 0,
        zonePhotos: 0,
        observationPhotos: 0,
        totalObservations: 0,
      ),
      progressStats: MissionProgressStats(
        totalMissions: 0,
        inProgressMissions: 0,
        pendingMissions: 0,
        completedMissions: 0,
        completionRate: 0,
      ),
      backupStats: BackupStats(
        totalMissions: 0,
        backedUpMissions: 0,
        pendingBackupMissions: 0,
        failedBackupMissions: 0,
      ),
    );
  }
}

/// Moteur de Diagnostic et d'Analyse Centralisé (`AnalyticsEngine`)
class AnalyticsEngine {
  /// Calcule et retourne un snapshot analytique certifié pour la liste des missions fournies.
  static AnalyticsDashboardData computeDashboardData(List<Mission> missions, {String? tensionFilter}) {
    if (missions.isEmpty) {
      return AnalyticsDashboardData.empty();
    }

    int totalZones = 0;
    int totalLocaux = 0;
    int locauxMTCount = 0;
    int locauxBTCount = 0;
    int locauxGECount = 0;

    int totalEquipments = 0;
    int cellulesMTCount = 0;
    int transformateursCount = 0;
    int groupesElectrogenesCount = 0;
    int tgbtCount = 0;
    int armoiresCount = 0;
    int coffretsCount = 0;
    int inverseursCount = 0;
    int prisesTerreCount = 0;

    int totalPointsEvaluated = 0;
    int compliantPointsCount = 0;
    int nonCompliantPointsCount = 0;
    int naPointsCount = 0;

    int critiqueCount = 0;
    int majeureCount = 0;
    int mineureCount = 0;
    int nonSpecifieesCount = 0;

    final allFindingsList = <AuditFinding>[];
    final allInstancesList = <DomainEntityInstance>[];
    final defectCountsMap = <String, int>{};
    final normRefsMap = <String, int>{};
    final riskFamiliesMap = <String, int>{};

    int totalPhotos = 0;
    int equipmentPhotos = 0;
    int localPhotos = 0;
    int zonePhotos = 0;
    int observationPhotos = 0;
    int totalObservations = 0;

    for (final mission in missions) {
      final inventory = MissionDomainInventoryEngine.buildInventory(mission.id);

      // Filtrage éventuel par Domaine de Tension (MT vs BT)
      var findings = inventory.allFindings;
      if (tensionFilter == 'MT') {
        findings = findings.where((f) => f.tensionDomain == TensionDomain.mt).toList();
      } else if (tensionFilter == 'BT') {
        findings = findings.where((f) => f.tensionDomain == TensionDomain.bt).toList();
      }

      allFindingsList.addAll(findings);
      allInstancesList.addAll(inventory.instances);

      // Cumul des instances par catégorie
      for (final inst in inventory.instances) {
        if (tensionFilter == 'MT' && inst.tensionDomain != TensionDomain.mt) continue;
        if (tensionFilter == 'BT' && inst.tensionDomain != TensionDomain.bt) continue;

        totalPointsEvaluated += inst.totalCheckpoints;
        compliantPointsCount += inst.compliantCheckpoints;
        nonCompliantPointsCount += inst.nonCompliantCheckpoints;
        naPointsCount += inst.naCheckpoints;

        switch (inst.category) {
          case DomainObjectType.localMT:
            locauxMTCount++;
            totalLocaux++;
            break;
          case DomainObjectType.localBT:
            locauxBTCount++;
            totalLocaux++;
            break;
          case DomainObjectType.localGE:
            locauxGECount++;
            totalLocaux++;
            break;
          case DomainObjectType.celluleMT:
            cellulesMTCount++;
            totalEquipments++;
            break;
          case DomainObjectType.transformateurMTBT:
            transformateursCount++;
            totalEquipments++;
            break;
          case DomainObjectType.tgbt:
            tgbtCount++;
            totalEquipments++;
            break;
          case DomainObjectType.armoire:
            armoiresCount++;
            totalEquipments++;
            break;
          case DomainObjectType.coffret:
            coffretsCount++;
            totalEquipments++;
            break;
          case DomainObjectType.inverseur:
            inverseursCount++;
            totalEquipments++;
            break;
          case DomainObjectType.priseTerre:
          case DomainObjectType.foudre:
            prisesTerreCount++;
            totalEquipments++;
            break;
        }

        // Photos sur l'équipement / local rattaché
        equipmentPhotos += inst.findings.fold<int>(0, (sum, f) => sum + f.photos.length);
      }

      // Parcourir les constats non conformes (Findings)
      for (final f in findings) {
        // Criticités
        final crit = f.criticality.trim().toLowerCase();
        if (crit.contains('critique')) {
          critiqueCount++;
        } else if (crit.contains('majeure')) {
          majeureCount++;
        } else if (crit.contains('mineure')) {
          mineureCount++;
        } else {
          nonSpecifieesCount++;
        }

        // Top points de vérification problématiques
        final point = f.verificationPoint.trim();
        if (point.isNotEmpty) {
          defectCountsMap[point] = (defectCountsMap[point] ?? 0) + 1;
        }

        // Références normatives
        final norm = f.normativeReference?.trim();
        if (norm != null && norm.isNotEmpty) {
          normRefsMap[norm] = (normRefsMap[norm] ?? 0) + 1;
        }

        // Familles de risques
        final risk = f.riskFamily?.trim();
        if (risk != null && risk.isNotEmpty) {
          riskFamiliesMap[risk] = (riskFamiliesMap[risk] ?? 0) + 1;
        }

        // Photos rattachées aux constatations
        observationPhotos += f.photos.length;
      }

      totalObservations += findings.length;

      // Zones & photos de zones
      final audit = HiveService.getAuditInstallationsByMissionId(mission.id);
      if (audit != null) {
        totalZones += audit.moyenneTensionZones.length + audit.basseTensionZones.length;
        for (final z in audit.moyenneTensionZones) {
          zonePhotos += z.photos.length;
        }
        for (final z in audit.basseTensionZones) {
          zonePhotos += z.photos.length;
        }
        localPhotos += audit.photos.length;
      }
    }

    totalPhotos = equipmentPhotos + localPhotos + zonePhotos + observationPhotos;

    // Taux de conformité global
    final evaluated = compliantPointsCount + nonCompliantPointsCount;
    double complianceRate = 100.0;
    if (evaluated > 0) {
      complianceRate = (compliantPointsCount / evaluated) * 100.0;
    } else if (totalPointsEvaluated > 0) {
      complianceRate = (compliantPointsCount / totalPointsEvaluated) * 100.0;
    }

    // Top 10 Défauts
    final sortedDefects = defectCountsMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalFindingsCount = allFindingsList.length;
    final topDefects = sortedDefects.take(10).map((e) {
      final pct = totalFindingsCount > 0 ? (e.value / totalFindingsCount) * 100.0 : 0.0;
      return TopDefectItem(
        title: e.key,
        count: e.value,
        percentage: pct,
      );
    }).toList();

    // Domaine de tension (MT vs BT)
    int mtCount = 0;
    int btCount = 0;
    for (final f in allFindingsList) {
      if (f.tensionDomain == TensionDomain.mt) {
        mtCount++;
      } else {
        btCount++;
      }
    }
    final mtPct = totalFindingsCount > 0 ? (mtCount / totalFindingsCount) * 100.0 : 0.0;
    final btPct = totalFindingsCount > 0 ? (btCount / totalFindingsCount) * 100.0 : 0.0;
    final tensionDomainStats = TensionDomainStats(
      mtCount: mtCount,
      btCount: btCount,
      totalCount: totalFindingsCount,
      mtPct: mtPct,
      btPct: btPct,
    );

    // Analyse croisée des 10 catégories d'équipements
    final categoryTrackers = <DomainObjectType, _CategorySummaryAccumulator>{};
    for (final inst in allInstancesList) {
      if (tensionFilter == 'MT' && inst.tensionDomain != TensionDomain.mt) continue;
      if (tensionFilter == 'BT' && inst.tensionDomain != TensionDomain.bt) continue;

      final acc = categoryTrackers.putIfAbsent(inst.category, () => _CategorySummaryAccumulator(inst.category));
      acc.equipmentCount++;
      acc.totalPointsEvaluated += inst.totalCheckpoints;
      acc.compliantPointsCount += inst.compliantCheckpoints;
      acc.nonCompliantPointsCount += inst.nonCompliantCheckpoints;
      acc.naPointsCount += inst.naCheckpoints;
      acc.critiqueCount += inst.critiqueCount;
      acc.majeureCount += inst.majeureCount;
      acc.mineureCount += inst.mineureCount;
    }

    final canonicalCategories = [
      DomainObjectType.localMT,
      DomainObjectType.localBT,
      DomainObjectType.localGE,
      DomainObjectType.celluleMT,
      DomainObjectType.transformateurMTBT,
      DomainObjectType.tgbt,
      DomainObjectType.armoire,
      DomainObjectType.coffret,
      DomainObjectType.inverseur,
      DomainObjectType.priseTerre,
    ];

    final crossCategoryAnalysis = canonicalCategories.map((cat) {
      final acc = categoryTrackers[cat] ?? _CategorySummaryAccumulator(cat);
      return acc.toCategoryCrossItem();
    }).where((item) => item.equipmentCount > 0 || item.totalPointsEvaluated > 0).toList();

    // Risk Installations
    final riskInstallations = <RiskInstallationItem>[];
    for (final inst in allInstancesList) {
      if (inst.critiqueCount > 0 || inst.nonCompliantCheckpoints > 3) {
        riskInstallations.add(
          RiskInstallationItem(
            id: inst.instanceId,
            name: inst.name,
            type: inst.category.label,
            isRisque: true,
            critiqueCount: inst.critiqueCount,
            nonConformitiesCount: inst.nonCompliantCheckpoints,
          ),
        );
      }
    }

    // Références normatives
    final sortedNorms = normRefsMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final normativeReferencesStats = sortedNorms.take(8).map((e) {
      final pct = totalFindingsCount > 0 ? (e.value / totalFindingsCount) * 100.0 : 0.0;
      return NormativeRefStatItem(
        reference: e.key,
        count: e.value,
        percentage: pct,
      );
    }).toList();

    // Familles de risques
    final sortedRisks = riskFamiliesMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final riskFamiliesStats = sortedRisks.map((e) {
      final pct = totalFindingsCount > 0 ? (e.value / totalFindingsCount) * 100.0 : 0.0;
      return RiskFamilyItem(
        name: e.key,
        count: e.value,
        percentage: pct,
      );
    }).toList();

    // Photos Stats
    final photoStats = PhotoStats(
      totalPhotos: totalPhotos,
      equipmentPhotos: equipmentPhotos,
      localPhotos: localPhotos,
      zonePhotos: zonePhotos,
      observationPhotos: observationPhotos,
      totalObservations: totalObservations,
    );

    // Progression des missions
    int inProgressMissions = 0;
    int pendingMissions = 0;
    int completedMissions = 0;

    for (final m in missions) {
      final st = m.status.toLowerCase();
      if (st.contains('encour') || st.contains('en cours')) {
        inProgressMissions++;
      } else if (st.contains('termine') || st.contains('terminé')) {
        completedMissions++;
      } else {
        pendingMissions++;
      }
    }

    final totalMissionsCount = missions.length;
    final completionRate = totalMissionsCount > 0 ? (completedMissions / totalMissionsCount) * 100.0 : 0.0;
    final progressStats = MissionProgressStats(
      totalMissions: totalMissionsCount,
      inProgressMissions: inProgressMissions,
      pendingMissions: pendingMissions,
      completedMissions: completedMissions,
      completionRate: completionRate,
    );

    // Backup stats
    final backupStats = BackupStats(
      totalMissions: totalMissionsCount,
      backedUpMissions: completedMissions,
      pendingBackupMissions: inProgressMissions + pendingMissions,
      failedBackupMissions: 0,
    );

    return AnalyticsDashboardData(
      missions: missions,
      totalZones: totalZones,
      totalLocaux: totalLocaux,
      locauxMTCount: locauxMTCount,
      locauxBTCount: locauxBTCount,
      locauxGECount: locauxGECount,
      totalEquipments: totalEquipments,
      cellulesMTCount: cellulesMTCount,
      transformateursCount: transformateursCount,
      groupesElectrogenesCount: groupesElectrogenesCount,
      tgbtCount: tgbtCount,
      armoiresCount: armoiresCount,
      coffretsCount: coffretsCount,
      inverseursCount: inverseursCount,
      prisesTerreCount: prisesTerreCount,
      totalPointsEvaluated: totalPointsEvaluated,
      compliantPointsCount: compliantPointsCount,
      nonCompliantPointsCount: nonCompliantPointsCount,
      naPointsCount: naPointsCount,
      complianceRate: complianceRate,
      critiqueCount: critiqueCount,
      majeureCount: majeureCount,
      mineureCount: mineureCount,
      nonSpecifieesCount: nonSpecifieesCount,
      topDefects: topDefects,
      crossCategoryAnalysis: crossCategoryAnalysis,
      tensionDomainStats: tensionDomainStats,
      riskInstallations: riskInstallations,
      normativeReferencesStats: normativeReferencesStats,
      riskFamiliesStats: riskFamiliesStats,
      photoStats: photoStats,
      progressStats: progressStats,
      backupStats: backupStats,
    );
  }
}

class _CategorySummaryAccumulator {
  final DomainObjectType category;
  int equipmentCount = 0;
  int totalPointsEvaluated = 0;
  int compliantPointsCount = 0;
  int nonCompliantPointsCount = 0;
  int naPointsCount = 0;
  int critiqueCount = 0;
  int majeureCount = 0;
  int mineureCount = 0;

  _CategorySummaryAccumulator(this.category);

  CategoryCrossItem toCategoryCrossItem() {
    final evaluated = compliantPointsCount + nonCompliantPointsCount;
    double rate = 100.0;
    if (evaluated > 0) {
      rate = (compliantPointsCount / evaluated) * 100.0;
    } else if (totalPointsEvaluated > 0) {
      rate = (compliantPointsCount / totalPointsEvaluated) * 100.0;
    }

    final density = equipmentCount > 0 ? nonCompliantPointsCount / equipmentCount : 0.0;

    return CategoryCrossItem(
      categoryKey: category.categoryKey,
      categoryName: category.label,
      equipmentCount: equipmentCount,
      totalPointsEvaluated: totalPointsEvaluated,
      compliantPointsCount: compliantPointsCount,
      nonCompliantPointsCount: nonCompliantPointsCount,
      naPointsCount: naPointsCount,
      critiqueCount: critiqueCount,
      majeureCount: majeureCount,
      mineureCount: mineureCount,
      complianceRate: rate,
      density: density,
    );
  }
}
