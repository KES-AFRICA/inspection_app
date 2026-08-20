import '../../models/audit_installations_electriques.dart';
import '../normative_search_service.dart';
import 'normative_matching_result.dart';

/// Moteur intelligent haute performance d'évaluation et de décision pour le rapprochement normatif
class NormativeMatchingEngine {
  /// Seuil de confiance minimal (30%)
  static const double minConfidenceThreshold = 30.0;

  /// Écart minimal pour considérer une proposition comme nettement supérieure (15.0)
  static const double dominanceGapThreshold = 15.0;

  /// Analyse une observation libre et détermine la pertinence du rattachement normatif
  static NormativeMatchAnalysis analyze(
    ObservationLibre observation, {
    String? entityContext,
  }) {
    // Si l'observation est déjà rattachée manuellement ou précédemment
    if (observation.hasNormativeReference) {
      return NormativeMatchAnalysis(
        observation: observation,
        status: MatchingConfidenceLevel.certain,
        confidenceScore: 100.0,
        justification: "Déjà rattaché à ${observation.referenceNormative}",
      );
    }

    final text = observation.texte.trim();
    if (text.length < 3) {
      return NormativeMatchAnalysis(
        observation: observation,
        status: MatchingConfidenceLevel.uncertain,
        confidenceScore: 0.0,
        justification: "Texte d'observation trop court (< 3 caractères)",
      );
    }

    // Effectuer la recherche par similarité dans le référentiel normatif
    final searchResults = NormativeSearchService.search(text, maxResults: 8);

    if (searchResults.isEmpty) {
      return NormativeMatchAnalysis(
        observation: observation,
        status: MatchingConfidenceLevel.uncertain,
        confidenceScore: 0.0,
        justification: "Aucune correspondance trouvée dans le référentiel",
      );
    }

    final topMatch = searchResults.first;
    final topScore = topMatch.score;

    // Filtrer les candidats qui dépassent le seuil minimal de 30%
    final validCandidates = searchResults.where((r) => r.score >= minConfidenceThreshold).toList();

    // 1. Si aucun candidat ne dépasse 30% -> Incertain (score < 30%)
    if (topScore < minConfidenceThreshold || validCandidates.isEmpty) {
      return NormativeMatchAnalysis(
        observation: observation,
        bestMatch: topMatch,
        candidateMatches: searchResults,
        status: MatchingConfidenceLevel.uncertain,
        confidenceScore: topScore,
        justification: "Score insuffisant (${topScore.toStringAsFixed(1)}% < $minConfidenceThreshold%)",
      );
    }

    // 2. Si un candidat a un score >= 30% et est strictement supérieur aux autres -> Certain
    bool isSingleDominant = false;
    if (validCandidates.length == 1) {
      isSingleDominant = true;
    } else {
      final top = validCandidates[0].score;
      final second = validCandidates[1].score;
      if (top > second) {
        isSingleDominant = true;
      }
    }

    if (isSingleDominant) {
      return NormativeMatchAnalysis(
        observation: observation,
        bestMatch: topMatch,
        candidateMatches: validCandidates,
        status: MatchingConfidenceLevel.certain,
        confidenceScore: topScore,
        justification: "Correspondance certifiée unique (score: ${topScore.toStringAsFixed(1)}%)",
      );
    }

    // 3. Plusieurs candidats proches au-dessus de 30% -> Ambigu (À valider)
    return NormativeMatchAnalysis(
      observation: observation,
      bestMatch: topMatch,
      candidateMatches: validCandidates,
      status: MatchingConfidenceLevel.ambiguous,
      confidenceScore: topScore,
      justification: "Plusieurs candidats proches au-dessus de $minConfidenceThreshold%",
    );
  }
}
