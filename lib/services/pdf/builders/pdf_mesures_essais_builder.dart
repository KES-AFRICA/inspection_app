import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/builders/pdf_audit_installations_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_observations_recap_builder.dart';
import 'package:inspec_app/services/pdf/pdf_photo_context.dart';
import 'package:inspec_app/components/safe_file_image.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:path_provider/path_provider.dart';

class PdfPriseTerreRowItem {
  final String zoneName;
  final String repereName;
  final int index;
  final PriseTerre item;

  PdfPriseTerreRowItem({
    required this.zoneName,
    required this.repereName,
    required this.index,
    required this.item,
  });
}

class PdfPriseTerreRepereGroup {
  final String repereName;
  final List<PdfPriseTerreRowItem> items;

  PdfPriseTerreRepereGroup({
    required this.repereName,
    required this.items,
  });
}

class PdfPriseTerreZoneGroup {
  final String zoneName;
  final List<PdfPriseTerreRepereGroup> repereGroups;

  PdfPriseTerreZoneGroup({
    required this.zoneName,
    required this.repereGroups,
  });
}

class PdfDdrRowItem {
  final String zoneName;
  final String repereName;
  final String equipmentName;
  final int index;
  final EssaiDeclenchementDifferentiel item;

  PdfDdrRowItem({
    required this.zoneName,
    required this.repereName,
    required this.equipmentName,
    required this.index,
    required this.item,
  });
}

class PdfDdrEquipmentGroup {
  final String equipmentName;
  final List<PdfDdrRowItem> items;

  PdfDdrEquipmentGroup({
    required this.equipmentName,
    required this.items,
  });
}

class PdfDdrRepereGroup {
  final String repereName;
  final List<PdfDdrEquipmentGroup> equipmentGroups;

  PdfDdrRepereGroup({
    required this.repereName,
    required this.equipmentGroups,
  });
}

class PdfDdrZoneGroup {
  final String zoneName;
  final List<PdfDdrRepereGroup> repereGroups;

  PdfDdrZoneGroup({
    required this.zoneName,
    required this.repereGroups,
  });
}

class PdfContinuiteRowItem {
  final String zoneName;
  final String repereName;
  final int index;
  final ContinuiteResistance item;

  PdfContinuiteRowItem({
    required this.zoneName,
    required this.repereName,
    required this.index,
    required this.item,
  });
}

class PdfContinuiteRepereGroup {
  final String repereName;
  final List<PdfContinuiteRowItem> items;

  PdfContinuiteRepereGroup({
    required this.repereName,
    required this.items,
  });
}

class PdfContinuiteZoneGroup {
  final String zoneName;
  final List<PdfContinuiteRepereGroup> repereGroups;

  PdfContinuiteZoneGroup({
    required this.zoneName,
    required this.repereGroups,
  });
}

class PdfIsolementRowItem {
  final String zoneName;
  final String repereName;
  final int index;
  final EssaiIsolement item;
  final PointEquipmentInfo? infoA;
  final PointEquipmentInfo? infoB;

  PdfIsolementRowItem({
    required this.zoneName,
    required this.repereName,
    required this.index,
    required this.item,
    this.infoA,
    this.infoB,
  });
}

class PdfIsolementZoneGroup {
  final String zoneName;
  final List<PdfIsolementRowItem> items;

  PdfIsolementZoneGroup({
    required this.zoneName,
    required this.items,
  });
}

class PdfCpiRowItem {
  final String zoneName;
  final String repereName;
  final String transformateurName;
  final String armoireName;
  final int index;
  final CpiTest item;

  PdfCpiRowItem({
    required this.zoneName,
    required this.repereName,
    required this.transformateurName,
    required this.armoireName,
    required this.index,
    required this.item,
  });
}

class PdfCpiArmoireGroup {
  final String armoireName;
  final List<PdfCpiRowItem> items;

  PdfCpiArmoireGroup({
    required this.armoireName,
    required this.items,
  });
}

class PdfCpiTransfoGroup {
  final String transformateurName;
  final List<PdfCpiArmoireGroup> armoireGroups;
  int get totalRows => armoireGroups.fold(0, (sum, g) => sum + g.items.length);

  PdfCpiTransfoGroup({
    required this.transformateurName,
    required this.armoireGroups,
  });
}

class PdfCpiRepereGroup {
  final String repereName;
  final List<PdfCpiTransfoGroup> transfoGroups;
  int get totalRows => transfoGroups.fold(0, (sum, g) => sum + g.totalRows);

  PdfCpiRepereGroup({
    required this.repereName,
    required this.transfoGroups,
  });
}

class PdfCpiZoneGroup {
  final String zoneName;
  final List<PdfCpiRepereGroup> repereGroups;
  int get totalRows => repereGroups.fold(0, (sum, g) => sum + g.totalRows);

  PdfCpiZoneGroup({
    required this.zoneName,
    required this.repereGroups,
  });
}

typedef _PriseTerreRowItem = PdfPriseTerreRowItem;
typedef _PriseTerreRepereGroup = PdfPriseTerreRepereGroup;
typedef _PriseTerreZoneGroup = PdfPriseTerreZoneGroup;
typedef _DdrRowItem = PdfDdrRowItem;
typedef _DdrEquipmentGroup = PdfDdrEquipmentGroup;
typedef _DdrRepereGroup = PdfDdrRepereGroup;
typedef _DdrZoneGroup = PdfDdrZoneGroup;
typedef _ContinuiteRowItem = PdfContinuiteRowItem;
typedef _ContinuiteRepereGroup = PdfContinuiteRepereGroup;
typedef _ContinuiteZoneGroup = PdfContinuiteZoneGroup;
typedef _IsolementRowItem = PdfIsolementRowItem;
typedef _IsolementZoneGroup = PdfIsolementZoneGroup;
typedef _CpiRowItem = PdfCpiRowItem;
typedef _CpiArmoireGroup = PdfCpiArmoireGroup;
typedef _CpiTransfoGroup = PdfCpiTransfoGroup;
typedef _CpiRepereGroup = PdfCpiRepereGroup;
typedef _CpiZoneGroup = PdfCpiZoneGroup;

class PdfMesuresEssaisBuilder {
  static pw.Font _fontRegular = pw.Font.helvetica();
  static pw.Font _fontBold = pw.Font.helveticaBold();

  static set fontRegular(pw.Font? f) {
    if (f != null) _fontRegular = f;
  }

  static pw.Font get fontRegular => _fontRegular;

  static set fontBold(pw.Font? f) {
    if (f != null) _fontBold = f;
  }

  static pw.Font get fontBold => _fontBold;

  static PdfColor get headerColor => PdfReportStyles.headerColor;
  static PdfColor get accentColor => PdfReportStyles.accentColor;
  static PdfColor get lightBlue => PdfReportStyles.lightBlue;
  static PdfColor get darkGrey => PdfReportStyles.darkGrey;
  static PdfColor get borderColor => PdfReportStyles.borderColor;
  static PdfColor get conformeColor => PdfReportStyles.conformeColor;
  static PdfColor get nonConformeColor => PdfReportStyles.nonConformeColor;
  static PdfColor get sansObjetColor => PdfReportStyles.sansObjetColor;
  static final PdfColor tableRowAlt = PdfColor.fromInt(0xFFF5F8FC);
  static double get fsBody => PdfReportStyles.fsBody;
  static double get fsSmall => PdfReportStyles.fsSmall;
  static double get fsH3 => PdfReportStyles.fsH3;

  static pw.Widget _sectionBox(String title) => PdfReportStyles.sectionBox(title);
  static pw.Widget _subSectionBar(String title) => PdfReportStyles.subTitle(title);
  static pw.Widget _bodyText(String text) =>
      PdfReportStyles.bodyText(text, fontRegular: _fontRegular);
  static pw.Widget _bodyBold(String text) =>
      PdfReportStyles.bodyBold(text, fontBold: _fontBold);

  static String formatHeaderUnit(String text) =>
      PdfReportStyles.formatHeaderUnit(text);

