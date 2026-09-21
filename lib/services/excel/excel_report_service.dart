// lib/services/excel/excel_report_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/pdf/builders/pdf_equipements_synthesis_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_observations_recap_builder.dart';

/// Service responsable de la génération du rapport Excel (.xlsx) professionnel
/// aligné sur les données et la logique métier du rapport PDF.
class ExcelReportService {
  // Palette de couleurs institutionnelle KES
  static const String _colorNavy = '#1E3A8A'; // En-tête principal & titres & séparations Zone
  static const String _colorAccentBlue = '#2563EB'; // Sous-titres & sections
  static const String _colorHeaderBg = '#1E3A8A'; // Fond d'en-tête de tableau
  static const String _colorHeaderFont = '#FFFFFF'; // Texte d'en-tête blanc
  static const String _colorBorder = '#CBD5E1'; // Bordure fine douce
  static const String _colorZebra = '#F8FAFC'; // Ligne alternée
  static const String _colorWhite = '#FFFFFF'; // Ligne blanche
  static const String _colorMuted = '#64748B'; // Texte secondaire
  static const String _colorSepRepere = '#475569'; // Séparation Repère (ardoise foncée / slate 600)
  static const String _colorSepEquip = '#94A3B8'; // Séparation Désignation (ardoise moyenne / slate 400)

  /// Génère le nom de fichier officiel pour le rapport Excel de Vérification Électrique.
  /// Format : `Rapport_Verif_elec_<client>_<site>_<année>_<timestamp>.xlsx`
  static String buildExcelReportFileName(
    String nomClient, {
    String? nomSite,
    DateTime? date,
    int? timestamp,
  }) {
    final now = date ?? DateTime.now();
    final year = now.year;
    final ts = timestamp ?? now.millisecondsSinceEpoch;
    final sanitizedClient =
        nomClient.trim().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final sanitizedSite = nomSite != null && nomSite.trim().isNotEmpty
        ? nomSite.trim().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        : '';
    final sitePart = sanitizedSite.isNotEmpty ? '_$sanitizedSite' : '';
    return 'Rapport_Verif_elec_$sanitizedClient${sitePart}_${year}_$ts.xlsx';
  }

