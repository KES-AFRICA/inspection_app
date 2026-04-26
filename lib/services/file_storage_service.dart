// lib/services/file_storage_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:external_path/external_path.dart';

class FileStorageService {
  static const String reportFolderName = 'Verif Elec';
  
  /// Récupérer le dossier de destination des rapports
  static Future<Directory> getReportsDirectory() async {
    Directory targetDir;
    
    try {
      // Pour Android, utiliser ExternalPath
      if (Platform.isAndroid) {
        final downloadsPath = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOAD
        );
        targetDir = Directory('$downloadsPath/$reportFolderName');
      } 
      // Pour iOS ou fallback
      else {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          targetDir = Directory('${downloadsDir.path}/$reportFolderName');
        } else {
          final documentsDir = await getApplicationDocumentsDirectory();
          targetDir = Directory('${documentsDir.path}/$reportFolderName');
        }
      }
    } catch (e) {
      // Fallback ultime
      final appDir = await getApplicationDocumentsDirectory();
      targetDir = Directory('${appDir.path}/$reportFolderName');
    }
    
    // Créer le dossier s'il n'existe pas
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
      if (kDebugMode) {
        print('✅ Dossier créé: ${targetDir.path}');
      }
    }
    
    return targetDir;
  }
  
  /// Sauvegarder un rapport dans le dossier dédié
  static Future<File> saveReport(File sourceFile, String fileName) async {
    final reportsDir = await getReportsDirectory();
    final destinationFile = File('${reportsDir.path}/$fileName');
    
    // Copier le fichier (écrase s'il existe déjà)
    await sourceFile.copy(destinationFile.path);
    if (kDebugMode) {
      if (kDebugMode) {
        print('✅ Rapport sauvegardé: ${destinationFile.path}');
      }
    }
    
    return destinationFile;
  }
  
  /// Récupérer tous les rapports d'une mission
  static Future<List<File>> getReportsForMission(String missionId) async {
    final reportsDir = await getReportsDirectory();
    if (!await reportsDir.exists()) return [];
    
    final files = await reportsDir.list().toList();
    
    return files
        .whereType<File>()
        .where((file) => file.path.contains(missionId))
        .toList();
  }
}