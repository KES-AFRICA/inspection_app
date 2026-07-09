// lib/features/mission/domain/usecases/update_schema_option_use_case.dart
import '../repositories/mission_repository.dart';

class UpdateSchemaOptionUseCase {
  final MissionRepository repository;

  UpdateSchemaOptionUseCase({required this.repository});

  Future<bool> call({required String missionId, required String option}) async {
    return await repository.updateSchemaOption(missionId: missionId, option: option);
  }
}
