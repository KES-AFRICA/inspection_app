import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inspec_app/services/statistics/mission_statistics_collector.dart';

import '../statistics/canonical_risk_family_registry.dart';
import 'ai_provider.dart';
import 'executive_summary_cache_entry.dart';
import 'executive_summary_data.dart';
import 'executive_summary_snapshot.dart';
import 'providers/gemini_rest_provider.dart';
import 'providers/groq_rest_provider.dart';

/// Service orchestrateur de la génération du « RÉSUMÉ EXÉCUTIF » intelligent pour le rapport PDF (7 sous-sections).
///
/// Garanties architecturales :
/// 1. Ne bloque ni ne ralentit jamais la génération du PDF.
/// 2. Déduplication single-flight (évite les appels API simultanés identiques).
/// 3. Invalidation automatique du cache par empreinte SHA-256 du snapshot.
/// 4. **Fallback à 3 Niveaux** :
///    - Niveau 1 : Résumé IA valide correspondant au hash actuel.
///    - Niveau 2 (Si échec API) : Dernier résumé valide conservé en cache pour cette mission.
///    - Niveau 3 (Si aucun cache) : Résumé déterministe généré localement (7 sous-sections 100% complètes).
class MissionExecutiveSummaryService {
  static const int promptVersion = 2;
  static const int schemaVersion = 2;
  static const String _boxName = 'executive_summary_cache';

  /// Clés API configurables
  static String? geminiApiKey;
  static String? groqApiKey;

  /// Verrou de déduplication single-flight
  static final Map<String, Future<ExecutiveSummaryData>> _pendingRequests = {};

