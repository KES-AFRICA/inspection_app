import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/statistics/mission_statistics_collector.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';
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
    final domainStats = summary.tensionDomainStats;
    final technical = summary.technical;

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

    // ── 1. Répartition des non-conformités par domaine de tension ──
    widgets.add(
      PageTracker(
        key: 'stat_tension',
        registry: trackedPages,
        offset: offset,
        child: _buildTensionDomainSection(domainStats, 1),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    // ── 2. Non-conformités croisées par catégorie d'installation ──
    widgets.add(
      PageTracker(
        key: 'stat_croisee',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfReportStyles.subTitle('2. Non-conformités croisées par catégorie d\'installation'),
            pw.SizedBox(height: 4),
            PdfReportStyles.bodyText(
              'Analyse granulaire croisant le parc d\'équipements recensés avec les non-conformités détectées, le volume d\'anomalies critiques et la densité par équipement selon le domaine de tension :',
            ),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 6));

    // 2.1 Moyenne tension
    widgets.add(
      PageTracker(
        key: 'stat_croisee_mt',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '2.1. Moyenne tension',
              style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
            ),
            pw.SizedBox(height: 4),
            _buildCrossAuditTable(
              technical.mtCategoriesCrossRows,
              technical.mtTotalCrossRow,
              'MT',
            ),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    // 2.2 Basse tension
    widgets.add(
      PageTracker(
        key: 'stat_croisee_bt',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '2.2. Basse tension',
              style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
            ),
            pw.SizedBox(height: 4),
            _buildCrossAuditTable(
              technical.btCategoriesCrossRows,
              technical.btTotalCrossRow,
              'BT',
            ),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    // ── 3. Sécurité et traçabilité des tableaux Basse Tension ──
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

    // 3.1 Sources d'alimentation
    widgets.add(
      PageTracker(
        key: 'stat_sources_alim',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '3.1. Identification des sources d’alimentation',
              style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
            ),
            pw.SizedBox(height: 4),
            _buildBtSourceTable(technical),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    // 3.2 Présence organe de coupure en tête
    widgets.add(
      PageTracker(
        key: 'stat_coupure_tete',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '3.2. Présence organe de coupure en tête d’installation',
              style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
            ),
            pw.SizedBox(height: 4),
            _buildBtCoupureTable(technical),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    // 3.3 Présence parafoudre
    widgets.add(
      PageTracker(
        key: 'stat_parafoudres',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '3.3. Présence parafoudre',
              style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
            ),
            pw.SizedBox(height: 4),
            _buildBtParafoudreTable(technical),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    // ── 4. Statistique par type de défaut : analyse de Pareto (corrigée) ──
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
                '4. Statistique par type de défaut : analyse de Pareto (corrigée)',
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
                'Donnée non disponible — Le présent rapport porte sur la première visite de vérification périodique disposant d\'une check-list numérique structurée pour ce site (Rapport n° $numeroRapportDoc). Aucun rapport antérieur exploitable au même format n\'a été fourni pour extraire le nombre de non-conformités de l\'année passée. Si un rapport antérieur existe, merci de le transmettre : cette section et la comparaison ci-dessous seront complétées automatiquement.',
              ),
            ],
          ),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    // ── 6. Synthèse de l'analyse statistique ──
    final paretoK = summary.paretoResult.paretoCategoryCount;
    final paretoCumul = summary.paretoResult.paretoCumulativePercentage;
    final totalEq = summary.totalEquipments;
    final activeCats = summary.crossCategoryItems.length;
    final topTwo = summary.topTwoCategoriesResult;

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
    widgets.add(pw.SizedBox(height: 12));

    // ── 7. Recommandation pour le renforcement des capacités des agents d’entretien ──
    widgets.add(
      PageTracker(
        key: 'stat_formation',
        registry: trackedPages,
        offset: offset,
        child: pw.Inseparable(
          child: _buildTrainingRecommendationsSection(7),
        ),
      ),
    );

    return widgets;
  }

  static String _formatCategoryName(DomainObjectType cat) {
    switch (cat) {
      case DomainObjectType.inverseur:
        return 'Inverseurs Normal / Secours';
      case DomainObjectType.tgbt:
        return 'TGBT (Tableaux Généraux)';
      case DomainObjectType.armoire:
        return 'Armoires divisionnaires';
      case DomainObjectType.coffret:
        return 'Coffrets terminaux';
      default:
        return cat.name;
    }
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

  static pw.Widget _buildCrossAuditTable(
    List<CategoryCrossAuditRow> rows,
    CategoryCrossAuditRow totalRow,
    String domainName,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.4),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.2),
        4: pw.FlexColumnWidth(1.4),
        5: pw.FlexColumnWidth(1.4),
        6: pw.FlexColumnWidth(1.6),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('CATÉGORIE D\'INSTALLATION'),
            _buildTableHeaderCell('ÉQUIP.'),
            _buildTableHeaderCell('NC'),
            _buildTableHeaderCell('CRIT.'),
            _buildTableHeaderCell('% TOTAL'),
            _buildTableHeaderCell('TX CRIT.'),
            _buildTableHeaderCell('DENSITÉ (NC/ÉQ)'),
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
              _buildTableCell('—'),
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

  static pw.Widget _buildBtSourceTable(TechnicalEnrichmentResult technical) {
    const categories = [
      DomainObjectType.inverseur,
      DomainObjectType.tgbt,
      DomainObjectType.armoire,
      DomainObjectType.coffret,
    ];

    int totEquip = 0;
    int totIdent = 0;
    int totNonIdent = 0;

    for (final cat in categories) {
      final s = technical.sourceStats[cat];
      totEquip += s?.totalEquipments ?? 0;
      totIdent += s?.identifiees ?? 0;
      totNonIdent += s?.nonIdentifiees ?? 0;
    }
    final totPct = totEquip > 0 ? (totIdent / totEquip * 100.0) : 0.0;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.8),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(1.6),
        4: pw.FlexColumnWidth(1.6),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('CATÉGORIE TABLEAU'),
            _buildTableHeaderCell('TOTAL'),
            _buildTableHeaderCell('IDENTIFIÉE'),
            _buildTableHeaderCell('NON IDENTIFIÉE'),
            _buildTableHeaderCell('TAUX (%)'),
          ],
        ),
        ...categories.map((cat) {
          final s = technical.sourceStats[cat];
          final tot = s?.totalEquipments ?? 0;
          final ident = s?.identifiees ?? 0;
          final nonIdent = s?.nonIdentifiees ?? 0;
          final pct = s?.percentage ?? 0.0;
          final isAlert = nonIdent > 0;
          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _buildTableCell(_formatCategoryName(cat), isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell('$tot'),
              _buildTableCell('$ident'),
              _buildTableCell('$nonIdent', isBold: isAlert, color: isAlert ? PdfColor.fromHex('#B71C1C') : null),
              _buildTableCell('${pct.toStringAsFixed(1).replaceAll('.', ',')} %', isBold: true, color: pct < 100.0 && tot > 0 ? PdfColor.fromHex('#B71C1C') : PdfReportStyles.accentColor),
            ],
          );
        }),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [
            _buildTableCell('TOTAL DISTRIBUTION BT', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            _buildTableCell('$totEquip', isBold: true),
            _buildTableCell('$totIdent', isBold: true),
            _buildTableCell('$totNonIdent', isBold: true, color: totNonIdent > 0 ? PdfColor.fromHex('#B71C1C') : null),
            _buildTableCell('${totPct.toStringAsFixed(1).replaceAll('.', ',')} %', isBold: true, color: totPct < 100.0 && totEquip > 0 ? PdfColor.fromHex('#B71C1C') : PdfReportStyles.accentColor),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildBtCoupureTable(TechnicalEnrichmentResult technical) {
    const categories = [
      DomainObjectType.inverseur,
      DomainObjectType.tgbt,
      DomainObjectType.armoire,
      DomainObjectType.coffret,
    ];

    int totEquip = 0;
    int totPres = 0;
    int totAbs = 0;

    for (final cat in categories) {
      final s = technical.coupureTeteStats[cat];
      totEquip += s?.totalEquipments ?? 0;
      totPres += s?.presents ?? 0;
      totAbs += s?.absents ?? 0;
    }
    final totPct = totEquip > 0 ? (totPres / totEquip * 100.0) : 0.0;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.8),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(1.6),
        4: pw.FlexColumnWidth(1.6),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('CATÉGORIE TABLEAU'),
            _buildTableHeaderCell('TOTAL'),
            _buildTableHeaderCell('PRÉSENT'),
            _buildTableHeaderCell('ABSENT'),
            _buildTableHeaderCell('TAUX (%)'),
          ],
        ),
        ...categories.map((cat) {
          final s = technical.coupureTeteStats[cat];
          final tot = s?.totalEquipments ?? 0;
          final pres = s?.presents ?? 0;
          final abs = s?.absents ?? 0;
          final pct = s?.percentage ?? 0.0;
          final isAlert = abs > 0;
          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _buildTableCell(_formatCategoryName(cat), isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell('$tot'),
              _buildTableCell('$pres'),
              _buildTableCell('$abs', isBold: isAlert, color: isAlert ? PdfColor.fromHex('#B71C1C') : null),
              _buildTableCell('${pct.toStringAsFixed(1).replaceAll('.', ',')} %', isBold: true, color: pct < 100.0 && tot > 0 ? PdfColor.fromHex('#B71C1C') : PdfReportStyles.accentColor),
            ],
          );
        }),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [
            _buildTableCell('TOTAL DISTRIBUTION BT', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            _buildTableCell('$totEquip', isBold: true),
            _buildTableCell('$totPres', isBold: true),
            _buildTableCell('$totAbs', isBold: true, color: totAbs > 0 ? PdfColor.fromHex('#B71C1C') : null),
            _buildTableCell('${totPct.toStringAsFixed(1).replaceAll('.', ',')} %', isBold: true, color: totPct < 100.0 && totEquip > 0 ? PdfColor.fromHex('#B71C1C') : PdfReportStyles.accentColor),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildBtParafoudreTable(TechnicalEnrichmentResult technical) {
    const categories = [
      DomainObjectType.inverseur,
      DomainObjectType.tgbt,
      DomainObjectType.armoire,
      DomainObjectType.coffret,
    ];

    int totEquip = 0;
    int totPres = 0;
    int totAbs = 0;

    for (final cat in categories) {
      final s = technical.parafoudreStats[cat];
      totEquip += s?.totalEquipments ?? 0;
      totPres += s?.avecParafoudre ?? 0;
      totAbs += s?.sansParafoudre ?? 0;
    }
    final totPct = totEquip > 0 ? (totPres / totEquip * 100.0) : 0.0;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.8),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(1.6),
        4: pw.FlexColumnWidth(1.6),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('CATÉGORIE TABLEAU'),
            _buildTableHeaderCell('TOTAL'),
            _buildTableHeaderCell('AVEC PARAFOUDRE'),
            _buildTableHeaderCell('SANS PARAFOUDRE'),
            _buildTableHeaderCell('TAUX (%)'),
          ],
        ),
        ...categories.map((cat) {
          final s = technical.parafoudreStats[cat];
          final tot = s?.totalEquipments ?? 0;
          final pres = s?.avecParafoudre ?? 0;
          final abs = s?.sansParafoudre ?? 0;
          final pct = s?.percentage ?? 0.0;
          final isAlert = abs > 0;
          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _buildTableCell(_formatCategoryName(cat), isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell('$tot'),
              _buildTableCell('$pres'),
              _buildTableCell('$abs', isBold: isAlert, color: isAlert ? PdfColor.fromHex('#B71C1C') : null),
              _buildTableCell('${pct.toStringAsFixed(1).replaceAll('.', ',')} %', isBold: true, color: pct < 100.0 && tot > 0 ? PdfColor.fromHex('#B71C1C') : PdfReportStyles.accentColor),
            ],
          );
        }),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [
            _buildTableCell('TOTAL DISTRIBUTION BT', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            _buildTableCell('$totEquip', isBold: true),
            _buildTableCell('$totPres', isBold: true),
            _buildTableCell('$totAbs', isBold: true, color: totAbs > 0 ? PdfColor.fromHex('#B71C1C') : null),
            _buildTableCell('${totPct.toStringAsFixed(1).replaceAll('.', ',')} %', isBold: true, color: totPct < 100.0 && totEquip > 0 ? PdfColor.fromHex('#B71C1C') : PdfReportStyles.accentColor),
          ],
        ),
      ],
    );
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


  static String _shortVerificationPointName(String title) {
    final s = title.trim();
    final lower = s.toLowerCase();
    if (lower.contains('contacts indirects') ||
        lower.contains('contact indirect')) {
      return 'contact\nindirect';
    }
    if (lower.contains('câblage') || lower.contains('cablage')) {
      return 'Câblage';
    }
    if (lower.contains('identification')) {
      return 'Identification\ncircuits';
    }
    if (lower.contains('dispositif') || lower.contains('protection')) {
      return 'Dispositifs de\nprotection';
    }
    if (lower.contains('répartiteur') || lower.contains('repartiteur')) {
      return 'Répartiteur de\ncircuit';
    }
    if (lower.contains('continuité') || lower.contains('pe')) {
      return 'Continuité PE';
    }
    if (lower.contains('répartition') || lower.contains('repartition')) {
      return 'Répartition des\ncircuits';
    }
    if (lower.contains('emplacement') || lower.contains('dégagement')) {
      return 'Emplacement /\ndégagement';
    }
    if (lower.contains('code couleur') || lower.contains('couleur')) {
      return 'Code couleur\ncâbles';
    }
    if (lower.contains('état') ||
        lower.contains('armoire') ||
        lower.contains('coffret')) {
      return 'État coffret /\narmoire / TGBT';
    }

    if (s.length > 20) {
      final parts = s.split(' ');
      if (parts.length > 2) {
        final mid = parts.length ~/ 2;
        return '${parts.sublist(0, mid).join(" ")}\n${parts.sublist(mid).join(" ")}';
      }
    }
    return s;
  }


  static pw.Widget _buildTrainingRecommendationsSection(int sectionNum) {
    final recoList = [
      (
        '1. Adéquation Pouvoir de Coupure (Pdc) / Icc max site',
        'Dimensionnement & sélection d\'appareillage selon les Icc amont calculés en tête de tableau.',
        'Prévention des destructions violentes de disjoncteurs et des arcs électriques majeurs.',
      ),
      (
        '2. Continuité des Masses et Conducteurs de Protection (PE)',
        'Méthodologie de mesure 4 fils au milliohmmètre (< 2 Ω) et contrôle des liaisons équipotentielles.',
        'Élimination des risques de choc électrique par contact indirect pour le personnel.',
      ),
      (
        '3. Sélectivité & Choix des Courbes de Déclenchement (B, C, D)',
        'Maîtrise des courants d\'appel (moteurs, transformateurs, charges informatiques) et étagement.',
        'Continuité d\'alimentation, limitation du déclenchement au seul circuit en défaut.',
      ),
      (
        '4. Coordination & Filiation des Protections Amont / Aval',
        'Règles normatives d\'association de disjoncteurs pour renforcer le pouvoir de coupure aval.',
        'Garantie de tenue en court-circuit à coût optimisé sans compromettre la sécurité.',
      ),
      (
        '5. Régimes de Neutre & Schémas de Liaison à la Terre (SLT)',
        'Exploitation et surveillance des schémas TT, TN et IT ; déclenchement au 1er ou 2nd défaut.',
        'Conformité réglementaire (décret travailleurs) et maintien de l\'exploitation.',
      ),
      (
        '6. Protection contre les Surtensions Transitoires (Parafoudres)',
        'Règles d\'installation (Type 1 / Type 2), règle des 50 cm et coordination avec la prise de terre.',
        'Préservation des cartes électroniques, automates industriels et charges sensibles.',
      ),
      (
        '7. Contrôle Thermographique Infrarouge & Serrages',
        'Utilisation des caméras thermiques, détection des points chauds et resserrage au couple.',
        'Prévention des départs d\'incendie d\'origine électrique et dégradation prématurée des isolants.',
      ),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfReportStyles.subTitle(
          '$sectionNum. Recommandation pour le renforcement des capacités des agents d’entretien',
        ),
        pw.SizedBox(height: 5),
        PdfReportStyles.bodyText(
          'L\'analyse approfondie des non-conformités et des caractéristiques techniques du site met en évidence la nécessité de renforcer les compétences des techniciens de maintenance selon 7 axes techniques prioritaires :',
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(3.2),
            1: pw.FlexColumnWidth(3.8),
            2: pw.FlexColumnWidth(3.0),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'AXE TECHNIQUE PRIORITAIRE',
                    style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.white),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'OBJECTIF PÉDAGOGIQUE & NORMES',
                    style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.white),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'RISQUE COUVERT & GAIN OPÉRATIONNEL',
                    style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.white),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
            ...recoList.map((item) {
              return pw.TableRow(
                verticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      item.$1,
                      style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfReportStyles.headerColor),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      item.$2,
                      style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.grey900),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      item.$3,
                      style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.grey900),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }
}
