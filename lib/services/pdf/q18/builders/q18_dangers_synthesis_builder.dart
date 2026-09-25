// lib/services/pdf/q18/builders/q18_dangers_synthesis_builder.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_snapshot.dart';

/// Builder responsable de la construction des Sections 10 et 11 du Rapport Q18 :
/// - Section 10 : Synthèse des dangers constatés
/// - Section 11 : Récapitulatif statistique
class Q18DangersSynthesisBuilder {
  /// Section 10 : Synthèse des dangers constatés
  static List<pw.Widget> buildSection10Dangers(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final dangers = data.dangers;

    return [
      PdfReportStyles.sectionBox('10. SYNTHÈSE DES DANGERS CONSTATÉS (RÉFÉRENTIEL APSAD D18)', fontBold: fontBold),
      pw.SizedBox(height: 6),
      if (dangers.isEmpty)
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfReportStyles.conformeColor,
            border: pw.TableBorder.all(color: PdfColors.green700, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 12,
                height: 12,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.green700,
                  shape: pw.BoxShape.circle,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'V',
                  style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  'NÉANT : Aucun danger ni anomalie relevant des risques d\'incendie et d\'explosion n\'a été constaté lors de la présente vérification.',
                  style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.green900),
                ),
              ),
            ],
          ),
        )
      else
        pw.Table(
          border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
          columnWidths: const {
            0: pw.FixedColumnWidth(18), // N°
            1: pw.FlexColumnWidth(1.8), // Zone
            2: pw.FlexColumnWidth(1.6), // Repère
            3: pw.FlexColumnWidth(1.8), // Désignation
            4: pw.FlexColumnWidth(3.8), // Danger constaté
            5: pw.FlexColumnWidth(1.8), // Famille de risque
            6: pw.FlexColumnWidth(1.7), // Niveau
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
              children: [
                PdfReportStyles.cell('N°', isHeader: true, centered: true),
                PdfReportStyles.cell('Zone / Bâtiment', isHeader: true, centered: false),
                PdfReportStyles.cell('Repère', isHeader: true, centered: false),
                PdfReportStyles.cell('Désignation', isHeader: true, centered: false),
                PdfReportStyles.cell('Danger constaté / Observation', isHeader: true, centered: false),
                PdfReportStyles.cell('Famille de risque', isHeader: true, centered: false),
                PdfReportStyles.cell('Niveau D18', isHeader: true, centered: true),
              ],
            ),
            ...dangers.map((item) {
              final isAlt = item.index.isOdd;
              final badgeColors = _getBadgeColors(item.niveau);

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: isAlt ? PdfReportStyles.tableRowAlt : PdfColors.white,
                ),
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      '${item.index}',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 7.5,
                        color: PdfReportStyles.headerColor,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: pw.Text(
                      item.zone,
                      style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.black),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: pw.Text(
                      item.repere,
                      style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.black),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: pw.Text(
                      item.designation,
                      style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.black),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: pw.Text(
                      item.dangerConstate,
                      style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.black),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: pw.Text(
                      item.familleDeRisque,
                      style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfReportStyles.darkGrey),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: badgeColors.bg,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                        border: pw.TableBorder.all(color: badgeColors.border, width: 0.3),
                      ),
                      child: pw.Text(
                        item.niveau.label,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 6.8,
                          color: badgeColors.text,
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

  /// Section 11 : Récapitulatif statistique des dangers
  static List<pw.Widget> buildSection11Statistiques(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final total = data.dangers.length;

    final statsRows = [
      ['Danger avéré (Risque direct et immédiat)', '${data.countDangerAvere}', PdfColor.fromInt(0xFFC00000)],
      ['Dégradation (Risque d\'aggravation différé)', '${data.countDegradation}', PdfColor.fromInt(0xFFED7D31)],
      ['Non-conformité hors périmètre APSAD', '${data.countHorsPerimetre}', PdfColor.fromInt(0xFF70AD47)],
      ['Point sensible / Observation', '${data.countPointSensible}', PdfColor.fromInt(0xFF41719C)],
    ];

    return [
      PdfReportStyles.sectionBox('11. RÉCAPITULATIF STATISTIQUE DES DANGERS', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(7.5),
          1: pw.FlexColumnWidth(2.5),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              PdfReportStyles.cell('Classification D18 des constats', isHeader: true, centered: false),
              PdfReportStyles.cell('Nombre constaté', isHeader: true, centered: true),
            ],
          ),
          ...statsRows.map((entry) {
            final label = entry[0] as String;
            final count = entry[1] as String;
            final color = entry[2] as PdfColor;
            return pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 8,
                        height: 8,
                        margin: const pw.EdgeInsets.only(right: 6),
                        decoration: pw.BoxDecoration(
                          color: color,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          label,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8.0,
                            color: PdfReportStyles.headerColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    count,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8.5,
                      color: count != '0' ? color : PdfColors.black,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            );
          }),
          // Ligne Total
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: pw.Text(
                  'TOTAL GÉNÉRAL DES ANOMALIES IDENTIFIÉES',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 8.5,
                    color: PdfReportStyles.headerColor,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  '$total',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 9.0,
                    color: PdfReportStyles.headerColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 12),
    ];
  }

  static ({PdfColor bg, PdfColor text, PdfColor border}) _getBadgeColors(Q18DangerLevel level) {
    switch (level) {
      case Q18DangerLevel.dangerAvere:
        return (
          bg: PdfColor.fromInt(0xFFFFEBEE),
          text: PdfColor.fromInt(0xFFC00000),
          border: PdfColor.fromInt(0xFFEF9A9A),
        );
      case Q18DangerLevel.degradation:
        return (
          bg: PdfColor.fromInt(0xFFFFF3E0),
          text: PdfColor.fromInt(0xFFE65100),
          border: PdfColor.fromInt(0xFFFFCC80),
        );
      case Q18DangerLevel.horsPerimetreApsad:
        return (
          bg: PdfColor.fromInt(0xFFE8F5E9),
          text: PdfColor.fromInt(0xFF2E7D32),
          border: PdfColor.fromInt(0xFFA5D6A7),
        );
      case Q18DangerLevel.pointSensible:
        return (
          bg: PdfColor.fromInt(0xFFE3F2FD),
          text: PdfColor.fromInt(0xFF1565C0),
          border: PdfColor.fromInt(0xFF90CAF9),
        );
    }
  }
}
