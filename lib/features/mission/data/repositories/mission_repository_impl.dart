// lib/features/mission/data/repositories/mission_repository_impl.dart
import '../../domain/entities/mission_entity.dart';
import '../../domain/repositories/mission_repository.dart';
import '../datasources/mission_local_data_source.dart';
import '../mappers/mission_mapper.dart';

class MissionRepositoryImpl implements MissionRepository {
  final MissionLocalDataSource missionLocalDataSource;

  MissionRepositoryImpl({required this.missionLocalDataSource});

  @override
  List<MissionEntity> getMissionsByMatricule(String matricule) {
    final models = missionLocalDataSource.getMissionsByMatricule(matricule);
    return models.map(MissionMapper.toEntity).toList();
  }
}
