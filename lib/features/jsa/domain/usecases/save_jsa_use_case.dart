// lib/features/jsa/domain/usecases/save_jsa_use_case.dart
import '../entities/jsa_entity.dart';
import '../repositories/jsa_repository.dart';

class SaveJsaUseCase {
  final JsaRepository repository;

  SaveJsaUseCase({required this.repository});

  Future<void> call(JsaEntity jsa) {
    return repository.saveJSA(jsa);
  }
}
