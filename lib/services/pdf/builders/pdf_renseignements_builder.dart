import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

/// Builder responsable de la section Renseignements Généraux (cadre d'intervention, client, vérificateurs)
class PdfRenseignementsBuilder {
  static const double fsSmall = PdfReportStyles.fsSmall;
  static const double fsBody = PdfReportStyles.fsBody;

  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();

  static pw.Widget buildRenseignementsGeneraux(
    Mission mission,
    RenseignementsGeneraux? rg,
    Map<String, int> trackedPages, {
    int offset = 0,
    pw.Font? fontBold,
    pw.Font? fontRegular,
    pw.Widget Function({String? nomClient, String? nomSite, String? numeroRapport, String? titreRapport})? pageHeaderBuilder,
  }) {
    final verificateursNoms = rg != null && rg.verificateurs.isNotEmpty
        ? rg.verificateurs
              .map((v) => '${v['prenom'] ?? ''} ${v['nom'] ?? ''}'.trim())
              .where((s) => s.isNotEmpty)
              .join(', ')
        : (mission.verificateurs != null
              ? mission.verificateurs!
                    .map((v) => '${v['prenom'] ?? ''} ${v['nom'] ?? ''}'.trim())
                    .where((s) => s.isNotEmpty)
                    .join(', ')
              : '');

    final dateDebut = rg?.dateDebut ?? mission.dateIntervention;
    final dateFin = rg?.dateFin;

    String dateIntervTxt;

    if (dateDebut != null &&
        dateFin != null &&
        !dateDebut.isAtSameMomentAs(dateFin)) {
      dateIntervTxt = 'Du ${PdfReportStyles.formatDate(dateDebut)} au ${PdfReportStyles.formatDate(dateFin)}';
    } else if (dateDebut != null) {
      dateIntervTxt = PdfReportStyles.formatDate(dateDebut);
    } else {
      dateIntervTxt = '';
    }

    // Construire la liste des lignes du tableau
    final rows = <pw.TableRow>[
      PdfReportStyles.tableHeaderRow(['LISTE DES DOCUMENTS', 'OBSERVATIONS']),
    ];

    // Documents standards
    final docsStandards = [
      {
        'label':
            'Cahier des prescriptions techniques ayant permis la réalisation des installations',
        'value': mission.docCahierPrescriptions,
      },
      {
        'label':
            'Notes de calculs justifiant le dimensionnement des canalisations électriques et des dispositifs de protection',
        'value': mission.docNotesCalculs,
      },
      {
        'label': 'Schémas unifilaires des installations électriques',
        'value': mission.docSchemasUnifilaires,
      },
      {
        'label':
            'Plan de masse à l\'échelle des installations avec implantations des prises de terre et électriques enterrés',
        'value': mission.docPlanMasse,
      },
      {
        'label': 'Plans architecturaux d\'implantation des différents circuits',
        'value': mission.docPlansArchitecturaux,
      },
      {
        'label':
            'Déclaration CE de conformité et notices des appareillages et câbles installés',
        'value': mission.docDeclarationsCe,
      },
      {
        'label':
            'Liste des installations de sécurité et effectif maximal des différents locaux ou bâtiments',
        'value': mission.docListeInstallations,
      },
      {
        'label': 'Rapport de dernière vérification',
        'value': mission.docRapportDerniereVerif,
      },
      {
        'label':
            'Plan des locaux, avec indications des locaux à risques particuliers d\'influences externes',
        'value': mission.docPlanLocauxRisques,
      },
      {
        'label': 'Rapport d\'analyse risque foudre',
        'value': mission.docRapportAnalyseFoudre,
      },
      {
        'label': 'Rapport d\'étude technique foudre',
        'value': mission.docRapportEtudeFoudre,
      },
      {'label': 'Registre de sécurité', 'value': mission.docRegistreSecurite},
    ];

    for (var doc in docsStandards) {
      rows.add(
        PdfReportStyles.tableDataRow([
          doc['label'] as String,
          PdfReportStyles.docStatus(doc['value'] as bool),
        ], alt: rows.length.isOdd),
      );
    }

    // Documents personnalisés
    final autresDocs = mission.autresDocuments;

    for (var doc in autresDocs) {
      rows.add(PdfReportStyles.tableDataRow([doc, 'Présent'], alt: rows.length.isOdd));
    }

    // Option "Autre"
    if (mission.docAutre && !autresDocs.contains('Autre document pertinent')) {
      rows.add(
        PdfReportStyles.tableDataRow([
          'Autre document pertinent',
          'Présent',
        ], alt: rows.length.isOdd),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        (pageHeaderBuilder != null ? pageHeaderBuilder(nomClient: mission.nomClient) : pw.SizedBox()),

        pw.SizedBox(height: 10),

        PageTracker(
          key: 'renseignements',
          registry: trackedPages,
          offset: offset,
          child: PdfReportStyles.sectionBox(
            'RENSEIGNEMENTS G\u00c9N\u00c9RAUX DE L\'\u00c9TABLISSEMENT',
          ),
        ),

        pw.SizedBox(height: 8),

        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PageTracker(
              key: 'renseignements_principaux',
              registry: trackedPages,
              offset: offset,
              child: PdfReportStyles.subTitle('1. Renseignements principaux'),
            ),
            pw.SizedBox(height: 5),
            pw.Table(
              border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
              },
              children: [
                PdfReportStyles.tableDataRow([
                  'Etablissement vérifié',
                  mission.nomClient,
                ], alt: false),
                PdfReportStyles.tableDataRow([
                  'Installation vérifié',
                  rg?.installation.isNotEmpty == true
                      ? rg!.installation
                      : (mission.installation ??
                            'Toutes les installations électriques'),
                ], alt: true),
                PdfReportStyles.tableDataRow([
                  'Activité principale',
                  rg?.activite.isNotEmpty == true
                      ? rg!.activite
                      : (mission.activiteClient ?? '—'),
                ], alt: false),
                PdfReportStyles.tableDataRow([
                  'Adresse',
                  mission.adresseClient ?? '—',
                ], alt: true),
                PdfReportStyles.tableDataRow([
                  'Nom du site',
                  rg?.nomSite.isNotEmpty == true
                      ? rg!.nomSite
                      : (mission.nomSite ?? '—'),
                ], alt: false),
                PdfReportStyles.tableDataRow([
                  'Activité sur le site',
                  (rg?.activiteSurSite?.isNotEmpty == true)
                      ? rg!.activiteSurSite!
                      : (mission.activiteSurSite ?? '—'),
                ], alt: true),
                PdfReportStyles.tableDataRow([
                  'Registre de contrôle',
                  rg?.registreControle.isNotEmpty == true
                      ? rg!.registreControle
                      : 'Non présenté',
                ], alt: false),
                PdfReportStyles.tableDataRow(['Classement règlementaire', ''], alt: true),
                PdfReportStyles.tableDataRow([
                  '                                     Type',
                  (rg?.classementReglementaireType?.isNotEmpty == true)
                      ? rg!.classementReglementaireType!
                      : (mission.classementReglementaireType ?? '—'),
                ], alt: false),
                PdfReportStyles.tableDataRow([
                  '                                     Catégorie',
                  (rg?.classementReglementaireCategorie?.isNotEmpty == true)
                      ? rg!.classementReglementaireCategorie!
                      : (mission.classementReglementaireCategorie ?? '—'),
                ], alt: true),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 16),

        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PageTracker(
              key: 'renseignements_documents',
              registry: trackedPages,
              offset: offset,
              child: PdfReportStyles.subTitle('2. Documents nécessaires à la vérification'),
            ),
            pw.SizedBox(height: 5),
            pw.Table(
              border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(2),
              },
              children: [
                PdfReportStyles.tableHeaderRow(['LISTE DES DOCUMENTS', 'OBSERVATIONS']),
                ...docsStandards.asMap().entries.map((e) {
                  final doc = docsStandards[e.key];
                  final label = doc['label'] as String;
                  final isPresent = doc['value'] as bool;
                  final observation = PdfReportStyles.docStatus(isPresent);
                  final isNonPresente = observation == 'Non presente';
                  return pw.TableRow(
                    decoration: e.key.isOdd
                        ? pw.BoxDecoration(color: PdfReportStyles.tableRowAlt)
                        : null,
                    children: [
                      PdfReportStyles.cell(label, isHeader: false),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        child: pw.Text(
                          observation,
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: fsSmall,
                            color: isNonPresente ? PdfColors.red : PdfReportStyles.darkGrey,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }),
                ...autresDocs.asMap().entries.map((e) {
                  final doc = autresDocs[e.key];
                  final rowIndex = docsStandards.length + e.key;
                  return pw.TableRow(
                    decoration: rowIndex.isOdd
                        ? pw.BoxDecoration(color: PdfReportStyles.tableRowAlt)
                        : null,
                    children: [
                      PdfReportStyles.cell(doc, isHeader: false),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        child: pw.Text(
                          'Présent',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: fsSmall,
                            color: PdfReportStyles.darkGrey,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }),
                if (mission.docAutre &&
                    !autresDocs.contains('Autre document pertinent'))
                  pw.TableRow(
                    decoration: (docsStandards.length + autresDocs.length).isOdd
                        ? pw.BoxDecoration(color: PdfReportStyles.tableRowAlt)
                        : null,
                    children: [
                      PdfReportStyles.cell('Autre document pertinent', isHeader: false),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        child: pw.Text(
                          'Présent',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: fsSmall,
                            color: PdfReportStyles.darkGrey,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PageTracker(
              key: 'renseignements_habilitation',
              registry: trackedPages,
              offset: offset,
              child: PdfReportStyles.subTitle(
                '3. Habilitation électrique du personnel d\'intervention',
              ),
            ),
            pw.SizedBox(height: 6),
            () {
              final habVal = rg?.habilitationElectriqueEffective ?? 'Inconnu';
              PdfColor habColor;
              if (habVal == 'Oui') {
                habColor = PdfColor.fromInt(0xFF2E7D32); // Vert
              } else if (habVal == 'Non') {
                habColor = PdfColor.fromInt(0xFFC62828); // Rouge
              } else {
                habColor = PdfColors.black; // Noir (Inconnu)
              }

              return pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.4),
                  color: PdfReportStyles.tableRowAlt,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(
                      flex: 7,
                      child: pw.Text(
                        'Les techniciens disposent-ils d\'une formation en habilitation électrique ?',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: fsBody,
                          color: PdfReportStyles.darkGrey,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      habVal,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: fsBody,
                        fontWeight: pw.FontWeight.bold,
                        color: habColor,
                      ),
                    ),
                  ],
                ),
              );
            }(),
          ],
        ),
      ],
    );
  }

}
