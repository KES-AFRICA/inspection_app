# Document de Conception Technique : Synchronisation Parfaite du Sommaire (Moteur PDF V3)

**Date** : 6 Août 2026  
**Auteur** : Lead AI Architect & Senior Flutter Engineer  
**Statut** : Approuvé & En cours d'implémentation  
**Fichier Cible** : `lib/services/pdf/pdf_report_service.dart`

---

## 1. Contexte & Problématique Résolue

### 1.1 Problématique
La pagination générale du document PDF est désormais 100% continue et exacte (`Page X / N`). Cependant, le Sommaire affichait des numéros de pages erronés ou décalés pour certaines sections (ex: `1` ou `2` au lieu de `15` ou `48`).

### 1.2 Cause Racine Identifiée
Dans l'architecture par micro-lots Moteur V3, le document PDF est découpé en plusieurs sous-documents autonomes (`pdfP1_2`, `pdfP1_3`, `pdfP1_4`, `pdfP2_1`, `pdfSchema`, etc.).
Les widgets utilitaires `PageTracker` enregistrent la page d'un titre dans la carte dynamique `trackedPages[key]` via la formule :

$$\text{trackedPages}[\text{key}] = \text{context.pageNumber} + \text{offset}$$

Plusieurs fonctions de construction de widgets (`_buildResumeExecutifAndStatsWidgets`, `_buildAnalyseStatistique`, `_buildRenseignementsGenerauxWidgets`, `_buildDescriptionInstallationsWidgets`, `_buildClassementEmplacementsMulti`, `_buildFoudre`, `_addSchemaSection`) omettaient de transmettre `offset: currentOffset` à leurs instances de `PageTracker`.
En conséquence, `PageTracker` utilisait `offset: 0` par défaut et enregistrait le numéro de page relatif du lot local au lieu du numéro de page globale du rapport final.

---

## 2. Solution Architecturale

### 2.1 Injection Systématique de `offset` dans les Fonctions Widget Builders
Toutes les fonctions construisant des widgets avec `PageTracker` accepteront le paramètre obligatoire/optionnel `int offset = 0` (ou `int pageOffset = 0`) et le propageront à **100% des instances de `PageTracker`** :

1. `_buildObjetPerimetreSecuriteWidgets(..., int offset)` -> `offset: offset` sur `key: 'objet'`
2. `_buildResumeExecutifAndStatsWidgets(..., int offset)` -> `offset: offset` sur `key: 'resume_executif'`
3. `_buildAnalyseStatistique(..., int offset)` -> `offset: offset` sur `'analyse_statistique'`, `'stat_annee_passee'`, `'stat_comparaison'`, `'stat_taux_conformite'`, `'stat_defauts'`, `'stat_tension'`, `'stat_croisee'`, `'stat_inventaire'`
4. `_buildRenseignementsGenerauxWidgets(..., int offset)` -> `offset: offset` sur `'renseignements'`, `'renseignements_principaux'`, `'renseignements_documents'`, `'renseignements_habilitation'`
5. `_buildDescriptionInstallationsWidgets(..., int offset)` -> `offset: offset` sur `'description'`, `'desc_locaux_risques'`
6. `_buildClassementEmplacementsMulti(..., int offset)` -> `offset: offset` sur `'classement'`
7. `_buildFoudre(..., int offset)` -> `offset: offset` sur `'foudre'`, `'foudre_equipements'`
8. `_addSchemaSection(..., int pageOffset)` -> `offset: pageOffset` sur `'schema_installations'`

### 2.2 Zéro Estimation & Source Unique de Vérité
Lors de la Passe 1, `trackedPages` enregistrera les numéros de page globale réels et exacts.
Lors de la Passe 2, `_addSommairePages` utilisera `trackedPages[key]` via `PageNumberText` pour afficher les numéros réels du document final sans aucun décalage ni calcul d'appoint.

---

## 3. Matrice de Synchronisation des 14 Sections

| Clé Section (`trackedPages`) | Intitulé Sommaire | Propagation Offset Verifiée |
| :--- | :--- | :--- |
| `objet` | OBJET DE LA VÉRIFICATION | Oui |
| `perimetre` | PERIMETRE DE LA MISSION | Oui |
| `rappel` | RAPPEL DES RESPONSABILITÉS | Oui |
| `mesures_securite` | MESURES DE SÉCURITÉ | Oui |
| `resume_executif` | RESUME EXECUTIF | Oui |
| `analyse_statistique` | ANALYSE STATISTIQUE | Oui |
| `renseignements` | RENSEIGNEMENTS GÉNÉRAUX | Oui |
| `description` | DESCRIPTION DES INSTALLATIONS | Oui |
| `liste_recap` | SYNTHÈSE RÉCAPITULATIVE | Oui |
| `audit` | AUDIT DES INSTALLATIONS | Oui |
| `classement` | CLASSEMENT ET EMPLACEMENTS | Oui |
| `foudre` | FOUDRE | Oui |
| `mesures` | RESULTATS DES MESURES ET ESSAIS | Oui |
| `photos` | PHOTOS | Oui |
| `schema_installations` | SCHEMA DES INSTALLATIONS (si Oui) | Oui |

---

## 4. Plan de Validation

1. **Analyse Statique (`flutter analyze lib/services/pdf/`)** : 0 erreur.
2. **Tests d'Intégration PDF (`flutter test test/features/pdf_schema_section_test.dart`)** : 100% Succès.
