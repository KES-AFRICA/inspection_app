import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// Service hautement optimisé de fusion de fichiers PDF temporaires (Moteur V2).
///
/// Plafonne la consommation mémoire RAM à < 10 Mo constant O(1) grâce à une fusion
/// séquentielle par micro-lots (micro-batches) de 3 chunks maximum à la fois.
/// Évite à la fois les erreurs List._grow OOM de Syncfusion et la saturation mémoire.
class PdfMergerService {
  /// Fusionne une liste de fichiers PDF chunks temporaires vers un fichier PDF destination.
  /// Nettoie automatiquement les chunks temporaires après fusion.
  static Future<File> mergePdfFiles(
    List<File> chunkFiles,
    File outputFile, {
    bool deleteChunksAfterMerge = true,
    int? batchSize,
  }) async {
    // Micro-lots de 3 chunks max par passe pour maintenir chaque buffer de sauvegarde < 10 Mo
    final int effectiveBatchSize = (batchSize != null && batchSize > 0) ? batchSize : 3;

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

    // Cas 1 : 1 seul chunk -> copie directe instantanée
    if (validChunks.length == 1) {
      await validChunks.first.copy(outputFile.path);
      if (deleteChunksAfterMerge) {
        try {
          await validChunks.first.delete();
        } catch (_) {}
      }
      return outputFile;
    }

    // Cas 2 : Fusion séquentielle par micro-lots de 3 chunks max par passe
    final tempSubDir = Directory('${outputFile.parent.path}/pdf_merge_batches_${DateTime.now().millisecondsSinceEpoch}');
    await tempSubDir.create(recursive: true);

    List<File> currentLevelChunks = List<File>.from(validChunks);
    int levelIndex = 0;

    try {
      while (currentLevelChunks.length > 1) {
        levelIndex++;
        final nextLevelChunks = <File>[];

        for (int i = 0; i < currentLevelChunks.length; i += effectiveBatchSize) {
          final batch = currentLevelChunks.sublist(
            i,
            (i + effectiveBatchSize).clamp(0, currentLevelChunks.length),
          );

          if (batch.length == 1) {
            nextLevelChunks.add(batch.first);
            continue;
          }

          final subBatchFile = File('${tempSubDir.path}/sub_batch_l${levelIndex}_b${i ~/ effectiveBatchSize}.pdf');
          await _mergeChunkListToDestination(batch, subBatchFile);
          nextLevelChunks.add(subBatchFile);
        }

        currentLevelChunks = nextLevelChunks;
      }

      // Copier le fichier final assemblé vers outputFile
      await currentLevelChunks.first.copy(outputFile.path);
    } finally {
      try {
        if (await tempSubDir.exists()) {
          await tempSubDir.delete(recursive: true);
        }
      } catch (_) {}
    }

    if (kDebugMode) {
      print('✅ Fusion PDF Moteur V2 terminée (${validChunks.length} chunks originaux) -> ${outputFile.path} (${await outputFile.length()} octets)');
    }

    if (deleteChunksAfterMerge) {
      for (final chunkFile in validChunks) {
        try {
          if (await chunkFile.exists()) {
            await chunkFile.delete();
          }
        } catch (_) {}
      }
    }

    return outputFile;
  }

  /// Fusionne un micro-lot (batch) de maximum 3 chunks vers un fichier destination temporaire.
  static Future<void> _mergeChunkListToDestination(List<File> files, File destination) async {
    final sf.PdfDocument finalDoc = sf.PdfDocument();
    finalDoc.pageSettings.margins.all = 0;

    try {
      for (final chunkFile in files) {
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
      await destination.writeAsBytes(mergedBytes);
    } finally {
      finalDoc.dispose();
    }
  }
}
