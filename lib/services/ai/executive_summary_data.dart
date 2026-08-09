import 'dart:convert';

/// Modèle de données structurées du « RÉSUMÉ EXÉCUTIF ».
///
/// Ce modèle contient la synthèse rédigée par l'IA (ou le fallback déterministe)
/// et est consommé directement par le moteur de génération PDF `PdfReportService`.
class ExecutiveSummaryData {
  /// Synthèse générale du contexte de la mission et de l'état général des installations
  final String overview;

  /// Principaux constats et points clés observés sur le site
  final List<String> keyFindings;

  /// Synthèse des risques majeurs et critiques
  final String criticalRisksSummary;

  /// Recommandations prioritaires d'actions correctives
  final List<String> recommendations;

  /// Conclusion technique sur la maîtrise du risque électrique
  final String conclusion;

  /// Indique si ce résumé provient du fallback déterministe (hors-ligne / échec API)
  final bool isFallback;

  /// Horodatage de la génération
  final DateTime generatedAt;

  ExecutiveSummaryData({
    required this.overview,
    required this.keyFindings,
    required this.criticalRisksSummary,
    required this.recommendations,
    required this.conclusion,
    this.isFallback = false,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  /// Conversion en Map pour persistance ou transmission
  Map<String, dynamic> toJson() {
    return {
      'overview': overview,
      'keyFindings': keyFindings,
      'criticalRisksSummary': criticalRisksSummary,
      'recommendations': recommendations,
      'conclusion': conclusion,
      'isFallback': isFallback,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  /// Construction à partir d'un objet Map / JSON validé
  factory ExecutiveSummaryData.fromJson(Map<String, dynamic> json) {
    return ExecutiveSummaryData(
      overview: json['overview'] as String? ?? '',
      keyFindings: (json['keyFindings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList() ??
          [],
      criticalRisksSummary: json['criticalRisksSummary'] as String? ?? '',
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList() ??
          [],
      conclusion: json['conclusion'] as String? ?? '',
      isFallback: json['isFallback'] as bool? ?? false,
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Chaîne JSON encodée
  String encodeJson() => jsonEncode(toJson());

  /// Décodage depuis une chaîne JSON
  factory ExecutiveSummaryData.decodeJson(String source) {
    return ExecutiveSummaryData.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }
}
