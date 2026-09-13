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
  static pw.Font get fontRegular => pw.Font.helvetica();
  static pw.Font get fontBold => pw.Font.helveticaBold();
  static final PdfColor textGrey = PdfColor.fromHex('#64748B');

  // ──────────────────────────────────────────────────────────────────────────
  // 1. DIAGRAMME HORIZONTAL : RÉPARTITION PAR DOMAINE DE TENSION
  // ──────────────────────────────────────────────────────────────────────────
  static pw.Widget buildTensionDomainChart(int btCount, int mtCount) {
    final total = btCount + mtCount;
    final maxVal = math.max(math.max(btCount, mtCount), 1);
    // Arrondi supérieur à un pas propre (50)
    final axisMax = ((maxVal / 50).ceil() * 50).clamp(50, 500);

    const chartWidth = 420.0;
    const barHeight = 24.0;
    const labelWidth = 120.0;
    const plotWidth = chartWidth - labelWidth - 40.0;

    final btWidth = (btCount / axisMax) * plotWidth;
    final mtWidth = (mtCount / axisMax) * plotWidth;

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
          // Barre Basse Tension
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(
                width: labelWidth,
                child: pw.Text(
                  'Basse tension\n(BT)',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfReportStyles.darkGrey),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                height: 38,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(left: pw.BorderSide(color: PdfColors.black, width: 1)),
                ),
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: btWidth.clamp(2.0, plotWidth),
                      height: barHeight,
                      color: PdfColor.fromHex('#0B192C'),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      '$btCount',
                      style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfReportStyles.headerColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          // Barre Moyenne Tension
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(
                width: labelWidth,
                child: pw.Text(
                  'Moyenne tension\n(MT/HTA)',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfReportStyles.darkGrey),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                height: 38,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(left: pw.BorderSide(color: PdfColors.black, width: 1)),
                ),
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: mtWidth.clamp(2.0, plotWidth),
                      height: barHeight,
                      color: PdfColor.fromHex('#4A7BB0'),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      '$mtCount',
                      style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfReportStyles.headerColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Axe des X
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: labelWidth + 8),
            child: pw.Column(
              children: [
                pw.Container(
                  width: plotWidth + 30,
                  height: 1,
                  color: PdfColors.black,
                ),
                pw.SizedBox(height: 2),
                pw.Container(
                  width: plotWidth + 30,
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
                pw.Text(
                  'Nombre de non-conformités (Total : $total)',
                  style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfReportStyles.darkGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. DIAGRAMME EN BARRES EMPIILÉES : NON-CONFORMITÉS PAR CATÉGORIE
  // ──────────────────────────────────────────────────────────────────────────
  static pw.Widget buildEquipmentCategoryStackedBarChart(
    List<CategoryCrossAuditRow> mtRows,
    List<CategoryCrossAuditRow> btRows,
  ) {
    // Agréger et trier par total NC décroissant
    final allRows = <CategoryCrossAuditRow>[...mtRows, ...btRows];
    allRows.sort((a, b) => b.ncCount.compareTo(a.ncCount));

    // Prendre les catégories avec NC > 0 ou au moins les 9 premières
    final displayRows = allRows.take(9).toList();
    if (displayRows.isEmpty) return pw.SizedBox();

    final maxVal = displayRows.first.ncCount;
    final axisMax = ((maxVal / 25).ceil() * 25).clamp(25, 250);
    const plotHeight = 110.0;

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
                'Non-conformités par catégorie d\'installation / d\'équipement',
                style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfReportStyles.headerColor),
              ),
              pw.Row(
                children: [
                  pw.Container(width: 8, height: 8, color: PdfColor.fromHex('#B71C1C')),
                  pw.SizedBox(width: 3),
                  pw.Text('Critique', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                  pw.SizedBox(width: 8),
                  pw.Container(width: 8, height: 8, color: PdfColor.fromHex('#D97706')),
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
              // Ligne verticale Y
              pw.Container(width: 1, height: plotHeight, color: PdfColors.black),
              pw.SizedBox(width: 6),
              // Barres des catégories
              pw.Expanded(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: displayRows.map((cat) {
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
                        // Pile : Majeure en haut, Critique en bas
                        pw.Container(
                          width: 22,
                          child: pw.Column(
                            children: [
                              if (majH > 0)
                                pw.Container(
                                  width: 22,
                                  height: majH,
                                  color: PdfColor.fromHex('#D97706'),
                                ),
                              if (critH > 0)
                                pw.Container(
                                  width: 22,
                                  height: critH,
                                  color: PdfColor.fromHex('#B71C1C'),
                                ),
                              if (majH == 0 && critH == 0)
                                pw.Container(width: 22, height: 1, color: PdfColors.grey),
                            ],
                          ),
                        ),
                        pw.Container(width: 32, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 3),
                        pw.SizedBox(
                          width: 42,
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
            'Nombre de non-conformités par catégorie',
            style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey),
          ),
        ],
      ),
    );
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
                  pw.Container(width: 8, height: 8, color: PdfColor.fromHex('#2E7D32')),
                  pw.SizedBox(width: 3),
                  pw.Text('Source identifiée', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                  pw.SizedBox(width: 8),
                  pw.Container(width: 8, height: 8, color: PdfColor.fromHex('#B71C1C')),
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
              pw.Container(width: 1, height: plotHeight, color: PdfColors.black),
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
                                  color: PdfColor.fromHex('#B71C1C'),
                                  alignment: pw.Alignment.center,
                                  child: cat.$4 > 0 && nonIdentH > 10
                                      ? pw.Text('${cat.$4}', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.white))
                                      : null,
                                ),
                              if (identH > 0)
                                pw.Container(
                                  width: 46,
                                  height: identH,
                                  color: PdfColor.fromHex('#2E7D32'),
                                  alignment: pw.Alignment.center,
                                  child: cat.$3 > 0 && identH > 10
                                      ? pw.Text('${cat.$3}', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.white))
                                      : null,
                                ),
                            ],
                          ),
                        ),
                        pw.Container(width: 60, height: 1, color: PdfColors.black),
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
            'Disjoncteur de tête (Armoires + Coffrets, n=$total)',
            style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfReportStyles.headerColor),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Label Présent
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Présent', style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColor.fromHex('#2E7D32'))),
                  pw.Text('${presentPct.toStringAsFixed(0)} % ($present)', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfReportStyles.darkGrey)),
                ],
              ),
              pw.SizedBox(width: 14),
              // Cercle graphique vectoriel
              pw.CustomPaint(
                size: const PdfPoint(80, 80),
                painter: (PdfGraphics canvas, PdfPoint size) {
                  final cx = size.x / 2;
                  final cy = size.y / 2;
                  final r = 36.0;

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
                  canvas.setFillColor(PdfColor.fromHex('#2E7D32'));
                  canvas.moveTo(cx, cy);
                  for (double a = 0; a <= anglePresent; a += 0.05) {
                    canvas.lineTo(cx + r * math.cos(a), cy + r * math.sin(a));
                  }
                  canvas.lineTo(cx + r * math.cos(anglePresent), cy + r * math.sin(anglePresent));
                  canvas.lineTo(cx, cy);
                  canvas.fillPath();

                  // Portion Absent (Rouge)
                  canvas.setFillColor(PdfColor.fromHex('#B71C1C'));
                  canvas.moveTo(cx, cy);
                  for (double a = anglePresent; a <= 2 * math.pi; a += 0.05) {
                    canvas.lineTo(cx + r * math.cos(a), cy + r * math.sin(a));
                  }
                  canvas.lineTo(cx + r, cy);
                  canvas.lineTo(cx, cy);
                  canvas.fillPath();

                  // Trou central Donut (Blanc)
                  canvas.setFillColor(PdfColors.white);
                  canvas.drawEllipse(cx, cy, 14, 14);
                  canvas.fillPath();
                },
              ),
              pw.SizedBox(width: 14),
              // Label Absent
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Absent', style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColor.fromHex('#B71C1C'))),
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
                  pw.Container(width: 8, height: 8, color: PdfColor.fromHex('#2E7D32')),
                  pw.SizedBox(width: 3),
                  pw.Text('Avec parafoudre', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                  pw.SizedBox(width: 8),
                  pw.Container(width: 8, height: 8, color: PdfColor.fromHex('#94A3B8')),
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
              pw.Container(width: 1, height: plotHeight, color: PdfColors.black),
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
                                  color: PdfColor.fromHex('#94A3B8'),
                                  alignment: pw.Alignment.center,
                                  child: cat.$4 > 0 && sansH > 10
                                      ? pw.Text('${cat.$4}', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.white))
                                      : null,
                                ),
                              if (avecH > 0)
                                pw.Container(
                                  width: 46,
                                  height: avecH,
                                  color: PdfColor.fromHex('#2E7D32'),
                                  alignment: pw.Alignment.center,
                                  child: cat.$3 > 0 && avecH > 10
                                      ? pw.Text('${cat.$3}', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.white))
                                      : null,
                                ),
                            ],
                          ),
                        ),
                        pw.Container(width: 60, height: 1, color: PdfColors.black),
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
    int totalOccurrences,
  ) {
    final top10 = items.isNotEmpty
        ? items.take(10).toList()
        : [
            TopDefectItem(title: 'Identification / repérage circuits', count: 0, percentage: 0),
            TopDefectItem(title: 'Câblages et canalisations', count: 0, percentage: 0),
            TopDefectItem(title: 'Continuité du conducteur PE', count: 0, percentage: 0),
            TopDefectItem(title: 'EPI électriques', count: 0, percentage: 0),
            TopDefectItem(title: 'Plan d\'intervention et consignation', count: 0, percentage: 0),
            TopDefectItem(title: 'Revêtement diélectrique au sol', count: 0, percentage: 0),
            TopDefectItem(title: 'Dispositifs de protection', count: 0, percentage: 0),
            TopDefectItem(title: 'Matériel de consignation', count: 0, percentage: 0),
            TopDefectItem(title: 'Coupure générale identifiée', count: 0, percentage: 0),
            TopDefectItem(title: 'Procédure de consignation', count: 0, percentage: 0),
          ];

    final maxVal = top10.first.count;
    final axisMax = ((maxVal / 20).ceil() * 20).clamp(20, 200);
    const plotHeight = 120.0;
    const barWidth = 24.0;

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
            'Analyse de Pareto - 10 principales catégories de défauts (sur $totalOccurrences occurrences)',
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
              pw.Container(width: 1, height: plotHeight, color: PdfColors.black),
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
                        children: top10.map((item) {
                          final h = axisMax > 0 ? (item.count / axisMax) * plotHeight : 0.0;
                          return pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text(
                                '${item.count}',
                                style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfReportStyles.darkGrey),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Container(
                                width: barWidth,
                                height: h.clamp(1.0, plotHeight),
                                color: PdfColor.fromHex('#1E3E62'),
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
                        // 1. Ligne en pointillés à 80%
                        final y80 = 0.8 * plotHeight;
                        canvas.setStrokeColor(PdfColor.fromHex('#D32F2F'));
                        canvas.setLineWidth(0.8);
                        canvas.setLineDashPattern([3, 2]);
                        canvas.drawLine(0, y80, size.x, y80);
                        canvas.strokePath();
                        canvas.setLineDashPattern(); // Reset pointillés

                        // 2. Courbe de Pareto cumulative
                        canvas.setStrokeColor(PdfColor.fromHex('#B71C1C'));
                        canvas.setLineWidth(1.8);

                        final count = top10.length;
                        final colWidth = size.x / count;

                        final points = <PdfPoint>[];
                        for (int i = 0; i < count; i++) {
                          final px = (i + 0.5) * colWidth;
                          final pct = (top10[i].cumulativePercentage / 100.0).clamp(0.0, 1.0);
                          final py = pct * plotHeight;
                          points.add(PdfPoint(px, py));
                        }

                        // Ligne reliant les points
                        for (int i = 0; i < points.length; i++) {
                          if (i == 0) {
                            canvas.moveTo(points[i].x, points[i].y);
                          } else {
                            canvas.lineTo(points[i].x, points[i].y);
                          }
                        }
                        canvas.strokePath();

                        // Points circulaires
                        canvas.setFillColor(PdfColor.fromHex('#B71C1C'));
                        for (final p in points) {
                          canvas.drawEllipse(p.x, p.y, 2.5, 2.5);
                          canvas.fillPath();
                        }
                      },
                    ),
                    // Badge 80 %
                    pw.Positioned(
                      top: plotHeight * 0.2 - 8,
                      right: 12,
                      child: pw.Text(
                        '80 %',
                        style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColor.fromHex('#D32F2F')),
                      ),
                    ),
                  ],
                ),
              ),
              // Axe Y droit (% cumulé)
              pw.Container(width: 1, height: plotHeight, color: PdfColors.black),
              pw.SizedBox(width: 4),
              pw.Container(
                height: plotHeight,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('100', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('80', style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColor.fromHex('#D32F2F'))),
                    pw.Text('60', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('40', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('20', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                    pw.Text('0', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
                  ],
                ),
              ),
            ],
          ),
          // Ligne horizontale bas
          pw.Container(
            margin: const pw.EdgeInsets.only(left: 20, right: 20),
            height: 1,
            color: PdfColors.black,
          ),
          pw.SizedBox(height: 4),
          // Libellés catégories sous les barres
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20, right: 20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: top10.map((item) {
                return pw.SizedBox(
                  width: 36,
                  child: pw.Text(
                    _formatShortParetoLabel(item.title),
                    textAlign: pw.TextAlign.center,
                    maxLines: 3,
                    style: pw.TextStyle(font: fontRegular, fontSize: 5.5, color: PdfReportStyles.darkGrey),
                  ),
                );
              }).toList(),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Nombre d\'occurrences', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
              pw.Text('% cumulé (base $totalOccurrences)', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textGrey)),
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
    if (full.contains('Armoire')) return 'Armoires';
    if (full.contains('Coffret')) return 'Coffrets';
    if (full.contains('Locaux MT') || full.contains('Locaux techniques MT')) return 'Locaux MT';
    if (full.contains('Locaux GE')) return 'Locaux GE';
    if (full.contains('Locaux BT') || full.contains('Locaux technique BT')) return 'Locaux BT';
    if (full.contains('Cellule')) return 'Cellules MT';
    if (full.contains('Inverseur')) return 'Inverseurs';
    if (full.contains('Transfo')) return 'Transfo MT/BT';
    if (full.contains('TGBT')) return 'TGBT';
    if (full.contains('Prises de terre') || full.contains('Essai')) return 'Prises terre';
    return full.length > 12 ? '${full.substring(0, 10)}.' : full;
  }

  static String _formatShortParetoLabel(String full) {
    if (full.contains('Identification') || full.contains('repérage')) return 'Repérage\ncircuits';
    if (full.contains('Câblages') || full.contains('raccordement')) return 'Câblages &\nraccords';
    if (full.contains('PE') || full.contains('conducteur PE')) return 'Continuité\nPE';
    if (full.contains('EPI')) return 'EPI\nélectriques';
    if (full.contains('Plan d\'intervention')) return 'Plans &\nconsignation';
    if (full.contains('diélectrique')) return 'Revêtement\nsol';
    if (full.contains('Dispositifs de protection')) return 'Dispositifs\nprotection';
    if (full.contains('Matériel de consignation')) return 'Matériel\nconsignation';
    if (full.contains('Coupure générale')) return 'Coupure\ngénérale';
    if (full.contains('Procédure de consignation')) return 'Procédure\nconsignation';
    return full.length > 15 ? '${full.substring(0, 13)}..' : full;
  }
}
