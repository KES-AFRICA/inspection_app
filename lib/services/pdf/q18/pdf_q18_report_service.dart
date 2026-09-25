// lib/services/pdf/q18/pdf_q18_report_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/cancellation_token.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';
import 'package:inspec_app/services/pdf/builders/pdf_cover_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_conclusion_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_dangers_synthesis_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_identification_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_perimetre_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_photos_builder.dart';
import 'package:inspec_app/services/pdf/q18/builders/q18_regulatory_builder.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_collector.dart';
import 'package:inspec_app/services/pdf/q18/q18_data_snapshot.dart';

typedef PdfProgressCallback = void Function(double progress, String statusMessage);

/// Service orchestrateur de production et génération du Rapport Q18 (APSAD D18).
///
/// Implémente la mise en page conforme à la charte KES, la pagination absolue en 2 passes
/// et le respect scrupuleux des 16 sections réglementaires du Traité APSAD D18.
class PdfQ18ReportService {
  /// Génère le nom de fichier officiel pour le rapport Q18
  static String buildQ18ReportFileName(Mission mission) {
    final client = mission.nomClient.trim().isNotEmpty
        ? _sanitizeFileName(mission.nomClient.trim())
        : 'Client';
    final site = (mission.nomSite != null && mission.nomSite!.trim().isNotEmpty)
        ? _sanitizeFileName(mission.nomSite!.trim())
        : 'Site';
    final annee = (mission.dateIntervention != null)
        ? mission.dateIntervention!.year
        : DateTime.now().year;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'Rapport_Q18_${client}_${site}_${annee}_$timestamp.pdf';
  }

  static String _sanitizeFileName(String text) {
    var s = text.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    s = s.replaceAll(' ', '_');
    return s.replaceAll(RegExp(r'_+'), '_');
  }

