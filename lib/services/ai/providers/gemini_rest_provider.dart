import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../ai_provider.dart';

/// Implémentation du fournisseur IA basé sur l'API REST Google Gemini (`gemini-2.5-flash` ou `gemini-1.5-flash`).
///
/// Avantages clés :
/// - Tier gratuit généreux (15 requêtes/min, 1 500 RPD 100% gratuit).
/// - Format JSON Schema natif garanti via `responseMimeType: "application/json"`.
/// - Légèreté (communique via `package:http` sans SDK lourd).
class GeminiRestProvider implements AiProvider {
  final String apiKey;
  final String _modelName;

  GeminiRestProvider({
    required this.apiKey,
    String modelName = 'gemini-flash-latest',
  }) : _modelName = modelName;

  @override
  String get providerName => 'gemini';

  @override
  String get modelName => _modelName;

  @override
  Future<String> generateStructuredText({
    required String prompt,
    required Map<String, dynamic> responseSchema,
    Duration timeout = const Duration(seconds: 18),
  }) async {
    if (apiKey.trim().isEmpty) {
      throw StateError('Clé API Gemini non configurée.');
    }

    // URL officielle Google Gemini REST API v1beta
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=$apiKey',
    );

    final payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': responseSchema,
        'temperature': 0.2,
      }
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('❌ Gemini API Code: ${response.statusCode} - Body: ${response.body}');
        }
        throw HttpException(
          'Gemini API Error (HTTP ${response.statusCode}): ${response.body}',
        );
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = jsonResponse['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw FormatException('Aucun candidat retourné par l\'API Gemini.');
      }

      final candidate = candidates.first as Map<String, dynamic>;
      final content = candidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw FormatException('Contenu texte vide dans la réponse Gemini.');
      }

      final text = parts.first['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw FormatException('Texte JSON vide retourné par l\'API Gemini.');
      }

      return text;
    } catch (e) {
      if (kDebugMode) print('⚠️ GeminiRestProvider Error: $e');
      rethrow;
    }
  }
}
