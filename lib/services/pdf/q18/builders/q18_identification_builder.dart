// lib/services/pdf/q18/builders/q18_identification_builder.dart

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_snapshot.dart';


/// Builder responsable de la construction des Sections 1 et 4 du Rapport Q18 :
/// - Section 1 : Identification de la mission (10 lignes normalisées selon référence)
/// - Section 4 : Présentation du site et des installations vérifiées (4.1 & 4.2)
class Q18IdentificationBuilder {
  /// Construit la Section 1 : Identification de la mission
  static List<pw.Widget> buildSection1Identification(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateEmission = dateFormat.format(data.dateRapportEffective);

    // Détermination de l'intitulé et des noms d'inspecteurs (Source JSA)
    final bool multiInspecteurs = data.intervenantsNoms.length > 1;
    final String labelInspecteur = multiInspecteurs ? 'Nom des vérificateurs' : 'Nom du vérificateur';
    final List<String> inspecteursList = data.intervenantsNoms.isNotEmpty
        ? data.intervenantsNoms
        : ['Ingénieur Contrôleur Technique'];

    final rows = <_IdentificationRowData>[
      _IdentificationRowData(
        label: labelInspecteur,
        widgetValue: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: inspecteursList
              .map(
                (nom) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                  child: pw.Text(
                    nom,
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 8.5,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      _IdentificationRowData(label: 'Client / exploitant', value: data.clientName),
      _IdentificationRowData(label: 'Site / établissement', value: data.siteName),
      _IdentificationRowData(label: 'Adresse du site', value: data.adresseSite),
      _IdentificationRowData(label: 'N° du rapport Q18', value: data.numeroRapportQ18),
      _IdentificationRowData(label: data.dateVisiteLabel, value: data.dateVisiteValue),
      _IdentificationRowData(label: 'Date d\'émission du rapport', value: dateEmission),
      _IdentificationRowData(label: 'Type de mission', value: data.typeMission),
      _IdentificationRowData(
        label: 'N° du rapport Q18 précédent',
        value: data.hasQ18Precedent ? 'Disponible sur site' : 'Non applicable',
      ),
      _IdentificationRowData(
        label: 'N° du rapport de vérification de conformité des installations électriques',
        value: data.numeroRapportVerifElec,
      ),
    ];

    return [
      PdfReportStyles.sectionBox('1. IDENTIFICATION DE LA MISSION', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(4.0),
          1: pw.FlexColumnWidth(6.0),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              PdfReportStyles.cell('Information', isHeader: true, centered: true),
              PdfReportStyles.cell('Valeur', isHeader: true, centered: true),
            ],
          ),
          ...rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isAlt = idx.isOdd;

            return pw.TableRow(
              verticalAlignment: pw.TableCellVerticalAlignment.middle,
              decoration: pw.BoxDecoration(
                color: isAlt ? PdfReportStyles.tableRowAlt : PdfColors.white,
              ),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    item.label,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8.5,
                      color: PdfReportStyles.headerColor,
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  alignment: pw.Alignment.centerLeft,
                  child: item.widgetValue ??
                      pw.Text(
                        item.value ?? '',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 8.5,
                          color: PdfColors.black,
                        ),
                      ),
                ),
              ],
            );
          }),
        ],
      ),
      pw.SizedBox(height: 12),
    ];
  }

  /// Construit la Section 4 : Présentation du site et des installations vérifiées
  static List<pw.Widget> buildSection4Presentation(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
    Map<String, int>? trackedPages,
    int pageOffset = 2,
  }) {
    final q = data.quantities;
    final mission = data.mission;
    final rg = data.renseignements;

    final activite = (mission.activiteSurSite != null && mission.activiteSurSite!.trim().isNotEmpty)
        ? mission.activiteSurSite!.trim()
        : (rg != null && rg.activiteSurSite != null && rg.activiteSurSite!.trim().isNotEmpty
            ? rg.activiteSurSite!.trim()
            : (mission.activiteClient != null && mission.activiteClient!.trim().isNotEmpty
                ? mission.activiteClient!.trim()
                : (rg != null && rg.activite.trim().isNotEmpty ? rg.activite.trim() : 'Non renseigné')));

    final siteRows = [
      ['Établissement', data.clientName],
      ['Site', data.siteName],
      ['Localisation', data.adresseSite],
      ['Activité exercée', activite],
    ];

    final quantitesRows = [
      // 1. Moyenne Tension (HTA)
      ['Moyenne Tension (HTA)', 'Nombre de locaux techniques HTA', '${q.nbLocauxTechniquesHTA}'],
      [
        'Moyenne Tension (HTA)',
        'Nombre de transformateurs et puissance',
        '${q.nbTransformateurs} (${q.transformateursPuissanceText})',
      ],
      ['Moyenne Tension (HTA)', 'Nombre de cellule(s)', '${q.nbCellules}'],
      // 2. Groupes Électrogènes (Section 4 Description)
      ['Alimentation de remplacement', 'Nombre de locaux groupe électrogène', '${q.nbLocauxGE}'],
      [
        'Alimentation de remplacement',
        'Nombre de Groupe électrogène et puissance',
        '${q.nbGroupesElectrogenes} (${q.groupesPuissanceText})',
      ],
      ['Alimentation de remplacement', 'Nombre d’inverseur', '${q.nbInverseurs}'],
      // 3. Basse Tension (BT)
      ['Basse Tension (BT)', 'Nombre de locaux techniques BT', '${q.nbLocauxTechniquesBT}'],
      ['Basse Tension (BT)', 'Nombre de TGBT', '${q.nbTGBT}'],
      ['Basse Tension (BT)', 'Nombre d’armoire', '${q.nbArmoires}'],
      ['Basse Tension (BT)', 'Nombre de coffret', '${q.nbCoffrets}'],
      // 4. Protection Foudre & Parafoudres
      [
        'Protection Foudre & Parafoudres',
        'Présence de paratonnerre',
        q.presenceParatonnerre ? 'Présent' : 'Absent',
      ],
      ['Protection Foudre & Parafoudres', 'Parafoudre - Inverseur', q.presenceParafoudreInverseur],
      ['Protection Foudre & Parafoudre', 'Parafoudre - TGBT', q.presenceParafoudreTGBT],
      ['Protection Foudre & Parafoudres', 'Parafoudre - Armoire', q.presenceParafoudreArmoire],
      ['Protection Foudre & Parafoudres', 'Parafoudre - Coffret', q.presenceParafoudreCoffret],
      // 5. Centrale Photovoltaïque (intacte)
      ['Énergies renouvelables', 'Présence d\'une centrale photovoltaïque', q.presenceCentralePhotovoltaique],
    ];

    final subTitle41 = PdfReportStyles.subTitle('4.1 Présentation générale du site', fontBold: fontBold);
    final subTitle42 = PdfReportStyles.subTitle('4.2 Récapitulatif quantitatif des installations contrôlées', fontBold: fontBold);

    return [
      PdfReportStyles.sectionBox('4. PRÉSENTATION DU SITE ET DES INSTALLATIONS VÉRIFIÉES', fontBold: fontBold),
      pw.SizedBox(height: 6),
      trackedPages != null
          ? PageTracker(key: 'q18_s4_1', registry: trackedPages, offset: pageOffset, child: subTitle41)
          : subTitle41,
      pw.SizedBox(height: 4),
      pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(3.0),
          1: pw.FlexColumnWidth(7.0),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              PdfReportStyles.cell('Rubrique', isHeader: true, centered: true),
              PdfReportStyles.cell('Informations', isHeader: true, centered: true),
            ],
          ),
          ...siteRows.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            final isAlt = idx.isOdd;
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: isAlt ? PdfReportStyles.tableRowAlt : PdfColors.white,
              ),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(
                    row[0],
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8.5,
                      color: PdfReportStyles.headerColor,
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(
                    row[1],
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 8.5,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      pw.SizedBox(height: 10),
      trackedPages != null
          ? PageTracker(key: 'q18_s4_2', registry: trackedPages, offset: pageOffset, child: subTitle42)
          : subTitle42,
      pw.SizedBox(height: 4),

      pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(3.2),
          1: pw.FlexColumnWidth(4.5),
          2: pw.FlexColumnWidth(2.3),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              PdfReportStyles.cell('Domaine / Sous-ensemble', isHeader: true, centered: true),
              PdfReportStyles.cell('Équipement / Ouvrage', isHeader: true, centered: true),
              PdfReportStyles.cell('Quantité / Statut', isHeader: true, centered: true),
            ],
          ),
          ...quantitesRows.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            final isAlt = idx.isOdd;
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: isAlt ? PdfReportStyles.tableRowAlt : PdfColors.white,
              ),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: pw.Text(
                    row[0],
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8.0,
                      color: PdfReportStyles.headerColor,
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: pw.Text(
                    row[1],
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 8.0,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    row[2],
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8.0,
                      color: PdfColors.black,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      pw.SizedBox(height: 14),
    ];
  }
}

class _IdentificationRowData {
  final String label;
  final String? value;
  final pw.Widget? widgetValue;

  const _IdentificationRowData({
    required this.label,
    this.value,
    this.widgetValue,
  });
}
