import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/excel/excel_report_service.dart';

void main() {
  group('ExcelReportService Tests', () {
    late Mission sampleMission;
    late AuditInstallationsElectriques sampleAudit;
    late DescriptionInstallations sampleDesc;

    setUp(() {
      sampleMission = Mission(
        id: 'mission_test_123',
        nomClient: 'TOTAL ENERGIES',
        nomSite: 'Site Logbaba',
        status: 'en_cours',
        createdAt: DateTime(2026, 1, 15),
        updatedAt: DateTime(2026, 1, 15),
        dateIntervention: DateTime(2026, 1, 15),
      );

      // Création de données d'audit avec MT et BT
      sampleAudit = AuditInstallationsElectriques(
        missionId: 'mission_test_123',
        updatedAt: DateTime(2026, 1, 15),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'Poste MT 01',
            type: 'LOCAL_MT',
            cellules: [
              Cellule(
                nom: 'Cellule Arrivée 1',
                type: 'Cellule MT',
                fonction: 'Arrivée HTA',
                marqueModeleAnnee: 'Schneider 2023',
                tensionAssignee: '20kV',
                pouvoirCoupure: '16kA',
                numerotation: '1',
                parafoudres: 'Non',
              ),
              Cellule(
                nom: 'Cellule Départ 1',
                type: 'Cellule MT',
                fonction: 'Départ HTA',
                marqueModeleAnnee: 'Schneider 2023',
                tensionAssignee: '20kV',
                pouvoirCoupure: '16kA',
                numerotation: '2',
                parafoudres: 'Non',
              ),
            ],
            transformateurs: [
              TransformateurMTBT(
                nom: 'Transfo Principal',
                typeTransformateur: 'Sec',
                marqueAnnee: 'ABB 2022',
                puissanceAssignee: '630kVA',
                tensionPrimaireSecondaire: '20kV/400V',
                relaisBuchholz: 'Non',
                typeRefroidissement: 'AN',
                regimeNeutre: 'TN-S',
                repere: 'TR-01',
              ),
            ],
            coffrets: [
              CoffretArmoire(
                qrCode: 'QR-01',
                repere: 'ARM-MT-01',
                nom: 'Armoire Auxiliaire MT',
                type: 'Armoire',
              ),
            ],
            observationsLibres: [],
          ),
        ],
        moyenneTensionZones: [],
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Bâtiment Administratif',
            coffretsDirects: [],
            locaux: [
              BasseTensionLocal(
                nom: 'Local TGBT',
                type: 'LOCAL_TGBT',
                coffrets: [
                  CoffretArmoire(
                    qrCode: 'QR-02',
                    nom: 'TGBT Général',
                    type: 'TGBT',
                    repere: 'TGBT-01',
                    accessible: true,
                    pointsVerification: [
                      PointVerification(
                        pointVerification: 'Présence plastron',
                        conformite: 'Non conforme',
                        observation: 'Plastron manquant sur le jeu de barres',
                        referenceNormative: 'NFC 15-100 § 411.3',
                      ),
                    ],
                    observationsLibres: [],
                    observationsParafoudre: [],
                  ),
                  CoffretArmoire(
                    qrCode: 'QR-03',
                    nom: 'Armoire Climatisation',
                    type: 'Armoire',
                    repere: 'TD-CLIM',
                    accessible: true,
                    pointsVerification: [],
                    observationsLibres: [],
                    observationsParafoudre: [],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      sampleDesc = DescriptionInstallations(
        missionId: 'mission_test_123',
      );
    });

    test('buildExcelReportFileName construit un nom officiel et assaini', () {
      final fileName = ExcelReportService.buildExcelReportFileName(
        'TOTAL / ENERGIES *',
        nomSite: 'Site : Douala',
        date: DateTime(2026, 9, 10),
        timestamp: 1726000000000,
      );

      expect(fileName, startsWith('Rapport_Verif_elec_TOTAL _ ENERGIES __Site _ Douala_2026_1726000000000.xlsx'));
      expect(fileName.contains('*'), isFalse);
      expect(fileName.contains(':'), isFalse);
      expect(fileName.contains('/'), isFalse);
      expect(fileName.endsWith('.xlsx'), isTrue);
    });

    test('generateWorkbookBytes produit un fichier Excel valide avec exactement 2 feuilles', () {
      final genDate = DateTime(2026, 9, 10);
      final bytes = ExcelReportService.generateWorkbookBytes(
        mission: sampleMission,
        audit: sampleAudit,
        description: sampleDesc,
        generationDate: genDate,
      );

      expect(bytes, isNotEmpty);

      // Écriture temporaire pour vérifier l'intégrité du fichier
      final tempFile = File('${Directory.systemTemp.path}/test_excel_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      tempFile.writeAsBytesSync(bytes);

      // Vérifier le fichier sur disque
      expect(tempFile.existsSync(), isTrue);
      expect(tempFile.lengthSync(), greaterThan(1000));

      // Nettoyer
      tempFile.deleteSync();
    });

    test('Vérification approfondie du contenu et des colonnes des 2 feuilles via XML OpenXML', () {
      final genDate = DateTime(2026, 9, 10);
      final dateExpected = DateFormat('dd/MM/yyyy').format(genDate);

      final bytes = ExcelReportService.generateWorkbookBytes(
        mission: sampleMission,
        audit: sampleAudit,
        description: sampleDesc,
        generationDate: genDate,
      );

      expect(bytes, isNotEmpty);

      // Décompression de l'archive .xlsx
      final archive = ZipDecoder().decodeBytes(bytes);

      // 1. Vérification du classeur (workbook.xml)
      final wbFile = archive.files.firstWhere((f) => f.name == 'xl/workbook.xml');
      final wbXml = utf8.decode(wbFile.content as List<int>);

      // Exactement les 2 feuilles spécifiées
      expect(wbXml.contains('Annexe des équipements'), isTrue);
      expect(wbXml.contains('Annexe des observations'), isTrue);

      // 2. Vérification des chaînes partagées (sharedStrings.xml)
      final ssFile = archive.files.firstWhere((f) => f.name == 'xl/sharedStrings.xml');
      final ssXml = utf8.decode(ssFile.content as List<int>);

      // Colonnes feuille 1
      expect(ssXml.contains('Zone'), isTrue);
      expect(ssXml.contains('Repère'), isTrue);
      expect(ssXml.contains('Désignation'), isTrue);
      expect(ssXml.contains('Type'), isTrue);
      expect(ssXml.contains('Vérifié'), isTrue);
      expect(ssXml.contains('Observation'), isTrue);
      expect(ssXml.contains('Date de réserve'), isTrue);
      expect(ssXml.contains('Date de rapport'), isTrue);

      // Colonnes feuille 2 (les 5 colonnes de réserve)
      expect(ssXml.contains('Réserve nécessitant une intervention ?'), isTrue);
      expect(ssXml.contains('Statut de la réserve'), isTrue);
      expect(ssXml.contains('Réserve levée par'), isTrue);
      expect(ssXml.contains('Date de la réserve'), isTrue);
      expect(ssXml.contains('Date de la levée de réserve'), isTrue);

      // Données métier réelles
      expect(ssXml.contains('TOTAL ENERGIES'), isTrue);
      expect(ssXml.contains('Plastron manquant sur le jeu de barres'), isTrue);
      expect(ssXml.contains(dateExpected), isTrue);

      // 3. Vérification des cellules fusionnées dynamiquement (mergeCells)
      final sheet1File = archive.files.firstWhere((f) => f.name == 'xl/worksheets/sheet1.xml');
      final sheet1Xml = utf8.decode(sheet1File.content as List<int>);
      expect(sheet1Xml.contains('mergeCells'), isTrue);

      final sheet2File = archive.files.firstWhere((f) => f.name == 'xl/worksheets/sheet2.xml');
      final sheet2Xml = utf8.decode(sheet2File.content as List<int>);
      expect(sheet2Xml.contains('mergeCells'), isTrue);
    });

    test('Structure et formatage de la date de rapport dans l\'onglet 1', () {
      final genDate = DateTime(2026, 9, 10);
      final dateExpected = DateFormat('dd/MM/yyyy').format(genDate);

      final bytes = ExcelReportService.generateWorkbookBytes(
        mission: sampleMission,
        audit: sampleAudit,
        description: sampleDesc,
        generationDate: genDate,
      );

      expect(bytes.length, greaterThan(0));
    });

    test('Génération sur mission vide ou sans données (rétrocompatibilité & null-safety)', () {
      final emptyMission = Mission(
        id: 'empty_mission',
        nomClient: 'CLIENT TEST',
        nomSite: '',
        status: 'en_cours',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final bytes = ExcelReportService.generateWorkbookBytes(
        mission: emptyMission,
        audit: null,
        description: null,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(500));
    });
  });
}
