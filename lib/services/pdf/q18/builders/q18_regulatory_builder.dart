// lib/services/pdf/q18/builders/q18_regulatory_builder.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

/// Builder responsable des sections réglementaires et méthodologiques du Rapport Q18 :
/// - Section 2 : Objet et cadre de la mission
/// - Section 3 : Cadre réglementaire et normatif
/// - Section 7 : Méthodologie et points de contrôle
/// - Section 8 : Échelle de classification des dangers
/// - Section 9 : Typologie des dangers les plus courants
class Q18RegulatoryBuilder {
  /// Section 2 : Objet et cadre de la mission
  static List<pw.Widget> buildSection2ObjetCadre({
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return [
      PdfReportStyles.sectionBox('2. OBJET ET CADRE DE LA MISSION', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Paragraph(
        text: 'La présente mission a pour objet la vérification des installations électriques au regard des risques d\'incendie et d\'explosion, conformément aux prescriptions du Traité d\'évaluation du risque APSAD D18 et aux référentiels réglementaires en vigueur.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black, lineSpacing: 1.2),
      ),
      pw.SizedBox(height: 2),
      pw.Paragraph(
        text: 'Elle s\'inscrit dans le cadre de la prévention des risques professionnels et de la préservation du patrimoine industriel et tertiaire contre les sinistres d\'origine électrique. Le présent compte-rendu Q18 rend compte des constats relevés lors de la visite sur site et permet aux exploitants ainsi qu\'aux assureurs d\'apprécier le niveau de sécurité réel des installations examinées.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black, lineSpacing: 1.2),
      ),
      pw.SizedBox(height: 6),
      pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          color: PdfReportStyles.priorite1Color,
          border: pw.TableBorder.all(color: PdfColors.orange800, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        ),
        child: pw.RichText(
          text: pw.TextSpan(
            style: pw.TextStyle(font: fontRegular, fontSize: 7.8, color: PdfColors.black),
            children: [
              pw.TextSpan(
                text: 'NOTE LIMINAIRE IMPORTANTE : ',
                style: pw.TextStyle(font: fontBold, color: PdfColors.brown900),
              ),
              const pw.TextSpan(
                text: 'La vérification Q18 est une inspection visuelle accompagnée d\'investigations par échantillonnage. Elle ne constitue ni une réception technique de conformité de fin de travaux, ni un audit exhaustif de dimensionnement d\'ingénierie. Elle cible prioritairement les anomalies et dégradations susceptibles d\'engendrer un échauffement excessif, un arc électrique, une inflammation de matériaux ou une explosion.',
              ),
            ],
          ),
        ),
      ),
      pw.SizedBox(height: 12),
    ];
  }

  /// Section 3 : Cadre réglementaire et normatif
  static List<pw.Widget> buildSection3CadreReglementaire({
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final textes = [
      [
        'Traité APSAD D18',
        'Vérification des installations électriques - Déclaration de conformité aux règles d\'assurances contre l\'incendie et l\'explosion.',
      ],
      [
        'Loi n° 2011/022 du 14 décembre 2011',
        'Loi régissant le secteur de l\'électricité en République du Cameroun.',
      ],
      [
        'Arrêté n° 002164/MINIMDT/MINEE du 20 juin 2012',
        'Rendant obligatoire la norme camerounaise NC 244 C 15 100 relative aux installations électriques à basse tension.',
      ],
      [
        'Norme NC 244 C 15 100 / NF C 15-100',
        'Règles d\'installation électrique à basse tension - Conception, mise en œuvre, vérification et entretien.',
      ],
      [
        'Norme NF C 13-100 & NF C 13-200',
        'Postes de livraison HTA et installations électriques à haute tension.',
      ],
      [
        'Décret n° 2018/1969/PM du 15 mars 2018',
        'Règles de base de sécurité incendie dans les bâtiments en République du Cameroun.',
      ],
      [
        'Arrêté n° 039/MTPS/IMT du 26 novembre 1984',
        'Mesures générales d\'hygiène et de sécurité sur les lieux de travail.',
      ],
      [
        'Norme NF C 17-102',
        'Protection contre la foudre - Systèmes de protection contre la foudre à dispositif d\'amorçage.',
      ],
    ];

    return [
      PdfReportStyles.sectionBox('3. CADRE RÉGLEMENTAIRE ET NORMATIF', fontBold: fontBold),
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
              PdfReportStyles.cell('Référence réglementaire / normative', isHeader: true, centered: false),
              PdfReportStyles.cell('Libellé et portée d\'application', isHeader: true, centered: false),
            ],
          ),
          ...textes.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: idx.isOdd ? PdfReportStyles.tableRowAlt : PdfColors.white,
              ),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: pw.Text(
                    item[0],
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
                    item[1],
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 8.0,
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

  /// Section 7 : Méthodologie et points de contrôle
  static List<pw.Widget> buildSection7Methodologie({
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final points = [
      '1. État général des matériels électriques (détérioration, vieillissement, propreté, traces de corrosion ou d\'humidité).',
      '2. Protection contre les contacts directs (maintien des indices IP/IK, intégrité des plastrons, enveloppes et presse-étoupes).',
      '3. Protection contre les contacts indirects (continuité des conducteurs de protection PE, schéma de liaison à la terre, DDR).',
      '4. Adéquation et calibrage des dispositifs de protection contre les surintensités (calibre disjoncteurs/fusibles vs section câbles).',
      '5. Échauffements anormaux et connexions défectueuses (serrage des borniers, traces de brûlures, absence de jeux de barres protégés).',
      '6. Protection contre les surtensions d\'origine atmosphérique (état et coordination des parafoudres, prise de terre des paratonnerres).',
      '7. Confinement du feu et coupe-feu (étanchéité des traversées de câbles, calfeutrement coupe-feu des parois, sas postes HTA).',
      '8. Exploitation en locaux à risques particuliers (locaux BE2 à risque d\'incendie, stockage de matières inflammables, conformité ATEX).',
      '9. Organes de sécurité d\'urgence (accessibilité et efficacité des arrêts d\'urgence coupure générale, éclairage de sécurité d\'évacuation).',
    ];

    return [
      PdfReportStyles.sectionBox('7. MÉTHODOLOGIE ET POINTS DE CONTRÔLE', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Paragraph(
        text: 'Les vérifications portent sur l\'examen méthodique visuel et instrumenté des installations, articulé autour de 9 thématiques majeures d\'investigation :',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
      ),
      pw.SizedBox(height: 4),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: points.map((p) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  margin: const pw.EdgeInsets.only(top: 3, right: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfReportStyles.accentColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    p,
                    style: pw.TextStyle(font: fontRegular, fontSize: 8.0, color: PdfColors.black),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      pw.SizedBox(height: 12),
    ];
  }

  /// Section 8 : Échelle de classification des dangers
  static List<pw.Widget> buildSection8ClassificationDangers({
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final echelles = [
      [
        'Danger avéré',
        'Anomalie présentant un risque direct, grave et immédiat d\'inflammation, d\'arc électrique ou d\'explosion (ex: connexion surchauffée, conducteur sous tension nu accessible, protection shuntée ou surcalibrée, calfeutrement absent en zone inflammable).',
        PdfColor.fromInt(0xFFC00000), // Rouge
      ],
      [
        'Dégradation',
        'Détérioration ou défaut d\'entretien ne présentant pas un risque immédiat mais susceptible d\'évoluer à court/moyen terme vers un danger avéré s\'il n\'est pas corrigé (ex: vieillissement d\'isolant, desserrage modéré, corrosion d\'enveloppe).',
        PdfColor.fromInt(0xFFED7D31), // Orange
      ],
      [
        'Non-conformité hors périmètre APSAD',
        'Écart par rapport aux normes ou décrets d\'hygiène et sécurité ne constituant pas directement une cause potentielle de départ de feu ou d\'explosion (ex: repérage incomplet, absence de schéma unifilaire, absence d\'affichage réglementaire).',
        PdfColor.fromInt(0xFF70AD47), // Vert olive / gris vert
      ],
      [
        'Point sensible / Observation',
        'Situation constatée méritant une vigilance particulière de l\'exploitant, ou bonne pratique recommandée pour préserver la sécurité globale de l\'installation dans le temps.',
        PdfColor.fromInt(0xFF41719C), // Bleu KES
      ],
    ];

    return [
      PdfReportStyles.sectionBox('8. ÉCHELLE DE CLASSIFICATION DES DANGERS', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Paragraph(
        text: 'Conformément au référentiel APSAD D18, chaque constat relevé est classé selon une hiérarchie normalisée à 4 niveaux d\'appréciation du risque :',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
      ),
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
              PdfReportStyles.cell('Niveau de gravité', isHeader: true, centered: false),
              PdfReportStyles.cell('Critères d\'attribution et portée du risque', isHeader: true, centered: false),
            ],
          ),
          ...echelles.map((item) {
            final label = item[0] as String;
            final desc = item[1] as String;
            final color = item[2] as PdfColor;
            return pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 8,
                        height: 8,
                        margin: const pw.EdgeInsets.only(right: 5),
                        decoration: pw.BoxDecoration(
                          color: color,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          label,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8.0,
                            color: PdfReportStyles.headerColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(
                    desc,
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 8.0,
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

  /// Section 9 : Typologie des dangers les plus courants
  static List<pw.Widget> buildSection9TypologieDangers({
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final dangersTypes = [
      ['Échauffement / Surcharge', 'Effet Joule excessif sur câbles sous-dimensionnés ou borniers desserrés.'],
      ['Défaut d\'isolement', 'Courant de fuite permanent à la terre, dégradation des gaines isolantes.'],
      ['Absence de coupure d\'urgence', 'Impossibilité d\'isoler rapidement l\'installation en cas de sinistre ou d\'amorce d\'arc.'],
      ['Mauvais état des canalisations', 'Gaines arrachées, câbles pincés ou exposés à des agressions mécaniques.'],
      ['Obturation / Calfeutrement absent', 'Propagation facilitée des gaz chauds et flammes à travers les parois coupe-feu.'],
      ['Protection inadaptée ou shuntée', 'Disjoncteur surcalibré par rapport au câble, fusible remplacé par du fil de cuivre.'],
      ['Défaut de liaison des masses / PE', 'Tension dangereuse sur enveloppes métalliques, non-déclenchement des DDR.'],
      ['Matières combustibles au voisinage', 'Stockage de cartons, bois ou solvants au contact immédiat de tableaux électriques.'],
      ['Non-conformité en zone ATEX / BE2', 'Matériels non antidéflagrants installés dans des locaux contenant des vapeurs inflammables.'],
    ];

    return [
      PdfReportStyles.sectionBox('9. TYPOLOGIE DES DANGERS LES PLUS COURANTS', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Paragraph(
        text: 'Les défaillances électriques génératrices de sinistres majeurs se concentrent principalement sur les 9 mécanismes typiques suivants :',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
      ),
      pw.SizedBox(height: 4),
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
              PdfReportStyles.cell('Nature du danger type', isHeader: true, centered: false),
              PdfReportStyles.cell('Mécanisme de génération du sinistre incendie / explosion', isHeader: true, centered: false),
            ],
          ),
          ...dangersTypes.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: idx.isOdd ? PdfReportStyles.tableRowAlt : PdfColors.white,
              ),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: pw.Text(
                    item[0],
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
                    item[1],
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 8.0,
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
}
