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
import 'package:inspec_app/services/pdf_report_service.dart';

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

  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  test('Should deduplicate coffret and description photos in PDF generation', () async {
    final tempDir = Directory.systemTemp.createTempSync('hive_photos_test');
    Hive.init(tempDir.path);

    Hive.registerAdapter(VerificateurAdapter());
    Hive.registerAdapter(MissionAdapter());
    Hive.registerAdapter(DescriptionInstallationsAdapter());
    Hive.registerAdapter(AuditInstallationsElectriquesAdapter());
    Hive.registerAdapter(MoyenneTensionLocalAdapter());
    Hive.registerAdapter(MoyenneTensionZoneAdapter());
    Hive.registerAdapter(BasseTensionZoneAdapter());
    Hive.registerAdapter(BasseTensionLocalAdapter());
    Hive.registerAdapter(ElementControleAdapter());
    Hive.registerAdapter(CelluleAdapter());
    Hive.registerAdapter(TransformateurMTBTAdapter());
    Hive.registerAdapter(CoffretArmoireAdapter());
    Hive.registerAdapter(AlimentationAdapter());
    Hive.registerAdapter(PointVerificationAdapter());
    Hive.registerAdapter(ClassementEmplacementAdapter());
    Hive.registerAdapter(FoudreAdapter());
    Hive.registerAdapter(MesuresEssaisAdapter());
    Hive.registerAdapter(ConditionMesureAdapter());
    Hive.registerAdapter(EssaiDemarrageAutoAdapter());
    Hive.registerAdapter(TestArretUrgenceAdapter());
    Hive.registerAdapter(PriseTerreAdapter());
    Hive.registerAdapter(AvisMesuresTerreAdapter());
    Hive.registerAdapter(EssaiDeclenchementDifferentielAdapter());
    Hive.registerAdapter(ContinuiteResistanceAdapter());
    Hive.registerAdapter(ObservationLibreAdapter());
    Hive.registerAdapter(InstallationItemAdapter());
    Hive.registerAdapter(RenseignementsGenerauxAdapter());
    Hive.registerAdapter(JSAAdapter());
    Hive.registerAdapter(JSAInspecteurAdapter());
    Hive.registerAdapter(JSAPlanUrgenceAdapter());
    Hive.registerAdapter(JSADangersAdapter());
    Hive.registerAdapter(JSAExigencesGeneralesAdapter());
    Hive.registerAdapter(JSAEPIAdapter());
    Hive.registerAdapter(JSAVerificationFinaleAdapter());
    Hive.registerAdapter(ClassementZoneAdapter());
    Hive.registerAdapter(LastReportAdapter());

    final missionsBox = await Hive.openBox<Mission>('missions');
    final descBox = await Hive.openBox<DescriptionInstallations>('description_installations');
    final auditBox = await Hive.openBox<AuditInstallationsElectriques>('audit_installations_electriques');
    await Hive.openBox<ClassementEmplacement>('classement_locaux');
    await Hive.openBox<Foudre>('foudre_observations');
    await Hive.openBox<MesuresEssais>('mesures_essais');
    final verificateursBox = await Hive.openBox<Verificateur>('verificateurs');
    final currentUserBox = await Hive.openBox('current_user');
    await Hive.openBox<RenseignementsGeneraux>('renseignements_generaux');
    await Hive.openBox<ClassementZone>('classement_zones');

    final verificateur = Verificateur(
      id: 'v1',
      nom: 'Tchoffo',
      prenom: 'Andelson',
      email: 'andelson@kes.com',
      password: 'pwd',
      matricule: 'KES-001',
      createdAt: DateTime.now(),
    );
    await verificateursBox.put(verificateur.email.toLowerCase(), verificateur);
    await currentUserBox.put('current_user', verificateur.email.toLowerCase());

    const missionId = 'mission_photos_dedup';

    final mission = Mission(
      id: missionId,
      nomClient: 'CLIENT TEST PHOTOS',
      nomSite: 'AGENCE BAFOUSSAM',
      installation: 'BT',
      natureMission: 'Audit',
      status: 'en_cours',
      dateIntervention: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await missionsBox.put(mission.id, mission);

    // Description avec photo
    final desc = DescriptionInstallations(
      missionId: missionId,
      alimentationMoyenneTension: [
        InstallationItem(data: {'Nom': 'Poste HTA'}, photoPaths: ['/tmp/photo_desc_1.jpg']),
      ],
      updatedAt: DateTime.now(),
    );
    await descBox.put(missionId, desc);

    // Audit avec coffret ayant des photos identiques dans photos, photosExternes et photosInternes
    final coffret = CoffretArmoire(
      nom: 'TGBT Principal',
      type: 'Coffret',
      qrCode: 'QR-001',
      photos: ['/tmp/photo_ext_1.jpg', '/tmp/photo_int_1.jpg'],
      photosExternes: ['/tmp/photo_ext_1.jpg'],
      photosInternes: ['/tmp/photo_int_1.jpg'],
    );

    final local = MoyenneTensionLocal(
      nom: 'Local TGBT',
      type: 'Local',
      coffrets: [coffret],
    );

    final audit = AuditInstallationsElectriques(
      missionId: missionId,
      moyenneTensionLocaux: [local],
      updatedAt: DateTime.now(),
    );
    await auditBox.put(missionId, audit);

    final file = await PdfReportService.generateMissionReport(missionId);
    expect(file, isNotNull);
    expect(await file!.exists(), isTrue);
  });
}
