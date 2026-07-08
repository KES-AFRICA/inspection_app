// lib/features/mission/domain/repositories/mission_repository.dart
import '../entities/mission_entity.dart';

abstract class MissionRepository {
  List<MissionEntity> getMissionsByMatricule(String matricule);
}
