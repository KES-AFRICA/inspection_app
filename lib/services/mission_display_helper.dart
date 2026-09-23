// lib/services/mission_display_helper.dart
import 'package:inspec_app/models/mission.dart';

/// Helper pour le calcul déterministe des libellés d'affichage des missions.
///
/// Distingue les missions par le couple (Client + Site).
/// Le suffixe d'affichage (ex: "(2)", "(3)") est strictement un attribut
/// de présentation visuelle pour l'interface utilisateur (HomeScreen / MissionCard)
/// et NE DOIT JAMAIS modifier le `nomClient` stocké en base Hive ou utilisé
/// dans les rapports certifiés (PDF, Word, Excel).
class MissionDisplayHelper {
  /// Calcule une Map associant l'ID de chaque mission à son nom d'affichage client.
  ///
  /// Règle métier :
  /// - Normalisation de la clé : `client.trim().toLowerCase() | site.trim().toLowerCase()`
  /// - Si une seule mission correspond au couple (Client + Site) : `nomClient` original
  /// - Si plusieurs missions ont strictement le même Client ET le même Site :
  ///   - Tri déterministe et stable par `createdAt` croissant, puis par `id`.
  ///   - 1ère mission : `nomClient` original (ex: "CAMRAIL")
  ///   - 2ème mission : `"$nomClient (2)"`
  ///   - 3ème mission : `"$nomClient (3)"`
  static Map<String, String> computeDisplayNames(List<Mission> missions) {
    final Map<String, String> displayNames = {};
    if (missions.isEmpty) return displayNames;

    // Regrouper par clé normalisée (client + '|' + site)
    final Map<String, List<Mission>> groups = {};
    for (final m in missions) {
      final key = _buildKey(m.nomClient, m.nomSite);
      groups.putIfAbsent(key, () => []).add(m);
    }

    for (final group in groups.values) {
      if (group.length == 1) {
        displayNames[group.first.id] = group.first.nomClient;
      } else {
        // Tri déterministe : par date de création croissante (les plus anciennes d'abord), puis par id
        final sorted = List<Mission>.from(group)
          ..sort((a, b) {
            final comp = a.createdAt.compareTo(b.createdAt);
            if (comp != 0) return comp;
            return a.id.compareTo(b.id);
          });

        for (int i = 0; i < sorted.length; i++) {
          final mission = sorted[i];
          if (i == 0) {
            displayNames[mission.id] = mission.nomClient;
          } else {
            displayNames[mission.id] = '${mission.nomClient} (${i + 1})';
          }
        }
      }
    }

    return displayNames;
  }

  /// Retourne le nom d'affichage client pour une mission spécifique au sein d'une liste de missions.
  static String getDisplayClientName(Mission mission, List<Mission> allMissions) {
    final map = computeDisplayNames(allMissions);
    return map[mission.id] ?? mission.nomClient;
  }

  static String _buildKey(String client, String? site) {
    final c = client.trim().toLowerCase();
    final s = (site ?? '').trim().toLowerCase();
    return '$c|$s';
  }
}
