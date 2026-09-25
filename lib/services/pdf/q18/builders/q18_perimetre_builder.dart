// lib/services/pdf/q18/builders/q18_perimetre_builder.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_snapshot.dart';

/// Builder responsable de la construction des Sections 5 et 6 du Rapport Q18 :
/// - Section 5 : Périmètre de la vérification et limites de la mission (5.1 & 5.2)
/// - Section 6 : Documents et éléments consultés
class Q18PerimetreBuilder {
  /// Section 5 : Périmètre de la vérification et limites de la mission
  static List<pw.Widget> buildSection5Perimetre(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
    Map<String, int>? trackedPages,
    int pageOffset = 2,
  }) {
    final couverts = data.perimetreCouverts;
    final exclusions = data.exclusionsPerimetre;

    final subTitle51 = PdfReportStyles.subTitle('5.1 Installations et locaux couverts par la présente vérification', fontBold: fontBold);
    final subTitle52 = PdfReportStyles.subTitle('5.2 Exclusions, parties non vérifiées et locaux inaccessibles', fontBold: fontBold);

    return [
      PdfReportStyles.sectionBox('5. PÉRIMÈTRE DE LA VÉRIFICATION ET LIMITES DE LA MISSION', fontBold: fontBold),
      pw.SizedBox(height: 6),
      trackedPages != null
          ? PageTracker(key: 'q18_s5_1', registry: trackedPages, offset: pageOffset, child: subTitle51)
          : subTitle51,
      pw.SizedBox(height: 4),

      pw.Paragraph(
        text: 'La vérification a porté sur les zones, locaux et équipements suivants :',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
      ),
      pw.SizedBox(height: 4),
      if (couverts.isEmpty)
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfReportStyles.tableRowAlt,
            border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Text(
            'Aucun équipement enregistré dans le périmètre.',
            style: pw.TextStyle(font: fontRegular, fontSize: 8.0, color: PdfColors.grey700),
          ),
        )
      else
        pw.Table(
          border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.6),
            1: pw.FlexColumnWidth(2.6),
            2: pw.FlexColumnWidth(3.4),
            3: pw.FlexColumnWidth(1.4),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
              children: [
                PdfReportStyles.cell('Zone', isHeader: true, centered: false),
                PdfReportStyles.cell('Repère', isHeader: true, centered: false),
                PdfReportStyles.cell('Équipements', isHeader: true, centered: false),
                PdfReportStyles.cell('Couvert par la mission', isHeader: true, centered: true),
              ],
            ),
            ...couverts.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isAlt = idx.isOdd;

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: isAlt ? PdfReportStyles.tableRowAlt : PdfColors.white,
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
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFDCFCE7),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                        border: pw.Border.all(color: const PdfColor.fromInt(0xFF86EFAC), width: 0.5),
                      ),
                      child: pw.Text(
                        'Oui',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 7.5,
                          color: const PdfColor.fromInt(0xFF15803D),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      pw.SizedBox(height: 10),
      trackedPages != null
          ? PageTracker(key: 'q18_s5_2', registry: trackedPages, offset: pageOffset, child: subTitle52)
          : subTitle52,
      pw.SizedBox(height: 4),

      pw.Paragraph(
        text: 'Exclusions éventuelles du périmètre (locaux non visités, installations non accessibles, parties d\'installation exclues contractuellement) :',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
      ),
      pw.SizedBox(height: 4),
      if (exclusions.isEmpty)
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfReportStyles.tableRowAlt,
            border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Center(
            child: pw.Text(
              'Sans Objet',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 9.0,
                color: PdfReportStyles.headerColor,
              ),
            ),
          ),
        )
      else
        pw.Table(
          border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.6),
            1: pw.FlexColumnWidth(2.6),
            2: pw.FlexColumnWidth(2.8),
            3: pw.FlexColumnWidth(2.0),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFC00000)),
              children: [
                PdfReportStyles.cell('Zone', isHeader: true, centered: false),
                PdfReportStyles.cell('Repère', isHeader: true, centered: false),
                PdfReportStyles.cell('Équipements non vérifiés', isHeader: true, centered: false),
                PdfReportStyles.cell('Motif d\'inaccessibilité', isHeader: true, centered: false),
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
                      item.equipements,
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
                      item.motifExclusion.isNotEmpty ? item.motifExclusion : 'Inaccessible lors de la visite',
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
      pw.SizedBox(height: 14),
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
        text: 'La vérification s\'est appuyée, lorsqu\'ils étaient disponibles, sur les documents suivants transmis par l\'exploitant :',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
      ),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FixedColumnWidth(24),
          1: pw.FlexColumnWidth(7.2),
          2: pw.FlexColumnWidth(2.8),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              PdfReportStyles.cell('N°', isHeader: true, centered: true),
              PdfReportStyles.cell('Document', isHeader: true, centered: false),
              PdfReportStyles.cell('Disponibilité sur site', isHeader: true, centered: true),
            ],
          ),
          ...docs.asMap().entries.map((entry) {
            final idx = entry.key;
            final doc = entry.value;
            final isDispo = doc.isDisponible;
            final hasCustom = doc.statutCustom != null && doc.statutCustom!.isNotEmpty;

            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: idx.isOdd ? PdfReportStyles.tableRowAlt : PdfColors.white,
              ),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    '${doc.index}',
                    style: pw.TextStyle(font: fontBold, fontSize: 8.0, color: PdfReportStyles.headerColor),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(
                    doc.titre,
                    style: pw.TextStyle(font: fontRegular, fontSize: 8.0, color: PdfColors.black),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  alignment: pw.Alignment.center,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: hasCustom
                          ? const PdfColor.fromInt(0xFFF1F5F9)
                          : (isDispo
                              ? const PdfColor.fromInt(0xFFDCFCE7)
                              : const PdfColor.fromInt(0xFFFEE2E2)),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      border: pw.Border.all(
                        color: hasCustom
                            ? const PdfColor.fromInt(0xFFCBD5E1)
                            : (isDispo
                                ? const PdfColor.fromInt(0xFF86EFAC)
                                : const PdfColor.fromInt(0xFFFCA5A5)),
                        width: 0.5,
                      ),
                    ),
                    child: pw.Text(
                      hasCustom ? doc.statutCustom! : (isDispo ? 'Oui' : 'Non'),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 7.5,
                        color: hasCustom
                            ? const PdfColor.fromInt(0xFF475569)
                            : (isDispo
                                ? const PdfColor.fromInt(0xFF15803D)
                                : const PdfColor.fromInt(0xFFB91C1C)),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      pw.SizedBox(height: 14),
    ];
  }
}
