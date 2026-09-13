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

/// Builder responsable du Résumé Exécutif KES (11 sections officielles, matrices et constats majeurs)
class PdfExecutiveSummaryBuilder {
  static pw.TableRow _buildIndicateurRow(String label, String value) =>
      PdfReportStyles.buildIndicateurRow(label, value, fontBold: fontBold, fontRegular: fontRegular);

  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();

  static const double fsH1 = PdfReportStyles.fsH1;
  static const double fsH2 = PdfReportStyles.fsH2;
  static const double fsH3 = PdfReportStyles.fsH3;
  static const double fsBody = PdfReportStyles.fsBody;
  static const double fsSmall = PdfReportStyles.fsSmall;

  /// Construit la section « RÉSUMÉ EXÉCUTIF » structurée en 11 sections officielles selon la spécification Word KES.
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

    // 2.1 Indicateurs clés de la mission
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_2_1',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '2.1. Indicateurs clés de la mission',
              style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
            ),
            pw.SizedBox(height: 4),
            _build12IndicateursTable(statsSummary, snapshot, technical),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    // 2.2 Criticité
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_2_2',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '2.2. Criticité',
              style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Container(
                  width: 4,
                  height: 4,
                  decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor, shape: pw.BoxShape.circle),
                ),
                pw.SizedBox(width: 6),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(text: 'Densité moyenne globale : ', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfReportStyles.darkGrey)),
                      pw.TextSpan(text: '${statsSummary.globalDensityStr} NC / équipement et local', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfReportStyles.darkGrey)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Container(
                  width: 4,
                  height: 4,
                  decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor, shape: pw.BoxShape.circle),
                ),
                pw.SizedBox(width: 6),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(text: 'Densité Moyenne Tension (HTA) : ', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfReportStyles.darkGrey)),
                      pw.TextSpan(text: '${statsSummary.densityHtaStr} NC / équipement', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfReportStyles.darkGrey)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Container(
                  width: 4,
                  height: 4,
                  decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor, shape: pw.BoxShape.circle),
                ),
                pw.SizedBox(width: 6),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(text: 'Densité Basse Tension (BT) : ', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfReportStyles.darkGrey)),
                      pw.TextSpan(text: '${statsSummary.densityBtStr} NC / équipement', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfReportStyles.darkGrey)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            _buildEnrichedDomainCriticalityTable(statsSummary, totalEquipments: snapshot.equipmentCount),
            if (data.syntheseResultats.commentaryParagraph.isNotEmpty) ...[
              pw.SizedBox(height: 5),
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
            ],
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    // 2.3 Facteurs de risque prépondérants
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_2_3',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '2.3. Facteurs de risque prépondérants',
              style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              data.facteursRisque.introParagraph.isNotEmpty
                  ? data.facteursRisque.introParagraph
                  : 'L\'analyse des facteurs de risque croise le domaine de tension (HTA / BT) et la nature des non-conformités (dispositions constructives vs conditions d\'exploitation et maintenance) :',
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: fsBody,
                color: PdfReportStyles.darkGrey,
                lineSpacing: 2.5,
              ),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 5),
            _buildEnrichedRiskFamilyMatrixTable(technical.riskFamilyMatrix),
            if (data.facteursRisque.commentaryParagraph.isNotEmpty) ...[
              pw.SizedBox(height: 5),
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
            ],
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 10));

    // ── 3. Répartition des non-conformités ──
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_3',
        registry: trackedPages,
        offset: offset,
        child: _subSectionHeader('3. Répartition des non-conformités'),
      ),
    );
    widgets.add(pw.SizedBox(height: 6));

    // Extraction des tops non-conformités MT et BT
    int critScore(String crit) {
      final c = crit.toLowerCase();
      if (c.contains('crit')) return 3;
      if (c.contains('maj')) return 2;
      return 1;
    }

    final invFindings = statsSummary.inventory.findings;
    final sortedMtFindings = invFindings
        .where((f) => f.tensionDomain == TensionDomain.mt)
        .toList()
      ..sort((a, b) => critScore(b.criticality).compareTo(critScore(a.criticality)));
    final top5Mt = sortedMtFindings.take(5).toList();

    final sortedBtFindings = invFindings
        .where((f) => f.tensionDomain == TensionDomain.bt)
        .toList()
      ..sort((a, b) => critScore(b.criticality).compareTo(critScore(a.criticality)));
    final top5Bt = sortedBtFindings.take(5).toList();

    // 3.1 Analyse Moyenne Tension (HTA)
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_3_1',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '3.1. Analyse Moyenne Tension (HTA)',
              style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'A. Locaux techniques MT (Dispositions constructives vs Exploitation) :',
              style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
            ),
            pw.SizedBox(height: 2),
            _buildLocauxStatsTable('Locaux techniques MT', technical.locauxMtFindings),
            pw.SizedBox(height: 6),
            pw.Text(
              'B. Exploitation & maintenance des équipements MT :',
              style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
            ),
            pw.SizedBox(height: 2),
            _buildCategoryCrossTable(
              technical.mtCategoriesCrossRows,
              technical.mtTotalCrossRow,
              'MT',
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'C. Principales non-conformités MT observées (Top 5) :',
              style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
            ),
            pw.SizedBox(height: 2),
            _buildTopFindingsTable(top5Mt, 'Aucune non-conformité MT recensée'),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    // 3.2 Analyse Basse Tension (BT)
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_3_2',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '3.2. Analyse Basse Tension (BT)',
              style: pw.TextStyle(font: fontBold, fontSize: fsH3, color: PdfReportStyles.headerColor),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'A. Locaux techniques BT & GE (Dispositions constructives vs Exploitation) :',
              style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
            ),
            pw.SizedBox(height: 2),
            _buildLocauxStatsTable('Locaux techniques BT & GE', technical.locauxBtFindings),
            pw.SizedBox(height: 6),
            pw.Text(
              'B. Exploitation & maintenance des équipements BT :',
              style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
            ),
            pw.SizedBox(height: 2),
            _buildCategoryCrossTable(
              technical.btCategoriesCrossRows,
              technical.btTotalCrossRow,
              'BT',
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'C. Principales non-conformités BT observées (Top 5) :',
              style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfReportStyles.darkGrey),
            ),
            pw.SizedBox(height: 2),
            _buildTopFindingsTable(top5Bt, 'Aucune non-conformité BT recensée'),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 10));

    // ── 4. Diversification des marques des appareillages de protection ──
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_4',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _subSectionHeader('4. Diversification des marques des appareillages de protection'),
            pw.SizedBox(height: 4),
            pw.Text(
              'Inventaire de la diversité des fabricants d\'appareillage BT selon le niveau de distribution (organe de tête, départs divisionnaires et circuits terminaux) pour évaluer l\'homogénéité du parc et la gestion des pièces de rechange :',
              style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 2.5),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 4),
            _buildMarquesTable(technical),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 10));

    // ── 5. Courbes et protections ──
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_5',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _subSectionHeader('5. Courbes et protections'),
            pw.SizedBox(height: 4),
            pw.Text(
              'Répartition des courbes de déclenchement magnétothermiques des disjoncteurs (B, C, D) sur l\'ensemble des tableaux de distribution pour vérifier la sélectivité et la maîtrise des courants d\'appel :',
              style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 2.5),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 4),
            _buildCourbesTable(technical),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 10));

    // ── 6. Adéquation ICC / PDC ──
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_6',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _subSectionHeader('6. Adéquation ICC / PDC'),
            pw.SizedBox(height: 4),
            pw.Text(
              'Contrôle normatif de la tenue en court-circuit vérifiant que le Pouvoir de Coupure (Pdc) des disjoncteurs est supérieur ou égal au courant de court-circuit maximal présumé (Icc3max) au point d\'installation (Pdc >= Icc) :',
              style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 2.5),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 4),
            _buildAdequationPdcTable(technical),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 10));

    // ── 7. Proportion type de câble par section ──
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_7',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _subSectionHeader('7. Proportion type de câble par section'),
            pw.SizedBox(height: 4),
            pw.Text(
              'Répartition de la filerie et des canalisations électriques selon la nature de l\'âme conductrice (Cuivre vs Aluminium) et les sections prédominantes relevées aux départs et circuits terminaux :',
              style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 2.5),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 4),
            _buildCablesTable(technical),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 10));

    // ── 8. Adéquation classement des zones et indices des équipements ──
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_8',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _subSectionHeader('8. Adéquation classement des zones et indices des équipements'),
            pw.SizedBox(height: 4),
            pw.Text(
              'Évaluation de la conformité des indices d\'étanchéité IP (solides/liquides) et de résistance mécanique IK des enveloppes par rapport aux exigences environnementales des locaux et zones du site :',
              style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 2.5),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 4),
            _buildIpIkTable(technical),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 10));

    // ── 9. Renforcement des compétences ──
    widgets.add(
      PageTracker(
        key: 'resume_executif_1_9',
        registry: trackedPages,
        offset: offset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _subSectionHeader('9. Renforcement des compétences'),
            pw.SizedBox(height: 4),
            pw.Text(
              'Afin d\'assurer la pérennité des installations et de prévenir la récurrence des défaillances constatées, six axes d\'amélioration des compétences des équipes techniques et d\'exploitation sont recommandés :',
              style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 2.5),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 5),
            _buildCompetencyEnhancementTable(),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 10));

    // ── 10. Recommandations prioritaires hiérarchisées ──
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
                style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.grey800),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Priorité 3 — Moyen Terme',
                style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.grey800),
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
      verticalAlignment: pw.TableCellVerticalAlignment.middle,
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
      key: 'resume_executif_1_10',
      registry: trackedPages,
      offset: offset,
      child: _subSectionHeader('10. Recommandations prioritaires hiérarchisées'),
    );

    final recoIntroWidget = data.recommandationsPrioritaires.introParagraph.isNotEmpty
        ? pw.Text(
            data.recommandationsPrioritaires.introParagraph,
            style: pw.TextStyle(font: fontRegular, fontSize: fsBody, color: PdfReportStyles.darkGrey, lineSpacing: 2.5),
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

    // ── 11. Appréciation globale ──
    widgets.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PageTracker(
            key: 'resume_executif_1_11',
            registry: trackedPages,
            offset: offset,
            child: _subSectionHeader('11. Appréciation globale'),
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
      for (int i = 0; i < data.appreciationGlobale.actionPlanSteps.length; i++) {
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

  static pw.Widget _build12IndicateursTable(
    MissionStatisticsSummary summary,
    ExecutiveSummarySnapshot snapshot,
    TechnicalEnrichmentResult technical,
  ) {
    final cStats = summary.criticalityStats;
    final totalEq = summary.totalEquipments;
    final activeCats = summary.crossCategoryItems.length;
    final densestStr = summary.densestCategoryFormatted;
    final topTwo = summary.topTwoCategoriesResult;

    final totalLocaux = technical.totalLocauxMt + technical.totalLocauxBt + technical.totalLocauxGe;
    final perimetreDesc = totalLocaux > 0
        ? '$totalEq installations et équipements (dont $totalLocaux locaux techniques) répartis en $activeCats catégories (${summary.htaEquipmentsCount} MT et ${summary.btEquipmentsCount} BT)'
        : '$totalEq installations et équipements répartis en $activeCats catégories (${summary.htaEquipmentsCount} MT et ${summary.btEquipmentsCount} BT)';

    final btCoupureDesc = technical.globalCoupureTeteTotal > 0
        ? '${technical.globalCoupureTeteRatio} (${technical.globalCoupureTetePct.toStringAsFixed(1).replaceAll('.', ',')} %)\n'
          'Inverseurs ${technical.coupureTeteStats[DomainObjectType.inverseur]?.ratioStr ?? '-'}, '
          'TGBT ${technical.coupureTeteStats[DomainObjectType.tgbt]?.ratioStr ?? '-'}, '
          'Armoires ${technical.coupureTeteStats[DomainObjectType.armoire]?.ratioStr ?? '-'}, '
          'Coffrets ${technical.coupureTeteStats[DomainObjectType.coffret]?.ratioStr ?? '-'}'
        : 'Non applicable (aucun tableau BT)';

    final btSourceDesc = technical.globalSourceTotal > 0
        ? '${technical.globalSourceRatio} (${technical.globalSourcePct.toStringAsFixed(1).replaceAll('.', ',')} % identifiées)\n'
          'Inverseurs ${technical.sourceStats[DomainObjectType.inverseur]?.ratioStr ?? '-'}, '
          'TGBT ${technical.sourceStats[DomainObjectType.tgbt]?.ratioStr ?? '-'}, '
          'Armoires ${technical.sourceStats[DomainObjectType.armoire]?.ratioStr ?? '-'}, '
          'Coffrets ${technical.sourceStats[DomainObjectType.coffret]?.ratioStr ?? '-'}'
        : 'Non applicable (aucun tableau BT)';

    final btParafoudreDesc = technical.globalParafoudreTotal > 0
        ? '${technical.globalParafoudreRatio} (${technical.globalParafoudrePct.toStringAsFixed(1).replaceAll('.', ',')} % équipés)\n'
          'Inverseurs ${technical.parafoudreStats[DomainObjectType.inverseur]?.ratioStr ?? '-'}, '
          'TGBT ${technical.parafoudreStats[DomainObjectType.tgbt]?.ratioStr ?? '-'}, '
          'Armoires ${technical.parafoudreStats[DomainObjectType.armoire]?.ratioStr ?? '-'}, '
          'Coffrets ${technical.parafoudreStats[DomainObjectType.coffret]?.ratioStr ?? '-'}'
        : 'Non applicable (aucun tableau BT)';

    final pdcDesc = technical.globalAdequationTeteEvalues > 0
        ? '${technical.globalAdequationTeteRatio} organe(s) de tête conforme(s) (${technical.globalAdequationTetePct.toStringAsFixed(1).replaceAll('.', ',')} %)${technical.globalAdequationTeteNonEvalues > 0 ? '\n${technical.globalAdequationTeteNonEvalues} équipement(s) sans Icc/Pdc classé(s) non évaluable(s)' : ''}'
        : 'Données Icc / Pdc non renseignées sur les équipements';

    final essaisDesc = 'Total instrumenté : ${technical.essaisCoverage.totalEssais} point(s) de mesure et d\'essai\n'
        '• Prises de terre : ${technical.essaisCoverage.prisesTerreCount} mesure(s)\n'
        '• Dispositifs différentiels (DDR) : ${technical.essaisCoverage.testDdrCount} essai(s)\n'
        '• Isolement des circuits : ${technical.essaisCoverage.mesureIsolementCount} mesure(s)\n'
        '• Continuité des conducteurs PE : ${technical.essaisCoverage.continuitePeCount} mesure(s)\n'
        '• Contrôleurs d\'isolement (CPI) : ${technical.essaisCoverage.testCpiCount} contrôle(s)\n'
        '• Démarrage groupe électrogène : ${technical.essaisCoverage.demarrageGeCount} essai(s)\n'
        '• Arrêts d\'urgence & déclencheurs : ${technical.essaisCoverage.arretUrgenceCount} essai(s)';

    return pw.Table(
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
                style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'VALEUR ET DESCRIPTION',
                style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
              ),
            ),
          ],
        ),
        _buildIndicateurRow('1. Périmètre couvert', perimetreDesc),
        _buildIndicateurRow('2. Total des non-conformités', '${cStats.total} (recensement unitaire exhaustif)'),
        _buildIndicateurRow('3. Densité moyenne globale', '${summary.globalDensityStr} NC / équipement et local'),
        _buildIndicateurRow('4. Densités par domaine', 'MT : ${summary.densityHtaStr} NC/équipement — BT : ${summary.densityBtStr} NC/équipement'),
        _buildIndicateurRow('5. Part des NC critiques', '${cStats.critique} constat(s) (${cStats.pctCritique.toStringAsFixed(1).replaceAll('.', ',')} %) — Sévérité élevée'),
        _buildIndicateurRow('6. Concentration volumique', '${topTwo.label} concentrent ${topTwo.formattedValue}'),
        _buildIndicateurRow('7. Catégorie la plus dense', densestStr),
        _buildIndicateurRow('8. Coupure de tête BT', btCoupureDesc),
        _buildIndicateurRow('9. Sources d\'alimentation BT', btSourceDesc),
        _buildIndicateurRow('10. Parafoudres (surtensions)', btParafoudreDesc),
        _buildIndicateurRow('11. Adéquation Pdc >= Icc', pdcDesc),
        _buildIndicateurRow('12. Mesures & essais réalisés', essaisDesc),
      ],
    );
  }

  static pw.Widget _buildLocauxStatsTable(String title, LocauxFindingsStats stats) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(6.0),
        1: pw.FlexColumnWidth(2.0),
        2: pw.FlexColumnWidth(2.0),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell(title.toUpperCase()),
            _buildTableHeaderCell('NOMBRE'),
            _buildTableHeaderCell('PART (%)'),
          ],
        ),
        pw.TableRow(
          children: [
            _buildTableCell('Dispositions constructives', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            _buildTableCell('${stats.dispoConstructives}'),
            _buildTableCell(stats.dispoConstructivesPctStr),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.tableRowAlt),
          children: [
            _buildTableCell('Conditions d\'exploitation et maintenance', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            _buildTableCell('${stats.conditionsExploitation}'),
            _buildTableCell(stats.conditionsExploitationPctStr),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [
            _buildTableCell('TOTAL', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            _buildTableCell('${stats.total}', isBold: true),
            _buildTableCell('100,0 %', isBold: true),
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
            _buildTableHeaderCell('CATÉGORIE'),
            _buildTableHeaderCell('ÉQUIP.'),
            _buildTableHeaderCell('NC'),
            _buildTableHeaderCell('CRIT.'),
            _buildTableHeaderCell('% DU TOTAL'),
            _buildTableHeaderCell('DENSITÉ (NC/ÉQ)'),
          ],
        ),
        if (rows.isEmpty)
          pw.TableRow(
            children: [
              _buildTableCell('Aucune installation $domainLabel recensée', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell('0'),
              _buildTableCell('0'),
              _buildTableCell('0'),
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
                _buildTableCell(rows[i].densiteStr, isBold: true),
              ],
            ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [
            _buildTableCell('TOTAL $domainLabel', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            _buildTableCell('${totalRow.equipementsCount}', isBold: true),
            _buildTableCell('${totalRow.ncCount}', isBold: true),
            _buildTableCell(
              '${totalRow.critiquesCount}',
              isBold: true,
              color: totalRow.critiquesCount > 0 ? PdfColor.fromHex('#B71C1C') : null,
            ),
            _buildTableCell(totalRow.pctOfTotalNcStr, isBold: true),
            _buildTableCell(totalRow.densiteStr, isBold: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTopFindingsTable(List<AuditFinding> findings, String emptyLabel) {
    if (findings.isEmpty) {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              _buildTableHeaderCell('RANG'),
              _buildTableHeaderCell('ÉQUIPEMENT / LOCAL'),
              _buildTableHeaderCell('NATURE DU CONSTAT'),
              _buildTableHeaderCell('CRITICITÉ'),
            ],
          ),
          pw.TableRow(
            children: [
              _buildTableCell('-'),
              _buildTableCell(emptyLabel, isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell('Aucune anomalie constatée'),
              _buildTableCell('Conforme', color: PdfReportStyles.accentColor, isBold: true),
            ],
          ),
        ],
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.8),
        1: pw.FlexColumnWidth(3.0),
        2: pw.FlexColumnWidth(4.7),
        3: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('RANG'),
            _buildTableHeaderCell('ÉQUIPEMENT / LOCAL'),
            _buildTableHeaderCell('NATURE DU CONSTAT'),
            _buildTableHeaderCell('CRITICITÉ'),
          ],
        ),
        for (int i = 0; i < findings.length; i++)
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            decoration: pw.BoxDecoration(
              color: i % 2 == 1 ? PdfReportStyles.tableRowAlt : PdfColors.white,
            ),
            children: [
              _buildTableCell('${i + 1}', isBold: true),
              _buildTableCell(
                findings[i].objectName.isNotEmpty ? findings[i].objectName : findings[i].origin,
                isBold: true,
                align: pw.TextAlign.left,
                alignment: pw.Alignment.centerLeft,
              ),
              _buildTableCell(
                findings[i].observationText.isNotEmpty ? findings[i].observationText : findings[i].verificationPoint,
                align: pw.TextAlign.left,
                alignment: pw.Alignment.centerLeft,
              ),
              _buildTableCell(
                findings[i].criticality,
                isBold: true,
                color: findings[i].criticality.toLowerCase().contains('crit')
                    ? PdfColor.fromHex('#B71C1C')
                    : (findings[i].criticality.toLowerCase().contains('maj')
                        ? PdfColor.fromHex('#C2410C')
                        : PdfReportStyles.darkGrey),
              ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildCompetencyEnhancementTable() {
    final axes = [
      (
        '1. Habilitation électrique & consignation (NF C 18-510)',
        'Maintien et recyclage des titres B1V, B2V, BR, BC, H1V, H2V. Respect strict des procédures de consignation, de Vérification d\'Absence de Tension (VAT) et de cadenassage.',
      ),
      (
        '2. Lecture, traçabilité & mise à jour des schémas unifilaires',
        'Capacité à repérer les circuits, documenter les modifications apportées aux tableaux et maintenir l\'adéquation entre le schéma d\'armoire et le câblage réel.',
      ),
      (
        '3. Réglage, coordination & sélectivité des protections',
        'Maîtrise des courbes de déclenchement (B, C, D), réglage des déclencheurs électroniques et magnétothermiques, vérification de la coordination amont/aval.',
      ),
      (
        '4. Mesures instrumentées & contrôles périodiques',
        'Pratique des mesures de boucle de terre, tests des différentiels (DDR), isolement des conducteurs et contrôle de continuité des liaisons équipotentielles.',
      ),
      (
        '5. Entretien préventif des locaux techniques & enveloppes',
        'Procédures de dépoussiérage hors tension, resserrage des connexions au couple prescrit, contrôle visuel d\'échauffement et préservation des indices IP/IK.',
      ),
      (
        '6. Exploitation des sources de remplacement & inverseurs',
        'Procédures d\'essai périodique sous charge, maintenance des batteries de démarrage, contrôle des verrouillages mécaniques et électriques Normal/Secours.',
      ),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.8),
        1: pw.FlexColumnWidth(6.2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('AXE PRIORITAIRE DE COMPÉTENCE'),
            _buildTableHeaderCell('OBJECTIF OPÉRATIONNEL & BONNES PRATIQUES'),
          ],
        ),
        for (int i = 0; i < axes.length; i++)
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            decoration: pw.BoxDecoration(
              color: i % 2 == 1 ? PdfReportStyles.tableRowAlt : PdfColors.white,
            ),
            children: [
              _buildTableCell(axes[i].$1, isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell(axes[i].$2, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            ],
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

    final mtPct = totGlobal > 0 ? '${(mtTot / totGlobal * 100).toStringAsFixed(1).replaceAll('.', ',')} %' : '0,0 %';
    final btPct = totGlobal > 0 ? '${(btTot / totGlobal * 100).toStringAsFixed(1).replaceAll('.', ',')} %' : '0,0 %';

    final densityHta = stats.densityHtaStr;
    final densityBt = stats.densityBtStr;
    final densityGlobal = stats.globalDensityStr;

    pw.Widget cell(String text, {bool isBold = false, bool isHeader = false, PdfColor? textColor, PdfColor? bgColor, pw.TextAlign align = pw.TextAlign.center}) {
      return pw.Container(
        color: bgColor,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
        alignment: align == pw.TextAlign.left ? pw.Alignment.centerLeft : pw.Alignment.center,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: isBold || isHeader ? fontBold : fontRegular,
            fontSize: isHeader ? 7.5 : 7,
            color: isHeader ? PdfColors.white : (textColor ?? PdfReportStyles.headerColor),
          ),
          textAlign: align,
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.0),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.2),
        4: pw.FlexColumnWidth(1.4),
        5: pw.FlexColumnWidth(1.4),
        6: pw.FlexColumnWidth(2.0),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            cell('DOMAINE D\'INSTALLATION', isHeader: true, align: pw.TextAlign.left),
            cell('CRITIQUE', isHeader: true),
            cell('MAJEURE', isHeader: true),
            cell('MINEURE', isHeader: true),
            cell('TOTAL NC', isHeader: true),
            cell('PART (%)', isHeader: true),
            cell('DENSITÉ (NC/ÉQ)', isHeader: true),
          ],
        ),
        pw.TableRow(
          children: [
            cell('Moyenne Tension (HTA)', isBold: true, align: pw.TextAlign.left),
            cell('$mtCrit', textColor: mtCrit > 0 ? PdfColor.fromHex('#B71C1C') : null, isBold: mtCrit > 0),
            cell('$mtMaj', textColor: mtMaj > 0 ? PdfColor.fromHex('#C2410C') : null, isBold: mtMaj > 0),
            cell('$mtMin'),
            cell('$mtTot', isBold: true),
            cell(mtPct),
            cell('$densityHta NC/éq', isBold: true),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.tableRowAlt),
          children: [
            cell('Basse Tension (BT)', isBold: true, align: pw.TextAlign.left),
            cell('$btCrit', textColor: btCrit > 0 ? PdfColor.fromHex('#B71C1C') : null, isBold: btCrit > 0),
            cell('$btMaj', textColor: btMaj > 0 ? PdfColor.fromHex('#C2410C') : null, isBold: btMaj > 0),
            cell('$btMin'),
            cell('$btTot', isBold: true),
            cell(btPct),
            cell('$densityBt NC/éq', isBold: true),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
          children: [
            cell('TOTAL GÉNÉRAL', isBold: true, align: pw.TextAlign.left),
            cell('$totCrit', textColor: PdfColor.fromHex('#B71C1C'), isBold: true),
            cell('$totMaj', textColor: PdfColor.fromHex('#C2410C'), isBold: true),
            cell('$totMin', isBold: true),
            cell('$totGlobal', isBold: true),
            cell('100 %', isBold: true),
            cell('$densityGlobal NC/éq', isBold: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildEnrichedRiskFamilyMatrixTable(RiskFamilyCrossMatrix matrix) {
    String formatTopDefects(Map<String, int> defects) {
      if (defects.isEmpty) return 'Aucune non-conformité recensée';
      final sorted = defects.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return sorted.take(3).map((e) => '${e.key} (${e.value})').join(', ');
    }

    final totalHta = matrix.totalHta;
    final totalBt = matrix.totalBt;
    final pctHtaDispo = totalHta > 0 ? '${(matrix.totalHtaDispo / totalHta * 100).toStringAsFixed(1).replaceAll('.', ',')} %' : '0,0 %';
    final pctHtaExploit = totalHta > 0 ? '${(matrix.totalHtaExploit / totalHta * 100).toStringAsFixed(1).replaceAll('.', ',')} %' : '0,0 %';
    final pctBtDispo = totalBt > 0 ? '${(matrix.totalBtDispo / totalBt * 100).toStringAsFixed(1).replaceAll('.', ',')} %' : '0,0 %';
    final pctBtExploit = totalBt > 0 ? '${(matrix.totalBtExploit / totalBt * 100).toStringAsFixed(1).replaceAll('.', ',')} %' : '0,0 %';

    final rows = [
      (
        'Moyenne Tension (HTA) — Dispositions constructives',
        '${matrix.totalHtaDispo}',
        pctHtaDispo,
        formatTopDefects(matrix.htaDispositionsConstructives),
      ),
      (
        'Moyenne Tension (HTA) — Exploitation & maintenance',
        '${matrix.totalHtaExploit}',
        pctHtaExploit,
        formatTopDefects(matrix.htaExploitationMaintenance),
      ),
      (
        'Basse Tension (BT) — Dispositions constructives',
        '${matrix.totalBtDispo}',
        pctBtDispo,
        formatTopDefects(matrix.btDispositionsConstructives),
      ),
      (
        'Basse Tension (BT) — Exploitation & maintenance',
        '${matrix.totalBtExploit}',
        pctBtExploit,
        formatTopDefects(matrix.btExploitationMaintenance),
      ),
    ];

    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.8),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.4),
        3: pw.FlexColumnWidth(4.6),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('DOMAINE & NATURE DU RISQUE'),
            _buildTableHeaderCell('CONSTATS'),
            _buildTableHeaderCell('PART (%)'),
            _buildTableHeaderCell('PRINCIPALES NON-CONFORMITÉS OBSERVÉES'),
          ],
        ),
        for (int i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i % 2 == 1 ? PdfReportStyles.tableRowAlt : PdfColors.white,
            ),
            children: [
              _buildTableCell(rows[i].$1, isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell(rows[i].$2, align: pw.TextAlign.center),
              _buildTableCell(rows[i].$3, align: pw.TextAlign.center),
              _buildTableCell(rows[i].$4, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            ],
          ),
      ],
    );
  }

  static String _formatCategoryName(DomainObjectType cat) {
    switch (cat) {
      case DomainObjectType.inverseur:
        return 'Inverseurs Normal/Secours';
      case DomainObjectType.tgbt:
        return 'Tableaux Généraux (TGBT)';
      case DomainObjectType.armoire:
        return 'Armoires divisionnaires';
      case DomainObjectType.coffret:
        return 'Coffrets terminaux';
      default:
        return cat.name;
    }
  }

  static String _formatBrandMap(Map<String, int> m) {
    if (m.isEmpty) return 'Non renseigné / Sans objet';
    final sorted = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => '${e.key} (${e.value})').join(', ');
  }

  static pw.Widget _buildMarquesTable(TechnicalEnrichmentResult technical) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.6),
        1: pw.FlexColumnWidth(2.4),
        2: pw.FlexColumnWidth(2.5),
        3: pw.FlexColumnWidth(2.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('CATÉGORIE TABLEAU'),
            _buildTableHeaderCell('ORGANE DE TÊTE'),
            _buildTableHeaderCell('DÉPARTS DIVISIONNAIRES'),
            _buildTableHeaderCell('CIRCUITS TERMINAUX'),
          ],
        ),
        ...technical.marquesMatrix.map((row) {
          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _buildTableCell(_formatCategoryName(row.category), isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell(_formatBrandMap(row.organeDeTete), align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell(_formatBrandMap(row.departs), align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell(_formatBrandMap(row.circuitsTerminaux), align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildCourbesTable(TechnicalEnrichmentResult technical) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.6),
        1: pw.FlexColumnWidth(2.4),
        2: pw.FlexColumnWidth(2.5),
        3: pw.FlexColumnWidth(2.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('CATÉGORIE TABLEAU'),
            _buildTableHeaderCell('ORGANE DE TÊTE'),
            _buildTableHeaderCell('DÉPARTS DIVISIONNAIRES'),
            _buildTableHeaderCell('CIRCUITS TERMINAUX'),
          ],
        ),
        ...technical.courbesMatrix.map((row) {
          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _buildTableCell(_formatCategoryName(row.category), isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell(_formatBrandMap(row.organeDeTete), align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell(_formatBrandMap(row.departs), align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell(_formatBrandMap(row.circuitsTerminaux), align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildAdequationPdcTable(TechnicalEnrichmentResult technical) {
    pw.TableRow buildPdcRow(String catName, String level, AdequationIccPdcStats stats) {
      final isLow = stats.evaluables > 0 && stats.complianceRate < 100.0;
      return pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          _buildTableCell(catName, isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
          _buildTableCell(level, align: pw.TextAlign.center),
          _buildTableCell('${stats.evaluables}', align: pw.TextAlign.center),
          _buildTableCell('${stats.conformes}', align: pw.TextAlign.center),
          _buildTableCell(
            '${stats.nonConformes}',
            align: pw.TextAlign.center,
            color: stats.nonConformes > 0 ? PdfColor.fromHex('#B71C1C') : null,
            isBold: stats.nonConformes > 0,
          ),
          _buildTableCell('${stats.nonRenseignes}', align: pw.TextAlign.center),
          _buildTableCell(
            stats.formattedComplianceRate,
            align: pw.TextAlign.center,
            isBold: true,
            color: isLow ? PdfColor.fromHex('#B71C1C') : PdfReportStyles.accentColor,
          ),
        ],
      );
    }

    final pdcRows = <pw.TableRow>[];
    const btCats = [
      DomainObjectType.inverseur,
      DomainObjectType.tgbt,
      DomainObjectType.armoire,
      DomainObjectType.coffret,
    ];
    for (final cat in btCats) {
      final cName = _formatCategoryName(cat);
      final teteStats = technical.adequationIccPdcStats[cat];
      final depStats = technical.pdcDepartStats[cat];
      final termStats = technical.pdcTerminalStats[cat];
      if (teteStats != null && teteStats.totalElements > 0) {
        pdcRows.add(buildPdcRow(cName, 'Tête', teteStats));
      }
      if (depStats != null && depStats.totalElements > 0) {
        pdcRows.add(buildPdcRow(cName, 'Départs', depStats));
      }
      if (termStats != null && termStats.totalElements > 0) {
        pdcRows.add(buildPdcRow(cName, 'Terminaux', termStats));
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.6),
        1: pw.FlexColumnWidth(1.6),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.2),
        4: pw.FlexColumnWidth(1.4),
        5: pw.FlexColumnWidth(1.4),
        6: pw.FlexColumnWidth(1.8),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('CATÉGORIE'),
            _buildTableHeaderCell('NIVEAU'),
            _buildTableHeaderCell('ÉVALUÉS'),
            _buildTableHeaderCell('CONF.'),
            _buildTableHeaderCell('NON CONF.'),
            _buildTableHeaderCell('NON ÉVAL.'),
            _buildTableHeaderCell('CONFORMITÉ (%)'),
          ],
        ),
        if (pdcRows.isEmpty)
          pw.TableRow(
            children: [
              _buildTableCell('Aucun appareillage recensé', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell('-'),
              _buildTableCell('0', align: pw.TextAlign.center),
              _buildTableCell('0', align: pw.TextAlign.center),
              _buildTableCell('0', align: pw.TextAlign.center),
              _buildTableCell('0', align: pw.TextAlign.center),
              _buildTableCell('—', align: pw.TextAlign.center),
            ],
          )
        else
          ...pdcRows,
      ],
    );
  }

  static pw.Widget _buildCablesTable(TechnicalEnrichmentResult technical) {
    String formatCableBreakdown(Map<String, CablesSectionBreakdown> b) {
      if (b.isEmpty) return 'Aucun circuit recensé';
      final parts = <String>[];
      for (final entry in b.entries) {
        final sb = entry.value;
        if (sb.count > 0) {
          final sortedSec = sb.sectionsCount.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final secStr = sortedSec.take(3).map((e) => '${e.key} (${e.value})').join(', ');
          parts.add('${sb.metal} : ${sb.count}${secStr.isNotEmpty ? ' [$secStr]' : ''}');
        }
      }
      return parts.isEmpty ? 'Aucun circuit recensé' : parts.join('\n');
    }

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
            _buildTableHeaderCell('CATÉGORIE TABLEAU'),
            _buildTableHeaderCell('DÉPARTS DIVISIONNAIRES'),
            _buildTableHeaderCell('CIRCUITS TERMINAUX'),
          ],
        ),
        ...technical.cablesMatrix.map((row) {
          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _buildTableCell(_formatCategoryName(row.category), isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell(formatCableBreakdown(row.departsBreakdown), align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell(formatCableBreakdown(row.circuitsTerminauxBreakdown), align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildIpIkTable(TechnicalEnrichmentResult technical) {
    final ipIkRows = technical.ipIkZoneItems.map((item) {
      final isEval = item.evaluables > 0;
      final isConf = isEval && item.nonConformes == 0 && item.conformes > 0;
      final statusColor = !isEval
          ? PdfColors.grey700
          : (isConf ? PdfReportStyles.accentColor : PdfColor.fromHex('#B71C1C'));
      final statusText = !isEval
          ? (item.nonRenseignes > 0 ? 'Non renseigné' : 'Non évaluable')
          : (isConf ? 'Conforme' : 'Non conforme');

      return pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          _buildTableCell(item.zoneNom, isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
          _buildTableCell(item.ipRequis ?? '—', align: pw.TextAlign.center),
          _buildTableCell(item.ikRequis ?? '—', align: pw.TextAlign.center),
          _buildTableCell('${item.totalEquipements}', align: pw.TextAlign.center),
          _buildTableCell('${item.conformes}', align: pw.TextAlign.center),
          _buildTableCell('${item.nonConformes}', align: pw.TextAlign.center),
          _buildTableCell(
            statusText,
            align: pw.TextAlign.center,
            isBold: true,
            color: statusColor,
          ),
          _buildTableCell(item.formattedRate, align: pw.TextAlign.center),
        ],
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.8),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.0),
        4: pw.FlexColumnWidth(1.0),
        5: pw.FlexColumnWidth(1.1),
        6: pw.FlexColumnWidth(1.8),
        7: pw.FlexColumnWidth(1.8),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            _buildTableHeaderCell('ZONE / LOCAL'),
            _buildTableHeaderCell('IP REQ.'),
            _buildTableHeaderCell('IK REQ.'),
            _buildTableHeaderCell('TOTAL'),
            _buildTableHeaderCell('CONF.'),
            _buildTableHeaderCell('NON CONF.'),
            _buildTableHeaderCell('STATUT'),
            _buildTableHeaderCell('TAUX CONF.'),
          ],
        ),
        if (ipIkRows.isEmpty)
          pw.TableRow(
            children: [
              _buildTableCell('Ambiance générale site (sans zone spécifique)', isBold: true, align: pw.TextAlign.left, alignment: pw.Alignment.centerLeft),
              _buildTableCell('IP2X', align: pw.TextAlign.center),
              _buildTableCell('IK02', align: pw.TextAlign.center),
              _buildTableCell('—', align: pw.TextAlign.center),
              _buildTableCell('—', align: pw.TextAlign.center),
              _buildTableCell('—', align: pw.TextAlign.center),
              _buildTableCell('Conforme', align: pw.TextAlign.center, isBold: true, color: PdfReportStyles.accentColor),
              _buildTableCell('100,0 %', align: pw.TextAlign.center),
            ],
          )
        else
          ...ipIkRows,
      ],
    );
  }
}
