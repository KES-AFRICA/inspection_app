// lib/features/mesures_essais/domain/usecases/save_mesures_essais_use_case.dart
import '../entities/mesures_essais_entities.dart';
import '../repositories/mesures_essais_repository.dart';

class SaveMesuresEssaisUseCase {
  final MesuresEssaisRepository repository;

  SaveMesuresEssaisUseCase({required this.repository});

  Future<void> call(MesuresEssaisEntity mesures) async {
    await repository.saveMesuresEssais(mesures);
  }
}
