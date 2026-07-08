// lib/features/auth/data/repositories/verificateur_repository_impl.dart
import '../../domain/entities/verificateur_entity.dart';
import '../../domain/repositories/verificateur_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../mappers/verificateur_mapper.dart';

class VerificateurRepositoryImpl implements VerificateurRepository {
  final AuthLocalDataSource authLocalDataSource;

  VerificateurRepositoryImpl({required this.authLocalDataSource});

  @override
  bool isUserLoggedIn() {
    return authLocalDataSource.isUserLoggedIn();
  }

  @override
  VerificateurEntity? getCurrentUser() {
    final model = authLocalDataSource.getCurrentUser();
    if (model == null) return null;
    return VerificateurMapper.toEntity(model);
  }

  @override
  Future<void> saveCurrentUser(VerificateurEntity user) async {
    final model = VerificateurMapper.toModel(user);
    await authLocalDataSource.saveCurrentUser(model);
  }
}
