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
  static const double fsH1 = 11.0;
  static const double fsH2 = 9.5;
  static const double fsH3 = 9.0;
  static const double fsBody = 8.0;
  static const double fsSmall = 7.0;

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
      'CAPACITE CUVE DE RETENTION',
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

  static String _docStatus(bool? val) => val == true ? 'Presente' : 'Non presente';

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
            'VERIFICATION PERIODIQUE REGLEMENTAIRE DES INSTALLATIONS ELECTRIQUES',
            style: pw.TextStyle(font: _fontRegular, fontSize: 16, color: accentColor),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          width: double.infinity,
          child: pw.Text(
            mission.nomClient.toUpperCase(),
            style: pw.TextStyle(font: _fontBold, fontSize: 16, fontWeight: pw.FontWeight.bold, color: accentColor),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 100),
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
      _SommaireEntry('Rappel des responsabilites de l\'employeur', pages['rappel'] ?? 3, isTitle: true),
      _SommaireEntry('Mesures de securite autours des installations', pages['mesures_securite'] ?? 4, isTitle: true),
      _SommaireEntry('Objet de la verification', pages['objet'] ?? 5, isTitle: true),
      _SommaireEntry('Renseignements generaux de l\'etablissement', pages['renseignements'] ?? 6, isTitle: true),
      _SommaireEntry('Description des installations', pages['description'] ?? 7, isTitle: true),
      if (audit != null) _SommaireEntry('Liste recapitulative des observations', pages['liste_recap'] ?? 8, isTitle: true),
      if (audit != null) _SommaireEntry('Audit des installations electriques', pages['audit'] ?? 9, isTitle: true),
      _SommaireEntry('Classement des locaux/zones et emplacements', pages['classement'] ?? 10, isTitle: true),
      _SommaireEntry('Foudre', pages['foudre'] ?? 11, isTitle: true),
      if (mesures != null) ...[
        _SommaireEntry('Resultats des mesures et essais', pages['mesures'] ?? 12, isTitle: true),
        _SommaireEntry('Essais de demarrage automatique du groupe electrogene', (pages['mesures'] ?? 12) + 1, isSub: true),
        _SommaireEntry('Test de fonctionnement de l\'arret d\'urgence', (pages['mesures'] ?? 12) + 2, isSub: true),
        _SommaireEntry('Prise de terre', (pages['mesures'] ?? 12) + 3, isSub: true),
        _SommaireEntry('Mesures d\'isolement des circuits BT', (pages['mesures'] ?? 12) + 4, isSub: true),
        _SommaireEntry('Essais de declenchement des DDR', (pages['mesures'] ?? 12) + 5, isSub: true),
        _SommaireEntry('Continuite et resistance des conducteurs', (pages['mesures'] ?? 12) + 6, isSub: true),
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
    final PdfColor color  = entry.isSub ? darkGrey : accentColor;

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

  // ──────────────────────────────────────────────────────────────
  //  RAPPEL DES RESPONSABILITES
  // ──────────────────────────────────────────────────────────────
  
  static pw.Widget _buildRappelResponsabilites() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeaderWidget(),
        pw.SizedBox(height: 10),
        _sectionBox('RAPPEL DES RESPONSABILITES DE L\'EMPLOYEUR'),
        pw.SizedBox(height: 8),
        _bodyText(
          'KES INSPECTIONS AND PROJECTS a le plaisir de vous transmettre le present rapport de verification de vos installations electriques, etabli a la suite des constats realises sur site.\n'
          'Ce document presente les observations effectuees par le verificateur a partir des elements et moyens mis a sa disposition.\n'
          'Il identifie les points de non-conformite constates au regard des exigences reglementaires, et formule, le cas echeant, les recommandations techniques necessaires a leur mise en conformite.',
        ),
        pw.SizedBox(height: 12),
        _subTitle('Responsabilite et accompagnement'),
        _bodyText(
          'Dans le cadre de la mission, il appartient a l\'employeur de designer une personne qualifiee et informee des installations, chargee d\'accompagner le verificateur durant l\'intervention.\n'
          'Cette personne doit pouvoir faciliter l\'acces a l\'ensemble des locaux, appareillages et equipements a controler.\n\n'
          'L\'employeur reste responsable du bon fonctionnement, de la securite et de la disponibilite des installations tout au long de la verification.\n'
          'Les informations et documents techniques fournis sous sa responsabilite doivent permettre la realisation des controles dans de bonnes conditions.',
        ),
        pw.SizedBox(height: 12),
        _subTitle('Conditions de realisation'),
        _bodyText('Afin d\'assurer le bon deroulement des operations, l\'employeur doit :'),
        _bulletItem('Veiller a ce que la verification soit realisee dans des conditions de securite optimales, en particulier lors des acces en zone electrique ;'),
        _bulletItem('Mettre en oeuvre les procedures necessaires aux mises hors tension permettant d\'effectuer les mesures et essais en toute securite ;'),
        _bulletItem('Garantir au verificateur l\'acces a l\'ensemble des equipements a controler, sans risque de chute ou d\'incident.'),
        pw.SizedBox(height: 8),
        _bodyText(
          'Si certaines verifications n\'ont pu etre effectuees (impossibilite d\'acces, absence d\'agents habilites, contraintes d\'exploitation, documentation manquante, etc.), '
          'KES INSPECTIONS AND PROJECTS en mentionnera la cause dans le rapport.\n\n'
          'Dans le cas des installations de moyenne ou haute tension, la mise hors tension et les manoeuvres associees relevent exclusivement de la responsabilite de l\'employeur ou de son representant habilite.',
        ),
        pw.SizedBox(height: 12),
        _subTitle('Verifications complementaires'),
        _bodyText(
          'Lorsque des elements du poste ou de l\'installation n\'ont pu etre controles lors de la visite initiale, une intervention complementaire pourra etre programmee a la demande de l\'employeur.\n'
          'Cette mission additionnelle fera alors l\'objet d\'une planification et d\'un rapport specifique.',
        ),
        pw.SizedBox(height: 12),
        _subTitle('Surveillance & maintenance des installations electriques'),
        _bodyText(
          'La verification de conformite des installations electriques ne constitue qu\'un des elements concourant a la securite des personnes et des biens. Conformement a la norme et aux textes reglementaires applicables, '
          'le chef d\'etablissement doit mettre en place une organisation pour les operations de surveillance et la maintenance des installations electriques. '
          'C\'est dans le cadre de ces operations que les dispositions doivent etre prises afin de remedier aux defectuosites constatees pendant la verification ou celles qui peuvent se manifester apres la verification.',
        ),
        pw.SizedBox(height: 12),
        _subTitle('Formation du personnel intervenant sur les installations et a proximite'),
        pw.SizedBox(height: 12),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  MESURE DE SECURITE AUTOURS DES INSTALLATIONS
  // ──────────────────────────────────────────────────────────────

  static pw.Widget _buildMesureSecurite() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeaderWidget(),
        pw.SizedBox(height: 10),
        _sectionBox('MESURES DE SECURITE AUTOURS DES INSTALLATIONS'),
        pw.SizedBox(height: 5),
        _bodyText('Suivant la reglementation applicable,'),
        _bulletItem('Article 5_Arrete 039/MTPS/IMT du 26 Novembre 1984 fixant les mesures generales d\'hygiene et de securite sur les lieux de travail'),
        _bulletItem('NFC 18-510 : Operations sur les ouvrages et installations electriques et dans un environnement electrique - Prevention du risque electrique'),
        pw.SizedBox(height: 5),
        _bodyText('Le personnel doit avoir subi avec succes une formation en habilitation electrique en fonction du domaine de tension.'),
        pw.SizedBox(height: 5),
        if (_imgHabilitation != null)
          pw.Container(width: double.infinity, child: pw.Image(_imgHabilitation!, fit: pw.BoxFit.fitWidth))
        else
          pw.Container(height: 60, color: PdfColors.grey200,
              child: pw.Center(child: pw.Text('image.png (habilitation)', style: pw.TextStyle(font: _fontRegular, fontSize: 8)))),
        pw.SizedBox(height: 12),
        _bodyText(
          'Il est rappele que des dispositions de securite particulieres et parfaitement definies doivent etre prises par le chef de l\'etablissement '
          'pour toute intervention de maintenance, reglage, nettoyage sur ou a proximite des installations electriques.\n\n'
          'L\'acces aux locaux et armoires electriques doit etre interdit par les personnes non autorisees.',
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 4,
              child: _imgAccesGauche != null
                  ? pw.Container(
                      height: 80,
                      width: double.infinity,
                      child: pw.Image(_imgAccesGauche!, fit: pw.BoxFit.contain),
                    )
                  : pw.Container(
                      height: 80,
                      width: double.infinity,
                      color: PdfColors.grey200,
                      child: pw.Center(child: pw.Text('image copy.png')),
                    ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              flex: 6,
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _imgAccesDroite1 != null
                        ? pw.Container(
                            height: 80,
                            width: double.infinity,
                            child: pw.Image(_imgAccesDroite1!, fit: pw.BoxFit.contain),
                          )
                        : pw.Container(
                            height: 80,
                            width: double.infinity,
                            color: PdfColors.grey200,
                            child: pw.Center(child: pw.Text('img copy 2')),
                          ),
                  ),
                  pw.Expanded(
                    child: _imgAccesDroite2 != null
                        ? pw.Container(
                            height: 80,
                            width: double.infinity,
                            child: pw.Image(_imgAccesDroite2!, fit: pw.BoxFit.contain),
                          )
                        : pw.Container(
                            height: 80,
                            width: double.infinity,
                            color: PdfColors.grey200,
                            child: pw.Center(child: pw.Text('img copy 3')),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        _bodyText(
          'En effet, une installation, bien que declaree conforme en phase d\'exploitation, peut lors d\'operations, par exemple d\'entretien, '
          'necessiter des precautions speciales du fait de la presence a proximite de pieces nues sous tension '
          '(cas des locaux reserves aux electriciens et dans lesquels la reglementation n\'interdit pas la presence de pieces nues sous tension).',
        ),
        pw.SizedBox(height: 12),
        _subTitle('Technicien en Maintenance Des Installations'),
        pw.SizedBox(height: 5),
        _bodyText('Il est fortement recommande a l\'employer de faire participer aux employes, a des seances de formations sur les modules suivants :'),
        _bulletItem('Connaissance des normes en electricite (NC 244 C15 00...)'),
        _bulletItem('Maintenance des installations electriques'),
        pw.SizedBox(height: 12),
        _subTitle('Engagement de KES INSPECTIONS AND PROJECTS'),
        _bodyText(
          'KES INSPECTIONS AND PROJECTS s\'engage a realiser ses verifications dans le strict respect des normes et reglements applicables, '
          'avec le souci constant de la securite, de la fiabilite technique et de l\'impartialite des constats.',
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  OBJET DE LA VERIFICATION
  // ──────────────────────────────────────────────────────────────
  
  static pw.Widget _buildObjetVerification() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeaderWidget(),
        pw.SizedBox(height: 10),
        _sectionBox('OBJET DE LA VERIFICATION'),
        pw.SizedBox(height: 8),
        _bodyText(
          'La mission a pour objet de deceler les non-conformites, pouvant affecter la securite des personnes et des biens, et de s\'assurer du bon etat de conservation des installations. '
          'Afin de presenter l\'etat des lieux de l\'existant, les points sur lesquelles les installations s\'ecartent des normes, textes applicables et de proposer des actions correctives.\n\n'
          'D\'une maniere generale, la verification a ete etendue a l\'ensemble des installations electriques presentees et accessibles dans l\'etablissement depuis les sources, jusqu\'aux points d\'utilisations.',
        ),
        pw.SizedBox(height: 12),
        _bodyText('Ainsi sont exclus du champ de la verification :'),
        _bulletItem('Les dispositions administratives, organisationnelles et techniques relatives a l\'information et a la formation du personnel (prescriptions au personnel) lors de l\'exploitation courante, de travaux ou d\'interventions sur les installations ainsi que les mesures de securite qui en decoulent ;'),
        _bulletItem('Les dispositions administratives relatives aux documents a tenir a la disposition des autorites publiques'),
        _bulletItem('L\'examen des materiels electriques en presentation ou en demonstration et destines a la vente ;'),
        _bulletItem('Les materiels stockes ou en reserve ou signales comme n\'etant plus mis en oeuvre. Du fait que les installations sont examinees en tenant compte des contraintes d\'exploitation et de securite propres a chaque etablissement et indiquees en debut de verification au personnel charge de la verification, celle-ci est limitee dans certains cas a l\'etat apparent des installations.'),
        pw.SizedBox(height: 12),
        _subTitle('References normatives et reglementaires'),
        pw.SizedBox(height: 5),
        _buildNormesTable(),
        pw.SizedBox(height: 12),
        _subTitle('Materiel utilise'),
        pw.SizedBox(height: 5),
        _buildMaterielTable(),
      ],
    );
  }

  static pw.Widget _buildNormesTable() {
    final normes = [
      'Articles 6, 112, 113_Arrete 039/MTPS/IMT du 26 Novembre 1984 fixant les mesures generales d\'hygiene et de securite sur les lieux de travail',
      'Cahier de prescription technique applicable au Decret N° 20181969/PM du 15 Mars 2018, fixant les regles de base de securite incendie dans les batiments',
      'Arrete conjoint 002164 du 21 Juin 2012 MNIMIDT/MINEE',
      'Loi N°896/PJL/AN du 15/11/2011',
      'NC 244 C 15 100 - Installation electrique a basse tension',
      'NF C 15 100 - Installation electrique a basse tension',
      'Norme NF C 13 100 - Poste de livraison etabli a l\'interieur d\'un batiment et alimente par un reseau de distribution publique de deuxieme categorie',
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
      ['Mesure de la resistance de prises de terre', 'FLUKE - 1630 2 FC'],
      ['Mesure de l\'isolement', 'CHAUVIN ARNOUX CA 6462'],
      ['Verification de la continuite et de la resistance des conducteurs de protection et des liaisons equipotentielles', 'CHAUVIN ARNOUX CA 6462'],
      ['Test de declenchement des dispositifs differentiels et Mesure des impedances de boucle', 'CHAUVIN ARNOUX CA 6462'],
      ['Controleur d\'installation electrique', 'CHAUVIN ARNOUX CA 6116N'],
      ['Analyseur de reseaux', 'CHAUVIN ARNOUX PEL 103 140631NFH'],
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        _tableHeaderRow(['Description', 'Appareil / Reference']),
        ...materiel.asMap().entries.map((e) =>
          _tableDataRow(e.value, alt: e.key.isOdd)),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  RENSEIGNEMENTS GENERAUX
  // ──────────────────────────────────────────────────────────────
  
  static pw.Widget _buildRenseignementsGeneraux(Mission mission, RenseignementsGeneraux? rg) {
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
    final dateFin   = rg?.dateFin;
    String dateIntervTxt;
    if (dateDebut != null && dateFin != null && !dateDebut.isAtSameMomentAs(dateFin)) {
      dateIntervTxt = 'Du ${_formatDate(dateDebut)} au ${_formatDate(dateFin)}';
    } else if (dateDebut != null) {
      dateIntervTxt = _formatDate(dateDebut);
    } else {
      dateIntervTxt = '';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeaderWidget(nomClient: mission.nomClient),
        pw.SizedBox(height: 10),
        _sectionBox('RENSEIGNEMENTS GENERAUX DE L\'ETABLISSEMENT'),
        pw.SizedBox(height: 8),
        _subTitle('RENSEIGNEMENTS PRINCIPAUX'),
        pw.SizedBox(height: 5),
        pw.Table(
          border: pw.TableBorder.all(color: borderColor, width: 0.4),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
          },
          children: [
            _tableDataRow(['Etablissement verifie', mission.nomClient], alt: false),
            if (rg != null) ...[
              _tableDataRow(['Installation verifiee', rg.installation], alt: true),
              _tableDataRow(['Activite principale', rg.activite], alt: false),
            ] else if (mission.activiteClient != null)
              _tableDataRow(['Activite principale', mission.activiteClient!], alt: false),
            if (mission.adresseClient != null)
              _tableDataRow(['Adresse', mission.adresseClient!], alt: true),
            if (rg != null && rg.nomSite.isNotEmpty)
              _tableDataRow(['Nom du site', rg.nomSite], alt: false)
            else if (mission.nomSite != null && mission.nomSite!.isNotEmpty)
              _tableDataRow(['Nom du site', mission.nomSite!], alt: false),
            _tableDataRow(['Nature', mission.natureMission ?? rg?.verificationType ?? ''], alt: true),
            if (dateIntervTxt.isNotEmpty)
              _tableDataRow(['Dates d\'intervention', dateIntervTxt], alt: false),
            if (rg != null && rg.dureeJours > 0)
              _tableDataRow(['Duree', '${rg.dureeJours} jour(s)'], alt: true)
            else if (mission.dureeMissionJours != null)
              _tableDataRow(['Duree', '${mission.dureeMissionJours} jour(s)'], alt: true),
            if (rg != null) ...[
              if (rg.accompagnateurs.isNotEmpty)
                _tableDataRow(['Accompagnateur / Responsable', rg.accompagnateurs.join(', ')], alt: false),
              if (rg.registreControle.isNotEmpty)
                _tableDataRow(['Registre de controle', rg.registreControle], alt: true),
              if (rg.compteRendu.isNotEmpty)
                _tableDataRow(['Compte rendu de fin de visite fait a', rg.compteRendu.join(', ')], alt: false),
              if (verificateursNoms.isNotEmpty)
                _tableDataRow(['Verificateur(s)', verificateursNoms], alt: true),
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
            _tableDataRow(['Cahier des prescriptions techniques ayant permis la realisation des installations', _docStatus(mission.docCahierPrescriptions)], alt: false),
            _tableDataRow(['Notes de calculs justifiant le dimensionnement des canalisations electriques et des dispositifs de protection', _docStatus(mission.docNotesCalculs)], alt: true),
            _tableDataRow(['Schemas unifilaires des installations electriques', _docStatus(mission.docSchemasUnifilaires)], alt: false),
            _tableDataRow(['Plan de masse a l\'echelle des installations avec implantations des prises de terre et electriques enterres', _docStatus(mission.docPlanMasse)], alt: true),
            _tableDataRow(['Plans architecturaux d\'implantation des differents circuits', _docStatus(mission.docPlansArchitecturaux)], alt: false),
            _tableDataRow(['Declaration CE de conformite et notices des appareillages et cables installes', _docStatus(mission.docDeclarationsCe)], alt: true),
            _tableDataRow(['Liste des installations de securite et effectif maximal des differents locaux ou batiments', _docStatus(mission.docListeInstallations)], alt: false),
            _tableDataRow(['Rapport de derniere verification', _docStatus(mission.docRapportDerniereVerif)], alt: true),
            _tableDataRow(['Plan des locaux, avec indications des locaux a risques particuliers d\'influences externes', _docStatus(mission.docPlanLocauxRisques)], alt: false),
            _tableDataRow(['Rapport d\'analyse risque foudre', _docStatus(mission.docRapportAnalyseFoudre)], alt: true),
            _tableDataRow(['Rapport d\'etude technique foudre', _docStatus(mission.docRapportEtudeFoudre)], alt: false),
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
      widgets.add(_bodyText('Aucune donnee disponible.'));
      return widgets;
    }

    widgets.add(_subTitle('Caracteristiques de l\'alimentation moyenne tension'));
    if (desc.alimentationMoyenneTension.isNotEmpty) {
      widgets.add(_buildInstallationTable(desc.alimentationMoyenneTension, sectionKey: 'MT'));
    } else {
      widgets.add(_bodyText('- Non renseignee'));
    }
    
    widgets.add(_subTitle('Caracteristiques de l\'alimentation basse tension'));
    if (desc.alimentationBasseTension.isNotEmpty) {
      widgets.add(_buildInstallationTable(desc.alimentationBasseTension, sectionKey: 'BT'));
    } else {
      widgets.add(_bodyText('- Non renseignee'));
    }
    
    widgets.add(_subTitle('Caracteristiques du groupe electrogene'));
    if (desc.groupeElectrogene.isNotEmpty) {
      widgets.add(_buildInstallationTable(desc.groupeElectrogene, sectionKey: 'GROUPE'));
    } else {
      widgets.add(_bodyText('- Absent'));
    }
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(_subTitle('Alimentation du groupe electrogene en carburant'));
    if (desc.alimentationCarburant.isNotEmpty) {
      widgets.add(_buildInstallationTable(desc.alimentationCarburant, sectionKey: 'CARBURANT'));
    } else {
      widgets.add(_bodyText('- Non applicable'));
    }
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(_subTitle('Caracteristiques de l\'inverseur'));
    if (desc.inverseur.isNotEmpty) {
      widgets.add(_buildInstallationTable(desc.inverseur, sectionKey: 'INVERSEUR'));
    } else {
      widgets.add(_bodyText('- Absent'));
    }
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(_subTitle('Caracteristiques du stabilisateur'));
    if (desc.stabilisateur.isNotEmpty) {
      widgets.add(_buildInstallationTable(desc.stabilisateur, sectionKey: 'STABILISATEUR'));
    } else {
      widgets.add(_bodyText('- Absent'));
    }
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(_subTitle('Caracteristiques des onduleurs'));
    if (desc.onduleurs.isNotEmpty) {
      widgets.add(_buildInstallationTable(desc.onduleurs, sectionKey: 'ONDULEUR'));
    } else {
      widgets.add(_bodyText('- Absent'));
    }
    widgets.add(pw.SizedBox(height: 8));

    widgets.add(_subTitle('Regime de neutre'));
    widgets.add(_bodyText('- ${desc.regimeNeutre ?? 'Non renseigne'}'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(_subTitle('Eclairage de securite'));
    widgets.add(_bodyText('- ${desc.eclairageSecurite ?? 'Non renseigne'}'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(_subTitle('Modifications apportees aux installations'));
    widgets.add(_bodyText(desc.modificationsInstallations ?? 'Sans Objet'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(_subTitle('Note de calcul des installations electriques'));
    widgets.add(_bodyText('- ${desc.noteCalcul ?? 'Non transmis'}'));
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(_subTitle('Presence de paratonnerre'));
    widgets.add(_bodyText('Presence : ${desc.presenceParatonnerre ?? 'NON'}'));
    if (desc.analyseRisqueFoudre != null && desc.analyseRisqueFoudre!.isNotEmpty) {
      widgets.add(_bodyText('Analyse risque foudre : ${desc.analyseRisqueFoudre}'));
    }
    if (desc.etudeTechniqueFoudre != null && desc.etudeTechniqueFoudre!.isNotEmpty) {
      widgets.add(_bodyText('Etude technique foudre : ${desc.etudeTechniqueFoudre}'));
    }
    widgets.add(pw.SizedBox(height: 5));

    widgets.add(_subTitle('Registre de securite'));
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

    if (fieldOrder.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor, width: 0.4)),
        child: _bodyText('Donnees non renseignees'),
      );
    }

    // Si on a un ordre imposé, on réorganise
    List<String> finalOrder = fieldOrder;
    if (sectionKey != null && _columnOrderBySection.containsKey(sectionKey)) {
      finalOrder = [];
      final imposedOrder = _columnOrderBySection[sectionKey]!;
      // D'abord les colonnes imposées qui existent
      for (var imposed in imposedOrder) {
        if (fieldOrder.contains(imposed)) {
          finalOrder.add(imposed);
        }
      }
      // Puis les colonnes restantes (dans l'ordre d'apparition original)
      for (var field in fieldOrder) {
        if (!finalOrder.contains(field)) {
          finalOrder.add(field);
        }
      }
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
            _cell('N\u00B0', isHeader: true),
            ...finalOrder.map((c) => _cell(c, isHeader: true)),
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
            ...finalOrder.map((key) => _cell(e.value.data[key]?.toString() ?? '-', isHeader: false)),
          ],
        )),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  LISTE RECAPITULATIVE DES OBSERVATIONS (BT sur nouvelle page)
  // ──────────────────────────────────────────────────────────────
  
  static List<pw.Widget> _buildListeRecapitulativeMulti(AuditInstallationsElectriques audit) {
    final widgets = <pw.Widget>[];
    widgets.add(_sectionBox('LISTE RECAPITULATIVE DES OBSERVATIONS'));
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(_subTitle('Niveau de priorite des observations constatees'));
    widgets.add(pw.SizedBox(height: 5));
    widgets.add(pw.Row(children: [
      _badgePriorite('1', priorite1Color), pw.SizedBox(width: 4),
      _bodyText('Niveau 1 : A surveiller'),
      pw.SizedBox(width: 12),
      _badgePriorite('2', priorite2Color), pw.SizedBox(width: 4),
      _bodyText('Niveau 2 : Mise en conformite a planifier'),
      pw.SizedBox(width: 12),
      _badgePriorite('3', priorite3Color), pw.SizedBox(width: 4),
      _bodyText('Niveau 3 : Critique, Action immediate'),
    ]));
    widgets.add(pw.SizedBox(height: 16));

    widgets.add(_subTitle('Observations de Moyenne Tension'));
    widgets.add(pw.SizedBox(height: 5));
    widgets.add(_buildObsRecapTable(_collectObservationsMT(audit)));

    widgets.add(pw.NewPage());
    widgets.add(_subTitle('Observations de Basse Tension'));
    widgets.add(pw.SizedBox(height: 5));
    widgets.add(_buildObsRecapTable(_collectObservationsBT(audit)));

    return widgets;
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
      if (local.cellule != null) {
        for (var el in local.cellule!.elementsVerifies) {
          if (el.conforme == false) {
            list.add(_ObsRecap(
              localisation: local.nom,
              coffret: 'Cellule',
              observation: el.observation ?? el.elementControle,
              refNorm: el.referenceNormative ?? '',
              priorite: el.priorite?.toString() ?? '',
            ));
          }
        }
      }
      if (local.transformateur != null) {
        for (var el in local.transformateur!.elementsVerifies) {
          if (el.conforme == false) {
            list.add(_ObsRecap(
              localisation: local.nom,
              coffret: 'Transformateur',
              observation: el.observation ?? el.elementControle,
              refNorm: el.referenceNormative ?? '',
              priorite: el.priorite?.toString() ?? '',
            ));
          }
        }
      }
      for (var coffret in local.coffrets) {
        for (var pv in coffret.pointsVerification) {
          if (pv.conformite == 'non' || pv.conformite == 'Non' || pv.conformite == 'Non conforme') {
            list.add(_ObsRecap(
              localisation: local.nom,
              coffret: coffret.nom,
              observation: pv.observation ?? pv.pointVerification,
              refNorm: pv.referenceNormative ?? '',
              priorite: pv.priorite?.toString() ?? '',
            ));
          }
        }
        for (var obs in coffret.observationsLibres) {
          list.add(_ObsRecap(
            localisation: local.nom,
            coffret: coffret.nom,
            observation: obs.texte,
            refNorm: '',
            priorite: '',
          ));
        }
      }
      for (var obs in local.observationsLibres) {
        list.add(_ObsRecap(
          localisation: local.nom,
          coffret: '',
          observation: obs.texte,
          refNorm: '',
          priorite: '',
        ));
      }
    }

    for (var zone in audit.moyenneTensionZones) {
      for (var coffret in zone.coffrets) {
        for (var pv in coffret.pointsVerification) {
          if (pv.conformite == 'non' || pv.conformite == 'Non' || pv.conformite == 'Non conforme') {
            list.add(_ObsRecap(
              localisation: zone.nom,
              coffret: coffret.nom,
              observation: pv.observation ?? pv.pointVerification,
              refNorm: pv.referenceNormative ?? '',
              priorite: pv.priorite?.toString() ?? '',
            ));
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
              list.add(_ObsRecap(
                localisation: '${zone.nom} / ${local.nom}',
                coffret: coffret.nom,
                observation: pv.observation ?? pv.pointVerification,
                refNorm: pv.referenceNormative ?? '',
                priorite: pv.priorite?.toString() ?? '',
              ));
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
        for (var pv in coffret.pointsVerification) {
          if (pv.conformite == 'non' || pv.conformite == 'Non' || pv.conformite == 'Non conforme') {
            list.add(_ObsRecap(
              localisation: zone.nom,
              coffret: coffret.nom,
              observation: pv.observation ?? pv.pointVerification,
              refNorm: pv.referenceNormative ?? '',
              priorite: pv.priorite?.toString() ?? '',
            ));
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
        if (local.dispositionsConstructives != null) {
          for (var el in local.dispositionsConstructives!) {
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
          for (var pv in coffret.pointsVerification) {
            if (pv.conformite == 'non' || pv.conformite == 'Non' || pv.conformite == 'Non conforme') {
              list.add(_ObsRecap(
                localisation: '${zone.nom} / ${local.nom}',
                coffret: coffret.nom,
                observation: pv.observation ?? pv.pointVerification,
                refNorm: pv.referenceNormative ?? '',
                priorite: pv.priorite?.toString() ?? '',
              ));
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

  static pw.Widget _buildObsRecapTable(List<_ObsRecap> obs) {
    if (obs.isEmpty) {
      return pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor, width: 0.4)),
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text('Aucune observation',
            style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall, fontStyle: pw.FontStyle.italic)),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.4),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(3),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(0.7),
      },
      children: [
        _tableHeaderRow(['N°', 'LOCALISATION', 'COFFRET / ARMOIRE',
            'NON-CONFORMITE - PRECONISATION', 'REF. NORMATIVE', 'PRIORITE']),
        ...obs.asMap().entries.map((e) {
          final o = e.value;
          PdfColor? rowColor;
          if (o.priorite == '3') {
            rowColor = PdfColor.fromInt(0xFFFFEEEE);
          } else if (o.priorite == '2') {
            rowColor = PdfColor.fromInt(0xFFFFF8EE);
          } else if (o.priorite == '1') {
            rowColor = priorite1Color;
          } else if (e.key.isOdd) {
            rowColor = tableRowAlt;
          }

          PdfColor badgeColor = PdfColors.grey300;
          if (o.priorite == '1') badgeColor = priorite1Color;
          if (o.priorite == '2') badgeColor = priorite2Color;
          if (o.priorite == '3') badgeColor = priorite3Color;

          return pw.TableRow(
            decoration: rowColor != null ? pw.BoxDecoration(color: rowColor) : null,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(3),
                alignment: pw.Alignment.center,
                child: pw.Text('${e.key + 1}',
                    style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall)),
              ),
              _cell(o.localisation, isHeader: false),
              _cell(o.coffret, isHeader: false),
              _cell(o.observation, isHeader: false),
              _cell(o.refNorm, isHeader: false),
              pw.Container(
                color: o.priorite.isNotEmpty ? badgeColor : null,
                padding: const pw.EdgeInsets.all(3),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  o.priorite,
                  style: pw.TextStyle(
                    font: _fontBold,
                    fontSize: fsSmall,
                    fontWeight: pw.FontWeight.bold,
                    color: o.priorite == '3' ? PdfColors.red900 : PdfColors.black,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
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
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(nom.toUpperCase(),
            style: pw.TextStyle(fontSize: fsH2, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
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
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            _cell('Items', isHeader: true, color: PdfColors.white),
            _cell('OBSERVATIONS RELATIVES A LA ZONE $zone', isHeader: true, color: PdfColors.white),
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

  static List<pw.Widget> _buildLocalMT(MoyenneTensionLocal local) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 5),
      _subSectionBar(local.nom.toUpperCase()),
      pw.SizedBox(height: 5),
    ];

    if (local.dispositionsConstructives.isNotEmpty) {
      widgets.add(_buildDispositionsTable(local.dispositionsConstructives, 'DISPOSITIONS CONSTRUCTIVES DU LOCAL'));
      widgets.add(pw.SizedBox(height: 5));
    }

    if (local.conditionsExploitation.isNotEmpty) {
      widgets.add(_buildDispositionsTable(local.conditionsExploitation, 'CONDITIONS D\'EXPLOITATION ET DE SECURITE'));
      widgets.add(pw.SizedBox(height: 5));
    }

    if (local.cellule != null) {
      widgets.addAll(_buildCelluleSection(local.cellule!));
    }

    if (local.transformateur != null) {
      widgets.addAll(_buildTransformateurSection(local.transformateur!));
    }

    for (var coffret in local.coffrets) {
      widgets.addAll(_buildCoffret(coffret));
    }

    return widgets;
  }

  static List<pw.Widget> _buildLocalBT(BasseTensionLocal local) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 5),
      _subSectionBar(local.nom.toUpperCase()),
      pw.SizedBox(height: 5),
    ];

    if (local.dispositionsConstructives != null && local.dispositionsConstructives!.isNotEmpty) {
      widgets.add(_buildDispositionsTable(local.dispositionsConstructives!, 'DISPOSITIONS CONSTRUCTIVES DU LOCAL'));
      widgets.add(pw.SizedBox(height: 5));
    }

    if (local.conditionsExploitation != null && local.conditionsExploitation!.isNotEmpty) {
      widgets.add(_buildDispositionsTable(local.conditionsExploitation!, 'CONDITIONS D\'EXPLOITATION ET DE SECURITE'));
      widgets.add(pw.SizedBox(height: 5));
    }

    for (var coffret in local.coffrets) {
      widgets.addAll(_buildCoffret(coffret));
    }

    return widgets;
  }

  static pw.Widget _subSectionBar(String title) {
    return pw.Container(
      width: double.infinity,
      color: accentColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: pw.Text(title,
          style: pw.TextStyle(fontSize: fsH3, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    );
  }

  static pw.Widget _buildDispositionsTable(List<ElementControle> elements, String titre) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            _cell(titre, isHeader: true, colspan: 3),
          ],
        ),
        _tableHeaderRow(['Elements controles', 'Conformite', 'Observations / Anomalies constatees']),
        ...elements.asMap().entries.map((e) {
          final el = e.value;
          String conf;
          PdfColor confColor;
          if (el.conforme == null) {
            conf = 'N/A';
            confColor = tableRowAlt;
          } else if (el.conforme == true) {
            conf = 'Oui';
            confColor = conformeColor;
          } else {
            conf = 'Non';
            confColor = nonConformeColor;
          }
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: e.key.isEven ? PdfColors.white : tableRowAlt),
            children: [
              _cell(el.elementControle, isHeader: false),
              pw.Container(
                color: confColor,
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text(conf, style: pw.TextStyle(fontSize: fsSmall)),
              ),
              _cell(el.observation ?? '', isHeader: false),
            ],
          );
        }),
      ],
    );
  }

  static List<pw.Widget> _buildCelluleSection(Cellule cellule) {
    String safe(String v) => v.trim().isEmpty ? 'Non renseigne' : v;

    return [
      pw.SizedBox(height: 5),
      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: 0.4),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(3),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: lightBlue),
            children: [_cell('CELLULE', isHeader: true, colspan: 4)],
          ),
          _tableDataRow(['Fonction de la cellule', safe(cellule.fonction),
              'Type de cellule', safe(cellule.type)], alt: false),
          _tableDataRow(['Marque / modele / annee', safe(cellule.marqueModeleAnnee),
              'Tension assignee (kV)', safe(cellule.tensionAssignee)], alt: true),
          _tableDataRow(['Pouvoir de coupure assigne (kA)', safe(cellule.pouvoirCoupure),
              'Numerotation / reperage', safe(cellule.numerotation)], alt: false),
          _tableDataRow(['Parafoudres installes sur l\'arrivee', safe(cellule.parafoudres),
              '', ''], alt: true),
        ],
      ),
      if (cellule.elementsVerifies.isNotEmpty) ...[
        pw.SizedBox(height: 3),
        _buildDispositionsTable(cellule.elementsVerifies, 'Elements verifies de la cellule'),
      ],
      pw.SizedBox(height: 5),
    ];
  }

  static List<pw.Widget> _buildTransformateurSection(TransformateurMTBT transfo) {
    String safe(String v) => v.trim().isEmpty ? 'Non renseigne' : v;

    return [
      pw.SizedBox(height: 5),
      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: 0.4),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(3),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: lightBlue),
            children: [_cell('TRANSFORMATEUR MT/BT', isHeader: true, colspan: 4)],
          ),
          _tableDataRow(['Type de transformateur', safe(transfo.typeTransformateur),
              'Marque / Annee de fabrication', safe(transfo.marqueAnnee)], alt: false),
          _tableDataRow(['Puissance assignee (kVA)', safe(transfo.puissanceAssignee),
              'Tension primaire / secondaire', safe(transfo.tensionPrimaireSecondaire)], alt: true),
          _tableDataRow(['Presence du relais Buchholz', safe(transfo.relaisBuchholz),
              'Type de refroidissement', safe(transfo.typeRefroidissement)], alt: false),
          _tableDataRow(['Regime du neutre', safe(transfo.regimeNeutre),
              '', ''], alt: true),
        ],
      ),
      if (transfo.elementsVerifies.isNotEmpty) ...[
        pw.SizedBox(height: 3),
        _buildDispositionsTable(transfo.elementsVerifies, 'Elements verifies du transformateur'),
      ],
      pw.SizedBox(height: 5),
    ];
  }

  static List<pw.Widget> _buildCoffret(CoffretArmoire coffret) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 5),
    ];

    widgets.add(pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(0.8),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('${coffret.type} : ${coffret.nom}',
                  style: pw.TextStyle(fontSize: fsH3, fontWeight: pw.FontWeight.bold, color: headerColor)),
            ),
            _cell('Zone ATEX : ${coffret.zoneAtex ? "Oui" : "Non"}', isHeader: false),
            _cell('Domaine de tension : ${coffret.domaineTension}', isHeader: false),
            _cell('ID armoire : ${coffret.identificationArmoire ? "Oui" : "Non"}', isHeader: false),
            _cell('Signal. danger : ${coffret.signalisationDanger ? "Oui" : "Non"}', isHeader: false),
          ],
        ),
        pw.TableRow(
          children: [
            _cell('Presence schema : ${coffret.presenceSchema ? "Oui" : "Non"}', isHeader: false),
            _cell('Presence parafoudre : ${coffret.presenceParafoudre ? "Oui" : "Non"}', isHeader: false),
            _cell('Thermographie : ${coffret.verificationThermographie ? "Oui" : "Non"}', isHeader: false),
            if (coffret.repere != null)
              _cell('Repere : ${coffret.repere}', isHeader: false)
            else
              _cell('', isHeader: false),
            _cell('', isHeader: false),
          ],
        ),
      ],
    ));

    if (coffret.alimentations.isNotEmpty || coffret.protectionTete != null) {
      widgets.add(pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: 0.4),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1),
          4: const pw.FlexColumnWidth(1.2),
        },
        children: [
          _tableHeaderRow(['Source', 'Type de protection', 'PDC kA', 'Calibre', 'Section de cable']),
          ...coffret.alimentations.map((a) =>
            _tableDataRow(['Alimentation', a.typeProtection, a.pdcKA, a.calibre, a.sectionCable], alt: false)),
          if (coffret.protectionTete != null)
            _tableDataRow(['Protection de tete', coffret.protectionTete!.typeProtection, coffret.protectionTete!.pdcKA, '', ''], alt: coffret.alimentations.isNotEmpty),
        ],
      ));
    }

    if (coffret.pointsVerification.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 3));
      widgets.add(_buildPointsVerificationTable(coffret.pointsVerification));
    }

    if (coffret.observationsLibres.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 3));
      widgets.add(_buildSimpleObsTable(coffret.observationsLibres, 'Observations du coffret'));
    }

    widgets.add(pw.SizedBox(height: 5));
    return widgets;
  }

  static pw.Widget _buildPointsVerificationTable(List<PointVerification> points) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(3.5),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(2.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        _tableHeaderRow(['Points de verification', 'Conformite', 'Observation', 'Reference normative']),
        ...points.asMap().entries.map((e) {
          final pv = e.value;
          final isConf = pv.conformite == 'oui' || pv.conformite == 'Oui';
          final confColor = pv.conformite == 'non_applicable'
              ? tableRowAlt
              : (isConf ? conformeColor : nonConformeColor);
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: e.key.isEven ? PdfColors.white : tableRowAlt),
            children: [
              _cell(pv.pointVerification, isHeader: false),
              pw.Container(
                color: confColor,
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                alignment: pw.Alignment.center,
                child: pw.Text(pv.conformite == 'non_applicable' ? 'NA' : (isConf ? 'Oui' : 'Non'), style: pw.TextStyle(fontSize: fsSmall)),
              ),
              _cell(pv.observation ?? '', isHeader: false),
              _cell(pv.referenceNormative ?? '', isHeader: false),
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

    widgets.add(_sectionBox(
      'CLASSEMENT DES LOCAUX/ZONES ET EMPLACEMENTS EN FONCTION DES INFLUENCES EXTERNES'
    ));
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(_bodyText(
      'Dans le cas d\'absence de fourniture d\'une liste exhaustive des risques '
      'particuliers, le classement eventuel ci-apres est propose par le verificateur '
      'et, sauf avis contraire, considere comme valide par le chef d\'etablissement.',
    ));
    widgets.add(pw.SizedBox(height: 12));

    final rows = <_ClassementRow>[];

    for (var zone in zonesClassement) {
      rows.add(_ClassementRow(
        localisation: zone.nomZone,
        zone: '—',
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
        zone: emp.zone ?? '—',
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

    widgets.add(pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(0.8),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(0.5),
        5: const pw.FlexColumnWidth(0.5),
        6: const pw.FlexColumnWidth(0.5),
        7: const pw.FlexColumnWidth(0.5),
        8: const pw.FlexColumnWidth(0.5),
        9: const pw.FlexColumnWidth(1),
        10: const pw.FlexColumnWidth(0.7),
      },
      children: [
        _tableHeaderRow([
          'Localisation', 'Type', 'Zone',
          'Origine classement',
          'AF', 'BE', 'AE', 'AD', 'AG',
          'Indice IP', 'IK',
        ]),
        if (rows.isEmpty)
          pw.TableRow(children: List.generate(11, (_) => _cell('', isHeader: false)))
        else
          ...rows.asMap().entries.map((e) {
            final r = e.value;
            final rowColor = r.isZone
                ? PdfColor.fromInt(0xFFE8F0FA)
                : (e.key.isOdd ? tableRowAlt : PdfColors.white);
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: rowColor),
              children: [
                _cell(r.localisation, isHeader: r.isZone),
                _cell(r.type, isHeader: false),
                _cell(r.zone, isHeader: false),
                _cell(r.origineClassement, isHeader: false),
                _cell(r.af ?? '—', isHeader: false),
                _cell(r.be ?? '—', isHeader: false),
                _cell(r.ae ?? '—', isHeader: false),
                _cell(r.ad ?? '—', isHeader: false),
                _cell(r.ag ?? '—', isHeader: false),
                _cell(r.ip ?? '—', isHeader: false),
                _cell(r.ik ?? '—', isHeader: false),
              ],
            );
          }),
      ],
    ));

    widgets.add(pw.SizedBox(height: 16));
    widgets.addAll(_buildCodificationInfluencesMulti());

    return widgets;
  }

  static List<pw.Widget> _buildCodificationInfluencesMulti() {
    return [_buildCodificationInfluences()];
  }

  static pw.Widget _buildCodificationInfluences() {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            _cell('CODIFICATION DES INFLUENCES EXTERNES - INDICES ET DEGRES DE PROTECTION', isHeader: true, colspan: 3),
          ],
        ),
        _tableHeaderRow(['PENETRATION DE CORPS SOLIDES', 'SUBSTANCES CORROSIVES OU POLLUANTES', 'MATIERES TRAITEES OU ENTREPOSEES']),
        _tableDataRow(['AE1 : Negligeable -> IP 2X', 'AF1 : Negligeable', 'BE1 : Risques negligeables'], alt: false),
        _tableDataRow(['AE2 : Petits objets (\u2265 2,5 mm) -> IP 3X', 'AF2 : Agents d\'origine atmospherique', 'BE2 : Risques d\'incendie'], alt: true),
        _tableDataRow(['AE3 : Tres petits objets (1 a 2,5 mm) -> IP 4X', 'AF3 : Intermittente ou accidentelle', 'BE3 : Risques d\'explosion'], alt: false),
        _tableDataRow(['AE4 : Poussieres -> IP 5X (Protege)', 'AF4 : Permanente', 'BE4 : Risques de contamination'], alt: true),
        _tableHeaderRow(['ACCES AUX PARTIES DANGEREUSES', 'PENETRATION DE LIQUIDES', 'RISQUES DE CHOCS MECANIQUES']),
        _tableDataRow(['Non protege -> IP 0X', 'AD1 : Negligeable -> IP X0', 'AG1 : Faibles (0,225 J) -> IK 02'], alt: false),
        _tableDataRow(['A : Avec le dos de la main -> IP 1X', 'AD2 : Chutes de gouttes d\'eau -> IP X1', 'AG2 : Moyens (2 J) -> IK 07'], alt: true),
        _tableDataRow(['B : Avec un doigt -> IP 2X', 'AD3 : Chutes de gouttes jusqu\'à 15\u00B0 -> IP X2', 'AG3 : Importants (5 J) -> IK 08'], alt: false),
        _tableDataRow(['C : Avec un outil -> IP 3X', 'AD4 : Aspersion d\'eau -> IP X3', 'AG4 : Tres importants (20 J) -> IK 10'], alt: true),
        _tableDataRow(['D : Avec un fil -> IP 4X', 'AD5 : Projections d\'eau -> IP X4', ''], alt: false),
        _tableDataRow(['', 'AD6 : Jets d\'eau -> IP X5', ''], alt: true),
        _tableDataRow(['', 'AD7 : Paquets d\'eau -> IP X6', ''], alt: false),
        _tableDataRow(['', 'AD8 : Immersion -> IP X7', ''], alt: true),
        _tableDataRow(['', 'AD9 : Submersion -> IP X8', ''], alt: false),
        _tableHeaderRow(['COMPETENCE DES PERSONNES', 'VIBRATIONS', '']),
        _tableDataRow(['BA1 : Ordinaires', 'AH1 : Faibles', ''], alt: false),
        _tableDataRow(['BA2 : Enfants', 'AH2 : Moyennes', ''], alt: true),
        _tableDataRow(['BA3 : Personnes handicapees', 'AH3 : Importantes', ''], alt: false),
        _tableDataRow(['BA4 : Personnes averties', '', ''], alt: true),
        _tableDataRow(['BA5 : Personnes qualifiees', '', ''], alt: false),
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
            columnWidths: {
              0: const pw.FlexColumnWidth(0.5),
              1: const pw.FlexColumnWidth(0.5),
              2: const pw.FlexColumnWidth(5),
            },
            children: [
              _tableHeaderRow(['Items', 'Priorite', 'Observations']),
              ...foudres.asMap().entries.map((e) {
                final f = e.value;
                PdfColor rowColor = e.key.isOdd ? tableRowAlt : PdfColors.white;
                if (f.niveauPriorite == 3) {
                  rowColor = PdfColor.fromInt(0xFFFFEBEB);
                } else if (f.niveauPriorite == 2) {
                  rowColor = PdfColor.fromInt(0xFFFFF8E8);
                }
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowColor),
                  children: [
                    _cell('${e.key + 1}', isHeader: false),
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('${f.niveauPriorite}',
                          style: pw.TextStyle(fontSize: fsBody, fontWeight: pw.FontWeight.bold,
                              color: f.niveauPriorite == 3 ? PdfColors.red800 : darkGrey)),
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
        pw.SizedBox(height: 8),
        
        // Conditions générales
        _bodyBold("MESURES D'ISOLEMENT"),
        _bodyText("Les mesures d'isolement par rapport a la terre sont effectuees sous 500 V continu sur les canalisations en aval des DDR defectueux. La valeur est satisfaisante si superieure a 0,5 M.ohms."),
        pw.SizedBox(height: 5),
        
        _bodyBold('VERIFICATION DE LA CONTINUITE ET RESISTANCE DES CONDUCTEURS DE PROTECTION'),
        _bodyText('Correcte si la valeur mesuree satisfait aux prescriptions du guide UTE C 15-105 \u00A7 D6.'),
        pw.SizedBox(height: 5),
        
        _bodyBold('ESSAIS DE DECLENCHEMENT DES DISPOSITIFS DIFFERENTIELS RESIDUELS'),
        _bodyText('La valeur du seuil de declenchement est correcte si elle est comprise entre 0,5 IAn et IAn.'),
        pw.SizedBox(height: 5),
        
        _bodyBold('MESURE DES IMPEDANCES DE BOUCLE (PROTECTION \u00AB CONTACTS INDIRECTS \u00BB)'),
        _bodyText('Correcte si le temps de coupure, pour le courant de defaut determine, satisfait aux prescriptions du guide UTE C 15-105.'),
        
        pw.SizedBox(height: 16),
        
        // Essais de demarrage automatique (sur la même page)
        _subSectionBar('Essais de demarrage automatique du groupe electrogene'),
        pw.SizedBox(height: 5),
        _resultBox(mesures.essaiDemarrageAuto.observation ?? 'Non satisfaisant'),
        
        pw.SizedBox(height: 16),
        
        // Test de l'arret d'urgence (sur la même page)
        _subSectionBar("Test de fonctionnement de l'arret d'urgence"),
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
        columnWidths: {0: const pw.FlexColumnWidth(1.5), 1: const pw.FlexColumnWidth(1.5), 2: const pw.FlexColumnWidth(1.2), 3: const pw.FlexColumnWidth(1), 4: const pw.FlexColumnWidth(1), 5: const pw.FlexColumnWidth(1), 6: const pw.FlexColumnWidth(1.5)},
        children: [
          _tableHeaderRow(['Localisation', 'Identification', 'Condition mesure', 'Nature', 'Methode', 'Valeur', 'Observation']),
          if (mesures.prisesTerre.isEmpty)
            pw.TableRow(children: List.generate(7, (_) => _cell('', isHeader: false)))
          else
            ...mesures.prisesTerre.asMap().entries.map((e) {
              final pt = e.value;
              return _tableDataRow([pt.localisation, pt.identification, pt.conditionPriseTerre, pt.naturePriseTerre, pt.methodeMesure, pt.valeurMesure?.toStringAsFixed(2) ?? '-', pt.observation ?? ''], alt: e.key.isOdd);
            }),
        ],
      ),
      if (mesures.avisMesuresTerre.observation != null && mesures.avisMesuresTerre.observation!.isNotEmpty) ...[
        pw.SizedBox(height: 5),
        _bodyText(mesures.avisMesuresTerre.observation!),
      ],
    ]),
  ));
  
  // Mesures d'isolement des circuits BT (nouvelle page)
  pdf.addPage(pw.Page(
    pageTheme: _buildInnerPageTheme(),
    build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _buildPageHeaderWidget(), pw.SizedBox(height: 10),
      _subSectionBar("Mesures d'isolement des circuits BT"),
      pw.SizedBox(height: 8),
      _bodyText('Sans observation'),
    ]),
  ));
  
  // Essais de declenchement des DDR (nouvelle page)
  pdf.addPage(pw.Page(
    pageTheme: _buildInnerPageTheme(),
    build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _buildPageHeaderWidget(), pw.SizedBox(height: 10),
      _subSectionBar('Essais de declenchement des dispositifs differentiels'),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: 0.4),
        columnWidths: {0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(1.5), 2: const pw.FlexColumnWidth(1.2), 3: const pw.FlexColumnWidth(0.8), 4: const pw.FlexColumnWidth(0.8), 5: const pw.FlexColumnWidth(0.8), 6: const pw.FlexColumnWidth(1)},
        children: [
          _tableHeaderRow(['Quantite', 'Designation circuit', 'Type dispositif', 'Reglage In (mA)', 'Tempo (s)', 'Essai', 'Isolement (M ohms)']),
          if (mesures.essaisDeclenchement.isEmpty)
            pw.TableRow(children: List.generate(7, (_) => _cell('', isHeader: false)))
          else
            ...mesures.essaisDeclenchement.asMap().entries.map((e) {
              final es = e.value;
              final essaiColor = es.essai == 'B' || es.essai == 'OK' ? conformeColor : (es.essai == 'M' || es.essai == 'NON OK' ? nonConformeColor : null);
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: e.key.isOdd ? tableRowAlt : PdfColors.white),
                children: [
                  _cell(es.localisation, isHeader: false),
                  _cell('${es.coffret ?? ''} / ${es.designationCircuit ?? ''}', isHeader: false),
                  _cell(es.typeDispositif, isHeader: false),
                  _cell(es.reglageIAn?.toString() ?? '-', isHeader: false),
                  _cell(es.tempo?.toString() ?? '-', isHeader: false),
                  pw.Container(color: essaiColor, padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3), alignment: pw.Alignment.center, child: pw.Text(es.essai, style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall))),
                  _cell(es.isolement?.toString() ?? '-', isHeader: false),
                ],
              );
            }),
        ],
      ),
      pw.SizedBox(height: 12),
      _buildAbreviationsTable(),
    ]),
  ));
  
  // Continuite (nouvelle page)
  pdf.addPage(pw.Page(
    pageTheme: _buildInnerPageTheme(),
    build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _buildPageHeaderWidget(), pw.SizedBox(height: 10),
      _subSectionBar('Continuite et resistance des conducteurs de protection et liaisons equipotentielles'),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: 0.4),
        columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(2.5), 2: const pw.FlexColumnWidth(1.5), 3: const pw.FlexColumnWidth(2)},
        children: [
          _tableHeaderRow(['Localisation', 'Designation Tableau / Equipement', 'Origine Mesure', 'Observation']),
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
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            _cell('Signification des abreviations utilisees', isHeader: true, colspan: 2),
          ],
        ),
        _tableHeaderRow(['Abreviation', 'Signification']),
        _tableDataRow(['DDR', 'Disjoncteur Differentiel'], alt: false),
        _tableDataRow(['RD', 'Relais Differentiel'], alt: true),
        _tableDataRow(['B', 'Bon fonctionnement'], alt: false),
        _tableDataRow(['NE', 'Non essaye'], alt: true),
        _tableDataRow(['IDR', 'Interrupteur Differentiel'], alt: false),
        _tableDataRow(['In', 'Intensite differentielle'], alt: true),
        _tableDataRow(['M', 'Fonctionnement incorrect'], alt: false),
        _tableDataRow(['Tempo', 'Temporisation'], alt: true),
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
      for (var local in audit.moyenneTensionLocaux) {
        _addPhotosFromList(allPhotos, local.photos, local.nom);
        if (local.cellule != null) {
          _addPhotosFromList(allPhotos, local.cellule!.photos, '${local.nom} - Cellule');
        }
        if (local.transformateur != null) {
          _addPhotosFromList(allPhotos, local.transformateur!.photos, '${local.nom} - Transformateur');
        }
        for (var c in local.coffrets) {
          _addPhotosFromList(allPhotos, c.photos, '${local.nom} - ${c.nom}', repere: c.repere);
        }
      }
      for (var zone in audit.moyenneTensionZones) {
        _addPhotosFromList(allPhotos, zone.photos, zone.nom);
        for (var c in zone.coffrets) {
          _addPhotosFromList(allPhotos, c.photos, '${zone.nom} - ${c.nom}', repere: c.repere);
        }
        for (var local in zone.locaux) {
          _addPhotosFromList(allPhotos, local.photos, '${zone.nom} - ${local.nom}');
          for (var c in local.coffrets) {
            _addPhotosFromList(allPhotos, c.photos, '${zone.nom} - ${local.nom} - ${c.nom}', repere: c.repere);
          }
        }
      }
      for (var zone in audit.basseTensionZones) {
        _addPhotosFromList(allPhotos, zone.photos, zone.nom);
        for (var c in zone.coffretsDirects) {
          _addPhotosFromList(allPhotos, c.photos, '${zone.nom} - ${c.nom}', repere: c.repere);
        }
        for (var local in zone.locaux) {
          _addPhotosFromList(allPhotos, local.photos, '${zone.nom} - ${local.nom}');
          for (var c in local.coffrets) {
            _addPhotosFromList(allPhotos, c.photos, '${zone.nom} - ${local.nom} - ${c.nom}', repere: c.repere);
          }
        }
      }
    }

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
          _sectionBox('PHOTOS'),
          pw.SizedBox(height: 8),
          if (allPhotos.isEmpty)
            _bodyText('Aucune photo disponible.')
          else ...[
            _bodyText('Inventaire des photos prises lors de l\'audit :'),
            pw.SizedBox(height: 5),
            pw.Table(
              border: pw.TableBorder.all(color: borderColor, width: 0.4),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.4),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(1.5),
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
        ],
      ),
    ));

    if (allPhotos.isEmpty) return;

    final loadedImages = <pw.MemoryImage?>[];
    for (final entry in allPhotos) {
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
      margin: const pw.EdgeInsets.all(3),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: lightBlue,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Photo $index / $total',
                      style: pw.TextStyle(font: _fontBold, fontSize: 6, color: headerColor),
                    ),
                    if (entry.repere != null && entry.repere!.isNotEmpty)
                      pw.Text(
                        'Ref: ${entry.repere}',
                        style: pw.TextStyle(font: _fontBold, fontSize: 6, color: accentColor),
                      ),
                  ],
                ),
                pw.Text(
                  entry.description,
                  style: pw.TextStyle(font: _fontRegular, fontSize: 5.5, color: darkGrey),
                  maxLines: 2,
                  overflow: pw.TextOverflow.clip,
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: img != null
                ? pw.Padding(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Image(img, fit: pw.BoxFit.contain),
                  )
                : pw.Container(
                    color: PdfColors.grey200,
                    child: pw.Center(
                      child: pw.Text('Image non disponible',
                          style: pw.TextStyle(font: _fontRegular, fontSize: 7, color: PdfColors.grey600)),
                    ),
                  ),
          ),
        ],
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
  static String _normalizeText(String text) {
    if (text.isEmpty) return text;
    
    // Mappings des caractères problématiques
    final replacements = {
      // Indices et exposants
      '₂': '2',      // indice 2
      '₃': '3',      // indice 3
      '₄': '4',      // indice 4
      '²': '2',      // exposant 2 (CO2 → CO2)
      '³': '3',      // exposant 3
      '¹': '1',      // exposant 1
      
      // Signes mathématiques
      '≥': '>=',
      '≤': '<=',
      '≠': '!=',
      '±': '+/-',
      '∞': 'infini',
      '∑': 'Somme',
      '√': 'racine',
      '∝': '~',
      '°': '°',      // degré - garder (ASCII compatible)
      '→': '->',
      '←': '<-',
      '↔': '<->',
      
      // Symboles monétaires
      '€': 'EUR',
      '£': 'GBP',
      '¥': 'JPY',
      
      // Guillemets et ponctuation spéciale
      '«': '"',
      '»': '"',
      '“': '"',
      '”': '"',
      '‘': "'",
      '’': "'",
      '…': '...',
      '—': '-',
      '–': '-',
      
      // Lettres accentuées (déjà supportées normalement)
      // Mais au cas où...
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'î': 'i',
      'ï': 'i',
      'ô': 'o',
      'ö': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'œ': 'oe',
      'æ': 'ae',
      
      // Symboles électriques
      'Ω': 'Ohm',
      'μ': 'u',      // micro → u
      '∆': 'Delta',
      'Φ': 'Phi',
      'θ': 'theta',
    };
    
    var result = text;
    replacements.forEach((original, replacement) {
      result = result.replaceAll(original, replacement);
    });
    
    return result;
  }
  
  static pw.Widget _sectionBox(String title) {
    return pw.Container(
      width: double.infinity,
      color: accentColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        _normalizeText(title),
        style: pw.TextStyle(fontSize: fsH1, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _subTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 5, bottom: 3),
      child: pw.Text(
        _normalizeText(title),
        style: pw.TextStyle(
          fontSize: fsH3,
          fontWeight: pw.FontWeight.bold,
          color: accentColor,
          decoration: pw.TextDecoration.underline,
        ),
      ),
    );
  }

  static pw.Widget _bodyText(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(
        _normalizeText(text),
        style: pw.TextStyle(fontSize: fsBody, color: darkGrey, lineSpacing: 1.4)),
    );
  }

  static pw.Widget _bodyBold(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(_normalizeText(text),
          style: pw.TextStyle(fontSize: fsBody, fontWeight: pw.FontWeight.bold, color: darkGrey)),
    );
  }

  static pw.Widget _bulletItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(_normalizeText('-  '), style: pw.TextStyle(fontSize: fsBody, color: accentColor)),
          pw.Expanded(
            child: pw.Text(text,
                style: pw.TextStyle(fontSize: fsBody, color: darkGrey, lineSpacing: 1.3)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cell(String text, {required bool isHeader, PdfColor? color, int colspan = 1}) {
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
      ),
    );
  }

  static pw.TableRow _tableHeaderRow(List<String> headers) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: lightBlue),
      children: headers.map((h) => _cell(h, isHeader: true)).toList(),
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

      // 3. Rappel des responsabilites
      pdf.addPage(
        pw.Page(
          pageTheme: _buildInnerPageTheme(),
          build: (ctx) => _buildRappelResponsabilites(),
        ),
      );

      pdf.addPage(
        pw.Page(
          pageTheme: _buildInnerPageTheme(),
          build: (ctx) => _buildMesureSecurite(),
        ),
      );

      pdf.addPage(
        pw.Page(
          pageTheme: _buildInnerPageTheme(),
          build: (ctx) => _buildObjetVerification(),
        ),
      );

      // 4. Renseignements generaux
      pdf.addPage(
        pw.Page(
          pageTheme: _buildInnerPageTheme(),
          build: (ctx) => _buildRenseignementsGeneraux(mission, renseignements),
        ),
      );

      // 5. Description des installations
      pdf.addPage(pw.MultiPage(
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
  _ObsRecap({
    required this.localisation,
    required this.coffret,
    required this.observation,
    required this.refNorm,
    required this.priorite,
  });
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