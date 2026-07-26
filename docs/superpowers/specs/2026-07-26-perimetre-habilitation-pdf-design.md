# Spécification technique : Périmètre de la Mission, Habilitation Électrique et Restructuration PDF

## 1. Contexte & Objectifs

Cette évolution introduit de nouveaux champs de données métier et réorganise la structure du rapport PDF généré pour l'application d'inspection **KES Inspection App**. L'application étant déjà en production sur le terrain, cette mise à jour garantit une **rétrocompatibilité à 100%** avec les missions existantes (champs optionnels/nullables) et les sauvegardes Hive/JSON.

---

## 2. Modifications des Modèles de Données & Persistance

### A. Modèle `Mission` & `MissionEntity`
- **Nouveau champ** : `perimetreMission` (`List<String>?`)
- **Annotation Hive** : `@HiveField(40)` dans `Mission` (`lib/models/mission.dart`)
- **Valeurs prédéfinies autorisées** :
  1. `Vérification électrique`
  2. `Audit foudre`
  3. `Analyse du risque foudre et étude technique foudre`
  4. `Vérification thermographique`
  5. `Vérification des prises de terre`
- **Comportement Rétrocompatible** : Nullable. Si la donnée est absente (missions existantes), la liste est `null` ou vide.
- **Mappers & Backup** : Mis à jour dans `MissionMapper` (`toEntity`, `toModel`), `fromJson`, `toJson`.

### B. Modèle `RenseignementsGeneraux` & `RenseignementsGenerauxEntity`
- **Nouveau champ** : `formationHabilitationElectrique` (`String?`)
- **Annotation Hive** : `@HiveField(14)` dans `RenseignementsGeneraux` (`lib/models/renseignements_generaux.dart`)
- **Valeurs admises** : `'Oui'`, `'Non'`, `'Inconnu'` (Valeur par défaut absolue : `'Inconnu'`)
- **Comportement Rétrocompatible** : Si le champ est `null` ou absent dans une mission existante, la valeur retournée est automatiquement `'Inconnu'`, garantissant 0 régression. L'inspecteur peut la modifier à tout moment.
- **Mappers & Backup** : Mis à jour dans `RenseignementsGenerauxMapper` (`toEntity`, `toModel`), `toMap`.

---

## 3. Évolutions de l'Interface Utilisateur (Formulaires)

### A. Formulaire Mission (`CreateMissionScreen`)
- Intégration d'un sélecteur multi-choix (puces/chips interactives ou liste de cases à cocher) pour la sélection d'une, plusieurs ou toutes les 5 prestations du périmètre.
- Enregistrement réactif dans `MissionEntity.perimetreMission`.

### B. Formulaire Renseignements Généraux (`general_info_step.dart`)
- Ajout d'une sous-section intitulée **« HABILITATION ÉLECTRIQUE DU PERSONNEL D'INTERVENTION »**.
- Ajout d'un sélecteur à choix unique (`Oui`, `Non`, `Inconnu`) pour la question : *« Les techniciens disposent-ils d'une formation en habilitation électrique ? »*.
- Persistance dans `RenseignementsGenerauxEntity.formationHabilitationElectrique`.

---

## 4. Évolutions du Service de Rapport PDF (`PdfReportService`)

### A. Nouvelle Page : « PÉRIMÈTRE DE LA MISSION »
- **Positionnement** : Placée immédiatement après la page **« OBJET DE LA MISSION »**.
- **Design & Charte** : Même mise en page (marges 1.5 cm, en-tête avec logo, pied de page avec numérotation, filigrane).
- **Contenu** :
  - Titre de section : **PÉRIMÈTRE DE LA MISSION**
  - Sous-titre : **Prestations vendues dans le cadre de cette mission**
  - Puces élégantes affichant la liste des prestations sélectionnées dans `mission.perimetreMission`.

### B. Restructuration des Sections PDF
1. **Sommaire Dynamique & Pagination** : Entrée *PÉRIMÈTRE DE LA MISSION* ajoutée dans le sommaire et les ancres de calcul à 2 passes.
2. **Résumé Exécutif** :
   - Saut de page forcé **avant** la section.
   - Architecture préparée pour du multi-pages (jusqu'à 5 pages max).
   - Structure initiale propre (titre + conteneur prêt pour évolutions futures).
3. **Analyse Statistique** :
   - Saut de page forcé **avant** la section (démarre systématiquement sur une nouvelle page immédiatement après le Résumé Exécutif).

### C. Sous-section Habilitation Électrique dans les Renseignements Généraux
- Titre sous-section : **HABILITATION ÉLECTRIQUE DU PERSONNEL D'INTERVENTION**
- Question : *Les techniciens disposent-ils d'une formation en habilitation électrique ?*
- Valeur affichée en **gras** avec mise en évidence couleur :
  - **Oui** : Vert (`PdfColor.fromInt(0xFF2E7D32)`)
  - **Non** : Rouge (`PdfColor.fromInt(0xFFC62828)`)
  - **Inconnu** : Noir (`PdfColors.black`)

---

## 5. Plan de Validation & Non-Régression
1. **Compilation des Générateurs** : Régénération des adaptateurs Hive avec `flutter pub run build_runner build --delete-conflicting-outputs`.
2. **Analyse Statique** : Validation avec `flutter analyze`.
3. **Test Rétrocompatibilité** : Chargement de missions existantes sans les nouveaux champs pour vérifier l'absence d'erreur ou de crash.
4. **Test Export/Import** : Validation de la sauvegarde JSON et restauration sans perte de données.
5. **Test PDF** : Contrôle visuel du sommaire, de la pagination, de la nouvelle page Périmètre, des sauts de page et des couleurs du texte d'habilitation.
