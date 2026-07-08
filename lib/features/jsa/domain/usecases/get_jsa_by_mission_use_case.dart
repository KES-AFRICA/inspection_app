// lib/features/jsa/domain/usecases/get_jsa_by_mission_use_case.dart
import '../entities/jsa_entity.dart';
import '../repositories/jsa_repository.dart';

class GetJsaByMissionUseCase {
  final JsaRepository repository;

  GetJsaByMissionUseCase({required this.repository});

  Future<JsaEntity> call(String missionId) {
    return repository.getOrCreateJSA(missionId);
  }
}
