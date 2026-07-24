import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive_io.dart';

void main() {
  test('Archive streaming zip test', () async {
    final tempDir = Directory.systemTemp.createTempSync('zip_test_');
    final zipPath = '${tempDir.path}/test_backup.zip';
    
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    
    final manifestFile = File('${tempDir.path}/manifest.json');
    manifestFile.writeAsStringSync('{"magic": "INSPEC_BACKUP_V4", "version": 4}');
    await encoder.addFile(manifestFile);
    
    final photoFile = File('${tempDir.path}/dummy_photo.jpg');
    photoFile.writeAsBytesSync(List.generate(1024 * 100, (i) => i % 256));
    await encoder.addFile(photoFile, 'photos/audit_photos/misc/dummy_photo.jpg');
    
    await encoder.close();
    
    final zipFile = File(zipPath);
    expect(zipFile.existsSync(), true);
    print("Created Zip Archive of size: ${zipFile.lengthSync()} bytes");
    
    final extractDir = '${tempDir.path}/extracted';
    await extractFileToDisk(zipPath, extractDir);
    
    final extractedManifest = File('$extractDir/manifest.json');
    expect(extractedManifest.existsSync(), true);
    print("Extracted manifest: ${extractedManifest.readAsStringSync()}");
    
    final extractedPhoto = File('$extractDir/photos/audit_photos/misc/dummy_photo.jpg');
    expect(extractedPhoto.existsSync(), true);
    print("Extracted photo size: ${extractedPhoto.lengthSync()} bytes");
    
    tempDir.deleteSync(recursive: true);
    print("✅ extractFileToDisk Streaming Test Passed!");
  });
}
