// lib/services/pdf/q18/builders/q18_conclusion_builder.dart

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_snapshot.dart';

/// Builder responsable de la construction des Sections 12, 13, 14 et 15 du Rapport Q18 :
/// - Section 12 : Avis global et conclusion
/// - Section 13 : Compte rendu de levée des dangers
/// - Section 14 : Prochaine échéance de vérification
/// - Section 15 : Signature et cachet du vérificateur
class Q18ConclusionBuilder {
  /// Section 12 : Avis global et conclusion
  static List<pw.Widget> buildSection12AvisGlobal(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final hasDangerAvere = data.hasDangerAvere;
    final appreciation = data.appreciationGlobale;

    pw.Widget buildCheckbox(bool isChecked, String label, {bool isRed = false}) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 12,
            height: 12,
            decoration: pw.BoxDecoration(
              color: isChecked ? (isRed ? PdfColor.fromInt(0xFFC00000) : PdfReportStyles.accentColor) : PdfColors.white,
              border: pw.TableBorder.all(
                color: isChecked ? (isRed ? PdfColor.fromInt(0xFFC00000) : PdfReportStyles.accentColor) : PdfReportStyles.borderColor,
                width: 1.0,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
            alignment: pw.Alignment.center,
            child: isChecked
                ? pw.Text(
                    'X',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8.0,
                      color: PdfColors.white,
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
                color: isChecked && isRed ? PdfColor.fromInt(0xFFC00000) : PdfColors.black,
              ),
            ),
          ),
        ],
      );
    }

    return [
      PdfReportStyles.sectionBox('12. AVIS GLOBAL ET CONCLUSION DE LA VÉRIFICATION', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: hasDangerAvere ? PdfReportStyles.priorite3Color : PdfReportStyles.conformeColor,
          border: pw.TableBorder.all(
            color: hasDangerAvere ? PdfColor.fromInt(0xFFC00000) : PdfColors.green800,
            width: 0.5,
          ),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'CONCLUSION AU REGARD DU RÉFÉRENTIEL APSAD D18 :',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 8.5,
                color: hasDangerAvere ? PdfColor.fromInt(0xFFC00000) : PdfColors.green900,
              ),
            ),
            pw.SizedBox(height: 6),
            buildCheckbox(
              !hasDangerAvere,
              'CAS 1 : Les installations électriques vérifiées ne présentent pas de danger avéré d\'incendie ou d\'explosion au jour de la visite.',
            ),
            pw.SizedBox(height: 6),
            buildCheckbox(
              hasDangerAvere,
              'CAS 2 : Les installations électriques vérifiées présentent des dangers avérés d\'incendie ou d\'explosion (se reporter à la Section 10).',
              isRed: true,
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 8),
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
            pw.Text(
              'Niveau d\'appréciation synthétique de l\'installation :',
              style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfReportStyles.headerColor),
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                buildAppreciationPill('Satisfaisant', appreciation == 'Satisfaisant', fontBold),
                buildAppreciationPill('Acceptable', appreciation == 'Acceptable', fontBold),
                buildAppreciationPill('Insuffisant', appreciation == 'Insuffisant', fontBold),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Synthèse opérationnelle :',
              style: pw.TextStyle(font: fontBold, fontSize: 8.0, color: PdfColors.black),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              data.avisSyntheseText,
              style: pw.TextStyle(font: fontRegular, fontSize: 8.0, color: PdfColors.black, lineSpacing: 1.2),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 12),
    ];
  }

  static pw.Widget buildAppreciationPill(String label, bool isSelected, pw.Font fontBold) {
    PdfColor bgColor = PdfColors.grey200;
    PdfColor textColor = PdfColors.grey700;
    PdfColor borderColor = PdfColors.grey400;

    if (isSelected) {
      if (label == 'Satisfaisant') {
        bgColor = PdfColor.fromInt(0xFFE8F5E9);
        textColor = PdfColor.fromInt(0xFF2E7D32);
        borderColor = PdfColor.fromInt(0xFF4CAF50);
      } else if (label == 'Acceptable') {
        bgColor = PdfColor.fromInt(0xFFFFF3E0);
        textColor = PdfColor.fromInt(0xFFE65100);
        borderColor = PdfColor.fromInt(0xFFFF9800);
      } else {
        bgColor = PdfColor.fromInt(0xFFFFEBEE);
        textColor = PdfColor.fromInt(0xFFC00000);
        borderColor = PdfColor.fromInt(0xFFF44336);
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.TableBorder.all(color: borderColor, width: isSelected ? 1.0 : 0.4),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (isSelected) ...[
            pw.Container(
              width: 8,
              height: 8,
              margin: const pw.EdgeInsets.only(right: 5),
              decoration: pw.BoxDecoration(color: textColor, shape: pw.BoxShape.circle),
            ),
          ],
          pw.Text(
            label,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 8.0,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Section 13 : Compte rendu de levée des dangers (Vérifications antérieures)
  static List<pw.Widget> buildSection13LeveeDangers({
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return [
      PdfReportStyles.sectionBox('13. COMPTE RENDU DE LEVÉE DES DANGERS ANTÉRIEURS', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Container(
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
    ];
  }

  /// Section 14 : Prochaine échéance de vérification
  static List<pw.Widget> buildSection14ProchaineEcheance(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateStr = dateFormat.format(data.dateProchaineVisite);

    return [
      PdfReportStyles.sectionBox('14. PROCHAINE ÉCHÉANCE DE VÉRIFICATION PÉRIODIQUE', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Container(
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
    ];
  }

  /// Section 15 : Signature du vérificateur
  static List<pw.Widget> buildSection15Signature(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateStr = dateFormat.format(data.dateRapportEffective);
    final lieu = data.lieuIntervention;

    final verificateur = data.currentUser;
    final nomVerificateur = (verificateur != null &&
            '${verificateur.prenom} ${verificateur.nom}'.trim().isNotEmpty)
        ? '${verificateur.prenom} ${verificateur.nom}'.trim()
        : 'L\'Inspecteur Technique';

    const titreVerificateur = 'Ingénieur Contrôleur Technique Électrique';

    return [
      PdfReportStyles.sectionBox('15. VISA ET SIGNATURE DU VÉRIFICATEUR AGRÉÉ', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(5.0),
          1: pw.FlexColumnWidth(5.0),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              PdfReportStyles.cell('Détails de l\'intervention', isHeader: true, centered: false),
              PdfReportStyles.cell('Cachet et signature de l\'organisme', isHeader: true, centered: false),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Fait à : $lieu', style: pw.TextStyle(font: fontBold, fontSize: 8.5)),
                    pw.SizedBox(height: 3),
                    pw.Text('Le : $dateStr', style: pw.TextStyle(font: fontBold, fontSize: 8.5)),
                    pw.SizedBox(height: 8),
                    pw.Text('Vérificateur : $nomVerificateur',
                        style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfReportStyles.headerColor)),
                    pw.SizedBox(height: 2),
                    pw.Text('Qualité : $titreVerificateur',
                        style: pw.TextStyle(font: fontRegular, fontSize: 8.0, color: PdfColors.grey800)),
                    pw.SizedBox(height: 6),
                    pw.Text('Organisme : KES INSPECTIONS AND PROJECTS',
                        style: pw.TextStyle(font: fontBold, fontSize: 8.0, color: PdfReportStyles.headerColor)),
                  ],
                ),
              ),
              pw.Container(
                height: 90,
                padding: const pw.EdgeInsets.all(8),
                alignment: pw.Alignment.center,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Cachet officiel & Signature',
                      style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey600),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      width: 140,
                      height: 50,
                      decoration: pw.BoxDecoration(
                        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5, style: pw.BorderStyle.dashed),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'Visa KES',
                        style: pw.TextStyle(font: fontBold, fontSize: 8.0, color: PdfColors.grey400),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 12),
    ];
  }
}
