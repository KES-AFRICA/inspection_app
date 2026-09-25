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
  /// Section 2 : Objet et cadre de la mission (2 paragraphes stricts de référence)
  static List<pw.Widget> buildSection2ObjetCadre({
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return [
      PdfReportStyles.sectionBox('2. OBJET ET CADRE DE LA MISSION', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Paragraph(
        text: 'Le présent rapport constitue le compte rendu de la mission de vérification périodique Q18 réalisée conformément au référentiel APSAD D18. Cette mission a pour objectif d\'identifier les dangers d\'incendie ou d\'explosion susceptibles d\'être liés à l\'installation électrique du site, en complément des vérifications réglementaires en vigueur.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black, lineSpacing: 1.2),
      ),
      pw.SizedBox(height: 2),
      pw.Paragraph(
        text: 'Cette vérification ne se substitue pas aux vérifications réglementaires obligatoires ni aux contrôles requis par d\'autres réglementations applicables (sécurité incendie ERP/ICPE, etc.). Elle constitue une démarche complémentaire de prévention destinée notamment à l\'information de l\'assureur du site.',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black, lineSpacing: 1.2),
      ),
      pw.SizedBox(height: 14),
    ];
  }

  /// Section 3 : Cadre réglementaire et normatif (8 textes de référence)
  static List<pw.Widget> buildSection3CadreReglementaire({
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final textes = [
      'Référentiel APSAD D18 (CNPP) — prévention des risques d\'incendie et d\'explosion',
      'Articles 6, 112, 113 - Arrêté 039/MTPS/IMT du 26 novembre 1984 fixant les mesures générales d\'hygiène et de sécurité sur les lieux de travail',
      'Cahier de prescription technique applicable au Décret N° 20181969/PM du 15 mars 2018, fixant les règles de base de sécurité incendie dans les bâtiments',
      'Arrêté conjoint 002164 du 21 juin 2012 MNIMIDT/MINEE',
      'Loi N° 896/PJL/AN du 15/11/2011',
      'NC 244 C 15 100 - Installation électrique à basse tension',
      'NF C 15 100 - Installation électrique à basse tension',
      'Norme NF C 13 100 - Poste de livraison établi à l\'intérieur d\'un bâtiment et alimenté par un réseau de distribution publique de deuxième catégorie',
    ];

    return [
      PdfReportStyles.sectionBox('3. CADRE RÉGLEMENTAIRE ET NORMATIF', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Paragraph(
        text: 'La mission s\'inscrit, sans s\'y substituer, dans le prolongement des textes et normes suivants, à rappeler ou compléter selon le contexte du site :',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
      ),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FixedColumnWidth(24),
          1: pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              PdfReportStyles.cell('N°', isHeader: true, centered: true),
              PdfReportStyles.cell('Textes réglementaires et normes applicables', isHeader: true, centered: true),
            ],
          ),
          ...textes.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;
            final isAlt = idx.isOdd;
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: isAlt ? PdfReportStyles.tableRowAlt : PdfColors.white,
              ),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    '${idx + 1}',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8.0,
                      color: PdfReportStyles.headerColor,
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(
                    text,
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
      pw.SizedBox(height: 14),
    ];
  }

  /// Section 7 : Méthodologie et points de contrôle (Tableau 9 éléments de référence)
  static List<pw.Widget> buildSection7Methodologie({
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final methodologieRows = [
      [
        'Tableaux électriques (TGBT, armoires, coffret, inverseur)',
        'État général, propreté, encombrement, repérage des circuits, accessibilité, échauffements anormaux',
      ],
      [
        'Dispositifs de protection',
        'Présence et calibrage des disjoncteurs et fusibles, fonctionnement des différentiels, sélectivité',
      ],
      [
        'Continuité des mises à la terre et liaisons équipotentielles',
        'Vérification de la continuité, état des connexions, résistance de terre',
      ],
      [
        'État des conducteurs et raccordements',
        'Absence d\'échauffement, de desserrage, d\'oxydation, de dénudage ou de surcharge apparente',
      ],
      [
        'Contrôle thermographique (le cas échéant)',
        'Détection des points chauds sur tableaux et connexions sous tension par caméra infrarouge',
      ],
      [
        'Environnement des installations',
        'Présence de poussières, d\'humidité, de produits inflammables ou corrosifs à proximité des équipements électriques',
      ],
      [
        'Zones à risque particulier / ATEX',
        'Adéquation du matériel installé (indices IP/IK, matériel ATEX) avec le classement de la zone',
      ],
      [
        'Éclairage de sécurité et signalisation',
        'Présence et bon fonctionnement des blocs autonomes, accessibilité des tableaux',
      ],
      [
        'Documentation associée',
        'Disponibilité des schémas électriques, du carnet de bord, des rapports de vérifications réglementaires antérieures',
      ],
    ];

    return [
      PdfReportStyles.sectionBox('7. MÉTHODOLOGIE ET POINTS DE CONTRÔLE', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Paragraph(
        text: 'La vérification a été réalisée par examen visuel des installations, complété le cas échéant par des mesures et un contrôle thermographique, portant notamment sur les points suivants :',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
      ),
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
              PdfReportStyles.cell('Éléments à vérifier', isHeader: true, centered: true),
              PdfReportStyles.cell('Point de contrôle', isHeader: true, centered: true),
            ],
          ),
          ...methodologieRows.asMap().entries.map((entry) {
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
                      fontSize: 8.0,
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
      pw.SizedBox(height: 14),
    ];
  }

  /// Section 8 : Échelle de classification des dangers (Tableau 4 niveaux de référence)
  static List<pw.Widget> buildSection8ClassificationDangers({
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final echelles = [
      [
        'Danger avéré (Critique)',
        'Anomalie présentant un risque direct et significatif d\'incendie ou d\'explosion (échauffement anormal constaté, protection différentielle absente ou hors service, conducteur dénudé sous tension, etc.)',
        'Action corrective immédiate ou à très court terme (délai à préciser par le vérificateur)',
        PdfColor.fromInt(0xFFC00000), // Rouge
      ],
      [
        'Dégradation (Majeure)',
        'Anomalie ou état de vieillissement constaté ne présentant pas de danger immédiat, mais susceptible d\'évoluer vers un danger avéré en l\'absence de correction',
        'Action corrective à programmer à moyen terme, à surveiller lors de la prochaine visite',
        PdfColor.fromInt(0xFFED7D31), // Orange
      ],
      [
        'Non-conformité hors périmètre APSAD',
        'Écart constaté par rapport à une exigence réglementaire / normative mais ne relevant pas directement du risque incendie/explosion visé par le D18',
        'Signalé pour information ; relève des vérifications réglementaires périodiques',
        PdfColor.fromInt(0xFF70AD47), // Vert
      ],
      [
        'Point sensible / observation',
        'Élément non classé comme danger mais méritant une vigilance particulière ou une bonne pratique à renforcer',
        'Recommandation, sans obligation de levée',
        PdfColor.fromInt(0xFF41719C), // Bleu
      ],
    ];

    return [
      PdfReportStyles.sectionBox('8. ÉCHELLE DE CLASSIFICATION DES DANGERS', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Paragraph(
        text: 'Chaque anomalie constatée est classée selon l\'échelle suivante, qui détermine le traitement attendu :',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
      ),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(2.6),
          1: pw.FlexColumnWidth(4.4),
          2: pw.FlexColumnWidth(3.0),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              PdfReportStyles.cell('Niveau', isHeader: true, centered: true),
              PdfReportStyles.cell('Critères de qualification', isHeader: true, centered: true),
              PdfReportStyles.cell('Traitement attendu', isHeader: true, centered: true),
            ],
          ),
          ...echelles.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final label = item[0] as String;
            final critere = item[1] as String;
            final traitement = item[2] as String;
            final color = item[3] as PdfColor;
            final isAlt = idx.isOdd;

            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: isAlt ? PdfReportStyles.tableRowAlt : PdfColors.white,
              ),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 7,
                        height: 7,
                        margin: const pw.EdgeInsets.only(top: 2, right: 4),
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
                            fontSize: 7.8,
                            color: PdfReportStyles.headerColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: pw.Text(
                    critere,
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 7.5,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: pw.Text(
                    traitement,
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 7.5,
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

  /// Section 9 : Typologie des dangers les plus courants (Tableau 9 dangers types)
  static List<pw.Widget> buildSection9TypologieDangers({
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final dangersTypes = [
      [
        'Échauffement anormal',
        'Point chaud détecté visuellement ou par thermographie sur un tableau, une connexion ou un câble',
        'Danger avéré (en général)',
      ],
      [
        'Protection différentielle absente ou défaillante',
        'Absence de dispositif différentiel adapté, ou déclenchement lors du test manuel non conforme',
        'Danger avéré',
      ],
      [
        'Conducteurs endommagés ou dénudés',
        'Gaine détériorée, conducteur apparent, épissures non protégées',
        'Danger avéré',
      ],
      [
        'Connexions desserrées ou oxydées',
        'Bornes non serrées, oxydation visible sur les connexions de puissance',
        'Dégradation à Danger avéré selon gravité',
      ],
      [
        'Encombrement des tableaux électriques',
        'Stockage de matériel combustible à proximité ou devant les tableaux, accès entravé',
        'Dégradation',
      ],
      [
        'Matériel non adapté à la zone (IP/IK/ATEX) à l’environnement',
        'Présence de poussières, d\'humidité ou de produits inflammables au contact d\'équipements non prévus pour cet usage (indice IP insuffisant)',
        'Danger avéré ou Dégradation selon exposition',
      ],
      [
        'Absence ou insuffisance de repérage',
        'Circuits, disjoncteurs ou câbles non identifiés, schémas absents ou obsolètes',
        'Point sensible / observation',
      ],
      [
        'Défaut de mise à la terre / liaison équipotentielle',
        'Continuité de terre non assurée, liaison manquante',
        'Danger avéré',
      ],
      [
        'Surcharge de circuit apparente',
        'Section de câble a priori insuffisante au regard des équipements raccordés, multiprises en cascade',
        'Dégradation à Danger avéré selon gravité',
      ],
    ];

    return [
      PdfReportStyles.sectionBox('9. TYPOLOGIE DES DANGERS LES PLUS COURANTS', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Paragraph(
        text: 'À titre de repère pour la rédaction du rapport, le tableau ci-dessous recense les types de dangers les plus fréquemment rencontrés lors des missions Q18 et leur niveau de classement habituel (à ajuster au cas par cas selon le contexte réel) :',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
      ),
      pw.SizedBox(height: 6),
      pw.Table(
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(2.8),
          1: pw.FlexColumnWidth(4.8),
          2: pw.FlexColumnWidth(2.4),
        },
        children: [
          pw.TableRow(
            repeat: true,
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              PdfReportStyles.cell('Type de danger', isHeader: true, centered: true, fontBold: fontBold),
              PdfReportStyles.cell('Description type', isHeader: true, centered: true, fontBold: fontBold),
              PdfReportStyles.cell('Niveau habituel', isHeader: true, centered: true, fontBold: fontBold),
            ],
          ),
          ...dangersTypes.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isAlt = idx.isOdd;
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: isAlt ? PdfReportStyles.tableRowAlt : PdfColors.white,
              ),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: pw.Text(
                    item[0],
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 7.8,
                      color: PdfReportStyles.headerColor,
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: pw.Text(
                    item[1],
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 7.5,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    item[2],
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 7.5,
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
