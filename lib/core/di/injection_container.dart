// lib/core/di/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/backup_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Enregistrement des services d'infrastructure
  sl.registerLazySingleton<HiveService>(() => HiveService());
  sl.registerLazySingleton<BackupService>(() => BackupService());
}
