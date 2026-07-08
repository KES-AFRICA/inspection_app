// lib/core/di/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/backup_service.dart';
import 'package:inspec_app/features/auth/domain/repositories/verificateur_repository.dart';
import 'package:inspec_app/features/auth/data/repositories/verificateur_repository_impl.dart';
import 'package:inspec_app/features/mission/domain/repositories/mission_repository.dart';
import 'package:inspec_app/features/mission/data/repositories/mission_repository_impl.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Enregistrement des services d'infrastructure
  sl.registerLazySingleton<HiveService>(() => HiveService());
  sl.registerLazySingleton<BackupService>(() => BackupService());

  // Repositories
  sl.registerLazySingleton<VerificateurRepository>(() => VerificateurRepositoryImpl());
  sl.registerLazySingleton<MissionRepository>(() => MissionRepositoryImpl());
}
