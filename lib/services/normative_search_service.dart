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

/// Service intelligent de recherche, d'indexation et de scoring contextuel des points de vérification.
class NormativeSearchService {
  static final NormativeSearchService _instance = NormativeSearchService._internal();
  factory NormativeSearchService() => _instance;
  NormativeSearchService._internal();

  static const Set<String> _stopWords = {
    'de', 'la', 'le', 'les', 'du', 'des', 'un', 'une', 'en', 'et', 'a', 'au',
    'aux', 'par', 'pour', 'dans', 'sur', 'avec', 'sans', 'est', 'sont', 'd', 'l',
    'dune', 'dun', 'pas', 'non', 'ne', 'ni'
  };

  /// Dictionnaire de pondération des mots (IDF - Inverse Document Frequency).
  /// Les termes génériques ont un poids faible (0.2), les termes spécifiques métiers un poids élevé (2.5 à 4.0).
  static const Map<String, double> _tokenWeights = {
    // Termes génériques (faible poids)
    'local': 0.2,
    'tableau': 0.3,
    'appareil': 0.2,
    'materiel': 0.2,
    'element': 0.2,
    'systeme': 0.2,
    'conforme': 0.1,
    'etat': 0.2,
    'presence': 0.2,
    'absence': 0.2,
    'defaut': 0.3,
    'anomalie': 0.3,
    'mauvais': 0.2,
    'bon': 0.1,
    'installation': 0.2,
    'equipement': 0.2,
    'general': 0.3,
    'constat': 0.2,
    'remarque': 0.2,
    'point': 0.2,
    'verification': 0.2,

    // Termes techniques moyens (poids 1.0)
    'cable': 1.0,
    'porte': 1.0,
    'voyant': 1.2,
    'schema': 1.5,
    'couleur': 1.2,
    'serrure': 1.2,
    'identification': 1.3,
    'reperage': 1.3,
    'borne': 1.2,
    'circuit': 1.0,
    'fixation': 1.0,

    // Termes techniques hautement spécifiques (poids 2.5 à 4.0)
    'parafoudre': 3.5,
    'differentiel': 3.5,
    'ddr': 3.5,
    'unifilaire': 3.0,
    'obturateur': 3.0,
    'ip2x': 3.5,
    'pe': 3.0,
    'terre': 2.5,
    'interrupteur': 2.5,
    'sectionneur': 2.5,
    'barrette': 3.0,
    'coupure': 2.0,
    'groupe': 2.5,
    'electrogene': 3.0,
    'disjoncteur': 2.5,
    'fusible': 2.5,
    'surintensite': 2.5,
    'surtension': 2.5,
    'transformateur': 3.0,
    'cellule': 3.0,
    'avarie': 3.0,
    'isolant': 2.5,
    'capot': 2.5,
    'barre': 2.5,
  };

