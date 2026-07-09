// lib/features/mission/domain/usecases/get_all_reports_for_mission_use_case.dart
import 'package:inspec_app/models/last_report.dart';
import '../repositories/mission_repository.dart';

class GetAllReportsForMissionUseCase {
  final MissionRepository repository;

  GetAllReportsForMissionUseCase({required this.repository});

  Future<List<LastReport>> call(String missionId) async {
    return await repository.getAllReportsForMission(missionId);
  }
}
