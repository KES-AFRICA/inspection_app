// lib/core/di/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/backup_service.dart';
// Auth
import 'package:inspec_app/features/auth/domain/repositories/verificateur_repository.dart';
import 'package:inspec_app/features/auth/data/repositories/verificateur_repository_impl.dart';
import 'package:inspec_app/features/auth/data/datasources/auth_local_data_source.dart';
// Mission
import 'package:inspec_app/features/mission/domain/repositories/mission_repository.dart';
import 'package:inspec_app/features/mission/data/repositories/mission_repository_impl.dart';
import 'package:inspec_app/features/mission/data/datasources/mission_local_data_source.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Enregistrement des services d'infrastructure
  sl.registerLazySingleton<HiveService>(() => HiveService());
  sl.registerLazySingleton<BackupService>(() => BackupService());

  // DataSources
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl());
  sl.registerLazySingleton<MissionLocalDataSource>(() => MissionLocalDataSourceImpl());

  // Repositories (avec injection de DataSource)
  sl.registerLazySingleton<VerificateurRepository>(
    () => VerificateurRepositoryImpl(authLocalDataSource: sl()),
  );
  sl.registerLazySingleton<MissionRepository>(
    () => MissionRepositoryImpl(missionLocalDataSource: sl()),
  );
}