  /// Récupère la boîte Hive dédiée au cache du résumé exécutif
  static Future<Box> _getCacheBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  /// Schéma JSON strict pour les 7 sous-sections officielles
  static final Map<String, dynamic> _geminiResponseSchema = {
    'type': 'OBJECT',
    'properties': {
      'contexte': {
        'type': 'OBJECT',
        'properties': {
          'paragraph': {
            'type': 'STRING',
            'description': 'Synthèse factuelle du contexte, du site, du rapporteur, de la période et du périmètre MT/BT.',
          },
        },
        'required': ['paragraph'],
      },
      'syntheseResultats': {
        'type': 'OBJECT',
        'properties': {
          'introParagraph': {
            'type': 'STRING',
            'description': 'Introduction chiffrée sur le nombre total de non-conformités et la densité moyenne par équipement.',
          },
          'tableRows': {
            'type': 'ARRAY',
            'items': {
              'type': 'OBJECT',
              'properties': {
                'criticite': {'type': 'STRING'},
                'nombre': {'type': 'INTEGER'},
                'partPct': {'type': 'STRING'},
                'densiteStr': {'type': 'STRING'},
              },
              'required': ['criticite', 'nombre', 'partPct', 'densiteStr'],
            },
          },
          'tableTotalRow': {
            'type': 'OBJECT',
            'properties': {
              'criticite': {'type': 'STRING'},
              'nombre': {'type': 'INTEGER'},
              'partPct': {'type': 'STRING'},
              'densiteStr': {'type': 'STRING'},
            },
            'required': ['criticite', 'nombre', 'partPct', 'densiteStr'],
          },
          'commentaryParagraph': {
            'type': 'STRING',
            'description': 'Commentaire analysant le pourcentage de non-conformités critiques et majeures par rapport aux seuils habituels.',
          },
        },
        'required': ['introParagraph', 'tableRows', 'tableTotalRow', 'commentaryParagraph'],
      },
      'concentrationRisque': {
        'type': 'OBJECT',
        'properties': {
          'title': {
            'type': 'STRING',
            'description': 'Titre de la sous-section 3 précisant les catégories concentrant le risque.',
          },
          'primaryConcentrationParagraph': {
            'type': 'STRING',
            'description': 'Analyse des 2 catégories concentrant la majorité des écarts.',
          },
          'highestDensityParagraph': {
            'type': 'STRING',
            'description': 'Analyse de la catégorie affichant la densité unitaire la plus élevée.',
          },
        },
        'required': ['title', 'primaryConcentrationParagraph', 'highestDensityParagraph'],
      },
      'facteursRisque': {
        'type': 'OBJECT',
        'properties': {
          'introParagraph': {
            'type': 'STRING',
            'description': 'Introduction sur l\'analyse par nature de risque.',
          },
          'tableRows': {
            'type': 'ARRAY',
            'items': {
              'type': 'OBJECT',
              'properties': {
                'natureRisque': {'type': 'STRING'},
                'constats': {'type': 'STRING'},
                'partPct': {'type': 'STRING'},
                'observation': {'type': 'STRING'},
              },
              'required': ['natureRisque', 'constats', 'partPct', 'observation'],
            },
          },
          'commentaryParagraph': {
            'type': 'STRING',
            'description': 'Commentaire de synthèse sur l\'impact des facteurs de risques dominants.',
          },
        },
        'required': ['introParagraph', 'tableRows', 'commentaryParagraph'],
      },
      'observationsMajores': {
        'type': 'OBJECT',
        'properties': {
          'bulletPoints': {
            'type': 'ARRAY',
            'items': {'type': 'STRING'},
            'description': 'Liste à puces des 3 à 5 constats clés sur les types de défauts prédominants.',
          },
          'summaryParagraph': {
            'type': 'STRING',
            'description': 'Part cumulée concentrée par les premières catégories de défauts.',
          },
        },
        'required': ['bulletPoints', 'summaryParagraph'],
      },
      'recommandationsPrioritaires': {
        'type': 'OBJECT',
        'properties': {
          'introParagraph': {
            'type': 'STRING',
            'description': 'Introduction sur la hiérarchisation des priorités.',
          },
          'priority1Immediate': {
            'type': 'STRING',
            'description': 'Priorité 1 — Immédiat : levée des non-conformités critiques.',
          },
          'priority2ShortTerm': {
            'type': 'STRING',
            'description': 'Priorité 2 — Court terme : réhabilitation des protections et câblages.',
          },
          'priority3MediumTerm': {
            'type': 'STRING',
            'description': 'Priorité 3 — Moyen terme : repérage, documentation et répartiteurs.',
          },
        },
        'required': ['introParagraph', 'priority1Immediate', 'priority2ShortTerm', 'priority3MediumTerm'],
      },
      'appreciationGlobale': {
        'type': 'OBJECT',
        'properties': {
          'assessmentParagraph1': {
            'type': 'STRING',
            'description': 'Appréciation générale du niveau de maîtrise du risque électrique.',
          },
          'assessmentParagraph2': {
            'type': 'STRING',
            'description': 'Synthese du nombre de NCs critiques/majeures et densité moyenne.',
          },
          'assessmentParagraph3': {
            'type': 'STRING',
            'description': 'Synthèse des équipements les plus sensibles.',
          },
          'actionPlanHeader': {
            'type': 'STRING',
            'description': 'En-tête introduisant le plan d\'actions correctives.',
          },
          'actionPlanSteps': {
            'type': 'ARRAY',
            'items': {'type': 'STRING'},
            'description': 'Liste de 6 recommandations d\'actions priorisées.',
          },
          'counterVisitParagraph': {
            'type': 'STRING',
            'description': 'Exigence de contre-visite de vérification réglementaire après travaux.',
          },
        },
        'required': [
          'assessmentParagraph1',
          'assessmentParagraph2',
          'assessmentParagraph3',
          'actionPlanHeader',
          'actionPlanSteps',
          'counterVisitParagraph',
        ],
      },
    },
    'required': [
      'contexte',
      'syntheseResultats',
      'concentrationRisque',
      'facteursRisque',
      'observationsMajores',
      'recommandationsPrioritaires',
      'appreciationGlobale',
    ],
  };

