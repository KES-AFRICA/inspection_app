import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/lighting_inspection.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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

  test('LightingInspection & NonConformingLuminaire models CRUD & calculate non-conformities', () async {
    final tempDir = Directory.systemTemp.createTempSync('hive_lighting_test');
    Hive.init(tempDir.path);

    Hive.registerAdapter(LuminaireQuestionAnswerAdapter());
    Hive.registerAdapter(NonConformingLuminaireAdapter());
    Hive.registerAdapter(LightingInspectionAdapter());

    final box = await Hive.openBox<LightingInspection>('lighting_inspections_test');

    final answer1 = LuminaireQuestionAnswer(
      questionIndex: 1,
      isConform: false,
      commentaire: 'Boîtier fissuré',
      photoPaths: ['/tmp/photo_q1.jpg'],
    );

    final answer2 = LuminaireQuestionAnswer(
      questionIndex: 2,
      isConform: true,
    );

    final luminaireNC = NonConformingLuminaire(
      id: 'lum_nc_1',
      repereLocalisation: 'Plafond bureau 102',
      answers: [answer1, answer2],
    );

    expect(luminaireNC.nbNonConformities, equals(1));

    final inspection = LightingInspection(
      id: 'insp_l_1',
      missionId: 'mission_100',
      batimentLocal: 'Bâtiment Principal - Bureau 102',
      typeLuminaire: 'Dalle LED 60x60',
      dateVerification: DateTime.now(),
      nbLuminairesConformes: 8,
      nonConformingLuminaires: [luminaireNC],
    );

    expect(inspection.nbLuminairesConformes, equals(8));
    expect(inspection.nbLuminairesNonConformes, equals(1));
    expect(inspection.nbTotalLuminaires, equals(9));
    expect(inspection.status, equals('Non conforme'));

    await box.put(inspection.id, inspection);

    final fetched = box.get('insp_l_1');
    expect(fetched, isNotNull);
    expect(fetched!.batimentLocal, equals('Bâtiment Principal - Bureau 102'));
    expect(fetched.nonConformingLuminaires.length, equals(1));
    expect(fetched.nonConformingLuminaires.first.answers.first.commentaire, equals('Boîtier fissuré'));
    expect(fetched.nonConformingLuminaires.first.answers.first.photoPaths, contains('/tmp/photo_q1.jpg'));
  });
}
