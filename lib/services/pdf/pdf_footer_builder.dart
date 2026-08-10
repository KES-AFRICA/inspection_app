// lib/services/pdf/pdf_footer_builder.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Constructeur vectoriel natif des pieds de page (FirstPageFooter & OtherPageFooter).
/// Reproduit avec une fidélité visuelle de 100% les images de référence officielles.
class PdfFooterBuilder {
  static const double kFullPageWidth = 595.28; // Largeur A4 physique en points
  static final PdfColor kesBlue = PdfColor.fromInt(0xFF186BB8);
  static final PdfColor darkSlateGrey = PdfColor.fromInt(0xFF5E666E);
  static final PdfColor subFooterGrey = PdfColor.fromInt(0xFF4A5158);
  static final PdfColor headerGrey = PdfColor.fromInt(0xFF404040);

  /// Pied de page Première Page (firstpage_footer - Référence Officielle Inversée)
  static pw.Widget buildFirstPageFooter(
    pw.Context ctx, {
    required pw.Font fontRegular,
    required pw.Font fontBold,
  }) {
    const double mainBoxHeight = 48.0;
    const double subFooterHeight = 18.0;
    const double totalHeight = mainBoxHeight + subFooterHeight;

    return pw.Container(
      width: kFullPageWidth,
      height: totalHeight,
      child: pw.Column(
        children: [
          // ── Zone Principale : Superposition & Biseau Bleu Inversé (Slant Outwards /) ──
          pw.Container(
            height: mainBoxHeight,
            width: kFullPageWidth,
            child: pw.Stack(
              children: [
                // Arrière-plan vectoriel : Bloc Gris en 1er (Bas), Bloc Bleu en 2nd (Haut avec biseau inversé /)
                pw.CustomPaint(
                  size: const PdfPoint(kFullPageWidth, mainBoxHeight),
                  painter: (PdfGraphics canvas, PdfPoint size) {
                    // 1. Polygon Gris Ardoise (Placé plus bas: de y=0 à y=size.y - 12)
                    canvas.setFillColor(darkSlateGrey);
                    canvas.moveTo(165, size.y - 12);
                    canvas.lineTo(size.x, size.y - 12);
                    canvas.lineTo(size.x, 0);
                    canvas.lineTo(190, 0);
                    canvas.fillPath();

                    // 2. Polygon Bleu KES (Forme inversée / : top-right à x=198, bottom-right s'évasant vers la droite à x=224)
                    canvas.setFillColor(kesBlue);
                    canvas.moveTo(0, size.y);
                    canvas.lineTo(198, size.y);
                    canvas.lineTo(224, 10);
                    canvas.lineTo(0, 10);
                    canvas.fillPath();
                  },
                ),
                // Contenu textuel & icônes parfaitement centrés
                pw.Positioned.fill(
                  child: pw.Row(
                    children: [
                      // Bloc Bleu Gauche (RCCM & N° Contribuable - Centré horizontalement & verticalement)
                      pw.Container(
                        width: 195,
                        padding: const pw.EdgeInsets.only(left: 12, right: 12, top: 8),
                        alignment: pw.Alignment.center,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              'RCCM : RC/DLN/2024/B/051',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 7.5,
                                color: PdfColors.white,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'N° contribuable : M022416482134Z',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 7.5,
                                color: PdfColors.white,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      // Bloc Gris Droit (Contacts déplacés vers la droite & centrés)
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.only(left: 40, right: 14, top: 4, bottom: 8),
                          alignment: pw.Alignment.center,
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              // Colonne 1 : Tél & Email
                              pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildContactItem(
                                    iconType: 1, // Phone
                                    text: '(+237) 6 40 20 38 17 / 6 77 51 08 24',
                                    fontRegular: fontRegular,
                                  ),
                                  pw.SizedBox(height: 3),
                                  _buildContactItem(
                                    iconType: 2, // Email
                                    text: 'contact.cmr@kes-africa.com',
                                    fontRegular: fontRegular,
                                  ),
                                ],
                              ),
                              // Colonne 2 : BP & Web
                              pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildContactItem(
                                    iconType: 3, // Map Pin
                                    text: 'BP : 4489 Douala-Cameroun',
                                    fontRegular: fontRegular,
                                  ),
                                  pw.SizedBox(height: 3),
                                  _buildContactItem(
                                    iconType: 4, // Globe
                                    text: 'www.kes-africa.com',
                                    fontRegular: fontRegular,
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
          // ── Sous-Ligne Inférieure Systématique : Phrase d'activités centrée sous les 2 blocs ──
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

  /// Pied de page Pages Suivantes (otherpage_footer - Pagination parfaitement centrée verticalement)
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
          // Arrière-plan vectoriel : Bloc Gris en 1er (Arrière-plan), Bloc Bleu en 2nd (Premier plan masquant la pointe gauche)
          pw.CustomPaint(
            size: const PdfPoint(kFullPageWidth, totalHeight),
            painter: (PdfGraphics canvas, PdfPoint size) {
              // 1. Bande Gris Ardoise en bas
              canvas.setFillColor(darkSlateGrey);
              canvas.moveTo(100, 0);
              canvas.lineTo(size.x, 0);
              canvas.lineTo(size.x, bottomBarHeight);
              canvas.lineTo(100, bottomBarHeight);
              canvas.fillPath();

              // 2. Polygon Bleu Pagination au premier plan (Recouvre la partie gauche du bloc gris)
              canvas.setFillColor(kesBlue);
              canvas.moveTo(0, 0);
              canvas.lineTo(210, 0);
              canvas.lineTo(185, size.y);
              canvas.lineTo(0, size.y);
              canvas.fillPath();
            },
          ),
          // Superposition du contenu textuel (Pagination parfaitement centrée verticalement dans le bloc bleu)
          pw.Positioned.fill(
            child: pw.Stack(
              children: [
                // Texte de Pagination centré verticalement & horizontalement sur TOUTE la hauteur du bloc bleu
                pw.Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: pw.Container(
                    width: 175,
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
                ),
                // Texte d'activités à droite dans la rangée supérieure
                pw.Positioned(
                  right: 12,
                  top: 3,
                  child: pw.Text(
                    'Inspection - Essais & Analyses - Formation - Certification & Conformité - Gestion de projets & Ingénierie',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 7.5,
                      color: headerGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper pour afficher une ligne de contact avec sa pastille d'icône vectorielle natif
  static pw.Widget _buildContactItem({
    required int iconType,
    required String text,
    required pw.Font fontRegular,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        _buildVectorIcon(iconType),
        pw.SizedBox(width: 5),
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

  /// Générateur d'icônes vectorielles natifs PDF (100% nettes & compatibles)
  static pw.Widget _buildVectorIcon(int iconType) {
    return pw.Container(
      width: 12,
      height: 12,
      child: pw.CustomPaint(
        size: const PdfPoint(12, 12),
        painter: (PdfGraphics canvas, PdfPoint size) {
          final double cx = size.x / 2;
          final double cy = size.y / 2;
          final double r = 5.5;

          // Cercle d'arrière-plan blanc
          canvas.setFillColor(PdfColors.white);
          canvas.drawEllipse(cx, cy, r, r);
          canvas.fillPath();

          // Bordure du cercle en bleu KES
          canvas.setStrokeColor(kesBlue);
          canvas.setLineWidth(0.8);
          canvas.drawEllipse(cx, cy, r, r);
          canvas.strokePath();

          // Contenu vectoriel de l'icône selon le type
          canvas.setFillColor(kesBlue);
          canvas.setLineWidth(0.7);

          if (iconType == 1) {
            // Icone 1 : Téléphone
            canvas.drawEllipse(cx - 1.2, cy + 1.2, 1.1, 1.1);
            canvas.fillPath();
            canvas.drawEllipse(cx + 1.2, cy - 1.2, 1.1, 1.1);
            canvas.fillPath();
            canvas.moveTo(cx - 2.2, cy + 2.2);
            canvas.lineTo(cx - 1.2, cy + 0.4);
            canvas.lineTo(cx + 0.4, cy - 1.2);
            canvas.lineTo(cx + 2.2, cy - 2.2);
            canvas.strokePath();
          } else if (iconType == 2) {
            // Icone 2 : Email / Envelope
            canvas.drawRect(cx - 3.0, cy - 2.0, 6.0, 4.0);
            canvas.strokePath();
            canvas.moveTo(cx - 3.0, cy + 2.0);
            canvas.lineTo(cx, cy - 0.2);
            canvas.lineTo(cx + 3.0, cy + 2.0);
            canvas.strokePath();
          } else if (iconType == 3) {
            // Icone 3 : Map Pin (Location BP)
            canvas.drawEllipse(cx, cy + 0.8, 1.8, 1.8);
            canvas.fillPath();
            canvas.moveTo(cx - 1.6, cy + 0.6);
            canvas.lineTo(cx, cy - 2.8);
            canvas.lineTo(cx + 1.6, cy + 0.6);
            canvas.fillPath();
            canvas.setFillColor(PdfColors.white);
            canvas.drawEllipse(cx, cy + 0.8, 0.7, 0.7);
            canvas.fillPath();
          } else if (iconType == 4) {
            // Icone 4 : Globe (Web)
            canvas.drawEllipse(cx, cy, 3.0, 3.0);
            canvas.strokePath();
            canvas.moveTo(cx - 3.0, cy);
            canvas.lineTo(cx + 3.0, cy);
            canvas.strokePath();
            canvas.moveTo(cx, cy - 3.0);
            canvas.lineTo(cx, cy + 3.0);
            canvas.strokePath();
            canvas.drawEllipse(cx, cy, 1.4, 3.0);
            canvas.strokePath();
          }
        },
      ),
    );
  }
}
