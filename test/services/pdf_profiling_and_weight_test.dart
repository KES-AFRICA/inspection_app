import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/pdf_footer_builder.dart';
import 'package:inspec_app/services/pdf/pdf_photo_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late pw.MemoryImage watermarkImage;
  late pw.MemoryImage logoKesImage;
  late pw.Font fontRegular;
  late pw.Font fontBold;
  late Uint8List watermarkBytes;
  late Uint8List logoBytes;

  setUpAll(() {
    watermarkBytes = File('assets/images/filigranne_image.png').readAsBytesSync();
    watermarkImage = pw.MemoryImage(watermarkBytes);

    logoBytes = File('assets/images/logo.png').readAsBytesSync();
    logoKesImage = pw.MemoryImage(logoBytes);

    final regData = File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync();
    final boldData = File('assets/fonts/Roboto-Bold.ttf').readAsBytesSync();
    fontRegular = pw.Font.ttf(regData.buffer.asByteData());
    fontBold = pw.Font.ttf(boldData.buffer.asByteData());
  });

  group('PROFILAGE DU POIDS PDF - DIAGNOSTIC INITIAL', () {
    test('1. Mesure de la contribution des Polices Roboto', () async {
      // Document minimal avec Helvetica (police standard non embarquée)
      final docHelvetica = pw.Document(compress: true);
      docHelvetica.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => pw.Text('Test de texte basique', style: pw.TextStyle(font: pw.Font.helvetica())),
        ),
      );
      final bytesHelvetica = await docHelvetica.save();

      // Document minimal avec Roboto Regular et Bold embarqués
      final docRoboto = pw.Document(compress: true);
      docRoboto.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => pw.Column(
            children: [
              pw.Text('Test régulier Roboto', style: pw.TextStyle(font: fontRegular)),
              pw.Text('Test gras Roboto', style: pw.TextStyle(font: fontBold)),
            ],
          ),
        ),
      );
      final bytesRoboto = await docRoboto.save();

      print('📊 TAILLE POLICES :');
      print('   - Document Helvetica (standard) : ${bytesHelvetica.length} octets (~${(bytesHelvetica.length / 1024).toStringAsFixed(1)} Ko)');
      print('   - Document Roboto (Regular + Bold) : ${bytesRoboto.length} octets (~${(bytesRoboto.length / 1024).toStringAsFixed(1)} Ko)');
      print('   - Surcoût d\'intégration Roboto complet : ${(bytesRoboto.length - bytesHelvetica.length)} octets (~${((bytesRoboto.length - bytesHelvetica.length) / 1024).toStringAsFixed(1)} Ko)');
      expect(bytesRoboto.length, greaterThan(bytesHelvetica.length));
    });

    test('2. Mesure de la contribution du Watermark (Filigrane)', () async {
      // Page avec texte seul
      final docNoWatermark = pw.Document(compress: true);
      docNoWatermark.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => pw.Text('Page de contenu sans watermark', style: pw.TextStyle(font: fontRegular)),
        ),
      );
      final bytesNoWm = await docNoWatermark.save();

      // Page avec Watermark (1 page)
      final doc1PageWm = pw.Document(compress: true);
      doc1PageWm.addPage(
        pw.Page(
          pageTheme: PdfReportStyles.buildInnerPageTheme(
            fontRegular: fontRegular,
            fontBold: fontBold,
            watermarkImage: watermarkImage,
          ),
          build: (ctx) => pw.Text('Page de contenu avec watermark', style: pw.TextStyle(font: fontRegular)),
        ),
      );
      final bytes1PageWm = await doc1PageWm.save();

      // Document avec Watermark répété sur 10 pages
      final doc10PagesWm = pw.Document(compress: true);
      for (int i = 0; i < 10; i++) {
        doc10PagesWm.addPage(
          pw.Page(
            pageTheme: PdfReportStyles.buildInnerPageTheme(
              fontRegular: fontRegular,
              fontBold: fontBold,
              watermarkImage: watermarkImage,
            ),
            build: (ctx) => pw.Text('Page ${i + 1} avec watermark', style: pw.TextStyle(font: fontRegular)),
          ),
        );
      }
      final bytes10PagesWm = await doc10PagesWm.save();

      print('📊 TAILLE WATERMARK :');
      print('   - Taille fichier source filigranne_image.png : ${watermarkBytes.length} octets (~${(watermarkBytes.length / 1024).toStringAsFixed(1)} Ko)');
      print('   - Doc 1 page sans watermark : ${bytesNoWm.length} octets');
      print('   - Doc 1 page avec watermark : ${bytes1PageWm.length} octets (Delta : ${bytes1PageWm.length - bytesNoWm.length} octets)');
      print('   - Doc 10 pages avec watermark : ${bytes10PagesWm.length} octets (Delta vs 1 page : ${bytes10PagesWm.length - bytes1PageWm.length} octets pour 9 pages supplémentaires, soit ~${((bytes10PagesWm.length - bytes1PageWm.length) / 9).toStringAsFixed(1)} octets/page)');
      expect((bytes10PagesWm.length - bytes1PageWm.length) / 9, lessThan(2000));
    });

    test('2.bis Déduplication d\'instances MemoryImage dans un document', () async {
      final imgInstance1 = pw.MemoryImage(logoBytes);
      final imgInstance2 = pw.MemoryImage(logoBytes);

      print('📊 ÉGALITÉ MemoryImage : identical=${identical(imgInstance1, imgInstance2)}, ==: ${imgInstance1 == imgInstance2}');

      // Doc A : 5 pages utilisant la MÊME instance imgInstance1
      final docSameInstance = pw.Document(compress: true);
      for (int i = 0; i < 5; i++) {
        docSameInstance.addPage(
          pw.Page(
            build: (ctx) => pw.Image(imgInstance1, width: 200, height: 100),
          ),
        );
      }
      final bytesSameInstance = await docSameInstance.save();

      // Doc B : 5 pages créant une NOUVELLE instance de MemoryImage(logoBytes) à chaque page
      final docNewInstance = pw.Document(compress: true);
      for (int i = 0; i < 5; i++) {
        docNewInstance.addPage(
          pw.Page(
            build: (ctx) => pw.Image(pw.MemoryImage(logoBytes), width: 200, height: 100),
          ),
        );
      }
      final bytesNewInstance = await docNewInstance.save();

      print('📊 COMPARAISON DÉDUPLICATION INSTANCE :');
      print('   - Doc A (même instance réutilisée x5) : ${bytesSameInstance.length} octets');
      print('   - Doc B (nouvelle instance MemoryImage x5) : ${bytesNewInstance.length} octets');
      print('   - Différence : ${bytesNewInstance.length - bytesSameInstance.length} octets (~${((bytesNewInstance.length - bytesSameInstance.length) / 1024).toStringAsFixed(1)} Ko de duplication !)');
    });

    test('3. Mesure du surcoût de la fusion multi-chunks Syncfusion', () async {
      // Chunk 1 (2 pages)
      final docChunk1 = pw.Document(compress: true);
      for (int i = 0; i < 2; i++) {
        docChunk1.addPage(
          pw.Page(
            pageTheme: PdfReportStyles.buildInnerPageTheme(
              fontRegular: fontRegular,
              fontBold: fontBold,
              watermarkImage: watermarkImage,
            ),
            build: (ctx) => pw.Text('Section 1 - Page $i', style: pw.TextStyle(font: fontRegular)),
          ),
        );
      }
      final bytesChunk1 = await docChunk1.save();

      // Chunk 2 (2 pages)
      final docChunk2 = pw.Document(compress: true);
      for (int i = 0; i < 2; i++) {
        docChunk2.addPage(
          pw.Page(
            pageTheme: PdfReportStyles.buildInnerPageTheme(
              fontRegular: fontRegular,
              fontBold: fontBold,
              watermarkImage: watermarkImage,
            ),
            build: (ctx) => pw.Text('Section 2 - Page $i', style: pw.TextStyle(font: fontRegular)),
          ),
        );
      }
      final bytesChunk2 = await docChunk2.save();

      // Fusion sans paramètre compressionLevel
      final sfDocDefault = sf.PdfDocument();
      for (final chunkBytes in [bytesChunk1, bytesChunk2]) {
        final input = sf.PdfDocument(inputBytes: chunkBytes);
        for (int i = 0; i < input.pages.count; i++) {
          final t = input.pages[i].createTemplate();
          sfDocDefault.pages.add().graphics.drawPdfTemplate(t, const Offset(0, 0));
        }
        input.dispose();
      }
      final mergedDefaultBytes = await sfDocDefault.save();
      sfDocDefault.dispose();

      // Fusion avec compressionLevel = sf.PdfCompressionLevel.best
      final sfDocBest = sf.PdfDocument();
      sfDocBest.compressionLevel = sf.PdfCompressionLevel.best;
      for (final chunkBytes in [bytesChunk1, bytesChunk2]) {
        final input = sf.PdfDocument(inputBytes: chunkBytes);
        for (int i = 0; i < input.pages.count; i++) {
          final t = input.pages[i].createTemplate();
          sfDocBest.pages.add().graphics.drawPdfTemplate(t, const Offset(0, 0));
        }
        input.dispose();
      }
      final mergedBestBytes = await sfDocBest.save();
      sfDocBest.dispose();

      print('📊 FUSION CHUNKS & COMPRESSION :');
      print('   - Chunk 1 : ${bytesChunk1.length} octets');
      print('   - Chunk 2 : ${bytesChunk2.length} octets');
      print('   - Somme brute : ${bytesChunk1.length + bytesChunk2.length} octets');
      print('   - Fusion Syncfusion Default : ${mergedDefaultBytes.length} octets');
      print('   - Fusion Syncfusion Best : ${mergedBestBytes.length} octets');
    });

    test('4. Géométrie du Watermark en Portrait et Paysage', () {
      // 1. Portrait A4 (595.28 x 841.89)
      final portraitFormat = PdfPageFormat.a4;
      const double width = 680.0;
      final double height = width * PdfReportStyles.kWatermarkAspectRatio;
      final double circleCx = width * PdfReportStyles.kWatermarkCircleCxRatio;
      final double circleCy = height * PdfReportStyles.kWatermarkCircleCyRatio;

      // Calcul Portrait
      final double portraitImgX = (portraitFormat.width / 2.0) - circleCx;
      final double portraitImgY = (portraitFormat.height / 2.0) - circleCy;
      final double portraitCenterPageX = portraitImgX + circleCx;
      final double portraitCenterPageY = portraitImgY + circleCy;

      expect(portraitCenterPageX, closeTo(portraitFormat.width / 2.0, 0.01));
      expect(portraitCenterPageY, closeTo(portraitFormat.height / 2.0, 0.01));

      // 2. Landscape A4 (841.89 x 595.28)
      final landscapeFormat = PdfPageFormat.a4.landscape;
      final double landscapeImgX = (landscapeFormat.width / 2.0) - circleCx;
      final double landscapeImgY = (landscapeFormat.height / 2.0) - circleCy;
      final double landscapeCenterPageX = landscapeImgX + circleCx;
      final double landscapeCenterPageY = landscapeImgY + circleCy;

      expect(landscapeCenterPageX, closeTo(landscapeFormat.width / 2.0, 0.01));
      expect(landscapeCenterPageY, closeTo(landscapeFormat.height / 2.0, 0.01));

      print('✅ GÉOMÉTRIE DU WATERMARK VÉRIFIÉE :');
      print('   - Portrait : Centre = (${portraitCenterPageX.toStringAsFixed(2)}, ${portraitCenterPageY.toStringAsFixed(2)}) sur page ${portraitFormat.width}x${portraitFormat.height}');
      print('   - Paysage  : Centre = (${landscapeCenterPageX.toStringAsFixed(2)}, ${landscapeCenterPageY.toStringAsFixed(2)}) sur page ${landscapeFormat.width}x${landscapeFormat.height}');
    });

    test('5. Simulation d\'un rapport avec photos réutilisées et impact du cache d\'instance', () async {
      // Simulation de 10 photos d'équipements réutilisées dans les observations et la galerie (20 apparitions)
      final photoBytesList = <Uint8List>[];
      for (int i = 0; i < 10; i++) {
        // Crée des bytes d'image distincts
        photoBytesList.add(Uint8List.fromList([...logoBytes, i]));
      }

      // ── Scénario SANS cache d'instance (nouvelle instance MemoryImage à chaque fois) ──
      final docWithoutCache = pw.Document(compress: true);
      // Pages tableaux (10 photos)
      docWithoutCache.addPage(
        pw.Page(
          pageTheme: PdfReportStyles.buildInnerPageTheme(fontRegular: fontRegular, fontBold: fontBold, watermarkImage: watermarkImage),
          build: (ctx) => pw.Column(
            children: photoBytesList.map((bytes) => pw.Image(pw.MemoryImage(bytes), width: 50, height: 40)).toList(),
          ),
        ),
      );
      // Pages galerie photos (10 mêmes photos réinsérées)
      docWithoutCache.addPage(
        pw.Page(
          pageTheme: PdfReportStyles.buildInnerPageTheme(fontRegular: fontRegular, fontBold: fontBold, watermarkImage: watermarkImage),
          build: (ctx) => pw.Column(
            children: photoBytesList.map((bytes) => pw.Image(pw.MemoryImage(bytes), width: 100, height: 80)).toList(),
          ),
        ),
      );
      final bytesWithoutCache = await docWithoutCache.save();

      // ── Scénario AVEC cache d'instance (même instance MemoryImage partagée) ──
      final imageCache = <int, pw.MemoryImage>{};
      pw.MemoryImage getCachedImage(int index, Uint8List bytes) {
        return imageCache.putIfAbsent(index, () => pw.MemoryImage(bytes));
      }

      final docWithCache = pw.Document(compress: true);
      // Pages tableaux (10 photos avec cache)
      docWithCache.addPage(
        pw.Page(
          pageTheme: PdfReportStyles.buildInnerPageTheme(fontRegular: fontRegular, fontBold: fontBold, watermarkImage: watermarkImage),
          build: (ctx) => pw.Column(
            children: photoBytesList.asMap().entries.map((e) => pw.Image(getCachedImage(e.key, e.value), width: 50, height: 40)).toList(),
          ),
        ),
      );
      // Pages galerie photos (10 mêmes photos avec cache)
      docWithCache.addPage(
        pw.Page(
          pageTheme: PdfReportStyles.buildInnerPageTheme(fontRegular: fontRegular, fontBold: fontBold, watermarkImage: watermarkImage),
          build: (ctx) => pw.Column(
            children: photoBytesList.asMap().entries.map((e) => pw.Image(getCachedImage(e.key, e.value), width: 100, height: 80)).toList(),
          ),
        ),
      );
      final bytesWithCache = await docWithCache.save();

      final gainBytes = bytesWithoutCache.length - bytesWithCache.length;
      final gainPercent = (gainBytes / bytesWithoutCache.length) * 100;

      print('📊 IMPACT DU CACHE D\'INSTANCE SUR UN RAPPORT AVEC PHOTOS RÉUTILISÉES :');
      print('   - Sans cache d\'instance : ${bytesWithoutCache.length} octets (~${(bytesWithoutCache.length / 1024).toStringAsFixed(1)} Ko)');
      print('   - Avec cache d\'instance : ${bytesWithCache.length} octets (~${(bytesWithCache.length / 1024).toStringAsFixed(1)} Ko)');
      print('   - Gain direct : $gainBytes octets (~${(gainBytes / 1024).toStringAsFixed(1)} Ko, soit -${gainPercent.toStringAsFixed(1)}% !)');

      expect(bytesWithCache.length, lessThan(bytesWithoutCache.length));
    });
  });
}
