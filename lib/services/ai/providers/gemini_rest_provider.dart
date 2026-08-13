import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../ai_provider.dart';

/// Implémentation haute résilience du fournisseur IA basé sur l'API REST Google Gemini.
///
/// Fonctionnalités avancées de résilience :
/// - Utilisation des modèles Gemini 2.5 actuels (`gemini-2.5-flash`, `gemini-2.5-flash-lite`, `gemini-flash-latest`).
/// - Re-tentatives automatiques (3 essais par modèle avec Backoff progressif) sur erreurs temporaires (429, 500, 503, 504, Timeout, Réseau).
/// - Bascule immédiate sur modèle suivant en cas d'erreur 404 (modèle non trouvé/déprécié).
class GeminiRestProvider implements AiProvider {
  final String apiKey;
  final String _modelName;

  GeminiRestProvider({
    required this.apiKey,
    String modelName = 'gemini-2.5-flash',
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

    // Liste des modèles Gemini 2.5 valides par ordre de priorité (1.5 et 2.0 supprimés)
    final modelsToTry = <String>{
      _modelName,
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      'gemini-flash-latest',
    }.toList();

    Object? lastError;
    const maxRetriesPerModel = 1;

    for (final currentModel in modelsToTry) {
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

      for (int retry = 1; retry <= maxRetriesPerModel; retry++) {
        try {
          if (kDebugMode) {
            print('🤖 [GeminiRestProvider] Modèle: $currentModel — Tentative $retry/$maxRetriesPerModel...');
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

          // Si HTTP 404 (modèle déprécié ou supprimé), passer directement au modèle suivant
          if (response.statusCode == 404) {
            if (kDebugMode) {
              print('⚠️ [GeminiRestProvider] Modèle $currentModel non trouvé (HTTP 404). Bascule vers le modèle suivant...');
            }
            lastError = HttpException('Gemini API Error (HTTP 404): ${response.body}');
            break; // Sortie des 3 retries pour ce modèle
          }

          // Erreur HTTP 429/500/503/504
          lastError = HttpException('Gemini API Error (HTTP ${response.statusCode}): ${response.body}');
          if (retry < maxRetriesPerModel) {
            final delayMs = retry * 1500;
            if (kDebugMode) {
              print('⚠️ [GeminiRestProvider] Erreur HTTP ${response.statusCode} sur $currentModel. Réessai $retry/$maxRetriesPerModel dans ${delayMs}ms...');
            }
            await Future.delayed(Duration(milliseconds: delayMs));
            continue;
          }
        } catch (e) {
          lastError = e;
          if (retry < maxRetriesPerModel && (e is TimeoutException || e is SocketException || e is HttpException)) {
            final delayMs = retry * 1500;
            if (kDebugMode) {
              print('⚠️ [GeminiRestProvider] Erreur réseau/temporaire ($e). Réessai $retry/$maxRetriesPerModel dans ${delayMs}ms...');
            }
            await Future.delayed(Duration(milliseconds: delayMs));
            continue;
          }
          break;
        }
      }
    }

    if (kDebugMode) {
      print('❌ [GeminiRestProvider] Échec final après essais sur tous les modèles: $lastError');
    }
    throw lastError ?? StateError('Échec de la génération Gemini');
  }
}
