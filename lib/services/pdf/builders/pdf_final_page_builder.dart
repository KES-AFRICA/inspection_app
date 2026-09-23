import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builder responsable de la quatrième de couverture (Page finale institutionnelle du rapport).
///
/// Reproduit fidèlement la maquette institutionnelle KES :
/// - Fond bleu uni (#115F9D)
/// - Grand filigrane blanc de la loupe KES positionné en haut
/// - Bloc « Contactez-nous » avec coordonnées téléphoniques, adresse, email et site web
/// - Accroche institutionnelle basse « Votre partenaire aujourd\'hui et demain »
class PdfFinalPageBuilder {
  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();
  static pw.MemoryImage? watermarkWhiteImage;
  static pw.MemoryImage? _cachedEmbeddedLoupeImage;

  static const String _embeddedLoupeBase64 =
      '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';

  static pw.MemoryImage get _effectiveLoupeImage {
    if (watermarkWhiteImage != null) return watermarkWhiteImage!;
    _cachedEmbeddedLoupeImage ??= pw.MemoryImage(base64Decode(_embeddedLoupeBase64));
    return _cachedEmbeddedLoupeImage!;
  }

  static const String _phoneSvg =
      '<svg viewBox="0 0 24 24" fill="#115F9D"><path d="M6.62 10.79a15.05 15.05 0 006.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z"/></svg>';

  static const String _locationSvg =
      '<svg viewBox="0 0 24 24" fill="#115F9D"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>';

  static const String _emailSvg =
      '<svg viewBox="0 0 24 24" fill="#115F9D"><path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/></svg>';

  static const String _globeSvg =
      '<svg viewBox="0 0 24 24" fill="#115F9D"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"/></svg>';

  static pw.Widget _buildIconContainer(String svgString) {
    return pw.Container(
      width: 14,
      height: 14,
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
      child: pw.Center(
        child: pw.SvgImage(
          svg: svgString,
          width: 9,
          height: 9,
        ),
      ),
    );
  }

  /// Construit la page complète de fin de rapport
  static pw.Page buildPage() {
    final bgColor = PdfColor.fromHex('#115F9D');

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) {
        final pageWidth = PdfPageFormat.a4.width; // 595.28 pt
        final pageHeight = PdfPageFormat.a4.height; // 841.89 pt

        // Dimensions et positionnement exact de la loupe blanche
        const loupeWidth = 567.0;
        const loupeHeight = 491.5;
        const imageLeft = -50.0;
        const imageTop = 52.0;

        return pw.Container(
          width: pageWidth,
          height: pageHeight,
          color: bgColor,
          child: pw.Stack(
            children: [
              // 1. Filigrane blanc de la loupe en haut (garanti non-null via base64)
              pw.Positioned(
                left: imageLeft,
                top: imageTop,
                child: pw.Image(
                  _effectiveLoupeImage,
                  width: loupeWidth,
                  height: loupeHeight,
                  fit: pw.BoxFit.contain,
                ),
              ),

              // 2. Bloc « Contactez-nous »
              pw.Positioned(
                left: 0,
                right: 0,
                top: 538,
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Contactez-nous',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 15,
                        color: PdfColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      width: 38,
                      height: 1.5,
                      color: PdfColors.white,
                    ),
                    pw.SizedBox(height: 24),

                    // Coordonnées en 2 lignes structurées pour un alignement horizontal parfait
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 92),
                      child: pw.Column(
                        children: [
                          // ── Ligne 1 : Téléphone (gauche) & Email (droite) ──
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              // Bloc Téléphone
                              pw.Expanded(
                                flex: 11,
                                child: pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    _buildIconContainer(_phoneSvg),
                                    pw.SizedBox(width: 8),
                                    pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Container(
                                          height: 14,
                                          alignment: pw.Alignment.centerLeft,
                                          child: pw.RichText(
                                            text: pw.TextSpan(
                                              children: [
                                                pw.TextSpan(
                                                  text: '(+237) ',
                                                  style: pw.TextStyle(
                                                    font: fontBold,
                                                    fontSize: 8.5,
                                                    color: PdfColors.white,
                                                  ),
                                                ),
                                                pw.TextSpan(
                                                  text: '699 42 95 89 - 640 20 38 17',
                                                  style: pw.TextStyle(
                                                    font: fontRegular,
                                                    fontSize: 8,
                                                    color: PdfColors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        pw.SizedBox(height: 2),
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.only(left: 31),
                                          child: pw.Text(
                                            '677 51 08 24 - 698 37 70 79',
                                            style: pw.TextStyle(
                                              font: fontRegular,
                                              fontSize: 8,
                                              color: PdfColors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              pw.SizedBox(width: 14),

                              // Bloc Email
                              pw.Expanded(
                                flex: 10,
                                child: pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    _buildIconContainer(_emailSvg),
                                    pw.SizedBox(width: 8),
                                    pw.Container(
                                      height: 14,
                                      alignment: pw.Alignment.centerLeft,
                                      child: pw.Text(
                                        'contact.cmr@kes-africa.com',
                                        style: pw.TextStyle(
                                          font: fontRegular,
                                          fontSize: 8.5,
                                          color: PdfColors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          pw.SizedBox(height: 10),

                          // ── Ligne 2 : Adresse (gauche) & Site Web (droite) ──
                          pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              // Bloc Adresse
                              pw.Expanded(
                                flex: 11,
                                child: pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                                  children: [
                                    _buildIconContainer(_locationSvg),
                                    pw.SizedBox(width: 8),
                                    pw.Container(
                                      height: 14,
                                      alignment: pw.Alignment.centerLeft,
                                      child: pw.Text(
                                        'B.P. 4489 Douala - Cameroun',
                                        style: pw.TextStyle(
                                          font: fontRegular,
                                          fontSize: 8.5,
                                          color: PdfColors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              pw.SizedBox(width: 14),

                              // Bloc Site Web
                              pw.Expanded(
                                flex: 10,
                                child: pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                                  children: [
                                    _buildIconContainer(_globeSvg),
                                    pw.SizedBox(width: 8),
                                    pw.Container(
                                      height: 14,
                                      alignment: pw.Alignment.centerLeft,
                                      child: pw.Text(
                                        'www.kes-africa.com',
                                        style: pw.TextStyle(
                                          font: fontRegular,
                                          fontSize: 8.5,
                                          color: PdfColors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Accroche basse parfaitement calée
              pw.Positioned(
                left: 0,
                right: 0,
                bottom: 68,
                child: pw.Center(
                  child: pw.Text(
                    "Votre partenaire aujourd'hui et demain",
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 13.5,
                      color: PdfColors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
