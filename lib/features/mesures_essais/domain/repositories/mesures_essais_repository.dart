// lib/features/mesures_essais/domain/repositories/mesures_essais_repository.dart
import '../entities/mesures_essais_entities.dart';

abstract class MesuresEssaisRepository {
  Future<MesuresEssaisEntity> getOrCreateMesuresEssais(String missionId);
  Future<void> saveMesuresEssais(MesuresEssaisEntity mesures);
}
