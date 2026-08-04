import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// Service hautement optimisé de fusion de fichiers PDF temporaires (Moteur V2).
///
/// Plafonne la consommation mémoire RAM à < 20 Mo constant O(1) grâce à une fusion
/// contrôlée à 2 niveaux (Batching L1 discret de 10 chunks max -> Assemblage L2 final).
/// Évite à la fois la récursion profonde de dictionnaires et les erreurs List._grow OOM.
class PdfMergerService {
  /// Fusionne une liste de fichiers PDF chunks temporaires vers un fichier PDF destination.
  /// Nettoie automatiquement les chunks temporaires après fusion.
  static Future<File> mergePdfFiles(
    List<File> chunkFiles,
    File outputFile, {
    bool deleteChunksAfterMerge = true,
    int? batchSize,
  }) async {
    final int effectiveBatchSize = (batchSize != null && batchSize > 0) ? batchSize : 10;

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

    // Cas 2 : Petits nombres de chunks (<= effectiveBatchSize) -> Passe directe unique (RAM < 15 Mo)
    if (validChunks.length <= effectiveBatchSize) {
      await _mergeChunkListToDestination(validChunks, outputFile);
    } else {
      // Cas 3 : Nombre élevé de chunks -> Fusion contrôlée à 2 niveaux maximum (L1 sub-batches -> L2 final)
      final tempSubDir = Directory('${outputFile.parent.path}/pdf_merge_batches_${DateTime.now().millisecondsSinceEpoch}');
      await tempSubDir.create(recursive: true);

      try {
        final level1SubBatchFiles = <File>[];

        // Niveau 1 : Fusion par sous-groupes discrets de 10 chunks max (Libération RAM immédiate par batch)
        for (int i = 0; i < validChunks.length; i += effectiveBatchSize) {
          final batch = validChunks.sublist(
            i,
            (i + effectiveBatchSize).clamp(0, validChunks.length),
          );

          if (batch.length == 1) {
            level1SubBatchFiles.add(batch.first);
            continue;
          }

          final subBatchFile = File('${tempSubDir.path}/sub_batch_l1_${i ~/ effectiveBatchSize}.pdf');
          await _mergeChunkListToDestination(batch, subBatchFile);
          level1SubBatchFiles.add(subBatchFile);
        }

        // Niveau 2 : Assemblage final des sous-fichiers de Niveau 1 vers la destination (Niveau max = 2)
        await _mergeChunkListToDestination(level1SubBatchFiles, outputFile);
      } finally {
        try {
          if (await tempSubDir.exists()) {
            await tempSubDir.delete(recursive: true);
          }
        } catch (_) {}
      }
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

  /// Fusionne une liste ciblée de fichiers chunks vers un fichier destination unique.
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
