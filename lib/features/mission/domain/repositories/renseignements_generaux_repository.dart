// lib/features/mission/domain/repositories/renseignements_generaux_repository.dart
import '../entities/renseignements_generaux_entity.dart';

abstract class RenseignementsGenerauxRepository {
  Future<RenseignementsGenerauxEntity> getOrCreateRenseignementsGeneraux(String missionId);
  Future<void> saveRenseignementsGeneraux(RenseignementsGenerauxEntity data);
}
