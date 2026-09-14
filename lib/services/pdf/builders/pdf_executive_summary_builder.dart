import 'package:flutter/foundation.dart';
import 'package:inspec_app/services/ai/executive_summary_snapshot.dart';
import 'package:inspec_app/services/ai/mission_executive_summary_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/ai/executive_summary_data.dart';
import 'package:inspec_app/services/statistics/mission_statistics.dart';
import 'package:inspec_app/services/statistics/mission_statistics_collector.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

/// Builder responsable du Résumé Exécutif KES (12 sections officielles, fidélité stricte au document de référence)
class PdfExecutiveSummaryBuilder {
  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();

  static const double fsH1 = PdfReportStyles.fsH1;
  static const double fsH2 = PdfReportStyles.fsH2;
  static const double fsH3 = PdfReportStyles.fsH3;
  static const double fsBody = PdfReportStyles.fsBody;
  static const double fsSmall = PdfReportStyles.fsSmall;

  /// Construit la section « RÉSUMÉ EXÉCUTIF » structurée en 12 sections officielles selon la spécification de référence KES.
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
    final statsSummary = MissionStatisticsCollector.collectSummary(mission.id);
    final technical = statsSummary.technical;
    final cStats = statsSummary.criticalityStats;

    // ── Entête de section RÉSUMÉ EXÉCUTIF ──
    widgets.add(
      PageTracker(
        key: 'resume_executif',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.sectionBox('RESUME EXECUTIF'),
      ),
    );
    widgets.add(pw.SizedBox(height: 10));

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
            data.contexte.paragraph.replaceAll('(MT/BT)', '(HTA/BT)'),
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
          if (data.syntheseResultats.introParagraph.isNotEmpty) ...[
            pw.SizedBox(height: 4),
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
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 6));

    // 2.1. Indicateurs clés de la mission
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_2_1',
        registry: trackedPages,
        offset: offset,
        child: pw.Text(
          '2.1. Indicateurs clés de la mission',
          style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(_build12IndicateursTable(statsSummary, snapshot, technical));
    widgets.add(pw.SizedBox(height: 8));

    // 2.2. Criticité
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_2_2',
        registry: trackedPages,
        offset: offset,
        child: pw.Text(
          '2.2. Criticité',
          style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      pw.Text(
        'Les vérifications ont permis de recenser ${statsSummary.totalNC} non-conformités sur l\'ensemble du périmètre, soit une densité moyenne de :',
        style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 2.0),
      ),
    );
    widgets.add(pw.SizedBox(height: 3));
    widgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('-  ${statsSummary.densityHtaStr} non-conformités par équipement HTA:', style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey)),
            pw.SizedBox(height: 1.5),
            pw.Text('-  ${statsSummary.densityBtStr} non-conformités par équipement BT:', style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey)),
            pw.SizedBox(height: 1.5),
            pw.Text('-  ${statsSummary.globalDensityStr} non-conformités par équipement HTA+BT:', style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey)),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 5));
    widgets.add(_buildEnrichedDomainCriticalityTable(statsSummary, totalEquipments: snapshot.equipmentCount));
    widgets.add(pw.SizedBox(height: 5));
    widgets.add(
      pw.Text(
        'Avec ${cStats.pctCritique.toStringAsFixed(1).replaceAll('.', ',')} % de non-conformités critiques et ${cStats.pctMajeure.toStringAsFixed(1).replaceAll('.', ',')} % majeures, soit 100,0 % des écarts relevant des deux niveaux de gravité les plus élevés, et une absence totale de non-conformité mineure, le site présente un profil de risque très largement supérieur aux seuils habituellement admis en exploitation maîtrisée (10 à 15 %).',
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

    // ── 3. Facteurs de risque prépondérants ──
    widgets.add(pw.NewPage(freeSpace: 460));
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_3',
        registry: trackedPages,
        offset: offset,
        child: _subSectionHeader('3. Facteurs de risque prépondérants'),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      pw.Text(
        'Au-delà de la répartition par équipement, l\'analyse par nature de risque identifie les facteurs suivants, qui concernent directement la sécurité des personnes et la protection des biens',
        style: pw.TextStyle(
          font: fontRegular,
          fontSize: fsBody,
          color: PdfReportStyles.darkGrey,
          lineSpacing: 2.5,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 5));
    widgets.add(_buildEnrichedRiskFamilyMatrixTable(technical.riskFamilyMatrix));
    widgets.add(pw.SizedBox(height: 10));

    // ── 4. Répartition des non-conformités ──
    widgets.add(pw.NewPage(freeSpace: 120));
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_4',
        registry: trackedPages,
        offset: offset,
        child: _subSectionHeader('4. Répartition des non-conformités'),
      ),
    );
    widgets.add(pw.SizedBox(height: 6));

    // 4.1 Analyse Moyenne Tension (HTA)
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_4_1',
        registry: trackedPages,
        offset: offset,
        child: pw.Text(
          '4.1. Analyse Moyenne Tension (HTA)',
          style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      pw.Text(
        'A. Disposition constructive et Conditions d’exploitation des locaux techniques',
        style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
      ),
    );
    widgets.add(pw.SizedBox(height: 2));
    widgets.add(_buildLocauxStatsTable(technical.locauxMtFindings, isHta: true));
    widgets.add(pw.SizedBox(height: 6));
    widgets.add(pw.NewPage(freeSpace: 120));
    widgets.add(
      pw.Text(
        'B. Exploitation et maintenance',
        style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
      ),
    );
    widgets.add(pw.SizedBox(height: 2));
    widgets.add(
      _buildCategoryCrossTable(
        technical.mtCategoriesCrossRows,
        technical.mtTotalCrossRow,
        'MT',
      ),
    );
    widgets.add(pw.SizedBox(height: 6));
    widgets.add(pw.NewPage(freeSpace: 120));
    widgets.add(
      pw.Text(
        'C. Non conformités majeures',
        style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
      ),
    );
    widgets.add(pw.SizedBox(height: 2));
    widgets.add(_buildTopFindingsTable(technical.top5Hta, 'Aucune non-conformité MT recensée'));
    widgets.add(pw.SizedBox(height: 8));

    // 4.2 Analyse Basse Tension (BT)
    widgets.add(pw.NewPage(freeSpace: 120));
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_4_2',
        registry: trackedPages,
        offset: offset,
        child: pw.Text(
          '4.2. Analyse Basse Tension (BT)',
          style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      pw.Text(
        'A. Disposition constructive et Conditions d’exploitation des locaux techniques',
        style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
      ),
    );
    widgets.add(pw.SizedBox(height: 2));
    widgets.add(_buildLocauxStatsTable(technical.locauxBtFindings, isHta: false));
    widgets.add(pw.SizedBox(height: 6));
    widgets.add(pw.NewPage(freeSpace: 130));
    widgets.add(
      pw.Text(
        'B. Exploitation et maintenance',
        style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
      ),
    );
    widgets.add(pw.SizedBox(height: 2));
    widgets.add(
      _buildCategoryCrossTable(
        technical.btCategoriesCrossRows,
        technical.btTotalCrossRow,
        'BT',
      ),
    );
    widgets.add(pw.SizedBox(height: 6));
    widgets.add(pw.NewPage(freeSpace: 120));
    widgets.add(
      pw.Text(
        'D. Non conformités majeures',
        style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
      ),
    );
    widgets.add(pw.SizedBox(height: 2));
    widgets.add(_buildTopFindingsTable(technical.top5Bt, 'Aucune non-conformité BT recensée'));
    widgets.add(pw.SizedBox(height: 10));

    // ── 5. Diversification des marques des appareillages de protection ──
    widgets.add(pw.NewPage(freeSpace: 130));
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_5',
        registry: trackedPages,
        offset: offset,
        child: _subSectionHeader('5. Diversification des marques des appareillages de protection'),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      pw.Text(
        'La diversité des marques et gammes de protections complexifie la filiation, la sélectivité et la coordination des appareillages, et peut compromettre les performances de protection en cas de court-circuit en l’absence de justification technique des associations amont/aval.',
        style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 2.5),
        textAlign: pw.TextAlign.justify,
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(_buildMarquesTable(technical));
    widgets.add(pw.SizedBox(height: 10));

    // ── 6. Courbes et protections ──
    widgets.add(pw.NewPage(freeSpace: 100));
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_6',
        registry: trackedPages,
        offset: offset,
        child: _subSectionHeader('6. Courbes et protections'),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(_buildCourbesTable(technical));
    widgets.add(pw.SizedBox(height: 10));

    // ── 7. Adéquation ICC / PDC ──
    widgets.add(pw.NewPage(freeSpace: 100));
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_7',
        registry: trackedPages,
        offset: offset,
        child: _subSectionHeader('7. Adéquation ICC / PDC'),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(_buildAdequationTable(technical));
    widgets.add(pw.SizedBox(height: 10));

    // ── 8. Proportion type de câble par section ──
    widgets.add(pw.NewPage(freeSpace: 110));
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_8',
        registry: trackedPages,
        offset: offset,
        child: _subSectionHeader('8. Proportion type de câble par section'),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(_buildCablesTable(technical));
    widgets.add(pw.SizedBox(height: 10));

    // ── 9. Adéquation classement des zones, et indices des équipements ──
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_9',
        registry: trackedPages,
        offset: offset,
        child: _subSectionHeader('9. Adéquation classement des zones, et indices des équipements'),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(_buildIpIkTable(technical));
    widgets.add(pw.SizedBox(height: 10));

    // ── 10. Renforcement des compétences ──
    final competencyItems = [
      'Consignation et sécurité électriques MT/BT',
      'Lecture et mise à jour des schémas',
      'Protections et Sélectivité',
      'Câbles, connexions et thermographie',
      'Parafoudre, terre et surtensions',
      'Groupes électrogènes / inverseurs',
    ];

    widgets.add(
      PageTracker(
        key: 'resume_executif_1_10',
        registry: trackedPages,
        offset: offset,
        child: _subSectionHeader('10. Renforcement des compétences'),
      ),
    );
    widgets.add(pw.SizedBox(height: 5));
    for (final item in competencyItems) {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 6, bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('• ', style: pw.TextStyle(font: fontBold, fontSize: fsBody, color: PdfReportStyles.accentColor)),
              pw.Expanded(
                child: pw.Text(
                  item,
                  style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey),
                ),
              ),
            ],
          ),
        ),
      );
    }
    widgets.add(pw.SizedBox(height: 10));

    // ── 11. Recommandations prioritaires hiérarchisées ──
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
                style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColor.fromHex('#B71C1C')),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Priorité 1 — Action Immédiate',
                style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColor.fromHex('#B71C1C')),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                PdfReportStyles.cleanRecommendationText(data.recommandationsPrioritaires.priority1Immediate),
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
                style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColor.fromHex('#C2410C')),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Priorité 2 — Court Terme',
                style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColor.fromHex('#C2410C')),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                PdfReportStyles.cleanRecommendationText(data.recommandationsPrioritaires.priority2ShortTerm),
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
                style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Priorité 3 — Moyen Terme',
                style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                PdfReportStyles.cleanRecommendationText(data.recommandationsPrioritaires.priority3MediumTerm),
                style: pw.TextStyle(font: fontRegular, fontSize: 7.5),
              ),
            ),
          ],
        ),
      );
    }

    final recoHeaderRow = pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            'CRITICITÉ',
            style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            'NIVEAU DE PRIORITÉ',
            style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            'ACTION CORRECTIVE RECOMMANDÉE',
            style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );

    final recoHeaderWidget = PageTracker(
      key: 'resume_executif_1_11',
      registry: trackedPages,
      offset: offset,
      child: _subSectionHeader('11. Recommandations prioritaires hiérarchisées'),
    );

    final recoIntroWidget = pw.Text(
      'Les actions correctives sont hiérarchisées en trois niveaux de priorité :',
      style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 2.5),
      textAlign: pw.TextAlign.justify,
    );

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

    // ── 12. Appréciation globale ──
    widgets.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PageTracker(
            key: 'resume_executif_1_12',
            registry: trackedPages,
            offset: offset,
            child: _subSectionHeader('12. Appréciation globale'),
          ),
          pw.SizedBox(height: 6),
          _buildAppreciationGlobaleText(statsSummary, technical),
        ],
      ),
    );

    return widgets;
  }

  static pw.Widget _buildAppreciationGlobaleText(
    MissionStatisticsSummary stats,
    TechnicalEnrichmentResult technical,
  ) {
    final cStats = stats.criticalityStats;
    final density = stats.globalDensityStr;
    final pctCrit = cStats.pctCritique.toStringAsFixed(1).replaceAll('.', ',');
    final pctMaj = cStats.pctMajeure.toStringAsFixed(1).replaceAll('.', ',');

    final p1 = 'La vérification périodique des installations électriques du site met en évidence un niveau de maîtrise du risque électrique insuffisant, avec une densité de $density NC/équipement et 100 % des écarts classés critiques ($pctCrit %) ou majeurs ($pctMaj %). Au-delà des non-conformités réglementaires classiques, l\'analyse enrichie révèle un déficit générique de documentation technique du parc (sources d\'alimentation, protections de tête, indices IP/IK), qui constitue en soi un facteur de risque et un frein à la maintenance préventive.';
    final p2 = 'Les vulnérabilités majeures relevées concernent prioritairement :\n'
        '• L\'absence systématique ou le faible taux d\'équipement en parafoudres sur les tableaux de distribution BT (armoires, coffrets, TGBT) ;\n'
        '• La présence significative de départs et circuits terminaux non identifiés, privant les exploitants de schémas unifilaires fiables ;\n'
        '• L\'absence de dispositifs de coupure et de sectionnement dédiés en tête d\'une proportion notable de coffrets et armoires divisionnaires.';
    final p3 = 'Une intervention corrective immédiate sur les non-conformités critiques s\'impose pour neutraliser les risques d\'électrisation et d\'incendie, complétée d\'un programme de fiabilisation de la documentation technique et de renforcement des compétences des équipes d\'exploitation.';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildFormattedText(p1),
        pw.SizedBox(height: 6),
        _buildFormattedText(p2),
        pw.SizedBox(height: 6),
        _buildFormattedText(p3),
      ],
    );
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

  static pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
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

  static pw.Widget _build12IndicateursTable(
    MissionStatisticsSummary summary,
    ExecutiveSummarySnapshot snapshot,
    TechnicalEnrichmentResult technical,
  ) {
    final findings = summary.inventory.findings;
    final htaFindings = findings.where((f) => f.tensionDomain == TensionDomain.mt).toList();
    final btFindings = findings.where((f) => f.tensionDomain == TensionDomain.bt).toList();

    final htaCrit = htaFindings.where((f) => f.criticality.toLowerCase() == 'critique').length;
    final htaTot = summary.tensionDomainStats.mtCount;
    final htaCritPct = htaTot > 0 ? (htaCrit / htaTot * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';

    final btCrit = btFindings.where((f) => f.criticality.toLowerCase() == 'critique').length;
    final btTot = summary.tensionDomainStats.btCount;
    final btCritPct = btTot > 0 ? (btCrit / btTot * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';

    final htaRisk = double.parse(htaCritPct.replaceAll(',', '.')) >= 15.0 ? 'niveau de risque élevé' : 'niveau de risque modéré';
    final btRisk = double.parse(btCritPct.replaceAll(',', '.')) >= 15.0 ? 'niveau de risque élevé' : 'niveau de risque modéré';

    // Tri pour trouver la catégorie la plus dense en HTA et BT
    final sortedMtCats = [...technical.mtCategoriesCrossRows]..sort((a, b) => b.densite.compareTo(a.densite));
    final densestMt = sortedMtCats.isNotEmpty ? sortedMtCats.first : null;

    final sortedBtCats = [...technical.btCategoriesCrossRows]..sort((a, b) => b.densite.compareTo(a.densite));
    final densestBt = sortedBtCats.isNotEmpty ? sortedBtCats.first : null;

    final densestMtStr = densestMt != null
        ? '${densestMt.categoryName} : ${densestMt.densiteStr} NC/équipement (${densestMt.tauxCritiqueStr} de criticité)'
        : 'Aucune installation HTA';
    final densestBtStr = densestBt != null
        ? '${densestBt.categoryName} : ${densestBt.densiteStr} NC/équipement (${densestBt.tauxCritiqueStr} de criticité)'
        : 'Aucune installation BT';

    // Marques en tête
    final sortedBrands = technical.globalMarquesDeTete.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final brandsText = sortedBrands.isNotEmpty
        ? sortedBrands.take(3).map((e) {
            final pct = technical.globalCoupureTeteTotal > 0
                ? (e.value / technical.globalCoupureTeteTotal * 100).toStringAsFixed(1).replaceAll('.', ',')
                : '0,0';
            return '- ${e.key} : ${e.value} , soit $pct %';
          }).join('\n')
        : '- Donnée non renseignée sur le terrain';

    // Câbles départs et terminaux
    String formatCableSectionList(Map<String, int> sections, int total) {
      if (sections.isEmpty) return '  (sections non renseignées)';
      final sorted = sections.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return sorted.take(2).map((e) {
        final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';
        return '  ${e.key} : $pct %';
      }).join('\n');
    }

    int depAluTotal = 0;
    int depCuTotal = 0;
    final depAluSec = <String, int>{};
    final depCuSec = <String, int>{};

    int termAluTotal = 0;
    int termCuTotal = 0;
    final termAluSec = <String, int>{};
    final termCuSec = <String, int>{};

    for (final r in technical.cablesMatrix) {
      final dAlu = r.departsBreakdown['Aluminium'];
      if (dAlu != null) {
        depAluTotal += dAlu.count;
        dAlu.sectionsCount.forEach((k, v) => depAluSec[k] = (depAluSec[k] ?? 0) + v);
      }
      final dCu = r.departsBreakdown['Cuivre'];
      if (dCu != null) {
        depCuTotal += dCu.count;
        dCu.sectionsCount.forEach((k, v) => depCuSec[k] = (depCuSec[k] ?? 0) + v);
      }
      final tAlu = r.circuitsTerminauxBreakdown['Aluminium'];
      if (tAlu != null) {
        termAluTotal += tAlu.count;
        tAlu.sectionsCount.forEach((k, v) => termAluSec[k] = (termAluSec[k] ?? 0) + v);
      }
      final tCu = r.circuitsTerminauxBreakdown['Cuivre'];
      if (tCu != null) {
        termCuTotal += tCu.count;
        tCu.sectionsCount.forEach((k, v) => termCuSec[k] = (termCuSec[k] ?? 0) + v);
      }
    }

    final totalDepCables = depAluTotal + depCuTotal;
    final depAluPct = totalDepCables > 0 ? (depAluTotal / totalDepCables * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';
    final depCuPct = totalDepCables > 0 ? (depCuTotal / totalDepCables * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';

    final totalTermCables = termAluTotal + termCuTotal;
    final termAluPct = totalTermCables > 0 ? (termAluTotal / totalTermCables * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';
    final termCuPct = totalTermCables > 0 ? (termCuTotal / totalTermCables * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';

    final cablesVal = 'Depart\n'
        'Aluminium : $depAluPct %\n'
        '${formatCableSectionList(depAluSec, depAluTotal)}\n'
        'Cuivre : $depCuPct %\n'
        '${formatCableSectionList(depCuSec, depCuTotal)}\n'
        'Circuit terminaux\n'
        'Aluminium : $termAluPct %\n'
        '${formatCableSectionList(termAluSec, termAluTotal)}\n'
        'Cuivre : $termCuPct %\n'
        '${formatCableSectionList(termCuSec, termCuTotal)}';

    pw.TableRow buildRow(String label, String value) {
      return pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(5),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.headerColor),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(5),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              value,
              style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfReportStyles.darkGrey, lineSpacing: 1.8),
            ),
          ),
        ],
      );
    }

    final htaDispo = technical.riskFamilyMatrix.totalHtaDispo;
    final htaExploit = technical.riskFamilyMatrix.totalHtaExploit;
    final htaDispoPct = htaTot > 0 ? (htaDispo / htaTot * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';
    final htaExploitPct = htaTot > 0 ? (htaExploit / htaTot * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';

    final btDispo = technical.riskFamilyMatrix.totalBtDispo;
    final btExploit = technical.riskFamilyMatrix.totalBtExploit;
    final btDispoPct = btTot > 0 ? (btDispo / btTot * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';
    final btExploitPct = btTot > 0 ? (btExploit / btTot * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';

    String formatCoupure(DomainObjectType type) {
      final s = technical.coupureTeteStats[type];
      final presents = s?.presents ?? 0;
      final total = s?.totalEquipments ?? 0;
      final pct = s?.formattedPercentage ?? '0,0 %';
      return '$presents/$total, soit $pct';
    }

    String formatSource(DomainObjectType type) {
      final s = technical.sourceStats[type];
      final identifiees = s?.identifiees ?? 0;
      final total = s?.totalEquipments ?? 0;
      final pct = s?.formattedPercentage ?? '0,0 %';
      return '$identifiees/$total, soit $pct';
    }

    String formatAdequation(DomainObjectType type) {
      final s = technical.adequationIccPdcStats[type];
      final conformes = s?.conformes ?? 0;
      final denom = (s != null && s.evaluables > 0) ? s.evaluables : (s?.totalElements ?? 0);
      final rate = (s != null && s.evaluables > 0 && s.formattedComplianceRate != 'Non évaluable')
          ? s.formattedComplianceRate
          : '0,0 %';
      return '$conformes/$denom, soit $rate';
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.8),
        1: pw.FlexColumnWidth(6.2),
      },
      children: [
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Indicateur',
                style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Valeur',
                style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
        buildRow(
          'Périmètre couvert',
          'Local Technique Moyenne tension : ${technical.totalLocauxMt}\n'
          'Local Technique GE : ${technical.totalLocauxGe}\n'
          'Local technique Basse tension : ${technical.totalLocauxBt}\n'
          'TGBT : ${technical.totalTgbt}\n'
          'Armoires : ${technical.totalArmoires}\n'
          'Coffrets : ${technical.totalCoffrets}\n'
          'Classement des zones : ${technical.totalZonesClassees}\n'
          'Essais : ${technical.essaisCoverage.totalEssais}\n'
          '  Prise de terre : ${technical.essaisCoverage.prisesTerreCount}\n'
          '  Test DDR : ${technical.essaisCoverage.testDdrCount}\n'
          '  Mesure d’isolement : ${technical.essaisCoverage.mesureIsolementCount}\n'
          '  Démarrage GE : ${technical.essaisCoverage.demarrageGeCount > 0 ? "Réalisé (${technical.essaisCoverage.demarrageGeCount})" : "Non réalisé"}\n'
          '  Test arret d’urgence : ${technical.essaisCoverage.arretUrgenceCount > 0 ? "Réalisé (${technical.essaisCoverage.arretUrgenceCount})" : "Non réalisé"}\n'
          '  Test CPI : ${technical.essaisCoverage.testCpiCount}\n'
          '  Mise a la terre : ${technical.essaisCoverage.continuitePeCount}',
        ),
        buildRow(
          'Non-conformités par domaine de tension',
          'NC HTA : $htaTot NC (${summary.tensionDomainStats.mtPercentageStr})\n'
          '- Disposition constructive : $htaDispo NC ($htaDispoPct %)\n'
          '- Exploitation et maintenance : $htaExploit NC ($htaExploitPct %)\n'
          'NC BT : $btTot NC (${summary.tensionDomainStats.btPercentageStr})\n'
          '- Disposition constructive : $btDispo NC ($btDispoPct %)\n'
          '- Exploitation et maintenance : $btExploit NC ($btExploitPct %)',
        ),
        buildRow(
          'Densité moyenne globale',
          'HTA : ${summary.densityHtaStr} NC/équipement\n'
          'BT : ${summary.densityBtStr} NC/équipement\n'
          'HTA + BT : ${summary.globalDensityStr} NC/équipement',
        ),
        buildRow(
          'Part des NC critiques',
          'HTA : $htaCritPct % - $htaRisk\n'
          'BT : $btCritPct % - $btRisk',
        ),
        buildRow(
          'Catégorie la plus dense',
          'HTA\n'
          '$densestMtStr\n'
          'BT\n'
          '$densestBtStr',
        ),
        buildRow(
          'Présence organe de coupure en tête d’installation',
          'Inverseur : ${formatCoupure(DomainObjectType.inverseur)}\n'
          'TGBT : ${formatCoupure(DomainObjectType.tgbt)}\n'
          'Armoire : ${formatCoupure(DomainObjectType.armoire)}\n'
          'Coffret : ${formatCoupure(DomainObjectType.coffret)}',
        ),
        buildRow(
          'Identification des sources d\'alimentation',
          'Inverseur : ${formatSource(DomainObjectType.inverseur)}\n'
          'TGBT : ${formatSource(DomainObjectType.tgbt)}\n'
          'Armoire : ${formatSource(DomainObjectType.armoire)}\n'
          'Coffret : ${formatSource(DomainObjectType.coffret)}',
        ),
        buildRow(
          'Adéquation entre l’ Intensité du courant de court circuit et le pouvoir de coupure des appareillages de protection',
          'Inverseur : ${formatAdequation(DomainObjectType.inverseur)}\n'
          'TGBT : ${formatAdequation(DomainObjectType.tgbt)}\n'
          'Armoire : ${formatAdequation(DomainObjectType.armoire)}\n'
          'Coffret : ${formatAdequation(DomainObjectType.coffret)}',
        ),
        buildRow(
          'Présence Parafoudre',
          'Inverseur : ${technical.parafoudreStats[DomainObjectType.inverseur]?.avecParafoudre ?? 0}/${technical.parafoudreStats[DomainObjectType.inverseur]?.totalEquipments ?? 0}, soit ${technical.parafoudreStats[DomainObjectType.inverseur]?.formattedPercentage ?? "0,0 %"}\n'
          'TGBT : ${technical.parafoudreStats[DomainObjectType.tgbt]?.avecParafoudre ?? 0}/${technical.parafoudreStats[DomainObjectType.tgbt]?.totalEquipments ?? 0}, soit ${technical.parafoudreStats[DomainObjectType.tgbt]?.formattedPercentage ?? "0,0 %"}\n'
          'Armoire : ${technical.parafoudreStats[DomainObjectType.armoire]?.avecParafoudre ?? 0}/${technical.parafoudreStats[DomainObjectType.armoire]?.totalEquipments ?? 0}, soit ${technical.parafoudreStats[DomainObjectType.armoire]?.formattedPercentage ?? "0,0 %"}\n'
          'Coffret : ${technical.parafoudreStats[DomainObjectType.coffret]?.avecParafoudre ?? 0}/${technical.parafoudreStats[DomainObjectType.coffret]?.totalEquipments ?? 0}, soit ${technical.parafoudreStats[DomainObjectType.coffret]?.formattedPercentage ?? "0,0 %"}',
        ),
        buildRow(
          'Adéquation classement des zones et Indice de protection IP/IK requis',
          technical.totalZonesClassees > 0
              ? 'Il y a ${technical.totalZonesClassees} zone(s) classée(s), et la proportion de l\'adéquation entre le classement et l\'indice requis pour les équipements est de ${technical.globalIpIkAdequationRateStr}'
              : 'Il y a 0 zone classée répertoriée, adéquation globale non évaluable en l\'absence d\'exigences IP/IK formalisées',
        ),
        buildRow(
          'Diversification de marque des appareillages de protection',
          'Sur ${technical.globalCoupureTeteTotal} appareillage(s) en tête d’installations\n'
          '$brandsText',
        ),
        buildRow(
          'Proportion nature des câbles par section, départs et circuits terminaux',
          cablesVal,
        ),
      ],
    );
  }

  static pw.Widget _buildEnrichedDomainCriticalityTable(
    MissionStatisticsSummary stats, {
    required int totalEquipments,
  }) {
    final inv = stats.inventory;
    final mtFindings = inv.findings.where((f) => f.tensionDomain == TensionDomain.mt).toList();
    final btFindings = inv.findings.where((f) => f.tensionDomain == TensionDomain.bt).toList();

    final mtCrit = mtFindings.where((f) => f.criticality.toLowerCase() == 'critique').length;
    final mtMaj = mtFindings.where((f) => f.criticality.toLowerCase() == 'majeure').length;
    final mtMin = mtFindings.where((f) => f.criticality.toLowerCase() == 'mineure').length;
    final mtTot = mtFindings.length;

    final btCrit = btFindings.where((f) => f.criticality.toLowerCase() == 'critique').length;
    final btMaj = btFindings.where((f) => f.criticality.toLowerCase() == 'majeure').length;
    final btMin = btFindings.where((f) => f.criticality.toLowerCase() == 'mineure').length;
    final btTot = btFindings.length;

    final totCrit = stats.criticalityStats.critique;
    final totMaj = stats.criticalityStats.majeure;
    final totMin = stats.criticalityStats.mineure;
    final totGlobal = stats.criticalityStats.total;

    final mtCritPct = mtTot > 0 ? (mtCrit / mtTot * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';
    final mtMajPct = mtTot > 0 ? (mtMaj / mtTot * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';
    final mtMinPct = mtTot > 0 ? (mtMin / mtTot * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';

    final btCritPct = btTot > 0 ? (btCrit / btTot * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';
    final btMajPct = btTot > 0 ? (btMaj / btTot * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';
    final btMinPct = btTot > 0 ? (btMin / btTot * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';

    final totCritPct = totGlobal > 0 ? (totCrit / totGlobal * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';
    final totMajPct = totGlobal > 0 ? (totMaj / totGlobal * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';
    final totMinPct = totGlobal > 0 ? (totMin / totGlobal * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0';

    final mtEq = stats.htaEquipmentsCount > 0 ? stats.htaEquipmentsCount : 1;
    final btEq = stats.btEquipmentsCount > 0 ? stats.btEquipmentsCount : 1;
    final globEq = stats.totalEquipments > 0 ? stats.totalEquipments : 1;

    final mtCritDens = (mtCrit / mtEq).toStringAsFixed(2).replaceAll('.', ',');
    final mtMajDens = (mtMaj / mtEq).toStringAsFixed(2).replaceAll('.', ',');
    final mtMinDens = (mtMin / mtEq).toStringAsFixed(2).replaceAll('.', ',');

    final btCritDens = (btCrit / btEq).toStringAsFixed(2).replaceAll('.', ',');
    final btMajDens = (btMaj / btEq).toStringAsFixed(2).replaceAll('.', ',');
    final btMinDens = (btMin / btEq).toStringAsFixed(2).replaceAll('.', ',');

    final totCritDens = (totCrit / globEq).toStringAsFixed(2).replaceAll('.', ',');
    final totMajDens = (totMaj / globEq).toStringAsFixed(2).replaceAll('.', ',');
    final totMinDens = (totMin / globEq).toStringAsFixed(2).replaceAll('.', ',');

    const domainColWidths = {
      0: pw.FlexColumnWidth(2.6),
      1: pw.FlexColumnWidth(1.6),
      2: pw.FlexColumnWidth(2.0),
      3: pw.FlexColumnWidth(3.8),
    };

    pw.TableRow buildCritRow(String level, int count, String pct, String dens, {bool isTotal = false}) {
      return pw.TableRow(
        decoration: isTotal ? pw.BoxDecoration(color: PdfReportStyles.lightBlue) : null,
        children: [
          _buildTableCell(level, isBold: isTotal || level == 'Critique', align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
          _buildTableCell(count > 0 || isTotal ? '$count' : '0', isBold: isTotal),
          _buildTableCell('$pct %', isBold: isTotal),
          _buildTableCell(dens, isBold: isTotal),
        ],
      );
    }

    pw.Widget buildBannerTable(String text) {
      return pw.Table(
        border: pw.TableBorder(
          left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
          right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
          bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
        ),
        columnWidths: const {0: pw.FlexColumnWidth(1.0)},
        children: [
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  text,
                  style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      );
    }

    final domainHeaderTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
      ),
      columnWidths: domainColWidths,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('Criticité'),
            _buildTableHeaderCell('Nombre'),
            _buildTableHeaderCell('Part du total'),
            _buildTableHeaderCell('Densité'),
          ],
        ),
      ],
    );

    pw.Widget buildDomainDataTable(List<pw.TableRow> rows) {
      return pw.Table(
        border: pw.TableBorder(
          left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
          right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
          bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
          horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
          verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
        ),
        columnWidths: domainColWidths,
        children: rows,
      );
    }

    return pw.Column(
      children: [
        domainHeaderTable,
        buildBannerTable('HTA'),
        buildDomainDataTable([
          buildCritRow('Critique', mtCrit, mtCritPct, '$mtCritDens NC critique / équipement'),
          buildCritRow('Majeure', mtMaj, mtMajPct, '$mtMajDens NC majeure / équipement'),
          buildCritRow('Mineure', mtMin, mtMinPct, '$mtMinDens NC mineure / équipement'),
          buildCritRow('TOTAL HTA', mtTot, '100', '${stats.densityHtaStr} NC / équipement (moyenne HTA)', isTotal: true),
        ]),
        buildBannerTable('BT'),
        buildDomainDataTable([
          buildCritRow('Critique', btCrit, btCritPct, '$btCritDens NC critique / équipement'),
          buildCritRow('Majeure', btMaj, btMajPct, '$btMajDens NC majeure / équipement'),
          buildCritRow('Mineure', btMin, btMinPct, '$btMinDens NC mineure / équipement'),
          buildCritRow('TOTAL BT', btTot, '100', '${stats.densityBtStr} NC / équipement (moyenne BT)', isTotal: true),
        ]),
        buildBannerTable('HTA + BT'),
        buildDomainDataTable([
          buildCritRow('Critique', totCrit, totCritPct, '$totCritDens NC critique / équipement'),
          buildCritRow('Majeure', totMaj, totMajPct, '$totMajDens NC majeure / équipement'),
          buildCritRow('Mineure', totMin, totMinPct, '$totMinDens NC mineure / équipement'),
          buildCritRow('TOTAL GLOBAL HTA + BT', totGlobal, '100', '${stats.globalDensityStr} NC / équipement (moyenne globale)', isTotal: true),
        ]),
      ],
    );
  }

  static pw.Widget _buildEnrichedRiskFamilyMatrixTable(RiskFamilyCrossMatrix matrix) {
    const riskColWidths = {
      0: pw.FlexColumnWidth(5.5),
      1: pw.FlexColumnWidth(2.2),
      2: pw.FlexColumnWidth(2.3),
    };

    pw.Widget buildRiskBannerTable(String title, PdfColor bgColor, PdfColor textColor) {
      return pw.Table(
        border: pw.TableBorder(
          left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
          right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
          bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
        ),
        columnWidths: const {0: pw.FlexColumnWidth(1.0)},
        children: [
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            decoration: pw.BoxDecoration(color: bgColor),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 3.5),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  title,
                  style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: textColor),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      );
    }

    final riskHeaderTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
      ),
      columnWidths: riskColWidths,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('Famille de risque'),
            _buildTableHeaderCell('Constats'),
            _buildTableHeaderCell('Part'),
          ],
        ),
      ],
    );

    pw.Widget buildRiskDataTable(RiskFamilyQuadrantStats quadrant) {
      final rows = <pw.TableRow>[];
      if (quadrant.topFamilies.isEmpty) {
        rows.add(
          pw.TableRow(
            children: [
              _buildTableCell('Aucun facteur de risque identifié', align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell('0'),
              _buildTableCell('0,0 %'),
            ],
          ),
        );
      } else {
        for (final item in quadrant.topFamilies) {
          rows.add(
            pw.TableRow(
              children: [
                _buildTableCell(item.famille, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
                _buildTableCell('${item.constats}'),
                _buildTableCell(item.formattedPart),
              ],
            ),
          );
        }
      }
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.tableRowAlt),
          children: [
            _buildTableCell('TOTAL', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            _buildTableCell('${quadrant.totalConstats}', isBold: true),
            _buildTableCell(quadrant.totalConstats > 0 ? '100,0 %' : '', isBold: true),
          ],
        ),
      );

      return pw.Table(
        border: pw.TableBorder(
          left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
          right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
          bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
          horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
          verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.5),
        ),
        columnWidths: riskColWidths,
        children: rows,
      );
    }

    return pw.Column(
      children: [
        riskHeaderTable,
        buildRiskBannerTable('HTA', PdfReportStyles.accentColor, PdfColors.white),
        buildRiskBannerTable('DISPOSITION CONSTRUCTIVE', PdfReportStyles.lightBlue, PdfReportStyles.headerColor),
        buildRiskDataTable(matrix.htaDispositionsConstructives),
        buildRiskBannerTable('EXPLOITATION ET MAINTENANCE', PdfReportStyles.lightBlue, PdfReportStyles.headerColor),
        buildRiskDataTable(matrix.htaExploitationMaintenance),

        buildRiskBannerTable('BT', PdfReportStyles.accentColor, PdfColors.white),
        buildRiskBannerTable('DISPOSITION CONSTRUCTIVE', PdfReportStyles.lightBlue, PdfReportStyles.headerColor),
        buildRiskDataTable(matrix.btDispositionsConstructives),
        buildRiskBannerTable('EXPLOITATION ET MAINTENANCE', PdfReportStyles.lightBlue, PdfReportStyles.headerColor),
        buildRiskDataTable(matrix.btExploitationMaintenance),
      ],
    );
  }

  static pw.Widget _buildLocauxStatsTable(LocauxFindingsStats stats, {required bool isHta}) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(6.5),
        1: pw.FlexColumnWidth(3.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('Domaine'),
            _buildTableHeaderCell('Nombre d’observations recensées'),
          ],
        ),
        pw.TableRow(
          children: [
            _buildTableCell(isHta ? 'DISPO CONSTRUCTIVES' : 'Dispo constructives', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            _buildTableCell('${stats.dispoConstructives}'),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.tableRowAlt),
          children: [
            _buildTableCell(isHta ? 'CONDITIONS D’EXPLOITATION' : 'Conditions d’exploitation', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            _buildTableCell('${stats.conditionsExploitation}'),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [
            _buildTableCell('TOTAL', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            _buildTableCell('${stats.total}', isBold: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildCategoryCrossTable(
    List<CategoryCrossAuditRow> rows,
    CategoryCrossAuditRow totalRow,
    String domainLabel,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.4),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.2),
        4: pw.FlexColumnWidth(1.4),
        5: pw.FlexColumnWidth(1.6),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell(domainLabel == 'BT' ? 'Catégorie BT' : 'Catégorie'),
            _buildTableHeaderCell(domainLabel == 'BT' ? 'Equipements' : 'Équipements'),
            _buildTableHeaderCell('NC'),
            _buildTableHeaderCell('Critiques'),
            _buildTableHeaderCell('Majeures'),
            _buildTableHeaderCell('Densité'),
          ],
        ),
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
              _buildTableCell('${rows[i].majeuresCount}'),
              _buildTableCell(rows[i].densiteStr, isBold: true),
            ],
          ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [
            _buildTableCell('TOTAL', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            _buildTableCell('${totalRow.equipementsCount}', isBold: true),
            _buildTableCell('${totalRow.ncCount}', isBold: true),
            _buildTableCell(
              '${totalRow.critiquesCount}',
              isBold: true,
              color: totalRow.critiquesCount > 0 ? PdfColor.fromHex('#B71C1C') : null,
            ),
            _buildTableCell('${totalRow.majeuresCount}', isBold: true),
            _buildTableCell(totalRow.densiteStr, isBold: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTopFindingsTable(List<TopDefectDomainItem> items, String emptyLabel) {
    if (items.isEmpty) {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              _buildTableHeaderCell('N°'),
              _buildTableHeaderCell('Observation'),
              _buildTableHeaderCell('Stats'),
            ],
          ),
          pw.TableRow(
            children: [
              _buildTableCell('-'),
              _buildTableCell(emptyLabel, isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell('0 constat'),
            ],
          ),
        ],
      );
    }

    final totalCount = items.fold<int>(0, (sum, it) => sum + it.count);
    final totalPct = items.fold<double>(0.0, (sum, it) => sum + it.percentageOfDomain);
    final totalCountStr = totalCount > 1 ? '$totalCount constats' : '$totalCount constat';

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.8),
        1: pw.FlexColumnWidth(6.2),
        2: pw.FlexColumnWidth(3.0),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('N°'),
            _buildTableHeaderCell('Observation'),
            _buildTableHeaderCell('Stats'),
          ],
        ),
        for (int i = 0; i < items.length; i++)
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            decoration: pw.BoxDecoration(
              color: i % 2 == 1 ? PdfReportStyles.tableRowAlt : PdfColors.white,
            ),
            children: [
              _buildTableCell('${i + 1}', isBold: true),
              _buildTableCell(
                items[i].title,
                align: pw.TextAlign.left,
                alignment: pw.Alignment.centerLeft,
              ),
              _buildTableCell(
                '${items[i].count} constats, ${items[i].percentageOfDomain.toStringAsFixed(1).replaceAll('.', ',')}%',
                align: pw.TextAlign.center,
              ),
            ],
          ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [
            _buildTableCell('', isBold: true),
            _buildTableCell('TOTAL', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            _buildTableCell(
              '$totalCountStr, ${totalPct.toStringAsFixed(1).replaceAll('.', ',')}%',
              isBold: true,
              align: pw.TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMarquesTable(TechnicalEnrichmentResult technical) {
    String formatBrands(Map<String, int> m, int total) {
      if (m.isEmpty) {
        return total > 0 ? '0 / $total, soit 0,0 %' : '-';
      }
      final sorted = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return sorted.map((e) {
        final pct = total > 0 ? (e.value / total) * 100.0 : 0.0;
        final pctStr = '${pct.toStringAsFixed(1).replaceAll('.', ',')} %';
        return '${e.key} : ${e.value} / $total, soit $pctStr';
      }).join('\n');
    }

    const categories = [
      (DomainObjectType.inverseur, 'INVERSEUR'),
      (DomainObjectType.tgbt, 'TGBT'),
      (DomainObjectType.armoire, 'ARMOIRES'),
      (DomainObjectType.coffret, 'COFFRETS'),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(2.5),
        2: pw.FlexColumnWidth(2.5),
        3: pw.FlexColumnWidth(2.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell(''),
            _buildTableHeaderCell('ORGANE DE TETE'),
            _buildTableHeaderCell('DEPART'),
            _buildTableHeaderCell('CIRCUITS TERMINAUX'),
          ],
        ),
        for (final c in categories)
          ...[
            () {
              final row = technical.marquesMatrix.firstWhere(
                (r) => r.category == c.$1,
                orElse: () => MarquesMatrixRow(
                  category: c.$1,
                  organeDeTete: {},
                  departs: {},
                  circuitsTerminaux: {},
                ),
              );
              return pw.TableRow(
                verticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  _buildTableCell(c.$2, isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
                  _buildTableCell(
                    formatBrands(row.organeDeTete, row.totalTete),
                    align: pw.TextAlign.left,
                    alignment: pw.Alignment.centerLeft,
                  ),
                  _buildTableCell(
                    formatBrands(row.departs, row.totalDeparts),
                    align: pw.TextAlign.left,
                    alignment: pw.Alignment.centerLeft,
                  ),
                  _buildTableCell(
                    formatBrands(row.circuitsTerminaux, row.totalTerminaux),
                    align: pw.TextAlign.left,
                    alignment: pw.Alignment.centerLeft,
                  ),
                ],
              );
            }(),
          ],
      ],
    );
  }

  static pw.Widget _buildCourbesTable(TechnicalEnrichmentResult technical) {
    String formatCourbes(Map<String, int> m, int total) {
      if (m.isEmpty) {
        return total > 0 ? '0 / $total, soit 0,0 %' : '-';
      }
      final sorted = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return sorted.map((e) {
        final pct = total > 0 ? (e.value / total) * 100.0 : 0.0;
        final pctStr = '${pct.toStringAsFixed(1).replaceAll('.', ',')} %';
        return '${e.key} : ${e.value} / $total, soit $pctStr';
      }).join('\n');
    }

    const categories = [
      (DomainObjectType.inverseur, 'INVERSEUR'),
      (DomainObjectType.tgbt, 'TGBT'),
      (DomainObjectType.armoire, 'ARMOIRES'),
      (DomainObjectType.coffret, 'COFFRETS'),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(2.5),
        2: pw.FlexColumnWidth(2.5),
        3: pw.FlexColumnWidth(2.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell(''),
            _buildTableHeaderCell('ORGANE DE TETE'),
            _buildTableHeaderCell('DEPART'),
            _buildTableHeaderCell('CIRCUITS TERMINAUX'),
          ],
        ),
        for (final c in categories)
          ...[
            () {
              final row = technical.courbesMatrix.firstWhere(
                (r) => r.category == c.$1,
                orElse: () => CourbesMatrixRow(
                  category: c.$1,
                  organeDeTete: {},
                  departs: {},
                  circuitsTerminaux: {},
                ),
              );
              return pw.TableRow(
                verticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  _buildTableCell(c.$2, isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
                  _buildTableCell(
                    formatCourbes(row.organeDeTete, row.totalTete),
                    align: pw.TextAlign.left,
                    alignment: pw.Alignment.centerLeft,
                  ),
                  _buildTableCell(
                    formatCourbes(row.departs, row.totalDeparts),
                    align: pw.TextAlign.left,
                    alignment: pw.Alignment.centerLeft,
                  ),
                  _buildTableCell(
                    formatCourbes(row.circuitsTerminaux, row.totalTerminaux),
                    align: pw.TextAlign.left,
                    alignment: pw.Alignment.centerLeft,
                  ),
                ],
              );
            }(),
          ],
      ],
    );
  }

  static pw.Widget _buildAdequationTable(TechnicalEnrichmentResult technical) {
    String formatAdequation(AdequationIccPdcStats? s) {
      if (s == null || s.totalElements == 0) {
        return '-';
      }
      if (s.evaluables == 0) {
        return 'Conforme : 0 / ${s.totalElements}, soit 0,0 %';
      }
      return 'Conforme : ${s.conformes} / ${s.evaluables}, soit ${s.formattedComplianceRate}';
    }

    const categories = [
      (DomainObjectType.inverseur, 'INVERSEUR'),
      (DomainObjectType.tgbt, 'TGBT'),
      (DomainObjectType.armoire, 'ARMOIRES'),
      (DomainObjectType.coffret, 'COFFRETS'),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(2.5),
        2: pw.FlexColumnWidth(2.5),
        3: pw.FlexColumnWidth(2.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell(''),
            _buildTableHeaderCell('ORGANE DE TETE'),
            _buildTableHeaderCell('DEPART'),
            _buildTableHeaderCell('CIRCUITS TERMINAUX'),
          ],
        ),
        for (final c in categories)
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _buildTableCell(c.$2, isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell(
                formatAdequation(technical.adequationIccPdcStats[c.$1]),
                align: pw.TextAlign.left,
                alignment: pw.Alignment.centerLeft,
              ),
              _buildTableCell(
                formatAdequation(technical.pdcDepartStats[c.$1]),
                align: pw.TextAlign.left,
                alignment: pw.Alignment.centerLeft,
              ),
              _buildTableCell(
                formatAdequation(technical.pdcTerminalStats[c.$1]),
                align: pw.TextAlign.left,
                alignment: pw.Alignment.centerLeft,
              ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildCablesTable(TechnicalEnrichmentResult technical) {
    String formatBreakdown(Map<String, CablesSectionBreakdown> b, int totalCables) {
      if (b.isEmpty || totalCables == 0) {
        return '-';
      }
      final parts = <String>[];
      for (final e in b.entries) {
        final sb = e.value;
        if (sb.count > 0) {
          final sortedSec = sb.sectionsCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          if (sortedSec.isNotEmpty) {
            for (final s in sortedSec) {
              final secPct = totalCables > 0 ? (s.value / totalCables * 100.0) : 0.0;
              final secPctStr = '${secPct.toStringAsFixed(1).replaceAll('.', ',')} %';
              parts.add('${sb.metal} — ${s.key} : ${s.value} / $totalCables, soit $secPctStr');
            }
          } else {
            final metalPct = totalCables > 0 ? (sb.count / totalCables * 100.0) : 0.0;
            final metalPctStr = '${metalPct.toStringAsFixed(1).replaceAll('.', ',')} %';
            parts.add('${sb.metal} : ${sb.count} / $totalCables, soit $metalPctStr');
          }
        }
      }
      return parts.isNotEmpty ? parts.join('\n') : '-';
    }

    const categories = [
      (DomainObjectType.inverseur, 'INVERSEUR'),
      (DomainObjectType.tgbt, 'TGBT'),
      (DomainObjectType.armoire, 'ARMOIRES'),
      (DomainObjectType.coffret, 'COFFRETS'),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.6),
        1: pw.FlexColumnWidth(3.7),
        2: pw.FlexColumnWidth(3.7),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell(''),
            _buildTableHeaderCell('DEPART'),
            _buildTableHeaderCell('CIRCUITS TERMINAUX'),
          ],
        ),
        for (final c in categories)
          ...[
            () {
              final row = technical.cablesMatrix.firstWhere(
                (r) => r.category == c.$1,
                orElse: () => CablesMatrixRow(
                  category: c.$1,
                  departsBreakdown: {},
                  circuitsTerminauxBreakdown: {},
                ),
              );
              return pw.TableRow(
                verticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  _buildTableCell(c.$2, isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
                  _buildTableCell(
                    formatBreakdown(row.departsBreakdown, row.totalDepartsCables),
                    align: pw.TextAlign.left,
                    alignment: pw.Alignment.centerLeft,
                  ),
                  _buildTableCell(
                    formatBreakdown(row.circuitsTerminauxBreakdown, row.totalTerminauxCables),
                    align: pw.TextAlign.left,
                    alignment: pw.Alignment.centerLeft,
                  ),
                ],
              );
            }(),
          ],
      ],
    );
  }

  static pw.Widget _buildIpIkTable(TechnicalEnrichmentResult technical) {
    pw.Widget buildRichStatsCell(IpIkZoneItem item) {
      final total = item.totalEquipements;
      if (total == 0) {
        return _buildTableCell('0 équipement (non évaluable)', align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft);
      }
      final indPct = (item.indicesPresents / total * 100.0).toStringAsFixed(1).replaceAll('.', ',');

      final String rateStr;
      final String detailStr;
      if (item.pointsVerifies > 0) {
        final pct = item.nonComplianceRate.toStringAsFixed(1).replaceAll('.', ',');
        rateStr = '$pct %';
        detailStr = '(${item.pointsNonConformes} NC / ${item.pointsVerifies} point${item.pointsVerifies > 1 ? "s" : ""} vérifié${item.pointsVerifies > 1 ? "s" : ""})';
      } else {
        rateStr = 'Non évaluable';
        detailStr = '(0 point vérifié)';
      }

      final hasNc = item.pointsNonConformes > 0;

      return pw.Container(
        alignment: pw.Alignment.centerLeft,
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.RichText(
              text: pw.TextSpan(
                style: pw.TextStyle(font: fontRegular, fontSize: fsSmall, color: PdfReportStyles.darkGrey),
                children: [
                  pw.TextSpan(
                    text: '$total équipement${total > 1 ? "s" : ""}',
                    style: pw.TextStyle(font: fontBold, color: PdfReportStyles.headerColor),
                  ),
                  const pw.TextSpan(text: ' , '),
                  pw.TextSpan(
                    text: 'Taux de non-conformité : ',
                    style: pw.TextStyle(font: fontBold, color: PdfReportStyles.headerColor),
                  ),
                  pw.TextSpan(
                    text: rateStr,
                    style: pw.TextStyle(
                      font: fontBold,
                      color: hasNc ? PdfColor.fromHex('#B71C1C') : PdfReportStyles.conformeColor,
                    ),
                  ),
                  pw.TextSpan(
                    text: ' $detailStr',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 1.5),
            pw.RichText(
              text: pw.TextSpan(
                style: pw.TextStyle(font: fontRegular, fontSize: fsSmall, color: PdfReportStyles.darkGrey),
                children: [
                  pw.TextSpan(
                    text: 'Indice présent : ${item.indicesPresents} / $total — $indPct %',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.2),
        1: pw.FlexColumnWidth(6.8),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('Classement'),
            _buildTableHeaderCell('Taux de conformité adéquation des équipements'),
          ],
        ),
        if (technical.ipIkZoneItems.isEmpty)
          pw.TableRow(
            children: [
              _buildTableCell('Ambiance générale site (sans zone classée spécifique)', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell('Donnée non renseignée sur le terrain', align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            ],
          )
        else
          for (final item in technical.ipIkZoneItems)
            pw.TableRow(
              verticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                _buildTableCell(item.zoneNom, isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
                buildRichStatsCell(item),
              ],
            ),
      ],
    );
  }

  @visibleForTesting
  static pw.Widget buildTopFindingsTableForTesting(List<TopDefectDomainItem> items, String emptyLabel) {
    return _buildTopFindingsTable(items, emptyLabel);
  }

  @visibleForTesting
  static pw.Widget buildCategoryCrossTableForTesting(List<CategoryCrossAuditRow> rows, CategoryCrossAuditRow totalRow, String domainLabel) {
    return _buildCategoryCrossTable(rows, totalRow, domainLabel);
  }
}
