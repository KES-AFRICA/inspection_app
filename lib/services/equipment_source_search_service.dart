import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/hive_service.dart';

/// Résultat de recherche pour une source d'alimentation d'équipement
class EquipmentSearchResult {
  final String equipmentId;
  final String nom;
  final String? repere;
  final String type;
  final String? localisation;
  final double score;

  const EquipmentSearchResult({
    required this.equipmentId,
    required this.nom,
    this.repere,
    required this.type,
    this.localisation,
    required this.score,
  });

  /// Nom d'affichage complet pour l'UI, le rapport PDF et la sauvegarde (format: nom - local - zone)
  String get displayName {
    final buffer = StringBuffer();
    buffer.write(nom);
    if (repere != null && repere!.trim().isNotEmpty && repere!.trim().toLowerCase() != nom.trim().toLowerCase()) {
      buffer.write(' (${repere!.trim()})');
    }
    if (localisation != null && localisation!.trim().isNotEmpty) {
      buffer.write(' - ${localisation!.trim()}');
    }
    return buffer.toString();
  }
}

/// Service intelligent de recherche d'équipements sources par similarité textuelle
class EquipmentSourceSearchService {
  static const Set<String> _stopWords = {
    'de', 'la', 'le', 'les', 'du', 'des', 'un', 'une', 'en', 'et', 'a', 'au',
    'aux', 'par', 'pour', 'dans', 'sur', 'avec', 'sans', 'n', 'd', 'l'
  };

  /// Normalisation du texte (accents, minuscules, ponctuation)
  static String normalizeString(String input) => _normalize(input);

  static double calculateSimilarityScore(String textA, String textB) {
    final normA = _normalize(textA);
    final normB = _normalize(textB);
    if (normA.isEmpty || normB.isEmpty) return 0.0;
    if (normA == normB) return 1.0;
    if (normA.contains(normB) || normB.contains(normA)) return 0.8;
    final tokensA = _tokenize(textA);
    final tokensB = _tokenize(textB);
    if (tokensA.isEmpty || tokensB.isEmpty) return 0.0;
    final common = tokensA.where((t) => tokensB.contains(t)).length;
    return common / tokensA.length;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r"[^a-z0-9\s]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Tokenisation
  static List<String> _tokenize(String text) {
    final norm = _normalize(text);
    if (norm.isEmpty) return [];
    return norm
        .split(' ')
        .where((t) => t.length >= 2 && !_stopWords.contains(t))
        .toList();
  }

  /// Extrait l'ensemble des coffrets/armoires/TGBT d'un audit avec leur localisation
  static List<MapEntry<CoffretArmoire, String?>> _getAllCoffretsWithLocation(
      AuditInstallationsElectriques audit) {
    final list = <MapEntry<CoffretArmoire, String?>>[];

    void processCoffrets(List<CoffretArmoire> coffrets, String? loc) {
      for (final c in coffrets) {
        list.add(MapEntry(c, loc));
      }
    }

    // Moyenne Tension Locaux directs
    for (final l in audit.moyenneTensionLocaux) {
      final locStr = l.nom.trim().toLowerCase().startsWith('local') ? l.nom.trim() : 'Local ${l.nom.trim()}';
      processCoffrets(l.coffrets, locStr);
    }

    // Moyenne Tension Zones
    for (final z in audit.moyenneTensionZones) {
      processCoffrets(z.coffrets, z.nom.trim());
      for (final l in z.locaux) {
        final locStr = l.nom.trim().toLowerCase().startsWith('local') ? l.nom.trim() : 'Local ${l.nom.trim()}';
        processCoffrets(l.coffrets, '$locStr - ${z.nom.trim()}');
      }
    }

    // Basse Tension Zones
    for (final z in audit.basseTensionZones) {
      processCoffrets(z.coffretsDirects, z.nom.trim());
      for (final l in z.locaux) {
        final locStr = l.nom.trim().toLowerCase().startsWith('local') ? l.nom.trim() : 'Local ${l.nom.trim()}';
        processCoffrets(l.coffrets, '$locStr - ${z.nom.trim()}');
      }
    }

    return list;
  }

  /// Recherche tolérante des équipements sources d'une mission
  static List<EquipmentSearchResult> searchSources({
    required String missionId,
    required String query,
    String? excludeEquipmentId,
    int maxResults = 8,
  }) {
    final trimmedQuery = query.trim();
    final audit = HiveService.getAuditInstallationsByMissionId(missionId);
    if (audit == null) return [];

    final allItems = _getAllCoffretsWithLocation(audit);
    if (allItems.isEmpty) return [];

    final queryNorm = _normalize(trimmedQuery);
    final queryTokens = _tokenize(trimmedQuery);

    final results = <EquipmentSearchResult>[];

    for (final entry in allItems) {
      final c = entry.key;
      final loc = entry.value;

      // Exclure l'équipement actuellement en cours d'édition
      if (excludeEquipmentId != null && c.equipmentId == excludeEquipmentId) {
        continue;
      }

      // Si pas de requête saisie, retourner tous les équipements disponibles ordonnés par nom
      if (queryNorm.isEmpty) {
        results.add(
          EquipmentSearchResult(
            equipmentId: c.equipmentId,
            nom: c.nom,
            repere: c.repere,
            type: c.type,
            localisation: loc,
            score: 1.0,
          ),
        );
        continue;
      }

      // Nom, repère et numéro d'équipement
      final nomNorm = _normalize(c.nom);
      final repereNorm = c.repere != null ? _normalize(c.repere!) : '';
      final numNorm = c.numeroEquipement != null ? _normalize(c.numeroEquipement!) : '';
      final locNorm = loc != null ? _normalize(loc) : '';

      final targetText = '$nomNorm $repereNorm $numNorm $locNorm ${c.type.toLowerCase()}';

      double score = 0.0;

      // Match exact
      if (nomNorm == queryNorm || repereNorm == queryNorm) {
        score += 10.0;
      } else if (targetText.contains(queryNorm)) {
        score += 5.0;
      }

      // Match par tokens
      if (queryTokens.isNotEmpty) {
        int tokenMatches = 0;
        for (final qt in queryTokens) {
          if (targetText.contains(qt)) {
            tokenMatches++;
          }
        }
        score += (tokenMatches / queryTokens.length) * 4.0;
      }

      if (score > 0.5) {
        results.add(
          EquipmentSearchResult(
            equipmentId: c.equipmentId,
            nom: c.nom,
            repere: c.repere,
            type: c.type,
            localisation: loc,
            score: score,
          ),
        );
      }
    }

    // Trier par score décroissant puis par nom
    results.sort((a, b) {
      final cmpScore = b.score.compareTo(a.score);
      if (cmpScore != 0) return cmpScore;
      return a.nom.compareTo(b.nom);
    });

    return results.take(maxResults).toList();
  }
}
