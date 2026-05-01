import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class SafeImageService {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> takePhoto({
    required bool mounted,
    int imageQuality = 75,
    double maxWidth = 1024,
    double maxHeight = 1024,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (photo == null || !mounted) return null;
      return File(photo.path);
    } catch (e, stack) {
      debugPrint('📸 Camera error: $e');
      debugPrintStack(stackTrace: stack);
      return null;
    }
  }

  static Future<File?> pickFromGallery({
    required bool mounted,
    int imageQuality = 75,
    double maxWidth = 1024,
    double maxHeight = 1024,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (photo == null || !mounted) return null;
      return File(photo.path);
    } catch (e, stack) {
      debugPrint('🖼️ Gallery error: $e');
      debugPrintStack(stackTrace: stack);
      return null;
    }
  }
}