import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../ai_provider.dart';

/// Implémentation haute résilience du fournisseur IA basé sur l'API REST Google Gemini.
///
/// Fonctionnalités avancées de résilience :
/// - Fallback multi-modèles (`gemini-2.0-flash`, `gemini-1.5-flash`, `gemini-flash-latest`).
/// - Re-tentatives automatiques (Retries avec Backoff) sur erreurs temporaires HTTP 503 (High Demand), 429, 500 et 504.
/// - Tier gratuit généreux et réponse JSON Schema native.
class GeminiRestProvider implements AiProvider {
  final String apiKey;
  final String _modelName;

  GeminiRestProvider({
    required this.apiKey,
    String modelName = 'gemini-2.0-flash',
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

    // Modèles Gemini à essayer par ordre de priorité en cas d'erreur 503/429 sur un endpoint
    final modelsToTry = <String>{
      _modelName,
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-flash-latest',
    }.toList();

    Object? lastError;

    for (int attempt = 0; attempt < modelsToTry.length; attempt++) {
      final currentModel = modelsToTry[attempt];
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$currentModel:generateContent?key=$apiKey',
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
        if (kDebugMode) {
          print('🤖 [GeminiRestProvider] Requête modèle: $currentModel (Tentative ${attempt + 1}/${modelsToTry.length})...');
        }

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
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
        }

        // Si le code HTTP signale une charge élevée ou indisponibilité (503, 429, 500, 504)
        if (response.statusCode == 503 ||
            response.statusCode == 429 ||
            response.statusCode == 500 ||
            response.statusCode == 504) {
          if (kDebugMode) {
            print(
              '⚠️ [GeminiRestProvider] Code ${response.statusCode} sur modèle $currentModel (Pic de charge). Bascule sur modèle suivant...',
            );
          }
          lastError = HttpException(
            'Gemini API Error (HTTP ${response.statusCode}): ${response.body}',
          );

          if (attempt < modelsToTry.length - 1) {
            await Future.delayed(const Duration(milliseconds: 1500));
            continue;
          }
        }

        // Pour les erreurs définitives de requête (ex: 400 Bad Request), abandon immédiat
        throw HttpException(
          'Gemini API Error (HTTP ${response.statusCode}): ${response.body}',
        );
      } catch (e) {
        lastError = e;
        if (attempt < modelsToTry.length - 1 && (e is TimeoutException || e is SocketException || e is HttpException)) {
          if (kDebugMode) {
            print('⚠️ [GeminiRestProvider] Erreur temporaire ($e). Réessai dans 1,5s...');
          }
          await Future.delayed(const Duration(milliseconds: 1500));
          continue;
        }
        break;
      }
    }

    if (kDebugMode) {
      print('❌ [GeminiRestProvider] Échec final après ${modelsToTry.length} tentatives: $lastError');
    }
    throw lastError ?? StateError('Échec de la génération Gemini');
  }
}
