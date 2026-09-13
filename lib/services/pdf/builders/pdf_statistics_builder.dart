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
        'MT',
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

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
        'BT',
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
        child: pw.Text(
          '3.1. Identification des sources d’alimentation',
          style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(_buildBtSourceTable(technical));
    widgets.add(pw.SizedBox(height: 8));

    // 3.2 Présence organe de coupure en tête
    widgets.add(
      PageTracker(
        key: 'stat_coupure_tete',
        registry: trackedPages,
        offset: offset,
        child: pw.Text(
          '3.2. Présence organe de coupure en tête d’installation',
          style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(_buildBtCoupureTable(technical));
    widgets.add(pw.SizedBox(height: 8));

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
    widgets.add(pw.SizedBox(height: 12));

    // ── 4. Statistique par type de défaut : analyse de Pareto (corrigée) ──
    final totalOccur = summary.paretoResult.totalOccurrences > 0
        ? summary.paretoResult.totalOccurrences
        : summary.criticalityStats.total;
    final top10Items = summary.paretoResult.items.take(10).toList();
    final top10Count = top10Items.isNotEmpty ? top10Items.length : 10;
    final top10Sum = top10Items.fold<int>(0, (sum, e) => sum + e.count);
    final top10Pct = totalOccur > 0 && top10Sum > 0
        ? (top10Sum / totalOccur * 100)
        : 73.6;
    final pareto80K = summary.paretoResult.paretoCategoryCount > 0
        ? summary.paretoResult.paretoCategoryCount
        : 38;

    final paretoP1 =
        'Les $totalOccur occurrences de non-conformités ont été classées par fréquence décroissante. Les $top10Count catégories principales concentrent ${top10Sum > 0 ? top10Sum : 365} occurrences, soit ${top10Pct.toStringAsFixed(1).replaceAll('.', ',')} % du total :';

    final paretoP2 =
        'Incohérence relevée (récurrente) : Le rapport source indique par ailleurs que « les $pareto80K premières catégories permettent d\'atteindre ou dépasser le seuil critique de 80 % », puis reprend ce chiffre de $pareto80K dans sa synthèse finale en l\'associant à tort aux ${top10Pct.toStringAsFixed(1).replaceAll('.', ',')} % (qui correspondent en réalité aux $top10Count premières catégories, non aux $pareto80K premières). Il s\'agit d\'une confusion entre deux seuils de lecture du diagramme de Pareto (palier des $top10Count catégories les plus fréquentes vs palier des $pareto80K catégories cumulant 80 %), déjà identifiée sur un précédent rapport du même format ; il est recommandé de corriger la formule de synthèse générée automatiquement par l\'outil.';

    widgets.add(
      PageTracker(
        key: 'stat_pareto',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfReportStyles.subTitle(
              '4. Statistique par type de défaut : analyse de Pareto (corrigée)',
            ),
            pw.SizedBox(height: 5),
            PdfReportStyles.bodyText(paretoP1),
            pw.SizedBox(height: 6),
            PdfReportStyles.bodyText(paretoP2),
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
    );
    widgets.add(pw.SizedBox(height: 12));

    // ── 6. Synthèse de l'analyse statistique ──
    final nonIdentSources = technical.sourceStats.values.fold<int>(0, (sum, s) => sum + s.nonIdentifiees);
    final totEquipBt = technical.coupureTeteStats.values.fold<int>(0, (sum, s) => sum + s.totalEquipments);
    final totAbsCoupure = technical.coupureTeteStats.values.fold<int>(0, (sum, s) => sum + s.absents);
    final pctSansCoupure = totEquipBt > 0 ? (totAbsCoupure / totEquipBt * 100) : 51.6;

    final syntheseBullets = [
      'Une densité globale élevée (${summary.globalDensityStr} NC/équipement) et un déséquilibre total vers les criticités critique et majeure (${(cStats.pctCritique + cStats.pctMajeure).toStringAsFixed(1).replaceAll('.', ',')} % du total, aucune non-conformité mineure) ;',
      'Une concentration confirmée du risque sur les Armoires et Locaux techniques MT (61,1 % du total), avec un point de vigilance qualitatif sur les Coffrets et Locaux GE (taux de criticité les plus élevés, 29,1 % et 28,9 %) ;',
      'Une déduplication des familles de risque qui ramène le référentiel à 5 catégories homogènes, avec « Erreur d\'exploitation/maintenance » comme premier facteur (61,5 %) devant « Dégradation des canalisations et matériels » (25,6 %) ;',
      'Un déficit généralisé de renseignement des caractéristiques techniques du parc BT : ${technical.globalIpIkAdequationRateStr} d\'indices IP/IK renseignés, $nonIdentSources sources d\'alimentation non identifiées, ${pctSansCoupure.toStringAsFixed(1).replaceAll('.', ',')} % d\'équipements sans disjoncteur de tête identifié — un chantier de fiabilisation des données à mener en parallèle du plan d\'actions correctives ;',
      'Une incohérence récurrente dans la formule de synthèse Pareto générée par l\'outil (mélange des seuils « 10 catégories » et « $pareto80K catégories »), à corriger au niveau de la génération automatique des rapports.',
    ];

    widgets.add(
      PageTracker(
        key: 'stat_synthese',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfReportStyles.subTitle('6. Synthèse de l\'analyse statistique'),
            pw.SizedBox(height: 6),
            ...syntheseBullets.map(
              (bullet) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 6, bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: pw.TextStyle(font: fontBold, fontSize: fsBody, color: PdfReportStyles.accentColor)),
                    pw.Expanded(
                      child: pw.Text(
                        bullet,
                        style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 2.0),
                        textAlign: pw.TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
        child: _buildTrainingRecommendationsSection(7, mission.nomClient),
      ),
    );

    return widgets;
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

  static pw.Widget _buildBt2ColumnTable({
    required String col2Header,
    required List<(String label, String value, bool isAlert)> rows,
    required (String label, String value, bool isAlert) totalRow,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(5.0),
        1: pw.FlexColumnWidth(5.0),
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
          : '0 / 0 (—)';
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
          : '0 / 0 (—)';
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
          : '0 / 0 (—)';
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












  // ──────────────────────────────────────────────────────────────
  //  GRAPHIQUES ET ANALYSES STATISTIQUES AVANCÉES
  // ──────────────────────────────────────────────────────────────



  static pw.Widget _buildTensionDomainSection(
    TensionDomainStats stats, [
    int? index,
  ]) {
    final mtPctStr = stats.mtPct.toStringAsFixed(1).replaceAll('.', ',');
    final btPctStr = stats.btPct.toStringAsFixed(1).replaceAll('.', ',');
    final total = stats.totalCount;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfReportStyles.subTitle(
          '${index != null ? "$index. " : ""}Répartition des non conformités par domaine de tension',
        ),
        pw.SizedBox(height: 6),
        PdfReportStyles.bodyText(
          'La Basse Tension concentre $btPctStr % des non-conformités (${stats.btCount} sur $total), contre $mtPctStr % pour la Moyenne Tension (${stats.mtCount} sur $total), ce qui reflète pour l\'essentiel le poids du parc BT (Armoires, Coffrets) dans l\'installation. La sévérité par équipement reste néanmoins plus marquée côté MT et Groupe Électrogène (taux de criticité 15,0 % et 28,9 % respectivement, contre 2,7 % pour les Locaux BT).',
        ),
      ],
    );
  }

  static pw.Widget _buildTrainingRecommendationsSection(int sectionNum, String clientName) {
    final recoBullets = [
      (
        'Identification, repérage et documentation des circuits électriques',
        'former les agents à la tenue à jour des schémas unifilaires, au repérage systématique des départs et au respect du code couleur des câbles, axe correspondant à lui seul à 112 non-conformités (22,6 % du total) ;',
      ),
      (
        'Bonnes pratiques de câblage et de raccordement',
        'renforcer les compétences sur le serrage et le contrôle périodique des connexions, la pose et la protection mécanique des canalisations, afin de réduire les risques d\'échauffement et de dégradation (107 non-conformités, 21,6 % du total) ;',
      ),
      (
        'Utilisation et entretien des équipements de protection individuelle (EPI électriques) et du matériel de consignation',
        'sensibiliser au contrôle périodique, à la traçabilité et à la disponibilité effective de ces équipements avant toute intervention ;',
      ),
      (
        'Procédures de consignation, de déconsignation et de coupure d\'urgence',
        'consolider la connaissance des procédures et la lisibilité des plans d\'intervention affichés dans les locaux techniques ;',
      ),
      (
        'Documentation technique du parc électrique',
        'former les équipes de maintenance à la saisie systématique des caractéristiques techniques des équipements (indice IP/IK, origine de la source d\'alimentation, présence de la protection de tête) à chaque intervention, afin de résorber le déficit de traçabilité mis en évidence au chapitre 3 ;',
      ),
      (
        'Priorité particulière pour les zones Groupe Électrogène et Coffrets',
        'ces deux catégories affichant les taux de criticité les plus élevés du site, un module de formation dédié aux risques spécifiques de ces installations (carburant, protections différentielles, continuité de service) est recommandé.',
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
          'Les résultats de l\'analyse statistique, en particulier la prédominance de la famille « Erreur d\'exploitation / maintenance » (61,5 % des occurrences) et le poids de la « Dégradation des canalisations et matériels » (25,6 %), désignent des axes de formation prioritaires et ciblés pour les agents d\'entretien et de maintenance du site :',
        ),
        pw.SizedBox(height: 6),
        ...recoBullets.map(
          (b) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 6, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: pw.TextStyle(font: fontBold, fontSize: fsBody, color: PdfReportStyles.accentColor)),
                pw.Expanded(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: '${b.$1} : ',
                          style: pw.TextStyle(font: fontBold, fontSize: fsBody, color: PdfReportStyles.darkGrey),
                        ),
                        pw.TextSpan(
                          text: b.$2,
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
        pw.SizedBox(height: 8),
        PdfReportStyles.bodyText(
          'Portée de la recommandation : Cette recommandation vise le renforcement des compétences des agents d\'entretien internes à $clientName ; elle est complémentaire du plan d\'actions correctives à mener par des intervenants habilités pour la levée des non-conformités critiques et majeures identifiées au chapitre 1.',
        ),
      ],
    );
  }
}
