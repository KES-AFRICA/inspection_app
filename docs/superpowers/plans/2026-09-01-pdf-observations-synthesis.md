# Plan d'implémentation - Refonte du Tableau de Synthèse des Observations PDF

> **Pour les agents :** SOUS-COMPÉTENCE REQUISE : Utilisez planification ou exécution directe pour implémenter ce plan tâche par tâche. Les étapes utilisent la syntaxe des cases à cocher (`- [ ]`) pour le suivi.

**Objectif :** Refondre l'affichage des tableaux de synthèse récapitulative des observations dans le rapport PDF afin d'offrir un rendu de qualité agence par cartes/blocs d'équipements avec bandeaux d'en-tête dédiés (Option A + C1), des délimitations nettes et une alternance de couleurs contrastée, en éliminant à 100 % les observations orphelines lors des sauts de page.

**Architecture :** Restructuration de `_buildObsRecapTableUnifie` et `_buildObsRecapTableMT` dans `lib/services/pdf/pdf_report_service.dart`. Remplacement du tableau 5 colonnes monolithique avec cellules vides par un générateur de cartes d'équipements avec bandeaux d'en-tête contextuels (Zone/Local et Équipement), suivi de mini-tableaux 3 colonnes avec alternance de couleur (`#FFFFFF` / `#F8FAFC`) et bordures solides fermées (`#1E3A8A`).

**Stack Technique :** Dart, Flutter, `pdf` package (`pw.Widget`, `pw.Table`, `pw.Container`, `pw.BoxDecoration`, `pw.Border`).

## Contraintes Globales
- Pas de réécriture totale des fichiers non concernés.
- Compatibilité avec le découpage chunked et le mode Isolate.
- Maintien du passage au vert de la suite de tests automatisés (`test/features/pdf_equipements_synthesis_test.dart` et `test/features/pdf_equipements_summary_table_test.dart`).

---

### Tâche 1 : Restructuration de `_buildObsRecapTableUnifie` (Rendu BT par Blocs d'Équipements)

**Fichiers :**
- Modifier : `lib/services/pdf/pdf_report_service.dart` (Lignes 8617 à 8930)
- Tester : `test/features/pdf_equipements_summary_table_test.dart`

**Interfaces :**
- Consomme : `List<_ObsRecap> obs` et le découpage hiérarchique `_groupByZoneLocalEquip(obs)`
- Produit : `List<pw.Widget>` contenant les bandeaux d'en-têtes et les cartes d'observations d'équipements

- [ ] **Étape 1 : Écrire le test automatisé vérifiant la présence des bandeaux et de la nouvelle structure**

```dart
// test/features/pdf_equipements_summary_table_test.dart
test('Tableau recap unifie genere des blocs d equipements avec bandeaux', () {
  // Verifier que _buildObsRecapTableUnifie retourne une liste de widgets non vide sans exception
  final obsList = [
    _ObsRecap(zone: 'ETAGE 2', local: 'Local 1', coffret: 'Armoire E41', observation: 'Obs 1', refNorm: 'NF C 15-100'),
    _ObsRecap(zone: 'ETAGE 2', local: 'Local 1', coffret: 'Armoire E41', observation: 'Obs 2', refNorm: 'NF C 15-100'),
  ];
  final widgets = PdfReportService.testBuildObsRecapTableUnifie(obsList);
  expect(widgets, isNotEmpty);
});
```

- [ ] **Étape 2 : Exécuter la commande pour vérifier le comportement initial**

Commande : `flutter test test/features/pdf_equipements_summary_table_test.dart`

- [ ] **Étape 3 : Implémenter le nouveau rendu par blocs dans `_buildObsRecapTableUnifie`**

Remplacer la boucle générant des lignes avec `pw.SizedBox()` par une boucle générant :
1. Bandeau de Zone / Local (`#1E3A8A`, texte blanc).
2. Bandeau d'en-tête d'équipement (`#DBEAFE`, bordure solide `#1E3A8A`, texte `ÉQUIPEMENT : [Nom]`).
3. Mini-tableau 3 colonnes (`N°`, `Non-conformité - Préconisation`, `Réf. Normative`) avec alternance `#FFFFFF` / `#F8FAFC` et bordures fines `#CBD5E1`.

- [ ] **Étape 4 : Exécuter la suite de tests pour valider le succès**

Commande : `flutter test test/features/pdf_equipements_summary_table_test.dart test/features/pdf_equipements_synthesis_test.dart`

- [ ] **Étape 5 : Commiter la modification**

Format commit : `[UPD] Refonte visuelle de _buildObsRecapTableUnifie avec bandeaux d'equipements et de zones`

---

### Tâche 2 : Harmonisation de `_buildObsRecapTableMT` (Rendu MT par Blocs d'Équipements)

**Fichiers :**
- Modifier : `lib/services/pdf/pdf_report_service.dart` (Lignes 8550 à 8616)
- Tester : `test/features/pdf_equipements_synthesis_test.dart`

- [ ] **Étape 1 : Vérifier que `_buildObsRecapTableMT` délègue proprement ou utilise la nouvelle structure**

S'assurer que les observations MT bénéficient de la même présentation en cartes et bandeaux d'équipements.

- [ ] **Étape 2 : Exécuter tous les tests PDF pour confirmer le passage au vert**

Commande : `flutter test test/features/pdf_equipements_synthesis_test.dart test/features/pdf_equipements_summary_table_test.dart`

- [ ] **Étape 3 : Commiter la modification**

Format commit : `[UPD] Harmonisation du rendu de la synthese des observations Moyenne Tension`
