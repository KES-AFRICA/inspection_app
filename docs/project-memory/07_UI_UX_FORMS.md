# 07_UI_UX_FORMS.md — Interface Utilisateur, Ergonomie Terrain & Formulaires

> **Module** : KES Inspection App — Pilier 7  
> **Dernière révision** : 24 Septembre 2026  
> **Source de vérité** : `lib/pages/`, `lib/features/*/presentation/`, `lib/constants/app_theme.dart`

---

## 1. SYSTÈME DE DESIGN (Design System KES)

### Palette de Couleurs (Tokens immuables)

| Token | Valeur Hex | Usage |
|---|---|---|
| `primaryBlue` | `#2196F3` | Boutons principaux, actions, FAB |
| `darkBlue` | `#1976D2` / `#1E3A8A` | En-têtes, titres, AppBar |
| `greyLight` | `#F5F5F5` | Fonds de champs et cartes neutres |
| `successGreen` | `#4CAF50` | Conformités validées, compteurs OK |
| `warningOrange` | `#FF9800` | Non-conformités mineures |
| `errorRed` | `#F44336` | Non-conformités critiques, erreurs |
| `backgroundDark` | `#121212` | Fond d'écran en mode chantier sombre |

Fichier de référence : `lib/constants/app_theme.dart`

### Typographie

- **Police principale** : Roboto (Material Design) — intégrée nativement Flutter
- **Titres d'écrans** : `TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkBlue)`
- **Sous-titres de section** : `TextStyle(fontSize: 16, fontWeight: FontWeight.w600)`
- **Libellés de champs** : `TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])`
- **Corps / valeurs** : `TextStyle(fontSize: 14, color: Colors.black87)`

---

## 2. ERGONOMIE TERRAIN (Contraintes Industrielles)

### Cibles Tactiles
- **Minimum absolu** : `48x48 dp` pour tout bouton, case à cocher, interrupteur ou sélecteur.
- **Raison** : Les inspecteurs portent des gants d'isolation ou de protection lors de la saisie sur site.
- **Pattern** : Toujours encapsuler dans `InkWell` ou `GestureDetector` avec une zone de tap > 48dp :
  ```dart
  Padding(
    padding: const EdgeInsets.all(8), // Assure la zone de tap minimale
    child: Checkbox(...),
  )
  ```

### Persistance Automatique
- Toute modification dans un formulaire déclenche une sauvegarde **non-bloquante** via le provider.
- Pattern utilisé : `onChanged` avec **debounce de 300ms** ou `onEditingComplete`/`onFieldSubmitted` pour les champs de texte.
- La sauvegarde ne doit jamais bloquer l'UI — elle s'exécute en arrière-plan via Riverpod.

### Saisie Assistée
- Les champs à valeurs fréquentes proposent un `DropdownButton` ou des `FilterChip` avec les options les plus courantes.
- Un champ libre *« Autre / Saisir »* est toujours disponible pour les cas non couverts.
- **Clavier numérique** (`TextInputType.numberWithOptions`) pour les mesures physiques (résistances, calibres, sections).

---

## 3. NAVIGATION SÉQUENTIELLE (SequenceScreen)

Fichier : `lib/pages/missions/sequence/sequence_screen.dart`

L'inspection est guidée par `SequenceProgressService` en étapes **chronologiques et non-régressives** :

```text
Étape 1 — Informations générales       → general_info_step.dart
Étape 2 — Description des installations → description_step.dart
Étape 3 — Audit installations          → audit_step.dart
Étape 4 — Schémas & Documents          → schema_step.dart + documents_step.dart
Étape 5 — Job Safety Analysis          → jsa_step.dart
Étape 6 — Synthèse & Génération rapports → summary_step.dart
```

- L'indicateur de progression est affiché en haut d'écran (stepper linéaire).
- La navigation entre étapes est possible via les boutons Suivant/Précédent ET via le stepper cliquable.
- Chaque étape persiste ses données avant la navigation vers la suivante.

---

## 4. FORMULAIRE COFFRET ARMOIRE (`CoffretFormScreen`)

C'est le formulaire le plus complexe de l'application. Il couvre :

