import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';
import 'package:inspec_app/services/pdf/pdf_photo_context.dart';
import 'package:inspec_app/components/safe_file_image.dart';
import 'package:path_provider/path_provider.dart';

class PdfEquipmentPhotoGroup {
  final CoffretArmoire coffret;
  final String locationPrefix;
  final PdfPhotoEntry? extPhoto;
  final PdfPhotoEntry? intPhoto;
  final List<PdfPhotoEntry> obsPhotos;

  PdfEquipmentPhotoGroup({
    required this.coffret,
    required this.locationPrefix,
    this.extPhoto,
    this.intPhoto,
    required this.obsPhotos,
  });

  bool get hasPhotos =>
      extPhoto != null || intPhoto != null || obsPhotos.isNotEmpty;
  int get totalPhotosCount =>
      (extPhoto != null ? 1 : 0) +
      (intPhoto != null ? 1 : 0) +
      obsPhotos.length;
}

class PdfPhotoEntry {
  final String filePath;
  final String description;
  final String? repere;
  final bool isObservation;
  final String? badgeLabel;
  final PdfColor? badgeBgColor;
  final PdfColor? badgeTextColor;

  PdfPhotoEntry({
    required this.filePath,
    required this.description,
    this.repere,
    this.isObservation = false,
    this.badgeLabel,
    this.badgeBgColor,
    this.badgeTextColor,
  });
}

class PdfPhotoSectionBlock {
  final String title;
  final String? subtitle;
  final List<PdfPhotoEntry> photos;
  final List<PdfEquipmentPhotoGroup> equipments;
  final List<PdfPhotoSectionBlock> subBlocks;

  PdfPhotoSectionBlock({
    required this.title,
    this.subtitle,
    this.photos = const [],
    this.equipments = const [],
    this.subBlocks = const [],
  });

  bool get hasContent =>
      photos.isNotEmpty ||
      equipments.any((e) => e.hasPhotos) ||
      subBlocks.any((sb) => sb.hasContent);

  int get totalPhotosCount =>
      photos.length +
      equipments.fold<int>(0, (sum, g) => sum + g.totalPhotosCount) +
      subBlocks.fold<int>(0, (sum, sb) => sum + sb.totalPhotosCount);
}

class PdfChunkSectionResult {
  final List<File> files;
  final int totalPages;
  PdfChunkSectionResult({required this.files, required this.totalPages});
}

typedef _EquipmentPhotoGroup = PdfEquipmentPhotoGroup;
typedef _PhotoEntry = PdfPhotoEntry;
typedef _PhotoSectionBlock = PdfPhotoSectionBlock;
typedef _ChunkSectionResult = PdfChunkSectionResult;

class PdfPhotosSchemasBuilder {
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
  static double get fsBody => PdfReportStyles.fsBody;
  static double get fsSmall => PdfReportStyles.fsSmall;

