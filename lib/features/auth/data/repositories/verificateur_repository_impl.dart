// lib/features/auth/data/repositories/verificateur_repository_impl.dart
import 'package:inspec_app/services/hive_service.dart';
import '../../domain/entities/verificateur_entity.dart';
import '../../domain/repositories/verificateur_repository.dart';
import '../mappers/verificateur_mapper.dart';

class VerificateurRepositoryImpl implements VerificateurRepository {
  @override
  bool isUserLoggedIn() {
    return HiveService.isUserLoggedIn();
  }

  @override
  VerificateurEntity? getCurrentUser() {
    final model = HiveService.getCurrentUser();
    if (model == null) return null;
    return VerificateurMapper.toEntity(model);
  }

  @override
  Future<void> saveCurrentUser(VerificateurEntity user) async {
    final model = VerificateurMapper.toModel(user);
    await HiveService.saveCurrentUser(model);
  }
}
