import 'package:inspec_app/models/pdf/installation_description_pdf_data.dart';
import 'package:inspec_app/services/installation_description_sync_service.dart';
import 'package:inspec_app/services/installation_fields_registry.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

class _PdfRepereSubGroup {
  final String localName;
  final List<InstallationDescriptionPdfRow> rows;

  _PdfRepereSubGroup({
    required this.localName,
    required this.rows,
  });
}

class _PdfZoneGroup {
  final String zoneName;
  final List<_PdfRepereSubGroup> repereGroups;

  _PdfZoneGroup({
    required this.zoneName,
    required this.repereGroups,
  });
}

class _RiskItem {
  final String title;
  final int indentLevel;

  const _RiskItem({required this.title, required this.indentLevel});
}

/// Builder responsable de la Description des Installations (Poste HT/BT, TGBT, Transfos, CPI, Zones à risque)
class PdfDescriptionBuilder {
  static pw.Widget _buildAlimentationSiteMtTable(DescriptionInstallations desc) =>
      buildAlimentationSiteMtTable(desc);

  static List<pw.Widget> _buildInstallationTableFromRows(
    List<InstallationDescriptionPdfRow> rows, {
    required String sectionKey,
  }) => buildInstallationTableFromRows(rows, sectionKey: sectionKey);

  static pw.Widget _buildInstallationTable(
    List<InstallationItem> itemsInput, {
    String? sectionKey,
    List<InstallationItem>? allGes,
  }) => buildInstallationTable(itemsInput, sectionKey: sectionKey, allGes: allGes);

  static pw.Widget _buildCpiTable(List<InstallationItem> cpiItems) =>
      buildCpiTable(cpiItems);

  static String _resolveInstallationValue(
    InstallationItem item,
    String columnHeader,
    String? sectionKey, {
    List<InstallationItem>? allGes,
  }) => resolveInstallationValue(item, columnHeader, sectionKey, allGes: allGes);

  
  static const double fsSmall = PdfReportStyles.fsSmall;
  static const double fsBody = PdfReportStyles.fsBody;
    
  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();

  // ──────────────────────────────────────────────────────────────
  //  DESCRIPTION DES INSTALLATIONS (avec ordre des colonnes)
  // ──────────────────────────────────────────────────────────────

  static List<String> collectRiskZonesAndLocauxForTesting(
    AuditInstallationsElectriques? audit,
  ) {
    return _collectRiskZonesAndLocauxStructured(audit).map((e) => e.title).toList();
  }

  static List<_RiskItem> _collectRiskZonesAndLocauxStructured(
    AuditInstallationsElectriques? audit,
  ) {
    final items = <_RiskItem>[];
    if (audit == null) return items;

    String formatZone(String name) =>
        name.toLowerCase().startsWith('zone') ? name : 'Zone $name';
    String formatLocal(String name) =>
        name.toLowerCase().startsWith('local') || name.toLowerCase().startsWith('salle')
            ? name
            : 'Local $name';

    // 1. Locaux MT directs (hors zone)
    for (final local in audit.moyenneTensionLocaux) {
      if (local.isRiskZone) {
        items.add(_RiskItem(title: formatLocal(local.nom), indentLevel: 0));
      }
    }

    // 2. Zones MT et leurs locaux à risque
    for (final zone in audit.moyenneTensionZones) {
      final riskLocaux = zone.locaux.where((l) => l.isRiskZone).toList();
      if (zone.isRiskZone) {
        items.add(_RiskItem(title: formatZone(zone.nom), indentLevel: 0));
        for (final local in riskLocaux) {
          items.add(_RiskItem(title: formatLocal(local.nom), indentLevel: 1));
        }
      } else {
        for (final local in riskLocaux) {
          items.add(_RiskItem(title: formatLocal(local.nom), indentLevel: 0));
        }
      }
    }

    // 3. Zones BT et leurs locaux à risque
    for (final zone in audit.basseTensionZones) {
      final riskLocaux = zone.locaux.where((l) => l.isRiskZone).toList();
      if (zone.isRiskZone) {
        items.add(_RiskItem(title: formatZone(zone.nom), indentLevel: 0));
        for (final local in riskLocaux) {
          items.add(_RiskItem(title: formatLocal(local.nom), indentLevel: 1));
        }
      } else {
        for (final local in riskLocaux) {
          items.add(_RiskItem(title: formatLocal(local.nom), indentLevel: 0));
        }
      }
    }

    return items;
  }

