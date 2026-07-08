// lib/features/foudre/domain/usecases/delete_foudre_observation_use_case.dart
import '../repositories/foudre_repository.dart';

class DeleteFoudreObservationUseCase {
  final FoudreRepository repository;

  DeleteFoudreObservationUseCase({required this.repository});

  Future<bool> call(dynamic foudreId) async {
    return await repository.deleteFoudreObservation(foudreId);
  }
}
