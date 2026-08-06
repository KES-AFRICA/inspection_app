# Document de Conception Technique : Architecture de Pagination Globale Centralisée (Moteur PDF V3)

**Date** : 6 Août 2026  
**Auteur** : Lead AI Architect & Senior Flutter Engineer  
**Statut** : En cours de validation  
**Fichier Cible** : `lib/services/pdf/pdf_report_service.dart`

---

## 1. Contexte & Objectifs

### 1.1 Problématique Résolue
Dans le moteur de génération PDF par micro-lots (Moteur V3), le rapport est découpé en plusieurs sous-documents PDF autonomes (`pw.Document`) pour prévenir les erreurs de débordement mémoire (*Out Of Memory*). 

Des désynchronisations de pagination apparaissaient en raison de 4 faiblesses structurelles :
1. **Saut de page initial** : L'estimation arbitraire du nombre de pages du Sommaire (`subChunk1_1_Pages`) sautait parfois la page 3 lors du passage au Périmètre.
2. **Affichages locaux non maîtrisés** : L'utilisation de `${ctx.pagesCount}` dans les footers locaux affichait des compteurs fragmentés (ex: `4/9` dans la section Mesures & Essais).
3. **Réinitialisation par lot** : La découpe dynamique par lots de photos (3 pages) réinitialisait la numérotation locale (`1/3`, `2/3`, `3/3`...).
4. **Variabilité des offsets** : La désynchronisation entre la Passe 1 (calcul des clés et du total) et la Passe 2 (génération des fichiers physiques).

### 1.2 Objectif Final
Garantir une numérotation globale unique, continue et monotone croissante (**Page 1, Page 2, Page 3, ..., Page N**) sur l'ensemble du document final fusionné, sans aucune rupture, quel que soit le nombre de chunks, de photos ou de sections conditionnelles.

---

## 2. Architecture Globale & Flux de Données

```
                                  [ENTRÉE MISSION]
                                         │
                                         ▼
                     ┌──────────────────────────────────────┐
                     │ Passe 1 : Pre-Flight & Offset Exact  │
                     └──────────────────────────────────────┘
                                         │
 1. Mesure exacte Sub-chunk 1.1 (Couverture + Sommaire réel en mémoire) -> Offset_1.2 = ExactPageCount
 2. Parcours séquentiel des Chunks (1.2 -> 13) avec propagation stricte : Offset_{i+1} = Offset_i + PageCount_i
 3. Footer en Passe 1 : Format "Page X" (Pas de "/ Total" local)
 4. Capture du nombre total exact de pages : TotalReportPages = FinalOffset
                                         │
                                         ▼
                     ┌──────────────────────────────────────┐
                     │ Passe 2 : Génération sur Disque (N)  │
                     └──────────────────────────────────────┘
                                         │
 1. Injection de overrideTotalPages = TotalReportPages
 2. Re-génération exacte avec pageOffset séquentiel identique à la Passe 1
 3. Footer en Passe 2 : Format "Page (ctx.pageNumber + pageOffset) / TotalReportPages"
 4. Écriture des fichiers chunks .pdf sur disque temporaire
                                         │
                                         ▼
                     ┌──────────────────────────────────────┐
                     │ Fusion Binaire Finale (PdfMerger)   │
                     └──────────────────────────────────────┘
                                         │
 1. Assemblage physique des Chunks .pdf dans l'ordre séquentiel 1 à N
 2. Nettoyage final des Chunks temporaires
                                         │
                                         ▼
                             [PDF FINAL UNIFIÉ 1..N]
```

---

## 3. Spécifications Détaillées des Composants

### 3.1 Pre-Flight Réel du Sub-chunk 1.1 (Couverture + Sommaire)
* **Suppression de l'estimation** : La formule `(sommaireEntries.length > 25) ? 2 : 1` est supprimée.
* **Génération préliminaire en mémoire** :
  1. La liste `sommaireEntries` est collectée au tout début de `_generateReportPass`.
  2. Le document `pdfP1_1` (Couverture + Pages Sommaire) est construit en mémoire.
  3. Le nombre exact de pages du Sub-chunk 1.1 est mesuré via `pdfP1_1.document.pdfPageList.pages.length`.
  4. L'offset de départ du Sub-chunk 1.2 est fixé à `subChunk1_1_Pages = pdfP1_1.document.pdfPageList.pages.length`.

