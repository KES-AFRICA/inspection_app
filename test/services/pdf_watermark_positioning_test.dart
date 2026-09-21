import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/services/pdf/builders/pdf_cover_builder.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late pw.MemoryImage watermarkImage;
  late pw.MemoryImage logoKesImage;
  late pw.Font fontRegular;
  late pw.Font fontBold;

  setUpAll(() {
    final watermarkBytes = File('assets/images/filigranne_image.png').readAsBytesSync();
    watermarkImage = pw.MemoryImage(watermarkBytes);

    final logoBytes = File('assets/images/logo.png').readAsBytesSync();
    logoKesImage = pw.MemoryImage(logoBytes);

    final regData = File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync();
    final boldData = File('assets/fonts/Roboto-Bold.ttf').readAsBytesSync();
    fontRegular = pw.Font.ttf(regData.buffer.asByteData());
    fontBold = pw.Font.ttf(boldData.buffer.asByteData());

    PdfCoverBuilder.fontRegular = fontRegular;
    PdfCoverBuilder.fontBold = fontBold;
    PdfCoverBuilder.logoKesImage = logoKesImage;
  });

  test('Vérification du positionnement optimisé du filigrane via PdfReportStyles (Couverture et pages intérieures)', () async {
    final now = DateTime.now();
    final dateInterv = DateTime(2026, 9, 21);

    final mission = Mission(
      id: 'MISSION_TEST_WATERMARK_PROD',
      nomClient: 'GUINNESS CAMEROUN S.A.',
      nomSite: 'Usine Principale de Bassa',
      natureMission: 'CONTRÔLE RÉGLEMENTAIRE PÉRIODIQUE DES INSTALLATIONS ÉLECTRIQUES',
      recepteurRapport: 'M. LE DIRECTEUR TECHNIQUE & SÉCURITÉ',
      lieuIntervention: 'Zone Industrielle de Bassa, Douala, Cameroun',
      dateIntervention: dateInterv,
      dateRapport: now,
      status: 'en_cours',
      createdAt: now,
      updatedAt: now,
    );

    final rg = RenseignementsGeneraux(
      missionId: mission.id,
      etablissement: 'Usine Industrielle Agroalimentaire',
      installation: 'Poste MT/BT, TGBT Général, Groupes Électrogènes',
      activite: 'Brasserie & Embouteillage',
      nomSite: 'Site de Bassa',
      dateDebut: dateInterv,
      dateFin: dateInterv,
      dateRapport: now,
      recepteurRapport: 'M. LE DIRECTEUR TECHNIQUE & SÉCURITÉ',
      lieuIntervention: 'Zone Industrielle de Bassa, Douala',
      updatedAt: now,
    );

    final jsa = JSA(
      missionId: mission.id,
      inspecteurs: [
        JSAInspecteur(
          nom: 'TEUFACK',
          prenom: 'Andelson',
        ),
      ],
    );

    final pdf = pw.Document();

    // PAGE 1 : Thème couverture officiel
    final coverTheme = PdfReportStyles.buildCoverPageTheme(
      fontRegular,
      fontBold,
      watermarkImage: watermarkImage,
    );

    pdf.addPage(
      pw.Page(
        pageTheme: coverTheme,
        build: (ctx) => PdfCoverBuilder.buildCoverPage(
          mission,
          rg,
          ctx,
          numeroRapport: 'KES/IP/RAP/2026/09-042',
        ),
      ),
    );

    // PAGE 2 : Thème pages intérieures officiel
    final innerTheme = PdfReportStyles.buildInnerPageTheme(
      fontRegular: fontRegular,
      fontBold: fontBold,
      watermarkImage: watermarkImage,
      pageOffset: 0,
      overrideTotalPages: 2,
    );

    pdf.addPage(
      pw.Page(
        pageTheme: innerTheme,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfReportStyles.buildPageHeaderWidget(
              logoKesImage: logoKesImage,
              fontRegular: fontRegular,
              fontBold: fontBold,
              nomClient: mission.nomClient,
              nomSite: mission.nomSite,
              numeroRapport: 'KES/IP/RAP/2026/09-042',
            ),
            pw.SizedBox(height: 8),
            PdfCoverBuilder.buildIntervenantsEtResponsabilitesPage(
              jsa,
              rg,
              null,
              {},
              0,
              reportGenerationDate: now,
              mission: mission,
            ),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(5000));
  });
}
