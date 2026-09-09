import 'package:inspec_app/services/hive_service.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/services/dispositions_constructives_registry.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

class PdfParafoudreEquipementRow {
  final String zoneName;
  final String localName;
  final String equipementName;
  final String repere;
  final String pointVerification;
  final String referenceNormative;
  final String criticite;
  final String observation;
  final List<String> photoPaths;
  final String identityKey;

  PdfParafoudreEquipementRow({
    this.zoneName = '',
    this.localName = '',
    this.equipementName = '',
    required this.repere,
    this.pointVerification = '-',
    this.referenceNormative = '-',
    this.criticite = '-',
    required this.observation,
    List<String>? photoPaths,
    required this.identityKey,
  }) : photoPaths = photoPaths ?? [];
}

class PdfFoudreZoneGroup {
  final String zoneName;
  final List<PdfFoudreLocalGroup> localGroups;
  PdfFoudreZoneGroup({required this.zoneName, required this.localGroups});
}

class PdfFoudreLocalGroup {
  final String localName;
  final List<PdfFoudreEquipGroup> equipGroups;
  PdfFoudreLocalGroup({required this.localName, required this.equipGroups});
}

class PdfFoudreEquipGroup {
  final String equipementName;
  final List<PdfParafoudreEquipementRow> items;
  PdfFoudreEquipGroup({required this.equipementName, required this.items});
}



class PdfClassementRow {
  final String localisation;
  final String zone;
  final String type;
  final String origineClassement;
  final String? af;
  final String? be;
  final String? ae;
  final String? ad;
  final String? ag;
  final String? ip;
  final String? ik;
  final bool isZone;

  PdfClassementRow({
    required this.localisation,
    required this.zone,
    required this.type,
    required this.origineClassement,
    this.af,
    this.be,
    this.ae,
    this.ad,
    this.ag,
    this.ip,
    this.ik,
    required this.isZone,
  });
}



/// Builder responsable du Classement des Emplacements et de la Protection Foudre & Surtensions
class PdfClassementFoudreBuilder {
  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();

  static const double fsH1 = PdfReportStyles.fsH1;
  static const double fsH2 = PdfReportStyles.fsH2;
  static const double fsH3 = PdfReportStyles.fsH3;
  static const double fsBody = PdfReportStyles.fsBody;
  static const double fsSmall = PdfReportStyles.fsSmall;

  static pw.Widget Function()? pageHeaderBuilder;

  static pw.Widget _subSectionBar(String title) => PdfReportStyles.subTitle(title);

  static String _normalizeText(String text) {
    if (text.isEmpty) return text;
    text = text.replaceAll(RegExp(r'§\s*'), 'art ');

    const replacements = <String, String>{
      '«': '"', '»': '"', '“': '"', '”': '"',
      '‘': "'", '’': "'",
      '—': '-', '–': '-', '…': '...',
      '≥': '>=', '≤': '<=', '≠': '!=',
      '±': '+/-', '∞': 'inf', '√': 'racine',
      '→': '->', '←': '<-', '↔': '<->',
      '∑': 'Somme', '∆': 'Delta', 'Φ': 'Phi',
      'θ': 'theta',
    };
    replacements.forEach((key, val) {
      text = text.replaceAll(key, val);
    });
    return text;
  }

  // Internal delegates for backward compatibility
  static List<pw.Widget> _buildClassementEmplacementsMulti(
    List<ClassementEmplacement> emplacements,
    List<ClassementZone> zonesClassement,
    Map<String, int> trackedPages, {
    int offset = 0,
  }) =>
      buildClassementEmplacementsMulti(
        emplacements,
        zonesClassement,
        trackedPages,
        offset: offset,
      );

  static List<pw.Widget> _buildCodificationInfluencesMulti() =>
      buildCodificationInfluencesMulti();

  static pw.Widget _buildCodificationInfluences() =>
      buildCodificationInfluences();

  static String _getFormattedPhotoLabel(
    List<String> photoPaths,
    Map<String, int>? photoRegistry,
  ) =>
      getFormattedPhotoLabel(photoPaths, photoRegistry);

  static List<PdfParafoudreEquipementRow> _collectParafoudreRows(
    AuditInstallationsElectriques? audit,
  ) =>
      collectParafoudreRows(audit);

  static List<PdfFoudreZoneGroup> _groupByZoneLocalEquipFoudre(
    List<PdfParafoudreEquipementRow> rows,
  ) =>
      groupByZoneLocalEquipFoudre(rows);

  static List<pw.Widget> _buildFoudre(
    AuditInstallationsElectriques? audit,
    List<Foudre> foudres,
    Map<String, int> trackedPages, {
    bool afficherTableauFoudre = true,
    int offset = 0,
    DescriptionInstallations? desc,
    Map<String, int>? photoRegistry,
    pw.Widget? headerWidget,
  }) =>
      buildFoudre(
        audit,
        foudres,
        trackedPages,
        afficherTableauFoudre: afficherTableauFoudre,
        offset: offset,
        desc: desc,
        photoRegistry: photoRegistry,
        headerWidget: headerWidget,
      );


  // ──────────────────────────────────────────────────────────────
  //  CLASSEMENT DES EMPLACEMENTS
  // ──────────────────────────────────────────────────────────────

