// lib/services/photo_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class PhotoService {
  static final ImagePicker _picker = ImagePicker();
  
  // Configuration optimisée
  static const double _maxWidth = 800;
  static const double _maxHeight = 800;
  static const int _imageQuality = 75;
  
  // Cache pour éviter les doublons
  static final Set<String> _processingPhotos = {};
  
  /// Prendre une photo avec gestion mémoire optimisée
  static Future<String?> takePhoto(String subDir) async {
    try {
      await _cleanupMemory();
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: _imageQuality,
        maxWidth: _maxWidth,
        maxHeight: _maxHeight,
      );
      
      if (photo == null) return null;
      
      final file = File(photo.path);
      if (!await file.exists()) return null;
      
      return await _savePhotoToDirectory(file, subDir);
      
    } catch (e) {
      if (kDebugMode) print('❌ Erreur prise photo: $e');
      return null;
    }
  }
  
  /// Choisir une photo depuis la galerie
  static Future<String?> pickPhoto(String subDir) async {
    try {
      await _cleanupMemory();
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: _imageQuality,
        maxWidth: _maxWidth,
        maxHeight: _maxHeight,
      );
      
      if (photo == null) return null;
      
      final file = File(photo.path);
      if (!await file.exists()) return null;
      
      return await _savePhotoToDirectory(file, subDir);
      
    } catch (e) {
      if (kDebugMode) print('❌ Erreur sélection photo: $e');
      return null;
    }
  }
  
  /// Sauvegarder la photo
  static Future<String> _savePhotoToDirectory(File sourceFile, String subDir) async {
    try {
      if (!await sourceFile.exists()) {
        throw Exception('Fichier source introuvable');
      }
      
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/audit_photos/$subDir');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = DateTime.now().microsecondsSinceEpoch % 10000;
      final fileName = '${subDir}_${timestamp}_$random.jpg';
      final newPath = '${photosDir.path}/$fileName';
      
      if (_processingPhotos.contains(newPath)) {
        throw Exception('Photo déjà en cours de traitement');
      }
      _processingPhotos.add(newPath);
      
      await sourceFile.copy(newPath);
      
      final savedFile = File(newPath);
      if (!await savedFile.exists()) {
        throw Exception('Échec de la sauvegarde');
      }
      
      _processingPhotos.remove(newPath);
      
      if (sourceFile.path != newPath && await sourceFile.exists()) {
        await sourceFile.delete().catchError((_) {});
      }
      
      if (kDebugMode) print('✅ Photo sauvegardée: $newPath');
      return newPath;
      
    } catch (e) {
      _processingPhotos.removeWhere((key) => key.contains(subDir));
      if (kDebugMode) print('❌ Erreur sauvegarde photo: $e');
      rethrow;
    }
  }
  
  static Future<void> _cleanupMemory() async {
    try {
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {}
  }
  
  static Future<bool> deletePhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) print('✅ Photo supprimée: $photoPath');
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur suppression photo: $e');
    }
    return false;
  }
}