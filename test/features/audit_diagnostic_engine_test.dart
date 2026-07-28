// test/features/audit_diagnostic_engine_test.dart

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
import 'package:inspec_app/services/statistics/audit_diagnostic_engine.dart';
import 'package:inspec_app/services/dispositions_constructives_registry.dart';

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
    tempDir = Directory.systemTemp.createTempSync('hive_diag_test');
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

  group('AuditDiagnosticEngine Tests', () {
    test('Should resolve normative criticality for Coffret points via DispositionsConstructivesRegistry', () async {
      final meta = DispositionsConstructivesRegistry.getCoffretMetadata("Emplacement / Dégagement autour");
      expect(meta, isNotNull);
      expect(meta!.criticite, equals("Majeure"));
    });
  });
}