  static List<pw.Widget> buildClassementEmplacementsMulti(
    List<ClassementEmplacement> emplacements,
    List<ClassementZone> zonesClassement,
    Map<String, int> trackedPages, {
    int offset = 0,
  }) {
    final widgets = <pw.Widget>[];

    // _sectionBox title like other sections
    widgets.add(
      PageTracker(
        key: 'classement',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.sectionBox(
          "CLASSEMENT ET EMPLACEMENTS DES LOCAUX ET ZONE EN FONCTION DES INFLUENCES EXTERNES",
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(
      PdfReportStyles.bodyText(
        "Dans le cas d'absence de fourniture d'une liste exhaustive des risques "
        "particuliers, le classement éventuel ci-après est proposé par le vérificateur "
        "et, sauf avis contraire, considéré comme validé par le chef d'établissement.",
      ),
    );
    widgets.add(pw.SizedBox(height: 12));

    final rows = <PdfClassementRow>[];

    // 1. Zones classées dans la mission (Règles A et B : Ligne 1 de la Zone avec Repère vide)
    for (var zone in zonesClassement) {
      if (zone.nomZone.trim().isEmpty) continue;
      rows.add(
        PdfClassementRow(
          localisation: '', // Repère vide pour l'entrée de Zone elle-même (Règles A et B)
          zone: zone.nomZone.trim(),
          type: 'Zone ${zone.typeZone}',
          origineClassement: zone.origineClassement,
          af: zone.af,
          be: zone.be,
          ae: zone.ae,
          ad: zone.ad,
          ag: zone.ag,
          ip: zone.ip,
          ik: zone.ik,
          isZone: true,
        ),
      );
    }

    // 2. Emplacements / Locaux classés (Règles B et C)
    for (var emp in emplacements) {
      final isZoneEmp = emp.typeEmplacement == 'zone';

      // Si c'est une zone déjà traitée dans zonesClassement, ne pas la dupliquer
      if (isZoneEmp) {
        final dejaPresente = zonesClassement.any(
          (z) => z.nomZone.trim().toLowerCase() == emp.localisation.trim().toLowerCase(),
        );
        if (dejaPresente) continue;
      }

      final hasZoneParent = (emp.zone != null && emp.zone!.trim().isNotEmpty);
      final String parentZoneName = hasZoneParent ? emp.zone!.trim() : '';

      if (isZoneEmp) {
        // Zone classée présente uniquement dans emplacements (Règle A)
        rows.add(
          PdfClassementRow(
            localisation: '', // Repère vide (Règle A)
            zone: emp.localisation.trim(),
            type: 'Zone',
            origineClassement: emp.origineClassement,
            af: emp.af,
            be: emp.be,
            ae: emp.ae,
            ad: emp.ad,
            ag: emp.ag,
            ip: emp.ip,
            ik: emp.ik,
            isZone: true,
          ),
        );
      } else {
        // C'est un local / repère (Règle B ou C)
        if (hasZoneParent) {
          // Règle B : Local dans une zone classée (Zone = nom zone, Repère = nom local)
          rows.add(
            PdfClassementRow(
              localisation: emp.localisation.trim(),
              zone: parentZoneName,
              type: 'Local',
              origineClassement: emp.origineClassement,
              af: emp.af,
              be: emp.be,
              ae: emp.ae,
              ad: emp.ad,
              ag: emp.ag,
              ip: emp.ip,
              ik: emp.ik,
              isZone: false,
            ),
          );
        } else {
          // Règle C : Local hors zone (Zone = '', Repère = nom local)
          rows.add(
            PdfClassementRow(
              localisation: emp.localisation.trim(),
              zone: '',
              type: 'Local',
              origineClassement: emp.origineClassement,
              af: emp.af,
              be: emp.be,
              ae: emp.ae,
              ad: emp.ad,
              ag: emp.ag,
              ip: emp.ip,
              ik: emp.ik,
              isZone: false,
            ),
          );
        }
      }
    }

    // Tri ordonné par Zone puis Repère (Ligne 1 de la zone en premier)
    rows.sort((a, b) {
      final aZoneKey = a.zone.trim().toLowerCase();
      final bZoneKey = b.zone.trim().toLowerCase();

      if (aZoneKey != bZoneKey) {
        if (aZoneKey.isEmpty) return 1; // Hors zone en fin de tableau
        if (bZoneKey.isEmpty) return -1;
        return aZoneKey.compareTo(bZoneKey);
      }

      // Dans la même zone : la ligne propre de la Zone (Repère vide) en PREMIER (Ligne 1)
      if (a.localisation.isEmpty && b.localisation.isNotEmpty) return -1;
      if (a.localisation.isNotEmpty && b.localisation.isEmpty) return 1;
      return a.localisation.compareTo(b.localisation);
    });

    // Main header table with PdfReportStyles.lightBlue decoration and PdfReportStyles.headerColor texts
    final header = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(24), // N°
        1: pw.FlexColumnWidth(1.2), // Zone
        2: pw.FlexColumnWidth(1.7), // Repère
        3: pw.FlexColumnWidth(0.9), // Origine classement
        4: pw.FlexColumnWidth(2.4), // Influences externes (5 sub-cols)
        5: pw.FlexColumnWidth(1.4), // Indice mini (2 sub-cols)
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text(
                'N°',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text(
                'Zone',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text(
                'Repère',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text(
                'Origine\nclassement',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsSmall,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            // Influences externes (double level with vertical inside borders)
            pw.Column(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text(
                    'Influences externes',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: PdfReportStyles.fsSmall,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Divider(height: 0.4, color: PdfReportStyles.borderColor),
                pw.Table(
                  defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                  border: pw.TableBorder(
                    verticalInside: pw.BorderSide(
                      color: PdfReportStyles.borderColor,
                      width: 0.4,
                    ),
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(0.48),
                    1: pw.FlexColumnWidth(0.48),
                    2: pw.FlexColumnWidth(0.48),
                    3: pw.FlexColumnWidth(0.48),
                    4: pw.FlexColumnWidth(0.48),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'AF',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: PdfReportStyles.fsSmall,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'BE',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: PdfReportStyles.fsSmall,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'AE',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: PdfReportStyles.fsSmall,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'AD',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: PdfReportStyles.fsSmall,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'AG',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: PdfReportStyles.fsSmall,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Indice mini de protection (double level with vertical inside borders)
            pw.Column(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text(
                    'Indice mini de\nprotection',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: PdfReportStyles.fsSmall,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Divider(height: 0.4, color: PdfReportStyles.borderColor),
                pw.Table(
                  defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                  border: pw.TableBorder(
                    verticalInside: pw.BorderSide(
                      color: PdfReportStyles.borderColor,
                      width: 0.4,
                    ),
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(0.7),
                    1: pw.FlexColumnWidth(0.7),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text(
                          'IP',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: PdfReportStyles.fsSmall,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          'IK',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: PdfReportStyles.fsSmall,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    widgets.add(header);

    final dataRows = <pw.TableRow>[];
    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      final rowColor = i.isOdd ? PdfReportStyles.tableRowAlt : PdfColors.white;
      final zoneText = r.zone == '—' ? '' : r.zone;

      dataRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: rowColor),
          children: [
            // N°
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '${i + 1}',
                style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                textAlign: pw.TextAlign.center,
              ),
            ),
            // Zone (uppercase, empty if null/empty)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                zoneText.toUpperCase(),
                style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                textAlign: pw.TextAlign.center,
              ),
            ),
            // Localisation (uppercase, centered)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                r.localisation.toUpperCase(),
                style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                textAlign: pw.TextAlign.center,
              ),
            ),
            // Origine
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                r.origineClassement,
                style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                textAlign: pw.TextAlign.center,
              ),
            ),
            // Influences (5 colonnes plates)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text(
                r.af ?? '',
                style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text(
                r.be ?? '',
                style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text(
                r.ae ?? '',
                style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text(
                r.ad ?? '',
                style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text(
                r.ag ?? '',
                style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                textAlign: pw.TextAlign.center,
              ),
            ),
            // IP/IK (2 colonnes plates)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text(
                r.ip ?? '',
                style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text(
                r.ik ?? '',
                style: pw.TextStyle(font: fontRegular, fontSize: PdfReportStyles.fsSmall),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    widgets.add(
      pw.Table(
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        border: pw.TableBorder(
          left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
          right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
          bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
          verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
          horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        ),
        columnWidths: const {
          0: pw.FixedColumnWidth(24), // N°
          1: pw.FlexColumnWidth(1.2), // Zone
          2: pw.FlexColumnWidth(1.7), // Localisation / Repère
          3: pw.FlexColumnWidth(0.9), // Origine
          4: pw.FlexColumnWidth(0.48), // AF
          5: pw.FlexColumnWidth(0.48), // BE
          6: pw.FlexColumnWidth(0.48), // AE
          7: pw.FlexColumnWidth(0.48), // AD
          8: pw.FlexColumnWidth(0.48), // AG
          9: pw.FlexColumnWidth(0.7), // IP
          10: pw.FlexColumnWidth(0.7), // IK
        },
        children: dataRows,
      ),
    );

    widgets.add(pw.NewPage()); // Saut de page avant la codification
    widgets.addAll(_buildCodificationInfluencesMulti());

    return widgets;
  }

  static List<pw.Widget> buildCodificationInfluencesMulti() {
    return [_buildCodificationInfluences()];
  }

  static pw.Widget buildCodificationInfluences() {
    final titleTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: const {0: pw.FlexColumnWidth(7.2)},
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                "CODIFICATION DES INFLUENCES EXTERNES – INDICES ET DEGRÉS DE PROTECTION",
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: PdfReportStyles.fsH3,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );

    pw.TableRow blueHeaderRow(List<String> headers) {
      return pw.TableRow(
        decoration: pw.BoxDecoration(
          color: PdfReportStyles.lightBlue,
        ), // Matching PdfReportStyles.lightBlue background
        children: headers
            .map(
              (h) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  h,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: PdfReportStyles.fsSmall,
                    color: PdfReportStyles.headerColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            )
            .toList(),
      );
    }

    final dataTable = pw.Table(
      border: pw.TableBorder(
        left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        blueHeaderRow([
          "PÉNÉTRATION DE CORPS SOLIDES",
          "SUBSTANCES CORROSIVES OU POLLUANTES",
          "MATIÈRES TRAITÉES OU ENTREPOSÉES",
        ]),
        PdfReportStyles.tableDataRow([
          "AE1 : Negligeable -> IP 2X",
          "AF1 : Negligeable",
          "BE1 : Risques negligeables",
        ], alt: false),
        PdfReportStyles.tableDataRow([
          "AE2 : Petits objets (\u2265 2,5 mm) -> IP 3X",
          "AF2 : Agents d'origine atmospherique",
          "BE2 : Risques d'incendie",
        ], alt: true),
        PdfReportStyles.tableDataRow([
          "AE3 : Tres petits objets (1 a 2,5 mm) -> IP 4X",
          "AF3 : Intermittente ou accidentelle",
          "BE3 : Risques d'explosion",
        ], alt: false),
        PdfReportStyles.tableDataRow([
          "AE4 : Poussieres -> IP 5X (Protege)",
          "AF4 : Permanente",
          "BE4 : Risques de contamination",
        ], alt: true),
        blueHeaderRow([
          "ACCÈS AUX PARTIES DANGEREUSES",
          "PÉNÉTRATION DE LIQUIDES",
          "RISQUES DE CHOCS MÉCANIQUES",
        ]),
        PdfReportStyles.tableDataRow([
          "Non protege -> IP 0X",
          "AD1 : Negligeable -> IP X0",
          "AG1 : Faibles (0,225 J) -> IK 02",
        ], alt: false),
        PdfReportStyles.tableDataRow([
          "A : Avec le dos de la main -> IP 1X",
          "AD2 : Chutes de gouttes d'eau -> IP X1",
          "AG2 : Moyens (2 J) -> IK 07",
        ], alt: true),
        PdfReportStyles.tableDataRow([
          "B : Avec un doigt -> IP 2X",
          "AD3 : Chutes de gouttes jusqu'à 15\u00B0 -> IP X2",
          "AG3 : Importants (5 J) -> IK 08",
        ], alt: false),
        PdfReportStyles.tableDataRow([
          "C : Avec un outil -> IP 3X",
          "AD4 : Aspersion d'eau -> IP X3",
          "AG4 : Tres importants (20 J) -> IK 10",
        ], alt: true),
        PdfReportStyles.tableDataRow([
          "D : Avec un fil -> IP 4X",
          "AD5 : Projections d'eau -> IP X4",
          "",
        ], alt: false),
        PdfReportStyles.tableDataRow(["", "AD6 : Jets d'eau -> IP X5", ""], alt: true),
        PdfReportStyles.tableDataRow(["", "AD7 : Paquets d'eau -> IP X6", ""], alt: false),
        PdfReportStyles.tableDataRow(["", "AD8 : Immersion -> IP X7", ""], alt: true),
        PdfReportStyles.tableDataRow(["", "AD9 : Submersion -> IP X8", ""], alt: false),
        blueHeaderRow(["COMPÉTENCE DES PERSONNES", "VIBRATIONS", ""]),
        PdfReportStyles.tableDataRow(["BA1 : Ordinaires", "AH1 : Faibles", ""], alt: false),
        PdfReportStyles.tableDataRow(["BA2 : Enfants", "AH2 : Moyennes", ""], alt: true),
        PdfReportStyles.tableDataRow([
          "BA3 : Personnes handicapees",
          "AH3 : Importantes",
          "",
        ], alt: false),
        PdfReportStyles.tableDataRow(["BA4 : Personnes averties", "", ""], alt: true),
        PdfReportStyles.tableDataRow(["BA5 : Personnes qualifiees", "", ""], alt: false),
      ],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [titleTable, dataTable],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  FOUDRE
  // ──────────────────────────────────────────────────────────────

  static String getFormattedPhotoLabel(
    List<String> photoPaths,
    Map<String, int>? photoRegistry,
  ) {
    if (photoPaths.isEmpty || photoRegistry == null || photoRegistry.isEmpty) {
      return '-';
    }

    final numbers = <int>[];
    for (final path in photoPaths) {
      final trimmed = path.trim();
      if (trimmed.isNotEmpty && photoRegistry.containsKey(trimmed)) {
        numbers.add(photoRegistry[trimmed]!);
      }
    }

    if (numbers.isEmpty) return '-';

    final sorted = numbers.toSet().toList()..sort();
    if (sorted.length == 1) {
      return 'Photo ${sorted.first}';
    }

    return 'Photos ${sorted.join(', ')}';
  }

  static const String defaultParafoudreRefNormative =
      'NF C 15-100-1:2024 – art 443 et art 534';
  static const String defaultParafoudreCriticite = 'Majeure';
  static const String defaultParafoudrePointPV =
      'Dispositif de protection contre les surtensions (parafoudre)';
  static const String defaultParafoudrePointSlide3 =
      'Dispositif de protection contre les surtensions (parafoudre)';

  static List<PdfParafoudreEquipementRow> collectParafoudreRows(
    AuditInstallationsElectriques? audit,
  ) {
    final rows = <PdfParafoudreEquipementRow>[];
    if (audit == null) return rows;

    final seenKeys = <String>{};

    bool isParafoudreRelated(String text) {
      final lower = text.toLowerCase();
      return lower.contains('parafoudre') ||
          lower.contains('surtension') ||
          lower.contains('foudre') ||
          lower.contains('limiteur');
    }

    void processCoffret(CoffretArmoire c, {String zoneName = '', String localName = ''}) {
      final cRepere = (c.repere != null && c.repere!.trim().isNotEmpty) ? c.repere!.trim() : '';
      final cNom = c.nom.trim();
      final cNum = c.numeroEquipement?.trim() ?? '';

      final String equipementName;
      if (cNom.isNotEmpty) {
        equipementName = cNom;
      } else if (cRepere.isNotEmpty) {
        equipementName = cRepere;
      } else if (cNum.isNotEmpty) {
        equipementName = cNum;
      } else {
        equipementName = '-';
      }

      String resolvedZone = zoneName.trim();
      String resolvedLocal = localName.trim();

      if (resolvedZone.isEmpty && resolvedLocal.isEmpty) {
        final targetLoc = cRepere.isNotEmpty ? cRepere : cNom;
        if (targetLoc.isNotEmpty) {
          final emp = HiveService.getEmplacementByNom(audit.missionId, targetLoc);
          if (emp != null) {
            if (emp.typeEmplacement == 'zone') {
              resolvedZone = emp.localisation.trim();
            } else {
              resolvedLocal = emp.localisation.trim();
              if (emp.zone != null && emp.zone!.trim().isNotEmpty) {
                resolvedZone = emp.zone!.trim();
              }
            }
          }
        }
      }

      if (resolvedLocal.isEmpty && cRepere.isNotEmpty && cRepere != cNom) {
        resolvedLocal = cRepere;
      }

      final String repereDisplay;
      if (cRepere.isNotEmpty && cNom.isNotEmpty && cRepere != cNom) {
        repereDisplay = '$cRepere - $cNom';
      } else if (cRepere.isNotEmpty) {
        repereDisplay = cRepere;
      } else if (resolvedLocal.isNotEmpty) {
        repereDisplay = resolvedLocal;
      } else if (cNom.isNotEmpty) {
        repereDisplay = cNom;
      } else if (cNum.isNotEmpty) {
        repereDisplay = cNum;
      } else {
        repereDisplay = '-';
      }

      final String? cid = c.id;
      final String equipKey = (cid != null && cid.trim().isNotEmpty)
          ? cid.trim()
          : '${resolvedZone.toLowerCase()}_${resolvedLocal.toLowerCase()}_${equipementName.toLowerCase()}';
      if (seenKeys.contains(equipKey)) return;

      bool equipObservationAdded = false;

      void addRow({
        required String observation,
        String pointVerification = '-',
        String referenceNormative = '-',
        String criticite = '-',
        List<String>? photoPaths,
        required String key,
      }) {
        if (equipObservationAdded || seenKeys.contains(equipKey)) return;

        final textTrim = observation.trim();
        if (textTrim.isEmpty) return;

        final refNormTrim = referenceNormative.trim();
        final finalRef = (refNormTrim.isEmpty || refNormTrim == '-')
            ? defaultParafoudreRefNormative
            : refNormTrim;

        final critTrim = criticite.trim();
        final finalCrit = (critTrim.isEmpty || critTrim == '-')
            ? defaultParafoudreCriticite
            : critTrim;

        // La colonne POINT DE VÉRIFICATION doit TOUJOURS contenir strictement:
        // "Dispositif de protection contre les surtensions (parafoudre)"
        const finalPv = defaultParafoudrePointPV;

        seenKeys.add(equipKey);
        equipObservationAdded = true;

        rows.add(
          PdfParafoudreEquipementRow(
            zoneName: resolvedZone,
            localName: resolvedLocal,
            equipementName: equipementName,
            repere: repereDisplay,
            pointVerification: finalPv,
            referenceNormative: finalRef,
            criticite: finalCrit,
            observation: textTrim,
            photoPaths: photoPaths ?? [],
            identityKey: equipKey,
          ),
        );
      }

      // Points de vérification liés au parafoudre / surtension (strictement réservés aux observations par équipement)
      for (var pv in c.pointsVerification) {
        if (equipObservationAdded) break;

        final isRelated = isParafoudreRelated(pv.pointVerification) ||
            isParafoudreRelated(pv.familleRisque ?? '') ||
            isParafoudreRelated(pv.referenceNormative ?? '') ||
            isParafoudreRelated(pv.observation ?? '');

        if (isRelated) {
          final pvTitle = pv.pointVerification.trim().isNotEmpty
              ? pv.pointVerification.trim()
              : defaultParafoudrePointPV;
          final pvRef = pv.referenceNormative?.trim().isNotEmpty == true
              ? pv.referenceNormative!.trim()
              : defaultParafoudreRefNormative;
          final pvCrit = pv.criticite?.trim().isNotEmpty == true
              ? pv.criticite!.trim()
              : defaultParafoudreCriticite;

          if (pv.observation != null && pv.observation!.trim().isNotEmpty) {
            final allPhotos = <String>[...pv.photos];
            if (pv.observations != null) {
              for (var el in pv.observations!) {
                for (var p in el.photos) {
                  if (!allPhotos.contains(p)) allPhotos.add(p);
                }
              }
            }
            addRow(
              pointVerification: pvTitle,
              referenceNormative: pvRef,
              criticite: pvCrit,
              observation: pv.observation!,
              photoPaths: allPhotos,
              key: 'pv_${identityHashCode(pv)}',
            );
          } else if (pv.observations != null && pv.observations!.isNotEmpty) {
            for (var el in pv.observations!) {
              if (equipObservationAdded) break;
              final text = el.observation?.isNotEmpty == true
                  ? el.observation!
                  : el.elementControle;
              final elPoint = el.elementControle.trim().isNotEmpty
                  ? el.elementControle.trim()
                  : pvTitle;
              addRow(
                pointVerification: elPoint,
                referenceNormative: el.referenceNormativeEffective ??
                    el.referenceNormative ??
                    pvRef,
                criticite: el.criticite ?? pvCrit,
                observation: text,
                photoPaths: el.photos,
                key: 'pvel_${identityHashCode(el)}',
              );
            }
          }
        }
      }

      // 4. Observations libres spécifiques au parafoudre sur le coffret (si aucune observation n'a été ajoutée)
      if (!equipObservationAdded) {
        for (var obs in c.observationsLibres) {
          if (equipObservationAdded) break;
          if (isParafoudreRelated(obs.texte)) {
            addRow(
              pointVerification: defaultParafoudrePointSlide3,
              referenceNormative: obs.referenceNormative ?? defaultParafoudreRefNormative,
              criticite: obs.criticite ?? defaultParafoudreCriticite,
              observation: obs.texte,
              photoPaths: obs.photos,
              key: 'obslibre_${identityHashCode(obs)}',
            );
          }
        }
      }
    }

    // 1. Locaux MT (Hors zone)
    for (var local in audit.moyenneTensionLocaux) {
      for (var coffret in local.coffrets) {
        processCoffret(coffret, localName: local.nom);
      }
    }
    // 2. Zones MT
    for (var zone in audit.moyenneTensionZones) {
      for (var coffret in zone.coffrets) {
        processCoffret(coffret, zoneName: zone.nom);
      }
      for (var local in zone.locaux) {
        for (var coffret in local.coffrets) {
          processCoffret(coffret, zoneName: zone.nom, localName: local.nom);
        }
      }
    }
    // 3. Zones BT
    for (var zone in audit.basseTensionZones) {
      for (var coffret in zone.coffretsDirects) {
        processCoffret(coffret, zoneName: zone.nom);
      }
      for (var local in zone.locaux) {
        for (var coffret in local.coffrets) {
          processCoffret(coffret, zoneName: zone.nom, localName: local.nom);
        }
      }
    }

    return rows;
  }

  static List<PdfFoudreZoneGroup> groupByZoneLocalEquipFoudre(
    List<PdfParafoudreEquipementRow> obsList,
  ) {
    final zoneGroups = <PdfFoudreZoneGroup>[];

    for (final o in obsList) {
      final zName = o.zoneName.trim();
      final lName = o.localName.trim().isNotEmpty
          ? o.localName.trim()
          : (o.repere.trim().isNotEmpty && o.repere != '-' ? o.repere.trim() : '-');
      final eName = o.equipementName.trim().isNotEmpty
          ? o.equipementName.trim()
          : '-';

      PdfFoudreZoneGroup currentZoneGroup;
      final existingZoneIdx = zoneGroups.indexWhere((z) => z.zoneName == zName);
      if (existingZoneIdx != -1) {
        currentZoneGroup = zoneGroups[existingZoneIdx];
      } else {
        currentZoneGroup = PdfFoudreZoneGroup(zoneName: zName, localGroups: []);
        zoneGroups.add(currentZoneGroup);
      }

      PdfFoudreLocalGroup currentLocalGroup;
      final existingLocalIdx = currentZoneGroup.localGroups.indexWhere((l) => l.localName == lName);
      if (existingLocalIdx != -1) {
        currentLocalGroup = currentZoneGroup.localGroups[existingLocalIdx];
      } else {
        currentLocalGroup = PdfFoudreLocalGroup(localName: lName, equipGroups: []);
        currentZoneGroup.localGroups.add(currentLocalGroup);
      }

      PdfFoudreEquipGroup currentEquipGroup;
      final existingEquipIdx = currentLocalGroup.equipGroups.indexWhere((e) => e.equipementName == eName);
      if (existingEquipIdx != -1) {
        currentEquipGroup = currentLocalGroup.equipGroups[existingEquipIdx];
      } else {
        currentEquipGroup = PdfFoudreEquipGroup(equipementName: eName, items: []);
        currentLocalGroup.equipGroups.add(currentEquipGroup);
      }

      currentEquipGroup.items.add(o);
    }

    return zoneGroups;
  }

  static List<pw.Widget> buildFoudre(
    AuditInstallationsElectriques? audit,
    List<Foudre> foudres,
    Map<String, int> trackedPages, {
    bool afficherTableauFoudre = false,
    int offset = 0,
    DescriptionInstallations? desc,
    Map<String, int>? photoRegistry,
    pw.Widget? headerWidget,
  }) {
    final equipRows = _collectParafoudreRows(audit);
    final presenceParatonnerre = desc?.presenceParatonnerre?.trim();
    final isParatonnerreNon = presenceParatonnerre == 'Non';
    final foudreObsList = desc?.foudreObservations ?? [];

    pw.Widget itemBulletBold(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 3, bottom: 2),
        child: pw.Text(
          _normalizeText(text),
          style: pw.TextStyle(
            font: fontBold,
            fontSize: PdfReportStyles.fsBody,
            color: PdfReportStyles.darkGrey,
          ),
        ),
      );
    }

    pw.Widget itemSubBullet(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(left: 6, bottom: 2),
        child: pw.Text(
          _normalizeText(text),
          style: pw.TextStyle(
            font: fontRegular,
            fontSize: PdfReportStyles.fsBody - 0.5,
            color: PdfReportStyles.darkGrey,
          ),
        ),
      );
    }

    final List<pw.Widget> widgets = [
      (headerWidget ?? (pageHeaderBuilder != null ? pageHeaderBuilder!() : pw.SizedBox.shrink())),
      pw.SizedBox(height: 10),
      PageTracker(
        key: 'foudre',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.sectionBox('FOUDRE ET SURTENSION'),
      ),
      pw.SizedBox(height: 10),
    ];

    // CAS 1 : Paratonnerre = "Non" -> Bloc Recommandation Protection contre la foudre EXCLUSIF
    if (isParatonnerreNon) {
      widgets.addAll([
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfReportStyles.borderColor, width: 0.5),
            color: PdfColors.white,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                color: PdfReportStyles.accentColor,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: pw.Text(
                  'Recommandation – Protection contre la foudre',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: PdfReportStyles.fsBody + 1,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Constat :',
                      style: pw.TextStyle(font: fontBold, fontSize: PdfReportStyles.fsBody, color: PdfReportStyles.headerColor),
                    ),
                    pw.SizedBox(height: 4),
                    PdfReportStyles.bodyText(
                      'Lors de la vérification des installations électriques, il a été constaté l’absence de dispositif de protection contre la foudre de type paratonnerre sur le site.',
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Recommandation :',
                      style: pw.TextStyle(font: fontBold, fontSize: PdfReportStyles.fsBody, color: PdfReportStyles.headerColor),
                    ),
                    pw.SizedBox(height: 4),
                    PdfReportStyles.bodyText(
                      'Au regard de l’absence de dispositif de protection contre les impacts directs de la foudre, il serait souhaitable de faire réaliser une analyse et étude technique du risque foudre, prenant notamment en compte les caractéristiques du site, la nature et la hauteur des bâtiments, leur environnement, les équipements installés ainsi que les conséquences potentielles d’un impact de foudre.',
                    ),
                    pw.SizedBox(height: 4),
                    PdfReportStyles.bodyText(
                      'Cette étude permettra de déterminer la nécessité, le niveau et le type de protection approprié, ainsi que les caractéristiques du système de protection à mettre en œuvre, notamment le dispositif de capture et les parafoudres.',
                    ),
                    pw.SizedBox(height: 4),
                    PdfReportStyles.bodyText(
                      'Il est par conséquent recommandé de programmer la réalisation de ces études afin de statuer sur la nécessité d’installer un paratonnerre et, le cas échéant, de définir une solution de protection adaptée aux caractéristiques du site.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 14),
      ]);
    } else {
      // CAS 2 : Paratonnerre = "Oui" (ou afficherTableauFoudre activé)
      widgets.addAll([
        pw.Table(
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
          border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
          columnWidths: const {
            0: pw.FlexColumnWidth(0.6),
            1: pw.FlexColumnWidth(0.9),
            2: pw.FlexColumnWidth(4.5),
          },
          children: [
            PdfReportStyles.tableHeaderRow(['Items', 'CRITICITÉ', 'Observations']),

            // Ligne Principale (Contenu principal d'analyse & étude)
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.white),
              children: [
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    '1',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: PdfReportStyles.fsBody,
                      color: PdfReportStyles.headerColor,
                    ),
                  ),
                ),
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Majeure',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: PdfReportStyles.fsSmall,
                      color: PdfColor.fromInt(0xFFE65100),
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      PdfReportStyles.bodyText(
                        "Une installation de paratonnerre conforme et efficace, doit répondre dans un premier temps aux principes de base d'installation d'un paratonnerre.",
                      ),
                      pw.SizedBox(height: 3),
                      PdfReportStyles.bodyText("Il est indispensable de réaliser :"),
                      itemBulletBold("- Une analyse risque foudre"),
                      PdfReportStyles.bodyText(
                        "L'ARF a pour objectif de définir précisément les biens à protéger ainsi que les niveaux de protection nécessaires aux installations et à l'étude technique.",
                      ),
                      pw.SizedBox(height: 3),
                      PdfReportStyles.bodyText(
                        "Analyse du Risque Foudre, selon la norme NF EN 62305-2,",
                      ),
                      PdfReportStyles.bodyText(
                        "Elle intégrera les différents points suivants :",
                      ),
                      itemSubBullet(
                        "•  Estimation des risques selon la norme EN 62305-2/FD 17018",
                      ),
                      itemSubBullet(
                        "•  Définition des niveaux de protection exigés sur l'installation",
                      ),
                      itemSubBullet(
                        "•  Identification des événements redoutés dus aux effets de la foudre",
                      ),
                      itemSubBullet(
                        "•  La rédaction d'un rapport ARF (En langue Française) précisant le niveau de protection éventuelle à atteindre pour les structures et services à protéger",
                      ),
                      pw.SizedBox(height: 4),
                      itemBulletBold("- Une étude technique foudre"),
                      PdfReportStyles.bodyText(
                        "L'Etude Technique définit de façon détaillée les Installations Extérieures de Protection Foudre (IEPF) et les Installations Intérieures de Protection Foudre (IIPF) selon les normes en vigueur NF C 17 102, NF EN 62305-3 et NF EN 62305-4.",
                      ),
                      pw.SizedBox(height: 3),
                      PdfReportStyles.bodyText(
                        "Elle intégrera les différents points suivants :",
                      ),
                      itemSubBullet("•  Les mesures de prévention"),
                      itemSubBullet(
                        "•  Le descriptif des équipements à installés (caractéristiques techniques)",
                      ),
                      itemSubBullet(
                        "•  Le lieu d'implantation des équipements de protection",
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Lignes Dynamiques d'observations structurées (Ligne 2, Ligne 3...)
            ...foudreObsList.asMap().entries.map((entry) {
              final itemIndex = entry.key + 2;
              final obs = entry.value;
              final crit = obs.criticite?.trim().isNotEmpty == true ? obs.criticite! : 'Majeure';

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: entry.key.isOdd ? PdfReportStyles.tableRowAlt : PdfColors.white,
                ),
                children: [
                  pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      '$itemIndex',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: PdfReportStyles.fsBody,
                        color: PdfReportStyles.headerColor,
                      ),
                    ),
                  ),
                  pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      crit,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: PdfReportStyles.fsSmall,
                        color: PdfColor.fromInt(0xFFE65100),
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: PdfReportStyles.bodyText(obs.texte),
                  ),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 14),

        // Sous-section : Observation par équipement
        PageTracker(
          key: 'foudre_equipements',
          registry: trackedPages,
          offset: offset,
          child: _subSectionBar("1. Observation par équipement"),
        ),
        pw.SizedBox(height: 6),
      ]);

      if (equipRows.isEmpty) {
        widgets.add(PdfReportStyles.bodyText('Aucune observation parafoudre par équipement disponible.'));
      } else {
        final zoneGroups = _groupByZoneLocalEquipFoudre(equipRows);
        final tableRows = <pw.TableRow>[];

        tableRows.add(
          PdfReportStyles.tableHeaderRow([
            'ZONE',
            'REPÈRE',
            'DÉSIGNATION',
            'POINT DE VÉRIFICATION',
            'RÉF. NORMATIVE',
            'CRITICITÉ',
            'OBSERVATION',
            'PHOTO',
          ]),
        );

        int zoneRowIndex = 0;

        for (final zoneGroup in zoneGroups) {
          final totalZoneItems = zoneGroup.localGroups.fold<int>(
            0,
            (sum, lg) => sum + lg.equipGroups.fold<int>(0, (s, eg) => s + eg.items.length),
          );

          int localRowIndex = 0;

          for (int lIdx = 0; lIdx < zoneGroup.localGroups.length; lIdx++) {
            final localGroup = zoneGroup.localGroups[lIdx];
            final totalLocalItems = localGroup.equipGroups.fold<int>(
              0,
              (s, eg) => s + eg.items.length,
            );

            for (int eIdx = 0; eIdx < localGroup.equipGroups.length; eIdx++) {
              final equipGroup = localGroup.equipGroups[eIdx];
              final totalEquipItems = equipGroup.items.length;

              final equipBg = eIdx % 2 == 0 ? PdfColors.white : PdfColor.fromInt(0xFFF8FAFC);

              for (int i = 0; i < totalEquipItems; i++) {
                final o = equipGroup.items[i];
                final currentZoneRowIdx = zoneRowIndex++;
                final currentLocalRowIdx = localRowIndex++;
                final currentEquipRowIdx = i;

                final isEndOfEquip = (currentEquipRowIdx == totalEquipItems - 1);
                final isEndOfLocal = (currentLocalRowIdx == totalLocalItems - 1);
                final isEndOfZone = (currentZoneRowIdx == totalZoneItems - 1);

                final zoneBorder = pw.Border(
                  bottom: isEndOfZone
                      ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                      : pw.BorderSide.none,
                );

                final localBorder = pw.Border(
                  bottom: isEndOfZone
                      ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                      : (isEndOfLocal
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                          : pw.BorderSide.none),
                );

                final equipBorder = pw.Border(
                  bottom: isEndOfZone
                      ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                      : (isEndOfLocal
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                          : (isEndOfEquip
                              ? const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.6)
                              : pw.BorderSide.none)),
                );

                final obsBorder = pw.Border(
                  bottom: isEndOfZone
                      ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                      : (isEndOfLocal
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                          : (isEndOfEquip
                              ? const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.6)
                              : const pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.4))),
                );

                final photoLabel = _getFormattedPhotoLabel(o.photoPaths, photoRegistry);

                tableRows.add(
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: equipBg),
                    children: [
                      // Cellule 0 : ZONE (centré)
                      PdfReportStyles.buildGroupedCellWidget(
                        currentIndex: currentZoneRowIdx,
                        totalRows: totalZoneItems,
                        text: zoneGroup.zoneName.isNotEmpty ? zoneGroup.zoneName : '-',
                        style: pw.TextStyle(font: fontBold, fontSize: 8.0, color: PdfReportStyles.headerColor),
                        border: zoneBorder,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        alignment: pw.Alignment.center,
                        textAlign: pw.TextAlign.center,
                      ),

                      // Cellule 1 : REPÈRE (centré)
                      PdfReportStyles.buildGroupedCellWidget(
                        currentIndex: currentLocalRowIdx,
                        totalRows: totalLocalItems,
                        text: localGroup.localName.isNotEmpty
                            ? localGroup.localName
                            : (o.repere.isNotEmpty && o.repere != '-' ? o.repere : '-'),
                        style: pw.TextStyle(font: fontBold, fontSize: 8.0, color: PdfReportStyles.headerColor),
                        border: localBorder,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        alignment: pw.Alignment.center,
                        textAlign: pw.TextAlign.center,
                      ),

                      // Cellule 2 : DÉSIGNATION (centré)
                      PdfReportStyles.buildGroupedCellWidget(
                        currentIndex: currentEquipRowIdx,
                        totalRows: totalEquipItems,
                        text: equipGroup.equipementName.isNotEmpty
                            ? equipGroup.equipementName
                            : (o.equipementName.isNotEmpty && o.equipementName != '-' ? o.equipementName : '-'),
                        style: pw.TextStyle(font: fontBold, fontSize: 8.0, color: PdfReportStyles.headerColor),
                        border: equipBorder,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                        alignment: pw.Alignment.center,
                        textAlign: pw.TextAlign.center,
                      ),

                      // Cellule 3 : POINT DE VÉRIFICATION (centré)
                      pw.Container(
                        decoration: pw.BoxDecoration(border: obsBorder),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          _normalizeText(o.pointVerification),
                          style: pw.TextStyle(font: fontBold, fontSize: 8.0, color: PdfReportStyles.headerColor),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),

                      // Cellule 4 : RÉF. NORMATIVE (centré)
                      pw.Container(
                        decoration: pw.BoxDecoration(border: obsBorder),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          _normalizeText(o.referenceNormative),
                          style: pw.TextStyle(font: fontRegular, fontSize: 8.0),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),

                      // Cellule 5 : CRITICITÉ (centré)
                      pw.Container(
                        decoration: pw.BoxDecoration(border: obsBorder),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          o.criticite,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 8.0,
                            color: PdfReportStyles.getCriticitePdfColor(o.criticite),
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),

                      // Cellule 6 : OBSERVATION (centré)
                      pw.Container(
                        decoration: pw.BoxDecoration(border: obsBorder),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          _normalizeText(o.observation),
                          style: pw.TextStyle(font: fontRegular, fontSize: 8.5),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),

                      // Cellule 7 : PHOTO (centré)
                      pw.Container(
                        decoration: pw.BoxDecoration(border: obsBorder),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          photoLabel,
                          style: pw.TextStyle(
                            font: photoLabel != '-' ? fontBold : fontRegular,
                            fontSize: 8.5,
                            color: photoLabel != '-' ? PdfColor.fromInt(0xFF1D4ED8) : PdfColors.black,
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
        }

        widgets.add(
          pw.Table(
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
            border: const pw.TableBorder(
              left: pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5),
              right: pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5),
              top: pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5),
              bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5),
              verticalInside: pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5),
              horizontalInside: pw.BorderSide.none,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.1), // ZONE
              1: pw.FlexColumnWidth(1.2), // REPÈRE
              2: pw.FlexColumnWidth(1.5), // ÉQUIPEMENT
              3: pw.FlexColumnWidth(2.0), // POINT DE VÉRIFICATION
              4: pw.FlexColumnWidth(1.4), // RÉF. NORMATIVE
              5: pw.FlexColumnWidth(0.9), // CRITICITÉ
              6: pw.FlexColumnWidth(2.9), // OBSERVATION
              7: pw.FlexColumnWidth(1.0), // PHOTO
            },
            children: tableRows,
          ),
        );
        widgets.add(pw.SizedBox(height: 8));
      }
    }

    return widgets;
  }

}
