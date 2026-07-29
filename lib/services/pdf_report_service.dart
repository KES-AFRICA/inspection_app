// pdf_report_service.dart 

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:inspec_app/models/classement_zone.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:inspec_app/services/pdf/pdf_chunk_merger.dart';
import 'dispositions_constructives_registry.dart';
import 'statistics/mission_statistics_collector.dart';
import 'statistics/audit_finding.dart';
import 'statistics/audit_diagnostic_engine.dart';

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
      'CALIBRE DU DISJONCTEUR',
      'SECTION DU CABLE',
      'NATURE DU RESEAU',
      'OBSERVATIONS',
    ],
    'BT': [
      'PUISSANCE TRANSFORMATEUR',
      'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR',
      'SECTION DU CABLE',
      'TENSION',
      'OBSERVATIONS',
    ],
    'GROUPE': [
      'N\u00B0',
      'MARQUE',
      'TYPE',
      'N\u00B0 SERIE',
      'PUISSANCE (KVA)',
      'INTENSITE',
      'ANNEE DE FABRICATION',
      'CALIBRE DU DISJONCTEUR',
      'SECTION DU CABLE',
    ],
    'CARBURANT': [
      'N\u00B0',
      'MODE',
      'CAPACITE',
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
  };

  /// Charge toutes les images necessaires (appele une seule fois)
  static Future<void> _loadImages() async {
    if (_imagesLoaded) return;
    
    Future<pw.MemoryImage?> tryLoad(String asset, {int? maxWidth, int? maxHeight}) async {
      try {
        final data = await rootBundle.load(asset);
        final bytes = data.buffer.asUint8List();
        if (maxWidth != null || maxHeight != null) {
          try {
            final compressed = await FlutterImageCompress.compressWithList(
              bytes,
              minWidth: maxWidth ?? 400,
              minHeight: maxHeight ?? 400,
              quality: 85,
              format: CompressFormat.png,
            );
            if (compressed.isNotEmpty) {
              return pw.MemoryImage(compressed);
            }
          } catch (_) {}
        }
        return pw.MemoryImage(bytes);
      } catch (e) {
        if (kDebugMode) print('Image non trouvee: $asset');
        return null;
      }
    }
    
    _watermarkImage       = await tryLoad('assets/images/filigranne_image.png');
    _firstPageFooterImage = await tryLoad('assets/images/firstpage_footer.png');
    _otherPageFooterImage = await tryLoad('assets/images/otherpage_footer.png');
    _logoKesImage         = await tryLoad('assets/images/logo.png', maxWidth: 400, maxHeight: 150);
    _imgHabilitation      = await tryLoad('assets/images/image.png');
    _imgAccesGauche       = await tryLoad('assets/images/image copy.png');
    _imgAccesDroite1      = await tryLoad('assets/images/image copy 2.png');
    _imgAccesDroite2      = await tryLoad('assets/images/image copy 3.png');
    
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
  
  /// Thème couverture (footer firstPage)
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
      buildBackground: (ctx) => _buildWatermarkBackground(),
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

  // Footer bord à bord physique
  static pw.Widget _buildFooterAbsolute({
    required bool isFirstPage,
    required pw.Context ctx,
    int pageOffset = 0,
    int? overrideTotalPages,
  }) {
    final footerImg = isFirstPage ? _firstPageFooterImage : _otherPageFooterImage;
    final double footerImgHeight = isFirstPage ? 80.0 : 50.0;
    const double descente = kBottomMargin + 40;

    final pageNum = ctx.pageNumber + pageOffset;
    final totalPagesStr = overrideTotalPages != null ? '$overrideTotalPages' : '${ctx.pagesCount}';

    return pw.Stack(
      overflow: pw.Overflow.visible,
      children: [
        pw.Positioned(
          bottom: -descente,
          left:  -kLeftMargin,
          right: -kRightMargin,
          child: pw.SizedBox(
            height: footerImgHeight,
            width: PdfPageFormat.a4.width,
            child: footerImg != null
                ? pw.Image(footerImg, fit: pw.BoxFit.fill)
                : pw.Container(
                    color: PdfColors.blueGrey800,
                    child: pw.Center(
                      child: pw.Text('FOOTER MANQUANT',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                    ),
                  ),
          ),
        ),
        if (!isFirstPage)
          pw.Positioned(
            bottom: -descente + 20,
            left:   -kLeftMargin + kLeftMargin,
            child: pw.Text(
              'Page $pageNum / $totalPagesStr',
              style: pw.TextStyle(
                font: _fontRegular,
                fontSize: 7.5,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
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

    pw.MemoryImage? clientLogoMemoryImg;
    if (mission.logoClient != null && mission.logoClient!.isNotEmpty) {
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

    pw.MemoryImage? clientQrMemoryImg;
    if (mission.qrCodeClient != null && mission.qrCodeClient!.isNotEmpty) {
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

    // 1. Objet de la vérification
    entries.add(_SommaireEntry(titre: "OBJET DE LA VERIFICATION", key: 'objet', level: 0, isBold: true, isUppercase: true));
    entries.add(_SommaireEntry(titre: "Références normatives et règlementaires", key: 'objet', level: 1));
    entries.add(_SommaireEntry(titre: "Matériel utilisé", key: 'objet', level: 1));

    // 2. Périmètre de la mission
    entries.add(_SommaireEntry(titre: "PERIMETRE DE LA MISSION", key: 'perimetre', level: 0, isBold: true, isUppercase: true));

    // 3. Rappel des responsabilités
    entries.add(_SommaireEntry(titre: "RAPPEL DES RESPONSABILITES DE L'EMPLOYEUR", key: 'rappel', level: 0, isBold: true, isUppercase: true));
    entries.add(_SommaireEntry(titre: "Responsabilité et accompagnement", key: 'rappel', level: 1));
    entries.add(_SommaireEntry(titre: "Conditions de réalisation", key: 'rappel', level: 1));
    entries.add(_SommaireEntry(titre: "Vérifications complémentaires", key: 'rappel', level: 1));
    entries.add(_SommaireEntry(titre: "Surveillance & maintenance des installations électriques", key: 'rappel', level: 1));
    entries.add(_SommaireEntry(titre: "Formation du personnel intervenant sur les installations et à proximité", key: 'rappel', level: 1));
    entries.add(_SommaireEntry(titre: "MESURES DE SECURITE AUTOUR DES INSTALLATIONS", key: 'mesures_securite', level: 1, isBold: true, isUppercase: true));
    entries.add(_SommaireEntry(titre: "Technicien en maintenance des installations", key: 'mesures_securite', level: 1));
    entries.add(_SommaireEntry(titre: "Engagement de KES INSPECTIONS AND PROJECTS", key: 'mesures_securite', level: 1));

    // 4. Résumé Exécutif (Immédiatement après MESURES DE SÉCURITÉ)
    entries.add(_SommaireEntry(titre: "RESUME EXECUTIF", key: 'resume_executif', level: 0, isBold: true, isUppercase: true));

    // 5. Analyse Statistique (Immédiatement après Résumé Exécutif)
    entries.add(_SommaireEntry(titre: "ANALYSE STATISTIQUE", key: 'analyse_statistique', level: 0, isBold: true, isUppercase: true));
    entries.add(_SommaireEntry(titre: "Principales non-conformités et répartition", key: 'analyse_statistique', level: 1));
    entries.add(_SommaireEntry(titre: "Statistique par type de défaut", key: 'stat_defauts', level: 1));
    entries.add(_SommaireEntry(titre: "Répartition par domaine de tension", key: 'stat_tension', level: 1));
    entries.add(_SommaireEntry(titre: "Non-conformités croisées par catégorie d'équipement", key: 'stat_croisee', level: 1));
    entries.add(_SommaireEntry(titre: "Inventaire chiffré des installations et équipements", key: 'stat_inventaire', level: 1));

    // 6. Renseignements généraux
    entries.add(_SommaireEntry(titre: "RENSEIGNEMENTS GENERAUX DE L'ETABLISSEMENT", key: 'renseignements', level: 0, isBold: true, isUppercase: true));
    entries.add(_SommaireEntry(titre: "Renseignements principaux", key: 'renseignements_principaux', level: 1));
    entries.add(_SommaireEntry(titre: "Documents nécessaires à la vérification", key: 'renseignements_documents', level: 1));
    entries.add(_SommaireEntry(titre: "Habilitation électrique du personnel d'intervention", key: 'renseignements_habilitation', level: 1));

    // 4. Description des installations
    entries.add(_SommaireEntry(titre: "DESCRIPTION DES INSTALLATIONS", key: 'description', level: 0, isBold: true, isUppercase: true));
    entries.add(_SommaireEntry(titre: "Zones et Locaux à risque", key: 'desc_locaux_risques', level: 1));

    // 5. Liste récapitulative
    if (audit != null) {
      entries.add(_SommaireEntry(titre: "SYNTHESE RECAPITULATIVE DES OBSERVATIONS", key: 'liste_recap', level: 0, isBold: true, isUppercase: true));
      entries.add(_SommaireEntry(titre: "Moyenne tension", key: 'liste_recap_mt', level: 1));
      entries.add(_SommaireEntry(titre: "Basse tension", key: 'liste_recap_bt', level: 1));
    }

    // 6. Audit des installations
    if (audit != null) {
      entries.add(_SommaireEntry(titre: "AUDIT DES INSTALLATIONS ELECTRIQUES", key: 'audit', level: 0, isBold: true, isUppercase: true));
    }

    // 7. Classement
    entries.add(_SommaireEntry(titre: "CLASSEMENT ET EMPLACEMENTS DES LOCAUX ET ZONES EN FONCTION DES INFLUENCES EXTERNES", key: 'classement', level: 0, isBold: true, isUppercase: true));

    // 8. Foudre
    entries.add(_SommaireEntry(titre: "FOUDRE", key: 'foudre', level: 0, isBold: true, isUppercase: true));

    // 9. Mesures et essais
    if (mesures != null) {
      entries.add(_SommaireEntry(titre: "RESULTATS DES MESURES ET ESSAIS", key: 'mesures', level: 0, isBold: true, isUppercase: true));
      entries.add(_SommaireEntry(titre: "Conditions de mesure", key: 'mesures_conditions', level: 1));
      entries.add(_SommaireEntry(titre: "Essais de démarrage automatique du groupe électrogène", key: 'mesures_demarrage', level: 1));
      entries.add(_SommaireEntry(titre: "Test de fonctionnement de l'arrêt d'urgence", key: 'mesures_arret', level: 1));
      entries.add(_SommaireEntry(titre: "Prise de terre", key: 'mesures_terre', level: 1));
      entries.add(_SommaireEntry(titre: "Essais de déclenchement des dispositifs différentiels et mesure d'isolement", key: 'mesures_ddr', level: 1));
      entries.add(_SommaireEntry(titre: "Continuité et de la résistance des conducteurs de protection et des liaisons équipotentielles", key: 'mesures_continuite', level: 1));
    }

    // 10. Photos
    entries.add(_SommaireEntry(titre: "PHOTOS", key: 'photos', level: 0, isBold: true, isUppercase: true));

    // 11. Schéma des installations électriques (si Oui)
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
  }) {
    pdf.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(),
      header: (ctx) => _buildPageHeaderWidget(
        nomClient: nomClient,
        nomSite: nomSite,
        numeroRapport: numeroRapport,
      ),
      build: (ctx) => [
        pw.Center(
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
    final double leftPadding = entry.level * 15.0;
    
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
            padding: const pw.EdgeInsets.only(right: 32.0),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (leftPadding > 0) pw.SizedBox(width: leftPadding),
                pw.Flexible(
                  child: pw.Text(
                    titleText.trim(),
                    style: pw.TextStyle(font: font, fontSize: fontSize, color: color),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  child: pw.ClipRect(
                    child: pw.Container(
                      width: double.infinity,
                      child: pw.Text(
                        '.' * 400,
                        style: pw.TextStyle(
                          font: _fontRegular,
                          fontSize: fontSize - 1,
                          color: PdfColors.grey500,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 4),
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
      'Articles 6, 112, 113 \u2013 Arr\u00eat\u00e9 039/MTPS/IMT du 26 novembre 1984 fixant les mesures g\u00e9n\u00e9rales d\'hygi\u00e8ne et de s\u00e9curit\u00e9 sur les lieux de travail',
      'Cahier de prescription technique applicable au D\u00e9cret N\u00b0\u00a020181969/PM du 15 mars 2018, fixant les r\u00e8gles de base de s\u00e9curit\u00e9 incendie dans les b\u00e2timents',
      'Arr\u00eat\u00e9 conjoint 002164 du 21 juin 2012 MNIMIDT/MINEE',
      'Loi N\u00b0\u00a0896/PJL/AN du 15/11/2011',
      'NC 244 C 15 100 \u2013 Installation \u00e9lectrique \u00e0 basse tension',
      'NF C 15 100 \u2013 Installation \u00e9lectrique \u00e0 basse tension',
      'Norme NF C 13 100 \u2013 Poste de livraison \u00e9tabli \u00e0 l\'int\u00e9rieur d\'un b\u00e2timent et aliment\u00e9 par un r\u00e9seau de distribution publique de deuxi\u00e8me cat\u00e9gorie',
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      children: normes.asMap().entries.map((e) {
        return pw.TableRow(
          decoration: pw.BoxDecoration(color: e.key.isEven ? PdfColors.white : tableRowAlt),
          children: [
            _cell(e.value, isHeader: false),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _buildMaterielTable() {
    final materiel = [
      ['Mesure de la r\u00e9sistance de prises de terre', 'FLUKE \u2013 1630 2 FC'],
      ['Mesure de l\'isolement', 'CHAUVIN ARNOUX CA 6462'],
      ['V\u00e9rification de la continuit\u00e9 et de la r\u00e9sistance des conducteurs de protection et des liaisons \u00e9quipotentielles', 'CHAUVIN ARNOUX CA 6462'],
      ['Test de d\u00e9clenchement des dispositifs diff\u00e9rentiels et mesure des imp\u00e9dances de boucle', 'CHAUVIN ARNOUX CA 6462'],
      ['Contr\u00f4leur d\'installation \u00e9lectrique', 'CHAUVIN ARNOUX CA 6116N'],
      ['Analyseur de r\u00e9seaux', 'CHAUVIN ARNOUX PEL 103 140631NFH'],
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        _tableHeaderRow(['Description', 'Appareil / R\u00e9f\u00e9rence']),
        ...materiel.asMap().entries.map((e) =>
          _tableDataRow(e.value, alt: e.key.isOdd)),
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

    pw.Widget buildInfoRow(String label, pw.Widget contentWidget, {required bool isLast, required bool isOdd}) {
      final bg = isOdd ? PdfColor.fromHex('#F8FAFC') : PdfColors.white;
      return pw.Container(
        decoration: pw.BoxDecoration(
          color: bg,
          border: isLast
              ? null
              : pw.Border(
                  bottom: pw.BorderSide(color: gridColor, width: borderWidth),
                ),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: leftColWidth,
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  right: pw.BorderSide(color: gridColor, width: borderWidth),
                ),
              ),
              child: pw.Text(label, style: labelStyle),
            ),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: contentWidget,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: gridColor, width: borderWidth),
      ),
      child: pw.Column(
        children: [
          // ── PARTIE A: MISSIONS (PÉRIMÈTRE - CELLULE UNIQUE À GAUCHE / ROWSPAN FACTEL) ──
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: gridColor, width: borderWidth),
              ),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: leftColWidth,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  alignment: pw.Alignment.centerLeft,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border(
                      right: pw.BorderSide(color: gridColor, width: borderWidth),
                    ),
                  ),
                  child: pw.Text('Missions', style: labelStyle),
                ),
                pw.Expanded(
                  child: pw.Column(
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
                ),
              ],
            ),
          ),

          // ── PARTIE B: INFORMATIONS GÉNÉRALES ──
          buildInfoRow(
            'Nature',
            pw.Text(mission.natureMission ?? 'Périodique réglementaire', style: valueStyle),
            isLast: false,
            isOdd: false,
          ),
          buildInfoRow(
            'Dates d\'intervention',
            pw.Text(dateInterventionStr, style: valueStyle),
            isLast: false,
            isOdd: true,
          ),
          buildInfoRow(
            'Durée',
            pw.Text('$dureeJours jour(s)', style: valueStyle),
            isLast: false,
            isOdd: false,
          ),
          buildInfoRow(
            'Accompagnateur / Responsable',
            pw.Text(accompagnateursStr, style: valueStyle),
            isLast: false,
            isOdd: true,
          ),
          buildInfoRow(
            'Compte rendu de fin de visite fait à',
            pw.Text(compteRenduStr, style: valueStyle),
            isLast: false,
            isOdd: false,
          ),
          buildInfoRow(
            'Vérificateur(s)',
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: verificateursList.map((v) => pw.Text(v, style: valueStyle)).toList(),
            ),
            isLast: true,
            isOdd: true,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  ANALYSE STATISTIQUE
  // ──────────────────────────────────────────────────────────────

  static String _formatPercent(double val) {
    return '${val.toStringAsFixed(1).replaceAll('.', ',')} %';
  }

  static pw.Widget _buildCalloutBox(String title, String body) {
    final borderColor = PdfColor.fromHex('#D97706');
    final bgColor = PdfColor.fromHex('#FFFBEB');
    final titleColor = PdfColor.fromHex('#B45309');

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: pw.Border.all(color: borderColor, width: 1.0),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
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
              color: titleColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            body,
            style: pw.TextStyle(
              font: _fontRegular,
              fontSize: 8.5,
              color: PdfColor.fromHex('#334155'),
              lineSpacing: 1.5,
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
            'R\u00e9partition des non-conformit\u00e9s par criticit\u00e9',
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: headerColor,
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
                        pw.Text('Critique', style: pw.TextStyle(font: _fontBold, fontSize: 8.5, color: headerColor)),
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
                        pw.Text('Majeure', style: pw.TextStyle(font: _fontBold, fontSize: 8.5, color: headerColor)),
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
                        pw.Text('Mineure', style: pw.TextStyle(font: _fontBold, fontSize: 8.5, color: headerColor)),
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
    final tableBorderColor = PdfColor.fromHex('#CBD5E1');
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
      border: pw.TableBorder.all(color: tableBorderColor, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.5),
        1: pw.FlexColumnWidth(3.0),
        2: pw.FlexColumnWidth(3.5),
      },
      children: [
        // En-tête
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
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

  static List<pw.Widget> _buildAnalyseStatistique(
    Mission mission,
    Map<String, int> trackedPages,
    String numeroRapportDoc,
  ) {
    final widgets = <pw.Widget>[];

    // Collecte unifiée via la pipeline statistique centralisée et impression d'inventaire
    final inventory = MissionStatisticsCollector.getInventory(mission.id);
    inventory.printFullInventoryDetails();
    final stats = MissionStatisticsCollector.collect(mission.id);
    final cStats = stats.criticalityStats;

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
      child: _sectionBox('ANALYSE STATISTIQUE'),
    ));
    widgets.add(pw.SizedBox(height: 10));

    // I. Sous-section : Non-conformités de l'année passée
    widgets.add(_subTitle('Non-conformit\u00e9s de l\'ann\u00e9e pass\u00e9e'));
    widgets.add(pw.SizedBox(height: 5));
    widgets.add(_buildCalloutBox(
      'Donn\u00e9e non disponible',
      'Le pr\u00e9sent rapport porte sur la premi\u00e8re visite de v\u00e9rification p\u00e9riodique disposant d\'une check-list num\u00e9rique structur\u00e9e pour ce site (Rapport n\u00b0 $numeroRapportDoc). Aucun rapport ant\u00e9rieur exploitable au m\u00eame format n\'a \u00e9t\u00e9 fourni pour extraire le nombre de non-conformit\u00e9s de l\'ann\u00e9e pass\u00e9e. Si un rapport ant\u00e9rieur existe, merci de le transmettre : cette section et la comparaison ci-dessous seront compl\u00e9t\u00e9es automatiquement.',
    ));
    widgets.add(pw.SizedBox(height: 10));

    // II. Sous-section : Comparaison avec celles de cette année
    widgets.add(_subTitle('Comparaison avec celles de cette ann\u00e9e'));
    widgets.add(pw.SizedBox(height: 5));
    widgets.add(_bodyText(
      'Non calculable en l\'absence de donn\u00e9es de r\u00e9f\u00e9rence de l\'ann\u00e9e pr\u00e9c\u00e9dente (voir ci-dessus). \u00c0 titre indicatif, les non-conformit\u00e9s de la pr\u00e9sente visite se r\u00e9partissent comme suit :',
    ));
    widgets.add(pw.SizedBox(height: 8));

    // III & IV. Graphique & Tableau des criticités
    widgets.add(_buildBarChart(critique, majeure, mineure));
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(_buildCriticiteTable(critique, majeure, mineure, total, pctCritique, pctMajeure, pctMineure));
    widgets.add(pw.SizedBox(height: 10));

    // V. Sous-section : Taux de mise en conformité
    widgets.add(_subTitle('Taux de mise en conformit\u00e9'));
    widgets.add(pw.SizedBox(height: 5));
    widgets.add(_buildCalloutBox(
      'Donn\u00e9e partiellement disponible',
      'Le taux de mise en conformit\u00e9 (\u00e9volution entre deux visites successives : non-conformit\u00e9s sold\u00e9es / non-conformit\u00e9s totales de l\'ann\u00e9e pr\u00e9c\u00e9dente) ne peut pas \u00eatre calcul\u00e9 sans le rapport de l\'ann\u00e9e pass\u00e9e. Il pourra \u00eatre renseign\u00e9 d\u00e8s r\u00e9ception de ce document de r\u00e9f\u00e9rence.',
    ));
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(_bodyText(
      'Le taux de conformit\u00e9 global mesur\u00e9 lors de la pr\u00e9sente visite (part des points de v\u00e9rification jug\u00e9s conformes sur l\'ensemble des points contr\u00f4l\u00e9s) n\u00e9cessite l\'export du d\u00e9tail base de donn\u00e9es de la check-list pour \u00eatre calcul\u00e9 avec pr\u00e9cision (d\u00e9nominateur exact des points \u00ab Sans objet \u00bb exclus). Il est recommand\u00e9 de le g\u00e9n\u00e9rer directement depuis l\'outil de check-list utilis\u00e9 sur le terrain.',
    ));
    widgets.add(pw.SizedBox(height: 12));

    // VI. Sous-section : Statistique par type de défaut (10 principales)
    final topDefects = inventory.getTopDefects(limit: 10);
    if (topDefects.isNotEmpty) {
      widgets.add(PageTracker(
        key: 'stat_defauts',
        registry: trackedPages,
        child: _subTitle('Statistique par type de d\u00e9faut'),
      ));
      widgets.add(pw.SizedBox(height: 5));
      widgets.add(_bodyText(
        'Les ${inventory.totalFindings} non-conformit\u00e9s relev\u00e9es ont \u00e9t\u00e9 regroup\u00e9es par nature de d\u00e9faut. Les dix cat\u00e9gories les plus repr\u00e9sent\u00e9es sont pr\u00e9sent\u00e9es ci-dessous ; elles concentrent \u00e0 elles seules la quasi-totalit\u00e9 des \u00e9carts constat\u00e9s.',
      ));
      widgets.add(pw.SizedBox(height: 8));
      widgets.add(_buildTopDefectsHorizontalChart(topDefects));
      widgets.add(pw.SizedBox(height: 12));
    }

    // VII. Sous-section : Répartition par domaine de tension (MT vs BT)
    final domainStats = inventory.getTensionDomainStats();
    if (domainStats.totalCount > 0) {
      widgets.add(PageTracker(
        key: 'stat_tension',
        registry: trackedPages,
        child: _buildTensionDomainSection(domainStats),
      ));
      widgets.add(pw.SizedBox(height: 12));
    }

    // VIII. Sous-section : Non-conformités croisées par catégorie d'installation / d'équipement
    final diagReport = AuditDiagnosticEngine.runDiagnostic(mission.id);
    final crossItems = inventory.getCrossCategoryAnalysis(
      countMTLocaux: diagReport.countLocauxMT,
      countBTLocaux: diagReport.countLocauxBT,
      countCellules: diagReport.countCellules,
      countTransfos: diagReport.countTransformateurs,
      countGELocaux: diagReport.countGroupesElectrogenes,
      countCoffrets: diagReport.countEquipements,
    );
    if (crossItems.isNotEmpty) {
      widgets.add(PageTracker(
        key: 'stat_croisee',
        registry: trackedPages,
        child: _buildCrossCategorySection(crossItems),
      ));
      widgets.add(pw.SizedBox(height: 12));
    }

    // IX. Sous-section : Inventaire chiffré des installations et équipements
    widgets.add(PageTracker(
      key: 'stat_inventaire',
      registry: trackedPages,
      child: _buildInventaireEquipementsSection(mission.id),
    ));

    return widgets;
  }

  // ──────────────────────────────────────────────────────────────
  //  GRAPHIQUES ET ANALYSES STATISTIQUES AVANCÉES
  // ──────────────────────────────────────────────────────────────

  static pw.Widget _buildInventaireEquipementsSection(String missionId) {
    final items = AuditFindingInventory.computeEquipmentInventory(missionId);
    final totalEquipementsBT = items
        .where((e) => e.label == 'TGBT' || e.label == 'Armoires' || e.label == 'Coffrets')
        .fold(0, (sum, e) => sum + e.count);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _subTitle('Inventaire chiffr\u00e9 des installations et \u00e9quipements'),
        pw.SizedBox(height: 5),
        _bodyText(
          'Les effectifs ci-dessous sont \u00e9tablis \u00e0 partir du d\u00e9tail point par point du chapitre \u00ab Audit des installations \u00e9lectriques \u00bb (comptage des fiches de v\u00e9rification effectivement renseign\u00e9es pour chaque \u00e9quipement).',
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3.5),
            1: const pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: headerColor),
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
        _buildCalloutBox(
          'Nombre de nouveaux coffret / armoire / TGBT',
          'Donn\u00e9e non disponible\nLe nombre d\'\u00e9quipements nouvellement install\u00e9s depuis la derni\u00e8re visite ne peut \u00eatre \u00e9tabli qu\'en comparant l\'inventaire de la pr\u00e9sente visite ($totalEquipementsBT \u00e9quipements BT) \u00e0 l\'inventaire du rapport pr\u00e9c\u00e9dent. En l\'absence de ce dernier, cette valeur ne peut \u00eatre renseign\u00e9e \u00e0 ce stade.',
        ),
        pw.SizedBox(height: 6),
        _buildCalloutBox(
          'Nombre de coffret / armoire / TGBT supprim\u00e9',
          'Donn\u00e9e non disponible\nDe la m\u00eame mani\u00e8re, le nombre d\'\u00e9quipements retir\u00e9s de l\'installation depuis la derni\u00e8re visite n\u00e9cessite une comparaison avec l\'inventaire du rapport pr\u00e9c\u00e9dent, non disponible \u00e0 ce jour.',
        ),
        pw.SizedBox(height: 6),
        _buildCalloutBox(
          'Pour compl\u00e9ter enti\u00e8rement cette analyse',
          'Merci de transmettre le rapport de v\u00e9rification p\u00e9riodique de l\'ann\u00e9e pr\u00e9c\u00e9dente pour ce site (ou son export de check-list). D\u00e8s r\u00e9ception, les sections \u00ab Non-conformit\u00e9s de l\'ann\u00e9e pass\u00e9e \u00bb, \u00ab Comparaison \u00bb, \u00ab Taux de mise en conformit\u00e9 \u00bb, \u00ab Nouveaux \u00e9quipements \u00bb et \u00ab \u00c9quipements supprim\u00e9s \u00bb seront calcul\u00e9es et compl\u00e9t\u00e9es.',
        ),
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

  static pw.Widget _buildTensionDomainSection(TensionDomainStats stats) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _subTitle('R\u00e9partition des non-conformit\u00e9s par domaine de tension'),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 110,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            color: PdfColors.white,
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'R\u00e9partition des non-conformit\u00e9s par domaine de tension',
                style: pw.TextStyle(font: _fontBold, fontSize: 9, color: headerColor),
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
                        pw.Text('${stats.mtCount}', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: headerColor)),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: 45,
                          height: stats.totalCount > 0 ? (stats.mtCount / stats.totalCount) * 55 + 4 : 4,
                          decoration: pw.BoxDecoration(
                            color: headerColor,
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
                        pw.Text('${stats.btCount}', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: headerColor)),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          width: 45,
                          height: stats.totalCount > 0 ? (stats.btCount / stats.totalCount) * 55 + 4 : 4,
                          decoration: pw.BoxDecoration(
                            color: headerColor,
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
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: headerColor),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('DOMAINE', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('NON-CONFORMIT\u00c9S', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('PART DU TOTAL', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.white), textAlign: pw.TextAlign.center)),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Moyenne tension (MT/HTA) \u2014 poste de livraison, cellules, transformateur', style: pw.TextStyle(font: _fontRegular, fontSize: 7.5))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${stats.mtCount}', style: pw.TextStyle(font: _fontRegular, fontSize: 7.5), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${stats.mtPct.toStringAsFixed(1).replaceAll('.', ',')} %', style: pw.TextStyle(font: _fontRegular, fontSize: 7.5), textAlign: pw.TextAlign.center)),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Basse tension (BT) \u2014 groupe \u00e9lectrog\u00e8ne, inverseur, TGBT, armoires, coffrets', style: pw.TextStyle(font: _fontRegular, fontSize: 7.5))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${stats.btCount}', style: pw.TextStyle(font: _fontRegular, fontSize: 7.5), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${stats.btPct.toStringAsFixed(1).replaceAll('.', ',')} %', style: pw.TextStyle(font: _fontRegular, fontSize: 7.5), textAlign: pw.TextAlign.center)),
              ],
            ),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('TOTAL', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: headerColor))),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${stats.totalCount}', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: headerColor), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('100 %', style: pw.TextStyle(font: _fontBold, fontSize: 8, color: headerColor), textAlign: pw.TextAlign.center)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildCrossCategorySection(List<CategoryCrossItem> items) {
    if (items.isEmpty) return pw.SizedBox();

    final maxVal = items.map((e) => e.nonConformitiesCount).fold(1, (a, b) => a > b ? a : b);

    final colorCritique = PdfColor.fromHex('#DC2626');
    final colorMajeure = PdfColor.fromHex('#EA580C');
    final colorMineure = PdfColor.fromHex('#16A34A');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _subTitle('Non-conformit\u00e9s crois\u00e9es par cat\u00e9gorie d\'installation / d\'\u00e9quipement'),
        pw.SizedBox(height: 5),
        _bodyText('En crois\u00e0nt chaque cat\u00e9gorie ci-dessus avec les non-conformit\u00e9s relev\u00e9es, la r\u00e9partition et la densit\u00e9 moyenne par \u00e9quipement se pr\u00e9sentent comme suit :'),
        pw.SizedBox(height: 8),
        pw.Container(
          height: 135,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
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
                    style: pw.TextStyle(font: _fontBold, fontSize: 9, color: headerColor),
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
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Expanded(
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
                        pw.Text('${item.nonConformitiesCount}', style: pw.TextStyle(font: _fontBold, fontSize: 7, color: headerColor)),
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
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(0.9),
            2: const pw.FlexColumnWidth(0.9),
            3: const pw.FlexColumnWidth(0.9),
            4: const pw.FlexColumnWidth(0.9),
            5: const pw.FlexColumnWidth(0.9),
            6: const pw.FlexColumnWidth(1.1),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: headerColor),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('CAT\u00c9GORIE', style: pw.TextStyle(font: _fontBold, fontSize: 7.5, color: PdfColors.white))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('NB \u00c9QUIP.', style: pw.TextStyle(font: _fontBold, fontSize: 7, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('NON-CONF.', style: pw.TextStyle(font: _fontBold, fontSize: 7, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('CRITIQUE', style: pw.TextStyle(font: _fontBold, fontSize: 7, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('MAJEURE', style: pw.TextStyle(font: _fontBold, fontSize: 7, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('MINEURE', style: pw.TextStyle(font: _fontBold, fontSize: 7, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('MOY. / \u00c9QUIP.', style: pw.TextStyle(font: _fontBold, fontSize: 7, color: PdfColors.white), textAlign: pw.TextAlign.center)),
              ],
            ),
            ...items.map((item) {
              return pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.categoryName, style: pw.TextStyle(font: _fontRegular, fontSize: 7))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${item.equipmentCount}', style: pw.TextStyle(font: _fontRegular, fontSize: 7), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${item.nonConformitiesCount}', style: pw.TextStyle(font: _fontRegular, fontSize: 7), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${item.critiqueCount}', style: pw.TextStyle(font: _fontRegular, fontSize: 7), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${item.majeureCount}', style: pw.TextStyle(font: _fontRegular, fontSize: 7), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${item.mineureCount}', style: pw.TextStyle(font: _fontRegular, fontSize: 7), textAlign: pw.TextAlign.center)),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.equipmentCount > 0 ? item.density.toStringAsFixed(1).replaceAll('.', ',') : '\u2014', style: pw.TextStyle(font: _fontRegular, fontSize: 7), textAlign: pw.TextAlign.center)),
                ],
              );
            }).toList(),
          ],
        ),
        pw.SizedBox(height: 8),
        _buildLectureCroiseeBox(items),
      ],
    );
  }

  static String _shortCatName(String cat) {
    if (cat.contains('Moyenne Tension')) return 'Local MT';
    if (cat.contains('Cellules')) return 'Cellule MT';
    if (cat.contains('Transformateurs')) return 'Transfo MT/BT';
    if (cat.contains('Groupe \u00c9lectrog\u00e8ne')) return 'Local GE';
    if (cat.contains('Basse Tension')) return 'Local BT';
    if (cat.contains('TGBT')) return 'TGBT';
    if (cat.contains('Armoires')) return 'Armoire';
    if (cat.contains('Coffrets')) return 'Coffret';
    if (cat.contains('Tableaux divisionnaires')) return 'Tab. Div.';
    if (cat.contains('Prises de terre')) return 'Terre';
    return cat;
  }

  static pw.Widget _buildLectureCroiseeBox(List<CategoryCrossItem> items) {
    if (items.isEmpty) return pw.SizedBox();

    final sortedByDensity = List<CategoryCrossItem>.from(items)
      ..sort((a, b) => b.density.compareTo(a.density));
    final highestDensity = sortedByDensity.first;

    final sortedByVolume = List<CategoryCrossItem>.from(items)
      ..sort((a, b) => b.nonConformitiesCount.compareTo(a.nonConformitiesCount));
    final highestVolume = sortedByVolume.first;

    final txt = 'Rapport\u00e9es au nombre d\'\u00e9quipements, la cat\u00e9gorie affichant la densit\u00e9 de non-conformit\u00e9s la plus \u00e9lev\u00e9e est "${highestDensity.categoryName}" (${highestDensity.density.toStringAsFixed(1).replaceAll('.', ',')} NC/\u00e9quipement). En volume brut, la cat\u00e9gorie "${highestVolume.categoryName}" enregistre le plus grand nombre d\'\u00e9carts constat\u00e9s (${highestVolume.nonConformitiesCount} non-conformit\u00e9s).';

    return _buildCalloutBox('Lecture crois\u00e9e', txt);
  }

  // ──────────────────────────────────────────────────────────────
  //  RENSEIGNEMENTS GENERAUX
  // ──────────────────────────────────────────────────────────────
  
  static pw.Widget _buildRenseignementsGeneraux(
    Mission mission,
    RenseignementsGeneraux? rg,
    Map<String, int> trackedPages,
  ) {
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
          child: _sectionBox('RENSEIGNEMENTS G\u00c9N\u00c9RAUX DE L\'\u00c9TABLISSEMENT'),
        ),

        pw.SizedBox(height: 8),

        PageTracker(
          key: 'renseignements_principaux',
          registry: trackedPages,
          child: _subTitle('RENSEIGNEMENTS PRINCIPAUX'),
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
              ['Activité sur le site', mission.activiteSurSite ?? '—'],
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
              ['                                     Type', mission.classementReglementaireType ?? '—'],
              alt: false,
            ),
            _tableDataRow(
              ['                                     Catégorie', mission.classementReglementaireCategorie ?? '—'],
              alt: true,
            ),
          ],
        ),

  pw.SizedBox(height: 16),

  PageTracker(
    key: 'renseignements_documents',
    registry: trackedPages,
    child: _subTitle('DOCUMENTS NECESSAIRES A LA VERIFICATION'),
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
    child: _subTitle('HABILITATION ÉLECTRIQUE DU PERSONNEL D\'INTERVENTION'),
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
    Map<String, int> trackedPages,
  ) {
    final widgets = <pw.Widget>[];
    widgets.add(PageTracker(
      key: 'description',
      registry: trackedPages,
      child: _sectionBox('DESCRIPTION DES INSTALLATIONS'),
    ));
    widgets.add(pw.SizedBox(height: 8));

    if (desc == null) {
      widgets.add(_bodyText('Aucune donnée disponible.'));
      return widgets;
    }

    widgets.add(_subTitle('Caractéristiques de l\'alimentation moyenne tension'));
    if (desc.alimentationMoyenneTension.isNotEmpty) {
      widgets.add(_buildInstallationTable(desc.alimentationMoyenneTension, sectionKey: 'MT'));
    } else {
      widgets.add(_bodyText('- Non renseignee'));
    }
    
    widgets.add(_subTitle('Caractéristiques de l\'alimentation basse tension sortie transformateur'));
    if (desc.alimentationBasseTension.isNotEmpty) {
      widgets.add(_buildInstallationTable(desc.alimentationBasseTension, sectionKey: 'BT'));
    } else {
      widgets.add(_bodyText('- Non renseignee'));
    }
    
    widgets.add(_subTitle('Caractéristiques du groupe électrogène'));
    if (desc.groupeElectrogene.isNotEmpty) {
      widgets.add(_buildInstallationTable(desc.groupeElectrogene, sectionKey: 'GROUPE'));
    } else {
      widgets.add(_bodyText('- Absent'));
    }
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(_subTitle('Alimentation du groupe électrogène en carburant'));
    if (desc.alimentationCarburant.isNotEmpty) {
      widgets.add(_buildInstallationTable(desc.alimentationCarburant, sectionKey: 'CARBURANT'));
    } else {
      widgets.add(_bodyText('- Non applicable'));
    }
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(_subTitle('Caractéristiques de l\'inverseur'));
    if (desc.inverseur.isNotEmpty) {
      widgets.add(_buildInstallationTable(desc.inverseur, sectionKey: 'INVERSEUR'));
    } else {
      widgets.add(_bodyText('- Absent'));
    }
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(_subTitle('Caractéristiques du stabilisateur'));
    if (desc.stabilisateur.isNotEmpty) {
      widgets.add(_buildInstallationTable(desc.stabilisateur, sectionKey: 'STABILISATEUR'));
    } else {
      widgets.add(_bodyText('- Absent'));
    }
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(_subTitle('Caractéristiques des onduleurs'));
    if (desc.onduleurs.isNotEmpty) {
      widgets.add(_buildInstallationTable(desc.onduleurs, sectionKey: 'ONDULEUR'));
    } else {
      widgets.add(_bodyText('- Absent'));
    }
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(_subTitle('Régime de neutre'));
  
    String regimeAffichage = desc.regimeNeutre ?? 'Non renseigné';
    if (desc.regimeNeutre == 'TN' && desc.regimeNeutreDetail != null) {
      regimeAffichage = 'TN (TN-${desc.regimeNeutreDetail})';
    }
    
    widgets.add(_bodyText('- $regimeAffichage'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(_subTitle('Eclairage de sécurité'));
    widgets.add(_bodyText('- ${desc.eclairageSecurite ?? 'Non renseigné'}'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(_subTitle('Modifications apportées aux installations'));
    widgets.add(_bodyText(desc.modificationsInstallations ?? 'Sans objet'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(_subTitle('Note de calcul des installations électriques'));
    widgets.add(_bodyText('- ${desc.noteCalcul ?? 'Non transmis'}'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(_subTitle('Présence de paratonnerre'));
    widgets.add(_bodyText('Présence : ${desc.presenceParatonnerre ?? 'NON'}'));
    if (desc.analyseRisqueFoudre != null && desc.analyseRisqueFoudre!.isNotEmpty) {
      widgets.add(_bodyText('Analyse risque foudre : ${desc.analyseRisqueFoudre}'));
    }
    if (desc.etudeTechniqueFoudre != null && desc.etudeTechniqueFoudre!.isNotEmpty) {
      widgets.add(_bodyText('Etude technique foudre : ${desc.etudeTechniqueFoudre}'));
    }
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(_subTitle('Registre de sécurité'));
    widgets.add(_bodyText('- ${desc.registreSecurite ?? 'Non transmis'}'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(PageTracker(
      key: 'desc_locaux_risques',
      registry: trackedPages,
      child: _subTitle('Zones et Locaux \u00e0 risque'),
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

  static pw.Widget _buildInstallationTable(List<InstallationItem> items, {String? sectionKey}) {
    if (items.isEmpty) return pw.Container();

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
          decoration: pw.BoxDecoration(color: lightBlue),
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
              String raw = '-';
              for (var k in e.value.data.keys) {
                if (k.toUpperCase().trim() == key.toUpperCase().trim()) {
                  raw = e.value.data[k]?.toString() ?? '-';
                  break;
                }
              }
              final unit = _unitForField(key);
              final display = (raw != '-' && unit.isNotEmpty) ? '$raw $unit' : raw;
              return _cell(display, isHeader: false, centered: true);
            }),
          ],
        )),
      ],
    );
  }

  static String _unitForField(String fieldKey) {
    const units = {
      'Calibre Du Disjoncteur': 'A',
      'CALIBRE DU DISJONCTEUR': 'A',
      'Calibre Du Disjoncteur Sortie Transformateur': 'A',
      'CALIBRE DU DISJONCTEUR SORTIE TRANSFORMATEUR': 'A',
      'Section Du Cable': 'mm²',
      'SECTION DU CABLE': 'mm²',
      'Puissance Transformateur': 'kVA',
      'PUISSANCE TRANSFORMATEUR': 'kVA',
      'Puissance (Kva)': 'kVA',
      'PUISSANCE (KVA)': 'kVA',
      'Tension': 'V',
      'TENSION': 'V',
      'Intensite': 'A',
      'INTENSITE': 'A',
      'Intensite (A)': 'A',
      'INTENSITE (A)': 'A',
      'Entree': 'V',
      'ENTREE': 'V',
      'Sortie': 'V',
      'SORTIE': 'V',
      'Capacite': 'L',
      'CAPACITE': 'L',
    };
    return units[fieldKey] ?? '';
  }

  // ──────────────────────────────────────────────────────────────
  //  LISTE RECAPITULATIVE DES OBSERVATIONS (BT sur nouvelle page)
  // ──────────────────────────────────────────────────────────────
  
  static List<pw.Widget> _buildListeRecapitulativeMulti(AuditInstallationsElectriques audit, Map<String, int> trackedPages) {
    final widgets = <pw.Widget>[];


    // ── Moyenne Tension ──
    widgets.add(PageTracker(
      key: 'liste_recap_mt',
      registry: trackedPages,
      child: _subSectionBar('Moyenne tension'),
    ));
    widgets.add(pw.SizedBox(height: 5));
    final obsMT = _collectObservationsMT(audit);
    widgets.addAll(_buildObsRecapTableMT(obsMT));

    widgets.add(pw.NewPage());

    // ── Basse Tension ──
    widgets.add(PageTracker(
      key: 'liste_recap_bt',
      registry: trackedPages,
      child: _subSectionBar('Basse tension'),
    ));
    widgets.add(pw.SizedBox(height: 5));
    final obsBT = _collectObservationsBT(audit);
    widgets.addAll(_buildObsRecapTableBT(obsBT));

    return widgets;
  }

  /// ── Tableau récap MT ──
  /// Colonnes : LOCAL | OBSERVATIONS | REF. NORMATIVE
  /// (pas de colonne ÉQUIPEMENT en MT — conforme à la trame)
  static List<pw.Widget> _buildObsRecapTableMT(List<_ObsRecap> obs) {
    if (obs.isEmpty) {
      return [pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor, width: 0.4)),
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text('Aucune observation',
            style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall, fontStyle: pw.FontStyle.italic)),
      )];
    }

    final widgets = <pw.Widget>[];

    final header1 = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.5),
        left: pw.BorderSide(color: borderColor, width: 0.5),
        right: pw.BorderSide(color: borderColor, width: 0.5),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.0),
        1: pw.FlexColumnWidth(6.0),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: [
            _obsHeaderCellMT('LOCALISATION'),
            _obsHeaderCellMT('NON-CONFORMITÉ - PRÉCONISATION'),
          ],
        ),
      ],
    );

    final header2 = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.5),
        bottom: pw.BorderSide(color: borderColor, width: 0.5),
        left: pw.BorderSide(color: borderColor, width: 0.5),
        right: pw.BorderSide(color: borderColor, width: 0.5),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.0),
        1: pw.FlexColumnWidth(4.2),
        2: pw.FlexColumnWidth(1.8),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF2E5F9A)),
          children: [
            _obsHeaderCellMT('LOCAL'),
            _obsHeaderCellMT('OBSERVATIONS'),
            _obsHeaderCellMT('RÉF. NORMATIVE'),
          ],
        ),
      ],
    );

    widgets.add(header1);
    widgets.add(header2);

    final groups = _groupByLocal(obs);
    int altIdx = 0;

    for (final group in groups) {
      final nestedRows = <pw.TableRow>[];
      for (int i = 0; i < group.items.length; i++) {
        final o = group.items[i];
        altIdx++;

        final rowBg = altIdx.isOdd ? tableRowAlt : PdfColors.white;

        nestedRows.add(pw.TableRow(
          decoration: pw.BoxDecoration(color: rowBg),
          children: [
            // OBSERVATIONS
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: pw.Text(o.observation,
                  style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
            ),
            // REF. NORMATIVE (centré)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text(o.refNorm,
                  style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                  textAlign: pw.TextAlign.center),
            ),
          ],
        ));
      }

      final dataTable = pw.Table(
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        border: pw.TableBorder(
          top: pw.BorderSide(color: borderColor, width: 0.4),
          bottom: pw.BorderSide(color: borderColor, width: 0.4),
          left: pw.BorderSide(color: borderColor, width: 0.4),
          right: pw.BorderSide(color: borderColor, width: 0.4),
          verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        ),
        columnWidths: const {
          0: pw.FlexColumnWidth(2.0),
          1: pw.FlexColumnWidth(6.0),
        },
        children: [
          pw.TableRow(
            children: [
              // LOCAL (perfectly centered vertically)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(group.local.toUpperCase(),
                    style: pw.TextStyle(font: _fontBold, fontSize: fsSmall),
                    textAlign: pw.TextAlign.center),
              ),
              // TABLE IMBRIQUÉE
              pw.Table(
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
                  verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(4.2),
                  1: pw.FlexColumnWidth(1.8),
                },
                children: nestedRows,
              ),
            ],
          ),
        ],
      );
      widgets.add(dataTable);
      widgets.add(pw.SizedBox(height: 6));
    }

    return widgets;
  }

  /// ── Tableau récap BT ──
  /// Colonnes : LOCAL | ÉQUIPEMENT | OBSERVATIONS | REF. NORMATIVE
  static List<pw.Widget> _buildObsRecapTableBT(List<_ObsRecap> obs) {
    if (obs.isEmpty) {
      return [pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor, width: 0.4)),
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text('Aucune observation',
            style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall, fontStyle: pw.FontStyle.italic)),
      )];
    }

    final widgets = <pw.Widget>[];

    // Ligne 1 : en-tête avec colspan
    final header1 = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.5),
        left: pw.BorderSide(color: borderColor, width: 0.5),
        right: pw.BorderSide(color: borderColor, width: 0.5),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.0),
        1: pw.FlexColumnWidth(2.0),
        2: pw.FlexColumnWidth(5.4),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: [
            _obsHeaderCellMT('LOCALISATION'),
            _obsHeaderCellMT(''),
            _obsHeaderCellMT('NON-CONFORMITÉ - PRÉCONISATION'),
          ],
        ),
      ],
    );

    // Ligne 2 : sous-colonnes
    final header2 = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.5),
        bottom: pw.BorderSide(color: borderColor, width: 0.5),
        left: pw.BorderSide(color: borderColor, width: 0.5),
        right: pw.BorderSide(color: borderColor, width: 0.5),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.0),
        1: pw.FlexColumnWidth(2.0),
        2: pw.FlexColumnWidth(3.9),
        3: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF2E5F9A)),
          children: [
            _obsHeaderCellMT(''), // Première colonne entièrement vide
            _obsHeaderCellMT('ÉQUIPEMENT'),
            _obsHeaderCellMT('OBSERVATIONS'),
            _obsHeaderCellMT('RÉF. NORMATIVE'),
          ],
        ),
      ],
    );

    widgets.add(header1);
    widgets.add(header2);

    final groups = _groupByLocal(obs);
    int altIdx = 0;
    int equipIdx = 0; // Global counter for equipments in the BT table

    for (final group in groups) {
      // Séparateur local (colspan sur col 1-4)
      final localSeparatorTable = pw.Table(
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        border: pw.TableBorder.all(color: borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.0),
          1: pw.FlexColumnWidth(7.4),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: lightBlue),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('LOCALISATION', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(group.local.toUpperCase(), style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor)),
              ),
            ],
          ),
        ],
      );
      widgets.add(localSeparatorTable);
      widgets.add(pw.SizedBox(height: 2));

      final localRows = <pw.TableRow>[];

      // Sous-grouper par équipement
      final equipGroups = <_ObsGroup>[];
      for (final o in group.items) {
        if (equipGroups.isEmpty || equipGroups.last.local != o.coffret) {
          equipGroups.add(_ObsGroup(local: o.coffret, items: [o]));
        } else {
          equipGroups.last.items.add(o);
        }
      }

      for (final eq in equipGroups) {
        equipIdx++; // Increment the global counter for each equipment
        final observationRows = <pw.TableRow>[];
        
        for (int i = 0; i < eq.items.length; i++) {
          final o = eq.items[i];
          altIdx++;

          final rowBg = altIdx.isOdd ? tableRowAlt : PdfColors.white;

          // Observations nested table row
          observationRows.add(pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              // OBSERVATIONS
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: pw.Text(o.observation, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
              ),
              // REF. NORMATIVE (centré)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text(o.refNorm,
                    style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall),
                    textAlign: pw.TextAlign.center),
              ),
            ],
          ));
        }

        localRows.add(pw.TableRow(
          children: [
            // INDEX (Single parent cell showing the global equipment index)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text('$equipIdx', style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
            ),
            // ÉQUIPEMENT (Perfectly centered vertically and horizontally)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(eq.local.toUpperCase(),
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall),
                  textAlign: pw.TextAlign.center),
            ),
            // OBSERVATIONS + REF
            pw.Table(
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
                verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(3.9),
                1: pw.FlexColumnWidth(1.5),
              },
              children: observationRows,
            ),
          ],
        ));
      }

      final localTable = pw.Table(
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        border: pw.TableBorder(
          top: pw.BorderSide(color: borderColor, width: 0.4),
          bottom: pw.BorderSide(color: borderColor, width: 0.4),
          left: pw.BorderSide(color: borderColor, width: 0.4),
          right: pw.BorderSide(color: borderColor, width: 0.4),
          verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
          horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
        ),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.0),
          1: pw.FlexColumnWidth(2.0),
          2: pw.FlexColumnWidth(5.4),
        },
        children: localRows,
      );
      widgets.add(localTable);
      widgets.add(pw.SizedBox(height: 6));
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
        // Observations parafoudre dans la liste récap
        if (coffret.presenceParafoudre) {
          final pfEnrichies = coffret.observationsParafoudreEnrichies ?? [];
          if (pfEnrichies.isNotEmpty) {
            for (var obs in pfEnrichies) {
              list.add(_ObsRecap(
                localisation: local.nom,
                coffret: '${coffret.nom} (Parafoudre)',
                observation: obs.observation?.isNotEmpty == true ? obs.observation! : obs.elementControle,
                refNorm: obs.referenceNormative ?? '',
                priorite: obs.priorite?.toString() ?? '',
                repere: coffretRepere,
              ));
            }
          } else {
            for (var obs in coffret.observationsParafoudre) {
              list.add(_ObsRecap(
                localisation: local.nom,
                coffret: '${coffret.nom} (Parafoudre)',
                observation: obs.texte, refNorm: '', priorite: '',
                repere: coffretRepere,
              ));
            }
          }
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
        if (coffret.presenceParafoudre) {
          final pfEnrichies = coffret.observationsParafoudreEnrichies ?? [];
          if (pfEnrichies.isNotEmpty) {
            for (var obs in pfEnrichies) {
              list.add(_ObsRecap(
                localisation: zone.nom,
                coffret: '${coffret.nom} (Parafoudre)',
                observation: obs.observation?.isNotEmpty == true ? obs.observation! : obs.elementControle,
                refNorm: obs.referenceNormative ?? '',
                priorite: obs.priorite?.toString() ?? '',
              ));
            }
          } else {
            for (var obs in coffret.observationsParafoudre) {
              list.add(_ObsRecap(
                localisation: zone.nom,
                coffret: '${coffret.nom} (Parafoudre)',
                observation: obs.texte, refNorm: '', priorite: '',
              ));
            }
          }
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
          if (coffret.presenceParafoudre) {
            final pfEnrichies = coffret.observationsParafoudreEnrichies ?? [];
            if (pfEnrichies.isNotEmpty) {
              for (var obs in pfEnrichies) {
                list.add(_ObsRecap(
                  localisation: '${zone.nom} / ${local.nom}',
                  coffret: '${coffret.nom} (Parafoudre)',
                  observation: obs.observation?.isNotEmpty == true ? obs.observation! : obs.elementControle,
                  refNorm: obs.referenceNormative ?? '',
                  priorite: obs.priorite?.toString() ?? '',
                ));
              }
            } else {
              for (var obs in coffret.observationsParafoudre) {
                list.add(_ObsRecap(
                  localisation: '${zone.nom} / ${local.nom}',
                  coffret: '${coffret.nom} (Parafoudre)',
                  observation: obs.texte, refNorm: '', priorite: '',
                ));
              }
            }
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
        if (coffret.presenceParafoudre) {
          final pfEnrichies = coffret.observationsParafoudreEnrichies ?? [];
          if (pfEnrichies.isNotEmpty) {
            for (var obs in pfEnrichies) {
              list.add(_ObsRecap(
                localisation: zone.nom,
                coffret: '${coffret.nom} (Parafoudre)',
                observation: obs.observation?.isNotEmpty == true ? obs.observation! : obs.elementControle,
                refNorm: obs.referenceNormative ?? '',
                priorite: obs.priorite?.toString() ?? '',
                repere: coffretRepere,
              ));
            }
          } else {
            for (var obs in coffret.observationsParafoudre) {
              list.add(_ObsRecap(
                localisation: zone.nom,
                coffret: '${coffret.nom} (Parafoudre)',
                observation: obs.texte, refNorm: '', priorite: '',
                repere: coffretRepere,
              ));
            }
          }
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
          if (coffret.presenceParafoudre) {
            final pfEnrichies = coffret.observationsParafoudreEnrichies ?? [];
            if (pfEnrichies.isNotEmpty) {
              for (var obs in pfEnrichies) {
                list.add(_ObsRecap(
                  localisation: '${zone.nom} / ${local.nom}',
                  coffret: '${coffret.nom} (Parafoudre)',
                  observation: obs.observation?.isNotEmpty == true ? obs.observation! : obs.elementControle,
                  refNorm: obs.referenceNormative ?? '',
                  priorite: obs.priorite?.toString() ?? '',
                  repere: coffretRepere,
                ));
              }
            } else {
              for (var obs in coffret.observationsParafoudre) {
                list.add(_ObsRecap(
                  localisation: '${zone.nom} / ${local.nom}',
                  coffret: '${coffret.nom} (Parafoudre)',
                  observation: obs.texte, refNorm: '', priorite: '',
                  repere: coffretRepere,
                ));
              }
            }
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

  static List<pw.Widget> _buildLocalMT(MoyenneTensionLocal local, Map<String, int> trackedPages) {
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
                  '⚠ LOCAL INACCESSIBLE — NON INSPECTÉ',
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
      widgets.addAll(_buildCelluleSection(local.cellules[i]));
    }
    for (int i = 0; i < local.transformateurs.length; i++) {
      widgets.add(pw.NewPage());
      widgets.addAll(_buildTransformateurSection(local.transformateurs[i]));
    }

    for (int i = 0; i < local.coffrets.length; i++) {
      widgets.add(pw.NewPage());
      widgets.addAll(_buildCoffret(local.coffrets[i], trackedPages, local.nom));
    }

    return widgets;
  }

  static List<pw.Widget> _buildLocalBT(BasseTensionLocal local, Map<String, int> trackedPages) {
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
                  '⚠ LOCAL INACCESSIBLE — NON INSPECTÉ',
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
      widgets.addAll(_buildCoffret(local.coffrets[i], trackedPages, local.nom));
    }

    return widgets;
  }

  // Barre de section principale (bleue)
  static pw.Widget _subSectionBar(String title) {
    return pw.Container(
      width: double.infinity,
      color: accentColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: pw.Text(title,
          style: pw.TextStyle(fontSize: fsH3, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    );
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
      0: pw.FlexColumnWidth(2.6), // Point de vérification
      1: pw.FlexColumnWidth(1.0), // Conformité
      2: pw.FlexColumnWidth(1.5), // Référence normative
      3: pw.FlexColumnWidth(1.3), // Famille de risque
      4: pw.FlexColumnWidth(0.9), // Criticité
      5: pw.FlexColumnWidth(1.7), // Observations
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
              child: pw.Text('Point de vérification',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Conformité',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Référence normative',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Famille de risque',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Criticité',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Observations',
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
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            child: pw.Text(el.elementControle,
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
          ),
          pw.Container(
            color: confColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(conf,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
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
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            child: pw.Text(el.observation ?? '',
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
        ],
      ));
    }

    final dataTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
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

  static List<pw.Widget> _buildCelluleSection(Cellule cellule) {
    DispositionsConstructivesRegistry.ensureCompleteCelluleChecklist(cellule.elementsVerifies);
    String safe(String v) => v.trim().isEmpty ? 'Non renseigné' : v;

    pw.TableRow tableDataRowInfo(String label, String value, {required bool alt}) {
      return pw.TableRow(
        decoration: alt ? pw.BoxDecoration(color: tableRowAlt) : null,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Text(label,
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Text(value,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
        ],
      );
    }

    const tableColumnWidths = <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(2.3),
      1: pw.FlexColumnWidth(0.9),
      2: pw.FlexColumnWidth(1.2),
      3: pw.FlexColumnWidth(1.2),
      4: pw.FlexColumnWidth(0.8),
      5: pw.FlexColumnWidth(1.1),
    };

    final titleTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.4),
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(7.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.center,
              child: pw.Text('CELLULE MOYENNE TENSION',
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
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.4),
        1: pw.FlexColumnWidth(3.1),
      },
      children: [
        tableDataRowInfo('Fonction de la cellule', safe(cellule.fonction), alt: false),
        tableDataRowInfo('Type de cellule', safe(cellule.type), alt: false),
        tableDataRowInfo('Marque / modèle / année', safe(cellule.marqueModeleAnnee), alt: false),
        tableDataRowInfo('Tension assignée', safe(cellule.tensionAssignee), alt: false),
        tableDataRowInfo('Pouvoir de coupure assigné (kA)', safe(cellule.pouvoirCoupure), alt: false),
        tableDataRowInfo('Numérotation / repérage cellule', safe(cellule.numerotation), alt: false),
        tableDataRowInfo("Parafoudres installés sur l'arrivée", safe(cellule.parafoudres), alt: false),
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
              child: pw.Text('Point de vérification',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Conformité',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Référence normative',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Famille de risque',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Criticité',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Observations',
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
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            child: pw.Text(el.elementControle,
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
          ),
          pw.Container(
            color: confColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(conf,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
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
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            child: pw.Text(el.observation ?? '',
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
        ],
      ));
    }

    final dataTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
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
      infoTable,
      headerTable,
      dataTable,
      pw.SizedBox(height: 5),
    ];
  }

  static List<pw.Widget> _buildTransformateurSection(TransformateurMTBT transfo) {
    DispositionsConstructivesRegistry.ensureCompleteTransformateurChecklist(transfo.elementsVerifies);
    String safe(String v) => v.trim().isEmpty ? 'Non renseigné' : v;

    pw.TableRow tableDataRowInfo(String label, String value, {required bool alt}) {
      return pw.TableRow(
        decoration: alt ? pw.BoxDecoration(color: tableRowAlt) : null,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Text(label,
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Text(value,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
        ],
      );
    }

    const tableColumnWidths = <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(2.3),
      1: pw.FlexColumnWidth(0.9),
      2: pw.FlexColumnWidth(1.2),
      3: pw.FlexColumnWidth(1.2),
      4: pw.FlexColumnWidth(0.8),
      5: pw.FlexColumnWidth(1.1),
    };

    final titleTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.4),
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(7.5),
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
      ],
    );

    final infoTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.4),
        1: pw.FlexColumnWidth(3.1),
      },
      children: [
        tableDataRowInfo('Type de transformateur', safe(transfo.typeTransformateur), alt: false),
        tableDataRowInfo('Marque/ Année de fabrication', safe(transfo.marqueAnnee), alt: false),
        tableDataRowInfo('Puissance assignée (kVA)', safe(transfo.puissanceAssignee), alt: false),
        tableDataRowInfo('Tension primaire / secondaire', safe(transfo.tensionPrimaireSecondaire), alt: false),
        tableDataRowInfo('Présence du relais Buchholz', safe(transfo.relaisBuchholz), alt: false),
        tableDataRowInfo('Type de refroidissement', safe(transfo.typeRefroidissement), alt: false),
        tableDataRowInfo('Régime du neutre', safe(transfo.regimeNeutre), alt: false),
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
              child: pw.Text('Point de vérification',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Conformité',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Référence normative',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Famille de risque',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Criticité',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Observations',
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
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            child: pw.Text(el.elementControle,
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
          ),
          pw.Container(
            color: confColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(conf,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
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
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            child: pw.Text(el.observation ?? '',
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
        ],
      ));
    }

    final dataTable = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
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
      infoTable,
      headerTable,
      dataTable,
      pw.SizedBox(height: 5),
    ];
  }


  static List<pw.Widget> _buildCoffret(CoffretArmoire coffret, Map<String, int> trackedPages, String parentName) {
    final widgets = <pw.Widget>[pw.SizedBox(height: 6)];
    String safe(String v) => v.trim().isEmpty ? 'Non renseigné' : v;

    // ── Photo interne ──────────────────────────────────────────────────────
    pw.MemoryImage? photoInterne;
    for (final src in [...coffret.photosInternes, ...coffret.photos, ...coffret.photosExternes]) {
      if (src.isEmpty) continue;
      if (_coffretPhotoCache.containsKey(src)) {
        photoInterne = _coffretPhotoCache[src];
        if (photoInterne != null) break;
      } else {
        try {
          final f = File(src);
          if (f.existsSync()) {
            photoInterne = pw.MemoryImage(f.readAsBytesSync());
            _coffretPhotoCache[src] = photoInterne;
            break;
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
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder(
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
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
      ],
    );

    final topSectionTable = pw.Table(
      border: pw.TableBorder(
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.2),
        1: pw.FlexColumnWidth(3.0),
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
        final alimentRows = <pw.TableRow>[];

        // En-tête alimentation
        alimentRows.add(pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
          children: [
            _thCell("Origine de la source d'alimentation"),
            _thCell('Type protection'),
            _thCell('Courbe'),
            _thCell('PDC kA'),
            _thCell('Calibre'),
            _thCell('Section de câble'),
          ],
        ));

        for (final a in coffret.alimentations) {
          alimentRows.add(pw.TableRow(children: [
            _valueCell(a.source.isEmpty ? '-' : a.source),
            _valueCell(a.typeProtection),
            _valueCell(a.courbe ?? ''),
            _valueCell(a.pdcKA),
            _valueCell(a.calibre),
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
            0: pw.FlexColumnWidth(2.2),
            1: pw.FlexColumnWidth(1.6),
            2: pw.FlexColumnWidth(1.0),
            3: pw.FlexColumnWidth(0.8),
            4: pw.FlexColumnWidth(0.8),
            5: pw.FlexColumnWidth(1.2),
          },
          children: alimentRows,
        ));
      }

      if (coffret.protectionTete != null) {
        final pt = coffret.protectionTete!;
        
        // Custom rowspan table using nested table to ensure perfect align and border scaling
        final protectionTeteTable = pw.Table(
          border: pw.TableBorder(
            left: pw.BorderSide(color: borderColor, width: 0.4),
            right: pw.BorderSide(color: borderColor, width: 0.4),
            bottom: pw.BorderSide(color: borderColor, width: 0.4),
            top: pw.BorderSide(color: borderColor, width: 0.4),
            verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.2),
            1: pw.FlexColumnWidth(5.4),
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
                  border: pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
                    verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1.6),
                    1: pw.FlexColumnWidth(1.0),
                    2: pw.FlexColumnWidth(0.8),
                    3: pw.FlexColumnWidth(0.8),
                    4: pw.FlexColumnWidth(1.2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
                      children: [
                        _thCell('Type protection'),
                        _thCell('Courbe'),
                        _thCell('PDC kA'),
                        _thCell('Calibre'),
                        _thCell('Section de câble'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _valueCell(pt.typeProtection),
                        _valueCell(pt.courbe ?? ''),
                        _valueCell(pt.pdcKA),
                        _valueCell(pt.calibre),
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
      border: pw.TableBorder(
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        top: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(1.0),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(1.6),
        4: pw.FlexColumnWidth(1.0),
        5: pw.FlexColumnWidth(1.7),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
          children: [
            _thCell('POINTS DE VÉRIFICATION'),
            _thCell('CONFORMITÉ'),
            _thCell('RÉFÉRENCE NORMATIVE'),
            _thCell('FAMILLE DE RISQUE'),
            _thCell('CRITICITÉ'),
            _thCell('OBSERVATIONS'),
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
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: pw.Text(pv.pointVerification,
                    style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
              ),
              pw.Container(
                color: confColor,
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text(confText,
                    style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
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
                                : PdfColors.black))),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: pw.Text(obsText,
                    style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
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
    Map<String, int> trackedPages,
  ) {
    final widgets = <pw.Widget>[];

    // _sectionBox title like other sections
    widgets.add(PageTracker(
      key: 'classement',
      registry: trackedPages,
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
          decoration: pw.BoxDecoration(color: lightBlue), // LightBlue background matching the report
          children: [
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text('Localisation', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text('Zone', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text('Origine\nclassement', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
            ),
            // Influences externes (double level with vertical inside borders)
            pw.Column(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text('Influences externes', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
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
                        pw.Text('AF', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
                        pw.Text('BE', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
                        pw.Text('AE', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
                        pw.Text('AD', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
                        pw.Text('AG', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
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
                  child: pw.Text('Indice mini de\nprotection', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
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
                        pw.Text('IP', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
                        pw.Text('IK', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
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
          decoration: pw.BoxDecoration(color: lightBlue), // Uniform lightBlue background
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.center,
              child: pw.Text(
                "CODIFICATION DES INFLUENCES EXTERNES – INDICES ET DEGRÉS DE PROTECTION",
                style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: headerColor), // H3 size, headerColor text
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
  
  static pw.Widget _buildFoudre(List<Foudre> foudres, Map<String, int> trackedPages) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeaderWidget(),
        pw.SizedBox(height: 10),
        PageTracker(
          key: 'foudre',
          registry: trackedPages,
          child: _sectionBox('FOUDRE'),
        ),
        pw.SizedBox(height: 8),
        if (foudres.isEmpty)
          _bodyText('Aucune observation foudre disponible.')
        else
          pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.4),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.5),
              1: pw.FlexColumnWidth(0.5),
              2: pw.FlexColumnWidth(5),
            },
            children: [
              _tableHeaderRow(['Items', 'Priorite', 'Observations']),
              ...foudres.asMap().entries.map((e) {
                final f = e.value;
                final rowColor = e.key.isOdd ? tableRowAlt : PdfColors.white;

                PdfColor badgeColor = PdfColors.white;
                if (f.niveauPriorite == 1) badgeColor = priorite1Color;
                if (f.niveauPriorite == 2) badgeColor = priorite2Color;
                if (f.niveauPriorite == 3) badgeColor = priorite3Color;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowColor),
                  children: [
                    _cell('${e.key + 1}', isHeader: false, centered: true),
                    pw.Container(
                      color: badgeColor,
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Text('${f.niveauPriorite}',
                          style: pw.TextStyle(fontSize: fsBody, fontWeight: pw.FontWeight.bold,
                              color: f.niveauPriorite == 3 ? PdfColors.red900 : PdfColors.black)),
                    ),
                    _cell(f.observation, isHeader: false),
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
  
  static void _addMesuresEssaisPages(pw.Document pdf, MesuresEssais mesures, Map<String, int> trackedPages) {
    // Page intro avec conditions ET les deux essais
    pdf.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(),
      header: (ctx) => _buildPageHeaderWidget(),
      build: (ctx) => [
          PageTracker(
            key: 'mesures',
            registry: trackedPages,
            child: _sectionBox('RESULTATS DES MESURES ET ESSAIS'),
          ),
          pw.SizedBox(height: 10),
          
          PageTracker(
            key: 'mesures_conditions',
            registry: trackedPages,
            child: _subSectionBar("Conditions de mesure"),
          ),
          pw.SizedBox(height: 10),
          
          // Conditions générales
          _bodyBold("MESURES D'ISOLEMENT"),
          _bodyText("Les mésures d'isolement par rapport a la terre sont effectuées sous 500 V continu sur les canalisations en aval des DDR defectueux. La valeur est satisfaisante si supérieure a 0,5 M.ohms."),
          pw.SizedBox(height: 5),
          
          _bodyBold('VERIFICATION DE LA CONTINUITE ET RESISTANCE DES CONDUCTEURS DE PROTECTION'),
          _bodyText('Correcte si la valeur mesurée satisfait aux prescriptions du guide UTE C 15-105 \u00A7 D6.'),
          pw.SizedBox(height: 5),
          
          _bodyBold('ESSAIS DE DECLENCHEMENT DES DISPOSITIFS DIFFERENTIELS RESIDUELS'),
          _bodyText('La valeur du seuil de déclenchement est correcte si elle est comprise entre 0,5 IAn et IAn.'),
          pw.SizedBox(height: 5),
          
          _bodyBold('MESURE DES IMPEDANCES DE BOUCLE (PROTECTION \u00AB CONTACTS INDIRECTS \u00BB)'),
          _bodyText('Correcte si le temps de coupure, pour le courant de défaut déterminé, satisfait aux prescriptions du guide UTE C 15-105.'),
          
          pw.SizedBox(height: 16),
          
          // Essais de démarrage automatique (sur la même page)
          PageTracker(
            key: 'mesures_demarrage',
            registry: trackedPages,
            child: _subSectionBar('Essais de démarrage automatique du groupe électrogène'),
          ),
          pw.SizedBox(height: 5),
          _resultBox(mesures.essaiDemarrageAuto.observation ?? 'Non satisfaisant'),
          
          pw.SizedBox(height: 16),
          
          // Test de l'arret d'urgence (sur la même page)
          PageTracker(
            key: 'mesures_arret',
            registry: trackedPages,
            child: _subSectionBar("Test de fonctionnement de l'arrêt d'urgence"),
          ),
          pw.SizedBox(height: 5),
          _resultBox(mesures.testArretUrgence.observation ?? 'Satisfaisant'),
      ],
    ));
    
    // Prise de terre (nouvelle page)
    pdf.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(),
      header: (ctx) => _buildPageHeaderWidget(),
      build: (ctx) => [
        PageTracker(
          key: 'mesures_terre',
          registry: trackedPages,
          child: _subSectionBar('Prise de terre'),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: borderColor, width: 0.4),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.2), // Localisation
            1: pw.FlexColumnWidth(1.6), // Identification de la prise de terre
            2: pw.FlexColumnWidth(1.2), // Condition de mesure
            3: pw.FlexColumnWidth(1.4), // Nature de la prise de terre
            4: pw.FlexColumnWidth(1.2), // Méthode de mesure
            5: pw.FlexColumnWidth(0.8), // Valeur de la mesure
            6: pw.FlexColumnWidth(1.2), // Observation
          },
          children: [
            _tableHeaderRow([
              'Localisation',
              'Identification de la prise de terre',
              'Condition de mésure',
              'Nature de la prise de terre',
              'Méthode de mésure',
              'Valeur de la mésure',
              'Observation'
            ]),
            if (mesures.prisesTerre.isEmpty)
              pw.TableRow(children: List.generate(7, (_) => _cell('', isHeader: false)))
            else
              ...mesures.prisesTerre.asMap().entries.map((e) {
                final pt = e.value;
                final obs = pt.observation ?? '';
                final isSat = obs.toLowerCase().contains('satisfaisant') && !obs.toLowerCase().contains('non');
                final isNonSat = obs.toLowerCase().contains('non') || obs.toLowerCase().contains('accessible');
                final obsColor = isSat ? PdfColor.fromInt(0xFF1B5E20) : (isNonSat ? PdfColor.fromInt(0xFFB71C1C) : darkGrey);

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: e.key.isOdd ? tableRowAlt : PdfColors.white),
                  children: [
                    _cell(pt.localisation, isHeader: false, centered: true),
                    _cell(pt.identification, isHeader: false, centered: true),
                    _cell(pt.conditionPriseTerre, isHeader: false, centered: true),
                    _cell(pt.naturePriseTerre, isHeader: false, centered: true),
                    _cell(pt.methodeMesure, isHeader: false, centered: true),
                    _cell(pt.valeurMesure?.toStringAsFixed(2) ?? '-', isHeader: false, centered: true),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        obs,
                        style: pw.TextStyle(
                          font: _fontBold,
                          fontSize: fsSmall,
                          color: obsColor,
                        ),
                      ),
                    ),
                  ],
                );
              }),
          ],
        ),
        if (mesures.avisMesuresTerre.observation != null && mesures.avisMesuresTerre.observation!.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text('❖ Avis sur les mésures', style: pw.TextStyle(font: _fontBold, fontSize: fsBody, color: headerColor)),
          pw.SizedBox(height: 4),
          ...mesures.avisMesuresTerre.observation!.split('\n').map((line) {
            if (line.trim().isEmpty) return pw.SizedBox();
            final isSat = line.toLowerCase().contains('satisfaisant') && !line.toLowerCase().contains('non');
            final isNonSat = line.toLowerCase().contains('non');
            final bulletColor = isSat ? PdfColor.fromInt(0xFF1B5E20) : (isNonSat ? PdfColor.fromInt(0xFFB71C1C) : darkGrey);
            return pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10, bottom: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('➢  ', style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: bulletColor)),
                  pw.Expanded(
                    child: pw.Text(line.trim(), style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall, color: bulletColor)),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    ));
    
    // Mesures d'isolement des circuits BT (nouvelle page)
    pdf.addPage(pw.Page(
      pageTheme: _buildInnerPageTheme(),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _buildPageHeaderWidget(), pw.SizedBox(height: 10),
        _subSectionBar("Mésures d'isolement des circuits BT"),
        pw.SizedBox(height: 8),
      ]),
    ));
    
    // Essais de declenchement des DDR (nouvelle page)
    pdf.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(),
      header: (ctx) => _buildPageHeaderWidget(),
      build: (ctx) {
        final widgets = <pw.Widget>[];

        widgets.add(PageTracker(
          key: 'mesures_ddr',
          registry: trackedPages,
          child: _subSectionBar("Essais de déclenchement des dispositifs différentiels et mesure d'isolement"),
        ));
        widgets.add(pw.SizedBox(height: 8));

        // 1. Table Header of DDR table
        final headerTable = pw.Table(
          border: pw.TableBorder(
            top: pw.BorderSide(color: borderColor, width: 0.4),
            left: pw.BorderSide(color: borderColor, width: 0.4),
            right: pw.BorderSide(color: borderColor, width: 0.4),
            bottom: pw.BorderSide(color: borderColor, width: 0.4),
            verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(0.6), // Quantité
            1: pw.FlexColumnWidth(2.0), // Désignation circuit
            2: pw.FlexColumnWidth(1.0), // Type dispositif
            3: pw.FlexColumnWidth(1.8), // Réglage (divided into IAn and Tempo)
            4: pw.FlexColumnWidth(0.8), // Essai
            5: pw.FlexColumnWidth(1.0), // Isolement
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: lightBlue),
              children: [
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Text("Quantité", style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
                ),
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Text("Désignation circuit", style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
                ),
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Text("Type de dispositif", style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
                ),
                // Réglage (double level with vertical inside borders)
                pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Text("Réglage", style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
                    ),
                    pw.Divider(height: 0.4, color: borderColor),
                    pw.Table(
                      border: pw.TableBorder(verticalInside: pw.BorderSide(color: borderColor, width: 0.4)),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(0.9),
                        1: pw.FlexColumnWidth(0.9),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Text("I\u0394n (mA)", style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
                            pw.Text("Tempo (s)", style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Text("Essai", style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
                ),
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Text("Isolement\n(M\u2126)", style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor), textAlign: pw.TextAlign.center),
                ),
              ],
            ),
          ],
        );

        widgets.add(headerTable);

        if (mesures.essaisDeclenchement.isEmpty) {
          widgets.add(pw.Table(
            border: pw.TableBorder(
              left: pw.BorderSide(color: borderColor, width: 0.4),
              right: pw.BorderSide(color: borderColor, width: 0.4),
              bottom: pw.BorderSide(color: borderColor, width: 0.4),
              verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.6),
              1: pw.FlexColumnWidth(2.0),
              2: pw.FlexColumnWidth(1.0),
              3: pw.FlexColumnWidth(0.9),
              4: pw.FlexColumnWidth(0.9),
              5: pw.FlexColumnWidth(0.8),
              6: pw.FlexColumnWidth(1.0),
            },
            children: [
              pw.TableRow(
                children: List.generate(7, (_) => _cell("", isHeader: false)),
              ),
            ],
          ));
        } else {
          // Groupement sémantique par local puis par coffret
          final ddrGroups = <String, Map<String, List<EssaiDeclenchementDifferentiel>>>{};
          for (final es in mesures.essaisDeclenchement) {
            final local = es.localisation.trim().isEmpty ? "HORS LOCAL" : es.localisation.trim();
            final coffret = es.coffret?.trim().isEmpty == true ? "HORS COFFRET" : es.coffret!.trim();
            ddrGroups.putIfAbsent(local, () => {});
            ddrGroups[local]!.putIfAbsent(coffret, () => []);
            ddrGroups[local]![coffret]!.add(es);
          }

          int altIdx = 0;
          ddrGroups.forEach((localName, coffrets) {
            // Local Name group banner: spans the full width without vertical lines
            widgets.add(pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border(
                  left: pw.BorderSide(color: borderColor, width: 0.4),
                  right: pw.BorderSide(color: borderColor, width: 0.4),
                  bottom: pw.BorderSide(color: borderColor, width: 0.4),
                ),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(localName.toUpperCase(), style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.black)),
            ));

            final localRows = <pw.TableRow>[];
            coffrets.forEach((coffretName, items) {
              for (final es in items) {
                altIdx++;
                final rowBg = altIdx.isOdd ? tableRowAlt : PdfColors.white;
                final essaiColor = es.essai == "B" || es.essai == "OK" ? conformeColor : (es.essai == "M" || es.essai == "NON OK" ? nonConformeColor : null);
                final circuitText = (es.designationCircuit != null && es.designationCircuit!.isNotEmpty)
                    ? es.designationCircuit!
                    : es.coffret ?? "";

                localRows.add(pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowBg),
                  children: [
                    _cell("", isHeader: false, centered: true), // Quantité (empty in reference image)
                    _cell(circuitText, isHeader: false),
                    _cell(es.typeDispositif, isHeader: false, centered: true),
                    _cell(es.reglageIAn?.toString() ?? "-", isHeader: false, centered: true),
                    _cell(es.tempo?.toString() ?? "-", isHeader: false, centered: true),
                    pw.Container(
                      color: essaiColor,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      alignment: pw.Alignment.center,
                      child: pw.Text(es.essai, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
                    ),
                    _cell(es.isolement?.toString() ?? "-", isHeader: false, centered: true),
                  ],
                ));
              }
            });

            widgets.add(pw.Table(
              border: pw.TableBorder(
                left: pw.BorderSide(color: borderColor, width: 0.4),
                right: pw.BorderSide(color: borderColor, width: 0.4),
                bottom: pw.BorderSide(color: borderColor, width: 0.4),
                verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
                horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(0.6), // Quantité
                1: pw.FlexColumnWidth(2.0), // Désignation circuit
                2: pw.FlexColumnWidth(1.0), // Type dispositif
                3: pw.FlexColumnWidth(0.9), // IAn
                4: pw.FlexColumnWidth(0.9), // Tempo
                5: pw.FlexColumnWidth(0.8), // Essai
                6: pw.FlexColumnWidth(1.0), // Isolement
              },
              children: localRows,
            ));
          });
        }

        widgets.add(pw.SizedBox(height: 12));
        widgets.add(_buildAbreviationsTable());

        return widgets;
      },
    ));
    
    // Continuite (nouvelle page)
    pdf.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(),
      header: (ctx) => _buildPageHeaderWidget(),
      build: (ctx) => [
        PageTracker(
          key: 'mesures_continuite',
          registry: trackedPages,
          child: _subSectionBar('Continuité et de la résistance des conducteurs de protection et des liaisons équipotentielles'),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: borderColor, width: 0.4),
          columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(2.5), 2: const pw.FlexColumnWidth(1.5), 3: const pw.FlexColumnWidth(2)},
          children: [
            _tableHeaderRow(['Localisation', 'Désignation Tableau / Equipement', 'Origine Mésure', 'Observation']),
            if (mesures.continuiteResistances.isEmpty)
              pw.TableRow(children: List.generate(4, (_) => _cell('', isHeader: false)))
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

  // Page signature "LA DIRECTION"
  static pw.Widget _buildSignaturePage(RenseignementsGeneraux? rg, String? nomInspecteur) {
    return pw.Column(
      children: [
        _buildPageHeaderWidget(),
        pw.Expanded(
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'LA DIRECTION',
                  style: pw.TextStyle(
                    font: _fontBold,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: headerColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Fait \u00E0 Douala le ${_formatDate(DateTime.now())}',
                  style: pw.TextStyle(
                    font: _fontBold,
                    fontSize: 14,
                    color: darkGrey,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 60),
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
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.center,
              child: pw.Text(
                "Signification des abréviations utilisées",
                style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: headerColor),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );

    final dataTable = pw.Table(
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
        _tableHeaderRow(["Abréviation", "Signification"]),
        _tableDataRow(["DDR", "Disjoncteur Différentiel"], alt: false),
        _tableDataRow(["RD", "Relais Différentiel"], alt: true),
        _tableDataRow(["B", "Bon fonctionnement"], alt: false),
        _tableDataRow(["NE", "Non essayé"], alt: true),
        _tableDataRow(["IDR", "Interrupteur Différentiel"], alt: false),
        _tableDataRow(["I\u0394n", "Intensité différentielle"], alt: true),
        _tableDataRow(["M", "Fonctionnement incorrect"], alt: false),
        _tableDataRow(["Tempo", "Temporisation"], alt: true),
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

  static final Map<String, pw.MemoryImage?> _coffretPhotoCache = {};

  static Future<pw.MemoryImage?> loadAndOptimizeImage(
    String path, {
    int maxWidth = 600,
    int maxHeight = 800,
    int quality = 65,
  }) =>
      _loadAndOptimizeImage(path, maxWidth: maxWidth, maxHeight: maxHeight, quality: quality);

  static Future<pw.MemoryImage?> _loadAndOptimizeImage(
    String path, {
    int maxWidth = 600,
    int maxHeight = 800,
    int quality = 65,
  }) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;

    try {
      final file = File(trimmed);
      if (!await file.exists()) return null;

      try {
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          minWidth: maxWidth,
          minHeight: maxHeight,
          quality: quality,
          format: CompressFormat.jpeg,
        );
        if (compressedBytes != null && compressedBytes.isNotEmpty) {
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

  static Future<List<File>> _addPhotosSectionChunked(
      Mission mission,
      String missionId,
      AuditInstallationsElectriques? audit,
      DescriptionInstallations? description,
      Map<String, int> trackedPages, {
      String? nomSite,
      String? numeroRapport,
  }) async {
    final chunkFiles = <File>[];
    final tempDir = await getTemporaryDirectory();
    final generalPhotos = <_PhotoEntry>[];
    final equipmentGroups = <_EquipmentPhotoGroup>[];
    final seenPaths = <String>{};

    void addGeneralPhotos(List<String>? paths, String desc, {String? repere, bool isObservation = false}) {
      if (paths == null || paths.isEmpty) return;
      for (var p in paths) {
        final trimmed = p.trim();
        if (trimmed.isEmpty) continue;
        if (!seenPaths.contains(trimmed)) {
          seenPaths.add(trimmed);
          generalPhotos.add(_PhotoEntry(filePath: trimmed, description: desc, repere: repere, isObservation: isObservation));
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

      // 3. Photos d'observations
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

    // 1. Photos Description des installations
    if (description != null) {
      void addItems(List<InstallationItem>? items, String categoryLabel) {
        if (items == null) return;
        for (var item in items) {
          final nomItem = item.data['nom'] ?? item.data['Nom'] ?? (item.data.isNotEmpty ? item.data.values.first : '');
          addGeneralPhotos(item.photoPaths, 'Description - $categoryLabel${nomItem.isNotEmpty ? ' : $nomItem' : ''}');
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
      addGeneralPhotos(audit.photos, "Général Audit");
      
      // Moyenne Tension Locaux
      for (var local in audit.moyenneTensionLocaux) {
        addGeneralPhotos(local.photos, local.nom);
        for (var dc in local.dispositionsConstructives) {
          addGeneralPhotos(dc.photos, '${local.nom} - DC : ${dc.elementControle}');
        }
        for (var ce in local.conditionsExploitation) {
          addGeneralPhotos(ce.photos, '${local.nom} - CE : ${ce.elementControle}');
        }
        for (var obs in local.observationsLibres) {
          addGeneralPhotos(obs.photos, '${local.nom} - Obs libre : ${obs.texte}', isObservation: true);
        }
        for (var i = 0; i < local.cellules.length; i++) {
          final cellule = local.cellules[i];
          addGeneralPhotos(cellule.photos, '${local.nom} - Cellule ${i + 1} (${cellule.fonction})');
          for (var ev in cellule.elementsVerifies) {
            addGeneralPhotos(ev.photos, '${local.nom} - Cellule ${i + 1} - Vérif : ${ev.elementControle}', isObservation: ev.conforme == false);
          }
        }
        for (var i = 0; i < local.transformateurs.length; i++) {
          final transfo = local.transformateurs[i];
          addGeneralPhotos(transfo.photos, '${local.nom} - Transformateur ${i + 1}');
          for (var ev in transfo.elementsVerifies) {
            addGeneralPhotos(ev.photos, '${local.nom} - Transformateur ${i + 1} - Vérif : ${ev.elementControle}', isObservation: ev.conforme == false);
          }
        }
        for (var c in local.coffrets) {
          equipmentGroups.add(processCoffret(c, local.nom));
        }
      }

      // Moyenne Tension Zones
      for (var zone in audit.moyenneTensionZones) {
        addGeneralPhotos(zone.photos, zone.nom);
        for (var obs in zone.observationsLibres) {
          addGeneralPhotos(obs.photos, '${zone.nom} - Obs libre : ${obs.texte}', isObservation: true);
        }
        for (var c in zone.coffrets) {
          equipmentGroups.add(processCoffret(c, zone.nom));
        }
        for (var local in zone.locaux) {
          addGeneralPhotos(local.photos, '${zone.nom} - Local ${local.nom}');
          for (var dc in local.dispositionsConstructives) {
            addGeneralPhotos(dc.photos, '${zone.nom} - Local ${local.nom} - DC : ${dc.elementControle}', isObservation: dc.conforme == false);
          }
          for (var ce in local.conditionsExploitation) {
            addGeneralPhotos(ce.photos, '${zone.nom} - Local ${local.nom} - CE : ${ce.elementControle}', isObservation: ce.conforme == false);
          }
          for (var obs in local.observationsLibres) {
            addGeneralPhotos(obs.photos, '${zone.nom} - Local ${local.nom} - Obs libre : ${obs.texte}', isObservation: true);
          }
          for (var c in local.coffrets) {
            equipmentGroups.add(processCoffret(c, '${zone.nom} - Local ${local.nom}'));
          }
        }
      }

      // Basse Tension Zones
      for (var zone in audit.basseTensionZones) {
        addGeneralPhotos(zone.photos, zone.nom);
        for (var obs in zone.observationsLibres) {
          addGeneralPhotos(obs.photos, '${zone.nom} - Obs libre : ${obs.texte}', isObservation: true);
        }
        for (var c in zone.coffretsDirects) {
          equipmentGroups.add(processCoffret(c, zone.nom));
        }
        for (var local in zone.locaux) {
          addGeneralPhotos(local.photos, '${zone.nom} - Local ${local.nom}');
          if (local.dispositionsConstructives != null) {
            for (var dc in local.dispositionsConstructives!) {
              addGeneralPhotos(dc.photos, '${zone.nom} - Local ${local.nom} - DC : ${dc.elementControle}', isObservation: dc.conforme == false);
            }
          }
          if (local.conditionsExploitation != null) {
            for (var ce in local.conditionsExploitation!) {
              addGeneralPhotos(ce.photos, '${zone.nom} - Local ${local.nom} - CE : ${ce.elementControle}', isObservation: ce.conforme == false);
            }
          }
          for (var obs in local.observationsLibres) {
            addGeneralPhotos(obs.photos, '${zone.nom} - Local ${local.nom} - Obs libre : ${obs.texte}', isObservation: true);
          }
          for (var c in local.coffrets) {
            equipmentGroups.add(processCoffret(c, '${zone.nom} - Local ${local.nom}'));
          }
        }
      }
    }

    final activeEquipmentGroups = equipmentGroups.where((g) => g.hasPhotos).toList();
    final totalPhotosCount = generalPhotos.length + activeEquipmentGroups.fold<int>(0, (sum, g) => sum + g.totalPhotosCount);

    if (totalPhotosCount == 0) return chunkFiles;

    int globalPhotoCounter = 1;
    int photoChunkIdx = 0;

    pw.Document photoDoc = pw.Document(
      title: 'Photos Batch - ${mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      compress: true,
    );
    int pagesInCurrentChunk = 0;

    Future<void> flushChunkIfNeeded({bool force = false}) async {
      if (pagesInCurrentChunk > 0 && (pagesInCurrentChunk >= 10 || force)) {
        photoChunkIdx++;
        final chunkBytes = await photoDoc.save();
        final photoChunkFile = File('${tempDir.path}/pdf_chunk_photos_${missionId}_$photoChunkIdx.pdf');
        await photoChunkFile.writeAsBytes(chunkBytes);
        chunkFiles.add(photoChunkFile);

        photoDoc = pw.Document(
          title: 'Photos Batch ${photoChunkIdx + 1} - ${mission.nomClient}',
          author: 'KES INSPECTIONS AND PROJECTS',
          compress: true,
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
        pageImgs.add(await _loadAndOptimizeImage(entry.filePath, maxWidth: 600, maxHeight: 800, quality: 65));
      }

      final startPhotoNum = globalPhotoCounter;
      globalPhotoCounter += pageGroup.length;

      photoDoc.addPage(pw.Page(
        pageTheme: _buildInnerPageTheme(),
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
        pageTheme: _buildInnerPageTheme(),
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
      // Charger l'image extérieure et intérieure
      pw.MemoryImage? extImg;
      if (group.extPhoto != null) {
        extImg = await _loadAndOptimizeImage(group.extPhoto!.filePath, maxWidth: 600, maxHeight: 800, quality: 65);
      }
      pw.MemoryImage? intImg;
      if (group.intPhoto != null) {
        intImg = await _loadAndOptimizeImage(group.intPhoto!.filePath, maxWidth: 600, maxHeight: 800, quality: 65);
      }

      // Charger les images d'observations
      final obsImgs = <pw.MemoryImage?>[];
      for (var obs in group.obsPhotos) {
        obsImgs.add(await _loadAndOptimizeImage(obs.filePath, maxWidth: 600, maxHeight: 800, quality: 65));
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
    return chunkFiles;
  }

  static Future<void> _preloadCoffretPhotos(AuditInstallationsElectriques? audit) async {
    _coffretPhotoCache.clear();
    if (audit == null) return;

    final coffretPhotoPaths = <String>{};

    void collectFromCoffret(CoffretArmoire c) {
      for (final p in [...c.photosInternes, ...c.photos, ...c.photosExternes]) {
        if (p.trim().isNotEmpty) coffretPhotoPaths.add(p.trim());
      }
    }

    for (var local in audit.moyenneTensionLocaux) {
      for (var c in local.coffrets) {
        collectFromCoffret(c);
      }
    }
    for (var zone in audit.moyenneTensionZones) {
      for (var c in zone.coffrets) {
        collectFromCoffret(c);
      }
      for (var local in zone.locaux) {
        for (var c in local.coffrets) {
          collectFromCoffret(c);
        }
      }
    }
    for (var zone in audit.basseTensionZones) {
      for (var c in zone.coffretsDirects) {
        collectFromCoffret(c);
      }
      for (var local in zone.locaux) {
        for (var c in local.coffrets) {
          collectFromCoffret(c);
        }
      }
    }

    for (final path in coffretPhotoPaths) {
      final img = await _loadAndOptimizeImage(path, maxWidth: 300, maxHeight: 300, quality: 60);
      if (img != null) {
        _coffretPhotoCache[path] = img;
      }
    }
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
  }) {
    final hasSchema = mission.schemaOption?.trim().toLowerCase() == 'oui';
    if (!hasSchema) return;

    pdf.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: _buildInnerPageTheme(showWatermark: false),
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
      child: pw.Container(
        padding: const pw.EdgeInsets.only(left: 8, top: 2, bottom: 2),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: accentColor, width: 2.5),
          ),
        ),
        child: pw.Text(
          _normalizeText(title),
          style: pw.TextStyle(
            font: _fontBold,
            fontSize: fsH3,
            fontWeight: pw.FontWeight.bold,
            color: accentColor,
          ),
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

  static pw.Widget _cell(String text, {required bool isHeader, PdfColor? color, int colspan = 1, bool centered = false}) {
    return pw.Container(
      color: color,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        _normalizeText(text),
        style: pw.TextStyle(
          fontSize: isHeader ? fsSmall : fsSmall,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color != null ? PdfColors.white : (isHeader ? headerColor : darkGrey),
        ),
        textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static pw.TableRow _tableHeaderRow(List<String> headers) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: lightBlue),
      children: headers.map((h) => _cell(h, isHeader: true, centered: true)).toList(),
    );
  }

  static pw.TableRow _tableDataRow(List<String> data, {required bool alt, bool centered = false}) {
    return pw.TableRow(
      decoration: alt ? pw.BoxDecoration(color: tableRowAlt) : null,
      children: data.map((d) => _cell(d, isHeader: false, centered: centered)).toList(),
    );
  }

  

  // ──────────────────────────────────────────────────────────────
  //  POINT D'ENTREE PRINCIPAL
  // ──────────────────────────────────────────────────────────────
  
  static Future<File?> generateMissionReport(String missionId) async {
    try {
      await _loadImages();
      await _loadFonts();
      
      final mission = HiveService.getMissionById(missionId);
      if (mission == null) return null;
      
      final description = HiveService.getDescriptionInstallationsByMissionId(missionId);
      final audit = HiveService.getAuditInstallationsByMissionId(missionId);
      await _preloadCoffretPhotos(audit);
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

      final trackedPages = <String, int>{};
      final sommaireEntries = _collectSommaireEntries(
        mission: mission,
        rg: renseignements,
        desc: description,
        audit: audit,
        mesures: mesures,
        foudres: foudres,
      );

      final pdf = pw.Document(
        title: 'Rapport d\'Audit Electrique - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: true,
      );

      // 1. PAGE DE COUVERTURE
      pdf.addPage(
        pw.Page(
          pageTheme: _buildCoverPageTheme(),
          build: (ctx) => _buildCoverPage(mission, renseignements, ctx),
        ),
      );

      // 2. SOMMAIRE
      _addSommairePages(
        pdf,
        sommaireEntries,
        trackedPages,
        nomClient: mission.nomClient,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
      );

      // 3. Rappel des responsabilités + Mesures de sécurité + Objet de la vérification
      pdf.addPage(pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSiteHeader,
          numeroRapport: numeroRapportDoc,
        ),
        build: (ctx) => [

          // ─── OBJET DE LA V\u00c9RIFICATION ───
          pw.SizedBox(height: 20),
          PageTracker(
            key: 'objet',
            registry: trackedPages,
            child: _sectionBox('OBJET DE LA V\u00c9RIFICATION'),
          ),
          pw.SizedBox(height: 10),
          _bodyText(
            'La mission a pour objet de d\u00e9celer les non-conformit\u00e9s pouvant affecter la s\u00e9curit\u00e9 des personnes et des biens, et de s\'assurer du bon \u00e9tat de conservation des installations. '
            'Afin de pr\u00e9senter l\'\u00e9tat des lieux de l\'existant, les points sur lesquels les installations s\'\u00e9cartent des normes et textes applicables, et de proposer des actions correctives.\n\n'
            'D\'une mani\u00e8re g\u00e9n\u00e9rale, la v\u00e9rification a \u00e9t\u00e9 \u00e9tendue \u00e0 l\'ensemble des installations \u00e9lectriques pr\u00e9sent\u00e9es et accessibles dans l\'\u00e9tablissement, depuis les sources jusqu\'aux points d\'utilisation.',
          ),
          pw.SizedBox(height: 10),
          _bodyText('Ainsi sont exclus du champ de la v\u00e9rification\u00a0:'),
          _bulletItem('Les dispositions administratives, organisationnelles et techniques relatives \u00e0 l\'information et \u00e0 la formation du personnel (prescriptions au personnel) lors de l\'exploitation courante, de travaux ou d\'interventions sur les installations, ainsi que les mesures de s\u00e9curit\u00e9 qui en d\u00e9coulent\u00a0;'),
          _bulletItem('Les dispositions administratives relatives aux documents \u00e0 tenir \u00e0 la disposition des autorit\u00e9s publiques\u00a0;'),
          _bulletItem('L\'examen des mat\u00e9riels \u00e9lectriques en pr\u00e9sentation ou en d\u00e9monstration et destin\u00e9s \u00e0 la vente\u00a0;'),
          _bulletItem('Les mat\u00e9riels stock\u00e9s ou en r\u00e9serve, ou signal\u00e9s comme n\'\u00e9tant plus mis en \u0153uvre. Du fait que les installations sont examin\u00e9es en tenant compte des contraintes d\'exploitation et de s\u00e9curit\u00e9 propres \u00e0 chaque \u00e9tablissement et indiqu\u00e9es en d\u00e9but de v\u00e9rification au personnel charg\u00e9 de la v\u00e9rification, celle-ci est limit\u00e9e dans certains cas \u00e0 l\'\u00e9tat apparent des installations.'),
          pw.SizedBox(height: 12),
          _subTitle('R\u00e9f\u00e9rences normatives et r\u00e9glementaires'),
          pw.SizedBox(height: 5),
          _buildNormesTable(),
          pw.SizedBox(height: 12),
          _subTitle('Mat\u00e9riel utilis\u00e9'),
          pw.SizedBox(height: 5),
          _buildMaterielTable(),

          // ─── PÉRIMÈTRE DE LA MISSION (Sur sa propre page immédiatement après OBJET DE LA VÉRIFICATION) ───
          pw.NewPage(),
          PageTracker(
            key: 'perimetre',
            registry: trackedPages,
            child: _sectionBox('PERIMETRE DE LA MISSION'),
          ),
          pw.SizedBox(height: 14),
          _buildPerimetreTable(mission, renseignements),

          // ─── RAPPEL DES RESPONSABILITÉS DE L'EMPLOYEUR ───
          pw.NewPage(),
          PageTracker(
            key: 'rappel',
            registry: trackedPages,
            child: _sectionBox('RAPPEL DES RESPONSABILIT\u00c9S DE L\'EMPLOYEUR'),
          ),
          pw.SizedBox(height: 14),
          _bodyText(
            'KES INSPECTIONS AND PROJECTS a le plaisir de vous transmettre le pr\u00e9sent rapport de v\u00e9rification de vos installations \u00e9lectriques, \u00e9tabli \u00e0 la suite des constats r\u00e9alis\u00e9s sur site.\n'
            'Ce document pr\u00e9sente les observations effectu\u00e9es par le v\u00e9rificateur \u00e0 partir des \u00e9l\u00e9ments et moyens mis \u00e0 sa disposition.\n'
            'Il identifie les points de non-conformit\u00e9 constat\u00e9s au regard des exigences r\u00e9glementaires, et formule, le cas \u00e9ch\u00e9ant, les recommandations techniques n\u00e9cessaires \u00e0 leur mise en conformit\u00e9.',
          ),
          pw.SizedBox(height: 10),
          _subTitle('Responsabilit\u00e9 et accompagnement'),
          _bodyText(
            'Dans le cadre de la mission, il appartient \u00e0 l\'employeur de d\u00e9signer une personne qualifi\u00e9e et inform\u00e9e des installations, charg\u00e9e d\'accompagner le v\u00e9rificateur durant l\'intervention.\n'
            'Cette personne doit pouvoir faciliter l\'acc\u00e8s \u00e0 l\'ensemble des locaux, appareillages et \u00e9quipements \u00e0 contr\u00f4ler.\n\n'
            'L\'employeur reste responsable du bon fonctionnement, de la s\u00e9curit\u00e9 et de la disponibilit\u00e9 des installations tout au long de la v\u00e9rification.\n'
            'Les informations et documents techniques fournis sous sa responsabilit\u00e9 doivent permettre la r\u00e9alisation des contr\u00f4les dans de bonnes conditions.',
          ),
          pw.SizedBox(height: 10),
          _subTitle('Conditions de r\u00e9alisation'),
          _bodyText('Afin d\'assurer le bon d\u00e9roulement des op\u00e9rations, l\'employeur doit\u00a0:'),
          _bulletItem('Veiller \u00e0 ce que la v\u00e9rification soit r\u00e9alis\u00e9e dans des conditions de s\u00e9curit\u00e9 optimales, en particulier lors des acc\u00e8s en zone \u00e9lectrique\u00a0;'),
          _bulletItem('Mettre en \u0153uvre les proc\u00e9dures n\u00e9cessaires aux mises hors tension permettant d\'effectuer les mesures et essais en toute s\u00e9curit\u00e9\u00a0;'),
          _bulletItem('Garantir au v\u00e9rificateur l\'acc\u00e8s \u00e0 l\'ensemble des \u00e9quipements \u00e0 contr\u00f4ler, sans risque de chute ou d\'incident.'),
          pw.SizedBox(height: 8),
          _bodyText(
            'Si certaines v\u00e9rifications n\'ont pu \u00eatre effectu\u00e9es (impossibilit\u00e9 d\'acc\u00e8s, absence d\'agents habilit\u00e9s, contraintes d\'exploitation, documentation manquante, etc.), '
            'KES INSPECTIONS AND PROJECTS en mentionnera la cause dans le rapport.\n\n'
            'Dans le cas des installations de moyenne ou haute tension, la mise hors tension et les man\u0153uvres associ\u00e9es rel\u00e8vent exclusivement de la responsabilit\u00e9 de l\'employeur ou de son repr\u00e9sentant habilit\u00e9.',
          ),
          pw.SizedBox(height: 10),
          _subTitle('V\u00e9rifications compl\u00e9mentaires'),
          _bodyText(
            'Lorsque des \u00e9l\u00e9ments du poste ou de l\'installation n\'ont pu \u00eatre contr\u00f4l\u00e9s lors de la visite initiale, une intervention compl\u00e9mentaire pourra \u00eatre programm\u00e9e \u00e0 la demande de l\'employeur.\n'
            'Cette mission additionnelle fera alors l\'objet d\'une planification et d\'un rapport sp\u00e9cifique.',
          ),
          pw.SizedBox(height: 10),
          _subTitle('Surveillance et maintenance des installations \u00e9lectriques'),
          _bodyText(
            'La v\u00e9rification de conformit\u00e9 des installations \u00e9lectriques ne constitue qu\'un des \u00e9l\u00e9ments concourant \u00e0 la s\u00e9curit\u00e9 des personnes et des biens. Conform\u00e9ment \u00e0 la norme et aux textes r\u00e9glementaires applicables, '
            'le chef d\'\u00e9tablissement doit mettre en place une organisation pour les op\u00e9rations de surveillance et la maintenance des installations \u00e9lectriques. '
            'C\'est dans le cadre de ces op\u00e9rations que les dispositions doivent \u00eatre prises afin de rem\u00e9dier aux d\u00e9fectuosit\u00e9s constat\u00e9es pendant la v\u00e9rification ou celles qui peuvent se manifester apr\u00e8s la v\u00e9rification.',
          ),
          pw.SizedBox(height: 10),
          _subTitle('Formation du personnel intervenant sur les installations et \u00e0 proximit\u00e9'),
          _bodyText(
            'Conform\u00e9ment aux dispositions r\u00e9glementaires en vigueur, l\'employeur doit s\'assurer que le personnel appel\u00e9 \u00e0 intervenir sur ou \u00e0 proximit\u00e9 des installations \u00e9lectriques dispose d\'une habilitation \u00e9lectrique adapt\u00e9e au domaine de tension concern\u00e9 '
            'et \u00e0 la nature des op\u00e9rations \u00e0 r\u00e9aliser.',
          ),
          // ─── MESURES DE S\u00c9CURIT\u00c9 ───
          pw.SizedBox(height: 20),
          PageTracker(
            key: 'mesures_securite',
            registry: trackedPages,
            child: _sectionBox('MESURES DE S\u00c9CURIT\u00c9 AUTOUR DES INSTALLATIONS'),
          ),
          pw.SizedBox(height: 8),
          _bodyText('Suivant la r\u00e9glementation applicable\u00a0:'),
          _bulletItem('Article 5 \u2013 Arr\u00eat\u00e9 039/MTPS/IMT du 26 novembre 1984 fixant les mesures g\u00e9n\u00e9rales d\'hygi\u00e8ne et de s\u00e9curit\u00e9 sur les lieux de travail\u00a0;'),
          _bulletItem('NFC 18-510\u00a0: Op\u00e9rations sur les ouvrages et installations \u00e9lectriques et dans un environnement \u00e9lectrique \u2013 Pr\u00e9vention du risque \u00e9lectrique.'),
          pw.SizedBox(height: 5),
          _bodyText('Le personnel doit avoir suivi avec succ\u00e8s une formation en habilitation \u00e9lectrique en fonction du domaine de tension.'),
          pw.SizedBox(height: 5),
          if (_imgHabilitation != null)
            pw.Container(width: double.infinity, child: pw.Image(_imgHabilitation!, fit: pw.BoxFit.fitWidth))
          else
            pw.SizedBox(),
          pw.SizedBox(height: 12),
          _bodyText(
            'Il est rappel\u00e9 que des dispositions de s\u00e9curit\u00e9 particuli\u00e8res et parfaitement d\u00e9finies doivent \u00eatre prises par le chef de l\'\u00e9tablissement '
            'pour toute intervention de maintenance, r\u00e9glage, nettoyage sur ou \u00e0 proximit\u00e9 des installations \u00e9lectriques.\n\n'
            'L\'acc\u00e8s aux locaux et armoires \u00e9lectriques doit \u00eatre interdit aux personnes non autoris\u00e9es.',
          ),
          pw.SizedBox(height: 8),
          if (_imgAccesGauche != null || _imgAccesDroite1 != null || _imgAccesDroite2 != null)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (_imgAccesGauche != null)
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(height: 80, width: double.infinity, child: pw.Image(_imgAccesGauche!, fit: pw.BoxFit.contain)),
                  ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  flex: 6,
                  child: pw.Row(children: [
                    if (_imgAccesDroite1 != null)
                      pw.Expanded(child: pw.Container(height: 80, width: double.infinity, child: pw.Image(_imgAccesDroite1!, fit: pw.BoxFit.contain))),
                    if (_imgAccesDroite2 != null)
                      pw.Expanded(child: pw.Container(height: 80, width: double.infinity, child: pw.Image(_imgAccesDroite2!, fit: pw.BoxFit.contain))),
                  ]),
                ),
              ],
            ),
          pw.SizedBox(height: 12),
          _bodyText(
            'En effet, une installation, bien que d\u00e9clar\u00e9e conforme en phase d\'exploitation, peut lors d\'op\u00e9rations, par exemple d\'entretien, '
            'n\u00e9cessiter des pr\u00e9cautions sp\u00e9ciales du fait de la pr\u00e9sence \u00e0 proximit\u00e9 de pi\u00e8ces nues sous tension '
            '(cas des locaux r\u00e9serv\u00e9s aux \u00e9lectriciens et dans lesquels la r\u00e9glementation n\'interdit pas la pr\u00e9sence de pi\u00e8ces nues sous tension).',
          ),
          pw.SizedBox(height: 10),
          _subTitle('Technicien en maintenance des installations'),
          pw.SizedBox(height: 5),
          _bodyText('Il est fortement recommand\u00e9 \u00e0 l\'employeur de faire participer les employ\u00e9s \u00e0 des s\u00e9ances de formation sur les modules suivants\u00a0:'),
          _bulletItem('Connaissance des normes en \u00e9lectricit\u00e9 (NC 244 C15 00\u2026)\u00a0;'),
          _bulletItem('Maintenance des installations \u00e9lectriques.'),
          pw.SizedBox(height: 10),
          _subTitle('Engagement de KES INSPECTIONS AND PROJECTS'),
          _bodyText(
            'KES INSPECTIONS AND PROJECTS s\'engage \u00e0 r\u00e9aliser ses v\u00e9rifications dans le strict respect des normes et r\u00e8glements applicables, '
            'avec le souci constant de la s\u00e9curit\u00e9, de la fiabilit\u00e9 technique et de l\'impartialit\u00e9 des constats.',
          ),

          // ─── RÉSUMÉ EXÉCUTIF (Démarre sur une nouvelle page juste après Mesures de Sécurité) ───
          pw.NewPage(),
          PageTracker(
            key: 'resume_executif',
            registry: trackedPages,
            child: _sectionBox('RESUME EXECUTIF'),
          ),
          pw.SizedBox(height: 14),
          pw.Container(width: double.infinity, height: 80),

          // ─── ANALYSE STATISTIQUE (Démarre sur une nouvelle page juste après Résumé Exécutif) ───
          pw.NewPage(),
          ..._buildAnalyseStatistique(mission, trackedPages, numeroRapportDoc),
        ],
      ));

      // 4. Renseignements generaux
      pdf.addPage(pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(),
        build: (ctx) => [_buildRenseignementsGeneraux(mission, renseignements, trackedPages)],
      ));

      // 5. Description des installations
      pdf.addPage(pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSiteHeader,
          numeroRapport: numeroRapportDoc,
        ),
        build: (ctx) => _buildDescriptionInstallationsMulti(description, audit, trackedPages),
      ));

      // 6. Synthèse récapitulative des observations (page de section + contenu)
      if (audit != null) {
        pdf.addPage(pw.MultiPage(
          maxPages: 10000,
          pageTheme: _buildInnerPageTheme(showWatermark: false),
          header: (ctx) => _buildPageHeaderWidget(
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
                    key: 'liste_recap',
                    registry: trackedPages,
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

        pdf.addPage(pw.MultiPage(
          maxPages: 10000,
          pageTheme: _buildInnerPageTheme(),
          header: (ctx) => _buildPageHeaderWidget(
            nomClient: mission.nomClient,
            nomSite: nomSiteHeader,
            numeroRapport: numeroRapportDoc,
          ),
          build: (ctx) => _buildListeRecapitulativeMulti(audit, trackedPages),
        ));
      }

      // 7. Audit des installations electriques (page titre + contenu)
      if (audit != null) {
        pdf.addPage(pw.MultiPage(
          maxPages: 10000,
          pageTheme: _buildInnerPageTheme(showWatermark: false),
          header: (ctx) => _buildPageHeaderWidget(
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
                    key: 'audit',
                    registry: trackedPages,
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
                ],
              ),
            ),
          ],
        ));

        pdf.addPage(pw.MultiPage(
          maxPages: 10000,
          pageTheme: _buildInnerPageTheme(),
          header: (ctx) => _buildPageHeaderWidget(
            nomClient: mission.nomClient,
            nomSite: nomSiteHeader,
            numeroRapport: numeroRapportDoc,
          ),
          build: (ctx) => _buildAuditContentOrdered(audit, trackedPages),
        ));
      }

      // 8. Classement des emplacements
      pdf.addPage(pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSiteHeader,
          numeroRapport: numeroRapportDoc,
        ),
        build: (ctx) => _buildClassementEmplacementsMulti(classements, classementsZones, trackedPages),
      ));

      // 9. Foudre
      pdf.addPage(pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(),
        build: (ctx) => [_buildFoudre(foudres, trackedPages)],
      ));

      // 10. Resultats des mesures et essais
      if (mesures != null) {
        _addMesuresEssaisPages(pdf, mesures, trackedPages);
        pdf.addPage(pw.Page(
          pageTheme: _buildInnerPageTheme(),
          build: (ctx) => _buildSignaturePage(renseignements, currentUser?.fullName),
        ));
      }

      // 11. Page de garde Photos (si des photos sont présentes)
      pdf.addPage(pw.MultiPage(
        maxPages: 10000,
        pageTheme: _buildInnerPageTheme(showWatermark: false),
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

      // 12. Schéma des installations électriques (si disponible, PLACÉ EN FIN DE RAPPORT APRÈS PHOTOS)
      _addSchemaSection(pdf, mission, trackedPages,
          nomSite: nomSiteHeader, numeroRapport: numeroRapportDoc);

      final dir = await getTemporaryDirectory();
      final mainChunkBytes = await pdf.save();
      final mainChunkFile = File('${dir.path}/pdf_chunk_main_$missionId.pdf');
      await mainChunkFile.writeAsBytes(mainChunkBytes);

      final allChunkFiles = <File>[mainChunkFile];

      // 11. Photos Chunked
      final photoChunkFiles = await _addPhotosSectionChunked(
        mission,
        missionId,
        audit,
        description,
        trackedPages,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
      );
      allChunkFiles.addAll(photoChunkFiles);

      final fileName = 'Rapport_${mission.nomClient}_${_formatDate(DateTime.now())}.pdf'
          .replaceAll(RegExp(r'[<>:"/\\|?*\s]'), '_');
      final outputFile = File('${dir.path}/$fileName');

      if (allChunkFiles.length == 1) {
        await mainChunkFile.copy(outputFile.path);
      } else {
        await PdfMergerService.mergePdfFiles(allChunkFiles, outputFile);
      }

      for (final f in allChunkFiles) {
        if (await f.exists()) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }

      if (kDebugMode) {
        print('✅ Rapport PDF genere avec succes: ${outputFile.path}');
      }
      return outputFile;
      
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Erreur generation PDF: $e\n$stack');
      }
      return null;
    } finally {
      _coffretPhotoCache.clear();
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  HELPERS DIVERS
  // ──────────────────────────────────────────────────────────────
  
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

  @override
  void layout(pw.Context context, pw.BoxConstraints constraints, {bool parentUsesSize = false}) {
    final dummy = pw.Text('999', style: style);
    dummy.layout(context, constraints, parentUsesSize: parentUsesSize);
    box = dummy.box;
  }

  @override
  void paint(pw.Context context) {
    super.paint(context);
    final pageNum = registry[keyName];
    final textStr = pageNum != null ? pageNum.toString() : '--';
    
    final textWidget = pw.Text(
      textStr,
      style: style,
      textAlign: pw.TextAlign.right,
    );
    textWidget.layout(context, pw.BoxConstraints.tight(box!.size));
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