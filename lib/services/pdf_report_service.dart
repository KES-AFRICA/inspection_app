import 'dart:io';
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
import 'package:inspec_app/services/hive_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

// ============================================================
//  PdfReportService - Rendu fidèle au modèle KES INSPECTIONS
// ============================================================

class PdfReportService {
  // ── Couleurs ────────────────────────────────────────────────
  static final PdfColor headerColor    = PdfColor.fromInt(0xFF1F3864); // bleu foncé
  static final PdfColor accentColor    = PdfColor.fromInt(0xFF2E74B5); // bleu moyen
  static final PdfColor lightBlue      = PdfColor.fromInt(0xFFD6E4F0); // fond en-tête tableau
  static final PdfColor darkGrey       = PdfColor.fromInt(0xFF404040);
  static final PdfColor tableRowAlt    = PdfColor.fromInt(0xFFF5F8FC);
  static final PdfColor borderColor    = PdfColor.fromInt(0xFFAAAAAA);
  static final PdfColor priorite1Color = PdfColor.fromInt(0xFFFFF2CC); // jaune
  static final PdfColor priorite2Color = PdfColor.fromInt(0xFFFFE0B2); // orange
  static final PdfColor priorite3Color = PdfColor.fromInt(0xFFFFCDD2); // rouge
  static final PdfColor conformeColor  = PdfColor.fromInt(0xFFE8F5E9); // vert clair
  static final PdfColor nonConformeColor = PdfColor.fromInt(0xFFFFEBEE); // rouge clair

  // ── Marges & espacements ─────────────────────────────────────
  static const double pageMarginH  = 18.0;
  static const double pageMarginV  = 18.0;
  static const double sectionGap   = 8.0;
  static const double subGap       = 5.0;
  static const double rowPad       = 3.0;
  static const double cellPadH     = 4.0;
  static const double cellPadV     = 3.0;
  static const double borderWidth  = 0.4;

  // ── Tailles de police ────────────────────────────────────────
  static const double fsH1   = 11.0;
  static const double fsH2   = 9.5;
  static const double fsH3   = 9.0;
  static const double fsBody = 8.0;
  static const double fsSmall = 7.0;

  // ============================================================
  //  POINT D'ENTRÉE
  // ============================================================
  static Future<File?> generateMissionReport(String missionId) async {
    try {
      final mission      = HiveService.getMissionById(missionId);
      if (mission == null) return null;
      final description  = HiveService.getDescriptionInstallationsByMissionId(missionId);
      final audit        = HiveService.getAuditInstallationsByMissionId(missionId);
      final classements  = HiveService.getEmplacementsByMissionId(missionId);
      final mesures      = HiveService.getMesuresEssaisByMissionId(missionId);
      final foudres      = HiveService.getFoudreObservationsByMissionId(missionId);

      final pdf = pw.Document(
        title: 'Rapport d\'Audit Électrique - ${mission.nomClient}',
        author: 'KES INSPECTIONS AND PROJECTS',
        compress: true,
      );

      // ── Chargement optionnel des logos (assets) ──────────────
      pw.MemoryImage? logoKes;
      pw.MemoryImage? logoKesM;
      pw.MemoryImage? logoClient;
      try {
        final bytes1 = (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List();
        final bytes11 = (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List();
        logoKes = pw.MemoryImage(bytes1);
        logoKesM = pw.MemoryImage(bytes11);
      } catch (_) {}
      try {
        final bytes2 = (await rootBundle.load('assets/logo_client.png')).buffer.asUint8List();
        logoClient = pw.MemoryImage(bytes2);
      } catch (_) {}

      // ── 1. Page de couverture ─────────────────────────────────
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.symmetric(horizontal: pageMarginH, vertical: pageMarginV),
        build: (ctx) => _buildCoverPage(mission, logoKes, logoClient),
      ));

      // ── 3. Rappel des responsabilités ────────────────────────
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.symmetric(horizontal: pageMarginH, vertical: pageMarginV),
        header: (ctx) => _buildPageHeader(mission, logoKesM),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => _buildRappelResponsabilites(),
      ));

