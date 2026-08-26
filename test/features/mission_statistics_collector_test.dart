// test/features/mission_statistics_collector_test.dart

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/models/last_report.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/services/statistics/mission_statistics_collector.dart';
import 'package:inspec_app/services/statistics/audit_finding_inventory_engine.dart';
import 'package:inspec_app/services/statistics/unified_observation.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
  @override
  Future<String?> getApplicationSupportPath() async => Directory.systemTemp.path;
  @override
  Future<String?> getApplicationDocumentsPath() async => Directory.systemTemp.path;
  @override
  Future<String?> getLibraryPath() async => null;
  @override
  Future<String?> getExternalStoragePath() async => null;
  @override
  Future<List<String>?> getExternalCachePaths() async => null;
  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async => null;
  @override
  Future<String?> getDownloadsPath() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    PathProviderPlatform.instance = MockPathProviderPlatform();
    tempDir = Directory.systemTemp.createTempSync('hive_stats_test');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(VerificateurAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MissionAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DescriptionInstallationsAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AuditInstallationsElectriquesAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(MoyenneTensionLocalAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(MoyenneTensionZoneAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(BasseTensionZoneAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(BasseTensionLocalAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(ElementControleAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(CelluleAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(TransformateurMTBTAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(CoffretArmoireAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(AlimentationAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(PointVerificationAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(ClassementEmplacementAdapter());
    if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(FoudreAdapter());
    if (!Hive.isAdapterRegistered(16)) Hive.registerAdapter(MesuresEssaisAdapter());
    if (!Hive.isAdapterRegistered(17)) Hive.registerAdapter(ConditionMesureAdapter());
    if (!Hive.isAdapterRegistered(18)) Hive.registerAdapter(EssaiDemarrageAutoAdapter());
    if (!Hive.isAdapterRegistered(19)) Hive.registerAdapter(TestArretUrgenceAdapter());
    if (!Hive.isAdapterRegistered(20)) Hive.registerAdapter(PriseTerreAdapter());
    if (!Hive.isAdapterRegistered(21)) Hive.registerAdapter(AvisMesuresTerreAdapter());
    if (!Hive.isAdapterRegistered(22)) Hive.registerAdapter(EssaiDeclenchementDifferentielAdapter());
    if (!Hive.isAdapterRegistered(23)) Hive.registerAdapter(ContinuiteResistanceAdapter());
    if (!Hive.isAdapterRegistered(24)) Hive.registerAdapter(ObservationLibreAdapter());
    if (!Hive.isAdapterRegistered(25)) Hive.registerAdapter(InstallationItemAdapter());
    if (!Hive.isAdapterRegistered(26)) Hive.registerAdapter(RenseignementsGenerauxAdapter());
    if (!Hive.isAdapterRegistered(27)) Hive.registerAdapter(JSAAdapter());

    await Hive.openBox<Mission>('missions');
    await Hive.openBox<AuditInstallationsElectriques>('audit_installations_electriques');
    await Hive.openBox<Foudre>('foudre_observations');
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('MissionStatisticsCollector Pipeline Tests', () {
    test('Should collect all non-conformities across MT, BT, GE, cells, transformers, equipment & Foudre via AuditFindingInventoryEngine', () async {
      final missionId = 'mission_test_stats_001';

      final now = DateTime.now();
      final mission = Mission(
        id: missionId,
        nomClient: 'CLIENT TEST ENGINE',
        dateIntervention: now,
        createdAt: now,
        updatedAt: now,
        status: 'en_cours',
      );
      final missionBox = Hive.box<Mission>('missions');
      await missionBox.put(missionId, mission);

      final audit = AuditInstallationsElectriques.create(missionId);

      // Local MT
      final mtLocal = MoyenneTensionLocal(
        nom: 'Poste MT 1',
        type: 'LOCAL_POSTE_HTA',
        dispositionsConstructives: [
          ElementControle(elementControle: 'Porte d\'accès au local', conforme: false, priorite: 3, criticite: 'Critique', referenceNormative: 'NF C 13-100:2015 – § 7.3'),
        ],
        conditionsExploitation: [
          ElementControle(elementControle: 'Outillage d\'isolement', conforme: false, priorite: 2, criticite: 'Majeure', referenceNormative: 'NF C 13-100:2015 – § 7.3'),
        ],
        cellules: [
          Cellule(
            fonction: 'Arrivée HTA',
            type: 'Interrupteur',
            marqueModeleAnnee: 'Schneider 2020',
            tensionAssignee: '24 kV',
            pouvoirCoupure: '16 kA',
            numerotation: 'C1',
            parafoudres: 'Oui',
            elementsVerifies: [
              ElementControle(elementControle: 'Verrouillage mécanique', conforme: false, priorite: 3, criticite: 'Critique', referenceNormative: 'NF C 13-100:2015 – § 7.3'),
            ],
          ),
        ],
        transformateurs: [
          TransformateurMTBT(
            typeTransformateur: 'Huile',
            marqueAnnee: 'France Transfo 2018',
            puissanceAssignee: '630 kVA',
            tensionPrimaireSecondaire: '20kV / 400V',
            relaisBuchholz: 'Oui',
            typeRefroidissement: 'ONAN',
            regimeNeutre: 'TN',
            elementsVerifies: [
              ElementControle(elementControle: 'Niveau d\'huile', conforme: false, priorite: 2, criticite: 'Majeure', referenceNormative: 'NF C 13-100:2015 – § 7.3'),
            ],
          ),
        ],
      );
      audit.moyenneTensionLocaux.add(mtLocal);

      // Local GE
      final geLocal = BasseTensionLocal(
        nom: 'Local Groupe Électrogène',
        type: 'LOCAL_GROUPE_ELECTROGENE',
        dispositionsConstructives: [
          ElementControle(elementControle: 'Bac de rétention fuel', conforme: false, priorite: 3, criticite: 'Critique', referenceNormative: 'NF C 15-100-1:2024 – § 512'),
        ],
        coffrets: [
          CoffretArmoire(
            qrCode: 'QR_TGBT_01',
            nom: 'TGBT Principal',
            type: 'TGBT',
            pointsVerification: [
              PointVerification(
                pointVerification: 'Protection IP2X',
                conformite: 'non',
                observation: 'Plastron manquant',
                priorite: 2,
                criticite: 'Majeure',
                referenceNormative: 'NF C 15-100-1:2024 – § 512',
              ),
              PointVerification(
                pointVerification: 'Identification circuits',
                conformite: 'oui',
              ),
              PointVerification(
                pointVerification: 'Présence schéma',
                conformite: 'sans_objet',
              ),
            ],
          ),
        ],
      );

      final btZone = BasseTensionZone(
        nom: 'Zone Usine',
        locaux: [geLocal],
      );
      audit.basseTensionZones.add(btZone);

      final auditBox = Hive.box<AuditInstallationsElectriques>('audit_installations_electriques');
      await auditBox.put(missionId, audit);

      // Foudre
      final foudre1 = Foudre.create(
        missionId: missionId,
        niveauPriorite: 1,
        observation: 'Corrosion sur collier de descente',
      );
      final foudreBox = Hive.box<Foudre>('foudre_observations');
      await foudreBox.put('foudre_1', foudre1);

      // EXÉCUTION DU MOTEUR D'INVENTAIRE ET IMPRESSION CONSOLE
      final inventory = AuditFindingInventoryEngine.buildInventory(missionId);
      inventory.printDiagnostic();

      expect(inventory.missionId, equals(missionId));
      expect(inventory.totalFindings, equals(7)); // 1 DC MT + 1 CE MT + 1 Cellule + 1 Transfo + 1 GE + 1 TGBT + 1 Foudre

      // Vérification des criticités recensées
      expect(inventory.critiqueCount, equals(3)); // Porte d'accès (3), Cellule (3), GE Rétention (3)
      expect(inventory.majeureCount, equals(3));  // Outillage (2), Transfo (2), TGBT IP2X (2)
      expect(inventory.mineureCount, equals(1));  // Foudre (1)

      // Exécution de la façade collector
      final stats = MissionStatisticsCollector.collect(missionId);
      final cStats = stats.criticalityStats;
      expect(cStats.critique, equals(3));
      expect(cStats.majeure, equals(3));
      expect(cStats.mineure, equals(1));
      expect(cStats.total, equals(7));
    });

    test('Should NOT count ObservationLibre items as Mineure non-conformities', () async {
      final missionId = 'mission_test_obs_libres_002';
      final now = DateTime.now();

      final mission = Mission(
        id: missionId,
        nomClient: 'CLIENT OBS LIBRES',
        dateIntervention: now,
        createdAt: now,
        updatedAt: now,
        status: 'en_cours',
      );
      final missionBox = Hive.box<Mission>('missions');
      await missionBox.put(missionId, mission);

      final audit = AuditInstallationsElectriques.create(missionId);

      // 1 seule non-conformité avec criticité 1 (Mineure)
      final foudre1 = Foudre.create(
        missionId: missionId,
        niveauPriorite: 1,
        observation: 'Point foudre mineur',
      );
      final foudreBox = Hive.box<Foudre>('foudre_observations');
      await foudreBox.put('foudre_obs_libres_1', foudre1);

      // 4 observations libres dans une zone BT
      final btZone = BasseTensionZone(
        nom: 'Zone Stockage',
        observationsLibres: [
          ObservationLibre(texte: 'Remarque libre 1'),
          ObservationLibre(texte: 'Remarque libre 2'),
          ObservationLibre(texte: 'Remarque libre 3'),
          ObservationLibre(texte: 'Remarque libre 4'),
        ],
      );
      audit.basseTensionZones.add(btZone);

      final auditBox = Hive.box<AuditInstallationsElectriques>('audit_installations_electriques');
      await auditBox.put(missionId, audit);

      final inventory = AuditFindingInventoryEngine.buildInventory(missionId);
      inventory.printDiagnostic();

      expect(inventory.mineureCount, equals(1));
      expect(inventory.critiqueCount, equals(0));
      expect(inventory.majeureCount, equals(0));
      expect(inventory.unspecifiedCount, equals(0));
    });
  });
}
