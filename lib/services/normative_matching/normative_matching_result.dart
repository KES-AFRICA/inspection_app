import '../../models/audit_installations_electriques.dart';
import '../normative_search_service.dart';

/// Niveaux de confiance certifiés pour le rapprochement normatif en 4 tiers
enum MatchingConfidenceLevel {
  /// Score >= 80.0% et candidat unique dominant -> Rattachement automatique certifié
  veryHigh,

  /// Score >= 60.0% -> Suggestion prioritaire dans l'interface utilisateur
  high,

  /// Score >= 40.0% -> Proposition ambiguë nécessitant le choix explicite de l'inspecteur
  medium,

  /// Score < 40.0% -> Confiance insuffisante, conservée intacte sans référence normative
  low;

  /// Rétrocompatibilité avec l'ancien système à 3 états
  bool get isCertain => this == MatchingConfidenceLevel.veryHigh;
  bool get isAmbiguous => this == MatchingConfidenceLevel.high || this == MatchingConfidenceLevel.medium;
  bool get isUncertain => this == MatchingConfidenceLevel.low;
}

/// Résultat détaillé de l'analyse d'une observation libre
class NormativeMatchAnalysis {
  final ObservationLibre observation;
  final NormativeSearchResult? bestMatch;
  final List<NormativeSearchResult> candidateMatches;
  final MatchingConfidenceLevel status;
  final double confidenceScore;
  final String justification;

  const NormativeMatchAnalysis({
    required this.observation,
    this.bestMatch,
    this.candidateMatches = const [],
    required this.status,
    required this.confidenceScore,
    required this.justification,
  });

  /// Auto-rattachement autorisé UNIQUEMENT si la confiance est très élevée (>= 80%) et le match valide.
  bool get shouldAutoLink => status == MatchingConfidenceLevel.veryHigh && bestMatch != null;
}

/// Rapport global d'exécution du batch de rattachement normatif sur une mission
class MissionNormativeBatchReport {
  final int totalObservationsAnalysed;
  final int autoLinkedCount;
  final int ambiguousCount;
  final int uncertainCount;
  final int alreadyLinkedCount;
  final List<NormativeMatchAnalysis> analyses;

  const MissionNormativeBatchReport({
    required this.totalObservationsAnalysed,
    required this.autoLinkedCount,
    required this.ambiguousCount,
    required this.uncertainCount,
    required this.alreadyLinkedCount,
    required this.analyses,
  });
}

