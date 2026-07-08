// lib/features/foudre/domain/usecases/create_foudre_observation_use_case.dart
import '../entities/foudre_entity.dart';
import '../repositories/foudre_repository.dart';

class CreateFoudreObservationUseCase {
  final FoudreRepository repository;

  CreateFoudreObservationUseCase({required this.repository});

  Future<FoudreEntity> call({
    required String missionId,
    required String observation,
    required int niveauPriorite,
  }) async {
    return await repository.createFoudreObservation(
      missionId: missionId,
      observation: observation,
      niveauPriorite: niveauPriorite,
    );
  }
}