### Sections du formulaire
1. **Métadonnées de l'armoire** : Nom, repère, localisation, type de tableau.
2. **Caractéristiques électriques** : Source d'alimentation, protection amont (calibre, type), courbe disjoncteur, présence DDR.
3. **Départs terminaux** (`DepartEquipement`) : Liste extensible de départs avec calibre (A), section (mm²), longueur, destination.
4. **Circuits terminaux** (`CircuitTerminalEquipement`) : Circuits à l'intérieur du départ (appareils spécifiques, puissances).
5. **Points de vérification** (`PointVerification`) : Constats réglementaires NF C 15-100, photos, non-conformités.
6. **Photos** : Jusqu'à N photos par coffret, compressées via `flutter_image_compress` avant stockage.

### Pattern de mise à jour (Sans perte de données)
```dart
// ✅ CORRECT — Copie défensive de l'objet puis mutation ciblée
final updatedCoffret = currentCoffret.copyWith(
  nom: newNom,
  departsEquipements: updatedDeparts,
);
ref.read(auditInstallationsProvider(missionId).notifier).saveAudit(updatedAudit);

// ❌ INTERDIT — Mutation directe de l'objet Hive (provoque des incohérences)
currentCoffret.nom = newNom; // Ne jamais faire ça
```

---

## 5. SÉLECTEUR DE SOURCE D'ALIMENTATION

Fichier : `lib/services/equipment_source_search_service.dart`

- Résolution hiérarchique : la source d'un coffret est recherchée dans la liste des TGBT/Armoires/Départs de la mission.
- Si aucune correspondance exacte → Mode de similarité (distance de Levenshtein normalisée).
- Affichage : `AutocompleteField` avec suggestions dynamiques filtrées lors de la frappe.
- Si la source reste vide ou non reconnue → Afficher le badge `Non identifiée` (accord **féminin** obligatoire).

---

## 6. COMPOSANT POINT DE VÉRIFICATION (`PointVerificationWidget`)

Chaque point de vérification dans un coffret ou un local possède :
- **Référence normative** : Sélecteur parmi les 496+ points du `NormativeReferenceService`.
- **Statut** : `Conforme` ✅ / `Non-Conforme` ❌ / `Sans Objet` ➖ / `Non Vérifié` ⬜
- **Constat** : Champ texte libre (description de l'observation).
- **Criticité** : Calculée automatiquement par `CriticalityEngine` selon la norme et le statut.
- **Photos** : Miniatures en grille avec possibilité d'agrandir ou supprimer.

### Règle d'affichage des non-conformités
- Non-conformité `Critique` → Fond rouge (`errorRed`) et icône ⚠️.
- Non-conformité `Importante` → Fond orange (`warningOrange`).
- Non-conformité `Mineure` → Fond jaune.
- Conforme → Fond vert clair (`successGreen`).

---

## 7. LISTE DES MISSIONS (MissionListScreen)

Fichier : `lib/pages/missions/mission_list_screen.dart`

- Affichage en **ListView.builder** avec `MissionCard` pour chaque mission.
- Chaque carte affiche : titre, client, date de création, avancement (% étapes complétées), statut sync backup.
- Tri par date de modification décroissante (par défaut).
- Recherche et filtrage par : client, statut, date.
- Actions rapides sur swipe : Archiver, Supprimer (vers corbeille), Dupliquer.

---

## 8. INDICATEUR GLOBAL DE SAUVEGARDE (`GlobalBackupProgressOverlay`)

- Une barre de progression flottante en bas d'écran s'affiche automatiquement lorsque `backupOrchestratorProvider` est en état `uploading`.
- L'overlay est transparent aux événements tactiles (ne bloque pas la saisie).
- Disparaît automatiquement après succès ou échec (avec snackbar de confirmation).

---

## 9. THÈME CLAIR / SOMBRE

- L'application supporte le **mode clair et le mode sombre** via `ThemeData.dark()`.
- Le mode sombre est prioritaire sur les terminaux durcis (économie batterie sur écran OLED).
- Les constantes de couleur dans `app_theme.dart` ont des variantes `*Dark` pour le mode sombre.
- Ne jamais utiliser `Colors.white` ou `Colors.black` directement dans le code — toujours référencer les tokens du thème.
