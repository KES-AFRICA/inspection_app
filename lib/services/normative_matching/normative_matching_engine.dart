import '../../models/audit_installations_electriques.dart';
import '../normative_search_service.dart';
import 'normative_matching_result.dart';

/// Moteur intelligent certifié d'évaluation, de décision et de rattachement normatif.
class NormativeMatchingEngine {
  /// Seuil de confiance minimale pour l'auto-rattachement certifié (80%)
  static const double veryHighConfidenceThreshold = 80.0;

  /// Seuil de confiance forte pour suggestion prioritaire (60%)
  static const double highConfidenceThreshold = 60.0;

  /// Seuil de confiance moyenne (40%)
  static const double mediumConfidenceThreshold = 40.0;

  /// Écart minimal pour considérer une proposition comme nettement supérieure (10.0%)
  static const double dominanceGapThreshold = 10.0;

  /// Analyse une observation libre avec son contexte d'équipement et détermine son niveau de confiance.
  static NormativeMatchAnalysis analyze(
    ObservationLibre observation, {
    String? equipmentType,
  }) {
    // 1. Si l'observation est déjà rattachée manuellement par l'inspecteur
    if (observation.hasNormativeReference && !observation.isAutoLinked) {
      return NormativeMatchAnalysis(
        observation: observation,
        status: MatchingConfidenceLevel.veryHigh,
        confidenceScore: 100.0,
        justification: "Rattachement manuel certifié (${observation.referenceNormative})",
      );
    }

    final text = observation.texte.trim();
    if (text.length < 3) {
      return NormativeMatchAnalysis(
        observation: observation,
        status: MatchingConfidenceLevel.low,
        confidenceScore: 0.0,
        justification: "Texte d'observation trop court (< 3 caractères)",
      );
    }

    // 2. Recherche contextuelle dans le référentiel des points de vérification
    final searchResults = NormativeSearchService.search(
      text,
      equipmentType: equipmentType,
      maxResults: 8,
    );

    if (searchResults.isEmpty) {
      return NormativeMatchAnalysis(
        observation: observation,
        status: MatchingConfidenceLevel.low,
        confidenceScore: 0.0,
        justification: "Aucune correspondance pertinente trouvée dans le référentiel métier",
      );
    }

    final topMatch = searchResults.first;
    final topScore = topMatch.score;

    // Calcul de l'écart de dominance avec le second candidat
    double gapWithSecond = 100.0;
    if (searchResults.length > 1) {
      gapWithSecond = topScore - searchResults[1].score;
    }

    // 3. Évaluation stricte selon les 4 niveaux de confiance

    // Niveau 1 : TRÈS FORTE (>= 80% + Écart de dominance >= 10%)
    if (topScore >= veryHighConfidenceThreshold && gapWithSecond >= dominanceGapThreshold) {
      return NormativeMatchAnalysis(
        observation: observation,
        bestMatch: topMatch,
        candidateMatches: searchResults,
        status: MatchingConfidenceLevel.veryHigh,
        confidenceScore: topScore,
        justification: "Correspondance certifiée très forte (Score: ${topScore.toStringAsFixed(1)}%, Écart: ${gapWithSecond.toStringAsFixed(1)}%)",
      );
    }

    // Niveau 2 : FORTE (>= 60%)
    if (topScore >= highConfidenceThreshold) {
      return NormativeMatchAnalysis(
        observation: observation,
        bestMatch: topMatch,
        candidateMatches: searchResults,
        status: MatchingConfidenceLevel.high,
        confidenceScore: topScore,
        justification: "Correspondance forte suggérée (Score: ${topScore.toStringAsFixed(1)}%)",
      );
    }

    // Niveau 3 : MOYENNE (>= 40%)
    if (topScore >= mediumConfidenceThreshold) {
      return NormativeMatchAnalysis(
        observation: observation,
        bestMatch: topMatch,
        candidateMatches: searchResults,
        status: MatchingConfidenceLevel.medium,
        confidenceScore: topScore,
        justification: "Correspondance moyenne nécessitant la validation explicite de l'inspecteur (Score: ${topScore.toStringAsFixed(1)}%)",
      );
    }

    // Niveau 4 : FAIBLE (< 40%)
    return NormativeMatchAnalysis(
      observation: observation,
      bestMatch: topMatch,
      candidateMatches: searchResults,
      status: MatchingConfidenceLevel.low,
      confidenceScore: topScore,
      justification: "Confiance insuffisante (< 40%). Observation conservée intacte sans attribution automatique.",
    );
  }
}
