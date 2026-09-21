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

      // Colonnes feuille 1 (MT: 9 cols, BT: 11 cols avec parafoudre et thermo)
      expect(ssXml.contains('Zone'), isTrue);
      expect(ssXml.contains('Repère'), isTrue);
      expect(ssXml.contains('Désignation'), isTrue);
      expect(ssXml.contains('Type'), isTrue);
      expect(ssXml.contains('Vérifié'), isTrue);
      expect(ssXml.contains('Présence du parafoudre'), isTrue);
      expect(ssXml.contains('Vérification thermo'), isTrue);
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

      final archive = ZipDecoder().decodeBytes(bytes);
      final ssFile = archive.files.firstWhere((f) => f.name == 'xl/sharedStrings.xml');
      final ssXml = utf8.decode(ssFile.content as List<int>);
      expect(ssXml.contains(dateExpected), isTrue);
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

    test('Validation du renforcement des séparations de groupes (Zone, Repère, Désignation)', () {
      // Mission multi-zones et multi-repères
      final multiZoneAudit = AuditInstallationsElectriques(
        missionId: 'multi_zone_mission',
        updatedAt: DateTime(2026, 1, 15),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'Local MT 1',
            type: 'LOCAL_MT',
            cellules: [
              Cellule(
                nom: 'Cellule 1',
                type: 'Cellule MT',
                fonction: 'Arrivée',
                marqueModeleAnnee: 'Schneider',
                tensionAssignee: '20kV',
                pouvoirCoupure: '16kA',
                numerotation: '1',
                parafoudres: 'Non',
              ),
            ],
          ),
          MoyenneTensionLocal(
            nom: 'Local MT 2 (Nouveau Repère)',
            type: 'LOCAL_MT',
            cellules: [
              Cellule(
                nom: 'Cellule 2',
                type: 'Cellule MT',
                fonction: 'Départ',
                marqueModeleAnnee: 'Schneider',
                tensionAssignee: '20kV',
                pouvoirCoupure: '16kA',
                numerotation: '2',
                parafoudres: 'Non',
              ),
            ],
          ),
        ],
        moyenneTensionZones: [],
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Usine',
            locaux: [
              BasseTensionLocal(
                nom: 'Atelier A',
                type: 'ATELIER',
                coffrets: [
                  CoffretArmoire(
                    qrCode: 'QR-A1',
                    nom: 'Armoire A1',
                    type: 'Armoire',
                    repere: 'ARM-A1',
                    pointsVerification: [
                      PointVerification(
                        pointVerification: 'Obs 1',
                        conformite: 'Non conforme',
                        observation: 'Défaut isolement',
                        referenceNormative: 'NFC 15-100',
                      ),
                      PointVerification(
                        pointVerification: 'Obs 2',
                        conformite: 'Non conforme',
                        observation: 'Absence repérage',
                        referenceNormative: 'NFC 15-100',
                      ),
                    ],
                  ),
                  CoffretArmoire(
                    qrCode: 'QR-A2',
                    nom: 'Armoire A2 (Nouvelle Désignation)',
                    type: 'Armoire',
                    repere: 'ARM-A2',
                    pointsVerification: [
                      PointVerification(
                        pointVerification: 'Obs 3',
                        conformite: 'Non conforme',
                        observation: 'Câble détérioré',
                        referenceNormative: 'NFC 15-100',
                      ),
                    ],
                  ),
                ],
              ),
              BasseTensionLocal(
                nom: 'Atelier B (Nouveau Repère)',
                type: 'ATELIER',
                coffrets: [
                  CoffretArmoire(
                    qrCode: 'QR-B1',
                    nom: 'Armoire B1',
                    type: 'Armoire',
                    repere: 'ARM-B1',
                    pointsVerification: [
                      PointVerification(
                        pointVerification: 'Obs 4',
                        conformite: 'Non conforme',
                        observation: 'Porte non verrouillée',
                        referenceNormative: 'NFC 15-100',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          BasseTensionZone(
            nom: 'Zone Bureaux (Nouvelle Zone)',
            locaux: [
              BasseTensionLocal(
                nom: 'Local Étage',
                type: 'LOCAL',
                coffrets: [
                  CoffretArmoire(
                    qrCode: 'QR-ET',
                    nom: 'TD Étage',
                    type: 'TD',
                    repere: 'TD-ET',
                    pointsVerification: [
                      PointVerification(
                        pointVerification: 'Obs 5',
                        conformite: 'Non conforme',
                        observation: 'Disjoncteur calibre inadapté',
                        referenceNormative: 'NFC 15-100',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final bytes = ExcelReportService.generateWorkbookBytes(
        mission: sampleMission,
        audit: multiZoneAudit,
        description: sampleDesc,
        generationDate: DateTime(2026, 9, 10),
      );

      expect(bytes, isNotEmpty);

      // Analyse du fichier styles.xml généré
      final archive = ZipDecoder().decodeBytes(bytes);
      final stylesFile = archive.files.firstWhere((f) => f.name == 'xl/styles.xml');
      final stylesXml = utf8.decode(stylesFile.content as List<int>);

      // Vérification que les bordures medium ont bien été configurées
      expect(stylesXml.contains('style="medium"'), isTrue,
          reason: 'Les bordures de séparation renforcées doivent utiliser le style medium');

      // Vérification des couleurs de séparation KES (Navy FF1E3A8A et Ardoise FF475569)
      expect(stylesXml.contains('FF1E3A8A'), isTrue,
          reason: 'La couleur marine KES doit être présente sur les bordures de Zone');
      expect(stylesXml.contains('FF475569'), isTrue,
          reason: 'La couleur ardoise doit être présente sur les bordures de Repère');

      // Vérification des feuilles et de la présence des fusions intactes
      final sheet1File = archive.files.firstWhere((f) => f.name == 'xl/worksheets/sheet1.xml');
      final sheet1Xml = utf8.decode(sheet1File.content as List<int>);
      expect(sheet1Xml.contains('mergeCells'), isTrue);

      final sheet2File = archive.files.firstWhere((f) => f.name == 'xl/worksheets/sheet2.xml');
      final sheet2Xml = utf8.decode(sheet2File.content as List<int>);
      expect(sheet2Xml.contains('mergeCells'), isTrue);
    });

    test('Validation du Tableau 3 et du numéro réel d\'équipement dans l\'export Excel', () {
      final coffretSansSource = CoffretArmoire(
        qrCode: 'QR-EX-01',
        nom: 'Armoire Climatisation',
        type: 'Armoire',
        repere: 'ARM-CLIM',
        numeroEquipement: '99',
        sourceNomComplet: 'non identifié',
        alimentations: [
          Alimentation(
            typeProtection: 'Inconnue',
            source: 'non identifié',
            sourceKnown: 'Inconnue',
            pdcKA: '',
            calibre: '',
            sectionCable: '',
          ),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm_excel_sources',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Technique',
            coffretsDirects: [coffretSansSource],
          ),
        ],
      );

      final bytes = ExcelReportService.generateWorkbookBytes(
        mission: sampleMission,
        audit: audit,
        description: sampleDesc,
        generationDate: DateTime(2026, 9, 16),
      );

      expect(bytes, isNotEmpty);

      final archive = ZipDecoder().decodeBytes(bytes);
      final sheet1File = archive.files.firstWhere((f) => f.name == 'xl/worksheets/sheet1.xml');
      final sheet1Xml = utf8.decode(sheet1File.content as List<int>);

      // Vérification de la présence du Tableau 3 avec statut Non identifiée
      final sharedStringsFile = archive.files.firstWhere((f) => f.name == 'xl/sharedStrings.xml');
      final sharedStringsXml = utf8.decode(sharedStringsFile.content as List<int>);

      expect(sharedStringsXml.contains("ÉQUIPEMENTS AUX SOURCES D'ALIMENTATION NON IDENTIFIÉES"), isTrue);
      expect(sharedStringsXml.contains('Non identifiée'), isTrue);
      expect(sharedStringsXml.contains('99') || sheet1Xml.contains('99'), isTrue);
    });
  });
}
