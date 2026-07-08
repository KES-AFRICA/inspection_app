// lib/features/mission/data/repositories/renseignements_generaux_repository_impl.dart
import '../../domain/entities/renseignements_generaux_entity.dart';
import '../../domain/repositories/renseignements_generaux_repository.dart';
import '../datasources/renseignements_generaux_local_data_source.dart';
import '../mappers/renseignements_generaux_mapper.dart';

class RenseignementsGenerauxRepositoryImpl implements RenseignementsGenerauxRepository {
  final RenseignementsGenerauxLocalDataSource localDataSource;

  RenseignementsGenerauxRepositoryImpl({required this.localDataSource});

  @override
  Future<RenseignementsGenerauxEntity> getOrCreateRenseignementsGeneraux(String missionId) async {
    final model = await localDataSource.getOrCreateRenseignementsGeneraux(missionId);
    return RenseignementsGenerauxMapper.toEntity(model);
  }

  @override
  Future<void> saveRenseignementsGeneraux(RenseignementsGenerauxEntity data) async {
    final model = RenseignementsGenerauxMapper.toModel(data);
    await localDataSource.saveRenseignementsGeneraux(model);
  }
}
