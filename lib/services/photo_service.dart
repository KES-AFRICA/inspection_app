// lib/services/photo_service.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PhotoService {
  static final ImagePicker _picker = ImagePicker();
  
  // Configuration optimisée
  static const double _maxWidth = 800;
  static const double _maxHeight = 800;
  static const int _imageQuality = 75; // Réduit de 85 à 75
  
  // Cache pour éviter les doublons
  static final Set<String> _processingPhotos = {};
  
  /// Prendre une photo avec gestion mémoire optimisée
  static Future<String?> takePhoto(String subDir) async {
    try {
      // Nettoyer la mémoire avant la prise de vue
      await _cleanupMemory();
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: _imageQuality,
        maxWidth: _maxWidth,
        maxHeight: _maxHeight,
      );
      
      if (photo == null) return null;
      
      // Vérifier si le fichier existe déjà
      final file = File(photo.path);
      if (!await file.exists()) return null;
      
      // Sauvegarder avec un nom unique
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
  
  /// Sauvegarder la photo avec gestion des conflits
  static Future<String> _savePhotoToDirectory(File sourceFile, String subDir) async {
    try {
      // Vérifier si le fichier source existe
      if (!await sourceFile.exists()) {
        throw Exception('Fichier source introuvable');
      }
      
      // Créer le répertoire de destination
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/audit_photos/$subDir');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      
      // Générer un nom unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = DateTime.now().microsecondsSinceEpoch % 10000;
      final fileName = '${subDir}_${timestamp}_$random.jpg';
      final newPath = '${photosDir.path}/$fileName';
      
      // Vérifier les doublons
      if (_processingPhotos.contains(newPath)) {
        throw Exception('Photo déjà en cours de traitement');
      }
      _processingPhotos.add(newPath);
      
      // Copier le fichier
      await sourceFile.copy(newPath);
      
      // Vérifier que la copie a réussi
      final savedFile = File(newPath);
      if (!await savedFile.exists()) {
        throw Exception('Échec de la sauvegarde');
      }
      
      // Nettoyer
      _processingPhotos.remove(newPath);
      
      // Supprimer le fichier temporaire si différent
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
  
  /// Nettoyer la mémoire
  static Future<void> _cleanupMemory() async {
    try {
      // Forcer le garbage collector
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      // Ignorer
    }
  }
  
  /// Supprimer une photo
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
  
  /// Vérifier si une photo existe
  static Future<bool> photoExists(String photoPath) async {
    try {
      final file = File(photoPath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
  
  /// Nettoyer les photos orphelines (non utilisées)
  static Future<void> cleanupOrphanPhotos(List<String> activePhotoPaths) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/audit_photos');
      
      if (!await photosDir.exists()) return;
      
      final activeSet = activePhotoPaths.toSet();
      
      await for (var entity in photosDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.jpg')) {
          if (!activeSet.contains(entity.path)) {
            await entity.delete().catchError((_) {});
            if (kDebugMode) print('🗑️ Photo orpheline supprimée: ${entity.path}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur nettoyage photos: $e');
    }
  }
}