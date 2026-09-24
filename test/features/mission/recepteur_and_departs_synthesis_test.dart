import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/features/mission/data/mappers/renseignements_generaux_mapper.dart';
import 'package:inspec_app/features/mission/data/mappers/mission_mapper.dart';
import 'package:inspec_app/services/pdf/builders/pdf_equipements_synthesis_builder.dart';
import 'package:inspec_app/services/excel/excel_report_service.dart';

void main() {
  group('1. Évolution du Récepteur du rapport - Rétrocompatibilité & Civilité', () {
    test('Mission ancienne avec seulement recepteurRapport en texte libre', () {
      final rg = RenseignementsGeneraux(
        missionId: 'm1',
        etablissement: 'Usine Alpha',
        installation: 'Atelier Central',
        activite: 'Industrie',
        nomSite: 'Site Bassa',
        dateDebut: DateTime(2026, 1, 10),
        dateFin: DateTime(2026, 1, 12),
        dureeJours: 2,
        verificationType: 'Périodique',
        recepteurRapport: 'Directeur Général',
        updatedAt: DateTime(2026, 1, 10),
      );

      // Vérification du getter de compatibilité
      expect(rg.effectiveRecepteurFonction, 'Directeur Général');
      expect(rg.effectiveRecepteurCivilite, 'Monsieur');
    });

    test('Mission moderne avec civilité Madame et fonction personnalisée', () {
      final rg = RenseignementsGeneraux(
        missionId: 'm2',
        etablissement: 'Usine Beta',
        installation: 'Atelier Sud',
        activite: 'Tertiaire',
        nomSite: 'Siège Social',
        dateDebut: DateTime(2026, 2, 1),
        dateFin: DateTime(2026, 2, 2),
        dureeJours: 1,
        verificationType: 'Initiale',
        recepteurCivilite: 'Madame',
        recepteurNom: 'Jeanne Dupont',
        recepteurFonction: 'Directrice Technique',
        recepteurEmail: 'jeanne.dupont@beta.com',
        recepteurTelephone: '+237 600000000',
        updatedAt: DateTime(2026, 2, 1),
      );

      expect(rg.effectiveRecepteurCivilite, 'Madame');
      expect(rg.effectiveRecepteurFonction, 'Directrice Technique');
      expect(rg.recepteurNom, 'Jeanne Dupont');
      expect(rg.recepteurEmail, 'jeanne.dupont@beta.com');
      expect(rg.recepteurTelephone, '+237 600000000');
    });

    test('Mapper RenseignementsGeneraux préserve les 5 nouveaux champs et la compatibilité', () {
      final rg = RenseignementsGeneraux(
        missionId: 'm3',
        etablissement: 'Usine Gamma',
        installation: 'Poste MT',
        activite: 'Agroalimentaire',
        nomSite: 'Bafoussam',
        dateDebut: DateTime(2026, 3, 1),
        dateFin: DateTime(2026, 3, 3),
        dureeJours: 2,
        verificationType: 'Périodique',
        recepteurCivilite: 'Madame',
        recepteurNom: 'Alice Ngo',
        recepteurFonction: 'Responsable QHSE',
        recepteurEmail: 'alice@qhse.com',
        recepteurTelephone: '+237 611223344',
        updatedAt: DateTime(2026, 3, 1),
      );

      final entity = RenseignementsGenerauxMapper.toEntity(rg);
      expect(entity.recepteurCivilite, 'Madame');
      expect(entity.recepteurNom, 'Alice Ngo');
      expect(entity.recepteurFonction, 'Responsable QHSE');
      expect(entity.recepteurEmail, 'alice@qhse.com');
      expect(entity.recepteurTelephone, '+237 611223344');

      final backToModel = RenseignementsGenerauxMapper.toModel(entity);
      expect(backToModel.recepteurCivilite, 'Madame');
      expect(backToModel.recepteurNom, 'Alice Ngo');
      expect(backToModel.recepteurFonction, 'Responsable QHSE');
      expect(backToModel.recepteurEmail, 'alice@qhse.com');
      expect(backToModel.recepteurTelephone, '+237 611223344');
      // Vérification que recepteurRapport est également nourri pour les anciens lecteurs
      expect(backToModel.recepteurRapport, 'Responsable QHSE');
    });

    test('Mapper Mission préserve les 5 champs de récepteur', () {
      final mission = Mission(
        id: 'mission-test-rec',
        nomClient: 'SABC',
        nomSite: 'Koumassi',
        status: 'en_cours',
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
        recepteurCivilite: 'Monsieur',
        recepteurNom: 'Jean Paul',
        recepteurFonction: 'Chef d\'Exploitation',
        recepteurEmail: 'jp@sabc.cm',
        recepteurTelephone: '+237 699887766',
      );

      final entity = MissionMapper.toEntity(mission);
      expect(entity.recepteurCivilite, 'Monsieur');
      expect(entity.recepteurNom, 'Jean Paul');
      expect(entity.recepteurFonction, 'Chef d\'Exploitation');

      final model = MissionMapper.toModel(entity);
      expect(model.recepteurCivilite, 'Monsieur');
      expect(model.recepteurNom, 'Jean Paul');
      expect(model.recepteurFonction, 'Chef d\'Exploitation');
      expect(model.recepteurRapport, 'Chef d\'Exploitation');
    });
  });

  group('2. Départs issus - Extraction et tableaux de synthèse', () {
    test('Extraction du nombre de départs issus sur des coffrets BT', () {
      final coffretAvec2Departs = CoffretArmoire(
        id: 'c1',
        nom: 'TGBT Principal',
        type: 'TGBT',
        repere: 'TGBT-01',
        numeroEquipement: '1',
        qrCode: 'QR1',
        departures: [
          DepartEquipement(identification: 'Départ Climatisation', sectionCable: '4x35'),
          DepartEquipement(identification: 'Départ Éclairage', sectionCable: '4x10'),
        ],
      );

      final coffretAvec0Depart = CoffretArmoire(
        id: 'c2',
        nom: 'Coffret Local Technique',
        type: 'Armoire',
        repere: 'ARM-02',
        numeroEquipement: '2',
        qrCode: 'QR2',
        departures: [],
      );

      final coffretSansInfoDepart = CoffretArmoire(
        id: 'c3',
        nom: 'Coffret Prises',
        type: 'Coffret',
        repere: 'COF-03',
        numeroEquipement: '3',
        qrCode: 'QR3',
        departures: null,
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm1',
        updatedAt: DateTime(2026, 4, 1),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Production',
            coffretsDirects: [
              coffretAvec2Departs,
              coffretAvec0Depart,
              coffretSansInfoDepart,
            ],
            locaux: [],
          ),
        ],
      );

      final equipementsBT = PdfEquipementsSynthesisBuilder.collectEquipementsBT(audit, null);

      expect(equipementsBT.length, 3);

      final item1 = equipementsBT.firstWhere((e) => e.repere == 'TGBT-01');
      expect(item1.departsIssus, '2');

      final item2 = equipementsBT.firstWhere((e) => e.repere == 'ARM-02');
      expect(item2.departsIssus, '0');

      final item3 = equipementsBT.firstWhere((e) => e.repere == 'COF-03');
      expect(item3.departsIssus, '-');
    });

    test('Équipement MT a départs issus neutre (-)', () {
      final localMT = MoyenneTensionLocal(
        nom: 'Poste MT Principal',
        type: 'Local MT',
        cellules: [
          Cellule(
            nom: 'Cellule Arrivée',
            repere: 'CEL-01',
            type: 'Arrivée',
            fonction: 'Arrivée',
            marqueModeleAnnee: 'Schneider 2020',
            tensionAssignee: '20 kV',
            pouvoirCoupure: '16 kA',
            numerotation: '1',
            parafoudres: 'Présent',
          ),
        ],
        transformateurs: [
          TransformateurMTBT(
            nom: 'Transfo 1',
            repere: 'TR-01',
            marqueAnnee: 'Schneider',
            typeTransformateur: 'Huile',
            puissanceAssignee: '630 kVA',
            tensionPrimaireSecondaire: '20 kV / 400 V',
            relaisBuchholz: 'Présent',
            typeRefroidissement: 'ONAN',
            regimeNeutre: 'TN-S',
          ),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm2',
        updatedAt: DateTime(2026, 4, 1),
        moyenneTensionLocaux: [localMT],
      );

      final equipementsMT = PdfEquipementsSynthesisBuilder.collectEquipementsMT(audit);
      expect(equipementsMT.isNotEmpty, true);
      for (final eq in equipementsMT) {
        expect(eq.departsIssus, '-');
      }
    });

    test('buildEquipementsTable génère le tableau avec la colonne Départs issus', () {
      final items = [
        PdfEquipementItem(
          zoneName: 'Zone A',
          localName: 'Local 1',
          repere: 'TGBT-1',
          nom: 'TGBT 1',
          type: 'TGBT',
          isMT: false,
          departsIssus: '5',
        ),
      ];

      final widgets = PdfEquipementsSynthesisBuilder.buildEquipementsTable(
        items,
        isMT: false,
      );

      expect(widgets.isNotEmpty, true);
    });

    test('Export Excel intègre la colonne Départs issus dans l\'Annexe des équipements', () {
      final mission = Mission(
        id: 'M_EXCEL_DEPARTS',
        nomClient: 'CLIENT TEST',
        status: 'en_cours',
        createdAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 4, 1),
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'M_EXCEL_DEPARTS',
        updatedAt: DateTime(2026, 4, 1),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Principale',
            coffretsDirects: [
              CoffretArmoire(
                id: 'c_test',
                nom: 'Coffret Test',
                type: 'Coffret',
                repere: 'COF-01',
                qrCode: 'QR_TEST',
                departures: [
                  DepartEquipement(identification: 'D1'),
                  DepartEquipement(identification: 'D2'),
                ],
              ),
            ],
            locaux: [],
          ),
        ],
      );

      final bytes = ExcelReportService.generateWorkbookBytes(
        mission: mission,
        audit: audit,
        description: null,
        generationDate: DateTime(2026, 4, 1),
      );

      expect(bytes, isNotEmpty);

      // Décompression de l'archive .xlsx et vérification des sharedStrings
      final archive = ZipDecoder().decodeBytes(bytes);
      final ssFile = archive.files.firstWhere((f) => f.name == 'xl/sharedStrings.xml');
      final ssXml = utf8.decode(ssFile.content as List<int>);

      expect(ssXml.contains('Départs issus'), isTrue);
    });
  });
}

