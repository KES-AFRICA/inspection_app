// test/features/autonomous_observation_test.dart

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
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/statistics/audit_finding_inventory_engine.dart';
import 'package:inspec_app/services/statistics/audit_diagnostic_engine.dart';

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
    tempDir = Directory.systemTemp.createTempSync('hive_auto_obs_test');
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

  group('Autonomous Observations & Silent Migration Tests', () {
    test('Should persist metadata directly on PointVerification and ElementControle', () async {
      final missionId = 'mission_auto_001';
      final now = DateTime.now();

      final mission = Mission(
        id: missionId,
        nomClient: 'CLIENT AUTONOME',
        dateIntervention: now,
        createdAt: now,
        updatedAt: now,
        status: 'en_cours',
      );
      final missionBox = Hive.box<Mission>('missions');
      await missionBox.put(missionId, mission);

      final audit = AuditInstallationsElectriques.create(missionId);

      // Création directe avec métadonnées persistées
      final localBT = BasseTensionLocal(
        nom: 'TGBT Principal',
        type: 'LOCAL_TGBT',
        dispositionsConstructives: [
          ElementControle(
            elementControle: 'Éclairage normal',
            conforme: false,
            criticite: 'Critique',
            familleRisque: 'Électrisation / électrocution',
            referenceNormative: 'Norme NF C 13-200 art 541',
          ),
        ],
        coffrets: [
          CoffretArmoire(
            qrCode: 'QR_AUTONOME',
            nom: 'Coffret Armoire Autonome',
            type: 'ARMOIRE',
            pointsVerification: [
              PointVerification(
                pointVerification: 'Identification complète des circuits',
                conformite: 'non',
                criticite: 'Majeure',
                familleRisque: 'Erreur d\'exploitation / maintenance',
                referenceNormative: 'NF C 15-100-1:2024 – § 514',
                priorite: 3, // Priorité terrain d'intervention
              ),
              PointVerification(
                pointVerification: 'Point sur-mesure créé à la main',
                conformite: 'non',
                criticite: null, // Point sur-mesure à la main -> null
                familleRisque: null,
                referenceNormative: null,
                priorite: null, // null
              ),
            ],
          ),
        ],
      );

      final zoneBT = BasseTensionZone(
        nom: 'Zone Technique',
        locaux: [localBT],
      );
      audit.basseTensionZones.add(zoneBT);

      final auditBox = Hive.box<AuditInstallationsElectriques>('audit_installations_electriques');
      await auditBox.put(missionId, audit);

      // Test d'inventaire
      final inventory = AuditFindingInventoryEngine.buildInventory(missionId);
      expect(inventory.totalFindings, equals(3));

      // L'éclairage (Critique)
      final elFinding = inventory.findings.firstWhere((f) => f.verificationPoint == 'Éclairage normal');
      expect(elFinding.criticality, equals('Critique'));

      // L'identification (Majeure persistée malgré priorite: 3)
      final pvFinding = inventory.findings.firstWhere((f) => f.verificationPoint == 'Identification complète des circuits');
      expect(pvFinding.criticality, equals('Majeure'));
      expect(pvFinding.priority, equals(3));

      // Le point sur-mesure à la main (Non spécifiée)
      final customFinding = inventory.findings.firstWhere((f) => f.verificationPoint == 'Point sur-mesure créé à la main');
      expect(customFinding.criticality, equals('Non spécifiée'));
      expect(customFinding.priority, isNull);
    });

    test('Should silently migrate legacy missions without persisted metadata', () async {
      final missionId = 'mission_legacy_002';
      final now = DateTime.now();

      final mission = Mission(
        id: missionId,
        nomClient: 'CLIENT LEGACY',
        dateIntervention: now,
        createdAt: now,
        updatedAt: now,
        status: 'en_cours',
      );
      final missionBox = Hive.box<Mission>('missions');
      await missionBox.put(missionId, mission);

      // Ancienne structure Hive sans criticité/familleRisque persistées
      final audit = AuditInstallationsElectriques.create(missionId);

      final localMT = MoyenneTensionLocal(
        nom: 'Poste HTA',
        type: 'LOCAL_POSTE_HTA',
        dispositionsConstructives: [
          ElementControle(
            elementControle: 'Signalisation visible "Local électrique – Accès réservé au personnel habilité"',
            conforme: false,
            priorite: 2,
            criticite: null,
            familleRisque: null,
            referenceNormative: null,
          ),
        ],
        coffrets: [
          CoffretArmoire(
            qrCode: 'QR_LEGACY',
            nom: 'Coffret BT',
            type: 'COFFRET',
            pointsVerification: [
              PointVerification(
                pointVerification: 'Emplacement / Dégagement autour',
                conformite: 'non',
                priorite: 3,
                criticite: null,
                familleRisque: null,
                referenceNormative: null,
              ),
            ],
          ),
        ],
      );
      audit.moyenneTensionLocaux.add(localMT);

      final auditBox = Hive.box<AuditInstallationsElectriques>('audit_installations_electriques');
      await auditBox.put(missionId, audit);

      // Exécution de la migration transparente lors du get
      final retrievedAudit = HiveService.getAuditInstallationsByMissionId(missionId);
      expect(retrievedAudit, isNotNull);

      // Vérification que l'instance en base a été silencieusement migrée
      final migratedEl = retrievedAudit!.moyenneTensionLocaux.first.dispositionsConstructives.first;
      expect(migratedEl.criticite, equals('Majeure'));
      expect(migratedEl.familleRisque, equals('Accès non autorisé / risque électrique'));
      expect(migratedEl.referenceNormative, equals('NF C 15-100-7-729:2024 – § 729'));

      final migratedPv = retrievedAudit.moyenneTensionLocaux.first.coffrets.first.pointsVerification.first;
      expect(migratedPv.criticite, equals('Majeure'));
      expect(migratedPv.familleRisque, equals('Accès / exploitation / intervention'));
      expect(migratedPv.referenceNormative, equals('NF C 15-100-1:2024 – § 513'));

      // Vérification de l'inventaire
      final inventory = AuditFindingInventoryEngine.buildInventory(missionId);
      expect(inventory.totalFindings, equals(2));
      expect(inventory.majeureCount, equals(2));
      expect(inventory.critiqueCount, equals(0));
    });
  });
}
