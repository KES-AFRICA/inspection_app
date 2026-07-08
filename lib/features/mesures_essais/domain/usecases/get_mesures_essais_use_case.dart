// lib/features/mesures_essais/domain/usecases/get_mesures_essais_use_case.dart
import '../entities/mesures_essais_entities.dart';
import '../repositories/mesures_essais_repository.dart';

class GetMesuresEssaisUseCase {
  final MesuresEssaisRepository repository;

  GetMesuresEssaisUseCase({required this.repository});

  Future<MesuresEssaisEntity> call(String missionId) async {
    return await repository.getOrCreateMesuresEssais(missionId);
  }
}
