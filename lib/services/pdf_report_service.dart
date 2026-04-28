// ================================================================
//  pdf_report_service.dart — Version améliorée v2.0
//  Correspondance fidèle avec la trame KES INSPECTIONS AND PROJECTS
//  Auteur : Refonte complète basée sur l'analyse de la trame PDF
// ================================================================

import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
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

class PdfReportService {
  // ──────────────────────────────────────────────────────────────
  //  CONSTANTES DE MISE EN PAGE
  // ──────────────────────────────────────────────────────────────

  // Marges document (1 cm ≈ 28.35 pt)
  static const double kLeftMargin   = 2.5 * 28.35; // 2.5 cm
  static const double kTopMargin    = 1.5 * 28.35; // 1.5 cm
  static const double kRightMargin  = 1.8 * 28.35; // 1.8 cm
  static const double kBottomMargin = 1.5 * 28.35; // 1.5 cm — réduit vs version précédente

  // ──────────────────────────────────────────────────────────────
  //  COULEURS (palette fidèle à la trame)
  // ──────────────────────────────────────────────────────────────
  static final PdfColor headerColor      = PdfColor.fromInt(0xFF1F3864); // bleu marine KES
  static final PdfColor accentColor      = PdfColor.fromInt(0xFF2E74B5); // bleu accent
  static final PdfColor lightBlue        = PdfColor.fromInt(0xFFD6E4F0); // bleu clair entête
  static final PdfColor darkGrey         = PdfColor.fromInt(0xFF404040);
  static final PdfColor tableRowAlt      = PdfColor.fromInt(0xFFF5F8FC);
  static final PdfColor borderColor      = PdfColor.fromInt(0xFFAAAAAA);
  static final PdfColor priorite1Color   = PdfColor.fromInt(0xFFFFF2CC); // jaune
  static final PdfColor priorite2Color   = PdfColor.fromInt(0xFFFFE0B2); // orange
  static final PdfColor priorite3Color   = PdfColor.fromInt(0xFFFFCDD2); // rouge clair
  static final PdfColor conformeColor    = PdfColor.fromInt(0xFFE8F5E9); // vert clair
  static final PdfColor nonConformeColor = PdfColor.fromInt(0xFFFFEBEE); // rouge clair

  // ──────────────────────────────────────────────────────────────
  //  TAILLES DE POLICE
  // ──────────────────────────────────────────────────────────────
  static const double fsH1    = 11.0;
  static const double fsH2    = 9.5;
  static const double fsH3    = 9.0;
  static const double fsBody  = 8.0;
  static const double fsSmall = 7.0;

  // ──────────────────────────────────────────────────────────────
  //  IMAGES (chargées une seule fois)
  // ──────────────────────────────────────────────────────────────
  static pw.MemoryImage? _watermarkImage;
  static pw.MemoryImage? _firstPageFooterImage;
  static pw.MemoryImage? _otherPageFooterImage;
  static pw.MemoryImage? _logoKesImage;
  // Images habilitation électrique (mesures de sécurité)
  static pw.MemoryImage? _habImage1;
  static pw.MemoryImage? _habImage2;
  static pw.MemoryImage? _habImage3;
  static pw.MemoryImage? _habImage4;
  static bool _imagesLoaded = false;

  static late final pw.Font _fontRegular;
  static late final pw.Font _fontBold;
  static bool _fontsLoaded = false;

  // ──────────────────────────────────────────────────────────────
  //  CHARGEMENT DES RESSOURCES
  // ──────────────────────────────────────────────────────────────
  static Future<void> _loadImages() async {
    if (_imagesLoaded) return;

    Future<pw.MemoryImage?> _tryLoad(String assetPath) async {
      try {
        return pw.MemoryImage(
          (await rootBundle.load(assetPath)).buffer.asUint8List(),
        );
      } catch (e) {
        print('⚠️ Asset non trouvé: $assetPath — $e');
        return null;
      }
    }

    _watermarkImage        = await _tryLoad('assets/images/filigranne_image.png');
    _firstPageFooterImage  = await _tryLoad('assets/images/firstpage_footer.png');
    _otherPageFooterImage  = await _tryLoad('assets/images/otherpage_footer.png');
    _logoKesImage          = await _tryLoad('assets/images/logo.png');
    // Images habilitations (section mesures de sécurité)
    _habImage1             = await _tryLoad('assets/images/image.png');
    _habImage2             = await _tryLoad('assets/images/image copy.png');
    _habImage3             = await _tryLoad('assets/images/image copy 2.png');
    _habImage4             = await _tryLoad('assets/images/image copy 3.png');

    _imagesLoaded = true;
  }

  static Future<void> _loadFonts() async {
    if (_fontsLoaded) return;
    try {
      final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldData    = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      _fontRegular = pw.Font.ttf(regularData);
      _fontBold    = pw.Font.ttf(boldData);
    } catch (e) {
      print('⚠️ Polices Roboto non trouvées, utilisation Helvetica: $e');
      _fontRegular = pw.Font.helvetica();
      _fontBold    = pw.Font.helveticaBold();
    }
    _fontsLoaded = true;
  }

  // ──────────────────────────────────────────────────────────────
  //  THÈME DE PAGE
  // ──────────────────────────────────────────────────────────────

