// lib/features/foudre/domain/usecases/update_foudre_observation_use_case.dart
import '../repositories/foudre_repository.dart';

class UpdateFoudreObservationUseCase {
  final FoudreRepository repository;

  UpdateFoudreObservationUseCase({required this.repository});

  Future<bool> call({
    required dynamic foudreId,
    required String observation,
    required int niveauPriorite,
  }) async {
    return await repository.updateFoudreObservation(
      foudreId: foudreId,
      observation: observation,
      niveauPriorite: niveauPriorite,
    );
  }
}
