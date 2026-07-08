// lib/features/mission/domain/usecases/get_missions_use_case.dart
import '../entities/mission_entity.dart';
import '../repositories/mission_repository.dart';

class GetMissionsUseCase {
  final MissionRepository repository;

  GetMissionsUseCase({required this.repository});

  List<MissionEntity> call(String matricule) {
    return repository.getMissionsByMatricule(matricule);
  }
}
