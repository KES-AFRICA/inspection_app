// lib/features/auth/domain/usecases/get_current_user_use_case.dart
import '../entities/verificateur_entity.dart';
import '../repositories/verificateur_repository.dart';

class GetCurrentUserUseCase {
  final VerificateurRepository repository;

  GetCurrentUserUseCase({required this.repository});

  VerificateurEntity? call() {
    return repository.getCurrentUser();
  }
}
