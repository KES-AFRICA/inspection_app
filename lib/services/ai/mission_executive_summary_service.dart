import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inspec_app/services/statistics/mission_statistics_collector.dart';

import 'ai_provider.dart';
import 'executive_summary_cache_entry.dart';
import 'executive_summary_data.dart';
import 'executive_summary_snapshot.dart';
import 'providers/gemini_rest_provider.dart';

/// Service orchestrateur de la génération du « RÉSUMÉ EXÉCUTIF » intelligent pour le rapport PDF.
///
/// Garanties architecturales :
/// 1. Ne bloque ni ne ralentit jamais la génération du PDF.
/// 2. Déduplication single-flight (évite les appels API simultanés identiques).
/// 3. Invalidation automatique du cache par empreinte SHA-256 du snapshot.
/// 4. **Fallback à 3 Niveaux** :
///    - Niveau 1 : Résumé IA valide correspondant au hash actuel.
///    - Niveau 2 (Si échec API) : Dernier résumé valide conservé en cache pour cette mission.
///    - Niveau 3 (Si aucun cache) : Résumé déterministe généré localement.
class MissionExecutiveSummaryService {
  static const int promptVersion = 1;
  static const int schemaVersion = 1;
  static const String _boxName = 'executive_summary_cache';

  /// Clé API Gemini optionnelle (peut être configurée dynamiquement ou via variable d'environnement)
  static String? geminiApiKey;

  /// Verrou de déduplication single-flight (évite les doublons de requêtes concourantes)
  static final Map<String, Future<ExecutiveSummaryData>> _pendingRequests = {};

