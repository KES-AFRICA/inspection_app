import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// Utility service to merge multiple temporary PDF chunk files into a single final PDF document.
/// Consumes minimal RAM by rendering page templates chunk by chunk.
class PdfMergerService {
  /// Merges multiple temporary PDF files into a single destination PDF file.
  /// Automatically cleans up temporary chunk files after merging.
  static Future<File> mergePdfFiles(
    List<File> chunkFiles,
    File outputFile, {
    bool deleteChunksAfterMerge = true,
  }) async {
    final sf.PdfDocument finalDoc = sf.PdfDocument();
    finalDoc.pageSettings.margins.all = 0;

    try {
      int totalPagesMerged = 0;
      for (final chunkFile in chunkFiles) {
        if (!await chunkFile.exists()) continue;
        final bytes = await chunkFile.readAsBytes();
        if (bytes.isEmpty) continue;

        final sf.PdfDocument inputDoc = sf.PdfDocument(inputBytes: bytes);
        for (int i = 0; i < inputDoc.pages.count; i++) {
          final sf.PdfPage page = inputDoc.pages[i];
          final sf.PdfTemplate template = page.createTemplate();
          
          final sf.PdfPage newPage = finalDoc.pages.add();
          newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
          totalPagesMerged++;
        }
        inputDoc.dispose();
      }

      final List<int> mergedBytes = await finalDoc.save();
      await outputFile.writeAsBytes(mergedBytes);

      if (kDebugMode) {
        print('✅ Fusion PDF terminée (${chunkFiles.length} chunks, $totalPagesMerged pages) : ${outputFile.path} (${mergedBytes.length} octets)');
      }

      // Nettoyage automatique des fichiers temporaires de chunks
      if (deleteChunksAfterMerge) {
        for (final chunkFile in chunkFiles) {
          try {
            if (await chunkFile.exists()) {
              await chunkFile.delete();
            }
          } catch (e) {
            if (kDebugMode) print('⚠️ Impossible de supprimer le chunk temporaire: ${chunkFile.path}');
          }
        }
      }

      return outputFile;
    } finally {
      finalDoc.dispose();
    }
  }
}