  /// Construit le PageTheme avec le bon background selon la page.
  /// [isFirstPage] : true = firstpage_footer, false = otherpage_footer
  /// [pageNumber]  : numéro de page physique (1-based)
  static pw.PageTheme _buildPageTheme({
    required bool isFirstPage,
    int pageNumber = 0,
    int totalPages = 0,
  }) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.only(
        left:   kLeftMargin,
        top:    kTopMargin,
        right:  kRightMargin,
        bottom: kBottomMargin,
      ),
      buildBackground: (ctx) => _buildPageBackground(
        ctx,
        isFirstPage: isFirstPage,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  ARRIÈRE-PLAN : filigrane + footer image
  //  Le numéro de page est injecté via pw.Context (dynamique)
  // ──────────────────────────────────────────────────────────────
  static pw.Widget _buildPageBackground(
    pw.Context context, {
    required bool isFirstPage,
  }) {
    return pw.Stack(
      children: [
        // ── Filigrane centré ──────────────────────────────────
        if (_watermarkImage != null)
          pw.Center(
            child: pw.Opacity(
              opacity: 0.07,
              child: pw.Image(_watermarkImage!, width: 380, height: 380),
            ),
          ),

        // ── Footer (dernier élément, collé en bas) ────────────
        pw.Positioned(
          bottom: 0,
          left:   0,
          right:  0,
          child: isFirstPage
              ? _buildFirstPageFooter()
              : _buildOtherPageFooter(context),
        ),
      ],
    );
  }

  /// Footer de la première page : image uniquement, pas de pagination
  static pw.Widget _buildFirstPageFooter() {
    if (_firstPageFooterImage != null) {
      return pw.Image(_firstPageFooterImage!, fit: pw.BoxFit.fitWidth);
    }
    return pw.Container(
      height: 50,
      color: headerColor,
      child: pw.Center(
        child: pw.Text('KES INSPECTIONS AND PROJECTS',
            style: pw.TextStyle(color: PdfColors.white, fontSize: 8,
                fontWeight: pw.FontWeight.bold)),
      ),
    );
  }

  /// Footer des pages intérieures : image + numéro de page superposé
  static pw.Widget _buildOtherPageFooter(pw.Context context) {
    return pw.Stack(
      children: [
        // Image du footer
        if (_otherPageFooterImage != null)
          pw.Image(_otherPageFooterImage!, fit: pw.BoxFit.fitWidth)
        else
          pw.Container(
            height: 40,
            color: headerColor,
          ),
        // Numéro de page à partir de la page 2 (pageNumber >= 2)
        // context.pageNumber = numéro de page physique dans le document
        pw.Positioned(
          bottom: 6,
          left:   20,
          child: pw.Text(
            'Page : ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 7.5,
              color:    PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  EN-TÊTE DES PAGES INTÉRIEURES (logo + titre + client)
  // ──────────────────────────────────────────────────────────────
  static pw.Widget _buildInnerPageHeader({String clientName = ''}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (_logoKesImage != null)
            pw.Image(_logoKesImage!, width: 48, height: 20, fit: pw.BoxFit.contain)
          else
            pw.Text('KES INSPECTIONS AND PROJECTS',
                style: pw.TextStyle(fontSize: 6, color: accentColor,
                    fontWeight: pw.FontWeight.bold)),
          pw.Text(
            'Rapport de vérification périodique réglementaire des installations électrique',
            style: pw.TextStyle(fontSize: 5.5, color: darkGrey),
          ),
          pw.Text(
            clientName,
            style: pw.TextStyle(fontSize: 5.5, color: darkGrey),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  POINT D'ENTRÉE PRINCIPAL
  // ──────────────────────────────────────────────────────────────
  static Future<File?> generateMissionReport(String missionId) async {
    try {
      await _loadImages();
      await _loadFonts();

      final mission        = HiveService.getMissionById(missionId);
      if (mission == null) return null;

      final description    = HiveService.getDescriptionInstallationsByMissionId(missionId);
      final audit          = HiveService.getAuditInstallationsByMissionId(missionId);
      final classements    = HiveService.getEmplacementsByMissionId(missionId);
      final mesures        = HiveService.getMesuresEssaisByMissionId(missionId);
      final foudres        = HiveService.getFoudreObservationsByMissionId(missionId);
      final renseignements = HiveService.getRenseignementsGenerauxByMissionId(missionId);

      final pdf = pw.Document(
        title:    'Rapport d\'Audit Électrique — ${mission.nomClient}',
        author:   'KES INSPECTIONS AND PROJECTS',
        compress: true,
      );

      final clientName = mission.nomSite ?? mission.nomClient;

      // ── 1. PAGE DE COUVERTURE ──────────────────────────────
      pdf.addPage(
        pw.Page(
          pageTheme: _buildPageTheme(isFirstPage: true),
          build: (ctx) => _buildCoverPage(mission, renseignements),
        ),
      );

      // ── 2. SOMMAIRE AUTOMATIQUE ────────────────────────────
      pdf.addPage(
        pw.MultiPage(
          pageTheme: _buildPageTheme(isFirstPage: false),
          build: (ctx) => [_buildSommaire(clientName)],
        ),
      );

      // ── 3. RAPPEL DES RESPONSABILITÉS ─────────────────────
      pdf.addPage(
        pw.MultiPage(
          pageTheme: _buildPageTheme(isFirstPage: false),
          build: (ctx) => _buildRappelResponsabilites(clientName),
        ),
      );

      // ── 4. OBJET DE LA VÉRIFICATION ───────────────────────
      pdf.addPage(
        pw.MultiPage(
          pageTheme: _buildPageTheme(isFirstPage: false),
          build: (ctx) => _buildObjetVerification(clientName),
        ),
      );

      // ── 5. RENSEIGNEMENTS GÉNÉRAUX ────────────────────────
      pdf.addPage(
        pw.MultiPage(
          pageTheme: _buildPageTheme(isFirstPage: false),
          build: (ctx) => _buildRenseignementsGeneraux(mission, renseignements, clientName),
        ),
      );

      // ── 6. DESCRIPTION DES INSTALLATIONS ─────────────────
      pdf.addPage(
        pw.MultiPage(
          pageTheme: _buildPageTheme(isFirstPage: false),
          build: (ctx) => _buildDescriptionInstallations(description, clientName),
        ),
      );

      // ── 7. LISTE RÉCAPITULATIVE DES OBSERVATIONS ──────────
      if (audit != null) {
        pdf.addPage(
          pw.MultiPage(
            pageTheme: _buildPageTheme(isFirstPage: false),
            build: (ctx) => _buildListeRecapitulative(audit, clientName),
          ),
        );
      }

      // ── 8. AUDIT DES INSTALLATIONS ÉLECTRIQUES ────────────
      if (audit != null) {
        pdf.addPage(
          pw.MultiPage(
            pageTheme: _buildPageTheme(isFirstPage: false),
            build: (ctx) => _buildAuditInstallations(audit, clientName),
          ),
        );
      }

      // ── 9. CLASSEMENT DES EMPLACEMENTS ───────────────────
      pdf.addPage(
        pw.MultiPage(
          pageTheme: _buildPageTheme(isFirstPage: false),
          build: (ctx) => _buildClassementEmplacements(classements, clientName),
        ),
      );

      // ── 10. FOUDRE ────────────────────────────────────────
      pdf.addPage(
        pw.MultiPage(
          pageTheme: _buildPageTheme(isFirstPage: false),
          build: (ctx) => _buildFoudre(foudres, clientName),
        ),
      );

      // ── 11. MESURES ET ESSAIS ─────────────────────────────
      if (mesures != null) {
        pdf.addPage(
          pw.MultiPage(
            pageTheme: _buildPageTheme(isFirstPage: false),
            build: (ctx) => _buildMesuresEssais(mesures, clientName),
          ),
        );
      }

      // ── 12. PHOTOS ────────────────────────────────────────
      await _addPhotosSection(pdf, mission, missionId, audit);

      // ── SAUVEGARDE ────────────────────────────────────────
      final bytes    = await pdf.save();
      final dir      = await getTemporaryDirectory();
      final fileName = 'Rapport_${mission.nomClient}_${_formatDate(DateTime.now())}.pdf'
          .replaceAll(RegExp(r'[<>:"/\\|?*\s]'), '_');
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      print('✅ Rapport PDF généré : ${file.path}');
      return file;
    } catch (e, stack) {
      print('❌ Erreur génération PDF: $e\n$stack');
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  PAGE DE COUVERTURE — fidèle à la trame
  // ──────────────────────────────────────────────────────────────
  static pw.Widget _buildCoverPage(Mission mission, RenseignementsGeneraux? rg) {
    // Calcul des dates d'intervention (début – fin)
    String dateIntervention = '';
    if (rg != null && rg.dateDebut != null && rg.dateFin != null) {
      final debut = rg.dateDebut!;
      final fin   = rg.dateFin!;
      if (debut.day == fin.day && debut.month == fin.month && debut.year == fin.year) {
        dateIntervention = _formatDateLong(debut);
      } else {
        dateIntervention = '${debut.day} et ${fin.day} ${_monthName(fin.month)} ${fin.year}';
      }
    } else if (mission.dateIntervention != null) {
      dateIntervention = _formatDateLong(mission.dateIntervention!);
    }

    // Rapport N° — on utilise un format standard si pas encore de champ dédié
    final String rapportNum = _buildRapportNumero(mission);

    // Date du rapport = date de génération
    final String dateRapport = _formatDateLong(DateTime.now());

    // Nombre total de pages : non dispo avant génération → on affiche une valeur estimée
    // En pratique, ce champ sera rempli manuellement ou via un champ Mission
    // Pour l'instant, on laisse le placeholder dynamique.

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [

        // ── Bande supérieure : logo KES + bande couleur ─────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo KES
            if (_logoKesImage != null)
              pw.Image(_logoKesImage!, width: 130, height: 65, fit: pw.BoxFit.contain)
            else
              pw.Container(
                width: 130, height: 65,
                child: pw.Text('KES INSPECTIONS AND PROJECTS',
                    style: pw.TextStyle(fontSize: 9, color: headerColor,
                        fontWeight: pw.FontWeight.bold)),
              ),
            pw.SizedBox(width: 16),
            // Bande couleur droite (dégradé simulé par superposition)
            pw.Expanded(
              child: pw.Container(
                height: 65,
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [accentColor, headerColor],
                    begin: pw.Alignment.centerLeft,
                    end:   pw.Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 30),

        // ── Bloc logo client + attention ─────────────────────
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Espace logo client (placeholder ou image réelle)
                if (mission.logoClient != null && mission.logoClient!.isNotEmpty)
                  _buildClientLogoFromPath(mission.logoClient!)
                else
                  pw.Container(
                    width: 110, height: 55,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                      color:  PdfColors.grey100,
                    ),
                    child: pw.Center(
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('LOGO CLIENT',
                              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text('(à coller ici)',
                              style: pw.TextStyle(fontSize: 6, color: PdfColors.grey400)),
                        ],
                      ),
                    ),
                  ),
                pw.SizedBox(height: 8),
                pw.Text('A l\'attention de Monsieur le',
                    style: pw.TextStyle(fontSize: 9, color: darkGrey)),
                pw.Text('Directeur General',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold,
                        color: darkGrey)),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 35),

        // ── Bandeau titre "RAPPORT" ───────────────────────────
        pw.Container(
          width:   double.infinity,
          color:   PdfColor.fromInt(0xFFEAEAEA),
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          child:   pw.Text(
            'RAPPORT',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold,
                color: headerColor),
            textAlign: pw.TextAlign.center,
          ),
        ),

        pw.SizedBox(height: 18),

        // ── Titre principal mission ───────────────────────────
        pw.Text(
          'AUDIT DES INSTALLATIONS ELECTRIQUES',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold,
              color: headerColor),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          (mission.nomSite ?? mission.nomClient).toUpperCase(),
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold,
              color: headerColor),
          textAlign: pw.TextAlign.center,
        ),

        pw.Spacer(),

        // ── Bloc infos bas de couverture ─────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Infos textuelles
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _coverInfoLine('Ce rapport contient', 'pages'),
                  _coverInfoLine('Date d\'intervention', dateIntervention),
                  _coverInfoLine('Date du rapport', dateRapport),
                  _coverInfoLine('Rapport N°', rapportNum),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            // QR Code placeholder
            pw.Container(
              width: 80, height: 80,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                color:  PdfColors.grey100,
              ),
              child: pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('QR CODE',
                        style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text('(à coller ici)',
                        style: pw.TextStyle(fontSize: 6, color: PdfColors.grey400)),
                  ],
                ),
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _coverInfoLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label : ',
              style: pw.TextStyle(fontSize: fsBody, color: darkGrey),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(fontSize: fsBody, fontWeight: pw.FontWeight.bold,
                  color: darkGrey),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildClientLogoFromPath(String logoPath) {
    try {
      final bytes = File(logoPath).readAsBytesSync();
      return pw.Image(pw.MemoryImage(bytes), width: 110, height: 55,
          fit: pw.BoxFit.contain);
    } catch (_) {
      return pw.Container(width: 110, height: 55);
    }
  }

  /// Construit un numéro de rapport standardisé KES
  static String _buildRapportNumero(Mission mission) {
    final now  = DateTime.now();
    final year = now.year.toString().substring(2);
    return 'KES/V$year/${now.month.toString().padLeft(2,'0')}/${mission.id.substring(0, 4).toUpperCase()}/SA001';
  }

  // ──────────────────────────────────────────────────────────────
  //  SOMMAIRE AUTOMATIQUE
  //  Structure fidèle à la trame (pages 2-4 du modèle)
  // ──────────────────────────────────────────────────────────────
  static pw.Widget _buildSommaire(String clientName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildInnerPageHeader(clientName: clientName),
        pw.SizedBox(height: 6),

        // Titre SOMMAIRE
        pw.Center(
          child: pw.Text(
            'SOMMAIRE',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color:      headerColor,
              fontStyle:  pw.FontStyle.italic,
            ),
          ),
        ),
        pw.SizedBox(height: 16),

        _sommaireSection('RAPPEL DES RESPONSABILITES DE L\'EMPLOYEUR', level: 1),
        _sommaireLine('Responsabilité et accompagnement',          level: 2),
        _sommaireLine('Conditions de réalisation',                 level: 2),
        _sommaireLine('Vérifications complémentaires',             level: 2),
        _sommaireLine('Surveillance & maintenance des installations électriques', level: 2),
        _sommaireLine('Formation du personnel intervenant sur les installations et a proximité', level: 2),
        _sommaireLine('MESURES DE SECURITE AUTOURS DES INSTALLATIONS', level: 3),
        _sommaireLine('TECHNICIEN EN MAINTENANCE DES INSTALLATIONS',    level: 3),
        _sommaireLine('Engagement de KES INSPECTIONS AND PROJECTS',     level: 2),

        _sommaireSection('OBJET DE LA VERIFICATION', level: 1),
        _sommaireLine('Références normatives et règlementaires', level: 2),
        _sommaireLine('Matériel utilisé',                        level: 2),

        _sommaireSection('RENSEIGNEMENTS GENERAUX DE L\'ETABLISSEMENT', level: 1),
        _sommaireLine('RENSEIGNEMENTS PRINCIPAUX',                  level: 2),
        _sommaireLine('DOCUMENTS NECESSAIRES A LA VERIFICATION',    level: 2),

        _sommaireSection('DESCRIPTION DES INSTALLATIONS', level: 1),
        _sommaireLine('Caractéristiques de l\'alimentation moyenne tension',              level: 2),
        _sommaireLine('Caractéristiques de l\'alimentation basse tension sortie transformateur', level: 2),
        _sommaireLine('Caractéristiques du groupe électrogène',   level: 2),
        _sommaireLine('Alimentation du groupe électrogène en carburant', level: 2),
        _sommaireLine('Caractéristiques de l\'inverseur',         level: 2),
        _sommaireLine('Caractéristiques du stabilisateur',        level: 2),
        _sommaireLine('Caractéristiques des onduleurs',           level: 2),
        _sommaireLine('Régime de neutre',                         level: 2),
        _sommaireLine('Eclairage de sécurité',                    level: 2),
        _sommaireLine('Modifications apportées aux installations',level: 2),
        _sommaireLine('Note de calcul des installations électriques', level: 2),
        _sommaireLine('Présence de paratonnerre',                 level: 2),
        _sommaireLine('Registre de sécurité',                     level: 2),

        _sommaireSection('LISTE RECAPITULATIVE DES OBSERVATIONS', level: 1),
        _sommaireLine('Niveau de priorité des observations constatées', level: 2),
        _sommaireLine('Moyenne tension',                               level: 2),
        _sommaireLine('Basse tension',                                 level: 2),

        _sommaireSection('AUDIT DES INSTALLATIONS ELECTRIQUES', level: 1),

        _sommaireSection('CLASSEMENT DES LOCAUX ET EMPLACEMENTS', level: 1),

        _sommaireSection('FOUDRE', level: 1),

        _sommaireSection('RESULTATS DES MESURES ET ESSAIS', level: 1),
        _sommaireLine('Conditions de mesure',                         level: 2),
        _sommaireLine('Essais de démarrage automatique du groupe électrogène', level: 2),
        _sommaireLine('Test de fonctionnement de l\'arrêt d\'urgence', level: 2),
        _sommaireLine('Prise de terre',                               level: 2),
        _sommaireLine('Mesures d\'isolement des circuits BT',         level: 2),
        _sommaireLine('Essais de déclenchement des dispositifs différentiels', level: 2),
        _sommaireLine('Continuité et résistance des conducteurs de protection', level: 2),

        _sommaireSection('PHOTOS', level: 1),
      ],
    );
  }

  static pw.Widget _sommaireSection(String title, {required int level}) {
    final bool isMajor = level == 1;
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: isMajor ? 6 : 2, bottom: 1),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize:   isMajor ? 9.5 : 8.0,
                fontWeight: isMajor ? pw.FontWeight.bold : pw.FontWeight.normal,
                color:      isMajor ? headerColor : darkGrey,
              ),
            ),
          ),
          // Pointillés
          pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.symmetric(horizontal: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5,
                      style: pw.BorderStyle.dashed),
                ),
              ),
              height: 6,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sommaireLine(String title, {required int level}) {
    double leftPad = level == 2 ? 12 : 24;
    return pw.Padding(
      padding: pw.EdgeInsets.only(left: leftPad, top: 1, bottom: 1),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: level == 3 ? 7.5 : 8.0,
                color:    darkGrey,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.symmetric(horizontal: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.4,
                      style: pw.BorderStyle.dashed),
                ),
              ),
              height: 5,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  RAPPEL DES RESPONSABILITÉS DE L'EMPLOYEUR
  // ──────────────────────────────────────────────────────────────
  static List<pw.Widget> _buildRappelResponsabilites(String clientName) {
    return [
      _buildInnerPageHeader(clientName: clientName),
      pw.SizedBox(height: 6),
      _sectionBox('RAPPEL DES RESPONSABILITES DE L\'EMPLOYEUR'),
      pw.SizedBox(height: 8),

      _bodyText(
        'KES INSPECTIONS AND PROJECTS a le plaisir de vous transmettre le présent rapport de vérification de vos '
        'installations électriques, établi à la suite des constats réalisés sur site.\n'
        'Ce document présente les observations effectuées par le vérificateur à partir des éléments et moyens mis à sa '
        'disposition. Il identifie les points de non-conformité constatés au regard des exigences réglementaires, et formule, '
        'le cas échéant, les recommandations techniques nécessaires à leur mise en conformité.',
      ),
      pw.SizedBox(height: 10),

      _subTitle('Responsabilité et accompagnement'),
      _bodyText(
        'Dans le cadre de la mission, il appartient à l\'employeur de désigner une personne qualifiée et informée des '
        'installations, chargée d\'accompagner le vérificateur durant l\'intervention. Cette personne doit pouvoir faciliter '
        'l\'accès à l\'ensemble des locaux, appareillages et équipements à contrôler.\n\n'
        'L\'employeur reste responsable du bon fonctionnement, de la sécurité et de la disponibilité des installations tout '
        'au long de la vérification. Les informations et documents techniques fournis sous sa responsabilité doivent permettre '
        'la réalisation des contrôles dans de bonnes conditions.',
      ),
      pw.SizedBox(height: 10),

      _subTitle('Conditions de réalisation'),
      _bodyText('Afin d\'assurer le bon déroulement des opérations, l\'employeur doit :'),
      _bulletItem('Veiller à ce que la vérification soit réalisée dans des conditions de sécurité optimales, en particulier lors des accès en zone électrique ;'),
      _bulletItem('Mettre en œuvre les procédures nécessaires aux mises hors tension permettant d\'effectuer les mesures et essais en toute sécurité ;'),
      _bulletItem('Garantir au vérificateur l\'accès à l\'ensemble des équipements à contrôler, sans risque de chute ou d\'incident.'),
      pw.SizedBox(height: 10),

      _bodyText(
        'Si certaines vérifications n\'ont pu être effectuées (impossibilité d\'accès, absence d\'agents habilités, '
        'contraintes d\'exploitation, documentation manquante, etc.), KES INSPECTIONS AND PROJECTS en mentionnera la cause '
        'dans le rapport.\n\n'
        'Dans le cas des installations de moyenne ou haute tension, la mise hors tension et les manœuvres associées relèvent '
        'exclusivement de la responsabilité de l\'employeur ou de son représentant habilité.',
      ),
      pw.SizedBox(height: 10),

      _subTitle('Vérifications complémentaires'),
      _bodyText(
        'Lorsque des éléments du poste ou de l\'installation n\'ont pu être contrôlés lors de la visite initiale, une '
        'intervention complémentaire pourra être programmée à la demande de l\'employeur. Cette mission additionnelle fera '
        'alors l\'objet d\'une planification et d\'un rapport spécifique.',
      ),
      pw.SizedBox(height: 10),

      _subTitle('Surveillance & maintenance des installations électriques'),
      _bodyText(
        'La vérification de conformité des installations électriques ne constitue qu\'un des éléments concourant à la '
        'sécurité des personnes et des biens. Conformément à la norme et aux textes réglementaires applicables, le chef '
        'd\'établissement doit mettre en place une organisation pour les opérations de surveillance et la maintenance des '
        'installations électriques. C\'est dans le cadre de ces opérations que les dispositions doivent être prises afin de '
        'remédier aux défectuosités constatées pendant la vérification ou celles qui peuvent se manifester après la vérification.',
      ),
      pw.SizedBox(height: 10),

      _subTitle('Formation du personnel intervenant sur les installations et à proximité'),
      pw.SizedBox(height: 6),

      // ── Section Mesures de sécurité ───────────────────────
      _sectionBox('MESURES DE SECURITE AUTOURS DES INSTALLATIONS'),
      pw.SizedBox(height: 6),

      _bodyText('Suivant la réglementation applicable,'),
      _bulletItem('Article 5 — Arrêté 039/MTPS/IMT du 26 Novembre 1984 fixant les mesures générales d\'hygiène et de sécurité sur les lieux de travail'),
      _bulletItem('NFC 18-510 : Opérations sur les ouvrages et installations électriques et dans un environnement électrique — Prévention du risque électrique'),
      pw.SizedBox(height: 6),

      _bodyText('Le personnel doit avoir subi avec succès une formation en habilitation électrique en fonction du domaine de tension.'),
      pw.SizedBox(height: 6),

      // Tableau habilitations + images
      _buildHabilitationsSection(),
      pw.SizedBox(height: 10),

      _bodyText(
        'Il est rappelé que des dispositions de sécurité particulières et parfaitement définies doivent être prises par le '
        'chef de l\'établissement pour toute intervention de maintenance, réglage, nettoyage sur ou à proximité des '
        'installations électriques.\n\n'
        'L\'accès aux locaux et armoires électriques doit être interdit par les personnes non autorisées.\n\n'
        'En effet, une installation, bien que déclarée conforme en phase d\'exploitation, peut lors d\'opérations, par '
        'exemple d\'entretien, nécessiter des précautions spéciales du fait de la présence à proximité de pièces nues sous '
        'tension (cas des locaux réservés aux électriciens et dans lesquels la réglementation n\'interdit pas la présence de '
        'pièces nues sous tension).',
      ),
      pw.SizedBox(height: 10),

      _sectionBox('TECHNICIEN EN MAINTENANCE DES INSTALLATIONS'),
      pw.SizedBox(height: 6),
      _bodyText('Il est fortement recommandé à l\'employeur de faire participer les employés à des séances de formations sur les modules suivants :'),
      _bulletItem('Connaissance des normes en électricité (NC 244 C15 00...)'),
      _bulletItem('Maintenance des installations électriques'),
      pw.SizedBox(height: 10),

      _subTitle('Engagement de KES INSPECTIONS AND PROJECTS'),
      _bodyText(
        'KES INSPECTIONS AND PROJECTS s\'engage à réaliser ses vérifications dans le strict respect des normes et règlements '
        'applicables, avec le souci constant de la sécurité, de la fiabilité technique et de l\'impartialité des constats.',
      ),
    ];
  }

  /// Section habilitations avec tableau + images (image.png, image copy.png, etc.)
  static pw.Widget _buildHabilitationsSection() {
    final images = [_habImage1, _habImage2, _habImage3, _habImage4]
        .where((img) => img != null)
        .cast<pw.MemoryImage>()
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Tableau symboles d'habilitation
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderColor, width: 0.4),
          ),
          child: pw.Column(
            children: [
              pw.Container(
                width: double.infinity,
                color: lightBlue,
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: pw.Text(
                  'SYMBOLES D\'HABILITATION ÉLECTRIQUE (NFC 18-510)',
                  style: pw.TextStyle(fontSize: fsH3, fontWeight: pw.FontWeight.bold,
                      color: headerColor),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Table(
                  border: pw.TableBorder.all(color: borderColor, width: 0.3),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(3),
                  },
                  children: [
                    _tableHeaderRow(['Symbole', 'Désignation', 'Symbole', 'Désignation']),
                    _tableDataRow(['B0', 'Habilitation de base — Travaux hors tension',    'H0', 'Habilitation hors tension pour non-électriciens'], alt: false),
                    _tableDataRow(['BR', 'Habilitation de remplacement — Consignation',    'H1', 'Habilitation de 1ère catégorie — Travaux HT'], alt: true),
                    _tableDataRow(['BC', 'Habilitation de consignation',                   'H2', 'Habilitation de 2ème catégorie — Travaux HT'], alt: false),
                    _tableDataRow(['BE', 'Habilitation d\'essai — Mesures',                'HC', 'Habilitation de consignation HT'], alt: true),
                    _tableDataRow(['BS', 'Habilitation de surveillance (travaux BT)',      'HE', 'Habilitation d\'essai — Mesures HT'], alt: false),
                    _tableDataRow(['B1', 'Habilitation de 1ère catégorie — Travaux BT',   'HR', 'Habilitation de remplacement HT'], alt: true),
                    _tableDataRow(['B2', 'Habilitation de 2ème catégorie — Travaux BT',   '',   ''], alt: false),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Images habilitation (si disponibles)
        if (images.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing:       8,
            runSpacing:    8,
            children: images.map((img) =>
              pw.Container(
                width:  120,
                height: 80,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.4),
                ),
                child: pw.Image(img, fit: pw.BoxFit.contain),
              ),
            ).toList(),
          ),
        ],
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  OBJET DE LA VÉRIFICATION
  // ──────────────────────────────────────────────────────────────
  static List<pw.Widget> _buildObjetVerification(String clientName) {
    return [
      _buildInnerPageHeader(clientName: clientName),
      pw.SizedBox(height: 6),
      _sectionBox('OBJET DE LA VERIFICATION'),
      pw.SizedBox(height: 8),

      _bodyText(
        'La mission a pour objet de déceler les non-conformités, pouvant affecter la sécurité des personnes et des biens, '
        'et de s\'assurer du bon état de conservation des installations. Afin de présenter l\'état des lieux de l\'existant, '
        'les points sur lesquels les installations s\'écartent des normes, textes applicables et de proposer des actions '
        'correctives.\n\n'
        'D\'une manière générale, la vérification a été étendue à l\'ensemble des installations électriques présentées et '
        'accessibles dans l\'établissement depuis les sources, jusqu\'aux points d\'utilisations.',
      ),
      pw.SizedBox(height: 10),

      _bodyText('Ainsi sont exclus du champ de la vérification :'),
      _bulletItem('Les dispositions administratives, organisationnelles et techniques relatives à l\'information et à la '
          'formation du personnel (prescriptions au personnel) lors de l\'exploitation courante, de travaux ou d\'interventions '
          'sur les installations ainsi que les mesures de sécurité qui en découlent ;'),
      _bulletItem('Les dispositions administratives relatives aux documents à tenir à la disposition des autorités publiques ;'),
      _bulletItem('L\'examen des matériels électriques en présentation ou en démonstration et destinés à la vente ;'),
      _bulletItem('Les matériels stockés ou en réserve ou signalés comme n\'étant plus mis en œuvre. Du fait que les '
          'installations sont examinées en tenant compte des contraintes d\'exploitation et de sécurité propres à chaque '
          'établissement et indiquées en début de vérification au personnel chargé de la vérification, celle-ci est limitée '
          'dans certains cas à l\'état apparent des installations.'),

      pw.SizedBox(height: 12),
      _subTitle('Références normatives et réglementaires'),
      pw.SizedBox(height: 4),
      _buildNormesTable(),

      pw.SizedBox(height: 12),
      _subTitle('Matériel utilisé'),
      pw.SizedBox(height: 4),
      _buildMaterielTable(),
    ];
  }

  static pw.Widget _buildNormesTable() {
    final normes = [
      'Articles 6, 112, 113 — Arrêté 039/MTPS/IMT du 26 Novembre 1984 fixant les mesures générales d\'hygiène et de sécurité sur les lieux de travail',
      'Cahier de prescription technique applicable au Décret N° 2018/1969/PM du 15 Mars 2018, fixant les règles de base de sécurité incendie dans les bâtiments',
      'Arrêté conjoint N° 002164 du 21 Juin 2012 — MINMIDT/MINEE',
      'Loi N° 896/PJL/AN du 15/11/2011',
      'NC 244 C 15 100 — Installation électrique à basse tension',
      'NF C 15 100 — Installation électrique à basse tension',
      'Norme NF C 13 100 — Poste de livraison établi à l\'intérieur d\'un bâtiment et alimenté par un réseau de distribution publique de deuxième catégorie',
      'NFC 18-510 — Opérations sur les ouvrages et installations électriques — Prévention du risque électrique',
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      children: normes.asMap().entries.map((e) =>
        pw.TableRow(
          decoration: pw.BoxDecoration(color: e.key.isEven ? PdfColors.white : tableRowAlt),
          children: [_cell(e.value, isHeader: false)],
        ),
      ).toList(),
    );
  }

  static pw.Widget _buildMaterielTable() {
    final materiel = [
      ['Mesure de la résistance de prises de terre', 'FLUKE 1630-2 FC'],
      ['Mesure de l\'isolement', 'CHAUVIN ARNOUX CA 6462'],
      ['Vérification de la continuité et de la résistance des conducteurs de protection et des liaisons équipotentielles', 'CHAUVIN ARNOUX CA 6462'],
      ['Test de déclenchement des dispositifs différentiels et mesure des impédances de boucle', 'CHAUVIN ARNOUX CA 6462'],
      ['Contrôleur d\'installation électrique', 'CHAUVIN ARNOUX CA 6116N'],
      ['Analyseur de réseaux', 'CHAUVIN ARNOUX PEL 103'],
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(3.5),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        _tableHeaderRow(['Description de l\'appareil / Usage', 'Référence appareil']),
        ...materiel.asMap().entries.map((e) =>
          _tableDataRow(e.value, alt: e.key.isOdd)),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  RENSEIGNEMENTS GÉNÉRAUX DE L'ÉTABLISSEMENT
  // ──────────────────────────────────────────────────────────────
  static List<pw.Widget> _buildRenseignementsGeneraux(
      Mission mission, RenseignementsGeneraux? rg, String clientName) {

    // Dates
    String datesIntervention = '';
    if (rg != null && rg.dateDebut != null && rg.dateFin != null) {
      datesIntervention = '${_formatDate(rg.dateDebut!)} — ${_formatDate(rg.dateFin!)}';
    } else if (mission.dateIntervention != null) {
      datesIntervention = _formatDate(mission.dateIntervention!);
    }

    String duree = '';
    if (rg != null && rg.dureeJours > 0) {
      duree = '${rg.dureeJours} jour(s)';
    } else if (mission.dureeMissionJours != null) {
      duree = '${mission.dureeMissionJours} jour(s)';
    }

    // Verificateurs
    String verificateursStr = '';
    if (rg != null && rg.verificateurs.isNotEmpty) {
      verificateursStr = rg.verificateurs.map((v) => v['nom'] ?? '').join(', ');
    } else if (mission.verificateurs != null && mission.verificateurs!.isNotEmpty) {
      verificateursStr = mission.verificateurs!.map((v) => v['nom']?.toString() ?? '').join(', ');
    }

    return [
      _buildInnerPageHeader(clientName: clientName),
      pw.SizedBox(height: 6),
      _sectionBox('RENSEIGNEMENTS GENERAUX DE L\'ETABLISSEMENT'),
      pw.SizedBox(height: 10),

      // ── Renseignements principaux ─────────────────────────
      _subTitle('RENSEIGNEMENTS PRINCIPAUX'),
      pw.SizedBox(height: 4),

      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: 0.4),
        columnWidths: {
          0: const pw.FlexColumnWidth(2.2),
          1: const pw.FlexColumnWidth(3.8),
        },
        children: [
          _tableDataRow(['Etablissement vérifié',        mission.nomClient],                                alt: false),
          if (rg != null)
            _tableDataRow(['Installation vérifiée',      rg.installation],                                 alt: true)
          else
            _tableDataRow(['Installation vérifiée',      ''],                                              alt: true),
          if (rg != null)
            _tableDataRow(['Activité principale',         rg.activite],                                    alt: false)
          else
            _tableDataRow(['Activité principale',         mission.activiteClient ?? ''],                   alt: false),
          _tableDataRow(['Adresse',                      mission.adresseClient ?? ''],                     alt: true),
          _tableDataRow(['Nom du site',                  mission.nomSite ?? rg?.nomSite ?? ''],            alt: false),
          _tableDataRow(['Vérification — Nature',        mission.natureMission ?? ''],                     alt: true),
          _tableDataRow(['Périodicité réglementaire',    mission.periodicite ?? ''],                       alt: false),
          _tableDataRow(['Dates d\'intervention',        datesIntervention],                               alt: true),
          _tableDataRow(['Durée',                        duree],                                           alt: false),
          _tableDataRow(['Accompagnateur / Responsable', mission.dgResponsable ?? ''],                     alt: true),
          if (rg != null)
            _tableDataRow(['Registre de contrôle',       rg.registreControle],                            alt: false),
          if (rg != null && rg.compteRendu.isNotEmpty)
            _tableDataRow(['Compte rendu de fin de visite fait à', rg.compteRendu.join(', ')],            alt: true),
          if (verificateursStr.isNotEmpty)
            _tableDataRow(['Vérificateur(s)',             verificateursStr],                               alt: rg != null ? false : true),
        ],
      ),

      pw.SizedBox(height: 16),

      // ── Documents nécessaires ─────────────────────────────
      _subTitle('DOCUMENTS NECESSAIRES A LA VERIFICATION'),
      pw.SizedBox(height: 4),

      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: 0.4),
        columnWidths: {
          0: const pw.FlexColumnWidth(5),
          1: const pw.FlexColumnWidth(2),
        },
        children: [
          _tableHeaderRow(['LISTE DES DOCUMENTS', 'OBSERVATIONS']),
          _tableDataRow(['Cahier des prescriptions techniques ayant permis la réalisation des installations',
              _docStatus(mission.docCahierPrescriptions)], alt: false),
          _tableDataRow(['Notes de calculs justifiant le dimensionnement des canalisations électriques et des dispositifs de protection',
              _docStatus(mission.docNotesCalculs)], alt: true),
          _tableDataRow(['Schémas unifilaires des installations électriques',
              _docStatus(mission.docSchemasUnifilaires)], alt: false),
          _tableDataRow(['Plan de masse à l\'échelle des installations avec implantations des prises de terre et électriques enterrés',
              _docStatus(mission.docPlanMasse)], alt: true),
          _tableDataRow(['Plans architecturaux d\'implantation des différents circuits',
              _docStatus(mission.docPlansArchitecturaux)], alt: false),
          _tableDataRow(['Déclaration CE de conformité et notices des appareillages et câbles installés',
              _docStatus(mission.docDeclarationsCe)], alt: true),
          _tableDataRow(['Liste des installations de sécurité et effectif maximal des différents locaux ou bâtiments',
              _docStatus(mission.docListeInstallations)], alt: false),
          _tableDataRow(['Rapport de dernière vérification',
              _docStatus(mission.docRapportDerniereVerif)], alt: true),
          _tableDataRow(['Plan des locaux, avec indications des locaux à risques particuliers d\'influences externes',
              _docStatus(mission.docPlanLocauxRisques)], alt: false),
          _tableDataRow(['Rapport d\'analyse risque foudre',
              _docStatus(mission.docRapportAnalyseFoudre)], alt: true),
          _tableDataRow(['Rapport d\'étude technique foudre',
              _docStatus(mission.docRapportEtudeFoudre)], alt: false),
          _tableDataRow(['Registre de sécurité',
              _docStatus(mission.docRegistreSecurite)], alt: true),
        ],
      ),
    ];
  }

  static String _docStatus(bool? val) => val == true ? 'Présenté' : 'Non présenté';

  // ──────────────────────────────────────────────────────────────
  //  DESCRIPTION DES INSTALLATIONS
  // ──────────────────────────────────────────────────────────────
  static List<pw.Widget> _buildDescriptionInstallations(
      DescriptionInstallations? desc, String clientName) {
    final widgets = <pw.Widget>[
      _buildInnerPageHeader(clientName: clientName),
      pw.SizedBox(height: 6),
      _sectionBox('DESCRIPTION DES INSTALLATIONS'),
      pw.SizedBox(height: 8),
    ];

    if (desc == null) {
      widgets.add(_bodyText('Aucune donnée disponible.'));
      return widgets;
    }

    void addSection(String title, List<InstallationItem> items, {String? fallbackText}) {
      widgets.add(_subTitle(title));
      widgets.add(pw.SizedBox(height: 3));
      if (items.isNotEmpty) {
        widgets.add(_buildInstallationTable(items));
      } else {
        widgets.add(_bodyText('— ${fallbackText ?? 'Sans objet'}'));
      }
      widgets.add(pw.SizedBox(height: 8));
    }

    addSection('Caractéristiques de l\'alimentation moyenne tension',    desc.alimentationMoyenneTension);
    addSection('Caractéristiques de l\'alimentation basse tension sortie transformateur', desc.alimentationBasseTension);
    addSection('Caractéristiques du groupe électrogène',                 desc.groupeElectrogene);
    addSection('Alimentation du groupe électrogène en carburant',        desc.alimentationCarburant);
    addSection('Caractéristiques de l\'inverseur',                       desc.inverseur);
    addSection('Caractéristiques du stabilisateur',                      desc.stabilisateur,
               fallbackText: 'Pas de stabilisateur');
    addSection('Caractéristiques des onduleurs',                         desc.onduleurs);

    widgets.add(_subTitle('Régime de neutre'));
    widgets.add(_bodyText('— ${desc.regimeNeutre ?? 'TT'}'));
    widgets.add(pw.SizedBox(height: 6));

    widgets.add(_subTitle('Eclairage de sécurité'));
    widgets.add(_bodyText('— ${desc.eclairageSecurite ?? 'Présent'}'));
    widgets.add(pw.SizedBox(height: 6));

    widgets.add(_subTitle('Modifications apportées aux installations'));
    widgets.add(_bodyText('${desc.modificationsInstallations ?? 'Sans Objet'}'));
    widgets.add(pw.SizedBox(height: 6));

    widgets.add(_subTitle('Note de calcul des installations électriques'));
    widgets.add(_bodyText('— ${desc.noteCalcul ?? 'Non transmis'}'));
    widgets.add(pw.SizedBox(height: 6));

    widgets.add(_subTitle('Présence de paratonnerre'));
    widgets.add(_bodyText('Présence de paratonnerre : ${desc.presenceParatonnerre ?? 'NON'}'));
    widgets.add(_bodyText('Analyse risque foudre : ${desc.analyseRisqueFoudre ?? 'Non réalisée'}'));
    widgets.add(_bodyText('Etude technique foudre : ${desc.etudeTechniqueFoudre ?? 'Non réalisée'}'));
    widgets.add(pw.SizedBox(height: 6));

    widgets.add(_subTitle('Registre de sécurité'));
    widgets.add(_bodyText('— ${desc.registreSecurite ?? 'Non transmis'}'));

    return widgets;
  }

  static pw.Widget _buildInstallationTable(List<InstallationItem> items) {
    if (items.isEmpty) return pw.Container();
    final fields = <String>{};
    for (var it in items) fields.addAll(it.data.keys);
    final cols = fields.toList()..sort();
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      children: [
        _tableHeaderRow(cols),
        ...items.asMap().entries.map((e) =>
          _tableDataRow(cols.map((c) => e.value.data[c]?.toString() ?? '-').toList(),
              alt: e.key.isOdd)),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  LISTE RÉCAPITULATIVE DES OBSERVATIONS
  // ──────────────────────────────────────────────────────────────
  static List<pw.Widget> _buildListeRecapitulative(
      AuditInstallationsElectriques audit, String clientName) {
    return [
      _buildInnerPageHeader(clientName: clientName),
      pw.SizedBox(height: 6),
      _sectionBox('LISTE RECAPITULATIVE DES OBSERVATIONS'),
      pw.SizedBox(height: 8),

      _subTitle('Niveau de priorité des observations constatées'),
      pw.SizedBox(height: 4),

      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: 0.4),
        columnWidths: {
          0: const pw.FlexColumnWidth(0.3),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(0.3),
          3: const pw.FlexColumnWidth(2),
          4: const pw.FlexColumnWidth(0.3),
          5: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            children: [
              _prioriteBadgeCell('1', priorite1Color),
              _cell('Niveau 1 : À surveiller', isHeader: false),
              _prioriteBadgeCell('2', priorite2Color),
              _cell('Niveau 2 : Mise en conformité à planifier', isHeader: false),
              _prioriteBadgeCell('3', priorite3Color),
              _cell('Niveau 3 : Critique, Action immédiate', isHeader: false),
            ],
          ),
        ],
      ),

      pw.SizedBox(height: 14),
      _subTitle('Moyenne tension'),
      pw.SizedBox(height: 4),
      _buildObsRecapTable(_collectObservationsMT(audit)),

      pw.SizedBox(height: 14),
      _subTitle('Basse tension'),
      pw.SizedBox(height: 4),
      _buildObsRecapTable(_collectObservationsBT(audit)),
    ];
  }

  static pw.Widget _prioriteBadgeCell(String p, PdfColor color) {
    return pw.Container(
      color: color,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(p, style: pw.TextStyle(fontSize: fsBody, fontWeight: pw.FontWeight.bold)),
    );
  }

  static List<_ObsRecap> _collectObservationsMT(AuditInstallationsElectriques audit) {
    final list = <_ObsRecap>[];
    for (var local in audit.moyenneTensionLocaux) {
      for (var coffret in local.coffrets) {
        for (var pv in coffret.pointsVerification) {
          if (_isNonConforme(pv.conformite)) {
            list.add(_ObsRecap(
              localisation: local.nom, coffret: coffret.nom,
              observation:  pv.observation ?? pv.pointVerification,
              refNorm:      pv.referenceNormative ?? '',
              priorite:     pv.priorite?.toString() ?? '',
            ));
          }
        }
        for (var obs in coffret.observationsLibres) {
          list.add(_ObsRecap(localisation: local.nom, coffret: coffret.nom,
              observation: obs.texte, refNorm: '', priorite: ''));
        }
      }
      for (var obs in local.observationsLibres) {
        list.add(_ObsRecap(localisation: local.nom, coffret: '',
            observation: obs.texte, refNorm: '', priorite: ''));
      }
    }
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        for (var coffret in local.coffrets) {
          for (var obs in coffret.observationsLibres) {
            list.add(_ObsRecap(localisation: '${zone.nom} / ${local.nom}', coffret: coffret.nom,
                observation: obs.texte, refNorm: '', priorite: ''));
          }
        }
      }
      for (var obs in zone.observationsLibres) {
        list.add(_ObsRecap(localisation: zone.nom, coffret: '',
            observation: obs.texte, refNorm: '', priorite: ''));
      }
    }
    return list;
  }

  static List<_ObsRecap> _collectObservationsBT(AuditInstallationsElectriques audit) {
    final list = <_ObsRecap>[];
    for (var zone in audit.basseTensionZones) {
      for (var coffret in zone.coffretsDirects) {
        for (var pv in coffret.pointsVerification) {
          if (_isNonConforme(pv.conformite)) {
            list.add(_ObsRecap(
              localisation: zone.nom, coffret: coffret.nom,
              observation:  pv.observation ?? pv.pointVerification,
              refNorm:      pv.referenceNormative ?? '',
              priorite:     pv.priorite?.toString() ?? '',
            ));
          }
        }
        for (var obs in coffret.observationsLibres) {
          list.add(_ObsRecap(localisation: zone.nom, coffret: coffret.nom,
              observation: obs.texte, refNorm: '', priorite: ''));
        }
      }
      for (var local in zone.locaux) {
        for (var coffret in local.coffrets) {
          for (var obs in coffret.observationsLibres) {
            list.add(_ObsRecap(localisation: '${zone.nom} / ${local.nom}', coffret: coffret.nom,
                observation: obs.texte, refNorm: '', priorite: ''));
          }
        }
      }
      for (var obs in zone.observationsLibres) {
        list.add(_ObsRecap(localisation: zone.nom, coffret: '',
            observation: obs.texte, refNorm: '', priorite: ''));
      }
    }
    return list;
  }

  static bool _isNonConforme(String? val) =>
      val == 'non' || val == 'Non' || val == 'Non conforme';

  static pw.Widget _buildObsRecapTable(List<_ObsRecap> obs) {
    if (obs.isEmpty) {
      return pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor, width: 0.4)),
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: pw.Text('Aucune observation',
            style: pw.TextStyle(fontSize: fsSmall, fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey600)),
      );
    }
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.8),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(0.8),
      },
      children: [
        _tableHeaderRow(['LOCALISATION', 'COFFRET / ARMOIRE',
            'NON-CONFORMITÉ — PRÉCONISATION', 'RÉF. NORMATIVE', 'PRIORITÉ']),
        ...obs.asMap().entries.map((e) {
          final o = e.value;
          PdfColor? rowColor;
          if (o.priorite == '3')      rowColor = PdfColor.fromInt(0xFFFFEEEE);
          else if (o.priorite == '2') rowColor = PdfColor.fromInt(0xFFFFF8EE);
          else if (e.key.isOdd)       rowColor = tableRowAlt;
          return pw.TableRow(
            decoration: rowColor != null ? pw.BoxDecoration(color: rowColor) : null,
            children: [o.localisation, o.coffret, o.observation, o.refNorm, o.priorite]
                .map((t) => _cell(t, isHeader: false))
                .toList(),
          );
        }),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  AUDIT DES INSTALLATIONS ÉLECTRIQUES
  // ──────────────────────────────────────────────────────────────
  static List<pw.Widget> _buildAuditInstallations(
      AuditInstallationsElectriques audit, String clientName) {
    return [
      _buildInnerPageHeader(clientName: clientName),
      pw.SizedBox(height: 6),
      _sectionBox('AUDIT DES INSTALLATIONS ELECTRIQUES'),
      pw.SizedBox(height: 8),
      ..._buildAuditContent(audit),
    ];
  }

  static List<pw.Widget> _buildAuditContent(AuditInstallationsElectriques audit) {
    final widgets = <pw.Widget>[];
    for (var zone in audit.moyenneTensionZones) {
      widgets.addAll(_buildZoneSection(zone.nom, zone.observationsLibres));
      for (var local in zone.locaux)   widgets.addAll(_buildLocalMT(local));
      for (var coffret in zone.coffrets) widgets.addAll(_buildCoffret(coffret));
    }
    for (var local in audit.moyenneTensionLocaux) widgets.addAll(_buildLocalMT(local));
    for (var zone in audit.basseTensionZones) {
      widgets.addAll(_buildZoneSection(zone.nom, zone.observationsLibres));
      for (var coffret in zone.coffretsDirects) widgets.addAll(_buildCoffret(coffret));
      for (var local in zone.locaux)   widgets.addAll(_buildLocalBT(local));
    }
    return widgets;
  }

  static List<pw.Widget> _buildZoneSection(String nom, List<ObservationLibre> obs) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 8),
      pw.Container(
        width: double.infinity, color: headerColor,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(nom.toUpperCase(),
            style: pw.TextStyle(fontSize: fsH2, fontWeight: pw.FontWeight.bold,
                color: PdfColors.white)),
      ),
    ];
    if (obs.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 4));
      widgets.add(_buildObsZoneTable(nom, obs));
    }
    widgets.add(pw.SizedBox(height: 4));
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
            _cell('N°', isHeader: true, color: PdfColors.white),
            _cell('OBSERVATIONS RELATIVES À LA ZONE $zone', isHeader: true, color: PdfColors.white),
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
      pw.SizedBox(height: 4),
      _subSectionBar(local.nom.toUpperCase()),
      pw.SizedBox(height: 4),
    ];
    if (local.dispositionsConstructives.isNotEmpty)
      widgets.add(_buildDispositionsTable(local.dispositionsConstructives, 'DISPOSITIONS CONSTRUCTIVES DU LOCAL'));
    if (local.conditionsExploitation.isNotEmpty)
      widgets.add(_buildDispositionsTable(local.conditionsExploitation, 'CONDITIONS D\'EXPLOITATION ET DE SÉCURITÉ'));
    if (local.cellule != null)       widgets.addAll(_buildCelluleSection(local.cellule!));
    if (local.transformateur != null) widgets.addAll(_buildTransformateurSection(local.transformateur!));
    for (var coffret in local.coffrets) widgets.addAll(_buildCoffret(coffret));
    return widgets;
  }

  static List<pw.Widget> _buildLocalBT(BasseTensionLocal local) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 4),
      _subSectionBar(local.nom.toUpperCase()),
      pw.SizedBox(height: 4),
    ];
    if (local.dispositionsConstructives != null && local.dispositionsConstructives!.isNotEmpty)
      widgets.add(_buildDispositionsTable(local.dispositionsConstructives!, 'DISPOSITIONS CONSTRUCTIVES DU LOCAL'));
    if (local.conditionsExploitation != null && local.conditionsExploitation!.isNotEmpty)
      widgets.add(_buildDispositionsTable(local.conditionsExploitation!, 'CONDITIONS D\'EXPLOITATION ET DE SÉCURITÉ'));
    for (var coffret in local.coffrets) widgets.addAll(_buildCoffret(coffret));
    return widgets;
  }

  static pw.Widget _subSectionBar(String title) {
    return pw.Container(
      width: double.infinity, color: accentColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: pw.Text(title,
          style: pw.TextStyle(fontSize: fsH3, fontWeight: pw.FontWeight.bold,
              color: PdfColors.white)),
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
          children: [_cell(titre, isHeader: true)],
        ),
        _tableHeaderRow(['Éléments contrôlés', 'Conformité', 'Observations / Anomalies constatées']),
        ...elements.asMap().entries.map((e) {
          final el      = e.value;
          final isConf  = el.conforme != null;
          final confCol = isConf ? conformeColor : nonConformeColor;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: e.key.isEven ? PdfColors.white : tableRowAlt),
            children: [
              _cell(el.elementControle, isHeader: false),
              pw.Container(
                color:     confCol,
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: pw.Text(isConf ? 'Oui' : 'Non',
                    style: pw.TextStyle(fontSize: fsSmall)),
              ),
              _cell(el.observation ?? '', isHeader: false),
            ],
          );
        }),
      ],
    );
  }

  static List<pw.Widget> _buildCelluleSection(Cellule cellule) {
    return [
      pw.SizedBox(height: 4),
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
            children: [_cell('CELLULE', isHeader: true)],
          ),
          _tableDataRow(['Fonction', cellule.fonction, 'Type', cellule.type], alt: false),
          _tableDataRow(['Marque / Modèle / Année', cellule.marqueModeleAnnee, 'Tension assignée', cellule.tensionAssignee], alt: true),
          _tableDataRow(['Pouvoir de coupure (kA)', cellule.pouvoirCoupure, 'Numérotation', cellule.numerotation], alt: false),
          _tableDataRow(['Parafoudres arrivée', cellule.parafoudres, '', ''], alt: true),
        ],
      ),
      if (cellule.elementsVerifies.isNotEmpty)
        _buildDispositionsTable(cellule.elementsVerifies, 'Éléments vérifiés de la cellule'),
      pw.SizedBox(height: 4),
    ];
  }

  static List<pw.Widget> _buildTransformateurSection(TransformateurMTBT transfo) {
    return [
      pw.SizedBox(height: 4),
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
            children: [_cell('TRANSFORMATEUR MT/BT', isHeader: true)],
          ),
          _tableDataRow(['Type', transfo.typeTransformateur, 'Marque / Année', transfo.marqueAnnee], alt: false),
          _tableDataRow(['Puissance (kVA)', transfo.puissanceAssignee, 'Tension primaire / secondaire', transfo.tensionPrimaireSecondaire], alt: true),
          _tableDataRow(['Relais Buchholz', transfo.relaisBuchholz, 'Type de refroidissement', transfo.typeRefroidissement], alt: false),
          _tableDataRow(['Régime du neutre', transfo.regimeNeutre, '', ''], alt: true),
        ],
      ),
      if (transfo.elementsVerifies.isNotEmpty)
        _buildDispositionsTable(transfo.elementsVerifies, 'Éléments vérifiés du transformateur'),
      pw.SizedBox(height: 4),
    ];
  }

  static List<pw.Widget> _buildCoffret(CoffretArmoire coffret) {
    final widgets = <pw.Widget>[pw.SizedBox(height: 4)];
    widgets.add(pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.8),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('${coffret.type} : ${coffret.nom}',
                  style: pw.TextStyle(fontSize: fsH3, fontWeight: pw.FontWeight.bold,
                      color: headerColor)),
            ),
            _cell('Zone ATEX : ${coffret.zoneAtex ? "Oui" : "Non"}',           isHeader: false),
            _cell('Domaine : ${coffret.domaineTension}',                         isHeader: false),
            _cell('Identification : ${coffret.identificationArmoire ? "Oui" : "Non"}', isHeader: false),
            _cell('Signal. danger : ${coffret.signalisationDanger ? "Oui" : "Non"}',   isHeader: false),
          ],
        ),
        pw.TableRow(
          children: [
            _cell('Schéma : ${coffret.presenceSchema ? "Oui" : "Non"}',          isHeader: false),
            _cell('Parafoudre : ${coffret.presenceParafoudre ? "Oui" : "Non"}',  isHeader: false),
            _cell('Thermographie : ${coffret.verificationThermographie ? "Oui" : "Non"}', isHeader: false),
            _cell(coffret.repere != null ? 'Repère : ${coffret.repere}' : '',     isHeader: false),
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
          _tableHeaderRow(['Source', 'Type de protection', 'PDC kA', 'Calibre', 'Section câble']),
          ...coffret.alimentations.map((a) =>
              _tableDataRow(['Alimentation', a.typeProtection, a.pdcKA, a.calibre, a.sectionCable], alt: false)),
          if (coffret.protectionTete != null)
            _tableDataRow(['Protection de tête', coffret.protectionTete!.typeProtection,
                coffret.protectionTete!.pdcKA, '', ''], alt: coffret.alimentations.isNotEmpty),
        ],
      ));
    }
    if (coffret.pointsVerification.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 2));
      widgets.add(_buildPointsVerificationTable(coffret.pointsVerification));
    }
    if (coffret.observationsLibres.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 2));
      widgets.add(_buildSimpleObsTable(coffret.observationsLibres, 'Observations du coffret'));
    }
    widgets.add(pw.SizedBox(height: 4));
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
        _tableHeaderRow(['Points de vérification', 'Conformité', 'Observation', 'Référence normative']),
        ...points.asMap().entries.map((e) {
          final pv       = e.value;
          final isConf   = pv.conformite == 'oui' || pv.conformite == 'Oui';
          final isNA     = pv.conformite == 'non_applicable';
          final confCol  = isNA ? tableRowAlt : (isConf ? conformeColor : nonConformeColor);
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: e.key.isEven ? PdfColors.white : tableRowAlt),
            children: [
              _cell(pv.pointVerification, isHeader: false),
              pw.Container(
                color:     confCol,
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: pw.Text(isNA ? 'NA' : (isConf ? 'Oui' : 'Non'),
                    style: pw.TextStyle(fontSize: fsSmall)),
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
          children: [_cell('N°', isHeader: true), _cell(titre, isHeader: true)],
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
  static List<pw.Widget> _buildClassementEmplacements(
      List<ClassementEmplacement> classements, String clientName) {
    return [
      _buildInnerPageHeader(clientName: clientName),
      pw.SizedBox(height: 6),
      _sectionBox('CLASSEMENT DES LOCAUX ET EMPLACEMENTS EN FONCTION DES INFLUENCES EXTERNES'),
      pw.SizedBox(height: 8),
      _bodyText(
        'Dans le cas d\'absence de fourniture d\'une liste exhaustive des risques particuliers, le classement éventuel '
        'ci-après est proposé par le vérificateur et, sauf avis contraire, considéré comme validé par le chef d\'établissement.',
      ),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: 0.4),
        columnWidths: {
          0: const pw.FlexColumnWidth(2.5),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1.5),
          3: const pw.FlexColumnWidth(1),
          4: const pw.FlexColumnWidth(0.5),
          5: const pw.FlexColumnWidth(0.5),
          6: const pw.FlexColumnWidth(0.5),
          7: const pw.FlexColumnWidth(0.5),
          8: const pw.FlexColumnWidth(0.5),
          9: const pw.FlexColumnWidth(1),
          10: const pw.FlexColumnWidth(0.7),
        },
        children: [
          _tableHeaderRow(['Localisation', 'Zone', 'Origine classement',
              'Influences ext.', 'AF', 'BE', 'AE', 'AD', 'AG',
              'Indice mini IP', 'IK']),
          if (classements.isEmpty)
            pw.TableRow(children: List.generate(11, (_) => _cell('', isHeader: false)))
          else
            ...classements.asMap().entries.map((e) {
              final c = e.value;
              return _tableDataRow([
                c.localisation, c.zone ?? '-', '',
                '', c.af ?? '-', c.be ?? '-', c.ae ?? '-',
                c.ad ?? '-', c.ag ?? '-', c.ip ?? '-', c.ik ?? '-',
              ], alt: e.key.isOdd);
            }),
        ],
      ),
      pw.SizedBox(height: 14),
      _buildCodificationInfluences(),
    ];
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
            _cell('CODIFICATION DES INFLUENCES EXTERNES — INDICES ET DEGRÉS DE PROTECTION', isHeader: true),
          ],
        ),
        _tableHeaderRow(['PÉNÉTRATION DE CORPS SOLIDES', 'SUBSTANCES CORROSIVES / POLLUANTES', 'MATIÈRES TRAITÉES / ENTREPOSÉES']),
        _tableDataRow(['AE1 : Négligeable → IP 2X', 'AF1 : Négligeable', 'BE1 : Risques négligeables'], alt: false),
        _tableDataRow(['AE2 : Petits objets (≥ 2,5 mm) → IP 3X', 'AF2 : Agents atmosphériques', 'BE2 : Risques d\'incendie'], alt: true),
        _tableDataRow(['AE3 : Très petits objets → IP 4X', 'AF3 : Intermittente/accidentelle', 'BE3 : Risques d\'explosion'], alt: false),
        _tableDataRow(['AE4 : Poussières → IP 5X', 'AF4 : Permanente', 'BE4 : Risques de contamination'], alt: true),
        _tableHeaderRow(['ACCÈS AUX PARTIES DANGEREUSES', 'PÉNÉTRATION DE LIQUIDES', 'RISQUES DE CHOCS MÉCANIQUES']),
        _tableDataRow(['Non protégé → IP 0X', 'AD1 : Négligeable → IP X0', 'AG1 : Faibles (0,225 J) → IK 02'], alt: false),
        _tableDataRow(['A : Dos de la main → IP 1X', 'AD2 : Gouttes d\'eau → IP X1', 'AG2 : Moyens (2 J) → IK 07'], alt: true),
        _tableDataRow(['B : Doigt → IP 2X', 'AD3 : Gouttes jusqu\'à 15° → IP X2', 'AG3 : Importants (5 J) → IK 08'], alt: false),
        _tableDataRow(['C : Outil → IP 3X', 'AD4 : Aspersion → IP X3', 'AG4 : Très importants (20 J) → IK 10'], alt: true),
        _tableDataRow(['D : Fil → IP 4X', 'AD5 : Projections → IP X4', ''], alt: false),
        _tableDataRow(['', 'AD6 : Jets d\'eau → IP X5', ''], alt: true),
        _tableDataRow(['', 'AD7 : Paquets d\'eau → IP X6', ''], alt: false),
        _tableDataRow(['', 'AD8 : Immersion → IP X7', ''], alt: true),
        _tableDataRow(['', 'AD9 : Submersion → IP X8', ''], alt: false),
        _tableHeaderRow(['COMPÉTENCE DES PERSONNES', 'VIBRATIONS', '']),
        _tableDataRow(['BA1 : Ordinaires', 'AH1 : Faibles', ''], alt: false),
        _tableDataRow(['BA2 : Enfants', 'AH2 : Moyennes', ''], alt: true),
        _tableDataRow(['BA3 : Personnes handicapées', 'AH3 : Importantes', ''], alt: false),
        _tableDataRow(['BA4 : Personnes averties', '', ''], alt: true),
        _tableDataRow(['BA5 : Personnes qualifiées', '', ''], alt: false),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  FOUDRE
  // ──────────────────────────────────────────────────────────────
  static List<pw.Widget> _buildFoudre(List<Foudre> foudres, String clientName) {
    return [
      _buildInnerPageHeader(clientName: clientName),
      pw.SizedBox(height: 6),
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
            _tableHeaderRow(['Items', 'Priorité', 'Observations']),
            ...foudres.asMap().entries.map((e) {
              final f     = e.value;
              PdfColor rc = e.key.isOdd ? tableRowAlt : PdfColors.white;
              if (f.niveauPriorite == 3)      rc = PdfColor.fromInt(0xFFFFEBEB);
              else if (f.niveauPriorite == 2) rc = PdfColor.fromInt(0xFFFFF8E8);
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: rc),
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
    ];
  }

  // ──────────────────────────────────────────────────────────────
  //  RÉSULTATS DES MESURES ET ESSAIS
  // ──────────────────────────────────────────────────────────────
  static List<pw.Widget> _buildMesuresEssais(MesuresEssais mesures, String clientName) {
    return [
      _buildInnerPageHeader(clientName: clientName),
      pw.SizedBox(height: 6),
      _sectionBox('RESULTATS DES MESURES ET ESSAIS'),
      pw.SizedBox(height: 8),

      _subSectionBar('Conditions de mesure'),
      pw.SizedBox(height: 5),

      _bodyBold('MESURES D\'ISOLEMENT'),
      _bodyText(
        'Les mesures d\'isolement par rapport à la terre sont effectuées sous 500 V continu sur les canalisations '
        'en aval des DDR défectueux ou sur les canalisations pour lesquelles il a été constaté une absence de DDR '
        'nécessaire. La valeur est considérée comme satisfaisante si elle est supérieure à 0,5 MΩ.',
      ),
      pw.SizedBox(height: 4),

      _bodyBold('VÉRIFICATION DE LA CONTINUITÉ ET DE LA RÉSISTANCE DES CONDUCTEURS DE PROTECTION'),
      _bodyText(
        'La vérification de la continuité des conducteurs de protection est effectuée à l\'aide d\'un ohmmètre ou '
        'd\'un milliohmmètre. Elle est correcte si la valeur mesurée satisfait aux prescriptions du guide UTE C 15-105 § D6.',
      ),
      pw.SizedBox(height: 4),

      _bodyBold('ESSAIS DE DÉCLENCHEMENT DES DISPOSITIFS DIFFÉRENTIELS RÉSIDUELS'),
      _bodyText(
        'La valeur du seuil de déclenchement est correcte si elle est comprise entre 0,5 IAn et IAn. Les essais '
        'sont réalisés entre une phase et la terre.',
      ),
      pw.SizedBox(height: 4),

      _bodyBold('MESURE DES IMPÉDANCES DE BOUCLE (PROTECTION CONTACTS INDIRECTS)'),
      _bodyText(
        'Cette mesure est effectuée si nécessaire à l\'aide d\'un milliohmmètre de boucle. Le dispositif de protection '
        'est correct si son temps de coupure satisfait aux prescriptions du guide UTE C 15-105.',
      ),

      if (mesures.conditionMesure.observation != null &&
          mesures.conditionMesure.observation!.isNotEmpty) ...[
        pw.SizedBox(height: 4),
        _bodyText(mesures.conditionMesure.observation!),
      ],

      pw.SizedBox(height: 14),
      _subSectionBar('Essais de démarrage automatique du groupe électrogène'),
      pw.SizedBox(height: 5),
      _resultBox(mesures.essaiDemarrageAuto.observation ?? 'Non satisfaisant'),

      pw.SizedBox(height: 14),
      _subSectionBar('Test de fonctionnement de l\'arrêt d\'urgence'),
      pw.SizedBox(height: 5),
      _resultBox(mesures.testArretUrgence.observation ?? 'Satisfaisant'),

      pw.SizedBox(height: 14),
      _subSectionBar('Prise de terre'),
      pw.SizedBox(height: 5),

      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: 0.4),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.5),
          1: const pw.FlexColumnWidth(1.5),
          2: const pw.FlexColumnWidth(1.2),
          3: const pw.FlexColumnWidth(1),
          4: const pw.FlexColumnWidth(1),
          5: const pw.FlexColumnWidth(1),
          6: const pw.FlexColumnWidth(1.5),
        },
        children: [
          _tableHeaderRow(['Localisation', 'Identification',
              'Condition mesure', 'Nature PT', 'Méthode', 'Valeur (Ω)', 'Observation']),
          if (mesures.prisesTerre.isEmpty)
            pw.TableRow(children: List.generate(7, (_) => _cell('', isHeader: false)))
          else
            ...mesures.prisesTerre.asMap().entries.map((e) {
              final pt = e.value;
              return _tableDataRow([
                pt.localisation, pt.identification, pt.conditionPriseTerre,
                pt.naturePriseTerre, pt.methodeMesure,
                pt.valeurMesure?.toStringAsFixed(2) ?? '-',
                pt.observation ?? '',
              ], alt: e.key.isOdd);
            }),
        ],
      ),

      if (mesures.avisMesuresTerre.observation != null &&
          mesures.avisMesuresTerre.observation!.isNotEmpty) ...[
        pw.SizedBox(height: 4),
        if (mesures.avisMesuresTerre.satisfaisants.isNotEmpty)
          _bodyText('Prises de terre satisfaisantes : ${mesures.avisMesuresTerre.satisfaisants.join(', ')}'),
        if (mesures.avisMesuresTerre.nonSatisfaisants.isNotEmpty)
          _bodyText('Prises de terre non satisfaisantes : ${mesures.avisMesuresTerre.nonSatisfaisants.join(', ')}'),
        _bodyText(mesures.avisMesuresTerre.observation!),
      ],

      pw.SizedBox(height: 14),
      _subSectionBar('Mesures d\'isolement des circuits BT'),
      pw.SizedBox(height: 5),
      _bodyText('Sans observation'),

      pw.SizedBox(height: 14),
      _subSectionBar('Essais de déclenchement des dispositifs différentiels'),
      pw.SizedBox(height: 5),

      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: 0.4),
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(1.5),
          2: const pw.FlexColumnWidth(1.2),
          3: const pw.FlexColumnWidth(0.8),
          4: const pw.FlexColumnWidth(0.8),
          5: const pw.FlexColumnWidth(0.8),
          6: const pw.FlexColumnWidth(1),
        },
        children: [
          _tableHeaderRow(['Quantité', 'Désignation circuit', 'Type dispositif',
              'Régl. In (mA)', 'Tempo (s)', 'Essai', 'Isolement (MΩ)']),
          if (mesures.essaisDeclenchement.isEmpty)
            pw.TableRow(children: List.generate(7, (_) => _cell('', isHeader: false)))
          else
            ...mesures.essaisDeclenchement.asMap().entries.map((e) {
              final es      = e.value;
              final essaiOk = es.essai == 'B' || es.essai == 'OK';
              final essaiKo = es.essai == 'M' || es.essai == 'NON OK';
              final esCol   = essaiOk ? conformeColor : (essaiKo ? nonConformeColor : null);
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: e.key.isOdd ? tableRowAlt : PdfColors.white),
                children: [
                  _cell(es.localisation, isHeader: false),
                  _cell('${es.coffret ?? ''} / ${es.designationCircuit ?? ''}', isHeader: false),
                  _cell(es.typeDispositif, isHeader: false),
                  _cell(es.reglageIAn?.toString() ?? '-', isHeader: false),
                  _cell(es.tempo?.toString() ?? '-', isHeader: false),
                  pw.Container(
                    color:     esCol,
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    child: pw.Text(es.essai, style: pw.TextStyle(fontSize: fsSmall)),
                  ),
                  _cell(es.isolement?.toString() ?? '-', isHeader: false),
                ],
              );
            }),
        ],
      ),

      pw.SizedBox(height: 14),
      _buildAbreviationsTable(),

      pw.SizedBox(height: 14),
      _subSectionBar('Continuité et résistance des conducteurs de protection et des liaisons équipotentielles'),
      pw.SizedBox(height: 5),

      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: 0.4),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(2.5),
          2: const pw.FlexColumnWidth(1.5),
          3: const pw.FlexColumnWidth(2),
        },
        children: [
          _tableHeaderRow(['Localisation', 'Désignation tableau / équipement',
              'Origine mesure', 'Observation']),
          if (mesures.continuiteResistances.isEmpty)
            pw.TableRow(children: List.generate(4, (_) => _cell('', isHeader: false)))
          else
            ...mesures.continuiteResistances.asMap().entries.map((e) {
              final c = e.value;
              return _tableDataRow([
                c.localisation, c.designationTableau, c.origineMesure, c.observation ?? '',
              ], alt: e.key.isOdd);
            }),
        ],
      ),
    ];
  }

  static pw.Widget _resultBox(String text) {
    final isOk = text.toLowerCase().contains('satisfaisant') &&
        !text.toLowerCase().contains('non');
    return pw.Container(
      decoration: pw.BoxDecoration(
        color:  isOk ? conformeColor : nonConformeColor,
        border: pw.Border.all(color: borderColor, width: 0.4),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: fsBody,
          fontWeight: isOk ? pw.FontWeight.bold : pw.FontWeight.normal)),
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
          children: [_cell('Signification des abréviations utilisées', isHeader: true)],
        ),
        _tableHeaderRow(['Abréviation', 'Signification']),
        _tableDataRow(['DDR', 'Disjoncteur Différentiel Résiduel'], alt: false),
        _tableDataRow(['RD',  'Relais Différentiel'],               alt: true),
        _tableDataRow(['B',   'Bon fonctionnement'],                alt: false),
        _tableDataRow(['NE',  'Non essayé'],                        alt: true),
        _tableDataRow(['IDR', 'Interrupteur Différentiel'],         alt: false),
        _tableDataRow(['In',  'Intensité différentielle nominale'], alt: true),
        _tableDataRow(['M',   'Fonctionnement incorrect'],          alt: false),
        _tableDataRow(['Tempo', 'Temporisation'],                   alt: true),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  SECTION PHOTOS
  // ──────────────────────────────────────────────────────────────
  static Future<void> _addPhotosSection(
      pw.Document pdf, Mission mission, String missionId,
      AuditInstallationsElectriques? audit) async {

    final allPhotos = <_PhotoEntry>[];
    final clientName = mission.nomSite ?? mission.nomClient;

    if (audit != null) {
      for (var local in audit.moyenneTensionLocaux) {
        _addPhotosFromList(allPhotos, local.photos, local.nom);
        if (local.cellule != null)
          _addPhotosFromList(allPhotos, local.cellule!.photos, '${local.nom} — Cellule');
        if (local.transformateur != null)
          _addPhotosFromList(allPhotos, local.transformateur!.photos, '${local.nom} — Transformateur');
        for (var c in local.coffrets)
          _addPhotosFromList(allPhotos, c.photos, '${local.nom} — ${c.nom}');
      }
      for (var zone in audit.moyenneTensionZones) {
        _addPhotosFromList(allPhotos, zone.photos, zone.nom);
        for (var c in zone.coffrets)
          _addPhotosFromList(allPhotos, c.photos, '${zone.nom} — ${c.nom}');
        for (var local in zone.locaux) {
          _addPhotosFromList(allPhotos, local.photos, '${zone.nom} — ${local.nom}');
          for (var c in local.coffrets)
            _addPhotosFromList(allPhotos, c.photos, '${zone.nom} — ${local.nom} — ${c.nom}');
        }
      }
      for (var zone in audit.basseTensionZones) {
        _addPhotosFromList(allPhotos, zone.photos, zone.nom);
        for (var c in zone.coffretsDirects)
          _addPhotosFromList(allPhotos, c.photos, '${zone.nom} — ${c.nom}');
        for (var local in zone.locaux) {
          _addPhotosFromList(allPhotos, local.photos, '${zone.nom} — ${local.nom}');
          for (var c in local.coffrets)
            _addPhotosFromList(allPhotos, c.photos, '${zone.nom} — ${local.nom} — ${c.nom}');
        }
      }
    }

    // Page index photos
    pdf.addPage(
      pw.MultiPage(
        pageTheme: _buildPageTheme(isFirstPage: false),
        build: (ctx) => [
          _buildInnerPageHeader(clientName: clientName),
          pw.SizedBox(height: 6),
          _sectionBox('PHOTOS'),
          pw.SizedBox(height: 8),
          if (allPhotos.isEmpty)
            _bodyText('Aucune photo disponible.')
          else ...[
            _bodyText('Liste des photos prises lors de l\'audit :'),
            pw.SizedBox(height: 5),
            pw.Table(
              border: pw.TableBorder.all(color: borderColor, width: 0.4),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3.5),
              },
              children: [
                _tableHeaderRow(['N°', 'Fichier photo', 'Localisation / Description']),
                ...allPhotos.asMap().entries.map((e) => _tableDataRow([
                  '${e.key + 1}',
                  path.basename(e.value.filePath),
                  e.value.description,
                ], alt: e.key.isOdd)),
              ],
            ),
          ],
        ],
      ),
    );

    // Pages individuelles de photos (2 par page)
    for (int i = 0; i < allPhotos.length; i += 2) {
      final entries = allPhotos.sublist(i, i + 2 < allPhotos.length ? i + 2 : allPhotos.length);

      final photoWidgets = <pw.Widget>[];
      for (int j = 0; j < entries.length; j++) {
        final entry = entries[j];
        try {
          final file = File(entry.filePath);
          if (!await file.exists()) continue;
          final bytes = await file.readAsBytes();
          final img   = pw.MemoryImage(bytes);
          photoWidgets.add(pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Photo ${i + j + 1} — ${entry.description}',
                  style: pw.TextStyle(fontSize: fsSmall, color: darkGrey)),
              pw.SizedBox(height: 4),
              pw.Container(
                height: 200,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.4),
                ),
                child: pw.Image(img, fit: pw.BoxFit.contain),
              ),
            ],
          ));
          if (j < entries.length - 1) photoWidgets.add(pw.SizedBox(height: 12));
        } catch (e) {
          print('❌ Erreur photo ${entry.filePath}: $e');
        }
      }

      if (photoWidgets.isNotEmpty) {
        pdf.addPage(
          pw.MultiPage(
            pageTheme: _buildPageTheme(isFirstPage: false),
            build: (ctx) => [
              _buildInnerPageHeader(clientName: clientName),
              pw.SizedBox(height: 8),
              ...photoWidgets,
            ],
          ),
        );
      }
    }
  }

  static void _addPhotosFromList(
      List<_PhotoEntry> list, List<String> photos, String description) {
    for (var p in photos) {
      if (p.isNotEmpty) list.add(_PhotoEntry(filePath: p, description: description));
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  UTILITAIRES PDF (cellules, lignes, titres...)
  // ──────────────────────────────────────────────────────────────

  static pw.Widget _sectionBox(String title) {
    return pw.Container(
      width:   double.infinity,
      color:   headerColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child:   pw.Text(
        title,
        style: pw.TextStyle(fontSize: fsH1, fontWeight: pw.FontWeight.bold,
            color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _subTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize:   fsH3,
          fontWeight: pw.FontWeight.bold,
          color:      accentColor,
          decoration: pw.TextDecoration.underline,
        ),
      ),
    );
  }

  static pw.Widget _bodyText(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: fsBody, color: darkGrey, lineSpacing: 1.4)),
    );
  }

  static pw.Widget _bodyBold(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: fsBody, fontWeight: pw.FontWeight.bold,
              color: darkGrey)),
    );
  }

  static pw.Widget _bulletItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('–  ', style: pw.TextStyle(fontSize: fsBody, color: accentColor)),
          pw.Expanded(
            child: pw.Text(text,
                style: pw.TextStyle(fontSize: fsBody, color: darkGrey, lineSpacing: 1.3)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cell(String text, {
    required bool isHeader,
    PdfColor? color,
    int colspan = 1,
  }) {
    return pw.Container(
      color:   color,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child:   pw.Text(
        text,
        style: pw.TextStyle(
          fontSize:   fsSmall,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color != null ? PdfColors.white
              : (isHeader ? headerColor : darkGrey),
        ),
      ),
    );
  }

  static pw.TableRow _tableHeaderRow(List<String> headers) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: lightBlue),
      children:   headers.map((h) => _cell(h, isHeader: true)).toList(),
    );
  }

  static pw.TableRow _tableDataRow(List<String> data, {required bool alt}) {
    return pw.TableRow(
      decoration: alt ? pw.BoxDecoration(color: tableRowAlt) : null,
      children:   data.map((d) => _cell(d, isHeader: false)).toList(),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  HELPERS DIVERS
  // ──────────────────────────────────────────────────────────────
  static String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  static String _formatDateLong(DateTime d) {
    const months = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  static String _monthName(int m) {
    const months = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return months[m];
  }

  static Future<void> shareReport(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Rapport d\'Audit Électrique — KES INSPECTIONS AND PROJECTS',
        text:    'Veuillez trouver ci-joint le rapport d\'audit électrique.',
      );
    } catch (e) {
      print('❌ Erreur partage PDF: $e');
    }
  }

  static Future<void> deleteReport(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (e) {
      print('❌ Erreur suppression PDF: $e');
    }
  }
}

// ================================================================
//  Classes internes
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
  _PhotoEntry({required this.filePath, required this.description});
}