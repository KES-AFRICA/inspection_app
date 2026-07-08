// test/features/repositories_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/core/di/injection_container.dart' as di;
import 'package:inspec_app/features/auth/domain/repositories/verificateur_repository.dart';
import 'package:inspec_app/features/mission/domain/repositories/mission_repository.dart';
import 'package:inspec_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:inspec_app/features/mission/data/datasources/mission_local_data_source.dart';

void main() {
  test('Should resolve data sources and repositories from get_it after di initialization', () async {
    // Réinitialiser GetIt avant le test
    await di.sl.reset();
    await di.init();

    // DataSources
    expect(di.sl.isRegistered<AuthLocalDataSource>(), true);
    expect(di.sl.isRegistered<MissionLocalDataSource>(), true);

    // Repositories
    expect(di.sl.isRegistered<VerificateurRepository>(), true);
    expect(di.sl.isRegistered<MissionRepository>(), true);
  });
}
