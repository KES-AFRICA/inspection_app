# Spécification de Conception : Refactorisation de PdfReportService (Façade & Builders Spécialisés)

**Date :** 2026-09-06  
**Auteur :** Antigravity & Lead Engineer  
**Statut :** Validé / En cours de planification  
**Cible :** lib/services/pdf/pdf_report_service.dart (~21 700 lignes)  

---

## 1. Contexte & Objectif

Le fichier lib/services/pdf/pdf_report_service.dart est le composant central de génération des rapports d\'audit électrique (KES Inspections and Projects). Il compte aujourd\'hui **21 700 lignes de code**, ce qui ralentit l\'IDE, complique la maintenance et rend les évolutions risquées.

### Exigences Impératives Utilisateur :
1. **Zéro Régression :** Le rendu PDF, les calculs, les formules de conformité et l\'intégrité des données doivent être 100% identiques au bit et au pixel près.
2. **Préservation Absolue de la Pagination :** Le moteur à 2 passes (_generateReportPass), la résolution dynamique du sommaire via PageTracker, les en-têtes/pieds de page dynamiques et le découpage en sous-chunks (PdfChunkMerger) doivent être rigoureusement conservés.
3. **Maintien des Contrats Publics & Tests :** Les 27 suites de tests existantes dans 	est/features/ et les appels depuis les 15 écrans de l\'application ne doivent subir aucune modification d\'interface.

---

## 2. Architecture Cible : Façade & Builders Spécialisés

L\'architecture adopte le patron **Façade** (exposant l\'API publique PdfReportService) associé à un ensemble de **Builders Spécialisés** par section métier, coordonnés par un contexte partagé PdfReportContext.

`mermaid
graph TD
    UI[Écrans & Contrôleurs UI / Tests] --> Façade[PdfReportService - Façade Publique]
    Façade --> Orchestrator[Moteur 2 Passes _generateReportPass]
    
    subgraph Core Shared Layer
        Context[PdfReportContext
Données, Assets, Polices, Session]
        Styles[PdfReportStyles
Couleurs, Typo, Helpers de table, Cellules]
    end
    
    Orchestrator --> Context
    Orchestrator --> Styles
    
    subgraph Builders Spécialisés (lib/services/pdf/builders/)
        B1[PdfCoverBuilder
Page de garde & Intervenants]
        B2[PdfSommaireBuilder
Sommaire dynamique & Collecte entrées]
        B3[PdfRegulatoryBuilder
Normes, Matériel & Périmètre]
        B4[PdfExecutiveSummaryBuilder
Résumé exécutif, Criticité, Facteurs]
        B5[PdfStatisticsBuilder
Pareto, Graphiques, Statistiques]
        B6[PdfRenseignementsBuilder
Renseignements généraux]
        B7[PdfDescriptionBuilder
Description MT/BT, Postes, Alimentation]
        B8[PdfEquipementsSynthesisBuilder
Synthèse équipements & Sources inconnues]
        B9[PdfObservationsRecapBuilder
Liste récapitulative unifiée]
        B10[PdfAuditInstallationsBuilder
Audit détaillé : Coffrets, Cellules, Transfos]
        B11[PdfClassementFoudreBuilder
Classement locaux & Foudre]
        B12[PdfMesuresEssaisBuilder
Mesures de terre, Continuité, Isolement]
        B13[PdfPhotosSchemasBuilder
Photographies chunkées & Schémas]
    end

    Orchestrator --> B1
    Orchestrator --> B2
    Orchestrator --> B3
    Orchestrator --> B4
    Orchestrator --> B5
    Orchestrator --> B6
    Orchestrator --> B7
    Orchestrator --> B8
    Orchestrator --> B9
    Orchestrator --> B10
    Orchestrator --> B11
    Orchestrator --> B12
    Orchestrator --> B13
    
    Orchestrator --> Merger[PdfMergerService
Assemblage binaire final]
`

---

## 3. Garantie de Préservation de la Pagination (Moteur 2-Passes)

La pagination de pdf_report_service.dart repose sur un mécanisme précis qu\'il est formellement interdit d\'altérer :

### 3.1. Algorithme des 2 Passes
1. **Passe 1 (saveFilesToDisk: false, overrideTotalPages: null) :**
   - Génération complète en mémoire de tous les sub-chunks.
   - Les instances de PageTracker enregistrent dans 	rackedPages: Map<String, int> le numéro de page physique exact de chaque section (currentOffset + pageIndexInDoc).
   - Le pré-flight de PdfSommaireBuilder calcule le nombre exact de pages occupées par la couverture et le sommaire sans estimation.
   - Le résultat final fournit 	otalReportPages.
2. **Passe 2 (saveFilesToDisk: true, overrideTotalPages: totalReportPages) :**
   - Régénération complète avec le 	otalReportPages injecté dans le pied de page : Page X / .
   - Les numéros de page résolus dans 	rackedPages lors de la Passe 1 sont injectés directement dans le sommaire dynamique (_buildSommaireEntryLine).
   - Les fichiers PDF temporaires sont écrits sur disque dans 	empDir.
3. **Fusion binaire finale :**
   - PdfMergerService.mergePdfFiles assemble tous les fichiers PDF des sub-chunks en préservant l\'ordre strict sans ré-encodage destructeur.

