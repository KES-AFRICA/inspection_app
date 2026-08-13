import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/statistics/mission_statistics_collector.dart';

/// Capture d'écran compacte, déterministe et versionnée des données d'une mission.
///
/// Ce snapshot ne contient QUE les données pertinentes pour la rédaction
/// du résumé exécutif par l'IA (sans photos, sans structures Hive lourdes).
/// L'empreinte SHA-256 de ce snapshot permet d'invalider intelligemment le cache.
class ExecutiveSummarySnapshot {
  static const int snapshotVersion = 2;

  final String missionId;
  final String clientName;
  final String siteName;
  final String natureMission;
  final String dateRangeText;
  final String domainTension;
  final String companyName;
  final String reportNumber;
  final String reportDateStr;

  /// Statistiques de criticité certifiées issues de notre moteur métier (Source de Vérité)
  final Map<String, dynamic> officialStats;

  /// Répartition par catégorie d'équipement
  final List<Map<String, dynamic>> categoryStats;

  /// Top des défauts les plus récurrents
  final List<Map<String, dynamic>> topDefects;

  /// Répartition par famille de risques
  final List<Map<String, dynamic>> riskFamilies;

  /// Nombre d'équipements et d'installations contrôlés
  final int equipmentCount;
  final int installationsCount;
  final String globalDensityStr;

  ExecutiveSummarySnapshot({
    required this.missionId,
    required this.clientName,
    required this.siteName,
    required this.natureMission,
    required this.dateRangeText,
    required this.domainTension,
    required this.companyName,
    required this.reportNumber,
    required this.reportDateStr,
    required this.officialStats,
    required this.categoryStats,
    required this.topDefects,
    required this.riskFamilies,
    required this.equipmentCount,
    required this.installationsCount,
    required this.globalDensityStr,
  });

