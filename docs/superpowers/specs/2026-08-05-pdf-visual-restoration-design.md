# Spécification Technique — Restauration Visuelle du Rapport PDF (Sommaire, Périmètre, Synthèse MT/BT)

## 1. Vue d'ensemble

L'objectif de cette intervention est de restaurer fidèlement le rendu visuel et le niveau de finition agence du rapport PDF d'inspection électrique, tout en conservant 100 % de la stabilité, de l'architecture par chunks et des garanties anti-OOM apportées par le nouveau moteur V3.

Cette modification touche exclusivement la couche de présentation (widgets PDF `pw.*`, tableaux, styles, bordures et calculs de décalage d'index de sommaire) sans altérer le pipeline de génération ni la fusion binaire natif (`PdfMergerService`).

---

## 2. Exigences et Principes Non-Négociables

1. **Stabilité Mémoire (Anti-OOM)** : Aucun chargement simultané d'images brutes en RAM, maintien des allocations légères et déchargement par micro-lots.
2. **Intégrité de l'Architecture V3** : Conservation des sous-chunks découpés (`p1_1`, `p1_2`, `p1_3`, `p1_4`, `recap_cover`, `recap_mt`, `recap_bt`, `audit`, `p2_1`, `p2_2`, `photos`) et de leur assemblage via `PdfMergerService`.
3. **Zéro Régression Métier** : Les données calculées (statistiques, non-conformités, références normatives, périmètres, durées, verificateurs) restent identiques.

---

## 3. Spécification des Composants Visuels

### 3.1 Sommaire Dynamique & Pagination (Fix Numérotation)
- **Problème résolu** : Dans la génération par chunks, le Sub-chunk 1.1 (Sommaire) était généré avant la connaissance du nombre exact de pages des sections suivantes.
- **Solution** :
  - Générer les chunks d'infrastructure et de contenu (1.2 à photos), et enregistrer la taille en pages réelle de chaque document `pw.Document`.
  - Calculer le décalage cumulé global pour chaque clé de section (`objet`, `perimetre`, `liste_recap`, `liste_recap_mt`, `liste_recap_bt`, `foudre`, `mesures`, `photos`, etc.).
  - Re-générer le Sub-chunk 1.1 (Couverture & Sommaire) en lui injectant la carte `trackedPages` complète avec les numéros de pages réels.
  - Placer `pdf_chunk_p1_1` au début du tableau de fusion binaire.
- **Résultat** : Numérotation 100 % exacte et dynamique sur l'ensemble du document.

---

### 3.2 Tableau « PERIMÈTRE DE LA MISSION »
- **Fidélité visuelle (Référence : Image 1)** :
  - En-tête : Bandeau bleu marine `#1E3A8A` avec le titre `PERIMETRE DE LA MISSION` (Texte blanc, majuscules, gras, taille 11 pt).
  - Bordure globale et intérieure : `#334155` (0.8 pt).
  - Structure :
    - Colonne 1 (`Fixe: 175 pt`) : Intitulés en gras `#1E3A8A` (`Missions`, `Nature`, `Dates d'intervention`, `Durée`, `Accompagnateur / Responsable`, `Compte rendu de fin de visite fait à`, `Vérificateur(s)`).
    - Colonne 2 (`Flexible`) : Valeurs correspondantes.
  - Alignement vertical centré sur toutes les cellules (`pw.TableCellVerticalAlignment.middle`), éliminant l'étirement ou le décalage d'affichage sur les missions à fort volume (ex: **Cimencam**).

---

### 3.3 Section « SYNTHÈSE RÉCAPITULATIVE DES OBSERVATIONS » (MT & BT)

#### A. Moyenne Tension (MT) — Référence Image 2
- **Bandeau de section** : Fond bleu vif `#2563EB`, texte blanc `Moyenne tension`.
- **Structure d'en-tête 2 niveaux** :
  - Ligne 1 (`#1E3A8A`) : `LOCALISATION` | `NON-CONFORMITÉ - PRÉCONISATION`.
  - Ligne 2 (`#2E5F9A`) : `LOCAL` | `OBSERVATIONS` | `RÉF. NORMATIVE`.
- **Rendu du tableau** :
  - 3 colonnes distinctes : `LOCAL` (22 %), `OBSERVATIONS` (58 %), `RÉF. NORMATIVE` (20 %).
  - Cellule `LOCAL` : Texte majuscule gras centré verticalement sur l'ensemble des observations du même local.
  - Lignes d'observations : Bordures cellulaires fines (`#475569`, 0.4 pt), alternance de fond (`#F8FAFC` / blanc), alignement à gauche pour l'observation et centré pour la référence normative.

#### B. Basse Tension (BT) — Références Images 3, 4 et 5
- **Bandeau de section** : Fond bleu vif `#2563EB`, texte blanc `Basse tension`.
- **Structure d'en-tête 2 niveaux** :
  - Ligne 1 (`#1E3A8A`) : `LOCALISATION` | `NON-CONFORMITÉ - PRÉCONISATION`.
  - Ligne 2 (`#2E5F9A`) : `#` | `ÉQUIPEMENT` | `OBSERVATIONS` | `RÉF. NORMATIVE`.
- **Ligne de séparation Zone / Local** :
  - Bandeau sous-section bleu céleste clair `#DBEAFE` avec texte bleu foncé `#1E3A8A` : `LOCALISATION` | `[Nom du local ou de la zone]`.
- **Rendu du tableau** :
  - 4 colonnes distinctes : `#` (8 %), `ÉQUIPEMENT` (22 %), `OBSERVATIONS` (52 %), `RÉF. NORMATIVE` (18 %).
  - Colonne `#` : Indexation numérique continue (`1`, `2`, `3`...), centrée verticalement.
  - Colonne `ÉQUIPEMENT` : Nom de l'équipement en majuscules gras centré verticalement sur le groupe d'observations.
  - Continuity & Borders : Unification du tableau pour éviter la fragmentation en micro-tables et maintenir des bordures cellulaires fermées sur toutes les pages.

---

## 4. Plan de Validation

1. **Compilation Statique** : `flutter analyze lib/services/pdf/` (0 erreur).
2. **Tests Unitaires & d'Intégration** : `flutter test test/features/` (100 % de réussite).
3. **Test de Volume & Rendu** : Génération complète sur une mission moyenne (Camrail) et une mission volumineuse (Cimencam).
