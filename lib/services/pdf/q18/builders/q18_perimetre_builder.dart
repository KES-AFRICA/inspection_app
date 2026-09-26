// lib/services/pdf/q18/builders/q18_perimetre_builder.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_snapshot.dart';

/// Builder responsable de la construction des Sections 5 et 6 du Rapport Q18 :
/// - Section 5 : Périmètre de la vérification et limites de la mission (5.1 & 5.2)
/// - Section 6 : Documents et éléments consultés
class Q18PerimetreBuilder {
  /// Section 5 : Périmètre de la vérification et limites de la mission
  static List<pw.Widget> buildSection5Perimetre(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
    Map<String, int>? trackedPages,
    int pageOffset = 2,
  }) {
    final couverts = data.perimetreCouverts;
    final exclusions = data.exclusionsPerimetre;

    final subTitle51 = PdfReportStyles.subTitle('5.1 Installations et locaux couverts par la présente vérification', fontBold: fontBold);
    final subTitle52 = PdfReportStyles.subTitle('5.2 Exclusions, parties non vérifiées et locaux inaccessibles', fontBold: fontBold);

    return [
      PdfReportStyles.sectionBox('5. PÉRIMÈTRE DE LA VÉRIFICATION ET LIMITES DE LA MISSION', fontBold: fontBold),
      pw.SizedBox(height: 6),
      trackedPages != null
          ? PageTracker(key: 'q18_s5_1', registry: trackedPages, offset: pageOffset, child: subTitle51)
          : subTitle51,
      pw.SizedBox(height: 4),

      pw.Paragraph(
        text: 'La vérification a porté sur les zones, locaux et équipements suivants :',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
      ),
      pw.SizedBox(height: 4),
      if (couverts.isEmpty)
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfReportStyles.tableRowAlt,
            border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Text(
            'Aucun équipement enregistré dans le périmètre.',
            style: pw.TextStyle(font: fontRegular, fontSize: 8.0, color: PdfColors.grey700),
          ),
        )
      else ...[
        () {
          final zoneGroups = <_Q18PerimetreZoneGroup>[];
          for (final item in couverts) {
            final normZone = item.zone.trim().isNotEmpty ? item.zone.trim() : 'Non précisée';
            final normRep = item.repere.trim().isNotEmpty ? item.repere.trim() : '-';

            var zGroup = zoneGroups.firstWhere(
              (zg) => zg.zone.toLowerCase() == normZone.toLowerCase(),
              orElse: () {
                final zg = _Q18PerimetreZoneGroup(zone: normZone, repereGroups: []);
                zoneGroups.add(zg);
                return zg;
              },
            );

            var rGroup = zGroup.repereGroups.firstWhere(
              (rg) => rg.repere.toLowerCase() == normRep.toLowerCase(),
              orElse: () {
                final rg = _Q18PerimetreRepereGroup(repere: normRep, items: []);
                zGroup.repereGroups.add(rg);
                return rg;
              },
            );

            rGroup.items.add(item);
          }

          final allTableRows = <pw.TableRow>[];

          allTableRows.add(
            pw.TableRow(
              repeat: true,
              decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
              children: [
                PdfReportStyles.cell('Zone', isHeader: true, centered: true),
                PdfReportStyles.cell('Repère', isHeader: true, centered: true),
                PdfReportStyles.cell('Désignation', isHeader: true, centered: true),
                PdfReportStyles.cell('Couvert par la mission', isHeader: true, centered: true),
              ],
            ),
          );

          int globalRowIndex = 0;

          for (final zoneGroup in zoneGroups) {
            final totalZoneItems =
                zoneGroup.repereGroups.fold<int>(0, (sum, g) => sum + g.items.length);

            int zoneItemIndex = 0;

            for (int rIdx = 0; rIdx < zoneGroup.repereGroups.length; rIdx++) {
              final repereGroup = zoneGroup.repereGroups[rIdx];
              final repereCount = repereGroup.items.length;

              for (int i = 0; i < repereCount; i++) {
                final item = repereGroup.items[i];
                final currentZoneItemIdx = zoneItemIndex++;
                final currentRepereItemIdx = i;

                final idx = globalRowIndex++;
                final isEven = idx % 2 == 0;
                final bg = isEven ? PdfColors.white : PdfColor.fromInt(0xFFF9FAFB);

                final isStartOfZone = (currentZoneItemIdx == 0 && idx > 0);
                final isStartOfRepere = (currentRepereItemIdx == 0 && currentZoneItemIdx > 0);

                final isEndOfZone = (currentZoneItemIdx == totalZoneItems - 1);
                final isEndOfRepere = (currentRepereItemIdx == repereCount - 1);

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

                final itemBorder = pw.Border(
                  top: isStartOfZone
                      ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                      : (isStartOfRepere
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                          : pw.BorderSide.none),
                  bottom: isEndOfZone
                      ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                      : (isEndOfRepere
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                          : const pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.4)),
                );

                allTableRows.add(
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      // Cellule 0 : Zone
                      PdfReportStyles.buildGroupedCellWidget(
                        currentIndex: currentZoneItemIdx,
                        totalRows: totalZoneItems,
                        text: zoneGroup.zone,
                        style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                        border: zoneBorder,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      ),

                      // Cellule 1 : Repère
                      PdfReportStyles.buildGroupedCellWidget(
                        currentIndex: currentRepereItemIdx,
                        totalRows: repereCount,
                        text: repereGroup.repere,
                        style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                        border: repereBorder,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      ),

                      // Cellule 2 : Équipements
                      pw.Container(
                        decoration: pw.BoxDecoration(
                          color: bg,
                          border: itemBorder,
                        ),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Text(
                          item.equipements.isNotEmpty ? item.equipements : '-',
                          style: pw.TextStyle(font: fontRegular, fontSize: 8.0, color: PdfColors.black),
                        ),
                      ),

                      // Cellule 3 : Couvert par la mission (coloration sur toute la case)
                      pw.Container(
                        decoration: pw.BoxDecoration(
                          color: item.isCouvert
                              ? PdfReportStyles.conformeColor
                              : PdfReportStyles.nonConformeColor,
                          border: itemBorder,
                        ),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          item.isCouvert ? 'Oui' : 'Non',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8.0,
                            color: PdfColors.black,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }
            }
          }

          return pw.Table(
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
              0: pw.FlexColumnWidth(2.6),
              1: pw.FlexColumnWidth(2.6),
              2: pw.FlexColumnWidth(3.4),
              3: pw.FlexColumnWidth(1.4),
            },
            children: allTableRows,
          );
        }(),
      ],
      pw.SizedBox(height: 10),
      trackedPages != null
          ? PageTracker(key: 'q18_s5_2', registry: trackedPages, offset: pageOffset, child: subTitle52)
          : subTitle52,
      pw.SizedBox(height: 4),

      pw.Paragraph(
        text: 'Exclusions éventuelles du périmètre (locaux non visités, installations non accessibles, parties d\'installation exclues contractuellement) :',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
      ),
      pw.SizedBox(height: 4),
      if (exclusions.isEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 4, top: 2),
          child: pw.Text(
            '- Sans Objet',
            style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
          ),
        )
      else
        pw.Table(
          border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.6),
            1: pw.FlexColumnWidth(2.6),
            2: pw.FlexColumnWidth(2.8),
            3: pw.FlexColumnWidth(2.0),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFC00000)),
              children: [
                PdfReportStyles.cell('Zone', isHeader: true, centered: true),
                PdfReportStyles.cell('Repère', isHeader: true, centered: true),
                PdfReportStyles.cell('Équipements non vérifiés', isHeader: true, centered: true),
                PdfReportStyles.cell('Motif d\'inaccessibilité', isHeader: true, centered: true),
              ],
            ),
            ...exclusions.asMap().entries.map((entry) {
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
                      item.zone,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8.0,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: pw.Text(
                      item.repere,
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8.0,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: pw.Text(
                      item.equipements,
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8.0,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: pw.Text(
                      item.motifExclusion.isNotEmpty ? item.motifExclusion : 'Inaccessible lors de la visite',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8.0,
                        color: PdfColors.red900,
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

  /// Section 6 : Documents et éléments consultés
  static List<pw.Widget> buildSection6DocumentsConsultes(
    Q18DataSnapshot data, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final docs = data.documentsConsultes;

    return [
      PdfReportStyles.sectionBox('6. DOCUMENTS ET ÉLÉMENTS CONSULTÉS', fontBold: fontBold),
      pw.SizedBox(height: 6),
      pw.Paragraph(
        text: 'La vérification s\'est appuyée, lorsqu\'ils étaient disponibles, sur les documents suivants transmis par l\'exploitant :',
        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
      ),
      pw.SizedBox(height: 6),
      pw.Table(
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
        border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FixedColumnWidth(24),
          1: pw.FlexColumnWidth(7.2),
          2: pw.FlexColumnWidth(2.8),
        },
        children: [
          pw.TableRow(
            repeat: true,
            decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
            children: [
              PdfReportStyles.cell('N°', isHeader: true, centered: true),
              PdfReportStyles.cell('Document', isHeader: true, centered: true),
              PdfReportStyles.cell('Disponibilité sur site', isHeader: true, centered: true),
            ],
          ),
          ...docs.asMap().entries.map((entry) {
            final idx = entry.key;
            final doc = entry.value;
            final isDispo = doc.isDisponible;
            final hasCustom = doc.statutCustom != null && doc.statutCustom!.isNotEmpty;

            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: idx.isOdd ? PdfReportStyles.tableRowAlt : PdfColors.white,
              ),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    '${doc.index}',
                    style: pw.TextStyle(font: fontBold, fontSize: 8.0, color: PdfReportStyles.headerColor),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    doc.titre,
                    style: pw.TextStyle(font: fontRegular, fontSize: 8.0, color: PdfColors.black),
                  ),
                ),
                pw.Container(
                  color: hasCustom
                      ? const PdfColor.fromInt(0xFFF1F5F9)
                      : (isDispo
                          ? PdfReportStyles.conformeColor
                          : PdfReportStyles.nonConformeColor),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    hasCustom ? doc.statutCustom! : (isDispo ? 'Disponible' : 'Non'),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8.0,
                      color: hasCustom
                          ? const PdfColor.fromInt(0xFF475569)
                          : PdfColors.black,
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

class _Q18PerimetreRepereGroup {
  final String repere;
  final List<Q18PerimetreItem> items;
  _Q18PerimetreRepereGroup({required this.repere, required this.items});
}

class _Q18PerimetreZoneGroup {
  final String zone;
  final List<_Q18PerimetreRepereGroup> repereGroups;
  _Q18PerimetreZoneGroup({required this.zone, required this.repereGroups});
}