### 3.2. Préservation des Clés et Offsets de PageTracker
Chaque builder recevra exactement :
- Le dictionnaire 	rackedPages
- L\'entier currentOffset
- L\'entier optionnel overrideTotalPages
- Les clés de tracking ('objet', 'objet_normes', 'objet_materiel', 'perimetre', 'resume', 'stats', 'renseignements', 'description', 'synthese_equipements', 'liste_recapitulative', 'audit', 'classement', 'mesures', 'photos', 'schemas') restent **strictement identiques**.

---

## 4. Garantie de Préservation des Calculs & Données

Tous les algorithmes de calcul métier seront extraits sans aucune modification :
1. **Statistiques & Pareto :**
   - MissionStatisticsCollector.calculate(audit, desc) reste la source de vérité.
   - Ratios de criticité : critique / total, majeure / total, mineure / total formatés avec _formatPercent.
2. **Synthèse Équipements & Sources Inconnues :**
   - Regroupement strict par Zone -> Local -> Repère -> Équipement.
   - Détection des sources d\'alimentation inconnues (isUnknownSource).
3. **Liste Récapitulative Unifiée :**
   - Agrégation des _ObsRecap (observations de coffrets, cellules, transfos, locaux et observations libres).
   - Tri par criticité décroissante puis par localisation (Zone > Local > Repère).
4. **Mesures & Essais :**
   - Vérification des seuils de résistance de terre (ex: $\\le 100\\,\\Omega$ ou $\\le 5\\,\\Omega$).
   - Continuité des masses et isolement (tableaux paysage avec gestion des valeurs Sans objet).
5. **Registre des Photos :**
   - Attribution déterministe des numéros de photos (_buildPhotoNumberRegistry).

---

## 5. Découpage Modulaire des Fichiers

| Fichier Cible | Rôle Métier | Lignes Estimées |
| :--- | :--- | :--- |
| lib/services/pdf/pdf_report_context.dart | Modèle de données du rapport, polices chargées, images/logos en cache, session temp | ~250 |
| lib/services/pdf/pdf_report_styles.dart | Thèmes (Cover, Portrait, Landscape), Palette graphique (Bleu #003366, Orange #FF6600), Composants de cellules | ~450 |
| lib/services/pdf/builders/pdf_cover_builder.dart | Page de garde officielle, métadonnées client/site, page intervenants & responsabilités | ~350 |
| lib/services/pdf/builders/pdf_sommaire_builder.dart | Collecte des sections, construction du sommaire dynamique multi-pages, calcul préflight | ~300 |
| lib/services/pdf/builders/pdf_regulatory_builder.dart | Tableaux des normes applicables, matériels de mesure étalonnés, périmètre de vérification | ~350 |
| lib/services/pdf/builders/pdf_executive_summary_builder.dart | Résumé exécutif KES, tableaux de criticité globale, analyse des facteurs de risque | ~700 |
| lib/services/pdf/builders/pdf_statistics_builder.dart | Diagramme Pareto, histogrammes de non-conformités, statistiques par zone/équipement | ~600 |
| lib/services/pdf/builders/pdf_renseignements_builder.dart | Tableaux d\'informations administratives du site et du client | ~300 |
| lib/services/pdf/builders/pdf_description_builder.dart | Description générale des installations (MT, BT, transformateurs, TGBT, alimentations) | ~800 |
| lib/services/pdf/builders/pdf_equipements_synthesis_builder.dart | Synthèse consolidée des équipements, gestion du chunking par page | ~650 |
| lib/services/pdf/builders/pdf_observations_recap_builder.dart | Tableau récapitulatif unifié des non-conformités avec références normatives | ~750 |
| lib/services/pdf/builders/pdf_audit_installations_builder.dart | Grilles d\'audit technique : coffrets, cellules MT, transformateurs, PV de vérification | ~1 200 |
| lib/services/pdf/builders/pdf_classement_foudre_builder.dart | Fiches de classement des locaux, influences externes et risque foudre/parafoudres | ~600 |
| lib/services/pdf/builders/pdf_mesures_essais_builder.dart | Tableaux en mode paysage : boucle de terre, continuité équipotentielle, isolement | ~800 |
| lib/services/pdf/builders/pdf_photos_schemas_builder.dart | Mosaïque de photographies probantes chunkée pour éviter les saturations mémoire | ~650 |
| lib/services/pdf/pdf_report_service.dart | **Façade publique** : Orchestration des 2 passes, fusion binaire, délégations @visibleForTesting | ~700 |

---

## 6. Stratégie de Vérification et Tests de Non-Régression

1. **Harnais de Tests Automatisés (27 Suites) :**
   Exécution continue de l\'ensemble des tests 	est/features/pdf_*.dart :
   - pdf_filename_format_test.dart
   - pdf_merger_test.dart
   - pdf_equipements_synthesis_test.dart
   - pdf_audit_coffret_tables_test.dart
   - pdf_observations_synthesis_evolution_test.dart
   - pdf_foudre_surtension_test.dart
   - pdf_continuite_and_classement_test.dart
   - pdf_section2_essais_landscape_test.dart
   - sommaire_dynamic_test.dart
   - ... et tous les autres tests de régression.
2. **Test End-to-End de Génération Complète :**
   Exécution de guinness_bassa_audit_test.dart et vérification de la génération du rapport PDF réel de bout en bout avec contrôle du nombre de pages et de la taille du fichier.
3. **Validation Matérielle Réelle :**
   Vérification sur le smartphone de terrain Ulefone Armor X16 connecté en USB via ADB.
