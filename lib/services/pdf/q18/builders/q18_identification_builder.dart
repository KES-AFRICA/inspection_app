// lib/services/pdf/q18/builders/q18_identification_builder.dart

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_snapshot.dart';

/// Builder responsable de la construction des Sections 1 et 4 du Rapport Q18 :
/// - Section 1 : Identification de la mission
/// - Section 4 : Présentation du site et des installations vérifiées
class Q18IdentificationBuilder {
  /// Construit la Section 1 : Identification de la mission
  static List<pw.Widget> buildSection1Identification(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final mission = data.mission;
    final rg = data.renseignements;
    final verificateur = data.currentUser;

    final clientName = mission.nomClient.trim().isNotEmpty
        ? mission.nomClient.trim()
        : (rg != null && rg.etablissement.trim().isNotEmpty
            ? rg.etablissement.trim()
            : 'Non renseigné');

    final signataire = (mission.dgResponsable != null && mission.dgResponsable!.trim().isNotEmpty)
        ? mission.dgResponsable!.trim()
        : 'Direction / Responsable technique du site';

    final adresse = (mission.adresseClient != null && mission.adresseClient!.trim().isNotEmpty)
        ? mission.adresseClient!.trim()
        : (data.lieuIntervention.isNotEmpty ? data.lieuIntervention : 'Non renseigné');

    final activite = (mission.activiteClient != null && mission.activiteClient!.trim().isNotEmpty)
        ? mission.activiteClient!.trim()
        : (rg != null && rg.activiteSurSite != null && rg.activiteSurSite!.trim().isNotEmpty
            ? rg.activiteSurSite!.trim()
            : (rg != null && rg.activite.trim().isNotEmpty
                ? rg.activite.trim()
                : 'Non renseigné'));

    final dateFormat = DateFormat('dd/MM/yyyy');
    final String datesVerification;
    if (rg?.dateDebut != null && rg?.dateFin != null) {
      if (rg!.dateDebut == rg.dateFin) {
        datesVerification = 'Le ${dateFormat.format(rg.dateDebut!)}';
      } else {
        datesVerification =
            'Du ${dateFormat.format(rg.dateDebut!)} au ${dateFormat.format(rg.dateFin!)}';
      }
    } else if (mission.dateIntervention != null) {
      datesVerification = 'Le ${dateFormat.format(mission.dateIntervention!)}';
    } else {
      datesVerification = dateFormat.format(data.dateRapportEffective);
    }

    final nomVerificateur = (verificateur != null &&
            '${verificateur.prenom} ${verificateur.nom}'.trim().isNotEmpty)
        ? '${verificateur.prenom} ${verificateur.nom}'.trim()
        : 'Ingénieur Contrôleur Technique Agréé';

    const qualiteVerificateur = 'Inspecteur / Contrôleur Technique Électrique';

    final rows = [
      ['Raison sociale de l\'établissement', clientName],
      ['Nom et qualité du signataire', signataire],
      ['Adresse de l\'établissement', adresse],
      ['Activité principale', activite],
      ['Date(s) de la vérification', datesVerification],
      ['Nom et qualité du vérificateur', '$nomVerificateur - $qualiteVerificateur'],
      ['Raison sociale du vérificateur', 'KES INSPECTIONS AND PROJECTS'],
      ['Adresse du vérificateur', 'B.P. 12564 Douala - Cameroun'],
      ['N° du présent compte-rendu', data.numeroRapportQ18],
      [
        'N° du rapport de vérification périodique des installations électriques',
        data.numeroRapportVerifElec,
      ],
    ];

    return [
      PdfReportStyles.sectionBox('1. IDENTIFICATION DE LA MISSION', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(3.8),
          1: pw.FlexColumnWidth(6.2),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              PdfReportStyles.cell('Désignation', isHeader: true, centered: false),
              PdfReportStyles.cell('Informations', isHeader: true, centered: false),
            ],
          ),
          ...rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final label = entry.value[0];
            final val = entry.value[1];
            final isAlt = idx.isOdd;
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: isAlt ? PdfReportStyles.tableRowAlt : PdfColors.white,
              ),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(
                    label,
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
                    val,
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
      pw.SizedBox(height: 14),
    ];
  }

  /// Construit la Section 4 : Présentation du site et des installations vérifiées
  static List<pw.Widget> buildSection4Presentation(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final q = data.quantities;
    final mission = data.mission;
    final rg = data.renseignements;

    final clientName = mission.nomClient.trim().isNotEmpty
        ? mission.nomClient.trim()
        : 'Non renseigné';
    final siteName = (mission.nomSite != null && mission.nomSite!.trim().isNotEmpty)
        ? mission.nomSite!.trim()
        : (rg != null && rg.nomSite.trim().isNotEmpty ? rg.nomSite.trim() : clientName);
    final localisation = (mission.adresseClient != null && mission.adresseClient!.trim().isNotEmpty)
        ? mission.adresseClient!.trim()
        : data.lieuIntervention;
    final activite = (mission.activiteClient != null && mission.activiteClient!.trim().isNotEmpty)
        ? mission.activiteClient!.trim()
        : (rg != null && rg.activiteSurSite != null && rg.activiteSurSite!.trim().isNotEmpty
            ? rg.activiteSurSite!.trim()
            : (rg != null && rg.activite.trim().isNotEmpty ? rg.activite.trim() : 'Non renseigné'));

    final quantitesRows = [
      // 1. Moyenne Tension (HTA)
      ['Moyenne Tension (HTA)', 'Postes / Locaux techniques HTA', '${q.nbLocauxTechniquesHTA}'],
      ['Moyenne Tension (HTA)', 'Transformateurs HTA/BT', '${q.nbTransformateurs} (${q.transformateursPuissanceText})'],
      ['Moyenne Tension (HTA)', 'Cellules MT', '${q.nbCellules}'],
      // 2. Groupes Électrogènes
      ['Alimentation de remplacement', 'Locaux GE', '${q.nbLocauxGE}'],
      ['Alimentation de remplacement', 'Groupes électrogènes', '${q.nbGroupesElectrogenes} (${q.groupesPuissanceText})'],
      ['Alimentation de remplacement', 'Inverseurs normal / secours', '${q.nbInverseurs}'],
      // 3. Basse Tension (BT)
      ['Basse Tension (BT)', 'Postes / Locaux techniques BT', '${q.nbLocauxTechniquesBT}'],
      ['Basse Tension (BT)', 'Tableaux Généraux Basse Tension (TGBT)', '${q.nbTGBT}'],
      ['Basse Tension (BT)', 'Armoires de distribution', '${q.nbArmoires}'],
      ['Basse Tension (BT)', 'Coffrets divisionnaires', '${q.nbCoffrets}'],
      // 4. Protection Foudre & Surtensions
      [
        'Protection Foudre & Surtensions',
        'Installation extérieure contre la foudre (Paratonnerre)',
        q.presenceParatonnerre ? 'Présente' : 'Absente',
      ],
      ['Protection Foudre & Surtensions', 'Parafoudres Inverseurs N/S', q.presenceParafoudreInverseur],
      ['Protection Foudre & Surtensions', 'Parafoudres TGBT', q.presenceParafoudreTGBT],
      ['Protection Foudre & Surtensions', 'Parafoudres Armoires', q.presenceParafoudreArmoire],
      ['Protection Foudre & Surtensions', 'Parafoudres Coffrets', q.presenceParafoudreCoffret],
      // 5. Centrale Photovoltaïque
      ['Énergies renouvelables', 'Centrale photovoltaïque', q.presenceCentralePhotovoltaique],
    ];

    return [
      PdfReportStyles.sectionBox('4. PRÉSENTATION DU SITE ET DES INSTALLATIONS VÉRIFIÉES', fontBold: fontBold),
      pw.SizedBox(height: 6),
      PdfReportStyles.subTitle('4.1 Présentation générale du site', fontBold: fontBold),
      pw.SizedBox(height: 4),
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfReportStyles.tableRowAlt,
          border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.RichText(
              text: pw.TextSpan(
                style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
                children: [
                  pw.TextSpan(text: 'Établissement : ', style: pw.TextStyle(font: fontBold)),
                  pw.TextSpan(text: '$clientName - Site de $siteName\n'),
                  pw.TextSpan(text: 'Localisation : ', style: pw.TextStyle(font: fontBold)),
                  pw.TextSpan(text: '$localisation\n'),
                  pw.TextSpan(text: 'Activité exercée : ', style: pw.TextStyle(font: fontBold)),
                  pw.TextSpan(text: activite),
                ],
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 10),
      PdfReportStyles.subTitle('4.2 Récapitulatif quantitatif des installations contrôlées', fontBold: fontBold),
      pw.SizedBox(height: 4),
      pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(3.0),
          1: pw.FlexColumnWidth(4.5),
          2: pw.FlexColumnWidth(2.5),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              PdfReportStyles.cell('Domaine / Sous-ensemble', isHeader: true, centered: false),
              PdfReportStyles.cell('Équipement / Ouvrage', isHeader: true, centered: false),
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
