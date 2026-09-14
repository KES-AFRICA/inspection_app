import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/components/safe_file_image.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

/// Builder responsable de la Page de Couverture et de la page Intervenants & Responsabilités
class PdfCoverBuilder {
  static pw.Font fontRegular = pw.Font.helvetica();
  static pw.Font fontBold = pw.Font.helveticaBold();
  static pw.MemoryImage? logoKesImage;
  static pw.MemoryImage? cachedClientLogoImg;
  static pw.MemoryImage? cachedClientQrImg;

  static final pw.MemoryImage placeholder1x1 = pw.MemoryImage(
    Uint8List.fromList(<int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]),
  );

  static String docStatus(bool? val) =>
      val == true ? 'Présenté' : 'Non présenté';


  static Future<void> preloadCoverImages(
    Mission mission, {
    required bool saveFilesToDisk,
  }) async {
    cachedClientLogoImg = null;
    cachedClientQrImg = null;

    if (mission.logoClient != null && mission.logoClient!.trim().isNotEmpty) {
      if (!saveFilesToDisk) {
        cachedClientLogoImg = placeholder1x1;
      } else {
        try {
          final resolvedPath = await AppImageUtils.resolvePathAsync(
            mission.logoClient!.trim(),
          );
          if (resolvedPath != null) {
            final file = File(resolvedPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              if (bytes.isNotEmpty)
                cachedClientLogoImg = pw.MemoryImage(bytes);
            }
          }
        } catch (_) {}
      }
    }

    if (mission.qrCodeClient != null &&
        mission.qrCodeClient!.trim().isNotEmpty) {
      if (!saveFilesToDisk) {
        cachedClientQrImg = placeholder1x1;
      } else {
        try {
          final resolvedPath = await AppImageUtils.resolvePathAsync(
            mission.qrCodeClient!.trim(),
          );
          if (resolvedPath != null) {
            final file = File(resolvedPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              if (bytes.isNotEmpty) cachedClientQrImg = pw.MemoryImage(bytes);
            }
          }
        } catch (_) {}
      }
    }
  }


  static pw.Widget buildCoverPage(
    Mission mission,
    RenseignementsGeneraux? rg,
    pw.Context ctx, {
    String? subTitleOverride,
  }) {
    final dateDebut = rg?.dateDebut ?? mission.dateIntervention;
    final dateFin = rg?.dateFin;
    String dateIntervention;
    if (dateDebut != null &&
        dateFin != null &&
        !dateDebut.isAtSameMomentAs(dateFin)) {
      dateIntervention =
          'Du ${PdfReportStyles.formatDate(dateDebut)} au ${PdfReportStyles.formatDate(dateFin)}';
    } else if (dateDebut != null) {
      dateIntervention = PdfReportStyles.formatDate(dateDebut);
    } else {
      dateIntervention = '';
    }

    pw.MemoryImage? clientLogoMemoryImg = cachedClientLogoImg;
    if (clientLogoMemoryImg == null &&
        mission.logoClient != null &&
        mission.logoClient!.isNotEmpty) {
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

    pw.MemoryImage? clientQrMemoryImg = cachedClientQrImg;
    if (clientQrMemoryImg == null &&
        mission.qrCodeClient != null &&
        mission.qrCodeClient!.isNotEmpty) {
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
            if (logoKesImage != null)
              pw.Image(
                logoKesImage!,
                width: 140,
                height: 80,
                fit: pw.BoxFit.contain,
              )
            else
              pw.Text(
                'KES INSPECTIONS AND PROJECTS',
                style: pw.TextStyle(
                  font: fontBold,
                  color: PdfReportStyles.headerColor,
                  fontSize: 10,
                ),
              ),
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
                        border: pw.Border.all(
                          color: PdfColors.grey400,
                          width: 1,
                        ),
                        color: PdfColors.grey200,
                      ),
                      child: pw.Center(
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              'LOGO CLIENT',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 8,
                                color: PdfColors.grey600,
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              '(a coller ici)',
                              style: pw.TextStyle(
                                font: fontRegular,
                                fontSize: 7,
                                color: PdfColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    "A l'attention de Monsieur le\nDirecteur General",
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 11,
                      color: PdfColors.black,
                    ),
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
            color: PdfReportStyles.accentColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            'RAPPORT',
            style: pw.TextStyle(
              font: fontBold,
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
                  final prefix =
                      (nature.startsWith('VERIFICATION') ||
                          nature.startsWith('VÉRIFICATION'))
                      ? nature
                      : 'VERIFICATION $nature';
                  return '$prefix\nDES INSTALLATIONS ELECTRIQUES';
                })(),
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 15,
              color: PdfReportStyles.headerColor,
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
                  font: fontBold,
                  fontSize: 16,
                  color: PdfReportStyles.headerColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
              if (mission.nomSite != null &&
                  mission.nomSite!.isNotEmpty &&
                  mission.nomSite!.toUpperCase() !=
                      mission.nomClient.toUpperCase()) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  mission.nomSite!.toUpperCase(),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 15,
                    color: PdfReportStyles.headerColor,
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
                    coverInfoRow('Date d\'intervention', dateIntervention),
                  coverInfoRow(
                    'Date du rapport',
                    PdfReportStyles.formatDate(mission.dateRapport ?? DateTime.now()),
                  ),
                  if (mission.natureMission != null)
                    coverInfoRow(
                      'Nature de la mission',
                      mission.natureMission!,
                    ),
                  coverInfoRow(
                    'Rapport N',
                    'KES/IP/VE/${DateTime.now().year}/001',
                  ),
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
                      pw.Text(
                        'QR CODE',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '(a coller ici)',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 7,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }


  static pw.Widget coverInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 125,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: PdfReportStyles.fsBody,
                fontWeight: pw.FontWeight.bold,
                color: PdfReportStyles.headerColor,
              ),
            ),
          ),
          pw.Text(
            ': ',
            style: pw.TextStyle(
              fontSize: PdfReportStyles.fsBody,
              fontWeight: pw.FontWeight.bold,
              color: PdfReportStyles.headerColor,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: PdfReportStyles.fsBody, color: PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildIntervenantsEtResponsabilitesPage(
    JSA? jsa,
    RenseignementsGeneraux? rg,
    dynamic currentUser,
    Map<String, int> trackedPages,
    int pageOffset, {
    DateTime? reportGenerationDate,
    Mission? mission,
    String? dateIntervention,
  }) {
    final List<String> inspecteursNoms = [];
    if (jsa != null && jsa.inspecteurs.isNotEmpty) {
      for (final insp in jsa.inspecteurs) {
        final fullName = '${insp.prenom} ${insp.nom}'.trim();
        if (fullName.isNotEmpty &&
            !inspecteursNoms.any(
              (existing) =>
                  JSAUtils.normalizeInspectorName(existing) ==
                  JSAUtils.normalizeInspectorName(fullName),
            )) {
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

    final dateGen = reportGenerationDate ?? DateTime.now();
    final dateGenStr = PdfReportStyles.formatDate(dateGen);

    final dateDebut = rg?.dateDebut ?? mission?.dateIntervention;
    final dateFin = rg?.dateFin;
    String intervDateStr;
    if (dateIntervention != null && dateIntervention.isNotEmpty) {
      intervDateStr = dateIntervention;
    } else if (dateDebut != null &&
        dateFin != null &&
        !dateDebut.isAtSameMomentAs(dateFin)) {
      intervDateStr =
          'Du ${PdfReportStyles.formatDate(dateDebut)}\nau ${PdfReportStyles.formatDate(dateFin)}';
    } else if (dateDebut != null) {
      intervDateStr = PdfReportStyles.formatDate(dateDebut);
    } else {
      intervDateStr = dateGenStr;
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
                    decoration: pw.BoxDecoration(color: PdfReportStyles.headerColor),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      name,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: PdfReportStyles.fsBody,
                        color: PdfReportStyles.darkGrey,
                      ),
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
          style: pw.TextStyle(
            font: fontBold,
            fontSize: PdfReportStyles.fsSmall,
            color: PdfColors.white,
          ),
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    pw.Widget buildRowHeaderCell(String text) {
      return pw.Container(
        decoration: pw.BoxDecoration(color: PdfReportStyles.lightBlue),
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        alignment: pw.Alignment.center,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: PdfReportStyles.fsBody,
            color: PdfReportStyles.headerColor,
          ),
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    pw.Widget buildDateCell(String text) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        alignment: pw.Alignment.center,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: fontRegular,
            fontSize: PdfReportStyles.fsSmall + 0.5,
            color: PdfColors.black,
          ),
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    final table = pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      border: pw.TableBorder.all(color: PdfReportStyles.borderColor, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(2.15),
        2: pw.FlexColumnWidth(2.15),
        3: pw.FlexColumnWidth(2.15),
        4: pw.FlexColumnWidth(2.15),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfReportStyles.accentColor),
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
            buildRowHeaderCell("NOM"),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: buildBulletList(
                inspecteursNoms,
                trackerKey: 'intervenants_inspection',
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: buildBulletList(
                inspecteursNoms,
                trackerKey: 'intervenants_redaction',
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: buildBulletList([
                'Patrick ESSAME',
              ], trackerKey: 'intervenants_verification'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: buildBulletList([
                'Patrick ESSAME',
              ], trackerKey: 'intervenants_validation'),
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            buildRowHeaderCell("Date"),
            buildDateCell(intervDateStr),
            buildDateCell(dateGenStr),
            buildDateCell(dateGenStr),
            buildDateCell(dateGenStr),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            buildRowHeaderCell("Signature"),
            pw.Container(height: 70),
            pw.Container(height: 70),
            pw.Container(height: 70),
            pw.Container(height: 70),
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
          child: PdfReportStyles.sectionBox('INTERVENANTS ET RESPONSABILITÉS'),
        ),
        pw.SizedBox(height: 14),
        table,
      ],
    );
  }

  // Page signature "LA DIRECTION"

}
