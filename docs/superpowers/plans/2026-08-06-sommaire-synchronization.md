# Plan d'implémentation - Synchronisation Parfaite du Sommaire (Moteur PDF V3)

> **Pour les agents :** SOUS-COMPÉTENCE REQUISE : Utilisez superpowers:subagent-driven-development (recommandé) ou planification pour implémenter ce plan tâche par tâche. Les étapes utilisent la syntaxe des cases à cocher (`- [ ]`) pour le suivi.

**Objectif :** Aligner parfaitement les numéros de page affichés dans le Sommaire avec les numéros de page globale réels du document final en injectant `offset: currentOffset` dans toutes les instances de `PageTracker`.

**Architecture :** Moteur PDF V3 à 2 passes. Transmission explicite de l'offset global à toutes les sous-fonctions de construction de widgets (`_buildResumeExecutifAndStatsWidgets`, `_buildAnalyseStatistique`, `_buildRenseignementsGenerauxWidgets`, `_buildDescriptionInstallationsWidgets`, `_buildClassementEmplacementsMulti`, `_buildFoudre`, `_addSchemaSection`).

**Stack Technique :** Flutter / Dart, Package `pdf`.

## Contraintes Globales
- **Invariance PDF** : Ne modifier aucune règle de pagination ni aucun pied de page.
- **Transparence** : Aucune formule d'estimation manuelle des numéros de pages.

---

### Tâche 1 : Mise à Jour des Signatures et Propagation de `offset` dans `_buildResumeExecutifAndStatsWidgets` et `_buildAnalyseStatistique`

**Fichiers :**
- Modifier : `lib/services/pdf/pdf_report_service.dart:1560-1820`

- [ ] **Étape 1 : Mettre à jour `_buildResumeExecutifAndStatsWidgets` et `_buildAnalyseStatistique`**

```dart
  static List<pw.Widget> _buildResumeExecutifAndStatsWidgets(
    Mission mission,
    AuditInstallationsElectriques? audit,
    Map<String, int> trackedPages,
    String numeroRapportDoc, {
    int offset = 0,
  }) {
    final widgets = <pw.Widget>[];
    // ...
    widgets.add(PageTracker(
      key: 'resume_executif',
      registry: trackedPages,
      offset: offset,
      child: _sectionBox('RESUME EXECUTIF'),
    ));
    // ...
    widgets.addAll(_buildAnalyseStatistique(mission, trackedPages, numeroRapportDoc, offset: offset));
    return widgets;
  }

  static List<pw.Widget> _buildAnalyseStatistique(
    Mission mission,
    Map<String, int> trackedPages,
    String numeroRapportDoc, {
    int offset = 0,
  }) {
    // Injecter offset: offset dans TOUS les PageTracker de _buildAnalyseStatistique :
    // key: 'analyse_statistique', 'stat_annee_passee', 'stat_comparaison',
    // 'stat_taux_conformite', 'stat_defauts', 'stat_tension', 'stat_croisee', 'stat_inventaire'
```

- [ ] **Étape 2 : Mettre à jour le site d'appel dans `_generateReportPass`**

```dart
    build: (ctx) => _buildResumeExecutifAndStatsWidgets(
      mission,
      audit,
      trackedPages,
      numeroRapportDoc,
      offset: currentOffset,
    ),
```

---

### Tâche 2 : Propagation de `offset` dans `_buildRenseignementsGenerauxWidgets` et `_buildDescriptionInstallationsWidgets`

**Fichiers :**
- Modifier : `lib/services/pdf/pdf_report_service.dart:2390-2810`

- [ ] **Étape 1 : Ajouter `int offset = 0` dans `_buildRenseignementsGenerauxWidgets` et `_buildDescriptionInstallationsWidgets`**

Injecter `offset: offset` sur tous leurs `PageTracker` (`'renseignements'`, `'renseignements_principaux'`, `'renseignements_documents'`, `'renseignements_habilitation'`, `'description'`, `'desc_locaux_risques'`).

- [ ] **Étape 2 : Mettre à jour les sites d'appels dans `_generateReportPass`**

Passer `offset: currentOffset` aux deux appels.

---

### Tâche 3 : Propagation de `offset` dans `_buildClassementEmplacementsMulti`, `_buildFoudre` et `_addSchemaSection`

**Fichiers :**
- Modifier : `lib/services/pdf/pdf_report_service.dart:5320-5330, 5765-5875, 7140-7150`

- [ ] **Étape 1 : Ajouter `int offset = 0` dans `_buildClassementEmplacementsMulti` et `_buildFoudre`**

Injecter `offset: offset` dans `PageTracker(key: 'classement')`, `PageTracker(key: 'foudre')`, `PageTracker(key: 'foudre_equipements')`.

- [ ] **Étape 2 : Transmettre `offset: pageOffset` dans `_addSchemaSection` pour `key: 'schema_installations'`**

```dart
  PageTracker(
    key: 'schema_installations',
    registry: trackedPages,
    offset: pageOffset,
    child: pw.Text(...),
  )
```

- [ ] **Étape 3 : Mettre à jour les sites d'appels dans `_generateReportPass`**

Passer `offset: currentOffset` à `_buildClassementEmplacementsMulti` et `_buildFoudre`.

---

### Tâche 4 : Verification Statique & Tests d'Intégration PDF

**Fichiers :**
- Tester : `test/features/pdf_schema_section_test.dart`

- [ ] **Étape 1 : Exécuter `flutter analyze lib/services/pdf/`**
- [ ] **Étape 2 : Exécuter `flutter test test/features/pdf_schema_section_test.dart`**
