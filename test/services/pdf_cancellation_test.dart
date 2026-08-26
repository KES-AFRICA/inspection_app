import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/cancellation_token.dart';
import 'package:inspec_app/services/pdf/pdf_chunk_merger.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('PDF Report Cancellation Tests', () {
    test('CancellationToken state and cancellation throwing', () {
      final token = CancellationToken();
      expect(token.isCancelled, false);
      token.throwIfCancelled(); // Should not throw

      token.cancel();
      expect(token.isCancelled, true);
      expect(
        () => token.throwIfCancelled(),
        throwsA(isA<ReportGenerationCancelledException>()),
      );
    });

    test('PdfMergerService aborts when CancellationToken is cancelled', () async {
      final tempDir = Directory.systemTemp.createTempSync('pdf_cancel_test_');
      try {
        final pdf1 = pw.Document();
        pdf1.addPage(pw.Page(build: (ctx) => pw.Text('Page 1')));
        final file1 = File('${tempDir.path}/chunk1.pdf');
        await file1.writeAsBytes(await pdf1.save());

        final pdf2 = pw.Document();
        pdf2.addPage(pw.Page(build: (ctx) => pw.Text('Page 2')));
        final file2 = File('${tempDir.path}/chunk2.pdf');
        await file2.writeAsBytes(await pdf2.save());

        final outputFile = File('${tempDir.path}/merged.pdf');
        final token = CancellationToken();

        // Cancel before merging
        token.cancel();

        expect(
          () => PdfMergerService.mergePdfFiles(
            [file1, file2],
            outputFile,
            cancellationToken: token,
          ),
          throwsA(isA<ReportGenerationCancelledException>()),
        );

        expect(outputFile.existsSync(), false);
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });
}
