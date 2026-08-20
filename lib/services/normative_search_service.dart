import 'dispositions_constructives_registry.dart';

/// Modèle représentant un résultat de recherche de point de vérification
class NormativeSearchResult {
  final String key;
  final String pointVerification;
  final String referenceNormative;
  final String familleRisque;
  final String criticite;
  final double score;

  const NormativeSearchResult({
    required this.key,
    required this.pointVerification,
    required this.referenceNormative,
    required this.familleRisque,
    required this.criticite,
    required this.score,
  });
}

/// Service intelligent de recherche et d'indexation des points de vérification
class NormativeSearchService {
  static final NormativeSearchService _instance = NormativeSearchService._internal();
  factory NormativeSearchService() => _instance;
  NormativeSearchService._internal();

  static const Set<String> _stopWords = {
    'de', 'la', 'le', 'les', 'du', 'des', 'un', 'une', 'en', 'et', 'a', 'au',
    'aux', 'par', 'pour', 'dans', 'sur', 'avec', 'sans', 'est', 'sont', 'd', 'l',
    'local', 'dune', 'dun'
  };

  /// Supprime les accents et met en minuscules
  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r"[^a-z0-9\s]"), ' ');
  }

  /// Découpe en mots significatifs
  static List<String> _tokenize(String text) {
    final normalized = _normalize(text);
    return normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.length >= 2 && !_stopWords.contains(token))
        .toList();
  }

  /// Recherche intelligente par pertinence dans le référentiel des points de vérification
  static List<NormativeSearchResult> search(String query, {int maxResults = 6}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty || trimmed.length < 2) return [];

    final queryNormalized = _normalize(trimmed);
    final queryTokens = _tokenize(trimmed);
    if (queryTokens.isEmpty && queryNormalized.length < 3) return [];

    final entries = DispositionsConstructivesRegistry.getAllEntries();
    final List<NormativeSearchResult> results = [];

    for (final entry in entries.entries) {
      final label = entry.key;
      final meta = entry.value;
      final labelNormalized = _normalize(label);
      final labelTokens = _tokenize(label);

      double score = 0.0;

      // 1. Match exact ou de sous-chaîne directe
      if (labelNormalized == queryNormalized) {
        score += 100.0;
      } else if (labelNormalized.contains(queryNormalized)) {
        score += 50.0;
      }

      // 2. Matching de tokens
      int matchedTokensCount = 0;
      for (final qToken in queryTokens) {
        bool tokenMatched = false;
        for (final lToken in labelTokens) {
          if (lToken == qToken) {
            score += 15.0;
            tokenMatched = true;
            break;
          } else if (lToken.contains(qToken) || qToken.contains(lToken)) {
            score += 8.0;
            tokenMatched = true;
            break;
          }
        }
        if (tokenMatched) {
          matchedTokensCount++;
        }
      }

      // Bonus si une majorité de tokens est trouvée
      if (queryTokens.isNotEmpty && matchedTokensCount > 0) {
        final ratio = matchedTokensCount / queryTokens.length;
        score += ratio * 20.0;
      }

      if (score > 0.0) {
        results.add(
          NormativeSearchResult(
            key: labelNormalized,
            pointVerification: label,
            referenceNormative: meta.referenceNormative,
            familleRisque: meta.familleRisque,
            criticite: meta.criticite,
            score: score,
          ),
        );
      }
    }

    // Trier par score décroissant puis par longueur de libellé
    results.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return a.pointVerification.length.compareTo(b.pointVerification.length);
    });

    return results.take(maxResults).toList();
  }
}
