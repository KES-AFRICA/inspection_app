# Plan d'implémentation - Architecture de Pagination Globale Centralisée (Moteur PDF V3)

> **Pour les agents :** SOUS-COMPÉTENCE REQUISE : Utilisez superpowers:subagent-driven-development (recommandé) ou planification pour implémenter ce plan tâche par tâche. Les étapes utilisent la syntaxe des cases à cocher (`- [ ]`) pour le suivi.

**Objectif :** Éradiquer toutes les ruptures, réinitialisations et décalages de pagination dans les rapports PDF générés par `PdfReportService`, en instituant une numérotation globale unique, continue et monotone croissante (`Page 1`, `Page 2`, `Page 3`, ..., `Page N`).

**Architecture :** 
1. Mesure exacte pre-flight du Sub-chunk 1.1 (Couverture + Sommaire) dès le démarrage de chaque passe pour déterminer sans estimation l'offset initial exact du Sub-chunk 1.2.
2. Suppression absolue du fallback `${ctx.pagesCount}` dans `_buildFooterAbsolute` pour interdire physiquement l'affichage de compteurs locaux (ex: `4/9`, `1/3`).
3. Propagation séquentielle stricte de `currentOffset` à travers les 16 sous-documents et mise à jour dynamique de l'offset à chaque flush de lot dans les sections chunked (Photos, Audit).

**Stack Technique :** Flutter / Dart, Package `pdf` (David PHAM-VAN), `PdfMergerService`, Hive.

## Contraintes Globales
- **Invariance Moteur V3** : Conserver l'assemblage binaire à micro-lots par `PdfMergerService`.
- **Mémoire** : Aucun surcoût mémoire, maintien de l'isolation par Isolate / GC.
- **Rendu Visuel** : Aucun changement sur la mise en page, les marges ou le filigrane.

---

### Tâche 1 : Éradication du Fallback Local `${ctx.pagesCount}` dans `_buildFooterAbsolute`

**Fichiers :**
- Modifier : `lib/services/pdf/pdf_report_service.dart:265-315`

**Interfaces :**
- Consomme : `ctx: pw.Context`, `pageOffset: int`, `overrideTotalPages: int?`
- Produit : Rendu du footer avec `Page $pageNum / $overrideTotalPages` (Passe 2) ou `Page $pageNum` (Passe 1).

- [ ] **Étape 1 : Modifier `_buildFooterAbsolute` dans `pdf_report_service.dart`**

```dart
  static pw.Widget _buildFooterAbsolute({
    required bool isFirstPage,
    required pw.Context ctx,
    int pageOffset = 0,
    int? overrideTotalPages,
  }) {
    final footerImg = isFirstPage ? _firstPageFooterImage : _otherPageFooterImage;
    final double footerImgHeight = isFirstPage ? 80.0 : 50.0;
    const double descente = kBottomMargin + 40;

    final pageNum = ctx.pageNumber + pageOffset;
    final String pageDisplay = (overrideTotalPages != null)
        ? 'Page $pageNum / $overrideTotalPages'
        : 'Page $pageNum';

    return pw.Stack(
      overflow: pw.Overflow.visible,
      children: [
        pw.Positioned(
          bottom: -descente,
          left:  -kLeftMargin,
          right: -kRightMargin,
          child: pw.SizedBox(
            height: footerImgHeight,
            width: PdfPageFormat.a4.width,
            child: footerImg != null
                ? pw.Image(footerImg, fit: pw.BoxFit.fill)
                : pw.Container(
                    color: PdfColors.blueGrey800,
                    child: pw.Center(
                      child: pw.Text('FOOTER MANQUANT',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                    ),
                  ),
          ),
        ),
        if (!isFirstPage)
          pw.Positioned(
            bottom: -descente + 20,
            left:   -kLeftMargin + kLeftMargin,
            child: pw.Text(
              pageDisplay,
              style: pw.TextStyle(
                font: _fontRegular,
                fontSize: 7.5,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
```

- [ ] **Étape 2 : Exécuter l'analyse statique pour vérifier l'absence d'erreurs**

Commande : `flutter analyze lib/services/pdf/`  
Attendu : Succès sans erreur sur `_buildFooterAbsolute`.

---

### Tâche 2 : Pre-Flight Réel du Sub-chunk 1.1 dans `_generateReportPass`

**Fichiers :**
- Modifier : `lib/services/pdf/pdf_report_service.dart:7870-7925`

