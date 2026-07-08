// lib/features/mission/domain/repositories/mission_repository.dart
import '../entities/mission_entity.dart';

abstract class MissionRepository {
  List<MissionEntity> getMissionsByMatricule(String matricule);
  MissionEntity? getMissionById(String id);
  Future<bool> updateDocumentStatus({
    required String missionId,
    required String documentField,
    required bool value,
  });
  Future<bool> addDocumentPersonnalise({
    required String missionId,
    required String documentName,
  });
  Future<bool> removeDocumentPersonnalise({
    required String missionId,
    required String documentName,
  });
}
