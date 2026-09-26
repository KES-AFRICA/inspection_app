// lib/services/pdf/q18/builders/q18_conclusion_builder.dart

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_snapshot.dart';

/// Builder responsable de la construction des Sections 12, 13, 14 et 15 du Rapport Q18 :
/// - Section 12 : Avis global et conclusion (Cas 1 / Cas 2 exclusifs, cases à cocher sobres)
/// - Section 13 : Compte rendu de levée des dangers
/// - Section 14 : Prochaine échéance de vérification
/// - Section 15 : Visa et signature du/des vérificateur(s) agréé(s) (Fait à Douala)
class Q18ConclusionBuilder {
  /// Section 12 : Avis global et conclusion de la vérification
  ///
  /// Règle fondamentale :
  /// - Détection déterministe entre Cas 1 (0 danger avéré ET 0 dégradation) et Cas 2.
  /// - Un SEUL cas affiché, aucun résidu ou bloc vide de l'autre cas.
  /// - Synthèse du vérificateur sobre avec 3 cases à cocher, couleur portée
  ///   uniquement par le check sélectionné (vert, orange, rouge).
  static List<pw.Widget> buildSection12AvisGlobal(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final bool isCas1 = data.countDangerAvere == 0 && data.countDegradation == 0;
    final appreciation = data.appreciationGlobale;

    pw.Widget buildCheckItem(bool isChecked, String label, {required PdfColor checkedColor}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3.0),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 11,
              height: 11,
              decoration: pw.BoxDecoration(
                border: pw.TableBorder.all(
                  color: isChecked ? checkedColor : PdfColors.grey600,
                  width: isChecked ? 1.0 : 0.8,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
              alignment: pw.Alignment.center,
              child: isChecked
                  ? pw.Text(
                      'X',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 7.5,
                        color: checkedColor,
                      ),
                    )
                  : null,
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  font: isChecked ? fontBold : fontRegular,
                  fontSize: 8.5,
                  color: PdfColors.black,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return [
      PdfReportStyles.sectionBox('12. AVIS GLOBAL ET CONCLUSION DE LA VÉRIFICATION', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Paragraph(
        text: 'À l\'issue de la mission de vérification des installations électriques, réalisée conformément au périmètre défini, les observations, essais et contrôles effectués ont permis d\'évaluer l\'état général des installations au regard des risques d\'incendie et d\'explosion d\'origine électrique.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black, lineSpacing: 1.2),
      ),
      pw.SizedBox(height: 6),

      // Cas exclusif 1 OU Cas 2 (Règle 27 & 28 : Ne pas afficher "Cas n°1 :" ou "Cas n°2 :")
      if (isCas1) ...[
        pw.Text(
          'Absence de danger identifié',
          style: pw.TextStyle(font: fontBold, fontSize: 9.0, color: PdfColor.fromInt(0xFF15803D)),
        ),
        pw.SizedBox(height: 4),
        pw.Paragraph(
          text: 'Les vérifications réalisées n\'ont pas mis en évidence de danger avéré susceptible de compromettre la sécurité des personnes, des biens ou la continuité d\'exploitation au regard du risque d\'incendie ou d\'explosion d\'origine électrique.',
          style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black, lineSpacing: 1.2),
        ),
        pw.SizedBox(height: 3),
        pw.Paragraph(
          text: 'L\'installation présente un niveau de sécurité satisfaisant dans le périmètre de la mission. Il est néanmoins recommandé de poursuivre les opérations de maintenance préventive, les vérifications réglementaires périodiques ainsi que les contrôles thermographiques afin de maintenir ce niveau de sécurité dans le temps.',
          style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black, lineSpacing: 1.2),
        ),
      ] else ...[
        pw.Text(
          'Danger(s) identifié(s)',
          style: pw.TextStyle(font: fontBold, fontSize: 9.0, color: PdfColor.fromInt(0xFFC00000)),
        ),
        pw.SizedBox(height: 4),
        pw.Paragraph(
          text: 'Les vérifications réalisées ont mis en évidence un ou plusieurs dangers susceptibles d\'accroître le risque d\'incendie ou d\'explosion d\'origine électrique (au total ${data.countDangerAvere} danger(s) avéré(s) et ${data.countDegradation} dégradation(s) relevé(s)).',
          style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black, lineSpacing: 1.2),
        ),
        pw.SizedBox(height: 3),
        pw.Paragraph(
          text: 'Ces anomalies nécessitent la mise en œuvre de mesures correctives afin de rétablir un niveau de sécurité conforme aux exigences réglementaires et aux règles de l\'art.',
          style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black, lineSpacing: 1.2),
        ),
        pw.SizedBox(height: 3),
        pw.Paragraph(
          text: 'Il y a lieu de procéder aux travaux de mise en conformité des installations électriques conformément aux recommandations formulées dans le présent rapport.',
          style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black, lineSpacing: 1.2),
        ),
        pw.SizedBox(height: 3),
        pw.Paragraph(
          text: 'La priorité des actions devra être définie en fonction de la criticité des anomalies identifiées, les situations présentant un danger immédiat devant faire l\'objet d\'une intervention sans délai.',
          style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black, lineSpacing: 1.2),
        ),
      ],

      pw.SizedBox(height: 8),

      // Synthèse du vérificateur
      pw.Text(
        'Synthèse du vérificateur',
        style: pw.TextStyle(font: fontBold, fontSize: 9.0, color: PdfReportStyles.headerColor),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'L\'état général des installations électriques est évalué comme :',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
      ),
      pw.SizedBox(height: 4),
      buildCheckItem(
        appreciation == 'Satisfaisant',
        'Satisfaisant - Aucun danger avéré identifié.',
        checkedColor: const PdfColor.fromInt(0xFF15803D),
      ),
      buildCheckItem(
        appreciation == 'Acceptable',
        'Acceptable sous réserve de la levée des anomalies relevées.',
        checkedColor: const PdfColor.fromInt(0xFFED7D31),
      ),
      buildCheckItem(
        appreciation == 'Insuffisant',
        'Insuffisant - Présence de dangers nécessitant des actions correctives prioritaires.',
        checkedColor: const PdfColor.fromInt(0xFFC00000),
      ),
      pw.SizedBox(height: 8),
      pw.Paragraph(
        text: 'Le présent avis est formulé sur la base des constatations effectuées lors de la vérification et dans les limites du périmètre de la mission. Il appartient au propriétaire ou à l\'exploitant des installations de mettre en œuvre les actions correctives nécessaires et d\'assurer le maintien en conformité des installations électriques.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.0, color: PdfColors.grey800, lineSpacing: 1.2),
      ),
      pw.SizedBox(height: 12),
    ];
  }

  /// Section 13 : Compte rendu de levée des dangers (Règle 30 : suppression de "le cas échéant")
  /// Règle 29 : Bloc logique indissociable.
  static List<pw.Widget> buildSection13LeveeDangers({
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PdfReportStyles.sectionBox('13. COMPTE RENDU DE LEVÉE DES DANGERS', fontBold: fontBold),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfReportStyles.tableRowAlt,
              border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Text(
              'Sans objet (Première vérification au titre du traité APSAD D18 ou absence de réserve antérieure formalisée).',
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 8.0,
                color: PdfColors.black,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
        ],
      ),
    ];
  }

  /// Section 14 : Prochaine échéance de vérification
  /// Règle 29 : Bloc logique indissociable.
  static List<pw.Widget> buildSection14ProchaineEcheance(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateStr = dateFormat.format(data.dateProchaineVisite);

    return [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PdfReportStyles.sectionBox('14. PROCHAINE ÉCHÉANCE DE VÉRIFICATION PÉRIODIQUE', fontBold: fontBold),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfReportStyles.lightBlue,
              border: pw.TableBorder.all(color: PdfReportStyles.accentColor, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
                      children: [
                        const pw.TextSpan(
                          text: 'Conformément aux exigences du référentiel APSAD D18, la périodicité de contrôle des installations électriques est annuelle.\n\n',
                        ),
                        pw.TextSpan(
                          text: 'DATE BUTOIR DE LA PROCHAINE VÉRIFICATION : ',
                          style: pw.TextStyle(font: fontBold, color: PdfReportStyles.headerColor),
                        ),
                        pw.TextSpan(
                          text: dateStr,
                          style: pw.TextStyle(font: fontBold, color: PdfColor.fromInt(0xFFC00000), fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
        ],
      ),
    ];
  }

  /// Section 15 : Visa et signature des vérificateurs agréés
  ///
  /// Réplique exacte et intégrale de la page de signature du rapport de vérification électrique :
  /// - Titre exact : 15. VISA ET SIGNATURE DES VÉRIFICATEURS AGRÉÉS
  /// - Bloc de direction centré : LA DIRECTION, Patrick ESSAME ESSAME
  /// - Lieu et date dynamique : Fait à Douala le [date]
  /// - Ligne séparatrice de 180pt et mention 'Signature et cachet'
  static List<pw.Widget> buildSection15Signature(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateStr = dateFormat.format(data.dateRapportEffective);

    return [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PdfReportStyles.sectionBox(
            '15. VISA ET SIGNATURE DES VÉRIFICATEURS AGRÉÉS',
            fontBold: fontBold,
          ),
          pw.SizedBox(height: 260),
          pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'LA DIRECTION',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfReportStyles.headerColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Patrick ESSAME ESSAME',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfReportStyles.headerColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 36),
                pw.Text(
                  'Fait à Douala le $dateStr',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 13,
                    color: PdfReportStyles.headerColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  width: 180,
                  height: 1,
                  color: PdfColors.grey500,
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Signature et cachet',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 8.5,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
        ],
      ),
    ];
  }
}
