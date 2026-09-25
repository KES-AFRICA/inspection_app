// lib/services/pdf/q18/builders/q18_perimetre_builder.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_snapshot.dart';

/// Builder responsable de la construction des Sections 5 et 6 du Rapport Q18 :
/// - Section 5 : Périmètre de la vérification et exclusions
/// - Section 6 : Documents et éléments consultés
class Q18PerimetreBuilder {
  /// Section 5 : Périmètre de la vérification
  static List<pw.Widget> buildSection5Perimetre(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final couverts = data.perimetreCouverts;
    final exclusions = data.exclusionsPerimetre;

    return [
      PdfReportStyles.sectionBox('5. PÉRIMÈTRE DE LA VÉRIFICATION ET LIMITES DE LA MISSION', fontBold: fontBold),
      pw.SizedBox(height: 6),
      PdfReportStyles.subTitle('5.1 Installations et locaux couverts par la présente vérification', fontBold: fontBold),
      pw.SizedBox(height: 4),
      if (couverts.isEmpty)
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            'Aucune zone ou local spécifiquement répertorié.',
            style: pw.TextStyle(font: fontRegular, fontSize: 8.0, color: PdfColors.grey700),
          ),
        )
      else
        pw.Table(
          border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
          columnWidths: const {
            0: pw.FlexColumnWidth(3.0),
            1: pw.FlexColumnWidth(3.0),
            2: pw.FlexColumnWidth(4.0),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
              children: [
                PdfReportStyles.cell('Zone / Bâtiment', isHeader: true, centered: false),
                PdfReportStyles.cell('Local technique / Emplacement', isHeader: true, centered: false),
                PdfReportStyles.cell('Équipements et tableaux vérifiés', isHeader: true, centered: false),
              ],
            ),
            ...couverts.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: idx.isOdd ? PdfReportStyles.tableRowAlt : PdfColors.white,
                ),
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: pw.Text(
                      item.zone,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8.0,
                        color: PdfReportStyles.headerColor,
                      ),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: pw.Text(
                      item.repere,
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8.0,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: pw.Text(
                      item.equipements,
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8.0,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      pw.SizedBox(height: 10),
      PdfReportStyles.subTitle('5.2 Exclusions, parties non vérifiées et locaux inaccessibles', fontBold: fontBold),
      pw.SizedBox(height: 4),
      if (exclusions.isEmpty)
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: PdfReportStyles.conformeColor,
            border: pw.TableBorder.all(color: PdfColors.green700, width: 0.4),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
          child: pw.Text(
            'Néant : Toutes les installations relevant du périmètre contractuel ont pu être examinées sans restriction d\'accès.',
            style: pw.TextStyle(font: fontRegular, fontSize: 8.0, color: PdfColors.green900),
          ),
        )
      else
        pw.Table(
          border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
          columnWidths: const {
            0: pw.FlexColumnWidth(3.0),
            1: pw.FlexColumnWidth(3.0),
            2: pw.FlexColumnWidth(4.0),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFC00000)),
              children: [
                PdfReportStyles.cell('Zone / Bâtiment', isHeader: true, centered: false),
                PdfReportStyles.cell('Local ou Ouvrage exclu', isHeader: true, centered: false),
                PdfReportStyles.cell('Motif d\'inaccessibilité / Justification', isHeader: true, centered: false),
              ],
            ),
            ...exclusions.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: idx.isOdd ? PdfReportStyles.tableRowAlt : PdfColors.white,
                ),
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: pw.Text(
                      item.zone,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8.0,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: pw.Text(
                      item.repere,
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8.0,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: pw.Text(
                      item.motifExclusion.isNotEmpty ? item.motifExclusion : 'Non accessible lors de la visite',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8.0,
                        color: PdfColors.red900,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      pw.SizedBox(height: 12),
    ];
  }

  /// Section 6 : Documents et éléments consultés
  static List<pw.Widget> buildSection6DocumentsConsultes(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final docs = data.documentsConsultes;

    return [
      PdfReportStyles.sectionBox('6. DOCUMENTS ET ÉLÉMENTS CONSULTÉS', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Paragraph(
        text: 'La vérification au titre du référentiel D18 implique l\'examen préalable ou contradictoire des dossiers techniques d\'exploitation. L\'état de disponibilité des pièces requises sur site est consigné ci-après :',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
      ),
      pw.SizedBox(height: 4),
      pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FixedColumnWidth(24),
          1: pw.FlexColumnWidth(7.5),
          2: pw.FlexColumnWidth(2.5),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              PdfReportStyles.cell('N°', isHeader: true, centered: true),
              PdfReportStyles.cell('Désignation du document / dossier technique', isHeader: true, centered: false),
              PdfReportStyles.cell('Disponibilité sur site', isHeader: true, centered: true),
            ],
          ),
          ...docs.asMap().entries.map((entry) {
            final idx = entry.key;
            final doc = entry.value;
            final isDispo = doc.isDisponible;
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: idx.isOdd ? PdfReportStyles.tableRowAlt : PdfColors.white,
              ),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    '${doc.index}',
                    style: pw.TextStyle(font: fontBold, fontSize: 8.0, color: PdfReportStyles.headerColor),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: pw.Text(
                    doc.titre,
                    style: pw.TextStyle(font: fontRegular, fontSize: 8.0, color: PdfColors.black),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: isDispo ? PdfReportStyles.conformeColor : PdfReportStyles.nonConformeColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                    ),
                    child: pw.Text(
                      isDispo ? 'Disponible' : 'Non disponible',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 7.5,
                        color: isDispo ? PdfColors.green900 : PdfColors.red900,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      pw.SizedBox(height: 12),
    ];
  }
}
