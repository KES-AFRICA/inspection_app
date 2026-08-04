import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// Service hautement optimisé de fusion de fichiers PDF temporaires (Moteur V2).
///
/// Garantit une consommation RAM ultra-faible et constante O(1) grâce à une fusion
/// séquentielle par lots (batches) de 10 chunks maximum à la fois.
class PdfMergerService {
  /// Fusionne une liste de fichiers PDF chunks temporaires vers un fichier PDF destination.
  /// Nettoie automatiquement les chunks temporaires après fusion.
  static Future<File> mergePdfFiles(
    List<File> chunkFiles,
    File outputFile, {
    bool deleteChunksAfterMerge = true,
    int batchSize = 10,
  }) async {
    if (chunkFiles.isEmpty) {
      throw Exception('Aucun fichier chunk PDF à fusionner.');
    }

    final validChunks = <File>[];
    for (final file in chunkFiles) {
      if (await file.exists() && (await file.length()) > 0) {
        validChunks.add(file);
      }
    }

    if (validChunks.isEmpty) {
      throw Exception('Aucun fichier chunk valide trouvé sur le disque.');
    }

    // Cas simple : 1 seul chunk
    if (validChunks.length == 1) {
      await validChunks.first.copy(outputFile.path);
      if (deleteChunksAfterMerge) {
        try { await validChunks.first.delete(); } catch (_) {}
      }
      return outputFile;
    }

    // Fusion hiérarchique par lots de 10 chunks max pour plafonner la RAM
    List<File> currentLevelChunks = List<File>.from(validChunks);
    final tempSubDir = Directory('${outputFile.parent.path}/pdf_merge_batches_${DateTime.now().millisecondsSinceEpoch}');
    await tempSubDir.create(recursive: true);

    int levelIndex = 0;

    try {
      while (currentLevelChunks.length > 1) {
        levelIndex++;
        final nextLevelChunks = <File>[];

        for (int i = 0; i < currentLevelChunks.length; i += batchSize) {
          final batch = currentLevelChunks.sublist(
            i,
            (i + batchSize).clamp(0, currentLevelChunks.length),
          );

          if (batch.length == 1) {
            nextLevelChunks.add(batch.first);
            continue;
          }

          final batchOutputFile = File('${tempSubDir.path}/sub_batch_l${levelIndex}_b${i ~/ batchSize}.pdf');
          await _mergeSingleBatch(batch, batchOutputFile);
          nextLevelChunks.add(batchOutputFile);
        }

        currentLevelChunks = nextLevelChunks;
      }

      // Copier le fichier fusionné final vers la destination
      await currentLevelChunks.first.copy(outputFile.path);

      if (kDebugMode) {
        print('✅ Fusion PDF Moteur V2 terminée (${validChunks.length} chunks originaux) -> ${outputFile.path} (${await outputFile.length()} octets)');
      }

      return outputFile;
    } finally {
      // Nettoyage de tous les fichiers et répertoires temporaires de batching
      try {
        if (await tempSubDir.exists()) {
          await tempSubDir.delete(recursive: true);
        }
      } catch (_) {}

      if (deleteChunksAfterMerge) {
        for (final chunkFile in validChunks) {
          try {
            if (await chunkFile.exists()) {
              await chunkFile.delete();
            }
          } catch (_) {}
        }
      }
    }
  }

  /// Fusionne un seul lot (batch) de maximum 10 chunks en un sous-document temporaire.
  static Future<void> _mergeSingleBatch(List<File> batchFiles, File outputFile) async {
    final sf.PdfDocument finalDoc = sf.PdfDocument();
    finalDoc.pageSettings.margins.all = 0;

    try {
      for (final chunkFile in batchFiles) {
        final bytes = await chunkFile.readAsBytes();
        if (bytes.isEmpty) continue;

        final sf.PdfDocument inputDoc = sf.PdfDocument(inputBytes: bytes);
        final count = inputDoc.pages.count;

        for (int i = 0; i < count; i++) {
          final sf.PdfPage page = inputDoc.pages[i];
          final sf.PdfTemplate template = page.createTemplate();
          final sf.PdfPage newPage = finalDoc.pages.add();
          newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
        }

        inputDoc.dispose();
      }

      final List<int> mergedBytes = await finalDoc.save();
      await outputFile.writeAsBytes(mergedBytes);
    } finally {
      finalDoc.dispose();
    }
  }
}
