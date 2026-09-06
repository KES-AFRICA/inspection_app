import 'package:inspec_app/services/ai/executive_summary_snapshot.dart';
import 'package:inspec_app/services/ai/mission_executive_summary_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/services/ai/executive_summary_data.dart';
import 'package:inspec_app/services/statistics/mission_statistics.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

/// Builder responsable du Résumé Exécutif KES (7 sous-sections officielles, matrices et constats majeurs)
class PdfExecutiveSummaryBuilder {
  static pw.TableRow _buildIndicateurRow(String label, String value) =>
      PdfReportStyles.buildIndicateurRow(label, value, fontBold: fontBold, fontRegular: fontRegular);

  static String _formatConcentrationTitle(String rawTitle) =>
      PdfReportStyles.formatConcentrationTitle(rawTitle);

  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();

  static const double fsH1 = PdfReportStyles.fsH1;
  static const double fsH2 = PdfReportStyles.fsH2;
  static const double fsH3 = PdfReportStyles.fsH3;
  static const double fsBody = PdfReportStyles.fsBody;
  static const double fsSmall = PdfReportStyles.fsSmall;

  /// Construit la section « RÉSUMÉ EXÉCUTIF » structurée en 7 sous-sections officielles.
  static List<pw.Widget> buildResumeExecutif(
    Mission mission,
    Map<String, int> trackedPages,
    String numeroRapportDoc, {
    ExecutiveSummaryData? summaryData,
    int offset = 0,
  }) {
    final widgets = <pw.Widget>[];

    final snapshot = ExecutiveSummarySnapshot.fromMission(mission.id);
    final data =
        summaryData ??
        MissionExecutiveSummaryService.buildDeterministicFallback(
          mission.id,
          snapshot,
        );

    // Entête de section RÉSUMÉ EXÉCUTIF
    widgets.add(
      PageTracker(
        key: 'resume_executif',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.sectionBox('RESUME EXECUTIF'),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    // ── 1. Contexte et périmètre de la mission ──
    widgets.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PageTracker(
            key: 'resume_executif_1_1',
            registry: trackedPages,
            offset: offset,
            child: _subSectionHeader('1. Contexte et périmètre de la mission'),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            data.contexte.paragraph,
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: fsBody,
              color: PdfReportStyles.darkGrey,
              lineSpacing: 2.5,
            ),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 10));

    // ── 2. Synthèse des résultats ──
    widgets.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PageTracker(
            key: 'resume_executif_1_2',
            registry: trackedPages,
            offset: offset,
            child: _subSectionHeader('2. Synthèse des résultats'),
          ),
          pw.SizedBox(height: 4),
          if (data.syntheseResultats.introParagraph.isNotEmpty)
            pw.Text(
              data.syntheseResultats.introParagraph,
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: fsBody,
                color: PdfReportStyles.darkGrey,
                lineSpacing: 2.5,
              ),
              textAlign: pw.TextAlign.justify,
            ),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 6));

    // Tableau de criticité (1.2)
    if (data.syntheseResultats.tableRows.isNotEmpty) {
      widgets.add(
        _buildCriticalitySummaryTable(
          data.syntheseResultats.tableRows,
          data.syntheseResultats.tableTotalRow,
          totalEquipments: snapshot.equipmentCount,
        ),
      );
      widgets.add(pw.SizedBox(height: 6));
    }

    if (data.syntheseResultats.commentaryParagraph.isNotEmpty) {
      widgets.add(
        pw.Text(
          data.syntheseResultats.commentaryParagraph,
          style: pw.TextStyle(
            font: fontRegular,
            fontSize: fsBody,
            color: PdfReportStyles.darkGrey,
            lineSpacing: 2.5,
          ),
          textAlign: pw.TextAlign.justify,
        ),
      );
      widgets.add(pw.SizedBox(height: 10));
    }

    // ── 3. Concentration du risque ──
    final concRows = <pw.TableRow>[];
    if (data.concentrationRisque.primaryConcentrationParagraph.isNotEmpty) {
      concRows.add(
        _buildIndicateurRow(
          'Volume & Catégories',
          data.concentrationRisque.primaryConcentrationParagraph,
        ),
      );
    }
    if (data.concentrationRisque.highestDensityParagraph.isNotEmpty) {
      concRows.add(
        _buildIndicateurRow(
          'Densité d\'équipement',
          data.concentrationRisque.highestDensityParagraph,
        ),
      );
    }

    widgets.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PageTracker(
            key: 'resume_executif_1_3',
            registry: trackedPages,
            offset: offset,
            child: _subSectionHeader(
              _formatConcentrationTitle(data.concentrationRisque.title),
            ),
          ),
          pw.SizedBox(height: 4),
          if (concRows.isNotEmpty)
            pw.Table(
              border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(3.0),
                1: pw.FlexColumnWidth(7.0),
              },
              children: [
                pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'AXE DE CONCENTRATION',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 8,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'ANALYSE ET CONSTAT',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 8,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
                ...concRows,
              ],
            ),
          if (data.concentrationRisque.qualitativeRiskCallout.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Point de risque qualitatif :',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: fsBody,
                color: PdfReportStyles.darkGrey,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              data.concentrationRisque.qualitativeRiskCallout,
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: fsBody,
                color: PdfReportStyles.darkGrey,
                lineSpacing: 2.5,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ],
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 10));

    // ── 4. Facteurs de risque prépondérants ──
    widgets.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PageTracker(
            key: 'resume_executif_1_4',
            registry: trackedPages,
            offset: offset,
            child: _subSectionHeader('4. Facteurs de risque prépondérants'),
          ),
          pw.SizedBox(height: 4),
          if (data.facteursRisque.introParagraph.isNotEmpty)
            pw.Text(
              data.facteursRisque.introParagraph,
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: fsBody,
                color: PdfReportStyles.darkGrey,
                lineSpacing: 2.5,
              ),
              textAlign: pw.TextAlign.justify,
            ),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 6));

    // Tableau des facteurs de risque (1.4)
    if (data.facteursRisque.tableRows.isNotEmpty) {
      widgets.add(_buildRiskFactorsSummaryTable(data.facteursRisque.tableRows));
      widgets.add(pw.SizedBox(height: 6));
    }

    if (data.facteursRisque.commentaryParagraph.isNotEmpty) {
      widgets.add(
        pw.Text(
          data.facteursRisque.commentaryParagraph,
          style: pw.TextStyle(
            font: fontRegular,
            fontSize: fsBody,
            color: PdfReportStyles.darkGrey,
            lineSpacing: 2.5,
          ),
          textAlign: pw.TextAlign.justify,
        ),
      );
      widgets.add(pw.SizedBox(height: 10));
    }

    // ── 5. Observations et constats majeurs ──
    final obsRows = <pw.TableRow>[];
    for (int i = 0; i < data.observationsMajores.bulletPoints.length; i++) {
      final parsed = PdfReportStyles.parseObservationRow(
        data.observationsMajores.bulletPoints[i],
      );
      obsRows.add(
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                '${i + 1}',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 8,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                parsed.observation,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 7.5,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                parsed.stats,
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 7.5,
                  color: PdfReportStyles.darkGrey,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                parsed.constatMajeur,
                style: pw.TextStyle(font: fontRegular, fontSize: 7.5),
              ),
            ),
          ],
        ),
      );
    }

    final obsHeaderRow = pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.middle,
      decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            'N°',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 8,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            'OBSERVATION',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 8,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            'STATS',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 8,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            'CONSTAT MAJEUR',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 8,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );

    final obsHeaderWidget = PageTracker(
      key: 'resume_executif_1_5',
      registry: trackedPages,
      offset: offset,
      child: _subSectionHeader('5. Observations et constats majeurs'),
    );

    final obsBlocks = PdfReportStyles.buildHeaderWithTableList(
      headerWidget: obsHeaderWidget,
      headerRow: obsHeaderRow,
      dataRows: obsRows,
      columnWidths: const {
        0: pw.FlexColumnWidth(0.6),
        1: pw.FlexColumnWidth(3.2),
        2: pw.FlexColumnWidth(2.2),
        3: pw.FlexColumnWidth(4.0),
      },
    );

    widgets.addAll(obsBlocks);

    if (data.observationsMajores.summaryParagraph.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 4));
      widgets.add(
        pw.Text(
          data.observationsMajores.summaryParagraph,
          style: pw.TextStyle(
            font: fontRegular,
            fontSize: fsBody,
            color: PdfReportStyles.darkGrey,
            lineSpacing: 2.5,
          ),
          textAlign: pw.TextAlign.justify,
        ),
      );
    }
    widgets.add(pw.SizedBox(height: 10));

    // ── 6. Recommandations prioritaires hiérarchisées ──
    final recoRows = <pw.TableRow>[];
    if (data.recommandationsPrioritaires.priority1Immediate.isNotEmpty) {
      recoRows.add(
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FEF2F2')),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Critique',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 7.5,
                  color: PdfColor.fromHex('#B71C1C'),
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Priorité 1 — Action Immédiate',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 7.5,
                  color: PdfColor.fromHex('#B71C1C'),
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                PdfReportStyles.cleanRecommendationText(
                  data.recommandationsPrioritaires.priority1Immediate,
                ),
                style: pw.TextStyle(font: fontRegular, fontSize: 7.5),
              ),
            ),
          ],
        ),
      );
    }
    if (data.recommandationsPrioritaires.priority2ShortTerm.isNotEmpty) {
      recoRows.add(
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FFF7ED')),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Majeure',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 7.5,
                  color: PdfColor.fromHex('#C2410C'),
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Priorité 2 — Court Terme',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 7.5,
                  color: PdfColor.fromHex('#C2410C'),
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                PdfReportStyles.cleanRecommendationText(
                  data.recommandationsPrioritaires.priority2ShortTerm,
                ),
                style: pw.TextStyle(font: fontRegular, fontSize: 7.5),
              ),
            ),
          ],
        ),
      );
    }
    if (data.recommandationsPrioritaires.priority3MediumTerm.isNotEmpty) {
      recoRows.add(
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Mineure',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 7.5,
                  color: PdfColors.grey800,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Priorité 3 — Moyen Terme',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 7.5,
                  color: PdfColors.grey800,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                PdfReportStyles.cleanRecommendationText(
                  data.recommandationsPrioritaires.priority3MediumTerm,
                ),
                style: pw.TextStyle(font: fontRegular, fontSize: 7.5),
              ),
            ),
          ],
        ),
      );
    }

    final recoHeaderRow = pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.middle,
      decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            'CRITICITÉ',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 8,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            'NIVEAU DE PRIORITÉ',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 8,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            'ACTION CORRECTIVE RECOMMANDÉE',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 8,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );

    final recoHeaderWidget = PageTracker(
      key: 'resume_executif_1_6',
      registry: trackedPages,
      offset: offset,
      child: _subSectionHeader('6. Recommandations prioritaires hiérarchisées'),
    );

    final recoIntroWidget =
        data.recommandationsPrioritaires.introParagraph.isNotEmpty
        ? pw.Text(
            data.recommandationsPrioritaires.introParagraph,
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: fsBody,
              color: PdfReportStyles.darkGrey,
              lineSpacing: 2.5,
            ),
            textAlign: pw.TextAlign.justify,
          )
        : null;

    final recoBlocks = PdfReportStyles.buildHeaderWithTableList(
      headerWidget: recoHeaderWidget,
      introWidget: recoIntroWidget,
      headerRow: recoHeaderRow,
      dataRows: recoRows,
      columnWidths: const {
        0: pw.FlexColumnWidth(1.8),
        1: pw.FlexColumnWidth(2.7),
        2: pw.FlexColumnWidth(5.5),
      },
    );

    widgets.addAll(recoBlocks);
    widgets.add(pw.SizedBox(height: 10));

    // ── 7. Appréciation globale ──
    widgets.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PageTracker(
            key: 'resume_executif_1_7',
            registry: trackedPages,
            offset: offset,
            child: _subSectionHeader('7. Appréciation globale'),
          ),
          pw.SizedBox(height: 6),
          if (data.appreciationGlobale.assessmentParagraph1.isNotEmpty)
            _buildFormattedText(data.appreciationGlobale.assessmentParagraph1),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 6));
    if (data.appreciationGlobale.assessmentParagraph2.isNotEmpty) {
      widgets.add(
        _buildFormattedText(data.appreciationGlobale.assessmentParagraph2),
      );
      widgets.add(pw.SizedBox(height: 6));
    }
    if (data.appreciationGlobale.assessmentParagraph3.isNotEmpty) {
      widgets.add(
        _buildFormattedText(data.appreciationGlobale.assessmentParagraph3),
      );
      widgets.add(pw.SizedBox(height: 8));
    }

    if (data.appreciationGlobale.actionPlanHeader.isNotEmpty) {
      widgets.add(
        _buildFormattedText(data.appreciationGlobale.actionPlanHeader),
      );
      widgets.add(pw.SizedBox(height: 6));
    }

    if (data.appreciationGlobale.actionPlanSteps.isNotEmpty) {
      for (
        int i = 0;
        i < data.appreciationGlobale.actionPlanSteps.length;
        i++
      ) {
        final step = data.appreciationGlobale.actionPlanSteps[i];
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 4,
                  height: 4,
                  margin: const pw.EdgeInsets.only(top: 4, right: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfReportStyles.accentColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(child: _buildFormattedText(step)),
              ],
            ),
          ),
        );
      }
      widgets.add(pw.SizedBox(height: 8));
    }

    if (data.appreciationGlobale.counterVisitParagraph.isNotEmpty) {
      widgets.add(
        _buildFormattedText(data.appreciationGlobale.counterVisitParagraph),
      );
    }

    return widgets;
  }

  static pw.Widget _buildFormattedText(
    String text, {
    pw.TextStyle? defaultStyle,
    pw.TextAlign textAlign = pw.TextAlign.justify,
  }) {
    final style =
        defaultStyle ??
        pw.TextStyle(
          font: fontRegular,
          fontSize: fsBody,
          color: PdfReportStyles.darkGrey,
          lineSpacing: 2.5,
        );
    final boldStyle = style.copyWith(font: fontBold);

    final parts = text.split('**');
    if (parts.length == 1) {
      return pw.Text(text, style: style, textAlign: textAlign);
    }

    final spans = <pw.TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final isBold = i % 2 == 1;
      spans.add(pw.TextSpan(text: parts[i], style: isBold ? boldStyle : style));
    }

    return pw.RichText(
      textAlign: textAlign,
      text: pw.TextSpan(children: spans),
    );
  }

  static pw.Widget _subSectionHeader(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(font: fontBold, fontSize: fsH2, color: PdfReportStyles.accentColor),
    );
  }

  static pw.Widget _buildCriticalitySummaryTable(
    List<CriticalityRowData> rows,
    CriticalityRowData totalRow, {
    int? totalEquipments,
  }) {
    final densityHeader = (totalEquipments != null && totalEquipments > 0)
        ? 'Densité (/$totalEquipments équip.)'
        : 'Densité (/ équip.)';

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.2),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(3.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('Criticité'),
            _buildTableHeaderCell('Nombre'),
            _buildTableHeaderCell('Part du total'),
            _buildTableHeaderCell(densityHeader),
          ],
        ),
        for (int i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i % 2 == 1 ? PdfReportStyles.tableRowAlt : PdfColors.white,
            ),
            children: [
              _buildTableCell(
                rows[i].criticite,
                isBold: true,
                color: _getCriticitePdfColor(rows[i].criticite),
              ),
              _buildTableCell('${rows[i].nombre}', align: pw.TextAlign.center),
              _buildTableCell(rows[i].partPct, align: pw.TextAlign.center),
              _buildTableCell(rows[i].densiteStr, align: pw.TextAlign.center),
            ],
          ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [
            _buildTableCell(totalRow.criticite, isBold: true),
            _buildTableCell(
              '${totalRow.nombre}',
              isBold: true,
              align: pw.TextAlign.center,
            ),
            _buildTableCell(
              totalRow.partPct,
              isBold: true,
              align: pw.TextAlign.center,
            ),
            _buildTableCell(
              totalRow.densiteStr,
              isBold: true,
              align: pw.TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildRiskFactorsSummaryTable(List<RiskFactorRowData> rows) {
    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.5),
        1: pw.FlexColumnWidth(1.3),
        2: pw.FlexColumnWidth(1.4),
        3: pw.FlexColumnWidth(3.8),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('Nature du risque'),
            _buildTableHeaderCell('Constats'),
            _buildTableHeaderCell('Part (%)'),
            _buildTableHeaderCell('Observation'),
          ],
        ),
        for (int i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i % 2 == 1 ? PdfReportStyles.tableRowAlt : PdfColors.white,
            ),
            children: [
              _buildTableCell(rows[i].natureRisque, isBold: true),
              _buildTableCell(rows[i].constats, align: pw.TextAlign.center),
              _buildTableCell(rows[i].partPct, align: pw.TextAlign.center),
              _buildTableCell(rows[i].observation, align: pw.TextAlign.center),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: fsSmall,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.center,
    pw.Alignment alignment = pw.Alignment.center,
    PdfColor? color,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isBold ? fontBold : fontRegular,
          fontSize: fsSmall,
          color: color ?? PdfReportStyles.darkGrey,
        ),
        textAlign: align,
      ),
    );
  }

  /// Widget utilitaire pour les cellules regroupées verticalement (ZONE, REPÈRE, ÉQUIPEMENT, etc.)
  /// Corrige le centrage vertical pour les regroupements comportant un nombre d'éléments PAIR (N=2, 4, 6...).
  static pw.Widget _buildGroupedCellWidget({
    required int currentIndex,
    required int totalRows,
    required String text,
    required pw.TextStyle style,
    required pw.Border border,
    PdfColor decorationColor = PdfColors.white,
    pw.EdgeInsets padding = const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    pw.TextAlign textAlign = pw.TextAlign.center,
    pw.Alignment alignment = pw.Alignment.center,
    bool condition = true,
  }) {
    final midIndex = (totalRows - 1) ~/ 2;
    if (currentIndex != midIndex || !condition || text.isEmpty) {
      return pw.Container(
        decoration: pw.BoxDecoration(color: decorationColor, border: border),
        padding: padding,
        alignment: alignment,
        child: pw.SizedBox(),
      );
    }

    final textWidget = pw.Text(
      text,
      style: style,
      textAlign: textAlign,
    );

    if (totalRows % 2 == 0) {
      final fs = style.fontSize ?? 8.5;
      final dynamicTopPadding = fs * 1.6;

      return pw.Container(
        decoration: pw.BoxDecoration(color: decorationColor, border: border),
        padding: pw.EdgeInsets.only(top: dynamicTopPadding, left: 4, right: 4, bottom: 2),
        alignment: pw.Alignment.topCenter,
        child: textWidget,
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(color: decorationColor, border: border),
      padding: padding,
      alignment: alignment,
      child: textWidget,
    );
  }

  /// Retourne la couleur standard KES pour l'affichage de la criticité dans les tableaux :
  /// - Critique : Rouge (#D32F2F)
  /// - Majeure : Orange (#E65100)
  /// - Mineure : Jaune (#F57F17 - ambre lisible sur fond blanc)
  static PdfColor _getCriticitePdfColor(String criticite) {
    final c = criticite.trim().toLowerCase();
    if (c.contains('critique') || c == '3') {
      return PdfColor.fromInt(0xFFD32F2F); // Rouge
    } else if (c.contains('majeur') || c == '2') {
      return PdfColor.fromInt(0xFFE65100); // Orange
    } else if (c.contains('mineur') || c == '1') {
      return PdfColor.fromInt(0xFFF57F17); // Jaune / Ambre
    }
    return PdfReportStyles.darkGrey;
  }

  /// Retourne la fonte appropriée (Gras si criticité définie)
  static pw.Font _getCriticiteFont(String criticite) {
    final c = criticite.trim().toLowerCase();
    if (c.contains('critique') || c.contains('majeur') || c.contains('mineur')) {
      return fontBold;
    }
    return fontRegular;
  }

}
