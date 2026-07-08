// lib/features/foudre/domain/usecases/get_foudre_observations_use_case.dart
import '../entities/foudre_entity.dart';
import '../repositories/foudre_repository.dart';

class GetFoudreObservationsUseCase {
  final FoudreRepository repository;

  GetFoudreObservationsUseCase({required this.repository});

  Future<List<FoudreEntity>> call(String missionId) async {
    return await repository.getFoudreObservationsByMissionId(missionId);
  }
}
