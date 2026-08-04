import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/pdf/pdf_chunk_merger.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('PdfMergerService should merge 25 PDF chunks hierarchically in batches of 5 without failure', () async {
    final tempDir = Directory.systemTemp.createTempSync('pdf_merger_test_');
    final chunkFiles = <File>[];

    try {
      for (int i = 0; i < 25; i++) {
        final doc = pw.Document();
        doc.addPage(pw.Page(build: (ctx) => pw.Text('Chunk $i - Page 1')));
        doc.addPage(pw.Page(build: (ctx) => pw.Text('Chunk $i - Page 2')));
        final bytes = await doc.save();

        final file = File('${tempDir.path}/chunk_$i.pdf');
        await file.writeAsBytes(bytes);
        chunkFiles.add(file);
      }

      final outputFile = File('${tempDir.path}/final_merged.pdf');
      final result = await PdfMergerService.mergePdfFiles(
        chunkFiles,
        outputFile,
        deleteChunksAfterMerge: false,
        batchSize: 5,
      );

      expect(await result.exists(), isTrue);
      expect(await result.length(), greaterThan(0));
    } finally {
      try { tempDir.deleteSync(recursive: true); } catch (_) {}
    }
  });
}
