import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';

/// Composants de graphiques vectoriels haute fidélité pour la section « Analyse Statistique ».
/// Rendu 100 % vectoriel, déterministe et conforme au document de référence KES.
class PdfStatisticsCharts {
  static pw.Font get fontRegular => PdfReportStyles.fontRegular;
  static set fontRegular(pw.Font font) => PdfReportStyles.fontRegular = font;

  static pw.Font get fontBold => PdfReportStyles.fontBold;
  static set fontBold(pw.Font font) => PdfReportStyles.fontBold = font;
  // Couleurs harmonisées selon la charte KES (orange/rouge des diagrammes MT et BT)
  static final PdfColor colorNavy = PdfColor.fromHex('#1B365D');
  static final PdfColor colorBlueMT = PdfColor.fromHex('#4A7BB0');
  static final PdfColor colorCritique = PdfColor.fromHex('#A91D22');
  static final PdfColor colorMajeure = PdfColor.fromHex('#D35400');
  static final PdfColor colorPresent = colorMajeure; // Orange (#D35400)
  static final PdfColor colorAbsent = colorCritique; // Rouge (#A91D22)
  static final PdfColor colorSansParafoudre = colorCritique; // Rouge (#A91D22)
  static final PdfColor textGrey = PdfColor.fromHex('#64748B');
  static final PdfColor axisBlack = PdfColors.black;

