// lib/features/mission/domain/usecases/update_mission_status_use_case.dart
import '../repositories/mission_repository.dart';

class UpdateMissionStatusUseCase {
  final MissionRepository repository;

  UpdateMissionStatusUseCase({required this.repository});

  Future<bool> call({required String missionId, required String status}) async {
    return await repository.updateMissionStatus(missionId: missionId, status: status);
  }
}