  static List<pw.Widget> buildDescriptionInstallationsMulti(
    DescriptionInstallations? desc,
    AuditInstallationsElectriques? audit,
    Map<String, int> trackedPages, {
    int offset = 0,
  }) {
    final widgets = <pw.Widget>[];
    widgets.add(
      PageTracker(
        key: 'description',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.sectionBox('DESCRIPTION DES INSTALLATIONS'),
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    if (desc == null && audit == null) {
      widgets.add(PdfReportStyles.bodyText('Aucune donnée disponible.'));
      return widgets;
    }

    final pdfData = InstallationDescriptionPdfData.fromDescription(
      desc: desc,
      audit: audit,
    );
    final safeDesc = desc ?? DescriptionInstallations.create('');

    int descBodyIdx = 1;

    widgets.add(pw.NewPage(freeSpace: 110));
    widgets.add(
      PageTracker(
        key: 'desc_alim_site_mt',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle(
          '${descBodyIdx++}. Alimentation du site Moyen Tension',
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(_buildAlimentationSiteMtTable(safeDesc));
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(pw.NewPage(freeSpace: 110));
    widgets.add(
      PageTracker(
        key: 'desc_mt',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle(
          '${descBodyIdx++}. Caractéristiques de l\'alimentation moyenne tension',
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.addAll(_buildInstallationTableFromRows(pdfData.mtRows, sectionKey: 'MT'));
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(pw.NewPage(freeSpace: 110));
    widgets.add(
      PageTracker(
        key: 'desc_bt',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle(
          '${descBodyIdx++}. Caractéristiques de l\'alimentation basse tension sortie transformateur',
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.addAll(_buildInstallationTableFromRows(pdfData.btRows, sectionKey: 'BT'));
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(pw.NewPage(freeSpace: 110));
    widgets.add(
      PageTracker(
        key: 'desc_ge',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle(
          '${descBodyIdx++}. Caractéristiques du groupe électrogène',
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      _buildInstallationTable(
        safeDesc.groupeElectrogene,
        sectionKey: 'GROUPE',
        allGes: safeDesc.groupeElectrogene,
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(pw.NewPage(freeSpace: 110));
    widgets.add(
      PageTracker(
        key: 'desc_carburant',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle(
          '${descBodyIdx++}. Alimentation du groupe électrogène en carburant',
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      _buildInstallationTable(
        safeDesc.alimentationCarburant,
        sectionKey: 'CARBURANT',
        allGes: safeDesc.groupeElectrogene,
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(pw.NewPage(freeSpace: 110));
    widgets.add(
      PageTracker(
        key: 'desc_inverseur',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle(
          '${descBodyIdx++}. Caractéristiques de l\'inverseur',
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      _buildInstallationTable(
        safeDesc.inverseur,
        sectionKey: 'INVERSEUR',
        allGes: safeDesc.groupeElectrogene,
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(pw.NewPage(freeSpace: 110));
    widgets.add(
      PageTracker(
        key: 'desc_stabilisateur',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle(
          '${descBodyIdx++}. Caractéristiques du stabilisateur',
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(
      _buildInstallationTable(
        safeDesc.stabilisateur,
        sectionKey: 'STABILISATEUR',
      ),
    );
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(pw.NewPage(freeSpace: 110));
    widgets.add(
      PageTracker(
        key: 'desc_onduleurs',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle(
          '${descBodyIdx++}. Caractéristiques des onduleurs',
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(_buildInstallationTable(safeDesc.onduleurs, sectionKey: 'ONDULEUR'));
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(pw.NewPage(freeSpace: 50));
    widgets.add(
      PageTracker(
        key: 'desc_regime_neutre',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle('${descBodyIdx++}. Régime de neutre'),
      ),
    );

    final String rawRegime = safeDesc.regimeNeutre?.trim() ?? '';
    if (rawRegime.isEmpty ||
        rawRegime.toLowerCase() == 'non renseigné' ||
        rawRegime.toLowerCase() == 'absent') {
      widgets.add(PdfReportStyles.bodyText('- absent'));
    } else {
      final items = rawRegime
          .split(RegExp(r'[,/;\n]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (items.isEmpty) {
        widgets.add(PdfReportStyles.bodyText('- absent'));
      } else {
        for (final item in items) {
          String displayItem = item;
          if (item == 'TN' &&
              safeDesc.regimeNeutreDetail != null &&
              safeDesc.regimeNeutreDetail!.isNotEmpty) {
            displayItem = 'TN (TN-${safeDesc.regimeNeutreDetail})';
          }
          widgets.add(PdfReportStyles.bodyText('- $displayItem'));
        }
      }
    }
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(pw.NewPage(freeSpace: 110));
    widgets.add(
      PageTracker(
        key: 'desc_cpi',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle(
          '${descBodyIdx++}. Caractéristiques du Contrôleur Permanent d\'Isolement (CPI)',
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 4));
    widgets.add(_buildCpiTable(safeDesc.cpi));
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(pw.NewPage(freeSpace: 50));
    widgets.add(
      PageTracker(
        key: 'desc_eclairage',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle('${descBodyIdx++}. Eclairage de sécurité'),
      ),
    );
    final String rawEclairage = safeDesc.eclairageSecurite?.trim() ?? '';
    final String eclairageDisplay = (rawEclairage.isEmpty || rawEclairage.toLowerCase() == 'non renseigné' || rawEclairage.toLowerCase() == 'absent') ? 'absent' : rawEclairage;
    widgets.add(PdfReportStyles.bodyText('- $eclairageDisplay'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(pw.NewPage(freeSpace: 50));
    widgets.add(
      PageTracker(
        key: 'desc_modifications',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle(
          '${descBodyIdx++}. Modifications apportées aux installations',
        ),
      ),
    );
    final String rawMods = safeDesc.modificationsInstallations?.trim() ?? '';
    final String modsDisplay = (rawMods.isEmpty || rawMods.toLowerCase() == 'non renseigné' || rawMods.toLowerCase() == 'sans objet' || rawMods.toLowerCase() == 'absent') ? 'absent' : rawMods;
    widgets.add(PdfReportStyles.bodyText(modsDisplay));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(pw.NewPage(freeSpace: 50));
    widgets.add(
      PageTracker(
        key: 'desc_note_calcul',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle(
          '${descBodyIdx++}. Note de calcul des installations électriques',
        ),
      ),
    );
    final String rawNote = safeDesc.noteCalcul?.trim() ?? '';
    final String noteDisplay = (rawNote.isEmpty || rawNote.toLowerCase() == 'non renseigné' || rawNote.toLowerCase() == 'non transmis' || rawNote.toLowerCase() == 'absent') ? 'absent' : rawNote;
    widgets.add(PdfReportStyles.bodyText('- $noteDisplay'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(pw.NewPage(freeSpace: 50));
    widgets.add(
      PageTracker(
        key: 'desc_paratonnerre',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle('${descBodyIdx++}. Présence de paratonnerre'),
      ),
    );
    widgets.add(
      PdfReportStyles.bodyText('Présence : ${safeDesc.presenceParatonnerre ?? 'NON'}'),
    );
    if (safeDesc.analyseRisqueFoudre != null &&
        safeDesc.analyseRisqueFoudre!.isNotEmpty) {
      widgets.add(
        PdfReportStyles.bodyText('Analyse risque foudre : ${safeDesc.analyseRisqueFoudre}'),
      );
    }
    if (safeDesc.etudeTechniqueFoudre != null &&
        safeDesc.etudeTechniqueFoudre!.isNotEmpty) {
      widgets.add(
        PdfReportStyles.bodyText('Etude technique foudre : ${safeDesc.etudeTechniqueFoudre}'),
      );
    }
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(pw.NewPage(freeSpace: 50));
    widgets.add(
      PageTracker(
        key: 'desc_registre',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle('${descBodyIdx++}. Registre de sécurité'),
      ),
    );
    final String rawReg = safeDesc.registreSecurite?.trim() ?? '';
    final String regDisplay = (rawReg.isEmpty || rawReg.toLowerCase() == 'non renseigné' || rawReg.toLowerCase() == 'non transmis' || rawReg.toLowerCase() == 'absent') ? 'absent' : rawReg;
    widgets.add(PdfReportStyles.bodyText('- $regDisplay'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(pw.NewPage(freeSpace: 50));
    widgets.add(
      PageTracker(
        key: 'desc_locaux_risques',
        registry: trackedPages,
        offset: offset,
        child: PdfReportStyles.subTitle('${descBodyIdx++}. Zones et Locaux à risque'),
      ),
    );

    final riskItems = _collectRiskZonesAndLocauxStructured(audit);
    if (riskItems.isEmpty) {
      widgets.add(PdfReportStyles.bodyText('Rien \u00e0 signaler.'));
    } else {
      for (final item in riskItems) {
        if (item.indentLevel == 0) {
          widgets.add(PdfReportStyles.bodyText('\u2022 ${item.title}'));
        } else {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 16),
              child: PdfReportStyles.bodyText('- ${item.title}'),
            ),
          );
        }
      }
    }

    return widgets;
  }

  static pw.Widget buildInstallationTable(
    List<InstallationItem> itemsInput, {
    String? sectionKey,
    List<InstallationItem>? allGes,
  }) {
    final items = itemsInput.isNotEmpty
        ? (List<InstallationItem>.from(itemsInput)..sort((a, b) => a.createdAt.compareTo(b.createdAt)))
        : [InstallationItem(data: {})];

    // Collecter tous les champs dans l'ORDRE D'APPARITION (pas de sort !)
    final fieldOrder = <String>[];
    final seen = <String>{};

    for (var it in items) {
      for (var key in it.data.keys) {
        if (it.data[key]!.isNotEmpty && !seen.contains(key)) {
          seen.add(key);
          fieldOrder.add(key);
        }
      }
    }

    // Si on a un ordre imposé, on restreint STRICTEMENT à celui-ci (excluant N°)
    List<String> finalOrder = [];
    if (sectionKey != null && PdfReportStyles.columnOrderBySection.containsKey(sectionKey)) {
      finalOrder = PdfReportStyles.columnOrderBySection[sectionKey]!
          .where((col) => col != 'N\u00B0' && col != 'N°')
          .toList();
    } else {
      finalOrder = fieldOrder;
    }

    if (finalOrder.isEmpty) {
      finalOrder = ['Description'];
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FixedColumnWidth(18),
        ...{
          for (var i = 1; i <= finalOrder.length; i++)
            i: const pw.FlexColumnWidth(1),
        },
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            PdfReportStyles.cell('N\u00B0', isHeader: true, centered: true),
            ...finalOrder.map((c) => PdfReportStyles.cell(c, isHeader: true, centered: true)),
          ],
        ),
        ...items.asMap().entries.map(
          (e) => pw.TableRow(
            decoration: pw.BoxDecoration(
              color: e.key.isOdd ? PdfReportStyles.tableRowAlt : PdfColors.white,
            ),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 3,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  '${e.key + 1}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: fsSmall,
                    color: PdfReportStyles.headerColor,
                  ),
                ),
              ),
              ...finalOrder.map((key) {
                final raw = _resolveInstallationValue(e.value, key, sectionKey, allGes: allGes);
                final unit = _unitForField(key);
                final display = PdfReportStyles.stripUnitFromValue(raw, unit);
                return PdfReportStyles.cell(display, isHeader: false, centered: true);
              }),
            ],
          ),
        ),
      ],
    );
  }

  static List<pw.Widget> buildInstallationTableFromRows(
    List<InstallationDescriptionPdfRow> rows, {
    required String sectionKey,
  }) {
    final finalOrder = (PdfReportStyles.columnOrderBySection[sectionKey] ?? [])
        .where((col) => col != 'N\u00B0' && col != 'N°')
        .toList();

    // Ordre des colonnes : ZONE | REPÈRE | N° | [Colonnes techniques...]
    final headers = ['ZONE', 'REP\u00C8RE', 'N\u00B0', ...finalOrder];

    final headerColumnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(1.2), // ZONE
      1: const pw.FlexColumnWidth(1.6), // REPÈRE
      2: const pw.FixedColumnWidth(18), // N°
      for (var i = 0; i < finalOrder.length; i++)
        i + 3: const pw.FlexColumnWidth(1.0),
    };

    if (rows.isEmpty) {
      return [
        pw.Table(
          border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
          columnWidths: headerColumnWidths,
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
              children: headers.map((c) => PdfReportStyles.cell(c, isHeader: true, centered: true)).toList(),
            ),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.white),
              children: [
                PdfReportStyles.cell('-', isHeader: false, centered: true),
                PdfReportStyles.cell('-', isHeader: false, centered: true),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    '1',
                    style: pw.TextStyle(font: fontBold, fontSize: fsSmall, color: PdfReportStyles.headerColor),
                  ),
                ),
                ...finalOrder.map((_) => PdfReportStyles.cell('-', isHeader: false, centered: true)),
              ],
            ),
          ],
        ),
      ];
    }

    // Regrouper à 2 niveaux : Zone -> Repère -> Éléments
    final zoneGroups = <_PdfZoneGroup>[];
    for (final row in rows) {
      final rawZone = row.zoneName.trim();
      final normZone = rawZone.isNotEmpty ? rawZone : '';
      final rawLoc = row.localName.trim();
      final normLoc = rawLoc.isNotEmpty ? rawLoc : '-';

      if (zoneGroups.isNotEmpty && zoneGroups.last.zoneName == normZone) {
        final currentZoneGroup = zoneGroups.last;
        if (currentZoneGroup.repereGroups.isNotEmpty &&
            currentZoneGroup.repereGroups.last.localName == normLoc) {
          currentZoneGroup.repereGroups.last.rows.add(row);
        } else {
          currentZoneGroup.repereGroups.add(
            _PdfRepereSubGroup(localName: normLoc, rows: [row]),
          );
        }
      } else {
        zoneGroups.add(
          _PdfZoneGroup(
            zoneName: normZone,
            repereGroups: [
              _PdfRepereSubGroup(localName: normLoc, rows: [row]),
            ],
          ),
        );
      }
    }

    final allTableRows = <pw.TableRow>[];

    // En-tête du tableau
    allTableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
        children: headers.map((c) => PdfReportStyles.cell(c, isHeader: true, centered: true)).toList(),
      ),
    );

    int globalRowIndex = 1;
    int globalItemNumber = 1;

    for (final zoneGroup in zoneGroups) {
      final totalZoneRows =
          zoneGroup.repereGroups.fold<int>(0, (sum, g) => sum + g.rows.length);

      int zoneItemIndex = 0;

      for (int rIdx = 0; rIdx < zoneGroup.repereGroups.length; rIdx++) {
        final repereGroup = zoneGroup.repereGroups[rIdx];
        final repereCount = repereGroup.rows.length;

        for (int i = 0; i < repereCount; i++) {
          final row = repereGroup.rows[i];
          final currentZoneItemIdx = zoneItemIndex++;
          final currentRepereItemIdx = i;

          final itemNumber = globalItemNumber++;
          final rowNum = globalRowIndex++;
          final isOdd = rowNum % 2 == 1;
          final rowBg = isOdd ? PdfReportStyles.tableRowAlt : PdfColors.white;

          final isStartOfZone = (currentZoneItemIdx == 0 && rowNum > 0);
          final isStartOfRepere = (currentRepereItemIdx == 0 && currentZoneItemIdx > 0);

          final isEndOfZone = (currentZoneItemIdx == totalZoneRows - 1);
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
              children: [
                // Cellule 0 : Nom de la ZONE
                PdfReportStyles.buildGroupedCellWidget(
                  currentIndex: currentZoneItemIdx,
                  totalRows: totalZoneRows,
                  text: zoneGroup.zoneName.toUpperCase(),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: fsSmall,
                    color: PdfReportStyles.headerColor,
                  ),
                  border: zoneBorder,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                ),

                // Cellule 1 : Nom du REPÈRE / LOCAL
                PdfReportStyles.buildGroupedCellWidget(
                  currentIndex: currentRepereItemIdx,
                  totalRows: repereCount,
                  text: repereGroup.localName.toUpperCase(),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: fsSmall,
                    color: PdfReportStyles.headerColor,
                  ),
                  border: repereBorder,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                ),

                // Cellule 2 : N° d'équipement/élément (Déplacé après REPÈRE !)
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: rowBg,
                    border: itemBorder,
                  ),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    '$itemNumber',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: fsSmall,
                      color: PdfReportStyles.headerColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                // Cellules 3..N : Colonnes de données avec couleur de ligne alternée et bordures internes
                ...finalOrder.map((key) {
                  final raw = row.getValueForColumn(key, sectionKey);
                  final unit = _unitForField(key);
                  final display = PdfReportStyles.stripUnitFromValue(raw, unit);
                  return pw.Container(
                    decoration: pw.BoxDecoration(
                      color: rowBg,
                      border: itemBorder,
                    ),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      display,
                      style: pw.TextStyle(font: fontRegular, fontSize: fsSmall),
                      textAlign: pw.TextAlign.center,
                    ),
                  );
                }),
              ],
            ),
          );
        }
      }
    }

    return [
      pw.Table(
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
        border: pw.TableBorder(
          left: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
          right: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
          top: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
          bottom: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
          verticalInside: pw.BorderSide(color: PdfReportStyles.borderColor, width: 0.4),
          horizontalInside: pw.BorderSide.none,
        ),
        columnWidths: headerColumnWidths,
        children: allTableRows,
      ),
    ];
  }

  /// Résolution tolérante des valeurs pour un champ de colonne PDF donné
  static String resolveInstallationValue(
    InstallationItem item,
    String columnHeader,
    String? sectionKey, {
    List<InstallationItem>? allGes,
  }) {
    if (item.data.isEmpty) return '-';

    // Résolution dynamique pour Identification du GE
    final targetNorm = InstallationFieldsRegistry.normalizeKey(columnHeader);
    if (targetNorm == 'identification du ge' || targetNorm == 'identification ge') {
      if (allGes != null && item.data.containsKey('geId') && item.data['geId']!.isNotEmpty) {
        final geId = item.data['geId']!;
        InstallationItem? foundGe;
        for (final g in allGes) {
          if (g.itemId == geId || g.id == geId) {
            foundGe = g;
            break;
          }
        }
        if (foundGe != null) {
          final idVal = foundGe.data['Identification']?.trim();
          if (idVal != null && idVal.isNotEmpty) return idVal;
          final marque = foundGe.data['Marque']?.trim() ?? '';
          if (marque.isNotEmpty) return 'GE $marque';
        }
      }
      final directVal = item.data['Identification du GE']?.trim();
      if (directVal != null && directVal.isNotEmpty) return directVal;
    }

    // 1. Déterminer le dictionnaire d'alias à utiliser selon la section
    Map<String, String> aliases = {};
    if (sectionKey == 'MT') {
      aliases = InstallationDescriptionSyncService.celluleAliases;
    } else if (sectionKey == 'BT') {
      aliases = InstallationDescriptionSyncService.transfoAliases;
    }

    // 2. Tenter la résolution tolérante via InstallationDescriptionSyncService.getFieldWithAlias
    final val = InstallationDescriptionSyncService.getFieldWithAlias(
      item.data,
      columnHeader,
      aliases,
    );
    if (val.isNotEmpty) return val;

    // 3. Fallback direct sur comparaison de clé normalisée
    for (final entry in item.data.entries) {
      if (entry.value.trim().isEmpty) continue;
      final entryNorm = InstallationFieldsRegistry.normalizeKey(entry.key);
      if (entryNorm == targetNorm ||
          entryNorm.contains(targetNorm) ||
          targetNorm.contains(entryNorm)) {
        return entry.value.trim();
      }
    }

    return '-';
  }

  static String unitForField(String fieldKey) => _unitForField(fieldKey);

  static String _unitForField(String fieldKey) {
    if (fieldKey.contains('(')) return '';
    const units = {
      'Calibre Du Disjoncteur': 'A',
      'CALIBRE DU DISJONCTEUR': 'A',
      'Calibre Du Disjoncteur Sortie Transformateur': 'A',
      'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR': 'A',
      'Section Du Cable': 'mm²',
      'SECTION DU CABLE': 'mm²',
      'SECTION DU CABLE(mm2)': 'mm²',
      'Puissance Transformateur': 'kVA',
      'PUISSANCE TRANSFORMATEUR (KVA)': 'kVA',
      'PUISSANCE TRANSFORMATEUR': 'kVA',
      'Puissance (Kva)': 'kVA',
      'PUISSANCE (KVA)': 'kVA',
      'Intensité nominale': 'A',
      'INTENSITE NOMINALE': 'A',
      'Intensite': 'A',
      'INTENSITE': 'A',
      'Tension assignée': 'kV',
      'TENSION ASSIGNEE(KV)': 'kV',
      'Tension de service': 'kV',
      'TENSION DE SERVICE': 'kV',
      'TENSION DE SERVICE (KV)': 'kV',
      'TENSION DE SERVICE (kV)': 'kV',
      'PCC amont': 'MVA',
      'PCC AMONT EN MVA': 'MVA',
      'IK3 MAX': 'kA',
      'IK3 MAX(KA)': 'kA',
      'Entree': 'V',
      'ENTREE': 'V',
      'Sortie': 'V',
      'SORTIE': 'V',
      'Capacite': 'L',
      'CAPACITE': 'L',
    };
    if (units.containsKey(fieldKey)) return units[fieldKey]!;
    if (units.containsKey(fieldKey.toUpperCase())) {
      return units[fieldKey.toUpperCase()]!;
    }
    final norm = InstallationFieldsRegistry.normalizeKey(fieldKey);
    for (var entry in units.entries) {
      if (InstallationFieldsRegistry.normalizeKey(entry.key) == norm) {
        return entry.value;
      }
    }
    return '';
  }



  static pw.Widget buildAlimentationSiteMtTable(DescriptionInstallations desc) {
    String safeVal(String? val) {
      if (val == null || val.trim().isEmpty) return '-';
      return val.trim();
    }

    final natureReseau = safeVal(desc.natureReseauAlimentationSite);
    final tensionRaw = desc.tensionAlimentationSite?.trim();
    final tension = (tensionRaw != null && tensionRaw.isNotEmpty)
        ? PdfReportStyles.stripUnitFromValue(tensionRaw, 'kV')
        : '-';
    final nombre = safeVal(desc.nombreAlimentationSite);
    final presenceIacm = safeVal(desc.presenceIacmAlimentationSite);

    final headers = [
      'N°',
      'Nature du réseau',
      'Tension d\'alimentation (kV)',
      'Nombre d\'alimentation',
      'Présence de l\'IACM',
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
      columnWidths: const {
        0: pw.FixedColumnWidth(18),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: headers
              .map((h) => PdfReportStyles.cell(h, isHeader: true, centered: true))
              .toList(),
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '1',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: fsSmall,
                  color: PdfReportStyles.headerColor,
                ),
              ),
            ),
            PdfReportStyles.cell(natureReseau, isHeader: false, centered: true),
            PdfReportStyles.cell(tension, isHeader: false, centered: true),
            PdfReportStyles.cell(nombre, isHeader: false, centered: true),
            PdfReportStyles.cell(presenceIacm, isHeader: false, centered: true),
          ],
        ),
      ],
    );
  }


  static pw.Widget buildCpiTable(List<InstallationItem> cpiItems) {
    final columns =
        PdfReportStyles.columnOrderBySection['CPI'] ??
        [
          'N\u00B0',
          'MARQUE',
          'TYPE',
          'N\u00B0 SÉRIE',
          'RÉGIME DE NEUTRE SURVEILLÉ',
          'SEUIL DE RÉGLAGE (kΩ)',
          'REPORT D\'ALARME',
          'ANNÉE DE FABRICATION',
        ];

    final dataCols = columns.where((c) => c != 'N\u00B0' && c != 'N°').toList();
    final itemsToRender = cpiItems.isNotEmpty
        ? [cpiItems.last]
        : [InstallationItem(data: {})];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FixedColumnWidth(18),
        ...{
          for (var i = 1; i <= dataCols.length; i++)
            i: const pw.FlexColumnWidth(1),
        },
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
          children: [
            PdfReportStyles.cell('N\u00B0', isHeader: true, centered: true),
            ...dataCols.map((c) => PdfReportStyles.cell(c, isHeader: true, centered: true)),
          ],
        ),
        ...itemsToRender.asMap().entries.map((e) {
          final idx = e.key;
          final item = e.value;
          final data = item.data;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: idx.isOdd ? PdfReportStyles.tableRowAlt : PdfColors.white,
            ),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 3,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  '${idx + 1}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: fsSmall,
                    color: PdfReportStyles.headerColor,
                  ),
                ),
              ),
              ...dataCols.map((key) {
                String val;
                if (key == 'RÉGIME DE NEUTRE SURVEILLÉ') {
                  val = 'IT';
                } else {
                  final raw = data[key]?.trim();
                  val = (raw != null && raw.isNotEmpty && raw.toLowerCase() != 'non renseigné') ? raw : 'absent';
                }
                return PdfReportStyles.cell(val, isHeader: false, centered: true);
              }),
            ],
          );
        }),
      ],
    );
  }

}
