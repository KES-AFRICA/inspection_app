// lib/services/pdf/q18/builders/q18_photos_builder.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/builders/pdf_photos_schemas_builder.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

/// Builder responsable de la Section 16 : Planche photographique des constats Q18
class Q18PhotosBuilder {
  /// Construit les pages de la planche photographique des constats
  static List<pw.Widget> buildSection16Photos(
    List<PdfPhotoEntry> photos, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final widgets = <pw.Widget>[
      PdfReportStyles.sectionBox('16. PLANCHE PHOTOGRAPHIQUE DES CONSTATS', fontBold: fontBold),
      pw.SizedBox(height: 8),
    ];

    if (photos.isEmpty) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfReportStyles.conformeColor,
            border: pw.TableBorder.all(color: PdfColors.green700, width: 0.5),
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

    // Regroupement par paires de photos pour affichage en grille (2 par ligne)
    final pairs = <List<PdfPhotoEntry>>[];
    for (int i = 0; i < photos.length; i += 2) {
      if (i + 1 < photos.length) {
        pairs.add([photos[i], photos[i + 1]]);
      } else {
        pairs.add([photos[i]]);
      }
    }

    for (final pair in pairs) {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _buildPhotoCard(pair[0], fontBold: fontBold, fontRegular: fontRegular),
              ),
              pw.SizedBox(width: 12),
              if (pair.length > 1)
                pw.Expanded(
                  child: _buildPhotoCard(pair[1], fontBold: fontBold, fontRegular: fontRegular),
                )
              else
                pw.Expanded(child: pw.SizedBox()),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  /// Carte photo optimisée (Règles 39-42) :
  /// - Utilisation accrue de la surface de la page (image 185pt)
  /// - Hauteur dynamique en fonction de la longueur réelle de l'observation (aucune coupure ni troncature)
  /// - Présentation dense, soignée et professionnelle
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
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // En-tête de la carte photo : Badge de danger + Repère
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
            color: PdfReportStyles.headerColor,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
          // Corps de l'image (Hauteur généreuse pour valoriser le visuel)
          pw.Container(
            height: 185,
            color: PdfColors.grey200,
            alignment: pw.Alignment.center,
            child: image != null
                ? pw.Image(image, fit: pw.BoxFit.cover)
                : pw.Text(
                    'Photographie non disponible',
                    style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey600),
                  ),
          ),
          // Pied de carte : Légende / Description (Hauteur dynamique sans troncature)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: PdfReportStyles.tableRowAlt,
            child: pw.Text(
              entry.description,
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 7.5,
                color: PdfColors.black,
                lineSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