  static Future<pw.MemoryImage?> _defaultLoadImage(
    String path, {
    PdfPhotoContext photoContext = PdfPhotoContext.equipmentObs,
    int? maxWidth,
    int? maxHeight,
    int? quality,
    bool saveFilesToDisk = true,
  }) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;
    try {
      final resolved = await AppImageUtils.resolvePathAsync(trimmed);
      if (resolved == null) return null;
      final file = File(resolved);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return pw.MemoryImage(bytes);
    } catch (e) {
      return null;
    }
  }

  // --- Photo Banner Bar ---
  static pw.Widget _buildPhotoBannerBar({
    required String title,
    String? subtitle,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 6),
      margin: const pw.EdgeInsets.only(bottom: 2),
      decoration: pw.BoxDecoration(
        color: lightBlue,
        border: pw.Border.all(color: borderColor, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: fsSmall,
              color: headerColor,
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty)
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                font: _fontRegular,
                fontSize: fsSmall - 1,
                color: headerColor,
              ),
            ),
        ],
      ),
    );
  }


  static pw.Widget buildPhotoBannerBar({
    required String title,
    String? subtitle,
  }) =>
      _buildPhotoBannerBar(title: title, subtitle: subtitle);

  // --- Photo Cell Builder ---
  static pw.Widget _buildPhotoCell(
    _PhotoEntry entry,
    pw.MemoryImage? img,
    int index,
    int total,
  ) {
    final isObs = entry.isObservation;
    final cardBorderColor = isObs ? PdfColors.red700 : borderColor;
    final cardBorderWidth = isObs ? 1.5 : 0.8;
    final captionBgColor = isObs
        ? PdfColor.fromInt(0xFFFFEBEE)
        : PdfColor.fromInt(0xFFF0F4FA);

    return pw.Container(
      margin: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: cardBorderColor, width: cardBorderWidth),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColors.grey400,
            blurRadius: 2,
            offset: const PdfPoint(1, 1),
          ),
        ],
      ),
      child: pw.ClipRRect(
        horizontalRadius: 3,
        verticalRadius: 3,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Bande de titre (avec badge ANOMALIE si isObs)
            pw.Container(
              color: isObs ? PdfColors.red800 : headerColor,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 3,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        'Photo $index / $total',
                        style: pw.TextStyle(
                          font: _fontBold,
                          fontSize: 6,
                          color: PdfColors.white,
                        ),
                      ),
                      if (entry.badgeLabel != null &&
                          entry.badgeLabel!.isNotEmpty) ...[
                        pw.SizedBox(width: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: pw.BoxDecoration(
                            color: entry.badgeBgColor ?? PdfColors.white,
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(2),
                            ),
                          ),
                          child: pw.Text(
                            entry.badgeLabel!,
                            style: pw.TextStyle(
                              font: _fontBold,
                              fontSize: 5,
                              color: entry.badgeTextColor ?? PdfColors.white,
                            ),
                          ),
                        ),
                      ] else if (isObs) ...[
                        pw.SizedBox(width: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.all(
                              pw.Radius.circular(2),
                            ),
                          ),
                          child: pw.Text(
                            'ANOMALIE',
                            style: pw.TextStyle(
                              font: _fontBold,
                              fontSize: 5,
                              color: PdfColors.red700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (entry.repere != null && entry.repere!.isNotEmpty)
                    pw.Text(
                      'Réf : ${entry.repere}',
                      style: pw.TextStyle(
                        font: _fontBold,
                        fontSize: 6,
                        color: PdfColors.yellow,
                      ),
                    ),
                ],
              ),
            ),
            // Image : couvre tout le cadre (BoxFit.cover)
            pw.Expanded(
              child: img != null
                  ? pw.Image(img, fit: pw.BoxFit.cover)
                  : pw.Container(
                      color: PdfColors.grey100,
                      child: pw.Center(
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Container(
                              width: 24,
                              height: 24,
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.grey300,
                                shape: pw.BoxShape.circle,
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  '?',
                                  style: pw.TextStyle(
                                    font: _fontBold,
                                    fontSize: 14,
                                    color: PdfColors.grey500,
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Image non disponible',
                              style: pw.TextStyle(
                                font: _fontRegular,
                                fontSize: 6,
                                color: PdfColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            // Légende en bas
            pw.Container(
              color: captionBgColor,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 3,
              ),
              child: pw.Text(
                entry.description,
                style: pw.TextStyle(
                  font: isObs ? _fontBold : _fontRegular,
                  fontSize: 5.5,
                  color: isObs ? PdfColors.red900 : darkGrey,
                ),
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget buildPhotoCell(
    PdfPhotoEntry entry,
    pw.MemoryImage? img,
    int index,
    int total,
  ) =>
      _buildPhotoCell(entry, img, index, total);

  // --- Schema Section ---
  static void addSchemaSection(
    pw.Document pdf,
    Mission mission,
    Map<String, int> trackedPages, {
    String? nomSite,
    String? numeroRapport,
    int pageOffset = 0,
    int? overrideTotalPages,
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
  }) {
    final hasSchema = mission.schemaOption?.trim().toLowerCase() == 'oui';
    if (!hasSchema) return;

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

    pdf.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: innerTheme(
          pageOffset: pageOffset,
          overrideTotalPages: overrideTotalPages,
          showWatermark: true,
        ),
        header: (ctx) => pageHeader(
          nomClient: mission.nomClient,
          nomSite: nomSite,
          numeroRapport: numeroRapport,
        ),
        build: (ctx) => [
          pw.SizedBox(height: 295),
          pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(width: 350, height: 2, color: accentColor),
                pw.SizedBox(height: 24),
                PageTracker(
                  key: 'schema_installations',
                  registry: trackedPages,
                  offset: pageOffset,
                  child: pw.Text(
                    'SCH\u00c9MA DES INSTALLATIONS ELECTRIQUES',
                    style: pw.TextStyle(
                      font: _fontBold,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: headerColor,
                      letterSpacing: 1.0,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  (nomSite ?? mission.nomClient).toUpperCase(),
                  style: pw.TextStyle(
                    font: _fontRegular,
                    fontSize: 13,
                    color: accentColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 24),
                pw.Container(width: 350, height: 2, color: accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }


  static void _addSchemaSection(
    pw.Document pdf,
    Mission mission,
    Map<String, int> trackedPages, {
    String? nomSite,
    String? numeroRapport,
    int pageOffset = 0,
    int? overrideTotalPages,
  }) =>
      addSchemaSection(
        pdf,
        mission,
        trackedPages,
        nomSite: nomSite,
        numeroRapport: numeroRapport,
        pageOffset: pageOffset,
        overrideTotalPages: overrideTotalPages,
      );

  // --- Photos Section Chunked ---
  static Future<PdfChunkSectionResult> addPhotosSectionChunked(
    Mission mission,
    String missionId,
    AuditInstallationsElectriques? audit,
    DescriptionInstallations? description,
    Map<String, int> trackedPages, {
    String? nomSite,
    String? numeroRapport,
    int pageOffset = 0,
    int? overrideTotalPages,
    bool saveFilesToDisk = true,
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

    final chunkFiles = <File>[];
    final tempDir = await getTemporaryDirectory();
    int currentOffset = pageOffset;
    final seenPaths = <String>{};

    Future<pw.MemoryImage?> loadImage(
      String path, {
      PdfPhotoContext photoContext = PdfPhotoContext.equipmentObs,
      int? maxWidth,
      int? maxHeight,
      int? quality,
      bool saveFilesToDisk = true,
    }) {
      if (imageLoader != null) {
        return imageLoader(
          path,
          photoContext: photoContext,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
          saveFilesToDisk: saveFilesToDisk,
        );
      }
      return _defaultLoadImage(
        path,
        photoContext: photoContext,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
        saveFilesToDisk: saveFilesToDisk,
      );
    }

    _EquipmentPhotoGroup processCoffret(CoffretArmoire c, String prefix) {
      final repVal = c.repere?.isNotEmpty == true
          ? c.repere
          : c.numeroEquipement;
      final typeTitle = c.type.isNotEmpty ? c.type.toUpperCase() : 'ÉQUIPEMENT';

      // 1. Photo Extérieure
      String? extPath = c.photosExternes.isNotEmpty
          ? c.photosExternes.first
          : (c.photos.isNotEmpty ? c.photos.first : null);
      _PhotoEntry? extEntry;
      if (extPath != null &&
          extPath.trim().isNotEmpty &&
          !seenPaths.contains(extPath.trim())) {
        seenPaths.add(extPath.trim());
        extEntry = _PhotoEntry(
          filePath: extPath.trim(),
          description: '$prefix - $typeTitle : ${c.nom} (Extérieur)',
          repere: repVal,
          badgeLabel: 'EXTÉRIEUR',
          badgeBgColor: PdfColor.fromInt(0xFF1E3A8A), // Bleu Marine
          badgeTextColor: PdfColors.white,
        );
      }

      // 2. Photo Intérieure
      String? intPath = c.photosInternes.isNotEmpty
          ? c.photosInternes.first
          : (c.photos.length > 1 ? c.photos[1] : null);
      _PhotoEntry? intEntry;
      if (intPath != null &&
          intPath.trim().isNotEmpty &&
          !seenPaths.contains(intPath.trim())) {
        seenPaths.add(intPath.trim());
        intEntry = _PhotoEntry(
          filePath: intPath.trim(),
          description: '$prefix - $typeTitle : ${c.nom} (Intérieur)',
          repere: repVal,
          badgeLabel: 'INTÉRIEUR',
          badgeBgColor: PdfColor.fromInt(0xFF065F46), // Vert Émeraude
          badgeTextColor: PdfColors.white,
        );
      }

      // 3. Photos d'observations (Équipements)
      final obsEntries = <_PhotoEntry>[];
      void addObsPhoto(List<String>? paths, String desc) {
        if (paths == null) return;
        for (var p in paths) {
          final t = p.trim();
          if (t.isNotEmpty && !seenPaths.contains(t)) {
            seenPaths.add(t);
            obsEntries.add(
              _PhotoEntry(
                filePath: t,
                description: desc,
                repere: repVal,
                isObservation: true,
                badgeLabel: 'ANOMALIE',
                badgeBgColor: PdfColors.white,
                badgeTextColor: PdfColors.red700,
              ),
            );
          }
        }
      }

      for (var pv in c.pointsVerification) {
        addObsPhoto(
          pv.photos,
          '$prefix - $typeTitle : ${c.nom} - Point : ${pv.pointVerification}',
        );
      }
      for (var obs in c.observationsLibres) {
        addObsPhoto(
          obs.photos,
          '$prefix - $typeTitle : ${c.nom} - Obs libre : ${obs.texte}',
        );
      }
      final pfEnrichies = c.observationsParafoudreEnrichies ?? [];
      for (var obs in pfEnrichies) {
        addObsPhoto(
          obs.photos,
          '$prefix - $typeTitle : ${c.nom} - Parafoudre : ${obs.elementControle}',
        );
      }

      return _EquipmentPhotoGroup(
        coffret: c,
        locationPrefix: prefix,
        extPhoto: extEntry,
        intPhoto: intEntry,
        obsPhotos: obsEntries,
      );
    }

    final localBadgeColor = PdfColor.fromInt(0xFF0F766E); // Deep Teal
    final zoneBadgeColor = PdfColor.fromInt(0xFF4338CA); // Dark Indigo
    final celluleBadgeColor = PdfColor.fromInt(0xFF0369A1); // Sky/Cyan Blue

    final sectionBlocks = <_PhotoSectionBlock>[];

    // 1. Photos Description des installations
    if (description != null) {
      final descPhotos = <_PhotoEntry>[];
      void addDescItems(List<InstallationItem>? items, String categoryLabel) {
        if (items == null) return;
        for (var item in items) {
          final nomItem =
              item.data['nom'] ??
              item.data['Nom'] ??
              (item.data.isNotEmpty ? item.data.values.first : '');
          for (var p in item.photoPaths) {
            final t = p.trim();
            if (t.isNotEmpty && !seenPaths.contains(t)) {
              seenPaths.add(t);
              descPhotos.add(
                _PhotoEntry(
                  filePath: t,
                  description: 'Description - $categoryLabel${nomItem.isNotEmpty ? ' : $nomItem' : ''}',
                  badgeLabel: 'DESCRIPTION',
                  badgeBgColor: PdfColor.fromInt(0xFF1E3A8A),
                  badgeTextColor: PdfColors.white,
                ),
              );
            }
          }
        }
      }

      addDescItems(description.alimentationMoyenneTension, 'Alimentation MT');
      addDescItems(description.alimentationBasseTension, 'Alimentation BT');
      addDescItems(description.groupeElectrogene, 'Groupe Électrogène');
      addDescItems(description.alimentationCarburant, 'Alimentation Carburant');
      addDescItems(description.inverseur, 'Inverseur');
      addDescItems(description.stabilisateur, 'Stabilisateur');
      addDescItems(description.onduleurs, 'Onduleurs');

      if (descPhotos.isNotEmpty) {
        sectionBlocks.add(
          _PhotoSectionBlock(
            title: 'DESCRIPTION DES INSTALLATIONS',
            subtitle: 'Alimentation & Sources',
            photos: descPhotos,
          ),
        );
      }
    }

    // 2. Photos Audit des installations électriques
    if (audit != null) {
      // Audit Général
      if (audit.photos.isNotEmpty) {
        final auditGenPhotos = <_PhotoEntry>[];
        for (var p in audit.photos) {
          final t = p.trim();
          if (t.isNotEmpty && !seenPaths.contains(t)) {
            seenPaths.add(t);
            auditGenPhotos.add(
              _PhotoEntry(
                filePath: t,
                description: "Général Audit",
                badgeLabel: 'AUDIT',
                badgeBgColor: PdfColor.fromInt(0xFF1E3A8A),
                badgeTextColor: PdfColors.white,
              ),
            );
          }
        }
        if (auditGenPhotos.isNotEmpty) {
          sectionBlocks.add(
            _PhotoSectionBlock(
              title: 'AUDIT GÉNÉRAL DU SITE',
              subtitle: 'Vues d\'ensemble',
              photos: auditGenPhotos,
            ),
          );
        }
      }

      // Moyenne Tension Locaux (Hors Zone)
      for (var local in audit.moyenneTensionLocaux) {
        final locPhotos = <_PhotoEntry>[];
        final locEquips = <_EquipmentPhotoGroup>[];

        void addLocPhoto(
          List<String>? paths,
          String desc, {
          bool isObs = false,
          String? badge,
          PdfColor? bg,
          PdfColor? text,
        }) {
          if (paths == null) return;
          for (var p in paths) {
            final t = p.trim();
            if (t.isNotEmpty && !seenPaths.contains(t)) {
              seenPaths.add(t);
              locPhotos.add(
                _PhotoEntry(
                  filePath: t,
                  description: desc,
                  isObservation: isObs,
                  badgeLabel: badge ?? (isObs ? 'ANOMALIE' : 'LOCAL'),
                  badgeBgColor: bg ?? (isObs ? PdfColors.white : localBadgeColor),
                  badgeTextColor: text ?? (isObs ? PdfColors.red700 : PdfColors.white),
                ),
              );
            }
          }
        }

        addLocPhoto(local.photos, 'Local : ${local.nom}');
        for (var dc in local.dispositionsConstructives) {
          addLocPhoto(
            dc.photos,
            'Local : ${local.nom} - DC : ${dc.elementControle}',
            isObs: dc.conforme == false,
          );
        }
        for (var ce in local.conditionsExploitation) {
          addLocPhoto(
            ce.photos,
            'Local : ${local.nom} - CE : ${ce.elementControle}',
            isObs: ce.conforme == false,
          );
        }
        for (var obs in local.observationsLibres) {
          addLocPhoto(
            obs.photos,
            'Local : ${local.nom} - Obs libre : ${obs.texte}',
            isObs: true,
          );
        }
        for (var i = 0; i < local.cellules.length; i++) {
          final cellule = local.cellules[i];
          addLocPhoto(
            cellule.photos,
            'Local : ${local.nom} - Cellule ${i + 1} (${cellule.fonction})',
            badge: 'CELLULE',
            bg: celluleBadgeColor,
          );
          for (var ev in cellule.elementsVerifies) {
            addLocPhoto(
              ev.photos,
              'Local : ${local.nom} - Cellule ${i + 1} - Vérif : ${ev.elementControle}',
              isObs: ev.conforme == false,
              badge: ev.conforme == false ? 'ANOMALIE' : 'CELLULE',
              bg: ev.conforme == false ? PdfColors.white : celluleBadgeColor,
              text: ev.conforme == false ? PdfColors.red700 : PdfColors.white,
            );
          }
        }
        for (var i = 0; i < local.transformateurs.length; i++) {
          final transfo = local.transformateurs[i];
          addLocPhoto(
            transfo.photos,
            'Local : ${local.nom} - Transformateur ${i + 1}',
            badge: 'TRANSFO',
            bg: celluleBadgeColor,
          );
          for (var ev in transfo.elementsVerifies) {
            addLocPhoto(
              ev.photos,
              'Local : ${local.nom} - Transformateur ${i + 1} - Vérif : ${ev.elementControle}',
              isObs: ev.conforme == false,
              badge: ev.conforme == false ? 'ANOMALIE' : 'TRANSFO',
              bg: ev.conforme == false ? PdfColors.white : celluleBadgeColor,
              text: ev.conforme == false ? PdfColors.red700 : PdfColors.white,
            );
          }
        }
        for (var c in local.coffrets) {
          final eqGroup = processCoffret(c, local.nom);
          if (eqGroup.hasPhotos) locEquips.add(eqGroup);
        }

        final block = _PhotoSectionBlock(
          title: 'LOCAL : ${local.nom.toUpperCase()}',
          subtitle: 'Moyenne Tension - Hors Zone',
          photos: locPhotos,
          equipments: locEquips,
        );
        if (block.hasContent) sectionBlocks.add(block);
      }

      // Moyenne Tension Zones
      for (var zone in audit.moyenneTensionZones) {
        final zonePhotos = <_PhotoEntry>[];
        final zoneEquips = <_EquipmentPhotoGroup>[];
        final localSubBlocks = <_PhotoSectionBlock>[];

        void addZonePhoto(List<String>? paths, String desc, {bool isObs = false}) {
          if (paths == null) return;
          for (var p in paths) {
            final t = p.trim();
            if (t.isNotEmpty && !seenPaths.contains(t)) {
              seenPaths.add(t);
              zonePhotos.add(
                _PhotoEntry(
                  filePath: t,
                  description: desc,
                  isObservation: isObs,
                  badgeLabel: isObs ? 'ANOMALIE' : 'ZONE',
                  badgeBgColor: isObs ? PdfColors.white : zoneBadgeColor,
                  badgeTextColor: isObs ? PdfColors.red700 : PdfColors.white,
                ),
              );
            }
          }
        }

        addZonePhoto(zone.photos, 'Zone : ${zone.nom}');
        for (var obs in zone.observationsLibres) {
          addZonePhoto(
            obs.photos,
            'Zone : ${zone.nom} - Obs libre : ${obs.texte}',
            isObs: true,
          );
        }
        for (var c in zone.coffrets) {
          final eqGroup = processCoffret(c, zone.nom);
          if (eqGroup.hasPhotos) zoneEquips.add(eqGroup);
        }

        for (var local in zone.locaux) {
          final locPhotos = <_PhotoEntry>[];
          final locEquips = <_EquipmentPhotoGroup>[];

          void addLocPhoto(
            List<String>? paths,
            String desc, {
            bool isObs = false,
            String? badge,
            PdfColor? bg,
            PdfColor? text,
          }) {
            if (paths == null) return;
            for (var p in paths) {
              final t = p.trim();
              if (t.isNotEmpty && !seenPaths.contains(t)) {
                seenPaths.add(t);
                locPhotos.add(
                  _PhotoEntry(
                    filePath: t,
                    description: desc,
                    isObservation: isObs,
                    badgeLabel: badge ?? (isObs ? 'ANOMALIE' : 'LOCAL'),
                    badgeBgColor: bg ?? (isObs ? PdfColors.white : localBadgeColor),
                    badgeTextColor: text ?? (isObs ? PdfColors.red700 : PdfColors.white),
                  ),
                );
              }
            }
          }

          addLocPhoto(local.photos, 'Zone : ${zone.nom} - Local : ${local.nom}');
          for (var dc in local.dispositionsConstructives) {
            addLocPhoto(
              dc.photos,
              'Zone : ${zone.nom} - Local : ${local.nom} - DC : ${dc.elementControle}',
              isObs: dc.conforme == false,
            );
          }
          for (var ce in local.conditionsExploitation) {
            addLocPhoto(
              ce.photos,
              'Zone : ${zone.nom} - Local : ${local.nom} - CE : ${ce.elementControle}',
              isObs: ce.conforme == false,
            );
          }
          for (var obs in local.observationsLibres) {
            addLocPhoto(
              obs.photos,
              'Zone : ${zone.nom} - Local : ${local.nom} - Obs libre : ${obs.texte}',
              isObs: true,
            );
          }
          for (var c in local.coffrets) {
            final eqGroup = processCoffret(c, '${zone.nom} - Local : ${local.nom}');
            if (eqGroup.hasPhotos) locEquips.add(eqGroup);
          }

          final locBlock = _PhotoSectionBlock(
            title: 'LOCAL : ${local.nom.toUpperCase()}',
            subtitle: 'Zone : ${zone.nom}',
            photos: locPhotos,
            equipments: locEquips,
          );
          if (locBlock.hasContent) localSubBlocks.add(locBlock);
        }

        final zoneBlock = _PhotoSectionBlock(
          title: 'ZONE : ${zone.nom.toUpperCase()}',
          subtitle: 'Zone Moyenne Tension',
          photos: zonePhotos,
          equipments: zoneEquips,
          subBlocks: localSubBlocks,
        );
        if (zoneBlock.hasContent) sectionBlocks.add(zoneBlock);
      }

      // Basse Tension Zones
      for (var zone in audit.basseTensionZones) {
        final zonePhotos = <_PhotoEntry>[];
        final zoneEquips = <_EquipmentPhotoGroup>[];
        final localSubBlocks = <_PhotoSectionBlock>[];

        void addZonePhoto(List<String>? paths, String desc, {bool isObs = false}) {
          if (paths == null) return;
          for (var p in paths) {
            final t = p.trim();
            if (t.isNotEmpty && !seenPaths.contains(t)) {
              seenPaths.add(t);
              zonePhotos.add(
                _PhotoEntry(
                  filePath: t,
                  description: desc,
                  isObservation: isObs,
                  badgeLabel: isObs ? 'ANOMALIE' : 'ZONE',
                  badgeBgColor: isObs ? PdfColors.white : zoneBadgeColor,
                  badgeTextColor: isObs ? PdfColors.red700 : PdfColors.white,
                ),
              );
            }
          }
        }

        addZonePhoto(zone.photos, 'Zone : ${zone.nom}');
        for (var obs in zone.observationsLibres) {
          addZonePhoto(
            obs.photos,
            'Zone : ${zone.nom} - Obs libre : ${obs.texte}',
            isObs: true,
          );
        }
        for (var c in zone.coffretsDirects) {
          final eqGroup = processCoffret(c, zone.nom);
          if (eqGroup.hasPhotos) zoneEquips.add(eqGroup);
        }

        for (var local in zone.locaux) {
          final locPhotos = <_PhotoEntry>[];
          final locEquips = <_EquipmentPhotoGroup>[];

          void addLocPhoto(
            List<String>? paths,
            String desc, {
            bool isObs = false,
            String? badge,
            PdfColor? bg,
            PdfColor? text,
          }) {
            if (paths == null) return;
            for (var p in paths) {
              final t = p.trim();
              if (t.isNotEmpty && !seenPaths.contains(t)) {
                seenPaths.add(t);
                locPhotos.add(
                  _PhotoEntry(
                    filePath: t,
                    description: desc,
                    isObservation: isObs,
                    badgeLabel: badge ?? (isObs ? 'ANOMALIE' : 'LOCAL'),
                    badgeBgColor: bg ?? (isObs ? PdfColors.white : localBadgeColor),
                    badgeTextColor: text ?? (isObs ? PdfColors.red700 : PdfColors.white),
                  ),
                );
              }
            }
          }

          addLocPhoto(local.photos, 'Zone : ${zone.nom} - Local : ${local.nom}');
          if (local.dispositionsConstructives != null) {
            for (var dc in local.dispositionsConstructives!) {
              addLocPhoto(
                dc.photos,
                'Zone : ${zone.nom} - Local : ${local.nom} - DC : ${dc.elementControle}',
                isObs: dc.conforme == false,
              );
            }
          }
          if (local.conditionsExploitation != null) {
            for (var ce in local.conditionsExploitation!) {
              addLocPhoto(
                ce.photos,
                'Zone : ${zone.nom} - Local : ${local.nom} - CE : ${ce.elementControle}',
                isObs: ce.conforme == false,
              );
            }
          }
          for (var obs in local.observationsLibres) {
            addLocPhoto(
              obs.photos,
              'Zone : ${zone.nom} - Local : ${local.nom} - Obs libre : ${obs.texte}',
              isObs: true,
            );
          }
          for (var c in local.coffrets) {
            final eqGroup = processCoffret(c, '${zone.nom} - Local : ${local.nom}');
            if (eqGroup.hasPhotos) locEquips.add(eqGroup);
          }

          final locBlock = _PhotoSectionBlock(
            title: 'LOCAL : ${local.nom.toUpperCase()}',
            subtitle: 'Zone : ${zone.nom}',
            photos: locPhotos,
            equipments: locEquips,
          );
          if (locBlock.hasContent) localSubBlocks.add(locBlock);
        }

        final zoneBlock = _PhotoSectionBlock(
          title: 'ZONE : ${zone.nom.toUpperCase()}',
          subtitle: 'Zone Basse Tension',
          photos: zonePhotos,
          equipments: zoneEquips,
          subBlocks: localSubBlocks,
        );
        if (zoneBlock.hasContent) sectionBlocks.add(zoneBlock);
      }
    }

    final totalPhotosCount = sectionBlocks.fold<int>(
      0,
      (sum, b) => sum + b.totalPhotosCount,
    );

    if (totalPhotosCount == 0) {
      return _ChunkSectionResult(files: chunkFiles, totalPages: 0);
    }

    int globalPhotoCounter = 1;
    int photoChunkIdx = 0;

    pw.Document photoDoc = pw.Document(
      title: 'Photos Batch - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: true,
    );
    int pagesInCurrentChunk = 0;

    Future<void> flushChunkIfNeeded({bool force = false}) async {
      if (pagesInCurrentChunk > 0 && (pagesInCurrentChunk >= 3 || force)) {
        photoChunkIdx++;
        if (saveFilesToDisk) {
          final chunkBytes = await photoDoc.save();
          final photoChunkFile = File(
            '${tempDir.path}/pdf_chunk_photos_${missionId}_$photoChunkIdx.pdf',
          );
          await photoChunkFile.writeAsBytes(chunkBytes);
          chunkFiles.add(photoChunkFile);
          await Future.delayed(Duration.zero);
        }
        currentOffset += pagesInCurrentChunk;

        photoDoc = pw.Document(
          title: 'Photos Batch ${photoChunkIdx + 1} - ${mission.nomClient}',
          author: 'KES INSPECTIONS AND PROJECTS',
          compress: saveFilesToDisk,
        );
        pagesInCurrentChunk = 0;
      }
    }

    var currentPageRows = <pw.Widget>[];

    Future<void> flushEquipmentPage() async {
      if (currentPageRows.isEmpty) return;
      final rowsToRender = List<pw.Widget>.from(currentPageRows);
      currentPageRows.clear();

      photoDoc.addPage(
        pw.Page(
          pageTheme: innerTheme(
            pageOffset: currentOffset,
            overrideTotalPages: overrideTotalPages,
            showWatermark: true,
          ),
          build: (ctx) {
            return pw.Column(
              children: [
                pageHeader(
                  nomClient: mission.nomClient,
                  nomSite: nomSite,
                  numeroRapport: numeroRapport,
                ),
                pw.SizedBox(height: 4),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Expanded(child: rowsToRender[0]),
                      pw.Expanded(
                        child: rowsToRender.length > 1
                            ? rowsToRender[1]
                            : pw.Row(
                                children: [
                                  pw.Expanded(
                                    child: pw.Container(
                                      margin: const pw.EdgeInsets.all(3),
                                      color: PdfColors.grey100,
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Container(
                                      margin: const pw.EdgeInsets.all(3),
                                      color: PdfColors.grey100,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
      pagesInCurrentChunk++;
      await flushChunkIfNeeded();
    }

    Future<void> renderBlock(
      _PhotoSectionBlock block, {
      String? parentTitle,
      String? parentSubtitle,
    }) async {
      if (!block.hasContent) return;

      bool headerEmitted = false;
      bool parentHeaderEmitted = parentTitle == null;

      // 1. Direct Photos
      for (int i = 0; i < block.photos.length; i += 2) {
        if (currentPageRows.length >= 2) {
          await flushEquipmentPage();
        }

        final p1 = block.photos[i];
        final img1 = await loadImage(
          p1.filePath,
          photoContext: PdfPhotoContext.equipmentObs,
          saveFilesToDisk: saveFilesToDisk,
        );
        final num1 = globalPhotoCounter++;
        final cell1 = _buildPhotoCell(p1, img1, num1, totalPhotosCount);

        pw.Widget cell2;
        if (i + 1 < block.photos.length) {
          final p2 = block.photos[i + 1];
          final img2 = await loadImage(
            p2.filePath,
            photoContext: PdfPhotoContext.equipmentObs,
            saveFilesToDisk: saveFilesToDisk,
          );
          final num2 = globalPhotoCounter++;
          cell2 = _buildPhotoCell(p2, img2, num2, totalPhotosCount);
        } else {
          cell2 = pw.Container(
            margin: const pw.EdgeInsets.all(3),
            color: PdfColors.grey100,
          );
        }

        final photoRowWidget = pw.Row(
          children: [
            pw.Expanded(child: cell1),
            pw.Expanded(child: cell2),
          ],
        );

        final banners = <pw.Widget>[];
        if (!parentHeaderEmitted) {
          parentHeaderEmitted = true;
          banners.add(_buildPhotoBannerBar(title: parentTitle!, subtitle: parentSubtitle));
        }
        if (!headerEmitted) {
          headerEmitted = true;
          banners.add(_buildPhotoBannerBar(title: block.title, subtitle: block.subtitle));
        }

        if (banners.isNotEmpty) {
          currentPageRows.add(
            pw.Column(
              children: [
                ...banners,
                pw.Expanded(child: photoRowWidget),
              ],
            ),
          );
        } else {
          currentPageRows.add(photoRowWidget);
        }
      }

      // 2. Direct Equipments
      for (var group in block.equipments) {
        if (!group.hasPhotos) continue;

        pw.MemoryImage? extImg;
        if (group.extPhoto != null) {
          extImg = await loadImage(
            group.extPhoto!.filePath,
            photoContext: PdfPhotoContext.equipmentObs,
            saveFilesToDisk: saveFilesToDisk,
          );
        }
        pw.MemoryImage? intImg;
        if (group.intPhoto != null) {
          intImg = await loadImage(
            group.intPhoto!.filePath,
            photoContext: PdfPhotoContext.equipmentObs,
            saveFilesToDisk: saveFilesToDisk,
          );
        }

        final obsImgs = <pw.MemoryImage?>[];
        for (var obs in group.obsPhotos) {
          obsImgs.add(
            await loadImage(
              obs.filePath,
              photoContext: PdfPhotoContext.equipmentObs,
              saveFilesToDisk: saveFilesToDisk,
            ),
          );
        }

        final extCellNum = group.extPhoto != null ? globalPhotoCounter++ : null;
        final extCellWidget = group.extPhoto != null
            ? _buildPhotoCell(
                group.extPhoto!,
                extImg,
                extCellNum!,
                totalPhotosCount,
              )
            : pw.Container(
                margin: const pw.EdgeInsets.all(3),
                color: PdfColors.grey100,
              );

        final intCellNum = group.intPhoto != null ? globalPhotoCounter++ : null;
        final intCellWidget = group.intPhoto != null
            ? _buildPhotoCell(
                group.intPhoto!,
                intImg,
                intCellNum!,
                totalPhotosCount,
              )
            : pw.Container(
                margin: const pw.EdgeInsets.all(3),
                color: PdfColors.grey100,
              );

        final typeHeader = group.coffret.type.isNotEmpty
            ? group.coffret.type.toUpperCase()
            : 'ÉQUIPEMENT';

        final equipBanner = _buildPhotoBannerBar(
          title: '$typeHeader : ${group.coffret.nom.toUpperCase()}',
          subtitle: 'Réf : ${group.coffret.repere ?? group.coffret.numeroEquipement ?? '-'} (${group.locationPrefix})',
        );

        final extIntPair = pw.Row(
          children: [
            pw.Expanded(child: extCellWidget),
            pw.Expanded(child: intCellWidget),
          ],
        );

        if (currentPageRows.length >= 2) {
          await flushEquipmentPage();
        }

        final banners = <pw.Widget>[];
        if (!parentHeaderEmitted) {
          parentHeaderEmitted = true;
          banners.add(_buildPhotoBannerBar(title: parentTitle!, subtitle: parentSubtitle));
        }
        if (!headerEmitted) {
          headerEmitted = true;
          banners.add(_buildPhotoBannerBar(title: block.title, subtitle: block.subtitle));
        }
        banners.add(equipBanner);

        currentPageRows.add(
          pw.Column(
            children: [
              ...banners,
              pw.Expanded(child: extIntPair),
            ],
          ),
        );

        // Equipment Observations
        for (int oi = 0; oi < group.obsPhotos.length; oi += 2) {
          if (currentPageRows.length >= 2) {
            await flushEquipmentPage();
          }

          final obs1 = group.obsPhotos[oi];
          final obs1Img = obsImgs[oi];
          final obs1Num = globalPhotoCounter++;
          final cell1 = _buildPhotoCell(obs1, obs1Img, obs1Num, totalPhotosCount);

          pw.Widget cell2;
          if (oi + 1 < group.obsPhotos.length) {
            final obs2 = group.obsPhotos[oi + 1];
            final obs2Img = obsImgs[oi + 1];
            final obs2Num = globalPhotoCounter++;
            cell2 = _buildPhotoCell(obs2, obs2Img, obs2Num, totalPhotosCount);
          } else {
            cell2 = pw.Container(
              margin: const pw.EdgeInsets.all(3),
              color: PdfColors.grey100,
            );
          }

          currentPageRows.add(
            pw.Row(
              children: [
                pw.Expanded(child: cell1),
                pw.Expanded(child: cell2),
              ],
            ),
          );
        }
      }

      // 3. SubBlocks (e.g. Locaux in a Zone)
      for (var subBlock in block.subBlocks) {
        final pTitle = parentHeaderEmitted ? null : parentTitle;
        final pSub = parentHeaderEmitted ? null : parentSubtitle;
        if (!parentHeaderEmitted) parentHeaderEmitted = true;

        await renderBlock(
          subBlock,
          parentTitle: pTitle ?? (headerEmitted ? null : block.title),
          parentSubtitle: pSub ?? (headerEmitted ? null : block.subtitle),
        );
        if (!headerEmitted) headerEmitted = true;
      }
    }

    for (var rootBlock in sectionBlocks) {
      await renderBlock(rootBlock);
    }

    await flushEquipmentPage();
    await flushChunkIfNeeded(force: true);
    return _ChunkSectionResult(
      files: chunkFiles,
      totalPages: currentOffset - pageOffset,
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  SCHÉMA DES INSTALLATIONS ÉLECTRIQUES
  // ──────────────────────────────────────────────────────────────


  static Future<PdfChunkSectionResult> _addPhotosSectionChunked(
    Mission mission,
    String missionId,
    AuditInstallationsElectriques? audit,
    DescriptionInstallations? description,
    Map<String, int> trackedPages, {
    String? nomSite,
    String? numeroRapport,
    int pageOffset = 0,
    int? overrideTotalPages,
    bool saveFilesToDisk = true,
  }) =>
      addPhotosSectionChunked(
        mission,
        missionId,
        audit,
        description,
        trackedPages,
        nomSite: nomSite,
        numeroRapport: numeroRapport,
        pageOffset: pageOffset,
        overrideTotalPages: overrideTotalPages,
        saveFilesToDisk: saveFilesToDisk,
      );
}
