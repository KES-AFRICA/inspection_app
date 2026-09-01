# SPÉCIFICATION DE DESIGN PDF — SYNTHÈSE DES OBSERVATIONS
**Date :** 01 Septembre 2026  
**Auteur :** Antigravity AI Engine  
**Fichier cible :** `lib/services/pdf/pdf_report_service.dart`

---

## 1. CONTEXTE ET OBJECTIF

La section « Synthèse des observations » du rapport PDF présente actuellement des défauts visuels et structurels majeurs :
1. **Cellules orphelines / vides** lors des sauts de page (le nom de l'équipement et de la zone n'apparaissant que sur une seule ligne centrale, la nouvelle page affiche des colonnes vides).
2. **Délimitations absentes ou mal alignées** entre les différents équipements d'une même zone.
3. **Absence de contraste visuel** et mauvaise alternance des couleurs (colonnes forcées à blanc pur, fond d'observations très peu contrasté).

L'objectif de cette refonte est d'implémenter l'**Option Recommandée (Option A + C1)** pour garantir une mise en page de qualité agence, 100 % custom, parfaitement lisible et insensible aux sauts de page.

---

## 2. SPÉCIFICATION DU NOUVEAU RENDU VISUEL

### 2.1 Structure Hiérarchique par Blocs d'Équipement

Au lieu d'un unique tableau monolithique de 5 colonnes avec des cellules vides, le rendu est structuré en **cartes / blocs d'équipements autonomes** :

1. **Bandeau de Localisation (Zone / Local)** :
   - Fond : `#1E3A8A` (Dark Navy).
   - Texte : Blanc gras 9pt centrée ou alignée à gauche avec retrait (ex: `ZONE : ETAGE 2  |  LOCAL / REPÈRE : LOCAL TECHNIQUE`).
   - Hauteur et marges respirantes (padding vertical 4pt).

2. **Bandeau d'En-tête d'Équipement (Option C1)** :
   - Fond : `#DBEAFE` (Soft Blue Accent) ou `#E2E8F0` (Slate Soft Header).
   - Bordure : Solide `#1E3A8A` de 1.0 pt sur tout le contour.
   - Texte : Gras Navy 8.5pt (ex: `ÉQUIPEMENT : Armoire E41` ou `Coffret Électrique départ clim`).
   - **Protection Saut de Page** : Ce bandeau ou son rappel contextuel accompagne chaque groupe d'observations, éliminant à 100 % les observations orphelines sur une nouvelle page.

3. **Tableau des Observations de l'Équipement** :
   - **Colonnes** :
     - `N°` : 8% de largeur, centré (ex: 1, 2, 3...).
     - `Non-conformité - Préconisation` : 67% de largeur, aligné à gauche avec padding 4pt.
     - `Référence Normative` : 25% de largeur, centré avec style propre (ex: `NF C 15-100-1:2024 - art 514`).
   - **Alternance de Couleur des Lignes (Row Shading)** :
     - Ligne paire (1, 3, 5...) : Blanc pur (`#FFFFFF`).
     - Ligne impaire (2, 4, 6...) : Soft Ice Grey (`#F8FAFC`).
   - **Bordures Internes et Externes** :
     - Entre observations d'un même équipement : Ligne fine grise (`#CBD5E1`, 0.5 pt).
     - Contour de l'équipement : Ligne solide fermée (`#1E3A8A`, 1.0 pt).

---

## 3. RÈGLES DE DÉLIMITATION ET DE PAGINATION

- **Sauts de page** : Si les observations d'un équipement dépassent sur la page suivante, le bloc est proprement découpé ou l'en-tête de l'équipement est rappelé en haut de page.
- **Aucune ligne vide** : Aucune ligne du tableau n'aura de cellule Zone/Local/Équipement vide ou orpheline.
- **Rapports volumineux (Mode Isolate/Chunked)** : Le découpage par tranche d'équipements/zones (`batchSize`) dans `_addListeRecapitulativeSectionChunked` reste 100 % compatible et fluide.

---

## 4. IMPACT SUR LE CODE ET REFACTORING

- **Fichier impacté** : `lib/services/pdf/pdf_report_service.dart`.
- **Méthodes réécrites** :
  - `_buildObsRecapTableUnifie(List<_ObsRecap> obs)`
  - `_buildObsRecapTableMT(List<_ObsRecap> obs)`
  - Helpers d'en-tête et d'alternance de lignes.
- **Tests associés** :
  - `test/features/pdf_equipements_synthesis_test.dart`
  - `test/features/pdf_equipements_summary_table_test.dart`

---

## 5. VALIDATION ET CRITÈRES DE SUCCÈS

1. Les 4 photos transmises par l'utilisateur sont corrigées : plus aucune observation sans nom d'équipement, plus aucune cellule vide sur saut de page.
2. Les délimitations entre équipements sont immédiatement distinctes grâce au bandeau d'en-tête d'équipement et aux bordures fermées.
3. L'alternance des couleurs est harmonieuse, contrastée et conforme aux standards de design du rapport (Navy `#1E3A8A`, Soft Blue `#DBEAFE`, Soft Ice `#F8FAFC`).
