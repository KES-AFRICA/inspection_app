import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/services/pdf/builders/pdf_renseignements_builder.dart';
import 'package:inspec_app/services/regulatory_classification_service.dart';

void main() {
  group('PDF Renseignements Principaux Table Tests', () {
    test('Renders ERP Établissements Spécialisés with Type OA and Première catégorie', () async {
      final mission = Mission(
        id: 'm1',
        nomClient: 'Hôtel des Cimes',
        status: 'en_cours',
        adresseClient: 'Mont Cameroun, Buea',
        nomSite: 'Refuge Altitude',
        activiteSurSite: 'Hôtellerie d\'altitude',
        classementReglementaire: RegulatoryClassificationService.erpSpecialises,
        classementReglementaireType: 'Type OA',
        classementReglementaireCategorie: 'Première catégorie',
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 16),
      );

      final rg = RenseignementsGeneraux(
        missionId: 'm1',
        etablissement: 'Hôtel des Cimes',
        installation: 'Toutes les installations électriques',
        activite: 'Hôtellerie',
        nomSite: 'Refuge Altitude',
        activiteSurSite: 'Hôtellerie d\'altitude',
        classementReglementaire: RegulatoryClassificationService.erpSpecialises,
        classementReglementaireType: 'Type OA',
        classementReglementaireCategorie: 'Première catégorie',
        updatedAt: DateTime(2026, 9, 16),
      );

      final doc = pw.Document();
      final widget = PdfRenseignementsBuilder.buildRenseignementsGeneraux(
        mission,
        rg,
        {},
      );

      doc.addPage(
        pw.Page(
          pageTheme: const pw.PageTheme(pageFormat: PdfPageFormat.a4),
          build: (ctx) => widget,
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('Renders Installations classées with Usines, Ateliers... and Sans objet category', () async {
      final mission = Mission(
        id: 'm2',
        nomClient: 'Cimencam Figuil',
        status: 'en_cours',
        adresseClient: 'Figuil, Nord Cameroun',
        nomSite: 'Usine de clinker',
        activiteSurSite: 'Broyage et ensachage',
        classementReglementaire: RegulatoryClassificationService.installationsClassees,
        classementReglementaireType: 'Usines, Ateliers, Dépôts, Chantiers',
        classementReglementaireCategorie: null,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 16),
      );

      final rg = RenseignementsGeneraux(
        missionId: 'm2',
        etablissement: 'Cimencam Figuil',
        installation: 'Postes MT et TGBT',
        activite: 'Cimenterie',
        nomSite: 'Usine de clinker',
        activiteSurSite: 'Broyage et ensachage',
        classementReglementaire: RegulatoryClassificationService.installationsClassees,
        classementReglementaireType: 'Usines, Ateliers, Dépôts, Chantiers',
        classementReglementaireCategorie: null,
        updatedAt: DateTime(2026, 9, 16),
      );

      final doc = pw.Document();
      final widget = PdfRenseignementsBuilder.buildRenseignementsGeneraux(
        mission,
        rg,
        {},
      );

      doc.addPage(
        pw.Page(
          pageTheme: const pw.PageTheme(pageFormat: PdfPageFormat.a4),
          build: (ctx) => widget,
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('Renders IGH with GHA and Sans objet category', () async {
      final mission = Mission(
        id: 'm3',
        nomClient: 'Tour de l\'Émergence',
        status: 'en_cours',
        adresseClient: 'Bonanjo, Douala',
        nomSite: 'Tour Principale',
        activiteSurSite: 'Habitation IGH',
        classementReglementaire: RegulatoryClassificationService.igh,
        classementReglementaireType: 'GHA',
        classementReglementaireCategorie: null,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 16),
      );

      final rg = RenseignementsGeneraux(
        missionId: 'm3',
        etablissement: 'Tour de l\'Émergence',
        installation: 'Distribution HT/BT',
        activite: 'Immeuble de grande hauteur',
        nomSite: 'Tour Principale',
        activiteSurSite: 'Habitation IGH',
        classementReglementaire: RegulatoryClassificationService.igh,
        classementReglementaireType: 'GHA',
        classementReglementaireCategorie: null,
        updatedAt: DateTime(2026, 9, 16),
      );

      final doc = pw.Document();
      final widget = PdfRenseignementsBuilder.buildRenseignementsGeneraux(
        mission,
        rg,
        {},
      );

      doc.addPage(
        pw.Page(
          pageTheme: const pw.PageTheme(pageFormat: PdfPageFormat.a4),
          build: (ctx) => widget,
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('Renders ERP Établissements Généraux with Type J and Cinquième catégorie', () async {
      final mission = Mission(
        id: 'm4',
        nomClient: 'Clinique du Soleil',
        status: 'en_cours',
        adresseClient: 'Bastos, Yaoundé',
        nomSite: 'Bâtiment Chirurgie',
        activiteSurSite: 'Soins de santé',
        classementReglementaire: RegulatoryClassificationService.erpGeneraux,
        classementReglementaireType: 'Type U',
        classementReglementaireCategorie: 'Cinquième catégorie',
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 16),
      );

      final rg = RenseignementsGeneraux(
        missionId: 'm4',
        etablissement: 'Clinique du Soleil',
        installation: 'TGBT & Tableaux divisionnaires',
        activite: 'Santé',
        nomSite: 'Bâtiment Chirurgie',
        activiteSurSite: 'Soins de santé',
        classementReglementaire: RegulatoryClassificationService.erpGeneraux,
        classementReglementaireType: 'Type U',
        classementReglementaireCategorie: 'Cinquième catégorie',
        updatedAt: DateTime(2026, 9, 16),
      );

      final doc = pw.Document();
      final widget = PdfRenseignementsBuilder.buildRenseignementsGeneraux(
        mission,
        rg,
        {},
      );

      doc.addPage(
        pw.Page(
          pageTheme: const pw.PageTheme(pageFormat: PdfPageFormat.a4),
          build: (ctx) => widget,
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('Renders historical legacy mission with inferred classification and categories', () async {
      // Mission historique sans classementReglementaire
      final mission = Mission(
        id: 'm5_legacy',
        nomClient: 'Établissement Ancien',
        status: 'en_cours',
        classementReglementaireType: 'J',
        classementReglementaireCategorie: '1ère catégorie',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final rg = RenseignementsGeneraux(
        missionId: 'm5_legacy',
        etablissement: 'Établissement Ancien',
        installation: 'Toutes',
        activite: 'Accueil personnes âgées',
        nomSite: 'Site Principal',
        classementReglementaireType: 'J',
        classementReglementaireCategorie: '1ère catégorie',
        updatedAt: DateTime(2024, 1, 1),
      );

      final doc = pw.Document();
      final widget = PdfRenseignementsBuilder.buildRenseignementsGeneraux(
        mission,
        rg,
        {},
      );

      doc.addPage(
        pw.Page(
          pageTheme: const pw.PageTheme(pageFormat: PdfPageFormat.a4),
          build: (ctx) => widget,
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });
  });
}
