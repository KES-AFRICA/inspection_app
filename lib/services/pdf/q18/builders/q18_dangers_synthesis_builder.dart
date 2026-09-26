// lib/services/pdf/q18/builders/q18_dangers_synthesis_builder.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_snapshot.dart';

/// Groupes hiérarchiques pour la Section 10 (Zone -> Repère -> Désignation -> Observations)
class _Q18DangerDesignationGroup {
  final String designation;
  final List<Q18DangerItem> items;
  _Q18DangerDesignationGroup({required this.designation, required this.items});
}

class _Q18DangerRepereGroup {
  final String repere;
  final List<_Q18DangerDesignationGroup> designationGroups;
  _Q18DangerRepereGroup({required this.repere, required this.designationGroups});
}

class _Q18DangerZoneGroup {
  final String zone;
  final List<_Q18DangerRepereGroup> repereGroups;
  _Q18DangerZoneGroup({required this.zone, required this.repereGroups});
}

/// Builder responsable de la construction des Sections 10 et 11 du Rapport Q18 :
/// - Section 10 : Synthèse des dangers constatés (regroupement hiérarchique 4-niveaux)
/// - Section 11 : Récapitulatif statistique (3 colonnes sans blocs colorés)
class Q18DangersSynthesisBuilder {
  /// Section 10 : Synthèse des dangers constatés
  static List<pw.Widget> buildSection10Dangers(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final dangers = data.dangers;

    if (dangers.isEmpty) {
      return [
        PdfReportStyles.sectionBox('10. SYNTHÈSE DES DANGERS CONSTATÉS', fontBold: fontBold),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfReportStyles.conformeColor,
            border: pw.TableBorder.all(color: PdfColors.green700, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 12,
                height: 12,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.green700,
                  shape: pw.BoxShape.circle,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'V',
                  style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  'NÉANT : Aucun danger ni anomalie relevant des risques d\'incendie et d\'explosion n\'a été constaté lors de la présente vérification.',
                  style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.green900),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
      ];
    }

    // Construction de la structure hiérarchique :
    // ZONE -> REPÈRE -> DÉSIGNATION -> OBSERVATIONS
    final zoneGroupsMap = <String, Map<String, Map<String, List<Q18DangerItem>>>>{};

    for (final item in dangers) {
      final rawZone = item.zone.trim();
      final zone = (rawZone == 'N/A' ||
              rawZone == 'Non renseigné' ||
              rawZone == 'Inconnu' ||
              rawZone == 'Sans zone' ||
              rawZone == '-')
          ? ''
          : rawZone;

      final rawRepere = item.repere.trim();
      final isRepereEmpty = rawRepere.isEmpty ||
          rawRepere == 'N/A' ||
          rawRepere == 'Sans local' ||
          rawRepere == 'Hors local' ||
          rawRepere == '-';
      final repere = !isRepereEmpty ? rawRepere : (zone.isNotEmpty ? zone : '');

      final rawDesig = item.designation.trim();
      final isDesigEmpty = rawDesig.isEmpty || rawDesig == 'N/A' || rawDesig == '-';
      final designation = !isDesigEmpty ? rawDesig : (repere.isNotEmpty ? repere : (zone.isNotEmpty ? zone : ''));

      zoneGroupsMap
          .putIfAbsent(zone, () => <String, Map<String, List<Q18DangerItem>>>{})
          .putIfAbsent(repere, () => <String, List<Q18DangerItem>>{})
          .putIfAbsent(designation, () => <Q18DangerItem>[])
          .add(item);
    }

    final zoneGroups = zoneGroupsMap.entries.map((zEntry) {
      final repereGroups = zEntry.value.entries.map((rEntry) {
        final desigGroups = rEntry.value.entries.map((dEntry) {
          return _Q18DangerDesignationGroup(
            designation: dEntry.key,
            items: dEntry.value,
          );
        }).toList();
        return _Q18DangerRepereGroup(
          repere: rEntry.key,
          designationGroups: desigGroups,
        );
      }).toList();
      return _Q18DangerZoneGroup(
        zone: zEntry.key,
        repereGroups: repereGroups,
      );
    }).toList();

    // Construction des lignes du tableau unifié (6 colonnes : Zone, Repère, Désignation, Danger constaté, Famille, Niveau)
    final allTableRows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
        children: [
          PdfReportStyles.cell('Zone', isHeader: true, centered: true, fontBold: fontBold),
          PdfReportStyles.cell('Repère', isHeader: true, centered: true, fontBold: fontBold),
          PdfReportStyles.cell('Désignation', isHeader: true, centered: true, fontBold: fontBold),
          PdfReportStyles.cell('Danger constaté / Observation', isHeader: true, centered: true, fontBold: fontBold),
          PdfReportStyles.cell('Famille de risque', isHeader: true, centered: true, fontBold: fontBold),
          PdfReportStyles.cell('Niveau D18', isHeader: true, centered: true, fontBold: fontBold),
        ],
      ),
    ];

    int globalRowIndex = 0;

    for (final zoneGroup in zoneGroups) {
      final totalZoneItems = zoneGroup.repereGroups.fold<int>(
        0,
        (sum, rg) => sum + rg.designationGroups.fold<int>(0, (s, dg) => s + dg.items.length),
      );
      int currentZoneItemIdx = 0;

      for (final repereGroup in zoneGroup.repereGroups) {
        final repereCount = repereGroup.designationGroups.fold<int>(
          0,
          (sum, dg) => sum + dg.items.length,
        );
        int currentRepereItemIdx = 0;

        for (final desigGroup in repereGroup.designationGroups) {
          final desigCount = desigGroup.items.length;

          for (int itemIdx = 0; itemIdx < desigGroup.items.length; itemIdx++) {
            final item = desigGroup.items[itemIdx];
            final idx = globalRowIndex;
            final isStartOfZone = (currentZoneItemIdx == 0 && idx > 0);
            final isEndOfZone = (currentZoneItemIdx == totalZoneItems - 1);
            final isStartOfRepere = (currentRepereItemIdx == 0 && currentZoneItemIdx > 0);
            final isEndOfRepere = (currentRepereItemIdx == repereCount - 1);
            final isStartOfDesig = (itemIdx == 0 && currentRepereItemIdx > 0);
            final isEndOfDesig = (itemIdx == desigCount - 1);

            final isAlt = globalRowIndex.isOdd;
            final rowBg = isAlt ? PdfReportStyles.tableRowAlt : PdfColors.white;

            final zoneBorder = pw.Border(
              top: isStartOfZone
                  ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                  : pw.BorderSide.none,
              bottom: isEndOfZone
                  ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                  : pw.BorderSide.none,
            );

            final repereBorder = pw.Border(
              top: isStartOfZone
                  ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                  : (isStartOfRepere
                      ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                      : pw.BorderSide.none),
              bottom: isEndOfZone
                  ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                  : (isEndOfRepere
                      ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                      : pw.BorderSide.none),
            );

            final desigBorder = pw.Border(
              top: isStartOfZone
                  ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                  : (isStartOfRepere
                      ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                      : (isStartOfDesig
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF64748B), width: 0.6)
                          : pw.BorderSide.none)),
              bottom: isEndOfZone
                  ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                  : (isEndOfRepere
                      ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                      : (isEndOfDesig
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF64748B), width: 0.6)
                          : pw.BorderSide.none)),
            );

            final itemBorder = pw.Border(
              top: isStartOfZone
                  ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                  : (isStartOfRepere
                      ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                      : (isStartOfDesig
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF64748B), width: 0.6)
                          : pw.BorderSide.none)),
              bottom: isEndOfZone
                  ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                  : (isEndOfRepere
                      ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                      : (isEndOfDesig
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF64748B), width: 0.6)
                          : const pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.4))),
            );

            final badgeColors = _getBadgeColors(item.niveau);

            allTableRows.add(
              pw.TableRow(
                decoration: pw.BoxDecoration(color: rowBg),
                children: [
                  // Cellule 0 : Zone (Groupée sans coupure interne)
                  PdfReportStyles.buildGroupedCellWidget(
                    currentIndex: currentZoneItemIdx,
                    totalRows: totalZoneItems,
                    text: zoneGroup.zone,
                    style: pw.TextStyle(font: fontBold, fontSize: 8.0, color: PdfColors.black),
                    border: zoneBorder,
                    decorationColor: PdfColors.white,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  ),

                  // Cellule 1 : Repère (Groupé sans coupure interne)
                  PdfReportStyles.buildGroupedCellWidget(
                    currentIndex: currentRepereItemIdx,
                    totalRows: repereCount,
                    text: repereGroup.repere,
                    style: pw.TextStyle(font: fontBold, fontSize: 8.0, color: PdfColors.black),
                    border: repereBorder,
                    decorationColor: PdfColors.white,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  ),

                  // Cellule 2 : Désignation (Groupée sans coupure interne)
                  PdfReportStyles.buildGroupedCellWidget(
                    currentIndex: itemIdx,
                    totalRows: desigCount,
                    text: desigGroup.designation,
                    style: pw.TextStyle(font: fontBold, fontSize: 8.0, color: PdfReportStyles.headerColor),
                    border: desigBorder,
                    decorationColor: PdfColors.white,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  ),

                  // Cellule 3 : Danger constaté / Observation
                  pw.Container(
                    decoration: pw.BoxDecoration(color: rowBg, border: itemBorder),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      item.dangerConstate,
                      style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.black),
                    ),
                  ),

                  // Cellule 4 : Famille de risque
                  pw.Container(
                    decoration: pw.BoxDecoration(color: rowBg, border: itemBorder),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      item.familleDeRisque,
                      style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfReportStyles.darkGrey),
                    ),
                  ),

                  // Cellule 5 : Niveau D18 (Badge)
                  pw.Container(
                    decoration: pw.BoxDecoration(color: rowBg, border: itemBorder),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: badgeColors.bg,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                        border: pw.Border.all(color: badgeColors.border, width: 0.3),
                      ),
                      child: pw.Text(
                        item.niveau.label,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 6.8,
                          color: badgeColors.text,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );

            currentZoneItemIdx++;
            currentRepereItemIdx++;
            globalRowIndex++;
          }
        }
      }
    }

    return [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PdfReportStyles.sectionBox('10. SYNTHÈSE DES DANGERS CONSTATÉS', fontBold: fontBold),
          pw.SizedBox(height: 6),
          pw.Paragraph(
            text: 'Les dangers identifiés lors de la vérification sont répertoriés dans le tableau ci-dessous, avec leur localisation, une description et le niveau de gravité retenu, ainsi que l\'action corrective recommandée :',
            style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
          ),
          pw.SizedBox(height: 6),
        ],
      ),
      pw.Table(
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
        border: const pw.TableBorder(
          left: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
          right: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
          top: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
          verticalInside: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
          horizontalInside: pw.BorderSide.none,
        ),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.8), // Zone
          1: pw.FlexColumnWidth(1.8), // Repère
          2: pw.FlexColumnWidth(2.0), // Désignation
          3: pw.FlexColumnWidth(4.2), // Danger constaté / Observation
          4: pw.FlexColumnWidth(2.0), // Famille de risque
          5: pw.FlexColumnWidth(1.6), // Niveau D18
        },
        children: allTableRows,
      ),
      pw.SizedBox(height: 12),
    ];
  }

  /// Section 11 : Récapitulatif statistique des dangers
  ///
  /// Structure exacte conforme au référentiel Q18 :
  /// 3 colonnes : Niveau de danger | Nombre constaté | Dont levés depuis le rapport précédent
  /// Blocs de couleur supprimés dans la colonne 1 (texte sobre).
  /// Colonne 3 laissée vide sans invention de données.
  /// Règle 26 : Titre, intro et tableau groupés dans un même bloc logique Column.
  static List<pw.Widget> buildSection11Statistiques(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final total = data.dangers.length;

    final statsRows = [
      ['Danger avéré', '${data.countDangerAvere}'],
      ['Dégradation', '${data.countDegradation}'],
      ['Non-conformité hors périmètre APSAD', '${data.countHorsPerimetre}'],
      ['Point sensible / observation', '${data.countPointSensible}'],
    ];

    return [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PdfReportStyles.sectionBox('11. RÉCAPITULATIF STATISTIQUE DES DANGERS', fontBold: fontBold),
          pw.SizedBox(height: 6),
          pw.Paragraph(
            text: 'Ce tableau offre une vue d\'ensemble du nombre de dangers constatés par niveau, à des fins de suivi dans le temps :',
            style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
            border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
            columnWidths: const {
              0: pw.FlexColumnWidth(4.5),
              1: pw.FlexColumnWidth(2.5),
              2: pw.FlexColumnWidth(3.0),
            },
            children: [
              pw.TableRow(
                repeat: true,
                decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
                children: [
                  PdfReportStyles.cell('Niveau de danger', isHeader: true, centered: true, fontBold: fontBold),
                  PdfReportStyles.cell('Nombre constaté', isHeader: true, centered: true, fontBold: fontBold),
                  PdfReportStyles.cell('Levés depuis le rapport précédent', isHeader: true, centered: true, fontBold: fontBold),
                ],
              ),
              ...statsRows.asMap().entries.map((entry) {
                final idx = entry.key;
                final label = entry.value[0];
                final count = entry.value[1];
                final isAlt = idx.isOdd;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isAlt ? PdfReportStyles.tableRowAlt : PdfColors.white,
                  ),
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Text(
                        label,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 8.0,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        count,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 8.5,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      alignment: pw.Alignment.center,
                      child: pw.SizedBox(),
                    ),
                  ],
                );
              }),
              // Ligne Total
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      'Total',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8.5,
                        color: PdfReportStyles.headerColor,
                      ),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      '$total',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 9.0,
                        color: PdfReportStyles.headerColor,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    alignment: pw.Alignment.center,
                    child: pw.SizedBox(),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
        ],
      ),
    ];
  }

  static ({PdfColor bg, PdfColor text, PdfColor border}) _getBadgeColors(Q18DangerLevel level) {
    switch (level) {
      case Q18DangerLevel.dangerAvere:
        return (
          bg: PdfColor.fromInt(0xFFFFEBEE),
          text: PdfColor.fromInt(0xFFC00000),
          border: PdfColor.fromInt(0xFFEF9A9A),
        );
      case Q18DangerLevel.degradation:
        return (
          bg: PdfColor.fromInt(0xFFFFF3E0),
          text: PdfColor.fromInt(0xFFE65100),
          border: PdfColor.fromInt(0xFFFFCC80),
        );
      case Q18DangerLevel.horsPerimetreApsad:
        return (
          bg: PdfColor.fromInt(0xFFE8F5E9),
          text: PdfColor.fromInt(0xFF2E7D32),
          border: PdfColor.fromInt(0xFFA5D6A7),
        );
      case Q18DangerLevel.pointSensible:
        return (
          bg: PdfColor.fromInt(0xFFE3F2FD),
          text: PdfColor.fromInt(0xFF1565C0),
          border: PdfColor.fromInt(0xFF90CAF9),
        );
    }
  }
}
