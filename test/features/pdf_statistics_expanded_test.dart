// test/features/pdf_statistics_expanded_test.dart

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
import 'package:inspec_app/services/statistics/audit_finding_inventory_engine.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';

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
    tempDir = Directory.systemTemp.createTempSync('hive_pdf_stats_test');
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

  group('Expanded PDF Statistics Analytics Tests', () {
    test('Should calculate Top 10 defects, tension domains, and cross category items', () async {
      final missionId = 'mission_pdf_stats_001';
      final now = DateTime.now();

      final mission = Mission(
        id: missionId,
        nomClient: 'CLIENT EXPANDED STATS',
        dateIntervention: now,
        createdAt: now,
        updatedAt: now,
        status: 'en_cours',
      );
      await Hive.box<Mission>('missions').put(missionId, mission);

      final audit = AuditInstallationsElectriques.create(missionId);

      // Local MT
      final localMT = MoyenneTensionLocal(
        nom: 'Poste Livraison HTA',
        type: 'LOCAL_POSTE_HTA',
        dispositionsConstructives: [
          ElementControle(
            elementControle: 'Signalisation visible "Local électrique – Accès réservé au personnel habilité"',
            conforme: false,
            criticite: 'Majeure',
            familleRisque: 'Accès non autorisé / risque électrique',
            referenceNormative: 'NF C 15-100-7-729:2024 – § 729',
          ),
        ],
        coffrets: [
          CoffretArmoire(
            qrCode: 'QR_MT_01',
            nom: 'Armoire MT',
            type: 'ARMOIRE',
            pointsVerification: [
              PointVerification(
                pointVerification: 'Identification complète des circuits',
                conformite: 'non',
                criticite: 'Critique',
                familleRisque: 'Erreur d\'exploitation',
                referenceNormative: 'NF C 15-100-1:2024 – § 514',
              ),
            ],
          ),
        ],
      );
      audit.moyenneTensionLocaux.add(localMT);

      // Local BT
      final localBT = BasseTensionLocal(
        nom: 'Local TGBT Principal',
        type: 'LOCAL_TGBT',
        dispositionsConstructives: [
          ElementControle(
            elementControle: 'Éclairage normal',
            conforme: false,
            criticite: 'Critique',
          ),
        ],
        coffrets: [
          CoffretArmoire(
            qrCode: 'QR_BT_01',
            nom: 'TGBT N°1',
            type: 'TGBT',
            pointsVerification: [
              PointVerification(
                pointVerification: 'Identification complète des circuits',
                conformite: 'non',
                criticite: 'Majeure',
              ),
              PointVerification(
                pointVerification: 'Identification complète des circuits',
                conformite: 'non',
                criticite: 'Majeure',
              ),
              PointVerification(
                pointVerification: 'Protection contacts directs / indirects',
                conformite: 'non',
                criticite: 'Critique',
              ),
            ],
          ),
        ],
      );
      final zoneBT = BasseTensionZone(nom: 'Zone Usine', locaux: [localBT]);
      audit.basseTensionZones.add(zoneBT);

      await Hive.box<AuditInstallationsElectriques>('audit_installations_electriques').put(missionId, audit);

      final inventory = AuditFindingInventoryEngine.buildInventory(missionId);
      expect(inventory.totalFindings, equals(6));

      // Test Top 10 Defects
      final topDefects = inventory.getTopDefects(limit: 10);
      expect(topDefects.isNotEmpty, isTrue);
      // Identification complète des circuits (3 occurrences)
      expect(topDefects.first.title, equals('Identification complète des circuits'));
      expect(topDefects.first.count, equals(3));

      // Test Tension Domain
      final domainStats = inventory.getTensionDomainStats();
      expect(domainStats.mtCount, equals(2)); // Local MT DC + Armoire MT PV
      expect(domainStats.btCount, equals(4)); // Local BT DC + 3 TGBT PV
      expect(domainStats.totalCount, equals(6));

      // Test Cross Category Analysis
      final crossItems = inventory.getCrossCategoryAnalysis();
      expect(crossItems, isNotNull);
    });
  });
}
