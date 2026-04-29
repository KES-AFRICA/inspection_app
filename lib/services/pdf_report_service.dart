// pdf_report_service.dart - Version corrigee finale

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
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
//  PdfReportService - Version amelioree avec filigrane, footers
//  et marges personnalisees
// ================================================================

class PdfReportService {
  // ──────────────────────────────────────────────────────────────
  //  CONSTANTES DE MISE EN PAGE
  // ──────────────────────────────────────────────────────────────
  
  /// Marges du document (en points DTP, 1 cm ≈ 28.35 pt)
  static const double kLeftMargin = 3.0 * 28.35;   // 3 cm a gauche
  static const double kTopMargin = 2.0 * 28.35;    // 2 cm en haut
  static const double kRightMargin = 2.0 * 28.35;  // 2 cm a droite
  static const double kBottomMargin = 2.0 * 28.35; // 2 cm en bas
  
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

  /// Charge toutes les images necessaires (appele une seule fois)
  static Future<void> _loadImages() async {
    if (_imagesLoaded) return;
    
    Future<pw.MemoryImage?> tryLoad(String asset) async {
      try {
        return pw.MemoryImage((await rootBundle.load(asset)).buffer.asUint8List());
      } catch (e) { if (kDebugMode) {
        print('Image non trouvee: $asset');
      } return null; }
    }
    _watermarkImage = await tryLoad('assets/images/filigranne_image.png');
    _firstPageFooterImage = await tryLoad('assets/images/firstpage_footer.png');
    _otherPageFooterImage = await tryLoad('assets/images/otherpage_footer.png');
    _logoKesImage = await tryLoad('assets/images/logo.png');
    _imgHabilitation = await tryLoad('assets/images/image.png');
    _imgAccesGauche = await tryLoad('assets/images/image copy.png');
    _imgAccesDroite1 = await tryLoad('assets/images/image copy 2.png');
    _imgAccesDroite2 = await tryLoad('assets/images/image copy 3.png');
    try {
      if (true) {
        // placeholder to match brace structure
        if (kDebugMode) {
          print('Images loaded');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Filigrane non trouve: $e');
      }
    }
    
    try {
      _firstPageFooterImage = pw.MemoryImage(
        (await rootBundle.load('assets/images/firstpage_footer.png')).buffer.asUint8List(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Footer couverture non trouve: $e');
      }
    }
    
    try {
      _otherPageFooterImage = pw.MemoryImage(
        (await rootBundle.load('assets/images/otherpage_footer.png')).buffer.asUint8List(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Footer pages interieures non trouve: $e');
      }
    }
    
    try {
      _logoKesImage = pw.MemoryImage(
        (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Logo non trouve: $e');
      }
    }
    
    _imagesLoaded = true;
  }

  /// Charge les polices necessaires
  static Future<void> _loadFonts() async {
    if (_fontsLoaded) return;
    
    // Utiliser une police qui supporte Unicode (Roboto, OpenSans, etc.)
    // Si tu as des fichiers de police dans assets, tu peux les charger :
    try {
      final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      _fontRegular = pw.Font.ttf(regularData);
      _fontBold = pw.Font.ttf(boldData);
    } catch (e) {
      // Fallback sur les polices standard (mais sans accents)
      if (kDebugMode) {
        print('⚠️ Polices personnalisees non trouvees, utilisation des polices standard');
      }
      _fontRegular = pw.Font.helvetica();
      _fontBold = pw.Font.helveticaBold();
    }
    
    _fontsLoaded = true;
  }

  // ──────────────────────────────────────────────────────────────
  //  CONSTRUCTION DU THEME DE PAGE
  // ──────────────────────────────────────────────────────────────
  static pw.PageTheme _buildPageTheme({required bool isFirstPage}) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.only(
        left: kLeftMargin,
        top: kTopMargin,
        right: kRightMargin,
        bottom: 2.5 * 28.35,
      ),
      buildBackground: (ctx) => _buildWatermarkBackground(),
      buildForeground: (ctx) => _buildFooterForeground(ctx, isFirstPage: isFirstPage),
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

  // ──────────────────────────────────────────────────────────────
  //  ARRIERE-PLAN DE PAGE (Watermark + Footer)
  // ──────────────────────────────────────────────────────────────

  // CORRECTION VIII: footer + pagination dans foreground (pageNumber accessible)
  static pw.Widget _buildFooterForeground(pw.Context ctx, {required bool isFirstPage}) {
    final footerImg = isFirstPage ? _firstPageFooterImage : _otherPageFooterImage;
    return pw.Stack(
      children: [
        pw.Positioned(
          bottom: 0,
          left: -kLeftMargin,
          right: -kRightMargin,
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              if (footerImg != null)
                pw.Image(footerImg, fit: pw.BoxFit.fitWidth, width: PdfPageFormat.a4.width)
              else
                pw.Container(height: 35, color: PdfColors.grey400),
              if (!isFirstPage)
                pw.Container(
                  width: PdfPageFormat.a4.width,
                  padding: pw.EdgeInsets.only(left: kLeftMargin, right: kRightMargin, bottom: 4),
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      'Page \${ctx.pageNumber} / \${ctx.pagesCount}',
                      style: pw.TextStyle(
                        font: _fontRegular,
                        fontSize: 7.5,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }


  // ──────────────────────────────────────────────────────────────
  //  POINT D'ENTREE PRINCIPAL
  // ──────────────────────────────────────────────────────────────
  static Future<File?> generateMissionReport(String missionId) async {
    try {
      // Charger les images
      await _loadImages();
      await _loadFonts();
      
      // Recuperer les donnees
      final mission = HiveService.getMissionById(missionId);
      if (mission == null) return null;
      
      final description = HiveService.getDescriptionInstallationsByMissionId(missionId);
      final audit = HiveService.getAuditInstallationsByMissionId(missionId);
      final classements = HiveService.getEmplacementsByMissionId(missionId);
      final mesures = HiveService.getMesuresEssaisByMissionId(missionId);
      final foudres = HiveService.getFoudreObservationsByMissionId(missionId);
      final renseignements = HiveService.getRenseignementsGenerauxByMissionId(missionId);
      final currentUser = HiveService.getCurrentUser();

      // Creer le document
      final pdf = pw.Document(
        title: 'Rapport d\'Audit Electrique - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: true,
      );

      // ────────────────────────────────────────────────────────────
      //  1. PAGE DE COUVERTURE
      // ────────────────────────────────────────────────────────────
      pdf.addPage(
        pw.Page(
          pageTheme: _buildPageTheme(isFirstPage: true),  // ← Appel direct, pas de lambda
          build: (ctx) => _buildCoverPage(mission, renseignements, ctx),
        ),
      );

      // Page Sommaire avec numeros de page
      pdf.addPage(pw.Page(
        pageTheme: _buildPageTheme(isFirstPage: false),
        build: (ctx) => _buildSommaire(audit, mesures),
      ));

      // ────────────────────────────────────────────────────────────
      //  PAGES SUIVANTES
      // ────────────────────────────────────────────────────────────
      
      // 2. Rappel des responsabilites
      pdf.addPage(
        pw.Page(
          pageTheme: _buildPageTheme(isFirstPage: false),  // ← Appel direct
          build: (ctx) => _buildRappelResponsabilites(),
        ),
      );

      pdf.addPage(
      pw.Page(
          pageTheme: _buildPageTheme(isFirstPage: false),
          build: (ctx) => _buildMesureSecurite(),
        ),
      );

      pdf.addPage(
        pw.Page(
          pageTheme: _buildPageTheme(isFirstPage: false),
          build: (ctx) => _buildObjetVerification(),
        ),
      );

    // 4. Renseignements generaux
    pdf.addPage(
      pw.Page(
        pageTheme: _buildPageTheme(isFirstPage: false),
        build: (ctx) => _buildRenseignementsGeneraux(mission, renseignements),
      ),
    );

    // 5. Description des installations
    pdf.addPage(
      pw.Page(
        pageTheme: _buildPageTheme(isFirstPage: false),
        build: (ctx) => _buildDescriptionInstallations(description),
      ),
    );

    // 6. Liste recapitulative des observations
    if (audit != null) {
      pdf.addPage(
        pw.Page(
          pageTheme: _buildPageTheme(isFirstPage: false),
          build: (ctx) => _buildListeRecapitulative(audit),
        ),
      );
    }

    // 7. Audit des installations electriques
    if (audit != null) {
      pdf.addPage(
        pw.Page(
          pageTheme: _buildPageTheme(isFirstPage: false),
          build: (ctx) => _buildAuditInstallations(audit),
        ),
      );
    }

    // 8. Classement des emplacements
    pdf.addPage(
      pw.Page(
        pageTheme: _buildPageTheme(isFirstPage: false),
        build: (ctx) => _buildClassementEmplacements(classements),
      ),
    );

    // 9. Foudre
    pdf.addPage(
      pw.Page(
        pageTheme: _buildPageTheme(isFirstPage: false),
        build: (ctx) => _buildFoudre(foudres),
      ),
    );

    // 10. Resultats des mesures et essais - chaque element sur nouvelle page
    if (mesures != null) {
      _addMesuresEssaisPages(pdf, mesures);
      // Page signature avant photos
      pdf.addPage(pw.Page(
        pageTheme: _buildPageTheme(isFirstPage: false),
        build: (ctx) => _buildSignaturePage(renseignements, currentUser?.fullName),
      ));
    }

      // 11. Photos
      await _addPhotosSection(pdf, mission, missionId, audit);

      // ────────────────────────────────────────────────────────────
      //  SAUVEGARDE DU FICHIER
      // ────────────────────────────────────────────────────────────
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
  //  EN-TETE DE PAGE (pour les pages interieures)
  // ──────────────────────────────────────────────────────────────
  static pw.Widget _buildPageHeader(Mission mission) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (_logoKesImage != null)
            pw.Image(_logoKesImage!, width: 55, height: 22, fit: pw.BoxFit.contain)
          else
            pw.Text('KES INSPECTIONS AND PROJECTS',
                style: pw.TextStyle(fontSize: 6, color: accentColor, fontWeight: pw.FontWeight.bold)),
          pw.Text('RAPPORT DE VERIFICATION DES INSTALLATIONS ELECTRIQUES',
              style: pw.TextStyle(fontSize: 6, color: darkGrey)),
          pw.Text(mission.nomClient,
              style: pw.TextStyle(fontSize: 6, color: darkGrey)),
        ],
      ),
    );
  }

  // Helper pour l'en-tete dans les pages sans header automatique
  static pw.Widget _buildPageHeaderWidget({String? nomClient}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: accentColor, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (_logoKesImage != null)
            pw.Image(_logoKesImage!, width: 55, height: 22, fit: pw.BoxFit.contain)
          else
            pw.Text('KES INSPECTIONS AND PROJECTS',
                style: pw.TextStyle(font: _fontBold, fontSize: 6, color: accentColor, fontWeight: pw.FontWeight.bold)),
          pw.Text('RAPPORT DE VERIFICATION DES INSTALLATIONS ELECTRIQUES',
              style: pw.TextStyle(font: _fontRegular, fontSize: 6, color: darkGrey)),
          pw.Text(nomClient ?? '', style: pw.TextStyle(font: _fontRegular, fontSize: 6, color: darkGrey)),
        ],
      ),
    );
  }

  static String _docStatus(bool? val) => val == true ? 'Presente' : 'Non presente';

  // ──────────────────────────────────────────────────────────────
  //  PAGE DE COUVERTURE
  // ──────────────────────────────────────────────────────────────
  static pw.Widget _buildSommaire(AuditInstallationsElectriques? audit, MesuresEssais? mesures) {
    final sections = <_SommaireEntry>[
      _SommaireEntry('Sommaire', 2),
      _SommaireEntry('Rappel des responsabilites de l\'employeur', 3),
      _SommaireEntry('Mésures de sécurité autours des installations', 4),
      _SommaireEntry('Objet de la verification', 5),
      _SommaireEntry('Renseignements generaux de l\'etablissement', 6),
      _SommaireEntry('Description des installations', 7),
      if (audit != null) _SommaireEntry('Liste recapitulative des observations', 7),
      if (audit != null) _SommaireEntry('Audit des installations electriques', 8),
      _SommaireEntry('Classement des locaux et influences externes', 10),
      _SommaireEntry('Foudre', 11),
      if (mesures != null) ...[
        _SommaireEntry('Resultats des mesures et essais', 12),
        _SommaireEntry('  Essais de demarrage automatique', 13),
        _SommaireEntry('  Test d\'arret d\'urgence', 14),
        _SommaireEntry('  Prise de terre', 15),
        _SommaireEntry('  Mesures d\'isolement des circuits BT', 16),
        _SommaireEntry('  Essais de declenchement des DDR', 17),
        _SommaireEntry('  Continuite et resistance des conducteurs', 18),
      ],
      _SommaireEntry('Photos', 19),
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeaderWidget(),
        pw.SizedBox(height: 10),
        _sectionBox('SOMMAIRE'),
        pw.SizedBox(height: 16),
        pw.Table(
          border: pw.TableBorder.all(color: borderColor, width: 0.4),
          columnWidths: {0: const pw.FlexColumnWidth(5), 1: const pw.FlexColumnWidth(1)},
          children: [
            _tableHeaderRow(['SECTION', 'PAGE']),
            ...sections.asMap().entries.map((e) {
              final isSub = e.value.titre.startsWith('  ');
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: e.key.isOdd ? tableRowAlt : PdfColors.white),
                children: [
                  pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      child: pw.Text(e.value.titre, style: pw.TextStyle(font: isSub ? _fontRegular : _fontBold, fontSize: fsSmall, color: isSub ? darkGrey : headerColor))),
                  pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3), alignment: pw.Alignment.center,
                      child: pw.Text('${e.value.page}', style: pw.TextStyle(font: _fontRegular, fontSize: fsSmall))),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }
  static pw.Widget _buildListeRecapitulative(AuditInstallationsElectriques audit) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeaderWidget(),
        pw.SizedBox(height: 10),
        _sectionBox('LISTE RECAPITULATIVE DES OBSERVATIONS'),
        pw.SizedBox(height: 8),
        _subTitle('Niveau de priorite des observations constatees'),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            _badgePriorite('1', priorite1Color), pw.SizedBox(width: 4),
            _bodyText('Niveau 1 : A surveiller'),
            pw.SizedBox(width: 16),
            _badgePriorite('2', priorite2Color), pw.SizedBox(width: 4),
            _bodyText('Niveau 2 : Mise en conformite a planifier'),
            pw.SizedBox(width: 16),
            _badgePriorite('3', priorite3Color), pw.SizedBox(width: 4),
            _bodyText('Niveau 3 : Critique, Action immediate'),
          ],
        ),
        pw.SizedBox(height: 16),
        _subTitle('Moyenne tension'),
        pw.SizedBox(height: 5),
        _buildObsRecapTable(_collectObservationsMT(audit)),
        pw.SizedBox(height: 16),
        _subTitle('Basse tension'),
        pw.SizedBox(height: 5),
        _buildObsRecapTable(_collectObservationsBT(audit)),
      ],
    );
  }
  static pw.Widget _buildAuditInstallations(AuditInstallationsElectriques audit) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeaderWidget(),
        pw.SizedBox(height: 10),
        _sectionBox('AUDIT DES INSTALLATIONS ELECTRIQUES'),
        pw.SizedBox(height: 8),
        ..._buildAuditContent(audit),
      ],
    );
  }
  static pw.Widget _buildDescriptionInstallations(DescriptionInstallations? desc) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeaderWidget(),
        pw.SizedBox(height: 10),
        _sectionBox('DESCRIPTION DES INSTALLATIONS'),
        pw.SizedBox(height: 8),
        if (desc == null)
          _bodyText('Aucune donnee disponible.')
        else
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (desc.alimentationMoyenneTension.isNotEmpty) ...[
                _subTitle('Caracteristiques de l\'alimentation moyenne tension'),
                _buildInstallationTable(desc.alimentationMoyenneTension),
                pw.SizedBox(height: 8),
              ],
              if (desc.alimentationBasseTension.isNotEmpty) ...[
                _subTitle('Caracteristiques de l\'alimentation basse tension sortie transformateur'),
                _buildInstallationTable(desc.alimentationBasseTension),
                pw.SizedBox(height: 8),
              ],
              if (desc.groupeElectrogene.isNotEmpty) ...[
                _subTitle('Caracteristiques du groupe electrogene'),
                _buildInstallationTable(desc.groupeElectrogene),
                pw.SizedBox(height: 8),
              ],
              if (desc.alimentationCarburant.isNotEmpty) ...[
                _subTitle('Alimentation du groupe electrogene en carburant'),
                _buildInstallationTable(desc.alimentationCarburant),
                pw.SizedBox(height: 8),
              ],
              if (desc.inverseur.isNotEmpty) ...[
                _subTitle('Caracteristiques de l\'inverseur'),
                _buildInstallationTable(desc.inverseur),
                pw.SizedBox(height: 8),
              ],
              _subTitle('Caracteristiques du stabilisateur'),
              if (desc.stabilisateur.isNotEmpty)
                _buildInstallationTable(desc.stabilisateur)
              else
                _bodyText('- Pas de stabilisateur'),
              pw.SizedBox(height: 8),
              if (desc.onduleurs.isNotEmpty) ...[
                _subTitle('Caracteristiques des onduleurs'),
                _buildInstallationTable(desc.onduleurs),
                pw.SizedBox(height: 8),
              ],
              _subTitle('Regime de neutre'),
              _bodyText('- ${desc.regimeNeutre ?? 'TT'}'),
              pw.SizedBox(height: 5),
              _subTitle('Eclairage de securite'),
              _bodyText('- ${desc.eclairageSecurite ?? 'Present'}'),
              pw.SizedBox(height: 5),
              _subTitle('Modifications apportees aux installations'),
              _bodyText('Modifications apportees aux installations : ${desc.modificationsInstallations ?? 'Sans Objet'}'),
              pw.SizedBox(height: 5),
              _subTitle('Note de calcul des installations electriques'),
              _bodyText('- ${desc.noteCalcul ?? 'Non transmis'}'),
              pw.SizedBox(height: 5),
              _subTitle('Presence de paratonnerre'),
              _bodyText('Presence de paratonnerre : ${desc.presenceParatonnerre ?? 'NON'}'),
              _bodyText('Analyse risque foudre : ${desc.analyseRisqueFoudre ?? ''}'),
              _bodyText('Etude technique foudre : ${desc.etudeTechniqueFoudre ?? ''}'),
              pw.SizedBox(height: 5),
              _subTitle('Registre de securite'),
              _bodyText('- ${desc.registreSecurite ?? 'Non transmis'}'),
            ],
          ),
      ],
    );
  }

  static List<_ObsRecap> _collectObservationsMT(AuditInstallationsElectriques audit) {
    final list = <_ObsRecap>[];
    for (var local in audit.moyenneTensionLocaux) {
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
        list.add(_ObsRecap(localisation: local.nom, coffret: '', observation: obs.texte, refNorm: '', priorite: ''));
      }
    }
    for (var zone in audit.moyenneTensionZones) {
      for (var local in zone.locaux) {
        for (var coffret in local.coffrets) {
          for (var obs in coffret.observationsLibres) {
            list.add(_ObsRecap(localisation: '${zone.nom} / ${local.nom}', coffret: coffret.nom, observation: obs.texte, refNorm: '', priorite: ''));
          }
        }
      }
      for (var obs in zone.observationsLibres) {
        list.add(_ObsRecap(localisation: zone.nom, coffret: '', observation: obs.texte, refNorm: '', priorite: ''));
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
          list.add(_ObsRecap(localisation: zone.nom, coffret: coffret.nom, observation: obs.texte, refNorm: '', priorite: ''));
        }
      }
      for (var local in zone.locaux) {
        for (var coffret in local.coffrets) {
          for (var obs in coffret.observationsLibres) {
            list.add(_ObsRecap(localisation: '${zone.nom} / ${local.nom}', coffret: coffret.nom, observation: obs.texte, refNorm: '', priorite: ''));
          }
        }
      }
      for (var obs in zone.observationsLibres) {
        list.add(_ObsRecap(localisation: zone.nom, coffret: '', observation: obs.texte, refNorm: '', priorite: ''));
      }
    }
    return list;
  }

  static pw.Widget _buildObsRecapTable(List<_ObsRecap> obs) {
    if (obs.isEmpty) {
      return pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor, width: 0.4)),
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text('Aucune observation', style: pw.TextStyle(fontSize: fsSmall, fontStyle: pw.FontStyle.italic)),
      );
    }

    final headers = ['LOCALISATION', 'COFFRET / ARMOIRE', 'NON-CONFORMITE - PRECONISATION', 'REF. NORMATIVE', 'PRIORITE'];

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(0.8),
      },
      children: [
        _tableHeaderRow(headers),
        ...obs.asMap().entries.map((e) {
          final o = e.value;
          PdfColor? rowColor;
          if (o.priorite == '3') {
            rowColor = PdfColor.fromInt(0xFFFFEEEE);
          } else if (o.priorite == '2') {
            rowColor = PdfColor.fromInt(0xFFFFF8EE);
          }
          else if (e.key.isOdd) {
            rowColor = tableRowAlt;
          }
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

  static pw.Widget _badgePriorite(String p, PdfColor color) {
    return pw.Container(
      width: 14, height: 14,
      decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
      alignment: pw.Alignment.center,
      child: pw.Text(p, style: pw.TextStyle(fontSize: fsSmall, fontWeight: pw.FontWeight.bold)),
    );
  }

  static List<pw.Widget> _buildZone(String nom, List<ObservationLibre> obs) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 8),
      pw.Container(
        width: double.infinity,
        color: headerColor,
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
          final conf = el.conforme != null ? 'Oui' : 'Non';
          final confColor = el.conforme != null ? conformeColor : nonConformeColor;
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

  static List<pw.Widget> _buildAuditContent(AuditInstallationsElectriques audit) {
    final widgets = <pw.Widget>[];
    
    for (var zone in audit.moyenneTensionZones) {
      widgets.addAll(_buildZone(zone.nom, zone.observationsLibres));
      for (var local in zone.locaux) {
        widgets.addAll(_buildLocalMT(local));
      }
      for (var coffret in zone.coffrets) {
        widgets.addAll(_buildCoffret(coffret));
      }
    }
    
    for (var local in audit.moyenneTensionLocaux) {
      widgets.addAll(_buildLocalMT(local));
    }
    
    for (var zone in audit.basseTensionZones) {
      widgets.addAll(_buildZone(zone.nom, zone.observationsLibres));
      for (var coffret in zone.coffretsDirects) {
        widgets.addAll(_buildCoffret(coffret));
      }
      for (var local in zone.locaux) {
        widgets.addAll(_buildLocalBT(local));
      }
    }
    
    return widgets;
  }

  static pw.Widget _buildInstallationTable(List<InstallationItem> items) {
    if (items.isEmpty) return pw.Container();
    final fields = <String>{};
    for (var it in items) {
      fields.addAll(it.data.keys);
    }
    final cols = fields.toList()..sort();
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.4),
      children: [
        _tableHeaderRow(cols),
        ...items.asMap().entries.map((e) =>
          _tableDataRow(cols.map((c) => e.value.data[c]?.toString() ?? '-').toList(), alt: e.key.isOdd)),
      ],
    );
  }

  static pw.Widget _buildCoverPage(Mission mission, RenseignementsGeneraux? rg, pw.Context ctx) {
    // Dates intervention depuis renseignements_generaux dateDebut/dateFin
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
        // Ligne haute: logo KES + "A l'attention de" (SANS bande bleue a droite)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (_logoKesImage != null)
              pw.Image(_logoKesImage!, width: 140, height: 80, fit: pw.BoxFit.contain)
            else
              pw.Text('KES INSPECTIONS AND PROJECTS',
                  style: pw.TextStyle(font: _fontBold, color: headerColor, fontSize: 10)),
            // "A l'attention de" : taille +2 (11pt), marges top/bottom augmentees
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
                  // Taille +2 par rapport a avant (11pt)
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

        // Deux lignes vides = descendre RAPPORT
        pw.SizedBox(height: 34),

        // Container RAPPORT
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

        // Espacement deux lignes apres RAPPORT
        pw.SizedBox(height: 28),

        // Sous-titre 1 - centrage parfait, taille -2 (16pt)
        pw.Container(
          width: double.infinity,
          child: pw.Text(
            'VERIFICATION PERIODIQUE REGLEMENTAIRE DES INSTALLATIONS ELECTRIQUES',
            style: pw.TextStyle(font: _fontRegular, fontSize: 16, color: accentColor),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 20),
        // Sous-titre 2 - centrage parfait, taille -2 (16pt)
        pw.Container(
          width: double.infinity,
          child: pw.Text(
            mission.nomClient.toUpperCase(),
            style: pw.TextStyle(font: _fontBold, fontSize: 16, fontWeight: pw.FontWeight.bold, color: accentColor),
            textAlign: pw.TextAlign.center,
          ),
        ),

        pw.SizedBox(height: 100),

        // Informations + QR Code
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
                  // Rapport N : statique pour l'instant
                  _coverInfoRow('Rapport N', 'KES/IP/VE/\${DateTime.now().year}/001'),
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
        // CORRECTION III: tableau habilitation supprime -> image.png pleine largeur
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

  static pw.Widget _buildHabilitationsTable() {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: 0.4),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SYMBOLES D\'HABILITATION ELECTRIQUE',
            style: pw.TextStyle(fontSize: fsH3, fontWeight: pw.FontWeight.bold, color: headerColor),
          ),
          pw.SizedBox(height: 4),
          _bodyText('B0 : Habilitation de base - Travaux hors tension'),
          _bodyText('BR : Habilitation de remplacement - Consignation'),
          _bodyText('BC : Habilitation de consignation'),
          _bodyText('BE : Habilitation d\'essai - Mesures'),
          _bodyText('BS : Habilitation de surveillance'),
          _bodyText('H0 : Habilitation hors tension pour non-electriciens'),
        ],
      ),
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
            // CORRECTION IV: "Registre de securite" supprime de cette liste
          ],
        ),
      ],
    );
  }

  static List<pw.Widget> _buildCelluleSection(Cellule cellule) {
    return [
      pw.SizedBox(height: 5),
      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: 0.4),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FlexColumnWidth(1.2),
          3: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: lightBlue),
            children: [
              _cell('CELLULE', isHeader: true, colspan: 4),
            ],
          ),
          _tableDataRow(['Fonction de la cellule', cellule.fonction, 'Type de cellule', cellule.type], alt: false),
          _tableDataRow(['Marque / modele / annee', cellule.marqueModeleAnnee, 'Tension assignee', cellule.tensionAssignee], alt: true),
          _tableDataRow(['Pouvoir de coupure assigne (kA)', cellule.pouvoirCoupure, 'Numerotation / reperage', cellule.numerotation], alt: false),
          _tableDataRow(['Parafoudres installes sur l\'arrivee', cellule.parafoudres, '', ''], alt: true),
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
          _tableDataRow(['Type de transformateur', transfo.typeTransformateur, 'Marque / Annee', transfo.marqueAnnee], alt: false),
          _tableDataRow(['Puissance assignee (kVA)', transfo.puissanceAssignee, 'Tension primaire / secondaire', transfo.tensionPrimaireSecondaire], alt: true),
          _tableDataRow(['Presence du relais Buchholz', transfo.relaisBuchholz, 'Type de refroidissement', transfo.typeRefroidissement], alt: false),
          _tableDataRow(['Regime du neutre', transfo.regimeNeutre, '', ''], alt: true),
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
  static pw.Widget _buildClassementEmplacements(List<ClassementEmplacement> classements) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeaderWidget(),
        pw.SizedBox(height: 10),
        _sectionBox('CLASSEMENT DES LOCAUX ET EMPLACEMENTS EN FONCTION DES INFLUENCES EXTERNES'),
        pw.SizedBox(height: 8),
        _bodyText(
          'Dans le cas d\'absence de fourniture d\'une liste exhaustive des risques particuliers, le classement eventuel ci-apres est propose par le verificateur et, sauf avis contraire, considere comme valide par le chef d\'etablissement.',
        ),
        pw.SizedBox(height: 12),
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
            _tableHeaderRow([
              'Localisation', 'Zone', 'Origine classement',
              'Influences externes', 'AF', 'BE', 'AE', 'AD', 'AG',
              'Indice mini de protection', 'IK'
            ]),
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
        pw.SizedBox(height: 16),
        _buildCodificationInfluences(),
      ],
    );
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
        _tableDataRow(['AE2 : Petits objets (≥ 2,5 mm) -> IP 3X', 'AF2 : Agents d\'origine atmospherique', 'BE2 : Risques d\'incendie'], alt: true),
        _tableDataRow(['AE3 : Tres petits objets (1 a 2,5 mm) -> IP 4X', 'AF3 : Intermittente ou accidentelle', 'BE3 : Risques d\'explosion'], alt: false),
        _tableDataRow(['AE4 : Poussieres -> IP 5X (Protege)', 'AF4 : Permanente', 'BE4 : Risques de contamination'], alt: true),
        _tableHeaderRow(['ACCES AUX PARTIES DANGEREUSES', 'PENETRATION DE LIQUIDES', 'RISQUES DE CHOCS MECANIQUES']),
        _tableDataRow(['Non protege -> IP 0X', 'AD1 : Negligeable -> IP X0', 'AG1 : Faibles (0,225 J) -> IK 02'], alt: false),
        _tableDataRow(['A : Avec le dos de la main -> IP 1X', 'AD2 : Chutes de gouttes d\'eau -> IP X1', 'AG2 : Moyens (2 J) -> IK 07'], alt: true),
        _tableDataRow(['B : Avec un doigt -> IP 2X', 'AD3 : Chutes de gouttes jusqu\'a 15° -> IP X2', 'AG3 : Importants (5 J) -> IK 08'], alt: false),
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
  // CORRECTION VII: Methode remplacant le widget unique par des pages separees
  static void _addMesuresEssaisPages(pw.Document pdf, MesuresEssais mesures) {
    // Page intro conditions
    pdf.addPage(pw.Page(
      pageTheme: _buildPageTheme(isFirstPage: false),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _buildPageHeaderWidget(),
        pw.SizedBox(height: 10),
        _sectionBox('RESULTATS DES MESURES ET ESSAIS'),
        pw.SizedBox(height: 8),
        _bodyBold("MESURES D'ISOLEMENT"),
        _bodyText("Les mesures d'isolement par rapport a la terre sont effectuees sous 500 V continu sur les canalisations en aval des DDR defectueux. La valeur est satisfaisante si superieure a 0,5 M.ohms."),
        pw.SizedBox(height: 5),
        _bodyBold('VERIFICATION DE LA CONTINUITE ET RESISTANCE DES CONDUCTEURS DE PROTECTION'),
        _bodyText('Correcte si la valeur mesuree satisfait aux prescriptions du guide UTE C 15-105 S D6.'),
        pw.SizedBox(height: 5),
        _bodyBold('ESSAIS DE DECLENCHEMENT DES DISPOSITIFS DIFFERENTIELS RESIDUELS'),
        _bodyText('La valeur du seuil de declenchement est correcte si elle est comprise entre 0,5 IAn et IAn.'),
        pw.SizedBox(height: 5),
        _bodyBold('MESURE DES IMPEDANCES DE BOUCLE (PROTECTION CONTACTS INDIRECTS)'),
        _bodyText('Correcte si le temps de coupure, pour le courant de defaut determine, satisfait aux prescriptions du guide UTE C 15-105.'),
      ]),
    ));
    // Page demarrage auto
    pdf.addPage(pw.Page(
      pageTheme: _buildPageTheme(isFirstPage: false),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _buildPageHeaderWidget(), pw.SizedBox(height: 10),
        _subSectionBar('Essais de demarrage automatique du groupe electrogene'),
        pw.SizedBox(height: 8),
        _resultBox(mesures.essaiDemarrageAuto.observation ?? 'Non satisfaisant'),
      ]),
    ));
    // Page arret urgence
    pdf.addPage(pw.Page(
      pageTheme: _buildPageTheme(isFirstPage: false),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _buildPageHeaderWidget(), pw.SizedBox(height: 10),
        _subSectionBar("Test de fonctionnement de l'arret d'urgence"),
        pw.SizedBox(height: 8),
        _resultBox(mesures.testArretUrgence.observation ?? 'Satisfaisant'),
      ]),
    ));
    // Page prise de terre
    pdf.addPage(pw.Page(
      pageTheme: _buildPageTheme(isFirstPage: false),
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
    // Page isolement
    pdf.addPage(pw.Page(
      pageTheme: _buildPageTheme(isFirstPage: false),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _buildPageHeaderWidget(), pw.SizedBox(height: 10),
        _subSectionBar("Mesures d'isolement des circuits BT"),
        pw.SizedBox(height: 8),
        _bodyText('Sans observation'),
      ]),
    ));
    // Page DDR
    pdf.addPage(pw.Page(
      pageTheme: _buildPageTheme(isFirstPage: false),
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
    // Page continuite
    pdf.addPage(pw.Page(
      pageTheme: _buildPageTheme(isFirstPage: false),
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

  // Page signature centree (avant photos)
  static pw.Widget _buildSignaturePage(RenseignementsGeneraux? rg, String? nomInspecteur) {
    return pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'Fait a Douala le ${_formatDate(DateTime.now())}',
            style: pw.TextStyle(font: _fontBold, fontSize: 16, fontWeight: pw.FontWeight.bold, color: headerColor),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            "Par: $nomInspecteur ",
            style: pw.TextStyle(font: _fontRegular, fontSize: 14, color: darkGrey),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMesuresEssais(MesuresEssais mesures) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPageHeaderWidget(),
        pw.SizedBox(height: 10),
        _sectionBox('RESULTATS DES MESURES ET ESSAIS'),
        pw.SizedBox(height: 8),
        
        _subSectionBar('Conditions de mesure'),
        pw.SizedBox(height: 5),
        _bodyBold('MESURES D\'ISOLEMENT'),
        _bodyText(
          'Les mesures d\'isolement par rapport a la terre sont effectuees sous 500 V continu sur les canalisations en aval des DDR defectueux ou sur les canalisations pour lesquelles il a ete constate une absence de DDR necessaire pour la protection des personnes (contacts indirects), '
          'sur les materiels amovibles hors tension, ou sur les recepteurs dont la liaison a la terre a ete jugee defectueuse. La valeur est consideree comme satisfaisante si elle est superieure a 0,5 M.ohms.',
        ),
        pw.SizedBox(height: 5),
        _bodyBold('VERIFICATION DE LA CONTINUITE ET DE LA RESISTANCE DES CONDUCTEURS DE PROTECTION ET DES LIAISONS EQUIPOTENTIELLES'),
        _bodyText(
          'La verification de la continuite des conducteurs de protection est effectuee a l\'aide d\'un ohmmetre ou d\'un milliohmmetre. Elle est correcte si la valeur mesuree satisfait aux prescriptions du guide UTE C 15-105 § D6.',
        ),
        pw.SizedBox(height: 5),
        _bodyBold('ESSAIS DE DECLENCHEMENT DES DISPOSITIFS DIFFERENTIELS RESIDUELS'),
        _bodyText(
          'La valeur du seuil de declenchement est correcte si elle est comprise entre 0,5 IAn et IAn (An : sensibilite du dispositif differentiel). Les essais sont realises entre une phase et la terre. '
          'En cas de manque de selectivite, les essais sont realises entre le neutre ou une phase amont et une autre phase en aval.',
        ),
        pw.SizedBox(height: 5),
        _bodyBold('MESURE DES IMPEDANCES DE BOUCLE (PROTECTION « CONTACTS INDIRECTS »)'),
        _bodyText(
          'Cette mesure est effectuee si necessaire a l\'aide d\'un milliohmmetre de boucle. Le dispositif de protection est correct si son temps de coupure, pour le courant de defaut determine, satisfait aux prescriptions du guide UTE C 15-105.',
        ),

        if (mesures.conditionMesure.observation != null && mesures.conditionMesure.observation!.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          _bodyText(mesures.conditionMesure.observation!),
        ],
        pw.SizedBox(height: 16),
        
        _subSectionBar('Essais de demarrage automatique du groupe electrogene'),
        pw.SizedBox(height: 5),
        _resultBox(mesures.essaiDemarrageAuto.observation ?? 'Non satisfaisant'),
        pw.SizedBox(height: 16),
        
        _subSectionBar('Test de fonctionnement de l\'arret d\'urgence'),
        pw.SizedBox(height: 5),
        _resultBox(mesures.testArretUrgence.observation ?? 'Satisfaisant'),
        pw.SizedBox(height: 16),
        
        _subSectionBar('Prise de terre'),
        pw.SizedBox(height: 5),
        _bodyText('Non satisfaisant'),
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
            _tableHeaderRow([
              'Localisation', 'Identification de la prise de terre',
              'Condition de mesure', 'Nature de la prise de terre',
              'Methode de mesure', 'Valeur de la mesure', 'Observation'
            ]),
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
        
        if (mesures.avisMesuresTerre.observation != null && mesures.avisMesuresTerre.observation!.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          if (mesures.avisMesuresTerre.satisfaisants.isNotEmpty)
            _bodyText('Prises de terre satisfaisantes : ${mesures.avisMesuresTerre.satisfaisants.join(', ')}'),
          if (mesures.avisMesuresTerre.nonSatisfaisants.isNotEmpty)
            _bodyText('Prises de terre non satisfaisantes : ${mesures.avisMesuresTerre.nonSatisfaisants.join(', ')}'),
          pw.SizedBox(height: 3),
          _bodyText(mesures.avisMesuresTerre.observation!),
        ],
        pw.SizedBox(height: 16),
        
        _subSectionBar('Mesures d\'isolement des circuits BT'),
        pw.SizedBox(height: 5),
        _bodyText('Sans observation'),
        pw.SizedBox(height: 16),
        
        _subSectionBar('Essais de declenchement des dispositifs differentiels'),
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
            _tableHeaderRow([
              'Quantite', 'Designation circuit', 'Type de dispositif',
              'Reglage In (mA)', 'Tempo (s)', 'Essai', 'Isolement (M ampe)'
            ]),
            if (mesures.essaisDeclenchement.isEmpty)
              pw.TableRow(children: List.generate(7, (_) => _cell('', isHeader: false)))
            else
              ...mesures.essaisDeclenchement.asMap().entries.map((e) {
                final es = e.value;
                final essaiColor = es.essai == 'B' || es.essai == 'OK'
                    ? conformeColor
                    : (es.essai == 'M' || es.essai == 'NON OK' ? nonConformeColor : null);
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: e.key.isOdd ? tableRowAlt : PdfColors.white),
                  children: [
                    _cell(es.localisation, isHeader: false),
                    _cell('${es.coffret ?? ''} / ${es.designationCircuit ?? ''}', isHeader: false),
                    _cell(es.typeDispositif, isHeader: false),
                    _cell(es.reglageIAn?.toString() ?? '-', isHeader: false),
                    _cell(es.tempo?.toString() ?? '-', isHeader: false),
                    pw.Container(
                      color: essaiColor,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      alignment: pw.Alignment.center,
                      child: pw.Text(es.essai, style: pw.TextStyle(fontSize: fsSmall)),
                    ),
                    _cell(es.isolement?.toString() ?? '-', isHeader: false),
                  ],
                );
              }),
          ],
        ),
        
        pw.SizedBox(height: 16),
        _buildAbreviationsTable(),
        pw.SizedBox(height: 16),
        
        _subSectionBar('Continuite et de la resistance des conducteurs de protection et des liaisons equipotentielles'),
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
            _tableHeaderRow([
              'Localisation', 'Designation Tableau / Equipement',
              'Origine Mesure', 'Observation'
            ]),
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
  //  PHOTOS
  // ──────────────────────────────────────────────────────────────
  static Future<void> _addPhotosSection(
      pw.Document pdf, Mission mission, String missionId,
      AuditInstallationsElectriques? audit) async {
    final allPhotos = <_PhotoEntry>[];

    if (audit != null) {
      for (var local in audit.moyenneTensionLocaux) {
        _addPhotosFromList(allPhotos, local.photos, local.nom);
        if (local.cellule != null) _addPhotosFromList(allPhotos, local.cellule!.photos, '${local.nom} - Cellule');
        if (local.transformateur != null) _addPhotosFromList(allPhotos, local.transformateur!.photos, '${local.nom} - Transformateur');
        for (var c in local.coffrets) {
          _addPhotosFromList(allPhotos, c.photos, '${local.nom} - ${c.nom}');
        }
      }
      for (var zone in audit.moyenneTensionZones) {
        _addPhotosFromList(allPhotos, zone.photos, zone.nom);
        for (var c in zone.coffrets) {
          _addPhotosFromList(allPhotos, c.photos, '${zone.nom} - ${c.nom}');
        }
        for (var local in zone.locaux) {
          _addPhotosFromList(allPhotos, local.photos, '${zone.nom} - ${local.nom}');
          for (var c in local.coffrets) {
            _addPhotosFromList(allPhotos, c.photos, '${zone.nom} - ${local.nom} - ${c.nom}');
          }
        }
      }
      for (var zone in audit.basseTensionZones) {
        _addPhotosFromList(allPhotos, zone.photos, zone.nom);
        for (var c in zone.coffretsDirects) {
          _addPhotosFromList(allPhotos, c.photos, '${zone.nom} - ${c.nom}');
        }
        for (var local in zone.locaux) {
          _addPhotosFromList(allPhotos, local.photos, '${zone.nom} - ${local.nom}');
          for (var c in local.coffrets) {
            _addPhotosFromList(allPhotos, c.photos, '${zone.nom} - ${local.nom} - ${c.nom}');
          }
        }
      }
    }

    // Page liste des photos
    pdf.addPage(
      pw.Page(
        pageTheme: _buildPageTheme(isFirstPage: false),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildPageHeader(mission),
            pw.SizedBox(height: 10),
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
                  2: const pw.FlexColumnWidth(3),
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
      ),
    );

    // Pages individuelles de photos
    for (int i = 0; i < allPhotos.length; i++) {
      final entry = allPhotos[i];
      try {
        final file = File(entry.filePath);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        final img = pw.MemoryImage(bytes);
        pdf.addPage(
          pw.Page(
            pageTheme: _buildPageTheme(isFirstPage: false),
            build: (ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                _buildPageHeader(mission),
                pw.SizedBox(height: 8),
                pw.Text('Photo ${i + 1} / ${allPhotos.length}',
                    style: pw.TextStyle(fontSize: fsH2, fontWeight: pw.FontWeight.bold, color: headerColor)),
                pw.SizedBox(height: 3),
                pw.Text(entry.description,
                    style: pw.TextStyle(fontSize: fsBody, color: darkGrey)),
                pw.SizedBox(height: 3),
                pw.Text(path.basename(entry.filePath),
                    style: pw.TextStyle(fontSize: fsSmall, color: PdfColors.grey)),
                pw.SizedBox(height: 10),
                pw.Expanded(
                  child: pw.Container(
                    alignment: pw.Alignment.center,
                    child: pw.Image(img, fit: pw.BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erreur photo ${entry.filePath}: $e');
        }
      }
    }
  }

  static void _addPhotosFromList(List<_PhotoEntry> list, List<String> photos, String description) {
    for (var p in photos) {
      if (p.isNotEmpty) list.add(_PhotoEntry(filePath: p, description: description));
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  UTILITAIRES PDF (cellules, lignes, titres...)
  // ──────────────────────────────────────────────────────────────
  static pw.Widget _sectionBox(String title) {
    return pw.Container(
      width: double.infinity,
      color: headerColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: fsH1, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _subTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 5, bottom: 3),
      child: pw.Text(
        title,
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
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: fsBody, color: darkGrey, lineSpacing: 1.4)),
    );
  }

  static pw.Widget _bodyBold(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: fsBody, fontWeight: pw.FontWeight.bold, color: darkGrey)),
    );
  }

  static pw.Widget _bulletItem(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('-  ', style: pw.TextStyle(fontSize: fsBody, color: accentColor)),
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
        text,
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
class _SommaireEntry {
  final String titre;
  final int page;
  _SommaireEntry(this.titre, this.page);
}