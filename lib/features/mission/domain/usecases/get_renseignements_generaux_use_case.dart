// lib/features/mission/domain/usecases/get_renseignements_generaux_use_case.dart
import '../entities/renseignements_generaux_entity.dart';
import '../repositories/renseignements_generaux_repository.dart';

class GetRenseignementsGenerauxUseCase {
  final RenseignementsGenerauxRepository repository;

  GetRenseignementsGenerauxUseCase({required this.repository});

  Future<RenseignementsGenerauxEntity> call(String missionId) {
    return repository.getOrCreateRenseignementsGeneraux(missionId);
  }
}