  /// Génère le document complet du Rapport Q18 pour une mission donnée.
  static Future<File> generateMissionReport(
    String missionId, {
    Directory? outputDir,
    PdfProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    onProgress?.call(0.05, 'Initialisation des données de la mission...');

    final mission = HiveService.getMissionById(missionId);
    if (mission == null) {
      throw Exception('Mission introuvable pour l\'id : $missionId');
    }

    // 1. Collecte pure et snapshot certifié
    onProgress?.call(0.15, 'Collecte et classification des dangers Q18...');
    final data = Q18DataCollector.collect(missionId);

    // 2. Chargement des polices et assets graphiques
    onProgress?.call(0.25, 'Chargement de la typographie et des ressources...');
    final fonts = await _loadFonts();
    PdfReportStyles.fontRegular = fonts.regular;
    PdfReportStyles.fontBold = fonts.bold;
    final assets = await _loadAssets();

    // 3. Passe 1 : Calcul de la pagination exacte (nombre total de pages)
    onProgress?.call(0.40, 'Mise en page préliminaire (Passe 1)...');
    final pass1Doc = _buildDocument(
      data: data,
      fonts: fonts,
      assets: assets,
      overrideTotalPages: null,
    );
    await pass1Doc.save();
    cancellationToken?.throwIfCancelled();

    final totalPages = pass1Doc.document.pdfPageList.pages.length;

    // 4. Passe 2 : Rendu final avec numérotation absolue (Page X / N)
    onProgress?.call(0.70, 'Génération du livrable définitif (Passe 2 : $totalPages pages)...');
    final pass2Doc = _buildDocument(
      data: data,
      fonts: fonts,
      assets: assets,
      overrideTotalPages: totalPages,
    );
    final finalPdfBytes = await pass2Doc.save();
    cancellationToken?.throwIfCancelled();

    // 5. Sauvegarde sur le disque
    onProgress?.call(0.90, 'Écriture du fichier PDF certifié...');
    final dir = outputDir ?? await getApplicationDocumentsDirectory();
    final fileName = buildQ18ReportFileName(mission);
    final outputFile = File(path.join(dir.path, fileName));
    await outputFile.writeAsBytes(finalPdfBytes, flush: true);

    onProgress?.call(1.0, 'Rapport Q18 finalisé avec succès ($totalPages pages).');
    return outputFile;
  }

  static pw.Document _buildDocument({
    required Q18DataSnapshot data,
    required ({pw.Font regular, pw.Font bold}) fonts,
    required ({pw.MemoryImage? logoKes, pw.MemoryImage? watermark}) assets,
    required int? overrideTotalPages,
  }) {
    final pdf = pw.Document(
      title: 'Rapport Q18 - ${data.mission.nomClient}',
      author: 'KES INSPECTIONS AND PROJECTS',
      creator: 'KES Inspection App',
    );

    // ── PAGE DE COUVERTURE ──
    pdf.addPage(
      pw.Page(
        pageTheme: PdfReportStyles.buildCoverPageTheme(
          fonts.regular,
          fonts.bold,
          watermarkImage: assets.watermark,
        ),
        build: (ctx) => _buildCoverPage(
          data: data,
          logoKesImage: assets.logoKes,
          fontBold: fonts.bold,
          fontRegular: fonts.regular,
        ),
      ),
    );

    // ── CORPS DU RAPPORT (SECTIONS 1 À 16) ──
    final innerPageTheme = PdfReportStyles.buildInnerPageTheme(
      fontRegular: fonts.regular,
      fontBold: fonts.bold,
      watermarkImage: assets.watermark,
      overrideTotalPages: overrideTotalPages,
      showWatermark: true,
    );

    pdf.addPage(
      pw.MultiPage(
        maxPages: 10000,
        pageTheme: innerPageTheme,
        header: (ctx) => PdfReportStyles.buildPageHeaderWidget(
          logoKesImage: assets.logoKes,
          fontRegular: fonts.regular,
          fontBold: fonts.bold,
          nomClient: data.mission.nomClient,
          nomSite: data.mission.nomSite,
          numeroRapport: data.numeroRapportQ18,
          titreRapport: 'RAPPORT Q18 - VÉRIFICATION DES INSTALLATIONS ÉLECTRIQUES (APSAD D18)',
        ),
        build: (ctx) {
          final widgets = <pw.Widget>[];

          // Section 1 : Identification de la mission
          widgets.addAll(
            Q18IdentificationBuilder.buildSection1Identification(
              data,
              fontBold: fonts.bold,
              fontRegular: fonts.regular,
            ),
          );

          widgets.add(pw.NewPage());

          // Section 2 : Objet et cadre de la mission
          widgets.addAll(
            Q18RegulatoryBuilder.buildSection2ObjetCadre(
              fontBold: fonts.bold,
              fontRegular: fonts.regular,
            ),
          );

          // Section 3 : Cadre réglementaire et normatif
          widgets.addAll(
            Q18RegulatoryBuilder.buildSection3CadreReglementaire(
              fontBold: fonts.bold,
              fontRegular: fonts.regular,
            ),
          );

          widgets.add(pw.NewPage());

          // Section 4 : Présentation du site et des installations
          widgets.addAll(
            Q18IdentificationBuilder.buildSection4Presentation(
              data,
              fontBold: fonts.bold,
              fontRegular: fonts.regular,
            ),
          );

          widgets.add(pw.NewPage());

          // Section 5 : Périmètre de la vérification et exclusions
          widgets.addAll(
            Q18PerimetreBuilder.buildSection5Perimetre(
              data,
              fontBold: fonts.bold,
              fontRegular: fonts.regular,
            ),
          );

          // Section 6 : Documents et éléments consultés
          widgets.addAll(
            Q18PerimetreBuilder.buildSection6DocumentsConsultes(
              data,
              fontBold: fonts.bold,
              fontRegular: fonts.regular,
            ),
          );

          widgets.add(pw.NewPage());

          // Section 7 : Méthodologie et points de contrôle
          widgets.addAll(
            Q18RegulatoryBuilder.buildSection7Methodologie(
              fontBold: fonts.bold,
              fontRegular: fonts.regular,
            ),
          );

          // Section 8 : Échelle de classification des dangers
          widgets.addAll(
            Q18RegulatoryBuilder.buildSection8ClassificationDangers(
              fontBold: fonts.bold,
              fontRegular: fonts.regular,
            ),
          );

          // Section 9 : Typologie des dangers les plus courants
          widgets.addAll(
            Q18RegulatoryBuilder.buildSection9TypologieDangers(
              fontBold: fonts.bold,
              fontRegular: fonts.regular,
            ),
          );

          widgets.add(pw.NewPage());

          // Section 10 : Synthèse des dangers constatés
          widgets.addAll(
            Q18DangersSynthesisBuilder.buildSection10Dangers(
              data,
              fontBold: fonts.bold,
              fontRegular: fonts.regular,
            ),
          );

          // Section 11 : Récapitulatif statistique
          widgets.addAll(
            Q18DangersSynthesisBuilder.buildSection11Statistiques(
              data,
              fontBold: fonts.bold,
              fontRegular: fonts.regular,
            ),
          );

          widgets.add(pw.NewPage());

          // Section 12 : Avis global et conclusion
          widgets.addAll(
            Q18ConclusionBuilder.buildSection12AvisGlobal(
              data,
              fontBold: fonts.bold,
              fontRegular: fonts.regular,
            ),
          );

          // Section 13 : Compte rendu de levée des dangers
          widgets.addAll(
            Q18ConclusionBuilder.buildSection13LeveeDangers(
              fontBold: fonts.bold,
              fontRegular: fonts.regular,
            ),
          );

          // Section 14 : Prochaine échéance
          widgets.addAll(
            Q18ConclusionBuilder.buildSection14ProchaineEcheance(
              data,
              fontBold: fonts.bold,
              fontRegular: fonts.regular,
            ),
          );

          // Section 15 : Signature du vérificateur
          widgets.addAll(
            Q18ConclusionBuilder.buildSection15Signature(
              data,
              fontBold: fonts.bold,
              fontRegular: fonts.regular,
            ),
          );

          // Section 16 : Planche photographique
          if (data.photoEntries.isNotEmpty) {
            widgets.add(pw.NewPage());
            widgets.addAll(
              Q18PhotosBuilder.buildSection16Photos(
                data.photoEntries,
                fontBold: fonts.bold,
                fontRegular: fonts.regular,
              ),
            );
          }

          return widgets;
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildCoverPage({
    required Q18DataSnapshot data,
    required pw.MemoryImage? logoKesImage,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    final mission = data.mission;
    final rg = data.renseignements;

    final clientName = mission.nomClient.trim().isNotEmpty
        ? mission.nomClient.trim().toUpperCase()
        : 'CLIENT';
    final siteName = (mission.nomSite != null && mission.nomSite!.trim().isNotEmpty)
        ? mission.nomSite!.trim().toUpperCase()
        : (rg != null && rg.nomSite.trim().isNotEmpty ? rg.nomSite.trim().toUpperCase() : clientName);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── En-tête supérieur : Logo KES (gauche) & Référence Q18 (droite) ──
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoKesImage != null)
              pw.Image(
                logoKesImage,
                width: 170,
                height: 62,
                fit: pw.BoxFit.contain,
              )
            else
              pw.Text(
                'KES INSPECTIONS & PROJECTS',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12,
                  color: PdfReportStyles.headerColor,
                ),
              ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'COMPTE-RENDU Q18',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: PdfReportStyles.accentColor,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'N° : ${data.numeroRapportQ18}',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 7.5,
                    color: PdfReportStyles.darkGrey,
                  ),
                ),
              ],
            ),
          ],
        ),

