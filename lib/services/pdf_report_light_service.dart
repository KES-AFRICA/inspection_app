import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:inspec_app/models/lighting_inspection.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/pdf_report_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Service dédié à la génération du rapport PDF de Vérification des Installations d'Éclairage
class PdfReportLightService {
  /// Intitulé du numéro de rapport pour l'Éclairage
  static const String numeroRapportDoc = 'KES/IP/VECL/2025/001';

  /// 12 Questions standard d'éclairage
  static const List<String> questionsText = [
    '1. État général du luminaire',
    '2. Fixation correcte et stable',
    '3. Protection contre les contacts directs',
    '4. Absence d\'échauffement ou de brûlure',
    '5. Absence de corrosion ou d\'encrassement',
    '6. Indice IP adapté au local',
    '7. Conducteurs correctement raccordés',
    '8. Présence de la mise à la terre',
    '9. Allumage correct',
    '10. Extinction correcte',
    '11. Absence de scintillement',
    '12. Accessibilité pour la maintenance',
  ];

  /// Génère le document PDF complet pour la mission d'éclairage spécifiée
  static Future<File?> generateLightingMissionReport(String missionId) async {
    try {
      await PdfReportService.loadImages();
      await PdfReportService.loadFonts();

      final mission = HiveService.getMissionById(missionId);
      if (mission == null) return null;

      final renseignements =
          HiveService.getRenseignementsGenerauxByMissionId(missionId);
      final inspections =
          HiveService.getLightingInspectionsByMissionId(missionId);

      final nomSiteHeader = renseignements?.nomSite.isNotEmpty == true
          ? renseignements!.nomSite
          : (mission.nomSite ?? '');

      final trackedPages = <String, int>{};
      final sommaireEntries = <SommaireEntry>[
        SommaireEntry(
          titre: "RENSEIGNEMENTS GENERAUX DE L'ETABLISSEMENT",
          key: 'renseignements',
          level: 0,
          isBold: true,
          isUppercase: true,
        ),
        SommaireEntry(
          titre: "Renseignements principaux",
          key: 'renseignements_principaux',
          level: 1,
        ),
        SommaireEntry(
          titre: "AUDIT DES INSTALLATIONS D'ECLAIRAGE",
          key: 'audit_eclairage',
          level: 0,
          isBold: true,
          isUppercase: true,
        ),
        SommaireEntry(
          titre: "PHOTOGRAPHIES",
          key: 'photos_eclairage',
          level: 0,
          isBold: true,
          isUppercase: true,
        ),
      ];

      final pdf = pw.Document(
        title: 'Rapport d\'Audit Éclairage - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: true,
      );

      // 1. PAGE DE COUVERTURE
      pdf.addPage(
        pw.Page(
          pageTheme: PdfReportService.buildCoverPageTheme(),
          build: (ctx) => PdfReportService.buildCoverPage(
            mission,
            renseignements,
            ctx,
            subTitleOverride: "DES INSTALLATIONS D'ECLAIRAGE",
          ),
        ),
      );

      // 2. SOMMAIRE DYNAMIQUE
      PdfReportService.addSommairePages(
        pdf,
        sommaireEntries,
        trackedPages,
        nomClient: mission.nomClient,
        nomSite: nomSiteHeader,
        numeroRapport: numeroRapportDoc,
      );

      // 3. RENSEIGNEMENTS GÉNÉRAUX (RENSEIGNEMENTS PRINCIPAUX UNIQUEMENT)
      pdf.addPage(
        pw.MultiPage(
          maxPages: 5,
          pageTheme: PdfReportService.buildInnerPageTheme(),
          header: (ctx) => PdfReportService.buildPageHeaderWidget(
            nomClient: mission.nomClient,
            nomSite: nomSiteHeader,
            numeroRapport: numeroRapportDoc,
          ),
          build: (ctx) => [
            PageTracker(
              key: 'renseignements',
              registry: trackedPages,
              child: PdfReportService.sectionBox(
                  'RENSEIGNEMENTS G\u00c9N\u00c9RAUX DE L\'\u00c9TABLISSEMENT'),
            ),
            pw.SizedBox(height: 14),
            PageTracker(
              key: 'renseignements_principaux',
              registry: trackedPages,
              child: PdfReportService.subTitle('Renseignements principaux'),
            ),
            pw.SizedBox(height: 8),
            _buildGeneralInfoTable(mission, renseignements),
          ],
        ),
      );

      // 4. AUDIT DES INSTALLATIONS D'ÉCLAIRAGE (TABLEAUX DE SYNTHÈSE PAR LOCAL, SANS PHOTOS)
      pdf.addPage(
        pw.MultiPage(
          maxPages: 100,
          pageTheme: PdfReportService.buildInnerPageTheme(),
          header: (ctx) => PdfReportService.buildPageHeaderWidget(
            nomClient: mission.nomClient,
            nomSite: nomSiteHeader,
            numeroRapport: numeroRapportDoc,
          ),
          build: (ctx) => [
            PageTracker(
              key: 'audit_eclairage',
              registry: trackedPages,
              child: PdfReportService.sectionBox('AUDIT DES INSTALLATIONS D\'ECLAIRAGE'),
            ),
            pw.SizedBox(height: 14),
            if (inspections.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text(
                  'Aucune inspection d\'\u00e9clairage r\u00e9alis\u00e9e pour cette mission.',
                  style: pw.TextStyle(
                      font: PdfReportService.fontRegular,
                      fontSize: 10,
                      color: PdfColors.grey700),
                ),
              )
            else
              for (final insp in inspections) ...[
                _buildLightingInspectionTable(insp),
                pw.SizedBox(height: 16),
              ],
          ],
        ),
      );

      // 5. PHOTOGRAPHIES DÉDIÉES AUX DÉFAILLANCES D'ÉCLAIRAGE
      pdf.addPage(
        pw.MultiPage(
          maxPages: 100,
          pageTheme: PdfReportService.buildInnerPageTheme(),
          header: (ctx) => PdfReportService.buildPageHeaderWidget(
            nomClient: mission.nomClient,
            nomSite: nomSiteHeader,
            numeroRapport: numeroRapportDoc,
          ),
          build: (ctx) => [
            PageTracker(
              key: 'photos_eclairage',
              registry: trackedPages,
              child: PdfReportService.sectionBox('PHOTOGRAPHIES'),
            ),
            pw.SizedBox(height: 14),
            ..._buildLightingPhotosList(inspections),
          ],
        ),
      );

      final outputDir = await getApplicationDocumentsDirectory();
      final sanitizedClient =
          mission.nomClient.replaceAll(RegExp(r'[^\w]'), '_');
      final file = File(
          '${outputDir.path}/Rapport_Eclairage_${sanitizedClient}_${mission.id}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la generation du rapport eclairage: $e');
      }
      return null;
    }
  }

  /// Tableau des Renseignements Principaux (Établissement, Adresse, Site, Vérificateurs)
  static pw.Widget _buildGeneralInfoTable(
      Mission mission, RenseignementsGeneraux? rg) {
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
            : 'Non renseigné');

    final etab = rg?.etablissement.isNotEmpty == true
        ? rg!.etablissement
        : mission.nomClient;
    final adresse = mission.adresseClient?.isNotEmpty == true
        ? mission.adresseClient!
        : 'Non renseignée';
    final site = rg?.nomSite.isNotEmpty == true
        ? rg!.nomSite
        : (mission.nomSite ?? 'Non renseigné');

    final rows = <pw.TableRow>[
      PdfReportService.tableHeaderRow(
          ['RENSEIGNEMENT', 'INFORMATIONS DE L\'\u00c9TABLISSEMENT']),
      PdfReportService.tableDataRow(['Établissement vérifié', etab], alt: false),
      PdfReportService.tableDataRow(['Adresse', adresse], alt: true),
      PdfReportService.tableDataRow(['Nom du site', site], alt: false),
      PdfReportService.tableDataRow(['Vérificateur(s)', verificateursNoms], alt: true),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfReportService.borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(4.5),
      },
      children: rows,
    );
  }

  /// Tableau synthétique d'une inspection d'éclairage
  static pw.Widget _buildLightingInspectionTable(
      LightingInspection inspection) {
    final isConforme = inspection.nbLuminairesNonConformes == 0;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête du Local
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: PdfReportService.headerColor,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    'LOCAL / B\u00c2TIMENT : ${inspection.batimentLocal.toUpperCase()}',
                    style: pw.TextStyle(
                      font: PdfReportService.fontBold,
                      fontSize: 11,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: isConforme ? PdfColors.green700 : PdfColors.red700,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Text(
                    inspection.status.toUpperCase(),
                    style: pw.TextStyle(
                      font: PdfReportService.fontBold,
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Métadonnées du local
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            color: PdfColors.grey100,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Type de luminaire : ${inspection.typeLuminaire}',
                  style: pw.TextStyle(font: PdfReportService.fontBold, fontSize: 9),
                ),
                pw.Text(
                  'Conformes : ${inspection.nbLuminairesConformes}  |  Non conformes : ${inspection.nbLuminairesNonConformes}',
                  style: pw.TextStyle(font: PdfReportService.fontBold, fontSize: 9),
                ),
              ],
            ),
          ),
          // Liste des luminaires non conformes et leurs défaillances
          if (inspection.nonConformingLuminaires.isNotEmpty) ...[
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'D\u00c9TAIL DES LUMINAIRES NON CONFORMES :',
                style: pw.TextStyle(
                  font: PdfReportService.fontBold,
                  fontSize: 9,
                  color: PdfReportService.headerColor,
                ),
              ),
            ),
            for (int index = 0;
                index < inspection.nonConformingLuminaires.length;
                index++) ...[
              () {
                final lum = inspection.nonConformingLuminaires[index];
                final repere = '#${(index + 1).toString().padLeft(4, '0')}';
                final nonConformAnswers =
                    lum.answers.where((a) => !a.isConform).toList();

                return pw.Container(
                  margin: const pw.EdgeInsets.fromLTRB(8, 0, 8, 8),
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red300, width: 0.8),
                    color: PdfColors.red50,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Luminaire $repere (${nonConformAnswers.length} point(s) non conforme(s))',
                        style: pw.TextStyle(
                          font: PdfReportService.fontBold,
                          fontSize: 9,
                          color: PdfColors.red900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      for (final ans in nonConformAnswers) ...[
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 6, bottom: 2),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('• ',
                                  style: pw.TextStyle(
                                      font: PdfReportService.fontBold,
                                      fontSize: 8,
                                      color: PdfColors.red800)),
                              pw.Expanded(
                                child: pw.RichText(
                                  text: pw.TextSpan(
                                    children: [
                                      pw.TextSpan(
                                        text:
                                            '${questionsText[ans.questionIndex - 1]} : ',
                                        style: pw.TextStyle(
                                          font: PdfReportService.fontBold,
                                          fontSize: 8,
                                          color: PdfColors.red800,
                                        ),
                                      ),
                                      pw.TextSpan(
                                        text: (ans.commentaire != null &&
                                                ans.commentaire!.trim().isNotEmpty)
                                            ? ans.commentaire
                                            : 'Non conforme sans observation',
                                        style: pw.TextStyle(
                                          font: PdfReportService.fontRegular,
                                          fontSize: 8,
                                          color: PdfColors.grey900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }(),
            ],
          ] else
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Aucune défaillance constatée sur les luminaires de ce local.',
                style: pw.TextStyle(
                  font: PdfReportService.fontRegular,
                  fontSize: 9,
                  color: PdfColors.green800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Galerie photos des défaillances éclairage
  static List<pw.Widget> _buildLightingPhotosList(
      List<LightingInspection> inspections) {
    final photoItems = <pw.Widget>[];

    for (final insp in inspections) {
      for (int lIdx = 0; lIdx < insp.nonConformingLuminaires.length; lIdx++) {
        final lum = insp.nonConformingLuminaires[lIdx];
        final repere = '#${(lIdx + 1).toString().padLeft(4, '0')}';

        for (final ans in lum.answers) {
          if (!ans.isConform && ans.photoPaths.isNotEmpty) {
            final qTitle = questionsText[ans.questionIndex - 1];

            for (final path in ans.photoPaths) {
              final file = File(path);
              if (!file.existsSync()) continue;

              try {
                final imageBytes = file.readAsBytesSync();
                final pdfImg = pw.MemoryImage(imageBytes);

                photoItems.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 1),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                      color: PdfColors.white,
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 150,
                          height: 110,
                          child: pw.ClipRRect(
                            horizontalRadius: 3,
                            verticalRadius: 3,
                            child: pw.Image(pdfImg, fit: pw.BoxFit.cover),
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Local : ${insp.batimentLocal.toUpperCase()}',
                                style: pw.TextStyle(
                                  font: PdfReportService.fontBold,
                                  fontSize: 10,
                                  color: PdfReportService.headerColor,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'Luminaire $repere (${insp.typeLuminaire})',
                                style: pw.TextStyle(
                                  font: PdfReportService.fontBold,
                                  fontSize: 9,
                                  color: PdfColors.red800,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'Critère : $qTitle',
                                style: pw.TextStyle(
                                  font: PdfReportService.fontBold,
                                  fontSize: 9,
                                  color: PdfColors.grey900,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Observation : ${ans.commentaire?.isNotEmpty == true ? ans.commentaire : "Aucun commentaire"}',
                                style: pw.TextStyle(
                                  font: PdfReportService.fontRegular,
                                  fontSize: 8.5,
                                  color: PdfColors.grey800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } catch (e) {
                if (kDebugMode) print('Erreur photo PDF: $e');
              }
            }
          }
        }
      }
    }

    if (photoItems.isEmpty) {
      return [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            'Aucune photographie enregistrée pour les défaillances d\'éclairage.',
            style: pw.TextStyle(
              font: PdfReportService.fontRegular,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ),
      ];
    }

    return photoItems;
  }
}
