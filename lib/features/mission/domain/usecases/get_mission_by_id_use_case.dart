// lib/features/mission/domain/usecases/get_mission_by_id_use_case.dart
import '../entities/mission_entity.dart';
import '../repositories/mission_repository.dart';

class GetMissionByIdUseCase {
  final MissionRepository repository;

  GetMissionByIdUseCase({required this.repository});

  MissionEntity? call(String id) {
    return repository.getMissionById(id);
  }
}
