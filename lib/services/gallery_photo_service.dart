import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

/// Service de sauvegarde des photos d'inspection dans la Galerie / Photos native du téléphone.
///
/// Ce service gère la copie locale des photos prises par l'appareil photo dans un album dédié
/// ("KES Inspection") ou dans la galerie principale en fallback.
///
/// Principes fondamentaux :
/// 1. Indépendance totale vis-à-vis du système métier de la mission.
/// 2. Tolérance absolue aux erreurs (un échec de sauvegarde Galerie n'interrompt JAMAIS l'inspection).
/// 3. Demande explicite de permission au premier usage via Gal.requestAccess().
/// 4. Fallback de sauvegarde en cas d'incompatibilité d'album spécifique au constructeur.
class GalleryPhotoService {
  static const String albumName = 'KES Inspection';

  /// Demande et vérifie l'autorisation d'accès à la galerie d'images.
  static Future<bool> requestPermission() async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (hasAccess) return true;
      return await Gal.requestAccess(toAlbum: true);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [Galerie] Erreur lors de la demande de permission : $e');
      }
      return false;
    }
  }

  /// Sauvegarde une copie de la photo originale prise par la caméra dans la galerie du téléphone.
  ///
  /// [photoFile] : Fichier temporaire issu de la prise de vue originale (ImagePicker / Camera).
  ///
  /// Cette méthode isole toutes les exceptions pour garantir l'absence d'impact sur la mission métier.
  static Future<bool> saveToGallery(File? photoFile) async {
    if (photoFile == null || !await photoFile.exists()) {
      if (kDebugMode) {
        print('⚠️ [Galerie] Fichier photo nul ou inexistant sur le disque.');
      }
      return false;
    }

    try {
      // 1. Demande / Vérification de permission explicite
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('⚠️ [Galerie] Permission d\'accès à la galerie refusée par l\'utilisateur.');
        }
        return false;
      }

      // 2. Tentative de sauvegarde dans l'album dédié "KES Inspection"
      try {
        await Gal.putImage(
          photoFile.path,
          album: albumName,
        );
        if (kDebugMode) {
          print('📸 [Galerie] Photo originale sauvegardée avec succès dans l\'album "$albumName" : ${photoFile.path}');
        }
        return true;
      } catch (albumError) {
        if (kDebugMode) {
          print('⚠️ [Galerie] Échec création d\'album dédié ($albumError), tentative de sauvegarde directe dans la Galerie principale...');
        }
        // Fallback ultime : sauvegarde directe dans la galerie principale sans nom d'album
        await Gal.putImage(photoFile.path);
        if (kDebugMode) {
          print('📸 [Galerie] Photo originale sauvegardée dans la Galerie principale (fallback ok) : ${photoFile.path}');
        }
        return true;
      }
    } on GalException catch (e) {
      if (kDebugMode) {
        print('⚠️ [Galerie] Exception Gal lors de la sauvegarde : ${e.type.message}');
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
