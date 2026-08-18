// pdf_report_service.dart 

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/services/ai/executive_summary_snapshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:inspec_app/models/pdf/installation_description_pdf_data.dart';
import 'package:inspec_app/services/installation_description_sync_service.dart';
import 'package:inspec_app/services/installation_fields_registry.dart';
import 'package:inspec_app/services/pdf/pdf_chunk_merger.dart';
import 'package:inspec_app/services/pdf/pdf_footer_builder.dart';
import '../dispositions_constructives_registry.dart';
import '../statistics/mission_statistics_collector.dart';
import '../statistics/audit_finding.dart';
import '../../components/safe_file_image.dart';
import '../ai/executive_summary_data.dart';
import '../ai/mission_executive_summary_service.dart';

typedef PdfProgressCallback = void Function(double progress, String statusMessage);

/// Contexte d'affichage de photo pour l'optimisation adaptative de résolution et de qualité.
enum PdfPhotoContext {
  /// Grille photo 2x2 (Pages photographies dédiées)
  grid2x2(maxWidth: 500, maxHeight: 375, quality: 60),

  /// Photos d'équipements, coffrets, armoires et constats d'observations
  equipmentObs(maxWidth: 320, maxHeight: 240, quality: 55),

  /// Schémas d'exploitation, diagrammes et illustrations pleine largeur
  schema(maxWidth: 800, maxHeight: 600, quality: 70);

  final int maxWidth;
  final int maxHeight;
  final int quality;
  const PdfPhotoContext({required this.maxWidth, required this.maxHeight, required this.quality});
}

// ================================================================
//  PdfReportService
// ================================================================

class PdfReportService {
  // ──────────────────────────────────────────────────────────────
  //  CONSTANTES DE MISE EN PAGE (1.5 cm partout)
  // ──────────────────────────────────────────────────────────────
  
  static const double kLeftMargin   = 1.5 * 28.35;   // 1.5 cm
  static const double kTopMargin    = 1.5 * 28.35;   // 1.5 cm
  static const double kRightMargin  = 1.5 * 28.35;   // 1.5 cm
  static const double kBottomMargin = 1.5 * 28.35;   // 1.5 cm
  
  // ──────────────────────────────────────────────────────────────
  //  COULEURS
  // ──────────────────────────────────────────────────────────────
  static final PdfColor headerColor = PdfColor.fromInt(0xFF1F3864);
  static final PdfColor accentColor = PdfColor.fromInt(0xFF2E74B5);
  static final PdfColor lightBlue = PdfColor.fromInt(0xFFD6E4F0);
  static final PdfColor darkGrey = PdfColor.fromInt(0xFF404040);
  static final PdfColor tableRowAlt = PdfColor.fromInt(0xFFF5F8FC);
  static final PdfColor borderColor = PdfColor.fromInt(0xFFAAAAAA);
  static final PdfColor priorite1Color = PdfColor.fromInt(0xFFFFF2CC);
  static final PdfColor priorite2Color = PdfColor.fromInt(0xFFFFE0B2);
  static final PdfColor priorite3Color = PdfColor.fromInt(0xFFFFCDD2);
  static final PdfColor conformeColor = PdfColor.fromInt(0xFFE8F5E9);
  static final PdfColor nonConformeColor = PdfColor.fromInt(0xFFFFEBEE);
  static final PdfColor sansObjetColor = PdfColor.fromInt(0xFFEEEEEE);

  // ──────────────────────────────────────────────────────────────
  //  TAILLES DE POLICE
  // ──────────────────────────────────────────────────────────────
  static const double fsH1 = 12.0;
  static const double fsH2 = 10.5;
  static const double fsH3 = 10.0;
  static const double fsBody = 9.0;
  static const double fsSmall = 7.5;

  // ──────────────────────────────────────────────────────────────
  //  IMAGES (chargees une seule fois)
  // ──────────────────────────────────────────────────────────────
  static pw.MemoryImage? _watermarkImage;
  static pw.MemoryImage? _firstPageFooterImage;
  static pw.MemoryImage? _otherPageFooterImage;
  static pw.MemoryImage? _logoKesImage;
  static pw.MemoryImage? _imgHabilitation;
  static pw.MemoryImage? _imgAccesGauche;
  static pw.MemoryImage? _imgAccesDroite1;
  static pw.MemoryImage? _imgAccesDroite2;
  static bool _imagesLoaded = false;

  static late final pw.Font _fontRegular;
  static late final pw.Font _fontBold;
  static bool _fontsLoaded = false;

  // Ordre des colonnes pour les tableaux d'installation
  static const Map<String, List<String>> _columnOrderBySection = {
    'MT': [
      'TYPE DE CELLULE',
      'TENSION DE SERVICE (kV)',
      'TENSION ASSIGNEE(KV)',
      'POUVOIR DE COUPURE ASSIGNE(KA)',
      'SECTION DU CABLE(mm2)',
      'NATURE DU RESEAU',
    ],
    'BT': [
      'PUISSANCE TRANSFORMATEUR(KVA)',
      'TYPE DE TRANSFORMATEUR',
      'INTENSITE NOMINALE (A)',
      'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR(A)',
      'SECTION DU CABLE(mm2)',
      'TENSION MT/BT(KV)',
      'COUPLAGE',
      'PCC AMONT(MVA)',
      'UCC EN(%)',
      'IK3 MAX(KA)',
    ],
    'GROUPE': [
      'N\u00B0',
      'MARQUE',
      'TYPE',
      'N\u00B0 SERIE',
      'PUISSANCE(KVA)',
      'INTENSITE(A)',
      'ANNEE DE FABRICATION',
      'CALIBRE DU DISJONCTEUR(A)',
      'SECTION DU CABLE(mm2)',
    ],
    'CARBURANT': [
      'N\u00B0',
      'MODE',
      'CAPACITE(L)',
      'CUVE DE RETENTION',
      'INDICATEUR DE NIVEAU',
      'MISE A LA TERRE',
      'ANNEE DE FABRICATION',
    ],
    'INVERSEUR': [
      'N\u00B0',
      'MARQUE',
      'TYPE',
      'N\u00B0 SERIE',
      'INTENSITE (A)',
      'REGLAGES',
    ],
    'STABILISATEUR': [
      'N\u00B0',
      'MARQUE',
      'TYPE',
      'N\u00B0 SERIE',
      'ANNEE DE FABRICATION',
      'ANNEE D\'INSTALLATION',
      'PUISSANCE (KVA)',
      'INTENSITE (A)',
      'ENTREE',
      'SORTIE',
    ],
    'ONDULEUR': [
      'N\u00B0',
      'MARQUE',
      'TYPE',
      'N\u00B0 DE SERIE',
      'PUISSANCE (KVA)',
      'INTENSITE (A)',
      'NOMBRE DE PHASE',
    ],
    'CPI': [
      'N\u00B0',
      'MARQUE',
      'TYPE',
      'N\u00B0 SÉRIE',
      'RÉGIME DE NEUTRE SURVEILLÉ',
      'SEUIL DE RÉGLAGE (kΩ)',
      'REPORT D\'ALARME',
      'ANNÉE DE FABRICATION',
    ],
  };

  /// Charge toutes les images necessaires avec compression adaptative des assets statiques
  static Future<void> _loadImages() async {
    if (_imagesLoaded) return;
    
    Future<pw.MemoryImage?> tryLoad(
      String asset, {
      int targetWidth = 500,
      int targetQuality = 70,
    }) async {
      try {
        final data = await rootBundle.load(asset);
        final bytes = data.buffer.asUint8List();
        if (bytes.isEmpty) return null;

        try {
          final tempDir = await getTemporaryDirectory();
          final cacheFile = File('${tempDir.path}/asset_${asset.hashCode}_${targetWidth}_$targetQuality.jpg');
          if (await cacheFile.exists()) {
            final cachedBytes = await cacheFile.readAsBytes();
            if (cachedBytes.isNotEmpty) return pw.MemoryImage(cachedBytes);
          }

          final tempAssetFile = File('${tempDir.path}/raw_asset_${asset.hashCode}.png');
          await tempAssetFile.writeAsBytes(bytes);

          final compressedBytes = await FlutterImageCompress.compressWithFile(
            tempAssetFile.absolute.path,
            minWidth: targetWidth,
            quality: targetQuality,
            format: CompressFormat.jpeg,
          ).timeout(const Duration(seconds: 2));

          if (compressedBytes != null && compressedBytes.isNotEmpty) {
            try {
              await cacheFile.writeAsBytes(compressedBytes);
            } catch (_) {}
            return pw.MemoryImage(compressedBytes);
          }
        } catch (_) {}

        return pw.MemoryImage(bytes);
      } catch (e) {
        if (kDebugMode) print('Image non trouvee: $asset');
        return null;
      }
    }
    
    Future<pw.MemoryImage?> tryLoadRaw(String asset) async {
      try {
        final data = await rootBundle.load(asset);
        final bytes = data.buffer.asUint8List();
        if (bytes.isEmpty) return null;
        return pw.MemoryImage(bytes);
      } catch (e) {
        if (kDebugMode) print('Image non trouvee: $asset');
        return null;
      }
    }
    
    // Polices et filigranes/logos PNG avec transparence native (0 fond noir/gris)
    _watermarkImage       = await tryLoadRaw('assets/images/filigranne_image.png');
    _logoKesImage         = await tryLoadRaw('assets/images/logo.png');
    _firstPageFooterImage = await tryLoad('assets/images/firstpage_footer.png', targetWidth: 600, targetQuality: 70);
    _otherPageFooterImage = await tryLoad('assets/images/otherpage_footer.png', targetWidth: 600, targetQuality: 70);
    _imgHabilitation      = await tryLoad('assets/images/image.png', targetWidth: 500, targetQuality: 70);
    _imgAccesGauche       = await tryLoad('assets/images/image copy.png', targetWidth: 400, targetQuality: 70);
    _imgAccesDroite1      = await tryLoad('assets/images/image copy 2.png', targetWidth: 400, targetQuality: 70);
    _imgAccesDroite2      = await tryLoad('assets/images/image copy 3.png', targetWidth: 400, targetQuality: 70);
    
    _imagesLoaded = true;
  }

  /// Charge les polices necessaires
  static Future<void> _loadFonts() async {
    if (_fontsLoaded) return;
    
    try {
      final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      _fontRegular = pw.Font.ttf(regularData);
      _fontBold = pw.Font.ttf(boldData);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Polices personnalisees non trouvees, utilisation des polices standard');
      }
      _fontRegular = pw.Font.helvetica();
      _fontBold = pw.Font.helveticaBold();
    }
    
    _fontsLoaded = true;
  }

  // ──────────────────────────────────────────────────────────────
  //  THEMES DE PAGE (Couverture et Interieures)
  // ──────────────────────────────────────────────────────────────
  
  /// Thème couverture (footer firstPage - Aucun filigrane sur la première page)
  static pw.PageTheme _buildCoverPageTheme() {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: _fontRegular, bold: _fontBold),
      margin: pw.EdgeInsets.only(
        left:   kLeftMargin,
        top:    kTopMargin,
        right:  kRightMargin,
        bottom: kBottomMargin + 40,
      ),
      buildBackground: (ctx) => pw.SizedBox(),
      buildForeground: (ctx) => _buildFooterAbsolute(isFirstPage: true, ctx: ctx),
    );
  }

  /// Thème pages intérieures (footer otherPage)
  static pw.PageTheme _buildInnerPageTheme({int pageOffset = 0, int? overrideTotalPages, bool showWatermark = true}) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: _fontRegular, bold: _fontBold),
      margin: pw.EdgeInsets.only(
        left:   kLeftMargin,
        top:    kTopMargin,
        right:  kRightMargin,
        bottom: kBottomMargin + 40,
      ),
      buildBackground: (ctx) => showWatermark ? _buildWatermarkBackground() : pw.SizedBox(),
      buildForeground: (ctx) => _buildFooterAbsolute(
        isFirstPage: false,
        ctx: ctx,
        pageOffset: pageOffset,
        overrideTotalPages: overrideTotalPages,
      ),
    );
  }

  // Filigrane seul dans background
  static pw.Widget _buildWatermarkBackground() {
    if (_watermarkImage == null) return pw.SizedBox();
    return pw.Center(
      child: pw.Opacity(
        opacity: 0.15,
        child: pw.Image(_watermarkImage!, width: 400, height: 400),
      ),
    );
  }

  // Footer bord à bord physique vectoriel natif
  static pw.Widget _buildFooterAbsolute({
    required bool isFirstPage,
    required pw.Context ctx,
    int pageOffset = 0,
    int? overrideTotalPages,
  }) {
    final double footerHeight = isFirstPage ? 72.0 : 40.0;
    const double descente = kBottomMargin + 40;

    final widget = isFirstPage
        ? PdfFooterBuilder.buildFirstPageFooter(
            ctx,
            fontRegular: _fontRegular,
            fontBold: _fontBold,
          )
        : PdfFooterBuilder.buildOtherPageFooter(
            ctx,
            pageOffset: pageOffset,
            overrideTotalPages: overrideTotalPages,
            fontRegular: _fontRegular,
            fontBold: _fontBold,
          );

    return pw.Stack(
      overflow: pw.Overflow.visible,
      children: [
        pw.Positioned(
          bottom: -descente,
          left: -kLeftMargin,
          right: -kRightMargin,
          child: pw.SizedBox(
            height: footerHeight,
            width: PdfPageFormat.a4.width,
            child: widget,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  EN-TETE DE PAGE (format multi-lignes droite)
  // ──────────────────────────────────────────────────────────────
  
  static pw.Widget _buildPageHeaderWidget({
    String? nomClient,
    String? nomSite,
    String? numeroRapport,
    String? titreRapport,
  }) {
    final dateGeneration = _formatDate(DateTime.now());
    final titre = titreRapport ??
        'VERIFICATION PERIODIQUE REGLEMENTAIRE DES INSTALLATIONS ELECTRIQUES';
    final rapportNum = numeroRapport ?? 'KES/IP/VE/${DateTime.now().year}/001';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: accentColor, width: 0.8),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (_logoKesImage != null)
            pw.Image(_logoKesImage!, width: 55, height: 28, fit: pw.BoxFit.contain)
          else
            pw.Text('KES',
                style: pw.TextStyle(font: _fontBold, fontSize: 8, color: accentColor)),
          pw.Expanded(child: pw.SizedBox()),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                '\u00A9 KES INSPECTIONS & PROJECTS',
                style: pw.TextStyle(font: _fontBold, fontSize: 6, color: headerColor),
                textAlign: pw.TextAlign.right,
              ),
              if (nomSite != null && nomSite.isNotEmpty)
                pw.Text(
                  nomSite,
                  style: pw.TextStyle(font: _fontRegular, fontSize: 6, color: darkGrey),
                  textAlign: pw.TextAlign.right,
                ),
              pw.Text(
                titre,
                style: pw.TextStyle(font: _fontRegular, fontSize: 5.5, color: darkGrey),
                textAlign: pw.TextAlign.right,
              ),
              pw.Text(
                'Rapport n\u00B0 : $rapportNum',
                style: pw.TextStyle(font: _fontRegular, fontSize: 5.5, color: darkGrey),
                textAlign: pw.TextAlign.right,
              ),
              pw.Text(
                'Date du : $dateGeneration',
                style: pw.TextStyle(font: _fontRegular, fontSize: 5.5, color: darkGrey),
                textAlign: pw.TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _docStatus(bool? val) => val == true ? 'Présenté' : 'Non présenté';

  // ──────────────────────────────────────────────────────────────
  //  PAGE DE COUVERTURE
  // ──────────────────────────────────────────────────────────────
  
  static pw.MemoryImage? _cachedClientLogoImg;
  static pw.MemoryImage? _cachedClientQrImg;

  static Future<void> _preloadCoverImages(Mission mission, {required bool saveFilesToDisk}) async {
    _cachedClientLogoImg = null;
    _cachedClientQrImg = null;

    if (mission.logoClient != null && mission.logoClient!.trim().isNotEmpty) {
      if (!saveFilesToDisk) {
        _cachedClientLogoImg = _placeholder1x1;
      } else {
        try {
          final resolvedPath = await AppImageUtils.resolvePathAsync(mission.logoClient!.trim());
          if (resolvedPath != null) {
            final file = File(resolvedPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              if (bytes.isNotEmpty) _cachedClientLogoImg = pw.MemoryImage(bytes);
            }
          }
        } catch (_) {}
      }
    }

    if (mission.qrCodeClient != null && mission.qrCodeClient!.trim().isNotEmpty) {
      if (!saveFilesToDisk) {
        _cachedClientQrImg = _placeholder1x1;
      } else {
        try {
          final resolvedPath = await AppImageUtils.resolvePathAsync(mission.qrCodeClient!.trim());
          if (resolvedPath != null) {
            final file = File(resolvedPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              if (bytes.isNotEmpty) _cachedClientQrImg = pw.MemoryImage(bytes);
            }
          }
        } catch (_) {}
      }
    }
  }

  static pw.Widget _buildCoverPage(
      Mission mission, RenseignementsGeneraux? rg, pw.Context ctx,
      {String? subTitleOverride}) {
    final dateDebut = rg?.dateDebut ?? mission.dateIntervention;
    final dateFin   = rg?.dateFin;
    String dateIntervention;
    if (dateDebut != null && dateFin != null && !dateDebut.isAtSameMomentAs(dateFin)) {
      dateIntervention = 'Du ${_formatDate(dateDebut)} au ${_formatDate(dateFin)}';
    } else if (dateDebut != null) {
      dateIntervention = _formatDate(dateDebut);
    } else {
      dateIntervention = '';
    }

    pw.MemoryImage? clientLogoMemoryImg = _cachedClientLogoImg;
    if (clientLogoMemoryImg == null && mission.logoClient != null && mission.logoClient!.isNotEmpty) {
      final logoFile = File(mission.logoClient!);
      if (logoFile.existsSync()) {
        try {
          final logoBytes = logoFile.readAsBytesSync();
          clientLogoMemoryImg = pw.MemoryImage(logoBytes);
        } catch (e) {
          if (kDebugMode) print('Erreur chargement logo client PDF: $e');
        }
      }
    }

    pw.MemoryImage? clientQrMemoryImg = _cachedClientQrImg;
    if (clientQrMemoryImg == null && mission.qrCodeClient != null && mission.qrCodeClient!.isNotEmpty) {
      final qrFile = File(mission.qrCodeClient!);
      if (qrFile.existsSync()) {
        try {
          final qrBytes = qrFile.readAsBytesSync();
          clientQrMemoryImg = pw.MemoryImage(qrBytes);
        } catch (e) {
          if (kDebugMode) print('Erreur chargement QR Code client PDF: $e');
        }
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (_logoKesImage != null)
              pw.Image(_logoKesImage!, width: 140, height: 80, fit: pw.BoxFit.contain)
            else
              pw.Text('KES INSPECTIONS AND PROJECTS',
                  style: pw.TextStyle(font: _fontBold, color: headerColor, fontSize: 10)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (clientLogoMemoryImg != null)
                    pw.Container(
                      width: 85,
                      height: 85,
                      alignment: pw.Alignment.center,
                      child: pw.Image(
                        clientLogoMemoryImg,
                        width: 85,
                        height: 85,
                        fit: pw.BoxFit.contain,
                      ),
                    )
                  else
                    pw.Container(
                      width: 85,
                      height: 85,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400, width: 1),
                        color: PdfColors.grey200,
                      ),
                      child: pw.Center(
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text('LOGO CLIENT',
                                style: pw.TextStyle(
                                    font: _fontBold,
                                    fontSize: 8,
                                    color: PdfColors.grey600)),
                            pw.SizedBox(height: 3),
                            pw.Text('(a coller ici)',
                                style: pw.TextStyle(
                                    font: _fontRegular,
                                    fontSize: 7,
                                    color: PdfColors.grey500)),
                          ],
                        ),
                      ),
                    ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    "A l'attention de Monsieur le\nDirecteur General",
                    style: pw.TextStyle(font: _fontRegular, fontSize: 11, color: PdfColors.black),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 55),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: pw.BoxDecoration(
            color: headerColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            'RAPPORT',
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 35),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 45),
          child: pw.Text(
            subTitleOverride ??
                (() {
                  final nature = (mission.natureMission ?? '').toUpperCase();
                  final prefix = (nature.startsWith('VERIFICATION') || nature.startsWith('VÉRIFICATION'))
                      ? nature
                      : 'VERIFICATION $nature';
                  return '$prefix\nDES INSTALLATIONS ELECTRIQUES';
                })(),
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: 15,
              color: headerColor,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 45),
        pw.Container(
          width: double.infinity,
          child: pw.Column(
            children: [
              pw.Text(
                mission.nomClient.toUpperCase(),
                style: pw.TextStyle(
                  font: _fontBold,
                  fontSize: 16,
                  color: headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
              if (mission.nomSite != null &&
                  mission.nomSite!.isNotEmpty &&
                  mission.nomSite!.toUpperCase() != mission.nomClient.toUpperCase()) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  mission.nomSite!.toUpperCase(),
                  style: pw.TextStyle(
                    font: _fontBold,
                    fontSize: 15,
                    color: headerColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 205),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (dateIntervention.isNotEmpty)
                    _coverInfoRow('Date d\'intervention', dateIntervention),
                  _coverInfoRow('Date du rapport', _formatDate(mission.dateRapport ?? DateTime.now())),
                  if (mission.natureMission != null)
                    _coverInfoRow('Nature de la mission', mission.natureMission!),
                  _coverInfoRow('Rapport N', 'KES/IP/VE/${DateTime.now().year}/001'),
                ],
              ),
            ),
            pw.SizedBox(width: 15),
            if (clientQrMemoryImg != null)
              pw.Container(
                width: 80,
                height: 80,
                alignment: pw.Alignment.center,
                child: pw.Image(
                  clientQrMemoryImg,
                  width: 80,
                  height: 80,
                  fit: pw.BoxFit.contain,
                ),
              )
            else
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 1),
                  color: PdfColors.grey200,
                ),
                child: pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('QR CODE',
                          style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.grey600)),
                      pw.SizedBox(height: 3),
                      pw.Text('(a coller ici)',
                          style: pw.TextStyle(font: _fontRegular, fontSize: 7, color: PdfColors.grey500)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _coverInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 125,
            child: pw.Text(label,
                style: pw.TextStyle(fontSize: fsBody, fontWeight: pw.FontWeight.bold, color: headerColor)),
          ),
          pw.Text(': ', style: pw.TextStyle(fontSize: fsBody, fontWeight: pw.FontWeight.bold, color: headerColor)),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: fsBody, color: PdfColors.black)),
          ),
        ],
      ),
    );
  }

  static List<SommaireEntry> getSommaireEntriesForTesting({
    Mission? mission,
    AuditInstallationsElectriques? audit,
    MesuresEssais? mesures,
  }) {
    final dummyMission = mission ?? Mission(
      id: 'test',
      nomClient: 'TEST',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: 'active',
    );
    return _collectSommaireEntries(
      mission: dummyMission,
      rg: null,
      desc: null,
      audit: audit,
      mesures: mesures,
      foudres: [],
    );
  }

  static List<_SommaireEntry> _collectSommaireEntries({
    required Mission mission,
    required RenseignementsGeneraux? rg,
    required DescriptionInstallations? desc,
    required AuditInstallationsElectriques? audit,
    required MesuresEssais? mesures,
    required List<Foudre> foudres,
  }) {
    final entries = <_SommaireEntry>[];

    // Intervenants et responsabilités (Page 2)
    entries.add(_SommaireEntry(titre: "INTERVENANTS ET RESPONSABILITÉS", key: 'intervenants', level: 0, isBold: true, isUppercase: true));

    // 0. Sommaire (Page 3)
    entries.add(_SommaireEntry(titre: "SOMMAIRE", key: 'sommaire', level: 0, isBold: true, isUppercase: true));

    // 1. Objet de la vérification
    entries.add(_SommaireEntry(titre: "OBJET DE LA VÉRIFICATION", key: 'objet', level: 0, isBold: true, isUppercase: true));
    entries.add(_SommaireEntry(titre: "1. Références normatives et réglementaires", key: 'objet_normes', level: 1));
    entries.add(_SommaireEntry(titre: "2. Matériel utilisé", key: 'objet_materiel', level: 1));

    // 2. Périmètre de la mission
    entries.add(_SommaireEntry(titre: "PERIMETRE DE LA MISSION", key: 'perimetre', level: 0, isBold: true, isUppercase: true));

    // 3. Rappel des responsabilités
    entries.add(_SommaireEntry(titre: "RAPPEL DES RESPONSABILITÉS DE L'EMPLOYEUR", key: 'rappel', level: 0, isBold: true, isUppercase: true));
    entries.add(_SommaireEntry(titre: "1. Responsabilité et accompagnement", key: 'rappel_accompagnement', level: 1));
    entries.add(_SommaireEntry(titre: "2. Conditions de réalisation", key: 'rappel_conditions', level: 1));
    entries.add(_SommaireEntry(titre: "3. Vérifications complémentaires", key: 'rappel_complementaires', level: 1));
    entries.add(_SommaireEntry(titre: "4. Surveillance et maintenance des installations électriques", key: 'rappel_maintenance', level: 1));
    entries.add(_SommaireEntry(titre: "5. Formation du personnel intervenant sur les installations et à proximité", key: 'rappel_formation', level: 1));

    // 4. Mesures de sécurité autour des installations
    entries.add(_SommaireEntry(titre: "MESURES DE SÉCURITÉ AUTOUR DES INSTALLATIONS", key: 'mesures_securite', level: 0, isBold: true, isUppercase: true));
    entries.add(_SommaireEntry(titre: "1. Technicien en maintenance des installations", key: 'mesures_technicien', level: 1));
    entries.add(_SommaireEntry(titre: "2. Engagement de KES INSPECTIONS AND PROJECTS", key: 'mesures_engagement', level: 1));

    // 5. Résumé Exécutif
    entries.add(_SommaireEntry(titre: "RESUME EXECUTIF", key: 'resume_executif', level: 0, isBold: true, isUppercase: true));
    entries.add(_SommaireEntry(titre: "1. Contexte et périmètre de la mission", key: 'resume_executif_1_1', level: 1));
    entries.add(_SommaireEntry(titre: "2. Synthèse des résultats", key: 'resume_executif_1_2', level: 1));
    entries.add(_SommaireEntry(titre: "3. Concentration du risque", key: 'resume_executif_1_3', level: 1));
    entries.add(_SommaireEntry(titre: "4. Facteurs de risque prépondérants", key: 'resume_executif_1_4', level: 1));
    entries.add(_SommaireEntry(titre: "5. Observations et constats majeurs", key: 'resume_executif_1_5', level: 1));
    entries.add(_SommaireEntry(titre: "6. Recommandations prioritaires hiérarchisées", key: 'resume_executif_1_6', level: 1));
    entries.add(_SommaireEntry(titre: "7. Appréciation globale", key: 'resume_executif_1_7', level: 1));

    // 6. Analyse Statistique
    entries.add(_SommaireEntry(titre: "ANALYSE STATISTIQUE", key: 'analyse_statistique', level: 0, isBold: true, isUppercase: true));
    entries.add(_SommaireEntry(titre: "1. Indicateurs clés de la mission", key: 'stat_indicateurs', level: 1));
    entries.add(_SommaireEntry(titre: "2. Inventaire chiffré des installations et équipements", key: 'stat_inventaire', level: 1));
    entries.add(_SommaireEntry(titre: "3. Répartition par criticité", key: 'stat_criticite', level: 1));
    entries.add(_SommaireEntry(titre: "4. Non-conformités de l'année passée et taux de mise en conformité", key: 'stat_annee_passee', level: 1));
    entries.add(_SommaireEntry(titre: "5. Statistique par type de défaut — analyse de Pareto", key: 'stat_pareto', level: 1));
    entries.add(_SommaireEntry(titre: "6. Répartition par domaine de tension", key: 'stat_tension', level: 1));
    entries.add(_SommaireEntry(titre: "7. Non-conformités croisées par catégorie d'équipement — vue enrichie", key: 'stat_croisee', level: 1));
    entries.add(_SommaireEntry(titre: "8. Synthèse de l'analyse statistique", key: 'stat_synthese', level: 1));

    // 7. Renseignements généraux
    entries.add(_SommaireEntry(titre: "RENSEIGNEMENTS GÉNÉRAUX DE L'ÉTABLISSEMENT", key: 'renseignements', level: 0, isBold: true, isUppercase: true));
    entries.add(_SommaireEntry(titre: "1. Renseignements principaux", key: 'renseignements_principaux', level: 1));
    entries.add(_SommaireEntry(titre: "2. Documents nécessaires à la vérification", key: 'renseignements_documents', level: 1));
    entries.add(_SommaireEntry(titre: "3. Habilitation électrique du personnel d'intervention", key: 'renseignements_habilitation', level: 1));

    // 8. Description des installations
    int descSubIdx = 1;
    entries.add(_SommaireEntry(titre: "DESCRIPTION DES INSTALLATIONS", key: 'description', level: 0, isBold: true, isUppercase: true));
    entries.add(_SommaireEntry(titre: "${descSubIdx++}. Caractéristiques de l'alimentation moyenne tension", key: 'desc_mt', level: 1));
    entries.add(_SommaireEntry(titre: "${descSubIdx++}. Caractéristiques de l'alimentation basse tension sortie transformateur", key: 'desc_bt', level: 1));
    entries.add(_SommaireEntry(titre: "${descSubIdx++}. Caractéristiques du groupe électrogène", key: 'desc_ge', level: 1));
    entries.add(_SommaireEntry(titre: "${descSubIdx++}. Alimentation du groupe électrogène en carburant", key: 'desc_carburant', level: 1));
    entries.add(_SommaireEntry(titre: "${descSubIdx++}. Caractéristiques de l'inverseur", key: 'desc_inverseur', level: 1));
    entries.add(_SommaireEntry(titre: "${descSubIdx++}. Caractéristiques du stabilisateur", key: 'desc_stabilisateur', level: 1));
    entries.add(_SommaireEntry(titre: "${descSubIdx++}. Caractéristiques des onduleurs", key: 'desc_onduleurs', level: 1));
    entries.add(_SommaireEntry(titre: "${descSubIdx++}. Régime de neutre", key: 'desc_regime_neutre', level: 1));
    entries.add(_SommaireEntry(titre: "${descSubIdx++}. Eclairage de sécurité", key: 'desc_eclairage', level: 1));
    entries.add(_SommaireEntry(titre: "${descSubIdx++}. Modifications apportées aux installations", key: 'desc_modifications', level: 1));
    entries.add(_SommaireEntry(titre: "${descSubIdx++}. Note de calcul des installations électriques", key: 'desc_note_calcul', level: 1));
    entries.add(_SommaireEntry(titre: "${descSubIdx++}. Présence de paratonnerre", key: 'desc_paratonnerre', level: 1));
    entries.add(_SommaireEntry(titre: "${descSubIdx++}. Registre de sécurité", key: 'desc_registre', level: 1));
    entries.add(_SommaireEntry(titre: "${descSubIdx++}. Zones et Locaux à risque", key: 'desc_locaux_risques', level: 1));

    // 9. Liste récapitulative (si audit)
    if (audit != null) {
      entries.add(_SommaireEntry(titre: "SYNTHÈSE RÉCAPITULATIVE DES OBSERVATIONS", key: 'liste_recap', level: 0, isBold: true, isUppercase: true));
      entries.add(_SommaireEntry(titre: "1. Moyenne tension", key: 'liste_recap_mt', level: 1));
      entries.add(_SommaireEntry(titre: "2. Basse tension", key: 'liste_recap_bt', level: 1));
    }

    // 10. Audit des installations (si audit)
    if (audit != null) {
      entries.add(_SommaireEntry(titre: "AUDIT DES INSTALLATIONS ELECTRIQUES", key: 'audit', level: 0, isBold: true, isUppercase: true));
    }

    // 11. Classement
    entries.add(_SommaireEntry(titre: "CLASSEMENT ET EMPLACEMENTS DES LOCAUX ET ZONES EN FONCTION DES INFLUENCES EXTERNES", key: 'classement', level: 0, isBold: true, isUppercase: true));

    // 12. Foudre
    entries.add(_SommaireEntry(titre: "FOUDRE", key: 'foudre', level: 0, isBold: true, isUppercase: true));
    entries.add(_SommaireEntry(titre: "1. Observations par équipement", key: 'foudre_equipements', level: 1));

    // 13. Mesures et essais (si mesures)
    if (mesures != null) {
      entries.add(_SommaireEntry(titre: "RESULTATS DES MESURES ET ESSAIS", key: 'mesures', level: 0, isBold: true, isUppercase: true));
      entries.add(_SommaireEntry(titre: "1. Conditions de mesure", key: 'mesures_conditions', level: 1));
      entries.add(_SommaireEntry(titre: "2. Essais de démarrage automatique du groupe électrogène", key: 'mesures_demarrage', level: 1));
      entries.add(_SommaireEntry(titre: "3. Test de fonctionnement de l'arrêt d'urgence", key: 'mesures_arret', level: 1));
      entries.add(_SommaireEntry(titre: "4. Prise de terre", key: 'mesures_terre', level: 1));
      entries.add(_SommaireEntry(titre: "5. Essais de déclenchement des dispositifs différentiels", key: 'mesures_ddr', level: 1));
      entries.add(_SommaireEntry(titre: "6. Essais de mesure d'isolement entre deux points d'un tronçon de câble", key: 'mesures_isolement', level: 1));
      entries.add(_SommaireEntry(titre: "7. Test du Contrôleur Permanent d'Isolement (CPI)", key: 'mesures_cpi', level: 1));
      entries.add(_SommaireEntry(titre: "8. Continuité et de la résistance des conducteurs de protection et des liaisons équipotentielles", key: 'mesures_continuite', level: 1));
    }

    // Signature du rapport
    entries.add(_SommaireEntry(titre: "Signature du rapport", key: 'signature_rapport', level: 0, isBold: true, isUppercase: false));

    // 14. Photos
    entries.add(_SommaireEntry(titre: "PHOTOS", key: 'photos', level: 0, isBold: true, isUppercase: true));

    // 15. Schéma des installations électriques (si Oui)
    final bool hasSchema = mission.schemaOption?.trim().toLowerCase() == 'oui';
    if (hasSchema) {
      entries.add(_SommaireEntry(
        titre: "SCHEMA DES INSTALLATIONS ELECTRIQUES",
        key: 'schema_installations',
        level: 0,
        isBold: true,
        isUppercase: true,
      ));
    }

    return entries;
  }

  // ──────────────────────────────────────────────────────────────
  //  SOMMAIRE (format Word avec points de liaison)
  // ──────────────────────────────────────────────────────────────
  
  static void _addSommairePages(
    pw.Document pdf,
    List<_SommaireEntry> entries,
    Map<String, int> trackedPages, {
    String? nomClient,
    String? nomSite,
    String? numeroRapport,
    int pageOffset = 0,
    int? overrideTotalPages,
  }) {
    pdf.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(pageOffset: pageOffset, overrideTotalPages: overrideTotalPages),
      header: (ctx) => _buildPageHeaderWidget(
        nomClient: nomClient,
        nomSite: nomSite,
        numeroRapport: numeroRapport,
      ),
      build: (ctx) => [
        PageTracker(
          key: 'sommaire',
          registry: trackedPages,
          offset: pageOffset,
          child: pw.Center(
            child: pw.Text(
              'SOMMAIRE',
              style: pw.TextStyle(
                font: _fontBold,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity, height: 1.5, color: accentColor,
        ),
        pw.SizedBox(height: 16),
        ...entries.map((entry) => _buildSommaireEntryLine(entry, trackedPages)),
      ],
    ));
  }

  static pw.Widget _buildSommaireEntryLine(_SommaireEntry entry, Map<String, int> trackedPages) {
    final double leftPadding = entry.level * 14.0;
    
    // Choose font & size
    final double fontSize = entry.level == 0 
        ? 8.5 
        : (entry.level == 1 ? 8.0 : (entry.level == 2 ? 7.5 : 7.0));
    final pw.Font font = entry.isBold ? _fontBold : _fontRegular;
    final PdfColor color = accentColor; // Consistent color

    final titleText = entry.isUppercase ? entry.titre.toUpperCase() : entry.titre;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4.0),
      child: pw.Stack(
        alignment: pw.Alignment.bottomRight,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(right: 20.0),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (leftPadding > 0) pw.SizedBox(width: leftPadding),
                pw.Flexible(
                  child: pw.Text(
                    titleText.trim(),
                    style: pw.TextStyle(font: font, fontSize: fontSize, color: color),
                    maxLines: 1,
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  child: pw.CustomPaint(
                    painter: (PdfGraphics canvas, PdfPoint size) {
                      canvas.setStrokeColor(PdfColors.grey400);
                      canvas.setLineWidth(0.8);
                      canvas.setLineDashPattern([1, 2.5]);
                      canvas.drawLine(0, 2, size.x, 2);
                      canvas.strokePath();
                    },
                  ),
                ),
              ],
            ),
          ),
          pw.Positioned(
            right: 0,
            bottom: 0,
            child: PageNumberText(
              keyName: entry.key,
              registry: trackedPages,
              style: pw.TextStyle(
                font: _fontBold,
                fontSize: fontSize,
                color: headerColor,
              ),
            ),
          ),
        ],
      ),
    );
  }



  static pw.Widget _buildNormesTable() {
    final normes = [
      ['Articles 6, 112, 113 – Arrêté 039/MTPS/IMT du 26 novembre 1984', 'Fixant les mesures générales d\'hygiène et de sécurité sur les lieux de travail'],
      ['Décret N° 20181969/PM du 15 mars 2018', 'Cahier de prescription technique applicable, fixant les règles de base de sécurité incendie dans les bâtiments'],
      ['Arrêté conjoint 002164 du 21 juin 2012 MNIMIDT/MINEE', '—'],
      ['Loi N° 896/PJL/AN du 15/11/2011', '—'],
      ['NC 244 C 15 100', 'Installation électrique à basse tension'],
      ['NF C 15 100', 'Installation électrique à basse tension'],
      ['Norme NF C 13 100', 'Poste de livraison établi à l\'intérieur d\'un bâtiment et alimenté par un réseau de distribution publique de deuxième catégorie'],
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.5),
        1: pw.FlexColumnWidth(5.5),
      },
      children: [
        _tableHeaderRow(['Référence', 'Objet']),
        ...normes.asMap().entries.map((e) =>
          _tableDataRow(e.value, alt: e.key.isOdd)),
      ],
    );
  }

  static pw.Widget _buildMaterielTable() {
    final materiel = [
      ['Mesure de la résistance de prises de terre', 'FLUKE – 1630 2 FC'],
      ['Mesure de l\'isolement', 'CHAUVIN ARNOUX CA 6462'],
      ['Vérification de la continuité et de la résistance des conducteurs de protection et des liaisons équipotentielles', 'CHAUVIN ARNOUX CA 6462'],
      ['Test de déclenchement des dispositifs différentiels et mesure des impédances de boucle', 'CHAUVIN ARNOUX CA 6462'],
      ['Contrôleur d\'installation électrique', 'CHAUVIN ARNOUX CA 6116N'],
      ['Analyseur de réseaux', 'CHAUVIN ARNOUX PEL 103 140631NFH'],
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(6.0),
        1: pw.FlexColumnWidth(4.0),
      },
      children: [
        _tableHeaderRow(['Description', 'Appareil / Référence']),
        ...materiel.asMap().entries.map((e) {
          final isOdd = e.key.isOdd;
          return pw.TableRow(
            decoration: isOdd ? pw.BoxDecoration(color: tableRowAlt) : null,
            children: [
              _cell(e.value[0], isHeader: false, centered: false),
              _cell(e.value[1], isHeader: false, centered: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildPerimetreTable(Mission mission, RenseignementsGeneraux? rg) {
    // 1. Périmètre normalisé
    final rawPerimetres = (mission.perimetreMission != null && mission.perimetreMission!.isNotEmpty)
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
    final dateFin   = rg?.dateFin;
    String dateInterventionStr;
    if (dateDebut != null && dateFin != null && !dateDebut.isAtSameMomentAs(dateFin)) {
      dateInterventionStr = 'Du ${_formatDate(dateDebut)} au ${_formatDate(dateFin)}';
    } else if (dateDebut != null) {
      dateInterventionStr = _formatDate(dateDebut);
    } else {
      dateInterventionStr = _formatDate(DateTime.now());
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
    if (mission.accompagnateurs != null && mission.accompagnateurs!.isNotEmpty) {
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
          .map((v) => '${v['prenom'] ?? ''} ${v['nom'] ?? ''}'.trim().toUpperCase())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (rg != null && rg.verificateurs.isNotEmpty) {
      verificateursList = rg.verificateurs
          .map((v) => '${v['prenom'] ?? ''} ${v['nom'] ?? ''}'.trim().toUpperCase())
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
      font: _fontBold,
      fontSize: 9.5,
      fontWeight: pw.FontWeight.bold,
      color: headerColor,
    );
    final valueStyle = pw.TextStyle(
      font: _fontBold,
      fontSize: 9.5,
      fontWeight: pw.FontWeight.bold,
      color: headerColor,
    );

    pw.TableRow buildTableRow(String label, pw.Widget contentWidget, {required bool isOdd}) {
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
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: pw.Text('Missions', style: labelStyle),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: perimetres.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isLast = idx == perimetres.length - 1;
                final isOdd = idx.isOdd;
                final bg = isOdd ? PdfColor.fromHex('#F8FAFC') : PdfColors.white;

                return pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    color: bg,
                    border: isLast
                        ? null
                        : pw.Border(
                            bottom: pw.BorderSide(color: gridColor, width: borderWidth),
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
          pw.Text(mission.natureMission ?? 'Périodique réglementaire', style: valueStyle),
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
            children: verificateursList.map((v) => pw.Text(v, style: valueStyle)).toList(),
          ),
          isOdd: true,
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  ANALYSE STATISTIQUE
  // ──────────────────────────────────────────────────────────────

  static String _formatPercent(double val) {
    return '${val.toStringAsFixed(1).replaceAll('.', ',')} %';
  }

  static pw.Widget _buildCalloutBox(String title, String body) {
    final boxBorderColor = accentColor;
    final boxBgColor = PdfColor.fromHex('#F4F7FA');
    final boxTitleColor = headerColor;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: boxBgColor,
        border: pw.Border.all(color: boxBorderColor, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: boxTitleColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            body,
            style: pw.TextStyle(
              font: _fontRegular,
              fontSize: 8.5,
              color: darkGrey,
              lineSpacing: 1.6,
            ),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBarChart(int critique, int majeure, int mineure) {
    final maxVal = [critique, majeure, mineure, 1].reduce((a, b) => a > b ? a : b);
    final yMax = ((maxVal * 1.25) / 10).ceil() * 10 > 0
        ? ((maxVal * 1.25) / 10).ceil() * 10
        : 10;
    final yMid = (yMax / 2).round();

    const double chartHeight = 100.0;
    const double barWidth = 46.0;

    double calcBarHeight(int val) {
      if (yMax == 0) return 0;
      final h = (val / yMax) * chartHeight;
      return h < 2 && val > 0 ? 2 : h;
    }

    final hCritique = calcBarHeight(critique);
    final hMajeure = calcBarHeight(majeure);
    final hMineure = calcBarHeight(mineure);

    final colorCritique = PdfColor.fromHex('#DC2626');
    final colorMajeure = PdfColor.fromHex('#EA580C');
    final colorMineure = PdfColor.fromHex('#16A34A');

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: pw.Column(
        children: [
          pw.Text(
            'Répartition des non-conformités par criticité',
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Axe Y - valeurs
              pw.Container(
                height: chartHeight + 20,
                margin: const pw.EdgeInsets.only(right: 6),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('$yMax', style: pw.TextStyle(font: _fontRegular, fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('$yMid', style: pw.TextStyle(font: _fontRegular, fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('0', style: pw.TextStyle(font: _fontRegular, fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ),

              // Ligne d'axe Y
              pw.Container(
                height: chartHeight + 2,
                width: 0.8,
                color: PdfColors.grey400,
              ),
              pw.SizedBox(width: 20),

              // Barres (Critique, Majeure, Mineure)
              pw.Container(
                height: chartHeight + 28,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Critique
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('$critique', style: pw.TextStyle(font: _fontBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: barWidth,
                          height: hCritique,
                          decoration: pw.BoxDecoration(
                            color: colorCritique,
                            borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(2)),
                          ),
                        ),
                        pw.Container(height: 0.8, width: barWidth + 14, color: PdfColors.grey600),
                        pw.SizedBox(height: 4),
                        pw.Text('Critique', style: pw.TextStyle(font: _fontBold, fontSize: 8.5, color: accentColor)),
                      ],
                    ),
                    pw.SizedBox(width: 28),

                    // Majeure
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('$majeure', style: pw.TextStyle(font: _fontBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: barWidth,
                          height: hMajeure,
                          decoration: pw.BoxDecoration(
                            color: colorMajeure,
                            borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(2)),
                          ),
                        ),
                        pw.Container(height: 0.8, width: barWidth + 14, color: PdfColors.grey600),
                        pw.SizedBox(height: 4),
                        pw.Text('Majeure', style: pw.TextStyle(font: _fontBold, fontSize: 8.5, color: accentColor)),
                      ],
                    ),
                    pw.SizedBox(width: 28),

                    // Mineure
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('$mineure', style: pw.TextStyle(font: _fontBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: barWidth,
                          height: hMineure,
                          decoration: pw.BoxDecoration(
                            color: colorMineure,
                            borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(2)),
                          ),
                        ),
                        pw.Container(height: 0.8, width: barWidth + 14, color: PdfColors.grey600),
                        pw.SizedBox(height: 4),
                        pw.Text('Mineure', style: pw.TextStyle(font: _fontBold, fontSize: 8.5, color: accentColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCriticiteTable(
    int critique,
    int majeure,
    int mineure,
    int total,
    double pctCritique,
    double pctMajeure,
    double pctMineure,
  ) {
    final headerStyle = pw.TextStyle(
      font: _fontBold,
      fontSize: 8.5,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final labelStyle = pw.TextStyle(
      font: _fontRegular,
      fontSize: 8.5,
      color: PdfColors.black,
    );
    final boldStyle = pw.TextStyle(
      font: _fontBold,
      fontSize: 8.5,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    );

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.5),
        1: pw.FlexColumnWidth(3.0),
        2: pw.FlexColumnWidth(3.5),
      },
      children: [
        // En-tête
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              child: pw.Text('CRITICIT\u00c9', style: headerStyle, textAlign: pw.TextAlign.left),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              child: pw.Text('NOMBRE', style: headerStyle, textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              child: pw.Text('PART DU TOTAL', style: headerStyle, textAlign: pw.TextAlign.center),
            ),
          ],
        ),
        // Critique
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: pw.Text('Critique', style: labelStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: pw.Text('$critique', style: labelStyle, textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: pw.Text(_formatPercent(pctCritique), style: labelStyle, textAlign: pw.TextAlign.center),
            ),
          ],
        ),
        // Majeure
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8FAFC')),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: pw.Text('Majeure', style: labelStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: pw.Text('$majeure', style: labelStyle, textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: pw.Text(_formatPercent(pctMajeure), style: labelStyle, textAlign: pw.TextAlign.center),
            ),
          ],
        ),
        // Mineure
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: pw.Text('Mineure', style: labelStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: pw.Text('$mineure', style: labelStyle, textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: pw.Text(_formatPercent(pctMineure), style: labelStyle, textAlign: pw.TextAlign.center),
            ),
          ],
        ),
        // TOTAL
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9')),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              child: pw.Text('TOTAL', style: boldStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              child: pw.Text('$total', style: boldStyle, textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              child: pw.Text(total > 0 ? '100 %' : '0 %', style: boldStyle, textAlign: pw.TextAlign.center),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatDateRangeFrench(DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      return _formatDate(DateTime.now());
    }
    final s = start ?? end!;
    final e = end ?? start!;

    final months = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];

    if (s.year == e.year && s.month == e.month && s.day == e.day) {
      return 'le ${s.day} ${months[s.month]} ${s.year}';
    }

    if (s.year == e.year && s.month == e.month) {
      if (e.day == s.day + 1) {
        return 'les ${s.day} et ${e.day} ${months[s.month]} ${s.year}';
      } else {
        return 'du ${s.day} au ${e.day} ${months[s.month]} ${s.year}';
      }
    }

    if (s.year == e.year) {
      return 'du ${s.day} ${months[s.month]} au ${e.day} ${months[e.month]} ${s.year}';
    }

    return 'du ${s.day} ${months[s.month]} ${s.year} au ${e.day} ${months[e.month]} ${e.year}';
  }

  static pw.Widget _buildBulletItemRow({
    required String countText,
    required String label,
    required String pctText,
    required bool isLast,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 14, bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('•  ', style: pw.TextStyle(font: _fontBold, fontSize: fsBody, color: darkGrey)),
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: darkGrey),
                children: [
                  pw.TextSpan(text: countText, style: pw.TextStyle(font: _fontBold)),
                  pw.TextSpan(text: label),
                  pw.TextSpan(text: ', soit '),
                  pw.TextSpan(text: '$pctText %', style: pw.TextStyle(font: _fontBold)),
                  pw.TextSpan(text: isLast ? '.' : ' ;'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSimpleBulletRow(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 14, bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('•  ', style: pw.TextStyle(font: _fontBold, fontSize: fsBody, color: darkGrey)),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: darkGrey, lineSpacing: 2.5),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la section « RÉSUMÉ EXÉCUTIF » structurée en 7 sous-sections officielles.
  static List<pw.Widget> _buildResumeExecutif(
    Mission mission,
    Map<String, int> trackedPages,
    String numeroRapportDoc, {
    ExecutiveSummaryData? summaryData,
    int offset = 0,
  }) {
    final widgets = <pw.Widget>[];

    final snapshot = ExecutiveSummarySnapshot.fromMission(mission.id);
    final data = summaryData ?? MissionExecutiveSummaryService.buildDeterministicFallback(mission.id, snapshot);

    // Entête de section RÉSUMÉ EXÉCUTIF
    widgets.add(PageTracker(
      key: 'resume_executif',
      registry: trackedPages,
      offset: offset,
      child: _sectionBox('RESUME EXECUTIF'),
    ));
    widgets.add(pw.SizedBox(height: 12));

    // ── 1. Contexte et périmètre de la mission ──
    widgets.add(pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PageTracker(
          key: 'resume_executif_1_1',
          registry: trackedPages,
          offset: offset,
          child: _subSectionHeader('1. Contexte et périmètre de la mission'),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          data.contexte.paragraph,
          style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: darkGrey, lineSpacing: 2.5),
          textAlign: pw.TextAlign.justify,
        ),
      ],
    ));
    widgets.add(pw.SizedBox(height: 10));

    // ── 2. Synthèse des résultats ──
    widgets.add(pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PageTracker(
          key: 'resume_executif_1_2',
          registry: trackedPages,
          offset: offset,
          child: _subSectionHeader('2. Synthèse des résultats'),
        ),
        pw.SizedBox(height: 4),
        if (data.syntheseResultats.introParagraph.isNotEmpty)
          pw.Text(
            data.syntheseResultats.introParagraph,
            style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: darkGrey, lineSpacing: 2.5),
            textAlign: pw.TextAlign.justify,
          ),
      ],
    ));
    widgets.add(pw.SizedBox(height: 6));

    // Tableau de criticité (1.2)
    if (data.syntheseResultats.tableRows.isNotEmpty) {
      widgets.add(_buildCriticalitySummaryTable(
        data.syntheseResultats.tableRows,
        data.syntheseResultats.tableTotalRow,
        totalEquipments: snapshot.equipmentCount,
      ));
      widgets.add(pw.SizedBox(height: 6));
    }

    if (data.syntheseResultats.commentaryParagraph.isNotEmpty) {
      widgets.add(pw.Text(
        data.syntheseResultats.commentaryParagraph,
        style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: darkGrey, lineSpacing: 2.5),
        textAlign: pw.TextAlign.justify,
      ));
      widgets.add(pw.SizedBox(height: 10));
    }

    // ── 3. Concentration du risque ──
    final concRows = <pw.TableRow>[];
    if (data.concentrationRisque.primaryConcentrationParagraph.isNotEmpty) {
      concRows.add(_buildIndicateurRow('Volume & Catégories', data.concentrationRisque.primaryConcentrationParagraph));
    }
    if (data.concentrationRisque.highestDensityParagraph.isNotEmpty) {
      concRows.add(_buildIndicateurRow('Densité d\'équipement', data.concentrationRisque.highestDensityParagraph));
    }

    widgets.add(pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PageTracker(
          key: 'resume_executif_1_3',
          registry: trackedPages,
          offset: offset,
          child: _subSectionHeader(_formatConcentrationTitle(data.concentrationRisque.title)),
        ),
        pw.SizedBox(height: 4),
        if (concRows.isNotEmpty)
          pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(3.0),
              1: pw.FlexColumnWidth(7.0),
            },
            children: [
              pw.TableRow(
                verticalAlignment: pw.TableCellVerticalAlignment.middle,
                decoration: pw.BoxDecoration(color: accentColor),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('AXE DE CONCENTRATION', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('ANALYSE ET CONSTAT', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                ],
              ),
              ...concRows,
            ],
          ),
        if (data.concentrationRisque.qualitativeRiskCallout.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            'Point de risque qualitatif :',
            style: pw.TextStyle(font: _fontBold, fontSize: fsBody, color: darkGrey),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            data.concentrationRisque.qualitativeRiskCallout,
            style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: darkGrey, lineSpacing: 2.5),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      ],
    ));
    widgets.add(pw.SizedBox(height: 10));

    // ── 4. Facteurs de risque prépondérants ──
    widgets.add(pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PageTracker(
          key: 'resume_executif_1_4',
          registry: trackedPages,
          offset: offset,
          child: _subSectionHeader('4. Facteurs de risque prépondérants'),
        ),
        pw.SizedBox(height: 4),
        if (data.facteursRisque.introParagraph.isNotEmpty)
          pw.Text(
            data.facteursRisque.introParagraph,
            style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: darkGrey, lineSpacing: 2.5),
            textAlign: pw.TextAlign.justify,
          ),
      ],
    ));
    widgets.add(pw.SizedBox(height: 6));

    // Tableau des facteurs de risque (1.4)
    if (data.facteursRisque.tableRows.isNotEmpty) {
      widgets.add(_buildRiskFactorsSummaryTable(data.facteursRisque.tableRows));
      widgets.add(pw.SizedBox(height: 6));
    }

    if (data.facteursRisque.commentaryParagraph.isNotEmpty) {
      widgets.add(pw.Text(
        data.facteursRisque.commentaryParagraph,
        style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: darkGrey, lineSpacing: 2.5),
        textAlign: pw.TextAlign.justify,
      ));
      widgets.add(pw.SizedBox(height: 10));
    }

    // ── 5. Observations et constats majeurs ──
    final obsRows = <pw.TableRow>[];
    for (int i = 0; i < data.observationsMajores.bulletPoints.length; i++) {
      final parsed = _parseObservationRow(data.observationsMajores.bulletPoints[i]);
      obsRows.add(
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${i + 1}', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: headerColor), textAlign: pw.TextAlign.center)),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(parsed.observation, style: pw.TextStyle(font: _fontBold, fontSize: 7.5, color: headerColor))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(parsed.stats, style: pw.TextStyle(font: _fontRegular, fontSize: 7.5, color: darkGrey), textAlign: pw.TextAlign.center)),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(parsed.constatMajeur, style: pw.TextStyle(font: _fontRegular, fontSize: 7.5))),
          ],
        ),
      );
    }

    final obsHeaderRow = pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.middle,
      decoration: pw.BoxDecoration(color: accentColor),
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('N°', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white), textAlign: pw.TextAlign.center)),
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('OBSERVATION', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white))),
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('STATS', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white), textAlign: pw.TextAlign.center)),
        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('CONSTAT MAJEUR', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white))),
      ],
    );

    final obsHeaderWidget = PageTracker(
      key: 'resume_executif_1_5',
      registry: trackedPages,
      offset: offset,
      child: _subSectionHeader('5. Observations et constats majeurs'),
    );

    final obsBlocks = _buildHeaderWithTableList(
      headerWidget: obsHeaderWidget,
      headerRow: obsHeaderRow,
      dataRows: obsRows,
      columnWidths: const {
        0: pw.FlexColumnWidth(0.8),
        1: pw.FlexColumnWidth(3.2),
        2: pw.FlexColumnWidth(2.2),
        3: pw.FlexColumnWidth(3.8),
      },
    );

    widgets.addAll(obsBlocks);

    if (data.observationsMajores.summaryParagraph.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 4));
      widgets.add(pw.Text(
        data.observationsMajores.summaryParagraph,
        style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: darkGrey, lineSpacing: 2.5),
        textAlign: pw.TextAlign.justify,
      ));
    }
    widgets.add(pw.SizedBox(height: 10));

    // ── 6. Recommandations prioritaires hiérarchisées ──
    final recoRows = <pw.TableRow>[];
    if (data.recommandationsPrioritaires.priority1Immediate.isNotEmpty) {
      recoRows.add(pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FEF2F2')),
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Priorité 1 — Action Immédiate', style: pw.TextStyle(font: _fontBold, fontSize: 7.5, color: PdfColor.fromHex('#B71C1C')))),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_cleanRecommendationText(data.recommandationsPrioritaires.priority1Immediate), style: pw.TextStyle(font: _fontRegular, fontSize: 7.5))),
        ],
      ));
    }
    if (data.recommandationsPrioritaires.priority2ShortTerm.isNotEmpty) {
      recoRows.add(pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FFF7ED')),
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Priorité 2 — Court Terme', style: pw.TextStyle(font: _fontBold, fontSize: 7.5, color: PdfColor.fromHex('#C2410C')))),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_cleanRecommendationText(data.recommandationsPrioritaires.priority2ShortTerm), style: pw.TextStyle(font: _fontRegular, fontSize: 7.5))),
        ],
      ));
    }
    if (data.recommandationsPrioritaires.priority3MediumTerm.isNotEmpty) {
      recoRows.add(pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Priorité 3 — Moyen Terme', style: pw.TextStyle(font: _fontBold, fontSize: 7.5, color: PdfColors.grey800))),
          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_cleanRecommendationText(data.recommandationsPrioritaires.priority3MediumTerm), style: pw.TextStyle(font: _fontRegular, fontSize: 7.5))),
        ],
      ));
    }

    final recoHeaderRow = pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.middle,
      decoration: pw.BoxDecoration(color: accentColor),
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('NIVEAU DE PRIORITÉ', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white))),
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('ACTION CORRECTIVE RECOMMANDÉE', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white))),
      ],
    );

    final recoHeaderWidget = PageTracker(
      key: 'resume_executif_1_6',
      registry: trackedPages,
      offset: offset,
      child: _subSectionHeader('6. Recommandations prioritaires hiérarchisées'),
    );

    final recoIntroWidget = data.recommandationsPrioritaires.introParagraph.isNotEmpty
        ? pw.Text(
            data.recommandationsPrioritaires.introParagraph,
            style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: darkGrey, lineSpacing: 2.5),
            textAlign: pw.TextAlign.justify,
          )
        : null;

    final recoBlocks = _buildHeaderWithTableList(
      headerWidget: recoHeaderWidget,
      introWidget: recoIntroWidget,
      headerRow: recoHeaderRow,
      dataRows: recoRows,
      columnWidths: const {
        0: pw.FlexColumnWidth(3.5),
        1: pw.FlexColumnWidth(6.5),
      },
    );

    widgets.addAll(recoBlocks);
    widgets.add(pw.SizedBox(height: 10));

    // ── 7. Appréciation globale ──
    widgets.add(pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PageTracker(
          key: 'resume_executif_1_7',
          registry: trackedPages,
          offset: offset,
          child: _subSectionHeader('7. Appréciation globale'),
        ),
        pw.SizedBox(height: 4),
        if (data.appreciationGlobale.assessmentParagraph1.isNotEmpty)
          pw.Text(
            data.appreciationGlobale.assessmentParagraph1,
            style: pw.TextStyle(font: _fontBold, fontSize: fsBody, color: darkGrey, lineSpacing: 2.5),
            textAlign: pw.TextAlign.justify,
          ),
      ],
    ));
    widgets.add(pw.SizedBox(height: 4));
    if (data.appreciationGlobale.assessmentParagraph2.isNotEmpty) {
      widgets.add(pw.Text(
        data.appreciationGlobale.assessmentParagraph2,
        style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: darkGrey, lineSpacing: 2.5),
        textAlign: pw.TextAlign.justify,
      ));
      widgets.add(pw.SizedBox(height: 4));
    }
    if (data.appreciationGlobale.assessmentParagraph3.isNotEmpty) {
      widgets.add(pw.Text(
        data.appreciationGlobale.assessmentParagraph3,
        style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: darkGrey, lineSpacing: 2.5),
        textAlign: pw.TextAlign.justify,
      ));
      widgets.add(pw.SizedBox(height: 8));
    }

    if (data.appreciationGlobale.actionPlanHeader.isNotEmpty) {
      widgets.add(pw.Text(
        data.appreciationGlobale.actionPlanHeader,
        style: pw.TextStyle(font: _fontBold, fontSize: fsBody, color: darkGrey, lineSpacing: 2.5),
        textAlign: pw.TextAlign.justify,
      ));
      widgets.add(pw.SizedBox(height: 4));
    }

    if (data.appreciationGlobale.actionPlanSteps.isNotEmpty) {
      for (int i = 0; i < data.appreciationGlobale.actionPlanSteps.length; i++) {
        final step = data.appreciationGlobale.actionPlanSteps[i];
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 10, bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 3.5,
                height: 3.5,
                margin: const pw.EdgeInsets.only(top: 4, right: 6),
                decoration: pw.BoxDecoration(color: accentColor, shape: pw.BoxShape.circle),
              ),
              pw.Expanded(
                child: pw.Text(
                  step,
                  style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: darkGrey, lineSpacing: 2.5),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
            ],
          ),
        ));
      }
      widgets.add(pw.SizedBox(height: 6));
    }

    if (data.appreciationGlobale.counterVisitParagraph.isNotEmpty) {
      widgets.add(pw.Text(
        data.appreciationGlobale.counterVisitParagraph,
        style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: darkGrey, lineSpacing: 2.5),
        textAlign: pw.TextAlign.justify,
      ));
    }

    return widgets;
  }

  static pw.Widget _subSectionHeader(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        font: _fontBold,
        fontSize: fsH2,
        color: accentColor,
      ),
    );
  }

  static pw.Widget _buildCriticalitySummaryTable(
    List<CriticalityRowData> rows,
    CriticalityRowData totalRow, {
    int? totalEquipments,
  }) {
    final densityHeader = (totalEquipments != null && totalEquipments > 0)
        ? 'Densité (/$totalEquipments équip.)'
        : 'Densité (/ équip.)';

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.2),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(3.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            _buildTableHeaderCell('Criticité'),
            _buildTableHeaderCell('Nombre'),
            _buildTableHeaderCell('Part du total'),
            _buildTableHeaderCell(densityHeader),
          ],
        ),
        for (int i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i % 2 == 1 ? tableRowAlt : PdfColors.white,
            ),
            children: [
              _buildTableCell(rows[i].criticite, isBold: true),
              _buildTableCell('${rows[i].nombre}', align: pw.TextAlign.center),
              _buildTableCell(rows[i].partPct, align: pw.TextAlign.center),
              _buildTableCell(rows[i].densiteStr, align: pw.TextAlign.center),
            ],
          ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            _buildTableCell(totalRow.criticite, isBold: true),
            _buildTableCell('${totalRow.nombre}', isBold: true, align: pw.TextAlign.center),
            _buildTableCell(totalRow.partPct, isBold: true, align: pw.TextAlign.center),
            _buildTableCell(totalRow.densiteStr, isBold: true, align: pw.TextAlign.center),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildRiskFactorsSummaryTable(List<RiskFactorRowData> rows) {
    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.5),
        1: pw.FlexColumnWidth(1.3),
        2: pw.FlexColumnWidth(1.4),
        3: pw.FlexColumnWidth(3.8),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            _buildTableHeaderCell('Nature du risque'),
            _buildTableHeaderCell('Constats'),
            _buildTableHeaderCell('Part (%)'),
            _buildTableHeaderCell('Observation'),
          ],
        ),
        for (int i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i % 2 == 1 ? tableRowAlt : PdfColors.white,
            ),
            children: [
              _buildTableCell(rows[i].natureRisque, isBold: true),
              _buildTableCell(rows[i].constats, align: pw.TextAlign.center),
              _buildTableCell(rows[i].partPct, align: pw.TextAlign.center),
              _buildTableCell(rows[i].observation),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isBold ? _fontBold : _fontRegular,
          fontSize: fsSmall,
          color: darkGrey,
        ),
        textAlign: align,
      ),
    );
  }

  static List<pw.Widget> _buildAnalyseStatistique(
    Mission mission,
    Map<String, int> trackedPages,
    String numeroRapportDoc, {
    int offset = 0,
  }) {
    final widgets = <pw.Widget>[];

    // Collecte unifiée via le résumé statistique Néo-Natif
    final summary = MissionStatisticsCollector.collectSummary(mission.id);
    final inventory = summary.inventory;
    final cStats = summary.criticalityStats;

    final critique = cStats.critique;
    final majeure = cStats.majeure;
    final mineure = cStats.mineure;
    final total = cStats.total;
    final pctCritique = cStats.pctCritique;
    final pctMajeure = cStats.pctMajeure;
    final pctMineure = cStats.pctMineure;

    // Entête de section
    widgets.add(PageTracker(
      key: 'analyse_statistique',
      registry: trackedPages,
      offset: offset,
      child: _sectionBox('ANALYSE STATISTIQUE'),
    ));
    widgets.add(pw.SizedBox(height: 10));

    // 1. Indicateurs clés de la mission
    final totalEq = summary.totalEquipments;
    final activeCats = summary.crossCategoryItems.length;
    final densestStr = summary.densestCategoryFormatted;
    final topTwo = summary.topTwoCategoriesResult;
    final domainStats = summary.tensionDomainStats;

    widgets.add(PageTracker(
      key: 'stat_indicateurs',
      registry: trackedPages,
      offset: offset,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _subTitle('1. Indicateurs clés de la mission'),
          pw.SizedBox(height: 5),
          _bodyText('Tableau synthétique des indicateurs majeurs de la mission (gravité, concentration et volume) :'),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(3.8),
              1: pw.FlexColumnWidth(6.2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: accentColor),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('INDICATEUR', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('VALEUR ET DESCRIPTION', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white))),
                ],
              ),
              _buildIndicateurRow('Périmètre couvert', '$totalEq installations et équipements répartis en $activeCats catégories (MT et BT)'),
              _buildIndicateurRow('Total des non-conformités', '$total (recensement par installation/équipement)'),
              _buildIndicateurRow('Densité moyenne globale', '${summary.globalDensityStr} NC/équipement'),
              _buildIndicateurRow('Part des NC critiques', '${pctCritique.toStringAsFixed(1).replaceAll('.', ',')} % — niveau de risque élevé'),
              _buildIndicateurRow(topTwo.label, topTwo.formattedValue),
              _buildIndicateurRow('Catégorie la plus dense', densestStr),
              _buildIndicateurRow('Répartition MT / BT', 'MT : ${domainStats.mtCount} NC (${domainStats.mtPct.toStringAsFixed(1).replaceAll('.', ',')} %) — BT : ${domainStats.btCount} NC (${domainStats.btPct.toStringAsFixed(1).replaceAll('.', ',')} %)'),
            ],
          ),
        ],
      ),
    ));
    widgets.add(pw.SizedBox(height: 12));

    // 2. Inventaire chiffré des installations et équipements
    widgets.add(PageTracker(
      key: 'stat_inventaire',
      registry: trackedPages,
      offset: offset,
      child: _buildInventaireEquipementsSection(summary.equipmentInventory, 2),
    ));
    widgets.add(pw.SizedBox(height: 12));

    // 3. Répartition par criticité
    final ratioCritMinStr = mineure > 0 ? (critique / mineure).toStringAsFixed(1).replaceAll('.', ',') : '$critique';
    final pctCritMajStr = (pctCritique + pctMajeure).toStringAsFixed(1).replaceAll('.', ',');

    widgets.add(PageTracker(
      key: 'stat_criticite',
      registry: trackedPages,
      offset: offset,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _subTitle('3. Répartition par criticité'),
          pw.SizedBox(height: 5),
          _bodyText('Distribution des non-conformités selon les 3 niveaux de gravité réglementaires KES :'),
          pw.SizedBox(height: 8),
          _buildBarChart(critique, majeure, mineure),
          pw.SizedBox(height: 8),
          _buildCriticiteTable(critique, majeure, mineure, total, pctCritique, pctMajeure, pctMineure),
          pw.SizedBox(height: 8),
          _buildTextBulletPoint(
            '3.1 Ratio de sévérité',
            'Le rapport de $critique non-conformité(s) critique(s) pour $mineure non-conformité(s) mineure(s) (soit un ratio de $ratioCritMinStr) confirme la prédominance des défauts majeurs à haut risque.',
          ),
          _buildTextBulletPoint(
            '3.2 Niveau de risque dominant',
            'Les non-conformités de niveaux Critique et Majeur concentrent $pctCritMajStr % de l\'ensemble des écarts constatés sur l\'établissement.',
          ),
          _buildTextBulletPoint(
            '3.3 Signal de gravité global',
            'Cette distribution réclame une mobilisation prioritaire des ressources correctives sur les équipements à criticité élevée.',
          ),
        ],
      ),
    ));
    widgets.add(pw.SizedBox(height: 12));

    // 4. Non-conformités de l'année passée et taux de mise en conformité
    widgets.add(PageTracker(
      key: 'stat_annee_passee',
      registry: trackedPages,
      offset: offset,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _subTitle('4. Non-conformités de l\'année passée et taux de mise en conformité'),
          pw.SizedBox(height: 5),
          _bodyText(
            'Donnée non disponible — Le présent rapport porte sur la première visite de vérification périodique disposant d\'une check-list numérique structurée pour ce site (Rapport n° $numeroRapportDoc). Aucun rapport antérieur exploitable au même format n\'a été fourni pour extraire le nombre de non-conformités de l\'année passée. Si un rapport antérieur existe, merci de le transmettre : cette section et la comparaison ci-dessous seront complétées automatiquement.',
          ),
        ],
      ),
    ));
    widgets.add(pw.SizedBox(height: 12));

    // 5. Statistique par type de défaut — analyse de Pareto (sur les points de vérification)
    final totalOccur = summary.paretoResult.totalOccurrences > 0
        ? summary.paretoResult.totalOccurrences
        : summary.criticalityStats.total;
    final topItemsCount = summary.paretoResult.items.length;
    final topSumCount = summary.paretoResult.items.fold<int>(0, (sum, e) => sum + e.count);
    final topSumPct = totalOccur > 0 ? (topSumCount / totalOccur * 100) : 0.0;
    final pareto80K = summary.paretoResult.paretoCategoryCount;
    final pareto80Name = (pareto80K > 0 && pareto80K <= summary.paretoResult.items.length)
        ? summary.paretoResult.items[pareto80K - 1].title.trim().toLowerCase()
        : '';

    final paretoIntroSummary =
        'Les $totalOccur occurrences de non-conformités par nature de défaut ont été classées par fréquence décroissante. L\'analyse de Pareto ci-dessous met en évidence que les $topItemsCount catégories principales concentrent $topSumCount occurrences, soit ${topSumPct.toStringAsFixed(1).replaceAll('.', ',')} % du total, et que les $pareto80K premières catégories à elles seules atteignent le seuil de 80 % cumulé${pareto80Name.isNotEmpty ? " dès la ${pareto80K}e catégorie ($pareto80Name)" : ""}.';

    final topThreeVerificationPoints = summary.paretoResult.items
        .take(3)
        .map((e) => e.title.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toList();

    final dynamicCausesText = topThreeVerificationPoints.isNotEmpty
        ? topThreeVerificationPoints.join(', ')
        : 'protection contre les contacts indirects, câblage, identification des circuits';

    final pareto8020DynamicText =
        'Cette lecture confirme la règle courante des « 80/20 » : une action corrective concentrée sur un nombre restreint de causes racines ($dynamicCausesText) permettrait de traiter la grande majorité des écarts constatés, avec un effet de levier maximal sur la réduction du risque global.';

    widgets.add(PageTracker(
      key: 'stat_pareto',
      registry: trackedPages,
      offset: offset,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _subTitle('5. Statistique par type de défaut — analyse de Pareto'),
          pw.SizedBox(height: 5),
          _bodyText(paretoIntroSummary),
          pw.SizedBox(height: 8),
          _buildParetoChartWidget(summary.paretoResult),
          pw.SizedBox(height: 6),
          _bodyText(pareto8020DynamicText),
        ],
      ),
    ));
    widgets.add(pw.SizedBox(height: 12));

    // 6. Répartition par domaine de tension
    if (domainStats.totalCount > 0) {
      widgets.add(PageTracker(
        key: 'stat_tension',
        registry: trackedPages,
        offset: offset,
        child: _buildTensionDomainSection(domainStats, 6),
      ));
      widgets.add(pw.SizedBox(height: 12));
    }

    // 7. Non-conformités croisées par catégorie d'équipement — vue enrichie
    if (summary.crossCategoryItems.isNotEmpty) {
      widgets.add(PageTracker(
        key: 'stat_croisee',
        registry: trackedPages,
        offset: offset,
        child: _buildCrossCategorySection(summary.crossCategoryItems, summary.crossAnalysisText, 7),
      ));
      widgets.add(pw.SizedBox(height: 12));
    }

    // 8. Synthèse de l'analyse statistique
    final paretoK = summary.paretoResult.paretoCategoryCount;
    final paretoCumul = summary.paretoResult.paretoCumulativePercentage;

    widgets.add(PageTracker(
      key: 'stat_synthese',
      registry: trackedPages,
      offset: offset,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _subTitle('8. Synthèse de l\'analyse statistique'),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(3.2),
              1: pw.FlexColumnWidth(6.8),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: accentColor),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('DOMAINE D\'ANALYSE', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('SYNTHÈSE ET CONCLUSION', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white))),
                ],
              ),
              _buildIndicateurRow('Périmètre d\'équipement', '$totalEq installations et équipements répertoriés en $activeCats catégories métiers (MT et BT).'),
              _buildIndicateurRow('Niveau de gravité global', '$critique non-conformité(s) critique(s) (${pctCritique.toStringAsFixed(1).replaceAll('.', ',')} %) et $majeure majeure(s) (${pctMajeure.toStringAsFixed(1).replaceAll('.', ',')} %).'),
              _buildIndicateurRow('Concentration majeure', '${topTwo.label} concentrent ${topTwo.formattedValue}.'),
              _buildIndicateurRow('Levier d\'action Pareto', '$paretoK catégorie(s) d\'équipements concentrent ${paretoCumul.toStringAsFixed(1).replaceAll('.', ',')} % des écarts relevés.'),
            ],
          ),
        ],
      ),
    ));

    return widgets;
  }

  static _ParsedObservationRow _parseObservationRow(String rawText) {
    var trimmed = rawText.trim();
    trimmed = trimmed.replaceAll(RegExp(r'^[•\-\*]\s*'), '').replaceAll(RegExp(r'^\d+[\.\)]\s*'), '');
    if (trimmed.endsWith(';')) {
      trimmed = trimmed.substring(0, trimmed.length - 1).trim();
    }

    final regExp = RegExp(r'^(.*?)\s*\((.*?)\)\s*(?::\s*(.*))?$');
    final match = regExp.firstMatch(trimmed);

    if (match != null) {
      var obs = match.group(1)?.trim() ?? trimmed;
      obs = obs.replaceAll(RegExp(r'^Défauts?\s+prédominants?\s+liés?\s+[àa]\s*', caseSensitive: false), '').trim();
      final stats = match.group(2)?.trim() ?? '';
      var constat = match.group(3)?.trim() ?? '';
      if (constat.isEmpty) {
        constat = obs;
      }
      return _ParsedObservationRow(
        observation: obs,
        stats: stats,
        constatMajeur: constat,
      );
    }

    if (trimmed.contains(' : ')) {
      final parts = trimmed.split(' : ');
      var obs = parts[0].trim();
      obs = obs.replaceAll(RegExp(r'^Défauts?\s+prédominants?\s+liés?\s+[àa]\s*', caseSensitive: false), '').trim();
      return _ParsedObservationRow(
        observation: obs,
        stats: '',
        constatMajeur: parts.sublist(1).join(' : ').trim(),
      );
    }

    var obs = trimmed.replaceAll(RegExp(r'^Défauts?\s+prédominants?\s+liés?\s+[àa]\s*', caseSensitive: false), '').trim();
    return _ParsedObservationRow(
      observation: obs,
      stats: '',
      constatMajeur: obs,
    );
  }

  static String _cleanRecommendationText(String text) {
    var cleaned = text.trim();
    cleaned = cleaned.replaceAll(
      RegExp(r'^Priorit[eé]\s*\d+\s*[—\-:]?\s*(Action\s+Immédiate|Immédiat|Court\s+[Tt]erme|Moyen\s+[Tt]erme)?\s*:\s*', caseSensitive: false),
      '',
    ).trim();

    if (cleaned.isNotEmpty) {
      cleaned = '${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
    }
    return cleaned;
  }

  static List<pw.Widget> _buildHeaderWithTableList({
    required pw.Widget headerWidget,
    pw.Widget? introWidget,
    required pw.TableRow headerRow,
    required List<pw.TableRow> dataRows,
    required Map<int, pw.TableColumnWidth> columnWidths,
    pw.TableCellVerticalAlignment defaultVerticalAlignment = pw.TableCellVerticalAlignment.middle,
    pw.TableBorder? border,
    double minFreeSpace = 115,
  }) {
    if (dataRows.isEmpty) {
      return [
        pw.NewPage(freeSpace: minFreeSpace),
        headerWidget,
        if (introWidget != null) ...[pw.SizedBox(height: 4), introWidget],
      ];
    }

    final tableBorder = border ?? pw.TableBorder.all(color: borderColor, width: 0.5);

    final block1Children = <pw.Widget>[
      pw.NewPage(freeSpace: minFreeSpace),
      headerWidget,
      if (introWidget != null) ...[pw.SizedBox(height: 4), introWidget],
      pw.SizedBox(height: 4),
      pw.Table(
        defaultVerticalAlignment: defaultVerticalAlignment,
        border: tableBorder,
        columnWidths: columnWidths,
        children: [
          headerRow,
          dataRows.first,
        ],
      ),
    ];

    if (dataRows.length == 1) {
      return [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: block1Children,
        ),
      ];
    }

    final block2Table = pw.Table(
      defaultVerticalAlignment: defaultVerticalAlignment,
      border: tableBorder,
      columnWidths: columnWidths,
      children: dataRows.sublist(1),
    );

    return [
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: block1Children,
      ),
      block2Table,
    ];
  }

  static String _formatConcentrationTitle(String rawTitle) {
    final trimmed = rawTitle.trim();
    if (trimmed.isEmpty) return '3. Concentration du risque';
    if (RegExp(r'^3\.\s*').hasMatch(trimmed)) return trimmed;
    return '3. $trimmed';
  }

  static pw.Widget _buildMultiLineValueWidget(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return pw.SizedBox();

    List<String> items = [];
    if (trimmed.contains('\n')) {
      items = trimmed.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else {
      final parts = trimmed.split('. ');
      if (parts.length > 1) {
        for (var i = 0; i < parts.length; i++) {
          var part = parts[i].trim();
          if (part.isEmpty) continue;
          if (!part.endsWith('.')) part = '$part.';
          items.add(part);
        }
      } else {
        items = [trimmed];
      }
    }

    if (items.length <= 1) {
      return pw.Text(trimmed, style: pw.TextStyle(font: _fontRegular, fontSize: 8));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: items.map((item) {
        final isSubBullet = item.startsWith('*') || item.startsWith('  *');
        final cleanText = item.replaceAll(RegExp(r'^[•\-\*]\s*'), '').trim();
        final leftPadding = isSubBullet ? 12.0 : 0.0;
        final bulletChar = isSubBullet ? '* ' : '• ';
        final bulletColor = isSubBullet ? darkGrey : accentColor;

        return pw.Padding(
          padding: pw.EdgeInsets.only(top: 2, bottom: 2, left: leftPadding),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(bulletChar, style: pw.TextStyle(font: _fontBold, fontSize: 8, color: bulletColor)),
              pw.Expanded(
                child: pw.Text(
                  cleanText,
                  style: pw.TextStyle(font: _fontRegular, fontSize: 8, color: darkGrey),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.TableRow _buildIndicateurRow(String label, String value) {
    return pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(label, style: pw.TextStyle(font: _fontBold, fontSize: 8, color: headerColor)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: _buildMultiLineValueWidget(value),
        ),
      ],
    );
  }

  static pw.Widget _buildTextBulletPoint(String title, String description) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4, left: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$title : ',
              style: pw.TextStyle(font: _fontBold, fontSize: 8.5, color: headerColor),
            ),
            pw.TextSpan(
              text: description,
              style: pw.TextStyle(font: _fontRegular, fontSize: 8.5, color: PdfColors.black),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildBulletItem(String text, {String? boldPrefix}) {
    String prefix = boldPrefix ?? '';
    String body = text;

    if (boldPrefix == null && text.contains(' : ')) {
      final parts = text.split(' : ');
      prefix = '${parts[0]} : ';
      body = parts.sublist(1).join(' : ');
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4, left: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4, right: 6),
            width: 4,
            height: 4,
            decoration: pw.BoxDecoration(
              color: accentColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: prefix.isNotEmpty
                ? pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(text: prefix, style: pw.TextStyle(font: _fontBold, fontSize: 8.5, color: darkGrey)),
                        pw.TextSpan(text: body, style: pw.TextStyle(font: _fontRegular, fontSize: 8.5, color: darkGrey)),
                      ],
                    ),
                  )
                : pw.Text(text, style: pw.TextStyle(font: _fontRegular, fontSize: 8.5, color: darkGrey)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCategoryParetoChartWidget(CategoryParetoResult pareto) {
    if (pareto.items.isEmpty) {
      return _bodyText('Aucune non-conformité recensée pour l\'analyse de Pareto par catégorie.');
    }

    final maxVal = pareto.items.map((e) => e.nonConformitiesCount).fold(1, (a, b) => a > b ? a : b);

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              'Analyse de Pareto par catégorie d\'équipement (Occurrences & % Cumulé 80%)',
              style: pw.TextStyle(font: _fontBold, fontSize: 9, color: accentColor),
            ),
          ),
          pw.SizedBox(height: 6),
          // ── Diagramme Visuel Pareto (Barres Horizontales) ──
          pw.Column(
            children: pareto.items.map((item) {
              final isPareto = item.cumulativePercentage <= pareto.paretoCumulativePercentage ||
                  pareto.items.indexOf(item) < pareto.paretoCategoryCount;
              final barColor = isPareto ? PdfColor.fromHex('#B71C1C') : accentColor;
              final barWidthPct = maxVal > 0 ? (item.nonConformitiesCount / maxVal) : 0.0;

              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 140,
                      child: pw.Text(
                        item.categoryName,
                        style: pw.TextStyle(font: isPareto ? _fontBold : _fontRegular, fontSize: 6.5, color: PdfColors.grey900),
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      child: pw.Container(
                        height: 7,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                        ),
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Container(
                          width: (barWidthPct * 260).clamp(2.0, 260.0),
                          height: 7,
                          decoration: pw.BoxDecoration(
                            color: barColor,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.SizedBox(
                      width: 65,
                      child: pw.Text(
                        '${item.nonConformitiesCount} NC (${item.percentage.toStringAsFixed(1).replaceAll('.', ',')} %)',
                        style: pw.TextStyle(font: _fontBold, fontSize: 6.5, color: barColor),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(3.2),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1.4),
              3: pw.FlexColumnWidth(1.2),
              4: pw.FlexColumnWidth(1.4),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: accentColor),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('CATÉGORIE', style: pw.TextStyle(font: _fontBold, fontSize: 7.5, color: PdfColors.white))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ÉQUIP.', style: pw.TextStyle(font: _fontBold, fontSize: 7, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('NON-CONF.', style: pw.TextStyle(font: _fontBold, fontSize: 7, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('PART (%)', style: pw.TextStyle(font: _fontBold, fontSize: 7, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('% CUMULÉ', style: pw.TextStyle(font: _fontBold, fontSize: 7, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                ],
              ),
              ...pareto.items.map((item) {
                final isPareto = item.cumulativePercentage <= pareto.paretoCumulativePercentage ||
                    pareto.items.indexOf(item) < pareto.paretoCategoryCount;
                final textStyle = isPareto
                    ? pw.TextStyle(font: _fontBold, fontSize: 7, color: PdfColor.fromHex('#B71C1C'))
                    : pw.TextStyle(font: _fontRegular, fontSize: 7, color: PdfColors.grey800);

                return pw.TableRow(
                  decoration: isPareto ? pw.BoxDecoration(color: PdfColor.fromHex('#FEF2F2')) : null,
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.categoryName, style: textStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${item.equipmentCount}', style: textStyle, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${item.nonConformitiesCount}', style: textStyle, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${item.percentage.toStringAsFixed(1).replaceAll('.', ',')} %', style: textStyle, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${item.cumulativePercentage.toStringAsFixed(1).replaceAll('.', ',')} %', style: textStyle, textAlign: pw.TextAlign.center)),
                  ],
                );
              }).toList(),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total non-conformités analysées : ${pareto.totalNonConformities}',
                style: pw.TextStyle(font: _fontRegular, fontSize: 7.5, color: PdfColors.grey700),
              ),
              pw.Text(
                'Seuil Pareto (80 %) atteint sur les ${pareto.paretoCategoryCount} première(s) catégorie(s)',
                style: pw.TextStyle(font: _fontBold, fontSize: 7.5, color: PdfColor.fromHex('#B71C1C')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildParetoChartWidget(ParetoAnalysisResult pareto) {
    if (pareto.items.isEmpty) return pw.SizedBox();

    final maxVal = pareto.items.map((e) => e.count).fold(1, (a, b) => a > b ? a : b);
    final yMaxLeft = ((maxVal * 1.15) / 5).ceil() * 5 > 0
        ? ((maxVal * 1.15) / 5).ceil() * 5
        : 5;

    const chartHeight = 110.0;
    final itemsCount = pareto.items.length;
    final colorRed = PdfColor.fromHex('#B71C1C');

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              'Analyse de Pareto — $itemsCount principales catégories de défauts (sur ${pareto.totalOccurrences} occurrences)',
              style: pw.TextStyle(
                font: _fontBold,
                fontSize: 9,
                color: accentColor,
              ),
            ),
          ),
          pw.SizedBox(height: 8),

          // Zone du graphique avec axes Y gauche & droit
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Axe Y gauche (Nombre d'occurrences)
              pw.Container(
                height: chartHeight + 25,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('$yMaxLeft', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5, color: PdfColors.grey700)),
                    pw.Text('${(yMaxLeft * 0.75).round()}', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5, color: PdfColors.grey700)),
                    pw.Text('${(yMaxLeft * 0.5).round()}', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5, color: PdfColors.grey700)),
                    pw.Text('${(yMaxLeft * 0.25).round()}', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5, color: PdfColors.grey700)),
                    pw.Text('0', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5, color: PdfColors.grey700)),
                    pw.SizedBox(height: 18),
                  ],
                ),
              ),
              pw.SizedBox(width: 4),

              // Zone Principale du Graphique (Barres + Courbe Cumulée + Ligne 80%)
              pw.Expanded(
                child: pw.LayoutBuilder(
                  builder: (ctx, constraints) {
                    final width = constraints?.maxWidth ?? 400.0;
                    final colWidth = width / itemsCount;

                    return pw.Column(
                      children: [
                        pw.Container(
                          height: chartHeight,
                          width: width,
                          child: pw.Stack(
                            children: [
                              // 1. Fond du graphique (Bordures)
                              pw.Container(
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(
                                    left: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                                    right: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                                    bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                                  ),
                                ),
                              ),

                              // 2. Barres Verticales avec leur valeur au-dessus
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: pareto.items.map((item) {
                                  final barH = yMaxLeft > 0 ? (item.count / yMaxLeft) * (chartHeight - 15) : 0.0;

                                  return pw.Column(
                                    mainAxisAlignment: pw.MainAxisAlignment.end,
                                    children: [
                                      pw.Text(
                                        '${item.count}',
                                        style: pw.TextStyle(font: _fontBold, fontSize: 7, color: PdfColors.grey900),
                                      ),
                                      pw.SizedBox(height: 2),
                                      pw.Container(
                                        width: (colWidth * 0.55).clamp(12.0, 24.0),
                                        height: barH < 2 ? 2 : barH,
                                        decoration: pw.BoxDecoration(
                                          color: accentColor,
                                          borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(2)),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),

                              // 3. CustomPaint pour la Ligne Pointillée 80% et la Courbe Rouge % Cumulé
                              pw.CustomPaint(
                                size: PdfPoint(width, chartHeight),
                                painter: (PdfGraphics canvas, PdfPoint size) {
                                  final h = size.y;
                                  final w = size.x;

                                  // Ligne pointillée 80 %
                                  final y80 = h * 0.8;
                                  canvas.setStrokeColor(colorRed);
                                  canvas.setLineWidth(0.8);
                                  canvas.setLineDashPattern([3, 3]);
                                  canvas.drawLine(0, y80, w, y80);
                                  canvas.strokePath();

                                  // Courbe du % cumulé (Ligne continue rouge avec points)
                                  canvas.setLineDashPattern([]);
                                  canvas.setLineWidth(1.2);

                                  final points = <PdfPoint>[];
                                  for (int i = 0; i < itemsCount; i++) {
                                    final item = pareto.items[i];
                                    final cx = (i + 0.5) * (w / itemsCount);
                                    final cy = (item.cumulativePercentage / 100.0) * h;
                                    points.add(PdfPoint(cx, cy));
                                  }

                                  // Tracer les segments de la courbe
                                  if (points.isNotEmpty) {
                                    canvas.setStrokeColor(colorRed);
                                    for (int i = 0; i < points.length - 1; i++) {
                                      canvas.drawLine(points[i].x, points[i].y, points[i + 1].x, points[i + 1].y);
                                    }
                                    canvas.strokePath();

                                    // Tracer les points (cercles rouges)
                                    canvas.setFillColor(colorRed);
                                    for (final p in points) {
                                      canvas.drawEllipse(p.x, p.y, 2.0, 2.0);
                                      canvas.fillPath();
                                    }
                                  }
                                },
                              ),

                              // Label 80% sur la ligne pointillée
                              pw.Positioned(
                                right: 4,
                                top: chartHeight * 0.2 - 9,
                                child: pw.Text(
                                  '80 %',
                                  style: pw.TextStyle(font: _fontBold, fontSize: 7, color: colorRed),
                                ),
                              ),
                            ],
                          ),
                        ),

                        pw.SizedBox(height: 4),

                        // Libellés sous chaque barre (Axe X)
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: pareto.items.map((item) {
                            return pw.SizedBox(
                              width: colWidth,
                              child: pw.Text(
                                _shortVerificationPointName(item.title),
                                style: pw.TextStyle(font: _fontRegular, fontSize: 5.8, color: PdfColors.grey800),
                                textAlign: pw.TextAlign.center,
                                maxLines: 2,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ),

              pw.SizedBox(width: 4),

              // Axe Y droit (% cumulé)
              pw.Container(
                height: chartHeight + 25,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('100', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5, color: PdfColors.grey700)),
                    pw.Text('80', style: pw.TextStyle(font: _fontBold, fontSize: 6.5, color: colorRed)),
                    pw.Text('60', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5, color: PdfColors.grey700)),
                    pw.Text('40', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5, color: PdfColors.grey700)),
                    pw.Text('20', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5, color: PdfColors.grey700)),
                    pw.Text('0', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5, color: PdfColors.grey700)),
                    pw.SizedBox(height: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  GRAPHIQUES ET ANALYSES STATISTIQUES AVANCÉES
  // ──────────────────────────────────────────────────────────────

  static pw.Widget _buildInventaireEquipementsSection(List<EquipmentInventoryItem> items, [int? index]) {
    final totalEquipementsBT = items
        .where((e) => e.label == 'TGBT' || e.label == 'Armoires' || e.label == 'Coffrets')
        .fold(0, (sum, e) => sum + e.count);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _subTitle('${index != null ? "$index. " : ""}Inventaire chiffr\u00e9 des installations et \u00e9quipements'),
        pw.SizedBox(height: 5),
        _bodyText(
          'Les effectifs ci-dessous sont \u00e9tablis \u00e0 partir du d\u00e9tail point par point du chapitre \u00ab Audit des installations \u00e9lectriques \u00bb (comptage des fiches de v\u00e9rification effectivement renseign\u00e9es pour chaque \u00e9quipement).',
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: borderColor, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(3.5),
            1: pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: accentColor),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('\u00c9L\u00c9MENT', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('NOMBRE', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white), textAlign: pw.TextAlign.center),
                ),
              ],
            ),
            ...items.map((item) {
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(item.label, style: pw.TextStyle(font: _fontRegular, fontSize: 8)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('${item.count}', style: pw.TextStyle(font: _fontRegular, fontSize: 8), textAlign: pw.TextAlign.center),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
        pw.SizedBox(height: 10),
        _buildBulletItem('Nombre de nouveaux coffret / armoire / TGBT : Donnée non disponible. Le nombre d\'équipements nouvellement installés depuis la dernière visite ne peut être établi qu\'en comparant l\'inventaire de la présente visite ($totalEquipementsBT équipements BT) à l\'inventaire du rapport précédent.'),
        pw.SizedBox(height: 4),
        _buildBulletItem('Nombre de coffret / armoire / TGBT supprimé : Donnée non disponible. Le nombre d\'équipements retirés de l\'installation depuis la dernière visite nécessite une comparaison avec l\'inventaire du rapport précédent, non disponible à ce jour.'),
        pw.SizedBox(height: 4),
        _buildBulletItem('Pour compléter entièrement cette analyse : Merci de transmettre le rapport de vérification périodique de l\'année précédente pour ce site (ou son export de check-list). Dès réception, les sections « Non-conformités de l\'année passée », « Comparaison », « Taux de mise en conformité », « Nouveaux équipements » et « Équipements supprimés » seront calculées et complétées.'),
      ],
    );
  }

  static pw.Widget _buildTopDefectsHorizontalChart(List<TopDefectItem> topItems) {
    if (topItems.isEmpty) return pw.SizedBox();

    final maxVal = topItems.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final xMax = ((maxVal * 1.2) / 10).ceil() * 10 > 0
        ? ((maxVal * 1.2) / 10).ceil() * 10
        : 10;
    final xMid = (xMax / 2).round();

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              'Statistique par type de d\u00e9faut (10 principales cat\u00e9gories)',
              style: pw.TextStyle(
                font: _fontBold,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: headerColor,
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Column(
            children: topItems.map((item) {
              final barWidthPct = xMax > 0 ? (item.count / xMax) : 0.0;
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 170,
                      child: pw.Text(
                        item.title,
                        style: pw.TextStyle(font: _fontRegular, fontSize: 7.5, color: PdfColors.grey900),
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Container(
                        height: 10,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                        ),
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Container(
                          width: (barWidthPct * 260).clamp(2.0, 260.0),
                          height: 10,
                          decoration: pw.BoxDecoration(
                            color: headerColor,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.SizedBox(
                      width: 25,
                      child: pw.Text(
                        '${item.count}',
                        style: pw.TextStyle(font: _fontBold, fontSize: 8, color: headerColor, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          pw.SizedBox(height: 6),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 178, right: 30),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('0', style: pw.TextStyle(font: _fontRegular, fontSize: 7, color: PdfColors.grey600)),
                pw.Text('$xMid', style: pw.TextStyle(font: _fontRegular, fontSize: 7, color: PdfColors.grey600)),
                pw.Text('$xMax', style: pw.TextStyle(font: _fontRegular, fontSize: 7, color: PdfColors.grey600)),
              ],
            ),
          ),
          pw.Center(
            child: pw.Text(
              'Nombre d\'occurrences',
              style: pw.TextStyle(font: _fontRegular, fontSize: 7.5, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTensionDomainSection(TensionDomainStats stats, [int? index]) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _subTitle('${index != null ? "$index. " : ""}R\u00e9partition des non-conformit\u00e9s par domaine de tension'),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 130,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            color: PdfColors.white,
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'Répartition des non-conformités par domaine de tension',
                style: pw.TextStyle(font: _fontBold, fontSize: 9, color: accentColor),
              ),
              pw.SizedBox(height: 6),
              pw.Expanded(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('${stats.mtCount}', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: accentColor)),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: 45,
                          height: stats.totalCount > 0 ? (stats.mtCount / stats.totalCount) * 45 + 4 : 4,
                          decoration: pw.BoxDecoration(
                            color: accentColor,
                            borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(3)),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Moyenne Tension\n(MT/HTA)', style: pw.TextStyle(font: _fontRegular, fontSize: 7, color: PdfColors.grey800), textAlign: pw.TextAlign.center),
                      ],
                    ),
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('${stats.btCount}', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: accentColor)),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: 45,
                          height: stats.totalCount > 0 ? (stats.btCount / stats.totalCount) * 45 + 4 : 4,
                          decoration: pw.BoxDecoration(
                            color: accentColor,
                            borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(3)),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Basse Tension\n(BT)', style: pw.TextStyle(font: _fontRegular, fontSize: 7, color: PdfColors.grey800), textAlign: pw.TextAlign.center),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: borderColor, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: accentColor),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('DOMAINE', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('NON-CONFORMITÉS', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('PART DU TOTAL', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white), textAlign: pw.TextAlign.center)),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Moyenne tension (MT/HTA) — poste de livraison, cellules, transformateur', style: pw.TextStyle(font: _fontRegular, fontSize: 7.5))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${stats.mtCount}', style: pw.TextStyle(font: _fontRegular, fontSize: 7.5), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${stats.mtPct.toStringAsFixed(1).replaceAll('.', ',')} %', style: pw.TextStyle(font: _fontRegular, fontSize: 7.5), textAlign: pw.TextAlign.center)),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Basse tension (BT) — groupe électrogène, inverseur, TGBT, armoires, coffrets', style: pw.TextStyle(font: _fontRegular, fontSize: 7.5))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${stats.btCount}', style: pw.TextStyle(font: _fontRegular, fontSize: 7.5), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${stats.btPct.toStringAsFixed(1).replaceAll('.', ',')} %', style: pw.TextStyle(font: _fontRegular, fontSize: 7.5), textAlign: pw.TextAlign.center)),
              ],
            ),
            pw.TableRow(
              decoration: pw.BoxDecoration(color: lightBlue),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('TOTAL', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: accentColor))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${stats.totalCount}', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: accentColor), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('100 %', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: accentColor), textAlign: pw.TextAlign.center)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        _bodyText(
          'L\'analyse par domaine de tension permet d\'isoler les risques spécifiques aux installations Moyenne Tension (MT/HTA) et Basse Tension (BT). Le domaine Basse Tension regroupe généralement la majorité des équipements de distribution finale (armoires, coffrets, TGBT), tandis que la Moyenne Tension concentre les équipements d\'alimentation principale à forts enjeux de sécurité électrique.',
        ),
      ],
    );
  }

  static pw.Widget _buildCrossCategorySection(List<CategoryCrossItem> items, String crossText, [int? index]) {
    if (items.isEmpty) return pw.SizedBox();

    final totalNC = items.fold<int>(0, (sum, e) => sum + e.nonConformitiesCount);
    final totalCritique = items.fold<int>(0, (sum, e) => sum + e.critiqueCount);
    final totalMajeure = items.fold<int>(0, (sum, e) => sum + e.majeureCount);
    final totalMineure = items.fold<int>(0, (sum, e) => sum + e.mineureCount);
    final totalEquipements = items.fold<int>(0, (sum, e) => sum + e.equipmentCount);
    final maxVal = items.map((e) => e.nonConformitiesCount).fold(1, (a, b) => a > b ? a : b);

    final colorCritique = PdfColor.fromHex('#DC2626');
    final colorMajeure = PdfColor.fromHex('#EA580C');
    final colorMineure = PdfColor.fromHex('#16A34A');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _subTitle('${index != null ? "$index. " : ""}Non-conformit\u00e9s crois\u00e9es par cat\u00e9gorie d\'installation / d\'\u00e9quipement'),
        pw.SizedBox(height: 5),
        _bodyText('En crois\u00e0nt chaque cat\u00e9gorie ci-dessus avec les non-conformit\u00e9s relev\u00e9es, la r\u00e9partition et la densit\u00e9 moyenne par \u00e9quipement se pr\u00e9sentent comme suit :'),
        pw.SizedBox(height: 8),
        pw.Container(
          height: 135,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderColor, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            color: PdfColors.white,
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Non-conformit\u00e9s par cat\u00e9gorie d\'installation / d\'\u00e9quipement',
                    style: pw.TextStyle(font: _fontBold, fontSize: 9, color: accentColor),
                  ),
                  pw.Row(
                    children: [
                      pw.Container(width: 8, height: 8, color: colorCritique),
                      pw.SizedBox(width: 3),
                      pw.Text('Critique', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5)),
                      pw.SizedBox(width: 6),
                      pw.Container(width: 8, height: 8, color: colorMajeure),
                      pw.SizedBox(width: 3),
                      pw.Text('Majeure', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5)),
                      pw.SizedBox(width: 6),
                      pw.Container(width: 8, height: 8, color: colorMineure),
                      pw.SizedBox(width: 3),
                      pw.Text('Mineure', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                height: 100,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: items.map((item) {
                    final hCrit = maxVal > 0 ? (item.critiqueCount / maxVal) * 70 : 0.0;
                    final hMaj = maxVal > 0 ? (item.majeureCount / maxVal) * 70 : 0.0;
                    final hMin = maxVal > 0 ? (item.mineureCount / maxVal) * 70 : 0.0;

                    return pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('${item.nonConformitiesCount}', style: pw.TextStyle(font: _fontBold, fontSize: 7, color: accentColor)),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: 22,
                          child: pw.Column(
                            children: [
                              if (hCrit > 0) pw.Container(height: hCrit < 2 ? 2 : hCrit, color: colorCritique),
                              if (hMaj > 0) pw.Container(height: hMaj < 2 ? 2 : hMaj, color: colorMajeure),
                              if (hMin > 0) pw.Container(height: hMin < 2 ? 2 : hMin, color: colorMineure),
                              if (item.nonConformitiesCount == 0) pw.Container(height: 2, color: PdfColors.grey300),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.SizedBox(
                          width: 42,
                          child: pw.Text(
                            _shortCatName(item.categoryName),
                            style: pw.TextStyle(font: _fontRegular, fontSize: 6, color: PdfColors.grey800),
                            textAlign: pw.TextAlign.center,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: borderColor, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.6),
            1: pw.FlexColumnWidth(0.8),
            2: pw.FlexColumnWidth(0.8),
            3: pw.FlexColumnWidth(0.8),
            4: pw.FlexColumnWidth(0.8),
            5: pw.FlexColumnWidth(0.8),
            6: pw.FlexColumnWidth(1.2),
            7: pw.FlexColumnWidth(1.3),
            8: pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: accentColor),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4), child: pw.Text('Catégorie', style: pw.TextStyle(font: _fontBold, fontSize: 7, color: PdfColors.white))),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text('Équip.', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text('NC', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text('Crit.', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text('Maj.', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text('Min.', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text('% du total NC', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text('Taux crit. / NC', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text('Densité NC/équip.', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: PdfColors.white), textAlign: pw.TextAlign.center)),
              ],
            ),
            for (int i = 0; i < items.length; i++) ...[
              () {
                final item = items[i];
                final pctTotalNC = totalNC > 0 ? (item.nonConformitiesCount / totalNC * 100) : 0.0;
                final tauxCrit = item.nonConformitiesCount > 0 ? (item.critiqueCount / item.nonConformitiesCount * 100) : 0.0;
                final densite = item.equipmentCount > 0 ? (item.nonConformitiesCount / item.equipmentCount) : 0.0;

                final isCritiqueHighlight = item.critiqueCount > 0;
                final critStyle = isCritiqueHighlight
                    ? pw.TextStyle(font: _fontBold, fontSize: 6.5, color: PdfColor.fromHex('#B71C1C'))
                    : pw.TextStyle(font: _fontRegular, fontSize: 6.5, color: PdfColors.grey700);

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: i % 2 == 1 ? tableRowAlt : PdfColors.white),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3), child: pw.Text(item.categoryName, style: pw.TextStyle(font: _fontBold, fontSize: 6.5, color: PdfColors.black))),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3), child: pw.Text('${item.equipmentCount}', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3), child: pw.Text('${item.nonConformitiesCount}', style: pw.TextStyle(font: _fontBold, fontSize: 6.5), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3), child: pw.Text('${item.critiqueCount}', style: critStyle, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3), child: pw.Text('${item.majeureCount}', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3), child: pw.Text('${item.mineureCount}', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3), child: pw.Text('${pctTotalNC.toStringAsFixed(1).replaceAll('.', ',')} %', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3), child: pw.Text(item.nonConformitiesCount > 0 ? '${tauxCrit.toStringAsFixed(1).replaceAll('.', ',')} %' : '\u2014', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3), child: pw.Text(item.equipmentCount > 0 ? densite.toStringAsFixed(1).replaceAll('.', ',') : '0,0', style: pw.TextStyle(font: _fontRegular, fontSize: 6.5), textAlign: pw.TextAlign.center)),
                  ],
                );
              }(),
            ],
            pw.TableRow(
              decoration: pw.BoxDecoration(color: lightBlue),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4), child: pw.Text('TOTAL', style: pw.TextStyle(font: _fontBold, fontSize: 7, color: accentColor))),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text('$totalEquipements', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: accentColor), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text('$totalNC', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: accentColor), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text('$totalCritique', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: PdfColor.fromHex('#B71C1C')), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text('$totalMajeure', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: accentColor), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text('$totalMineure', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: accentColor), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text('100 %', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: accentColor), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text(totalNC > 0 ? '${(totalCritique / totalNC * 100).toStringAsFixed(1).replaceAll('.', ',')} %' : '\u2014', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: accentColor), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: pw.Text(totalEquipements > 0 ? (totalNC / totalEquipements).toStringAsFixed(1).replaceAll('.', ',') : '0,0', style: pw.TextStyle(font: _fontBold, fontSize: 6.8, color: accentColor), textAlign: pw.TextAlign.center)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        _bodyText('Lecture crois\u00e9e : $crossText'),
      ],
    );
  }

  static String _shortCatName(String cat) {
    if (cat.contains('Moyenne Tension')) return 'Local MT';
    if (cat.contains('Cellules')) return 'Cellule MT';
    if (cat.contains('Transformateurs')) return 'Transfo MT/BT';
    if (cat.contains('Groupe')) return 'Local GE';
    if (cat.contains('Basse Tension')) return 'Local BT';
    if (cat.contains('TGBT')) return 'TGBT';
    if (cat.contains('Armoires')) return 'Armoire';
    if (cat.contains('Coffrets')) return 'Coffret';
    if (cat.contains('Inverseurs')) return 'Inverseur';
    return cat;
  }

  static String _shortVerificationPointName(String title) {
    final s = title.trim();
    final lower = s.toLowerCase();
    if (lower.contains('contacts indirects')) return 'Protection contacts\nindirects';
    if (lower.contains('câblage') || lower.contains('cablage')) return 'Câblage';
    if (lower.contains('identification')) return 'Identification\ncircuits';
    if (lower.contains('dispositif') || lower.contains('protection')) return 'Dispositifs de\nprotection';
    if (lower.contains('répartiteur') || lower.contains('repartiteur')) return 'Répartiteur de\ncircuit';
    if (lower.contains('continuité') || lower.contains('pe')) return 'Continuité PE';
    if (lower.contains('répartition') || lower.contains('repartition')) return 'Répartition des\ncircuits';
    if (lower.contains('emplacement') || lower.contains('dégagement')) return 'Emplacement /\ndégagement';
    if (lower.contains('code couleur') || lower.contains('couleur')) return 'Code couleur\ncâbles';
    if (lower.contains('état') || lower.contains('armoire') || lower.contains('coffret')) return 'État coffret /\narmoire / TGBT';

    if (s.length > 20) {
      final parts = s.split(' ');
      if (parts.length > 2) {
        final mid = parts.length ~/ 2;
        return '${parts.sublist(0, mid).join(" ")}\n${parts.sublist(mid).join(" ")}';
      }
    }
    return s;
  }

  // ──────────────────────────────────────────────────────────────
  //  RENSEIGNEMENTS GENERAUX
  // ──────────────────────────────────────────────────────────────
  
  static pw.Widget _buildRenseignementsGeneraux(
    Mission mission,
    RenseignementsGeneraux? rg,
    Map<String, int> trackedPages, {
    int offset = 0,
  }) {
    final verificateursNoms = rg != null && rg.verificateurs.isNotEmpty
        ? rg.verificateurs
            .map((v) => '${v['prenom'] ?? ''} ${v['nom'] ?? ''}'.trim())
            .where((s) => s.isNotEmpty)
            .join(', ')
        : (mission.verificateurs != null
            ? mission.verificateurs!
                .map((v) => '${v['prenom'] ?? ''} ${v['nom'] ?? ''}'.trim())
                .where((s) => s.isNotEmpty)
                .join(', ')
            : '');

    final dateDebut = rg?.dateDebut ?? mission.dateIntervention;
    final dateFin = rg?.dateFin;

    String dateIntervTxt;

    if (dateDebut != null &&
        dateFin != null &&
        !dateDebut.isAtSameMomentAs(dateFin)) {
      dateIntervTxt =
          'Du ${_formatDate(dateDebut)} au ${_formatDate(dateFin)}';
    } else if (dateDebut != null) {
      dateIntervTxt = _formatDate(dateDebut);
    } else {
      dateIntervTxt = '';
    }

    // Construire la liste des lignes du tableau
    final rows = <pw.TableRow>[
      _tableHeaderRow(['LISTE DES DOCUMENTS', 'OBSERVATIONS']),
    ];

    // Documents standards
    final docsStandards = [
      {
        'label':
            'Cahier des prescriptions techniques ayant permis la réalisation des installations',
        'value': mission.docCahierPrescriptions,
      },
      {
        'label':
            'Notes de calculs justifiant le dimensionnement des canalisations électriques et des dispositifs de protection',
        'value': mission.docNotesCalculs,
      },
      {
        'label': 'Schémas unifilaires des installations électriques',
        'value': mission.docSchemasUnifilaires,
      },
      {
        'label':
            'Plan de masse à l\'échelle des installations avec implantations des prises de terre et électriques enterrés',
        'value': mission.docPlanMasse,
      },
      {
        'label':
            'Plans architecturaux d\'implantation des différents circuits',
        'value': mission.docPlansArchitecturaux,
      },
      {
        'label':
            'Déclaration CE de conformité et notices des appareillages et câbles installés',
        'value': mission.docDeclarationsCe,
      },
      {
        'label':
            'Liste des installations de sécurité et effectif maximal des différents locaux ou bâtiments',
        'value': mission.docListeInstallations,
      },
      {
        'label': 'Rapport de dernière vérification',
        'value': mission.docRapportDerniereVerif,
      },
      {
        'label':
            'Plan des locaux, avec indications des locaux à risques particuliers d\'influences externes',
        'value': mission.docPlanLocauxRisques,
      },
      {
        'label': 'Rapport d\'analyse risque foudre',
        'value': mission.docRapportAnalyseFoudre,
      },
      {
        'label': 'Rapport d\'étude technique foudre',
        'value': mission.docRapportEtudeFoudre,
      },
      {
        'label': 'Registre de sécurité',
        'value': mission.docRegistreSecurite,
      },
    ];

    for (var doc in docsStandards) {
      rows.add(
        _tableDataRow(
          [
            doc['label'] as String,
            _docStatus(doc['value'] as bool),
          ],
          alt: rows.length.isOdd,
        ),
      );
    }

    // Documents personnalisés
    final autresDocs = mission.autresDocuments;

    for (var doc in autresDocs) {
      rows.add(
        _tableDataRow(
          [doc, 'Présent'],
          alt: rows.length.isOdd,
        ),
      );
    }

    // Option "Autre"
    if (mission.docAutre &&
        !autresDocs.contains('Autre document pertinent')) {
      rows.add(
        _tableDataRow(
          ['Autre document pertinent', 'Présent'],
          alt: rows.length.isOdd,
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeaderWidget(nomClient: mission.nomClient),

        pw.SizedBox(height: 10),

        PageTracker(
          key: 'renseignements',
          registry: trackedPages,
          offset: offset,
          child: _sectionBox('RENSEIGNEMENTS G\u00c9N\u00c9RAUX DE L\'\u00c9TABLISSEMENT'),
        ),

        pw.SizedBox(height: 8),

        PageTracker(
          key: 'renseignements_principaux',
          registry: trackedPages,
          offset: offset,
          child: _subTitle('1. Renseignements principaux'),
        ),

        pw.SizedBox(height: 5),

        pw.Table(
          border: pw.TableBorder.all(
            color: borderColor,
            width: 0.4,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
          },
          children: [
            _tableDataRow(
              ['Etablissement vérifié', mission.nomClient],
              alt: false,
            ),
            _tableDataRow(
              [
                'Installation vérifié',
                rg?.installation.isNotEmpty == true
                    ? rg!.installation
                    : (mission.installation ?? 'Toutes les installations électriques'),
              ],
              alt: true,
            ),
            _tableDataRow(
              [
                'Activité principale',
                rg?.activite.isNotEmpty == true
                    ? rg!.activite
                    : (mission.activiteClient ?? '—'),
              ],
              alt: false,
            ),
            _tableDataRow(
              ['Adresse', mission.adresseClient ?? '—'],
              alt: true,
            ),
            _tableDataRow(
              [
                'Nom du site',
                rg?.nomSite.isNotEmpty == true
                    ? rg!.nomSite
                    : (mission.nomSite ?? '—'),
              ],
              alt: false,
            ),
            _tableDataRow(
              [
                'Activité sur le site',
                (rg?.activiteSurSite?.isNotEmpty == true)
                    ? rg!.activiteSurSite!
                    : (mission.activiteSurSite ?? '—'),
              ],
              alt: true,
            ),
            _tableDataRow(
              [
                'Registre de contrôle',
                rg?.registreControle.isNotEmpty == true
                    ? rg!.registreControle
                    : 'Non présenté',
              ],
              alt: false,
            ),
            _tableDataRow(
              ['Classement règlementaire', ''],
              alt: true,
            ),
            _tableDataRow(
              [
                '                                     Type',
                (rg?.classementReglementaireType?.isNotEmpty == true)
                    ? rg!.classementReglementaireType!
                    : (mission.classementReglementaireType ?? '—'),
              ],
              alt: false,
            ),
            _tableDataRow(
              [
                '                                     Catégorie',
                (rg?.classementReglementaireCategorie?.isNotEmpty == true)
                    ? rg!.classementReglementaireCategorie!
                    : (mission.classementReglementaireCategorie ?? '—'),
              ],
              alt: true,
            ),
          ],
        ),

  pw.SizedBox(height: 16),

  PageTracker(
    key: 'renseignements_documents',
    registry: trackedPages,
    offset: offset,
    child: _subTitle('2. Documents nécessaires à la vérification'),
  ),

  pw.SizedBox(height: 5),

  pw.Table(
    border: pw.TableBorder.all(color: borderColor, width: 0.4),
    columnWidths: {
      0: const pw.FlexColumnWidth(4),
      1: const pw.FlexColumnWidth(2),
    },
    children: [
      _tableHeaderRow(['LISTE DES DOCUMENTS', 'OBSERVATIONS']),
      ...docsStandards.asMap().entries.map((e) {
        final doc = docsStandards[e.key];
        final label = doc['label'] as String;
        final isPresent = doc['value'] as bool;
        final observation = _docStatus(isPresent);
        final isNonPresente = observation == 'Non presente';
        return pw.TableRow(
          decoration: e.key.isOdd ? pw.BoxDecoration(color: tableRowAlt) : null,
          children: [
            _cell(label, isHeader: false),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: pw.Text(
                observation,
                style: pw.TextStyle(
                  font: _fontRegular,
                  fontSize: fsSmall,
                  color: isNonPresente ? PdfColors.red : darkGrey,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        );
      }),
      ...autresDocs.asMap().entries.map((e) {
        final doc = autresDocs[e.key];
        final rowIndex = docsStandards.length + e.key;
        return pw.TableRow(
          decoration: rowIndex.isOdd ? pw.BoxDecoration(color: tableRowAlt) : null,
          children: [
            _cell(doc, isHeader: false),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: pw.Text(
                'Présent',
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall, color: darkGrey),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        );
      }),
      if (mission.docAutre && !autresDocs.contains('Autre document pertinent'))
        pw.TableRow(
          decoration: (docsStandards.length + autresDocs.length).isOdd ? pw.BoxDecoration(color: tableRowAlt) : null,
          children: [
            _cell('Autre document pertinent', isHeader: false),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: pw.Text(
                'Présent',
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall, color: darkGrey),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
    ],
  ),
  pw.SizedBox(height: 16),
  PageTracker(
    key: 'renseignements_habilitation',
    registry: trackedPages,
    offset: offset,
    child: _subTitle('3. Habilitation électrique du personnel d\'intervention'),
  ),
  pw.SizedBox(height: 6),
  () {
    final habVal = rg?.habilitationElectriqueEffective ?? 'Inconnu';
    PdfColor habColor;
    if (habVal == 'Oui') {
      habColor = PdfColor.fromInt(0xFF2E7D32); // Vert
    } else if (habVal == 'Non') {
      habColor = PdfColor.fromInt(0xFFC62828); // Rouge
    } else {
      habColor = PdfColors.black; // Noir (Inconnu)
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: 0.4),
        color: tableRowAlt,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            flex: 7,
            child: pw.Text(
              'Les techniciens disposent-ils d\'une formation en habilitation électrique ?',
              style: pw.TextStyle(
                font: _fontRegular,
                fontSize: fsBody,
                color: darkGrey,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            habVal,
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: fsBody,
              fontWeight: pw.FontWeight.bold,
              color: habColor,
            ),
          ),
        ],
      ),
    );
  }(),
      ],
    );
  }
  // ──────────────────────────────────────────────────────────────
  //  DESCRIPTION DES INSTALLATIONS (avec ordre des colonnes)
  // ──────────────────────────────────────────────────────────────
  
  static List<String> collectRiskZonesAndLocauxForTesting(AuditInstallationsElectriques? audit) {
    return _collectRiskZonesAndLocaux(audit);
  }

  static List<String> _collectRiskZonesAndLocaux(AuditInstallationsElectriques? audit) {
    final items = <String>[];
    if (audit == null) return items;

    void addZone(String name) {
      final formatted = name.toLowerCase().startsWith('zone') ? name : 'Zone $name';
      if (!items.contains(formatted)) items.add(formatted);
    }

    void addLocal(String name) {
      final formatted = name.toLowerCase().startsWith('local') || name.toLowerCase().startsWith('salle') ? name : 'Local $name';
      if (!items.contains(formatted)) items.add(formatted);
    }

    // Locaux MT directs
    for (final local in audit.moyenneTensionLocaux) {
      if (local.isRiskZone) addLocal(local.nom);
    }

    // Zones MT et leurs locaux
    for (final zone in audit.moyenneTensionZones) {
      if (zone.isRiskZone) addZone(zone.nom);
      for (final local in zone.locaux) {
        if (local.isRiskZone) addLocal(local.nom);
      }
    }

    // Zones BT et leurs locaux
    for (final zone in audit.basseTensionZones) {
      if (zone.isRiskZone) addZone(zone.nom);
      for (final local in zone.locaux) {
        if (local.isRiskZone) addLocal(local.nom);
      }
    }

    return items;
  }

  static List<pw.Widget> _buildDescriptionInstallationsMulti(
    DescriptionInstallations? desc,
    AuditInstallationsElectriques? audit,
    Map<String, int> trackedPages, {
    int offset = 0,
  }) {
    final widgets = <pw.Widget>[];
    widgets.add(PageTracker(
      key: 'description',
      registry: trackedPages,
      offset: offset,
      child: _sectionBox('DESCRIPTION DES INSTALLATIONS'),
    ));
    widgets.add(pw.SizedBox(height: 8));

    if (desc == null && audit == null) {
      widgets.add(_bodyText('Aucune donnée disponible.'));
      return widgets;
    }

    final pdfData = InstallationDescriptionPdfData.fromDescription(desc: desc, audit: audit);
    final safeDesc = desc ?? DescriptionInstallations.create('');

    int descBodyIdx = 1;

    widgets.add(PageTracker(
      key: 'desc_mt',
      registry: trackedPages,
      offset: offset,
      child: _subTitle('${descBodyIdx++}. Caractéristiques de l\'alimentation moyenne tension'),
    ));
    if (pdfData.mtRows.isNotEmpty) {
      widgets.add(_buildInstallationTableFromRows(pdfData.mtRows, sectionKey: 'MT'));
    } else {
      widgets.add(_bodyText('- Non renseignee'));
    }
    
    widgets.add(PageTracker(
      key: 'desc_bt',
      registry: trackedPages,
      offset: offset,
      child: _subTitle('${descBodyIdx++}. Caractéristiques de l\'alimentation basse tension sortie transformateur'),
    ));
    if (pdfData.btRows.isNotEmpty) {
      widgets.add(_buildInstallationTableFromRows(pdfData.btRows, sectionKey: 'BT'));
    } else {
      widgets.add(_bodyText('- Non renseignee'));
    }
    
    widgets.add(PageTracker(
      key: 'desc_ge',
      registry: trackedPages,
      offset: offset,
      child: _subTitle('${descBodyIdx++}. Caractéristiques du groupe électrogène'),
    ));
    if (safeDesc.groupeElectrogene.isNotEmpty) {
      widgets.add(_buildInstallationTable(safeDesc.groupeElectrogene, sectionKey: 'GROUPE'));
    } else {
      widgets.add(_bodyText('- Absent'));
    }
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(PageTracker(
      key: 'desc_carburant',
      registry: trackedPages,
      offset: offset,
      child: _subTitle('${descBodyIdx++}. Alimentation du groupe électrogène en carburant'),
    ));
    if (safeDesc.alimentationCarburant.isNotEmpty) {
      widgets.add(_buildInstallationTable(safeDesc.alimentationCarburant, sectionKey: 'CARBURANT'));
    } else {
      widgets.add(_bodyText('- Non applicable'));
    }
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(PageTracker(
      key: 'desc_inverseur',
      registry: trackedPages,
      offset: offset,
      child: _subTitle('${descBodyIdx++}. Caractéristiques de l\'inverseur'),
    ));
    if (safeDesc.inverseur.isNotEmpty) {
      widgets.add(_buildInstallationTable(safeDesc.inverseur, sectionKey: 'INVERSEUR'));
    } else {
      widgets.add(_bodyText('- Absent'));
    }
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(PageTracker(
      key: 'desc_stabilisateur',
      registry: trackedPages,
      offset: offset,
      child: _subTitle('${descBodyIdx++}. Caractéristiques du stabilisateur'),
    ));
    if (safeDesc.stabilisateur.isNotEmpty) {
      widgets.add(_buildInstallationTable(safeDesc.stabilisateur, sectionKey: 'STABILISATEUR'));
    } else {
      widgets.add(_bodyText('- Absent'));
    }
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(PageTracker(
      key: 'desc_onduleurs',
      registry: trackedPages,
      offset: offset,
      child: _subTitle('${descBodyIdx++}. Caractéristiques des onduleurs'),
    ));
    if (safeDesc.onduleurs.isNotEmpty) {
      widgets.add(_buildInstallationTable(safeDesc.onduleurs, sectionKey: 'ONDULEUR'));
    } else {
      widgets.add(_bodyText('- Absent'));
    }
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(PageTracker(
      key: 'desc_regime_neutre',
      registry: trackedPages,
      offset: offset,
      child: _subTitle('${descBodyIdx++}. Régime de neutre'),
    ));
  
    String regimeAffichage = safeDesc.regimeNeutre ?? 'Non renseigné';
    if (safeDesc.regimeNeutre == 'TN' && safeDesc.regimeNeutreDetail != null) {
      regimeAffichage = 'TN (TN-${safeDesc.regimeNeutreDetail})';
    }
    
    widgets.add(_bodyText('- $regimeAffichage'));
    widgets.add(pw.SizedBox(height: 5));



    widgets.add(PageTracker(
      key: 'desc_eclairage',
      registry: trackedPages,
      offset: offset,
      child: _subTitle('${descBodyIdx++}. Eclairage de sécurité'),
    ));
    widgets.add(_bodyText('- ${safeDesc.eclairageSecurite ?? 'Non renseigné'}'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(PageTracker(
      key: 'desc_modifications',
      registry: trackedPages,
      offset: offset,
      child: _subTitle('${descBodyIdx++}. Modifications apportées aux installations'),
    ));
    widgets.add(_bodyText(safeDesc.modificationsInstallations ?? 'Sans objet'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(PageTracker(
      key: 'desc_note_calcul',
      registry: trackedPages,
      offset: offset,
      child: _subTitle('${descBodyIdx++}. Note de calcul des installations électriques'),
    ));
    widgets.add(_bodyText('- ${safeDesc.noteCalcul ?? 'Non transmis'}'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(PageTracker(
      key: 'desc_paratonnerre',
      registry: trackedPages,
      offset: offset,
      child: _subTitle('${descBodyIdx++}. Présence de paratonnerre'),
    ));
    widgets.add(_bodyText('Présence : ${safeDesc.presenceParatonnerre ?? 'NON'}'));
    if (safeDesc.analyseRisqueFoudre != null && safeDesc.analyseRisqueFoudre!.isNotEmpty) {
      widgets.add(_bodyText('Analyse risque foudre : ${safeDesc.analyseRisqueFoudre}'));
    }
    if (safeDesc.etudeTechniqueFoudre != null && safeDesc.etudeTechniqueFoudre!.isNotEmpty) {
      widgets.add(_bodyText('Etude technique foudre : ${safeDesc.etudeTechniqueFoudre}'));
    }
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(PageTracker(
      key: 'desc_registre',
      registry: trackedPages,
      offset: offset,
      child: _subTitle('${descBodyIdx++}. Registre de sécurité'),
    ));
    widgets.add(_bodyText('- ${safeDesc.registreSecurite ?? 'Non transmis'}'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(PageTracker(
      key: 'desc_locaux_risques',
      registry: trackedPages,
      offset: offset,
      child: _subTitle('${descBodyIdx++}. Zones et Locaux à risque'),
    ));

    final riskItems = _collectRiskZonesAndLocaux(audit);
    if (riskItems.isEmpty) {
      widgets.add(_bodyText('Rien \u00e0 signaler.'));
    } else {
      for (final item in riskItems) {
        widgets.add(_bodyText('\u2022 $item'));
      }
    }

    return widgets;
  }

  static pw.Widget _buildInstallationTable(List<InstallationItem> itemsInput, {String? sectionKey}) {
    if (itemsInput.isEmpty) return pw.Container();

    final items = List<InstallationItem>.from(itemsInput)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

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
    if (sectionKey != null && _columnOrderBySection.containsKey(sectionKey)) {
      finalOrder = _columnOrderBySection[sectionKey]!
          .where((col) => col != 'N\u00B0' && col != 'N°')
          .toList();
    } else {
      finalOrder = fieldOrder;
    }

    if (finalOrder.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor, width: 0.4)),
        child: _bodyText('Données non renseignees'),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FixedColumnWidth(18),
        ...{for (var i = 1; i <= finalOrder.length; i++) i: const pw.FlexColumnWidth(1)},
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            _cell('N\u00B0', isHeader: true, centered: true),
            ...finalOrder.map((c) => _cell(c, isHeader: true, centered: true)),
          ],
        ),
        ...items.asMap().entries.map((e) => pw.TableRow(
          decoration: pw.BoxDecoration(color: e.key.isOdd ? tableRowAlt : PdfColors.white),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '${e.key + 1}',
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
              ),
            ),
            ...finalOrder.map((key) {
              final raw = _resolveInstallationValue(e.value, key, sectionKey);
              final unit = _unitForField(key);
              final display = (raw != '-' &&
                      raw.isNotEmpty &&
                      unit.isNotEmpty &&
                      !raw.toLowerCase().contains(unit.toLowerCase()))
                  ? '$raw $unit'
                  : raw;
              return _cell(display, isHeader: false, centered: true);
            }),
          ],
        )),
      ],
    );
  }

  /// Construit un tableau PDF récapitulatif pour les installations à partir d'une liste de lignes normalisées
  static pw.Widget _buildInstallationTableFromRows(
      List<InstallationDescriptionPdfRow> rows,
      {required String sectionKey}) {
    if (rows.isEmpty) return _bodyText('- Non renseignee');

    final finalOrder = _columnOrderBySection[sectionKey] ?? [];
    if (finalOrder.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor, width: 0.4)),
        child: _bodyText('Données non renseignees'),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FixedColumnWidth(18),
        ...{for (var i = 1; i <= finalOrder.length; i++) i: const pw.FlexColumnWidth(1)},
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            _cell('N\u00B0', isHeader: true, centered: true),
            ...finalOrder.map((c) => _cell(c, isHeader: true, centered: true)),
          ],
        ),
        ...rows.asMap().entries.map((e) => pw.TableRow(
          decoration: pw.BoxDecoration(color: e.key.isOdd ? tableRowAlt : PdfColors.white),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '${e.key + 1}',
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
              ),
            ),
            ...finalOrder.map((key) {
              final raw = e.value.getValueForColumn(key, sectionKey);
              final unit = _unitForField(key);
              final display = (raw != '-' &&
                      raw.isNotEmpty &&
                      unit.isNotEmpty &&
                      !raw.toLowerCase().contains(unit.toLowerCase()))
                  ? '$raw $unit'
                  : raw;
              return _cell(display, isHeader: false, centered: true);
            }),
          ],
        )),
      ],
    );
  }

  /// Résolution tolérante des valeurs pour un champ de colonne PDF donné
  static String _resolveInstallationValue(
      InstallationItem item, String columnHeader, String? sectionKey) {
    if (item.data.isEmpty) return '-';

    // 1. Déterminer le dictionnaire d'alias à utiliser selon la section
    Map<String, String> aliases = {};
    if (sectionKey == 'MT') {
      aliases = InstallationDescriptionSyncService.celluleAliases;
    } else if (sectionKey == 'BT') {
      aliases = InstallationDescriptionSyncService.transfoAliases;
    }

    // 2. Tenter la résolution tolérante via InstallationDescriptionSyncService.getFieldWithAlias
    final val = InstallationDescriptionSyncService.getFieldWithAlias(
        item.data, columnHeader, aliases);
    if (val.isNotEmpty) return val;

    // 3. Fallback direct sur comparaison de clé normalisée
    final targetNorm = InstallationFieldsRegistry.normalizeKey(columnHeader);
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
    if (units.containsKey(fieldKey.toUpperCase())) return units[fieldKey.toUpperCase()]!;
    final norm = InstallationFieldsRegistry.normalizeKey(fieldKey);
    for (var entry in units.entries) {
      if (InstallationFieldsRegistry.normalizeKey(entry.key) == norm) {
        return entry.value;
      }
    }
    return '';
  }

  static List<pw.Widget> _buildListeRecapitulativeMulti(AuditInstallationsElectriques audit, Map<String, int> trackedPages) {
    final widgets = <pw.Widget>[];


    widgets.add(PageTracker(
      key: 'liste_recap_mt',
      registry: trackedPages,
      child: _subSectionBar('1. Moyenne tension'),
    ));
    widgets.add(pw.SizedBox(height: 5));
    final obsMT = _collectObservationsMT(audit);
    widgets.addAll(_buildObsRecapTableMT(obsMT));

    widgets.add(pw.NewPage());

    widgets.add(PageTracker(
      key: 'liste_recap_bt',
      registry: trackedPages,
      child: _subSectionBar('2. Basse tension'),
    ));
    widgets.add(pw.SizedBox(height: 5));
    final obsBT = _collectObservationsBT(audit);
    widgets.addAll(_buildObsRecapTableBT(obsBT));

    return widgets;
  }

  /// ── Tableau récap MT (Référence : Image 1) ──
  /// En-tête Ligne 1 : LOCALISATION (22%) | NON-CONFORMITÉ - PRÉCONISATION (78%)
  /// En-tête Ligne 2 : LOCAL (22%) | OBSERVATIONS (58%) | RÉF. NORMATIVE (20%)
  /// RowSpan : LOCAL fusionné verticalement sur le groupe avec texte centré.
  static List<pw.Widget> _buildObsRecapTableMT(List<_ObsRecap> obs) {
    if (obs.isEmpty) {
      return [
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColor.fromHex('#475569'), width: 0.5)),
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('Aucune observation',
              style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall, fontStyle: pw.FontStyle.italic)),
        )
      ];
    }

    final groups = _groupByLocal(obs);
    final widgets = <pw.Widget>[];

    // En-tête Ligne 1 (#1E3A8A Dark Navy)
    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColor.fromHex('#475569'), width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(2.2),
          1: pw.FlexColumnWidth(7.8),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: headerColor),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                alignment: pw.Alignment.center,
                child: pw.Text('LOCALISATION',
                    style: pw.TextStyle(font: _fontBold, fontSize: 8.0, color: PdfColors.white),
                    textAlign: pw.TextAlign.center),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                alignment: pw.Alignment.center,
                child: pw.Text('NON-CONFORMITÉ - PRÉCONISATION',
                    style: pw.TextStyle(font: _fontBold, fontSize: 8.0, color: PdfColors.white),
                    textAlign: pw.TextAlign.center),
              ),
            ],
          ),
        ],
      ),
    );

    // En-tête Ligne 2 (#2E5F9A Medium Blue)
    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColor.fromHex('#475569'), width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(2.2),
          1: pw.FlexColumnWidth(5.8),
          2: pw.FlexColumnWidth(2.0),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2E5F9A)),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text('LOCAL',
                    style: pw.TextStyle(font: _fontBold, fontSize: 7.5, color: PdfColors.white),
                    textAlign: pw.TextAlign.center),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text('OBSERVATIONS',
                    style: pw.TextStyle(font: _fontBold, fontSize: 7.5, color: PdfColors.white),
                    textAlign: pw.TextAlign.center),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text('RÉF. NORMATIVE',
                    style: pw.TextStyle(font: _fontBold, fontSize: 7.5, color: PdfColors.white),
                    textAlign: pw.TextAlign.center),
              ),
            ],
          ),
        ],
      ),
    );

    // Corps : 1 Table par groupe de Localisation avec effet visuel RowSpan (ligne médiane & masque de bordures)
    for (final group in groups) {
      final tableRows = <pw.TableRow>[];
      final count = group.items.length;
      final midIndex = (count - 1) ~/ 2;

      for (int i = 0; i < count; i++) {
        final o = group.items[i];
        final rowBg = i.isOdd ? tableRowAlt : PdfColors.white;
        final obsBorder = pw.Border(
          top: i > 0
              ? const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5)
              : pw.BorderSide.none,
          bottom: i < count - 1
              ? const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5)
              : pw.BorderSide.none,
        );

        tableRows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              // Cellule 0 : Nom du LOCAL (centré verticalement sur la ligne médiane du groupe)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: pw.Alignment.center,
                child: i == midIndex
                    ? pw.Text(
                        group.local.toUpperCase(),
                        style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                        textAlign: pw.TextAlign.center,
                      )
                    : pw.SizedBox(),
              ),
              // Cellule 1 : Observation (avec bordure supérieure et inférieure séparatrices)
              pw.Container(
                decoration: pw.BoxDecoration(border: obsBorder),
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(o.observation, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
              ),
              // Cellule 2 : Référence Normative (avec bordure supérieure et inférieure séparatrices)
              pw.Container(
                decoration: pw.BoxDecoration(border: obsBorder),
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text(o.refNorm,
                    style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                    textAlign: pw.TextAlign.center),
              ),
            ],
          ),
        );
      }

      widgets.add(
        pw.Table(
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
          border: pw.TableBorder(
            left: const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5),
            right: const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5),
            top: const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5),
            bottom: const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5),
            verticalInside: const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5),
            horizontalInside: pw.BorderSide.none,
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.2),
            1: pw.FlexColumnWidth(5.8),
            2: pw.FlexColumnWidth(2.0),
          },
          children: tableRows,
        ),
      );
    }

    return widgets;
  }

  /// ── Tableau récap BT (Référence : Image 2) ──
  /// Première ligne (2 sections) : LOCALISATION (30%) | NON-CONFORMITÉ - PRÉCONISATION (70%)
  /// Deuxième ligne (4 colonnes) : LOCALISATION / cellule vide (8%) | ÉQUIPEMENT (22%) | OBSERVATIONS (52%) | RÉF. NORMATIVE (18%)
  /// Troisième ligne (Sub-header) : LOCALISATION (30%) | VALEUR RÉELLE DE LA LOCALISATION (70%)
  /// RowSpan : ÉQUIPEMENT et # fusionnés verticalement sur chaque sous-groupe avec texte centré.
  static List<pw.Widget> _buildObsRecapTableBT(List<_ObsRecap> obs) {
    return _buildObsRecapTableBTFromGroups(_groupByLocal(obs));
  }

  static List<pw.Widget> _buildObsRecapTableBTFromGroups(List<_ObsGroup> groups) {
    if (groups.isEmpty) {
      return [
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColor.fromHex('#475569'), width: 0.5)),
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('Aucune observation',
              style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall, fontStyle: pw.FontStyle.italic)),
        )
      ];
    }

    final widgets = <pw.Widget>[];

    // En-tête Ligne 1 (#1E3A8A Dark Navy)
    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColor.fromHex('#475569'), width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(3.0),
          1: pw.FlexColumnWidth(7.0),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: headerColor),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                alignment: pw.Alignment.center,
                child: pw.Text('LOCALISATION',
                    style: pw.TextStyle(font: _fontBold, fontSize: 8.0, color: PdfColors.white),
                    textAlign: pw.TextAlign.center),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                alignment: pw.Alignment.center,
                child: pw.Text('NON-CONFORMITÉ - PRÉCONISATION',
                    style: pw.TextStyle(font: _fontBold, fontSize: 8.0, color: PdfColors.white),
                    textAlign: pw.TextAlign.center),
              ),
            ],
          ),
        ],
      ),
    );

    // En-tête Ligne 2 (#2E5F9A Medium Blue)
    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColor.fromHex('#475569'), width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(3.0),
          1: pw.FlexColumnWidth(5.2),
          2: pw.FlexColumnWidth(1.8),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2E5F9A)),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text('ÉQUIPEMENT',
                    style: pw.TextStyle(font: _fontBold, fontSize: 7.5, color: PdfColors.white),
                    textAlign: pw.TextAlign.center),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text('OBSERVATIONS',
                    style: pw.TextStyle(font: _fontBold, fontSize: 7.5, color: PdfColors.white),
                    textAlign: pw.TextAlign.center),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text('RÉF. NORMATIVE',
                    style: pw.TextStyle(font: _fontBold, fontSize: 7.5, color: PdfColors.white),
                    textAlign: pw.TextAlign.center),
              ),
            ],
          ),
        ],
      ),
    );

    int equipIdx = 0;

    for (final group in groups) {
      // Troisième ligne : Sous-titre Localisation (#DBEAFE Light Ice Blue)
      widgets.add(
        pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromHex('#475569'), width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(3.0),
            1: pw.FlexColumnWidth(7.0),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFDBEAFE)),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  alignment: pw.Alignment.center,
                  child: pw.Text('LOCALISATION',
                      style: pw.TextStyle(font: _fontBold, fontSize: 7.0, color: headerColor),
                      textAlign: pw.TextAlign.center),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(group.local.toUpperCase(),
                      style: pw.TextStyle(font: _fontBold, fontSize: 8.0, color: headerColor)),
                ),
              ],
            ),
          ],
        ),
      );

      // Sous-grouper par équipement (coffret)
      final equipGroups = <_ObsGroup>[];
      for (final o in group.items) {
        if (equipGroups.isEmpty || equipGroups.last.local != o.coffret) {
          equipGroups.add(_ObsGroup(local: o.coffret, items: [o]));
        } else {
          equipGroups.last.items.add(o);
        }
      }

      for (final eq in equipGroups) {
        equipIdx++;
        final tableRows = <pw.TableRow>[];
        final count = eq.items.length;
        final midIndex = (count - 1) ~/ 2;

        for (int i = 0; i < count; i++) {
          final o = eq.items[i];
          final rowBg = i.isOdd ? tableRowAlt : PdfColors.white;
          final obsBorder = pw.Border(
            top: i > 0
                ? const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5)
                : pw.BorderSide.none,
            bottom: i < count - 1
                ? const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5)
                : pw.BorderSide.none,
          );

          tableRows.add(
            pw.TableRow(
              decoration: pw.BoxDecoration(color: rowBg),
              children: [
                // Cellule 0 : N° Équipement (#) - centré verticalement sur la ligne médiane
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  alignment: pw.Alignment.center,
                  child: i == midIndex
                      ? pw.Text('$equipIdx',
                          style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                          textAlign: pw.TextAlign.center)
                      : pw.SizedBox(),
                ),
                // Cellule 1 : Nom Équipement - centré verticalement sur la ligne médiane
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  alignment: pw.Alignment.center,
                  child: i == midIndex
                      ? pw.Text(
                          eq.local.toUpperCase(),
                          style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                          textAlign: pw.TextAlign.center,
                        )
                      : pw.SizedBox(),
                ),
                // Cellule 2 : Observation (avec bordures supérieure et inférieure séparatrices)
                pw.Container(
                  decoration: pw.BoxDecoration(border: obsBorder),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(o.observation, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
                ),
                // Cellule 3 : Référence Normative (avec bordures supérieure et inférieure séparatrices)
                pw.Container(
                  decoration: pw.BoxDecoration(border: obsBorder),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  alignment: pw.Alignment.center,
                  child: pw.Text(o.refNorm,
                      style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                      textAlign: pw.TextAlign.center),
                ),
              ],
            ),
          );
        }

        widgets.add(
          pw.Table(
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
            border: pw.TableBorder(
              left: const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5),
              right: const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5),
              top: const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5),
              bottom: const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5),
              verticalInside: const pw.BorderSide(color: PdfColor.fromInt(0xFF475569), width: 0.5),
              horizontalInside: pw.BorderSide.none,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.8),
              1: pw.FlexColumnWidth(2.2),
              2: pw.FlexColumnWidth(5.2),
              3: pw.FlexColumnWidth(1.8),
            },
            children: tableRows,
          ),
        );
      }
    }

    return widgets;
  }


  static pw.Widget _obsHeaderCellMT(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: pw.Alignment.center,
      child: pw.Text(text,
          style: pw.TextStyle(
              font: _fontBold, fontSize: fsSmall, color: PdfColors.white),
          textAlign: pw.TextAlign.center),
    );
  }

  static List<_ObsGroup> _groupByLocal(List<_ObsRecap> obs) {
    final groups = <_ObsGroup>[];
    for (final o in obs) {
      if (groups.isEmpty || groups.last.local != o.localisation) {
        groups.add(_ObsGroup(local: o.localisation, items: [o]));
      } else {
        groups.last.items.add(o);
      }
    }
    return groups;
  }

  // ──────────────────────────────────────────────────────────────
  //  COLLECTE DES OBSERVATIONS
  // ──────────────────────────────────────────────────────────────
  
  static List<_ObsRecap> _collectObservationsMT(AuditInstallationsElectriques audit) {
    final list = <_ObsRecap>[];

    for (var local in audit.moyenneTensionLocaux) {
      for (var el in local.dispositionsConstructives) {
        if (el.conforme == false) {
          list.add(_ObsRecap(
            localisation: local.nom,
            coffret: 'Dispositions constructives',
            observation: el.observation ?? el.elementControle,
            refNorm: el.referenceNormative ?? '',
            priorite: el.priorite?.toString() ?? '',
          ));
        }
      }
      for (var el in local.conditionsExploitation) {
        if (el.conforme == false) {
          list.add(_ObsRecap(
            localisation: local.nom,
            coffret: 'Conditions d\'exploitation',
            observation: el.observation ?? el.elementControle,
            refNorm: el.referenceNormative ?? '',
            priorite: el.priorite?.toString() ?? '',
          ));
        }
      }
      // Cellules (liste complète, pas ancien champ unique)
      for (var i = 0; i < local.cellules.length; i++) {
        final cellule = local.cellules[i];
        final label = 'Cellule ${i + 1} — ${cellule.fonction}';
        for (var el in cellule.elementsVerifies) {
          if (el.conforme == false || el.estNA) {
            list.add(_ObsRecap(
              localisation: local.nom,
              coffret: label,
              observation: el.observation ?? el.elementControle,
              refNorm: el.referenceNormative ?? '',
              priorite: el.conforme == false ? (el.priorite?.toString() ?? '') : 'NA',
            ));
          }
        }
      }
      // Transformateurs (liste complète)
      for (var i = 0; i < local.transformateurs.length; i++) {
        final transfo = local.transformateurs[i];
        final label = 'Transformateur ${i + 1}';
        for (var el in transfo.elementsVerifies) {
          if (el.conforme == false || el.estNA) {
            list.add(_ObsRecap(
              localisation: local.nom,
              coffret: label,
              observation: el.observation ?? el.elementControle,
              refNorm: el.referenceNormative ?? '',
              priorite: el.conforme == false ? (el.priorite?.toString() ?? '') : 'NA',
            ));
          }
        }
      }
      for (var coffret in local.coffrets) {
        final coffretRepere = coffret.repere?.isNotEmpty == true ? coffret.repere : coffret.numeroEquipement;
        for (var pv in coffret.pointsVerification) {
          final conf = pv.conformite.toLowerCase().trim();
          if (conf == 'non' || conf == 'non conforme') {
            if (pv.observations != null && pv.observations!.isNotEmpty) {
              for (var obs in pv.observations!) {
                list.add(_ObsRecap(
                  localisation: local.nom,
                  coffret: coffret.nom,
                  observation: obs.observation?.isNotEmpty == true ? obs.observation! : pv.pointVerification,
                  refNorm: obs.referenceNormative ?? pv.referenceNormative ?? '',
                  priorite: obs.priorite?.toString() ?? '',
                  repere: coffretRepere,
                ));
              }
            } else {
              list.add(_ObsRecap(
                localisation: local.nom,
                coffret: coffret.nom,
                observation: pv.observation ?? pv.pointVerification,
                refNorm: pv.referenceNormative ?? '',
                priorite: pv.priorite?.toString() ?? '',
                repere: coffretRepere,
              ));
            }
          }
        }
        for (var obs in coffret.observationsLibres) {
          list.add(_ObsRecap(
            localisation: local.nom,
            coffret: coffret.nom,
            observation: obs.texte, refNorm: '', priorite: '',
            repere: coffretRepere,
          ));
        }
      }
      for (var obs in local.observationsLibres) {
        list.add(_ObsRecap(
          localisation: local.nom,
          coffret: '', observation: obs.texte, refNorm: '', priorite: '',
        ));
      }
    }

    for (var zone in audit.moyenneTensionZones) {
      for (var coffret in zone.coffrets) {
        for (var pv in coffret.pointsVerification) {
          final conf = pv.conformite.toLowerCase().trim();
          if (conf == 'non' || conf == 'non conforme') {
            if (pv.observations != null && pv.observations!.isNotEmpty) {
              for (var obs in pv.observations!) {
                list.add(_ObsRecap(
                  localisation: zone.nom,
                  coffret: coffret.nom,
                  observation: obs.observation?.isNotEmpty == true ? obs.observation! : pv.pointVerification,
                  refNorm: obs.referenceNormative ?? pv.referenceNormative ?? '',
                  priorite: obs.priorite?.toString() ?? '',
                ));
              }
            } else {
              list.add(_ObsRecap(
                localisation: zone.nom,
                coffret: coffret.nom,
                observation: pv.observation ?? pv.pointVerification,
                refNorm: pv.referenceNormative ?? '',
                priorite: pv.priorite?.toString() ?? '',
              ));
            }
          }
        }
        for (var obs in coffret.observationsLibres) {
          list.add(_ObsRecap(
            localisation: zone.nom, coffret: coffret.nom,
            observation: obs.texte, refNorm: '', priorite: '',
          ));
        }
      }
      for (var local in zone.locaux) {
        for (var el in local.dispositionsConstructives) {
          if (el.conforme == false) {
            list.add(_ObsRecap(
              localisation: '${zone.nom} / ${local.nom}',
              coffret: 'Dispositions constructives',
              observation: el.observation ?? el.elementControle,
              refNorm: el.referenceNormative ?? '',
              priorite: el.priorite?.toString() ?? '',
            ));
          }
        }
        for (var coffret in local.coffrets) {
          for (var pv in coffret.pointsVerification) {
            if (pv.conformite == 'non' || pv.conformite == 'Non' || pv.conformite == 'Non conforme') {
              if (pv.observations != null && pv.observations!.isNotEmpty) {
                for (var obs in pv.observations!) {
                  list.add(_ObsRecap(
                    localisation: '${zone.nom} / ${local.nom}',
                    coffret: coffret.nom,
                    observation: obs.observation?.isNotEmpty == true ? obs.observation! : pv.pointVerification,
                    refNorm: obs.referenceNormative ?? pv.referenceNormative ?? '',
                    priorite: obs.priorite?.toString() ?? '',
                  ));
                }
              } else {
                list.add(_ObsRecap(
                  localisation: '${zone.nom} / ${local.nom}',
                  coffret: coffret.nom,
                  observation: pv.observation ?? pv.pointVerification,
                  refNorm: pv.referenceNormative ?? '',
                  priorite: pv.priorite?.toString() ?? '',
                ));
              }
            }
          }
          for (var obs in coffret.observationsLibres) {
            list.add(_ObsRecap(
              localisation: '${zone.nom} / ${local.nom}',
              coffret: coffret.nom,
              observation: obs.texte, refNorm: '', priorite: '',
            ));
          }
        }
        for (var obs in local.observationsLibres) {
          list.add(_ObsRecap(
            localisation: '${zone.nom} / ${local.nom}',
            coffret: '', observation: obs.texte, refNorm: '', priorite: '',
          ));
        }
      }
      for (var obs in zone.observationsLibres) {
        list.add(_ObsRecap(
          localisation: zone.nom, coffret: '',
          observation: obs.texte, refNorm: '', priorite: '',
        ));
      }
    }

    return list;
  }

  static List<_ObsRecap> _collectObservationsBT(AuditInstallationsElectriques audit) {
    final list = <_ObsRecap>[];

    for (var zone in audit.basseTensionZones) {
      for (var coffret in zone.coffretsDirects) {
        final coffretRepere = coffret.repere?.isNotEmpty == true ? coffret.repere : coffret.numeroEquipement;
        for (var pv in coffret.pointsVerification) {
          if (pv.conformite == 'non' || pv.conformite == 'Non' || pv.conformite == 'Non conforme') {
            if (pv.observations != null && pv.observations!.isNotEmpty) {
              for (var obs in pv.observations!) {
                list.add(_ObsRecap(
                  localisation: zone.nom,
                  coffret: coffret.nom,
                  observation: obs.observation?.isNotEmpty == true ? obs.observation! : pv.pointVerification,
                  refNorm: obs.referenceNormative ?? pv.referenceNormative ?? '',
                  priorite: obs.priorite?.toString() ?? '',
                  repere: coffretRepere,
                ));
              }
            } else {
              list.add(_ObsRecap(
                localisation: zone.nom,
                coffret: coffret.nom,
                observation: pv.observation ?? pv.pointVerification,
                refNorm: pv.referenceNormative ?? '',
                priorite: pv.priorite?.toString() ?? '',
                repere: coffretRepere,
              ));
            }
          }
        }
        for (var obs in coffret.observationsLibres) {
          list.add(_ObsRecap(
            localisation: zone.nom, coffret: coffret.nom,
            observation: obs.texte, refNorm: '', priorite: '',
            repere: coffretRepere,
          ));
        }
      }

      for (var local in zone.locaux) {
        if (local.dispositionsConstructives != null) {
          for (var el in local.dispositionsConstructives!) {
            if (el.conforme == false || el.estNA) {
              list.add(_ObsRecap(
                localisation: '${zone.nom} / ${local.nom}',
                coffret: 'Dispositions constructives',
                observation: el.observation ?? el.elementControle,
                refNorm: el.referenceNormative ?? '',
                priorite: el.conforme == false ? (el.priorite?.toString() ?? '') : 'NA',
              ));
            }
          }
        }
        if (local.conditionsExploitation != null) {
          for (var el in local.conditionsExploitation!) {
            if (el.conforme == false) {
              list.add(_ObsRecap(
                localisation: '${zone.nom} / ${local.nom}',
                coffret: 'Conditions d\'exploitation',
                observation: el.observation ?? el.elementControle,
                refNorm: el.referenceNormative ?? '',
                priorite: el.priorite?.toString() ?? '',
              ));
            }
          }
        }
        for (var coffret in local.coffrets) {
          final coffretRepere = coffret.repere?.isNotEmpty == true ? coffret.repere : coffret.numeroEquipement;
          for (var pv in coffret.pointsVerification) {
            final conf = pv.conformite.toLowerCase().trim();
            if (conf == 'non' || conf == 'non conforme') {
              if (pv.observations != null && pv.observations!.isNotEmpty) {
                for (var obs in pv.observations!) {
                  list.add(_ObsRecap(
                    localisation: '${zone.nom} / ${local.nom}',
                    coffret: coffret.nom,
                    observation: obs.observation?.isNotEmpty == true ? obs.observation! : pv.pointVerification,
                    refNorm: obs.referenceNormative ?? pv.referenceNormative ?? '',
                    priorite: obs.priorite?.toString() ?? '',
                    repere: coffretRepere,
                  ));
                }
              } else {
                list.add(_ObsRecap(
                  localisation: '${zone.nom} / ${local.nom}',
                  coffret: coffret.nom,
                  observation: pv.observation ?? pv.pointVerification,
                  refNorm: pv.referenceNormative ?? '',
                  priorite: pv.priorite?.toString() ?? '',
                  repere: coffretRepere,
                ));
              }
            }
          }
          for (var obs in coffret.observationsLibres) {
            list.add(_ObsRecap(
              localisation: '${zone.nom} / ${local.nom}',
              coffret: coffret.nom,
              observation: obs.texte, refNorm: '', priorite: '',
              repere: coffretRepere,
            ));
          }
        }
        for (var obs in local.observationsLibres) {
          list.add(_ObsRecap(
            localisation: '${zone.nom} / ${local.nom}',
            coffret: '', observation: obs.texte, refNorm: '', priorite: '',
          ));
        }
      }
      for (var obs in zone.observationsLibres) {
        list.add(_ObsRecap(
          localisation: zone.nom, coffret: '',
          observation: obs.texte, refNorm: '', priorite: '',
        ));
      }
    }

    return list;
  }





  // ──────────────────────────────────────────────────────────────
  //  AUDIT DES INSTALLATIONS ELECTRIQUES
  // ──────────────────────────────────────────────────────────────
  
  static List<pw.Widget> _buildAuditContentOrdered(AuditInstallationsElectriques audit, Map<String, int> trackedPages) {
    final widgets = <pw.Widget>[];

    // 1. Locaux MT directs (hors zone) — PREMIER local sur la même page que le titre
    if (audit.moyenneTensionLocaux.isNotEmpty) {
      if (widgets.isNotEmpty) widgets.add(pw.NewPage());
      widgets.add(_subSectionBar('MOYENNE TENSION — LOCAUX DIRECTS'));
      
      for (int i = 0; i < audit.moyenneTensionLocaux.length; i++) {
        final local = audit.moyenneTensionLocaux[i];
        // Pas de NewPage pour le premier local (i == 0)
        if (i > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildLocalMT(local, trackedPages));
      }
    }

    // 2. Zones MT
    for (var zone in audit.moyenneTensionZones) {
      widgets.add(pw.NewPage());
      widgets.addAll(_buildZone(zone.nom, zone.observationsLibres, trackedPages));
      
      int elementIndex = 0;
      // Locaux dans la zone : le premier sur la même page que la zone (élément 0)
      for (int i = 0; i < zone.locaux.length; i++) {
        final local = zone.locaux[i];
        if (elementIndex > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildLocalMT(local, trackedPages));
        elementIndex++;
      }
      
      // Coffrets de la zone
      for (int i = 0; i < zone.coffrets.length; i++) {
        final coffret = zone.coffrets[i];
        if (elementIndex > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildCoffret(coffret, trackedPages, zone.nom));
        elementIndex++;
      }
    }

    // 3. Zones BT
    for (var zone in audit.basseTensionZones) {
      widgets.add(pw.NewPage());
      widgets.addAll(_buildZone(zone.nom, zone.observationsLibres, trackedPages));
      
      int elementIndex = 0;
      // Coffrets directs de la zone : le premier sur la même page que la zone (élément 0)
      for (int i = 0; i < zone.coffretsDirects.length; i++) {
        final coffret = zone.coffretsDirects[i];
        if (elementIndex > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildCoffret(coffret, trackedPages, zone.nom));
        elementIndex++;
      }
      
      // Locaux BT
      for (int i = 0; i < zone.locaux.length; i++) {
        final local = zone.locaux[i];
        if (elementIndex > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildLocalBT(local, trackedPages));
        elementIndex++;
      }
    }

    if (widgets.isEmpty) {
      widgets.add(_bodyText('Aucune installation enregistree.'));
    }

    return widgets;
  }

  static List<pw.Widget> _buildZone(String nom, List<ObservationLibre> obs, Map<String, int> trackedPages) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 8),
      PageTracker(
        key: 'audit_zone_$nom',
        registry: trackedPages,
        child: pw.Container(
          width: double.infinity,
          color: accentColor,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Text(nom.toUpperCase(),
              style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: PdfColors.white)),
        ),
      ),
    ];

    widgets.add(pw.SizedBox(height: 5));
    widgets.add(_buildObsZoneTable(nom, obs));
    
    widgets.add(pw.SizedBox(height: 5));
    return widgets;
  }

  static pw.Widget _buildObsZoneTable(String zone, List<ObservationLibre> obs) {
    final rows = <pw.TableRow>[
      // En-tête (avec Items centré et Titre à gauche en majuscule)
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.white),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            alignment: pw.Alignment.center,
            child: pw.Text('Items',
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.black)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text('OBSERVATIONS RELATIVES A ${zone.toUpperCase()}',
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.black)),
          ),
        ],
      ),
    ];

    if (obs.isEmpty) {
      rows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text('-',
                  style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: pw.Text('Rien à signaler',
                  style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      );
    } else {
      rows.addAll(obs.asMap().entries.map((e) => pw.TableRow(
        decoration: pw.BoxDecoration(color: e.key.isEven ? PdfColors.white : tableRowAlt),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            alignment: pw.Alignment.center,
            child: pw.Text('${e.key + 1}',
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: pw.Text(e.value.texte,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
        ],
      )));
    }

    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        top: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.8),
        1: pw.FlexColumnWidth(6.4),
      },
      children: rows,
    );
  }

  static List<pw.Widget> _buildLocalMT(
    MoyenneTensionLocal local,
    Map<String, int> trackedPages, {
    Map<dynamic, pw.MemoryImage?>? photoCache,
    bool saveFilesToDisk = true,
  }) {
    final widgets = <pw.Widget>[
      PageTracker(
        key: 'audit_local_${local.nom}',
        registry: trackedPages,
        child: _localNameBar(local.nom.toUpperCase()),
      ),
      pw.SizedBox(height: 5),
    ];

    // Infos générales du local (toujours affichées)
    final typeLabelMT = HiveService.getLocalTypes()[local.type] ?? local.type;
    widgets.add(pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(3)},
      children: [
        _tableDataRow(['Type de local', typeLabelMT], alt: false),
      ],
    ));
    widgets.add(pw.SizedBox(height: 5));

    // Photo du local (si présente, alignée à droite)
    pw.MemoryImage? localPhotoImg;
    if (photoCache != null && photoCache.containsKey(local)) {
      localPhotoImg = photoCache[local];
    } else if (local.photos.isNotEmpty) {
      final rawPath = local.photos.first.trim();
      if (rawPath.isNotEmpty && File(rawPath).existsSync()) {
        try {
          final f = File(rawPath);
          if (f.lengthSync() < 500000) {
            final bytes = f.readAsBytesSync();
            if (bytes.isNotEmpty) {
              localPhotoImg = pw.MemoryImage(bytes);
            }
          }
        } catch (_) {}
      }
    }

    if (localPhotoImg != null) {
      widgets.add(
        pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 2, bottom: 6),
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderColor, width: 0.4),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            padding: const pw.EdgeInsets.all(3),
            child: pw.Image(
              localPhotoImg,
              height: 120,
              width: 160,
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
      );
    }

    // Local inaccessible : mention claire dans le rapport
    if (local.accessible == false) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.red50,
            border: pw.Border.all(color: PdfColors.red200),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(children: [
                pw.Container(
                  width: 10, height: 10,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.red,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text(
                  '[!] LOCAL INACCESSIBLE — NON INSPECTÉ',
                  style: pw.TextStyle(
                    color: PdfColors.red,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ]),
              pw.SizedBox(height: 4),
              pw.Text(
                "Ce local n'a pas pu être inspecté lors de la visite. "
                "Une nouvelle vérification est nécessaire pour couvrir cet emplacement.",
                style: pw.TextStyle(
                  color: PdfColors.red700,
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
      return widgets; // Pas d'éléments à afficher
    }

    DispositionsConstructivesRegistry.ensureCompleteLocalChecklists(
      dispositionsConstructives: local.dispositionsConstructives,
      conditionsExploitation: local.conditionsExploitation,
    );
    if (local.dispositionsConstructives.isNotEmpty) {
      widgets.addAll(_buildDispositionsTable(
        local.dispositionsConstructives,
        'DISPOSITIONS CONSTRUCTIVES DU LOCAL TECHNIQUE MOYENNE TENSION',
        localType: local.type,
      ));
    }
    if (local.conditionsExploitation.isNotEmpty) {
      if (local.dispositionsConstructives.isNotEmpty) {
        widgets.add(pw.NewPage());
      }
      widgets.addAll(_buildDispositionsTable(
        local.conditionsExploitation,
        'CONDITIONS D\'EXPLOITATION ET DE SÉCURITÉ DU LOCAL MOYENNE TENSION',
        localType: local.type,
      ));
    }

    for (int i = 0; i < local.cellules.length; i++) {
      widgets.add(pw.NewPage());
      widgets.addAll(_buildCelluleSection(
        local.cellules[i],
        photoCache: photoCache,
        saveFilesToDisk: saveFilesToDisk,
      ));
    }
    for (int i = 0; i < local.transformateurs.length; i++) {
      widgets.add(pw.NewPage());
      widgets.addAll(_buildTransformateurSection(
        local.transformateurs[i],
        photoCache: photoCache,
        saveFilesToDisk: saveFilesToDisk,
      ));
    }

    for (int i = 0; i < local.coffrets.length; i++) {
      widgets.add(pw.NewPage());
      widgets.addAll(_buildCoffret(local.coffrets[i], trackedPages, local.nom, photoCache: photoCache));
    }

    return widgets;
  }

  static List<pw.Widget> _buildLocalBT(
    BasseTensionLocal local,
    Map<String, int> trackedPages, {
    Map<dynamic, pw.MemoryImage?>? photoCache,
  }) {
    final widgets = <pw.Widget>[
      PageTracker(
        key: 'audit_local_${local.nom}',
        registry: trackedPages,
        child: _localNameBar(local.nom.toUpperCase()),
      ),
      pw.SizedBox(height: 5),
    ];

    // Infos générales du local (toujours affichées)
    final typeLabelMT = HiveService.getLocalTypes()[local.type] ?? local.type;
    widgets.add(pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(3)},
      children: [
        _tableDataRow(['Type de local', typeLabelMT], alt: false),
      ],
    ));
    widgets.add(pw.SizedBox(height: 5));

    // Photo du local (si présente, alignée à droite)
    pw.MemoryImage? localPhotoImg;
    if (photoCache != null && photoCache.containsKey(local)) {
      localPhotoImg = photoCache[local];
    } else if (local.photos.isNotEmpty) {
      final rawPath = local.photos.first.trim();
      if (rawPath.isNotEmpty && File(rawPath).existsSync()) {
        try {
          final f = File(rawPath);
          if (f.lengthSync() < 500000) {
            final bytes = f.readAsBytesSync();
            if (bytes.isNotEmpty) {
              localPhotoImg = pw.MemoryImage(bytes);
            }
          }
        } catch (_) {}
      }
    }

    if (localPhotoImg != null) {
      widgets.add(
        pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 2, bottom: 6),
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderColor, width: 0.4),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            padding: const pw.EdgeInsets.all(3),
            child: pw.Image(
              localPhotoImg,
              height: 120,
              width: 160,
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
      );
    }

    // Local inaccessible : mention claire dans le rapport
    if (local.accessible == false) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.red50,
            border: pw.Border.all(color: PdfColors.red200),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(children: [
                pw.Container(
                  width: 10, height: 10,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.red,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text(
                  '[!] LOCAL INACCESSIBLE — NON INSPECTÉ',
                  style: pw.TextStyle(
                    color: PdfColors.red,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ]),
              pw.SizedBox(height: 4),
              pw.Text(
                "Ce local n'a pas pu être inspecté lors de la visite. "
                "Une nouvelle vérification est nécessaire pour couvrir cet emplacement.",
                style: pw.TextStyle(
                  color: PdfColors.red700,
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
      return widgets; // Pas d'éléments à afficher
    }

    final isGE = local.type == 'LOCAL_GROUPE_ELECTROGENE';
    final isBT = !isGE;

    if (isGE && local.dispositionsConstructives != null && local.conditionsExploitation != null) {
      DispositionsConstructivesRegistry.ensureCompleteGELocalChecklists(
        dispositionsConstructives: local.dispositionsConstructives!,
        conditionsExploitation: local.conditionsExploitation!,
      );
    } else if (isBT && local.dispositionsConstructives != null && local.conditionsExploitation != null) {
      DispositionsConstructivesRegistry.ensureCompleteBTLocalChecklists(
        dispositionsConstructives: local.dispositionsConstructives!,
        conditionsExploitation: local.conditionsExploitation!,
      );
    }

    final dispTitle = isGE
        ? 'DISPOSITIONS CONSTRUCTIVES DU LOCAL TECHNIQUE GROUPE ÉLECTROGENE'
        : 'DISPOSITIONS CONSTRUCTIVES DU LOCAL TECHNIQUE BASSE TENSION';
    final condTitle = isGE
        ? 'CONDITIONS D\'EXPLOITATION ET DE SÉCURITÉ LOCAL GROUPE ÉLECTROGENE'
        : 'CONDITIONS D\'EXPLOITATION ET DE SÉCURITÉ LOCAL BASSE TENSION';

    if (local.dispositionsConstructives != null && local.dispositionsConstructives!.isNotEmpty) {
      widgets.addAll(_buildDispositionsTable(
        local.dispositionsConstructives!,
        dispTitle,
        localType: local.type,
      ));
    }
    if (local.conditionsExploitation != null && local.conditionsExploitation!.isNotEmpty) {
      if (local.dispositionsConstructives != null && local.dispositionsConstructives!.isNotEmpty) {
        widgets.add(pw.NewPage());
      }
      widgets.addAll(_buildDispositionsTable(
        local.conditionsExploitation!,
        condTitle,
        localType: local.type,
      ));
    }

    for (int i = 0; i < local.coffrets.length; i++) {
      widgets.add(pw.NewPage());
      widgets.addAll(_buildCoffret(local.coffrets[i], trackedPages, local.nom, photoCache: photoCache));
    }

    return widgets;
  }

  // En-tête de sous-section épuré textuel (sans bloc graphique)
  static pw.Widget _subSectionBar(String title) {
    return _subTitle(title);
  }

  // Barre de nom de local (vert clair — comme la trame)
  static pw.Widget _localNameBar(String title) {
    return pw.Container(
      width: double.infinity,
      color: PdfColor.fromInt(0xFFD8EAD3), // vert très clair
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: fsH3,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF1E4620))), // vert foncé
    );
  }

  static List<pw.Widget> _buildDispositionsTable(
    List<ElementControle> elements,
    String titre, {
    String? localType,
  }) {
    const tableColumnWidths = <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(2.4), // POINTS DE VÉRIFICATION
      1: pw.FlexColumnWidth(1.2), // CONFORMITÉ (garantit CONFORMITÉ sur 1 seule ligne)
      2: pw.FlexColumnWidth(1.4), // RÉF. NORMATIVE
      3: pw.FlexColumnWidth(1.4), // FAMILLE DE RISQUE
      4: pw.FlexColumnWidth(0.9), // CRITICITÉ
      5: pw.FlexColumnWidth(1.7), // OBSERVATION
    };

    final titleTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.4),
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(9.0),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.center,
              child: pw.Text(
                titre,
                style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: headerColor),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );

    final headerTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: tableColumnWidths,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('POINTS DE VÉRIFICATION',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('CONFORMITÉ',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('RÉF. NORMATIVE',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('FAMILLE DE RISQUE',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('CRITICITÉ',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('OBSERVATION',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
          ],
        ),
      ],
    );

    final rows = <pw.TableRow>[];
    for (int idx = 0; idx < elements.length; idx++) {
      final el = elements[idx];
      String conf;
      PdfColor confColor;
      if (el.estNA) {
        conf = 'Sans objet';
        confColor = PdfColor.fromInt(0xFFE0E0E0);
      } else if (el.conforme == null) {
        conf = '-';
        confColor = tableRowAlt;
      } else if (el.conforme == true) {
        conf = 'Oui';
        confColor = conformeColor;
      } else {
        conf = 'Non';
        confColor = nonConformeColor;
      }

      // Condition d'affichage : Renseignement uniquement si la conformité est "Non" (conforme == false)
      final isNonConforme = el.conforme == false && !el.estNA;
      final meta = DispositionsConstructivesRegistry.getMetadata(el.elementControle, localType: localType);
      final refNorm = isNonConforme ? (meta?.referenceNormative ?? el.referenceNormative ?? '') : '';
      final familleRisque = isNonConforme ? (meta?.familleRisque ?? el.familleRisque ?? '') : '';
      final criticite = isNonConforme ? (meta?.criticite ?? el.criticite ?? '') : '';

      rows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: idx.isEven ? PdfColors.white : tableRowAlt),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(el.elementControle,
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
          ),
          pw.Container(
            color: confColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(conf,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                textAlign: pw.TextAlign.center),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(refNorm,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall - 0.5),
                textAlign: pw.TextAlign.center),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(familleRisque,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall - 0.5),
                textAlign: pw.TextAlign.center),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(criticite,
                style: pw.TextStyle(
                  font: criticite == 'Critique' ? _fontBold : _fontRegular,
                  fontSize: fsSmall - 0.5,
                  color: criticite == 'Critique' ? PdfColors.red900 : darkGrey,
                ),
                textAlign: pw.TextAlign.center),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(el.observation ?? '',
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                textAlign: pw.TextAlign.center),
          ),
        ],
      ));
    }

    final dataTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: tableColumnWidths,
      children: rows,
    );

    return [
      titleTable,
      headerTable,
      dataTable,
    ];
  }

  static List<pw.Widget> _buildCelluleSection(
    Cellule cellule, {
    Map<dynamic, pw.MemoryImage?>? photoCache,
    bool saveFilesToDisk = true,
  }) {
    DispositionsConstructivesRegistry.ensureCompleteCelluleChecklist(cellule.elementsVerifies);
    String safe(String v) => v.trim().isEmpty ? 'Non renseigné' : v;

    final hasNom = cellule.nom != null && cellule.nom!.trim().isNotEmpty;
    final rawPhotoPath = (cellule.photo != null && cellule.photo!.trim().isNotEmpty)
        ? cellule.photo!.trim()
        : (cellule.photos.isNotEmpty ? cellule.photos.first.trim() : null);
    final hasPhoto = rawPhotoPath != null && rawPhotoPath.isNotEmpty;

    pw.MemoryImage? photoImg;
    if (hasPhoto) {
      if (photoCache != null && photoCache.containsKey(cellule)) {
        photoImg = photoCache[cellule];
      } else if (!saveFilesToDisk) {
        photoImg = _placeholder1x1;
      }
    }

    pw.TableRow tableDataRowInfo(String label, String value, {required bool alt}) {
      return pw.TableRow(
        decoration: alt ? pw.BoxDecoration(color: tableRowAlt) : null,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Text(label,
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(value,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                textAlign: pw.TextAlign.center),
          ),
        ],
      );
    }

    const tableColumnWidths = <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(2.4), // POINTS DE VÉRIFICATION
      1: pw.FlexColumnWidth(1.2), // CONFORMITÉ
      2: pw.FlexColumnWidth(1.4), // RÉF. NORMATIVE
      3: pw.FlexColumnWidth(1.4), // FAMILLE DE RISQUE
      4: pw.FlexColumnWidth(0.9), // CRITICITÉ
      5: pw.FlexColumnWidth(1.7), // OBSERVATION
    };

    final titleTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.4),
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(9.0),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text('CELLULE MOYENNE TENSION',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
          ],
        ),
        if (hasNom)
          pw.TableRow(
            decoration: pw.BoxDecoration(color: lightBlue),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.only(left: 6, right: 6, bottom: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(cellule.nom!.trim(),
                    style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: headerColor),
                    textAlign: pw.TextAlign.center),
              ),
            ],
          ),
      ],
    );

    final infoTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.6),
        1: pw.FlexColumnWidth(2.8),
      },
      children: [
        tableDataRowInfo('Fonction de la cellule', safe(cellule.fonction), alt: false),
        tableDataRowInfo('Type de cellule', safe(cellule.type), alt: false),
        tableDataRowInfo('Gamme de la cellule', safe(cellule.gamme ?? ''), alt: false),
        tableDataRowInfo('Marque / modèle / année', safe(cellule.marqueModeleAnnee), alt: false),
        tableDataRowInfo('Tension assignée (kV)', safe(cellule.tensionAssignee), alt: false),
        tableDataRowInfo('Pouvoir de coupure assigné (kA)', safe(cellule.pouvoirCoupure), alt: false),
        tableDataRowInfo('Calibre du disjoncteur (A)', safe(cellule.calibreDisjoncteur ?? ''), alt: false),
        tableDataRowInfo('Section des câbles (mm²)', safe(cellule.sectionCables ?? ''), alt: false),
        tableDataRowInfo('Nature du réseau', safe(cellule.natureReseau ?? ''), alt: false),
        tableDataRowInfo('Présence IACM', safe(cellule.presenceIacm ?? ''), alt: false),
        tableDataRowInfo('Numérotation / repérage cellule', safe(cellule.numerotation), alt: false),
        tableDataRowInfo("Parafoudres installés sur l'arrivée", safe(cellule.parafoudres), alt: false),
        if (cellule.observations != null && cellule.observations!.isNotEmpty)
          tableDataRowInfo(
            'Observations',
            safe(cellule.observations!
                .map((o) => (o.observation != null && o.observation!.isNotEmpty) ? o.observation! : o.elementControle)
                .where((s) => s.isNotEmpty)
                .join(', ')),
            alt: false,
          ),
      ],
    );

    final topSectionTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(6.4),
        1: pw.FlexColumnWidth(2.6),
      },
      children: [
        pw.TableRow(
          children: [
            infoTable,
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.center,
              child: photoImg != null
                  ? pw.Image(photoImg, width: 140, height: 140, fit: pw.BoxFit.contain)
                  : pw.SizedBox(width: 140, height: 140),
            ),
          ],
        ),
      ],
    );

    final headerTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: tableColumnWidths,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('POINTS DE VÉRIFICATION',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('CONFORMITÉ',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('RÉF. NORMATIVE',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('FAMILLE DE RISQUE',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('CRITICITÉ',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('OBSERVATION',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
          ],
        ),
      ],
    );

    final dataRows = <pw.TableRow>[];
    for (int idx = 0; idx < cellule.elementsVerifies.length; idx++) {
      final el = cellule.elementsVerifies[idx];
      String conf;
      PdfColor confColor;
      if (el.estNA) {
        conf = 'Sans objet';
        confColor = PdfColor.fromInt(0xFFE0E0E0);
      } else if (el.conforme == null) {
        conf = '-';
        confColor = tableRowAlt;
      } else if (el.conforme == true) {
        conf = 'Oui';
        confColor = conformeColor;
      } else {
        conf = 'Non';
        confColor = nonConformeColor;
      }

      final isNonConforme = el.conforme == false && !el.estNA;
      final refNorm = isNonConforme ? (el.referenceNormativeEffective ?? '') : '';
      final familleRisque = isNonConforme ? (el.familleRisqueEffective ?? '') : '';
      final criticite = isNonConforme ? (el.criticiteEffective ?? '') : '';

      dataRows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: idx.isEven ? PdfColors.white : tableRowAlt),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(el.elementControle,
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
          ),
          pw.Container(
            color: confColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(conf,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                textAlign: pw.TextAlign.center),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(refNorm,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall - 0.5),
                textAlign: pw.TextAlign.center),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(familleRisque,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall - 0.5),
                textAlign: pw.TextAlign.center),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(criticite,
                style: pw.TextStyle(
                  font: criticite == 'Critique' ? _fontBold : _fontRegular,
                  fontSize: fsSmall - 0.5,
                  color: criticite == 'Critique' ? PdfColors.red900 : darkGrey,
                ),
                textAlign: pw.TextAlign.center),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(el.observation ?? '',
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                textAlign: pw.TextAlign.center),
          ),
        ],
      ));
    }

    final dataTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: tableColumnWidths,
      children: dataRows,
    );

    return [
      pw.SizedBox(height: 6),
      titleTable,
      topSectionTable,
      headerTable,
      dataTable,
      pw.SizedBox(height: 5),
    ];
  }

  static List<pw.Widget> _buildTransformateurSection(
    TransformateurMTBT transfo, {
    Map<dynamic, pw.MemoryImage?>? photoCache,
    bool saveFilesToDisk = true,
  }) {
    DispositionsConstructivesRegistry.ensureCompleteTransformateurChecklist(transfo.elementsVerifies);
    String safe(String v) => v.trim().isEmpty ? 'Non renseigné' : v;

    final rawPhotoPath = (transfo.photo != null && transfo.photo!.trim().isNotEmpty)
        ? transfo.photo!.trim()
        : (transfo.photos.isNotEmpty ? transfo.photos.first.trim() : null);
    final hasPhoto = rawPhotoPath != null && rawPhotoPath.isNotEmpty;

    pw.MemoryImage? photoImg;
    if (hasPhoto) {
      if (photoCache != null && photoCache.containsKey(transfo)) {
        photoImg = photoCache[transfo];
      } else if (!saveFilesToDisk) {
        photoImg = _placeholder1x1;
      }
    }

    pw.TableRow tableDataRowInfo(String label, String value, {required bool alt}) {
      return pw.TableRow(
        decoration: alt ? pw.BoxDecoration(color: tableRowAlt) : null,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Text(label,
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(value,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                textAlign: pw.TextAlign.center),
          ),
        ],
      );
    }

    const tableColumnWidths = <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(2.4), // POINTS DE VÉRIFICATION
      1: pw.FlexColumnWidth(1.2), // CONFORMITÉ
      2: pw.FlexColumnWidth(1.4), // RÉF. NORMATIVE
      3: pw.FlexColumnWidth(1.4), // FAMILLE DE RISQUE
      4: pw.FlexColumnWidth(0.9), // CRITICITÉ
      5: pw.FlexColumnWidth(1.7), // OBSERVATION
    };

    final hasNom = transfo.nom != null && transfo.nom!.trim().isNotEmpty;

    final titleTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.4),
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(9.0),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.center,
              child: pw.Text('TRANSFORMATEUR MT/BT',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
          ],
        ),
        if (hasNom)
          pw.TableRow(
            decoration: pw.BoxDecoration(color: lightBlue),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.only(left: 6, right: 6, bottom: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(transfo.nom!.trim(),
                    style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: headerColor),
                    textAlign: pw.TextAlign.center),
              ),
            ],
          ),
      ],
    );

    final infoTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.6),
        1: pw.FlexColumnWidth(2.8),
      },
      children: [
        tableDataRowInfo('Type de transformateur', safe(transfo.typeTransformateur), alt: false),
        tableDataRowInfo('Marque / Année de fabrication', safe(transfo.marqueAnnee), alt: false),
        tableDataRowInfo('Puissance assignée (kVA)', safe(transfo.puissanceAssignee), alt: false),
        tableDataRowInfo('Tension primaire / secondaire', safe(transfo.tensionPrimaireSecondaire), alt: false),
        tableDataRowInfo('Intensité nominale (A)', safe(transfo.intensiteNominale ?? ''), alt: false),
        tableDataRowInfo('Calibre du disjoncteur sortie transformateur (A)', safe(transfo.calibreDisjoncteur ?? ''), alt: false),
        tableDataRowInfo('Section des câbles (mm²)', safe(transfo.sectionCables ?? ''), alt: false),
        tableDataRowInfo('Couplage', safe(transfo.couplage ?? ''), alt: false),
        tableDataRowInfo('Type de réseau', safe(transfo.typeReseau ?? ''), alt: false),
        tableDataRowInfo('PCC amont (MVA)', safe(transfo.pccAmont ?? ''), alt: false),
        tableDataRowInfo('Puissance UCC (%)', safe(transfo.puissanceUcc ?? ''), alt: false),
        tableDataRowInfo('IK3 MAX (kA)', safe(transfo.ik3Max ?? ''), alt: false),
        tableDataRowInfo('Présence du relais Buchholz', safe(transfo.relaisBuchholz), alt: false),
        tableDataRowInfo('Type de refroidissement', safe(transfo.typeRefroidissement), alt: false),
        tableDataRowInfo('Régime du neutre', safe(transfo.regimeNeutre), alt: false),
        if (transfo.observations != null && transfo.observations!.isNotEmpty)
          tableDataRowInfo(
            'Observations',
            safe(transfo.observations!
                .map((o) => (o.observation != null && o.observation!.isNotEmpty) ? o.observation! : o.elementControle)
                .where((s) => s.isNotEmpty)
                .join(', ')),
            alt: false,
          ),
      ],
    );

    final topSectionTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(6.4),
        1: pw.FlexColumnWidth(2.6),
      },
      children: [
        pw.TableRow(
          children: [
            infoTable,
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.center,
              child: photoImg != null
                  ? pw.Image(photoImg, width: 140, height: 140, fit: pw.BoxFit.contain)
                  : pw.SizedBox(width: 140, height: 140),
            ),
          ],
        ),
      ],
    );

    final headerTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: tableColumnWidths,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('POINTS DE VÉRIFICATION',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('CONFORMITÉ',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('RÉF. NORMATIVE',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('FAMILLE DE RISQUE',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('CRITICITÉ',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('OBSERVATION',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
          ],
        ),
      ],
    );

    final dataRows = <pw.TableRow>[];
    for (int idx = 0; idx < transfo.elementsVerifies.length; idx++) {
      final el = transfo.elementsVerifies[idx];
      String conf;
      PdfColor confColor;
      if (el.estNA) {
        conf = 'Sans objet';
        confColor = PdfColor.fromInt(0xFFE0E0E0);
      } else if (el.conforme == null) {
        conf = '-';
        confColor = tableRowAlt;
      } else if (el.conforme == true) {
        conf = 'Oui';
        confColor = conformeColor;
      } else {
        conf = 'Non';
        confColor = nonConformeColor;
      }

      final isNonConforme = el.conforme == false && !el.estNA;
      final refNorm = isNonConforme ? (el.referenceNormativeEffective ?? '') : '';
      final familleRisque = isNonConforme ? (el.familleRisqueEffective ?? '') : '';
      final criticite = isNonConforme ? (el.criticiteEffective ?? '') : '';

      dataRows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: idx.isEven ? PdfColors.white : tableRowAlt),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(el.elementControle,
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
          ),
          pw.Container(
            color: confColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(conf,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                textAlign: pw.TextAlign.center),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(refNorm,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall - 0.5),
                textAlign: pw.TextAlign.center),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(familleRisque,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall - 0.5),
                textAlign: pw.TextAlign.center),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(criticite,
                style: pw.TextStyle(
                  font: criticite == 'Critique' ? _fontBold : _fontRegular,
                  fontSize: fsSmall - 0.5,
                  color: criticite == 'Critique' ? PdfColors.red900 : darkGrey,
                ),
                textAlign: pw.TextAlign.center),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(el.observation ?? '',
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                textAlign: pw.TextAlign.center),
          ),
        ],
      ));
    }

    final dataTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: tableColumnWidths,
      children: dataRows,
    );

    return [
      pw.SizedBox(height: 6),
      titleTable,
      topSectionTable,
      headerTable,
      dataTable,
      pw.SizedBox(height: 5),
    ];
  }

  static pw.Widget _buildCpiTable(List<InstallationItem> cpiItems) {
    final columns = _columnOrderBySection['CPI'] ?? [
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
    final itemsToRender = cpiItems.isNotEmpty ? [cpiItems.last] : [InstallationItem(data: {})];

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FixedColumnWidth(18),
        ...{for (var i = 1; i <= dataCols.length; i++) i: const pw.FlexColumnWidth(1)},
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            _cell('N\u00B0', isHeader: true, centered: true),
            ...dataCols.map((c) => _cell(c, isHeader: true, centered: true)),
          ],
        ),
        ...itemsToRender.asMap().entries.map((e) {
          final idx = e.key;
          final item = e.value;
          final data = item.data;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: idx.isOdd ? tableRowAlt : PdfColors.white),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  '${idx + 1}',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                ),
              ),
              ...dataCols.map((key) {
                String val;
                if (key == 'RÉGIME DE NEUTRE SURVEILLÉ') {
                  val = 'IT';
                } else {
                  final raw = data[key]?.trim();
                  val = (raw != null && raw.isNotEmpty) ? raw : 'Non renseigné';
                }
                return _cell(val, isHeader: false, centered: true);
              }),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildCpiTestContent(String testResult) {
    PdfColor badgeBgColor;
    PdfColor badgeBorderColor;
    PdfColor badgeTextColor;

    switch (testResult) {
      case 'Satisfaisant':
        badgeBgColor = PdfColor.fromHex('E8F5E9');
        badgeBorderColor = PdfColor.fromHex('A5D6A7');
        badgeTextColor = PdfColor.fromHex('2E7D32');
        break;
      case 'Non satisfaisant':
        badgeBgColor = PdfColor.fromHex('FFEBEE');
        badgeBorderColor = PdfColor.fromHex('EF9A9A');
        badgeTextColor = PdfColor.fromHex('C62828');
        break;
      case 'Sans objet':
      default:
        badgeBgColor = PdfColor.fromHex('F5F5F5');
        badgeBorderColor = PdfColor.fromHex('E0E0E0');
        badgeTextColor = PdfColor.fromHex('616161');
        break;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 6),
        pw.Text(
          'ESSAI DE DÉCLENCHEMENT DU CPI',
          style: pw.TextStyle(
            font: _fontBold,
            fontSize: fsSmall,
            color: PdfColor.fromHex('1B365D'),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'L\'essai consiste à simuler, au moyen d\'une résistance calibrée, un défaut d\'isolement sur le réseau IT surveillé, et à vérifier que le Contrôleur Permanent d\'Isolement détecte ce défaut et déclenche l\'alarme (locale et/ou à distance) au seuil de réglage configuré, sans provoquer de coupure de l\'installation. L\'essai est satisfaisant si l\'alarme se déclenche au seuil attendu et si son report (local et/ou à distance) est correctement transmis.',
          style: pw.TextStyle(
            font: _fontRegular,
            fontSize: fsSmall - 0.5,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'VÉRIFICATION DU REPORT D\'ALARME',
          style: pw.TextStyle(
            font: _fontBold,
            fontSize: fsSmall,
            color: PdfColor.fromHex('1B365D'),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'Le report d\'alarme (voyant local, report GTB/GTC, ou tout autre dispositif de signalisation à distance) est contrôlé conjointement afin de s\'assurer que le personnel d\'exploitation est effectivement informé en cas de premier défaut d\'isolement, condition indispensable à la sécurité en régime IT (absence de coupure automatique au premier défaut).',
          style: pw.TextStyle(
            font: _fontRegular,
            fontSize: fsSmall - 0.5,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: pw.BoxDecoration(
            color: badgeBgColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: badgeBorderColor, width: 0.8),
          ),
          child: pw.Text(
            testResult,
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: fsSmall + 1,
              color: badgeTextColor,
            ),
          ),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildCoffret(
    CoffretArmoire coffret,
    Map<String, int> trackedPages,
    String parentName, {
    Map<dynamic, pw.MemoryImage?>? photoCache,
  }) {
    final widgets = <pw.Widget>[pw.SizedBox(height: 6)];
    String safe(String v) => v.trim().isEmpty ? 'Non renseigné' : v;
    pw.MemoryImage? photoInterne = photoCache?[coffret];
    if (photoInterne == null && photoCache == null) {
      for (final src in [...coffret.photosInternes, ...coffret.photos, ...coffret.photosExternes]) {
        final trimmed = src.trim();
        if (trimmed.isEmpty) continue;
        try {
          final resolved = AppImageUtils.resolvePathSync(trimmed);
          if (resolved != null) {
            final f = File(resolved);
            // Charger l'image uniquement si elle pèse moins de 150 Ko
            if (f.existsSync() && f.lengthSync() < 150000) {
              final bytes = f.readAsBytesSync();
              if (bytes.isNotEmpty) {
                photoInterne = pw.MemoryImage(bytes);
                break;
              }
            }
          }
        } catch (_) {}
      }
    }

    // Helper functions for characteristics
    pw.TableRow tableRowChar(String label, String value) {
      return pw.TableRow(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(label, style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(value, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall), textAlign: pw.TextAlign.center),
          ),
        ],
      );
    }

    pw.TableRow tableRowCharBool(String label, bool value) {
      final color = value ? conformeColor : nonConformeColor;
      final text = value ? 'Oui' : 'Non';
      return pw.TableRow(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(label, style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
          ),
          pw.Container(
            color: color,
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(text, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
        ],
      );
    }

    pw.TableRow tableRowThermoDefect(String label, String? state) {
      PdfColor color;
      String text;
      if (state == 'Oui') {
        color = conformeColor;
        text = 'Oui';
      } else if (state == 'Non') {
        color = nonConformeColor;
        text = 'Non';
      } else {
        color = sansObjetColor;
        text = 'Sans objet';
      }
      return pw.TableRow(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(label, style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
          ),
          pw.Container(
            color: color,
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(text, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
        ],
      );
    }

    // ══════════════════════════════════════════════════════════════════════
    // TABLEAU 1 : Titre + Caractéristiques + Photo
    // ══════════════════════════════════════════════════════════════════════
    final titleTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.4),
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.8),
        1: pw.FlexColumnWidth(6.4),
      },
      children: [
        pw.TableRow(
          children: [
            // Left cell: Number (gray background, centered, bold)
            pw.Container(
              color: PdfColor.fromInt(0xFFECECEC),
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.center,
              child: pw.Text(
                coffret.numeroEquipement?.isNotEmpty == true ? coffret.numeroEquipement! : '-',
                style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: headerColor),
                textAlign: pw.TextAlign.center,
              ),
            ),
            // Right cell: Name (white background, left-aligned, bold)
            pw.Container(
              color: PdfColors.white,
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                coffret.nom,
                style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: headerColor),
              ),
            ),
          ],
        ),
      ],
    );

    final charTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: pw.TableBorder(
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.4),
        1: pw.FlexColumnWidth(1.7),
      },
      children: [
        tableRowChar('Repère', coffret.repere?.isNotEmpty == true ? coffret.repere! : '-'),
        tableRowCharBool('Zone ATEX', coffret.zoneAtex),
        tableRowChar('Domaine de tension', safe(coffret.domaineTension)),
        tableRowCharBool("Identification de l'armoire", coffret.identificationArmoire),
        tableRowCharBool('Signalisation de danger électrique présente et visible', coffret.signalisationDanger),
        tableRowCharBool('Présence de schéma électrique', coffret.presenceSchema),
        tableRowCharBool('Présence de parafoudre', coffret.presenceParafoudre),
        tableRowCharBool('Vérification par thermographie infrarouge', coffret.verificationThermographie),
        if (coffret.verificationThermographie)
          tableRowThermoDefect('Présence de défaut thermo', coffret.effectivePresenceDefautThermo),
      ],
    );

    final topSectionTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: pw.TableBorder(
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(5.1),
        1: pw.FlexColumnWidth(3.2),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              child: charTable,
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              alignment: pw.Alignment.center,
              child: photoInterne != null
                  ? pw.Image(photoInterne, width: 140, height: 110, fit: pw.BoxFit.contain)
                  : pw.Text('Aucune photo', style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
            ),
          ],
        ),
      ],
    );

    widgets.add(pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PageTracker(
          key: 'audit_coffret_${parentName}_${coffret.nom}',
          registry: trackedPages,
          child: titleTable,
        ),
        topSectionTable,
      ],
    ));

    // ══════════════════════════════════════════════════════════════════════
    // OBSERVATIONS PARAFOUDRE
    // ══════════════════════════════════════════════════════════════════════
    if (coffret.presenceParafoudre) {
      final pfEnrichies = coffret.observationsParafoudreEnrichies ?? [];
      final pfLegacy = coffret.observationsParafoudre;
      if (pfEnrichies.isNotEmpty || pfLegacy.isNotEmpty) {
        widgets.add(pw.SizedBox(height: 4));
        widgets.add(pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFFFF3E0),
            border: pw.Border.all(color: PdfColor.fromInt(0xFFE65100), width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Observations parafoudre :',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall,
                      color: PdfColor.fromInt(0xFFE65100))),
              pw.SizedBox(height: 3),
              if (pfEnrichies.isNotEmpty)
                ...pfEnrichies.map((obs) => pw.Row(children: [
                  pw.Text('•  ', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
                  pw.Expanded(child: pw.Text(
                      '${obs.observation?.isNotEmpty == true ? obs.observation! : obs.elementControle}'
                      '${obs.priorite != null ? ' [P${obs.priorite}]' : ''}'
                      '${obs.referenceNormative?.isNotEmpty == true ? ' (${obs.referenceNormative})' : ''}',
                      style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall))),
                ]))
              else
                ...pfLegacy.map((obs) => pw.Row(children: [
                  pw.Text('•  ', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
                  pw.Expanded(child: pw.Text(obs.texte,
                      style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall))),
                ])),
            ],
          ),
        ));
      }
    }

    // ══════════════════════════════════════════════════════════════════════
    // TABLEAU 2 : Alimentations (+ Protection de tête si présente)
    // ══════════════════════════════════════════════════════════════════════
    if (coffret.alimentations.isNotEmpty || coffret.protectionTete != null) {
      widgets.add(pw.SizedBox(height: 3));
      final List<pw.Widget> tables = <pw.Widget>[];

      if (coffret.alimentations.isNotEmpty) {
        if (coffret.type == 'INVERSEUR') {
          // ══════════════════════════════════════════════════════════════════
          // INVERSEUR : 1. Tableau ORIGINE DE LA SOURCE (Alimentation 1 & 2 - MAX 2 LIGNES)
          // ══════════════════════════════════════════════════════════════════
          final entrees = coffret.alimentationsInverseurEntree;
          if (entrees.isNotEmpty) {
            final alimentRows = <pw.TableRow>[];
            alimentRows.add(pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
              children: [
                _thCell("Origine de la source d'alimentation"),
                _thCell('Type protection'),
                _thCell('Courbe'),
                _thCell('PDC (kA)'),
                _thCell('Calibre (A)'),
                _thCell('DDR (I\u0394n (mA))'),
                _thCell('Section de câble (mm\u00B2)'),
              ],
            ));

            for (int i = 0; i < entrees.length; i++) {
              final a = entrees[i];
              final label = a.source.isNotEmpty ? a.source : 'Alimentation ${i + 1}';
              alimentRows.add(pw.TableRow(children: [
                _valueCell(label),
                _valueCell(a.typeProtection),
                _valueCell(a.courbe ?? ''),
                _valueCell(a.pdcKA),
                _valueCell(a.calibre),
                _valueCell(a.ddr != null && a.ddr!.isNotEmpty ? '${a.ddr} mA' : '-'),
                _valueCell(a.sectionCable),
              ]));
            }

            tables.add(pw.Table(
              border: pw.TableBorder(
                left: pw.BorderSide(color: borderColor, width: 0.4),
                right: pw.BorderSide(color: borderColor, width: 0.4),
                bottom: pw.BorderSide(color: borderColor, width: 0.4),
                top: pw.BorderSide(color: borderColor, width: 0.4),
                verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
                horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.0),
                1: pw.FlexColumnWidth(1.4),
                2: pw.FlexColumnWidth(0.9),
                3: pw.FlexColumnWidth(0.8),
                4: pw.FlexColumnWidth(0.8),
                5: pw.FlexColumnWidth(1.3),
                6: pw.FlexColumnWidth(1.1),
              },
              children: alimentRows,
            ));
          }

          // ══════════════════════════════════════════════════════════════════
          // INVERSEUR : 2. NOUVEAU TABLEAU DÉDIÉ "SORTIE INVERSEUR" (DYNAMIQUE : 1 à N LIGNES)
          // ══════════════════════════════════════════════════════════════════
          final sorties = coffret.sortiesInverseur;
          if (sorties.isNotEmpty) {
            if (tables.isNotEmpty) {
              tables.add(pw.SizedBox(height: 3));
            }

            final sortieRows = <pw.TableRow>[];
            sortieRows.add(pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
              children: [
                _thCell('SORTIE INVERSEUR'),
                _thCell('Type protection'),
                _thCell('Courbe'),
                _thCell('PDC (kA)'),
                _thCell('Calibre (A)'),
                _thCell('DDR (I\u0394n (mA))'),
                _thCell('Section de câble (mm\u00B2)'),
              ],
            ));

            for (int i = 0; i < sorties.length; i++) {
              final s = sorties[i];
              final label = s.source.isNotEmpty
                  ? s.source
                  : (sorties.length > 1 ? 'Sortie inverseur ${i + 1}' : 'Sortie inverseur');
              sortieRows.add(pw.TableRow(children: [
                _valueCell(label),
                _valueCell(s.typeProtection),
                _valueCell(s.courbe ?? ''),
                _valueCell(s.pdcKA),
                _valueCell(s.calibre),
                _valueCell(s.ddr != null && s.ddr!.isNotEmpty ? '${s.ddr} mA' : '-'),
                _valueCell(s.sectionCable),
              ]));
            }

            tables.add(pw.Table(
              border: pw.TableBorder(
                left: pw.BorderSide(color: borderColor, width: 0.4),
                right: pw.BorderSide(color: borderColor, width: 0.4),
                bottom: pw.BorderSide(color: borderColor, width: 0.4),
                top: pw.BorderSide(color: borderColor, width: 0.4),
                verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
                horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.0),
                1: pw.FlexColumnWidth(1.4),
                2: pw.FlexColumnWidth(0.9),
                3: pw.FlexColumnWidth(0.8),
                4: pw.FlexColumnWidth(0.8),
                5: pw.FlexColumnWidth(1.3),
                6: pw.FlexColumnWidth(1.1),
              },
              children: sortieRows,
            ));
          }
        } else {
          // AUTRES ÉQUIPEMENTS (TGBT, ARMOIRE, COFFRET CLASSIQUE)
          final alimentRows = <pw.TableRow>[];

          alimentRows.add(pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
            children: [
              _thCell("Origine de la source d'alimentation"),
              _thCell('Type protection'),
              _thCell('Courbe'),
              _thCell('PDC (kA)'),
              _thCell('Calibre (A)'),
              _thCell('DDR (I\u0394n (mA))'),
              _thCell('Section de câble (mm\u00B2)'),
            ],
          ));

          for (final a in coffret.alimentations) {
            alimentRows.add(pw.TableRow(children: [
              _valueCell(a.source.isEmpty ? '-' : a.source),
              _valueCell(a.typeProtection),
              _valueCell(a.courbe ?? ''),
              _valueCell(a.pdcKA),
              _valueCell(a.calibre),
              _valueCell(a.ddr != null && a.ddr!.isNotEmpty ? '${a.ddr} mA' : '-'),
              _valueCell(a.sectionCable),
            ]));
          }

          tables.add(pw.Table(
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
            border: pw.TableBorder(
              left: pw.BorderSide(color: borderColor, width: 0.4),
              right: pw.BorderSide(color: borderColor, width: 0.4),
              bottom: pw.BorderSide(color: borderColor, width: 0.4),
              top: pw.BorderSide(color: borderColor, width: 0.4),
              verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
              horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.0),
              1: pw.FlexColumnWidth(1.4),
              2: pw.FlexColumnWidth(0.9),
              3: pw.FlexColumnWidth(0.8),
              4: pw.FlexColumnWidth(0.8),
              5: pw.FlexColumnWidth(1.3),
              6: pw.FlexColumnWidth(1.1),
            },
            children: alimentRows,
          ));
        }
      }

      if (coffret.protectionTete != null) {
        final pt = coffret.protectionTete!;
        
        // Custom rowspan table using nested table to ensure perfect align and border scaling
        final protectionTeteTable = pw.Table(
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
          border: pw.TableBorder(
            left: pw.BorderSide(color: borderColor, width: 0.4),
            right: pw.BorderSide(color: borderColor, width: 0.4),
            bottom: pw.BorderSide(color: borderColor, width: 0.4),
            top: pw.BorderSide(color: borderColor, width: 0.4),
            verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.0),
            1: pw.FlexColumnWidth(6.3),
          },
          children: [
            pw.TableRow(
              children: [
                // Left column: label (spans two rows vertically)
                pw.Container(
                  color: PdfColor.fromInt(0xFFE8F0FB),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Protection de tête de coffret\n/Armoire',
                    style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                // Right column: nested table containing type, courbe, PDC, caliber, section headers and values
                pw.Table(
                  defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
                  border: pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
                    verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1.4),
                    1: pw.FlexColumnWidth(0.9),
                    2: pw.FlexColumnWidth(0.8),
                    3: pw.FlexColumnWidth(0.8),
                    4: pw.FlexColumnWidth(1.3),
                    5: pw.FlexColumnWidth(1.1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
                      children: [
                        _thCell('Type protection'),
                        _thCell('Courbe'),
                        _thCell('PDC (kA)'),
                        _thCell('Calibre (A)'),
                        _thCell('DDR (I\u0394n (mA))'),
                        _thCell('Section de câble (mm\u00B2)'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _valueCell(pt.typeProtection),
                        _valueCell(pt.courbe ?? ''),
                        _valueCell(pt.pdcKA),
                        _valueCell(pt.calibre),
                        _valueCell(pt.ddr != null && pt.ddr!.isNotEmpty ? '${pt.ddr} mA' : '-'),
                        _valueCell(pt.sectionCable),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        if (tables.isNotEmpty) {
          tables.add(pw.SizedBox(height: 3));
        }
        tables.add(protectionTeteTable);
      }

      widgets.addAll(tables);
    }

    // ══════════════════════════════════════════════════════════════════════
    // POINTS DE VÉRIFICATION
    // ══════════════════════════════════════════════════════════════════════
    if (coffret.pointsVerification.isNotEmpty) {
      if (coffret.type == 'INVERSEUR') {
        DispositionsConstructivesRegistry.ensureCompleteInverseurChecklist(coffret.pointsVerification);
      } else {
        DispositionsConstructivesRegistry.ensureCompleteCoffretChecklist(coffret.pointsVerification);
      }
      widgets.add(pw.SizedBox(height: 3));
      widgets.add(_buildPointsVerificationTable(coffret.pointsVerification, coffretType: coffret.type));
    }

    // ══════════════════════════════════════════════════════════════════════
    // OBSERVATIONS LIBRES
    // ══════════════════════════════════════════════════════════════════════
    if (coffret.observationsLibres.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 3));
      widgets.add(_buildSimpleObsTable(coffret.observationsLibres, 'Observations'));
    }

    widgets.add(pw.SizedBox(height: 10));
    return widgets;
  }


  /// Cellule valeur (police normale)
  static pw.Widget _valueCell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    child: pw.Text(text, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
  );

  /// En-tête tableau (fond bleu clair, gras, centré)
  static pw.Widget _thCell(String text) => pw.Container(
    color: PdfColor.fromInt(0xFFE8F0FB),
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    alignment: pw.Alignment.center,
    child: pw.Text(text,
        style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
        textAlign: pw.TextAlign.center),
  );


  static pw.Widget _buildPointsVerificationTable(List<PointVerification> points, {String? coffretType}) {
    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: pw.TableBorder(
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        top: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.4), // POINTS DE VÉRIFICATION
        1: pw.FlexColumnWidth(1.2), // CONFORMITÉ
        2: pw.FlexColumnWidth(1.4), // RÉF. NORMATIVE
        3: pw.FlexColumnWidth(1.4), // FAMILLE DE RISQUE
        4: pw.FlexColumnWidth(0.9), // CRITICITÉ
        5: pw.FlexColumnWidth(1.7), // OBSERVATION
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
          children: [
            _thCell('POINTS DE VÉRIFICATION'),
            _thCell('CONFORMITÉ'),
            _thCell('RÉF. NORMATIVE'),
            _thCell('FAMILLE DE RISQUE'),
            _thCell('CRITICITÉ'),
            _thCell('OBSERVATION'),
          ],
        ),
        ...points.asMap().entries.map((e) {
          final pv = e.value;
          final conf = pv.conformite.toLowerCase().trim();
          final isConf = conf == 'oui';
          final isNA = conf == 'na' || conf == 'non_applicable' || conf == 'sans_objet' || conf == 'n/a' || conf == 'sans objet';
          final isNonConf = !isConf && !isNA;

          final confColor = isNA
              ? PdfColor.fromInt(0xFFE0E0E0)
              : (isConf ? conformeColor : nonConformeColor);
          final confText = isNA ? 'Sans objet' : (isConf ? 'Oui' : 'Non');

          final meta = DispositionsConstructivesRegistry.getCoffretMetadata(pv.pointVerification, coffretType: coffretType);
          final refNorm = isNonConf ? (meta?.referenceNormative ?? pv.referenceNormative ?? '') : '';
          final familleRisque = isNonConf ? (meta?.familleRisque ?? '') : '';
          final criticite = isNonConf ? (meta?.criticite ?? '') : '';

          final obsText = pv.observations != null && pv.observations!.isNotEmpty
              ? pv.observations!.map((obs) => obs.observation ?? '').where((s) => s.isNotEmpty).join('\n')
              : (pv.observation ?? '');

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: e.key.isEven ? PdfColors.white : tableRowAlt),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(pv.pointVerification,
                    style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
              ),
              pw.Container(
                color: confColor,
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text(confText,
                    style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                    textAlign: pw.TextAlign.center),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text(refNorm,
                    style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                    textAlign: pw.TextAlign.center),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text(familleRisque,
                    style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                    textAlign: pw.TextAlign.center),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text(criticite,
                    style: pw.TextStyle(
                        font: _fontBold,
                        fontSize: fsSmall,
                        color: criticite == 'Critique'
                            ? PdfColor.fromInt(0xFFD32F2F)
                            : (criticite == 'Majeure'
                                ? PdfColor.fromInt(0xFFE65100)
                                : PdfColors.black)),
                    textAlign: pw.TextAlign.center),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text(obsText,
                    style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                    textAlign: pw.TextAlign.center),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildSimpleObsTable(List<ObservationLibre> obs, String titre) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            _cell('N°', isHeader: true),
            _cell(titre, isHeader: true),
          ],
        ),
        ...obs.asMap().entries.map((e) => pw.TableRow(
          decoration: pw.BoxDecoration(color: e.key.isEven ? PdfColors.white : tableRowAlt),
          children: [
            _cell('${e.key + 1}', isHeader: false),
            _cell(e.value.texte, isHeader: false),
          ],
        )),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  CLASSEMENT DES EMPLACEMENTS
  // ──────────────────────────────────────────────────────────────
  
  static List<pw.Widget> _buildClassementEmplacementsMulti(
    List<ClassementEmplacement> emplacements,
    List<ClassementZone> zonesClassement,
    Map<String, int> trackedPages, {
    int offset = 0,
  }) {
    final widgets = <pw.Widget>[];

    // _sectionBox title like other sections
    widgets.add(PageTracker(
      key: 'classement',
      registry: trackedPages,
      offset: offset,
      child: _sectionBox(
        "CLASSEMENT ET EMPLACEMENTS DES LOCAUX ET ZONE EN FONCTION DES INFLUENCES EXTERNES"
      ),
    ));
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(_bodyText(
      "Dans le cas d'absence de fourniture d'une liste exhaustive des risques "
      "particuliers, le classement éventuel ci-après est proposé par le vérificateur "
      "et, sauf avis contraire, considéré comme validé par le chef d'établissement.",
    ));
    widgets.add(pw.SizedBox(height: 12));

    final rows = <_ClassementRow>[];

    for (var zone in zonesClassement) {
      rows.add(_ClassementRow(
        localisation: zone.nomZone,
        zone: '',
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
      ));
    }

    for (var emp in emplacements) {
      final dejaPresent = zonesClassement.any(
        (z) => z.nomZone == emp.localisation && emp.typeEmplacement == 'zone'
      );
      if (dejaPresent) continue;

      rows.add(_ClassementRow(
        localisation: emp.localisation,
        zone: emp.zone ?? '',
        type: emp.typeEmplacement == 'zone' ? 'Zone' : 'Local',
        origineClassement: emp.origineClassement,
        af: emp.af,
        be: emp.be,
        ae: emp.ae,
        ad: emp.ad,
        ag: emp.ag,
        ip: emp.ip,
        ik: emp.ik,
        isZone: emp.typeEmplacement == 'zone',
      ));
    }

    rows.sort((a, b) {
      if (a.isZone && !b.isZone) return -1;
      if (!a.isZone && b.isZone) return 1;
      return a.localisation.compareTo(b.localisation);
    });

    // Main header table with lightBlue decoration and headerColor texts
    final header = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.4),
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.7), // Localisation
        1: pw.FlexColumnWidth(0.8), // Zone
        2: pw.FlexColumnWidth(0.9), // Origine classement
        3: pw.FlexColumnWidth(2.4), // Influences externes (5 sub-cols)
        4: pw.FlexColumnWidth(1.4), // Indice mini (2 sub-cols)
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text('Localisation', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text('Zone', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text('Origine\nclassement', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
            ),
            // Influences externes (double level with vertical inside borders)
            pw.Column(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text('Influences externes', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
                ),
                pw.Divider(height: 0.4, color: borderColor),
                pw.Table(
                  border: pw.TableBorder(verticalInside: pw.BorderSide(color: borderColor, width: 0.4)),
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
                        pw.Text('AF', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
                        pw.Text('BE', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
                        pw.Text('AE', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
                        pw.Text('AD', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
                        pw.Text('AG', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
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
                  child: pw.Text('Indice mini de\nprotection', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
                ),
                pw.Divider(height: 0.4, color: borderColor),
                pw.Table(
                  border: pw.TableBorder(verticalInside: pw.BorderSide(color: borderColor, width: 0.4)),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(0.7),
                    1: pw.FlexColumnWidth(0.7),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text('IP', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
                        pw.Text('IK', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
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
      final rowColor = i.isOdd ? tableRowAlt : PdfColors.white;
      final zoneText = r.zone == '—' ? '' : r.zone;

      dataRows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: rowColor),
        children: [
          // Localisation (uppercase)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(r.localisation.toUpperCase(), style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
          // Zone (uppercase, empty if null/empty)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(zoneText.toUpperCase(), style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
          // Origine
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(r.origineClassement, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
          // Influences (5 colonnes plates)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(r.af ?? '', style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(r.be ?? '', style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(r.ae ?? '', style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(r.ad ?? '', style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(r.ag ?? '', style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
          // IP/IK (2 colonnes plates)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(r.ip ?? '', style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(r.ik ?? '', style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
        ],
      ));
    }

    widgets.add(pw.Table(
      border: pw.TableBorder(
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.7),  // Localisation
        1: pw.FlexColumnWidth(0.8),  // Zone
        2: pw.FlexColumnWidth(0.9),  // Origine
        3: pw.FlexColumnWidth(0.48), // AF
        4: pw.FlexColumnWidth(0.48), // BE
        5: pw.FlexColumnWidth(0.48), // AE
        6: pw.FlexColumnWidth(0.48), // AD
        7: pw.FlexColumnWidth(0.48), // AG
        8: pw.FlexColumnWidth(0.7),  // IP
        9: pw.FlexColumnWidth(0.7),  // IK
      },
      children: dataRows,
    ));

    widgets.add(pw.NewPage()); // Saut de page avant la codification
    widgets.addAll(_buildCodificationInfluencesMulti());

    return widgets;
  }

  static List<pw.Widget> _buildCodificationInfluencesMulti() {
    return [_buildCodificationInfluences()];
  }

  static pw.Widget _buildCodificationInfluences() {
    final titleTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.4),
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(7.2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.center,
              child: pw.Text(
                "CODIFICATION DES INFLUENCES EXTERNES – INDICES ET DEGRÉS DE PROTECTION",
                style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: PdfColors.white),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );

    pw.TableRow blueHeaderRow(List<String> headers) {
      return pw.TableRow(
        decoration: pw.BoxDecoration(color: lightBlue), // Matching lightBlue background
        children: headers.map((h) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          alignment: pw.Alignment.center,
          child: pw.Text(h, style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
        )).toList(),
      );
    }

    final dataTable = pw.Table(
      border: pw.TableBorder(
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        blueHeaderRow(["PÉNÉTRATION DE CORPS SOLIDES", "SUBSTANCES CORROSIVES OU POLLUANTES", "MATIÈRES TRAITÉES OU ENTREPOSÉES"]),
        _tableDataRow(["AE1 : Negligeable -> IP 2X", "AF1 : Negligeable", "BE1 : Risques negligeables"], alt: false),
        _tableDataRow(["AE2 : Petits objets (\u2265 2,5 mm) -> IP 3X", "AF2 : Agents d'origine atmospherique", "BE2 : Risques d'incendie"], alt: true),
        _tableDataRow(["AE3 : Tres petits objets (1 a 2,5 mm) -> IP 4X", "AF3 : Intermittente ou accidentelle", "BE3 : Risques d'explosion"], alt: false),
        _tableDataRow(["AE4 : Poussieres -> IP 5X (Protege)", "AF4 : Permanente", "BE4 : Risques de contamination"], alt: true),
        blueHeaderRow(["ACCÈS AUX PARTIES DANGEREUSES", "PÉNÉTRATION DE LIQUIDES", "RISQUES DE CHOCS MÉCANIQUES"]),
        _tableDataRow(["Non protege -> IP 0X", "AD1 : Negligeable -> IP X0", "AG1 : Faibles (0,225 J) -> IK 02"], alt: false),
        _tableDataRow(["A : Avec le dos de la main -> IP 1X", "AD2 : Chutes de gouttes d'eau -> IP X1", "AG2 : Moyens (2 J) -> IK 07"], alt: true),
        _tableDataRow(["B : Avec un doigt -> IP 2X", "AD3 : Chutes de gouttes jusqu'à 15\u00B0 -> IP X2", "AG3 : Importants (5 J) -> IK 08"], alt: false),
        _tableDataRow(["C : Avec un outil -> IP 3X", "AD4 : Aspersion d'eau -> IP X3", "AG4 : Tres importants (20 J) -> IK 10"], alt: true),
        _tableDataRow(["D : Avec un fil -> IP 4X", "AD5 : Projections d'eau -> IP X4", ""], alt: false),
        _tableDataRow(["", "AD6 : Jets d'eau -> IP X5", ""], alt: true),
        _tableDataRow(["", "AD7 : Paquets d'eau -> IP X6", ""], alt: false),
        _tableDataRow(["", "AD8 : Immersion -> IP X7", ""], alt: true),
        _tableDataRow(["", "AD9 : Submersion -> IP X8", ""], alt: false),
        blueHeaderRow(["COMPÉTENCE DES PERSONNES", "VIBRATIONS", ""]),
        _tableDataRow(["BA1 : Ordinaires", "AH1 : Faibles", ""], alt: false),
        _tableDataRow(["BA2 : Enfants", "AH2 : Moyennes", ""], alt: true),
        _tableDataRow(["BA3 : Personnes handicapees", "AH3 : Importantes", ""], alt: false),
        _tableDataRow(["BA4 : Personnes averties", "", ""], alt: true),
        _tableDataRow(["BA5 : Personnes qualifiees", "", ""], alt: false),
      ],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        titleTable,
        dataTable,
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  FOUDRE
  // ──────────────────────────────────────────────────────────────
  
  static List<_ParafoudreEquipementRow> _collectParafoudreRows(AuditInstallationsElectriques? audit) {
    final rows = <_ParafoudreEquipementRow>[];
    if (audit == null) return rows;

    void processCoffretList(List<CoffretArmoire> coffrets, String locName) {
      for (var c in coffrets) {
        if (c.presenceParafoudre) {
          final coffretRepere = c.repere?.isNotEmpty == true ? c.repere! : (c.numeroEquipement ?? '');
          final repStr = coffretRepere.isNotEmpty ? ' [Réf: $coffretRepere]' : '';
          final typeStr = c.type.isNotEmpty ? c.type : 'Équipement';
          final coffretTitle = '$typeStr : ${c.nom}$repStr';
          final fullLoc = '$coffretTitle ($locName)';

          final pfEnrichies = c.observationsParafoudreEnrichies ?? [];
          if (pfEnrichies.isNotEmpty) {
            for (var obs in pfEnrichies) {
              final text = obs.observation?.isNotEmpty == true
                  ? obs.observation!
                  : obs.elementControle;
              if (text.trim().isNotEmpty) {
                rows.add(_ParafoudreEquipementRow(
                  observation: text.trim(),
                  localisation: fullLoc,
                ));
              }
            }
          } else {
            for (var obs in c.observationsParafoudre) {
              if (obs.texte.trim().isNotEmpty) {
                rows.add(_ParafoudreEquipementRow(
                  observation: obs.texte.trim(),
                  localisation: fullLoc,
                ));
              }
            }
          }
        }
      }
    }

    // 1. Locaux MT
    for (var local in audit.moyenneTensionLocaux) {
      processCoffretList(local.coffrets, local.nom);
    }
    // 2. Zones MT
    for (var zone in audit.moyenneTensionZones) {
      processCoffretList(zone.coffrets, zone.nom);
      for (var local in zone.locaux) {
        processCoffretList(local.coffrets, '${zone.nom} / ${local.nom}');
      }
    }
    // 3. Zones BT
    for (var zone in audit.basseTensionZones) {
      processCoffretList(zone.coffretsDirects, zone.nom);
      for (var local in zone.locaux) {
        processCoffretList(local.coffrets, '${zone.nom} / ${local.nom}');
      }
    }

    return rows;
  }

  static pw.Widget _buildFoudre(
    AuditInstallationsElectriques? audit,
    List<Foudre> foudres,
    Map<String, int> trackedPages, {
    bool afficherTableauFoudre = false,
    int offset = 0,
  }) {
    final equipRows = _collectParafoudreRows(audit);

    pw.Widget itemBulletBold(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 3, bottom: 2),
        child: pw.Text(
          _normalizeText(text),
          style: pw.TextStyle(font: _fontBold, fontSize: fsBody, color: darkGrey),
        ),
      );
    }

    pw.Widget itemSubBullet(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(left: 6, bottom: 2),
        child: pw.Text(
          _normalizeText(text),
          style: pw.TextStyle(font: _fontRegular, fontSize: fsBody - 0.5, color: darkGrey),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeaderWidget(),
        pw.SizedBox(height: 10),
        PageTracker(
          key: 'foudre',
          registry: trackedPages,
          offset: offset,
          child: _sectionBox('FOUDRE'),
        ),
        pw.SizedBox(height: 8),

        // Tableau Statique Foudre (Affiché uniquement si le toggle est activé)
        if (afficherTableauFoudre) ...[
          pw.Table(
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
            border: pw.TableBorder.all(color: borderColor, width: 0.4),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.6),
              1: pw.FlexColumnWidth(0.9),
              2: pw.FlexColumnWidth(4.5),
            },
            children: [
              _tableHeaderRow(['Items', 'CRITICITÉ', 'Observations']),

              // Item 1
              pw.TableRow(
                children: [
                  pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('1', style: pw.TextStyle(font: _fontBold, fontSize: fsBody, color: headerColor)),
                  ),
                  pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Majeure', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColor.fromInt(0xFFE65100))),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _bodyText("- Absence d'étude technique foudre avec caractéristiques des parafoudres"),
                        _bodyText("- Mise en œuvre non conforme du conducteur de descente"),
                      ],
                    ),
                  ),
                ],
              ),

              // Item 2
              pw.TableRow(
                decoration: pw.BoxDecoration(color: tableRowAlt),
                children: [
                  pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('2', style: pw.TextStyle(font: _fontBold, fontSize: fsBody, color: headerColor)),
                  ),
                  pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Majeure', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColor.fromInt(0xFFE65100))),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _bodyText("Une installation de paratonnerre conforme et efficace, doit répondre dans un premier temps aux principes de base d'installation d'un paratonnerre."),
                        pw.SizedBox(height: 3),
                        _bodyText("Il est indispensable de réaliser :"),
                        itemBulletBold("- Une analyse risque foudre"),
                        _bodyText("L'ARF a pour objectif de définir précisément les biens à protéger ainsi que les niveaux de protection nécessaires aux installations et à l'étude technique."),
                        pw.SizedBox(height: 3),
                        _bodyText("Analyse du Risque Foudre, selon la norme NF EN 62305-2,"),
                        _bodyText("Elle intégrera les différents points suivants :"),
                        itemSubBullet("•  Estimation des risques selon la norme EN 62305-2/FD 17018"),
                        itemSubBullet("•  Définition des niveaux de protection exigés sur l'installation"),
                        itemSubBullet("•  Identification des événements redoutés dus aux effets de la foudre"),
                        itemSubBullet("•  La rédaction d'un rapport ARF (En langue Française) précisant le niveau de protection éventuelle à atteindre pour les structures et services à protéger"),
                        pw.SizedBox(height: 4),
                        itemBulletBold("- Une étude technique foudre"),
                        _bodyText("L'Etude Technique définit de façon détaillée les Installations Extérieures de Protection Foudre (IEPF) et les Installations Intérieures de Protection Foudre (IIPF) selon les normes en vigueur NF C 17 102, NF EN 62305-3 et NF EN 62305-4."),
                        pw.SizedBox(height: 3),
                        _bodyText("Elle intégrera les différents points suivants :"),
                        itemSubBullet("•  Les mesures de prévention"),
                        itemSubBullet("•  Le descriptif des équipements à installés (caractéristiques techniques)"),
                        itemSubBullet("•  Le lieu d'implantation des équipements de protection"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),
        ],

        pw.SizedBox(height: 14),

        // Sous-section : Observations par équipement
        PageTracker(
          key: 'foudre_equipements',
          registry: trackedPages,
          offset: offset,
          child: _subSectionBar("1. Observations par équipement"),
        ),
        pw.SizedBox(height: 6),

        if (equipRows.isEmpty)
          _bodyText('Aucune observation parafoudre par équipement disponible.')
        else
          pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.4),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.6),
              1: pw.FlexColumnWidth(3.4),
              2: pw.FlexColumnWidth(2.0),
            },
            children: [
              _tableHeaderRow(['Item', 'Observation', 'Localisation']),
              ...equipRows.asMap().entries.map((e) {
                final idx = e.key + 1;
                final row = e.value;
                final bg = e.key.isOdd ? tableRowAlt : PdfColors.white;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _cell('$idx', isHeader: false, centered: true),
                    _cell(row.observation, isHeader: false),
                    _cell(row.localisation, isHeader: false),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  RESULTATS DES MESURES ET ESSAIS
  // ──────────────────────────────────────────────────────────────
  
  static void _addMesuresEssaisPages(
    pw.Document pdf,
    MesuresEssais mesures,
    Map<String, int> trackedPages, {
    int pageOffset = 0,
    int? overrideTotalPages,
    DescriptionInstallations? desc,
  }) {
    // Page intro avec conditions ET les deux essais
    pdf.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(pageOffset: pageOffset, overrideTotalPages: overrideTotalPages),
      header: (ctx) => _buildPageHeaderWidget(),
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
            child: _subSectionBar("1. Conditions de mesure"),
          ),
          pw.SizedBox(height: 6),
          
          _bodyText("Les mesures et essais sont réalisés conformément aux conditions de mesure, aux méthodes d’essai et aux critères d’acceptation définis ci-après."),
          pw.SizedBox(height: 4),

          // 1. Mesure de la résistance d'isolement
          _buildBlueBoxBanner("Mesure de la résistance d’isolement"),
          _para([
            const pw.TextSpan(text: "Les mesures de résistance d’isolement par rapport à la terre sont réalisées sous une "),
            pw.TextSpan(text: "tension continue de 500 V", style: pw.TextStyle(font: _fontBold)),
            const pw.TextSpan(text: "."),
          ]),
          _para([
            const pw.TextSpan(text: "La valeur mesurée est considérée comme "),
            pw.TextSpan(text: "satisfaisante lorsqu’elle est supérieure à 0,5 MΩ", style: pw.TextStyle(font: _fontBold)),
            const pw.TextSpan(text: "."),
          ]),

          // 2. Vérification de la continuité et de la résistance des conducteurs de protection
          _buildBlueBoxBanner("Vérification de la continuité et de la résistance des conducteurs de protection"),
          _bodyText("La continuité et la résistance des conducteurs de protection (PE) sont vérifiées afin de s’assurer de leur capacité à assurer efficacement la protection des personnes en cas de défaut d’isolement."),
          _para([
            const pw.TextSpan(text: "Le résultat est considéré comme "),
            pw.TextSpan(
              text: "conforme lorsque les valeurs mesurées satisfont aux prescriptions du guide UTE C 15-105, notamment celles relatives à la continuité des conducteurs de protection",
              style: pw.TextStyle(font: _fontBold),
            ),
            const pw.TextSpan(text: "."),
          ]),

          // 3. Essai de déclenchement des dispositifs différentiels résiduels (DDR)
          _buildBlueBoxBanner("Essai de déclenchement des dispositifs différentiels résiduels (DDR)"),
          _bodyText("Les essais de déclenchement permettent de vérifier le bon fonctionnement des dispositifs différentiels résiduels ainsi que leur seuil effectif de déclenchement."),
          _para([
            const pw.TextSpan(text: "Le seuil de déclenchement est considéré comme "),
            pw.TextSpan(
              text: "satisfaisant lorsque la valeur mesurée est comprise entre 0,5 IΔn et IΔn, où IΔn",
              style: pw.TextStyle(font: _fontBold),
            ),
            const pw.TextSpan(text: " représente le courant différentiel résiduel assigné du dispositif."),
          ]),
          _bodyText("Les essais permettent également de vérifier le comportement du dispositif dans les conditions prévues de fonctionnement."),

          // 4. Mesure des impédances de boucle – Protection contre les contacts indirects
          _buildBlueBoxBanner("Mesure des impédances de boucle – Protection contre les contacts indirects"),
          _bodyText("La mesure de l’impédance de boucle permet de vérifier l’efficacité du dispositif de protection contre les contacts indirects."),
          _bodyText("Elle permet notamment de déterminer le courant de défaut susceptible de circuler en cas de défaut d’isolement et de vérifier que le dispositif de protection est susceptible de provoquer la coupure du circuit dans le temps requis."),
          _para([
            const pw.TextSpan(text: "Le résultat est considéré comme "),
            pw.TextSpan(
              text: "conforme lorsque les conditions de coupure correspondant au courant de défaut déterminé satisfont aux prescriptions du référentiel applicable, notamment celles du guide UTE C 15-105 lorsque celui-ci est retenu comme référentiel de vérification",
              style: pw.TextStyle(font: _fontBold),
            ),
            const pw.TextSpan(text: "."),
          ]),

          // 5. Mesure de la résistance des prises de terre
          _buildBlueBoxBanner("Mesure de la résistance des prises de terre"),
          _bodyText("La mesure de la résistance des prises de terre est réalisée afin de vérifier l’efficacité du système de mise à la terre et son aptitude à contribuer à la protection des personnes et au fonctionnement des dispositifs de protection."),
          _para([
            const pw.TextSpan(text: "Avant toute mesure, "),
            pw.TextSpan(
              text: "la position de la barrette principale de terre ou de la barrette de coupure est vérifiée et mentionnée dans le rapport",
              style: pw.TextStyle(font: _fontBold),
            ),
            const pw.TextSpan(text: "."),
          ]),
          _bodyText("La mesure peut être réalisée selon deux méthodes principales :"),
          pw.SizedBox(height: 2),

          _subMethodHeader("Méthode des trois piquets – Barrette ouverte"),
          _para([
            const pw.TextSpan(text: "La méthode des trois piquets est réalisée avec la "),
            pw.TextSpan(text: "barrette de terre ouverte", style: pw.TextStyle(font: _fontBold)),
            const pw.TextSpan(text: ", lorsque la configuration de l'installation permet d'isoler la prise de terre à meuser."),
          ]),
          _bodyText("Elle utilise :"),
          _bulletPoint("La prise de terre à mesurer ;"),
          _bulletPoint("Un piquet auxiliaire de courant ;"),
          _bulletPoint("Un piquet auxiliaire de potentiel."),
          _bodyText("Cette méthode permet de mesurer la résistance de la prise de terre selon le principe de la chute de potentiel."),
          pw.SizedBox(height: 3),

          _bodyBold("Position de la barrette lors de la mesure :"),
          pw.SizedBox(height: 3),
          _checkboxRow("Barrette ouverte"),
          _checkboxRow("Barrette fermée"),
          pw.SizedBox(height: 3),
          _bodyText("Lorsque la barrette est ouverte, il convient de s'assurer que les conditions de sécurité sont maîtrisées et que la coupure temporaire de la liaison de terre ne met pas les personnes ou les équipements en danger."),
          pw.SizedBox(height: 4),

          _subMethodHeader("Méthode à la pince de terre – Barrette fermée"),
          _bodyText("La mesure à la pince de terre peut être utilisée lorsque la configuration de l'installation permet ce type de mesure et qu'il n'est pas possible ou souhaitable d'implanter des piquets auxiliaires."),
          _bodyText("Cette méthode est particulièrement adaptée aux sites :"),
          _bulletPoint("Fortement bétonnés ou asphaltés ;"),
          _bulletPoint("Industriels ;"),
          _bulletPoint("Présentant des contraintes d'accès ;"),
          _bulletPoint("Dans lesquels l'implantation de piquets est difficile ;"),
          _bulletPoint("Où l'interruption du réseau de terre n'est pas souhaitable."),
          pw.SizedBox(height: 3),
          _para([
            const pw.TextSpan(text: "Dans ce cas, la mesure est généralement réalisée "),
            pw.TextSpan(text: "barrette fermée", style: pw.TextStyle(font: _fontBold)),
            const pw.TextSpan(text: ", afin de conserver le réseau de terre dans sa configuration normale de fonctionnement."),
          ]),
          
          pw.SizedBox(height: 16),
          
          // Essais de démarrage automatique (sur la même page)
          PageTracker(
            key: 'mesures_demarrage',
            registry: trackedPages,
            offset: pageOffset,
            child: _subSectionBar('2. Essais de démarrage automatique du groupe électrogène'),
          ),
          pw.SizedBox(height: 5),
          _resultBox(mesures.essaiDemarrageAuto.observation ?? 'Non satisfaisant'),
          
          pw.SizedBox(height: 16),
          
          // Test de l'arret d'urgence (sur la même page)
          PageTracker(
            key: 'mesures_arret',
            registry: trackedPages,
            offset: pageOffset,
            child: _subSectionBar("3. Test de fonctionnement de l'arrêt d'urgence"),
          ),
          pw.SizedBox(height: 5),
          _resultBox(mesures.testArretUrgence.observation ?? 'Satisfaisant'),
      ],
    ));
    
    // Prise de terre (nouvelle page)
    pdf.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(pageOffset: pageOffset, overrideTotalPages: overrideTotalPages),
      header: (ctx) => _buildPageHeaderWidget(),
      build: (ctx) => [
        PageTracker(
          key: 'mesures_terre',
          registry: trackedPages,
          offset: pageOffset,
          child: _subSectionBar('4. Prise de terre'),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
          border: pw.TableBorder.all(color: borderColor, width: 0.4),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.2), // Localisation
            1: pw.FlexColumnWidth(1.6), // Identification de la prise de terre
            2: pw.FlexColumnWidth(1.2), // Condition de mesure
            3: pw.FlexColumnWidth(1.4), // Nature de la prise de terre
            4: pw.FlexColumnWidth(1.2), // Méthode de mesure
            5: pw.FlexColumnWidth(0.8), // Valeur de la mesure
            6: pw.FlexColumnWidth(1.4), // Observation
          },
          children: [
            _tableHeaderRow([
              'Localisation',
              'Identification de la prise de terre',
              'Condition de mesure',
              'Nature de la prise de terre',
              'Méthode de mesure',
              'Valeur de la mesure',
              'Observation'
            ]),
            if (mesures.prisesTerre.isEmpty)
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.white),
                children: List.generate(7, (_) => _cell('', isHeader: false, centered: true)),
              )
            else
              ...mesures.prisesTerre.asMap().entries.map((e) {
                final pt = e.value;
                final obs = pt.observation ?? '';
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: e.key.isOdd ? tableRowAlt : PdfColors.white),
                  children: [
                    _cell(pt.localisation, isHeader: false, centered: true),
                    _cell(pt.identification, isHeader: false, centered: true),
                    _cell(pt.conditionPriseTerre, isHeader: false, centered: true),
                    _cell(pt.naturePriseTerre, isHeader: false, centered: true),
                    _cell(pt.methodeMesure, isHeader: false, centered: true),
                    _cell(pt.valeurMesure?.toStringAsFixed(2) ?? '-', isHeader: false, centered: true),
                    _cell(obs.isEmpty ? '-' : obs, isHeader: false, centered: true),
                  ],
                );
              }),
          ],
        ),
        if (mesures.avisMesuresTerre.observation != null && mesures.avisMesuresTerre.observation!.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border.all(color: borderColor, width: 0.4),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '4.1. Avis sur les mesures',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall + 0.5, color: headerColor),
                ),
                pw.SizedBox(height: 6),
                ...mesures.avisMesuresTerre.observation!.split('\n').map((line) {
                  if (line.trim().isEmpty) return pw.SizedBox();
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 4, bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 4,
                          height: 4,
                          margin: const pw.EdgeInsets.only(top: 4, right: 6),
                          decoration: pw.BoxDecoration(color: accentColor, shape: pw.BoxShape.circle),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            line.trim(),
                            style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall, color: darkGrey),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    ));

    
    // Essais de declenchement des DDR (nouvelle page)
    pdf.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(pageOffset: pageOffset, overrideTotalPages: overrideTotalPages),
      header: (ctx) => _buildPageHeaderWidget(),
      build: (ctx) {
        final widgets = <pw.Widget>[];

        widgets.add(PageTracker(
          key: 'mesures_ddr',
          registry: trackedPages,
          offset: pageOffset,
          child: _subSectionBar("5. Essais de déclenchement des dispositifs différentiels"),
        ));
        widgets.add(pw.SizedBox(height: 8));

        // 1. Table Header of DDR table
        final headerTable = pw.Table(
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
          border: pw.TableBorder(
            top: pw.BorderSide(color: borderColor, width: 0.4),
            left: pw.BorderSide(color: borderColor, width: 0.4),
            right: pw.BorderSide(color: borderColor, width: 0.4),
            bottom: pw.BorderSide(color: borderColor, width: 0.4),
            verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.8), // LOCALISATION
            1: pw.FlexColumnWidth(2.6), // Désignation circuit
            2: pw.FlexColumnWidth(1.4), // Type dispositif
            3: pw.FlexColumnWidth(2.2), // Réglage (divided into IAn and Tempo)
            4: pw.FlexColumnWidth(1.2), // Essai
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: accentColor),
              children: [
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: pw.Text("LOCALISATION", style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
                ),
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: pw.Text("Désignation circuit", style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
                ),
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: pw.Text("Type de dispositif", style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
                ),
                // Réglage (double level with vertical inside borders)
                pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Text("Réglage", style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
                    ),
                    pw.Divider(height: 0.4, color: borderColor),
                    pw.Table(
                      border: pw.TableBorder(verticalInside: pw.BorderSide(color: borderColor, width: 0.4)),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(1.1),
                        1: pw.FlexColumnWidth(1.1),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Text("I\u0394n (mA)", style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
                            pw.Text("Tempo (s)", style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: pw.Text("Essai", style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white), textAlign: pw.TextAlign.center),
                ),
              ],
            ),
          ],
        );

        widgets.add(headerTable);

        final ddrRows = <pw.TableRow>[];
        if (mesures.essaisDeclenchement.isEmpty) {
          ddrRows.add(pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.white),
            children: List.generate(6, (_) => _cell('', isHeader: false, centered: true)),
          ));
        } else {
          int altIdx = 0;
          for (final es in mesures.essaisDeclenchement) {
            altIdx++;
            final rowBg = altIdx.isOdd ? tableRowAlt : PdfColors.white;
            final essaiColor = es.essai == "B" || es.essai == "OK" ? conformeColor : (es.essai == "M" || es.essai == "NON OK" ? nonConformeColor : null);
            final circuitText = (es.designationCircuit != null && es.designationCircuit!.isNotEmpty)
                ? es.designationCircuit!
                : es.coffret ?? "";
            final localText = es.localisation.trim().isEmpty ? "-" : es.localisation.trim();

            ddrRows.add(pw.TableRow(
              decoration: pw.BoxDecoration(color: rowBg),
              children: [
                _cell(localText, isHeader: false, centered: true),
                _cell(circuitText, isHeader: false, centered: true),
                _cell(es.typeDispositif, isHeader: false, centered: true),
                _cell(es.reglageIAn?.toString() ?? "-", isHeader: false, centered: true),
                _cell(es.tempo?.toString() ?? "-", isHeader: false, centered: true),
                pw.Container(
                  color: essaiColor,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text(es.essai, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall), textAlign: pw.TextAlign.center),
                ),
              ],
            ));
          }
        }

        widgets.add(pw.Table(
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
          border: pw.TableBorder(
            left: pw.BorderSide(color: borderColor, width: 0.4),
            right: pw.BorderSide(color: borderColor, width: 0.4),
            bottom: pw.BorderSide(color: borderColor, width: 0.4),
            verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
            horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.8), // LOCALISATION
            1: pw.FlexColumnWidth(2.6), // Désignation circuit
            2: pw.FlexColumnWidth(1.4), // Type dispositif
            3: pw.FlexColumnWidth(1.1), // IAn
            4: pw.FlexColumnWidth(1.1), // Tempo
            5: pw.FlexColumnWidth(1.2), // Essai
          },
          children: ddrRows,
        ));

        widgets.add(pw.SizedBox(height: 12));
        widgets.add(_buildAbreviationsTable());

        return widgets;
      },
    ));

    // 6. Essais de mesure d'isolement (nouvelle page)
    pdf.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(pageOffset: pageOffset, overrideTotalPages: overrideTotalPages),
      header: (ctx) => _buildPageHeaderWidget(),
      build: (ctx) => [
        PageTracker(
          key: 'mesures_isolement',
          registry: trackedPages,
          offset: pageOffset,
          child: _subSectionBar("6. Essais de mesure d'isolement entre deux points d'un tronçon de câble"),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
          border: pw.TableBorder.all(color: borderColor, width: 0.4),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.0), // Repère du point d'origine
            1: pw.FlexColumnWidth(2.2), // Point A (origine)
            2: pw.FlexColumnWidth(2.2), // Point B (extrémité)
            3: pw.FlexColumnWidth(1.6), // Section du câble (mm²)
            4: pw.FlexColumnWidth(1.6), // Nombre de câbles testés
            5: pw.FlexColumnWidth(1.6), // Isolement (MΩ)
            6: pw.FlexColumnWidth(1.8), // Appréciation
          },
          children: [
            _tableHeaderRow([
              'Repère du point d\'origine',
              'Point A (origine)',
              'Point B (extrémité)',
              'Section du câble (mm²)',
              'Nombre de câble testée',
              'Isolement(MΩ)',
              'Appréciation',
            ]),
            if (mesures.essaisIsolement.isEmpty)
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.white),
                children: List.generate(7, (_) => _cell('', isHeader: false, centered: true)),
              )
            else
              ...mesures.essaisIsolement.asMap().entries.map((e) {
                final ei = e.value;
                final app = ei.appreciation;
                final isSat = app == 'Satisfaisant';
                final isNonSat = app == 'Non satisfaisant';
                final appBgColor = isSat
                    ? conformeColor
                    : (isNonSat ? nonConformeColor : PdfColor.fromInt(0xFFEEEEEE));

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: e.key.isOdd ? tableRowAlt : PdfColors.white),
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(ei.displayRepereOrigine, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall), textAlign: pw.TextAlign.center),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(ei.displayPointA, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall), textAlign: pw.TextAlign.center),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(ei.displayPointB, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall), textAlign: pw.TextAlign.center),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(ei.displaySection, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall), textAlign: pw.TextAlign.center),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(ei.displayNombreCables, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall), textAlign: pw.TextAlign.center),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text('${ei.isolement}', style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall), textAlign: pw.TextAlign.center),
                    ),
                    pw.Container(
                      color: appBgColor,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        app,
                        style: pw.TextStyle(
                          font: _fontBold,
                          fontSize: fsSmall,
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
      ],
    ));
    
    // 7. Test du CPI (nouvelle page)
    final cpiTestResult = desc != null && desc.cpi.isNotEmpty
        ? (desc.cpi.last.data['RESULTAT_TEST'] ?? 'Sans objet')
        : 'Sans objet';

    pdf.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(pageOffset: pageOffset, overrideTotalPages: overrideTotalPages),
      header: (ctx) => _buildPageHeaderWidget(),
      build: (ctx) => [
        PageTracker(
          key: 'mesures_cpi',
          registry: trackedPages,
          offset: pageOffset,
          child: _subSectionBar("7. Test du Contrôleur Permanent d'Isolement (CPI)"),
        ),
        pw.SizedBox(height: 8),
        _buildCpiTestContent(cpiTestResult),
      ],
    ));

    // 8. Continuite (nouvelle page)
    pdf.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(pageOffset: pageOffset, overrideTotalPages: overrideTotalPages),
      header: (ctx) => _buildPageHeaderWidget(),
      build: (ctx) => [
        PageTracker(
          key: 'mesures_continuite',
          registry: trackedPages,
          offset: pageOffset,
          child: _subSectionBar('8. Continuité et de la résistance des conducteurs de protection et des liaisons équipotentielles'),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
          border: pw.TableBorder.all(color: borderColor, width: 0.4),
          columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(2.5), 2: pw.FlexColumnWidth(1.5), 3: pw.FlexColumnWidth(2)},
          children: [
            _tableHeaderRow(['Localisation', 'Désignation Tableau / Equipement', 'Origine Mésure', 'Observation']),
            if (mesures.continuiteResistances.isEmpty)
              _tableDataRow(['', '', '', ''], alt: false, centered: true)
            else
              ...mesures.continuiteResistances.asMap().entries.map((e) {
                final c = e.value;
                return _tableDataRow([c.localisation, c.designationTableau, c.origineMesure, c.observation ?? ''], alt: e.key.isOdd, centered: true);
              }),
          ],
        ),
      ],
    ));
  }

  // Page "INTERVENANTS ET RESPONSABILITÉS"
  static pw.Widget _buildIntervenantsEtResponsabilitesPage(
    JSA? jsa,
    RenseignementsGeneraux? rg,
    dynamic currentUser,
    Map<String, int> trackedPages,
    int pageOffset,
  ) {
    final List<String> inspecteursNoms = [];
    if (jsa != null && jsa.inspecteurs.isNotEmpty) {
      for (final insp in jsa.inspecteurs) {
        final fullName = '${insp.prenom} ${insp.nom}'.trim();
        if (fullName.isNotEmpty &&
            !inspecteursNoms.any((existing) =>
                JSAUtils.normalizeInspectorName(existing) == JSAUtils.normalizeInspectorName(fullName))) {
          inspecteursNoms.add(fullName);
        }
      }
    }

    if (inspecteursNoms.isEmpty) {
      final userFullName = currentUser != null && currentUser.fullName != null
          ? currentUser.fullName.toString().trim()
          : '';
      if (userFullName.isNotEmpty) {
        inspecteursNoms.add(userFullName);
      } else if (rg != null && rg.verificateurs.isNotEmpty) {
        for (final v in rg.verificateurs) {
          final nom = '${v['prenom'] ?? ''} ${v['nom'] ?? ''}'.trim();
          if (nom.isNotEmpty) inspecteursNoms.add(nom);
        }
      }
      if (inspecteursNoms.isEmpty) {
        inspecteursNoms.add('Inspecteur non renseigné');
      }
    }

    pw.Widget buildBulletList(List<String> list, {required String trackerKey}) {
      return PageTracker(
        key: trackerKey,
        registry: trackedPages,
        offset: pageOffset,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: list.map((name) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Container(
                    width: 3.5,
                    height: 3.5,
                    margin: const pw.EdgeInsets.only(right: 5),
                    decoration: pw.BoxDecoration(color: headerColor),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      name,
                      style: pw.TextStyle(font: _fontBold, fontSize: fsBody, color: darkGrey),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    pw.Widget buildHeaderCell(String text) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        alignment: pw.Alignment.center,
        child: pw.Text(
          text,
          style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.white),
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    pw.Widget buildRowHeaderCell(String text) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        alignment: pw.Alignment.center,
        child: pw.Text(
          text,
          style: pw.TextStyle(font: _fontBold, fontSize: fsBody, color: headerColor),
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    final table = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(2.15),
        2: pw.FlexColumnWidth(2.15),
        3: pw.FlexColumnWidth(2.15),
        4: pw.FlexColumnWidth(2.15),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            pw.Container(),
            buildHeaderCell("INSPECTION\nRÉALISÉE PAR"),
            buildHeaderCell("RAPPORT\nRÉDIGÉ PAR"),
            buildHeaderCell("RAPPORT\nVÉRIFIÉ PAR"),
            buildHeaderCell("RAPPORT\nVALIDÉ PAR"),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            pw.Container(
              decoration: pw.BoxDecoration(color: lightBlue),
              padding: const pw.EdgeInsets.all(6),
              alignment: pw.Alignment.center,
              child: buildRowHeaderCell("NOM"),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: buildBulletList(inspecteursNoms, trackerKey: 'intervenants_inspection'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: buildBulletList(inspecteursNoms, trackerKey: 'intervenants_redaction'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: buildBulletList(['Lucien BOYOMO', 'Patrick ESSAME'], trackerKey: 'intervenants_verification'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: buildBulletList(['Patrick ESSAME'], trackerKey: 'intervenants_validation'),
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            pw.Container(
              decoration: pw.BoxDecoration(color: lightBlue),
              padding: const pw.EdgeInsets.symmetric(vertical: 12),
              alignment: pw.Alignment.center,
              child: buildRowHeaderCell("Date"),
            ),
            pw.Container(height: 35),
            pw.Container(height: 35),
            pw.Container(height: 35),
            pw.Container(height: 35),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            pw.Container(
              decoration: pw.BoxDecoration(color: lightBlue),
              padding: const pw.EdgeInsets.symmetric(vertical: 30),
              alignment: pw.Alignment.center,
              child: buildRowHeaderCell("Signature"),
            ),
            pw.Container(height: 75),
            pw.Container(height: 75),
            pw.Container(height: 75),
            pw.Container(height: 75),
          ],
        ),
      ],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PageTracker(
          key: 'intervenants',
          registry: trackedPages,
          offset: pageOffset,
          child: _sectionBox('INTERVENANTS ET RESPONSABILITÉS'),
        ),
        pw.SizedBox(height: 14),
        table,
      ],
    );
  }

  // Page signature "LA DIRECTION"
  static pw.Widget _buildSignaturePage(
    RenseignementsGeneraux? rg,
    String? nomInspecteur,
    Map<String, int> trackedPages,
    int pageOffset,
  ) {
    return pw.Column(
      children: [
        _buildPageHeaderWidget(),
        pw.Expanded(
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                PageTracker(
                  key: 'signature_rapport',
                  registry: trackedPages,
                  offset: pageOffset,
                  child: pw.Text(
                    'LA DIRECTION',
                    style: pw.TextStyle(
                      font: _fontBold,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: headerColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Patrick ESSAME ESSAME',
                  style: pw.TextStyle(
                    font: _fontBold,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: headerColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                
                pw.SizedBox(height: 40),
                pw.Text(
                  'Fait \u00E0 Douala le ${_formatDate(DateTime.now())}',
                  style: pw.TextStyle(
                    font: _fontBold,
                    fontSize: 14,
                    color: darkGrey,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                
                pw.SizedBox(height: 25),
                pw.Container(
                  width: 200, height: 1, color: PdfColors.grey400,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Signature et cachet',
                  style: pw.TextStyle(
                    font: _fontRegular, fontSize: 8, color: PdfColors.grey500,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _resultBox(String text) {
    final isOk = text.toLowerCase().contains('satisfaisant') && !text.toLowerCase().contains('non');
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: isOk ? conformeColor : nonConformeColor,
        border: pw.Border.all(color: borderColor, width: 0.4),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Text(text, style: pw.TextStyle(fontSize: fsBody)),
    );
  }

  static pw.Widget _buildAbreviationsTable() {
    final titleTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.4),
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.0),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.center,
              child: pw.Text(
                "Signification des abréviations utilisées",
                style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: PdfColors.white),
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
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            _cell("Abréviation", isHeader: true, centered: true, color: headerColor),
            _cell("Signification", isHeader: true, centered: true, color: headerColor),
          ],
        ),
        _tableDataRow(["DDR", "Disjoncteur Différentiel"], alt: false, centered: true),
        _tableDataRow(["RD", "Relais Différentiel"], alt: true, centered: true),
        _tableDataRow(["B", "Bon fonctionnement"], alt: false, centered: true),
        _tableDataRow(["NE", "Non essayé"], alt: true, centered: true),
        _tableDataRow(["IDR", "Interrupteur Différentiel"], alt: false, centered: true),
        _tableDataRow(["I\u0394n", "Intensité différentielle"], alt: true, centered: true),
        _tableDataRow(["M", "Fonctionnement incorrect"], alt: false, centered: true),
        _tableDataRow(["Tempo", "Temporisation"], alt: true, centered: true),
      ],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        titleTable,
        dataTable,
      ],
    );
  }

  static final pw.MemoryImage _placeholder1x1 = pw.MemoryImage(
    Uint8List.fromList(<int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
    ]),
  );

  static Future<pw.MemoryImage?> loadAndOptimizeImage(
    String path, {
    PdfPhotoContext photoContext = PdfPhotoContext.equipmentObs,
    int? maxWidth,
    int? maxHeight,
    int? quality,
    bool saveFilesToDisk = true,
  }) =>
      _loadAndOptimizeImage(
        path,
        photoContext: photoContext,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
        saveFilesToDisk: saveFilesToDisk,
      );

  static Future<pw.MemoryImage?> _loadAndOptimizeImage(
    String path, {
    PdfPhotoContext photoContext = PdfPhotoContext.equipmentObs,
    int? maxWidth,
    int? maxHeight,
    int? quality,
    bool saveFilesToDisk = true,
  }) async {
    // ── Passe 1 (Pagination) : Utilisation du Placeholder 1x1 ultra-rapide (Zero-Load) ──
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

      // ── Cache Disque de la Photo Optimisée (Évite les décodages Skia natifs répétés) ──
      final tempDir = await getTemporaryDirectory();
      final cacheFileName = 'img_cache_${resolvedPath.hashCode}_${targetWidth}_${targetHeight}_$targetQuality.jpg';
      final cacheFile = File('${tempDir.path}/$cacheFileName');

      if (await cacheFile.exists()) {
        try {
          final cachedBytes = await cacheFile.readAsBytes();
          if (cachedBytes.isNotEmpty) {
            return pw.MemoryImage(cachedBytes);
          }
        } catch (_) {}
      }

      try {
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: targetWidth,
          minHeight: targetHeight,
          quality: targetQuality,
          format: CompressFormat.jpeg,
        ).timeout(const Duration(seconds: 2));
        if (compressedBytes != null && compressedBytes.isNotEmpty) {
          try {
            await cacheFile.writeAsBytes(compressedBytes);
          } catch (_) {}
          return pw.MemoryImage(compressedBytes);
        }
      } catch (_) {}

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  static Future<_ChunkSectionResult> _addPhotosSectionChunked(
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
  }) async {
    final chunkFiles = <File>[];
    final tempDir = await getTemporaryDirectory();
    int currentOffset = pageOffset;
    final generalPhotos = <_PhotoEntry>[];
    final equipmentGroups = <_EquipmentPhotoGroup>[];
    final seenPaths = <String>{};

    void addGeneralPhotos(
      List<String>? paths,
      String desc, {
      String? repere,
      bool isObservation = false,
      String? badgeLabel,
      PdfColor? badgeBgColor,
      PdfColor? badgeTextColor,
    }) {
      if (paths == null || paths.isEmpty) return;
      for (var p in paths) {
        final trimmed = p.trim();
        if (trimmed.isEmpty) continue;
        if (!seenPaths.contains(trimmed)) {
          seenPaths.add(trimmed);
          generalPhotos.add(_PhotoEntry(
            filePath: trimmed,
            description: desc,
            repere: repere,
            isObservation: isObservation,
            badgeLabel: badgeLabel ?? (isObservation ? 'ANOMALIE' : null),
            badgeBgColor: badgeBgColor ?? (isObservation ? PdfColors.white : null),
            badgeTextColor: badgeTextColor ?? (isObservation ? PdfColors.red700 : null),
          ));
        }
      }
    }

    _EquipmentPhotoGroup processCoffret(CoffretArmoire c, String prefix) {
      final repVal = c.repere?.isNotEmpty == true ? c.repere : c.numeroEquipement;
      final typeTitle = c.type.isNotEmpty ? c.type.toUpperCase() : 'ÉQUIPEMENT';

      // 1. Photo Extérieure
      String? extPath = c.photosExternes.isNotEmpty
          ? c.photosExternes.first
          : (c.photos.isNotEmpty ? c.photos.first : null);
      _PhotoEntry? extEntry;
      if (extPath != null && extPath.trim().isNotEmpty && !seenPaths.contains(extPath.trim())) {
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
      if (intPath != null && intPath.trim().isNotEmpty && !seenPaths.contains(intPath.trim())) {
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
            obsEntries.add(_PhotoEntry(
              filePath: t,
              description: desc,
              repere: repVal,
              isObservation: true,
              badgeLabel: 'ANOMALIE',
              badgeBgColor: PdfColors.white,
              badgeTextColor: PdfColors.red700,
            ));
          }
        }
      }

      for (var pv in c.pointsVerification) {
        addObsPhoto(pv.photos, '$prefix - $typeTitle : ${c.nom} - Point : ${pv.pointVerification}');
      }
      for (var obs in c.observationsLibres) {
        addObsPhoto(obs.photos, '$prefix - $typeTitle : ${c.nom} - Obs libre : ${obs.texte}');
      }
      final pfEnrichies = c.observationsParafoudreEnrichies ?? [];
      for (var obs in pfEnrichies) {
        addObsPhoto(obs.photos, '$prefix - $typeTitle : ${c.nom} - Parafoudre : ${obs.elementControle}');
      }

      return _EquipmentPhotoGroup(
        coffret: c,
        locationPrefix: prefix,
        extPhoto: extEntry,
        intPhoto: intEntry,
        obsPhotos: obsEntries,
      );
    }

    // Palette des badges par catégorie d'élément
    final localBadgeColor = PdfColor.fromInt(0xFF0F766E); // Deep Teal
    final zoneBadgeColor = PdfColor.fromInt(0xFF4338CA);  // Dark Indigo
    final celluleBadgeColor = PdfColor.fromInt(0xFF0369A1); // Sky/Cyan Blue

    // 1. Photos Description des installations
    if (description != null) {
      void addItems(List<InstallationItem>? items, String categoryLabel) {
        if (items == null) return;
        for (var item in items) {
          final nomItem = item.data['nom'] ?? item.data['Nom'] ?? (item.data.isNotEmpty ? item.data.values.first : '');
          addGeneralPhotos(
            item.photoPaths,
            'Description - $categoryLabel${nomItem.isNotEmpty ? ' : $nomItem' : ''}',
            badgeLabel: 'DESCRIPTION',
            badgeBgColor: PdfColor.fromInt(0xFF1E3A8A),
            badgeTextColor: PdfColors.white,
          );
        }
      }
      addItems(description.alimentationMoyenneTension, 'Alimentation MT');
      addItems(description.alimentationBasseTension, 'Alimentation BT');
      addItems(description.groupeElectrogene, 'Groupe Électrogène');
      addItems(description.alimentationCarburant, 'Alimentation Carburant');
      addItems(description.inverseur, 'Inverseur');
      addItems(description.stabilisateur, 'Stabilisateur');
      addItems(description.onduleurs, 'Onduleurs');
    }

    // 2. Photos Audit des installations électriques
    if (audit != null) {
      addGeneralPhotos(
        audit.photos,
        "Général Audit",
        badgeLabel: 'AUDIT',
        badgeBgColor: PdfColor.fromInt(0xFF1E3A8A),
        badgeTextColor: PdfColors.white,
      );
      
      // Moyenne Tension Locaux
      for (var local in audit.moyenneTensionLocaux) {
        addGeneralPhotos(
          local.photos,
          'Local : ${local.nom}',
          badgeLabel: 'LOCAL',
          badgeBgColor: localBadgeColor,
          badgeTextColor: PdfColors.white,
        );
        for (var dc in local.dispositionsConstructives) {
          final isObs = dc.conforme == false;
          addGeneralPhotos(
            dc.photos,
            'Local : ${local.nom} - DC : ${dc.elementControle}',
            isObservation: isObs,
            badgeLabel: isObs ? 'ANOMALIE' : 'LOCAL',
            badgeBgColor: isObs ? PdfColors.white : localBadgeColor,
            badgeTextColor: isObs ? PdfColors.red700 : PdfColors.white,
          );
        }
        for (var ce in local.conditionsExploitation) {
          final isObs = ce.conforme == false;
          addGeneralPhotos(
            ce.photos,
            'Local : ${local.nom} - CE : ${ce.elementControle}',
            isObservation: isObs,
            badgeLabel: isObs ? 'ANOMALIE' : 'LOCAL',
            badgeBgColor: isObs ? PdfColors.white : localBadgeColor,
            badgeTextColor: isObs ? PdfColors.red700 : PdfColors.white,
          );
        }
        for (var obs in local.observationsLibres) {
          addGeneralPhotos(
            obs.photos,
            'Local : ${local.nom} - Obs libre : ${obs.texte}',
            isObservation: true,
            badgeLabel: 'ANOMALIE',
            badgeBgColor: PdfColors.white,
            badgeTextColor: PdfColors.red700,
          );
        }
        for (var i = 0; i < local.cellules.length; i++) {
          final cellule = local.cellules[i];
          addGeneralPhotos(
            cellule.photos,
            'Local : ${local.nom} - Cellule ${i + 1} (${cellule.fonction})',
            badgeLabel: 'CELLULE',
            badgeBgColor: celluleBadgeColor,
            badgeTextColor: PdfColors.white,
          );
          for (var ev in cellule.elementsVerifies) {
            final isObs = ev.conforme == false;
            addGeneralPhotos(
              ev.photos,
              'Local : ${local.nom} - Cellule ${i + 1} - Vérif : ${ev.elementControle}',
              isObservation: isObs,
              badgeLabel: isObs ? 'ANOMALIE' : 'CELLULE',
              badgeBgColor: isObs ? PdfColors.white : celluleBadgeColor,
              badgeTextColor: isObs ? PdfColors.red700 : PdfColors.white,
            );
          }
        }
        for (var i = 0; i < local.transformateurs.length; i++) {
          final transfo = local.transformateurs[i];
          addGeneralPhotos(
            transfo.photos,
            'Local : ${local.nom} - Transformateur ${i + 1}',
            badgeLabel: 'TRANSFO',
            badgeBgColor: celluleBadgeColor,
            badgeTextColor: PdfColors.white,
          );
          for (var ev in transfo.elementsVerifies) {
            final isObs = ev.conforme == false;
            addGeneralPhotos(
              ev.photos,
              'Local : ${local.nom} - Transformateur ${i + 1} - Vérif : ${ev.elementControle}',
              isObservation: isObs,
              badgeLabel: isObs ? 'ANOMALIE' : 'TRANSFO',
              badgeBgColor: isObs ? PdfColors.white : celluleBadgeColor,
              badgeTextColor: isObs ? PdfColors.red700 : PdfColors.white,
            );
          }
        }
        for (var c in local.coffrets) {
          equipmentGroups.add(processCoffret(c, local.nom));
        }
      }

      // Moyenne Tension Zones
      for (var zone in audit.moyenneTensionZones) {
        addGeneralPhotos(
          zone.photos,
          'Zone : ${zone.nom}',
          badgeLabel: 'ZONE',
          badgeBgColor: zoneBadgeColor,
          badgeTextColor: PdfColors.white,
        );
        for (var obs in zone.observationsLibres) {
          addGeneralPhotos(
            obs.photos,
            'Zone : ${zone.nom} - Obs libre : ${obs.texte}',
            isObservation: true,
            badgeLabel: 'ANOMALIE',
            badgeBgColor: PdfColors.white,
            badgeTextColor: PdfColors.red700,
          );
        }
        for (var c in zone.coffrets) {
          equipmentGroups.add(processCoffret(c, zone.nom));
        }
        for (var local in zone.locaux) {
          addGeneralPhotos(
            local.photos,
            'Zone : ${zone.nom} - Local : ${local.nom}',
            badgeLabel: 'LOCAL',
            badgeBgColor: localBadgeColor,
            badgeTextColor: PdfColors.white,
          );
          for (var dc in local.dispositionsConstructives) {
            final isObs = dc.conforme == false;
            addGeneralPhotos(
              dc.photos,
              'Zone : ${zone.nom} - Local : ${local.nom} - DC : ${dc.elementControle}',
              isObservation: isObs,
              badgeLabel: isObs ? 'ANOMALIE' : 'LOCAL',
              badgeBgColor: isObs ? PdfColors.white : localBadgeColor,
              badgeTextColor: isObs ? PdfColors.red700 : PdfColors.white,
            );
          }
          for (var ce in local.conditionsExploitation) {
            final isObs = ce.conforme == false;
            addGeneralPhotos(
              ce.photos,
              'Zone : ${zone.nom} - Local : ${local.nom} - CE : ${ce.elementControle}',
              isObservation: isObs,
              badgeLabel: isObs ? 'ANOMALIE' : 'LOCAL',
              badgeBgColor: isObs ? PdfColors.white : localBadgeColor,
              badgeTextColor: isObs ? PdfColors.red700 : PdfColors.white,
            );
          }
          for (var obs in local.observationsLibres) {
            addGeneralPhotos(
              obs.photos,
              'Zone : ${zone.nom} - Local : ${local.nom} - Obs libre : ${obs.texte}',
              isObservation: true,
              badgeLabel: 'ANOMALIE',
              badgeBgColor: PdfColors.white,
              badgeTextColor: PdfColors.red700,
            );
          }
          for (var c in local.coffrets) {
            equipmentGroups.add(processCoffret(c, '${zone.nom} - Local : ${local.nom}'));
          }
        }
      }

      // Basse Tension Zones
      for (var zone in audit.basseTensionZones) {
        addGeneralPhotos(
          zone.photos,
          'Zone : ${zone.nom}',
          badgeLabel: 'ZONE',
          badgeBgColor: zoneBadgeColor,
          badgeTextColor: PdfColors.white,
        );
        for (var obs in zone.observationsLibres) {
          addGeneralPhotos(
            obs.photos,
            'Zone : ${zone.nom} - Obs libre : ${obs.texte}',
            isObservation: true,
            badgeLabel: 'ANOMALIE',
            badgeBgColor: PdfColors.white,
            badgeTextColor: PdfColors.red700,
          );
        }
        for (var c in zone.coffretsDirects) {
          equipmentGroups.add(processCoffret(c, zone.nom));
        }
        for (var local in zone.locaux) {
          addGeneralPhotos(
            local.photos,
            'Zone : ${zone.nom} - Local : ${local.nom}',
            badgeLabel: 'LOCAL',
            badgeBgColor: localBadgeColor,
            badgeTextColor: PdfColors.white,
          );
          if (local.dispositionsConstructives != null) {
            for (var dc in local.dispositionsConstructives!) {
              final isObs = dc.conforme == false;
              addGeneralPhotos(
                dc.photos,
                'Zone : ${zone.nom} - Local : ${local.nom} - DC : ${dc.elementControle}',
                isObservation: isObs,
                badgeLabel: isObs ? 'ANOMALIE' : 'LOCAL',
                badgeBgColor: isObs ? PdfColors.white : localBadgeColor,
                badgeTextColor: isObs ? PdfColors.red700 : PdfColors.white,
              );
            }
          }
          if (local.conditionsExploitation != null) {
            for (var ce in local.conditionsExploitation!) {
              final isObs = ce.conforme == false;
              addGeneralPhotos(
                ce.photos,
                'Zone : ${zone.nom} - Local : ${local.nom} - CE : ${ce.elementControle}',
                isObservation: isObs,
                badgeLabel: isObs ? 'ANOMALIE' : 'LOCAL',
                badgeBgColor: isObs ? PdfColors.white : localBadgeColor,
                badgeTextColor: isObs ? PdfColors.red700 : PdfColors.white,
              );
            }
          }
          for (var obs in local.observationsLibres) {
            addGeneralPhotos(
              obs.photos,
              'Zone : ${zone.nom} - Local : ${local.nom} - Obs libre : ${obs.texte}',
              isObservation: true,
              badgeLabel: 'ANOMALIE',
              badgeBgColor: PdfColors.white,
              badgeTextColor: PdfColors.red700,
            );
          }
          for (var c in local.coffrets) {
            equipmentGroups.add(processCoffret(c, '${zone.nom} - Local : ${local.nom}'));
          }
        }
      }
    }

    final activeEquipmentGroups = equipmentGroups.where((g) => g.hasPhotos).toList();
    final totalPhotosCount = generalPhotos.length + activeEquipmentGroups.fold<int>(0, (sum, g) => sum + g.totalPhotosCount);

    if (totalPhotosCount == 0) return _ChunkSectionResult(files: chunkFiles, totalPages: 0);

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
          final photoChunkFile = File('${tempDir.path}/pdf_chunk_photos_${missionId}_$photoChunkIdx.pdf');
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

    // ─────────────────────────────────────────────────────────────
    //  PHASE 1: Photos Générales / Zones / Locaux (Grille 2x2 standard)
    // ─────────────────────────────────────────────────────────────
    for (int gi = 0; gi < generalPhotos.length; gi += 4) {
      final pageGroup = generalPhotos.sublist(gi, (gi + 4).clamp(0, generalPhotos.length));
      final pageImgs = <pw.MemoryImage?>[];
      for (final entry in pageGroup) {
        pageImgs.add(await _loadAndOptimizeImage(
          entry.filePath,
          photoContext: PdfPhotoContext.grid2x2,
          saveFilesToDisk: saveFilesToDisk,
        ));
      }

      final startPhotoNum = globalPhotoCounter;
      globalPhotoCounter += pageGroup.length;

      photoDoc.addPage(pw.Page(
        pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages, showWatermark: false),
        build: (ctx) {
          final cells = <pw.Widget>[];
          for (int ci = 0; ci < 4; ci++) {
            if (ci < pageGroup.length) {
              final entry = pageGroup[ci];
              final img = pageImgs[ci];
              cells.add(_buildPhotoCell(entry, img, startPhotoNum + ci, totalPhotosCount));
            } else {
              cells.add(pw.Container(margin: const pw.EdgeInsets.all(3), color: PdfColors.grey100));
            }
          }
          return pw.Column(
            children: [
              _buildPageHeaderWidget(nomClient: mission.nomClient, nomSite: nomSite, numeroRapport: numeroRapport),
              pw.SizedBox(height: 6),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Expanded(child: pw.Row(children: [pw.Expanded(child: cells[0]), pw.Expanded(child: cells[1])])),
                    pw.Expanded(child: pw.Row(children: [pw.Expanded(child: cells[2]), pw.Expanded(child: cells[3])])),
                  ],
                ),
              ),
            ],
          );
        },
      ));
      pagesInCurrentChunk++;
      await flushChunkIfNeeded();
    }

    // ─────────────────────────────────────────────────────────────
    //  PHASE 2: Équipements (Extérieur & Intérieur toujours sur la même ligne)
    // ─────────────────────────────────────────────────────────────
    var currentPageEquipRows = <pw.Widget>[];

    Future<void> flushEquipmentPage() async {
      if (currentPageEquipRows.isEmpty) return;
      final rowsToRender = List<pw.Widget>.from(currentPageEquipRows);
      currentPageEquipRows.clear();

      photoDoc.addPage(pw.Page(
        pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages, showWatermark: false),
        build: (ctx) {
          return pw.Column(
            children: [
              _buildPageHeaderWidget(nomClient: mission.nomClient, nomSite: nomSite, numeroRapport: numeroRapport),
              pw.SizedBox(height: 4),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Expanded(child: rowsToRender[0]),
                    pw.Expanded(
                      child: rowsToRender.length > 1
                          ? rowsToRender[1]
                          : pw.Row(children: [
                              pw.Expanded(child: pw.Container(margin: const pw.EdgeInsets.all(3), color: PdfColors.grey100)),
                              pw.Expanded(child: pw.Container(margin: const pw.EdgeInsets.all(3), color: PdfColors.grey100)),
                            ]),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ));
      pagesInCurrentChunk++;
      await flushChunkIfNeeded();
    }

    for (var group in activeEquipmentGroups) {
      // Charger l'image extérieure et intérieure avec le contexte adaptatif
      pw.MemoryImage? extImg;
      if (group.extPhoto != null) {
        extImg = await _loadAndOptimizeImage(
          group.extPhoto!.filePath,
          photoContext: PdfPhotoContext.equipmentObs,
          saveFilesToDisk: saveFilesToDisk,
        );
      }
      pw.MemoryImage? intImg;
      if (group.intPhoto != null) {
        intImg = await _loadAndOptimizeImage(
          group.intPhoto!.filePath,
          photoContext: PdfPhotoContext.equipmentObs,
          saveFilesToDisk: saveFilesToDisk,
        );
      }

      // Charger les images d'observations avec le contexte adaptatif
      final obsImgs = <pw.MemoryImage?>[];
      for (var obs in group.obsPhotos) {
        obsImgs.add(await _loadAndOptimizeImage(
          obs.filePath,
          photoContext: PdfPhotoContext.equipmentObs,
          saveFilesToDisk: saveFilesToDisk,
        ));
      }

      final extCellNum = group.extPhoto != null ? globalPhotoCounter++ : null;
      final extCellWidget = group.extPhoto != null
          ? _buildPhotoCell(group.extPhoto!, extImg, extCellNum!, totalPhotosCount)
          : pw.Container(margin: const pw.EdgeInsets.all(3), color: PdfColors.grey100);

      final intCellNum = group.intPhoto != null ? globalPhotoCounter++ : null;
      final intCellWidget = group.intPhoto != null
          ? _buildPhotoCell(group.intPhoto!, intImg, intCellNum!, totalPhotosCount)
          : pw.Container(margin: const pw.EdgeInsets.all(3), color: PdfColors.grey100);

      final typeHeader = group.coffret.type.isNotEmpty ? group.coffret.type.toUpperCase() : 'ÉQUIPEMENT';

      // Rangée principale Extérieur & Intérieur côte à côte (avec bannière d'en-tête)
      final extIntRowWidget = pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
            decoration: pw.BoxDecoration(
              color: lightBlue,
              border: pw.Border.all(color: borderColor, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('$typeHeader : ${group.coffret.nom.toUpperCase()}',
                    style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor)),
                pw.Text('Réf : ${group.coffret.repere ?? group.coffret.numeroEquipement ?? '-'} (${group.locationPrefix})',
                    style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall - 1, color: headerColor)),
              ],
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Expanded(
            child: pw.Row(
              children: [
                pw.Expanded(child: extCellWidget),
                pw.Expanded(child: intCellWidget),
              ],
            ),
          ),
        ],
      );

      if (currentPageEquipRows.length >= 2) {
        await flushEquipmentPage();
      }
      currentPageEquipRows.add(extIntRowWidget);

      // Ajout des photos d'observations par paires (2 par rangée)
      for (int oi = 0; oi < group.obsPhotos.length; oi += 2) {
        if (currentPageEquipRows.length >= 2) {
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
          cell2 = pw.Container(margin: const pw.EdgeInsets.all(3), color: PdfColors.grey100);
        }

        final obsRowWidget = pw.Row(
          children: [
            pw.Expanded(child: cell1),
            pw.Expanded(child: cell2),
          ],
        );
        currentPageEquipRows.add(obsRowWidget);
      }
    }

    await flushEquipmentPage();
    await flushChunkIfNeeded(force: true);
    return _ChunkSectionResult(files: chunkFiles, totalPages: currentOffset - pageOffset);
  }





  // ──────────────────────────────────────────────────────────────
  //  SCHÉMA DES INSTALLATIONS ÉLECTRIQUES
  // ──────────────────────────────────────────────────────────────
  
  static void _addSchemaSection(
    pw.Document pdf,
    Mission mission,
    Map<String, int> trackedPages, {
    String? nomSite,
    String? numeroRapport,
    int pageOffset = 0,
    int? overrideTotalPages,
  }) {
    final hasSchema = mission.schemaOption?.trim().toLowerCase() == 'oui';
    if (!hasSchema) return;

    pdf.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(pageOffset: pageOffset, overrideTotalPages: overrideTotalPages, showWatermark: false),
      header: (ctx) => _buildPageHeaderWidget(
        nomClient: mission.nomClient,
        nomSite: nomSite,
        numeroRapport: numeroRapport,
      ),
      build: (ctx) => [
        pw.SizedBox(height: 220),
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
                    font: _fontBold, fontSize: 20,
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
                  font: _fontRegular, fontSize: 13, color: accentColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 24),
              pw.Container(width: 350, height: 2, color: accentColor),
            ],
          ),
        ),
      ],
    ));
  }

  static pw.Widget _buildPhotoCell(_PhotoEntry entry, pw.MemoryImage? img, int index, int total) {
    final isObs = entry.isObservation;
    final cardBorderColor = isObs ? PdfColors.red700 : borderColor;
    final cardBorderWidth = isObs ? 1.5 : 0.8;
    final captionBgColor = isObs ? PdfColor.fromInt(0xFFFFEBEE) : PdfColor.fromInt(0xFFF0F4FA);

    return pw.Container(
      margin: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: cardBorderColor, width: cardBorderWidth),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        boxShadow: [pw.BoxShadow(color: PdfColors.grey400, blurRadius: 2, offset: const PdfPoint(1, 1))],
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
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(children: [
                    pw.Text('Photo $index / $total',
                        style: pw.TextStyle(font: _fontBold, fontSize: 6, color: PdfColors.white)),
                    if (entry.badgeLabel != null && entry.badgeLabel!.isNotEmpty) ...[
                      pw.SizedBox(width: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: pw.BoxDecoration(
                          color: entry.badgeBgColor ?? PdfColors.white,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                        ),
                        child: pw.Text(entry.badgeLabel!,
                            style: pw.TextStyle(font: _fontBold, fontSize: 5, color: entry.badgeTextColor ?? PdfColors.white)),
                      ),
                    ] else if (isObs) ...[
                      pw.SizedBox(width: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                        ),
                        child: pw.Text('ANOMALIE',
                            style: pw.TextStyle(font: _fontBold, fontSize: 5, color: PdfColors.red700)),
                      ),
                    ],
                  ]),
                  if (entry.repere != null && entry.repere!.isNotEmpty)
                    pw.Text('Réf : ${entry.repere}',
                        style: pw.TextStyle(font: _fontBold, fontSize: 6, color: PdfColors.yellow)),
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
                              width: 24, height: 24,
                              decoration: const pw.BoxDecoration(
                                  color: PdfColors.grey300, shape: pw.BoxShape.circle),
                              child: pw.Center(
                                child: pw.Text('?',
                                    style: pw.TextStyle(font: _fontBold, fontSize: 14,
                                        color: PdfColors.grey500)),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text('Image non disponible',
                                style: pw.TextStyle(font: _fontRegular, fontSize: 6,
                                    color: PdfColors.grey500)),
                          ],
                        ),
                      ),
                    ),
            ),
            // Légende en bas
            pw.Container(
              color: captionBgColor,
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: pw.Text(
                entry.description,
                style: pw.TextStyle(font: isObs ? _fontBold : _fontRegular, fontSize: 5.5, color: isObs ? PdfColors.red900 : darkGrey),
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ──────────────────────────────────────────────────────────────
  //  UTILITAIRES PDF (cellules, lignes, titres...)
  // ──────────────────────────────────────────────────────────────

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
          style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: PdfColors.black),
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
              style: pw.TextStyle(font: _fontRegular, fontSize: fsBody, color: PdfColors.black),
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
            style: pw.TextStyle(font: _fontBold, fontSize: fsBody, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Convertit les caractères spéciaux en versions compatibles avec les polices standard
  /// Normalise le texte pour l'encodage PDF.
  /// IMPORTANT : conserve tous les accents français (supportés nativement
  /// par Helvetica Latin-1 et toute police TrueType chargée).
  /// Seuls les symboles Unicode hors-charset sont translittérés.
  static String _normalizeText(String text) {
    if (text.isEmpty) return text;
    text = text.replaceAll(RegExp(r'§\s*'), 'art ');

    const replacements = <String, String>{
      // Guillemets typographiques
      '«': '"', '»': '"', '“': '"', '”': '"',
      '‘': "'", '’': "'",
      // Tirets longs
      '—': '-', '–': '-', '…': '...',
      // Symboles mathématiques
      '≥': '>=', '≤': '<=', '≠': '!=',
      '±': '+/-', '∞': 'inf', '√': 'racine',
      '→': '->', '←': '<-', '↔': '<->',
      '∑': 'Somme', '∆': 'Delta', 'Φ': 'Phi',
      'θ': 'theta',
      // Symboles électriques
      'Ω': 'Ohm', 'μ': 'u', 'Σ': 'Sigma',
      // Exposants/indices
      '²': '2', '³': '3', '¹': '1',
      '₁': '1', '₂': '2', '₃': '3', '₄': '4',
      // Monétaires
      '€': 'EUR', '£': 'GBP', '¥': 'JPY',
    };

    var result = text;
    replacements.forEach((k, v) => result = result.replaceAll(k, v));
    return result;
  }
  static pw.Widget _sectionBox(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: headerColor,
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Text(
        _normalizeText(title),
        style: pw.TextStyle(
          font: _fontBold,
          fontSize: fsH1,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static pw.Widget _subTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10, bottom: 5),
      child: pw.Text(
        _normalizeText(title),
        style: pw.TextStyle(
          font: _fontBold,
          fontSize: fsH3,
          fontWeight: pw.FontWeight.bold,
          color: accentColor,
        ),
      ),
    );
  }

  static pw.Widget _bodyText(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        _normalizeText(text),
        style: pw.TextStyle(
          font: _fontRegular,
          fontSize: fsBody,
          color: darkGrey,
          lineSpacing: 2.0,
        ),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }

  static pw.Widget _bodyBold(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(_normalizeText(text),
          style: pw.TextStyle(
            font: _fontBold,
            fontSize: fsBody,
            fontWeight: pw.FontWeight.bold,
            color: darkGrey,
            lineSpacing: 2.0,
          )),
    );
  }

  static pw.Widget _bulletItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 14, bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4, right: 8),
            width: 5,
            height: 5,
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
                color: darkGrey,
                lineSpacing: 1.8,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  /// Formate les intitulés d'en-tête de colonnes contenant une unité de mesure entre parenthèses
  /// pour garantir que l'unité "(unité)" forme un bloc indivisible précédé d'un espace.
  static String formatHeaderUnit(String text) {
    if (text.isEmpty || !text.contains('(')) return text;

    final unitRegex = RegExp(r'\s*\(([^)]+)\)');
    return text.replaceAllMapped(unitRegex, (match) {
      final unitContent = match.group(1)?.trim() ?? '';
      if (unitContent.isEmpty) return match.group(0)!;

      final nonBreakingUnitContent = unitContent.replaceAll(' ', '\u00A0');
      return ' ($nonBreakingUnitContent)';
    });
  }

  static pw.Widget _cell(String text, {required bool isHeader, PdfColor? color, int colspan = 1, bool centered = false}) {
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
      children: headers.map((h) => _cell(h, isHeader: true, centered: true)).toList(),
    );
  }

  static pw.TableRow _tableDataRow(List<String> data, {required bool alt, bool centered = false}) {
    return pw.TableRow(
      decoration: alt ? pw.BoxDecoration(color: tableRowAlt) : null,
      children: data.map((d) => _cell(d, isHeader: false, centered: centered)).toList(),
    );
  }

  

  static Future<_ChunkSectionResult> _addListeRecapitulativeSectionChunked(
    Mission mission,
    AuditInstallationsElectriques audit,
    Map<String, int> trackedPages, {
    required String nomSite,
    required String numeroRapport,
    int pageOffset = 0,
    int? overrideTotalPages,
    bool saveFilesToDisk = true,
  }) async {
    final chunkFiles = <File>[];
    final tempDir = await getTemporaryDirectory();
    int currentOffset = pageOffset;

    // 1. Page de Garde de la Synthèse Récapitulative
    final coverDoc = pw.Document(
      title: 'Recap Cover - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    coverDoc.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages, showWatermark: false),
      header: (ctx) => _buildPageHeaderWidget(
        nomSite: nomSite,
        numeroRapport: numeroRapport,
      ),
      build: (ctx) => [
        pw.SizedBox(height: 220),
        pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(width: 350, height: 2, color: accentColor),
              pw.SizedBox(height: 24),
              PageTracker(
                key: 'liste_recap',
                registry: trackedPages,
                offset: currentOffset,
                child: pw.Text(
                  'SYNTHÈSE RÉCAPITULATIVE DES OBSERVATIONS',
                  style: pw.TextStyle(
                    font: _fontBold, fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: headerColor,
                    letterSpacing: 1.0,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                mission.nomClient.toUpperCase(),
                style: pw.TextStyle(
                  font: _fontRegular, fontSize: 13, color: accentColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 24),
              pw.Container(width: 350, height: 2, color: accentColor),
            ],
          ),
        ),
      ],
    ));
    final coverBytes = await coverDoc.save();
    if (saveFilesToDisk) {
      final coverFile = File('${tempDir.path}/pdf_chunk_recap_cover_${mission.id}.pdf');
      await coverFile.writeAsBytes(coverBytes);
      chunkFiles.add(coverFile);
    }
    currentOffset += coverDoc.document.pdfPageList.pages.length;

    // 2. Moyenne Tension Récap
    final obsMT = _collectObservationsMT(audit);
    final mtDoc = pw.Document(
      title: 'Recap MT - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    final mtWidgets = <pw.Widget>[
      PageTracker(
        key: 'liste_recap_mt',
        registry: trackedPages,
        offset: currentOffset,
        child: _subSectionBar('1. Moyenne tension'),
      ),
      pw.SizedBox(height: 5),
      ..._buildObsRecapTableMT(obsMT),
    ];
    mtDoc.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages),
      header: (ctx) => _buildPageHeaderWidget(
        nomClient: mission.nomClient,
        nomSite: nomSite,
        numeroRapport: numeroRapport,
      ),
      build: (ctx) => mtWidgets,
    ));
    final mtBytes = await mtDoc.save();
    if (saveFilesToDisk) {
      final mtFile = File('${tempDir.path}/pdf_chunk_recap_mt_${mission.id}.pdf');
      await mtFile.writeAsBytes(mtBytes);
      chunkFiles.add(mtFile);
    }
    currentOffset += mtDoc.document.pdfPageList.pages.length;

    // 3. Basse Tension Récap (Découpé par tranche de 15 groupes de locaux max)
    final obsBT = _collectObservationsBT(audit);
    final groupsBT = _groupByLocal(obsBT);

    if (groupsBT.isEmpty) {
      final btDoc = pw.Document(
        title: 'Recap BT Empty - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: saveFilesToDisk,
      );
      btDoc.addPage(pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSite,
          numeroRapport: numeroRapport,
        ),
        build: (ctx) => [
          PageTracker(
            key: 'liste_recap_bt',
            registry: trackedPages,
            offset: currentOffset,
            child: _subSectionBar('2. Basse tension'),
          ),
          pw.SizedBox(height: 5),
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor, width: 0.4)),
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('Aucune observation',
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall, fontStyle: pw.FontStyle.italic)),
          ),
        ],
      ));
      final btBytes = await btDoc.save();
      if (saveFilesToDisk) {
        final btFile = File('${tempDir.path}/pdf_chunk_recap_bt_empty_${mission.id}.pdf');
        await btFile.writeAsBytes(btBytes);
        chunkFiles.add(btFile);
      }
      currentOffset += btDoc.document.pdfPageList.pages.length;
    } else {
      const int batchSize = 15;
      for (int i = 0; i < groupsBT.length; i += batchSize) {
        final subGroups = groupsBT.sublist(i, (i + batchSize).clamp(0, groupsBT.length));
        final btDoc = pw.Document(
          title: 'Recap BT Chunk ${i ~/ batchSize} - ${mission.nomClient}',
          author: 'KES INSPECTIONS AND PROJECTS',
          compress: saveFilesToDisk,
        );
        final btWidgets = <pw.Widget>[];
        if (i == 0) {
          btWidgets.add(PageTracker(
            key: 'liste_recap_bt',
            registry: trackedPages,
            offset: currentOffset,
            child: _subSectionBar('2. Basse tension'),
          ));
          btWidgets.add(pw.SizedBox(height: 5));
        }
        btWidgets.addAll(_buildObsRecapTableBTFromGroups(subGroups));

        btDoc.addPage(pw.MultiPage(
          maxPages: 10000,
          pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages),
          header: (ctx) => _buildPageHeaderWidget(
            nomClient: mission.nomClient,
            nomSite: nomSite,
            numeroRapport: numeroRapport,
          ),
          build: (ctx) => btWidgets,
        ));
        final btBytes = await btDoc.save();
        if (saveFilesToDisk) {
          final btFile = File('${tempDir.path}/pdf_chunk_recap_bt_${i ~/ batchSize}_${mission.id}.pdf');
          await btFile.writeAsBytes(btBytes);
          chunkFiles.add(btFile);
        }
        currentOffset += btDoc.document.pdfPageList.pages.length;
      }
    }

    return _ChunkSectionResult(files: chunkFiles, totalPages: currentOffset - pageOffset);
  }

  static Future<Map<dynamic, pw.MemoryImage?>> _preloadEquipmentPhotos(
    List<dynamic> items, {
    bool loadImages = true,
  }) async {
    final cache = <dynamic, pw.MemoryImage?>{};
    if (!loadImages) return cache;

    for (final item in items) {
      if (item is CoffretArmoire) {
        for (final src in [...item.photosInternes, ...item.photos, ...item.photosExternes]) {
          final trimmed = src.trim();
          if (trimmed.isEmpty) continue;
          final img = await _loadAndOptimizeImage(
            trimmed,
            photoContext: PdfPhotoContext.equipmentObs,
            saveFilesToDisk: loadImages,
          );
          if (img != null) {
            cache[item] = img;
            break;
          }
        }
      } else if (item is Cellule) {
        final rawPath = (item.photo != null && item.photo!.trim().isNotEmpty)
            ? item.photo!.trim()
            : (item.photos.isNotEmpty ? item.photos.first.trim() : null);
        if (rawPath != null && rawPath.isNotEmpty) {
          final img = await _loadAndOptimizeImage(
            rawPath,
            photoContext: PdfPhotoContext.equipmentObs,
            saveFilesToDisk: loadImages,
          );
          if (img != null) {
            cache[item] = img;
          }
        }
      } else if (item is TransformateurMTBT) {
        final rawPath = (item.photo != null && item.photo!.trim().isNotEmpty)
            ? item.photo!.trim()
            : (item.photos.isNotEmpty ? item.photos.first.trim() : null);
        if (rawPath != null && rawPath.isNotEmpty) {
          final img = await _loadAndOptimizeImage(
            rawPath,
            photoContext: PdfPhotoContext.equipmentObs,
            saveFilesToDisk: loadImages,
          );
          if (img != null) {
            cache[item] = img;
          }
        }
      } else if (item is MoyenneTensionLocal) {
        if (item.photos.isNotEmpty) {
          final rawPath = item.photos.first.trim();
          if (rawPath.isNotEmpty) {
            final img = await _loadAndOptimizeImage(
              rawPath,
              photoContext: PdfPhotoContext.equipmentObs,
              saveFilesToDisk: loadImages,
            );
            if (img != null) {
              cache[item] = img;
            }
          }
        }
      } else if (item is BasseTensionLocal) {
        if (item.photos.isNotEmpty) {
          final rawPath = item.photos.first.trim();
          if (rawPath.isNotEmpty) {
            final img = await _loadAndOptimizeImage(
              rawPath,
              photoContext: PdfPhotoContext.equipmentObs,
              saveFilesToDisk: loadImages,
            );
            if (img != null) {
              cache[item] = img;
            }
          }
        }
      }
    }
    return cache;
  }

  static Future<Map<dynamic, pw.MemoryImage?>> _preloadCoffretsList(
    List<CoffretArmoire> coffrets, {
    List<Cellule>? cellules,
    List<TransformateurMTBT>? transformateurs,
    List<dynamic>? locaux,
    bool loadImages = true,
  }) async {
    final list = <dynamic>[...coffrets, ...?cellules, ...?transformateurs, ...?locaux];
    return _preloadEquipmentPhotos(list, loadImages: loadImages);
  }

  static Future<Map<dynamic, pw.MemoryImage?>> _preloadZoneMTCoffrets(
    MoyenneTensionZone zone, {
    bool loadImages = true,
  }) async {
    final list = <dynamic>[...zone.coffrets];
    for (final local in zone.locaux) {
      list.addAll(local.coffrets);
      list.addAll(local.cellules);
      list.addAll(local.transformateurs);
    }
    return _preloadEquipmentPhotos(list, loadImages: loadImages);
  }

  static Future<Map<dynamic, pw.MemoryImage?>> _preloadZoneBTCoffrets(
    BasseTensionZone zone, {
    bool loadImages = true,
  }) async {
    final coffrets = <CoffretArmoire>[...zone.coffretsDirects];
    for (final local in zone.locaux) {
      coffrets.addAll(local.coffrets);
    }
    return _preloadCoffretsList(coffrets, loadImages: loadImages);
  }

  static Future<_ChunkSectionResult> _addAuditSectionChunked(
    Mission mission,
    AuditInstallationsElectriques audit,
    Map<String, int> trackedPages, {
    required String nomSite,
    required String numeroRapport,
    int pageOffset = 0,
    int? overrideTotalPages,
    bool saveFilesToDisk = true,
  }) async {
    final chunkFiles = <File>[];
    final tempDir = await getTemporaryDirectory();
    int currentOffset = pageOffset;

    final bool hasNoAuditContent = audit.moyenneTensionLocaux.isEmpty &&
        audit.moyenneTensionZones.isEmpty &&
        audit.basseTensionZones.isEmpty;

    // 1. Page de Garde / Titre de l'Audit
    final coverDoc = pw.Document(
      title: 'Audit Cover - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    coverDoc.addPage(pw.MultiPage(
      maxPages: 200,
      pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages, showWatermark: false),
      header: (ctx) => _buildPageHeaderWidget(
        nomSite: nomSite,
        numeroRapport: numeroRapport,
      ),
      build: (ctx) => [
        pw.SizedBox(height: 220),
        pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(width: 350, height: 2, color: accentColor),
              pw.SizedBox(height: 24),
              PageTracker(
                key: 'audit',
                registry: trackedPages,
                offset: currentOffset,
                child: pw.Text(
                  'AUDIT DES INSTALLATIONS ELECTRIQUES',
                  style: pw.TextStyle(
                    font: _fontBold, fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: headerColor,
                    letterSpacing: 1.0,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                mission.nomClient.toUpperCase(),
                style: pw.TextStyle(
                  font: _fontRegular, fontSize: 13, color: accentColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 24),
              pw.Container(width: 350, height: 2, color: accentColor),
              if (hasNoAuditContent) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'Aucune installation enregistrée dans cet audit.',
                  style: pw.TextStyle(
                    font: _fontRegular,
                    fontSize: 10,
                    color: darkGrey,
                    fontStyle: pw.FontStyle.italic,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    ));
    final coverBytes = await coverDoc.save();
    if (saveFilesToDisk) {
      final coverFile = File('${tempDir.path}/pdf_chunk_audit_cover_${mission.id}.pdf');
      await coverFile.writeAsBytes(coverBytes);
      chunkFiles.add(coverFile);
    }
    currentOffset += coverDoc.document.pdfPageList.pages.length;

    // 2. MT Locaux Directs (si présents)
    if (audit.moyenneTensionLocaux.isNotEmpty) {
      final mtCoffrets = <CoffretArmoire>[];
      final mtCellules = <Cellule>[];
      final mtTransfos = <TransformateurMTBT>[];
      final mtLocaux = <dynamic>[];
      for (final local in audit.moyenneTensionLocaux) {
        mtLocaux.add(local);
        mtCoffrets.addAll(local.coffrets);
        mtCellules.addAll(local.cellules);
        mtTransfos.addAll(local.transformateurs);
      }
      final mtPhotoCache = await _preloadCoffretsList(
        mtCoffrets,
        cellules: mtCellules,
        transformateurs: mtTransfos,
        locaux: mtLocaux,
        loadImages: saveFilesToDisk,
      );

      final mtDoc = pw.Document(
        title: 'Audit MT Directs - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: saveFilesToDisk,
      );
      final widgets = <pw.Widget>[
        PageTracker(
          key: 'audit_mt',
          registry: trackedPages,
          offset: currentOffset,
          child: _subSectionBar('MOYENNE TENSION — LOCAUX DIRECTS'),
        ),
      ];
      for (int i = 0; i < audit.moyenneTensionLocaux.length; i++) {
        if (i > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildLocalMT(
          audit.moyenneTensionLocaux[i],
          trackedPages,
          photoCache: mtPhotoCache,
          saveFilesToDisk: saveFilesToDisk,
        ));
      }
      mtDoc.addPage(pw.MultiPage(
        maxPages: 200,
        pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSite,
          numeroRapport: numeroRapport,
        ),
        build: (ctx) => widgets,
      ));
      final mtBytes = await mtDoc.save();
      if (saveFilesToDisk) {
        final mtFile = File('${tempDir.path}/pdf_chunk_audit_mt_${mission.id}.pdf');
        await mtFile.writeAsBytes(mtBytes);
        chunkFiles.add(mtFile);
      }
      currentOffset += mtDoc.document.pdfPageList.pages.length;
      mtPhotoCache.clear();
    }

    // 3. Zones MT (1 chunk autonome par Zone MT)
    for (var zIdx = 0; zIdx < audit.moyenneTensionZones.length; zIdx++) {
      final zone = audit.moyenneTensionZones[zIdx];
      final zonePhotoCache = await _preloadZoneMTCoffrets(zone, loadImages: saveFilesToDisk);

      final zoneDoc = pw.Document(
        title: 'Audit Zone MT ${zone.nom} - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: saveFilesToDisk,
      );
      final widgets = <pw.Widget>[];
      widgets.addAll(_buildZone(zone.nom, zone.observationsLibres, trackedPages));
      int elemIdx = 0;
      for (int i = 0; i < zone.locaux.length; i++) {
        if (elemIdx > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildLocalMT(
          zone.locaux[i],
          trackedPages,
          photoCache: zonePhotoCache,
          saveFilesToDisk: saveFilesToDisk,
        ));
        elemIdx++;
      }
      for (int i = 0; i < zone.coffrets.length; i++) {
        if (elemIdx > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildCoffret(zone.coffrets[i], trackedPages, zone.nom, photoCache: zonePhotoCache));
        elemIdx++;
      }
      zoneDoc.addPage(pw.MultiPage(
        maxPages: 200,
        pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSite,
          numeroRapport: numeroRapport,
        ),
        build: (ctx) => widgets,
      ));
      final zoneBytes = await zoneDoc.save();
      if (saveFilesToDisk) {
        final zoneFile = File('${tempDir.path}/pdf_chunk_audit_mt_z${zIdx}_${mission.id}.pdf');
        await zoneFile.writeAsBytes(zoneBytes);
        chunkFiles.add(zoneFile);
      }
      currentOffset += zoneDoc.document.pdfPageList.pages.length;
      zonePhotoCache.clear();
    }

    // 4. Zones BT (1 chunk autonome par Zone BT)
    for (var zIdx = 0; zIdx < audit.basseTensionZones.length; zIdx++) {
      final zone = audit.basseTensionZones[zIdx];
      final zonePhotoCache = await _preloadZoneBTCoffrets(zone, loadImages: saveFilesToDisk);

      final zoneDoc = pw.Document(
        title: 'Audit Zone BT ${zone.nom} - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: saveFilesToDisk,
      );
      final widgets = <pw.Widget>[];
      widgets.addAll(_buildZone(zone.nom, zone.observationsLibres, trackedPages));
      int elemIdx = 0;
      for (int i = 0; i < zone.coffretsDirects.length; i++) {
        if (elemIdx > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildCoffret(zone.coffretsDirects[i], trackedPages, zone.nom, photoCache: zonePhotoCache));
        elemIdx++;
      }
      for (int i = 0; i < zone.locaux.length; i++) {
        if (elemIdx > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildLocalBT(zone.locaux[i], trackedPages, photoCache: zonePhotoCache));
        elemIdx++;
      }
      zoneDoc.addPage(pw.MultiPage(
        maxPages: 200,
        pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSite,
          numeroRapport: numeroRapport,
        ),
        build: (ctx) => widgets,
      ));
      final zoneBytes = await zoneDoc.save();
      if (saveFilesToDisk) {
        final zoneFile = File('${tempDir.path}/pdf_chunk_audit_bt_z${zIdx}_${mission.id}.pdf');
        await zoneFile.writeAsBytes(zoneBytes);
        chunkFiles.add(zoneFile);
      }
      currentOffset += zoneDoc.document.pdfPageList.pages.length;
      zonePhotoCache.clear();
    }

    return _ChunkSectionResult(files: chunkFiles, totalPages: currentOffset - pageOffset);
  }

  static Future<_GeneratedReportResult> _generateReportPass({
    required Mission mission,
    required String missionId,
    required AuditInstallationsElectriques? audit,
    required DescriptionInstallations? description,
    required dynamic classements,
    required dynamic classementsZones,
    required dynamic mesures,
    required dynamic foudres,
    required dynamic renseignements,
    required dynamic currentUser,
    required String nomSiteHeader,
    required String numeroRapportDoc,
    required Directory tempDir,
    int? overrideTotalPages,
    bool saveFilesToDisk = true,
    PdfProgressCallback? onProgress,
  }) async {
    final allChunkFiles = <File>[];
    final trackedPages = <String, int>{};

    await _preloadCoverImages(mission, saveFilesToDisk: saveFilesToDisk);

    final sommaireEntries = _collectSommaireEntries(
      mission: mission,
      rg: renseignements,
      desc: description,
      audit: audit,
      mesures: mesures,
      foudres: foudres,
    );

    // Pre-flight réel du Sub-chunk 1.1 pour mesurer sans estimation le nombre de pages initial
    final preflightP1_1 = pw.Document(
      title: 'Couverture, Intervenants & Sommaire Preflight - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    final jsaPreflight = HiveService.getJSAByMissionId(mission.id);
    preflightP1_1.addPage(
      pw.Page(
        pageTheme: _buildCoverPageTheme(),
        build: (ctx) => _buildCoverPage(mission, renseignements, ctx),
      ),
    );
    preflightP1_1.addPage(
      pw.Page(
        pageTheme: _buildInnerPageTheme(pageOffset: 0, overrideTotalPages: overrideTotalPages),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeaderWidget(
              nomClient: mission.nomClient,
              nomSite: nomSiteHeader,
              numeroRapport: numeroRapportDoc,
            ),
            pw.SizedBox(height: 8),
            _buildIntervenantsEtResponsabilitesPage(jsaPreflight, renseignements, currentUser, trackedPages, 0),
          ],
        ),
      ),
    );
    _addSommairePages(
      preflightP1_1,
      sommaireEntries,
      trackedPages,
      nomClient: mission.nomClient,
      nomSite: nomSiteHeader,
      numeroRapport: numeroRapportDoc,
      pageOffset: 0,
      overrideTotalPages: overrideTotalPages,
    );

    await preflightP1_1.save();
    final int subChunk1_1_Pages = preflightP1_1.document.pdfPageList.pages.length;
    int currentOffset = subChunk1_1_Pages;

    // ── Sub-chunk 1.2 : Objet, Périmètre & Mesures de sécurité ──
    if (saveFilesToDisk) onProgress?.call(0.18, 'Génération du périmètre et des mesures de sécurité...');
    final pdfP1_2 = pw.Document(
      title: 'Périmètre & Sécurité - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    pdfP1_2.addPage(pw.MultiPage(
      maxPages: 200,
      pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages),
      header: (ctx) => _buildPageHeaderWidget(
        nomClient: mission.nomClient,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
      ),
      build: (ctx) => [
        PageTracker(
          key: 'objet',
          registry: trackedPages,
          offset: currentOffset,
          child: _sectionBox('OBJET DE LA VÉRIFICATION'),
        ),
        pw.SizedBox(height: 10),
        _bodyText(
          'La mission a pour objet de déceler les non-conformités pouvant affecter la sécurité des personnes et des biens, et de s\'assurer du bon état de conservation des installations. '
          'Afin de présenter l\'état des lieux de l\'existant, les points sur lesquels les installations s\'écartent des normes et textes applicables, et de proposer des actions correctives.\n\n'
          'D\'une manière générale, la vérification a été étendue à l\'ensemble des installations électriques présentées et accessibles dans l\'établissement, depuis les sources jusqu\'aux points d\'utilisation.',
        ),
        pw.SizedBox(height: 10),
        _bodyText('Ainsi sont exclus du champ de la vérification\u00a0:'),
        _bulletItem('Les dispositions administratives, organisationnelles et techniques relatives à l\'information et à la formation du personnel (prescriptions au personnel) lors de l\'exploitation courante, de travaux ou d\'interventions sur les installations, ainsi que les mesures de sécurité qui en découlent\u00a0;'),
        _bulletItem('Les dispositions administratives relatives aux documents à tenir à la disposition des autorités publiques\u00a0;'),
        _bulletItem('L\'examen des matériels électriques en présentation ou en démonstration et destinés à la vente\u00a0;'),
        _bulletItem('Les matériels stockés ou en réserve, ou signalés comme n\'étant plus mis en œuvre. Du fait que les installations sont examinées en tenant compte des contraintes d\'exploitation et de sécurité propres à chaque établissement et indiquées en début de vérification au personnel chargé de la vérification, celle-ci est limitée dans certains cas à l\'état apparent des installations.'),
        pw.SizedBox(height: 12),
        PageTracker(
          key: 'objet_normes',
          registry: trackedPages,
          offset: currentOffset,
          child: _subTitle('1. Références normatives et réglementaires'),
        ),
        pw.SizedBox(height: 5),
        _buildNormesTable(),
        pw.SizedBox(height: 12),
        PageTracker(
          key: 'objet_materiel',
          registry: trackedPages,
          offset: currentOffset,
          child: _subTitle('2. Matériel utilisé'),
        ),
        pw.SizedBox(height: 5),
        _buildMaterielTable(),
        pw.NewPage(),
        PageTracker(
          key: 'perimetre',
          registry: trackedPages,
          offset: currentOffset,
          child: _sectionBox('PERIMETRE DE LA MISSION'),
        ),
        pw.SizedBox(height: 14),
        _buildPerimetreTable(mission, renseignements),
        pw.NewPage(),
        PageTracker(
          key: 'rappel',
          registry: trackedPages,
          offset: currentOffset,
          child: _sectionBox('RAPPEL DES RESPONSABILITÉS DE L\'EMPLOYEUR'),
        ),
        pw.SizedBox(height: 14),
        _bodyText(
          'KES INSPECTIONS AND PROJECTS a le plaisir de vous transmettre le présent rapport de vérification de vos installations électriques, établi à la suite des constats réalisés sur site.\n'
          'Ce document présente les observations effectuées par le vérificateur à partir des éléments et moyens mis à sa disposition.\n'
          'Il identifie les points de non-conformité constatés au regard des exigences réglementaires, et formule, le cas échéant, les recommandations techniques nécessaires à leur mise en conformité.',
        ),
        pw.SizedBox(height: 7),
        PageTracker(
          key: 'rappel_accompagnement',
          registry: trackedPages,
          offset: currentOffset,
          child: _subTitle('1. Responsabilité et accompagnement'),
        ),
        _bodyText(
          'Dans le cadre de la mission, il appartient à l\'employeur de désigner une personne qualifiée et informée des installations, chargée d\'accompagner le vérificateur durant l\'intervention.\n'
          'Cette personne doit pouvoir faciliter l\'accès à l\'ensemble des locaux, appareillages et équipements à contrôler.\n\n'
          'L\'employeur reste responsable du bon fonctionnement, de la sécurité et de la disponibilité des installations tout au long de la vérification.\n'
          'Les informations et documents techniques fournis sous sa responsabilité doivent permettre la réalisation des contrôles dans de bonnes conditions.',
        ),
        pw.SizedBox(height: 7),
        PageTracker(
          key: 'rappel_conditions',
          registry: trackedPages,
          offset: currentOffset,
          child: _subTitle('2. Conditions de réalisation'),
        ),
        _bodyText('Afin d\'assurer le bon déroulement des opérations, l\'employeur doit\u00a0:'),
        _bulletItem('Veiller à ce que la vérification soit réalisée dans des conditions de sécurité optimales, en particulier lors des accès en zone électrique\u00a0;'),
        _bulletItem('Mettre en œuvre les procédures nécessaires aux mises hors tension permettant d\'effectuer les mesures et essais en toute sécurité\u00a0;'),
        _bulletItem('Garantir au vérificateur l\'accès à l\'ensemble des équipements à contrôler, sans risque de chute ou d\'incident.'),
        pw.SizedBox(height: 8),
        _bodyText(
          'Si certaines vérifications n\'ont pu être effectuées (impossibilité d\'accès, absence d\'agents habilités, contraintes d\'exploitation, documentation manquante, etc.), '
          'KES INSPECTIONS AND PROJECTS en mentionnera la cause dans le rapport.\n\n'
          'Dans le cas des installations de moyenne ou haute tension, la mise hors tension et les manœuvres associées relèvent exclusivement de la responsabilité de l\'employeur ou de son représentant habilité.',
        ),
        pw.SizedBox(height: 7),
        PageTracker(
          key: 'rappel_complementaires',
          registry: trackedPages,
          offset: currentOffset,
          child: _subTitle('3. Vérifications complémentaires'),
        ),
        _bodyText(
          'Lorsque des éléments du poste ou de l\'installation n\'ont pu être contrôlés lors de la visite initiale, une intervention complémentaire pourra être programmée à la demande de l\'employeur.\n'
          'Cette mission additionnelle fera alors l\'objet d\'une planification et d\'un rapport spécifique.',
        ),
        pw.SizedBox(height: 7),
        PageTracker(
          key: 'rappel_maintenance',
          registry: trackedPages,
          offset: currentOffset,
          child: _subTitle('4. Surveillance et maintenance des installations électriques'),
        ),
        _bodyText(
          'La vérification de conformité des installations électriques ne constitue qu\'un des éléments concourant à la sécurité des personnes et des biens. Conformément à la norme et aux textes réglementaires applicables, '
          'le chef d\'établissement doit mettre en place une organisation pour les opérations de surveillance et la maintenance des installations électriques. '
          'C\'est dans le cadre de ces opérations que les dispositions doivent être prises afin de remédier aux défectuosités constatées pendant la vérification ou celles qui peuvent se manifester après la vérification.',
        ),
        pw.NewPage(),
        PageTracker(
          key: 'rappel_formation',
          registry: trackedPages,
          offset: currentOffset,
          child: _subTitle('5. Formation du personnel intervenant sur les installations et à proximité'),
        ),
        _bodyText(
          'Conformément aux dispositions réglementaires en vigueur, l\'employeur doit s\'assurer que le personnel appelé à intervenir sur ou à proximité des installations électriques dispose d\'une habilitation électrique adaptée au domaine de tension concerné '
          'et à la nature des opérations à réaliser.',
        ),
        pw.SizedBox(height: 15),
        PageTracker(
          key: 'mesures_securite',
          registry: trackedPages,
          offset: currentOffset,
          child: _sectionBox('MESURES DE SÉCURITÉ AUTOUR DES INSTALLATIONS'),
        ),
        pw.SizedBox(height: 8),
        _bodyText('Suivant la réglementation applicable\u00a0:'),
        _bulletItem('Article 5 \u2013 Arrêté 039/MTPS/IMT du 26 novembre 1984 fixant les mesures générales d\'hygiène et de sécurité sur les lieux de travail\u00a0;'),
        _bulletItem('NFC 18-510\u00a0: Opérations sur les ouvrages et installations électriques et dans un environnement électrique \u2013 Prévention du risque électrique.'),
        pw.SizedBox(height: 5),
        _bodyText('Le personnel doit avoir suivi avec succès une formation en habilitation électrique en fonction du domaine de tension.'),
        pw.SizedBox(height: 5),
        if (_imgHabilitation != null)
          pw.Container(width: double.infinity, child: pw.Image(_imgHabilitation!, fit: pw.BoxFit.fitWidth))
        else
          pw.SizedBox(),
        pw.SizedBox(height: 12),
        _bodyText(
          'Il est rappelé que des dispositions de sécurité particulières et parfaitement définies doivent être prises par le chef de l\'établissement '
          'pour toute intervention de maintenance, réglage, nettoyage sur ou à proximité des installations électriques.\n\n'
          'L\'accès aux locaux et armoires électriques doit être interdit aux personnes non autorisées.',
        ),
        pw.SizedBox(height: 8),
        if (_imgAccesGauche != null || _imgAccesDroite1 != null || _imgAccesDroite2 != null)
          pw.Center(
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (_imgAccesGauche != null)
                  pw.Container(height: 85, child: pw.Image(_imgAccesGauche!, fit: pw.BoxFit.contain)),
                if (_imgAccesGauche != null && (_imgAccesDroite1 != null || _imgAccesDroite2 != null))
                  pw.SizedBox(width: 12),
                if (_imgAccesDroite1 != null)
                  pw.Container(height: 85, child: pw.Image(_imgAccesDroite1!, fit: pw.BoxFit.contain)),
                if (_imgAccesDroite1 != null && _imgAccesDroite2 != null)
                  pw.SizedBox(width: 12),
                if (_imgAccesDroite2 != null)
                  pw.Container(height: 85, child: pw.Image(_imgAccesDroite2!, fit: pw.BoxFit.contain)),
              ],
            ),
          ),
        pw.SizedBox(height: 12),
        _bodyText(
          'En effet, une installation, bien que déclarée conforme en phase d\'exploitation, peut lors d\'opérations, par exemple d\'entretien, '
          'nécessiter des précautions spéciales du fait de la présence à proximité de pièces nues sous tension '
          '(cas des locaux réservés aux électriciens et dans lesquels la réglementation n\'interdit pas la présence de pièces nues sous tension).',
        ),
        pw.SizedBox(height: 7),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PageTracker(
              key: 'mesures_technicien',
              registry: trackedPages,
              offset: currentOffset,
              child: _subTitle('1. Technicien en maintenance des installations'),
            ),
            pw.SizedBox(height: 5),
            _bodyText('Il est fortement recommandé à l\'employeur de faire participer les employés à des séances de formation sur les modules suivants\u00a0:'),
            _bulletItem('Connaissance des normes en électricité (NC 244 C15 00\u2026)\u00a0;'),
            _bulletItem('Maintenance des installations électriques.'),
          ],
        ),
        pw.SizedBox(height: 7),
        pw.NewPage(freeSpace: 110),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PageTracker(
              key: 'mesures_engagement',
              registry: trackedPages,
              offset: currentOffset,
              child: _subTitle('2. Engagement de KES INSPECTIONS AND PROJECTS'),
            ),
            pw.SizedBox(height: 5),
            _bodyText(
              'KES INSPECTIONS AND PROJECTS s\'engage à réaliser ses vérifications dans le strict respect des normes et règlements applicables, '
              'avec le souci constant de la sécurité, de la fiabilité technique et de l\'impartialité des constats.',
            ),
          ],
        ),
      ],
    ));
    final bytesP1_2 = await pdfP1_2.save();
    if (saveFilesToDisk) {
      final chunkP1_2 = File('${tempDir.path}/pdf_chunk_p1_2_$missionId.pdf');
      await chunkP1_2.writeAsBytes(bytesP1_2);
      allChunkFiles.add(chunkP1_2);
    }
    currentOffset += pdfP1_2.document.pdfPageList.pages.length;

    // ── Sub-chunk 1.3 : Résumé exécutif & Analyse statistique ──
    if (saveFilesToDisk) {
      onProgress?.call(0.28, 'Génération du résumé exécutif et des statistiques...');
      await Future.delayed(Duration.zero);
    }
    
    // Récupération réactive du résumé exécutif (avec Fallback 3 Niveaux)
    final summaryData = await MissionExecutiveSummaryService.getOrGenerateSummary(missionId);

    final pdfP1_3 = pw.Document(
      title: 'Résumé Exécutif & Stats - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    pdfP1_3.addPage(pw.MultiPage(
      maxPages: 200,
      pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages),
      header: (ctx) => _buildPageHeaderWidget(
        nomClient: mission.nomClient,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
      ),
      build: (ctx) => [
        ..._buildResumeExecutif(mission, trackedPages, numeroRapportDoc, summaryData: summaryData, offset: currentOffset),
        pw.NewPage(),
        ..._buildAnalyseStatistique(mission, trackedPages, numeroRapportDoc, offset: currentOffset),
      ],
    ));
    final bytesP1_3 = await pdfP1_3.save();
    if (saveFilesToDisk) {
      final chunkP1_3 = File('${tempDir.path}/pdf_chunk_p1_3_$missionId.pdf');
      await chunkP1_3.writeAsBytes(bytesP1_3);
      allChunkFiles.add(chunkP1_3);
    }
    currentOffset += pdfP1_3.document.pdfPageList.pages.length;

    // ── Sub-chunk 1.4 : Renseignements généraux & Description des installations ──
    if (saveFilesToDisk) {
      onProgress?.call(0.38, 'Génération de la description des installations...');
      await Future.delayed(Duration.zero);
    }
    final pdfP1_4 = pw.Document(
      title: 'Description Installations - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    pdfP1_4.addPage(pw.MultiPage(
      maxPages: 200,
      pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages),
      build: (ctx) => [_buildRenseignementsGeneraux(mission, renseignements, trackedPages, offset: currentOffset)],
    ));
    pdfP1_4.addPage(pw.MultiPage(
      maxPages: 200,
      pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages),
      header: (ctx) => _buildPageHeaderWidget(
        nomClient: mission.nomClient,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
      ),
      build: (ctx) => _buildDescriptionInstallationsMulti(description, audit, trackedPages, offset: currentOffset),
    ));
    final bytesP1_4 = await pdfP1_4.save();
    if (saveFilesToDisk) {
      final chunkP1_4 = File('${tempDir.path}/pdf_chunk_p1_4_$missionId.pdf');
      await chunkP1_4.writeAsBytes(bytesP1_4);
      allChunkFiles.add(chunkP1_4);
    }
    currentOffset += pdfP1_4.document.pdfPageList.pages.length;

    // ── Section 6 & 7 : Synthèse Récapitulative et Audit par zone ──
    if (audit != null) {
      if (saveFilesToDisk) {
        onProgress?.call(0.48, 'Génération de la synthèse récapitulative...');
        await Future.delayed(Duration.zero);
      }
      final recapResult = await _addListeRecapitulativeSectionChunked(
        mission,
        audit,
        trackedPages,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
        pageOffset: currentOffset,
        overrideTotalPages: overrideTotalPages,
        saveFilesToDisk: saveFilesToDisk,
      );
      if (saveFilesToDisk) allChunkFiles.addAll(recapResult.files);
      currentOffset += recapResult.totalPages;

      if (saveFilesToDisk) {
        onProgress?.call(0.60, 'Audit détaillé des zones MT et BT...');
        await Future.delayed(Duration.zero);
      }
      final auditResult = await _addAuditSectionChunked(
        mission,
        audit,
        trackedPages,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
        pageOffset: currentOffset,
        overrideTotalPages: overrideTotalPages,
        saveFilesToDisk: saveFilesToDisk,
      );
      if (saveFilesToDisk) allChunkFiles.addAll(auditResult.files);
      currentOffset += auditResult.totalPages;
    }

    // ── Sub-chunk 2.1 : Classement, Foudre, Mesures & Essais, Signatures ──
    if (saveFilesToDisk) {
      onProgress?.call(0.75, 'Génération du classement, foudre et signatures...');
      await Future.delayed(Duration.zero);
    }
    final pdfP2_1 = pw.Document(
      title: 'Classement & Mesures - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    pdfP2_1.addPage(pw.MultiPage(
      maxPages: 200,
      pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages),
      header: (ctx) => _buildPageHeaderWidget(
        nomClient: mission.nomClient,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
      ),
      build: (ctx) => _buildClassementEmplacementsMulti(classements, classementsZones, trackedPages, offset: currentOffset),
    ));
    pdfP2_1.addPage(pw.MultiPage(
      maxPages: 200,
      pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages),
      build: (ctx) => [_buildFoudre(audit, foudres, trackedPages, afficherTableauFoudre: mission.afficherTableauFoudre, offset: currentOffset)],
    ));

    if (mesures != null) {
      _addMesuresEssaisPages(pdfP2_1, mesures, trackedPages, pageOffset: currentOffset, overrideTotalPages: overrideTotalPages, desc: description);
    }
    pdfP2_1.addPage(pw.Page(
      pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages),
      build: (ctx) => _buildSignaturePage(renseignements, currentUser?.fullName, trackedPages, currentOffset),
    ));
    final bytesP2_1 = await pdfP2_1.save();
    if (saveFilesToDisk) {
      final chunkP2_1 = File('${tempDir.path}/pdf_chunk_p2_1_$missionId.pdf');
      await chunkP2_1.writeAsBytes(bytesP2_1);
      allChunkFiles.add(chunkP2_1);
    }
    currentOffset += pdfP2_1.document.pdfPageList.pages.length;

    // ── Sub-chunk 2.2 : Page de garde Photos & Schéma ──
    if (saveFilesToDisk) onProgress?.call(0.82, 'Génération de la section schéma et garde des photos...');
    final pdfP2_2 = pw.Document(
      title: 'Garde Photos & Schéma - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: saveFilesToDisk,
    );
    pdfP2_2.addPage(pw.MultiPage(
      maxPages: 200,
      pageTheme: _buildInnerPageTheme(pageOffset: currentOffset, overrideTotalPages: overrideTotalPages, showWatermark: false),
      header: (ctx) => _buildPageHeaderWidget(
        nomClient: mission.nomClient,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
      ),
      build: (ctx) => [
        pw.SizedBox(height: 220),
        pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(width: 350, height: 2, color: accentColor),
              pw.SizedBox(height: 24),
              PageTracker(
                key: 'photos',
                registry: trackedPages,
                offset: currentOffset,
                child: pw.Text(
                  'PHOTOS',
                  style: pw.TextStyle(
                    font: _fontBold, fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: headerColor,
                    letterSpacing: 1.0,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                nomSiteHeader.isNotEmpty ? nomSiteHeader.toUpperCase() : mission.nomClient.toUpperCase(),
                style: pw.TextStyle(
                  font: _fontRegular, fontSize: 13, color: accentColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 24),
              pw.Container(width: 350, height: 2, color: accentColor),
            ],
          ),
        ),
      ],
    ));
    final bytesP2_2 = await pdfP2_2.save();
    if (saveFilesToDisk) {
      final chunkP2_2 = File('${tempDir.path}/pdf_chunk_p2_2_$missionId.pdf');
      await chunkP2_2.writeAsBytes(bytesP2_2);
      allChunkFiles.add(chunkP2_2);
    }
    currentOffset += pdfP2_2.document.pdfPageList.pages.length;

    // ── Section 13 : Photos Chunked ──
    if (saveFilesToDisk) onProgress?.call(0.87, 'Traitement et compression des photos d\'illustration...');
    final photoResult = await _addPhotosSectionChunked(
      mission,
      missionId,
      audit,
      description,
      trackedPages,
      nomSite: nomSiteHeader,
      numeroRapport: numeroRapportDoc,
      pageOffset: currentOffset,
      overrideTotalPages: overrideTotalPages,
      saveFilesToDisk: saveFilesToDisk,
    );
    if (saveFilesToDisk) allChunkFiles.addAll(photoResult.files);
    currentOffset += photoResult.totalPages;

    // ── Sub-chunk 2.3 : Schéma d'exploitation (Placé à la FIN du document si schemaOption == 'oui') ──
    final hasSchema = mission.schemaOption?.trim().toLowerCase() == 'oui';
    if (hasSchema) {
      final pdfSchema = pw.Document(
        title: 'Schéma - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: saveFilesToDisk,
      );
      _addSchemaSection(
        pdfSchema,
        mission,
        trackedPages,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
        pageOffset: currentOffset,
        overrideTotalPages: overrideTotalPages,
      );
      final bytesSchema = await pdfSchema.save();
      if (saveFilesToDisk) {
        final chunkSchema = File('${tempDir.path}/pdf_chunk_schema_$missionId.pdf');
        await chunkSchema.writeAsBytes(bytesSchema);
        allChunkFiles.add(chunkSchema);
      }
      currentOffset += pdfSchema.document.pdfPageList.pages.length;
    }

    final totalReportPages = currentOffset;

    // ── Sub-chunk 1.1 : Couverture, Intervenants & Sommaire (Généré en dernier) ──
    if (saveFilesToDisk) {
      onProgress?.call(0.92, 'Génération du sommaire dynamique et finalisation...');
      final pdfP1_1 = pw.Document(
        title: 'Couverture, Intervenants & Sommaire - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: saveFilesToDisk,
      );
      final jsaP1_1 = HiveService.getJSAByMissionId(mission.id);
      pdfP1_1.addPage(
        pw.Page(
          pageTheme: _buildCoverPageTheme(),
          build: (ctx) => _buildCoverPage(mission, renseignements, ctx),
        ),
      );
      pdfP1_1.addPage(
        pw.Page(
          pageTheme: _buildInnerPageTheme(pageOffset: 0, overrideTotalPages: totalReportPages),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPageHeaderWidget(
                nomClient: mission.nomClient,
                nomSite: nomSiteHeader,
                numeroRapport: numeroRapportDoc,
              ),
              pw.SizedBox(height: 8),
              _buildIntervenantsEtResponsabilitesPage(jsaP1_1, renseignements, currentUser, trackedPages, 0),
            ],
          ),
        ),
      );
      _addSommairePages(
        pdfP1_1,
        sommaireEntries,
        trackedPages,
        nomClient: mission.nomClient,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
        pageOffset: 0,
        overrideTotalPages: totalReportPages,
      );
      final chunkP1_1 = File('${tempDir.path}/pdf_chunk_p1_1_$missionId.pdf');
      final bytesP1_1 = await pdfP1_1.save();
      await chunkP1_1.writeAsBytes(bytesP1_1);

      allChunkFiles.insert(0, chunkP1_1);
    }

    return _GeneratedReportResult(
      files: allChunkFiles,
      trackedPages: trackedPages,
      totalReportPages: totalReportPages,
    );
  }

  static Future<File?> generateMissionReport(
    String missionId, {
    PdfProgressCallback? onProgress,
  }) async {
    List<File> allChunkFiles = [];
    Directory? sessionDir;
    try {
      onProgress?.call(0.02, 'Initialisation des ressources et des polices...');
      await _loadImages();
      await _loadFonts();
      
      // Permettre au Thread UI de traiter les callbacks de progression
      await Future.delayed(Duration.zero);
      
      onProgress?.call(0.05, 'Chargement des données de la mission...');
      final mission = HiveService.getMissionById(missionId);
      if (mission == null) return null;
      
      final description = HiveService.getDescriptionInstallationsByMissionId(missionId);
      final audit = HiveService.getAuditInstallationsByMissionId(missionId);
      final classements = HiveService.getEmplacementsByMissionId(missionId);
      final classementsZones = HiveService.getClassementsZonesByMissionId(missionId);
      final mesures = HiveService.getMesuresEssaisByMissionId(missionId);
      final foudres = HiveService.getFoudreObservationsByMissionId(missionId);
      final renseignements = HiveService.getRenseignementsGenerauxByMissionId(missionId);
      final currentUser = HiveService.getCurrentUser();

      final nomSiteHeader = renseignements?.nomSite.isNotEmpty == true
          ? renseignements!.nomSite
          : (mission.nomSite ?? '');
      const String numeroRapportDoc = 'KES/IP/VE/2025/001';

      final systemTempDir = await getTemporaryDirectory();
      final sessionTimestamp = DateTime.now().millisecondsSinceEpoch;
      sessionDir = Directory('${systemTempDir.path}/pdf_session_${missionId}_$sessionTimestamp');
      await sessionDir.create(recursive: true);

      // ── Passe 1 : Calcul préliminaire de la pagination totale et enregistrement des clés ──
      onProgress?.call(0.10, 'Calcul préliminaire de la pagination et du sommaire...');
      await Future.delayed(Duration.zero);

      final pass1Result = await _generateReportPass(
        mission: mission,
        missionId: missionId,
        audit: audit,
        description: description,
        classements: classements,
        classementsZones: classementsZones,
        mesures: mesures,
        foudres: foudres,
        renseignements: renseignements,
        currentUser: currentUser,
        nomSiteHeader: nomSiteHeader,
        numeroRapportDoc: numeroRapportDoc,
        tempDir: sessionDir,
        saveFilesToDisk: false,
      );

      final totalReportPages = pass1Result.totalReportPages;

      // ── Passe 2 : Génération finale avec numérotation Page X / N et enregistrement sur disque ──
      onProgress?.call(0.15, 'Génération des fichiers PDF avec pagination Page / $totalReportPages...');
      await Future.delayed(Duration.zero);

      final pass2Result = await _generateReportPass(
        mission: mission,
        missionId: missionId,
        audit: audit,
        description: description,
        classements: classements,
        classementsZones: classementsZones,
        mesures: mesures,
        foudres: foudres,
        renseignements: renseignements,
        currentUser: currentUser,
        nomSiteHeader: nomSiteHeader,
        numeroRapportDoc: numeroRapportDoc,
        tempDir: sessionDir,
        overrideTotalPages: totalReportPages,
        saveFilesToDisk: true,
        onProgress: onProgress,
      );

      allChunkFiles = pass2Result.files;

      // ── Assembly final par fusion binaire ──
      onProgress?.call(0.96, 'Fusion binaire haute performance du document final...');
      final fileName = 'Rapport_${mission.nomClient}_${_formatDate(DateTime.now())}_$sessionTimestamp.pdf'
          .replaceAll(RegExp(r'[<>:"/\\|?*\s]'), '_');
      final outputFile = File('${systemTempDir.path}/$fileName');

      final finalPdfFile = await PdfMergerService.mergePdfFiles(
        allChunkFiles,
        outputFile,
        deleteChunksAfterMerge: false,
        onProgress: onProgress,
      );

      if (kDebugMode && await finalPdfFile.exists()) {
        final double sizeMb = (await finalPdfFile.length()) / (1024 * 1024);
        print('⚡ [PDF Compression] Rapport généré avec succès avec compression adaptative : ${sizeMb.toStringAsFixed(2)} Mo ($totalReportPages pages)');
      }

      onProgress?.call(1.0, 'Génération du rapport terminée avec succès.');
      return finalPdfFile;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Erreur lors de la génération du rapport PDF: $e\n$stackTrace');
      }
      return null;
    } finally {
      // Nettoyage final exhaustif de tous les fichiers chunks et du dossier de session temporaire
      for (final chunkFile in allChunkFiles) {
        try {
          if (chunkFile.existsSync()) {
            chunkFile.deleteSync();
          }
        } catch (_) {}
      }
      if (sessionDir != null) {
        try {
          if (await sessionDir.exists()) {
            await sessionDir.delete(recursive: true);
          }
        } catch (_) {}
      }
    }
  }
  
  static String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  static Future<void> shareReport(File file) async {
    try {
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)],
          subject: 'Rapport d\'Audit Electrique PDF',
          text: 'Veuillez trouver ci-joint le rapport d\'audit electrique.');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur partage PDF: $e');
      }
    }
  }

  static Future<void> deleteReport(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur suppression PDF: $e');
      }
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  HELPERS PUBLICS REUTILISABLES PAR LES MODULES DEDIES (EX: PdfReportLightService)
  // ──────────────────────────────────────────────────────────────

  static pw.PageTheme buildCoverPageTheme() => _buildCoverPageTheme();
  static pw.PageTheme buildInnerPageTheme() => _buildInnerPageTheme();
  static pw.Widget buildCoverPage(
          Mission mission, RenseignementsGeneraux? rg, pw.Context ctx,
          {String? subTitleOverride}) =>
      _buildCoverPage(mission, rg, ctx, subTitleOverride: subTitleOverride);
  static pw.Widget buildPageHeaderWidget(
          {String? nomClient, String? nomSite, String? numeroRapport}) =>
      _buildPageHeaderWidget(
          nomClient: nomClient, nomSite: nomSite, numeroRapport: numeroRapport);
  static void addSommairePages(
          pw.Document pdf, List<SommaireEntry> entries, Map<String, int> trackedPages,
          {String? nomClient, String? nomSite, String? numeroRapport}) =>
      _addSommairePages(pdf, entries, trackedPages,
          nomClient: nomClient, nomSite: nomSite, numeroRapport: numeroRapport);
  static pw.Widget sectionBox(String title) => _sectionBox(title);
  static pw.Widget subTitle(String title) => _subTitle(title);
  static pw.TableRow tableHeaderRow(List<String> headers) =>
      _tableHeaderRow(headers);
  static pw.TableRow tableDataRow(List<String> data, {required bool alt}) =>
      _tableDataRow(data, alt: alt);
  static pw.Widget cell(String text,
          {required bool isHeader,
          PdfColor? color,
          int colspan = 1,
          bool centered = false}) =>
      _cell(text, isHeader: isHeader, color: color, colspan: colspan, centered: centered);
  static Future<void> loadImages() => _loadImages();
  static Future<void> loadFonts() => _loadFonts();
  static pw.Font get fontRegular => _fontRegular;
  static pw.Font get fontBold => _fontBold;
  static pw.MemoryImage? get logoKesImage => _logoKesImage;
  static pw.MemoryImage? get firstPageFooterImage => _firstPageFooterImage;
  static String formatDate(DateTime d) => _formatDate(d);
}

// ================================================================
//  Classes internes (mises à jour)
// ================================================================

class _ObsRecap {
  final String localisation;
  final String coffret;
  final String observation;
  final String refNorm;
  final String priorite;
  final String? repere;
  _ObsRecap({
    required this.localisation,
    required this.coffret,
    required this.observation,
    required String refNorm,
    required this.priorite,
    this.repere,
  }) : refNorm = refNorm.replaceAll(RegExp(r'§\s*'), 'art ');
}


class _ObsGroup {
  final String local;
  final List<_ObsRecap> items;
  _ObsGroup({required this.local, required this.items});
}

class _ParafoudreEquipementRow {
  final String observation;
  final String localisation;
  _ParafoudreEquipementRow({required this.observation, required this.localisation});
}

class _EquipmentPhotoGroup {
  final CoffretArmoire coffret;
  final String locationPrefix;
  final _PhotoEntry? extPhoto;
  final _PhotoEntry? intPhoto;
  final List<_PhotoEntry> obsPhotos;

  _EquipmentPhotoGroup({
    required this.coffret,
    required this.locationPrefix,
    this.extPhoto,
    this.intPhoto,
    required this.obsPhotos,
  });

  bool get hasPhotos => extPhoto != null || intPhoto != null || obsPhotos.isNotEmpty;
  int get totalPhotosCount => (extPhoto != null ? 1 : 0) + (intPhoto != null ? 1 : 0) + obsPhotos.length;
}

class _PhotoEntry {
  final String filePath;
  final String description;
  final String? repere;
  final bool isObservation;
  final String? badgeLabel;
  final PdfColor? badgeBgColor;
  final PdfColor? badgeTextColor;

  _PhotoEntry({
    required this.filePath,
    required this.description,
    this.repere,
    this.isObservation = false,
    this.badgeLabel,
    this.badgeBgColor,
    this.badgeTextColor,
  });
}

class SommaireEntry {
  final String titre;
  final String key;
  final int level;
  final bool isBold;
  final bool isUppercase;

  SommaireEntry({
    required this.titre,
    required this.key,
    required this.level,
    this.isBold = false,
    this.isUppercase = false,
  });
}

typedef _SommaireEntry = SommaireEntry;

class PageTracker extends pw.SingleChildWidget {
  final String key;
  final Map<String, int> registry;
  final int offset;

  PageTracker({required this.key, required pw.Widget child, required this.registry, this.offset = 0})
      : super(child: child);

  @override
  void layout(pw.Context context, pw.BoxConstraints constraints, {bool parentUsesSize = false}) {
    super.layout(context, constraints, parentUsesSize: parentUsesSize);
    registry[key] = context.pageNumber + offset;
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    paintChild(context);
  }
}

class PageNumberText extends pw.Widget {
  final String keyName;
  final Map<String, int> registry;
  final pw.TextStyle style;

  PageNumberText({required this.keyName, required this.registry, required this.style});

  String _getText() {
    final pageNum = registry[keyName];
    return pageNum != null ? pageNum.toString() : '--';
  }

  @override
  void layout(pw.Context context, pw.BoxConstraints constraints, {bool parentUsesSize = false}) {
    final textWidget = pw.Text(_getText(), style: style);
    textWidget.layout(context, constraints, parentUsesSize: parentUsesSize);
    box = textWidget.box;
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    final textWidget = pw.Text(
      _getText(),
      style: style,
      textAlign: pw.TextAlign.right,
    );
    textWidget.layout(context, pw.BoxConstraints.tight(box!.size));
    textWidget.box = box;
    textWidget.paint(context);
  }
}

class _ClassementRow {
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

  _ClassementRow({
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

class _ChunkSectionResult {
  final List<File> files;
  final int totalPages;
  _ChunkSectionResult({required this.files, required this.totalPages});
}

class _GeneratedReportResult {
  final List<File> files;
  final Map<String, int> trackedPages;
  final int totalReportPages;
  _GeneratedReportResult({
    required this.files,
    required this.trackedPages,
    required this.totalReportPages,
  });
}

class _ParsedObservationRow {
  final String observation;
  final String stats;
  final String constatMajeur;

  _ParsedObservationRow({
    required this.observation,
    required this.stats,
    required this.constatMajeur,
  });
}