  // ──────────────────────────────────────────────────────────────────────────
  // 1. DIAGRAMME HORIZONTAL : RÉPARTITION PAR DOMAINE DE TENSION
  // ──────────────────────────────────────────────────────────────────────────
  static pw.Widget buildTensionDomainChart(int btCount, int mtCount) {
    final total = btCount + mtCount;
    final maxVal = math.max(math.max(btCount, mtCount), 1);
    final axisMax = ((maxVal / 50).ceil() * 50).clamp(50, 500);

    const barHeight = 22.0;
    const barSlotHeight = 36.0;
    const labelWidth = 115.0;
    const plotWidth = 270.0;
    const chartInnerWidth = labelWidth + 1 + plotWidth + 70.0;

    final btPct = total > 0 ? (btCount / total) * 100.0 : 0.0;
    final mtPct = total > 0 ? (100.0 - btPct) : 0.0;
    final btPctStr = btPct.toStringAsFixed(1).replaceAll('.', ',');
    final mtPctStr = mtPct.toStringAsFixed(1).replaceAll('.', ',');

    final btWidth = total > 0 ? (btCount / axisMax) * plotWidth : 0.0;
    final mtWidth = total > 0 ? (mtCount / axisMax) * plotWidth : 0.0;

    pw.Widget buildDomainBarRow({
      required int count,
      required String pctStr,
      required double rawWidth,
      required PdfColor barColor,
    }) {
      final clampedWidth = rawWidth.clamp(count > 0 ? 2.0 : 0.0, plotWidth);
      const minInternalWidth = 35.0;
      final fitsInside = count > 0 && clampedWidth >= minInternalWidth;

      if (fitsInside) {
        return pw.Row(
          children: [
            pw.Container(
              width: clampedWidth,
              height: barHeight,
              color: barColor,
              alignment: pw.Alignment.center,
              child: pw.Text(
                '$pctStr %',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 7.8,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.SizedBox(width: 6),
            pw.Text(
              '$count',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 9,
                color: PdfReportStyles.headerColor,
              ),
            ),
          ],
        );
      } else {
        return pw.Row(
          children: [
            if (clampedWidth > 0)
              pw.Container(
                width: clampedWidth,
                height: barHeight,
                color: barColor,
              ),
            pw.SizedBox(width: 6),
            pw.Text(
              '$count ($pctStr %)',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 8.5,
                color: PdfReportStyles.headerColor,
              ),
            ),
          ],
        );
      }
    }

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'Répartition des non-conformités par domaine de tension',
            style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfReportStyles.headerColor),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: chartInnerWidth,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Colonne des libellés à gauche
                    pw.SizedBox(
                      width: labelWidth,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            height: barSlotHeight,
                            alignment: pw.Alignment.centerRight,
                            padding: const pw.EdgeInsets.only(right: 8),
                            child: pw.Text(
                              'Basse tension\n(BT)',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfReportStyles.darkGrey),
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Container(
                            height: barSlotHeight,
                            alignment: pw.Alignment.centerRight,
                            padding: const pw.EdgeInsets.only(right: 8),
                            child: pw.Text(
                              'Moyenne tension\n(MT/HTA)',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfReportStyles.darkGrey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Axe Y continu
                    pw.Container(
                      width: 1,
                      height: barSlotHeight * 2 + 6,
                      color: axisBlack,
                    ),
                    // Barres de données
                    pw.SizedBox(
                      width: plotWidth + 70,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            height: barSlotHeight,
                            alignment: pw.Alignment.centerLeft,
                            child: buildDomainBarRow(
                              count: btCount,
                              pctStr: btPctStr,
                              rawWidth: btWidth,
                              barColor: colorNavy,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Container(
                            height: barSlotHeight,
                            alignment: pw.Alignment.centerLeft,
                            child: buildDomainBarRow(
                              count: mtCount,
                              pctStr: mtPctStr,
                              rawWidth: mtWidth,
                              barColor: colorBlueMT,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Axe X parfaitement calé sur l'axe Y
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: labelWidth),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: plotWidth + 1,
                        height: 1,
                        color: axisBlack,
                      ),
                      pw.SizedBox(height: 2),
                      pw.SizedBox(
                        width: plotWidth,
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            (axisMax ~/ 50) + 1,
                            (i) => pw.Text(
                              '${i * 50}',
                              style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey),
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Container(
                        width: plotWidth,
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'Nombre de non-conformités (Total : $total)',
                          style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfReportStyles.darkGrey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2.1 DIAGRAMME EN BARRES EMPIILÉES : NON-CONFORMITÉS MOYENNE TENSION (MT)
  // ──────────────────────────────────────────────────────────────────────────
  static pw.Widget buildMtCategoryStackedBarChart(List<CategoryCrossAuditRow> mtRows) {
    if (mtRows.isEmpty) return pw.SizedBox();

    final maxVal = mtRows.fold<int>(0, (m, r) => math.max(m, r.ncCount));
    final axisMax = math.max(10, ((maxVal * 1.1) / 10).ceil() * 10);
    const plotHeight = 100.0;

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Non-conformités par catégorie - Moyenne Tension (MT)',
                style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfReportStyles.headerColor),
              ),
              pw.Row(
                children: [
                  pw.Container(width: 8, height: 8, color: colorCritique),
                  pw.SizedBox(width: 3),
                  pw.Text('Critique', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                  pw.SizedBox(width: 8),
                  pw.Container(width: 8, height: 8, color: colorMajeure),
                  pw.SizedBox(width: 3),
                  pw.Text('Majeure', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Axe Y
              pw.Container(
                height: plotHeight,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('$axisMax', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('${(axisMax * 0.5).round()}', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('0', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                  ],
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Container(width: 1, height: plotHeight, color: axisBlack),
              pw.SizedBox(width: 6),
              // Barres des catégories MT
              pw.Expanded(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: mtRows.map((cat) {
                    final critH = axisMax > 0 ? (cat.critiquesCount / axisMax) * plotHeight : 0.0;
                    final majCount = math.max(0, cat.ncCount - cat.critiquesCount);
                    final majH = axisMax > 0 ? (majCount / axisMax) * plotHeight : 0.0;

                    return pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          '${cat.ncCount}',
                          style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: 38,
                          child: pw.Column(
                            children: [
                              if (majH > 0)
                                pw.Container(
                                  width: 38,
                                  height: majH,
                                  color: colorMajeure,
                                ),
                              if (critH > 0)
                                pw.Container(
                                  width: 38,
                                  height: critH,
                                  color: colorCritique,
                                ),
                              if (majH == 0 && critH == 0)
                                pw.Container(width: 38, height: 1, color: PdfColors.grey),
                            ],
                          ),
                        ),
                        pw.Container(width: 50, height: 1, color: axisBlack),
                        pw.SizedBox(height: 3),
                        pw.SizedBox(
                          width: 65,
                          child: pw.Text(
                            _formatShortCategoryName(cat.categoryName),
                            textAlign: pw.TextAlign.center,
                            maxLines: 2,
                            style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: PdfReportStyles.darkGrey),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Nombre de non-conformités par catégorie Moyenne Tension',
            style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2.2 DIAGRAMME EN BARRES EMPIILÉES : NON-CONFORMITÉS BASSE TENSION (BT)
  // ──────────────────────────────────────────────────────────────────────────
  static pw.Widget buildBtCategoryStackedBarChart(List<CategoryCrossAuditRow> btRows) {
    if (btRows.isEmpty) return pw.SizedBox();

    final maxVal = btRows.fold<int>(0, (m, r) => math.max(m, r.ncCount));
    final axisMax = math.max(25, ((maxVal * 1.1) / 25).ceil() * 25);
    const plotHeight = 100.0;

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Non-conformités par catégorie - Basse Tension (BT)',
                style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfReportStyles.headerColor),
              ),
              pw.Row(
                children: [
                  pw.Container(width: 8, height: 8, color: colorCritique),
                  pw.SizedBox(width: 3),
                  pw.Text('Critique', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                  pw.SizedBox(width: 8),
                  pw.Container(width: 8, height: 8, color: colorMajeure),
                  pw.SizedBox(width: 3),
                  pw.Text('Majeure', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Axe Y
              pw.Container(
                height: plotHeight,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('$axisMax', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('${(axisMax * 0.75).round()}', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('${(axisMax * 0.5).round()}', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('${(axisMax * 0.25).round()}', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('0', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                  ],
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Container(width: 1, height: plotHeight, color: axisBlack),
              pw.SizedBox(width: 6),
              // Barres des 7 catégories BT
              pw.Expanded(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: btRows.map((cat) {
                    final critH = axisMax > 0 ? (cat.critiquesCount / axisMax) * plotHeight : 0.0;
                    final majCount = math.max(0, cat.ncCount - cat.critiquesCount);
                    final majH = axisMax > 0 ? (majCount / axisMax) * plotHeight : 0.0;

                    return pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          '${cat.ncCount}',
                          style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: 22,
                          child: pw.Column(
                            children: [
                              if (majH > 0)
                                pw.Container(
                                  width: 22,
                                  height: majH,
                                  color: colorMajeure,
                                ),
                              if (critH > 0)
                                pw.Container(
                                  width: 22,
                                  height: critH,
                                  color: colorCritique,
                                ),
                              if (majH == 0 && critH == 0)
                                pw.Container(width: 22, height: 1, color: PdfColors.grey),
                            ],
                          ),
                        ),
                        pw.Container(width: 32, height: 1, color: axisBlack),
                        pw.SizedBox(height: 3),
                        pw.SizedBox(
                          width: 44,
                          child: pw.Text(
                            _formatShortCategoryName(cat.categoryName),
                            textAlign: pw.TextAlign.center,
                            maxLines: 2,
                            style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: PdfReportStyles.darkGrey),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Nombre de non-conformités par catégorie Basse Tension',
            style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey),
          ),
        ],
      ),
    );
  }

  // Conservé pour rétrocompatibilité
  static pw.Widget buildEquipmentCategoryStackedBarChart(
    List<CategoryCrossAuditRow> mtRows,
    List<CategoryCrossAuditRow> btRows,
  ) {
    return buildBtCategoryStackedBarChart(btRows);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. DIAGRAMME EN BARRES EMPIILÉES : IDENTIFICATION SOURCE ALIMENTATION
  // ──────────────────────────────────────────────────────────────────────────
  static pw.Widget buildBtSourceStackedBarChart(TechnicalEnrichmentResult technical) {
    const categories = [
      (DomainObjectType.armoire, 'Armoires'),
      (DomainObjectType.coffret, 'Coffrets'),
      (DomainObjectType.inverseur, 'Inverseur'),
    ];

    final validCats = <(String, int, int, int)>[];
    for (final item in categories) {
      final s = technical.sourceStats[item.$1];
      final tot = s?.totalEquipments ?? 0;
      final ident = s?.identifiees ?? 0;
      final nonIdent = math.max(0, tot - ident);
      validCats.add((item.$2, tot, ident, nonIdent));
    }

    final maxVal = validCats.fold<int>(0, (m, c) => math.max(m, c.$2));
    final axisMax = ((maxVal / 10).ceil() * 10).clamp(10, 100);
    const plotHeight = 100.0;

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Identification de la source d\'alimentation',
                style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfReportStyles.headerColor),
              ),
              pw.Row(
                children: [
                  pw.Container(width: 8, height: 8, color: colorPresent),
                  pw.SizedBox(width: 3),
                  pw.Text('Source identifiée', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                  pw.SizedBox(width: 8),
                  pw.Container(width: 8, height: 8, color: colorAbsent),
                  pw.SizedBox(width: 3),
                  pw.Text('Source non identifiée', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Axe Y
              pw.Container(
                height: plotHeight,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('$axisMax', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('${(axisMax * 0.5).round()}', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('0', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                  ],
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Container(width: 1, height: plotHeight, color: axisBlack),
              pw.SizedBox(width: 12),
              // Barres
              pw.Expanded(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: validCats.map((cat) {
                    final nonIdentH = axisMax > 0 ? (cat.$4 / axisMax) * plotHeight : 0.0;
                    final identH = axisMax > 0 ? (cat.$3 / axisMax) * plotHeight : 0.0;

                    return pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Container(
                          width: 46,
                          child: pw.Column(
                            children: [
                              if (nonIdentH > 0)
                                pw.Container(
                                  width: 46,
                                  height: nonIdentH,
                                  color: colorAbsent,
                                  alignment: pw.Alignment.center,
                                  child: cat.$4 > 0 && nonIdentH > 10
                                      ? pw.Text('${cat.$4}', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.white))
                                      : null,
                                ),
                              if (identH > 0)
                                pw.Container(
                                  width: 46,
                                  height: identH,
                                  color: colorPresent,
                                  alignment: pw.Alignment.center,
                                  child: cat.$3 > 0 && identH > 10
                                      ? pw.Text('${cat.$3}', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.white))
                                      : null,
                                ),
                            ],
                          ),
                        ),
                        pw.Container(width: 60, height: 1, color: axisBlack),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${cat.$1}\n(n=${cat.$2})',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfReportStyles.darkGrey),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. DIAGRAMME CIRCULAIRE / DONUT : ORGANE DE COUPURE EN TÊTE
  // ──────────────────────────────────────────────────────────────────────────
  static pw.Widget buildDisjoncteurTeteDonutChart(TechnicalEnrichmentResult technical) {
    int total = 0;
    int present = 0;
    for (final s in technical.coupureTeteStats.values) {
      total += s.totalEquipments;
      present += s.presents;
    }
    final absent = math.max(0, total - present);
    final presentPct = total > 0 ? (present / total * 100.0) : 0.0;
    final absentPct = total > 0 ? (absent / total * 100.0) : 0.0;

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Disjoncteur de tête (Armoires + Coffrets, n=$total)',
            style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfReportStyles.headerColor),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Label Présent
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Présent', style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: colorPresent)),
                  pw.Text('${presentPct.toStringAsFixed(0)} % ($present)', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfReportStyles.darkGrey)),
                ],
              ),
              pw.SizedBox(width: 14),
              // Cercle graphique vectoriel compact
              pw.CustomPaint(
                size: const PdfPoint(70, 70),
                painter: (PdfGraphics canvas, PdfPoint size) {
                  final cx = size.x / 2;
                  final cy = size.y / 2;
                  final r = 32.0;

                  // Si total == 0, cercle neutre
                  if (total == 0) {
                    canvas.setFillColor(PdfColors.grey300);
                    canvas.drawEllipse(cx, cy, r, r);
                    canvas.fillPath();
                    return;
                  }

                  // Angle de découpe
                  final anglePresent = (present / total) * 2 * math.pi;

                  // Portion Présent (Vert)
                  canvas.setFillColor(colorPresent);
                  canvas.moveTo(cx, cy);
                  for (double a = 0; a <= anglePresent; a += 0.05) {
                    canvas.lineTo(cx + r * math.cos(a), cy + r * math.sin(a));
                  }
                  canvas.lineTo(cx + r * math.cos(anglePresent), cy + r * math.sin(anglePresent));
                  canvas.lineTo(cx, cy);
                  canvas.fillPath();

                  // Portion Absent (Rouge)
                  canvas.setFillColor(colorAbsent);
                  canvas.moveTo(cx, cy);
                  for (double a = anglePresent; a <= 2 * math.pi; a += 0.05) {
                    canvas.lineTo(cx + r * math.cos(a), cy + r * math.sin(a));
                  }
                  canvas.lineTo(cx + r, cy);
                  canvas.lineTo(cx, cy);
                  canvas.fillPath();

                  // Trou central Donut (Blanc)
                  canvas.setFillColor(PdfColors.white);
                  canvas.drawEllipse(cx, cy, 12, 12);
                  canvas.fillPath();
                },
              ),
              pw.SizedBox(width: 14),
              // Label Absent
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Absent', style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: colorAbsent)),
                  pw.Text('${absentPct.toStringAsFixed(0)} % ($absent)', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfReportStyles.darkGrey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. DIAGRAMME EN BARRES EMPIILÉES : PRÉSENCE PARAFOUDRE
  // ──────────────────────────────────────────────────────────────────────────
  static pw.Widget buildBtParafoudreStackedBarChart(TechnicalEnrichmentResult technical) {
    const categories = [
      (DomainObjectType.armoire, 'Armoires'),
      (DomainObjectType.coffret, 'Coffrets'),
      (DomainObjectType.inverseur, 'Inverseur'),
    ];

    final validCats = <(String, int, int, int)>[];
    for (final item in categories) {
      final s = technical.parafoudreStats[item.$1];
      final tot = s?.totalEquipments ?? 0;
      final avec = s?.avecParafoudre ?? 0;
      final sans = math.max(0, tot - avec);
      validCats.add((item.$2, tot, avec, sans));
    }

    final maxVal = validCats.fold<int>(0, (m, c) => math.max(m, c.$2));
    final axisMax = ((maxVal / 10).ceil() * 10).clamp(10, 100);
    const plotHeight = 100.0;

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Présence de parafoudre',
                style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfReportStyles.headerColor),
              ),
              pw.Row(
                children: [
                  pw.Container(width: 8, height: 8, color: colorPresent),
                  pw.SizedBox(width: 3),
                  pw.Text('Avec parafoudre', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                  pw.SizedBox(width: 8),
                  pw.Container(width: 8, height: 8, color: colorSansParafoudre),
                  pw.SizedBox(width: 3),
                  pw.Text('Sans parafoudre', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Axe Y
              pw.Container(
                height: plotHeight,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('$axisMax', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('${(axisMax * 0.5).round()}', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('0', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                  ],
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Container(width: 1, height: plotHeight, color: axisBlack),
              pw.SizedBox(width: 12),
              // Barres
              pw.Expanded(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: validCats.map((cat) {
                    final sansH = axisMax > 0 ? (cat.$4 / axisMax) * plotHeight : 0.0;
                    final avecH = axisMax > 0 ? (cat.$3 / axisMax) * plotHeight : 0.0;

                    return pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Container(
                          width: 46,
                          child: pw.Column(
                            children: [
                              if (sansH > 0)
                                pw.Container(
                                  width: 46,
                                  height: sansH,
                                  color: colorSansParafoudre,
                                  alignment: pw.Alignment.center,
                                  child: cat.$4 > 0 && sansH > 10
                                      ? pw.Text('${cat.$4}', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.white))
                                      : null,
                                ),
                              if (avecH > 0)
                                pw.Container(
                                  width: 46,
                                  height: avecH,
                                  color: colorPresent,
                                  alignment: pw.Alignment.center,
                                  child: cat.$3 > 0 && avecH > 10
                                      ? pw.Text('${cat.$3}', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.white))
                                      : null,
                                ),
                            ],
                          ),
                        ),
                        pw.Container(width: 60, height: 1, color: axisBlack),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${cat.$1}\n(n=${cat.$2})',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfReportStyles.darkGrey),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 6. DIAGRAMME DE PARETO À DOUBLE AXE (OCCURRENCES & % CUMULÉ + SEUIL 80 %)
  // ──────────────────────────────────────────────────────────────────────────
  static pw.Widget buildParetoDualAxisChart(
    List<TopDefectItem> items,
    int totalOccurrences, {
    ParetoAnalysisResult? paretoResult,
  }) {
    final List<TopDefectItem> displayItems;
    if (paretoResult != null && paretoResult.allDisplayItems.isNotEmpty) {
      displayItems = paretoResult.allDisplayItems;
    } else if (items.isNotEmpty) {
      displayItems = items.take(10).toList();
    } else {
      displayItems = [
        TopDefectItem(title: 'Identification / repérage circuits', count: 0, percentage: 0),
        TopDefectItem(title: 'Câblages et canalisations', count: 0, percentage: 0),
        TopDefectItem(title: 'Terre et différentiels', count: 0, percentage: 0),
        TopDefectItem(title: 'EPI et habilitations', count: 0, percentage: 0),
        TopDefectItem(title: 'Plans et consignation', count: 0, percentage: 0),
        TopDefectItem(title: 'Revêtement diélectrique au sol', count: 0, percentage: 0),
        TopDefectItem(title: 'Protections surintensités', count: 0, percentage: 0),
        TopDefectItem(title: 'Organes de coupure', count: 0, percentage: 0),
        TopDefectItem(title: 'Poste et cellules MT', count: 0, percentage: 0),
        TopDefectItem(title: 'Éclairage de sécurité', count: 0, percentage: 0),
      ];
    }

    final maxVal = displayItems.map((e) => e.count).fold<int>(0, math.max);
    final axisMax = maxVal > 0 ? ((maxVal / 10).ceil() * 10).clamp(10, 500) : 20;
    const plotHeight = 125.0;
    final count = displayItems.length;
    final barWidth = count > 10 ? 20.0 : 24.0;

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Analyse de Pareto - Typologies de défauts (sur $totalOccurrences occurrences - Bouclage 100 %)',
            style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfReportStyles.headerColor),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Axe Y gauche (Occurrences)
              pw.Container(
                height: plotHeight,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('$axisMax', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('${(axisMax * 0.8).round()}', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('${(axisMax * 0.6).round()}', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('${(axisMax * 0.4).round()}', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('${(axisMax * 0.2).round()}', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('0', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                  ],
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Container(width: 1, height: plotHeight, color: axisBlack),
              // Zone de tracé : Barres + Courbe de Pareto avec CustomPaint
              pw.Expanded(
                child: pw.Stack(
                  alignment: pw.Alignment.bottomLeft,
                  children: [
                    // Barres de fond
                    pw.Container(
                      height: plotHeight + 15,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: displayItems.map((item) {
                          final h = axisMax > 0 ? (item.count / axisMax) * plotHeight : 0.0;
                          final barColor = item.isOtherAggregate
                              ? PdfColor.fromHex('#94A3B8')
                              : colorNavy;
                          return pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text(
                                '${item.count}',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 6.5,
                                  color: item.isOtherAggregate ? PdfColor.fromHex('#64748B') : PdfReportStyles.darkGrey,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Container(
                                width: barWidth,
                                height: h.clamp(1.0, plotHeight),
                                decoration: pw.BoxDecoration(
                                  color: barColor,
                                  borderRadius: const pw.BorderRadius.only(
                                    topLeft: pw.Radius.circular(2),
                                    topRight: pw.Radius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    // Canvas vectoriel pour la ligne à 80% et la courbe cumulative
                    pw.CustomPaint(
                      size: const PdfPoint(400, plotHeight),
                      painter: (PdfGraphics canvas, PdfPoint size) {
                        // 1. Ligne en pointillés à 80% traversant tout le tracé
                        final y80 = 0.8 * plotHeight;
                        canvas.setStrokeColor(colorCritique);
                        canvas.setLineWidth(0.8);
                        canvas.setLineDashPattern([3, 2]);
                        canvas.drawLine(0, y80, size.x, y80);
                        canvas.strokePath();
                        canvas.setLineDashPattern(); // Reset pointillés

                        // 2. Points de la courbe cumulative
                        final colWidth = size.x / count;
                        final points = <PdfPoint>[];
                        int? k80Index;

                        for (int i = 0; i < count; i++) {
                          final px = (i + 0.5) * colWidth;
                          final pct = (displayItems[i].cumulativePercentage / 100.0).clamp(0.0, 1.0);
                          final py = pct * plotHeight;
                          points.add(PdfPoint(px, py));
                          if (k80Index == null && displayItems[i].cumulativePercentage >= 80.0) {
                            k80Index = i;
                          }
                        }

                        // 3. Tracé continu de la courbe
                        canvas.setStrokeColor(colorCritique);
                        canvas.setLineWidth(1.8);
                        for (int i = 0; i < points.length; i++) {
                          if (i == 0) {
                            canvas.moveTo(points[i].x, points[i].y);
                          } else {
                            canvas.lineTo(points[i].x, points[i].y);
                          }
                        }
                        canvas.strokePath();

                        // 4. Marqueurs circulaires sur les points
                        for (int i = 0; i < points.length; i++) {
                          final p = points[i];
                          final isK80 = i == k80Index;
                          if (isK80) {
                            canvas.setFillColor(PdfColors.white);
                            canvas.setStrokeColor(colorCritique);
                            canvas.setLineWidth(1.5);
                            canvas.drawEllipse(p.x, p.y, 4.0, 4.0);
                            canvas.fillPath();
                            canvas.drawEllipse(p.x, p.y, 4.0, 4.0);
                            canvas.strokePath();

                            canvas.setFillColor(colorCritique);
                            canvas.drawEllipse(p.x, p.y, 2.2, 2.2);
                            canvas.fillPath();
                          } else {
                            canvas.setFillColor(colorCritique);
                            canvas.drawEllipse(p.x, p.y, 2.5, 2.5);
                            canvas.fillPath();
                          }
                        }
                      },
                    ),
                    // Badge 80 %
                    pw.Positioned(
                      top: plotHeight * 0.2 - 8,
                      right: 4,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                          border: pw.Border.all(color: colorCritique, width: 0.5),
                        ),
                        child: pw.Text(
                          'Seuil 80 %',
                          style: pw.TextStyle(font: fontBold, fontSize: 6.5, color: colorCritique),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Axe Y droit (% cumulé)
              pw.Container(width: 1, height: plotHeight, color: axisBlack),
              pw.SizedBox(width: 4),
              pw.Container(
                height: plotHeight,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('100 %', style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: textGrey)),
                    pw.Text('80 %', style: pw.TextStyle(font: fontBold, fontSize: 6.5, color: colorCritique)),
                    pw.Text('60 %', style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: textGrey)),
                    pw.Text('40 %', style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: textGrey)),
                    pw.Text('20 %', style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: textGrey)),
                    pw.Text('0 %', style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: textGrey)),
                  ],
                ),
              ),
            ],
          ),
          // Ligne horizontale bas
          pw.Container(
            margin: const pw.EdgeInsets.only(left: 20, right: 20),
            height: 1,
            color: axisBlack,
          ),
          pw.SizedBox(height: 4),
          // Libellés catégories sous les barres
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20, right: 20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < displayItems.length; i++)
                  pw.SizedBox(
                    width: count > 10 ? 32 : 36,
                    child: pw.Column(
                      children: [
                        pw.Text(
                          displayItems[i].isOtherAggregate ? 'Autre' : 'N°${i + 1}',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 5.5,
                            color: displayItems[i].isOtherAggregate
                                ? PdfColor.fromHex('#64748B')
                                : PdfReportStyles.headerColor,
                          ),
                        ),
                        pw.Text(
                          formatShortParetoLabel(displayItems[i].title),
                          textAlign: pw.TextAlign.center,
                          maxLines: 3,
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 5.0,
                            color: displayItems[i].isOtherAggregate
                                ? PdfColor.fromHex('#64748B')
                                : PdfReportStyles.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Nombre d\'occurrences (barres)', style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: textGrey)),
              pw.Text('Courbe cumulative (axe droit 0-100 %)', style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: textGrey)),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UTILITAIRES DE FORMATAGE
  // ──────────────────────────────────────────────────────────────────────────
  static String _formatShortCategoryName(String full) {
    final upper = full.toUpperCase();
    if (upper.contains('CELLULE')) return 'Cellules MT';
    if (upper.contains('TRANSFO')) return 'Transfo MT/BT';
    if (upper.contains('INVERSEUR')) return 'Inverseurs';
    if (upper.contains('TGBT')) return 'TGBT';
    if (upper.contains('ARMOIRE')) return 'Armoires';
    if (upper.contains('COFFRET')) return 'Coffrets';
    if (upper.contains('TERRE') || upper.contains('ESSAI')) return 'Prises terre';
    if (upper.contains('GE') || upper.contains('GROUPE')) return 'Locaux GE';
    if (upper.contains('BT') || upper.contains('BASSE')) return 'Locaux BT';
    if (upper.contains('MT') || upper.contains('MOYENNE') || upper.contains('TECHNIQUE')) return 'Locaux MT';
    return full.length > 12 ? '${full.substring(0, 10)}.' : full;
  }

  static String formatShortParetoLabel(String full) {
    final l = full.toLowerCase();
    if (l.contains('autre')) return 'Autres\nanomalies';
    // Contacts directs & protection des personnes (prioritaire sur 'borne' / 'bornier')
    if (l.contains('contact direct') ||
        l.contains('contacts directs') ||
        l.contains('capot') ||
        l.contains('cache') ||
        l.contains('ip2x')) {
      return 'Contacts\ndirects';
    }
    if (l.contains('identification') || l.contains('repérage') || l.contains('reperage')) return 'Repérage\ncircuits';
    if (l.contains('câblage') || l.contains('canalisation') || l.contains('raccordement')) return 'Câblages &\ncanalisations';
    if (l.contains('enveloppe') || l.contains('armoire') || l.contains('coffret') || l.contains('ip')) return 'Enveloppes\n& coffrets';
    if (l.contains('conducteur pe') || l.contains('terre') || l.contains('différentiel') || l.contains('differentiel')) return 'Terre &\nliaisons PE';
    if (l.contains('disjoncteur') || l.contains('fusible') || l.contains('surintensité') || l.contains('surintensite')) return 'Protections\nsurintensités';
    if (l.contains('epi') || l.contains('habilitation')) return 'EPI &\nhabilitations';
    if (l.contains('consignation') || l.contains('intervention') || l.contains('plan')) return 'Plans &\nconsignation';
    if (l.contains('coupure') || l.contains('sectionnement') || l.contains('arrêt d\'urgence') || l.contains('arret')) return 'Organes de\ncoupure';
    if (l.contains('diélectrique') || l.contains('dielectrique') || l.contains('tapis') || l.contains('tabouret')) return 'Revêtement\nsol';
    if (l.contains('moyenne tension') || l.contains('hta') || l.contains('transfo') || l.contains('cellule')) return 'Poste &\ncellules MT';
    if (l.contains('éclairage') || l.contains('eclairage') || l.contains('baes')) return 'Éclairage de\nsécurité';
    if (l.contains('répartiteur') || l.contains('repartiteur') || l.contains('borne') || l.contains('bornier')) return 'Répartition\n& bornes';
    if (l.contains('foudre') || l.contains('parafoudre') || l.contains('paratonnerre')) return 'Foudre &\nparafoudres';
    if (l.contains('ambiance') || l.contains('ventilation') || l.contains('poussière') || l.contains('humidité')) return 'Conditions\nd\'ambiance';
    return full.length > 15 ? '${full.substring(0, 13)}..' : full;
  }
}