  /// Normalisation avancée du texte (accents, casse, ponctuation, lemmatisation basique).
  static String _normalize(String input) {
    var normalized = input
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r"[^a-z0-9\s]"), ' ');

    // Normalisation des pluriels simples
    final words = normalized.split(RegExp(r'\s+'));
    final SingularWords = words.map((w) {
      if (w.length > 3 && w.endsWith('s') && !w.endsWith('ss')) {
        return w.substring(0, w.length - 1);
      }
      if (w.length > 4 && w.endsWith('x')) {
        return w.substring(0, w.length - 1);
      }
      return w;
    });

    return SingularWords.join(' ');
  }

  /// Synonymes métiers canoniques
  static String _canonicalToken(String token) {
    if (token == 'schemat' || token == 'unifilaire') return 'schema';
    if (token == 'ddr' || token == 'differentiel') return 'differentiel';
    if (token == 'masses' || token == 'masse') return 'terre';
    return token;
  }

  /// Découpe en mots significatifs
  static List<String> _tokenize(String text) {
    final normalized = _normalize(text);
    return normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.length >= 2 && !_stopWords.contains(token))
        .map((t) => _canonicalToken(t))
        .toList();
  }

  /// Calcule le poids d'un token
  static double _getTokenWeight(String token) {
    final canonical = _canonicalToken(token);
    return _tokenWeights[canonical] ?? 0.8;
  }

  /// Recherche par pertinence dans le référentiel des points de vérification
  static List<NormativeSearchResult> search(
    String query, {
    String? equipmentType,
    int maxResults = 6,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty || trimmed.length < 2) return [];

    final queryNormalized = _normalize(trimmed);
    final queryTokens = _tokenize(trimmed);
    if (queryTokens.isEmpty && queryNormalized.length < 3) return [];

    final entries = DispositionsConstructivesRegistry.getAllEntries();
    final List<NormativeSearchResult> results = [];

    // Calcul du poids total et max de la requête pour la normalisation du score
    double totalQueryWeight = 0.0;
    double maxQueryTokenWeight = 0.0;
    for (final qToken in queryTokens) {
      final w = _getTokenWeight(qToken);
      totalQueryWeight += w;
      if (w > maxQueryTokenWeight) maxQueryTokenWeight = w;
    }
    if (totalQueryWeight == 0.0) totalQueryWeight = 1.0;

    // Si la requête ne contient QUE des mots génériques (max weight < 1.0)
    final bool isPurelyGenericQuery = maxQueryTokenWeight < 1.0;

    for (final entry in entries.entries) {
      final label = entry.key;

      // Résolution dynamique des métadonnées contextuelles si equipmentType est spécifié
      final meta = equipmentType != null && equipmentType.trim().isNotEmpty
          ? DispositionsConstructivesRegistry.getCoffretMetadata(label, coffretType: equipmentType) ?? entry.value
          : entry.value;

      final labelNormalized = _normalize(label);
      final labelTokens = _tokenize(label);

      double rawScore = 0.0;
      int matchedTokensCount = 0;

      // 1. Match exact ou de sous-chaîne directe
      if (labelNormalized == queryNormalized) {
        rawScore += 100.0;
        matchedTokensCount = queryTokens.length;
      } else if (!isPurelyGenericQuery && labelNormalized.contains(queryNormalized) && queryNormalized.length > 5) {
        rawScore += 60.0;
      }

      // 2. Matching de tokens avec pondération IDF
      double matchedTokensWeightSum = 0.0;
      for (final qToken in queryTokens) {
        final qWeight = _getTokenWeight(qToken);
        bool tokenMatched = false;
        for (final lToken in labelTokens) {
          if (lToken == qToken) {
            rawScore += 25.0 * qWeight;
            matchedTokensWeightSum += qWeight;
            tokenMatched = true;
            break;
          } else if (qToken.length >= 5 && lToken.length >= 5 && (lToken.contains(qToken) || qToken.contains(lToken))) {
            rawScore += 12.0 * qWeight;
            matchedTokensWeightSum += qWeight * 0.5;
            tokenMatched = true;
            break;
          }
        }
        if (tokenMatched) {
          matchedTokensCount++;
        }
      }

      // Ratio de couverture des mots de la requête
      final coverageRatio = matchedTokensWeightSum / totalQueryWeight;
      rawScore += coverageRatio * 30.0;

      // Bonus contextuel d'équipement si spécifié
      if (equipmentType != null && equipmentType.isNotEmpty) {
        final eqUpper = equipmentType.toUpperCase();
        if (labelNormalized.contains(eqUpper.toLowerCase()) ||
            (eqUpper == 'TGBT' && labelNormalized.contains('general')) ||
            (eqUpper.contains('CELLULE') && labelNormalized.contains('cellule')) ||
            (eqUpper.contains('TRANSFO') && labelNormalized.contains('transformateur'))) {
          rawScore *= 1.20; // +20% bonus de pertinence contextuelle
        }
      }

      // Normalisation du score final sur une échelle de 0.0 à 100.0
      double finalScore = 0.0;
      if (isPurelyGenericQuery) {
        // Règle d'or : Les requêtes purement génériques ("Anomalie", "Installation") ont un score plafonné à 35% (Confiance Low)
        finalScore = (coverageRatio * 35.0);
      } else if (labelNormalized == queryNormalized) {
        finalScore = 100.0;
      } else {
        finalScore = (coverageRatio * 65.0) + (rawScore > 100.0 ? 35.0 : (rawScore / 100.0) * 35.0);
        if (matchedTokensCount == 0) {
          finalScore = 0.0;
        } else if (coverageRatio >= 0.50 && maxQueryTokenWeight >= 2.5) {
          // Boost pour les requêtes explicites contenant des mots métiers hautement spécifiques
          finalScore = 80.0 + (coverageRatio * 20.0);
        }
      }

      if (finalScore > 100.0) finalScore = 100.0;

      if (finalScore >= 15.0) {
        results.add(
          NormativeSearchResult(
            key: labelNormalized,
            pointVerification: label,
            referenceNormative: meta.referenceNormative,
            familleRisque: meta.familleRisque,
            criticite: meta.criticite,
            score: finalScore,
          ),
        );
      }
    }

    // Trier par score décroissant
    results.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return a.pointVerification.length.compareTo(b.pointVerification.length);
    });

    return results.take(maxResults).toList();
  }
}

