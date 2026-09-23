import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builder responsable de la quatrième de couverture (Page finale institutionnelle du rapport).
///
/// Reproduit fidèlement la maquette institutionnelle KES :
/// - Fond bleu uni (#115F9D)
/// - Grand filigrane blanc de la loupe KES positionné en haut
/// - Bloc central « Contactez-nous » avec coordonnées téléphoniques, adresse, email et site web
/// - Accroche institutionnelle basse « Votre partenaire aujourd’hui et demain »
class PdfFinalPageBuilder {
  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();
  static pw.MemoryImage? watermarkWhiteImage;

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

        // Calcul du positionnement de la loupe blanche
        const loupeWidth = 620.0;
        const loupeHeight = loupeWidth * (887.0 / 1023.0); // ~537.6 pt
        const circleCenterXInImage = loupeWidth * (650.0 / 1023.0); // ~393.9 pt
        const circleCenterYInImage = loupeHeight * (371.5 / 887.0); // ~225.1 pt

        const targetCenterY = 240.0; // Place le cercle dans le haut de page
        final imageLeft = (pageWidth / 2.0) - circleCenterXInImage;
        final imageTop = targetCenterY - circleCenterYInImage;

        return pw.Container(
          width: pageWidth,
          height: pageHeight,
          color: bgColor,
          child: pw.Stack(
            children: [
              // 1. Filigrane blanc de la loupe en haut
              if (watermarkWhiteImage != null)
                pw.Positioned(
                  left: imageLeft,
                  top: imageTop,
                  child: pw.Image(
                    watermarkWhiteImage!,
                    width: loupeWidth,
                    height: loupeHeight,
                    fit: pw.BoxFit.contain,
                  ),
                ),

              // 2. Contenu principal (Contactez-nous & Accroche basse)
              pw.Positioned.fill(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    // ── Bloc Contactez-nous ──
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
                      width: 44,
                      height: 1.5,
                      color: PdfColors.white,
                    ),
                    pw.SizedBox(height: 16),

                    // Coordonnées en 2 colonnes
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 50),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Colonne Gauche : Téléphone & Adresse
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                // Téléphone
                                pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    _buildIconContainer(_phoneSvg),
                                    pw.SizedBox(width: 8),
                                    pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.RichText(
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
                                pw.SizedBox(height: 10),

                                // Adresse B.P.
                                pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                                  children: [
                                    _buildIconContainer(_locationSvg),
                                    pw.SizedBox(width: 8),
                                    pw.Text(
                                      'B.P. 4489 Douala - Cameroun',
                                      style: pw.TextStyle(
                                        font: fontRegular,
                                        fontSize: 8.5,
                                        color: PdfColors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          pw.SizedBox(width: 20),

                          // Colonne Droite : Email & Site web
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                // Email
                                pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                                  children: [
                                    _buildIconContainer(_emailSvg),
                                    pw.SizedBox(width: 8),
                                    pw.Text(
                                      'contact.cmr@kes-africa.com',
                                      style: pw.TextStyle(
                                        font: fontRegular,
                                        fontSize: 8.5,
                                        color: PdfColors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                pw.SizedBox(height: 10),

                                // Site Web
                                pw.Row(
                                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                                  children: [
                                    _buildIconContainer(_globeSvg),
                                    pw.SizedBox(width: 8),
                                    pw.Text(
                                      'www.kes-africa.com',
                                      style: pw.TextStyle(
                                        font: fontRegular,
                                        fontSize: 8.5,
                                        color: PdfColors.white,
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

                    pw.SizedBox(height: 55),

                    // ── Accroche basse ──
                    pw.Text(
                      'Votre partenaire aujourd’hui et demain',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 14.5,
                        color: PdfColors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    pw.SizedBox(height: 45),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