        pw.Spacer(flex: 1),

        // ── Titre principal : Centré au cœur de la loupe du filigrane, en AccentColor ──
        pw.Center(
          child: pw.ConstrainedBox(
            constraints: const pw.BoxConstraints(maxWidth: 450),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'RAPPORT Q18',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 24,
                    color: PdfReportStyles.accentColor,
                    letterSpacing: 1.0,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 14),
                pw.Text(
                  'Compte rendu de vérification des installations électriques',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 14,
                    color: PdfReportStyles.accentColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Établi selon le référentiel APSAD D18 (prévention des risques d\'incendie et d\'explosion), à la suite de la mission de vérification de conformité des installations électriques',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 10,
                    color: PdfReportStyles.accentColor,
                    lineSpacing: 1.5,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        pw.Spacer(flex: 1),

        // ── Bloc inférieur : Tableau d'identification de l'établissement audité en bas juste en haut du pied de page ──
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: pw.FlexColumnWidth(1.2),
            1: pw.FlexColumnWidth(1.0),
            2: pw.FlexColumnWidth(1.0),
          },
          children: [
            // Ligne d'en-tête (en accentColor)
            pw.TableRow(
              children: [
                _buildCoverTableHeaderCell('ÉTABLISSEMENT AUDITÉ', fontBold: fontBold),
                _buildCoverTableHeaderCell('SITE', fontBold: fontBold),
                _buildCoverTableHeaderCell('LOCALISATION', fontBold: fontBold),
              ],
            ),
            // Ligne des données (en accentColor)
            pw.TableRow(
              children: [
                _buildCoverTableDataCell(
                  clientName,
                  fontBold: fontBold,
                  fontRegular: fontRegular,
                  isBold: true,
                ),
                _buildCoverTableDataCell(
                  siteName,
                  fontBold: fontBold,
                  fontRegular: fontRegular,
                  isBold: true,
                ),
                _buildCoverTableDataCell(
                  data.lieuIntervention.isNotEmpty ? data.lieuIntervention : siteName,
                  fontBold: fontBold,
                  fontRegular: fontRegular,
                  isBold: false,
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 25),
      ],
    );
  }

  static pw.Widget _buildCoverTableHeaderCell(
    String text, {
    required pw.Font fontBold,
    double height = 24.0,
  }) {
    return pw.Container(
      height: height,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: 8.0,
          color: PdfReportStyles.accentColor,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildCoverTableDataCell(
    String text, {
    required pw.Font fontBold,
    required pw.Font fontRegular,
    bool isBold = false,
    double height = 46.0,
    double fontSize = 8.5,
  }) {
    return pw.Container(
      height: height,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isBold ? fontBold : fontRegular,
          fontSize: fontSize,
          color: PdfReportStyles.accentColor,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static Future<({pw.Font regular, pw.Font bold})> _loadFonts() async {
    try {
      final regData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      return (
        regular: pw.Font.ttf(regData),
        bold: pw.Font.ttf(boldData),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Fallback sur polices système PDF pour le rapport Q18: $e');
      }
      return (
        regular: PdfReportStyles.fontRegular,
        bold: PdfReportStyles.fontBold,
      );
    }
  }

  static Future<({pw.MemoryImage? logoKes, pw.MemoryImage? watermark})> _loadAssets() async {
    pw.MemoryImage? logoKes;
    pw.MemoryImage? watermark;

    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      if (logoBytes.lengthInBytes > 0) {
        logoKes = pw.MemoryImage(logoBytes.buffer.asUint8List());
      }
    } catch (_) {}

    logoKes ??= PdfReportService.logoKesImage ?? PdfCoverBuilder.logoKesImage;

    try {
      final wmBytes = await rootBundle.load('assets/images/filigranne_image.png');
      if (wmBytes.lengthInBytes > 0) {
        watermark = pw.MemoryImage(wmBytes.buffer.asUint8List());
      }
    } catch (_) {}

    return (logoKes: logoKes, watermark: watermark);
  }
}
