import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/statistics/mission_statistics_collector.dart';
import 'package:inspec_app/services/statistics/mission_statistics.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/builders/pdf_statistics_charts.dart';
import 'package:inspec_app/services/statistics/statistical_synthesis_engine.dart';

/// Builder responsable de l'Analyse Statistique (indicateurs clés, diagramme Pareto, histogrammes, tableaux de synthèse).
/// Restitution 100 % conforme au document de référence KES avec calculs dynamiques déterministes.
class PdfStatisticsBuilder {
  static pw.Font? _fontRegular;
  static pw.Font? _fontBold;

  static pw.Font get fontRegular => _fontRegular ?? PdfReportStyles.fontRegular;
  static set fontRegular(pw.Font font) {
    _fontRegular = font;
    PdfReportStyles.fontRegular = font;
  }

  static pw.Font get fontBold => _fontBold ?? PdfReportStyles.fontBold;
  static set fontBold(pw.Font font) {
    _fontBold = font;
    PdfReportStyles.fontBold = font;
  }

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
    final summary = MissionStatisticsCollector.collectSummary(mission.id);
    return buildStatisticsWidgets(
      mission: mission,
      summary: summary,
      technical: summary.technical,
      trackedPages: trackedPages,
      numeroRapportDoc: numeroRapportDoc,
      offset: offset,
    );
  }

  static List<pw.Widget> buildStatisticsWidgets({
    required Mission mission,
    required MissionStatisticsSummary summary,
    required TechnicalEnrichmentResult technical,
    required Map<String, int> trackedPages,
    String numeroRapportDoc = '',
    int offset = 0,
  }) {
    final widgets = <pw.Widget>[];
    final domainStats = summary.tensionDomainStats;

    // Entête de section principale
    widgets.add(
      PageTracker(
        key: 'analyse_statistique',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.sectionBox('ANALYSE STATISTIQUE'),
      ),
    );
    widgets.add(pw.SizedBox(height: 10));

    // ── 1. Répartition des non-conformités par domaine de tension ──
    widgets.add(
      PageTracker(
        key: 'stat_tension',
        registry: trackedPages,
        offset: offset,
        child: _buildTensionDomainSection(domainStats, technical, 1),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    // ── 2. Non-conformités croisées par catégorie d'installation ──
    widgets.add(
      PageTracker(
        key: 'stat_croisee',
        registry: trackedPages,
        offset: offset,
        child: _buildCrossAuditIntroText(),
      ),
    );
    widgets.add(pw.SizedBox(height: 6));

    // 2.1 Moyenne tension
    widgets.add(
      PageTracker(
        key: 'stat_croisee_mt',
        registry: trackedPages,
        offset: offset,
        child: pw.Text(
          '2.1. Moyenne tension',
          style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      _buildCrossAuditTable(
        technical.mtCategoriesCrossRows,
        technical.mtTotalCrossRow,
        'Moyenne Tension (MT)',
      ),
    );
    widgets.add(pw.SizedBox(height: 6));

    // Diagramme MT : les catégories MT du tableau
    widgets.add(
      PdfStatisticsCharts.buildMtCategoryStackedBarChart(
        technical.mtCategoriesCrossRows,
      ),
    );
    widgets.add(pw.SizedBox(height: 6));
    widgets.add(
      _buildMtCrossAuditCommentary(
        technical.mtCategoriesCrossRows,
        technical.mtTotalCrossRow,
      ),
    );
    widgets.add(pw.SizedBox(height: 10));

    // Saut de page systématique pour regrouper 2.2 Basse tension et son tableau
    widgets.add(pw.NewPage());

    // 2.2 Basse tension
    widgets.add(
      PageTracker(
        key: 'stat_croisee_bt',
        registry: trackedPages,
        offset: offset,
        child: pw.Text(
          '2.2. Basse tension',
          style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      _buildCrossAuditTable(
        technical.btCategoriesCrossRows,
        technical.btTotalCrossRow,
        'Basse Tension (BT)',
      ),
    );
    widgets.add(pw.SizedBox(height: 6));

    // Diagramme BT : les 7 catégories du tableau BT
    widgets.add(
      PdfStatisticsCharts.buildBtCategoryStackedBarChart(
        technical.btCategoriesCrossRows,
      ),
    );
    widgets.add(pw.SizedBox(height: 6));
    widgets.add(
      _buildBtCrossAuditCommentary(
        technical.btCategoriesCrossRows,
        technical.btTotalCrossRow,
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    // ── 3. Sécurité et traçabilité des tableaux Basse Tension ──
    widgets.add(pw.NewPage());
    widgets.add(
      PageTracker(
        key: 'stat_securite_bt',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfReportStyles.subTitle('3. Sécurité et traçabilité des tableaux Basse Tension'),
            pw.SizedBox(height: 4),
            PdfReportStyles.bodyText(
              'Synthèse technique portant sur les 3 prérequis normatifs critiques de la distribution Basse Tension (NF C 15-100) : identification des sources d\'alimentation, présence d\'un organe de coupure générale dédié en tête, et protection contre les surtensions transitoires (parafoudres) :',
            ),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 6));

    // 3.1 Identification des sources d'alimentation
    widgets.add(
      PageTracker(
        key: 'stat_sources_alim',
        registry: trackedPages,
        offset: offset,
        child: pw.Text(
          '3.1. Identification des sources d\'alimentation',
          style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(_buildBtSourceTable(technical));
    widgets.add(pw.SizedBox(height: 6));
    widgets.add(PdfStatisticsCharts.buildBtSourceStackedBarChart(technical));
    widgets.add(pw.NewPage());

    // 3.2 Présence organe de coupure en tête d'installation
    widgets.add(
      PageTracker(
        key: 'stat_coupure_tete',
        registry: trackedPages,
        offset: offset,
        child: pw.Text(
          '3.2. Présence organe de coupure en tête d\'installation',
          style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(_buildBtCoupureTable(technical));
    widgets.add(pw.SizedBox(height: 6));
    widgets.add(PdfStatisticsCharts.buildDisjoncteurTeteDonutChart(technical));
    widgets.add(pw.SizedBox(height: 10));

    // 3.3 Présence parafoudre
    widgets.add(
      PageTracker(
        key: 'stat_parafoudres',
        registry: trackedPages,
        offset: offset,
        child: pw.Text(
          '3.3. Présence parafoudre',
          style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(_buildBtParafoudreTable(technical));
    widgets.add(pw.SizedBox(height: 6));
    widgets.add(PdfStatisticsCharts.buildBtParafoudreStackedBarChart(technical));
    widgets.add(pw.SizedBox(height: 12));

    // Saut de page systématique pour regrouper le titre 4, son texte et le diagramme de Pareto
    widgets.add(pw.NewPage());

    // ── 4. Statistique par type de défaut : analyse de Pareto
    final totalOccur = summary.totalNC > 0
        ? summary.totalNC
        : (summary.paretoResult.totalOccurrences > 0
            ? summary.paretoResult.totalOccurrences
            : summary.criticalityStats.total);
    final top10Items = summary.paretoResult.items.take(10).toList();
    final top10Count = top10Items.isNotEmpty ? top10Items.length : 10;
    final top10Sum = top10Items.fold<int>(0, (sum, e) => sum + e.count);
    final top10Pct = totalOccur > 0 && top10Sum > 0
        ? (top10Sum / totalOccur * 100)
        : (summary.paretoResult.top10Percentage > 0 ? summary.paretoResult.top10Percentage : 0.0);
    final top10PctStr = top10Pct.toStringAsFixed(1).replaceAll('.', ',');

    final paretoP1 =
        'Les $totalOccur occurrences de non-conformités ont été classées par fréquence décroissante. Les $top10Count catégories principales concentrent $top10Sum occurrences, soit $top10PctStr % du total :';

    widgets.add(
      PageTracker(
        key: 'stat_pareto',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfReportStyles.subTitle(
              '4. Statistique par type de défaut : analyse de Pareto',
            ),
            pw.SizedBox(height: 5),
            PdfReportStyles.bodyText(paretoP1),
            pw.SizedBox(height: 8),
            // Diagramme de Pareto double axe (occurrences et % cumulé)
            PdfStatisticsCharts.buildParetoDualAxisChart(
              summary.paretoResult.items,
              totalOccur,
            ),
            pw.SizedBox(height: 8),
            // Tableau récapitulatif Top 10 Pareto
            _buildParetoTop10Table(summary.paretoResult, totalOccur),
            pw.SizedBox(height: 8),
            // Explication dynamique et rigoureuse de la loi de Pareto
            _buildDynamicParetoExplanation(summary.paretoResult, totalOccur),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    // ── 5. Analyse comparative avec la visite précédente ──
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
                '5. Analyse comparative avec la visite précédente',
              ),
              pw.SizedBox(height: 5),
              PdfReportStyles.bodyText(
                'Donnée non disponible : il s\'agit de la première visite de vérification périodique disposant d\'une check-list numérique structurée pour ce site (Rapport n° $numeroRapportDoc). Cette section, ainsi que le taux de mise en conformité par rapport à l\'année passée, pourra être complétée automatiquement dès réception du rapport de l\'exercice précédent.',
              ),
            ],
          ),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    // ── 6. Synthèse de l'analyse statistique ──
    final synthesisResult = StatisticalSynthesisEngine.analyze(
      summary: summary,
      technical: technical,
    );

    widgets.add(
      PageTracker(
        key: 'stat_synthese',
        registry: trackedPages,
        offset: offset,
        child: _buildDynamicStatisticalSynthesis(synthesisResult),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    // // ── 7. Recommandation pour le renforcement des capacités des agents d’entretien ──
    // widgets.add(
    //   PageTracker(
    //     key: 'stat_formation',
    //     registry: trackedPages,
    //     offset: offset,
    //     child: _buildTrainingRecommendationsSection(
    //       7,
    //       mission.nomClient,
    //       summary,
    //     ),
    //   ),
    // );

    return widgets;
  }

  // ──────────────────────────────────────────────────────────────
  //  CONSTRUCTION DES TABLEAUX ET CELLULES
  // ──────────────────────────────────────────────────────────────

  static pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
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

  static pw.Widget _buildCrossAuditTable(
    List<CategoryCrossAuditRow> rows,
    CategoryCrossAuditRow totalRow,
    String domainName,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.0),
        1: pw.FlexColumnWidth(1.1),
        2: pw.FlexColumnWidth(1.1),
        3: pw.FlexColumnWidth(1.1),
        4: pw.FlexColumnWidth(1.4),
        5: pw.FlexColumnWidth(1.4),
        6: pw.FlexColumnWidth(1.3),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('Catégorie'),
            _buildTableHeaderCell('Équip.'),
            _buildTableHeaderCell('NC'),
            _buildTableHeaderCell('Crit.'),
            _buildTableHeaderCell('% total NC'),
            _buildTableHeaderCell('Taux crit./NC'),
            _buildTableHeaderCell('Densité'),
          ],
        ),
        if (rows.isEmpty)
          pw.TableRow(
            children: [
              _buildTableCell('Aucune installation $domainName recensée', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell('0'),
              _buildTableCell('0'),
              _buildTableCell('0'),
              _buildTableCell('0,0 %'),
              _buildTableCell('0,0 %'),
              _buildTableCell('-'),
            ],
          )
        else
          for (int i = 0; i < rows.length; i++)
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: i % 2 == 1 ? PdfReportStyles.tableRowAlt : PdfColors.white,
              ),
              children: [
                _buildTableCell(rows[i].categoryName, isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
                _buildTableCell('${rows[i].equipementsCount}'),
                _buildTableCell('${rows[i].ncCount}'),
                _buildTableCell(
                  '${rows[i].critiquesCount}',
                  color: rows[i].critiquesCount > 0 ? PdfColor.fromHex('#B71C1C') : null,
                  isBold: rows[i].critiquesCount > 0,
                ),
                _buildTableCell(rows[i].pctOfTotalNcStr),
                _buildTableCell(rows[i].tauxCritiqueStr),
                _buildTableCell(rows[i].densiteStr, isBold: true),
              ],
            ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [
            _buildTableCell('TOTAL $domainName', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            _buildTableCell('${totalRow.equipementsCount}', isBold: true),
            _buildTableCell('${totalRow.ncCount}', isBold: true),
            _buildTableCell(
              '${totalRow.critiquesCount}',
              isBold: true,
              color: totalRow.critiquesCount > 0 ? PdfColor.fromHex('#B71C1C') : null,
            ),
            _buildTableCell(totalRow.pctOfTotalNcStr, isBold: true),
            _buildTableCell(totalRow.tauxCritiqueStr, isBold: true),
            _buildTableCell(totalRow.densiteStr, isBold: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildBt2ColumnTable({
    required String col2Header,
    required List<(String label, String value, bool isAlert)> rows,
    required (String label, String value, bool isAlert) totalRow,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.5),
        1: pw.FlexColumnWidth(5.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('DESIGNATION'),
            _buildTableHeaderCell(col2Header),
          ],
        ),
        for (int i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i % 2 == 1 ? PdfReportStyles.tableRowAlt : PdfColors.white,
            ),
            children: [
              _buildTableCell(rows[i].$1, isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell(
                rows[i].$2,
                isBold: rows[i].$3,
                color: rows[i].$3 ? PdfColor.fromHex('#B71C1C') : null,
                align: pw.TextAlign.left,
                alignment: pw.Alignment.centerLeft,
              ),
            ],
          ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [
            _buildTableCell(totalRow.$1, isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            _buildTableCell(
              totalRow.$2,
              isBold: true,
              color: totalRow.$3 ? PdfColor.fromHex('#B71C1C') : null,
              align: pw.TextAlign.left,
              alignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildBtSourceTable(TechnicalEnrichmentResult technical) {
    const categories = [
      (DomainObjectType.inverseur, 'INVERSEUR'),
      (DomainObjectType.tgbt, 'TGBT'),
      (DomainObjectType.armoire, 'ARMOIRES'),
      (DomainObjectType.coffret, 'COFFRETS'),
    ];

    int totEquip = 0;
    int totIdent = 0;
    final rows = <(String, String, bool)>[];

    for (final item in categories) {
      final s = technical.sourceStats[item.$1];
      final tot = s?.totalEquipments ?? 0;
      final ident = s?.identifiees ?? 0;
      final pct = s?.percentage ?? 0.0;
      totEquip += tot;
      totIdent += ident;
      final valStr = tot > 0
          ? '$ident / $tot (${pct.toStringAsFixed(1).replaceAll('.', ',')} %)'
          : '0 / 0 (-)';
      rows.add((item.$2, valStr, ident < tot && tot > 0));
    }

    final totPct = totEquip > 0 ? (totIdent / totEquip * 100.0) : 0.0;
    final totalRow = (
      'TOTAL DISTRIBUTION BT',
      '$totIdent / $totEquip (${totPct.toStringAsFixed(1).replaceAll('.', ',')} %)',
      totIdent < totEquip && totEquip > 0,
    );

    return _buildBt2ColumnTable(
      col2Header: 'IDENTIFIE / PRESENT',
      rows: rows,
      totalRow: totalRow,
    );
  }

  static pw.Widget _buildBtCoupureTable(TechnicalEnrichmentResult technical) {
    const categories = [
      (DomainObjectType.inverseur, 'INVERSEUR'),
      (DomainObjectType.tgbt, 'TGBT'),
      (DomainObjectType.armoire, 'ARMOIRES'),
      (DomainObjectType.coffret, 'COFFRETS'),
    ];

    int totEquip = 0;
    int totPres = 0;
    final rows = <(String, String, bool)>[];

    for (final item in categories) {
      final s = technical.coupureTeteStats[item.$1];
      final tot = s?.totalEquipments ?? 0;
      final pres = s?.presents ?? 0;
      final pct = s?.percentage ?? 0.0;
      totEquip += tot;
      totPres += pres;
      final valStr = tot > 0
          ? '$pres / $tot (${pct.toStringAsFixed(1).replaceAll('.', ',')} %)'
          : '0 / 0 (-)';
      rows.add((item.$2, valStr, pres < tot && tot > 0));
    }

    final totPct = totEquip > 0 ? (totPres / totEquip * 100.0) : 0.0;
    final totalRow = (
      'TOTAL DISTRIBUTION BT',
      '$totPres / $totEquip (${totPct.toStringAsFixed(1).replaceAll('.', ',')} %)',
      totPres < totEquip && totEquip > 0,
    );

    return _buildBt2ColumnTable(
      col2Header: 'IDENTIFIE / PRESENT',
      rows: rows,
      totalRow: totalRow,
    );
  }

  static pw.Widget _buildBtParafoudreTable(TechnicalEnrichmentResult technical) {
    const categories = [
      (DomainObjectType.inverseur, 'INVERSEUR'),
      (DomainObjectType.tgbt, 'TGBT'),
      (DomainObjectType.armoire, 'ARMOIRES'),
      (DomainObjectType.coffret, 'COFFRETS'),
    ];

    int totEquip = 0;
    int totPres = 0;
    final rows = <(String, String, bool)>[];

    for (final item in categories) {
      final s = technical.parafoudreStats[item.$1];
      final tot = s?.totalEquipments ?? 0;
      final pres = s?.avecParafoudre ?? 0;
      final pct = s?.percentage ?? 0.0;
      totEquip += tot;
      totPres += pres;
      final valStr = tot > 0
          ? '$pres / $tot (${pct.toStringAsFixed(1).replaceAll('.', ',')} %)'
          : '0 / 0 (-)';
      rows.add((item.$2, valStr, pres < tot && tot > 0));
    }

    final totPct = totEquip > 0 ? (totPres / totEquip * 100.0) : 0.0;
    final totalRow = (
      'TOTAL DISTRIBUTION BT',
      '$totPres / $totEquip (${totPct.toStringAsFixed(1).replaceAll('.', ',')} %)',
      totPres < totEquip && totEquip > 0,
    );

    return _buildBt2ColumnTable(
      col2Header: 'IDENTIFIE / PRESENT',
      rows: rows,
      totalRow: totalRow,
    );
  }

  static pw.Widget _buildParetoTop10Table(ParetoAnalysisResult paretoResult, int totalOccurrences) {
    final top10 = paretoResult.items.take(10).toList();
    final top10Sum = top10.fold<int>(0, (sum, e) => sum + e.count);
    final top10Pct = totalOccurrences > 0 ? (top10Sum / totalOccurrences * 100) : 0.0;

    return pw.Column(
      children: [
        pw.Table(
          border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(0.8),
            1: pw.FlexColumnWidth(4.8),
            2: pw.FlexColumnWidth(1.4),
            3: pw.FlexColumnWidth(1.4),
            4: pw.FlexColumnWidth(1.6),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
              children: [
                _buildTableHeaderCell('N°'),
                _buildTableHeaderCell('Catégorie de non-conformité'),
                _buildTableHeaderCell('Constats'),
                _buildTableHeaderCell('Part (%)'),
                _buildTableHeaderCell('Part cumulée (%)'),
              ],
            ),
            for (int i = 0; i < top10.length; i++)
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: i % 2 == 1 ? PdfReportStyles.tableRowAlt : PdfColors.white,
                ),
                children: [
                  _buildTableCell('${i + 1}', isBold: true),
                  _buildTableCell(top10[i].title, isBold: false, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
                  _buildTableCell('${top10[i].count}', isBold: true),
                  _buildTableCell('${top10[i].percentage.toStringAsFixed(1).replaceAll('.', ',')} %'),
                  _buildTableCell('${top10[i].cumulativePercentage.toStringAsFixed(1).replaceAll('.', ',')} %', isBold: true),
                ],
              ),
          ],
        ),
        // Ligne de total avec fusion native des colonnes 0 et 1 (0.8 + 4.8 = 5.6)
        pw.Table(
          border: pw.TableBorder(
            left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
            right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
            bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
            verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(5.6),
            1: pw.FlexColumnWidth(1.4),
            2: pw.FlexColumnWidth(1.4),
            3: pw.FlexColumnWidth(1.6),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
              children: [
                _buildTableCell('TOTAL TOP 10', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
                _buildTableCell('$top10Sum', isBold: true),
                _buildTableCell('${top10Pct.toStringAsFixed(1).replaceAll('.', ',')} %', isBold: true),
                _buildTableCell('${top10Pct.toStringAsFixed(1).replaceAll('.', ',')} %', isBold: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildDynamicParetoExplanation(
    ParetoAnalysisResult pareto,
    int totalOccurrences,
  ) {
    final top10Items = pareto.items.take(10).toList();
    final top10Count = top10Items.length;
    final top10Sum = top10Items.fold<int>(0, (sum, e) => sum + e.count);
    final top10PctStr = totalOccurrences > 0 && top10Sum > 0
        ? (top10Sum / totalOccurrences * 100).toStringAsFixed(1).replaceAll('.', ',')
        : '0,0';
    final pareto80K = pareto.paretoCategoryCount > 0 ? pareto.paretoCategoryCount : 1;
    final paretoCumPctStr = pareto.paretoCumulativePercentage > 0
        ? pareto.paretoCumulativePercentage.toStringAsFixed(1).replaceAll('.', ',')
        : '0,0';
    final totalDistinct = pareto.totalDistinctCategories > 0
        ? pareto.totalDistinctCategories
        : (pareto.items.isNotEmpty ? pareto.items.length : 1);
    final k80RatioPctStr = (pareto.k80Ratio * 100).toStringAsFixed(1).replaceAll('.', ',');

    // ── Diagnostic dynamique de la concentration ──
    final String seuilTitle;
    final String seuilText;
    final String porteeText;

    switch (pareto.profile) {
      case ParetoConcentrationProfile.noData:
        seuilTitle = '• Seuil critique des 80 % : ';
        seuilText = 'Aucune non-conformité recensée sur le périmètre analysé. Le seuil de 80 % n\'est pas applicable.\n';
        porteeText = 'Maintenir la régularité des contrôles périodiques et les protocoles de maintenance préventive.';
        break;

      case ParetoConcentrationProfile.singleDominant:
        final catName = pareto.items.isNotEmpty ? pareto.items.first.title : 'Défaut prépondérant';
        final catPctStr = pareto.items.isNotEmpty
            ? pareto.items.first.percentage.toStringAsFixed(1).replaceAll('.', ',')
            : '0,0';
        seuilTitle = '• Seuil critique des 80 % (monopole de défaillance) : ';
        seuilText = 'Le seuil des 80 % est franchi dès la toute première catégorie (« $catName »), qui concentre à elle seule $catPctStr % de l\'ensemble des défaillances. Il s\'agit d\'une situation de concentration extrême, bien au-delà de la distribution classique 80/20.\n';
        porteeText = 'La priorité absolue d\'intervention et d\'investissement doit être focalisée sans délai sur la résolution de cette anomalie majeure (« $catName »), dont la résorption permettra à elle seule d\'assainir immédiatement plus de 80 % du risque global du site.';
        break;

      case ParetoConcentrationProfile.highConcentration:
        seuilTitle = '• Seuil critique des 80 % (règle de Pareto vérifiée) : ';
        seuilText = 'Le seuil de 80 % du volume global ($paretoCumPctStr %) est atteint dès la ${pareto80K == 1 ? "1ère" : "$pareto80K"}${pareto80K > 1 ? "e" : ""} catégorie de défauts (sur un total de $totalDistinct typologies, soit $k80RatioPctStr % du référentiel). Les constats observés sur le site vérifient fidèlement la loi de Pareto : une forte concentration du risque repose sur un nombre restreint de défaillances récurrentes.\n';
        porteeText = 'Pour maximiser l\'efficacité des investissements et sécuriser rapidement le site, le plan d\'action prioritaire doit cibler en premier lieu ces $pareto80K typologies (et singulièrement le Top $top10Count ci-dessus), permettant ainsi d\'éliminer l\'immense majorité des risques identifiés sans dispersion d\'efforts.';
        break;

      case ParetoConcentrationProfile.moderateConcentration:
        seuilTitle = '• Seuil critique des 80 % (concentration modérée) : ';
        seuilText = 'Le seuil de 80 % du volume global ($paretoCumPctStr %) est atteint à la $pareto80K${pareto80K > 1 ? "e" : ""} catégorie (sur un total de $totalDistinct typologies, soit $k80RatioPctStr %). La concentration est modérée : bien que les premières catégories constituent des gisements prioritaires, l\'atteinte des 80 % nécessite d\'englober un spectre plus étendu de typologies réparties sur plusieurs domaines techniques.\n';
        porteeText = 'Le plan d\'action doit combiner un traitement prioritaire des premières typologies tout en maintenant un programme de maintenance préventive structuré sur l\'ensemble des installations pour éviter la dégradation des anomalies secondaires.';
        break;

      case ParetoConcentrationProfile.homogeneousOrDispersed:
        seuilTitle = '• Seuil critique des 80 % (distribution dispersée / homogène) : ';
        seuilText = 'Le seuil des 80 % ($paretoCumPctStr %) n\'est atteint qu\'au rang $pareto80K (sur $totalDistinct typologies recensées, soit $k80RatioPctStr % du référentiel). Les données observées ne présentent pas de concentration caractéristique de type Pareto (80/20) : les anomalies sont relativement homogènes et dispersées sur un large éventail de défectuosités sans prédominance hégémonique.\n';
        porteeText = 'En l\'absence de concentration nette, la résorption des risques ne peut se focaliser uniquement sur quelques catégories. Une démarche de remise à niveau globale et un renforcement systématique des procédures de contrôle sur l\'ensemble du parc sont indispensables.';
        break;

      case ParetoConcentrationProfile.thresholdNotReached:
        seuilTitle = '• Seuil critique des 80 % (seuil non atteint) : ';
        seuilText = 'Le seuil des 80 % n\'est pas atteint sur la sélection observée (cumul maximal atteint : $paretoCumPctStr %). Les non-conformités sont très réparties sur le site sans concentration dominante sur les premiers rangs.\n';
        porteeText = 'Les priorités d\'intervention doivent être déterminées en priorité sur la criticité intrinsèque des équipements plutôt que sur la seule récurrence statistique des catégories.';
        break;
    }

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Lecture et enseignements du diagramme de Pareto (loi des 80/20)',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: fsH3,
              color: PdfReportStyles.headerColor,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.RichText(
            textAlign: pw.TextAlign.justify,
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '• Principe du diagramme : ',
                  style: pw.TextStyle(font: fontBold, fontSize: fsBody, color: PdfReportStyles.headerColor),
                ),
                pw.TextSpan(
                  text: 'Le diagramme de Pareto classe les catégories de défaillances par ordre décroissant de fréquence (occurrences unitaires) et superpose la courbe des pourcentages cumulés. Il permet d\'évaluer objectivement si une minorité de causes produit la majorité des effets constatés sur le site.\n',
                  style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 1.6),
                ),
                pw.TextSpan(
                  text: '• Périmètre analysé : ',
                  style: pw.TextStyle(font: fontBold, fontSize: fsBody, color: PdfReportStyles.headerColor),
                ),
                pw.TextSpan(
                  text: 'L\'ensemble des $totalOccurrences occurrences de non-conformités normatives relevées sur les installations ont été classées sous $totalDistinct typologies de défauts ordonnées par fréquence décroissante.\n',
                  style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 1.6),
                ),
                pw.TextSpan(
                  text: '• Palier Top $top10Count : ',
                  style: pw.TextStyle(font: fontBold, fontSize: fsBody, color: PdfReportStyles.headerColor),
                ),
                pw.TextSpan(
                  text: 'Les $top10Count catégories de défauts les plus fréquentes concentrent à elles seules $top10Sum non-conformités, soit $top10PctStr % du volume total des anomalies du site.\n',
                  style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 1.6),
                ),
                pw.TextSpan(
                  text: seuilTitle,
                  style: pw.TextStyle(font: fontBold, fontSize: fsBody, color: PdfReportStyles.headerColor),
                ),
                pw.TextSpan(
                  text: seuilText,
                  style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 1.6),
                ),
                pw.TextSpan(
                  text: '• Portée opérationnelle : ',
                  style: pw.TextStyle(font: fontBold, fontSize: fsBody, color: PdfReportStyles.headerColor),
                ),
                pw.TextSpan(
                  text: porteeText,
                  style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCalloutBox(String text) {
    String title = 'Note : ';
    String body = text;
    if (text.startsWith('Portée de la recommandation : ')) {
      title = 'Portée de la recommandation : ';
      body = text.substring('Portée de la recommandation : '.length);
    }

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
      ),
      child: pw.RichText(
        textAlign: pw.TextAlign.justify,
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: title,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: fsBody,
                color: PdfReportStyles.headerColor,
              ),
            ),
            pw.TextSpan(
              text: body,
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: fsBody,
                color: PdfReportStyles.darkGrey,
                lineSpacing: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  SOUS-SECTIONS PARTICULIÈRES (1 & 7)
  // ──────────────────────────────────────────────────────────────

  static pw.Widget _buildTensionDomainSection(
    TensionDomainStats stats,
    TechnicalEnrichmentResult technical, [
    int? index,
  ]) {
    final total = stats.totalCount;
    final btCount = stats.btCount;
    final mtCount = stats.mtCount;
    final btPct = total > 0 ? (btCount / total) * 100.0 : 0.0;
    final mtPct = total > 0 ? (100.0 - btPct) : 0.0;
    final btPctStr = btPct.toStringAsFixed(1).replaceAll('.', ',');
    final mtPctStr = mtPct.toStringAsFixed(1).replaceAll('.', ',');

    String analysisText;
    if (total == 0) {
      analysisText =
          'Aucune non-conformité n\'a été recensée sur l\'ensemble des installations Moyenne Tension (HTA) et Basse Tension (BT) auditées lors de cette mission.';
    } else if (mtCount == 0 && btCount > 0) {
      analysisText =
          'L\'intégralité des non-conformités relevées ($btCount constats, soit 100,0 %) se concentre exclusivement sur le domaine de la Basse Tension (BT), le périmètre Moyenne Tension (HTA) ne présentant aucune anomalie.';
    } else if (btCount == 0 && mtCount > 0) {
      analysisText =
          'L\'intégralité des non-conformités relevées ($mtCount constats, soit 100,0 %) relève exclusivement du domaine de la Moyenne Tension (HTA), le périmètre Basse Tension (BT) ne comportant aucune anomalie.';
    } else {
      final diff = (btPct - mtPct).abs();
      if (diff <= 10.0) {
        analysisText =
            'Les non-conformités se répartissent de façon équilibrée entre la Basse Tension ($btCount constats, soit $btPctStr %) et la Moyenne Tension ($mtCount constats, soit $mtPctStr %), traduisant des exigences de mise en conformité réparties de manière homogène sur l\'ensemble des deux domaines de tension.';
      } else if (btCount > mtCount) {
        analysisText =
            'La Basse Tension regroupe la majorité des constats relevés avec $btPctStr % des non-conformités ($btCount sur un total de $total), contre $mtPctStr % pour la Moyenne Tension ($mtCount sur $total). Cette structure d\'écarts situe le principal volume d\'actions correctives sur les installations et tableaux Basse Tension du site.';
      } else {
        analysisText =
            'La Moyenne Tension concentre la majorité des constats relevés avec $mtPctStr % des non-conformités ($mtCount sur un total de $total), contre $btPctStr % pour la Basse Tension ($btCount sur $total), plaçant le foyer principal des écarts constatés sur le périmètre HTA (postes, cellules ou transformateurs).';
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfReportStyles.subTitle(
          '${index != null ? "$index. " : ""}Répartition des non-conformités par domaine de tension',
        ),
        pw.SizedBox(height: 6),
        // Diagramme 1 : Répartition par domaine de tension
        PdfStatisticsCharts.buildTensionDomainChart(stats.btCount, stats.mtCount),
        pw.SizedBox(height: 6),
        PdfReportStyles.bodyText(analysisText),
      ],
    );
  }

  static pw.Widget _buildCrossAuditIntroText() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfReportStyles.subTitle('2. Non-conformités croisées par catégorie d\'installation'),
        pw.SizedBox(height: 4),
        PdfReportStyles.bodyText(
          'L\'analyse croisée met en regard le recensement exhaustif du parc d\'équipements électrotechniques avec la distribution des non-conformités constatées, leur niveau de criticité et leur densité moyenne par unité inspectée. '
          'Les domaines Moyenne Tension (HTA) et Basse Tension (BT) font l\'objet d\'évaluations distinctes en raison de leurs règles normatives spécifiques (NF C 13-100 / NF C 13-200 pour la MT et NF C 15-100 pour la BT) et de leurs contraintes d\'exploitation propres.\n\n'
          'Lecture des tableaux :\n'
          '- Équip. : Nombre total d\'équipements ou de locaux recensés dans la catégorie.\n'
          '- NC : Volume de non-conformités (constats non conformes) relevées.\n'
          '- Crit. / Maj. : Nombre d\'anomalies classées en sévérité Critique ou Majeure.\n'
          '- % du total : Part relative des NC de la catégorie rapportée à l\'ensemble des non-conformités de la mission.\n'
          '- Taux critique : Proportion de constats critiques parmi les non-conformités de la catégorie.\n'
          '- Densité : Ratio moyen de non-conformités par équipement de la catégorie.\n\n'
          'Note méthodologique : Les non-conformités afférentes aux dispositions constructives du génie civil des locaux techniques sont isolées dans le volet bâtiment du résumé exécutif pour garantir la stricte comparabilité de l\'exploitation et de la maintenance des parcs d\'équipements.',
        ),
      ],
    );
  }

  static pw.Widget _buildMtCrossAuditCommentary(
    List<CategoryCrossAuditRow> rows,
    CategoryCrossAuditRow totalRow,
  ) {
    if (totalRow.ncCount == 0) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4, bottom: 6),
        child: PdfReportStyles.bodyText(
          'Synthèse MT : Aucun écart de conformité n\'est relevé sur le parc Moyenne Tension recensé (${totalRow.equipementsCount} équipement(s) au total). L\'ensemble des cellules, transformateurs et locaux MT inspectés satisfont aux exigences réglementaires applicables.',
        ),
      );
    }

    final activeRows = rows.where((r) => r.ncCount > 0).toList()
      ..sort((a, b) => b.ncCount.compareTo(a.ncCount));
    final dominant = activeRows.isNotEmpty ? activeRows.first : null;
    final emptyRows = rows.where((r) => r.equipementsCount > 0 && r.ncCount == 0).toList();

    String emptyCatNote = '';
    if (emptyRows.isNotEmpty) {
      final names = emptyRows.map((r) => r.categoryName).join(', ');
      emptyCatNote = ' À l\'inverse, les catégories $names ne présentent aucune non-conformité.';
    }

    final densiteStr = totalRow.densite.toStringAsFixed(2).replaceAll('.', ',');
    final critCount = totalRow.critiquesCount;
    final majCount = totalRow.majeuresCount;

    String text = 'Synthèse MT : Le périmètre Moyenne Tension totalise ${totalRow.ncCount} non-conformité(s) '
        'sur un parc de ${totalRow.equipementsCount} équipement(s) ou local/locaux inspecté(s), soit une densité moyenne de $densiteStr anomalie(s) par unité. ';
    if (dominant != null) {
      text += 'La catégorie « ${dominant.categoryName} » concentre le principal volume d\'écarts avec ${dominant.ncCount} NC (${dominant.pctOfTotalNcStr} de la mission, densité de ${dominant.densiteStr}). ';
    }
    if (critCount > 0 || majCount > 0) {
      text += 'Sur le plan de la sévérité, ce domaine enregistre $critCount anomalie(s) critique(s) et $majCount anomalie(s) majeure(s).';
    } else {
      text += 'Aucune anomalie critique ou majeure n\'est relevée sur ce domaine.';
    }
    text += emptyCatNote;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4, bottom: 6),
      child: PdfReportStyles.bodyText(text),
    );
  }

  static pw.Widget _buildBtCrossAuditCommentary(
    List<CategoryCrossAuditRow> rows,
    CategoryCrossAuditRow totalRow,
  ) {
    if (totalRow.ncCount == 0) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4, bottom: 6),
        child: PdfReportStyles.bodyText(
          'Synthèse BT : Aucun écart de conformité n\'est relevé sur le parc Basse Tension recensé (${totalRow.equipementsCount} équipement(s) au total). L\'ensemble des armoires, coffrets et tableaux inspectés satisfont aux exigences réglementaires applicables.',
        ),
      );
    }

    final activeRows = rows.where((r) => r.ncCount > 0).toList()
      ..sort((a, b) => b.ncCount.compareTo(a.ncCount));
    final dominant = activeRows.isNotEmpty ? activeRows.first : null;
    final highestDensityRow = List<CategoryCrossAuditRow>.from(rows.where((r) => r.equipementsCount > 0))
      ..sort((a, b) => b.densite.compareTo(a.densite));
    final topDensity = highestDensityRow.isNotEmpty && highestDensityRow.first.densite > 0
        ? highestDensityRow.first
        : null;

    final critRows = rows.where((r) => r.critiquesCount > 0).toList()
      ..sort((a, b) => b.critiquesCount.compareTo(a.critiquesCount));
    final topCrit = critRows.isNotEmpty ? critRows.first : null;

    final densiteStr = totalRow.densite.toStringAsFixed(2).replaceAll('.', ',');
    final critCount = totalRow.critiquesCount;
    final majCount = totalRow.majeuresCount;

    String text = 'Synthèse BT : Le domaine Basse Tension regroupe ${totalRow.ncCount} non-conformité(s) '
        'sur un parc total de ${totalRow.equipementsCount} équipement(s), représentant une densité moyenne de $densiteStr anomalie(s) par équipement. ';

    if (dominant != null) {
      text += 'En volume brut, la catégorie « ${dominant.categoryName} » réunit la part la plus importante avec ${dominant.ncCount} NC (${dominant.pctOfTotalNcStr} de la mission). ';
    }
    if (topDensity != null && topDensity.categoryName != dominant?.categoryName) {
      text += 'En termes de concentration unitaire, les « ${topDensity.categoryName} » affichent la densité la plus forte (${topDensity.densiteStr} NC/équipement). ';
    }
    if (topCrit != null) {
      text += 'La sévérité la plus marquée concerne les « ${topCrit.categoryName} » avec ${topCrit.critiquesCount} anomalie(s) critique(s) (taux critique de ${topCrit.tauxCritiqueStr}). ';
    }
    text += 'Au global, le périmètre BT concentre $critCount anomalie(s) critique(s) et $majCount majeure(s).';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4, bottom: 6),
      child: PdfReportStyles.bodyText(text),
    );
  }

  static pw.Widget buildTrainingRecommendationsSection(
    int sectionNum,
    String clientName,
    MissionStatisticsSummary summary,
  ) {
    final comp = summary.competencyNeeds;
    final porteeText =
        'Portée de la recommandation : Cette recommandation vise le renforcement des compétences des agents d\'entretien internes à $clientName ; elle est complémentaire du plan d\'actions correctives à mener par des intervenants habilités pour la levée des non-conformités critiques et majeures identifiées au chapitre 1.';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Inseparable(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfReportStyles.subTitle(
                '$sectionNum. Recommandation pour le renforcement des capacités des agents d\'entretien',
              ),
              pw.SizedBox(height: 5),
              PdfReportStyles.bodyText(comp.introNarrative),
              pw.SizedBox(height: 6),
            ],
          ),
        ),
        if (comp.axes.isNotEmpty)
          ...comp.axes.map(
            (axis) => pw.Inseparable(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(left: 6, bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 3.5,
                      height: 3.5,
                      margin: const pw.EdgeInsets.only(top: 4, right: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfReportStyles.accentColor,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: '${axis.title} (${axis.occurrenceCount} constats, ${axis.percentageStr} %) : ',
                              style: pw.TextStyle(font: fontBold, fontSize: fsBody, color: PdfReportStyles.darkGrey),
                            ),
                            pw.TextSpan(
                              text: axis.fullNarrative,
                              style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey),
                            ),
                          ],
                        ),
                        textAlign: pw.TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        pw.SizedBox(height: 8),
        pw.Inseparable(
          child: _buildCalloutBox(porteeText),
        ),
      ],
    );
  }

  static pw.Widget _buildDynamicStatisticalSynthesis(StatisticalSynthesisResult synthesis) {
    final children = <pw.Widget>[];

    // Titre de sous-section
    final titleWidget = PdfReportStyles.subTitle('6. Synthèse de l\'analyse statistique');

    final paragraphs = synthesis.paragraphs;
    if (paragraphs.isEmpty) {
      return pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            titleWidget,
            pw.SizedBox(height: 6),
            _buildFormattedText('Donnée non disponible pour cette mission.'),
          ],
        ),
      );
    }

    // Le titre et le premier paragraphe sont groupés dans un Inseparable pour éviter un titre orphelin
    final firstParagraph = _buildFormattedText(paragraphs.first);
    children.add(
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            titleWidget,
            pw.SizedBox(height: 6),
            firstParagraph,
          ],
        ),
      ),
    );

    // Les paragraphes suivants s'enchaînent avec un espacement respirant
    for (int i = 1; i < paragraphs.length; i++) {
      children.add(pw.SizedBox(height: 6));
      children.add(_buildFormattedText(paragraphs[i]));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  static pw.Widget _buildFormattedText(
    String text, {
    pw.TextStyle? defaultStyle,
    pw.TextAlign textAlign = pw.TextAlign.justify,
  }) {
    final style = defaultStyle ??
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

  static pw.Widget buildTensionDomainSectionForTesting(
    TensionDomainStats stats,
    TechnicalEnrichmentResult technical,
  ) =>
      _buildTensionDomainSection(stats, technical);

  static pw.Widget buildCrossAuditIntroTextForTesting() =>
      _buildCrossAuditIntroText();

  static pw.Widget buildMtCrossAuditCommentaryForTesting(
    List<CategoryCrossAuditRow> rows,
    CategoryCrossAuditRow totalRow,
  ) =>
      _buildMtCrossAuditCommentary(rows, totalRow);

  static pw.Widget buildBtCrossAuditCommentaryForTesting(
    List<CategoryCrossAuditRow> rows,
    CategoryCrossAuditRow totalRow,
  ) =>
      _buildBtCrossAuditCommentary(rows, totalRow);
}

