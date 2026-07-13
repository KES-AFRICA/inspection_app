import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressHelper {
  /// Compresse un fichier image vers un chemin cible
  static Future<File> compressImage(File file, String targetPath) async {
    try {
      if (!await file.exists()) return file;

      // flutter_image_compress requiert un format cible valide (ici JPEG)
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        keepExif: true,
      );

      if (result != null) {
        if (kDebugMode) {
          final oldSize = await file.length();
          final newSize = await File(result.path).length();
          final pct = ((oldSize - newSize) / oldSize * 100).toStringAsFixed(1);
          print('⚡ Image compressée : $targetPath ($pct% gagné, ${newSize ~/ 1024} Ko)');
        }
        return File(result.path);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur compression image: $e');
    }
    // Fallback en cas d'erreur ou si la lib échoue : copie brute
    return file.copy(targetPath);
  }

  /// Optimise de façon progressive les photos existantes au démarrage
  static Future<void> optimizeExistingPhotosProgressively() async {
    // Exécuter en arrière-plan sans bloquer l'UI
    Future.delayed(const Duration(seconds: 10), () async {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final photosDir = Directory('${appDir.path}/audit_photos');
        if (!await photosDir.exists()) return;

        final List<File> filesToOptimize = [];
        await for (final entity in photosDir.list(recursive: true)) {
          if (entity is File) {
            final path = entity.path.toLowerCase();
            if (path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png')) {
              final size = await entity.length();
              // Si la photo fait plus de 250 Ko, elle a besoin d'être optimisée
              if (size > 250 * 1024) {
                filesToOptimize.add(entity);
              }
            }
          }
        }

        if (filesToOptimize.isEmpty) return;
        if (kDebugMode) {
          print('🔄 Optimisation progressive de ${filesToOptimize.length} photos existantes détectée...');
        }

        // Traiter les photos une par une avec un délai de repos pour ne pas surcharger le processeur
        for (final file in filesToOptimize) {
          await Future.delayed(const Duration(milliseconds: 1500));
          if (!await file.exists()) continue;

          final originalPath = file.path;
          final tempPath = '$originalPath.tmp';

          try {
            final oldSize = await file.length();
            final resultFile = await FlutterImageCompress.compressAndGetFile(
              file.absolute.path,
              tempPath,
              quality: 80,
              keepExif: true,
            );

            if (resultFile != null) {
              final newSize = await File(resultFile.path).length();
              // On ne remplace que si la taille a effectivement diminué
              if (newSize < oldSize) {
                // Remplacement atomique
                await file.delete();
                await File(resultFile.path).rename(originalPath);
                if (kDebugMode) {
                  final pct = ((oldSize - newSize) / oldSize * 100).toStringAsFixed(1);
                  print('✅ Photo existante optimisée : $originalPath (-$pct%)');
                }
              } else {
                // Supprimer le fichier temporaire inutile
                await File(resultFile.path).delete();
              }
            }
          } catch (e) {
            if (kDebugMode) print('⚠️ Échec d\'optimisation sur $originalPath : $e');
            // S'assurer de nettoyer le fichier temporaire en cas de plantage
            final tempFile = File(tempPath);
            if (await tempFile.exists()) await tempFile.delete();
          }
        }
      } catch (e) {
        if (kDebugMode) print('❌ optimizeExistingPhotosProgressively: $e');
      }
    });
  }
}
