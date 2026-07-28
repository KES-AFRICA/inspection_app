// lib/services/statistics/mission_statistics_collector.dart

import 'mission_tree_visitor.dart';
import 'mission_statistics.dart';

/// Moteur de Synthèse Statistique d'Inspection (Façade du Pipeline en 2 Phases).
/// 
/// Phase 1 : Inventaire Exhaustif (`MissionTreeVisitor.collectInventory`)
/// Phase 2 : Calculs & Synthèse Statistique (`MissionStatistics.compute`)
class MissionStatisticsCollector {
  /// Point d'entrée principal pour la génération des statistiques d'une mission.
  static MissionStatistics collect(String missionId) {
    // Phase 1 : Collecte de l'inventaire certifié de toutes les occurrences d'instances
    final inventory = MissionTreeVisitor.collectInventory(missionId);

    // Phase 2 : Calcul déterministe des agrégats et statistiques
    return MissionStatistics.compute(missionId, inventory);
  }
}
