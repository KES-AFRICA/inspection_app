// test/features/repositories_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/core/di/injection_container.dart' as di;
import 'package:inspec_app/features/auth/domain/repositories/verificateur_repository.dart';
import 'package:inspec_app/features/mission/domain/repositories/mission_repository.dart';

void main() {
  test('Should resolve repositories from get_it after di initialization', () async {
    // Initialiser les dépendances (simulé)
    await di.init();

    expect(di.sl.isRegistered<VerificateurRepository>(), true);
    expect(di.sl.isRegistered<MissionRepository>(), true);
  });
}
