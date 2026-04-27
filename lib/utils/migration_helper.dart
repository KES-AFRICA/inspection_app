// lib/utils/migration_helper.dart
import 'package:flutter/foundation.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/secure_password_service.dart';

class MigrationHelper {
  static Future<void> migrateExistingUsers() async {
    final users = HiveService.getAllVerificateurs();
    
    for (var user in users) {
      final oldPassword = user.password;
      
      // Ne migrer que si le mot de passe n'est pas déjà sécurisé
      if (oldPassword.isNotEmpty && oldPassword.length < 60) {
        final success = await HiveService.createUserWithSecurePassword(
          email: user.email,
          password: oldPassword,
          nom: user.nom,
          prenom: user.prenom,
          matricule: user.matricule,
        );
        
        if (success) {
          if (kDebugMode) {
            print('✅ Migration réussie pour ${user.email}');
          }
          // Supprimer l'ancien mot de passe en clair
          user.password = '';
          await user.save();
        } else {
          if (kDebugMode) {
            print('❌ Migration échouée pour ${user.email}');
          }
        }
      }
    }
  }
}