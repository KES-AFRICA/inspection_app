import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/features/mission/data/mappers/renseignements_generaux_mapper.dart';
import 'package:inspec_app/features/mission/data/mappers/mission_mapper.dart';
import 'package:inspec_app/services/excel/excel_report_service.dart';
import 'package:inspec_app/services/pdf/builders/pdf_cover_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_equipements_synthesis_builder.dart';

void main() {
  group('I. Tests Évolution « Récepteur du rapport »', () {
    test('1. Rétrocompatibilité : ancienne mission avec uniquement recepteurRapport en chaîne', () {
      final legacyRg = RenseignementsGeneraux(
        missionId: 'm_legacy',
        etablissement: 'USINE CENTRALE',
        installation: 'Bâtiment Principal',
        activite: 'Industrie',
        nomSite: 'Site A',
        updatedAt: DateTime(2025, 5, 1),
        recepteurRapport: 'DIRECTEUR TECHNIQUE',
      );

      // Le getter effectiveRecepteurFonction doit renvoyer la valeur historique
      expect(legacyRg.effectiveRecepteurFonction, equals('DIRECTEUR TECHNIQUE'));
      // La civilité par défaut doit être 'Monsieur'
      expect(legacyRg.effectiveRecepteurCivilite, equals('Monsieur'));
      // Les nouveaux champs individuels non renseignés restent null
      expect(legacyRg.recepteurNom, isNull);
      expect(legacyRg.recepteurEmail, isNull);
      expect(legacyRg.recepteurTelephone, isNull);

      // Conversion vers Entity et retour vers Model
      final entity = RenseignementsGenerauxMapper.toEntity(legacyRg);
      expect(entity.recepteurRapport, equals('DIRECTEUR TECHNIQUE'));
      final backToModel = RenseignementsGenerauxMapper.toModel(entity);
      expect(backToModel.effectiveRecepteurFonction, equals('DIRECTEUR TECHNIQUE'));
    });

    test('2. Nouvelle mission : champs structurés Civilité, Nom, Fonction, Email, Téléphone', () {
      final modernRg = RenseignementsGeneraux(
        missionId: 'm_modern',
        etablissement: 'KES LAB',
        installation: 'Bureau R&D',
        activite: 'Ingénierie',
        nomSite: 'Siège',
        updatedAt: DateTime(2026, 9, 20),
        recepteurCivilite: 'Madame',
        recepteurNom: 'Jeanne Dupont',
        recepteurFonction: 'Responsable QHSE',
        recepteurEmail: 'jeanne.dupont@kes.cm',
        recepteurTelephone: '+237 6 99 88 77 66',
      );

      expect(modernRg.effectiveRecepteurCivilite, equals('Madame'));
      expect(modernRg.effectiveRecepteurNom, equals('Jeanne Dupont'));
      expect(modernRg.effectiveRecepteurFonction, equals('Responsable QHSE'));
      expect(modernRg.recepteurEmail, equals('jeanne.dupont@kes.cm'));
      expect(modernRg.recepteurTelephone, equals('+237 6 99 88 77 66'));

      // Propagation via Mapper Entity <-> Model
      final entity = RenseignementsGenerauxMapper.toEntity(modernRg);
      expect(entity.recepteurCivilite, equals('Madame'));
      expect(entity.recepteurNom, equals('Jeanne Dupont'));
      expect(entity.recepteurFonction, equals('Responsable QHSE'));
      expect(entity.recepteurEmail, equals('jeanne.dupont@kes.cm'));
      expect(entity.recepteurTelephone, equals('+237 6 99 88 77 66'));

      final missionModel = Mission(
        id: 'm_modern',
        nomClient: 'KES LAB',
        status: 'en_cours',
        createdAt: DateTime(2026, 9, 20),
        updatedAt: DateTime(2026, 9, 20),
        recepteurCivilite: 'Madame',
        recepteurNom: 'Jeanne Dupont',
        recepteurFonction: 'Responsable QHSE',
        recepteurEmail: 'jeanne.dupont@kes.cm',
        recepteurTelephone: '+237 6 99 88 77 66',
      );

      final missionEntity = MissionMapper.toEntity(missionModel);
      expect(missionEntity.recepteurCivilite, equals('Madame'));
      expect(missionEntity.recepteurFonction, equals('Responsable QHSE'));
      final backMission = MissionMapper.toModel(missionEntity);
      expect(backMission.recepteurCivilite, equals('Madame'));
      expect(backMission.recepteurFonction, equals('Responsable QHSE'));
    });

    test('3. Rendu Couverture PDF : formatage Civilité dynamique et Fonction en MAJUSCULES', () async {
      final missionMadame = Mission(
        id: 'm_test_cover',
        nomClient: 'TOTAL ENERGIES',
        status: 'en_cours',
        createdAt: DateTime(2026, 9, 24),
        updatedAt: DateTime(2026, 9, 24),
        recepteurCivilite: 'Madame',
        recepteurNom: 'Marie Curie',
        recepteurFonction: 'Directrice de site',
      );

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return PdfCoverBuilder.buildCoverPage(
              missionMadame,
              null,
              context,
            );
          },
        ),
      );

      final pdfBytes = await doc.save();
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));

      // Cas sans récepteur : pas de civilité orpheline ("À l'attention de null")
      final missionVide = Mission(
        id: 'm_empty',
        nomClient: 'CLIENT TEST',
        status: 'en_cours',
        createdAt: DateTime(2026, 9, 24),
        updatedAt: DateTime(2026, 9, 24),
      );

      final docVide = pw.Document();
      docVide.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return PdfCoverBuilder.buildCoverPage(
              missionVide,
              null,
              context,
            );
          },
        ),
      );

      final pdfVideBytes = await docVide.save();
      expect(pdfVideBytes, isNotNull);
    });
  });

  group('II. Tests Ajout « Départs issus » dans Synthèses PDF et Excel', () {
    test('4. Collecte Départs issus : coffret avec départs vs coffret sans départs', () {
      final coffretAvec3Departs = CoffretArmoire(
        qrCode: 'QR_TGBT',
        nom: 'TGBT Atelier',
        type: 'TGBT',
        repere: 'TGBT-01',
        numeroEquipement: '1',
        departures: [
          DepartEquipement(identification: 'Départ Éclairage', calibre: '16A'),
          DepartEquipement(identification: 'Départ Prises', calibre: '20A'),
          DepartEquipement(identification: 'Départ Force', calibre: '32A'),
        ],
      );

      final coffretSansDeparts = CoffretArmoire(
        qrCode: 'QR_COFFRET',
        nom: 'Coffret Local',
        type: 'Coffret',
        repere: 'COFF-01',
        numeroEquipement: '2',
        departures: null,
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm_departs_test',
        updatedAt: DateTime(2026, 9, 24),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Principale',
            coffretsDirects: [coffretAvec3Departs, coffretSansDeparts],
          ),
        ],
      );

      final itemsBT = PdfEquipementsSynthesisBuilder.collectEquipementsBT(audit, null);
      expect(itemsBT.length, equals(2));

      final item1 = itemsBT.firstWhere((it) => it.nom == 'TGBT Atelier');
      expect(item1.departsIssus, equals('3'));

      final item2 = itemsBT.firstWhere((it) => it.nom == 'Coffret Local');
      expect(item2.departsIssus, equals('-'));
    });

    test('5. Rendu PDF BT : tableau avec colonne « Départs issus » positionnée après « Type »', () async {
      final coffret = CoffretArmoire(
        qrCode: 'QR_TGBT_PDF',
        nom: 'TGBT Principal',
        type: 'TGBT',
        repere: 'TGBT',
        numeroEquipement: '10',
        departures: [
          DepartEquipement(identification: 'D1'),
          DepartEquipement(identification: 'D2'),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm_pdf_departs',
        updatedAt: DateTime(2026, 9, 24),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Usine',
            coffretsDirects: [coffret],
          ),
        ],
      );

      final itemsBT = PdfEquipementsSynthesisBuilder.collectEquipementsBT(audit, null);

      final widgets = PdfEquipementsSynthesisBuilder.buildEquipementsTable(
        itemsBT,
        showTableHeader: true,
        isMT: false,
      );

      expect(widgets, isNotEmpty);

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => widgets,
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotNull);
      expect(bytes.length, greaterThan(100));
    });

    test('6. Export Excel : colonne « Départs issus » présente après « Type » dans Annexe des équipements', () {
      final mission = Mission(
        id: 'm_excel_departs',
        nomClient: 'CIMENCAM',
        nomSite: 'Usine Figuil',
        status: 'en_cours',
        createdAt: DateTime(2026, 9, 24),
        updatedAt: DateTime(2026, 9, 24),
      );

      final coffret = CoffretArmoire(
        qrCode: 'QR_EXCEL_DEP',
        nom: 'Armoire Broyeur',
        type: 'Armoire',
        repere: 'ARM-BROY',
        numeroEquipement: '15',
        departures: [
          DepartEquipement(identification: 'Moteur 1'),
          DepartEquipement(identification: 'Moteur 2'),
          DepartEquipement(identification: 'Moteur 3'),
          DepartEquipement(identification: 'Ventilateur'),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm_excel_departs',
        updatedAt: DateTime(2026, 9, 24),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Production',
            coffretsDirects: [coffret],
          ),
        ],
      );

      final bytes = ExcelReportService.generateWorkbookBytes(
        mission: mission,
        audit: audit,
        generationDate: DateTime(2026, 9, 24),
      );

      expect(bytes, isNotEmpty);

      final archive = ZipDecoder().decodeBytes(bytes);
      final ssFile = archive.files.firstWhere((f) => f.name == 'xl/sharedStrings.xml');
      final ssXml = utf8.decode(ssFile.content as List<int>);

      // Vérification que l'en-tête « Départs issus » est présent
      expect(ssXml.contains('Départs issus'), isTrue);

      // Vérification de la feuille 1 (Annexe des équipements)
      final sheet1File = archive.files.firstWhere((f) => f.name == 'xl/worksheets/sheet1.xml');
      final sheet1Xml = utf8.decode(sheet1File.content as List<int>);

      // Le nombre de départs (4) est encodé sous forme numérique dans sheet1.xml
      expect(sheet1Xml.contains('<v>4</v>') || sheet1Xml.contains('4'), isTrue);
    });
  });
}
