import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/statistics/mission_statistics.dart';
import 'package:inspec_app/services/statistics/mission_statistics_collector.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

/// Builder responsable de l'Analyse Statistique (indicateurs clés, diagramme Pareto, histogrammes)
class PdfStatisticsBuilder {
  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();

  static const double fsH1 = PdfReportStyles.fsH1;
  static const double fsH2 = PdfReportStyles.fsH2;
  static const double fsH3 = PdfReportStyles.fsH3;
  static const double fsBody = PdfReportStyles.fsBody;
  static const double fsSmall = PdfReportStyles.fsSmall;

  static List<pw.Widget> buildAnalyseStatistique(
    Mission mission,
    Map<String, int> trackedPages,
    String numeroRapportDoc, {
    int offset = 0,
  }) {
    final widgets = <pw.Widget>[];

    // Collecte unifiée via le résumé statistique Néo-Natif
    final summary = MissionStatisticsCollector.collectSummary(mission.id);
    final cStats = summary.criticalityStats;

    // Entête de section
    widgets.add(
      PageTracker(
        key: 'analyse_statistique',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.sectionBox('ANALYSE STATISTIQUE'),
      ),
    );
    widgets.add(pw.SizedBox(height: 10));

    // 1. Indicateurs clés de la mission
    final totalEq = summary.totalEquipments;
    final activeCats = summary.crossCategoryItems.length;
    final densestStr = summary.densestCategoryFormatted;
    final topTwo = summary.topTwoCategoriesResult;
    final domainStats = summary.tensionDomainStats;

    widgets.add(
      PageTracker(
        key: 'stat_indicateurs',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfReportStyles.subTitle('1. Indicateurs clés de la mission'),
            pw.SizedBox(height: 5),
            PdfReportStyles.bodyText(
              'Tableau synthétique des indicateurs majeurs de la mission (gravité, concentration et volume) :',
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(3.8),
                1: pw.FlexColumnWidth(6.2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'INDICATEUR',
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
                        'VALEUR ET DESCRIPTION',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 8,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                _buildIndicateurRow(
                  'Périmètre couvert',
                  '$totalEq installations et équipements répartis en $activeCats catégories (MT et BT)',
                ),
                _buildIndicateurRow(
                  'Total des non-conformités',
                  '${cStats.total} (recensement par installation/équipement)',
                ),
                _buildIndicateurRow(
                  'Densité moyenne globale',
                  '${summary.globalDensityStr} NC/équipement',
                ),
                _buildIndicateurRow(
                  'Part des NC critiques',
                  '${cStats.pctCritique.toStringAsFixed(1).replaceAll('.', ',')} % — niveau de risque élevé',
                ),
                _buildIndicateurRow(topTwo.label, topTwo.formattedValue),
                _buildIndicateurRow('Catégorie la plus dense', densestStr),
                _buildIndicateurRow(
                  'Répartition MT / BT',
                  'MT : ${domainStats.mtCount} NC (${domainStats.mtPct.toStringAsFixed(1).replaceAll('.', ',')} %) — BT : ${domainStats.btCount} NC (${domainStats.btPct.toStringAsFixed(1).replaceAll('.', ',')} %)',
                ),
              ],
            ),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    // 2. Analyse croisée par catégories / équipement (incluant criticité et historique)
    if (summary.crossCategoryItems.isNotEmpty) {
      widgets.add(
        PageTracker(
          key: 'stat_croisee',
          registry: trackedPages,
          offset: offset,
          child: _buildCrossCategorySection(
            summary.crossCategoryItems,
            summary.crossAnalysisText,
            cStats,
            2,
          ),
        ),
      );
      widgets.add(pw.SizedBox(height: 12));
    }

    // 3. Répartition des non-conformités par domaine de tension
    if (domainStats.totalCount > 0) {
      widgets.add(
        PageTracker(
          key: 'stat_tension',
          registry: trackedPages,
          offset: offset,
          child: _buildTensionDomainSection(domainStats, 3),
        ),
      );
      widgets.add(pw.SizedBox(height: 12));
    }

    // 4. Statistique par type de défaut — analyse de Pareto (normalisée & explicite)
    final totalOccur = summary.paretoResult.totalOccurrences > 0
        ? summary.paretoResult.totalOccurrences
        : summary.criticalityStats.total;
    final topItemsCount = summary.paretoResult.items.length;
    final topSumCount = summary.paretoResult.items.fold<int>(
      0,
      (sum, e) => sum + e.count,
    );
    final topSumPct = totalOccur > 0 ? (topSumCount / totalOccur * 100) : 0.0;
    final pareto80K = summary.paretoResult.paretoCategoryCount;

    final topThreeNames = summary.paretoResult.items
        .take(3)
        .map((e) => e.title.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final topThreeText = topThreeNames.isNotEmpty
        ? topThreeNames.join(', ')
        : 'Interconnexion à la terre, Protections contre les surintensités, Répartition des circuits';

    final paretoIntroSummary =
        'L\'analyse porte sur la totalité des $totalOccur occurrences de non-conformités répertoriées sur le site, classées selon les catégories de défauts normalisées. Les $topItemsCount catégories les plus récurrentes totalisent $topSumCount constats (${topSumPct.toStringAsFixed(1).replaceAll('.', ',')} % des défaillances), et les $pareto80K premières catégories permettent d\'atteindre ou dépasser le seuil critique de 80 % du volume global des anomalies.';

    final pareto8020DynamicText =
        'Interprétation statistique : Cette distribution confirme l\'application stricte du principe de Pareto (règle des 80/20). La prise en charge prioritaire des $pareto80K premières catégories de défauts ($topThreeText) permettra d\'éliminer plus de 80 % des risques électriques identifiés, optimisant ainsi l\'efficacité opérationnelle du plan d\'actions correctives.';

    widgets.add(
      PageTracker(
        key: 'stat_pareto',
        registry: trackedPages,
        offset: offset,
        child: pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfReportStyles.subTitle(
                '4. Statistique par type de défaut — analyse de Pareto',
              ),
              pw.SizedBox(height: 5),
              PdfReportStyles.bodyText(paretoIntroSummary),
              pw.SizedBox(height: 8),
              _buildParetoChartWidget(summary.paretoResult),
              pw.SizedBox(height: 6),
              PdfReportStyles.bodyText(pareto8020DynamicText),
            ],
          ),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    // 5. Non-conformités de l'année passée et taux de mise en conformité
    widgets.add(
      PageTracker(
        key: 'stat_annee_passee',
        registry: trackedPages,
        offset: offset,
        child: pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfReportStyles.subTitle(
                '5. Non-conformités de l\'année passée et taux de mise en conformité',
              ),
              pw.SizedBox(height: 5),
              PdfReportStyles.bodyText(
                'Donnée non disponible — Le présent rapport porte sur la première visite de vérification périodique disposant d\'une check-list numérique structurée pour ce site (Rapport n° $numeroRapportDoc). Aucun rapport antérieur exploitable au même format n\'a été fourni pour extraire le nombre de non-conformités de l\'année passée. Si un rapport antérieur existe, merci de le transmettre : cette section et la comparaison ci-dessous seront complétées automatiquement.',
              ),
            ],
          ),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    // 6. Synthèse de l'analyse statistique
    final paretoK = summary.paretoResult.paretoCategoryCount;
    final paretoCumul = summary.paretoResult.paretoCumulativePercentage;

    widgets.add(
      PageTracker(
        key: 'stat_synthese',
        registry: trackedPages,
        offset: offset,
        child: pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfReportStyles.subTitle('6. Synthèse de l\'analyse statistique'),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3.2),
                  1: pw.FlexColumnWidth(6.8),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'DOMAINE D\'ANALYSE',
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
                          'SYNTHÈSE ET CONCLUSION',
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
                  _buildIndicateurRow(
                    'Périmètre d\'équipement',
                    '$totalEq installations et équipements répertoriés en $activeCats catégories métiers (MT et BT).',
                  ),
                  _buildIndicateurRow(
                    'Niveau de gravité global',
                    '${cStats.critique} non-conformité(s) critique(s) (${cStats.pctCritique.toStringAsFixed(1).replaceAll('.', ',')} %) et ${cStats.majeure} majeure(s) (${cStats.pctMajeure.toStringAsFixed(1).replaceAll('.', ',')} %).',
                  ),
                  _buildIndicateurRow(
                    'Concentration majeure',
                    '${topTwo.label} concentrent ${topTwo.formattedValue}.',
                  ),
                  _buildIndicateurRow(
                    'Levier d\'action Pareto',
                    '$paretoK catégorie(s) de défauts concentrent ${paretoCumul.toStringAsFixed(1).replaceAll('.', ',')} % des écarts relevés.',
                  ),
                  _buildIndicateurRow(
                    'Évolution inter-annuelle',
                    'Donnée non disponible (1ère visite numérique). Nécessite le rapport de l\'année précédente.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return widgets;
  }


  static String _formatConcentrationTitle(String rawTitle) {
    final trimmed = rawTitle.trim();
    if (trimmed.isEmpty) return '3. Concentration du risque';
    if (RegExp(r'^3\.\s*').hasMatch(trimmed)) return trimmed;
    return '3. $trimmed';
  }

  static pw.Widget _buildMultiLineValueWidget(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return pw.SizedBox();

    List<String> items = [];
    if (trimmed.contains('\n')) {
      items = trimmed
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      final parts = trimmed.split('. ');
      if (parts.length > 1) {
        for (var i = 0; i < parts.length; i++) {
          var part = parts[i].trim();
          if (part.isEmpty) continue;
          if (!part.endsWith('.')) part = '$part.';
          items.add(part);
        }
      } else {
        items = [trimmed];
      }
    }

    if (items.length <= 1) {
      return pw.Text(
        trimmed,
        style: pw.TextStyle(font: fontRegular, fontSize: 8),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: items.map((item) {
        final isSubBullet = item.startsWith('*') || item.startsWith('  *');
        final cleanText = item.replaceAll(RegExp(r'^[•\-\*]\s*'), '').trim();
        final leftPadding = isSubBullet ? 12.0 : 0.0;
        final bulletChar = isSubBullet ? '* ' : '• ';
        final bulletColor = isSubBullet ? PdfReportStyles.darkGrey : PdfReportStyles.accentColor;

        return pw.Padding(
          padding: pw.EdgeInsets.only(top: 2, bottom: 2, left: leftPadding),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                bulletChar,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 8,
                  color: bulletColor,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  cleanText,
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 8,
                    color: PdfReportStyles.darkGrey,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.TableRow _buildIndicateurRow(String label, String value) {
    return pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 8,
              color: PdfReportStyles.headerColor,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: _buildMultiLineValueWidget(value),
        ),
      ],
    );
  }

  static pw.Widget _buildTextBulletPoint(String title, String description) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4, left: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$title : ',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 8.5,
                color: PdfReportStyles.headerColor,
              ),
            ),
            pw.TextSpan(
              text: description,
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 8.5,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildBulletItem(String text, {String? boldPrefix}) {
    String prefix = boldPrefix ?? '';
    String body = text;

    if (boldPrefix == null && text.contains(' : ')) {
      final parts = text.split(' : ');
      prefix = '${parts[0]} : ';
      body = parts.sublist(1).join(' : ');
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4, left: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4, right: 6),
            width: 4,
            height: 4,
            decoration: pw.BoxDecoration(
              color: PdfReportStyles.accentColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: prefix.isNotEmpty
                ? pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: prefix,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8.5,
                            color: PdfReportStyles.darkGrey,
                          ),
                        ),
                        pw.TextSpan(
                          text: body,
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 8.5,
                            color: PdfReportStyles.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  )
                : pw.Text(
                    text,
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 8.5,
                      color: PdfReportStyles.darkGrey,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCategoryParetoChartWidget(
    CategoryParetoResult pareto,
  ) {
    if (pareto.items.isEmpty) {
      return PdfReportStyles.bodyText(
        'Aucune non-conformité recensée pour l\'analyse de Pareto par catégorie.',
      );
    }

    final maxVal = pareto.items
        .map((e) => e.nonConformitiesCount)
        .fold(1, (a, b) => a > b ? a : b);

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              'Analyse de Pareto par catégorie d\'équipement (Occurrences & % Cumulé 80%)',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 9,
                color: PdfReportStyles.accentColor,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          // ── Diagramme Visuel Pareto (Barres Horizontales) ──
          pw.Column(
            children: pareto.items.map((item) {
              final isPareto =
                  item.cumulativePercentage <=
                      pareto.paretoCumulativePercentage ||
                  pareto.items.indexOf(item) < pareto.paretoCategoryCount;
              final barColor = isPareto
                  ? PdfColor.fromHex('#B71C1C')
                  : PdfReportStyles.accentColor;
              final barWidthPct = maxVal > 0
                  ? (item.nonConformitiesCount / maxVal)
                  : 0.0;

              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 140,
                      child: pw.Text(
                        item.categoryName,
                        style: pw.TextStyle(
                          font: isPareto ? fontBold : fontRegular,
                          fontSize: 6.5,
                          color: PdfColors.grey900,
                        ),
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: pw.Container(
                        height: 7,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.all(
                            pw.Radius.circular(2),
                          ),
                        ),
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Container(
                          width: (barWidthPct * 260).clamp(2.0, 260.0),
                          height: 7,
                          decoration: pw.BoxDecoration(
                            color: barColor,
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.SizedBox(
                      width: 65,
                      child: pw.Text(
                        '${item.nonConformitiesCount} NC (${item.percentage.toStringAsFixed(1).replaceAll('.', ',')} %)',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 6.5,
                          color: barColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(3.2),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1.4),
              3: pw.FlexColumnWidth(1.2),
              4: pw.FlexColumnWidth(1.4),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'CATÉGORIE',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 7.5,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'ÉQUIP.',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 7,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'NON-CONF.',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 7,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'PART (%)',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 7,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      '% CUMULÉ',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 7,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
              ...pareto.items.map((item) {
                final isPareto =
                    item.cumulativePercentage <=
                        pareto.paretoCumulativePercentage ||
                    pareto.items.indexOf(item) < pareto.paretoCategoryCount;
                final textStyle = isPareto
                    ? pw.TextStyle(
                        font: fontBold,
                        fontSize: 7,
                        color: PdfColor.fromHex('#B71C1C'),
                      )
                    : pw.TextStyle(
                        font: fontRegular,
                        fontSize: 7,
                        color: PdfColors.grey800,
                      );

                return pw.TableRow(
                  decoration: isPareto
                      ? pw.BoxDecoration(color: PdfColor.fromHex('#FEF2F2'))
                      : null,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(item.categoryName, style: textStyle),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        '${item.equipmentCount}',
                        style: textStyle,
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        '${item.nonConformitiesCount}',
                        style: textStyle,
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        '${item.percentage.toStringAsFixed(1).replaceAll('.', ',')} %',
                        style: textStyle,
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        '${item.cumulativePercentage.toStringAsFixed(1).replaceAll('.', ',')} %',
                        style: textStyle,
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total non-conformités analysées : ${pareto.totalNonConformities}',
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 7.5,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                'Seuil Pareto (80 %) atteint sur les ${pareto.paretoCategoryCount} première(s) catégorie(s)',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 7.5,
                  color: PdfColor.fromHex('#B71C1C'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildParetoChartWidget(ParetoAnalysisResult pareto) {
    if (pareto.items.isEmpty) return pw.SizedBox();

    final maxVal = pareto.items
        .map((e) => e.count)
        .fold(1, (a, b) => a > b ? a : b);
    final yMaxLeft = ((maxVal * 1.15) / 5).ceil() * 5 > 0
        ? ((maxVal * 1.15) / 5).ceil() * 5
        : 5;

    const chartHeight = 110.0;
    final itemsCount = pareto.items.length;
    final colorRed = PdfColor.fromHex('#B71C1C');

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              'Analyse de Pareto — $itemsCount principales catégories de défauts (sur ${pareto.totalOccurrences} occurrences)',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 9,
                color: PdfReportStyles.accentColor,
              ),
            ),
          ),
          pw.SizedBox(height: 8),

          // Zone du graphique avec axes Y gauche & droit
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Axe Y gauche (Nombre d'occurrences)
              pw.Container(
                height: chartHeight + 25,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      '$yMaxLeft',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 6.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      '${(yMaxLeft * 0.75).round()}',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 6.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      '${(yMaxLeft * 0.5).round()}',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 6.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      '${(yMaxLeft * 0.25).round()}',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 6.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      '0',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 6.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 18),
                  ],
                ),
              ),
              pw.SizedBox(width: 4),

              // Zone Principale du Graphique (Barres + Courbe Cumulée + Ligne 80%)
              pw.Expanded(
                child: pw.LayoutBuilder(
                  builder: (ctx, constraints) {
                    final width = constraints?.maxWidth ?? 400.0;
                    final colWidth = width / itemsCount;

                    return pw.Column(
                      children: [
                        pw.Container(
                          height: chartHeight,
                          width: width,
                          child: pw.Stack(
                            children: [
                              // 1. Fond du graphique (Bordures)
                              pw.Container(
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(
                                    left: pw.BorderSide(
                                      color: PdfColors.grey400,
                                      width: 0.5,
                                    ),
                                    right: pw.BorderSide(
                                      color: PdfColors.grey400,
                                      width: 0.5,
                                    ),
                                    bottom: pw.BorderSide(
                                      color: PdfColors.grey400,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                              ),

                              // 2. Barres Verticales avec leur valeur au-dessus
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceAround,
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: pareto.items.map((item) {
                                  final barH = yMaxLeft > 0
                                      ? (item.count / yMaxLeft) *
                                            (chartHeight - 15)
                                      : 0.0;

                                  return pw.Column(
                                    mainAxisAlignment: pw.MainAxisAlignment.end,
                                    children: [
                                      pw.Text(
                                        '${item.count}',
                                        style: pw.TextStyle(
                                          font: fontBold,
                                          fontSize: 7,
                                          color: PdfColors.grey900,
                                        ),
                                      ),
                                      pw.SizedBox(height: 2),
                                      pw.Container(
                                        width: (colWidth * 0.55).clamp(
                                          12.0,
                                          24.0,
                                        ),
                                        height: barH < 2 ? 2 : barH,
                                        decoration: pw.BoxDecoration(
                                          color: PdfReportStyles.accentColor,
                                          borderRadius:
                                              const pw.BorderRadius.vertical(
                                                top: pw.Radius.circular(2),
                                              ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),

                              // 3. CustomPaint pour la Ligne Pointillée 80% et la Courbe Rouge % Cumulé
                              pw.CustomPaint(
                                size: PdfPoint(width, chartHeight),
                                painter: (PdfGraphics canvas, PdfPoint size) {
                                  final h = size.y;
                                  final w = size.x;

                                  // Ligne pointillée 80 %
                                  final y80 = h * 0.8;
                                  canvas.setStrokeColor(colorRed);
                                  canvas.setLineWidth(0.8);
                                  canvas.setLineDashPattern([3, 3]);
                                  canvas.drawLine(0, y80, w, y80);
                                  canvas.strokePath();

                                  // Courbe du % cumulé (Ligne continue rouge avec points)
                                  canvas.setLineDashPattern([]);
                                  canvas.setLineWidth(1.2);

                                  final points = <PdfPoint>[];
                                  for (int i = 0; i < itemsCount; i++) {
                                    final item = pareto.items[i];
                                    final cx = (i + 0.5) * (w / itemsCount);
                                    final cy =
                                        (item.cumulativePercentage / 100.0) * h;
                                    points.add(PdfPoint(cx, cy));
                                  }

                                  // Tracer les segments de la courbe
                                  if (points.isNotEmpty) {
                                    canvas.setStrokeColor(colorRed);
                                    for (
                                      int i = 0;
                                      i < points.length - 1;
                                      i++
                                    ) {
                                      canvas.drawLine(
                                        points[i].x,
                                        points[i].y,
                                        points[i + 1].x,
                                        points[i + 1].y,
                                      );
                                    }
                                    canvas.strokePath();

                                    // Tracer les points (cercles rouges)
                                    canvas.setFillColor(colorRed);
                                    for (final p in points) {
                                      canvas.drawEllipse(p.x, p.y, 2.0, 2.0);
                                      canvas.fillPath();
                                    }
                                  }
                                },
                              ),

                              // Label 80% sur la ligne pointillée
                              pw.Positioned(
                                right: 4,
                                top: chartHeight * 0.2 - 9,
                                child: pw.Text(
                                  '80 %',
                                  style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 7,
                                    color: colorRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        pw.SizedBox(height: 4),

                        // Libellés sous chaque barre (Axe X)
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: pareto.items.map((item) {
                            return pw.SizedBox(
                              width: colWidth,
                              child: pw.Text(
                                _shortVerificationPointName(item.title),
                                style: pw.TextStyle(
                                  font: fontRegular,
                                  fontSize: 5.8,
                                  color: PdfColors.grey800,
                                ),
                                textAlign: pw.TextAlign.center,
                                maxLines: 2,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ),

              pw.SizedBox(width: 4),

              // Axe Y droit (% cumulé)
              pw.Container(
                height: chartHeight + 25,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '100',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 6.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      '80',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 6.5,
                        color: colorRed,
                      ),
                    ),
                    pw.Text(
                      '60',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 6.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      '40',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 6.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      '20',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 6.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      '0',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 6.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  GRAPHIQUES ET ANALYSES STATISTIQUES AVANCÉES
  // ──────────────────────────────────────────────────────────────

  static pw.Widget _buildTopDefectsHorizontalChart(
    List<TopDefectItem> topItems,
  ) {
    if (topItems.isEmpty) return pw.SizedBox();

    final maxVal = topItems.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final xMax = ((maxVal * 1.2) / 10).ceil() * 10 > 0
        ? ((maxVal * 1.2) / 10).ceil() * 10
        : 10;
    final xMid = (xMax / 2).round();

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              'Statistique par type de d\u00e9faut (10 principales cat\u00e9gories)',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfReportStyles.headerColor,
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Column(
            children: topItems.map((item) {
              final barWidthPct = xMax > 0 ? (item.count / xMax) : 0.0;
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 170,
                      child: pw.Text(
                        item.title,
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 7.5,
                          color: PdfColors.grey900,
                        ),
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Container(
                        height: 10,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.all(
                            pw.Radius.circular(2),
                          ),
                        ),
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Container(
                          width: (barWidthPct * 260).clamp(2.0, 260.0),
                          height: 10,
                          decoration: pw.BoxDecoration(
                            color: PdfReportStyles.headerColor,
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.SizedBox(
                      width: 25,
                      child: pw.Text(
                        '${item.count}',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 8,
                          color: PdfReportStyles.headerColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          pw.SizedBox(height: 6),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 178, right: 30),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '0',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  '$xMid',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  '$xMax',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          pw.Center(
            child: pw.Text(
              'Nombre d\'occurrences',
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 7.5,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTensionDomainSection(
    TensionDomainStats stats, [
    int? index,
  ]) {
    final mtPctStr = stats.mtPct.toStringAsFixed(1).replaceAll('.', ',');
    final btPctStr = stats.btPct.toStringAsFixed(1).replaceAll('.', ',');

    return pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PdfReportStyles.subTitle(
            '${index != null ? "$index. " : ""}Répartition des non-conformités par domaine de tension',
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            height: 135,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              color: PdfColors.white,
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Répartition des non-conformités par domaine de tension (Total : ${stats.totalCount} NC)',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 9,
                    color: PdfReportStyles.accentColor,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Expanded(
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            '${stats.mtCount} ($mtPctStr %)',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 8.5,
                              color: PdfReportStyles.accentColor,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Container(
                            width: 55,
                            height: stats.totalCount > 0
                                ? (stats.mtCount / stats.totalCount) * 45 + 4
                                : 4,
                            decoration: pw.BoxDecoration(
                              color: PdfReportStyles.accentColor,
                              borderRadius: const pw.BorderRadius.vertical(
                                top: pw.Radius.circular(3),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Moyenne Tension\n(MT/HTA)',
                            style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 7,
                              color: PdfColors.grey800,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                      pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            '${stats.btCount} ($btPctStr %)',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 8.5,
                              color: PdfReportStyles.accentColor,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Container(
                            width: 55,
                            height: stats.totalCount > 0
                                ? (stats.btCount / stats.totalCount) * 45 + 4
                                : 4,
                            decoration: pw.BoxDecoration(
                              color: PdfReportStyles.accentColor,
                              borderRadius: const pw.BorderRadius.vertical(
                                top: pw.Radius.circular(3),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Basse Tension\n(BT)',
                            style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 7,
                              color: PdfColors.grey800,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          PdfReportStyles.bodyText(
            'L\'analyse par domaine de tension permet d\'isoler les risques spécifiques aux installations Moyenne Tension (MT/HTA) et Basse Tension (BT). Le domaine Basse Tension regroupe généralement la majorité des équipements de distribution finale (armoires, coffrets, TGBT), tandis que la Moyenne Tension concentre les équipements d\'alimentation principale à forts enjeux de sécurité électrique.',
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCrossCategorySection(
    List<CategoryCrossItem> items,
    String crossText,
    CriticalityStats cStats, [
    int? index,
  ]) {
    final totalNC = items.fold<int>(
      0,
      (sum, e) => sum + e.nonConformitiesCount,
    );
    final totalCritique = items.fold<int>(0, (sum, e) => sum + e.critiqueCount);
    final totalMajeure = items.fold<int>(0, (sum, e) => sum + e.majeureCount);
    final totalMineure = items.fold<int>(0, (sum, e) => sum + e.mineureCount);
    final totalEquipements = items.fold<int>(
      0,
      (sum, e) => sum + e.equipmentCount,
    );
    final maxVal = items
        .map((e) => e.nonConformitiesCount)
        .fold(1, (a, b) => a > b ? a : b);

    final colorCritique = PdfColor.fromHex('#DC2626');
    final colorMajeure = PdfColor.fromHex('#EA580C');
    final colorMineure = PdfColor.fromHex('#D97706');

    final bgCritiqueHeader = PdfColor.fromHex('#DC2626');
    final bgMajeureHeader = PdfColor.fromHex('#EA580C');
    final bgMineureHeader = PdfColor.fromHex('#D97706');

    final bgCritiqueCell = PdfColor.fromHex('#FEF2F2');
    final bgMajeureCell = PdfColor.fromHex('#FFF7ED');
    final bgMineureCell = PdfColor.fromHex('#FEF3C7');

    final textCritique = PdfColor.fromHex('#B71C1C');
    final textMajeure = PdfColor.fromHex('#C2410C');
    final textMineure = PdfColor.fromHex('#B45309');

    final comments = crossText
        .split(RegExp(r'\.(?=\s|[A-Z]|$)'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => s.endsWith('.') ? s : '$s.')
        .toList();

    // 2.2 Calculations pour la criticité
    final critique = cStats.critique;
    final majeure = cStats.majeure;
    final mineure = cStats.mineure;
    final total = cStats.total;
    final pctCritique = cStats.pctCritique;
    final pctMajeure = cStats.pctMajeure;
    final pctMineure = cStats.pctMineure;

    final pctCritStr = pctCritique.toStringAsFixed(1).replaceAll('.', ',');
    final pctMajStr = pctMajeure.toStringAsFixed(1).replaceAll('.', ',');
    final pctMinStr = pctMineure.toStringAsFixed(1).replaceAll('.', ',');

    final totalCritMaj = critique + majeure;
    final pctCritMaj = total > 0 ? ((totalCritMaj / total) * 100.0) : 0.0;
    final pctCritMajStr = pctCritMaj.toStringAsFixed(1).replaceAll('.', ',');

    String textRatioSeverite;
    if (mineure > 0) {
      final ratioVal = (critique / mineure)
          .toStringAsFixed(1)
          .replaceAll('.', ',');
      textRatioSeverite =
          'L\'analyse recense $critique non-conformité(s) de niveau Critique ($pctCritStr %) pour $mineure non-conformité(s) de niveau Mineur ($pctMinStr %), soit un ratio de $ratioVal NC critique(s) pour 1 NC mineure. Ce rapport traduit la sévérité relative des anomalies constatées sur l\'installation.';
    } else if (critique > 0) {
      textRatioSeverite =
          'L\'analyse recense $critique non-conformité(s) de niveau Critique ($pctCritStr %) et 0 non-conformité mineure (0,0 %). L\'absence de défauts mineurs atteste que l\'intégralité des défaillances relevées présente un niveau de sévérité élevé.';
    } else {
      textRatioSeverite =
          'L\'analyse recense 0 non-conformité de niveau Critique (0,0 %) et $mineure non-conformité(s) de niveau Mineur ($pctMinStr %). Aucun défaut à sévérité critique n\'a été constaté.';
    }

    final textNiveauRisqueDominant =
        'Les non-conformités à fort impact (niveaux Critique et Majeur) cumulent $totalCritMaj constat(s) sur un total de $total, soit $pctCritMajStr % de l\'ensemble des défaillances de la mission ($critique critique(s), soit $pctCritStr % + $majeure majeure(s), soit $pctMajStr %). Ce regroupement confirme la prédominance nette des risques majeurs pour la sécurité des personnes et la continuité d\'exploitation.';

    String textSignalGraviteGlobal;
    if (pctCritMaj >= 70.0) {
      textSignalGraviteGlobal =
          'La forte concentration des écarts sur les niveaux de gravité Critique et Majeur ($pctCritMajStr %) constitue un signal de risque très élevé. Il est vivement recommandé d\'engager en priorité les interventions de levée de réserves sur les $critique équipement(s)/point(s) critique(s) et les $majeure élément(s) majeur(s) afin de prévenir tout incident électrique ou dommage matériel.';
    } else if (pctCritMaj >= 40.0) {
      textSignalGraviteGlobal =
          'La répartition des défauts montre un niveau de risque modéré à élevé ($pctCritMajStr % d\'écarts critiques et majeurs). Les travaux de remise en conformité doivent prioriser les $critique constat(s) critique(s), tout en intégrant les $majeure anomalie(s) majeure(s) dans le plan de maintenance à moyen terme.';
    } else {
      textSignalGraviteGlobal =
          'La majorité des non-conformités identifiées relève de niveaux de gravité mineurs ou modérés. Le plan d\'action peut s\'inscrire dans le cadre des opérations de maintenance préventive et d\'entretien courant de l\'établissement.';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Groupe Titre 2 + Entête 2.1 + Diagramme en pw.Inseparable anti-titre orphelin
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfReportStyles.subTitle(
                '${index != null ? "$index. " : ""}Analyse croisée par catégories / équipement',
              ),
              pw.SizedBox(height: 6),
              PdfReportStyles.subTitle(
                '2.1 Non-conformités par catégorie d\'installation / d\'équipement',
              ),
              pw.SizedBox(height: 4),
              PdfReportStyles.bodyText(
                'En croisant chaque catégorie ci-dessus avec les non-conformités relevées, la répartition et la densité moyenne par équipement se présentent comme suit :',
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                height: 135,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                  color: PdfColors.white,
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Non-conformités par catégorie d\'installation / d\'équipement',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 9,
                            color: PdfReportStyles.accentColor,
                          ),
                        ),
                        pw.Row(
                          children: [
                            pw.Container(
                              width: 8,
                              height: 8,
                              color: colorCritique,
                            ),
                            pw.SizedBox(width: 3),
                            pw.Text(
                              'Critique',
                              style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 6.5,
                              ),
                            ),
                            pw.SizedBox(width: 6),
                            pw.Container(
                              width: 8,
                              height: 8,
                              color: colorMajeure,
                            ),
                            pw.SizedBox(width: 3),
                            pw.Text(
                              'Majeure',
                              style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 6.5,
                              ),
                            ),
                            pw.SizedBox(width: 6),
                            pw.Container(
                              width: 8,
                              height: 8,
                              color: colorMineure,
                            ),
                            pw.SizedBox(width: 3),
                            pw.Text(
                              'Mineure',
                              style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 6.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      height: 100,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: items.map((item) {
                          final hCrit = maxVal > 0
                              ? (item.critiqueCount / maxVal) * 65
                              : 0.0;
                          final hMaj = maxVal > 0
                              ? (item.majeureCount / maxVal) * 65
                              : 0.0;
                          final hMin = maxVal > 0
                              ? (item.mineureCount / maxVal) * 65
                              : 0.0;

                          return pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text(
                                '${item.nonConformitiesCount}',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 7,
                                  color: PdfReportStyles.accentColor,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Container(
                                width: 22,
                                child: pw.Column(
                                  children: [
                                    if (hCrit > 0)
                                      pw.Container(
                                        height: hCrit < 2 ? 2 : hCrit,
                                        color: colorCritique,
                                      ),
                                    if (hMaj > 0)
                                      pw.Container(
                                        height: hMaj < 2 ? 2 : hMaj,
                                        color: colorMajeure,
                                      ),
                                    if (hMin > 0)
                                      pw.Container(
                                        height: hMin < 2 ? 2 : hMin,
                                        color: colorMineure,
                                      ),
                                    if (item.nonConformitiesCount == 0)
                                      pw.Container(
                                        height: 2,
                                        color: PdfColors.grey300,
                                      ),
                                  ],
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.SizedBox(
                                width: 44,
                                height: 22,
                                child: pw.Align(
                                  alignment: pw.Alignment.topCenter,
                                  child: pw.Text(
                                    _shortCatName(item.categoryName),
                                    style: pw.TextStyle(
                                      font: fontRegular,
                                      fontSize: 6,
                                      color: PdfColors.grey800,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.6),
            1: pw.FlexColumnWidth(0.8),
            2: pw.FlexColumnWidth(0.8),
            3: pw.FlexColumnWidth(0.8),
            4: pw.FlexColumnWidth(0.8),
            5: pw.FlexColumnWidth(0.8),
            6: pw.FlexColumnWidth(1.2),
            7: pw.FlexColumnWidth(1.3),
            8: pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Container(
                  color: PdfReportStyles.accentColor,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    'Catégorie',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 7,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.Container(
                  color: PdfReportStyles.accentColor,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    'Équip.',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  color: PdfReportStyles.accentColor,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    'NC',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  color: bgCritiqueHeader,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    'Crit.',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  color: bgMajeureHeader,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    'Maj.',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  color: bgMineureHeader,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    'Min.',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  color: PdfReportStyles.accentColor,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    '% du total NC',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  color: PdfReportStyles.accentColor,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    'Taux crit. / NC',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  color: PdfReportStyles.accentColor,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    'Densité NC/équip.',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
            for (int i = 0; i < items.length; i++) ...[
              () {
                final item = items[i];
                final pctTotalNC = totalNC > 0
                    ? (item.nonConformitiesCount / totalNC * 100)
                    : 0.0;
                final tauxCrit = item.nonConformitiesCount > 0
                    ? (item.critiqueCount / item.nonConformitiesCount * 100)
                    : 0.0;
                final densite = item.equipmentCount > 0
                    ? (item.nonConformitiesCount / item.equipmentCount)
                    : 0.0;

                final rowBg = i % 2 == 1 ? PdfReportStyles.tableRowAlt : PdfColors.white;

                return pw.TableRow(
                  children: [
                    pw.Container(
                      color: rowBg,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 3,
                      ),
                      child: pw.Text(
                        item.categoryName,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 6.5,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                    pw.Container(
                      color: rowBg,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 3,
                      ),
                      child: pw.Text(
                        '${item.equipmentCount}',
                        style: pw.TextStyle(font: fontRegular, fontSize: 6.5),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      color: rowBg,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 3,
                      ),
                      child: pw.Text(
                        '${item.nonConformitiesCount}',
                        style: pw.TextStyle(font: fontBold, fontSize: 6.5),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),

                    pw.Container(
                      color: item.critiqueCount > 0 ? bgCritiqueCell : rowBg,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 3,
                      ),
                      child: pw.Text(
                        '${item.critiqueCount}',
                        style: pw.TextStyle(
                          font: item.critiqueCount > 0
                              ? fontBold
                              : fontRegular,
                          fontSize: 6.5,
                          color: item.critiqueCount > 0
                              ? textCritique
                              : PdfColors.grey700,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),

                    pw.Container(
                      color: item.majeureCount > 0 ? bgMajeureCell : rowBg,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 3,
                      ),
                      child: pw.Text(
                        '${item.majeureCount}',
                        style: pw.TextStyle(
                          font: item.majeureCount > 0
                              ? fontBold
                              : fontRegular,
                          fontSize: 6.5,
                          color: item.majeureCount > 0
                              ? textMajeure
                              : PdfColors.grey700,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),

                    pw.Container(
                      color: item.mineureCount > 0 ? bgMineureCell : rowBg,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 3,
                      ),
                      child: pw.Text(
                        '${item.mineureCount}',
                        style: pw.TextStyle(
                          font: item.mineureCount > 0
                              ? fontBold
                              : fontRegular,
                          fontSize: 6.5,
                          color: item.mineureCount > 0
                              ? textMineure
                              : PdfColors.grey700,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),

                    pw.Container(
                      color: rowBg,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 3,
                      ),
                      child: pw.Text(
                        '${pctTotalNC.toStringAsFixed(1).replaceAll('.', ',')} %',
                        style: pw.TextStyle(font: fontRegular, fontSize: 6.5),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      color: rowBg,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 3,
                      ),
                      child: pw.Text(
                        item.nonConformitiesCount > 0
                            ? '${tauxCrit.toStringAsFixed(1).replaceAll('.', ',')} %'
                            : '—',
                        style: pw.TextStyle(font: fontRegular, fontSize: 6.5),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      color: rowBg,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 3,
                      ),
                      child: pw.Text(
                        item.equipmentCount > 0
                            ? densite.toStringAsFixed(1).replaceAll('.', ',')
                            : '0,0',
                        style: pw.TextStyle(font: fontRegular, fontSize: 6.5),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                );
              }(),
            ],
            pw.TableRow(
              children: [
                pw.Container(
                  color: PdfReportStyles.lightBlue,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 7,
                      color: PdfReportStyles.accentColor,
                    ),
                  ),
                ),
                pw.Container(
                  color: PdfReportStyles.lightBlue,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    '$totalEquipements',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: PdfReportStyles.accentColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  color: PdfReportStyles.lightBlue,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    '$totalNC',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: PdfReportStyles.accentColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  color: PdfColor.fromHex('#FEE2E2'),
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    '$totalCritique',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: textCritique,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  color: PdfColor.fromHex('#FFEDD5'),
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    '$totalMajeure',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: textMajeure,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  color: PdfColor.fromHex('#FEF3C7'),
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    '$totalMineure',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: textMineure,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  color: PdfReportStyles.lightBlue,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    '100 %',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: PdfReportStyles.accentColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  color: PdfReportStyles.lightBlue,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    totalNC > 0
                        ? '${(totalCritique / totalNC * 100).toStringAsFixed(1).replaceAll('.', ',')} %'
                        : '—',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: PdfReportStyles.accentColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  color: PdfReportStyles.lightBlue,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    totalEquipements > 0
                        ? (totalNC / totalEquipements)
                              .toStringAsFixed(1)
                              .replaceAll('.', ',')
                        : '0,0',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 6.8,
                      color: PdfReportStyles.accentColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 2),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Glossaire des abréviations et termes du tableau :',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 8.5,
                  color: PdfReportStyles.accentColor,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Table(
                border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.2),
                  1: pw.FlexColumnWidth(3.8),
                  2: pw.FlexColumnWidth(1.2),
                  3: pw.FlexColumnWidth(3.8),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfReportStyles.tableRowAlt),
                    children: [
                      _buildGlossaireCell('Équip.', true),
                      _buildGlossaireCell(
                        'Nombre d\'équipements répertoriés',
                        false,
                      ),
                      _buildGlossaireCell('Maj.', true),
                      _buildGlossaireCell(
                        'Non-conformités majeures (orange)',
                        false,
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildGlossaireCell('NC', true),
                      _buildGlossaireCell(
                        'Nombre total de non-conformités',
                        false,
                      ),
                      _buildGlossaireCell('Min.', true),
                      _buildGlossaireCell(
                        'Non-conformités mineures (jaune)',
                        false,
                      ),
                    ],
                  ),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfReportStyles.tableRowAlt),
                    children: [
                      _buildGlossaireCell('Crit.', true),
                      _buildGlossaireCell(
                        'Non-conformités critiques (rouge)',
                        false,
                      ),
                      _buildGlossaireCell('Taux crit.', true),
                      _buildGlossaireCell(
                        'Ratio NC Critiques / NC Totales (%)',
                        false,
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildGlossaireCell('Densité', true),
                      _buildGlossaireCell(
                        'Ratio NC par équipement (NC / Équip.)',
                        false,
                      ),
                      _buildGlossaireCell('', true),
                      _buildGlossaireCell('', false),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Constatations et commentaires d\'analyse :',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 8.5,
                color: PdfReportStyles.accentColor,
              ),
            ),
            pw.SizedBox(height: 4),
            ...comments.map((comment) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 3,
                      height: 3,
                      margin: const pw.EdgeInsets.only(top: 3, right: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfReportStyles.accentColor,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        comment,
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 7.5,
                          color: PdfColors.grey900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
        pw.SizedBox(height: 10),

        // 2.2 Analyse de la criticité des non-conformités
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfReportStyles.subTitle('2.2 Analyse de la criticité des non-conformités'),
              pw.SizedBox(height: 4),
              PdfReportStyles.bodyText(
                'Distribution des non-conformités selon les 3 niveaux de gravité réglementaires KES :',
              ),
              pw.SizedBox(height: 6),
              _buildBarChart(critique, majeure, mineure),
              pw.SizedBox(height: 8),
              _buildTextBulletPoint('Ratio de sévérité', textRatioSeverite),
              pw.SizedBox(height: 4),
              _buildTextBulletPoint(
                'Niveau de risque dominant',
                textNiveauRisqueDominant,
              ),
              pw.SizedBox(height: 4),
              _buildTextBulletPoint(
                'Signal de gravité global',
                textSignalGraviteGlobal,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        // 2.3 Analyse comparative avec la visite précédente
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfReportStyles.subTitle('2.3 Analyse comparative avec la visite précédente'),
              pw.SizedBox(height: 4),
              _buildBulletItem(
                'Nouveaux équipements (coffret / armoire / TGBT) : Donnée non disponible. Le nombre d\'équipements nouvellement installés depuis la dernière visite nécessite une comparaison directe avec l\'inventaire du rapport précédent.',
              ),
              pw.SizedBox(height: 4),
              _buildBulletItem(
                'Équipements supprimés (coffret / armoire / TGBT) : Donnée non disponible. Le nombre d\'équipements retirés de l\'installation depuis la dernière visite nécessite également une comparaison avec le rapport précédent.',
              ),
              pw.SizedBox(height: 4),
              _buildBulletItem(
                'Rapport précédent nécessaire : Merci de transmettre le rapport de vérification périodique de l\'année précédente pour ce site (ou son export de check-list). Dès réception, l\'historique d\'évolution sera calculé automatiquement.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _shortCatName(String cat) {
    if (cat.contains('Moyenne Tension')) return 'Local MT';
    if (cat.contains('Cellules')) return 'Cellule MT';
    if (cat.contains('Transformateurs')) return 'Transfo MT/BT';
    if (cat.contains('Groupe')) return 'Local GE';
    if (cat.contains('Basse Tension')) return 'Local BT';
    if (cat.contains('TGBT')) return 'TGBT';
    if (cat.contains('Armoires')) return 'Armoire';
    if (cat.contains('Coffrets')) return 'Coffret';
    if (cat.contains('Inverseurs')) return 'Inverseur';
    return cat;
  }

  static pw.Widget _buildGlossaireCell(String text, bool isKey) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isKey ? fontBold : fontRegular,
          fontSize: 6.8,
          color: isKey ? PdfReportStyles.accentColor : PdfColors.grey900,
        ),
      ),
    );
  }

  static String _shortVerificationPointName(String title) {
    final s = title.trim();
    final lower = s.toLowerCase();
    if (lower.contains('contacts indirects') ||
        lower.contains('contact indirect'))
      return 'contact\nindirect';
    if (lower.contains('câblage') || lower.contains('cablage'))
      return 'Câblage';
    if (lower.contains('identification')) return 'Identification\ncircuits';
    if (lower.contains('dispositif') || lower.contains('protection'))
      return 'Dispositifs de\nprotection';
    if (lower.contains('répartiteur') || lower.contains('repartiteur'))
      return 'Répartiteur de\ncircuit';
    if (lower.contains('continuité') || lower.contains('pe'))
      return 'Continuité PE';
    if (lower.contains('répartition') || lower.contains('repartition'))
      return 'Répartition des\ncircuits';
    if (lower.contains('emplacement') || lower.contains('dégagement'))
      return 'Emplacement /\ndégagement';
    if (lower.contains('code couleur') || lower.contains('couleur'))
      return 'Code couleur\ncâbles';
    if (lower.contains('état') ||
        lower.contains('armoire') ||
        lower.contains('coffret'))
      return 'État coffret /\narmoire / TGBT';

    if (s.length > 20) {
      final parts = s.split(' ');
      if (parts.length > 2) {
        final mid = parts.length ~/ 2;
        return '${parts.sublist(0, mid).join(" ")}\n${parts.sublist(mid).join(" ")}';
      }
    }
    return s;
  }

  // ──────────────────────────────────────────────────────────────
  //  RENSEIGNEMENTS GENERAUX
  // ──────────────────────────────────────────────────────────────



  static pw.Widget _buildBarChart(int critique, int majeure, int mineure) {
    final total = critique + majeure + mineure;
    final pctCritique = total > 0 ? (critique / total) * 100.0 : 0.0;
    final pctMajeure = total > 0 ? (majeure / total) * 100.0 : 0.0;
    final pctMineure = total > 0 ? (mineure / total) * 100.0 : 0.0;

    final pctCritStr = pctCritique.toStringAsFixed(1).replaceAll('.', ',');
    final pctMajStr = pctMajeure.toStringAsFixed(1).replaceAll('.', ',');
    final pctMinStr = pctMineure.toStringAsFixed(1).replaceAll('.', ',');

    final maxVal = [
      critique,
      majeure,
      mineure,
      1,
    ].reduce((a, b) => a > b ? a : b);
    final yMax = ((maxVal * 1.25) / 10).ceil() * 10 > 0
        ? ((maxVal * 1.25) / 10).ceil() * 10
        : 10;
    final yMid = (yMax / 2).round();

    const double chartHeight = 100.0;
    const double barWidth = 54.0;

    double calcBarHeight(int val) {
      if (yMax == 0) return 0;
      final h = (val / yMax) * chartHeight;
      return h < 2 && val > 0 ? 2 : h;
    }

    final hCritique = calcBarHeight(critique);
    final hMajeure = calcBarHeight(majeure);
    final hMineure = calcBarHeight(mineure);

    final colorCritique = PdfColor.fromHex('#DC2626');
    final colorMajeure = PdfColor.fromHex('#EA580C');
    final colorMineure = PdfColor.fromHex('#16A34A');

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: pw.Column(
        children: [
          pw.Text(
            'Répartition des non-conformités par criticité',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfReportStyles.accentColor,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Axe Y - valeurs
              pw.Container(
                height: chartHeight + 20,
                margin: const pw.EdgeInsets.only(right: 6),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      '$yMax',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      '$yMid',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      '0',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),

              // Ligne d'axe Y
              pw.Container(
                height: chartHeight + 2,
                width: 0.8,
                color: PdfColors.grey400,
              ),
              pw.SizedBox(width: 20),

              // Barres (Critique, Majeure, Mineure)
              pw.Container(
                height: chartHeight + 28,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Critique
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          '$critique ($pctCritStr %)',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: barWidth,
                          height: hCritique,
                          decoration: pw.BoxDecoration(
                            color: colorCritique,
                            borderRadius: const pw.BorderRadius.vertical(
                              top: pw.Radius.circular(2),
                            ),
                          ),
                        ),
                        pw.Container(
                          height: 0.8,
                          width: barWidth + 14,
                          color: PdfColors.grey600,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Critique',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8.5,
                            color: PdfReportStyles.accentColor,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(width: 24),

                    // Majeure
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          '$majeure ($pctMajStr %)',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: barWidth,
                          height: hMajeure,
                          decoration: pw.BoxDecoration(
                            color: colorMajeure,
                            borderRadius: const pw.BorderRadius.vertical(
                              top: pw.Radius.circular(2),
                            ),
                          ),
                        ),
                        pw.Container(
                          height: 0.8,
                          width: barWidth + 14,
                          color: PdfColors.grey600,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Majeure',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8.5,
                            color: PdfReportStyles.accentColor,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(width: 24),

                    // Mineure
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          '$mineure ($pctMinStr %)',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: barWidth,
                          height: hMineure,
                          decoration: pw.BoxDecoration(
                            color: colorMineure,
                            borderRadius: const pw.BorderRadius.vertical(
                              top: pw.Radius.circular(2),
                            ),
                          ),
                        ),
                        pw.Container(
                          height: 0.8,
                          width: barWidth + 14,
                          color: PdfColors.grey600,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Mineure',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8.5,
                            color: PdfReportStyles.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}
