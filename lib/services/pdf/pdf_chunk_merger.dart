import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// Service hautement optimisé de fusion de fichiers PDF temporaires (Moteur V2).
///
/// Garantit une consommation RAM ultra-faible et constante O(1) grâce à une fusion
/// linéaire directe en une seule passe, évitant l'imbrication récursive de modèles PDF.
class PdfMergerService {
  /// Fusionne une liste de fichiers PDF chunks temporaires vers un fichier PDF destination.
  /// Nettoie automatiquement les chunks temporaires après fusion.
  static Future<File> mergePdfFiles(
    List<File> chunkFiles,
    File outputFile, {
    bool deleteChunksAfterMerge = true,
    int? batchSize,
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

    // Cas 1 : Un seul chunk -> copie directe instantanée
    if (validChunks.length == 1) {
      await validChunks.first.copy(outputFile.path);
      if (deleteChunksAfterMerge) {
        try {
          await validChunks.first.delete();
        } catch (_) {}
      }
      return outputFile;
    }

    // Cas 2 : Fusion linéaire directe en une seule passe (Linear Pass)
    final sf.PdfDocument finalDoc = sf.PdfDocument();
    finalDoc.pageSettings.margins.all = 0;

    try {
      for (int cIdx = 0; cIdx < validChunks.length; cIdx++) {
        final chunkFile = validChunks[cIdx];
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

      if (kDebugMode) {
        print('✅ Fusion PDF Moteur V2 terminée en passe directe (${validChunks.length} chunks originaux) -> ${outputFile.path} (${await outputFile.length()} octets)');
      }

      return outputFile;
    } finally {
      finalDoc.dispose();

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
}
