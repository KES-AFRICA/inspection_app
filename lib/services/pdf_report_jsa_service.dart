import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/models/last_report.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/pdf_report_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Service dédié à la génération du rapport PDF JSA (Job Safety Analysis) en page unique
class PdfReportJsaService {
  static final PdfColor _greyHeaderBg = PdfColor.fromInt(0xFFB0B0B0);
  static final PdfColor _borderColor = PdfColors.grey700;
  static final PdfColor _kesBlue = PdfColor.fromInt(0xFF2E74B5);

  // Marges cohérentes avec le rapport de Vérification Électrique
  static const double _leftMargin = 60.0;
  static const double _topMargin = 30.0;
  static const double _rightMargin = 60.0;
  static const double _bottomMargin = 50.0;

  /// Generates the single-page JSA PDF report for a given mission
  static Future<File?> generateJsaReport({
    required String missionId,
    Verificateur? user,
  }) async {
    try {
      await PdfReportService.loadImages();
      await PdfReportService.loadFonts();

      final mission = HiveService.getMissionById(missionId);
      if (mission == null) return null;

      final jsa = HiveService.getJSAByMissionId(missionId) ?? JSA.create(missionId);

      final currentUser = user ?? HiveService.getCurrentUser();
      final currentUserFullName = currentUser != null
          ? '${currentUser.prenom} ${currentUser.nom}'.trim()
          : '';

      final pdf = pw.Document(
        title: 'Rapport JSA - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: true,
      );

      final dateFormatted = DateFormat('dd/MM/yyyy').format(DateTime.now());

      pdf.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(_leftMargin, _topMargin, _rightMargin, _bottomMargin),
            // Footer en foreground pour qu'il soit toujours visible (identique au rapport Vérification Électrique)
            buildForeground: (ctx) {
              final footerImg = PdfReportService.firstPageFooterImage;
              if (footerImg == null) return pw.SizedBox();
              return pw.Stack(
                overflow: pw.Overflow.visible,
                children: [
                  pw.Positioned(
                    bottom: -_bottomMargin,
                    left: -_leftMargin,
                    right: -_rightMargin,
                    child: pw.SizedBox(
                      height: 80,
                      width: PdfPageFormat.a4.width,
                      child: pw.Image(footerImg, fit: pw.BoxFit.fill),
                    ),
                  ),
                ],
              );
            },
          ),
          build: (ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // 1. LOGO KES SEUL EN HAUT À GAUCHE
                _buildLogoSection(),
                pw.SizedBox(height: 8),

                // 2. TABLEAU D'EN-TÊTE (dans le corps, pas dans le header)
                _buildInfoTable(
                  mission.adresseClient ?? '',
                  mission.nomClient,
                  currentUserFullName,
                  dateFormatted,
                ),
                pw.SizedBox(height: 8),

                // 3. OPÉRATION À EFFECTUER
                _buildOperationSection(jsa.operationEffectuer),
                pw.SizedBox(height: 8),

                // 4. TABLEAU INSPECTEURS
                _buildInspecteursTable(jsa.inspecteurs),
                pw.SizedBox(height: 8),

                // 5. PLAN D'INTERVENTION EN CAS D'URGENCE
                _buildPlanUrgenceTable(jsa.planUrgence),
                pw.SizedBox(height: 8),

                // 6. DANGERS
                _buildDangersTable(jsa.dangers),
                pw.SizedBox(height: 8),

                // 7. EXIGENCES GENERALES (EPC)
                _buildEpcTable(jsa.exigencesGenerales),
                pw.SizedBox(height: 8),

                // 8. EQUIPEMENTS DE PROTECTION INDIVIDUELLE (EPI)
                _buildEpiTable(jsa.epi),
                pw.SizedBox(height: 8),

                // 9. VERIFICATION FINALE
                _buildVerificationFinaleTable(jsa.verificationFinale),
                pw.SizedBox(height: 8),

                // 10. NOMS ET SIGNATURE DES RESPONSABLES
                _buildResponsablesTable(jsa.verificationFinale),
              ],
            );
          },
        ),
      );

      // Sauvegarde du fichier PDF
      final outputDir = await getApplicationDocumentsDirectory();
      final missionDir = Directory('${outputDir.path}/missions/$missionId');
      if (!await missionDir.exists()) {
        await missionDir.create(recursive: true);
      }

      final fileName =
          'Rapport_JSA_${mission.nomClient.replaceAll(RegExp(r'[^\w]'), '_')}.pdf';
      final file = File('${missionDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Enregistrement dans Hive des derniers rapports générés
      final lastReport = LastReport(
        missionId: '${missionId}_jsa',
        filePath: file.path,
        fileName: fileName,
        generatedAt: DateTime.now(),
        reportType: 'pdf',
      );
      await HiveService.saveLastReport(lastReport);

      return file;
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Erreur génération PDF JSA: $e');
        print(stack);
      }
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // COMPOSANTS DE CONSTRUCTION DES WIDGETS PDF
  // ──────────────────────────────────────────────────────────────

  /// En-tête de section uniforme avec fond grisé et texte centré
  static pw.Widget _buildSectionHeaderBar(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 4),
      decoration: pw.BoxDecoration(
        color: _greyHeaderBg,
        border: pw.Border.all(color: _borderColor, width: 0.5),
      ),
      child: pw.Text(
        title,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: PdfReportService.fontBold,
          fontSize: 7.0,
          color: PdfColors.black,
        ),
      ),
    );
  }

  /// Logo KES seul — aucun autre élément à côté
  static pw.Widget _buildLogoSection() {
    final logo = PdfReportService.logoKesImage;
    return pw.Align(
      alignment: pw.Alignment.topLeft,
      child: pw.Container(
        width: 85,
        height: 42,
        child: logo != null
            ? pw.Image(logo, fit: pw.BoxFit.contain)
            : pw.Text('KES LOGO', style: const pw.TextStyle(fontSize: 10)),
      ),
    );
  }

  /// Tableau d'en-tête avec titre JSA et infos — dans le corps du document
  static pw.Widget _buildInfoTable(
    String site,
    String client,
    String chefEquipe,
    String dateStr,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(1.8),
      },
      children: [
        pw.TableRow(
          children: [
            // Colonne 1 : Titre JSA
            pw.Container(
              height: 52,
              padding: const pw.EdgeInsets.all(3),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'JSA',
                    style: pw.TextStyle(
                      font: PdfReportService.fontBold,
                      fontSize: 16,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'JOB SAFETY ANALYSIS',
                    style: pw.TextStyle(
                      font: PdfReportService.fontBold,
                      fontSize: 7.0,
                      color: _kesBlue,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            // Colonne 2 : Sous-tableau d'infos
            pw.Table(
              border: pw.TableBorder.all(color: _borderColor, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(1.8),
              },
              children: [
                _buildHeaderInfoRow('N° Ref:', 'KIP/DG/FOR/QHSE/JSA/01'),
                _buildHeaderInfoRow('Date du jour:', dateStr),
                _buildHeaderInfoRow('Reference de la mission:', ''),
                _buildHeaderInfoRow('Localisation :', site),
                _buildHeaderInfoRow('Nom du client :', client),
                _buildHeaderInfoRow('Chef d\'équipe:', chefEquipe),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _buildHeaderInfoRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.2),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: PdfReportService.fontBold,
              fontSize: 6.0,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.2),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              font: PdfReportService.fontRegular,
              fontSize: 6.0,
            ),
          ),
        ),
      ],
    );
  }

  /// Ligne Opération à effectuer
  static pw.Widget _buildOperationSection(String operation) {
    final hasOp = operation.trim().isNotEmpty;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Text(
              'OPERATION A EFFECTUER: ',
              style: pw.TextStyle(
                font: PdfReportService.fontBold,
                fontSize: 7.0,
              ),
            ),
            pw.Expanded(
              child: hasOp
                  ? pw.Text(
                      operation,
                      style: pw.TextStyle(
                        font: PdfReportService.fontRegular,
                        fontSize: 7.0,
                      ),
                    )
                  : pw.Text(
                      '.......................................................................................................................................................................................',
                      style: pw.TextStyle(
                        fontSize: 6.5,
                        color: PdfColors.grey600,
                      ),
                    ),
            ),
          ],
        ),
        pw.SizedBox(height: 1),
        pw.Text(
          '............................................................................................................................................................................................................................................',
          style: pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
        ),
      ],
    );
  }

  /// Tableau 1: INSPECTEURS (Dynamique selon le nombre d'inspecteurs de la mission)
  static pw.Widget _buildInspecteursTable(List<JSAInspecteur> inspecteurs) {
    final total = inspecteurs.length;
    final rowCount = total == 0 ? 3 : ((total + 1) ~/ 2).clamp(3, 10);

    final tableRows = <pw.TableRow>[];

    // Column Headers (exactement 6 colonnes)
    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _buildCell('N°', isHeader: true, fontSize: 6.0, width: 18),
          _buildCell('NOMS ET PRENOMS', isHeader: true, fontSize: 6.0),
          _buildCell('SIGNATURES', isHeader: true, fontSize: 6.0),
          _buildCell('N°', isHeader: true, fontSize: 6.0, width: 18),
          _buildCell('NOMS ET PRENOMS', isHeader: true, fontSize: 6.0),
          _buildCell('SIGNATURES', isHeader: true, fontSize: 6.0),
        ],
      ),
    );

    for (int r = 0; r < rowCount; r++) {
      final leftIndex = r;
      final rightIndex = r + rowCount;

      final leftInsp = leftIndex < inspecteurs.length ? inspecteurs[leftIndex] : null;
      final rightInsp = rightIndex < inspecteurs.length ? inspecteurs[rightIndex] : null;

      final leftNom = leftInsp != null ? '${leftInsp.nom} ${leftInsp.prenom}'.trim() : '';
      final rightNom = rightInsp != null ? '${rightInsp.nom} ${rightInsp.prenom}'.trim() : '';

      tableRows.add(
        pw.TableRow(
          children: [
            _buildCell('${leftIndex + 1}', isHeader: false, fontSize: 6.0, alignCenter: true),
            _buildCell(leftNom, isHeader: false, fontSize: 6.0),
            _buildCell(leftInsp?.signature ?? '', isHeader: false, fontSize: 6.0),
            _buildCell('${rightIndex + 1}', isHeader: false, fontSize: 6.0, alignCenter: true),
            _buildCell(rightNom, isHeader: false, fontSize: 6.0),
            _buildCell(rightInsp?.signature ?? '', isHeader: false, fontSize: 6.0),
          ],
        ),
      );
    }

    return pw.Column(
      children: [
        _buildSectionHeaderBar('INSPECTEURS'),
        pw.Table(
          border: pw.TableBorder(
            left: pw.BorderSide(color: _borderColor, width: 0.5),
            right: pw.BorderSide(color: _borderColor, width: 0.5),
            bottom: pw.BorderSide(color: _borderColor, width: 0.5),
            horizontalInside: pw.BorderSide(color: _borderColor, width: 0.5),
            verticalInside: pw.BorderSide(color: _borderColor, width: 0.5),
          ),
          columnWidths: const {
            0: pw.FixedColumnWidth(18),
            1: pw.FlexColumnWidth(2.5),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FixedColumnWidth(18),
            4: pw.FlexColumnWidth(2.5),
            5: pw.FlexColumnWidth(1.5),
          },
          children: tableRows,
        ),
      ],
    );
  }

  /// Tableau 2: PLAN D'INTERVENTION EN CAS D'URGENCE
  static pw.Widget _buildPlanUrgenceTable(JSAPlanUrgence plan) {
    return pw.Column(
      children: [
        _buildSectionHeaderBar('PLAN D\'INTERVENTION EN CAS D\'URGENCE'),
        pw.Table(
          border: pw.TableBorder(
            left: pw.BorderSide(color: _borderColor, width: 0.5),
            right: pw.BorderSide(color: _borderColor, width: 0.5),
            bottom: pw.BorderSide(color: _borderColor, width: 0.5),
            horizontalInside: pw.BorderSide(color: _borderColor, width: 0.5),
            verticalInside: pw.BorderSide(color: _borderColor, width: 0.5),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(4.5),
            1: pw.FlexColumnWidth(1.0),
            2: pw.FlexColumnWidth(1.0),
          },
          children: [
            _buildPlanUrgenceRow(
              'Voies d\'issues de secours identifiées :',
              plan.voiesIssuesIdentifiees,
            ),
            _buildPlanUrgenceRow(
              'Zones de rassemblement identifiés :',
              plan.zonesRassemblementIdentifiees,
            ),
            _buildPlanUrgenceRow(
              'Consignes de sécurité internes :',
              plan.consignesSecuriteInternes,
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'Personne à contacter en cas d\'urgence : CLIENT: ',
                        style: pw.TextStyle(font: PdfReportService.fontBold, fontSize: 6.0),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          plan.personneContactClient.isNotEmpty
                              ? plan.personneContactClient
                              : '...............................................................................................................................',
                          style: pw.TextStyle(font: PdfReportService.fontRegular, fontSize: 6.0),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(),
                pw.Container(),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'KES:   ',
                        style: pw.TextStyle(font: PdfReportService.fontBold, fontSize: 6.0, color: PdfColors.black),
                      ),
                      pw.Text(
                        '656 294 506 / 655 903 178',
                        style: pw.TextStyle(font: PdfReportService.fontBold, fontSize: 6.0, color: _kesBlue),
                      ),
                      pw.Text(
                        ' (QHSE)',
                        style: pw.TextStyle(font: PdfReportService.fontBold, fontSize: 6.0, color: PdfColors.black),
                      ),
                      pw.Text(
                        '   -   ',
                        style: pw.TextStyle(font: PdfReportService.fontRegular, fontSize: 6.0),
                      ),
                      pw.Text(
                        '699 429 589',
                        style: pw.TextStyle(font: PdfReportService.fontBold, fontSize: 6.0, color: _kesBlue),
                      ),
                      pw.Text(
                        ' (DG)',
                        style: pw.TextStyle(font: PdfReportService.fontBold, fontSize: 6.0, color: PdfColors.black),
                      ),
                    ],
                  ),
                ),
                pw.Container(),
                pw.Container(),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _buildPlanUrgenceRow(String label, bool isYes) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
          child: pw.Text(label, style: pw.TextStyle(fontSize: 6.0)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
          child: _buildCheckbox(isYes, 'oui'),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
          child: _buildCheckbox(!isYes, 'Non'),
        ),
      ],
    );
  }

  /// Tableau 3: DANGERS
  static pw.Widget _buildDangersTable(JSADangers dangers) {
    return pw.Column(
      children: [
        _buildSectionHeaderBar('DANGERS'),
        pw.Table(
          border: pw.TableBorder(
            left: pw.BorderSide(color: _borderColor, width: 0.5),
            right: pw.BorderSide(color: _borderColor, width: 0.5),
            bottom: pw.BorderSide(color: _borderColor, width: 0.5),
            horizontalInside: pw.BorderSide(color: _borderColor, width: 0.5),
            verticalInside: pw.BorderSide(color: _borderColor, width: 0.5),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(2),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Lié à l\'environnement',
                    style: pw.TextStyle(font: PdfReportService.fontBold, fontSize: 6.5, fontStyle: pw.FontStyle.italic),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(2),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Physiques',
                    style: pw.TextStyle(font: PdfReportService.fontBold, fontSize: 6.5, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildCheckboxPair(
                        dangers.chocElectrique, 'Choc électrique',
                        dangers.bruit, 'Bruit',
                      ),
                      _buildCheckboxPair(
                        dangers.stressThermique, 'Stress thermique (chaleur)',
                        dangers.eclairageInadapte, 'Éclairage inadapté',
                      ),
                      _buildCheckboxPair(
                        dangers.zoneCirculationMalDefinie, 'Zone de circulation mal définie',
                        dangers.solAccidente, 'Sol accidenté',
                      ),
                      _buildCheckboxPair(
                        dangers.emissionGazPoussiere, 'Émission (gaz, poussière, fumées)',
                        dangers.espaceConfine, 'Espace confiné',
                      ),
                      _buildCheckboxLine(
                        dangers.autreEnvironnement.isNotEmpty,
                        'Autre : ${dangers.autreEnvironnement.isNotEmpty ? dangers.autreEnvironnement : '..........................................................'}',
                      ),
                    ],
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildCheckboxPair(
                        dangers.chuteObjets, 'Chute d\'objets',
                        dangers.coactivite, 'Coactivité (intervention entreprise autre)',
                      ),
                      _buildCheckboxPair(
                        dangers.portCharge, 'Port de charge',
                        dangers.expositionProduitsChimiques, 'Exposition aux produits Chimique',
                      ),
                      _buildCheckboxPair(
                        dangers.chuteHauteur, 'Chute de hauteur',
                        dangers.electrification, 'Électrisation/ électrocution',
                      ),
                      _buildCheckboxPair(
                        dangers.incendiesExplosion, 'Incendies/explosion',
                        dangers.mauvaisesPostures, 'Mauvaises postures',
                      ),
                      _buildCheckboxPair(
                        dangers.chutePlainPied, 'Chute de plain-pied',
                        dangers.autrePhysique.isNotEmpty,
                        'Autre : ${dangers.autrePhysique.isNotEmpty ? dangers.autrePhysique : '..............................'}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Tableau 4: EXIGENCES GENERALES (EPC)
  static pw.Widget _buildEpcTable(JSAExigencesGenerales epc) {
    return pw.Column(
      children: [
        _buildSectionHeaderBar('EXIGENCES GENERALES (EPC)'),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: _borderColor, width: 0.5),
              right: pw.BorderSide(color: _borderColor, width: 0.5),
              bottom: pw.BorderSide(color: _borderColor, width: 0.5),
            ),
          ),
          padding: const pw.EdgeInsets.all(3),
          child: pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildCheckboxLine(epc.signaletiqueSecurite, 'Signalétique sécurité'),
                      _buildCheckboxLine(epc.balise, 'Balise'),
                      _buildCheckboxLine(epc.permisTravail, 'Permis de travail'),
                      _buildCheckboxLine(epc.boitePharmacie, 'Boîte à pharmacie'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildCheckboxLine(epc.ficheDonneeSecuriteDisponible, 'Fiche de donnée sécurité disponible'),
                      _buildCheckboxLine(epc.zoneTravailPropre, 'Zone de travail propre'),
                      _buildCheckboxLine(epc.extincteurs, 'Extincteurs'),
                      _buildCheckboxLine(
                        epc.autre.isNotEmpty,
                        'Autres : ${epc.autre.isNotEmpty ? epc.autre : '....................'}',
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildCheckboxLine(epc.uneMinuteMaSecurite, '1 minute ma sécurité'),
                      _buildCheckboxLine(epc.toolboxMeeting, 'Toolbox meeting'),
                      _buildCheckboxLine(epc.outilsMaterielsIsolants, 'Outils / matériels/ équipements isolants'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tableau 5: EQUIPEMENTS DE PROTECTION INDIVIDUELLE (EPI)
  static pw.Widget _buildEpiTable(JSAEPI epi) {
    return pw.Column(
      children: [
        _buildSectionHeaderBar('EQUIPEMENTS DE PROTECTION INDIVIDUELLE (Nécessaire contre les dangers)'),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: _borderColor, width: 0.5),
              right: pw.BorderSide(color: _borderColor, width: 0.5),
              bottom: pw.BorderSide(color: _borderColor, width: 0.5),
            ),
          ),
          padding: const pw.EdgeInsets.all(3),
          child: pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildCheckboxLine(epi.casqueSecurite, 'Casque de sécurité'),
                      _buildCheckboxLine(epi.chaussureSecurite, 'Chaussure de sécurité'),
                      _buildCheckboxLine(epi.gantsIsolants, 'Gants isolants'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildCheckboxLine(epi.bouchonsOreille, 'Bouchons d\'oreille'),
                      _buildCheckboxLine(epi.masqueSecurite, 'masque de sécurité'),
                      _buildCheckboxLine(epi.cacheNez, 'Cache-nez'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildCheckboxLine(epi.lunettesProtection, 'Lunettes de protection'),
                      _buildCheckboxLine(epi.combinaisonLongueManche, 'Combinaison : longue manche'),
                      _buildCheckboxLine(epi.gilet, 'Gilet'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildCheckboxLine(epi.harnaisSecurite, 'Harnais de sécurité'),
                      _buildCheckboxLine(epi.bouchonsOreille, 'Bouchons d\'oreille'),
                      _buildCheckboxLine(
                        epi.autre.isNotEmpty,
                        'Autre : ${epi.autre.isNotEmpty ? epi.autre : '..............'}',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            '« Vous êtes responsable de votre sécurité et celle des autres ; le port des EPI ne remplacera jamais la vigilance et la prudence. »',
            style: pw.TextStyle(
              font: PdfReportService.fontBold,
              fontSize: 6.0,
              color: PdfColors.red800,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  /// Tableau 6: VERIFICATION FINALE
  static pw.Widget _buildVerificationFinaleTable(JSAVerificationFinale vf) {
    return pw.Column(
      children: [
        _buildSectionHeaderBar('VERIFICATION FINALE'),
        // Texte introductif qui s'étend sur toute la largeur
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(color: _borderColor, width: 0.5),
              right: pw.BorderSide(color: _borderColor, width: 0.5),
              bottom: pw.BorderSide(color: _borderColor, width: 0.5),
            ),
          ),
          child: pw.Text(
            'Le chargé d\'affaires et le donneur d\'ordre certifient que :',
            style: pw.TextStyle(font: PdfReportService.fontBold, fontSize: 6.0),
          ),
        ),
        // Tableau avec les checkboxes N/A et Applicable
        pw.Table(
          border: pw.TableBorder(
            left: pw.BorderSide(color: _borderColor, width: 0.5),
            right: pw.BorderSide(color: _borderColor, width: 0.5),
            bottom: pw.BorderSide(color: _borderColor, width: 0.5),
            horizontalInside: pw.BorderSide(color: _borderColor, width: 0.5),
            verticalInside: pw.BorderSide(color: _borderColor, width: 0.5),
          ),
          columnWidths: const {
            0: pw.FixedColumnWidth(30),
            1: pw.FixedColumnWidth(55),
            2: pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildCell('N/A', isHeader: true, fontSize: 6.0, alignCenter: true),
                _buildCell('Applicable', isHeader: true, fontSize: 6.0, alignCenter: true),
                _buildCell('', isHeader: false, fontSize: 6.0),
              ],
            ),
            _buildVerificationRow(vf.travailTermineNA, vf.travailTermineApplicable, 'Le travail est terminé.'),
            _buildVerificationRow(vf.consignationCadenasRetireNA, vf.consignationCadenasRetireApplicable, 'En cas de consignation a retiré le cadenas.'),
            _buildVerificationRow(vf.absenceConsignataireProcedureNA, vf.absenceConsignataireProcedureApplicable, 'En cas d\'absence d\'un consignataire, se référer aux consignes de la procédure.'),
            _buildVerificationRow(vf.consignataireAbsentProcedureAppliqueeNA, vf.consignataireAbsentProcedureAppliqueeApplicable, 'Un consignataire est absent et la procédure est appliquée.'),
            _buildVerificationRow(vf.materielEnleveZoneNettoyeeNA, vf.materielEnleveZoneNettoyeeApplicable, 'Le matériel utilisé a été enlevé et la zone de travail est nettoyée.'),
            _buildVerificationRow(vf.risquesSupprimesEquipementPretNA, vf.risquesSupprimesEquipementPretApplicable, 'Tous les risques sont supprimés et l\'équipement est prêt à être utilisé.'),
            pw.TableRow(
              children: [
                pw.Container(),
                pw.Container(),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  child: pw.Text(
                    'Autres points : ${vf.autresPoints.isNotEmpty ? vf.autresPoints : '..................................................................................................................................................................'}',
                    style: pw.TextStyle(fontSize: 6.0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _buildVerificationRow(bool isNA, bool isApp, String label) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(1.5),
          child: pw.Center(child: _buildCheckbox(isNA, '')),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(1.5),
          child: pw.Center(child: _buildCheckbox(isApp, '')),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
          child: pw.Text(label, style: pw.TextStyle(fontSize: 6.0)),
        ),
      ],
    );
  }

  /// Tableau 7: NOMS ET SIGNATURE DES RESPONSABLES
  static pw.Widget _buildResponsablesTable(JSAVerificationFinale vf) {
    return pw.Column(
      children: [
        _buildSectionHeaderBar('NOMS ET SIGNATURE DES RESPONSABLES APRES VERIFICATION FINALE DES TRAVAUX'),
        pw.Table(
          border: pw.TableBorder(
            left: pw.BorderSide(color: _borderColor, width: 0.5),
            right: pw.BorderSide(color: _borderColor, width: 0.5),
            bottom: pw.BorderSide(color: _borderColor, width: 0.5),
            horizontalInside: pw.BorderSide(color: _borderColor, width: 0.5),
            verticalInside: pw.BorderSide(color: _borderColor, width: 0.5),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(1),
          },
          children: [
            // Ligne 1 : Labels
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: pw.Text('Donneur d\'ordre :', style: pw.TextStyle(font: PdfReportService.fontBold, fontSize: 6.0)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: pw.Text('Chargé d\'affaires :', style: pw.TextStyle(font: PdfReportService.fontBold, fontSize: 6.0)),
                ),
              ],
            ),
            // Ligne 2 : Signatures (espace pour signer)
            pw.TableRow(
              children: [
                pw.Container(
                  height: 35,
                  padding: const pw.EdgeInsets.all(4),
                  alignment: pw.Alignment.bottomLeft,
                  child: pw.Text(
                    vf.donneurOrdreSignature.isNotEmpty
                        ? vf.donneurOrdreSignature
                        : '....................................................................................................................................',
                    style: pw.TextStyle(fontSize: 5.5),
                  ),
                ),
                pw.Container(
                  height: 35,
                  padding: const pw.EdgeInsets.all(4),
                  alignment: pw.Alignment.bottomLeft,
                  child: pw.Text(
                    vf.chargeAffairesSignature.isNotEmpty
                        ? vf.chargeAffairesSignature
                        : '....................................................................................................................................',
                    style: pw.TextStyle(fontSize: 5.5),
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
  // UTILITIES WIDGETS ET CHECKBOXES
  // ──────────────────────────────────────────────────────────────

  static pw.Widget _buildCell(
    String text, {
    required bool isHeader,
    double fontSize = 6.0,
    double? width,
    bool alignCenter = false,
  }) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
      alignment: alignCenter ? pw.Alignment.center : (isHeader ? pw.Alignment.center : pw.Alignment.centerLeft),
      child: pw.Text(
        text,
        textAlign: alignCenter ? pw.TextAlign.center : (isHeader ? pw.TextAlign.center : pw.TextAlign.left),
        style: pw.TextStyle(
          font: isHeader ? PdfReportService.fontBold : PdfReportService.fontRegular,
          fontSize: fontSize,
          color: PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildCheckbox(bool checked, String label, {double fontSize = 6.0}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 6.5,
          height: 6.5,
          margin: const pw.EdgeInsets.only(right: 2.5),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
          child: checked
              ? pw.Center(
                  child: pw.Text('X',
                      style: pw.TextStyle(
                          font: PdfReportService.fontBold,
                          fontSize: 4.5,
                          color: PdfColors.black)))
              : null,
        ),
        if (label.isNotEmpty)
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize)),
      ],
    );
  }

  static pw.Widget _buildCheckboxLine(bool checked, String label) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: _buildCheckbox(checked, label),
    );
  }

  static pw.Widget _buildCheckboxPair(bool c1, String l1, bool c2, String l2) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(1),
          1: pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            children: [
              _buildCheckbox(c1, l1),
              _buildCheckbox(c2, l2),
            ],
          ),
        ],
      ),
    );
  }
}
