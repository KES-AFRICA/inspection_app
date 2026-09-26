// lib/services/pdf/q18/builders/q18_photos_builder.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/builders/pdf_photos_schemas_builder.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

/// Builder responsable de la Section 16 : Planche photographique des constats Q18
class Q18PhotosBuilder {
  /// Construit les pages de la planche photographique des constats
  /// - Exactement 6 images par page (2 colonnes x 3 lignes)
  /// - Cartes d'images rigoureusement identiques en dimensions (hauteur et largeur constantes)
  static List<pw.Widget> buildSection16Photos(
    List<PdfPhotoEntry> photos, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final widgets = <pw.Widget>[];

    if (photos.isEmpty) {
      widgets.add(PdfReportStyles.sectionBox('16. PLANCHE PHOTOGRAPHIQUE DES CONSTATS', fontBold: fontBold));
      widgets.add(pw.SizedBox(height: 8));
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfReportStyles.conformeColor,
            border: pw.Border.all(color: PdfColors.green700, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Text(
            'NÉANT : Aucune photographie d\'anomalie ou de danger relevée lors de la visite.',
            style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.green900),
          ),
        ),
      );
      return widgets;
    }

    // Découpage strict par lots de 6 photos par page (2 colonnes x 3 lignes)
    final chunks = <List<PdfPhotoEntry>>[];
    for (int i = 0; i < photos.length; i += 6) {
      final end = (i + 6 > photos.length) ? photos.length : i + 6;
      chunks.add(photos.sublist(i, end));
    }

    for (int chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
      if (chunkIndex > 0) {
        // Nouvelle page pour chaque lot de 6 photos
        widgets.add(pw.NewPage());
      } else {
        // En-tête de section sur la première page de photos
        widgets.add(PdfReportStyles.sectionBox('16. PLANCHE PHOTOGRAPHIQUE DES CONSTATS', fontBold: fontBold));
        widgets.add(pw.SizedBox(height: 6));
      }

      final currentChunk = chunks[chunkIndex];
      // Paires de 2 photos par ligne (jusqu'à 3 lignes par page)
      for (int i = 0; i < currentChunk.length; i += 2) {
        final photo1 = currentChunk[i];
        final photo2 = (i + 1 < currentChunk.length) ? currentChunk[i + 1] : null;

        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _buildPhotoCard(photo1, fontBold: fontBold, fontRegular: fontRegular),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: photo2 != null
                      ? _buildPhotoCard(photo2, fontBold: fontBold, fontRegular: fontRegular)
                      : pw.SizedBox(),
                ),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  /// Carte photo calibrée aux dimensions strictement identiques (hauteur totale 180pt)
  static pw.Widget _buildPhotoCard(
    PdfPhotoEntry entry, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    pw.MemoryImage? image;
    try {
      final file = File(entry.filePath);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        if (bytes.isNotEmpty) {
          image = pw.MemoryImage(bytes);
        }
      }
    } catch (_) {}

    final badgeBg = entry.badgeBgColor ?? PdfColor.fromInt(0xFFC00000);
    final badgeText = entry.badgeTextColor ?? PdfColors.white;
    final badgeLabel = entry.badgeLabel ?? 'Danger';

    return pw.Container(
      height: 180,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // 1. En-tête de la carte photo : Hauteur fixe 20pt
          pw.Container(
            height: 20,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            color: PdfReportStyles.headerColor,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: pw.BoxDecoration(
                    color: badgeBg,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                  child: pw.Text(
                    badgeLabel.toUpperCase(),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: badgeText,
                    ),
                  ),
                ),
                if (entry.repere != null && entry.repere!.trim().isNotEmpty)
                  pw.Text(
                    entry.repere!.trim(),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 7.5,
                      color: PdfColors.amber,
                    ),
                  ),
              ],
            ),
          ),
          // 2. Corps de l'image : Hauteur fixe 115pt
          pw.Container(
            height: 115,
            color: PdfColors.grey200,
            alignment: pw.Alignment.center,
            child: image != null
                ? pw.Image(image, fit: pw.BoxFit.cover)
                : pw.Text(
                    'Photographie non disponible',
                    style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey600),
                  ),
          ),
          // 3. Pied de carte : Légende / Description : Hauteur fixe 45pt
          pw.Container(
            height: 45,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: PdfReportStyles.tableRowAlt,
            child: pw.Text(
              entry.description,
              maxLines: 3,
              overflow: pw.TextOverflow.clip,
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 7.2,
                color: PdfColors.black,
                lineSpacing: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
