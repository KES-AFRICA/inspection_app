import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

/// Builder responsable des tableaux réglementaires : normes, matériels et périmètre de la mission
class PdfRegulatoryBuilder {
  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();

  static pw.Widget buildNormesTable({pw.Font? fontBold, pw.Font? fontRegular}) {
    final normes = [
      [
        'Loi n° 2011/022 du 14 décembre 2011',
        'Loi régissant le secteur de l’électricité au Cameroun. Le numéro de projet adopté par l’Assemblée nationale était n° 896/PJL/AN le 15 novembre 2011.',
      ],
      [
        'Arrêté conjoint n° 002164/MINIMDT/MINEE du 20 juin 2012',
        'Arrêté conjoint rendant d’application obligatoire la norme camerounaise NC 244 C 15 100 relative aux installations électriques à basse tension.',
      ],
      [
        'NC 244 C 15 100 : 2011-08',
        'Installations électriques à basse tension – norme camerounaise rendue d’application obligatoire par l’arrêté conjoint n° 002164/MINIMDT/MINEE.',
      ],
      [
        'NF C 15-100',
        'Installations électriques à basse tension – Règles.',
      ],
      [
        'NF C 13-100',
        'Postes de livraison alimentés par un réseau public de distribution HTA (jusqu’à 33 kV), notamment pour les postes de livraison établis à l’intérieur d’un bâtiment.',
      ],
      [
        'Décret n° 2018/1969/PM du 15 mars 2018',
        'Décret fixant les règles de base de sécurité incendie dans les bâtiments.',
      ],
      [
        'Arrêté n° 039/MTPS/IMT du 26 novembre 1984',
        'Arrêté fixant les mesures générales d’hygiène et de sécurité sur les lieux de travail.',
      ],
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.0),
        1: pw.FlexColumnWidth(6.0),
      },
      children: [
        PdfReportStyles.tableHeaderRow(['Référence', 'Libellé'], fontBold: fontBold),
        ...normes.asMap().entries.map(
          (e) => PdfReportStyles.tableDataRow(e.value, alt: e.key.isOdd, fontRegular: fontRegular),
        ),
      ],
    );
  }

  static pw.Widget buildMaterielTable({pw.Font? fontBold, pw.Font? fontRegular}) {
    final materiel = [
      ['Mesure de la résistance de prises de terre', 'FLUKE – 1630 2 FC'],
      ['Mesure de l\'isolement', 'CHAUVIN ARNOUX CA 6462'],
      [
        'Vérification de la continuité et de la résistance des conducteurs de protection et des liaisons équipotentielles',
        'CHAUVIN ARNOUX CA 6462',
      ],
      [
        'Test de déclenchement des dispositifs différentiels et mesure des impédances de boucle',
        'CHAUVIN ARNOUX CA 6462',
      ],
      ['Contrôleur d\'installation électrique', 'CHAUVIN ARNOUX CA 6116N'],
      ['Analyseur de réseaux', 'CHAUVIN ARNOUX PEL 103 140631NFH'],
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(6.0),
        1: pw.FlexColumnWidth(4.0),
      },
      children: [
        PdfReportStyles.tableHeaderRow(['Description', 'Appareil / Référence']),
        ...materiel.asMap().entries.map((e) {
          final isOdd = e.key.isOdd;
          return pw.TableRow(
            decoration: isOdd ? pw.BoxDecoration(color: PdfReportStyles.tableRowAlt) : null,
            children: [
              PdfReportStyles.cell(e.value[0], isHeader: false, centered: false),
              PdfReportStyles.cell(e.value[1], isHeader: false, centered: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget buildPerimetreTable(
    Mission mission,
    RenseignementsGeneraux? rg, {
    pw.Font? fontBold,
    pw.Font? fontRegular,
  }) {
    // 1. Périmètre normalisé
    final rawPerimetres =
        (mission.perimetreMission != null &&
            mission.perimetreMission!.isNotEmpty)
        ? mission.perimetreMission!
        : <String>['Vérification électrique'];

    const mapping = {
      'Vérification thermographique': 'Vérification thermographie infrarouge',
      'Vérification des prises de terre': 'Cartographie des prises de terre',
    };

    final perimetres = <String>[];
    for (final item in rawPerimetres) {
      final normalized = mapping[item] ?? item;
      if (!perimetres.contains(normalized)) {
        perimetres.add(normalized);
      }
    }
    if (perimetres.isEmpty) {
      perimetres.add('Vérification électrique');
    }

    // 2. Préparation des dates et de la durée
    final dateDebut = rg?.dateDebut ?? mission.dateIntervention;
    final dateFin = rg?.dateFin;
    String dateInterventionStr;
    if (dateDebut != null &&
        dateFin != null &&
        !dateDebut.isAtSameMomentAs(dateFin)) {
      dateInterventionStr =
          'Du ${PdfReportStyles.formatDate(dateDebut)} au ${PdfReportStyles.formatDate(dateFin)}';
    } else if (dateDebut != null) {
      dateInterventionStr = PdfReportStyles.formatDate(dateDebut);
    } else {
      dateInterventionStr = PdfReportStyles.formatDate(DateTime.now());
    }

    int dureeJours = 1;
    if (rg != null && rg.dureeJours > 0) {
      dureeJours = rg.dureeJours;
    } else if (dateDebut != null && dateFin != null) {
      dureeJours = dateFin.difference(dateDebut).inDays + 1;
      if (dureeJours < 1) dureeJours = 1;
    }

    // 3. Accompagnateurs
    String accompagnateursStr = '';
    if (mission.accompagnateurs != null &&
        mission.accompagnateurs!.isNotEmpty) {
      accompagnateursStr = mission.accompagnateurs!.join(', ');
    } else if (rg != null && rg.accompagnateurs.isNotEmpty) {
      accompagnateursStr = rg.accompagnateurs
          .map((a) => '${a['prenom'] ?? ''} ${a['nom'] ?? ''}'.trim())
          .where((s) => s.isNotEmpty)
          .join(', ');
    } else {
      accompagnateursStr = 'Non spécifié';
    }

    // 4. Compte rendu fait à
    String compteRenduStr = accompagnateursStr;
    if (rg != null && rg.compteRendu.isNotEmpty) {
      compteRenduStr = rg.compteRendu.join(', ');
    }

    // 5. Vérificateurs
    List<String> verificateursList = [];
    if (mission.verificateurs != null && mission.verificateurs!.isNotEmpty) {
      verificateursList = mission.verificateurs!
          .map(
            (v) =>
                '${v['prenom'] ?? ''} ${v['nom'] ?? ''}'.trim().toUpperCase(),
          )
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (rg != null && rg.verificateurs.isNotEmpty) {
      verificateursList = rg.verificateurs
          .map(
            (v) =>
                '${v['prenom'] ?? ''} ${v['nom'] ?? ''}'.trim().toUpperCase(),
          )
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (verificateursList.isEmpty) {
      verificateursList = ['Non spécifié'];
    }

    // Bordures sombres (#475569 slate dark, épaisseur 0.8 pt) pour une visibilité parfaite
    final gridColor = PdfColor.fromHex('#475569');
    const double borderWidth = 0.8;
    const double leftColWidth = 175.0;

    final labelStyle = pw.TextStyle(
      font: fontBold,
      fontSize: 9.5,
      fontWeight: pw.FontWeight.bold,
      color: PdfReportStyles.headerColor,
    );
    final valueStyle = pw.TextStyle(
      font: fontBold,
      fontSize: 9.5,
      fontWeight: pw.FontWeight.bold,
      color: PdfReportStyles.headerColor,
    );

    pw.TableRow buildTableRow(
      String label,
      pw.Widget contentWidget, {
      required bool isOdd,
    }) {
      final bg = isOdd ? PdfColor.fromHex('#F8FAFC') : PdfColors.white;
      return pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: pw.Text(label, style: labelStyle),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: contentWidget,
          ),
        ],
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: gridColor, width: borderWidth),
      columnWidths: const {
        0: pw.FixedColumnWidth(leftColWidth),
        1: pw.FlexColumnWidth(),
      },
      children: [
        // ── PARTIE A: MISSIONS (PÉRIMÈTRE - CELLULE UNIQUE À GAUCHE) ──
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 8,
              ),
              child: pw.Text('Missions', style: labelStyle),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: perimetres.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isLast = idx == perimetres.length - 1;
                final isOdd = idx.isOdd;
                final bg = isOdd
                    ? PdfColor.fromHex('#F8FAFC')
                    : PdfColors.white;

                return pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: bg,
                    border: isLast
                        ? null
                        : pw.Border(
                            bottom: pw.BorderSide(
                              color: gridColor,
                              width: borderWidth,
                            ),
                          ),
                  ),
                  child: pw.Text(item, style: valueStyle),
                );
              }).toList(),
            ),
          ],
        ),

        // ── PARTIE B: INFORMATIONS GÉNÉRALES ──
        buildTableRow(
          'Nature',
          pw.Text(
            mission.natureMission ?? 'Périodique réglementaire',
            style: valueStyle,
          ),
          isOdd: false,
        ),
        buildTableRow(
          'Dates d\'intervention',
          pw.Text(dateInterventionStr, style: valueStyle),
          isOdd: true,
        ),
        buildTableRow(
          'Durée',
          pw.Text('$dureeJours jour(s)', style: valueStyle),
          isOdd: false,
        ),
        buildTableRow(
          'Accompagnateur / Responsable',
          pw.Text(accompagnateursStr, style: valueStyle),
          isOdd: true,
        ),
        buildTableRow(
          'Compte rendu de fin de visite fait à',
          pw.Text(compteRenduStr, style: valueStyle),
          isOdd: false,
        ),
        buildTableRow(
          'Vérificateur(s)',
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: verificateursList
                .map((v) => pw.Text(v, style: valueStyle))
                .toList(),
          ),
          isOdd: true,
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  ANALYSE STATISTIQUE
  // ──────────────────────────────────────────────────────────────


}