  /// Récupère la boîte Hive dédiée au cache du résumé exécutif
  static Future<Box> _getCacheBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  /// Schéma JSON strict attendu par l'API IA
  static final Map<String, dynamic> _geminiResponseSchema = {
    'type': 'OBJECT',
    'properties': {
      'overview': {
        'type': 'STRING',
        'description': 'Synthèse professionnelle du contexte de la mission et de l\'état général des installations.',
      },
      'keyFindings': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
        'description': 'Liste de 2 à 4 observations ou constats majeurs observés sur le site.',
      },
      'criticalRisksSummary': {
        'type': 'STRING',
        'description': 'Synthèse factuelle des risques majeurs et critiques prioritaires.',
      },
      'recommendations': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
        'description': 'Liste de 2 à 4 recommandations d\'actions correctives prioritaires.',
      },
      'conclusion': {
        'type': 'STRING',
        'description': 'Conclusion technique sur le niveau global de sécurité et la démarche de mise en conformité.',
      },
    },
    'required': [
      'overview',
      'keyFindings',
      'criticalRisksSummary',
      'recommendations',
      'conclusion',
    ],
  };

  /// Point d'entrée principal pour la récupération ou la génération du résumé d'une mission.
  static Future<ExecutiveSummaryData> getOrGenerateSummary(
    String missionId, {
    AiProvider? customProvider,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    // 1. Si une requête est déjà en cours pour cette mission, la réutiliser (Single-Flight)
    if (_pendingRequests.containsKey(missionId)) {
      return await _pendingRequests[missionId]!;
    }

    final future = _processSummaryRetrieval(
      missionId,
      customProvider: customProvider,
      timeout: timeout,
    );

    _pendingRequests[missionId] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _pendingRequests.remove(missionId);
    }
  }

  /// Logique d'orchestration avec le fallback à 3 niveaux
  static Future<ExecutiveSummaryData> _processSummaryRetrieval(
    String missionId, {
    AiProvider? customProvider,
    required Duration timeout,
  }) async {
    final snapshot = ExecutiveSummarySnapshot.fromMission(missionId);
    final currentHash = snapshot.computeHash();

    Box? cacheBox;
    ExecutiveSummaryCacheEntry? cachedEntry;

    // ── NIVEAU 1 : TENTER DE LIRE LE CACHE CORRESPONDANT AU HASH ACTUEL ──
    try {
      cacheBox = await _getCacheBox();
      final rawCache = cacheBox.get(missionId);

      if (rawCache != null) {
        try {
          if (rawCache is String) {
            cachedEntry = ExecutiveSummaryCacheEntry.decodeJson(rawCache);
          } else if (rawCache is Map) {
            cachedEntry = ExecutiveSummaryCacheEntry.fromJson(
              Map<String, dynamic>.from(rawCache),
            );
          }

          if (cachedEntry != null &&
              cachedEntry.snapshotHash == currentHash &&
              cachedEntry.promptVersion == promptVersion &&
              cachedEntry.schemaVersion == schemaVersion &&
              !cachedEntry.summaryData.isFallback) {
            if (kDebugMode) {
              print('⚡ [AI Executive Summary] Hit Cache Hash Parfait pour mission $missionId');
            }
            return cachedEntry.summaryData;
          }
        } catch (e) {
          if (kDebugMode) print('⚠️ Erreur lecture cache entry: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Erreur d\'accès au cache Hive: $e');
    }

    // ── TENTATIVE D'APPEL DE L'API IA ──
    final provider = customProvider ?? _resolveDefaultProvider();

    if (provider != null) {
      try {
        if (kDebugMode) {
          print('🤖 [AI Executive Summary] Appel API IA (${provider.providerName}) pour mission $missionId...');
        }

        final prompt = _buildPrompt(snapshot);
        final rawResponseJson = await provider.generateStructuredText(
          prompt: prompt,
          responseSchema: _geminiResponseSchema,
          timeout: timeout,
        );

        final jsonMap = jsonDecode(rawResponseJson) as Map<String, dynamic>;
        final aiSummaryData = ExecutiveSummaryData.fromJson(jsonMap);

        // Valider la réponse IA
        if (_validateAiSummary(aiSummaryData)) {
          final newEntry = ExecutiveSummaryCacheEntry(
            missionId: missionId,
            snapshotHash: currentHash,
            promptVersion: promptVersion,
            schemaVersion: schemaVersion,
            provider: provider.providerName,
            model: provider.modelName,
            generatedAt: DateTime.now(),
            summaryData: aiSummaryData,
          );

          // Sauvegarder dans le cache persistant Hive
          try {
            await cacheBox?.put(missionId, newEntry.encodeJson());
          } catch (e) {
            if (kDebugMode) print('⚠️ Échec écriture cache Hive: $e');
          }

          return aiSummaryData;
        } else {
          if (kDebugMode) print('⚠️ Résumé IA invalide lors de la validation.');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Appel API IA échoué ou inaccessible ($e). Activation du Fallback...');
        }
      }
    }

    // ── NIVEAU 2 (FALLBACK 2) : UTILISER LE DERNIER RÉSUMÉ EN CACHE DE CETTE MISSION ──
    if (cachedEntry != null && !cachedEntry.summaryData.isFallback) {
      if (kDebugMode) {
        print('🔄 [AI Executive Summary] Fallback Niveau 2: Utilisation du dernier résumé valide en cache pour $missionId');
      }
      return cachedEntry.summaryData;
    }

    // ── NIVEAU 3 (FALLBACK 3) : RÉSUMÉ DÉTERMINISTE LOCAL ──
    if (kDebugMode) {
      print('🛡️ [AI Executive Summary] Fallback Niveau 3: Génération du résumé déterministe local pour $missionId');
    }
    return _buildDeterministicFallback(missionId, snapshot);
  }

  /// Résolution du fournisseur par défaut (Gemini REST)
  static AiProvider? _resolveDefaultProvider() {
    final key = geminiApiKey ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (key.trim().isEmpty) return null;
    return GeminiRestProvider(apiKey: key);
  }

  /// Construction du prompt strict en français avec données du snapshot
  static String _buildPrompt(ExecutiveSummarySnapshot snapshot) {
    return '''
Tu es un ingénieur senior expert en contrôle et sécurité des installations électriques chez KES INSPECTIONS & PROJECTS.
Ta mission est de rédiger la synthèse du « RÉSUMÉ EXÉCUTIF » pour un rapport de vérification périodique d'installations électriques.

DONNÉES OFFICIELLES CERTIFIÉES DE LA MISSION (NE JAMAIS EN MODIFIER LES CHIFFRES) :
- Client : ${snapshot.clientName}
- Site / Établissement : ${snapshot.siteName}
- Nature de la mission : ${snapshot.natureMission}
- Période d'intervention : ${snapshot.dateRangeText}
- Domaine de tension : ${snapshot.domainTension}
- Total Non-Conformités : ${snapshot.officialStats['totalNC']}
- Non-Conformités Critiques : ${snapshot.officialStats['critique']} (${snapshot.officialStats['pctCritique']}%)
- Non-Conformités Majeures : ${snapshot.officialStats['majeure']} (${snapshot.officialStats['pctMajeure']}%)
- Non-Conformités Mineures : ${snapshot.officialStats['mineure']} (${snapshot.officialStats['pctMineure']}%)
- Principaux défauts constatés : ${jsonEncode(snapshot.topDefects)}
- Principales familles de risques : ${jsonEncode(snapshot.riskFamilies)}
- Nombre d'équipements/installations inspectés : ${snapshot.equipmentCount}

INSTRUCTIONS ET CONTRAT RÉDACTIONNEL STRICT :
1. Rédige un texte technique, professionnel, factuel et concis en français.
2. Utilise STRICTEMENT le format JSON structuré demandé.
3. RÈGLE D'OR : N'invente AUCUNE donnée absente du snapshot. Ne modifie AUCUN chiffre certifié.
4. Dans `overview` : Présente le contexte et l'état général des installations.
5. Dans `keyFindings` : Liste 2 à 4 points clés majeurs tirés des défauts et risques fournis.
6. Dans `criticalRisksSummary` : Rédige une synthèse sur les risques prioritaires (sécurité des personnes/biens).
7. Dans `recommendations` : Propose 2 à 4 recommandations d'actions correctives pragmatiques.
8. Dans `conclusion` : Rédige une conclusion technique sur la maîtrise du risque et la situation de référence.
''';
  }

  /// Validation des données du résumé IA
  static bool _validateAiSummary(ExecutiveSummaryData summary) {
    if (summary.overview.trim().length < 15) return false;
    if (summary.criticalRisksSummary.trim().length < 10) return false;
    if (summary.conclusion.trim().length < 10) return false;
    return true;
  }

  /// Générateur déterministe de secours (Fallback Niveau 3 - 100% Hors-ligne / Sans Clé)
  static ExecutiveSummaryData _buildDeterministicFallback(
    String missionId,
    ExecutiveSummarySnapshot snapshot,
  ) {
    int total = 0;
    int critique = 0;
    int majeure = 0;
    int mineure = 0;

    try {
      final summary = MissionStatisticsCollector.collectSummary(missionId);
      final cStats = summary.criticalityStats;
      total = cStats.total;
      critique = cStats.critique;
      majeure = cStats.majeure;
      mineure = cStats.mineure;
    } catch (_) {}

    final overviewText = 'Dans le cadre de la mission de ${snapshot.natureMission.toLowerCase()} '
        'des installations électriques du site ${snapshot.siteName}, KES INSPECTIONS & PROJECTS a procédé, '
        '${snapshot.dateRangeText}, à l\'examen des installations électriques (${snapshot.domainTension.toLowerCase()}). '
        'La mission couvre l\'ensemble des installations électriques et vise notamment à apprécier leur état de conservation, '
        'leur niveau de sécurité et leur conformité aux prescriptions réglementaires et normatives applicables.';

    final keyFindingsList = <String>[];
    if (total == 0) {
      keyFindingsList.add('Aucune non-conformité relevée lors de l\'inspection des installations.');
    } else {
      if (critique > 0) {
        keyFindingsList.add('$critique non-conformité(s) critique(s) nécessitant une intervention immédiate.');
      }
      if (majeure > 0) {
        keyFindingsList.add('$majeure non-conformité(s) majeure(s) impactant la sécurité des installations.');
      }
      if (mineure > 0) {
        keyFindingsList.add('$mineure non-conformité(s) mineure(s) à corriger lors de la maintenance courante.');
      }
    }

    String riskSummaryText;
    if (total == 0) {
      riskSummaryText = 'L\'examen approfondi des installations n\'a révélé aucune non-conformité '
          'lors de la présente vérification, attestant d\'un excellent niveau de conservation et de conformité des équipements du site.';
    } else if (critique > 0 || (critique + majeure) / total >= 0.4) {
      riskSummaryText = 'La proportion élevée de non-conformités critiques et majeures '
          'montre que le niveau de risque demeure significatif et nécessite la poursuite d\'un programme structuré de mise en conformité.';
    } else {
      riskSummaryText = 'La répartition des observations montre une prédominance de non-conformités mineures, '
          'traduisant un niveau de risque globalement maîtrisé, nécessitant néanmoins la programmation d\'actions correctives ciblées.';
    }

    final recommendationsList = <String>[
      if (critique > 0) 'Traiter en priorité absolue les non-conformités critiques identifiées.',
      if (total > 0) 'Mettre en place un plan d\'action correctif basé sur la grille de priorité des observations.',
      'Assurer le suivi régulier du registre de contrôle de sécurité électrique.',
    ];

    final conclusionText = 'La présente campagne de vérification doit servir de situation de référence '
        'pour la mise en place d\'un suivi systématique des non-conformités, permettant, lors des prochaines inspections, '
        'de distinguer clairement les observations levées, maintenues et nouvelles.';

    return ExecutiveSummaryData(
      overview: overviewText,
      keyFindings: keyFindingsList,
      criticalRisksSummary: riskSummaryText,
      recommendations: recommendationsList,
      conclusion: conclusionText,
      isFallback: true,
    );
  }
}