  /// Génère le fichier Excel pour une mission donnée.
  static Future<File?> generateMissionReport(String missionId) async {
    try {
      final mission = HiveService.getMissionById(missionId);
      if (mission == null) return null;

      final audit = HiveService.getAuditInstallationsByMissionId(missionId);
      final description =
          HiveService.getDescriptionInstallationsByMissionId(missionId);

      final bytes = generateWorkbookBytes(
        mission: mission,
        audit: audit,
        description: description,
        generationDate: DateTime.now(),
      );

      final tempDir = await getTemporaryDirectory();
      final fileName = buildExcelReportFileName(
        mission.nomClient,
        nomSite: mission.nomSite,
      );
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      if (kDebugMode) {
        print('✅ Rapport Excel généré: ${file.path} (${bytes.length} octets)');
      }
      return file;
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Erreur génération rapport Excel: $e\n$st');
      }
      rethrow;
    }
  }

  /// Construit le classeur Excel complet (2 feuilles) et retourne les octets.
  static List<int> generateWorkbookBytes({
    required Mission mission,
    AuditInstallationsElectriques? audit,
    DescriptionInstallations? description,
    DateTime? generationDate,
  }) {
    final dateGen = generationDate ?? DateTime.now();
    final reportDateFormatted = DateFormat('dd/MM/yyyy').format(dateGen);

    // Initialisation du Workbook Syncfusion (2 feuilles)
    final workbook = xlsio.Workbook(2);

    // FEUILLE 1 : Annexe des équipements
    final sheet1 = workbook.worksheets[0];
    sheet1.name = 'Annexe des équipements';
    _buildEquipementsSheet(
      sheet: sheet1,
      mission: mission,
      audit: audit,
      description: description,
      reportDateStr: reportDateFormatted,
    );

    // FEUILLE 2 : Annexe des observations
    final sheet2 = workbook.worksheets[1];
    sheet2.name = 'Annexe des observations';
    _buildObservationsSheet(
      sheet: sheet2,
      mission: mission,
      audit: audit,
      reportDateStr: reportDateFormatted,
    );

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return bytes;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FEUILLE 1 : ANNEXE DES ÉQUIPEMENTS
  // ══════════════════════════════════════════════════════════════════════════

  static void _buildEquipementsSheet({
    required xlsio.Worksheet sheet,
    required Mission mission,
    AuditInstallationsElectriques? audit,
    DescriptionInstallations? description,
    required String reportDateStr,
  }) {
    // 9 colonnes exactes pour MT (7 colonnes PDF + 2 colonnes supplémentaires Excel) :
    // Zone | Repère | N° | Désignation | Type | Vérifié | Observation | Date de réserve | Date de rapport
    final headersMT = [
      'Zone',
      'Repère',
      'N°',
      'Désignation',
      'Type',
      'Vérifié',
      'Observation',
      'Date de réserve',
      'Date de rapport',
    ];

    // 11 colonnes exactes pour BT (9 colonnes PDF répliquées + 2 colonnes supplémentaires Excel) :
    // Zone | Repère | N° | Désignation | Type | Vérifié | Présence du parafoudre | Vérification thermo | Observation | Date de réserve | Date de rapport
    final headersBT = [
      'Zone',
      'Repère',
      'N°',
      'Désignation',
      'Type',
      'Vérifié',
      'Présence du parafoudre',
      'Vérification thermo',
      'Observation',
      'Date de réserve',
      'Date de rapport',
    ];

    // Largeurs de colonnes optimisées (en caractères) pour les 11 colonnes de la feuille
    final colWidths = [
      18.0, // Col 1 : Zone
      22.0, // Col 2 : Repère
      8.0,  // Col 3 : N°
      30.0, // Col 4 : Désignation
      16.0, // Col 5 : Type
      14.0, // Col 6 : Vérifié
      22.0, // Col 7 : Présence du parafoudre (BT) / Observation (MT)
      20.0, // Col 8 : Vérification thermo (BT) / Date de réserve (MT)
      18.0, // Col 9 : Observation (BT) / Date de rapport (MT)
      18.0, // Col 10 : Date de réserve (BT)
      18.0, // Col 11 : Date de rapport (BT)
    ];
    for (int i = 0; i < colWidths.length; i++) {
      sheet.getRangeByIndex(1, i + 1).columnWidth = colWidths[i];
    }

    int currentRow = 1;

    // 1. Grand bandeau de titre KES (fusionné sur la largeur maximale de 11 colonnes)
    final titleRange = sheet.getRangeByIndex(currentRow, 1, currentRow, 11);
    titleRange.merge();
    titleRange.setText(
      'SYNTHÈSE RÉCAPITULATIVE DES ÉQUIPEMENTS — ${mission.nomClient.toUpperCase()}${mission.nomSite != null && mission.nomSite!.isNotEmpty ? ' (${mission.nomSite})' : ''}',
    );
    titleRange.rowHeight = 32;
    _styleBanner(titleRange, _colorNavy, 12);
    currentRow += 2; // Ligne vide de respiration

    // 2. TABLEAU 1 : Équipements Moyenne Tension (MT) - 9 colonnes (7 PDF + 2 Excel)
    final equipementsMT =
        PdfEquipementsSynthesisBuilder.collectEquipementsMT(audit);
    currentRow = _renderEquipementsTable(
      sheet: sheet,
      items: equipementsMT,
      sectionTitle: '1. ÉQUIPEMENTS MOYENNE TENSION',
      headers: headersMT,
      startRow: currentRow,
      reportDateStr: reportDateStr,
      isMT: true,
    );

    currentRow += 2; // Séparation entre les 2 tableaux

    // 3. TABLEAU 2 : Équipements Basse Tension (BT) - 11 colonnes (9 PDF + 2 Excel)
    final equipementsBT =
        PdfEquipementsSynthesisBuilder.collectEquipementsBT(audit, description);
    currentRow = _renderEquipementsTable(
      sheet: sheet,
      items: equipementsBT,
      sectionTitle: '2. ÉQUIPEMENTS BASSE TENSION',
      headers: headersBT,
      startRow: currentRow,
      reportDateStr: reportDateStr,
      isMT: false,
    );

    // 4. TABLEAU 3 : Équipements aux sources d'alimentation non identifiées
    if (audit != null) {
      final unknownSources =
          PdfEquipementsSynthesisBuilder.collectUnknownSources(audit);
      if (unknownSources.isNotEmpty) {
        currentRow += 2;
        final unknownHeaders = [
          'Zone',
          'Repère',
          'N°',
          'Désignation',
          'Type',
          'Source',
        ];
        _renderUnknownSourcesTable(
          sheet: sheet,
          items: unknownSources,
          sectionTitle:
              '3. ÉQUIPEMENTS AUX SOURCES D\'ALIMENTATION NON IDENTIFIÉES',
          headers: unknownHeaders,
          startRow: currentRow,
        );
      }
    }
  }

  static int _renderEquipementsTable({
    required xlsio.Worksheet sheet,
    required List<PdfEquipementItem> items,
    required String sectionTitle,
    required List<String> headers,
    required int startRow,
    required String reportDateStr,
    bool isMT = false,
  }) {
    int currentRow = startRow;
    final int totalCols = headers.length;

    // Titre de section (MT sur 9 colonnes ou BT sur 11 colonnes)
    final sectionRange = sheet.getRangeByIndex(currentRow, 1, currentRow, totalCols);
    sectionRange.merge();
    sectionRange.setText(sectionTitle);
    sectionRange.rowHeight = 24;
    _styleBanner(sectionRange, _colorAccentBlue, 11);
    currentRow++;

    // Ligne d'en-tête de tableau
    for (int col = 1; col <= headers.length; col++) {
      final cell = sheet.getRangeByIndex(currentRow, col);
      cell.setText(headers[col - 1]);
      _styleHeaderCell(cell);
    }
    sheet.getRangeByIndex(currentRow, 1).rowHeight = 26;
    currentRow++;

    if (items.isEmpty) {
      final emptyRange = sheet.getRangeByIndex(currentRow, 1, currentRow, totalCols);
      emptyRange.merge();
      emptyRange.setText('Aucun équipement recensé.');
      emptyRange.rowHeight = 22;
      _styleEmptyRow(emptyRange);
      return currentRow + 1;
    }

    // Regroupement identique au PDF : Zone -> Repère -> Équipements
    final zoneGroups = <PdfEquipementZoneGroup>[];
    for (final eq in items) {
      final normZone = eq.zoneName.trim();
      final normLoc = eq.localName.trim();

      var zGroup = zoneGroups.firstWhere(
        (zg) => zg.zoneName.toLowerCase() == normZone.toLowerCase(),
        orElse: () {
          final zg =
              PdfEquipementZoneGroup(zoneName: normZone, repereGroups: []);
          zoneGroups.add(zg);
          return zg;
        },
      );

      var rGroup = zGroup.repereGroups.firstWhere(
        (rg) => rg.localName.toLowerCase() == normLoc.toLowerCase(),
        orElse: () {
          final rg = PdfEquipementRepereGroup(localName: normLoc, items: []);
          zGroup.repereGroups.add(rg);
          return rg;
        },
      );

      rGroup.items.add(eq);
    }

    for (final zoneGroup in zoneGroups) {
      final bool isNewZone = (zoneGroup != zoneGroups.first);
      final int zoneStartRow = currentRow;
      final int totalZoneItems =
          zoneGroup.repereGroups.fold<int>(0, (sum, g) => sum + g.items.length);

      for (final repereGroup in zoneGroup.repereGroups) {
        final bool isNewRepere =
            (repereGroup != zoneGroup.repereGroups.first);
        final int repereStartRow = currentRow;
        final int repereCount = repereGroup.items.length;
        final String displayRepere = repereGroup.localName.isNotEmpty
            ? repereGroup.localName
            : (zoneGroup.zoneName.isNotEmpty ? zoneGroup.zoneName : '-');

        for (final item in repereGroup.items) {
          final isEven = (currentRow % 2 == 0);
          final bgColor = isEven ? _colorZebra : _colorWhite;

          // Col 1 : Zone
          final cellZone = sheet.getRangeByIndex(currentRow, 1);
          cellZone.setText(
              zoneGroup.zoneName.isNotEmpty ? zoneGroup.zoneName : '-');
          _styleDataCell(cellZone,
              bgColor: bgColor, hAlign: xlsio.HAlignType.center, bold: true);

          // Col 2 : Repère
          final cellRepere = sheet.getRangeByIndex(currentRow, 2);
          cellRepere.setText(displayRepere);
          _styleDataCell(cellRepere,
              bgColor: bgColor, hAlign: xlsio.HAlignType.center, bold: true);

          // Col 3 : N°
          final cellNum = sheet.getRangeByIndex(currentRow, 3);
          final parsedNum = int.tryParse(item.numero);
          if (parsedNum != null) {
            cellNum.setNumber(parsedNum.toDouble());
          } else if (item.numero.isNotEmpty) {
            cellNum.setText(item.numero);
          } else {
            cellNum.setText('-');
          }
          _styleDataCell(cellNum,
              bgColor: bgColor, hAlign: xlsio.HAlignType.center, bold: true);

          // Col 4 : Désignation
          final cellNom = sheet.getRangeByIndex(currentRow, 4);
          cellNom.setText(item.nom);
          _styleDataCell(cellNom,
              bgColor: bgColor, hAlign: xlsio.HAlignType.left, wrapText: true);

          // Col 5 : Type
          final cellType = sheet.getRangeByIndex(currentRow, 5);
          cellType.setText(item.type);
          _styleDataCell(cellType,
              bgColor: bgColor, hAlign: xlsio.HAlignType.center);

          // Col 6 : Vérifié
          final cellVerifie = sheet.getRangeByIndex(currentRow, 6);
          cellVerifie.setText(item.accessible ? 'Oui' : 'Non');
          _styleDataCell(cellVerifie,
              bgColor: bgColor, hAlign: xlsio.HAlignType.center);

          if (isMT) {
            // MT : 7 colonnes PDF + 2 colonnes supplémentaires Excel
            // Col 7 : Observation
            final cellObs = sheet.getRangeByIndex(currentRow, 7);
            cellObs.setText(item.hasObservation);
            _styleDataCell(cellObs,
                bgColor: bgColor, hAlign: xlsio.HAlignType.center);

            // Col 8 : Date de réserve (laisser strictement vide)
            final cellDateRes = sheet.getRangeByIndex(currentRow, 8);
            cellDateRes.setText('');
            _styleDataCell(cellDateRes,
                bgColor: bgColor, hAlign: xlsio.HAlignType.center);

            // Col 9 : Date de rapport (date réelle de génération)
            final cellDateRap = sheet.getRangeByIndex(currentRow, 9);
            cellDateRap.setText(reportDateStr);
            _styleDataCell(cellDateRap,
                bgColor: bgColor, hAlign: xlsio.HAlignType.center);
          } else {
            // BT : 9 colonnes PDF répliquées + 2 colonnes supplémentaires Excel
            // Col 7 : Présence du parafoudre
            final cellPara = sheet.getRangeByIndex(currentRow, 7);
            cellPara.setText(item.presenceParafoudre ?? '-');
            _styleDataCell(cellPara,
                bgColor: bgColor, hAlign: xlsio.HAlignType.center);

            // Col 8 : Vérification thermo
            final cellThermo = sheet.getRangeByIndex(currentRow, 8);
            cellThermo.setText(item.verificationThermo ?? '-');
            _styleDataCell(cellThermo,
                bgColor: bgColor, hAlign: xlsio.HAlignType.center);

            // Col 9 : Observation
            final cellObs = sheet.getRangeByIndex(currentRow, 9);
            cellObs.setText(item.hasObservation);
            _styleDataCell(cellObs,
                bgColor: bgColor, hAlign: xlsio.HAlignType.center);

            // Col 10 : Date de réserve (laisser strictement vide)
            final cellDateRes = sheet.getRangeByIndex(currentRow, 10);
            cellDateRes.setText('');
            _styleDataCell(cellDateRes,
                bgColor: bgColor, hAlign: xlsio.HAlignType.center);

            // Col 11 : Date de rapport (date réelle de génération)
            final cellDateRap = sheet.getRangeByIndex(currentRow, 11);
            cellDateRap.setText(reportDateStr);
            _styleDataCell(cellDateRap,
                bgColor: bgColor, hAlign: xlsio.HAlignType.center);
          }

          sheet.getRangeByIndex(currentRow, 1).rowHeight = 22;

          currentRow++;
        }

        // Renforcement ciblé des bordures de séparation (hiérarchie visuelle)
        if (isNewZone && repereStartRow == zoneStartRow) {
          _applyHorizontalSeparator(
            sheet,
            repereStartRow,
            1,
            totalCols,
            color: _colorNavy,
            lineStyle: xlsio.LineStyle.medium,
          );
        } else if (isNewRepere) {
          _applyHorizontalSeparator(
            sheet,
            repereStartRow,
            2,
            totalCols,
            color: _colorSepRepere,
            lineStyle: xlsio.LineStyle.medium,
          );
        }

        // Fusion verticale dynamique de Repère
        final int repereEndRow = repereStartRow + repereCount - 1;
        if (repereEndRow > repereStartRow) {
          final repereMerge =
              sheet.getRangeByIndex(repereStartRow, 2, repereEndRow, 2);
          repereMerge.merge();
          repereMerge.cellStyle.vAlign = xlsio.VAlignType.center;
          repereMerge.cellStyle.hAlign = xlsio.HAlignType.center;
        }
      }

      // Fusion verticale dynamique de Zone
      final int zoneEndRow = zoneStartRow + totalZoneItems - 1;
      if (zoneEndRow > zoneStartRow) {
        final zoneMerge = sheet.getRangeByIndex(zoneStartRow, 1, zoneEndRow, 1);
        zoneMerge.merge();
        zoneMerge.cellStyle.vAlign = xlsio.VAlignType.center;
        zoneMerge.cellStyle.hAlign = xlsio.HAlignType.center;
      }
    }

    return currentRow;
  }

  static int _renderUnknownSourcesTable({
    required xlsio.Worksheet sheet,
    required List<PdfUnknownSourceItem> items,
    required String sectionTitle,
    required List<String> headers,
    required int startRow,
  }) {
    int currentRow = startRow;

    // Titre de section (tableau 3)
    final sectionRange = sheet.getRangeByIndex(currentRow, 1, currentRow, 6);
    sectionRange.merge();
    sectionRange.setText(sectionTitle);
    sectionRange.rowHeight = 24;
    _styleBanner(sectionRange, _colorAccentBlue, 11);
    currentRow++;

    // Ligne d'en-tête de tableau
    for (int col = 1; col <= headers.length; col++) {
      final cell = sheet.getRangeByIndex(currentRow, col);
      cell.setText(headers[col - 1]);
      _styleHeaderCell(cell);
    }
    sheet.getRangeByIndex(currentRow, 1).rowHeight = 26;
    currentRow++;

    if (items.isEmpty) {
      final emptyRange = sheet.getRangeByIndex(currentRow, 1, currentRow, 6);
      emptyRange.merge();
      emptyRange.setText('Aucun équipement à source d\'alimentation non identifiée.');
      emptyRange.rowHeight = 22;
      _styleEmptyRow(emptyRange);
      return currentRow + 1;
    }

    // Regroupement identique au PDF : Zone -> Repère -> Items
    final zoneGroups = <PdfUnknownSourceZoneGroup>[];
    for (final it in items) {
      final normZone = it.zoneName.trim();
      final normLoc = it.localName.trim();

      var zGroup = zoneGroups.firstWhere(
        (zg) => zg.zoneName.toLowerCase() == normZone.toLowerCase(),
        orElse: () {
          final zg = PdfUnknownSourceZoneGroup(zoneName: normZone, repereGroups: []);
          zoneGroups.add(zg);
          return zg;
        },
      );

      var rGroup = zGroup.repereGroups.firstWhere(
        (rg) => rg.localName.toLowerCase() == normLoc.toLowerCase(),
        orElse: () {
          final rg = PdfUnknownSourceRepereGroup(localName: normLoc, items: []);
          zGroup.repereGroups.add(rg);
          return rg;
        },
      );

      rGroup.items.add(it);
    }

    for (final zoneGroup in zoneGroups) {
      final bool isNewZone = (zoneGroup != zoneGroups.first);
      final int zoneStartRow = currentRow;
      final int totalZoneItems =
          zoneGroup.repereGroups.fold<int>(0, (sum, g) => sum + g.items.length);

      for (final repereGroup in zoneGroup.repereGroups) {
        final bool isNewRepere =
            (repereGroup != zoneGroup.repereGroups.first);
        final int repereStartRow = currentRow;
        final int repereCount = repereGroup.items.length;
        final String displayRepere = repereGroup.localName.isNotEmpty
            ? repereGroup.localName
            : (zoneGroup.zoneName.isNotEmpty ? zoneGroup.zoneName : '-');

        for (final item in repereGroup.items) {
          final isEven = (currentRow % 2 == 0);
          final bgColor = isEven ? _colorZebra : _colorWhite;

          // Col 1 : Zone
          final cellZone = sheet.getRangeByIndex(currentRow, 1);
          cellZone.setText(
              zoneGroup.zoneName.isNotEmpty ? zoneGroup.zoneName : '-');
          _styleDataCell(cellZone,
              bgColor: bgColor, hAlign: xlsio.HAlignType.center, bold: true);

          // Col 2 : Repère
          final cellRepere = sheet.getRangeByIndex(currentRow, 2);
          cellRepere.setText(displayRepere);
          _styleDataCell(cellRepere,
              bgColor: bgColor, hAlign: xlsio.HAlignType.center, bold: true);

          // Col 3 : N°
          final cellNum = sheet.getRangeByIndex(currentRow, 3);
          final parsedNum = int.tryParse(item.numero);
          if (parsedNum != null) {
            cellNum.setNumber(parsedNum.toDouble());
          } else if (item.numero.isNotEmpty) {
            cellNum.setText(item.numero);
          } else {
            cellNum.setText('-');
          }
          _styleDataCell(cellNum,
              bgColor: bgColor, hAlign: xlsio.HAlignType.center, bold: true);

          // Col 4 : Désignation
          final cellNom = sheet.getRangeByIndex(currentRow, 4);
          cellNom.setText(item.nom);
          _styleDataCell(cellNom,
              bgColor: bgColor, hAlign: xlsio.HAlignType.left, wrapText: true);

          // Col 5 : Type
          final cellType = sheet.getRangeByIndex(currentRow, 5);
          cellType.setText(item.type);
          _styleDataCell(cellType,
              bgColor: bgColor, hAlign: xlsio.HAlignType.center);

          // Col 6 : Source (Règle unifiée PDF/Excel : "Identifiée" ou "Non identifiée")
          final cellSource = sheet.getRangeByIndex(currentRow, 6);
          final isIdentified = PdfEquipementsSynthesisBuilder.isSourceIdentified(item.source);
          final sourceText = PdfEquipementsSynthesisBuilder.formatSourceDisplay(item.source);
          cellSource.setText(sourceText);
          _styleDataCell(
            cellSource,
            bgColor: bgColor,
            hAlign: xlsio.HAlignType.center,
            bold: true,
            fontColor: isIdentified ? '#15803D' : '#C62828',
          );

          sheet.getRangeByIndex(currentRow, 1).rowHeight = 22;
          currentRow++;
        }

        // Bordures séparatrices
        if (isNewZone && repereStartRow == zoneStartRow) {
          _applyHorizontalSeparator(
            sheet,
            repereStartRow,
            1,
            6,
            color: _colorNavy,
            lineStyle: xlsio.LineStyle.medium,
          );
        } else if (isNewRepere) {
          _applyHorizontalSeparator(
            sheet,
            repereStartRow,
            2,
            6,
            color: _colorSepRepere,
            lineStyle: xlsio.LineStyle.medium,
          );
        }

        // Fusion verticale dynamique de Repère
        final int repereEndRow = repereStartRow + repereCount - 1;
        if (repereEndRow > repereStartRow) {
          final repereMerge =
              sheet.getRangeByIndex(repereStartRow, 2, repereEndRow, 2);
          repereMerge.merge();
          repereMerge.cellStyle.vAlign = xlsio.VAlignType.center;
          repereMerge.cellStyle.hAlign = xlsio.HAlignType.center;
        }
      }

      // Fusion verticale dynamique de Zone
      final int zoneEndRow = zoneStartRow + totalZoneItems - 1;
      if (zoneEndRow > zoneStartRow) {
        final zoneMerge = sheet.getRangeByIndex(zoneStartRow, 1, zoneEndRow, 1);
        zoneMerge.merge();
        zoneMerge.cellStyle.vAlign = xlsio.VAlignType.center;
        zoneMerge.cellStyle.hAlign = xlsio.HAlignType.center;
      }
    }

    return currentRow;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FEUILLE 2 : ANNEXE DES OBSERVATIONS
  // ══════════════════════════════════════════════════════════════════════════

  static void _buildObservationsSheet({
    required xlsio.Worksheet sheet,
    required Mission mission,
    AuditInstallationsElectriques? audit,
    required String reportDateStr,
  }) {
    // 10 colonnes exactes :
    // Zone | Repère | Désignation | Observation | Réf normative |
    // Réserve nécessitant une intervention ? | Statut de la réserve | Réserve levée par | Date de la réserve | Date de la levée de réserve
    final headers = [
      'Zone',
      'Repère',
      'Désignation',
      'Observation',
      'Réf normative',
      'Réserve nécessitant une intervention ?',
      'Statut de la réserve',
      'Réserve levée par',
      'Date de la réserve',
      'Date de la levée de réserve',
    ];

    // Largeurs de colonnes optimisées (en caractères)
    final colWidths = [
      18.0, // Zone
      22.0, // Repère
      28.0, // Désignation
      48.0, // Observation
      24.0, // Réf normative
      22.0, // Réserve nécessitant une intervention ?
      20.0, // Statut de la réserve
      20.0, // Réserve levée par
      18.0, // Date de la réserve
      20.0, // Date de la levée de réserve
    ];
    for (int i = 0; i < colWidths.length; i++) {
      sheet.getRangeByIndex(1, i + 1).columnWidth = colWidths[i];
    }

    int currentRow = 1;

    // 1. Grand bandeau de titre KES
    final titleRange = sheet.getRangeByIndex(currentRow, 1, currentRow, 10);
    titleRange.merge();
    titleRange.setText(
      'SYNTHÈSE RÉCAPITULATIVE DES OBSERVATIONS — ${mission.nomClient.toUpperCase()}${mission.nomSite != null && mission.nomSite!.isNotEmpty ? ' (${mission.nomSite})' : ''}',
    );
    titleRange.rowHeight = 32;
    _styleBanner(titleRange, _colorNavy, 12);
    currentRow += 2; // Ligne vide de respiration

    // 2. TABLEAU 1 : Observations Moyenne Tension (MT)
    final obsMT = audit != null
        ? PdfObservationsRecapBuilder.collectObservationsMT(audit)
        : <PdfObsRecap>[];
    currentRow = _renderObservationsTable(
      sheet: sheet,
      obsList: obsMT,
      sectionTitle: '1. OBSERVATIONS MOYENNE TENSION',
      headers: headers,
      startRow: currentRow,
    );

    currentRow += 2; // Séparation entre les 2 tableaux

    // 3. TABLEAU 2 : Observations Basse Tension (BT)
    final obsBT = audit != null
        ? PdfObservationsRecapBuilder.collectObservationsBT(audit)
        : <PdfObsRecap>[];
    _renderObservationsTable(
      sheet: sheet,
      obsList: obsBT,
      sectionTitle: '2. OBSERVATIONS BASSE TENSION',
      headers: headers,
      startRow: currentRow,
    );
  }

  static int _renderObservationsTable({
    required xlsio.Worksheet sheet,
    required List<PdfObsRecap> obsList,
    required String sectionTitle,
    required List<String> headers,
    required int startRow,
  }) {
    int currentRow = startRow;

    // Titre de section (MT ou BT)
    final sectionRange = sheet.getRangeByIndex(currentRow, 1, currentRow, 10);
    sectionRange.merge();
    sectionRange.setText(sectionTitle);
    sectionRange.rowHeight = 24;
    _styleBanner(sectionRange, _colorAccentBlue, 11);
    currentRow++;

    // Ligne d'en-tête de tableau
    for (int col = 1; col <= headers.length; col++) {
      final cell = sheet.getRangeByIndex(currentRow, col);
      cell.setText(headers[col - 1]);
      _styleHeaderCell(cell);
    }
    sheet.getRangeByIndex(currentRow, 1).rowHeight = 28;
    currentRow++;

    if (obsList.isEmpty) {
      final emptyRange = sheet.getRangeByIndex(currentRow, 1, currentRow, 10);
      emptyRange.merge();
      emptyRange.setText('Aucune observation recensée.');
      emptyRange.rowHeight = 22;
      _styleEmptyRow(emptyRange);
      return currentRow + 1;
    }

    // Regroupement identique au PDF : Zone -> Local -> Équipement -> Observations
    final zoneGroups =
        PdfObservationsRecapBuilder.groupByZoneLocalEquip(obsList);

    for (final zoneGroup in zoneGroups) {
      final bool isNewZone = (zoneGroup != zoneGroups.first);
      final int zoneStartRow = currentRow;

      for (final localGroup in zoneGroup.localGroups) {
        final bool isNewRepere = (localGroup != zoneGroup.localGroups.first);
        final int localStartRow = currentRow;

        final String displayRepere = localGroup.localName.isNotEmpty
            ? localGroup.localName
            : (zoneGroup.zoneName.isNotEmpty ? zoneGroup.zoneName : '-');

        for (final equipGroup in localGroup.equipGroups) {
          final bool isNewEquip = (equipGroup != localGroup.equipGroups.first);
          final int equipStartRow = currentRow;
          final rawEquip = equipGroup.coffret.trim();
          final bool isGenericEquip = rawEquip.isEmpty ||
              rawEquip.toLowerCase() == 'équipement sans nom' ||
              rawEquip.toLowerCase() == 'equipement sans nom' ||
              rawEquip.toLowerCase() == 'sans nom';

          final String equipName = !isGenericEquip
              ? rawEquip
              : (localGroup.localName.trim().isNotEmpty
                  ? 'Équipement (${localGroup.localName.trim()})'
                  : (zoneGroup.zoneName.trim().isNotEmpty
                      ? 'Équipement (${zoneGroup.zoneName.trim()})'
                      : 'Équipement'));

          for (final obs in equipGroup.items) {
            final isEven = (currentRow % 2 == 0);
            final bgColor = isEven ? _colorZebra : _colorWhite;

            // Col 1 : Zone
            final cellZone = sheet.getRangeByIndex(currentRow, 1);
            cellZone.setText(
                zoneGroup.zoneName.isNotEmpty ? zoneGroup.zoneName : '-');
            _styleDataCell(cellZone,
                bgColor: bgColor, hAlign: xlsio.HAlignType.center, bold: true);

            // Col 2 : Repère
            final cellRepere = sheet.getRangeByIndex(currentRow, 2);
            cellRepere.setText(displayRepere);
            _styleDataCell(cellRepere,
                bgColor: bgColor, hAlign: xlsio.HAlignType.center, bold: true);

            // Col 3 : Désignation
            final cellNom = sheet.getRangeByIndex(currentRow, 3);
            cellNom.setText(equipName);
            _styleDataCell(cellNom,
                bgColor: bgColor,
                hAlign: xlsio.HAlignType.center,
                bold: true,
                wrapText: true);

            // Col 4 : Observation
            final cellObs = sheet.getRangeByIndex(currentRow, 4);
            cellObs.setText(obs.observation);
            _styleDataCell(cellObs,
                bgColor: bgColor, hAlign: xlsio.HAlignType.left, wrapText: true);

            // Col 5 : Réf normative
            final cellNorm = sheet.getRangeByIndex(currentRow, 5);
            cellNorm.setText(obs.refNorm);
            _styleDataCell(cellNorm,
                bgColor: bgColor,
                hAlign: xlsio.HAlignType.center,
                wrapText: true);

            // Col 6 à 10 : STRICTEMENT VIDES (Règle d'or : aucune fausse valeur)
            for (int c = 6; c <= 10; c++) {
              final cellReserve = sheet.getRangeByIndex(currentRow, c);
              cellReserve.setText('');
              _styleDataCell(cellReserve,
                  bgColor: bgColor, hAlign: xlsio.HAlignType.center);
            }

            sheet.getRangeByIndex(currentRow, 1).rowHeight = 26;
            currentRow++;
          }

          // Renforcement ciblé des bordures de séparation (hiérarchie visuelle)
          if (isNewZone && equipStartRow == zoneStartRow) {
            _applyHorizontalSeparator(
              sheet,
              equipStartRow,
              1,
              10,
              color: _colorNavy,
              lineStyle: xlsio.LineStyle.medium,
            );
          } else if (isNewRepere && equipStartRow == localStartRow) {
            _applyHorizontalSeparator(
              sheet,
              equipStartRow,
              2,
              10,
              color: _colorSepRepere,
              lineStyle: xlsio.LineStyle.medium,
            );
          } else if (isNewEquip) {
            _applyHorizontalSeparator(
              sheet,
              equipStartRow,
              3,
              10,
              color: _colorSepEquip,
              lineStyle: xlsio.LineStyle.medium,
            );
          }

          // Fusion verticale dynamique de Désignation
          if (currentRow - 1 > equipStartRow) {
            final equipMerge =
                sheet.getRangeByIndex(equipStartRow, 3, currentRow - 1, 3);
            equipMerge.merge();
            equipMerge.cellStyle.vAlign = xlsio.VAlignType.center;
            equipMerge.cellStyle.hAlign = xlsio.HAlignType.center;
          }
        }

        // Fusion verticale dynamique de Repère
        if (currentRow - 1 > localStartRow) {
          final repereMerge =
              sheet.getRangeByIndex(localStartRow, 2, currentRow - 1, 2);
          repereMerge.merge();
          repereMerge.cellStyle.vAlign = xlsio.VAlignType.center;
          repereMerge.cellStyle.hAlign = xlsio.HAlignType.center;
        }
      }

      // Fusion verticale dynamique de Zone
      if (currentRow - 1 > zoneStartRow) {
        final zoneMerge =
            sheet.getRangeByIndex(zoneStartRow, 1, currentRow - 1, 1);
        zoneMerge.merge();
        zoneMerge.cellStyle.vAlign = xlsio.VAlignType.center;
        zoneMerge.cellStyle.hAlign = xlsio.HAlignType.center;
      }
    }

    return currentRow;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER STYLES
  // ══════════════════════════════════════════════════════════════════════════

  static void _styleBanner(xlsio.Range range, String bgColor, double fontSize) {
    range.cellStyle.backColor = bgColor;
    range.cellStyle.fontName = 'Calibri';
    range.cellStyle.fontSize = fontSize;
    range.cellStyle.bold = true;
    range.cellStyle.fontColor = _colorHeaderFont;
    range.cellStyle.hAlign = xlsio.HAlignType.center;
    range.cellStyle.vAlign = xlsio.VAlignType.center;
    range.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    range.cellStyle.borders.all.color = bgColor;
  }

  static void _styleHeaderCell(xlsio.Range cell) {
    cell.cellStyle.backColor = _colorHeaderBg;
    cell.cellStyle.fontName = 'Calibri';
    cell.cellStyle.fontSize = 10;
    cell.cellStyle.bold = true;
    cell.cellStyle.fontColor = _colorHeaderFont;
    cell.cellStyle.hAlign = xlsio.HAlignType.center;
    cell.cellStyle.vAlign = xlsio.VAlignType.center;
    cell.cellStyle.wrapText = true;
    cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    cell.cellStyle.borders.all.color = '#0F172A';
  }

  static void _styleDataCell(
    xlsio.Range cell, {
    required String bgColor,
    required xlsio.HAlignType hAlign,
    bool bold = false,
    bool wrapText = false,
    String? fontColor,
  }) {
    cell.cellStyle.backColor = bgColor;
    cell.cellStyle.fontName = 'Calibri';
    cell.cellStyle.fontSize = 9.5;
    cell.cellStyle.bold = bold;
    cell.cellStyle.fontColor = fontColor ?? '#1E293B';
    cell.cellStyle.hAlign = hAlign;
    cell.cellStyle.vAlign = xlsio.VAlignType.center;
    cell.cellStyle.wrapText = wrapText;
    final borders = cell.cellStyle.borders;
    borders.left.lineStyle = xlsio.LineStyle.thin;
    borders.left.color = _colorBorder;
    borders.right.lineStyle = xlsio.LineStyle.thin;
    borders.right.color = _colorBorder;
    borders.top.lineStyle = xlsio.LineStyle.thin;
    borders.top.color = _colorBorder;
    borders.bottom.lineStyle = xlsio.LineStyle.thin;
    borders.bottom.color = _colorBorder;
  }

  static void _styleEmptyRow(xlsio.Range range) {
    range.cellStyle.backColor = _colorZebra;
    range.cellStyle.fontName = 'Calibri';
    range.cellStyle.fontSize = 10;
    range.cellStyle.italic = true;
    range.cellStyle.fontColor = _colorMuted;
    range.cellStyle.hAlign = xlsio.HAlignType.center;
    range.cellStyle.vAlign = xlsio.VAlignType.center;
    final borders = range.cellStyle.borders;
    borders.left.lineStyle = xlsio.LineStyle.thin;
    borders.left.color = _colorBorder;
    borders.right.lineStyle = xlsio.LineStyle.thin;
    borders.right.color = _colorBorder;
    borders.top.lineStyle = xlsio.LineStyle.thin;
    borders.top.color = _colorBorder;
    borders.bottom.lineStyle = xlsio.LineStyle.thin;
    borders.bottom.color = _colorBorder;
  }

  /// Applique une bordure de séparation horizontale continue sur une plage de colonnes.
  /// Configure la bordure haute (top) de la ligne cible et la bordure basse (bottom) de la ligne précédente
  /// pour garantir un rendu net et homogène sur Excel et LibreOffice.
  static void _applyHorizontalSeparator(
    xlsio.Worksheet sheet,
    int row,
    int startCol,
    int endCol, {
    required String color,
    required xlsio.LineStyle lineStyle,
  }) {
    for (int col = startCol; col <= endCol; col++) {
      final cell = sheet.getRangeByIndex(row, col);
      cell.cellStyle.borders.top.lineStyle = lineStyle;
      cell.cellStyle.borders.top.color = color;

      if (row > 1) {
        final cellAbove = sheet.getRangeByIndex(row - 1, col);
        cellAbove.cellStyle.borders.bottom.lineStyle = lineStyle;
        cellAbove.cellStyle.borders.bottom.color = color;
      }
    }
  }
}
