// pdf_report_service.dart 

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:inspec_app/models/classement_zone.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;
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
    
    Future<pw.MemoryImage?> tryLoad(String asset) async {
      try {
        return pw.MemoryImage((await rootBundle.load(asset)).buffer.asUint8List());
      } catch (e) {
        if (kDebugMode) print('Image non trouvee: $asset');
        return null;
      }
    }
    
    _watermarkImage       = await tryLoad('assets/images/filigranne_image.png');
    _firstPageFooterImage = await tryLoad('assets/images/firstpage_footer.png');
    _otherPageFooterImage = await tryLoad('assets/images/otherpage_footer.png');
    _logoKesImage         = await tryLoad('assets/images/logo.png');
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
  static pw.PageTheme _buildInnerPageTheme() {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.only(
        left:   kLeftMargin,
        top:    kTopMargin,
        right:  kRightMargin,
        bottom: kBottomMargin + 40,
      ),
      buildBackground: (ctx) => _buildWatermarkBackground(),
      buildForeground: (ctx) => _buildFooterAbsolute(isFirstPage: false, ctx: ctx),
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
  }) {
    final footerImg = isFirstPage ? _firstPageFooterImage : _otherPageFooterImage;
    final double footerImgHeight = isFirstPage ? 80.0 : 50.0;
    const double descente = kBottomMargin + 40;

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
              'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
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
  
  static pw.Widget _buildCoverPage(Mission mission, RenseignementsGeneraux? rg, pw.Context ctx) {
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
                  pw.Container(
                    width: 85, height: 85,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400, width: 1),
                      color: PdfColors.grey200,
                    ),
                    child: pw.Center(
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('LOGO CLIENT',
                              style: pw.TextStyle(font: _fontBold, fontSize: 8, color: PdfColors.grey600)),
                          pw.SizedBox(height: 3),
                          pw.Text('(a coller ici)',
                              style: pw.TextStyle(font: _fontRegular, fontSize: 7, color: PdfColors.grey500)),
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
        pw.SizedBox(height: 34),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey500,
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
        pw.SizedBox(height: 28),
        pw.Container(
          width: double.infinity,
          child: pw.Text(
            '${mission.natureMission!.toUpperCase()} DES INSTALLATIONS ELECTRIQUES',
            style: pw.TextStyle(
              font: _fontRegular, 
              fontWeight: pw.FontWeight.bold,
              fontSize: 16, 
              color: accentColor
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        // pw.SizedBox(height: 20),
        // pw.Container(
        //   width: double.infinity,
        //   child: pw.Text(
        //     mission.nomClient.toUpperCase(),
        //     style: pw.TextStyle(font: _fontBold, fontSize: 16, fontWeight: pw.FontWeight.bold, color: accentColor),
        //     textAlign: pw.TextAlign.center,
        //   ),
        // ),
        pw.SizedBox(height: 20),
        pw.Container(
          width: double.infinity,
          child: pw.Text(
            mission.nomSite!.toUpperCase(),
            style: pw.TextStyle(font: _fontBold, fontSize: 16, fontWeight: pw.FontWeight.bold, color: accentColor),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 150),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
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
            pw.SizedBox(width: 10),
            pw.Container(
              width: 80, height: 80,
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
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label,
                style: pw.TextStyle(fontSize: fsBody, fontWeight: pw.FontWeight.bold, color: headerColor)),
          ),
          pw.Text(': ', style: pw.TextStyle(fontSize: fsBody, fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: fsBody)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  SOMMAIRE (format Word avec points de liaison)
  // ──────────────────────────────────────────────────────────────
  
  static pw.Widget _buildSommaire(
    AuditInstallationsElectriques? audit,
    MesuresEssais? mesures,
    Map<String, int> pages,
  ) {
    final sections = <_SommaireEntry>[
      _SommaireEntry('Sommaire', 2, isTitle: true),
      _SommaireEntry('Rappel des responsabilit\u00e9s de l\'employeur', pages['rappel'] ?? 3, isTitle: true),
      _SommaireEntry('Mesures de s\u00e9curit\u00e9 autour des installations', pages['mesures_securite'] ?? 4, isTitle: true),
      _SommaireEntry('Objet de la v\u00e9rification', pages['objet'] ?? 5, isTitle: true),
      _SommaireEntry('Renseignements g\u00e9n\u00e9raux de l\'\u00e9tablissement', pages['renseignements'] ?? 6, isTitle: true),
      _SommaireEntry('Description des installations', pages['description'] ?? 7, isTitle: true),
      if (audit != null) _SommaireEntry('Liste r\u00e9capitulative des observations', pages['liste_recap'] ?? 8, isTitle: true),
      if (audit != null) _SommaireEntry('Audit des installations \u00e9lectriques', pages['audit'] ?? 9, isTitle: true),
      _SommaireEntry('Classement des locaux/zones et emplacements', pages['classement'] ?? 10, isTitle: true),
      _SommaireEntry('Foudre', pages['foudre'] ?? 11, isTitle: true),
      if (mesures != null) ...[
        _SommaireEntry('R\u00e9sultats des mesures et essais', pages['mesures'] ?? 12, isTitle: true),
        _SommaireEntry('Essais de d\u00e9marrage automatique du groupe \u00e9lectrog\u00e8ne', (pages['mesures'] ?? 12) + 1, isSub: true),
        _SommaireEntry('Test de fonctionnement de l\'arr\u00eat d\'urgence', (pages['mesures'] ?? 12) + 2, isSub: true),
        _SommaireEntry('Prise de terre', (pages['mesures'] ?? 12) + 3, isSub: true),
        _SommaireEntry('Mesures d\'isolement des circuits BT', (pages['mesures'] ?? 12) + 4, isSub: true),
        _SommaireEntry('Essais de d\u00e9clenchement des DDR', (pages['mesures'] ?? 12) + 5, isSub: true),
        _SommaireEntry('Continuit\u00e9 et r\u00e9sistance des conducteurs', (pages['mesures'] ?? 12) + 6, isSub: true),
      ],
      _SommaireEntry('Photos', pages['photos'] ?? 19, isTitle: true),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeaderWidget(),
        pw.SizedBox(height: 10),
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
        pw.SizedBox(height: 20),
        pw.Container(
          width: double.infinity, height: 1.5, color: accentColor,
        ),
        pw.SizedBox(height: 16),
        ...sections.asMap().entries.map((e) {
          final entry = e.value;
          return pw.Padding(
            padding: pw.EdgeInsets.only(
              left: entry.isSub ? 16.0 : 0.0,
              bottom: entry.isTitle ? 5.0 : 3.0,
            ),
            child: _buildSommaireEntryLine(entry),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildSommaireEntryLine(_SommaireEntry entry) {
    final double fontSize = entry.isSub ? 7.5 : 8.5;
    final pw.Font font    = entry.isSub ? _fontRegular : _fontBold;
    final PdfColor color  = entry.isSub ? accentColor : accentColor;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          entry.titre.trimLeft(),
          style: pw.TextStyle(font: font, fontSize: fontSize, color: color),
        ),
        pw.Expanded(
          child: pw.Text(
            ' ${'.' * 120}',
            style: pw.TextStyle(
              font: _fontRegular,
              fontSize: fontSize - 1,
              color: PdfColors.grey500,
              letterSpacing: 0.8,
            ),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            textAlign: pw.TextAlign.left,
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          '${entry.page}',
          style: pw.TextStyle(
            font: _fontBold,
            fontSize: fontSize,
            color: headerColor,
          ),
        ),
      ],
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

  // ──────────────────────────────────────────────────────────────
  //  RENSEIGNEMENTS GENERAUX
  // ──────────────────────────────────────────────────────────────
  
  static pw.Widget _buildRenseignementsGeneraux(
    Mission mission,
    RenseignementsGeneraux? rg,
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
    final autresDocs = mission.autresDocuments ?? [];

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

        _sectionBox('RENSEIGNEMENTS G\u00c9N\u00c9RAUX DE L\'\u00c9TABLISSEMENT'),

        pw.SizedBox(height: 8),

        _subTitle('RENSEIGNEMENTS PRINCIPAUX'),

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

            if (rg != null) ...[
              _tableDataRow(
                ['Installation vérifié', rg.installation],
                alt: true,
              ),
              _tableDataRow(
                ['Activité principale', rg.activite],
                alt: false,
              ),
            ] else if (mission.activiteClient != null)
              _tableDataRow(
                ['Activité principale', mission.activiteClient!],
                alt: false,
              ),

            if (mission.adresseClient != null)
              _tableDataRow(
                ['Adresse', mission.adresseClient!],
                alt: true,
              ),

            if (rg != null && rg.nomSite.isNotEmpty)
              _tableDataRow(
                ['Nom du site', rg.nomSite],
                alt: false,
              )
            else if (mission.nomSite != null &&
                mission.nomSite!.isNotEmpty)
              _tableDataRow(
                ['Nom du site', mission.nomSite!],
                alt: false,
              ),

            _tableDataRow(
              [
                'Nature',
                mission.natureMission ??
                    rg?.verificationType ??
                    '',
              ],
              alt: true,
            ),

            if (dateIntervTxt.isNotEmpty)
              _tableDataRow(
                ['Dates d\'intervention', dateIntervTxt],
                alt: false,
              ),

            if (rg != null && rg.dureeJours > 0)
              _tableDataRow(
                ['Durée', '${rg.dureeJours} jour(s)'],
                alt: true,
              )
            else if (mission.dureeMissionJours != null)
              _tableDataRow(
                [
                  'Durée',
                  '${mission.dureeMissionJours} jour(s)',
                ],
                alt: true,
              ),

            if (rg != null) ...[
              if (rg.accompagnateurs.isNotEmpty)
                _tableDataRow(
                  [
                    'Accompagnateur / Responsable',
                    rg.accompagnateurs
                        .map((m) => m['nom'] ?? '')
                        .where((n) => n.isNotEmpty)
                        .join(', '),
                  ],
                  alt: false,
                ),

              if (rg.registreControle.isNotEmpty)
                _tableDataRow(
                  ['Registre de controle', rg.registreControle],
                  alt: true,
                ),

              if (rg.compteRendu.isNotEmpty)
                _tableDataRow(
                  [
                    'Compte rendu de fin de visite fait à',
                    rg.compteRendu.join(', '),
                  ],
                  alt: false,
                ),

              if (verificateursNoms.isNotEmpty)
                _tableDataRow(
                  ['Vérificateur(s)', verificateursNoms],
                  alt: true,
                ),
            ],
          ],
        ),

  pw.SizedBox(height: 16),

  _subTitle('DOCUMENTS NECESSAIRES A LA VERIFICATION'),

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
      ],
    );
  }
  // ──────────────────────────────────────────────────────────────
  //  DESCRIPTION DES INSTALLATIONS (avec ordre des colonnes)
  // ──────────────────────────────────────────────────────────────
  
  static List<pw.Widget> _buildDescriptionInstallationsMulti(DescriptionInstallations? desc) {
    final widgets = <pw.Widget>[];
    widgets.add(_sectionBox('DESCRIPTION DES INSTALLATIONS'));
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
  
  static List<pw.Widget> _buildListeRecapitulativeMulti(AuditInstallationsElectriques audit) {
    final widgets = <pw.Widget>[];
    widgets.add(_sectionBox('LISTE RECAPITULATIVE DES OBSERVATIONS'));
    widgets.add(pw.SizedBox(height: 8));

    // Légende priorités — style trame
    widgets.add(pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF5F8FC),
        border: pw.Border.all(color: borderColor, width: 0.4),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Niveau de priorité des observations constatées',
              style: pw.TextStyle(font: _fontBold, fontSize: fsBody)),
          pw.SizedBox(height: 5),
          pw.Row(children: [
            _legendePriorite('1', priorite1Color, 'Niveau 1 : À surveiller'),
            pw.SizedBox(width: 16),
            _legendePriorite('2', priorite2Color, 'Niveau 2 : Mise en conformité à planifier'),
            pw.SizedBox(width: 16),
            _legendePriorite('3', priorite3Color, 'Niveau 3 : Critique, Action immédiate'),
          ]),
        ],
      ),
    ));
    widgets.add(pw.SizedBox(height: 14));

    // ── Moyenne Tension ──
    widgets.add(_subSectionBar('Moyenne tension'));
    widgets.add(pw.SizedBox(height: 5));
    final obsMT = _collectObservationsMT(audit);
    widgets.addAll(_buildObsRecapTableMT(obsMT));

    widgets.add(pw.NewPage());

    // ── Basse Tension ──
    widgets.add(_subSectionBar('Basse tension'));
    widgets.add(pw.SizedBox(height: 5));
    final obsBT = _collectObservationsBT(audit);
    widgets.addAll(_buildObsRecapTableBT(obsBT));

    return widgets;
  }

  /// Légende priorité (cercle coloré + texte)
  static pw.Widget _legendePriorite(String num, PdfColor color, String label) {
    return pw.Row(children: [
      pw.Container(
        width: 14, height: 14,
        decoration: pw.BoxDecoration(color: color,
            border: pw.Border.all(color: PdfColors.grey400, width: 0.4),
            shape: pw.BoxShape.circle),
        alignment: pw.Alignment.center,
        child: pw.Text(num,
            style: pw.TextStyle(font: _fontBold, fontSize: 6, color: PdfColors.black)),
      ),
      pw.SizedBox(width: 4),
      pw.Text(label, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
    ]);
  }

  /// ── Tableau récap MT ──
  /// Colonnes : LOCAL | OBSERVATIONS | REF. NORMATIVE | PRIORITÉ
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
        0: pw.FlexColumnWidth(1.8),
        1: pw.FlexColumnWidth(6.2),
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
        0: pw.FlexColumnWidth(1.8),
        1: pw.FlexColumnWidth(3.8),
        2: pw.FlexColumnWidth(1.8),
        3: pw.FlexColumnWidth(0.6),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF2E5F9A)),
          children: [
            _obsHeaderCellMT('LOCAL'),
            _obsHeaderCellMT('OBSERVATIONS'),
            _obsHeaderCellMT('RÉF. NORMATIVE'),
            _obsHeaderCellMT('PRIORITÉ'),
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

        PdfColor badgeColor = PdfColors.white;
        if (o.priorite == '1') badgeColor = priorite1Color;
        if (o.priorite == '2') badgeColor = priorite2Color;
        if (o.priorite == '3') badgeColor = priorite3Color;

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
            // REF. NORMATIVE
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: pw.Text(o.refNorm,
                  style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
            ),
            // PRIORITÉ
            pw.Container(
              color: o.priorite.isNotEmpty ? badgeColor : null,
              padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text(o.priorite,
                  style: pw.TextStyle(
                      font: _fontBold, fontSize: fsSmall,
                      color: o.priorite == '3' ? PdfColors.red900 : PdfColors.black)),
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
          0: pw.FlexColumnWidth(1.8),
          1: pw.FlexColumnWidth(6.2),
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
                  0: pw.FlexColumnWidth(3.8),
                  1: pw.FlexColumnWidth(1.8),
                  2: pw.FlexColumnWidth(0.6),
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
  /// Colonnes : LOCAL | ÉQUIPEMENT | OBSERVATIONS | REF. NORMATIVE | PRIORITÉ
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
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(1.8),
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
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(1.8),
        2: pw.FlexColumnWidth(3.4),
        3: pw.FlexColumnWidth(1.2),
        4: pw.FlexColumnWidth(0.8),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF2E5F9A)),
          children: [
            _obsHeaderCellMT(''), // Première colonne entièrement vide
            _obsHeaderCellMT('ÉQUIPEMENT'),
            _obsHeaderCellMT('OBSERVATIONS'),
            _obsHeaderCellMT('RÉF. NORMATIVE'),
            _obsHeaderCellMT('PRIORITÉ'),
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
      // Troisième ligne : Séparateur local (colspan sur col 1-4)
      final localSeparatorTable = pw.Table(
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        border: pw.TableBorder.all(color: borderColor, width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.2),
          1: pw.FlexColumnWidth(7.2),
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

          PdfColor badgeColor = PdfColors.white;
          if (o.priorite == '1') badgeColor = priorite1Color;
          if (o.priorite == '2') badgeColor = priorite2Color;
          if (o.priorite == '3') badgeColor = priorite3Color;

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
              // REF. NORMATIVE
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: pw.Text(o.refNorm, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
              ),
              // PRIORITÉ
              pw.Container(
                color: o.priorite.isNotEmpty ? badgeColor : null,
                padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text(o.priorite, style: pw.TextStyle(
                    font: _fontBold, fontSize: fsSmall,
                    color: o.priorite == '3' ? PdfColors.red900 : PdfColors.black)),
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
            // OBSERVATIONS + REF + PRIORITÉ
            pw.Table(
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
                verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(3.4),
                1: pw.FlexColumnWidth(1.2),
                2: pw.FlexColumnWidth(0.8),
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
          0: pw.FlexColumnWidth(1.2),
          1: pw.FlexColumnWidth(1.8),
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



  static pw.Widget _badgePriorite(String p, PdfColor color) {
    return pw.Container(
      width: 14, height: 14,
      decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
      alignment: pw.Alignment.center,
      child: pw.Text(p, style: pw.TextStyle(fontSize: fsSmall, fontWeight: pw.FontWeight.bold)),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  AUDIT DES INSTALLATIONS ELECTRIQUES
  // ──────────────────────────────────────────────────────────────
  
  static List<pw.Widget> _buildAuditContentOrdered(AuditInstallationsElectriques audit) {
    final widgets = <pw.Widget>[];

    // 1. Locaux MT directs (hors zone) — PREMIER local sur la même page que le titre
    if (audit.moyenneTensionLocaux.isNotEmpty) {
      if (widgets.isNotEmpty) widgets.add(pw.NewPage());
      widgets.add(_subSectionBar('MOYENNE TENSION — LOCAUX DIRECTS'));
      
      for (int i = 0; i < audit.moyenneTensionLocaux.length; i++) {
        final local = audit.moyenneTensionLocaux[i];
        // Pas de NewPage pour le premier local (i == 0)
        if (i > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildLocalMT(local));
      }
    }

    // 2. Zones MT
    for (var zone in audit.moyenneTensionZones) {
      widgets.add(pw.NewPage());
      widgets.addAll(_buildZone(zone.nom, zone.observationsLibres));
      
      // Locaux dans la zone : premier sur la même page que la zone
      for (int i = 0; i < zone.locaux.length; i++) {
        final local = zone.locaux[i];
        if (i > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildLocalMT(local));
      }
      
      // Coffrets de la zone
      for (int i = 0; i < zone.coffrets.length; i++) {
        final coffret = zone.coffrets[i];
        if (i > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildCoffret(coffret));
      }
    }

    // 3. Zones BT
    for (var zone in audit.basseTensionZones) {
      widgets.add(pw.NewPage());
      widgets.addAll(_buildZone(zone.nom, zone.observationsLibres));
      
      // Coffrets directs de la zone
      for (int i = 0; i < zone.coffretsDirects.length; i++) {
        final coffret = zone.coffretsDirects[i];
        if (i > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildCoffret(coffret));
      }
      
      // Locaux BT
      for (int i = 0; i < zone.locaux.length; i++) {
        final local = zone.locaux[i];
        if (i > 0) widgets.add(pw.NewPage());
        widgets.addAll(_buildLocalBT(local));
      }
    }

    if (widgets.isEmpty) {
      widgets.add(_bodyText('Aucune installation enregistree.'));
    }

    return widgets;
  }

  static List<pw.Widget> _buildZone(String nom, List<ObservationLibre> obs) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 8),
      pw.Container(
        width: double.infinity,
        color: accentColor,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(nom.toUpperCase(),
            style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: PdfColors.white)),
      ),
    ];

    if (obs.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 5));
      widgets.add(_buildObsZoneTable(nom, obs));
    }
    
    widgets.add(pw.SizedBox(height: 5));
    return widgets;
  }

  static pw.Widget _buildObsZoneTable(String zone, List<ObservationLibre> obs) {
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
      children: [
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
              child: pw.Text('OBSERVATIONS RELATIVES A LA ${zone.toUpperCase()}',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: PdfColors.black)),
            ),
          ],
        ),
        // Lignes d'observations
        ...obs.asMap().entries.map((e) => pw.TableRow(
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
        )),
      ],
    );
  }

  static List<pw.Widget> _buildLocalMT(MoyenneTensionLocal local) {
    final widgets = <pw.Widget>[
      _localNameBar(local.nom.toUpperCase()),
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

    final auditWidgets = <pw.Widget>[];
    if (local.dispositionsConstructives.isNotEmpty) {
      auditWidgets.add(_buildDispositionsTable(local.dispositionsConstructives, 'DISPOSITIONS CONSTRUCTIVES DU LOCAL'));
    }
    if (local.conditionsExploitation.isNotEmpty) {
      if (auditWidgets.isNotEmpty) {
        auditWidgets.add(pw.SizedBox(height: 12));
      }
      auditWidgets.add(_buildDispositionsTable(local.conditionsExploitation, 'CONDITIONS D\'EXPLOITATION ET DE SÉCURITÉ'));
    }
    if (auditWidgets.isNotEmpty) {
      widgets.add(pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: auditWidgets,
      ));
    }

    final hasEquipments = local.cellules.isNotEmpty || local.transformateurs.isNotEmpty;
    final hasCoffrets = local.coffrets.isNotEmpty;

    if (auditWidgets.isNotEmpty && (hasEquipments || hasCoffrets)) {
      widgets.add(pw.NewPage());
    }

    if (hasEquipments) {
      final equipmentWidgets = <pw.Widget>[];
      for (final cellule in local.cellules) {
        equipmentWidgets.addAll(_buildCelluleSection(cellule));
      }
      for (final transfo in local.transformateurs) {
        equipmentWidgets.addAll(_buildTransformateurSection(transfo));
      }
      widgets.add(pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: equipmentWidgets,
      ));
      if (hasCoffrets) {
        widgets.add(pw.NewPage());
      }
    }

    for (var coffret in local.coffrets) {
      widgets.addAll(_buildCoffret(coffret));
    }

    return widgets;
  }

  static List<pw.Widget> _buildLocalBT(BasseTensionLocal local) {
    final widgets = <pw.Widget>[
      _localNameBar(local.nom.toUpperCase()),
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

    final auditWidgets = <pw.Widget>[];
    if (local.dispositionsConstructives != null && local.dispositionsConstructives!.isNotEmpty) {
      auditWidgets.add(_buildDispositionsTable(local.dispositionsConstructives!, 'DISPOSITIONS CONSTRUCTIVES DU LOCAL'));
    }
    if (local.conditionsExploitation != null && local.conditionsExploitation!.isNotEmpty) {
      if (auditWidgets.isNotEmpty) {
        auditWidgets.add(pw.SizedBox(height: 12));
      }
      auditWidgets.add(_buildDispositionsTable(local.conditionsExploitation!, 'CONDITIONS D\'EXPLOITATION ET DE SÉCURITÉ'));
    }
    if (auditWidgets.isNotEmpty) {
      widgets.add(pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: auditWidgets,
      ));
    }

    final hasCoffrets = local.coffrets.isNotEmpty;
    if (auditWidgets.isNotEmpty && hasCoffrets) {
      widgets.add(pw.NewPage());
    }

    for (var coffret in local.coffrets) {
      widgets.addAll(_buildCoffret(coffret));
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

  static pw.Widget _buildDispositionsTable(List<ElementControle> elements, String titre) {
    final titleTable = pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: borderColor, width: 0.4),
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(7.2),
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
      columnWidths: const {
        0: pw.FlexColumnWidth(4.0),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(2.0),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Éléments contrôlés',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Conformité',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Observations / Anomalies constatées',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsH3, color: headerColor),
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
        conf = 'NA';
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

      rows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: idx.isEven ? PdfColors.white : tableRowAlt),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Text(el.elementControle,
                style: pw.TextStyle(font: _fontBold, fontSize: fsSmall)),
          ),
          pw.Container(
            color: confColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(conf,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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
      columnWidths: const {
        0: pw.FlexColumnWidth(4.0),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(2.0),
      },
      children: rows,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        titleTable,
        headerTable,
        dataTable,
      ],
    );
  }

  static List<pw.Widget> _buildCelluleSection(Cellule cellule) {
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
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              alignment: pw.Alignment.center,
              child: pw.Text('CELLULE',
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
        0: pw.FlexColumnWidth(4.0),
        1: pw.FlexColumnWidth(3.2),
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
      columnWidths: const {
        0: pw.FlexColumnWidth(4.0),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(2.0),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Éléments vérifiés',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Conformité',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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
        conf = 'NA';
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

      dataRows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: idx.isEven ? PdfColors.white : tableRowAlt),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Text(el.elementControle,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
          pw.Container(
            color: confColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(conf,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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
      columnWidths: const {
        0: pw.FlexColumnWidth(4.0),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(2.0),
      },
      children: dataRows,
    );

    return [
      pw.SizedBox(height: 6),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          titleTable,
          infoTable,
          headerTable,
          dataTable,
        ],
      ),
      pw.SizedBox(height: 5),
    ];
  }

  static List<pw.Widget> _buildTransformateurSection(TransformateurMTBT transfo) {
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
        0: pw.FlexColumnWidth(4.0),
        1: pw.FlexColumnWidth(3.2),
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
      columnWidths: const {
        0: pw.FlexColumnWidth(4.0),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(2.0),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Éléments vérifiés',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              alignment: pw.Alignment.center,
              child: pw.Text('Conformité',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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
        conf = 'NA';
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

      dataRows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: idx.isEven ? PdfColors.white : tableRowAlt),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Text(el.elementControle,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
          pw.Container(
            color: confColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            alignment: pw.Alignment.center,
            child: pw.Text(conf,
                style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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
      columnWidths: const {
        0: pw.FlexColumnWidth(4.0),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(2.0),
      },
      children: dataRows,
    );

    return [
      pw.SizedBox(height: 6),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          titleTable,
          infoTable,
          headerTable,
          dataTable,
        ],
      ),
      pw.SizedBox(height: 5),
    ];
  }


  static List<pw.Widget> _buildCoffret(CoffretArmoire coffret) {
    final widgets = <pw.Widget>[pw.SizedBox(height: 6)];
    String safe(String v) => v.trim().isEmpty ? 'Non renseigné' : v;

    // ── Photo interne ──────────────────────────────────────────────────────
    pw.MemoryImage? photoInterne;
    for (final src in [...coffret.photosInternes, ...coffret.photos]) {
      if (src.isEmpty) continue;
      try {
        final f = File(src);
        if (f.existsSync()) {
          photoInterne = pw.MemoryImage(f.readAsBytesSync());
          break;
        }
      } catch (_) {}
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
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: pw.Text(value, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
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
        titleTable,
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
            _thCell('PDC kA'),
            _thCell('Calibre'),
            _thCell('Section de câble'),
          ],
        ));

        for (final a in coffret.alimentations) {
          alimentRows.add(pw.TableRow(children: [
            _valueCell(a.source.isEmpty ? '-' : a.source),
            _valueCell(a.typeProtection),
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
            1: pw.FlexColumnWidth(1.8),
            2: pw.FlexColumnWidth(0.9),
            3: pw.FlexColumnWidth(0.9),
            4: pw.FlexColumnWidth(1.4),
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
            1: pw.FlexColumnWidth(5.0),
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
                // Right column: nested table containing type, PDC, caliber, section headers and values
                pw.Table(
                  border: pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
                    verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1.8),
                    1: pw.FlexColumnWidth(0.9),
                    2: pw.FlexColumnWidth(0.9),
                    3: pw.FlexColumnWidth(1.4),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
                      children: [
                        _thCell('Type protection'),
                        _thCell('PDC kA'),
                        _thCell('Calibre'),
                        _thCell('Section de câble'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        _valueCell(pt.typeProtection),
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
      widgets.add(pw.SizedBox(height: 3));
      widgets.add(_buildPointsVerificationTable(coffret.pointsVerification));
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


  static pw.Widget _buildPointsVerificationTable(List<PointVerification> points) {
    return pw.Table(
      border: pw.TableBorder(
        left: pw.BorderSide(color: borderColor, width: 0.4),
        right: pw.BorderSide(color: borderColor, width: 0.4),
        bottom: pw.BorderSide(color: borderColor, width: 0.4),
        verticalInside: pw.BorderSide(color: borderColor, width: 0.4),
        horizontalInside: pw.BorderSide(color: borderColor, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.8),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(1.4),
      },
      children: [
        // En-tête en gras — style trame (avec centrage parfait horizontal et vertical)
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8F0FB)),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text('Points de vérification',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text('Conformité',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text('Observation',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text('Reference normative',
                  style: pw.TextStyle(font: _fontBold, fontSize: fsSmall, color: headerColor),
                  textAlign: pw.TextAlign.center),
            ),
          ],
        ),
        ...points.asMap().entries.map((e) {
          final pv = e.value;
          final conf = pv.conformite.toLowerCase().trim();
          final isConf = conf == 'oui';
          final isNA = conf == 'na' || conf == 'non_applicable';
          final confColor = isNA
              ? PdfColor.fromInt(0xFFE0E0E0)
              : (isConf ? conformeColor : nonConformeColor);
          final confText = isNA ? 'N/A' : (isConf ? 'Oui' : 'Non');
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
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: pw.Text(
                    pv.observations != null && pv.observations!.isNotEmpty
                        ? pv.observations!.map((obs) => obs.observation ?? '').where((s) => s.isNotEmpty).join('\n')
                        : pv.observation ?? '',
                    style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: pw.Text(
                    pv.observations != null && pv.observations!.isNotEmpty
                        ? pv.observations!.map((obs) => obs.referenceNormative ?? '').where((s) => s.isNotEmpty).join('\n')
                        : pv.referenceNormative ?? '',
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
  ) {
    final widgets = <pw.Widget>[];

    // _sectionBox title like other sections
    widgets.add(_sectionBox(
      "CLASSEMENT DES LOCAUX ET EMPLACEMENTS EN FONCTION DES INFLUENCES EXTERNES"
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
          // Influences
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
                ],
              ),
            ],
          ),
          // IP/IK
          pw.Table(
            border: pw.TableBorder(verticalInside: pw.BorderSide(color: borderColor, width: 0.4)),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.7),
              1: pw.FlexColumnWidth(0.7),
            },
            children: [
              pw.TableRow(
                children: [
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
              ),
            ],
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
        0: pw.FlexColumnWidth(1.7),
        1: pw.FlexColumnWidth(0.8),
        2: pw.FlexColumnWidth(0.9),
        3: pw.FlexColumnWidth(2.4),
        4: pw.FlexColumnWidth(1.4),
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
  
  static pw.Widget _buildFoudre(List<Foudre> foudres) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeaderWidget(),
        pw.SizedBox(height: 10),
        _sectionBox('FOUDRE'),
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
  
  static void _addMesuresEssaisPages(pw.Document pdf, MesuresEssais mesures) {
    // Page intro avec conditions ET les deux essais
    pdf.addPage(pw.Page(
      pageTheme: _buildInnerPageTheme(),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPageHeaderWidget(),
          pw.SizedBox(height: 10),
          _sectionBox('RESULTATS DES MESURES ET ESSAIS'),
          pw.SizedBox(height: 10),
          
          _subSectionBar("Conditions de mesure"),
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
          _subSectionBar('Essais de démarrage automatique du groupe électrogène'),
          pw.SizedBox(height: 5),
          _resultBox(mesures.essaiDemarrageAuto.observation ?? 'Non satisfaisant'),
          
          pw.SizedBox(height: 16),
          
          // Test de l'arret d'urgence (sur la même page)
          _subSectionBar("Test de fonctionnement de l'arrêt d'urgence"),
          pw.SizedBox(height: 5),
          _resultBox(mesures.testArretUrgence.observation ?? 'Satisfaisant'),
        ],
      ),
    ));
    
    // Prise de terre (nouvelle page)
    pdf.addPage(pw.Page(
      pageTheme: _buildInnerPageTheme(),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _buildPageHeaderWidget(), pw.SizedBox(height: 10),
        _subSectionBar('Prise de terre'),
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
                    _cell(pt.localisation, isHeader: false),
                    _cell(pt.identification, isHeader: false, centered: true),
                    _cell(pt.conditionPriseTerre, isHeader: false, centered: true),
                    _cell(pt.naturePriseTerre, isHeader: false),
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
      ]),
    ));
    
    // Mesures d'isolement des circuits BT (nouvelle page)
    pdf.addPage(pw.Page(
      pageTheme: _buildInnerPageTheme(),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _buildPageHeaderWidget(), pw.SizedBox(height: 10),
        _subSectionBar("Mésures d'isolement des circuits BT"),
        pw.SizedBox(height: 8),
        _bodyText('Sans observation'),
      ]),
    ));
    
    // Essais de declenchement des DDR (nouvelle page)
    pdf.addPage(pw.Page(
      pageTheme: _buildInnerPageTheme(),
      build: (ctx) {
        final widgets = <pw.Widget>[];

        widgets.add(_buildPageHeaderWidget());
        widgets.add(pw.SizedBox(height: 10));
        widgets.add(_subSectionBar("Essais de déclenchement des dispositifs différentiels et mésure d'isolement"));
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

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: widgets,
        );
      },
    ));
    
    // Continuite (nouvelle page)
    pdf.addPage(pw.Page(
      pageTheme: _buildInnerPageTheme(),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _buildPageHeaderWidget(), pw.SizedBox(height: 10),
        _subSectionBar('Continuité et résistance des conducteurs de protection et liaisons équipotentielles'),
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
                return _tableDataRow([c.localisation, c.designationTableau, c.origineMesure, c.observation ?? ''], alt: e.key.isOdd);
              }),
          ],
        ),
      ]),
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

  // ──────────────────────────────────────────────────────────────
  //  PHOTOS (grille 2×2)
  // ──────────────────────────────────────────────────────────────
  
  static Future<void> _addPhotosSection(
      pw.Document pdf,
      Mission mission,
      String missionId,
      AuditInstallationsElectriques? audit, {
      String? nomSite,
      String? numeroRapport,
  }) async {
    final allPhotos = <_PhotoEntry>[];

    if (audit != null) {
      void addList(List<String> paths, String desc, {String? repere}) {
        _addPhotosFromList(allPhotos, paths, desc, repere: repere);
      }
      
      // 1. Photos générales de l'audit
      addList(audit.photos, "Général Audit");
      
      // 2. Moyenne Tension Locaux
      for (var local in audit.moyenneTensionLocaux) {
        addList(local.photos, local.nom);
        for (var dc in local.dispositionsConstructives) {
          addList(dc.photos, '${local.nom} - DC : ${dc.elementControle}');
        }
        for (var ce in local.conditionsExploitation) {
          addList(ce.photos, '${local.nom} - CE : ${ce.elementControle}');
        }
        for (var obs in local.observationsLibres) {
          addList(obs.photos, '${local.nom} - Obs libre : ${obs.texte}');
        }
        for (var i = 0; i < local.cellules.length; i++) {
          final cellule = local.cellules[i];
          addList(cellule.photos, '${local.nom} - Cellule ${i + 1} (${cellule.fonction})');
          for (var ev in cellule.elementsVerifies) {
            addList(ev.photos, '${local.nom} - Cellule ${i + 1} - Vérif : ${ev.elementControle}');
          }
        }
        for (var i = 0; i < local.transformateurs.length; i++) {
          final transfo = local.transformateurs[i];
          addList(transfo.photos, '${local.nom} - Transformateur ${i + 1}');
          for (var ev in transfo.elementsVerifies) {
            addList(ev.photos, '${local.nom} - Transformateur ${i + 1} - Vérif : ${ev.elementControle}');
          }
        }
        for (var c in local.coffrets) {
          final repVal = c.repere?.isNotEmpty == true ? c.repere : c.numeroEquipement;
          addList(c.photos, '${local.nom} - Coffret : ${c.nom}', repere: repVal);
          addList(c.photosExternes, '${local.nom} - Coffret : ${c.nom} (Extérieur)', repere: repVal);
          addList(c.photosInternes, '${local.nom} - Coffret : ${c.nom} (Intérieur)', repere: repVal);
          for (var pv in c.pointsVerification) {
            addList(pv.photos, '${local.nom} - Coffret : ${c.nom} - Point : ${pv.pointVerification}', repere: repVal);
          }
          for (var obs in c.observationsLibres) {
            addList(obs.photos, '${local.nom} - Coffret : ${c.nom} - Obs libre : ${obs.texte}', repere: repVal);
          }
          final pfEnrichies = c.observationsParafoudreEnrichies ?? [];
          for (var obs in pfEnrichies) {
            addList(obs.photos, '${local.nom} - Coffret : ${c.nom} - Parafoudre : ${obs.elementControle}', repere: repVal);
          }
        }
      }

      // 3. Moyenne Tension Zones
      for (var zone in audit.moyenneTensionZones) {
        addList(zone.photos, zone.nom);
        for (var obs in zone.observationsLibres) {
          addList(obs.photos, '${zone.nom} - Obs libre : ${obs.texte}');
        }
        for (var c in zone.coffrets) {
          final repVal = c.repere?.isNotEmpty == true ? c.repere : c.numeroEquipement;
          addList(c.photos, '${zone.nom} - Coffret : ${c.nom}', repere: repVal);
          addList(c.photosExternes, '${zone.nom} - Coffret : ${c.nom} (Extérieur)', repere: repVal);
          addList(c.photosInternes, '${zone.nom} - Coffret : ${c.nom} (Intérieur)', repere: repVal);
          for (var pv in c.pointsVerification) {
            addList(pv.photos, '${zone.nom} - Coffret : ${c.nom} - Point : ${pv.pointVerification}', repere: repVal);
          }
          for (var obs in c.observationsLibres) {
            addList(obs.photos, '${zone.nom} - Coffret : ${c.nom} - Obs libre : ${obs.texte}', repere: repVal);
          }
          final pfEnrichies = c.observationsParafoudreEnrichies ?? [];
          for (var obs in pfEnrichies) {
            addList(obs.photos, '${zone.nom} - Coffret : ${c.nom} - Parafoudre : ${obs.elementControle}', repere: repVal);
          }
        }
        for (var local in zone.locaux) {
          addList(local.photos, '${zone.nom} - Local ${local.nom}');
          for (var dc in local.dispositionsConstructives) {
            addList(dc.photos, '${zone.nom} - Local ${local.nom} - DC : ${dc.elementControle}');
          }
          for (var ce in local.conditionsExploitation) {
            addList(ce.photos, '${zone.nom} - Local ${local.nom} - CE : ${ce.elementControle}');
          }
          for (var obs in local.observationsLibres) {
            addList(obs.photos, '${zone.nom} - Local ${local.nom} - Obs libre : ${obs.texte}');
          }
          for (var c in local.coffrets) {
            final repVal = c.repere?.isNotEmpty == true ? c.repere : c.numeroEquipement;
            addList(c.photos, '${zone.nom} - Local ${local.nom} - Coffret : ${c.nom}', repere: repVal);
            addList(c.photosExternes, '${zone.nom} - Local ${local.nom} - Coffret : ${c.nom} (Extérieur)', repere: repVal);
            addList(c.photosInternes, '${zone.nom} - Local ${local.nom} - Coffret : ${c.nom} (Intérieur)', repere: repVal);
            for (var pv in c.pointsVerification) {
              addList(pv.photos, '${zone.nom} - Local ${local.nom} - Coffret : ${c.nom} - Point : ${pv.pointVerification}', repere: repVal);
            }
            for (var obs in c.observationsLibres) {
              addList(obs.photos, '${zone.nom} - Local ${local.nom} - Coffret : ${c.nom} - Obs libre : ${obs.texte}', repere: repVal);
            }
            final pfEnrichies = c.observationsParafoudreEnrichies ?? [];
            for (var obs in pfEnrichies) {
              addList(obs.photos, '${zone.nom} - Local ${local.nom} - Coffret : ${c.nom} - Parafoudre : ${obs.elementControle}', repere: repVal);
            }
          }
        }
      }

      // 4. Basse Tension Zones
      for (var zone in audit.basseTensionZones) {
        addList(zone.photos, zone.nom);
        for (var obs in zone.observationsLibres) {
          addList(obs.photos, '${zone.nom} - Obs libre : ${obs.texte}');
        }
        for (var c in zone.coffretsDirects) {
          final repVal = c.repere?.isNotEmpty == true ? c.repere : c.numeroEquipement;
          addList(c.photos, '${zone.nom} - Coffret : ${c.nom}', repere: repVal);
          addList(c.photosExternes, '${zone.nom} - Coffret : ${c.nom} (Extérieur)', repere: repVal);
          addList(c.photosInternes, '${zone.nom} - Coffret : ${c.nom} (Intérieur)', repere: repVal);
          for (var pv in c.pointsVerification) {
            addList(pv.photos, '${zone.nom} - Coffret : ${c.nom} - Point : ${pv.pointVerification}', repere: repVal);
          }
          for (var obs in c.observationsLibres) {
            addList(obs.photos, '${zone.nom} - Coffret : ${c.nom} - Obs libre : ${obs.texte}', repere: repVal);
          }
          final pfEnrichies = c.observationsParafoudreEnrichies ?? [];
          for (var obs in pfEnrichies) {
            addList(obs.photos, '${zone.nom} - Coffret : ${c.nom} - Parafoudre : ${obs.elementControle}', repere: repVal);
          }
        }
        for (var local in zone.locaux) {
          addList(local.photos, '${zone.nom} - Local ${local.nom}');
          if (local.dispositionsConstructives != null) {
            for (var dc in local.dispositionsConstructives!) {
              addList(dc.photos, '${zone.nom} - Local ${local.nom} - DC : ${dc.elementControle}');
            }
          }
          if (local.conditionsExploitation != null) {
            for (var ce in local.conditionsExploitation!) {
              addList(ce.photos, '${zone.nom} - Local ${local.nom} - CE : ${ce.elementControle}');
            }
          }
          for (var obs in local.observationsLibres) {
            addList(obs.photos, '${zone.nom} - Local ${local.nom} - Obs libre : ${obs.texte}');
          }
          for (var c in local.coffrets) {
            final repVal = c.repere?.isNotEmpty == true ? c.repere : c.numeroEquipement;
            addList(c.photos, '${zone.nom} - Local ${local.nom} - Coffret : ${c.nom}', repere: repVal);
            addList(c.photosExternes, '${zone.nom} - Local ${local.nom} - Coffret : ${c.nom} (Extérieur)', repere: repVal);
            addList(c.photosInternes, '${zone.nom} - Local ${local.nom} - Coffret : ${c.nom} (Intérieur)', repere: repVal);
            for (var pv in c.pointsVerification) {
              addList(pv.photos, '${zone.nom} - Local ${local.nom} - Coffret : ${c.nom} - Point : ${pv.pointVerification}', repere: repVal);
            }
            for (var obs in c.observationsLibres) {
              addList(obs.photos, '${zone.nom} - Local ${local.nom} - Coffret : ${c.nom} - Obs libre : ${obs.texte}', repere: repVal);
            }
            final pfEnrichies = c.observationsParafoudreEnrichies ?? [];
            for (var obs in pfEnrichies) {
              addList(obs.photos, '${zone.nom} - Local ${local.nom} - Coffret : ${c.nom} - Parafoudre : ${obs.elementControle}', repere: repVal);
            }
          }
        }
      }
    }

        if (allPhotos.isEmpty) return;

    // 1. Photos Cover/Separator Page (similar style to Audit cover page)
    pdf.addPage(pw.Page(
      pageTheme: _buildInnerPageTheme(),
      build: (ctx) => pw.Column(
        children: [
          _buildPageHeaderWidget(
            nomClient: mission.nomClient,
            nomSite: nomSite,
            numeroRapport: numeroRapport,
          ),
          pw.Expanded(
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 350, height: 2, color: accentColor),
                  pw.SizedBox(height: 24),
                  pw.Text(
                    'PHOTOS',
                    style: pw.TextStyle(
                      font: _fontBold, fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: headerColor,
                      letterSpacing: 1.0,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    nomSite?.toUpperCase() ?? mission.nomClient.toUpperCase(),
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
          ),
        ],
      ),
    ));

    // 2. Index page of photo descriptions
    pdf.addPage(pw.Page(
      pageTheme: _buildInnerPageTheme(),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPageHeaderWidget(
            nomClient: mission.nomClient,
            nomSite: nomSite,
            numeroRapport: numeroRapport,
          ),
          pw.SizedBox(height: 10),
          _subSectionBar("Index des photos d'anomalies"),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.4),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.4),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(3),
              3: pw.FlexColumnWidth(1.5),
            },
            children: [
              _tableHeaderRow(['N\u00B0', 'Fichier', 'Localisation / Description', 'Repere']),
              ...allPhotos.asMap().entries.map((e) => _tableDataRow([
                '${e.key + 1}',
                path.basename(e.value.filePath),
                e.value.description,
                e.value.repere ?? '-',
              ], alt: e.key.isOdd)),
            ],
          ),
        ],
      ),
    ));

    final loadedImages = <pw.MemoryImage?>[];
    for (final entry in allPhotos) {
      try {
        final file = File(entry.filePath);
        if (await file.exists()) {
          final compressedBytes = await FlutterImageCompress.compressWithFile(
            file.absolute.path,
            minWidth: 600,
            minHeight: 800,
            quality: 70,
            format: CompressFormat.jpeg,
          );
          if (compressedBytes != null) {
            loadedImages.add(pw.MemoryImage(compressedBytes));
          } else {
            loadedImages.add(pw.MemoryImage(await file.readAsBytes()));
          }
        } else {
          loadedImages.add(null);
        }
      } catch (_) {
        try {
          final file = File(entry.filePath);
          if (await file.exists()) {
            loadedImages.add(pw.MemoryImage(await file.readAsBytes()));
          } else {
            loadedImages.add(null);
          }
        } catch (_) {
          loadedImages.add(null);
        }
      }
    }

    for (int gi = 0; gi < allPhotos.length; gi += 4) {
      final groupEnd = (gi + 4).clamp(0, allPhotos.length);
      final group = allPhotos.sublist(gi, groupEnd);
      final imgs = loadedImages.sublist(gi, groupEnd);
      final startIdx = gi;

      pdf.addPage(pw.Page(
        pageTheme: _buildInnerPageTheme(),
        build: (ctx) {
          final cells = <pw.Widget>[];
          for (int ci = 0; ci < 4; ci++) {
            if (ci < group.length) {
              final entry = group[ci];
              final img = imgs[ci];
              final globalIdx = startIdx + ci + 1;
              cells.add(_buildPhotoCell(entry, img, globalIdx, allPhotos.length));
            } else {
              cells.add(pw.Container(
                margin: const pw.EdgeInsets.all(3),
                color: PdfColors.grey100,
              ));
            }
          }

          return pw.Column(
            children: [
              _buildPageHeaderWidget(
                nomClient: mission.nomClient,
                nomSite: nomSite,
                numeroRapport: numeroRapport,
              ),
              pw.SizedBox(height: 6),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Expanded(
                      child: pw.Row(
                        children: [
                          pw.Expanded(child: cells[0]),
                          pw.Expanded(child: cells[1]),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Row(
                        children: [
                          pw.Expanded(child: cells[2]),
                          pw.Expanded(child: cells[3]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ));
    }
  }

  static pw.Widget _buildPhotoCell(_PhotoEntry entry, pw.MemoryImage? img, int index, int total) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        boxShadow: [pw.BoxShadow(color: PdfColors.grey400, blurRadius: 2, offset: const PdfPoint(1, 1))],
      ),
      child: pw.ClipRRect(
        horizontalRadius: 3,
        verticalRadius: 3,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Bande de titre
            pw.Container(
              color: headerColor,
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Photo $index / $total',
                      style: pw.TextStyle(font: _fontBold, fontSize: 6, color: PdfColors.white)),
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
                              decoration: pw.BoxDecoration(
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
              color: PdfColor.fromInt(0xFFF0F4FA),
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: pw.Text(
                entry.description,
                style: pw.TextStyle(font: _fontRegular, fontSize: 5.5, color: darkGrey),
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _addPhotosFromList(List<_PhotoEntry> list, List<String> photos, String description, {String? repere}) {
    for (var p in photos) {
      if (p.isNotEmpty) list.add(_PhotoEntry(filePath: p, description: description, repere: repere));
    }
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

  static pw.TableRow _tableDataRow(List<String> data, {required bool alt}) {
    return pw.TableRow(
      decoration: alt ? pw.BoxDecoration(color: tableRowAlt) : null,
      children: data.map((d) => _cell(d, isHeader: false)).toList(),
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

      int pageCounter = 1;
      final Map<String, int> pages = {};

      pageCounter++;
      pages['rappel'] = ++pageCounter;
      pages['mesures_securite'] = ++pageCounter;
      pages['objet'] = ++pageCounter;
      pages['renseignements'] = ++pageCounter;
      pages['description'] = ++pageCounter;
      if (audit != null) {
        pages['liste_recap'] = ++pageCounter;
        pages['audit'] = ++pageCounter;
        pageCounter += audit.moyenneTensionZones.length;
        pageCounter += audit.moyenneTensionLocaux.length;
        pageCounter += audit.basseTensionZones.length;
      }
      pages['classement'] = ++pageCounter;
      pages['foudre'] = ++pageCounter;
      if (mesures != null) {
        pages['mesures'] = ++pageCounter;
        pageCounter += 6;
        pages['signature'] = ++pageCounter;
      }
      pages['photos'] = ++pageCounter;

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
      pdf.addPage(pw.Page(
        pageTheme: _buildInnerPageTheme(),
        build: (ctx) => _buildSommaire(audit, mesures, pages),
      ));

      // 3. Rappel des responsabilit\u00e9s + Mesures de s\u00e9curit\u00e9 + Objet de la v\u00e9rification
      pdf.addPage(pw.MultiPage(
        maxPages: 10,
        pageTheme: _buildInnerPageTheme(),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSiteHeader,
          numeroRapport: numeroRapportDoc,
        ),
        build: (ctx) => [
          _sectionBox('RAPPEL DES RESPONSABILIT\u00c9S DE L\'EMPLOYEUR'),
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
          _sectionBox('MESURES DE S\u00c9CURIT\u00c9 AUTOUR DES INSTALLATIONS'),
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
          // ─── OBJET DE LA V\u00c9RIFICATION ───
          pw.SizedBox(height: 20),
          _sectionBox('OBJET DE LA V\u00c9RIFICATION'),
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
        ],
      ));

      // 4. Renseignements generaux
      pdf.addPage(
        pw.Page(
          pageTheme: _buildInnerPageTheme(),
          build: (ctx) => _buildRenseignementsGeneraux(mission, renseignements),
        ),
      );

      // 5. Description des installations
      pdf.addPage(pw.MultiPage(
          maxPages: 200,
        pageTheme: _buildInnerPageTheme(),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSiteHeader,
          numeroRapport: numeroRapportDoc,
        ),
        build: (ctx) => _buildDescriptionInstallationsMulti(description),
      ));

      // 6. Liste recapitulative des observations
      if (audit != null) {
        pdf.addPage(pw.MultiPage(
          maxPages: 200,
          pageTheme: _buildInnerPageTheme(),
          header: (ctx) => _buildPageHeaderWidget(
            nomClient: mission.nomClient,
            nomSite: nomSiteHeader,
            numeroRapport: numeroRapportDoc,
          ),
          build: (ctx) => _buildListeRecapitulativeMulti(audit),
        ));
      }

      // 7. Audit des installations electriques (page titre + contenu)
      if (audit != null) {
        pdf.addPage(pw.Page(
          pageTheme: _buildInnerPageTheme(),
          build: (ctx) => pw.Column(
            children: [
              _buildPageHeaderWidget(
                nomSite: nomSiteHeader,
                numeroRapport: numeroRapportDoc,
              ),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(width: 350, height: 2, color: accentColor),
                      pw.SizedBox(height: 24),
                      pw.Text(
                        'AUDIT DES INSTALLATIONS ELECTRIQUES',
                        style: pw.TextStyle(
                          font: _fontBold, fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: headerColor,
                          letterSpacing: 1.0,
                        ),
                        textAlign: pw.TextAlign.center,
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
              ),
            ],
          ),
        ));

        pdf.addPage(pw.MultiPage(
          maxPages: 200,
          pageTheme: _buildInnerPageTheme(),
          header: (ctx) => _buildPageHeaderWidget(
            nomClient: mission.nomClient,
            nomSite: nomSiteHeader,
            numeroRapport: numeroRapportDoc,
          ),
          build: (ctx) => _buildAuditContentOrdered(audit),
        ));
      }

      // 8. Classement des emplacements
      pdf.addPage(pw.MultiPage(
          maxPages: 200,
        pageTheme: _buildInnerPageTheme(),
        header: (ctx) => _buildPageHeaderWidget(
          nomClient: mission.nomClient,
          nomSite: nomSiteHeader,
          numeroRapport: numeroRapportDoc,
        ),
        build: (ctx) => _buildClassementEmplacementsMulti(classements, classementsZones),
      ));

      // 9. Foudre
      pdf.addPage(
        pw.Page(
          pageTheme: _buildInnerPageTheme(),
          build: (ctx) => _buildFoudre(foudres),
        ),
      );

      // 10. Resultats des mesures et essais
      if (mesures != null) {
        _addMesuresEssaisPages(pdf, mesures);
        pdf.addPage(pw.Page(
          pageTheme: _buildInnerPageTheme(),
          build: (ctx) => _buildSignaturePage(renseignements, currentUser?.fullName),
        ));
      }

      // 11. Photos
      await _addPhotosSection(pdf, mission, missionId, audit,
          nomSite: nomSiteHeader, numeroRapport: numeroRapportDoc);

      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final fileName = 'Rapport_${mission.nomClient}_${_formatDate(DateTime.now())}.pdf'
          .replaceAll(RegExp(r'[<>:"/\\|?*\s]'), '_');
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      if (kDebugMode) {
        print('✅ Rapport PDF genere avec succes: ${file.path}');
      }
      return file;
      
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Erreur generation PDF: $e\n$stack');
      }
      return null;
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
    required this.refNorm,
    required this.priorite,
    this.repere,
  });
}


class _ObsGroup {
  final String local;
  final List<_ObsRecap> items;
  _ObsGroup({required this.local, required this.items});
}

class _PhotoEntry {
  final String filePath;
  final String description;
  final String? repere;
  _PhotoEntry({
    required this.filePath,
    required this.description,
    this.repere,
  });
}

class _SommaireEntry {
  final String titre;
  final int page;
  final bool isSub;
  final bool isTitle;
  _SommaireEntry(this.titre, this.page, {this.isSub = false, this.isTitle = false});
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