import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/gallery_photo_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GalleryPhotoService Unit Tests', () {
    test('saveToGallery should return false for null file', () async {
      final result = await GalleryPhotoService.saveToGallery(null);
      expect(result, isFalse);
    });

    test('saveToGallery should return false for non-existent file', () async {
      final nonExistentFile = File('/tmp/non_existent_photo_12345.jpg');
      final result = await GalleryPhotoService.saveToGallery(nonExistentFile);
      expect(result, isFalse);
    });

    test('GalleryPhotoService albumName should be "KES Inspection"', () {
      expect(GalleryPhotoService.albumName, equals('KES Inspection'));
    });
  });
}