### 3.2 Règle Stricte du Footer (`_buildFooterAbsolute`)
* **Éradication de `ctx.pagesCount`** : Le getter local `ctx.pagesCount` ne sera plus jamais appelé pour afficher le total des pages.
* **Format de rendu** :
  ```dart
  final pageNum = ctx.pageNumber + pageOffset;
  final String pageStr = (overrideTotalPages != null)
      ? 'Page $pageNum / $overrideTotalPages'
      : 'Page $pageNum';
  ```
* **Résultat** : En Passe 1, le footer indique `Page 3`. En Passe 2, le footer indique `Page 3 / 48`. Aucun chunk ne peut afficher `Page 1 / 3` ou `Page 4 / 9`.

### 3.3 Chaîne d'Offset Séquentielle Continue
Chaque section ou créateur de chunk reçoit `int pageOffset` et renvoie le nombre exact de pages produites `int totalPages` :

1. **Sub-chunk 1.1** : Offset `0`. Taille `P_1_1`.
2. **Sub-chunk 1.2** (Objet & Périmètre) : Offset `P_1_1`. Taille `P_1_2`.
3. **Sub-chunk 1.3** (Résumé Executif & Stats) : Offset `P_1_1 + P_1_2`. Taille `P_1_3`.
4. **Sub-chunk 1.4** (RG & Description) : Offset cumulé. Taille `P_1_4`.
5. **Section 6** (Synthèse Récapitulative Chunked) : Offset cumulé. Met à jour `currentOffset` à chaque lot BT/MT.
6. **Section 7** (Audit Détaillé Chunked) : Offset cumulé. Met à jour `currentOffset` à chaque lot de Zone.
7. **Sub-chunk 2.1** (Classement, Foudre, Mesures & Signatures) : Offset cumulé.
8. **Sub-chunk 2.2** (Garde Photos & Schéma) : Offset cumulé.
9. **Section 13** (Photos Chunked) : Offset cumulé. Met à jour `currentOffset` à chaque flush de 3 pages.

### 3.4 Invariance des Widgets & de la Fusion Binaire
- `PageTracker` : Continue d'enregistrer la page exacte d'un titre de section dans `trackedPages` avec la formule `offset + ctx.pageNumber`.
- `PdfMergerService` : Assemble la séquence finale des fichiers PDF générés sans altérer le contenu vectoriel ni la pagination inscrite sur les pages.

---

## 4. Plan de Vérification

1. **Analyse Statique (`flutter analyze lib/services/pdf/`)** :
   - 0 erreur de compilation, 0 warning sur le typage des offsets.
2. **Tests Unitaires & d'Intégration (`flutter test`)** :
   - Exécution complète des suites `pdf_report_service_test.dart`, `pdf_schema_section_test.dart`, `pdf_photos_deduplication_test.dart`.
3. **Validation Visuelle de Pagination sur PDF Produits** :
   - Vérifier que la page suivant le sommaire est la page 3 (et non 4).
   - Vérifier la section "Mesures et Essais" (pagination continue sans `/9`).
   - Vérifier la section "Photos" (pagination continue sans réinitialisation `1/3`).

---

## 5. Matrice des Risques & Mitigations

| Risque | Impact | Mitigation |
| :--- | :--- | :--- |
| Surcoût mémoire lors du pre-flight | Faible | Le document `pdfP1_1` (Couverture + Sommaire) ne contient pas d'images lourdes et fait seulement 2 à 3 pages en mémoire. |
| Incohérence entre Passe 1 et Passe 2 | Élevé | La passe 1 et la passe 2 partagent exactement les mêmes paramètres et le même pre-flight réel de Sub-chunk 1.1. |

---

## 6. Prochaines Étapes
Une fois ce document de spécification validé par l'utilisateur, appel à la compétence `planification` pour élaborer le plan d'exécution étape par étape.
