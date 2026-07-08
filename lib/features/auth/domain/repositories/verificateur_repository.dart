// lib/features/auth/domain/repositories/verificateur_repository.dart
import '../entities/verificateur_entity.dart';

abstract class VerificateurRepository {
  bool isUserLoggedIn();
  VerificateurEntity? getCurrentUser();
  Future<void> saveCurrentUser(VerificateurEntity user);
}