**Interfaces :**
- Consomme : `mission`, `renseignements`, `sommaireEntries`, `trackedPages`
- Produit : Document `pdfP1_1` construit dès le début et mesure exacte de son nombre de pages `subChunk1_1_Pages`.

- [ ] **Étape 1 : Mettre à jour le début de `_generateReportPass`**

```dart
    final sommaireEntries = _collectSommaireEntries(
      mission: mission,
      rg: renseignements,
      desc: description,
      audit: audit,
      mesures: mesures,
      foudres: foudres,
    );

    // Construction immédiate de Sub-chunk 1.1 pour mesure exacte du nombre de pages
    final pdfP1_1 = pw.Document(
      title: 'Couverture & Sommaire - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: true,
    );
    pdfP1_1.addPage(
      pw.Page(
        pageTheme: _buildCoverPageTheme(),
        build: (ctx) => _buildCoverPage(mission, renseignements, ctx),
      ),
    );
    _addSommairePages(
      pdfP1_1,
      sommaireEntries,
      trackedPages,
      nomClient: mission.nomClient,
      nomSite: nomSiteHeader,
      numeroRapport: numeroRapportDoc,
    );

    final int subChunk1_1_Pages = pdfP1_1.document.pdfPageList.pages.length;
    int currentOffset = subChunk1_1_Pages;
```

- [ ] **Étape 2 : Insérer `pdfP1_1` dans `allChunkFiles` lorsque `saveFilesToDisk` est `true`**

```dart
    if (saveFilesToDisk) {
      final chunkP1_1 = File('${tempDir.path}/pdf_chunk_p1_1_$missionId.pdf');
      final bytesP1_1 = await pdfP1_1.save();
      await chunkP1_1.writeAsBytes(bytesP1_1);
      allChunkFiles.add(chunkP1_1);
    }
```

- [ ] **Étape 3 : Valider avec l'analyse statique**

Commande : `flutter analyze lib/services/pdf/`  
Attendu : 0 erreur de compilation.

---

### Tâche 3 : Synchronisation Continue des Offsets dans les Sections Chunked

**Fichiers :**
- Modifier : `lib/services/pdf/pdf_report_service.dart:6880-6910, 7450-7625, 7740-7865`

**Interfaces :**
- Consomme : `pageOffset`, `overrideTotalPages`
- Produit : Progression strictement croissante de `currentOffset` à chaque lot généré dans les sections Photos, Synthèse Récap, et Audit.

- [ ] **Étape 1 : Mettre à jour `_addPhotosSectionChunked` pour incrémenter `currentOffset` par lot**

```dart
    Future<void> flushChunkIfNeeded({bool force = false}) async {
      if (pagesInCurrentChunk > 0 && (pagesInCurrentChunk >= 3 || force)) {
        photoChunkIdx++;
        if (saveFilesToDisk) {
          final chunkBytes = await photoDoc.save();
          final photoChunkFile = File('${tempDir.path}/pdf_chunk_photos_${missionId}_$photoChunkIdx.pdf');
          await photoChunkFile.writeAsBytes(chunkBytes);
          chunkFiles.add(photoChunkFile);
        }
        currentOffset += pagesInCurrentChunk;

        photoDoc = pw.Document(
          title: 'Photos Batch ${photoChunkIdx + 1} - ${mission.nomClient}',
          author: 'KES INSPECTIONS AND PROJECTS',
          compress: true,
        );
        pagesInCurrentChunk = 0;
      }
    }
```

- [ ] **Étape 2 : Vérifier les incrémentations dans `_addListeRecapitulativeSectionChunked` et `_addAuditSectionChunked`**

Conserver la mise à jour séquentielle de `currentOffset` avec `doc.document.pdfPageList.pages.length`.

---

### Tâche 4 : Exécution des Tests d'Intégration & Validation Finale

**Fichiers :**
- Tester : `test/features/pdf_schema_section_test.dart`
- Tester : `test/features/pdf_photos_deduplication_test.dart`

- [ ] **Étape 1 : Exécuter l'analyse statique complète**

Commande : `flutter analyze lib/services/pdf/`  
Attendu : Aucun avertissement ni erreur sur la pagination.

- [ ] **Étape 2 : Exécuter la suite de tests PDF**

Commande : `flutter test test/features/pdf_schema_section_test.dart`  
Attendu : All tests passed!

- [ ] **Étape 3 : Exécuter la suite de tests de déduplication photos**

Commande : `flutter test test/features/pdf_photos_deduplication_test.dart`  
Attendu : All tests passed!