  static pw.Widget _cell(
    String text, {
    required bool isHeader,
    PdfColor? color,
    int colspan = 1,
    bool centered = false,
  }) {
    final displayText = isHeader ? formatHeaderUnit(text) : text;
    return pw.Container(
      color: color,
      alignment: centered ? pw.Alignment.center : pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        _normalizeText(displayText),
        style: pw.TextStyle(
          fontSize: isHeader ? fsSmall : fsSmall,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.white : darkGrey),
        ),
        textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static pw.TableRow _tableHeaderRow(List<String> headers) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: accentColor),
      children: headers
          .map((h) => _cell(h, isHeader: true, centered: true))
          .toList(),
    );
  }

  static String _normalizeText(String text) => PdfReportStyles.normalizeText(text);

  static PdfLocationInfo _resolveLocation(
    AuditInstallationsElectriques? audit, {
    String? localisationStr,
    String? coffretStr,
  }) =>
      PdfObservationsRecapBuilder.resolveLocation(
        audit,
        localisationStr: localisationStr,
        coffretStr: coffretStr,
      );

  static final pw.MemoryImage _placeholder1x1 = pw.MemoryImage(
    Uint8List.fromList(<int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]),
  );

  static Future<pw.MemoryImage?> _loadAndOptimizeImage(
    String path, {
    PdfPhotoContext photoContext = PdfPhotoContext.equipmentObs,
    int? maxWidth,
    int? maxHeight,
    int? quality,
    bool saveFilesToDisk = true,
  }) async {
    if (!saveFilesToDisk) return _placeholder1x1;

    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;

    final targetWidth = maxWidth ?? photoContext.maxWidth;
    final targetHeight = maxHeight ?? photoContext.maxHeight;
    final targetQuality = quality ?? photoContext.quality;

    try {
      final resolvedPath = await AppImageUtils.resolvePathAsync(trimmed);
      if (resolvedPath == null) return null;
      final file = File(resolvedPath);
      if (!await file.exists()) return null;

      final tempDir = await getTemporaryDirectory();
      final cacheKey =
          'cache_' + file.path.hashCode.toString() + '_' + file.lengthSync().toString() + '_' + targetWidth.toString() + 'x' + targetHeight.toString() + '_q' + targetQuality.toString() + '.jpg';
      final cachedFile = File(tempDir.path + '/' + cacheKey);

      if (await cachedFile.exists()) {
        final cachedBytes = await cachedFile.readAsBytes();
        return pw.MemoryImage(cachedBytes);
      }

      final originalBytes = await file.readAsBytes();
      return pw.MemoryImage(originalBytes);
    } catch (e) {
      debugPrint('[PdfMesuresEssaisBuilder] Erreur chargement image (' + trimmed + '): ' + e.toString());
      return null;
    }
  }

  static pw.Widget _buildGroupedCellWidget({
    required int currentIndex,
    required int totalRows,
    required String text,
    required pw.TextStyle style,
    required pw.Border border,
    PdfColor decorationColor = PdfColors.white,
    pw.EdgeInsets padding = const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    pw.TextAlign textAlign = pw.TextAlign.center,
    pw.Alignment alignment = pw.Alignment.center,
    bool condition = true,
  }) {
    final midIndex = (totalRows - 1) ~/ 2;
    if (currentIndex != midIndex || !condition || text.isEmpty) {
      return pw.Container(
        decoration: pw.BoxDecoration(color: decorationColor, border: border),
        padding: padding,
        alignment: alignment,
        child: pw.SizedBox(),
      );
    }

    final textWidget = pw.Text(
      text,
      style: style,
      textAlign: textAlign,
    );

    if (totalRows % 2 == 0) {
      final fs = style.fontSize ?? 8.5;
      final dynamicTopPadding = fs * 1.6;

      return pw.Container(
        decoration: pw.BoxDecoration(color: decorationColor, border: border),
        padding: pw.EdgeInsets.only(top: dynamicTopPadding, left: 4, right: 4, bottom: 2),
        alignment: pw.Alignment.topCenter,
        child: textWidget,
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(color: decorationColor, border: border),
      padding: padding,
      alignment: alignment,
      child: textWidget,
    );
  }

  static pw.Widget _thHeaderCell(String title) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: _fontBold,
          fontSize: fsSmall,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _resultBox(String text) {
    final lower = text.toLowerCase();
    final isOk = lower.contains('satisfaisant') && !lower.contains('non');
    final isSansObjet = lower.contains('sans objet') || lower.contains('absent');
    final bg = isSansObjet
        ? sansObjetColor
        : (isOk ? conformeColor : nonConformeColor);
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: bg,
        border: pw.Border.all(color: borderColor, width: 0.4),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Text(text, style: pw.TextStyle(fontSize: fsBody)),
    );
  }

  static String _formatIsolement(dynamic val) {
    if (val == null) return '-';
    if (val is num) {
      if (val % 1 == 0) {
        return val.toInt().toString();
      }
      return val.toString().replaceAll('.', ',');
    }
    final str = val.toString().trim();
    if (str.isEmpty) return '-';
    final parsed = double.tryParse(str.replaceAll(',', '.'));
    if (parsed != null) {
      if (parsed % 1 == 0) {
        return parsed.toInt().toString();
      }
      return parsed.toString().replaceAll('.', ',');
    }
    return str;
  }

  static pw.Widget _buildCpiExplanations() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF0F4F8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: borderColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "ESSAI DE DÉCLENCHEMENT DU CPI :",
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: fsSmall,
              color: headerColor,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            "L'essai consiste à simuler, au moyen d'une résistance calibrée, un défaut d'isolement sur le réseau IT surveillé, et à vérifier que le Contrôleur Permanent d'Isolement détecte ce défaut et déclenche l'alarme (locale et/ou à distance) au seuil de réglage configuré, sans provoquer de coupure de l'installation.",
            style: pw.TextStyle(
              font: _fontRegular,
              fontSize: 7.5,
              color: darkGrey,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            "VÉRIFICATION DU REPORT D'ALARME :",
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: fsSmall,
              color: headerColor,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            "Le report d'alarme (voyant local, report GTB/GTC, ou tout autre dispositif de signalisation à distance) est contrôlé conjointement afin de s'assurer que le personnel d'exploitation est effectivement informé en cas de premier défaut d'isolement.",
            style: pw.TextStyle(
              font: _fontRegular,
              fontSize: 7.5,
              color: darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAbreviationsTable() {
    final titleTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.4),
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide.none,
      ),
      columnWidths: const {0: pw.FlexColumnWidth(4.0)},
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                "Signification des abréviations utilisées",
                style: pw.TextStyle(
                  font: _fontBold,
                  fontSize: fsH3,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );

    final dataTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: pw.TableBorder(
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.0),
        1: pw.FlexColumnWidth(3.0),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.white),
          children: [
            _cell("DDR", isHeader: false, centered: true),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(
                "Disjoncteur Différentiel",
                style: pw.TextStyle(
                  font: _fontRegular,
                  fontSize: fsSmall,
                  color: darkGrey,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: tableRowAlt),
          children: [
            _cell("RD", isHeader: false, centered: true),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(
                "Relais Différentiel",
                style: pw.TextStyle(
                  font: _fontRegular,
                  fontSize: fsSmall,
                  color: darkGrey,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.white),
          children: [
            _cell("IDR", isHeader: false, centered: true),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(
                "Interrupteur Différentiel",
                style: pw.TextStyle(
                  font: _fontRegular,
                  fontSize: fsSmall,
                  color: darkGrey,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: tableRowAlt),
          children: [
            _cell("I\u0394n", isHeader: false, centered: true),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(
                "Intensité différentielle",
                style: pw.TextStyle(
                  font: _fontRegular,
                  fontSize: fsSmall,
                  color: darkGrey,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),
          ],
        ),
      ],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [titleTable, dataTable],
    );
  }

  static pw.Widget _buildBlueBoxBanner(String title) {
    return pw.Container(
      width: double.infinity,
      color: lightBlue,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
      child: pw.Text(
        _normalizeText(title),
        style: pw.TextStyle(
          font: _fontBold,
          fontSize: fsBody,
          fontWeight: pw.FontWeight.bold,
          color: headerColor,
        ),
      ),
    );
  }

  static pw.Widget _para(List<pw.InlineSpan> spans) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          style: pw.TextStyle(
            font: _fontRegular,
            fontSize: fsBody,
            color: PdfColors.black,
          ),
          children: spans,
        ),
      ),
    );
  }

  static pw.Widget _subMethodHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6, bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 5,
            height: 5,
            decoration: pw.BoxDecoration(
              color: accentColor,
              shape: pw.BoxShape.rectangle,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            _normalizeText(title),
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: fsBody,
              fontWeight: pw.FontWeight.bold,
              color: headerColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _bulletPoint(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4, right: 6),
            width: 3.5,
            height: 3.5,
            decoration: pw.BoxDecoration(
              color: accentColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _normalizeText(text),
              style: pw.TextStyle(
                font: _fontRegular,
                fontSize: fsBody,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _checkboxRow(String label) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 12, bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            _normalizeText(label),
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: fsBody,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Future<Map<PriseTerre, pw.MemoryImage?>> preloadPrisesTerrePhotos(
    List<PriseTerre> prises, {
    bool loadImages = true,
    Future<pw.MemoryImage?> Function(
      String path, {
      PdfPhotoContext photoContext,
      int? maxWidth,
      int? maxHeight,
      int? quality,
      bool saveFilesToDisk,
    })? imageLoader,
  }) async {
    final cache = <PriseTerre, pw.MemoryImage?>{};
    if (!loadImages) return cache;

    for (final pt in prises) {
      final path = pt.photo?.trim();
      if (path != null && path.isNotEmpty) {
        final img = imageLoader != null
            ? await imageLoader(
                path,
                photoContext: PdfPhotoContext.equipmentObs,
                saveFilesToDisk: loadImages,
              )
            : await _loadAndOptimizeImage(
                path,
                photoContext: PdfPhotoContext.equipmentObs,
                saveFilesToDisk: loadImages,
              );
        if (img != null) {
          cache[pt] = img;
        }
      }
    }
    return cache;
  }

  static pw.Widget buildGroupedCellWidget({
    required int currentIndex,
    required int totalRows,
    required String text,
    required pw.TextStyle style,
    required pw.Border border,
    PdfColor decorationColor = PdfColors.white,
    pw.EdgeInsets padding = const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    pw.TextAlign textAlign = pw.TextAlign.center,
    pw.Alignment alignment = pw.Alignment.center,
    bool condition = true,
  }) =>
      _buildGroupedCellWidget(
        currentIndex: currentIndex,
        totalRows: totalRows,
        text: text,
        style: style,
        border: border,
        decorationColor: decorationColor,
        padding: padding,
        textAlign: textAlign,
        alignment: alignment,
        condition: condition,
      );

  static pw.Widget thHeaderCell(String title) => _thHeaderCell(title);
  static pw.Widget resultBox(String text) => _resultBox(text);
  static String formatIsolement(dynamic val) => _formatIsolement(val);
  static pw.Widget buildAbreviationsTable() => _buildAbreviationsTable();
  static pw.Widget buildBlueBoxBanner(String title) => _buildBlueBoxBanner(title);
  static pw.Widget para(List<pw.InlineSpan> spans) => _para(spans);
  static pw.Widget subMethodHeader(String title) => _subMethodHeader(title);
  static pw.Widget bulletPoint(String text) => _bulletPoint(text);
  static pw.Widget checkboxRow(String label) => _checkboxRow(label);

  static Future<void> addMesuresEssaisPages(
    pw.Document pdf,
    MesuresEssais mesures,
    Map<String, int> trackedPages, {
    int pageOffset = 0,
    int? overrideTotalPages,
    DescriptionInstallations? desc,
    bool saveFilesToDisk = true,
    AuditInstallationsElectriques? audit,
    String? nomSite,
    String? numeroRapport,
    pw.PageTheme Function({
      int pageOffset,
      int? overrideTotalPages,
      bool showWatermark,
      PdfPageFormat pageFormat,
    })? innerPageThemeBuilder,
    pw.Widget Function({
      String? nomClient,
      String? nomSite,
      String? numeroRapport,
      String? titreRapport,
    })? pageHeaderBuilder,
    Future<pw.MemoryImage?> Function(
      String path, {
      PdfPhotoContext photoContext,
      int? maxWidth,
      int? maxHeight,
      int? quality,
      bool saveFilesToDisk,
    })? imageLoader,
  }) async {
    pw.PageTheme innerTheme({
      int pageOffset = 0,
      int? overrideTotalPages,
      bool showWatermark = true,
      PdfPageFormat pageFormat = PdfPageFormat.a4,
    }) {
      if (innerPageThemeBuilder != null) {
        return innerPageThemeBuilder(
          pageOffset: pageOffset,
          overrideTotalPages: overrideTotalPages,
          showWatermark: showWatermark,
          pageFormat: pageFormat,
        );
      }
      return pw.PageTheme(
        pageFormat: pageFormat,
        theme: pw.ThemeData.withFont(base: _fontRegular, bold: _fontBold),
        margin: const pw.EdgeInsets.only(
          left: PdfReportStyles.kLeftMargin,
          top: PdfReportStyles.kTopMargin,
          right: PdfReportStyles.kRightMargin,
          bottom: PdfReportStyles.kBottomMargin + 4,
        ),
      );
    }

    pw.Widget pageHeader({
      String? nomClient,
      String? nomSite,
      String? numeroRapport,
      String? titreRapport,
    }) {
      if (pageHeaderBuilder != null) {
        return pageHeaderBuilder(
          nomClient: nomClient,
          nomSite: nomSite,
          numeroRapport: numeroRapport,
          titreRapport: titreRapport,
        );
      }
      return PdfReportStyles.buildPageHeaderWidget(
        fontRegular: _fontRegular,
        fontBold: _fontBold,
        nomClient: nomClient,
        nomSite: nomSite,
        numeroRapport: numeroRapport,
        titreRapport: titreRapport,
      );
    }

    final ptPhotosCache = await preloadPrisesTerrePhotos(
      mesures.prisesTerre,
      loadImages: saveFilesToDisk,
      imageLoader: imageLoader,
    );

    // Page intro avec conditions ET les deux essais
    pdf.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: innerTheme(
          pageOffset: pageOffset,
          overrideTotalPages: overrideTotalPages,
        ),
        header: (ctx) => pageHeader(),
        build: (ctx) => [
          PageTracker(
            key: 'mesures',
            registry: trackedPages,
            offset: pageOffset,
            child: _sectionBox('RESULTATS DES MESURES ET ESSAIS'),
          ),
          pw.SizedBox(height: 10),

          PageTracker(
            key: 'mesures_conditions',
            registry: trackedPages,
            offset: pageOffset,
            child: _subSectionBar("I. CONDITIONS DE MESURE"),
          ),
          pw.SizedBox(height: 6),

          _bodyText(
            "Les mesures et essais sont réalisés conformément aux conditions de mesure, aux méthodes d’essai et aux critères d’acceptation définis ci-après.",
          ),
          pw.SizedBox(height: 4),

          // 1. Mesure de la résistance d'isolement
          _buildBlueBoxBanner("Mesure de la résistance d’isolement"),
          _para([
            const pw.TextSpan(
              text:
                  "Les mesures de résistance d’isolement par rapport à la terre sont réalisées sous une tension continue de 500 V.",
            ),
          ]),
          _para([
            const pw.TextSpan(
              text:
                  "La valeur mesurée est considérée comme satisfaisante lorsqu’elle est supérieure à 0,5 M ohms.",
            ),
          ]),

          // 2. Vérification de la continuité et de la résistance des conducteurs de protection
          _buildBlueBoxBanner(
            "Vérification de la continuité et de la résistance des conducteurs de protection",
          ),
          _bodyText(
            "La continuité et la résistance des conducteurs de protection (PE) sont vérifiées afin de s’assurer de leur capacité à assurer efficacement la protection des personnes en cas de défaut d’isolement.",
          ),
          _para([
            const pw.TextSpan(
              text:
                  "Le résultat est considéré comme conforme lorsque les valeurs mesurées satisfont aux prescriptions du guide UTE C 15-105, notamment celles relatives à la continuité des conducteurs de protection.",
            ),
          ]),

          // 3. Essai de déclenchement des dispositifs différentiels résiduels (DDR)
          _buildBlueBoxBanner(
            "Essai de déclenchement des dispositifs différentiels résiduels (DDR)",
          ),
          _bodyText(
            "Les essais de déclenchement permettent de vérifier le bon fonctionnement des dispositifs différentiels résiduels ainsi que leur seuil effectif de déclenchement.",
          ),
          _para([
            const pw.TextSpan(
              text:
                  "Le seuil de déclenchement est considéré comme satisfaisant lorsque la valeur mesurée est comprise entre 0,5 IΔn et IΔn, où IΔn représente le courant différentiel résiduel assigné du dispositif.",
            ),
          ]),
          _bodyText(
            "Les essais permettent également de vérifier le comportement du dispositif dans les conditions prévues de fonctionnement.",
          ),

          // 4. Mesure des impédances de boucle – Protection contre les contacts indirects
          _buildBlueBoxBanner(
            "Mesure des impédances de boucle – Protection contre les contacts indirects",
          ),
          _bodyText(
            "La mesure de l’impédance de boucle permet de vérifier l’efficacité du dispositif de protection contre les contacts indirects.",
          ),
          _bodyText(
            "Elle permet notamment de déterminer le courant de défaut susceptible de circuler en cas de défaut d’isolement et de vérifier que le dispositif de protection est susceptible de provoquer la coupure du circuit dans le temps requis.",
          ),
          _para([
            const pw.TextSpan(
              text:
                  "Le résultat est considéré comme conforme lorsque les conditions de coupure correspondant au courant de défaut déterminé satisfont aux prescriptions du référentiel applicable, notamment celles du guide UTE C 15-105 lorsque celui-ci est retenu comme référentiel de vérification.",
            ),
          ]),

          // 5. Mesure de la résistance des prises de terre
          _buildBlueBoxBanner("Mesure de la résistance des prises de terre"),
          _bodyText(
            "La mesure de la résistance des prises de terre est réalisée afin de vérifier l’efficacité du système de mise à la terre et son aptitude à contribuer à la protection des personnes et au fonctionnement des dispositifs de protection.",
          ),
          _para([
            const pw.TextSpan(
              text:
                  "Avant toute mesure, la position de la barrette principale de terre ou de la barrette de coupure est vérifiée et mentionnée dans le rapport.",
            ),
          ]),
          _bodyText(
            "La mesure peut être réalisée selon deux méthodes principales :",
          ),
          pw.SizedBox(height: 2),

          _subMethodHeader("Méthode des trois piquets – Barrette ouverte"),
          _para([
            const pw.TextSpan(
              text:
                  "La méthode des trois piquets est réalisée avec la barrette de terre ouverte, lorsque la configuration de l'installation permet d'isoler la prise de terre à meuser.",
            ),
          ]),
          _bodyText("Elle utilise :"),
          _bulletPoint("La prise de terre à mesurer ;"),
          _bulletPoint("Un piquet auxiliaire de courant ;"),
          _bulletPoint("Un piquet auxiliaire de potentiel."),
          _bodyText(
            "Cette méthode permet de mesurer la résistance de la prise de terre selon le principe de la chute de potentiel.",
          ),
          pw.SizedBox(height: 3),

          pw.NewPage(),
          _bodyBold("Position de la barrette lors de la mesure :"),
          pw.SizedBox(height: 3),
          _checkboxRow("Barrette ouverte"),
          _checkboxRow("Barrette fermée"),
          pw.SizedBox(height: 3),
          _bodyText(
            "Lorsque la barrette est ouverte, il convient de s'assurer que les conditions de sécurité sont maîtrisées et que la coupure temporaire de la liaison de terre ne met pas les personnes ou les équipements en danger.",
          ),
          pw.SizedBox(height: 4),

          _subMethodHeader("Méthode à la pince de terre – Barrette fermée"),
          _bodyText(
            "La mesure à la pince de terre peut être utilisée lorsque la configuration de l'installation permet ce type de mesure et qu'il n'est pas possible ou souhaitable d'implanter des piquets auxiliaires.",
          ),
          _bodyText("Cette méthode est particulièrement adaptée aux sites :"),
          _bulletPoint("Fortement bétonnés ou asphaltés ;"),
          _bulletPoint("Industriels ;"),
          _bulletPoint("Présentant des contraintes d'accès ;"),
          _bulletPoint(
            "Dans lesquels l'implantation de piquets est difficile ;",
          ),
          _bulletPoint(
            "Où l'interruption du réseau de terre n'est pas souhaitable.",
          ),
          pw.SizedBox(height: 3),
          _para([
            const pw.TextSpan(
              text:
                  "Dans ce cas, la mesure est généralement réalisée barrette fermée, afin de conserver le réseau de terre dans sa configuration normale de fonctionnement.",
            ),
          ]),
        ],
      ),
    );

    // II. RÉSULTATS DES ESSAIS (nouvelle page - PAYSAGE)
    pdf.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: innerTheme(
          pageOffset: pageOffset,
          overrideTotalPages: overrideTotalPages,
          pageFormat: PdfPageFormat.a4.landscape,
        ),
        header: (ctx) => pageHeader(
          nomSite: nomSite,
          numeroRapport: numeroRapport,
        ),
        build: (ctx) {
          final ptRows = <_PriseTerreRowItem>[];
          for (int i = 0; i < mesures.prisesTerre.length; i++) {
            final pt = mesures.prisesTerre[i];
            final locInfo = _resolveLocation(audit, localisationStr: pt.localisation);
            ptRows.add(
              _PriseTerreRowItem(
                zoneName: locInfo.zoneName,
                repereName: locInfo.repereName,
                index: i + 1,
                item: pt,
              ),
            );
          }

          // Regroupement par Zone -> Repère
          final ptZoneGroups = <_PriseTerreZoneGroup>[];
          for (final row in ptRows) {
            final normZone = row.zoneName.trim();
            final normRep = row.repereName.trim();

            var zGroup = ptZoneGroups.firstWhere(
              (zg) => zg.zoneName.toLowerCase() == normZone.toLowerCase(),
              orElse: () {
                final zg = _PriseTerreZoneGroup(zoneName: normZone, repereGroups: []);
                ptZoneGroups.add(zg);
                return zg;
              },
            );

            var rGroup = zGroup.repereGroups.firstWhere(
              (rg) => rg.repereName.toLowerCase() == normRep.toLowerCase(),
              orElse: () {
                final rg = _PriseTerreRepereGroup(repereName: normRep, items: []);
                zGroup.repereGroups.add(rg);
                return rg;
              },
            );

            rGroup.items.add(row);
          }

          const ptColumnWidths = <int, pw.TableColumnWidth>{
            0: pw.FlexColumnWidth(1.2), // ZONE
            1: pw.FlexColumnWidth(1.4), // REPÈRE
            2: pw.FixedColumnWidth(28), // N°
            3: pw.FlexColumnWidth(1.3), // Identification
            4: pw.FlexColumnWidth(1.2), // Condition
            5: pw.FlexColumnWidth(1.4), // Nature
            6: pw.FlexColumnWidth(1.2), // Méthode
            7: pw.FlexColumnWidth(1.0), // Valeur
            8: pw.FlexColumnWidth(1.1), // Interconnecté
            9: pw.FlexColumnWidth(1.8), // Observation
            10: pw.FlexColumnWidth(2.0), // Photo
          };

          final ptTableRows = <pw.TableRow>[];
          ptTableRows.add(
            _tableHeaderRow([
              'ZONE',
              'REPÈRE',
              'N°',
              'Identification de la prise de terre',
              'Condition de mesure',
              'Nature de la prise de terre',
              'Méthode de mesure',
              'Valeur de la mesure',
              'Interconnecté à d\'autre prise',
              'Observation',
              'Photo',
            ]),
          );

          if (ptRows.isEmpty) {
            ptTableRows.add(
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.white),
                children: List.generate(
                  11,
                  (_) => _cell('', isHeader: false, centered: true),
                ),
              ),
            );
          } else {
            int globalRowIdx = 0;
            for (final zoneGroup in ptZoneGroups) {
              final totalZoneItems = zoneGroup.repereGroups.fold<int>(
                0,
                (sum, g) => sum + g.items.length,
              );
              final zoneMidIdx = (totalZoneItems - 1) ~/ 2;
              int zoneItemIdx = 0;

              for (int rIdx = 0; rIdx < zoneGroup.repereGroups.length; rIdx++) {
                final repGroup = zoneGroup.repereGroups[rIdx];
                final repCount = repGroup.items.length;
                final repMidIdx = (repCount - 1) ~/ 2;

                for (int i = 0; i < repCount; i++) {
                  final rowItem = repGroup.items[i];
                  final pt = rowItem.item;
                  final currentZoneItemIdx = zoneItemIdx++;
                  final currentRepItemIdx = i;

                  final idx = globalRowIdx++;
                  final isEven = idx % 2 == 0;
                  final bg = isEven ? PdfColors.white : tableRowAlt;

                  final isStartOfZone = (currentZoneItemIdx == 0 && idx > 0);
                  final isStartOfRepere = (currentRepItemIdx == 0 && currentZoneItemIdx > 0);

                  final isEndOfZone = (currentZoneItemIdx == totalZoneItems - 1);
                  final isEndOfRepere = (currentRepItemIdx == repCount - 1);

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

                  final obs = pt.observation ?? '';
                  final inter = pt.interconnecteAutrePrise?.trim();
                  PdfColor? cellBg;
                  String textVal = '-';
                  if (inter == 'Oui') {
                    cellBg = conformeColor;
                    textVal = 'Oui';
                  } else if (inter == 'Non') {
                    cellBg = nonConformeColor;
                    textVal = 'Non';
                  }

                  final photoImg = ptPhotosCache[pt];

                  ptTableRows.add(
                    pw.TableRow(
                      children: [
                        // Cellule 0 : Zone
                        _buildGroupedCellWidget(
                          currentIndex: currentZoneItemIdx,
                          totalRows: totalZoneItems,
                          text: zoneGroup.zoneName,
                          style: pw.TextStyle(font: _fontBold, fontSize: 8.5),
                          border: zoneBorder,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        ),

                        // Cellule 1 : Repère
                        _buildGroupedCellWidget(
                          currentIndex: currentRepItemIdx,
                          totalRows: repCount,
                          text: repGroup.repereName.isNotEmpty
                              ? repGroup.repereName
                              : (zoneGroup.zoneName.isNotEmpty ? zoneGroup.zoneName : ''),
                          style: pw.TextStyle(font: _fontBold, fontSize: 8.5),
                          border: repereBorder,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        ),

                        // Cellule 2 : N°
                        pw.Container(
                          decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            '${rowItem.index}',
                            style: pw.TextStyle(font: _fontBold, fontSize: 8.5),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),

                        // Cellule 3 : Identification
                        pw.Container(
                          decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            pt.identification.isNotEmpty ? pt.identification : '-',
                            style: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),

                        // Cellule 4 : Condition de mesure
                        pw.Container(
                          decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            pt.conditionPriseTerre.isNotEmpty ? pt.conditionPriseTerre : '-',
                            style: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),

                        // Cellule 5 : Nature
                        pw.Container(
                          decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            pt.naturePriseTerre.isNotEmpty ? pt.naturePriseTerre : '-',
                            style: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),

                        // Cellule 6 : Méthode
                        pw.Container(
                          decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            pt.methodeMesure.isNotEmpty ? pt.methodeMesure : '-',
                            style: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),

                        // Cellule 7 : Valeur de la mesure
                        pw.Container(
                          decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            pt.valeurMesure?.toStringAsFixed(2) ?? '-',
                            style: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),

                        // Cellule 8 : Interconnecté
                        pw.Container(
                          decoration: pw.BoxDecoration(color: cellBg ?? bg, border: itemBorder),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            textVal,
                            style: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),

                        // Cellule 9 : Observation
                        pw.Container(
                          decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            obs.isEmpty ? '-' : obs,
                            style: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),

                        // Cellule 10 : Photo
                        pw.Container(
                          decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                          padding: const pw.EdgeInsets.all(3),
                          alignment: pw.Alignment.center,
                          child: photoImg != null
                              ? pw.Container(
                                  height: 65,
                                  alignment: pw.Alignment.center,
                                  child: pw.Image(photoImg, fit: pw.BoxFit.contain),
                                )
                              : pw.Text(
                                  '-',
                                  style: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
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

          return [
            PageTracker(
              key: 'mesures_resultats',
              registry: trackedPages,
              offset: pageOffset,
              child: _subSectionBar("II. RÉSULTATS DES ESSAIS"),
            ),
            pw.SizedBox(height: 6),
            _bodyText(
              "Les résultats des mesures et essais réalisés sont présentés ci-après par type de vérification.",
            ),
            pw.SizedBox(height: 12),

            // 1. Prise de terre
            PageTracker(
              key: 'mesures_terre',
              registry: trackedPages,
              offset: pageOffset,
              child: _subSectionBar('1. Prise de terre'),
            ),
            pw.SizedBox(height: 8),

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
              columnWidths: ptColumnWidths,
              children: ptTableRows,
            ),
          ];
        },
      ),
    );

    // 2. Essais de declenchement des DDR (nouvelle page - PAYSAGE)
    pdf.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: innerTheme(
          pageOffset: pageOffset,
          overrideTotalPages: overrideTotalPages,
          pageFormat: PdfPageFormat.a4.landscape,
        ),
        header: (ctx) => pageHeader(
          nomSite: nomSite,
          numeroRapport: numeroRapport,
        ),
        build: (ctx) {
          final widgets = <pw.Widget>[];

          widgets.add(
            PageTracker(
              key: 'mesures_ddr',
              registry: trackedPages,
              offset: pageOffset,
              child: _subSectionBar(
                "2. Essais de déclenchement des dispositifs différentiels",
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 8));

          final ddrRows = <_DdrRowItem>[];
          for (int i = 0; i < mesures.essaisDeclenchement.length; i++) {
            final es = mesures.essaisDeclenchement[i];
            final locInfo = _resolveLocation(
              audit,
              localisationStr: es.localisation,
              coffretStr: es.coffret,
            );
            ddrRows.add(
              _DdrRowItem(
                zoneName: locInfo.zoneName,
                repereName: locInfo.repereName,
                equipmentName: locInfo.equipmentName,
                index: i + 1,
                item: es,
              ),
            );
          }

          // Regroupement 3 niveaux : Zone -> Repère -> Équipement
          final ddrZoneGroups = <_DdrZoneGroup>[];
          for (final row in ddrRows) {
            final normZone = row.zoneName.trim();
            final normRep = row.repereName.trim();
            final normEq = row.equipmentName.trim();

            var zGroup = ddrZoneGroups.firstWhere(
              (zg) => zg.zoneName.toLowerCase() == normZone.toLowerCase(),
              orElse: () {
                final zg = _DdrZoneGroup(zoneName: normZone, repereGroups: []);
                ddrZoneGroups.add(zg);
                return zg;
              },
            );

            var rGroup = zGroup.repereGroups.firstWhere(
              (rg) => rg.repereName.toLowerCase() == normRep.toLowerCase(),
              orElse: () {
                final rg = _DdrRepereGroup(repereName: normRep, equipmentGroups: []);
                zGroup.repereGroups.add(rg);
                return rg;
              },
            );

            var eGroup = rGroup.equipmentGroups.firstWhere(
              (eg) => eg.equipmentName.toLowerCase() == normEq.toLowerCase(),
              orElse: () {
                final eg = _DdrEquipmentGroup(equipmentName: normEq, items: []);
                rGroup.equipmentGroups.add(eg);
                return eg;
              },
            );

            eGroup.items.add(row);
          }

          const ddrColumnWidthsHeader = <int, pw.TableColumnWidth>{
            0: pw.FlexColumnWidth(1.2), // ZONE
            1: pw.FlexColumnWidth(1.4), // REPÈRE
            2: pw.FixedColumnWidth(28), // N°
            3: pw.FlexColumnWidth(1.8), // ÉQUIPEMENT
            4: pw.FlexColumnWidth(2.0), // DÉSIGNATION CIRCUIT
            5: pw.FlexColumnWidth(1.5), // TYPE DISPOSITIF
            6: pw.FlexColumnWidth(1.1), // CALIBRE
            7: pw.FlexColumnWidth(2.0), // RÉGLAGE (IAn + Tempo)
            8: pw.FlexColumnWidth(1.2), // ESSAI
          };

          const ddrColumnWidthsData = <int, pw.TableColumnWidth>{
            0: pw.FlexColumnWidth(1.2), // ZONE
            1: pw.FlexColumnWidth(1.4), // REPÈRE
            2: pw.FixedColumnWidth(28), // N°
            3: pw.FlexColumnWidth(1.8), // ÉQUIPEMENT
            4: pw.FlexColumnWidth(2.0), // DÉSIGNATION CIRCUIT
            5: pw.FlexColumnWidth(1.5), // TYPE DISPOSITIF
            6: pw.FlexColumnWidth(1.1), // CALIBRE
            7: pw.FlexColumnWidth(1.0), // IAn
            8: pw.FlexColumnWidth(1.0), // Tempo
            9: pw.FlexColumnWidth(1.2), // ESSAI
          };

          // 1. Table Header
          final headerTable = pw.Table(
            border: const pw.TableBorder(
              left: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
              right: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
              top: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
              bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
              verticalInside: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
              horizontalInside: pw.BorderSide.none,
            ),
            columnWidths: ddrColumnWidthsHeader,
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: accentColor),
                children: [
                  _thHeaderCell("ZONE"),
                  _thHeaderCell("REPÈRE"),
                  _thHeaderCell("N°"),
                  _thHeaderCell("Désignation"),
                  _thHeaderCell("Précision"),
                  _thHeaderCell("Type de dispositif"),
                  _thHeaderCell("Calibre du dispositif (A)"),
                  pw.Column(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Text(
                          "Réglage",
                          style: pw.TextStyle(
                            font: _fontBold,
                            fontSize: fsSmall,
                            color: PdfColors.white,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Divider(height: 0.4, color: borderColor),
                      pw.Table(
                        border: pw.TableBorder(
                          verticalInside: pw.BorderSide(
                            color: borderColor,
                            width: 0.4,
                          ),
                        ),
                        columnWidths: const {
                          0: pw.FlexColumnWidth(1.0),
                          1: pw.FlexColumnWidth(1.0),
                        },
                        children: [
                          pw.TableRow(
                            children: [
                              pw.Text(
                                "I\u0394n (mA)",
                                style: pw.TextStyle(
                                  font: _fontBold,
                                  fontSize: fsSmall,
                                  color: PdfColors.white,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.Text(
                                "Tempo (s)",
                                style: pw.TextStyle(
                                  font: _fontBold,
                                  fontSize: fsSmall,
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
                  _thHeaderCell("Essai"),
                ],
              ),
            ],
          );

          widgets.add(headerTable);

          final ddrTableRows = <pw.TableRow>[];
          if (ddrRows.isEmpty) {
            ddrTableRows.add(
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.white),
                children: List.generate(
                  10,
                  (_) => _cell('', isHeader: false, centered: true),
                ),
              ),
            );
          } else {
            int globalRowIdx = 0;
            for (final zGroup in ddrZoneGroups) {
              final totalZoneItems = zGroup.repereGroups.fold<int>(
                0,
                (sum, rg) => sum + rg.equipmentGroups.fold<int>(0, (s, eg) => s + eg.items.length),
              );
              final zoneMidIdx = (totalZoneItems - 1) ~/ 2;
              int zoneItemIdx = 0;

              for (final rGroup in zGroup.repereGroups) {
                final totalRepereItems = rGroup.equipmentGroups.fold<int>(
                  0,
                  (sum, eg) => sum + eg.items.length,
                );
                final repMidIdx = (totalRepereItems - 1) ~/ 2;
                int repItemIdx = 0;

                for (final eGroup in rGroup.equipmentGroups) {
                  final eqCount = eGroup.items.length;
                  final eqMidIdx = (eqCount - 1) ~/ 2;

                  for (int i = 0; i < eqCount; i++) {
                    final rowItem = eGroup.items[i];
                    final es = rowItem.item;
                    final currentZoneItemIdx = zoneItemIdx++;
                    final currentRepItemIdx = repItemIdx++;
                    final currentEqItemIdx = i;

                    final idx = globalRowIdx++;
                    final isEven = idx % 2 == 0;
                    final bg = isEven ? PdfColors.white : tableRowAlt;

                    final isStartOfZone = (currentZoneItemIdx == 0 && idx > 0);
                    final isStartOfRepere = (currentRepItemIdx == 0 && currentZoneItemIdx > 0);
                    final isStartOfEquip = (currentEqItemIdx == 0 && currentRepItemIdx > 0);

                    final isEndOfZone = (currentZoneItemIdx == totalZoneItems - 1);
                    final isEndOfRepere = (currentRepItemIdx == totalRepereItems - 1);
                    final isEndOfEquip = (currentEqItemIdx == eqCount - 1);

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

                    final equipmentBorder = pw.Border(
                      top: isStartOfZone
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                          : (isStartOfRepere
                              ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                              : (isStartOfEquip
                                  ? const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.6)
                                  : pw.BorderSide.none)),
                      bottom: isEndOfZone
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                          : (isEndOfRepere
                              ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                              : (isEndOfEquip
                                  ? const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.6)
                                  : pw.BorderSide.none)),
                    );

                    final itemBorder = pw.Border(
                      top: isStartOfZone
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                          : (isStartOfRepere
                              ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                              : (isStartOfEquip
                                  ? const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.6)
                                  : pw.BorderSide.none)),
                      bottom: isEndOfZone
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                          : (isEndOfRepere
                              ? const pw.BorderSide(color: PdfColor.fromInt(0xFF334155), width: 0.8)
                              : (isEndOfEquip
                                  ? const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.6)
                                  : const pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.4))),
                    );

                    String displayText;
                    PdfColor? essaiColor;
                    final raw = es.essai.trim().toUpperCase();

                    if (raw == 'OK' || raw == 'B' || raw == 'SATISFAISANT') {
                      displayText = 'Satisfaisant';
                      essaiColor = conformeColor;
                    } else if (raw == 'NON OK' || raw == 'M' || raw == 'NON SATISFAISANT') {
                      displayText = 'Non Satisfaisant';
                      essaiColor = nonConformeColor;
                    } else if (raw == 'NE' || raw == 'SO' || raw == 'SANS OBJET') {
                      displayText = 'Sans Objet';
                      essaiColor = null;
                    } else {
                      displayText = es.essai;
                      essaiColor = null;
                    }

                    final precisionVal = (es.precision != null && es.precision!.trim().isNotEmpty)
                        ? es.precision!.trim()
                        : (es.designationCircuit != null && es.designationCircuit!.trim().isNotEmpty
                            ? es.designationCircuit!.trim()
                            : '-');

                    final calibreDisplay = es.calibre != null
                        ? '${es.calibre! % 1 == 0 ? es.calibre!.toInt() : es.calibre}'
                        : '-';

                    ddrTableRows.add(
                      pw.TableRow(
                        children: [
                          // Cellule 0 : Zone
                          _buildGroupedCellWidget(
                            currentIndex: currentZoneItemIdx,
                            totalRows: totalZoneItems,
                            text: zGroup.zoneName,
                            style: pw.TextStyle(font: _fontBold, fontSize: 8.5),
                            border: zoneBorder,
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          ),

                          // Cellule 1 : Repère
                          _buildGroupedCellWidget(
                            currentIndex: currentRepItemIdx,
                            totalRows: totalRepereItems,
                            text: rGroup.repereName.isNotEmpty
                                ? rGroup.repereName
                                : (zGroup.zoneName.isNotEmpty ? zGroup.zoneName : ''),
                            style: pw.TextStyle(font: _fontBold, fontSize: 8.5),
                            border: repereBorder,
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          ),

                          // Cellule 2 : N°
                          pw.Container(
                            decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              '${rowItem.index}',
                              style: pw.TextStyle(font: _fontBold, fontSize: 8.5),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),

                          // Cellule 3 : Désignation
                          _buildGroupedCellWidget(
                            currentIndex: currentEqItemIdx,
                            totalRows: eqCount,
                            text: eGroup.equipmentName,
                            style: pw.TextStyle(font: _fontBold, fontSize: 8.5),
                            border: equipmentBorder,
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          ),

                          // Cellule 4 : Précision
                          pw.Container(
                            decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              precisionVal,
                              style: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),

                          // Cellule 5 : Type de dispositif
                          pw.Container(
                            decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              es.displayTypeDispositif,
                              style: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),

                          // Cellule 6 : Calibre (A)
                          pw.Container(
                            decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              calibreDisplay,
                              style: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),

                          // Cellule 7 : IAn (mA)
                          pw.Container(
                            decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              es.reglageIAn != null
                                  ? '${es.reglageIAn! % 1 == 0 ? es.reglageIAn!.toInt() : es.reglageIAn}'
                                  : '-',
                              style: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),

                          // Cellule 8 : Tempo (s)
                          pw.Container(
                            decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              es.displayTempo,
                              style: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),

                          // Cellule 9 : Essai
                          pw.Container(
                            decoration: pw.BoxDecoration(color: essaiColor ?? bg, border: itemBorder),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              displayText,
                              style: pw.TextStyle(font: _fontRegular, fontSize: 8.5),
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
          }

          widgets.add(
            pw.Table(
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
              border: const pw.TableBorder(
                left: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
                right: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
                bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
                verticalInside: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
                horizontalInside: pw.BorderSide.none,
              ),
              columnWidths: ddrColumnWidthsData,
              children: ddrTableRows,
            ),
          );

          widgets.add(pw.SizedBox(height: 12));
          widgets.add(_buildAbreviationsTable());

          return widgets;
        },
      ),
    );

    // 3. Essais de mesure d'isolement (nouvelle page en paysage)
    pdf.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: innerTheme(
          pageOffset: pageOffset,
          overrideTotalPages: overrideTotalPages,
          pageFormat: PdfPageFormat.a4.landscape,
        ),
        header: (ctx) => pageHeader(
          nomSite: nomSite,
          numeroRapport: numeroRapport,
        ),
        build: (ctx) {
          final widgets = <pw.Widget>[];

          widgets.add(
            PageTracker(
              key: 'mesures_isolement',
              registry: trackedPages,
              offset: pageOffset,
              child: _subSectionBar(
                "3. Essais de mesure d'isolement entre deux points d'un tronçon de câble",
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 5));

          if (mesures.essaisIsolement.isEmpty) {
            widgets.add(_resultBox('Sans objet'));
            return widgets;
          }

          final availEquips = audit != null && audit.missionId.isNotEmpty
              ? HiveService.getAllEquipementsIsolementForMission(audit.missionId)
              : <EquipementIsolementItem>[];
          final isoRows = <_IsolementRowItem>[];
          for (int i = 0; i < mesures.essaisIsolement.length; i++) {
            final ei = mesures.essaisIsolement[i];
            final infoA = ei.resolvePointAInfo(availEquips);
            final infoB = ei.resolvePointBInfo(availEquips);

            final locInfo = _resolveLocation(
              audit,
              localisationStr: ei.displayRepereOrigine,
              coffretStr: ei.pointA,
            );

            String zoneName = infoA.zone.trim().isNotEmpty ? infoA.zone.trim() : locInfo.zoneName.trim();
            String repereName = EssaiIsolement.computeRepereDerive(
              infoA.repere.isNotEmpty ? infoA.repere : locInfo.repereName,
              infoB.repere,
            ).trim();

            if (zoneName.isEmpty && ei.displayRepereOrigine.trim().isNotEmpty) {
              final rawRep = ei.displayRepereOrigine.trim();
              if (rawRep.toLowerCase().startsWith('zone ') || rawRep.toLowerCase().startsWith('zone_')) {
                zoneName = rawRep;
                repereName = '';
              } else {
                repereName = rawRep;
              }
            }

            final String effectiveRepere = repereName.isNotEmpty
                ? repereName
                : (zoneName.isNotEmpty ? zoneName : '-');

            isoRows.add(
              _IsolementRowItem(
                zoneName: zoneName,
                repereName: effectiveRepere,
                index: i + 1,
                item: ei,
                infoA: infoA,
                infoB: infoB,
              ),
            );
          }

          final isoZoneGroups = <_IsolementZoneGroup>[];
          for (final row in isoRows) {
            final normZone = row.zoneName.trim();

            var zGroup = isoZoneGroups.firstWhere(
              (zg) => zg.zoneName.toLowerCase() == normZone.toLowerCase(),
              orElse: () {
                final zg = _IsolementZoneGroup(zoneName: normZone, items: []);
                isoZoneGroups.add(zg);
                return zg;
              },
            );

            zGroup.items.add(row);
          }

          String stripMm2(String val) {
            final clean = val.replaceAll('mm²', '').replaceAll('mm2', '').replaceAll('MM²', '').trim();
            if (clean.isEmpty || clean == '0') return '-';
            return clean;
          }

          const isoColumnWidths = <int, pw.TableColumnWidth>{
            0: pw.FlexColumnWidth(1.2), // ZONE
            1: pw.FlexColumnWidth(1.5), // Repère du point d'origine
            2: pw.FixedColumnWidth(20), // N°
            3: pw.FlexColumnWidth(1.6), // Point A (origine)
            4: pw.FlexColumnWidth(1.6), // Point B (extrémité)
            5: pw.FlexColumnWidth(1.3), // SECTION DE CÂBLE A (mm²)
            6: pw.FlexColumnWidth(1.3), // SECTION DE CÂBLE B (mm²)
            7: pw.FlexColumnWidth(1.2), // NATURE DU CÂBLE
            8: pw.FlexColumnWidth(0.9), // Nb. câbles
            9: pw.FlexColumnWidth(1.1), // Isolement (MΩ)
            10: pw.FlexColumnWidth(1.4), // Appréciation
          };

          final headerRow = pw.TableRow(
            repeat: true,
            decoration: pw.BoxDecoration(color: accentColor),
            children: [
              _thHeaderCell("ZONE"),
              _thHeaderCell("Repère du point d'origine"),
              _thHeaderCell("N°"),
              _thHeaderCell("Point A (origine)"),
              _thHeaderCell("Point B (extrémité)"),
              _thHeaderCell("SECTION DE CÂBLE A (mm²)"),
              _thHeaderCell("SECTION DE CÂBLE B (mm²)"),
              _thHeaderCell("NATURE DU CÂBLE"),
              _thHeaderCell("Nb. câbles"),
              _thHeaderCell("Isolement (MΩ)"),
              _thHeaderCell("Appréciation"),
            ],
          );

          // 2. Table Data Rows
          final isoTableRows = <pw.TableRow>[];
          int globalRowIndex = 0;

          for (final zGroup in isoZoneGroups) {
            final totalZoneItems = zGroup.items.length;
            final zoneMidIndex = (totalZoneItems - 1) ~/ 2;

            for (int currentZoneItemIdx = 0; currentZoneItemIdx < totalZoneItems; currentZoneItemIdx++) {
              final rowItem = zGroup.items[currentZoneItemIdx];
              final ei = rowItem.item;

              final idx = globalRowIndex++;
              final isEven = idx % 2 == 0;
              final bg = isEven ? PdfColors.white : tableRowAlt;

              final isStartOfZone = (currentZoneItemIdx == 0 && idx > 0);
              final isEndOfZone = (currentZoneItemIdx == totalZoneItems - 1);

              final zoneBorder = pw.Border(
                top: isStartOfZone
                    ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                    : pw.BorderSide.none,
                bottom: isEndOfZone
                    ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                    : pw.BorderSide.none,
              );

              final itemBorder = pw.Border(
                top: isStartOfZone
                    ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                    : pw.BorderSide.none,
                bottom: isEndOfZone
                    ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                    : const pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.4),
              );

              final app = ei.appreciation;
              final isSat = app == 'Satisfaisant';
              final isNonSat = app == 'Non satisfaisant';
              final appBgColor = isSat
                  ? conformeColor
                  : (isNonSat ? nonConformeColor : PdfColor.fromInt(0xFFEEEEEE));

              isoTableRows.add(
                pw.TableRow(
                  children: [
                    // Cellule 0 : ZONE
                    _buildGroupedCellWidget(
                      currentIndex: currentZoneItemIdx,
                      totalRows: totalZoneItems,
                      text: zGroup.zoneName,
                      style: pw.TextStyle(font: _fontBold, fontSize: 8.5),
                      border: zoneBorder,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    ),

                    // Cellule 1 : Repère du point d'origine
                    pw.Container(
                      decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        rowItem.repereName.isNotEmpty ? rowItem.repereName : '-',
                        style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),

                    // Cellule 2 : N°
                    pw.Container(
                      decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        '${rowItem.index}',
                        style: pw.TextStyle(font: _fontBold, fontSize: 8.5),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),

                    // Cellule 3 : Point A (origine)
                    pw.Container(
                      decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        (rowItem.infoA != null && rowItem.infoA!.nomEquipement.isNotEmpty)
                            ? rowItem.infoA!.nomEquipement
                            : ei.displayPointA,
                        style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),

                    // Cellule 4 : Point B (extrémité)
                    pw.Container(
                      decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        (rowItem.infoB != null && rowItem.infoB!.nomEquipement.isNotEmpty)
                            ? rowItem.infoB!.nomEquipement
                            : ei.displayPointB,
                        style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),

                    // Cellule 5 : SECTION DE CÂBLE A (mm²)
                    pw.Container(
                      decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        stripMm2(ei.displaySectionPointA),
                        style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),

                    // Cellule 6 : SECTION DE CÂBLE B (mm²)
                    pw.Container(
                      decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        stripMm2(ei.displaySectionPointB),
                        style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),

                    // Cellule 7 : NATURE DU CÂBLE
                    pw.Container(
                      decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        (ei.natureCable != null && ei.natureCable!.trim().isNotEmpty) ? ei.natureCable!.trim() : '-',
                        style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),

                    // Cellule 8 : Nb. câbles
                    pw.Container(
                      decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        ei.displayNombreCables,
                        style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),

                    // Cellule 9 : Isolement (MΩ)
                    pw.Container(
                      decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        ei.displayIsolement,
                        style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),

                    // Cellule 10 : Appréciation
                    pw.Container(
                      decoration: pw.BoxDecoration(color: appBgColor, border: itemBorder),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        app,
                        style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.black),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }
          }

          widgets.add(
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
              columnWidths: isoColumnWidths,
              children: [headerRow, ...isoTableRows],
            ),
          );

          return widgets;
        },
      ),
    );

    // 4. Test CPI (nouvelle page dédiée en paysage)
    pdf.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: innerTheme(
          pageOffset: pageOffset,
          overrideTotalPages: overrideTotalPages,
          pageFormat: PdfPageFormat.a4.landscape,
        ),
        header: (ctx) => pageHeader(
          nomSite: nomSite,
          numeroRapport: numeroRapport,
        ),
        build: (ctx) {
          final widgets = <pw.Widget>[];

          widgets.add(
            PageTracker(
              key: 'mesures_cpi',
              registry: trackedPages,
              offset: pageOffset,
              child: _subSectionBar(
                "4. Test du Contrôleur Permanent d'Isolement (CPI)",
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 8));

          // Récupération des tests CPI (avec rétrocompatibilité desc.cpi)
          final cpiTests = List<CpiTest>.from(mesures.cpiTests);
          if (cpiTests.isEmpty && desc != null && desc.cpi.isNotEmpty) {
            for (var item in desc.cpi) {
              final d = item.data;
              final marque = d['MARQUE'] ?? '';
              final type = d['TYPE'] ?? '';
              final cpiName = [marque, type].where((s) => s.trim().isNotEmpty).join(' ');
              cpiTests.add(CpiTest(
                id: 'hist_${item.hashCode}',
                equipmentNom: d['ARMOIRE'] ?? 'Armoire BT',
                transformateurNom: d['TRANSFORMATEUR'] ?? 'Non renseigné',
                zone: d['ZONE'] ?? '',
                repere: d['REPERE'] ?? '',
                cpi: cpiName.isNotEmpty ? cpiName : 'CPI',
                essaiDeclenchement: d['RESULTAT_TEST'] ?? (d['ESSAI_DECLENCHEMENT'] ?? 'Satisfaisant'),
                reportAlarme: d['REPORT_ALARME'] ?? 'Satisfaisant',
              ));
            }
          }

          const cpiColumnWidths = <int, pw.TableColumnWidth>{
            0: pw.FlexColumnWidth(1.4), // ZONE
            1: pw.FlexColumnWidth(1.6), // REPÈRE
            2: pw.FlexColumnWidth(2.0), // TRANSFORMATEUR
            3: pw.FlexColumnWidth(2.0), // ARMOIRE
            4: pw.FlexColumnWidth(2.0), // CPI
            5: pw.FlexColumnWidth(1.8), // ESSAIS DE DÉCLENCHEMENT
            6: pw.FlexColumnWidth(1.8), // VÉRIF. DU REPORT D'ALARME
          };

          // 1. En-tête de tableau CPI
          final headerTable = pw.Table(
            border: const pw.TableBorder(
              left: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
              right: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
              top: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
              bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
              verticalInside: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
              horizontalInside: pw.BorderSide.none,
            ),
            columnWidths: cpiColumnWidths,
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: accentColor),
                children: [
                  _thHeaderCell("ZONE"),
                  _thHeaderCell("REPÈRE"),
                  _thHeaderCell("TRANSFORMATEUR"),
                  _thHeaderCell("ARMOIRE"),
                  _thHeaderCell("CPI"),
                  _thHeaderCell("ESSAIS DE DÉCLENCHEMENT"),
                  _thHeaderCell("VÉRIF. DU REPORT D'ALARME"),
                ],
              ),
            ],
          );
          widgets.add(headerTable);

          if (cpiTests.isEmpty) {
            // Ligne état vide propre dans la table
            final emptyTable = pw.Table(
              border: const pw.TableBorder(
                left: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
                right: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
                bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
                verticalInside: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
                horizontalInside: pw.BorderSide.none,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.0),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.white),
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'NÉANT - Aucun Contrôleur Permanent d\'Isolement (CPI) recensé ou testé pour cette installation',
                        style: pw.TextStyle(
                          font: _fontRegular,
                          fontSize: fsSmall,
                          color: darkGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
            widgets.add(emptyTable);
            widgets.add(_buildCpiExplanations());
            return widgets;
          }

          // Tri déterministe : Zone -> Repère -> Transformateur -> Armoire -> CPI
          final sortedTests = List<CpiTest>.from(cpiTests);
          sortedTests.sort((a, b) {
            final zA = a.zone ?? '';
            final zB = b.zone ?? '';
            final cmpZ = zA.toLowerCase().compareTo(zB.toLowerCase());
            if (cmpZ != 0) return cmpZ;

            final rA = a.repere ?? '';
            final rB = b.repere ?? '';
            final cmpR = rA.toLowerCase().compareTo(rB.toLowerCase());
            if (cmpR != 0) return cmpR;

            final tA = a.transformateurNom ?? '';
            final tB = b.transformateurNom ?? '';
            final cmpT = tA.toLowerCase().compareTo(tB.toLowerCase());
            if (cmpT != 0) return cmpT;

            final eA = a.equipmentNom ?? '';
            final eB = b.equipmentNom ?? '';
            final cmpE = eA.toLowerCase().compareTo(eB.toLowerCase());
            if (cmpE != 0) return cmpE;

            return a.cpi.toLowerCase().compareTo(b.cpi.toLowerCase());
          });

          // Regroupement hiérarchique : Zone -> Repère -> Transformateur -> Armoire
          final zoneGroups = <_CpiZoneGroup>[];
          for (int i = 0; i < sortedTests.length; i++) {
            final test = sortedTests[i];
            final zName = (test.zone ?? '').trim();
            final rName = (test.repere ?? '').trim();
            final tName = (test.transformateurNom ?? 'Non renseigné').trim();
            final aName = (test.equipmentNom ?? 'Armoire BT').trim();

            var zGroup = zoneGroups.firstWhere(
              (g) => g.zoneName == zName,
              orElse: () {
                final ng = _CpiZoneGroup(zoneName: zName, repereGroups: []);
                zoneGroups.add(ng);
                return ng;
              },
            );

            var rGroup = zGroup.repereGroups.firstWhere(
              (g) => g.repereName == rName,
              orElse: () {
                final ng = _CpiRepereGroup(repereName: rName, transfoGroups: []);
                zGroup.repereGroups.add(ng);
                return ng;
              },
            );

            var tGroup = rGroup.transfoGroups.firstWhere(
              (g) => g.transformateurName == tName,
              orElse: () {
                final ng = _CpiTransfoGroup(transformateurName: tName, armoireGroups: []);
                rGroup.transfoGroups.add(ng);
                return ng;
              },
            );

            var aGroup = tGroup.armoireGroups.firstWhere(
              (g) => g.armoireName == aName,
              orElse: () {
                final ng = _CpiArmoireGroup(armoireName: aName, items: []);
                tGroup.armoireGroups.add(ng);
                return ng;
              },
            );

            aGroup.items.add(_CpiRowItem(
              zoneName: zName,
              repereName: rName,
              transformateurName: tName,
              armoireName: aName,
              index: i + 1,
              item: test,
            ));
          }

          // Construction des lignes de tableau avec cellules fusionnées
          final cpiTableRows = <pw.TableRow>[];
          int globalRowIndex = 0;

          for (final zGroup in zoneGroups) {
            final totalZoneItems = zGroup.totalRows;
            int currentZoneItemIdx = 0;

            for (final rGroup in zGroup.repereGroups) {
              final totalRepereItems = rGroup.totalRows;
              int currentRepereItemIdx = 0;

              for (final tGroup in rGroup.transfoGroups) {
                final totalTransfoItems = tGroup.totalRows;
                int currentTransfoItemIdx = 0;

                for (final aGroup in tGroup.armoireGroups) {
                  final totalArmoireItems = aGroup.items.length;

                  for (int currentArmoireItemIdx = 0;
                      currentArmoireItemIdx < totalArmoireItems;
                      currentArmoireItemIdx++) {
                    final rowItem = aGroup.items[currentArmoireItemIdx];
                    final test = rowItem.item;

                    final idx = globalRowIndex++;
                    final isEven = idx % 2 == 0;
                    final bg = isEven ? PdfColors.white : tableRowAlt;

                    final isStartOfZone = (currentZoneItemIdx == 0 && idx > 0);
                    final isEndOfZone = (currentZoneItemIdx == totalZoneItems - 1);

                    final zoneBorder = pw.Border(
                      top: isStartOfZone
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                          : pw.BorderSide.none,
                      bottom: isEndOfZone
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                          : pw.BorderSide.none,
                    );

                    final repereBorder = pw.Border(
                      top: (currentRepereItemIdx == 0 && idx > 0)
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 0.8)
                          : pw.BorderSide.none,
                      bottom: (currentRepereItemIdx == totalRepereItems - 1)
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 0.8)
                          : pw.BorderSide.none,
                    );

                    final transfoBorder = pw.Border(
                      top: (currentTransfoItemIdx == 0 && idx > 0)
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 0.6)
                          : pw.BorderSide.none,
                      bottom: (currentTransfoItemIdx == totalTransfoItems - 1)
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 0.6)
                          : pw.BorderSide.none,
                    );

                    final armoireBorder = pw.Border(
                      top: (currentArmoireItemIdx == 0 && idx > 0)
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 0.6)
                          : pw.BorderSide.none,
                      bottom: (currentArmoireItemIdx == totalArmoireItems - 1)
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 0.6)
                          : pw.BorderSide.none,
                    );

                    final itemBorder = pw.Border(
                      top: isStartOfZone
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                          : pw.BorderSide.none,
                      bottom: isEndOfZone
                          ? const pw.BorderSide(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.0)
                          : const pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.4),
                    );

                    // Couleur résultat essai déclenchement
                    final declLower = test.essaiDeclenchement.toLowerCase();
                    final isDeclSat = declLower.contains('satisfaisant') && !declLower.contains('non');
                    final isDeclNonSat = declLower.contains('non');
                    final declBg = isDeclSat
                        ? conformeColor
                        : (isDeclNonSat ? nonConformeColor : PdfColor.fromInt(0xFFEEEEEE));

                    // Couleur résultat report d'alarme
                    final alarmeLower = test.reportAlarme.toLowerCase();
                    final isAlarmeSat = alarmeLower.contains('satisfaisant') && !alarmeLower.contains('non');
                    final isAlarmeNonSat = alarmeLower.contains('non');
                    final alarmeBg = isAlarmeSat
                        ? conformeColor
                        : (isAlarmeNonSat ? nonConformeColor : PdfColor.fromInt(0xFFEEEEEE));

                    cpiTableRows.add(
                      pw.TableRow(
                        children: [
                          // Cellule 0 : ZONE
                          _buildGroupedCellWidget(
                            currentIndex: currentZoneItemIdx,
                            totalRows: totalZoneItems,
                            text: zGroup.zoneName.isNotEmpty ? zGroup.zoneName : '-',
                            style: pw.TextStyle(font: _fontBold, fontSize: 8.5),
                            border: zoneBorder,
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          ),

                          // Cellule 1 : REPÈRE
                          _buildGroupedCellWidget(
                            currentIndex: currentRepereItemIdx,
                            totalRows: totalRepereItems,
                            text: rGroup.repereName.isNotEmpty ? rGroup.repereName : '-',
                            style: pw.TextStyle(font: _fontBold, fontSize: 8.5),
                            border: repereBorder,
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          ),

                          // Cellule 2 : TRANSFORMATEUR
                          _buildGroupedCellWidget(
                            currentIndex: currentTransfoItemIdx,
                            totalRows: totalTransfoItems,
                            text: tGroup.transformateurName.isNotEmpty ? tGroup.transformateurName : '-',
                            style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                            border: transfoBorder,
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          ),

                          // Cellule 3 : ARMOIRE
                          _buildGroupedCellWidget(
                            currentIndex: currentArmoireItemIdx,
                            totalRows: totalArmoireItems,
                            text: aGroup.armoireName.isNotEmpty ? aGroup.armoireName : '-',
                            style: pw.TextStyle(font: _fontBold, fontSize: 8.5),
                            border: armoireBorder,
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          ),

                          // Cellule 4 : CPI
                          pw.Container(
                            decoration: pw.BoxDecoration(color: bg, border: itemBorder),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              test.cpi.isNotEmpty ? test.cpi : '-',
                              style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),

                          // Cellule 5 : ESSAIS DE DÉCLENCHEMENT
                          pw.Container(
                            decoration: pw.BoxDecoration(color: declBg, border: itemBorder),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              test.essaiDeclenchement.isNotEmpty ? test.essaiDeclenchement : '-',
                              style: pw.TextStyle(
                                font: (isDeclSat || isDeclNonSat) ? _fontBold : _fontRegular,
                                fontSize: fsSmall,
                                color: PdfColors.black,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),

                          // Cellule 6 : VÉRIF. DU REPORT D'ALARME
                          pw.Container(
                            decoration: pw.BoxDecoration(color: alarmeBg, border: itemBorder),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              test.reportAlarme.isNotEmpty ? test.reportAlarme : '-',
                              style: pw.TextStyle(
                                font: (isAlarmeSat || isAlarmeNonSat) ? _fontBold : _fontRegular,
                                fontSize: fsSmall,
                                color: PdfColors.black,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );

                    currentZoneItemIdx++;
                    currentRepereItemIdx++;
                    currentTransfoItemIdx++;
                  }
                }
              }
            }
          }

          widgets.add(
            pw.Table(
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
              border: const pw.TableBorder(
                left: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
                right: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
                bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
                verticalInside: pw.BorderSide(color: PdfColor.fromInt(0xFF9CA3AF), width: 0.4),
                horizontalInside: pw.BorderSide.none,
              ),
              columnWidths: cpiColumnWidths,
              children: cpiTableRows,
            ),
          );

          widgets.add(_buildCpiExplanations());

          return widgets;
        },
      ),
    );

    // 5 & 6. GE et Arrêt d'urgence (page dédiée en portrait)
    pdf.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: innerTheme(
          pageOffset: pageOffset,
          overrideTotalPages: overrideTotalPages,
        ),
        header: (ctx) => pageHeader(
          nomSite: nomSite,
          numeroRapport: numeroRapport,
        ),
        build: (ctx) => [
          PageTracker(
            key: 'mesures_demarrage',
            registry: trackedPages,
            offset: pageOffset,
            child: _subSectionBar(
              '5. Essais de démarrage automatique du groupe électrogène',
            ),
          ),
          pw.SizedBox(height: 5),
          _resultBox(
            mesures.essaiDemarrageAuto.observation ?? 'Non satisfaisant',
          ),

          pw.SizedBox(height: 16),

          PageTracker(
            key: 'mesures_arret',
            registry: trackedPages,
            offset: pageOffset,
            child: _subSectionBar(
              "6. Test de fonctionnement de l'arrêt d'urgence",
            ),
          ),
          pw.SizedBox(height: 5),
          _resultBox(
            !mesures.testArretUrgence.estPresent
                ? "Arrêt d'urgence général absent"
                : (mesures.testArretUrgence.observation ?? 'Sans objet'),
          ),
        ],
      ),
    );

    // 7. Continuité (nouvelle page en paysage)
    pdf.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: innerTheme(
          pageOffset: pageOffset,
          overrideTotalPages: overrideTotalPages,
          pageFormat: PdfPageFormat.a4.landscape,
        ),
        header: (ctx) => pageHeader(
          nomSite: nomSite,
          numeroRapport: numeroRapport,
        ),
        build: (ctx) {
          final contRows = <_ContinuiteRowItem>[];
          for (int i = 0; i < mesures.continuiteResistances.length; i++) {
            final c = mesures.continuiteResistances[i];
            final locInfo = _resolveLocation(audit, localisationStr: c.localisation);
            String zName = locInfo.zoneName.trim();
            String rName = locInfo.repereName.trim();
            if (zName.isEmpty && rName.isEmpty && c.localisation.trim().isNotEmpty) {
              final locClean = c.localisation.trim();
              if (locClean.toLowerCase().startsWith('zone ') || locClean.toLowerCase().startsWith('zone_')) {
                zName = locClean;
                rName = '';
              } else {
                zName = '';
                rName = locClean;
              }
            }
            contRows.add(_ContinuiteRowItem(
              zoneName: zName,
              repereName: rName,
              index: i + 1,
              item: c,
            ));
          }

          final contZoneGroups = <_ContinuiteZoneGroup>[];
          for (final item in contRows) {
            var zGroup = contZoneGroups.firstWhere(
              (zg) => zg.zoneName.toLowerCase() == item.zoneName.toLowerCase(),
              orElse: () {
                final zg = _ContinuiteZoneGroup(zoneName: item.zoneName, repereGroups: []);
                contZoneGroups.add(zg);
                return zg;
              },
            );

            var rGroup = zGroup.repereGroups.firstWhere(
              (rg) => rg.repereName.toLowerCase() == item.repereName.toLowerCase(),
              orElse: () {
                final rg = _ContinuiteRepereGroup(repereName: item.repereName, items: []);
                zGroup.repereGroups.add(rg);
                return rg;
              },
            );

            rGroup.items.add(item);
          }

          final tableRows = <pw.TableRow>[];
          tableRows.add(
            pw.TableRow(
              decoration: pw.BoxDecoration(color: accentColor),
              children: [
                _thHeaderCell('Zone'),
                _thHeaderCell('Repère'),
                _thHeaderCell('N°'),
                _thHeaderCell('Désignation Tableau / Equipement'),
                _thHeaderCell('Origine Mesure'),
                _thHeaderCell('Essai'),
                _thHeaderCell('Observation'),
              ],
            ),
          );

          if (mesures.continuiteResistances.isEmpty) {
            tableRows.add(
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.white),
                children: List.generate(
                  7,
                  (_) => _cell('', isHeader: false, centered: true),
                ),
              ),
            );
          } else {
            int globalRowIndex = 0;
            for (final zoneGroup in contZoneGroups) {
              final totalZoneItems = zoneGroup.repereGroups.fold<int>(
                0,
                (sum, rg) => sum + rg.items.length,
              );
              final zoneMidIndex = (totalZoneItems - 1) ~/ 2;
              int zoneRowIdx = 0;

              for (int rIdx = 0; rIdx < zoneGroup.repereGroups.length; rIdx++) {
                final repereGroup = zoneGroup.repereGroups[rIdx];
                final totalRepereItems = repereGroup.items.length;
                final repereMidIndex = (totalRepereItems - 1) ~/ 2;

                for (int i = 0; i < totalRepereItems; i++) {
                  final rowItem = repereGroup.items[i];
                  final c = rowItem.item;
                  final currentZoneRowIdx = zoneRowIdx++;
                  final currentRepereRowIdx = i;

                  final idx = globalRowIndex++;
                  final isStartOfZone = (currentZoneRowIdx == 0 && idx > 0);
                  final isStartOfRepere = (currentRepereRowIdx == 0 && currentZoneRowIdx > 0);

                  final isEndOfRepere = (currentRepereRowIdx == totalRepereItems - 1);
                  final isEndOfZone = (currentZoneRowIdx == totalZoneItems - 1);

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

                  final essaiVal = c.essai?.trim();
                  PdfColor? essaiBg;
                  String textEssai = '-';
                  if (essaiVal == 'Satisfaisant') {
                    essaiBg = conformeColor;
                    textEssai = 'Satisfaisant';
                  } else if (essaiVal == 'Non satisfaisant') {
                    essaiBg = nonConformeColor;
                    textEssai = 'Non satisfaisant';
                  } else if (essaiVal == 'Sans objet') {
                    essaiBg = sansObjetColor;
                    textEssai = 'Sans objet';
                  }

                  final bg = globalRowIndex.isOdd ? tableRowAlt : PdfColors.white;
                  globalRowIndex++;

                  tableRows.add(
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: bg),
                      children: [
                        // Cellule 0 : Zone
                        _buildGroupedCellWidget(
                          currentIndex: currentZoneRowIdx,
                          totalRows: totalZoneItems,
                          text: zoneGroup.zoneName,
                          style: pw.TextStyle(font: _fontBold, fontSize: 8.0, color: headerColor),
                          border: zoneBorder,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        ),

                        // Cellule 1 : Repère
                        _buildGroupedCellWidget(
                          currentIndex: currentRepereRowIdx,
                          totalRows: totalRepereItems,
                          text: repereGroup.repereName.isNotEmpty
                              ? repereGroup.repereName
                              : (zoneGroup.zoneName.isNotEmpty ? zoneGroup.zoneName : ''),
                          style: pw.TextStyle(font: _fontBold, fontSize: 8.0, color: headerColor),
                          border: repereBorder,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        ),

                        // Cellule 2 : N°
                        pw.Container(
                          decoration: pw.BoxDecoration(border: itemBorder),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            '${rowItem.index}',
                            style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),

                        // Cellule 3 : Désignation Tableau / Équipement
                        pw.Container(
                          decoration: pw.BoxDecoration(border: itemBorder),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            c.designationTableau.isNotEmpty ? c.designationTableau : '-',
                            style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),

                        // Cellule 4 : Origine Mesure
                        pw.Container(
                          decoration: pw.BoxDecoration(border: itemBorder),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            c.origineMesure.isNotEmpty ? c.origineMesure : '-',
                            style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),

                        // Cellule 5 : Essai
                        pw.Container(
                          decoration: pw.BoxDecoration(color: essaiBg, border: itemBorder),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            textEssai,
                            style: pw.TextStyle(
                              font: (essaiVal != null && essaiVal.isNotEmpty) ? _fontBold : _fontRegular,
                              fontSize: fsSmall,
                              color: PdfColors.black,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),

                        // Cellule 6 : Observation
                        pw.Container(
                          decoration: pw.BoxDecoration(border: itemBorder),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Text(
                            c.observation?.isNotEmpty == true ? c.observation! : '-',
                            style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }
            }
          }

          return [
            PageTracker(
              key: 'mesures_continuite',
              registry: trackedPages,
              offset: pageOffset,
              child: _subSectionBar(
                '7. Continuité et de la résistance des conducteurs de protection et des liaisons équipotentielles',
              ),
            ),
            pw.SizedBox(height: 8),
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
                0: pw.FlexColumnWidth(1.2), // Zone
                1: pw.FlexColumnWidth(1.4), // Repère
                2: pw.FixedColumnWidth(24), // N°
                3: pw.FlexColumnWidth(2.2), // Désignation Tableau / Equipement
                4: pw.FlexColumnWidth(1.4), // Origine Mesure
                5: pw.FlexColumnWidth(1.3), // Essai
                6: pw.FlexColumnWidth(1.8), // Observation
              },
              children: tableRows,
            ),
          ];
        },
      ),
    );
  }

}
