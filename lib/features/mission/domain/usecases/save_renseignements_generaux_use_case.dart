// lib/features/mission/domain/usecases/save_renseignements_generaux_use_case.dart
import '../entities/renseignements_generaux_entity.dart';
import '../repositories/renseignements_generaux_repository.dart';

class SaveRenseignementsGenerauxUseCase {
  final RenseignementsGenerauxRepository repository;

  SaveRenseignementsGenerauxUseCase({required this.repository});

  Future<void> call(RenseignementsGenerauxEntity data) {
    return repository.saveRenseignementsGeneraux(data);
  }
}
