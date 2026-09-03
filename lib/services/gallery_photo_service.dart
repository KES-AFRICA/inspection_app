import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

/// Service de sauvegarde des photos d'inspection dans la Galerie / Photos native du téléphone.
///
/// Ce service gère la copie locale des photos prises par l'appareil photo dans un album dédié
/// (ex: "KES Inspection").
///
/// Principes fondamentaux :
/// 1. Indépendance totale vis-à-vis du système métier de la mission.
/// 2. Tolérance absolue aux erreurs (un échec de sauvegarde Galerie n'interrompt JAMAIS l'inspection).
/// 3. Préservation de la photo originale non compressée autant que possible.
class GalleryPhotoService {
  static const String albumName = 'KES Inspection';

  /// Sauvegarde une copie de la photo originale prise par la caméra dans la galerie du téléphone.
  ///
  /// [photoFile] : Fichier temporaire issu de la prise de vue originale (ImagePicker / Camera).
  ///
  /// Cette méthode s'exécute de manière asynchrone et isole toutes les exceptions
  /// pour garantir l'absence d'impact sur la mission métier.
  static Future<bool> saveToGallery(File? photoFile) async {
    if (photoFile == null || !await photoFile.exists()) {
      if (kDebugMode) {
        print('⚠️ GalleryPhotoService: Fichier photo nul ou inexistant.');
      }
      return false;
    }

    try {
      // Sauvegarde de l'image originale dans l'album dédié via la bibliothèque Gal (MediaStore / PhotoKit)
      await Gal.putImage(
        photoFile.path,
        album: albumName,
      );

      if (kDebugMode) {
        print('📸 [Galerie] Photo originale sauvegardée avec succès dans l\'album "$albumName" : ${photoFile.path}');
      }
      return true;
    } on GalException catch (e) {
      if (kDebugMode) {
        print('⚠️ [Galerie] Exception Gal lors de la sauvegarde dans la Galerie : ${e.type.message}');
      }
      return false;
    } catch (e, stack) {
      if (kDebugMode) {
        print('⚠️ [Galerie] Erreur inattendue lors de la sauvegarde Galerie : $e\n$stack');
      }
      return false;
    }
  }
}
