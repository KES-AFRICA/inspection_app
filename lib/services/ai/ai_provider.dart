/// Interface abstraite pour l'intégration de fournisseurs d'IA (Gemini, OpenAI, Mistral...).
abstract class AiProvider {
  /// Nom identifiant du fournisseur (ex: "gemini", "openai")
  String get providerName;

  /// Modèle actuellement utilisé (ex: "gemini-2.5-flash")
  String get modelName;

  /// Génère un texte JSON structuré correspondant à [responseSchema] à partir d'un [prompt].
  Future<String> generateStructuredText({
    required String prompt,
    required Map<String, dynamic> responseSchema,
    Duration timeout = const Duration(seconds: 18),
  });
}
