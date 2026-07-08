// lib/features/mission/data/repositories/mission_repository_impl.dart
import 'package:inspec_app/services/hive_service.dart';
import '../../domain/entities/mission_entity.dart';
import '../../domain/repositories/mission_repository.dart';
import '../mappers/mission_mapper.dart';

class MissionRepositoryImpl implements MissionRepository {
  @override
  List<MissionEntity> getMissionsByMatricule(String matricule) {
    final models = HiveService.getMissionsByMatricule(matricule);
    return models.map(MissionMapper.toEntity).toList();
  }
}
