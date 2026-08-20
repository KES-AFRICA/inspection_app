import '../../models/audit_installations_electriques.dart';
import '../normative_search_service.dart';

/// Niveaux de confiance pour le rapprochement normatif
enum MatchingConfidenceLevel {
  /// Score >= 30.0% et candidat unique dominant -> Rattachement automatique
  certain,

  /// Score >= 30.0% mais plusieurs candidats très proches -> Ambigu, à réviser
  ambiguous,

  /// Score < 30.0% -> Incertain, conservé intact sans référence
  uncertain,
}

/// Résultat de l'analyse d'une observation libre
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

  bool get shouldAutoLink => status == MatchingConfidenceLevel.certain && bestMatch != null;
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
