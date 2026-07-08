// lib/features/auth/domain/usecases/check_login_status_use_case.dart
import '../repositories/verificateur_repository.dart';

class CheckLoginStatusUseCase {
  final VerificateurRepository repository;

  CheckLoginStatusUseCase({required this.repository});

  bool call() {
    return repository.isUserLoggedIn();
  }
}