  /// Point d'entrée principal pour la récupération ou la génération du résumé d'une mission.
  static Future<ExecutiveSummaryData> getOrGenerateSummary(
    String missionId, {
    AiProvider? customProvider,
    Duration timeout = const Duration(seconds: 18),
  }) async {
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

          // Purge automatique du cache si la version du schéma est obsolète (< schemaVersion) ou invalide
          if (cachedEntry != null &&
              (cachedEntry.schemaVersion < schemaVersion ||
               cachedEntry.promptVersion < promptVersion ||
               !_validateAiSummary(cachedEntry.summaryData))) {
            if (kDebugMode) {
              print('🧹 [AI Executive Summary] Purge automatique du cache obsolète (v${cachedEntry.schemaVersion} vs v$schemaVersion) pour $missionId...');
            }
            try {
              await cacheBox?.delete(missionId);
            } catch (_) {}
            cachedEntry = null;
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
          try {
            await cacheBox?.delete(missionId);
          } catch (_) {}
          cachedEntry = null;
        }
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Erreur d\'accès au cache Hive: $e');
    }

    // ── TENTATIVE D'APPEL DE LA CHAÎNE IA (Groq -> OpenRouter -> Gemini) ──
    final providerChain = customProvider != null ? [customProvider] : _resolveProviderChain();

    for (final provider in providerChain) {
      try {
        if (kDebugMode) {
          print('🤖 [AI Executive Summary] Essai provider IA (${provider.providerName}:${provider.modelName}) pour mission $missionId...');
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

          try {
            await cacheBox?.put(missionId, newEntry.encodeJson());
          } catch (e) {
            if (kDebugMode) print('⚠️ Échec écriture cache Hive: $e');
          }

          if (kDebugMode) {
            print('✅ [AI Executive Summary] Succès de la génération IA via ${provider.providerName}:${provider.modelName} !');
          }
          return aiSummaryData;
        } else {
          if (kDebugMode) print('⚠️ Résumé IA invalide lors de la validation pour ${provider.providerName}.');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [AI Executive Summary] Échec sur ${provider.providerName}:${provider.modelName} ($e). Bascule vers le fournisseur suivant...');
        }
      }
    }

    // ── NIVEAU 2 (FALLBACK 2) : UTILISER UN RÉSULTAT HORS-LIGNE DÉTERMINISTE POUR LE HASH ACTUEL ──
    if (kDebugMode) {
      print('🛡️ [AI Executive Summary] Moteur Offline Déterministe pour mission $missionId (hash: ${currentHash.substring(0, 8)})');
    }

    final offlineSummary = buildDeterministicFallback(missionId, snapshot);

    // Sauvegarder la version offline dans le cache Hive avec l'empreinte actuelle
    final offlineEntry = ExecutiveSummaryCacheEntry(
      missionId: missionId,
      snapshotHash: currentHash,
      promptVersion: promptVersion,
      schemaVersion: schemaVersion,
      provider: 'offline_engine',
      model: 'deterministic_v2',
      generatedAt: DateTime.now(),
      summaryData: offlineSummary,
    );

    try {
      await cacheBox?.put(missionId, offlineEntry.encodeJson());
    } catch (e) {
      if (kDebugMode) print('⚠️ Échec écriture cache Hive offline: $e');
    }

    return offlineSummary;
  }

  /// Résolution de la chaîne de fournisseurs par ordre de priorité :
  /// 1. Groq (GroqCloud REST API — llama-3.3-70b-versatile, 100% gratuit)
  /// 2. Gemini (Google Gemini REST API — gemini-flash-latest)
  static List<AiProvider> _resolveProviderChain() {
    final chain = <AiProvider>[];

    final groqKey = groqApiKey ?? const String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
    if (groqKey.trim().isNotEmpty) {
      chain.add(GroqRestProvider(apiKey: groqKey.trim()));
    }

    final geminiKey = geminiApiKey ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (geminiKey.trim().isNotEmpty) {
      chain.add(GeminiRestProvider(apiKey: geminiKey.trim(), modelName: 'gemini-flash-latest'));
    }

    return chain;
  }

  /// Construction du prompt strict en français avec données du snapshot
  static String _buildPrompt(ExecutiveSummarySnapshot snapshot) {
    return '''
Tu es un ingénieur senior expert en contrôle et sécurité des installations électriques chez KES INSPECTIONS & PROJECTS.
Ta mission est de rédiger les 7 sous-sections du « RÉSUMÉ EXÉCUTIF » pour un rapport de vérification périodique d'installations électriques.

DONNÉES OFFICIELLES CERTIFIÉES DE LA MISSION (NE JAMAIS EN MODIFIER LES CHIFFRES NI LES COMPTAGES) :
- Client : ${snapshot.clientName}
- Site / Établissement : ${snapshot.siteName}
- Organisme d'inspection : ${snapshot.companyName}
- Rapport n° : ${snapshot.reportNumber} (émis le ${snapshot.reportDateStr})
- Nature de la mission : ${snapshot.natureMission}
- Période d'intervention : ${snapshot.dateRangeText}
- Domaine de tension : ${snapshot.domainTension}
- Nombre total d'équipements/installations contrôlés : ${snapshot.equipmentCount}
- Nombre de catégories d'équipements : ${snapshot.installationsCount}
- Total Non-Conformités : ${snapshot.officialStats['totalNC']}
- Densité moyenne globale : ${snapshot.globalDensityStr} NC / équipement
- Non-Conformités Critiques : ${snapshot.officialStats['critique']} (${snapshot.officialStats['pctCritique']}%)
- Non-Conformités Majeures : ${snapshot.officialStats['majeure']} (${snapshot.officialStats['pctMajeure']}%)
- Non-Conformités Mineures : ${snapshot.officialStats['mineure']} (${snapshot.officialStats['pctMineure']}%)
- Ventilation par catégorie d'équipement : ${jsonEncode(snapshot.categoryStats)}
- Principaux défauts constatés : ${jsonEncode(snapshot.topDefects)}
- Principales familles de risques : ${jsonEncode(snapshot.riskFamilies)}

INSTRUCTIONS ET CONTRAT RÉDACTIONNEL STRICT :
1. Rédige un texte technique, professionnel, factuel et concis en français.
2. Utilise STRICTEMENT le format JSON structuré demandé pour remplir les 7 sous-sections (contexte, syntheseResultats, concentrationRisque, facteursRisque, observationsMajores, recommandationsPrioritaires, appreciationGlobale).
3. RÈGLE D'OR : N'invente AUCUNE donnée absente du snapshot. Ne modifie AUCUN chiffre certifié.
4. Remplis fidèlement chaque champ requis du schéma JSON.
''';
  }

  /// Validation des données du résumé IA
  static bool _validateAiSummary(ExecutiveSummaryData summary) {
    if (summary.contexte.paragraph.trim().length < 15) return false;
    if (summary.syntheseResultats.introParagraph.trim().length < 10) return false;
    if (summary.appreciationGlobale.assessmentParagraph1.trim().length < 10) return false;
    return true;
  }

  /// Générateur déterministe (Moteur Offline Déterministe pour la version actuelle)
  static ExecutiveSummaryData buildDeterministicFallback(
    String missionId,
    ExecutiveSummarySnapshot snapshot,
  ) {
    int total = 0;
    int critique = 0;
    int majeure = 0;
    int mineure = 0;
    String pctCritiqueStr = '0,0 %';
    String pctMajeureStr = '0,0 %';
    String pctMineureStr = '0,0 %';

    try {
      final summary = MissionStatisticsCollector.collectSummary(missionId);
      final cStats = summary.criticalityStats;
      total = cStats.total;
      critique = cStats.critique;
      majeure = cStats.majeure;
      mineure = cStats.mineure;
      pctCritiqueStr = '${cStats.pctCritique.toStringAsFixed(1).replaceAll('.', ',')} %';
      pctMajeureStr = '${cStats.pctMajeure.toStringAsFixed(1).replaceAll('.', ',')} %';
      pctMineureStr = '${cStats.pctMineure.toStringAsFixed(1).replaceAll('.', ',')} %';
    } catch (_) {
      total = snapshot.officialStats['totalNC'] as int? ?? 0;
      critique = snapshot.officialStats['critique'] as int? ?? 0;
      majeure = snapshot.officialStats['majeure'] as int? ?? 0;
      mineure = snapshot.officialStats['mineure'] as int? ?? 0;
      pctCritiqueStr = '${snapshot.officialStats['pctCritique'] ?? '0,0'} %';
      pctMajeureStr = '${snapshot.officialStats['pctMajeure'] ?? '0,0'} %';
      pctMineureStr = '${snapshot.officialStats['pctMineure'] ?? '0,0'} %';
    }

    final eqCount = snapshot.equipmentCount;
    final globalDensityStr = snapshot.globalDensityStr;

    final contextText =
        'La vérification périodique réglementaire des installations électriques du site ${snapshot.siteName} '
        'a été réalisée ${snapshot.dateRangeText} par ${snapshot.companyName} '
        '(rapport n° ${snapshot.reportNumber}, émis le ${snapshot.reportDateStr}). '
        'La mission a porté sur l\'ensemble des installations électriques ${snapshot.domainTension}, '
        'depuis les sources d\'alimentation jusqu\'aux équipements terminaux, conformément au périmètre défini dans le rapport, '
        'soit un total de ${snapshot.equipmentCount} installation${snapshot.equipmentCount > 1 ? 's' : ''} et équipement${snapshot.equipmentCount > 1 ? 's' : ''} contrôlés.';

    final introSynthese =
        'Les vérifications ont permis de recenser $total non-conformité${total > 1 ? 's' : ''} sur l\'ensemble du périmètre, '
        'soit une densité moyenne de $globalDensityStr non-conformité${total > 1 ? 's' : ''} par équipement.'
        '${total > 0 ? " Cette densité traduit un état de vétusté ou de maintenance insuffisante généralisé plutôt que des défauts ponctuels isolés." : ""}';

    final critRows = [
      CriticalityRowData(
        criticite: 'Critique',
        nombre: critique,
        partPct: pctCritiqueStr,
        densiteStr: eqCount > 0 ? '${(critique / eqCount).toStringAsFixed(2).replaceAll('.', ',')} NC critique / équipement' : '0,00',
      ),
      CriticalityRowData(
        criticite: 'Majeure',
        nombre: majeure,
        partPct: pctMajeureStr,
        densiteStr: eqCount > 0 ? '${(majeure / eqCount).toStringAsFixed(2).replaceAll('.', ',')} NC majeure / équipement' : '0,00',
      ),
      CriticalityRowData(
        criticite: 'Mineure',
        nombre: mineure,
        partPct: pctMineureStr,
        densiteStr: eqCount > 0 ? '${(mineure / eqCount).toStringAsFixed(2).replaceAll('.', ',')} NC mineure / équipement' : '0,00',
      ),
    ];

    final critTotalRow = CriticalityRowData(
      criticite: 'TOTAL',
      nombre: total,
      partPct: '100 %',
      densiteStr: '$globalDensityStr NC / équipement (moyenne globale)',
    );

    final pctCritVal = total > 0 ? (critique / total) * 100 : 0.0;
    final commentarySynthese = total == 0
        ? 'Aucune non-conformité n\'a été décelée lors de cette campagne de vérification.'
        : 'Avec ${pctCritVal.toStringAsFixed(1).replaceAll('.', ',')} % de non-conformités classées critiques, la situation constatée dépasse '
            'largement les seuils habituellement considérés comme acceptables (généralement de l\'ordre de 10 à 15 % en exploitation maîtrisée) '
            'et caractérise un site en risque avéré nécessitant une intervention corrective immédiate.';

    // Sélection déterministe des 2 catégories prépondérantes (Top 2 NCs)
    final top1 = snapshot.categoryStats.isNotEmpty ? snapshot.categoryStats[0] : null;
    final top2 = snapshot.categoryStats.length > 1 ? snapshot.categoryStats[1] : null;

    final top1Name = top1 != null ? (top1['categoryName'] as String? ?? 'équipements') : 'équipements';
    final top1Nc = top1 != null ? (top1['ncCount'] as int? ?? 0) : 0;
    final top1Pct = top1 != null ? (top1['pctOfTotalNc'] as String? ?? '0,0') : '0,0';
    final top1Eq = top1 != null ? (top1['equipmentCount'] as int? ?? 0) : 0;
    final top1PctEq = top1 != null ? (top1['pctOfTotalEquipment'] as String? ?? '0,0') : '0,0';
    final top1Density = top1 != null ? (top1['densityStr'] as String? ?? '0,00') : '0,00';

    final top2Name = top2 != null ? (top2['categoryName'] as String? ?? '') : '';
    final top2Nc = top2 != null ? (top2['ncCount'] as int? ?? 0) : 0;
    final top2Pct = top2 != null ? (top2['pctOfTotalNc'] as String? ?? '0,0') : '0,0';

    final String concentrationTitle;
    final String primaryConcText;
    final String highestDensityText;

    if (total == 0) {
      concentrationTitle = '3. Concentration du risque';
      primaryConcText = 'L\'analyse ne révèle aucune concentration particulière d\'écarts.';
      highestDensityText = 'Toutes les installations examinées présentent un niveau de conformité satisfaisant.';
    } else if (top2Name.isNotEmpty && top2Nc > 0) {
      concentrationTitle = '3. Concentration du risque : les $top1Name et les $top2Name concentrent l\'essentiel des réfections';
      primaryConcText = '• L\'analyse croisée par catégorie fait apparaître une forte concentration du risque :\n'
          '  * Les $top1Name concentrent $top1Nc non-conformités ($top1Pct % du total)\n'
          '  * Les $top2Name comptabilisent $top2Nc non-conformités ($top2Pct % du total)\n'
          '• Ces deux catégories regroupent à elles seules la majorité des anomalies du site.';
      highestDensityText = 'En termes de densité unitaire, la catégorie $top1Name affiche une densité de $top1Density NC / équipement '
          'sur un effectif de $top1Eq unité${top1Eq > 1 ? 's' : ''} (soit $top1PctEq % du parc contrôlé).';
    } else {
      concentrationTitle = '3. Concentration du risque : les $top1Name concentrent l\'essentiel des réfections';
      primaryConcText = 'L\'analyse croisée fait apparaître une concentration majeure sur la catégorie $top1Name avec $top1Nc non-conformités, '
          'représentant $top1Pct % de l\'ensemble des écarts constatés sur la mission.';
      highestDensityText = 'Cette catégorie présente une densité de $top1Density NC / équipement sur $top1Eq unité${top1Eq > 1 ? 's' : ''}.';
    }

    final riskRows = snapshot.riskFamilies.take(5).map((r) {
      final name = r['name'] as String? ?? 'Famille de risque';
      final defaultObs = CanonicalRiskFamilyRegistry.defaultObservations[name] ??
          'Facteur de risque identifié lors du contrôle';
      return RiskFactorRowData(
        natureRisque: name,
        constats: r['count']?.toString() ?? '0',
        partPct: '${r['percentage'] ?? '0,0'} %',
        observation: defaultObs,
      );
    }).toList();

    if (riskRows.isEmpty) {
      riskRows.add(RiskFactorRowData(
        natureRisque: 'Risques généraux d\'exploitation',
        constats: '0',
        partPct: '0,0 %',
        observation: 'Aucun facteur de risque prépondérant identifié',
      ));
    }

    final riskCommentary = total == 0
        ? 'Aucun facteur de risque prépondérant décelé.'
        : 'Ces facteurs de risque répertoriés concernent directement la sécurité des personnes et la protection des installations, '
            'ce qui en fait la priorité du plan d\'actions correctives.';

    final bulletPoints = snapshot.topDefects.take(5).map((d) {
      final title = d['title'] as String? ?? 'Défaut constaté';
      final count = d['count'] as int? ?? 0;
      final pct = d['percentage'] as String? ?? '0,0';
      final detail = CanonicalRiskFamilyRegistry.defaultObservations[title] ??
          'Anomalies et écarts réglementaires relevés lors des vérifications.';
      return '$title ($count constat${count > 1 ? 's' : ''}, $pct %) : $detail';
    }).toList();

    if (bulletPoints.isEmpty) {
      bulletPoints.add('Examen conforme de l\'ensemble des organes de protection et de câblage.');
    }

    final summaryObs = total == 0
        ? ''
        : 'Les principales catégories de défauts concentrent le volume majeur des occurrences relevées lors des contrôles.';

    final priority1 = critique > 0
        ? 'Priorité 1 — Immédiat : lever les $critique non-conformités critiques, en particulier sur les $top1Name, pour neutraliser les risques directs d\'électrocution et d\'électrisation.'
        : 'Priorité 1 — Immédiat : maintenir l\'intégrité des équipements et organes de protection existants.';

    final priority2 = majeure > 0
        ? 'Priorité 2 — Court terme : remettre en état les $majeure non-conformités majeures (systèmes de protection contre les contacts indirects, câblages et disjoncteurs).'
        : 'Priorité 2 — Court terme : planifier la maintenance préventive régulière.';

    final priority3 =
        'Priorité 3 — Moyen terme : finaliser l\'identification complète des circuits, le repérage et la conformité des répartiteurs afin de sécuriser durablement l\'exploitation et la maintenance du site.';

    final assessment1 = total == 0
        ? 'La vérification périodique des installations électriques du site ${snapshot.siteName} met en évidence un bon niveau de maîtrise du risque électrique.'
        : 'La vérification périodique des installations électriques du site ${snapshot.siteName} met en évidence un niveau de maîtrise du risque électrique nécessitant une vigilance renforcée et des actions correctives structurées.';

    final assessment2 =
        'L\'inspection a permis d\'identifier $total non-conformités, dont $critique critiques et $majeure majeures, avec une densité moyenne de $globalDensityStr non-conformité${total > 1 ? 's' : ''} par équipement contrôlé.';

    final assessment3 =
        'L\'analyse des résultats met en évidence une concentration des anomalies sur la catégorie $top1Name${top2Name.isNotEmpty ? ' et $top2Name' : ''}, qui constituent les équipements les plus sensibles au regard de la sécurité et de la continuité d\'exploitation.';

    final actionSteps = <String>[
      'Supprimer immédiatement toutes les situations présentant un danger grave et imminent pour les personnes ou les installations.',
      'Remettre en conformité les dispositifs de protection électrique (protection contre les contacts directs et indirects, surintensités et courts-circuits).',
      'Réhabiliter les armoires électriques, coffrets de distribution et tableaux généraux en traitant les défauts de câblage, raccordement et repérage.',
      'Reprendre l\'identification, le repérage et la documentation des circuits électriques afin de sécuriser l\'exploitation.',
      'Renforcer le programme de maintenance préventive et de contrôle périodique en intégrant des vérifications systématiques.',
      'Mettre en place un plan de suivi des non-conformités avec définition des responsabilités, échéances de traitement et indicateurs de performance.',
    ];

    final counterVisit =
        'Une contre-visite de vérification réglementaire devra être programmée à l\'issue des travaux afin de confirmer la levée des non-conformités, d\'évaluer l\'efficacité des actions mises en œuvre et d\'attester du rétablissement d\'un niveau de sécurité compatible avec les exigences réglementaires et les bonnes pratiques d\'exploitation.';

    return ExecutiveSummaryData(
      contexte: SectionContexte(paragraph: contextText),
      syntheseResultats: SectionSyntheseResultats(
        introParagraph: introSynthese,
        tableRows: critRows,
        tableTotalRow: critTotalRow,
        commentaryParagraph: commentarySynthese,
      ),
      concentrationRisque: SectionConcentrationRisque(
        title: concentrationTitle,
        primaryConcentrationParagraph: primaryConcText,
        highestDensityParagraph: highestDensityText,
      ),
      facteursRisque: SectionFacteursRisque(
        introParagraph: 'Au-delà de la répartition par équipement, l\'analyse par nature de risque met en évidence les facteurs dominants suivants :',
        tableRows: riskRows,
        commentaryParagraph: riskCommentary,
      ),
      observationsMajores: SectionObservationsMajores(
        bulletPoints: bulletPoints,
        summaryParagraph: summaryObs,
      ),
      recommandationsPrioritaires: SectionRecommandationsPrioritaires(
        introParagraph: 'Les actions correctives sont hiérarchisées en trois niveaux de priorité :',
        priority1Immediate: priority1,
        priority2ShortTerm: priority2,
        priority3MediumTerm: priority3,
      ),
      appreciationGlobale: SectionAppreciationGlobale(
        assessmentParagraph1: assessment1,
        assessmentParagraph2: assessment2,
        assessmentParagraph3: assessment3,
        actionPlanHeader: 'Au regard de ces constats, il est recommandé de mettre en œuvre sans délai un plan d\'actions correctives structuré, fondé sur une hiérarchisation des risques, selon les priorités suivantes :',
        actionPlanSteps: actionSteps,
        counterVisitParagraph: counterVisit,
      ),
      isFallback: true,
    );
  }
}