      // ── 4. Objet de la vérification ──────────────────────────
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.symmetric(horizontal: pageMarginH, vertical: pageMarginV),
        header: (ctx) => _buildPageHeader(mission, logoKesM),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => _buildObjetVerification(),
      ));

      // ── 5. Renseignements généraux ───────────────────────────
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.symmetric(horizontal: pageMarginH, vertical: pageMarginV),
        header: (ctx) => _buildPageHeader(mission, logoKesM),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => _buildRenseignementsGeneraux(mission),
      ));

      // ── 6. Description des installations ─────────────────────
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.symmetric(horizontal: pageMarginH, vertical: pageMarginV),
        header: (ctx) => _buildPageHeader(mission, logoKesM),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => _buildDescriptionInstallations(description),
      ));

      // ── 7. Liste récapitulative des observations ─────────────
      if (audit != null) {
        pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.symmetric(horizontal: pageMarginH, vertical: pageMarginV),
          header: (ctx) => _buildPageHeader(mission, logoKesM),
          footer: (ctx) => _buildFooter(ctx),
          build: (ctx) => _buildListeRecapitulative(audit),
        ));
      }

      // ── 8. Audit des installations électriques ───────────────
      if (audit != null) {
        pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.symmetric(horizontal: pageMarginH, vertical: pageMarginV),
          header: (ctx) => _buildPageHeader(mission, logoKesM),
          footer: (ctx) => _buildFooter(ctx),
          build: (ctx) => _buildAuditInstallations(audit),
        ));
      }

      // ── 9. Classement des emplacements ───────────────────────
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.symmetric(horizontal: pageMarginH, vertical: pageMarginV),
        header: (ctx) => _buildPageHeader(mission, logoKesM),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => _buildClassementEmplacements(classements),
      ));

      // ── 10. Foudre ───────────────────────────────────────────
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.symmetric(horizontal: pageMarginH, vertical: pageMarginV),
        header: (ctx) => _buildPageHeader(mission, logoKesM),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => _buildFoudre(foudres),
      ));

      // ── 11. Résultats des mesures et essais ──────────────────
      if (mesures != null) {
        pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.symmetric(horizontal: pageMarginH, vertical: pageMarginV),
          header: (ctx) => _buildPageHeader(mission, logoKesM),
          footer: (ctx) => _buildFooter(ctx),
          build: (ctx) => _buildMesuresEssais(mesures),
        ));
      }

      // ── 12. Photos ───────────────────────────────────────────
      await _addPhotosSection(pdf, mission, missionId, audit, logoKesM);

      // ── Sauvegarde ───────────────────────────────────────────
      final bytes    = await pdf.save();
      final dir      = await getTemporaryDirectory();
      final fileName = 'Rapport_${mission.nomClient}_${_formatDate(DateTime.now())}.pdf'
          .replaceAll(RegExp(r'[<>:"/\\|?*\s]'), '_');
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e, stack) {
      print('❌ Erreur génération PDF: $e\n$stack');
      return null;
    }
  }

  // ============================================================
  //  EN-TÊTE & PIED DE PAGE
  // ============================================================
  static pw.Widget _buildPageHeader(Mission mission, pw.MemoryImage? logoKes) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (logoKes != null)
            pw.Image(logoKes, width: 55, height: 22, fit: pw.BoxFit.contain)
          else
            pw.Text('KES INSPECTIONS AND PROJECTS',
                style: pw.TextStyle(fontSize: 6, color: accentColor, fontWeight: pw.FontWeight.bold)),
          pw.Text('RAPPORT DE VÉRIFICATION DES INSTALLATIONS ÉLECTRIQUES',
              style: pw.TextStyle(fontSize: 6, color: darkGrey)),
          pw.Text(mission.nomClient,
              style: pw.TextStyle(fontSize: 6, color: darkGrey)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Container(
      margin: pw.EdgeInsets.only(top: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('KES INSPECTIONS AND PROJECTS - Confidentiel',
              style: pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
          pw.Text('Page ${ctx.pageNumber}',
              style: pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  // ============================================================
  //  PAGE DE COUVERTURE
  // ============================================================
  static pw.Widget _buildCoverPage(
      Mission mission, pw.MemoryImage? logoKes, pw.MemoryImage? logoClient) {
    return pw.Column(
      children: [
        // Bande haute avec logos
        pw.Container(
          width: double.infinity,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              logoKes != null
                  ? pw.Image(logoKes,width: 140, height: 80, fit: pw.BoxFit.contain)
                  : pw.Text('KES INSPECTIONS AND PROJECTS',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
              logoClient != null
                  ? pw.Image(logoClient, width: 60, height: 35, fit: pw.BoxFit.contain)
                  : pw.SizedBox(width: 60),
            ],
          ),
        ),

        pw.SizedBox(height: 40),

        pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  child: pw.Center(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
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
                                  pw.Text('LOGO CLIENT',
                                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600,
                                        fontWeight: pw.FontWeight.bold)),
                                  pw.SizedBox(height: 3),
                                  pw.Text('(a coller ici)',
                                    style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500,)),
                                ],
                              ),
                            ),
                          ),
                        
                        pw.SizedBox(height: 3),
                        pw.Text("A l'attention de Monsieur le \n Directeur General",
                          style: pw.TextStyle(fontSize: 9, color: PdfColors.black)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          pw.SizedBox(height: 40),

        // Titre principal
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: pw.Column(
            children: [
              pw.Text(
                'RAPPORT',
                style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold, color: accentColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'VERIFICATION PERIODIQUE REGLEMENTAIRE DES INSTALLATIONS ELECTRIQUES',
                style: pw.TextStyle(fontSize: 14, color: accentColor),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 16),

         pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: pw.Text(
                mission.nomClient,
                style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold, color: accentColor,
                ),
                textAlign: pw.TextAlign.center,
          ),
        ),

        pw.SizedBox(height: 50),

        // Informations client
        pw.Container(
          width: double.infinity, height: 90,
          padding: pw.EdgeInsets.symmetric(horizontal: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
               pw.Expanded(  
             child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _coverInfoRow('Date d\'intervention',
                      _formatDate(mission.dateIntervention ?? DateTime.now())),
                  _coverInfoRow('Date du rapport',
                      _formatDate(mission.dateRapport ?? DateTime.now())),
                  if (mission.natureMission != null)
                    _coverInfoRow('Nature de la mission', mission.natureMission!),
                  if (mission.periodicite != null)
                    _coverInfoRow('Périodicité', mission.periodicite!),
                ],
              )),
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
                          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600,
                              fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 3),
                        pw.Text('(a coller ici)',
                          style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500,)),
                      ],
                    ),
                  ),
                ),
            ]
          )
        ),

        pw.Spacer(),

        // Pied de couverture
        pw.Container(
          decoration: pw.BoxDecoration(
            color: headerColor,
            borderRadius: pw.BorderRadius.circular(3),
          ),
          padding: pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('KES INSPECTIONS AND PROJECTS',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold)),
              pw.Text('Rapport généré le ${_formatDate(DateTime.now())}',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 7)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _coverInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
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

  // ============================================================
  //  RAPPEL DES RESPONSABILITÉS
  // ============================================================
  static List<pw.Widget> _buildRappelResponsabilites() {
    return [
      _sectionBox('RAPPEL DES RESPONSABILITES DE L\'EMPLOYEUR'),
      pw.SizedBox(height: subGap),
      _bodyText(
        'KES INSPECTIONS AND PROJECTS a le plaisir de vous transmettre le présent rapport de vérification de vos installations électriques, établi à la suite des constats réalisés sur site.\n'
        'Ce document présente les observations effectuées par le vérificateur à partir des éléments et moyens mis à sa disposition.\n'
        'Il identifie les points de non-conformité constatés au regard des exigences réglementaires, et formule, le cas échéant, les recommandations techniques nécessaires à leur mise en conformité.',
      ),
      pw.SizedBox(height: sectionGap),

      _subTitle('Responsabilité et accompagnement'),
      _bodyText(
        'Dans le cadre de la mission, il appartient à l\'employeur de désigner une personne qualifiée et informée des installations, chargée d\'accompagner le vérificateur durant l\'intervention.\n'
        'Cette personne doit pouvoir faciliter l\'accès à l\'ensemble des locaux, appareillages et équipements à contrôler.\n\n'
        'L\'employeur reste responsable du bon fonctionnement, de la sécurité et de la disponibilité des installations tout au long de la vérification.\n'
        'Les informations et documents techniques fournis sous sa responsabilité doivent permettre la réalisation des contrôles dans de bonnes conditions.',
      ),
      pw.SizedBox(height: sectionGap),

      _subTitle('Conditions de réalisation'),
      _bodyText('Afin d\'assurer le bon déroulement des opérations, l\'employeur doit :'),
      _bulletItem('Veiller à ce que la vérification soit réalisée dans des conditions de sécurité optimales, en particulier lors des accès en zone électrique ;'),
      _bulletItem('Mettre en oeuvre les procédures nécessaires aux mises hors tension permettant d\'effectuer les mesures et essais en toute sécurité ;'),
      _bulletItem('Garantir au vérificateur l\'accès à l\'ensemble des équipements à contrôler, sans risque de chute ou d\'incident.'),
      pw.SizedBox(height: 3),
      _bodyText(
        'Si certaines vérifications n\'ont pu être effectuées (impossibilité d\'accès, absence d\'agents habilités, contraintes d\'exploitation, documentation manquante, etc.), '
        'KES INSPECTIONS AND PROJECTS en mentionnera la cause dans le rapport.\n\n'
        'Dans le cas des installations de moyenne ou haute tension, la mise hors tension et les manoeuvres associées relèvent exclusivement de la responsabilité de l\'employeur ou de son représentant habilité.',
      ),
      pw.SizedBox(height: sectionGap),

      _subTitle('Vérifications complémentaires'),
      _bodyText(
        'Lorsque des éléments du poste ou de l\'installation n\'ont pu être contrôlés lors de la visite initiale, une intervention complémentaire pourra être programmée à la demande de l\'employeur.\n'
        'Cette mission additionnelle fera alors l\'objet d\'une planification et d\'un rapport spécifique.',
      ),
      pw.SizedBox(height: sectionGap),

      _subTitle('Surveillance & maintenance des installations électriques'),
      _bodyText(
        'La vérification de conformité des installations électriques ne constitue qu\'un des éléments concourant à la sécurité des personnes et des biens. Conformément à la norme et aux textes réglementaires applicables, '
        'le chef d\'établissement doit mettre en place une organisation pour les opérations de surveillance et la maintenance des installations électriques. '
        'C\'est dans le cadre de ces opérations que les dispositions doivent être prises afin de remédier aux défectuosités constatées pendant la vérification ou celles qui peuvent se manifester après la vérification.',
      ),
      pw.SizedBox(height: sectionGap),

      _subTitle('Formation du personnel intervenant sur les installations et à proximité'),
      pw.SizedBox(height: subGap),

      _sectionBox('MESURES DE SECURITE AUTOURS DES INSTALLATIONS'),
      pw.SizedBox(height: subGap),
      _bodyText('Suivant la réglementation applicable,'),
      _bulletItem('Article 5_Arrêté 039/MTPS/IMT du 26 Novembre 1984 fixant les mesures générales d\'hygiène et de sécurité sur les lieux de travail'),
      _bulletItem('NFC 18-510 : Opérations sur les ouvrages et installations électriques et dans un environnement électrique - Prévention du risque électrique'),
      pw.SizedBox(height: 3),
      _bodyText('Le personnel doit avoir subi avec succès une formation en habilitation électrique en fonction du domaine de tension.'),
      pw.SizedBox(height: 3),
      // Tableau habilitations
      _buildHabilitationsTable(),
      pw.SizedBox(height: sectionGap),
      _bodyText(
        'Il est rappelé que des dispositions de sécurité particulières et parfaitement définies doivent être prises par le chef de l\'établissement '
        'pour toute intervention de maintenance, réglage, nettoyage sur ou à proximité des installations électriques.\n\n'
        'L\'accès aux locaux et armoires électriques doit être interdit par les personnes non autorisées.\n\n'
        'En effet, une installation, bien que déclarée conforme en phase d\'exploitation, peut lors d\'opérations, par exemple d\'entretien, '
        'nécessiter des précautions spéciales du fait de la présence à proximité de pièces nues sous tension '
        '(cas des locaux réservés aux électriciens et dans lesquels la réglementation n\'interdit pas la présence de pièces nues sous tension).',
      ),
      pw.SizedBox(height: sectionGap),

      _sectionBox('TECHNICIEN EN MAINTENANCE DES INSTALLATIONS'),
      pw.SizedBox(height: subGap),
      _bodyText('Il est fortement recommandé à l\'employer de faire participer aux employés, à des séances de formations sur les modules suivants :'),
      _bulletItem('Connaissance des normes en électricité (NC 244 C15 00...)'),
      _bulletItem('Maintenance des installations électriques'),
      pw.SizedBox(height: sectionGap),

      _subTitle('Engagement de KES INSPECTIONS AND PROJECTS'),
      _bodyText(
        'KES INSPECTIONS AND PROJECTS s\'engage à réaliser ses vérifications dans le strict respect des normes et règlements applicables, '
        'avec le souci constant de la sécurité, de la fiabilité technique et de l\'impartialité des constats.',
      ),
    ];
  }

  static pw.Widget _buildHabilitationsTable() {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: borderWidth),
      ),
      padding: pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SYMBOLES D\'HABILITATION ÉLECTRIQUE',
            style: pw.TextStyle(fontSize: fsH3, fontWeight: pw.FontWeight.bold, color: headerColor),
          ),
          pw.SizedBox(height: 4),
          _bodyText('B0 : Habilitation de base - Travaux hors tension'),
          _bodyText('BR : Habilitation de remplacement - Consignation'),
          _bodyText('BC : Habilitation de consignation'),
          _bodyText('BE : Habilitation d\'essai - Mesures'),
          _bodyText('BS : Habilitation de surveillance'),
          _bodyText('H0 : Habilitation hors tension pour non-électriciens'),
        ],
      ),
    );
  }

  // ============================================================
  //  OBJET DE LA VÉRIFICATION
  // ============================================================
  static List<pw.Widget> _buildObjetVerification() {
    return [
      _sectionBox('OBJET DE LA VERIFICATION'),
      pw.SizedBox(height: subGap),
      _bodyText(
        'La mission a pour objet de déceler les non-conformités, pouvant affecter la sécurité des personnes et des biens, et de s\'assurer du bon état de conservation des installations. '
        'Afin de présenter l\'état des lieux de l\'existant, les points sur lesquelles les installations s\'écartent des normes, textes applicables et de proposer des actions correctives.\n\n'
        'D\'une manière générale, la vérification a été étendue à l\'ensemble des installations électriques présentées et accessibles dans l\'établissement depuis les sources, jusqu\'aux points d\'utilisations.',
      ),
      pw.SizedBox(height: sectionGap),
      _bodyText('Ainsi sont exclus du champ de la vérification :'),
      _bulletItem('Les dispositions administratives, organisationnelles et techniques relatives à l\'information et à la formation du personnel (prescriptions au personnel) lors de l\'exploitation courante, de travaux ou d\'interventions sur les installations ainsi que les mesures de sécurité qui en découlent ;'),
      _bulletItem('Les dispositions administratives relatives aux documents à tenir à la disposition des autorités publiques'),
      _bulletItem('L\'examen des matériels électriques en présentation ou en démonstration et destinés à la vente ;'),
      _bulletItem('Les matériels stockés ou en réserve ou signalés comme n\'étant plus mis en oeuvre. Du fait que les installations sont examinées en tenant compte des contraintes d\'exploitation et de sécurité propres à chaque établissement et indiquées en début de vérification au personnel chargé de la vérification, celle-ci est limitée dans certains cas à l\'état apparent des installations.'),
      pw.SizedBox(height: sectionGap),

      _subTitle('Références normatives et réglementaires'),
      pw.SizedBox(height: 3),
      _buildNormesTable(),
      pw.SizedBox(height: sectionGap),

      _subTitle('Matériel utilisé'),
      pw.SizedBox(height: 3),
      _buildMaterielTable(),
    ];
  }

  static pw.Widget _buildNormesTable() {
    final normes = [
      'Articles 6, 112, 113_Arrêté 039/MTPS/IMT du 26 Novembre 1984 fixant les mesures générales d\'hygiène et de sécurité sur les lieux de travail',
      'Cahier de prescription technique applicable au Décret N° 20181969/PM du 15 Mars 2018, fixant les règles de base de sécurité incendie dans les bâtiments',
      'Arrête conjoint 002164 du 21 Juin 2012 MNIMIDT/MINEE',
      'Loi N°896/PJL/AN du 15/11/2011',
      'NC 244 C 15 100 - Installation électrique à basse tension',
      'NF C 15 100 - Installation électrique à basse tension',
      'Norme NF C 13 100 - Poste de livraison établi à l\'intérieur d\'un bâtiment et alimenté par un réseau de distribution publique de deuxième catégorie',
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: borderWidth),
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
      ['Mesure de la résistance de prises de terre', 'FLUKE - 1630 2 FC'],
      ['Mesure de l\'isolement', 'CHAUVIN ARNOUX CA 6462'],
      ['Vérification de la continuité et de la résistance des conducteurs de protection et des liaisons équipotentielles', 'CHAUVIN ARNOUX CA 6462'],
      ['Test de déclenchement des dispositifs différentiels et Mesure des impédances de boucle', 'CHAUVIN ARNOUX CA 6462'],
      ['Contrôleur d\'installation électrique', 'CHAUVIN ARNOUX CA 6116N'],
      ['Analyseur de réseaux', 'CHAUVIN ARNOUX PEL 103 140631NFH'],
    ];
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: borderWidth),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        _tableHeaderRow(['Description', 'Appareil / Référence']),
        ...materiel.asMap().entries.map((e) =>
          _tableDataRow(e.value, alt: e.key.isOdd)),
      ],
    );
  }

  // ============================================================
  //  RENSEIGNEMENTS GÉNÉRAUX
  // ============================================================
  static List<pw.Widget> _buildRenseignementsGeneraux(Mission mission) {
    return [
      _sectionBox('RENSEIGNEMENTS GENERAUX DE L\'ETABLISSEMENT'),
      pw.SizedBox(height: subGap),
      _subTitle('RENSEIGNEMENTS PRINCIPAUX'),
      pw.SizedBox(height: 3),

      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: borderWidth),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(3),
        },
        children: [
          _tableDataRow(['Etablissement vérifié', mission.nomClient], alt: false),
          if (mission.activiteClient != null)
            _tableDataRow(['Activité principale', mission.activiteClient!], alt: true),
          if (mission.adresseClient != null)
            _tableDataRow(['Adresse', mission.adresseClient!], alt: false),
          _tableDataRow(['Vérification - Nature', mission.natureMission ?? ''], alt: true),
          _tableDataRow(['Périodicité réglementaire', mission.periodicite ?? ''], alt: false),
          _tableDataRow(['Dates d\'intervention',
              mission.dateIntervention != null ? _formatDate(mission.dateIntervention!) : ''], alt: true),
          if (mission.dureeMissionJours != null)
            _tableDataRow(['Durée', '${mission.dureeMissionJours} jour(s)'], alt: false),
          if (mission.dgResponsable != null)
            _tableDataRow(['Accompagnateur / Responsable', mission.dgResponsable!], alt: true),
        ],
      ),

      pw.SizedBox(height: sectionGap),
      _subTitle('DOCUMENTS NECESSAIRES A LA VERIFICATION'),
      pw.SizedBox(height: 3),

      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: borderWidth),
        columnWidths: {
          0: const pw.FlexColumnWidth(4),
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

  static String _docStatus(bool? val) =>
      val == true ? 'Présenté' : 'Non présenté';

  // ============================================================
  //  DESCRIPTION DES INSTALLATIONS
  // ============================================================
  static List<pw.Widget> _buildDescriptionInstallations(DescriptionInstallations? desc) {
    final widgets = <pw.Widget>[
      _sectionBox('DESCRIPTION DES INSTALLATIONS'),
      pw.SizedBox(height: subGap),
    ];

    if (desc == null) {
      widgets.add(_bodyText('Aucune donnée disponible.'));
      return widgets;
    }

    // ── MT ──────────────────────────────────────────────────────
    if (desc.alimentationMoyenneTension.isNotEmpty) {
      widgets.add(_subTitle('Caractéristiques de l\'alimentation moyenne tension'));
      widgets.add(_buildInstallationTable(desc.alimentationMoyenneTension));
      widgets.add(pw.SizedBox(height: subGap));
    }

    // ── BT ──────────────────────────────────────────────────────
    if (desc.alimentationBasseTension.isNotEmpty) {
      widgets.add(_subTitle('Caractéristiques de l\'alimentation basse tension sortie transformateur'));
      widgets.add(_buildInstallationTable(desc.alimentationBasseTension));
      widgets.add(pw.SizedBox(height: subGap));
    }

    // ── Groupe électrogène ──────────────────────────────────────
    if (desc.groupeElectrogene.isNotEmpty) {
      widgets.add(_subTitle('Caractéristiques du groupe électrogène'));
      widgets.add(_buildInstallationTable(desc.groupeElectrogene));
      widgets.add(pw.SizedBox(height: subGap));
    }

    // ── Carburant ───────────────────────────────────────────────
    if (desc.alimentationCarburant.isNotEmpty) {
      widgets.add(_subTitle('Alimentation du groupe électrogène en carburant'));
      widgets.add(_buildInstallationTable(desc.alimentationCarburant));
      widgets.add(pw.SizedBox(height: subGap));
    }

    // ── Inverseur ───────────────────────────────────────────────
    if (desc.inverseur.isNotEmpty) {
      widgets.add(_subTitle('Caractéristiques de l\'inverseur'));
      widgets.add(_buildInstallationTable(desc.inverseur));
      widgets.add(pw.SizedBox(height: subGap));
    }

    // ── Stabilisateur ───────────────────────────────────────────
    widgets.add(_subTitle('Caractéristiques du stabilisateur'));
    if (desc.stabilisateur.isNotEmpty) {
      widgets.add(_buildInstallationTable(desc.stabilisateur));
    } else {
      widgets.add(_bodyText('- Pas de stabilisateur'));
    }
    widgets.add(pw.SizedBox(height: subGap));

    // ── Onduleurs ───────────────────────────────────────────────
    if (desc.onduleurs.isNotEmpty) {
      widgets.add(_subTitle('Caractéristiques des onduleurs'));
      widgets.add(_buildInstallationTable(desc.onduleurs));
      widgets.add(pw.SizedBox(height: subGap));
    }

    // ── Caractéristiques générales ──────────────────────────────
    widgets.add(_subTitle('Régime de neutre'));
    widgets.add(_bodyText('- ${desc.regimeNeutre ?? 'TT'}'));
    widgets.add(pw.SizedBox(height: 2));

    widgets.add(_subTitle('Eclairage de sécurité'));
    widgets.add(_bodyText('- ${desc.eclairageSecurite ?? 'Présent'}'));
    widgets.add(pw.SizedBox(height: 2));

    widgets.add(_subTitle('Modifications apportées aux installations'));
    widgets.add(_bodyText('Modifications apportées aux installations : ${desc.modificationsInstallations ?? 'Sans Objet'}'));
    widgets.add(pw.SizedBox(height: 2));

    widgets.add(_subTitle('Note de calcul des installations électriques'));
    widgets.add(_bodyText('- ${desc.noteCalcul ?? 'Non transmis'}'));
    widgets.add(pw.SizedBox(height: 2));

    widgets.add(_subTitle('Présence de paratonnerre'));
    widgets.add(_bodyText('Présence de paratonnerre : ${desc.presenceParatonnerre ?? 'NON'}'));
    widgets.add(_bodyText('Analyse risque foudre : ${desc.analyseRisqueFoudre ?? ''}'));
    widgets.add(_bodyText('Etude technique foudre : ${desc.etudeTechniqueFoudre ?? ''}'));
    widgets.add(pw.SizedBox(height: 2));

    widgets.add(_subTitle('Registre de sécurité'));
    widgets.add(_bodyText('- ${desc.registreSecurite ?? 'Non transmis'}'));

    return widgets;
  }

  static pw.Widget _buildInstallationTable(List<InstallationItem> items) {
    if (items.isEmpty) return pw.Container();
    final fields = <String>{};
    for (var it in items) fields.addAll(it.data.keys);
    final cols = fields.toList()..sort();
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: borderWidth),
      children: [
        _tableHeaderRow(cols),
        ...items.asMap().entries.map((e) =>
          _tableDataRow(cols.map((c) => e.value.data[c]?.toString() ?? '-').toList(), alt: e.key.isOdd)),
      ],
    );
  }

  // ============================================================
  //  LISTE RÉCAPITULATIVE DES OBSERVATIONS
  // ============================================================
  static List<pw.Widget> _buildListeRecapitulative(AuditInstallationsElectriques audit) {
    final widgets = <pw.Widget>[
      _sectionBox('LISTE RECAPITULATIVE DES OBSERVATIONS'),
      pw.SizedBox(height: subGap),
      _subTitle('Niveau de priorité des observations constatées'),
      pw.SizedBox(height: 3),
      pw.Row(
        children: [
          _badgePriorite('1', priorite1Color), pw.SizedBox(width: 4),
          _bodyText('Niveau 1 : À surveiller'),
          pw.SizedBox(width: 16),
          _badgePriorite('2', priorite2Color), pw.SizedBox(width: 4),
          _bodyText('Niveau 2 : Mise en conformité à planifier'),
          pw.SizedBox(width: 16),
          _badgePriorite('3', priorite3Color), pw.SizedBox(width: 4),
          _bodyText('Niveau 3 : Critique, Action immédiate'),
        ],
      ),
      pw.SizedBox(height: sectionGap),
    ];

    // ── Collecter toutes les observations MT ────────────────────
    final obsMT = _collectObservationsMT(audit);
    final obsBT = _collectObservationsBT(audit);

    widgets.add(_subTitle('Moyenne tension'));
    widgets.add(pw.SizedBox(height: 3));
    widgets.add(_buildObsRecapTable(obsMT));

    widgets.add(pw.SizedBox(height: sectionGap));
    widgets.add(_subTitle('Basse tension'));
    widgets.add(pw.SizedBox(height: 3));
    widgets.add(_buildObsRecapTable(obsBT));

    return widgets;
  }

  static pw.Widget _badgePriorite(String p, PdfColor color) {
    return pw.Container(
      width: 14, height: 14,
      decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
      alignment: pw.Alignment.center,
      child: pw.Text(p, style: pw.TextStyle(fontSize: fsSmall, fontWeight: pw.FontWeight.bold)),
    );
  }

  static List<_ObsRecap> _collectObservationsMT(AuditInstallationsElectriques audit) {
    final list = <_ObsRecap>[];
    for (var local in audit.moyenneTensionLocaux) {
      for (var coffret in local.coffrets) {
        for (var pv in coffret.pointsVerification) {
          if (pv.conformite == 'Non' || pv.conformite == 'Non conforme') {
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
          if (pv.conformite == 'Non' || pv.conformite == 'Non conforme') {
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
        decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor, width: borderWidth)),
        padding: pw.EdgeInsets.all(4),
        child: pw.Text('Aucune observation', style: pw.TextStyle(fontSize: fsSmall, fontStyle: pw.FontStyle.italic)),
      );
    }

    final headers = ['LOCALISATION', 'COFFRET / ARMOIRE', 'NON-CONFORMITÉ - PRÉCONISATION', 'RÉF. NORMATIVE', 'PRIORITÉ'];

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: borderWidth),
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
          if (o.priorite == '3') rowColor = PdfColor.fromInt(0xFFFFEEEE);
          else if (o.priorite == '2') rowColor = PdfColor.fromInt(0xFFFFF8EE);
          else if (e.key.isOdd) rowColor = tableRowAlt;
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

  // ============================================================
  //  AUDIT DES INSTALLATIONS ÉLECTRIQUES
  // ============================================================
  static List<pw.Widget> _buildAuditInstallations(AuditInstallationsElectriques audit) {
    final widgets = <pw.Widget>[
      _sectionBox('AUDIT DES INSTALLATIONS ELECTRIQUES'),
      pw.SizedBox(height: subGap),
    ];

    // ── Zones MT avec locaux ────────────────────────────────────
    for (var zone in audit.moyenneTensionZones) {
      widgets.addAll(_buildZone(zone.nom, zone.observationsLibres));
      for (var local in zone.locaux) {
        widgets.addAll(_buildLocalMT(local));
      }
      for (var coffret in zone.coffrets) {
        widgets.addAll(_buildCoffret(coffret));
      }
    }

    // ── Locaux MT directs ───────────────────────────────────────
    for (var local in audit.moyenneTensionLocaux) {
      widgets.addAll(_buildLocalMT(local));
    }

    // ── Zones BT ────────────────────────────────────────────────
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

  // ── Zone ──────────────────────────────────────────────────────
  static List<pw.Widget> _buildZone(String nom, List<ObservationLibre> obs) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: sectionGap),
      pw.Container(
        width: double.infinity,
        color: headerColor,
        padding: pw.EdgeInsets.symmetric(horizontal: cellPadH, vertical: cellPadV + 1),
        child: pw.Text(nom.toUpperCase(),
            style: pw.TextStyle(fontSize: fsH2, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
      ),
    ];

    if (obs.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 3));
      widgets.add(_buildObsZoneTable(nom, obs));
    }

    widgets.add(pw.SizedBox(height: 3));
    return widgets;
  }

  static pw.Widget _buildObsZoneTable(String zone, List<ObservationLibre> obs) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: borderWidth),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            _cell('Items', isHeader: true, color: PdfColors.white),
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

  // ── Local MT ──────────────────────────────────────────────────
  static List<pw.Widget> _buildLocalMT(MoyenneTensionLocal local) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 3),
      _subSectionBar(local.nom.toUpperCase()),
      pw.SizedBox(height: 3),
    ];

    // Dispositions constructives
    if (local.dispositionsConstructives.isNotEmpty) {
      widgets.add(_buildDispositionsTable(local.dispositionsConstructives, 'DISPOSITIONS CONSTRUCTIVES DU LOCAL'));
      widgets.add(pw.SizedBox(height: 3));
    }

    // Conditions d'exploitation
    if (local.conditionsExploitation.isNotEmpty) {
      widgets.add(_buildDispositionsTable(local.conditionsExploitation, 'CONDITIONS D\'EXPLOITATION ET DE SÉCURITÉ'));
      widgets.add(pw.SizedBox(height: 3));
    }

    // Cellule
    if (local.cellule != null) {
      widgets.addAll(_buildCelluleSection(local.cellule!));
    }

    // Transformateur
    if (local.transformateur != null) {
      widgets.addAll(_buildTransformateurSection(local.transformateur!));
    }

    // Coffrets
    for (var coffret in local.coffrets) {
      widgets.addAll(_buildCoffret(coffret));
    }

    return widgets;
  }

  // ── Local BT ──────────────────────────────────────────────────
  static List<pw.Widget> _buildLocalBT(BasseTensionLocal local) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 3),
      _subSectionBar(local.nom.toUpperCase()),
      pw.SizedBox(height: 3),
    ];

    if (local.dispositionsConstructives != null && local.dispositionsConstructives!.isNotEmpty) {
      widgets.add(_buildDispositionsTable(local.dispositionsConstructives!, 'DISPOSITIONS CONSTRUCTIVES DU LOCAL'));
      widgets.add(pw.SizedBox(height: 3));
    }

    if (local.conditionsExploitation != null && local.conditionsExploitation!.isNotEmpty) {
      widgets.add(_buildDispositionsTable(local.conditionsExploitation!, 'CONDITIONS D\'EXPLOITATION ET DE SÉCURITÉ'));
      widgets.add(pw.SizedBox(height: 3));
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
      padding: pw.EdgeInsets.symmetric(horizontal: cellPadH, vertical: cellPadV),
      child: pw.Text(title,
          style: pw.TextStyle(fontSize: fsH3, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    );
  }

  // ── Dispositions constructives / conditions ───────────────────
  static pw.Widget _buildDispositionsTable(List<ElementControle> elements, String titre) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: borderWidth),
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
        _tableHeaderRow(['Éléments contrôlés', 'Conformité', 'Observations / Anomalies constatées']),
        ...elements.asMap().entries.map((e) {
          final el = e.value;
          final conf = el.conforme ? 'Oui' : 'Non';
          final confColor = el.conforme ? conformeColor : nonConformeColor;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: e.key.isEven ? PdfColors.white : tableRowAlt),
            children: [
              _cell(el.elementControle, isHeader: false),
              pw.Container(
                color: confColor,
                padding: pw.EdgeInsets.symmetric(horizontal: cellPadH, vertical: cellPadV),
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

  // ── Cellule MT ────────────────────────────────────────────────
  static List<pw.Widget> _buildCelluleSection(Cellule cellule) {
    return [
      pw.SizedBox(height: 3),
      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: borderWidth),
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
          _tableDataRow(['Marque / modèle / année', cellule.marqueModeleAnnee, 'Tension assignée', cellule.tensionAssignee], alt: true),
          _tableDataRow(['Pouvoir de coupure assigné (kA)', cellule.pouvoirCoupure, 'Numérotation / repérage', cellule.numerotation], alt: false),
          _tableDataRow(['Parafoudres installés sur l\'arrivée', cellule.parafoudres, '', ''], alt: true),
        ],
      ),
      if (cellule.elementsVerifies.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        _buildDispositionsTable(cellule.elementsVerifies, 'Éléments vérifiés de la cellule'),
      ],
      pw.SizedBox(height: 3),
    ];
  }

  // ── Transformateur MT/BT ──────────────────────────────────────
  static List<pw.Widget> _buildTransformateurSection(TransformateurMTBT transfo) {
    return [
      pw.SizedBox(height: 3),
      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: borderWidth),
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
          _tableDataRow(['Type de transformateur', transfo.typeTransformateur, 'Marque / Année', transfo.marqueAnnee], alt: false),
          _tableDataRow(['Puissance assignée (kVA)', transfo.puissanceAssignee, 'Tension primaire / secondaire', transfo.tensionPrimaireSecondaire], alt: true),
          _tableDataRow(['Présence du relais Buchholz', transfo.relaisBuchholz, 'Type de refroidissement', transfo.typeRefroidissement], alt: false),
          _tableDataRow(['Régime du neutre', transfo.regimeNeutre, '', ''], alt: true),
        ],
      ),
      if (transfo.elementsVerifies.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        _buildDispositionsTable(transfo.elementsVerifies, 'Éléments vérifiés du transformateur'),
      ],
      pw.SizedBox(height: 3),
    ];
  }

  // ── Coffret / Armoire ─────────────────────────────────────────
  static List<pw.Widget> _buildCoffret(CoffretArmoire coffret) {
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 3),
    ];

    // Bloc identification
    widgets.add(pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: borderWidth),
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
              padding: pw.EdgeInsets.all(cellPadH),
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
            _cell('Présence schéma : ${coffret.presenceSchema ? "Oui" : "Non"}', isHeader: false),
            _cell('Présence parafoudre : ${coffret.presenceParafoudre ? "Oui" : "Non"}', isHeader: false),
            _cell('Thermographie : ${coffret.verificationThermographie ? "Oui" : "Non"}', isHeader: false),
            if (coffret.repere != null)
              _cell('Repère : ${coffret.repere}', isHeader: false)
            else
              _cell('', isHeader: false),
            _cell('', isHeader: false),
          ],
        ),
      ],
    ));

    // Alimentation
    if (coffret.alimentations.isNotEmpty || coffret.protectionTete != null) {
      widgets.add(pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: borderWidth),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1),
          4: const pw.FlexColumnWidth(1.2),
        },
        children: [
          _tableHeaderRow(['Source', 'Type de protection', 'PDC kA', 'Calibre', 'Section de câble']),
          ...coffret.alimentations.map((a) =>
            _tableDataRow(['Alimentation', a.typeProtection, a.pdcKA, a.calibre, a.sectionCable], alt: false)),
          if (coffret.protectionTete != null)
            _tableDataRow(['Protection de tête', coffret.protectionTete!.typeProtection, coffret.protectionTete!.pdcKA, '', ''], alt: coffret.alimentations.isNotEmpty),
        ],
      ));
    }

    // Points de vérification
    if (coffret.pointsVerification.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 2));
      widgets.add(_buildPointsVerificationTable(coffret.pointsVerification));
    }

    // Observations
    if (coffret.observationsLibres.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 2));
      widgets.add(_buildSimpleObsTable(coffret.observationsLibres, 'Observations du coffret'));
    }

    widgets.add(pw.SizedBox(height: 3));
    return widgets;
  }

  static pw.Widget _buildPointsVerificationTable(List<PointVerification> points) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: borderWidth),
      columnWidths: {
        0: const pw.FlexColumnWidth(3.5),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(2.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        _tableHeaderRow(['Points de vérification', 'Conformité', 'Observation', 'Référence normative']),
        ...points.asMap().entries.map((e) {
          final pv = e.value;
          final isConf = pv.conformite == 'Oui';
          final confColor = pv.conformite == 'non_applicable'
              ? tableRowAlt
              : (isConf ? conformeColor : nonConformeColor);
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: e.key.isEven ? PdfColors.white : tableRowAlt),
            children: [
              _cell(pv.pointVerification, isHeader: false),
              pw.Container(
                color: confColor,
                padding: pw.EdgeInsets.symmetric(horizontal: cellPadH, vertical: cellPadV),
                alignment: pw.Alignment.center,
                child: pw.Text(pv.conformite=='non_applicable'?'NA':pv.conformite=='non'?'Non':'Oui', style: pw.TextStyle(fontSize: fsSmall)),
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
      border: pw.TableBorder.all(color: borderColor, width: borderWidth),
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

  // ============================================================
  //  CLASSEMENT DES EMPLACEMENTS
  // ============================================================
  static List<pw.Widget> _buildClassementEmplacements(List<ClassementEmplacement> classements) {
    final widgets = <pw.Widget>[
      _sectionBox('CLASSEMENT DES LOCAUX ET EMPLACEMENTS EN FONCTION DES INFLUENCES EXTERNES'),
      pw.SizedBox(height: subGap),
      _bodyText(
        'Dans le cas d\'absence de fourniture d\'une liste exhaustive des risques particuliers, le classement éventuel ci-après est proposé par le vérificateur et, sauf avis contraire, considéré comme validé par le chef d\'établissement.',
      ),
      pw.SizedBox(height: sectionGap),
      pw.Table(
        border: pw.TableBorder.all(color: borderColor, width: borderWidth),
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
      pw.SizedBox(height: sectionGap),
      // Tableau de codification
      _buildCodificationInfluences(),
    ];

    return widgets;
  }

  static pw.Widget _buildCodificationInfluences() {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: borderWidth),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            _cell('CODIFICATION DES INFLUENCES EXTERNES - INDICES ET DEGRÉS DE PROTECTION', isHeader: true, colspan: 3),
          ],
        ),
        _tableHeaderRow(['PÉNÉTRATION DE CORPS SOLIDES', 'SUBSTANCES CORROSIVES OU POLLUANTES', 'MATIÈRES TRAITÉES OU ENTREPOSÉES']),
        _tableDataRow(['AE1 : Négligeable -> IP 2X', 'AF1 : Négligeable', 'BE1 : Risques négligeables'], alt: false),
        _tableDataRow(['AE2 : Petits objets (≥ 2,5 mm) -> IP 3X', 'AF2 : Agents d\'origine atmosphérique', 'BE2 : Risques d\'incendie'], alt: true),
        _tableDataRow(['AE3 : Très petits objets (1 à 2,5 mm) -> IP 4X', 'AF3 : Intermittente ou accidentelle', 'BE3 : Risques d\'explosion'], alt: false),
        _tableDataRow(['AE4 : Poussières -> IP 5X (Protégé)', 'AF4 : Permanente', 'BE4 : Risques de contamination'], alt: true),
        _tableHeaderRow(['ACCÈS AUX PARTIES DANGEREUSES', 'PÉNÉTRATION DE LIQUIDES', 'RISQUES DE CHOCS MÉCANIQUES']),
        _tableDataRow(['Non protégé -> IP 0X', 'AD1 : Négligeable -> IP X0', 'AG1 : Faibles (0,225 J) -> IK 02'], alt: false),
        _tableDataRow(['A : Avec le dos de la main -> IP 1X', 'AD2 : Chutes de gouttes d\'eau -> IP X1', 'AG2 : Moyens (2 J) -> IK 07'], alt: true),
        _tableDataRow(['B : Avec un doigt -> IP 2X', 'AD3 : Chutes de gouttes jusqu\'à 15° -> IP X2', 'AG3 : Importants (5 J) -> IK 08'], alt: false),
        _tableDataRow(['C : Avec un outil -> IP 3X', 'AD4 : Aspersion d\'eau -> IP X3', 'AG4 : Très importants (20 J) -> IK 10'], alt: true),
        _tableDataRow(['D : Avec un fil -> IP 4X', 'AD5 : Projections d\'eau -> IP X4', ''], alt: false),
        _tableDataRow(['', 'AD6 : Jets d\'eau -> IP X5', ''], alt: true),
        _tableDataRow(['', 'AD7 : Paquets d\'eau -> IP X6', ''], alt: false),
        _tableDataRow(['', 'AD8 : Immersion -> IP X7', ''], alt: true),
        _tableDataRow(['', 'AD9 : Submersion -> IP X8', ''], alt: false),
        _tableHeaderRow(['COMPÉTENCE DES PERSONNES', 'VIBRATIONS', '']),
        _tableDataRow(['BA1 : Ordinaires', 'AH1 : Faibles', ''], alt: false),
        _tableDataRow(['BA2 : Enfants', 'AH2 : Moyennes', ''], alt: true),
        _tableDataRow(['BA3 : Personnes handicapées', 'AH3 : Importantes', ''], alt: false),
        _tableDataRow(['BA4 : Personnes averties', '', ''], alt: true),
        _tableDataRow(['BA5 : Personnes qualifiées', '', ''], alt: false),
      ],
    );
  }

  // ============================================================
  //  FOUDRE
  // ============================================================
  static List<pw.Widget> _buildFoudre(List<Foudre> foudres) {
    final widgets = <pw.Widget>[
      _sectionBox('FOUDRE'),
      pw.SizedBox(height: subGap),
    ];

    if (foudres.isEmpty) {
      widgets.add(_bodyText('Aucune observation foudre disponible.'));
      return widgets;
    }

    foudres.sort((a, b) => a.niveauPriorite.compareTo(b.niveauPriorite));

    widgets.add(pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: borderWidth),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(0.5),
        2: const pw.FlexColumnWidth(5),
      },
      children: [
        _tableHeaderRow(['Items', 'Priorité', 'Observations']),
        ...foudres.asMap().entries.map((e) {
          final f = e.value;
          PdfColor rowColor = e.key.isOdd ? tableRowAlt : PdfColors.white;
          if (f.niveauPriorite == 3) rowColor = PdfColor.fromInt(0xFFFFEBEB);
          else if (f.niveauPriorite == 2) rowColor = PdfColor.fromInt(0xFFFFF8E8);
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowColor),
            children: [
              _cell('${e.key + 1}', isHeader: false),
              pw.Container(
                alignment: pw.Alignment.center,
                padding: pw.EdgeInsets.all(cellPadV),
                child: pw.Text('${f.niveauPriorite}',
                    style: pw.TextStyle(fontSize: fsBody, fontWeight: pw.FontWeight.bold,
                        color: f.niveauPriorite == 3 ? PdfColors.red800 : darkGrey)),
              ),
              _cell(f.observation, isHeader: false),
            ],
          );
        }),
      ],
    ));

    return widgets;
  }

  // ============================================================
  //  RÉSULTATS DES MESURES ET ESSAIS
  // ============================================================
  static List<pw.Widget> _buildMesuresEssais(MesuresEssais mesures) {
    final widgets = <pw.Widget>[
      _sectionBox('RESULTATS DES MESURES ET ESSAIS'),
      pw.SizedBox(height: subGap),
    ];

    // ── 1. Conditions de mesure ──────────────────────────────────
    widgets.add(_subSectionBar('Conditions de mesure'));
    widgets.add(pw.SizedBox(height: 3));
    widgets.add(_bodyBold('MESURES D\'ISOLEMENT'));
    widgets.add(_bodyText(
      'Les mesures d\'isolement par rapport à la terre sont effectuées sous 500 V continu sur les canalisations en aval des DDR défectueux ou sur les canalisations pour lesquelles il a été constaté une absence de DDR nécessaire pour la protection des personnes (contacts indirects), '
      'sur les matériels amovibles hors tension, ou sur les récepteurs dont la liaison à la terre a été jugée défectueuse. La valeur est considérée comme satisfaisante si elle est supérieure à 0,5 M.ohms.',
    ));
    widgets.add(pw.SizedBox(height: 3));
    widgets.add(_bodyBold('VERIFICATION DE LA CONTINUITE ET DE LA RESISTANCE DES CONDUCTEURS DE PROTECTION ET DES LIAISONS EQUIPOTENTIELLES'));
    widgets.add(_bodyText(
      'La vérification de la continuité des conducteurs de protection est effectuée à l\'aide d\'un ohmmètre ou d\'un milliohmmètre. Elle est correcte si la valeur mesurée satisfait aux prescriptions du guide UTE C 15-105 § D6.',
    ));
    widgets.add(pw.SizedBox(height: 3));
    widgets.add(_bodyBold('ESSAIS DE DECLENCHEMENT DES DISPOSITIFS DIFFERENTIELS RESIDUELS'));
    widgets.add(_bodyText(
      'La valeur du seuil de déclenchement est correcte si elle est comprise entre 0,5 IAn et IAn (An : sensibilité du dispositif différentiel). Les essais sont réalisés entre une phase et la terre. '
      'En cas de manque de sélectivité, les essais sont réalisés entre le neutre ou une phase amont et une autre phase en aval.',
    ));
    widgets.add(pw.SizedBox(height: 3));
    widgets.add(_bodyBold('MESURE DES IMPEDANCES DE BOUCLE (PROTECTION « CONTACTS INDIRECTS »)'));
    widgets.add(_bodyText(
      'Cette mesure est effectuée si nécessaire à l\'aide d\'un milliohmmètre de boucle. Le dispositif de protection est correct si son temps de coupure, pour le courant de défaut déterminé, satisfait aux prescriptions du guide UTE C 15-105.',
    ));

    if (mesures.conditionMesure.observation != null && mesures.conditionMesure.observation!.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 3));
      widgets.add(_bodyText(mesures.conditionMesure.observation!));
    }
    widgets.add(pw.SizedBox(height: sectionGap));

    // ── 2. Essais de démarrage automatique ───────────────────────
    widgets.add(_subSectionBar('Essais de démarrage automatique du groupe électrogène'));
    widgets.add(pw.SizedBox(height: 3));
    final demarrageObs = mesures.essaiDemarrageAuto.observation ?? 'Non satisfaisant';
    widgets.add(_resultBox(demarrageObs));
    widgets.add(pw.SizedBox(height: sectionGap));

    // ── 3. Test d'arrêt d'urgence ────────────────────────────────
    widgets.add(_subSectionBar('Test de fonctionnement de l\'arrêt d\'urgence'));
    widgets.add(pw.SizedBox(height: 3));
    final arretObs = mesures.testArretUrgence.observation ?? 'Satisfaisant';
    widgets.add(_resultBox(arretObs));
    widgets.add(pw.SizedBox(height: sectionGap));

    // ── 4. Prises de terre ───────────────────────────────────────
    widgets.add(_subSectionBar('Prise de terre'));
    widgets.add(pw.SizedBox(height: 3));
    widgets.add(_bodyText('Non satisfaisant'));
    widgets.add(pw.SizedBox(height: 3));

    widgets.add(pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: borderWidth),
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
          'Méthode de mesure', 'Valeur de la mesure', 'Observation'
        ]),
        if (mesures.prisesTerre.isEmpty)
          pw.TableRow(children: List.generate(7, (_) => _cell('', isHeader: false)))
        else
          ...mesures.prisesTerre.asMap().entries.map((e) {
            final pt = e.value;
            return _tableDataRow([
              pt.localisation, pt.identification, pt.conditionMesure,
              pt.naturePriseTerre, pt.methodeMesure,
              pt.valeurMesure?.toStringAsFixed(2) ?? '-',
              pt.observation ?? '',
            ], alt: e.key.isOdd);
          }),
      ],
    ));

    // Avis sur les mesures
    if (mesures.avisMesuresTerre.observation != null && mesures.avisMesuresTerre.observation!.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 3));
      if (mesures.avisMesuresTerre.satisfaisants.isNotEmpty) {
        widgets.add(_bodyText('Prises de terre satisfaisantes : ${mesures.avisMesuresTerre.satisfaisants.join(', ')}'));
      }
      if (mesures.avisMesuresTerre.nonSatisfaisants.isNotEmpty) {
        widgets.add(_bodyText('Prises de terre non satisfaisantes : ${mesures.avisMesuresTerre.nonSatisfaisants.join(', ')}'));
      }
      widgets.add(pw.SizedBox(height: 2));
      widgets.add(_bodyText(mesures.avisMesuresTerre.observation!));
    }
    widgets.add(pw.SizedBox(height: sectionGap));

    // ── 5. Mesures d'isolement ───────────────────────────────────
    widgets.add(_subSectionBar('Mesures d\'isolement des circuits BT'));
    widgets.add(pw.SizedBox(height: 3));
    widgets.add(_bodyText('Sans observation'));
    widgets.add(pw.SizedBox(height: sectionGap));

    // ── 6. Essais de déclenchement ───────────────────────────────
    widgets.add(_subSectionBar('Essais de déclenchement des dispositifs différentiels'));
    widgets.add(pw.SizedBox(height: 3));

    widgets.add(pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: borderWidth),
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
          'Quantité', 'Désignation circuit', 'Type de dispositif',
          'Réglage In (mA)', 'Tempo (s)', 'Essai', 'Isolement (M ampe)'
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
                  padding: pw.EdgeInsets.symmetric(horizontal: cellPadH, vertical: cellPadV),
                  alignment: pw.Alignment.center,
                  child: pw.Text(es.essai, style: pw.TextStyle(fontSize: fsSmall)),
                ),
                _cell(es.isolement?.toString() ?? '-', isHeader: false),
              ],
            );
          }),
      ],
    ));

    // Tableau abréviations
    widgets.add(pw.SizedBox(height: sectionGap));
    widgets.add(pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: borderWidth),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: lightBlue),
          children: [
            _cell('Signification des abréviations utilisées', isHeader: true, colspan: 2),
          ],
        ),
        _tableHeaderRow(['Abréviation', 'Signification']),
        _tableDataRow(['DDR', 'Disjoncteur Différentiel'], alt: false),
        _tableDataRow(['RD', 'Relais Différentiel'], alt: true),
        _tableDataRow(['B', 'Bon fonctionnement'], alt: false),
        _tableDataRow(['NE', 'Non essayé'], alt: true),
        _tableDataRow(['IDR', 'Interrupteur Différentiel'], alt: false),
        _tableDataRow(['In', 'Intensité différentielle'], alt: true),
        _tableDataRow(['M', 'Fonctionnement incorrect'], alt: false),
        _tableDataRow(['Tempo', 'Temporisation'], alt: true),
      ],
    ));
    widgets.add(pw.SizedBox(height: sectionGap));

    // ── 7. Continuité et résistance ──────────────────────────────
    widgets.add(_subSectionBar('Continuité et de la résistance des conducteurs de protection et des liaisons équipotentielles'));
    widgets.add(pw.SizedBox(height: 3));
    widgets.add(pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: borderWidth),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        _tableHeaderRow([
          'Localisation', 'Désignation Tableau / Equipement',
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
    ));

    return widgets;
  }

  static pw.Widget _resultBox(String text) {
    final isOk = text.toLowerCase().contains('satisfaisant') && !text.toLowerCase().contains('non');
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: isOk ? conformeColor : nonConformeColor,
        border: pw.Border.all(color: borderColor, width: borderWidth),
      ),
      padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Text(text, style: pw.TextStyle(fontSize: fsBody)),
    );
  }

  // ============================================================
  //  PHOTOS
  // ============================================================
  static Future<void> _addPhotosSection(
      pw.Document pdf, Mission mission, String missionId,
      AuditInstallationsElectriques? audit, pw.MemoryImage? logoKes) async {
    final allPhotos = <_PhotoEntry>[];

    if (audit != null) {
      for (var local in audit.moyenneTensionLocaux) {
        _addPhotosFromList(allPhotos, local.photos, local.nom);
        if (local.cellule != null) _addPhotosFromList(allPhotos, local.cellule!.photos, '${local.nom} - Cellule');
        if (local.transformateur != null) _addPhotosFromList(allPhotos, local.transformateur!.photos, '${local.nom} - Transformateur');
        for (var c in local.coffrets) _addPhotosFromList(allPhotos, c.photos, '${local.nom} - ${c.nom}');
      }
      for (var zone in audit.moyenneTensionZones) {
        _addPhotosFromList(allPhotos, zone.photos, zone.nom);
        for (var c in zone.coffrets) _addPhotosFromList(allPhotos, c.photos, '${zone.nom} - ${c.nom}');
        for (var local in zone.locaux) {
          _addPhotosFromList(allPhotos, local.photos, '${zone.nom} - ${local.nom}');
          for (var c in local.coffrets) _addPhotosFromList(allPhotos, c.photos, '${zone.nom} - ${local.nom} - ${c.nom}');
        }
      }
      for (var zone in audit.basseTensionZones) {
        _addPhotosFromList(allPhotos, zone.photos, zone.nom);
        for (var c in zone.coffretsDirects) _addPhotosFromList(allPhotos, c.photos, '${zone.nom} - ${c.nom}');
        for (var local in zone.locaux) {
          _addPhotosFromList(allPhotos, local.photos, '${zone.nom} - ${local.nom}');
          for (var c in local.coffrets) _addPhotosFromList(allPhotos, c.photos, '${zone.nom} - ${local.nom} - ${c.nom}');
        }
      }
    }

    // Page liste des photos
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.symmetric(horizontal: pageMarginH, vertical: pageMarginV),
      header: (ctx) => _buildPageHeader(mission, logoKes),
      footer: (ctx) => _buildFooter(ctx),
      build: (ctx) => [
        _sectionBox('PHOTOS'),
        pw.SizedBox(height: subGap),
        if (allPhotos.isEmpty)
          _bodyText('Aucune photo disponible.')
        else ...[
          _bodyText('Liste des photos prises lors de l\'audit :'),
          pw.SizedBox(height: 3),
          pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: borderWidth),
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
    ));

    // Pages individuelles de photos
    for (int i = 0; i < allPhotos.length; i++) {
      final entry = allPhotos[i];
      try {
        final file = File(entry.filePath);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        final img = pw.MemoryImage(bytes);
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.symmetric(horizontal: pageMarginH, vertical: pageMarginV),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              _buildPageHeader(mission, logoKes),
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
              _buildFooter(ctx),
            ],
          ),
        ));
      } catch (e) {
        print('❌ Erreur photo ${entry.filePath}: $e');
      }
    }
  }

  static void _addPhotosFromList(List<_PhotoEntry> list, List<String> photos, String description) {
    for (var p in photos) {
      if (p.isNotEmpty) list.add(_PhotoEntry(filePath: p, description: description));
    }
  }

  // ============================================================
  //  UTILITAIRES PDF (cellules, lignes, titres…)
  // ============================================================
  static pw.Widget _sectionBox(String title) {
    return pw.Container(
      width: double.infinity,
      color: headerColor,
      padding: pw.EdgeInsets.symmetric(horizontal: cellPadH + 2, vertical: cellPadV + 2),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: fsH1, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: accentColor, width: 1.5)),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(fontSize: fsH1, fontWeight: pw.FontWeight.bold, color: headerColor)),
    );
  }

  static pw.Widget _subTitle(String title) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: subGap, bottom: 2),
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
      padding: pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: fsBody, color: darkGrey, lineSpacing: 1.4)),
    );
  }

  static pw.Widget _bodyBold(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: fsBody, fontWeight: pw.FontWeight.bold, color: darkGrey)),
    );
  }

  static pw.Widget _bulletItem(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(left: 10, bottom: 2),
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

  // ── Table helpers ─────────────────────────────────────────────
  static pw.Widget _cell(String text, {required bool isHeader, PdfColor? color, int colspan = 1}) {
    return pw.Container(
      color: color,
      padding: pw.EdgeInsets.symmetric(horizontal: cellPadH, vertical: cellPadV),
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

  // ============================================================
  //  HELPERS DIVERS
  // ============================================================
  static String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  static Future<void> shareReport(File file) async {
    try {
      await Share.shareXFiles([XFile(file.path)],
          subject: 'Rapport d\'Audit Électrique PDF',
          text: 'Veuillez trouver ci-joint le rapport d\'audit électrique.');
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

// ============================================================
//  Classes internes
// ============================================================
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