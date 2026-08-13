import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../ai_provider.dart';

/// Fournisseur d'IA alternatif gratuit et ultra-rapide basé sur l'API REST Groq.
///
/// Avantages de Groq Free Tier :
/// - 100% Gratuit (jusqu'à 14 400 requêtes / jour, 30 req / min).
/// - Vitesse exceptionnelle (jusqu'à 500+ tokens/sec grâce aux processeurs Groq LPU).
/// - Modèles haute capacité : `llama-3.3-70b-versatile`, `llama-3.1-8b-instant`, `qwen-2.5-coder-32b`.
class GroqRestProvider implements AiProvider {
  final String apiKey;
  final String _modelName;

  GroqRestProvider({
    required this.apiKey,
    String modelName = 'llama-3.3-70b-versatile',
  }) : _modelName = modelName;

  @override
  String get providerName => 'groq';

  @override
  String get modelName => _modelName;

  @override
  Future<String> generateStructuredText({
    required String prompt,
    required Map<String, dynamic> responseSchema,
    Duration timeout = const Duration(seconds: 18),
  }) async {
    if (apiKey.trim().isEmpty) {
      throw StateError('Clé API Groq non configurée.');
    }

    final modelsToTry = <String>{
      _modelName,
      'llama-3.3-70b-versatile',
      'llama-3.1-8b-instant',
      'qwen-2.5-coder-32b',
    }.toList();

    Object? lastError;
    const maxRetriesPerModel = 1;

    for (final currentModel in modelsToTry) {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final payload = {
        'model': currentModel,
        'messages': [
          {
            'role': 'system',
            'content': 'Tu es un expert qui génère uniquement du JSON valide respectant le schéma demandé.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.2,
      };

      for (int retry = 1; retry <= maxRetriesPerModel; retry++) {
        try {
          if (kDebugMode) {
            print('⚡ [GroqRestProvider] Modèle: $currentModel — Tentative $retry/$maxRetriesPerModel...');
          }

          final response = await http
              .post(
                url,
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $apiKey',
                },
                body: jsonEncode(payload),
              )
              .timeout(timeout);

          if (response.statusCode == 200) {
            final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
            final choices = jsonResponse['choices'] as List<dynamic>?;
            if (choices == null || choices.isEmpty) {
              throw FormatException('Aucun choix retourné par l\'API Groq.');
            }

            final message = choices.first['message'] as Map<String, dynamic>?;
            final text = message?['content'] as String?;
            if (text == null || text.trim().isEmpty) {
              throw FormatException('Contenu JSON vide retourné par Groq.');
            }

            return text;
          }

          if (response.statusCode == 404) {
            lastError = HttpException('Groq API Error (HTTP 404): ${response.body}');
            break;
          }

          lastError = HttpException('Groq API Error (HTTP ${response.statusCode}): ${response.body}');
          if (retry < maxRetriesPerModel) {
            await Future.delayed(Duration(milliseconds: retry * 1000));
            continue;
          }
        } catch (e) {
          lastError = e;
          if (retry < maxRetriesPerModel && (e is TimeoutException || e is SocketException || e is HttpException)) {
            await Future.delayed(Duration(milliseconds: retry * 1000));
            continue;
          }
          break;
        }
      }
    }

    throw lastError ?? StateError('Échec de la génération Groq');
  }
}
