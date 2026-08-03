import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive_io.dart';
import 'package:inspec_app/services/backup/backup_format_strategy.dart';
import 'package:inspec_app/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multi-Format Backup Detection & Import Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('backup_multiformat_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('BackupFormatDetector should identify legacy JSON format correctly', () async {
      final jsonFile = File('${tempDir.path}/legacy_backup.json');
      final content = jsonEncode({
        'magic': 'INSPEC_BACKUP_V3',
        'schema_version': 3,
        'export_type': 'single_mission',
        'exported_at': '2026-08-03T10:00:00Z',
        'mission_count': 1,
        'missions': [
          {'id': 'm_legacy_1', 'nomClient': 'Client Legacy'}
        ],
      });
      await jsonFile.writeAsString(content);

      final formatInfo = await BackupFormatDetector.detectFormat(jsonFile);
      expect(formatInfo.format, equals(BackupFileFormat.jsonLegacy));
      expect(formatInfo.isSupported, isTrue);
    });

    test('BackupFormatDetector should identify BIN / ZIP V4 format correctly', () async {
      final binFilePath = '${tempDir.path}/backup_v4.bin';
      final encoder = ZipFileEncoder();
      encoder.create(binFilePath);

      final manifestFile = File('${tempDir.path}/manifest.json');
      await manifestFile.writeAsString(jsonEncode({
        'magic': 'INSPEC_BACKUP_V4',
        'schema_version': 4,
        'export_type': 'single_mission',
        'exported_at': '2026-08-03T10:00:00Z',
        'mission_count': 1,
      }));
      await encoder.addFile(manifestFile);
      await encoder.close();

      final binFile = File(binFilePath);
      expect(binFile.existsSync(), isTrue);

      final formatInfo = await BackupFormatDetector.detectFormat(binFile);
      expect(formatInfo.format, equals(BackupFileFormat.zipBin));
      expect(formatInfo.isZipHeader, isTrue);
      expect(formatInfo.isSupported, isTrue);
    });

    test('BackupFormatDetector should return unknown for invalid/corrupted files', () async {
      final dummyFile = File('${tempDir.path}/random_corrupted.xyz');
      await dummyFile.writeAsBytes([0x00, 0x01, 0x02, 0x03, 0x04]);

      final formatInfo = await BackupFormatDetector.detectFormat(dummyFile);
      expect(formatInfo.format, equals(BackupFileFormat.unknown));
      expect(formatInfo.isSupported, isFalse);
    });

    test('inspecterSauvegardeFichier should validate both JSON and BIN backup files', () async {
      // 1. Valid JSON Backup
      final jsonFile = File('${tempDir.path}/test_valid.json');
      await jsonFile.writeAsString(jsonEncode({
        'magic': 'INSPEC_BACKUP_V3',
        'schema_version': 3,
        'export_type': 'single_mission',
        'exported_at': '2026-08-03T10:00:00Z',
        'mission_count': 1,
      }));

      final jsonInspect = await BackupService.inspecterSauvegardeFichier(jsonFile.path);
      expect(jsonInspect.isValid, isTrue);
      expect(jsonInspect.magic, equals('INSPEC_BACKUP_V3'));

      // 2. Valid BIN Zip Backup
      final binPath = '${tempDir.path}/test_valid.bin';
      final encoder = ZipFileEncoder();
      encoder.create(binPath);

      final manifestFile = File('${tempDir.path}/manifest.json');
      await manifestFile.writeAsString(jsonEncode({
        'magic': 'INSPEC_BACKUP_V4',
        'schema_version': 4,
        'export_type': 'single_mission',
        'exported_at': '2026-08-03T10:00:00Z',
        'mission_count': 1,
      }));
      await encoder.addFile(manifestFile);
      await encoder.close();

      final binInspect = await BackupService.inspecterSauvegardeFichier(binPath);
      expect(binInspect.isValid, isTrue);
      expect(binInspect.magic, equals('INSPEC_BACKUP_V4'));
    });

    test('inspecterSauvegardeFichier & importerMissions should handle .inspec extension without extractFileToDisk ArgumentError', () async {
      final inspecPath = '${tempDir.path}/test_backup.inspec';
      final encoder = ZipFileEncoder();
      encoder.create(inspecPath);

      final manifestFile = File('${tempDir.path}/manifest.json');
      await manifestFile.writeAsString(jsonEncode({
        'magic': 'INSPEC_BACKUP_V4',
        'schema_version': 4,
        'export_type': 'single_mission',
        'exported_at': '2026-08-03T10:00:00Z',
        'mission_count': 1,
      }));
      await encoder.addFile(manifestFile);
      await encoder.close();

      final inspecFile = File(inspecPath);
      expect(inspecFile.existsSync(), isTrue);

      final inspectResult = await BackupService.inspecterSauvegardeFichier(inspecPath);
      expect(inspectResult.isValid, isTrue);
      expect(inspectResult.magic, equals('INSPEC_BACKUP_V4'));

      final realInspecFile = File('/home/andelson-teufack/Téléchargements/inspec_Camwater_2026-08-03T12-13-29.inspec');
      if (realInspecFile.existsSync()) {
        final realInspect = await BackupService.inspecterSauvegardeFichier(realInspecFile.path);
        expect(realInspect.isValid, isTrue);
        expect(realInspect.magic, equals('INSPEC_BACKUP_V4'));
      }
    });

    test('importerMissions should reject unsupported file formats gracefully', () async {
      final invalidFile = File('${tempDir.path}/invalid.xyz');
      await invalidFile.writeAsString('Invalid payload content');

      final result = await BackupService.importerMissions(
        invalidFile.path,
        importeurMatricule: 'TEST_MAT',
        importeurNom: 'Nom',
        importeurPrenom: 'Prenom',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Format de fichier non supporté'));
    });
  });
}
