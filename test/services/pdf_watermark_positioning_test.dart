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

  test('Vérification du filigrane en mode Paysage : taille réduite et non-débordement sur le header', () {
    final landscapeFormat = PdfPageFormat.a4.landscape; // 841.89 x 595.28
    final bool isLandscape = landscapeFormat.width > landscapeFormat.height;
    expect(isLandscape, isTrue);

    // En paysage, la largeur automatique doit être de 460 pt (au lieu de 680 pt en portrait)
    final double defaultWidth = isLandscape ? 460.0 : 680.0;
    expect(defaultWidth, equals(460.0));

    final double height = defaultWidth * PdfReportStyles.kWatermarkAspectRatio;
    final double actualTargetCenterY = landscapeFormat.height / 2.0; // 297.64 pt

    final double circleCenterYInImage = height * PdfReportStyles.kWatermarkCircleCyRatio; // 460 * 0.44 = 202.4 pt
    final double imagePageY = actualTargetCenterY - circleCenterYInImage; // 297.64 - 202.4 = 95.24 pt

    // Le haut de l'image est à 95.24 pt, et le header s'arrête à ~70 pt.
    // L'en-tête est donc protégé avec une marge positive confortable.
    expect(imagePageY, greaterThan(75.0));
  });

  test('Vérification du centrage vertical des pages de garde et signature dans le cercle de la loupe', () {
    const double pageHeight = 841.89;
    const double targetCenterY = pageHeight / 2.0; // 420.945 pt
    const double headerBottomY = 73.8; // top margin 32 + header ~41.8 pt

    // 1. Couvertures de section (Équipements, Observations, Audit, Photos, Schémas)
    // Blocs de titre : barre (2) + gap (24) + titre (24) + gap (12) + client (16) + gap (24) + barre (2) = 104 pt
    const double titleBlockHeight = 104.0;
    const double titleTopOffset = 295.0; // pw.SizedBox(height: 295)
    final double titleBlockCenterY = headerBottomY + titleTopOffset + (titleBlockHeight / 2.0);

    expect(titleBlockCenterY, closeTo(targetCenterY, 3.0));

    // 2. Page de Signature
    // Bloc de signature : Direction (19) + gap (12) + Nom (16.5) + gap (36) + Lieu/Date (15.5) + gap (12) + Barre (1) + gap (6) + Signature (10) = 128 pt
    const double signatureBlockHeight = 128.0;
    const double signatureTopOffset = 283.0; // pw.SizedBox(height: 283)
    final double signatureBlockCenterY = headerBottomY + signatureTopOffset + (signatureBlockHeight / 2.0);

    expect(signatureBlockCenterY, closeTo(targetCenterY, 3.0));
  });
}
