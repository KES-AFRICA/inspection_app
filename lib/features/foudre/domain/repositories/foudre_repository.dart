// lib/features/foudre/domain/repositories/foudre_repository.dart
import '../entities/foudre_entity.dart';

abstract class FoudreRepository {
  Future<List<FoudreEntity>> getFoudreObservationsByMissionId(String missionId);
  Future<FoudreEntity> createFoudreObservation({
    required String missionId,
    required String observation,
    required int niveauPriorite,
  });
  Future<bool> updateFoudreObservation({
    required dynamic foudreId,
    required String observation,
    required int niveauPriorite,
  });
  Future<bool> deleteFoudreObservation(dynamic foudreId);
}
