import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/components/safe_file_image.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String path;
  FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_image_test_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('AppImageUtils.resolvePathAsync ré-ancre un chemin absolu obsolète vers le dossier courant', () async {
    // 1. Créer une photo physique dans le répertoire temporaire imitant app_flutter/audit_photos/locaux/photo.jpg
    final photoDir = Directory('${tempDir.path}/audit_photos/locaux');
    await photoDir.create(recursive: true);
    final photoFile = File('${photoDir.path}/test_photo.jpg');
    await photoFile.writeAsString('fake_image_bytes');

    // 2. Simuler un ancien chemin absolu provenant d'un autre téléphone ou sandbox Android/iOS
    const stalePath = '/data/user/0/com.example.old_app/app_flutter/audit_photos/locaux/test_photo.jpg';

    // 3. Résoudre
    final resolvedPath = await AppImageUtils.resolvePathAsync(stalePath);

    expect(resolvedPath, isNotNull);
    expect(resolvedPath, equals(photoFile.path));
    expect(File(resolvedPath!).existsSync(), isTrue);
  });

  test('AppImageUtils.resolvePathAsync retourne le chemin direct s\'il existe', () async {
    final directFile = File('${tempDir.path}/direct_photo.jpg');
    await directFile.writeAsString('bytes');

    final resolved = await AppImageUtils.resolvePathAsync(directFile.path);
    expect(resolved, equals(directFile.path));
  });

  test('AppImageUtils.resolvePathAsync retourne null si le fichier n\'existe nulle part', () async {
    const nonexistentPath = '/data/user/0/com.example.app/app_flutter/audit_photos/locaux/ghost.jpg';
    final resolved = await AppImageUtils.resolvePathAsync(nonexistentPath);
    expect(resolved, isNull);
  });
}
