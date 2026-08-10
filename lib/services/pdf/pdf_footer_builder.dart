// lib/services/pdf/pdf_footer_builder.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Constructeur vectoriel natif des pieds de page (FirstPageFooter & OtherPageFooter).
/// Reproduit fidèlement et à l'identique 100% les images de référence d'origine,
/// sans aucune ressource image bitmap raster (0 Ko d'images footer).
class PdfFooterBuilder {
  static const double kFullPageWidth = 595.28; // Largeur A4 physique en points
  static final PdfColor kesBlue = PdfColor.fromInt(0xFF186BB8);
  static final PdfColor darkSlateGrey = PdfColor.fromInt(0xFF5E666E);
  static final PdfColor subFooterGrey = PdfColor.fromInt(0xFF4A5158);
  static final PdfColor headerGrey = PdfColor.fromInt(0xFF404040);

  /// Pied de page Première Page (firstpage_footer)
  static pw.Widget buildFirstPageFooter(
    pw.Context ctx, {
    required pw.Font fontRegular,
    required pw.Font fontBold,
  }) {
    const double mainBoxHeight = 44.0;
    const double subFooterHeight = 18.0;
    const double totalHeight = mainBoxHeight + subFooterHeight;

    return pw.Container(
      width: kFullPageWidth,
      height: totalHeight,
      child: pw.Column(
        children: [
          // ── Zone Principale : Biseau Bleu (Infos Légales) + Zone Gris Ardoise (Contacts) ──
          pw.Container(
            height: mainBoxHeight,
            width: kFullPageWidth,
            child: pw.Stack(
              children: [
                // Arrière-plan vectoriel biseauté
                pw.CustomPaint(
                  size: const PdfPoint(kFullPageWidth, mainBoxHeight),
                  painter: (PdfGraphics canvas, PdfPoint size) {
                    // Polygon Bleu Biseauté à gauche
                    canvas.setFillColor(kesBlue);
                    canvas.moveTo(0, 0);
                    canvas.lineTo(215, 0);
                    canvas.lineTo(192, size.y);
                    canvas.lineTo(0, size.y);
                    canvas.fillPath();

                    // Polygon Gris Ardoise à droite
                    canvas.setFillColor(darkSlateGrey);
                    canvas.moveTo(192, size.y);
                    canvas.lineTo(215, 0);
                    canvas.lineTo(size.x, 0);
                    canvas.lineTo(size.x, size.y);
                    canvas.fillPath();
                  },
                ),
                // Contenu textuel superposé
                pw.Positioned.fill(
                  child: pw.Row(
                    children: [
                      // Bloc Bleu Gauche (RCCM & N° Contribuable)
                      pw.Container(
                        width: 195,
                        padding: const pw.EdgeInsets.only(left: 14, top: 4, bottom: 4),
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'RCCM : RC/DLN/2024/B/051',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 7.2,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'N° contribuable : M022416482134Z',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 7.2,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bloc Gris Droit (Contacts 2 colonnes avec icônes)
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.only(left: 28, right: 10, top: 2, bottom: 2),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              // Colonne 1 : Tél & Email
                              pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildContactItem(
                                    symbol: '☎',
                                    text: '(+237) 6 40 20 38 17 / 6 77 51 08 24',
                                    fontRegular: fontRegular,
                                    fontBold: fontBold,
                                  ),
                                  pw.SizedBox(height: 3),
                                  _buildContactItem(
                                    symbol: '✉',
                                    text: 'contact.cmr@kes-africa.com',
                                    fontRegular: fontRegular,
                                    fontBold: fontBold,
                                  ),
                                ],
                              ),
                              // Colonne 2 : BP & Web
                              pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildContactItem(
                                    symbol: '📍',
                                    text: 'BP : 4489 Douala-Cameroun',
                                    fontRegular: fontRegular,
                                    fontBold: fontBold,
                                  ),
                                  pw.SizedBox(height: 3),
                                  _buildContactItem(
                                    symbol: '🌐',
                                    text: 'www.kes-africa.com',
                                    fontRegular: fontRegular,
                                    fontBold: fontBold,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Sous-Ligne Inférieure : Phrase d'activités centrée sur Fond Blanc ──
          pw.Container(
            height: subFooterHeight,
            width: kFullPageWidth,
            color: PdfColors.white,
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Inspection — Essais & Analyses — Formation — Certification & Conformité — Gestion de projets & Ingénierie',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 7.5,
                color: subFooterGrey,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Pied de page Pages Suivantes (otherpage_footer)
  static pw.Widget buildOtherPageFooter(
    pw.Context ctx, {
    int pageOffset = 0,
    int? overrideTotalPages,
    required pw.Font fontRegular,
    required pw.Font fontBold,
  }) {
    const double topRowHeight = 20.0;
    const double bottomBarHeight = 18.0;
    const double totalHeight = topRowHeight + bottomBarHeight;

    final pageNum = ctx.pageNumber + pageOffset;
    final String pageDisplay = (overrideTotalPages != null)
        ? 'Page $pageNum / $overrideTotalPages'
        : 'Page $pageNum';

    return pw.Container(
      width: kFullPageWidth,
      height: totalHeight,
      child: pw.Stack(
        children: [
          // Arrière-plan vectoriel des formes biseautées
          pw.CustomPaint(
            size: const PdfPoint(kFullPageWidth, totalHeight),
            painter: (PdfGraphics canvas, PdfPoint size) {
              // Polygon Bleu Pagination en haut à gauche
              canvas.setFillColor(kesBlue);
              canvas.moveTo(0, bottomBarHeight);
              canvas.lineTo(180, bottomBarHeight);
              canvas.lineTo(158, size.y);
              canvas.lineTo(0, size.y);
              canvas.fillPath();

              // Bande Rectangle Gris Ardoise en bas
              canvas.setFillColor(darkSlateGrey);
              canvas.moveTo(158, 0);
              canvas.lineTo(size.x, 0);
              canvas.lineTo(size.x, bottomBarHeight);
              canvas.lineTo(158, bottomBarHeight);
              canvas.fillPath();
            },
          ),
          // Superposition du contenu textuel
          pw.Positioned.fill(
            child: pw.Column(
              children: [
                // Rangée Supérieure : Numéro de Page (dans le biseau bleu) + Texte Activités
                pw.Container(
                  height: topRowHeight,
                  width: kFullPageWidth,
                  child: pw.Row(
                    children: [
                      // Forme Bleue Contenant la Pagination
                      pw.Container(
                        width: 165,
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          pageDisplay,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8.0,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      // Texte Activités à droite de la forme bleue
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.only(right: 12),
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            'Inspection - Essais & Analyses - Formation - Certification & Conformité - Gestion de projets & Ingénierie',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 7.5,
                              color: headerGrey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Rangée Inférieure (Bande Gris Ardoise)
                pw.SizedBox(height: bottomBarHeight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper pour afficher une ligne d'information de contact avec sa pastille circulaire
  static pw.Widget _buildContactItem({
    required String symbol,
    required String text,
    required pw.Font fontRegular,
    required pw.Font fontBold,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Pastille circulaire blanche avec bordure bleue KES
        pw.Container(
          width: 11,
          height: 11,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: PdfColors.white,
            border: pw.Border.all(color: kesBlue, width: 0.8),
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            symbol,
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: 6.0,
              color: kesBlue,
            ),
          ),
        ),
        pw.SizedBox(width: 4),
        // Texte d'information
        pw.Text(
          text,
          style: pw.TextStyle(
            font: fontRegular,
            fontSize: 7.2,
            color: PdfColors.white,
          ),
        ),
      ],
    );
  }
}