  /// Construit un snapshot à partir de la mission et de notre moteur de statistiques centralisé
  factory ExecutiveSummarySnapshot.fromMission(String missionId) {
    try {
      final mission = HiveService.getMissionById(missionId);
      final rg = HiveService.getRenseignementsGenerauxByMissionId(missionId);
      final summary = MissionStatisticsCollector.collectSummary(missionId);

      final clientName = mission?.nomClient.trim() ?? 'Client';
      final siteName = (rg?.nomSite != null && rg!.nomSite.trim().isNotEmpty)
          ? rg.nomSite.trim()
          : ((rg?.etablissement != null && rg!.etablissement.trim().isNotEmpty)
              ? rg.etablissement.trim()
              : clientName);

      final nature = (rg?.verificationType != null && rg!.verificationType!.trim().isNotEmpty)
          ? rg.verificationType!.trim()
          : ((mission?.natureMission != null && mission!.natureMission!.trim().isNotEmpty)
              ? mission.natureMission!.trim()
              : 'Vérification périodique réglementaire');

      final dateStart = rg?.dateDebut ?? mission?.dateIntervention;
      final dateEnd = rg?.dateFin;
      final dateText = _formatDateRange(dateStart, dateEnd);

      final companyName = 'KES INSPECTIONS AND PROJECTS';
      final reportNumber = mission?.id ?? 'KES/IP/VE/2026/001';
      final reportDate = dateEnd ?? dateStart ?? DateTime.now();
      final reportDateStr = '${reportDate.day.toString().padLeft(2, '0')}/${reportDate.month.toString().padLeft(2, '0')}/${reportDate.year}';

      final cStats = summary.criticalityStats;
      final tensionStats = summary.tensionDomainStats;
      final domainStr = (tensionStats.mtCount > 0) ? 'Moyenne et Basse Tension (MT/BT)' : 'Basse Tension (BT)';

      final eqCount = summary.equipmentInventory.length;
      final totalNc = cStats.total;

      final double globalDensity = eqCount > 0 ? totalNc / eqCount : 0.0;
      final globalDensityStr = globalDensity.toStringAsFixed(2).replaceAll('.', ',');

      // Category breakdown from summary.crossCategoryItems
      final categoryStatsList = summary.crossCategoryItems.map((c) {
        final double density = c.density;
        final double pctEq = eqCount > 0 ? (c.equipmentCount / eqCount) * 100 : 0.0;
        final double pctNc = totalNc > 0 ? (c.nonConformitiesCount / totalNc) * 100 : 0.0;
        return {
          'categoryName': c.categoryName,
          'equipmentCount': c.equipmentCount,
          'ncCount': c.nonConformitiesCount,
          'densityStr': density.toStringAsFixed(2).replaceAll('.', ','),
          'pctOfTotalEquipment': pctEq.toStringAsFixed(1).replaceAll('.', ','),
          'pctOfTotalNc': pctNc.toStringAsFixed(1).replaceAll('.', ','),
        };
      }).toList();

      final topDefectsList = summary.topDefects.take(5).map((d) {
        return {
          'title': d.title,
          'count': d.count,
          'percentage': d.percentage.toStringAsFixed(1).replaceAll('.', ','),
        };
      }).toList();

      final riskFamiliesList = summary.riskFamilyStats.take(5).map((r) {
        return {
          'name': r.name,
          'count': r.count,
          'percentage': r.percentage.toStringAsFixed(1).replaceAll('.', ','),
        };
      }).toList();

      return ExecutiveSummarySnapshot(
        missionId: missionId,
        clientName: clientName,
        siteName: siteName,
        natureMission: nature,
        dateRangeText: dateText,
        domainTension: domainStr,
        companyName: companyName,
        reportNumber: reportNumber,
        reportDateStr: reportDateStr,
        officialStats: {
          'totalNC': totalNc,
          'critique': cStats.critique,
          'majeure': cStats.majeure,
          'mineure': cStats.mineure,
          'pctCritique': cStats.pctCritique.toStringAsFixed(1).replaceAll('.', ','),
          'pctMajeure': cStats.pctMajeure.toStringAsFixed(1).replaceAll('.', ','),
          'pctMineure': cStats.pctMineure.toStringAsFixed(1).replaceAll('.', ','),
        },
        categoryStats: categoryStatsList,
        topDefects: topDefectsList,
        riskFamilies: riskFamiliesList,
        equipmentCount: eqCount,
        installationsCount: summary.installationTypeStats.length,
        globalDensityStr: globalDensityStr,
      );
    } catch (_) {
      return ExecutiveSummarySnapshot(
        missionId: missionId,
        clientName: 'Client',
        siteName: 'Site',
        natureMission: 'Vérification périodique réglementaire',
        dateRangeText: 'Période d\'intervention',
        domainTension: 'Basse Tension (BT)',
        companyName: 'KES INSPECTIONS AND PROJECTS',
        reportNumber: 'KES/IP/VE/2026/001',
        reportDateStr: '10/08/2026',
        officialStats: {
          'totalNC': 0,
          'critique': 0,
          'majeure': 0,
          'mineure': 0,
          'pctCritique': '0,0',
          'pctMajeure': '0,0',
          'pctMineure': '0,0',
        },
        categoryStats: [],
        topDefects: [],
        riskFamilies: [],
        equipmentCount: 0,
        installationsCount: 0,
        globalDensityStr: '0,00',
      );
    }
  }

  static String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return 'Période non spécifiée';
    final s = '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}';
    if (end == null || (end.year == start.year && end.month == start.month && end.day == start.day)) {
      return 'le $s';
    }
    final e = '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
    return 'du $s au $e';
  }

  /// Map déterministe avec clés triées
  Map<String, dynamic> toCanonicalMap() {
    return {
      'snapshotVersion': snapshotVersion,
      'missionId': missionId,
      'clientName': clientName,
      'siteName': siteName,
      'natureMission': natureMission,
      'dateRangeText': dateRangeText,
      'domainTension': domainTension,
      'companyName': companyName,
      'reportNumber': reportNumber,
      'reportDateStr': reportDateStr,
      'officialStats': officialStats,
      'categoryStats': categoryStats,
      'topDefects': topDefects,
      'riskFamilies': riskFamilies,
      'equipmentCount': equipmentCount,
      'installationsCount': installationsCount,
      'globalDensityStr': globalDensityStr,
    };
  }

  /// Chaîne JSON déterministe
  String toCanonicalJson() {
    return jsonEncode(toCanonicalMap());
  }

  /// Calcul de l'empreinte SHA-256 normalisée
  String computeHash() {
    final bytes = utf8.encode(toCanonicalJson());
    return sha256.convert(bytes).toString();
  }
}
