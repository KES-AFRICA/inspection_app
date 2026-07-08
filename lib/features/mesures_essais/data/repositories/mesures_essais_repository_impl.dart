// lib/features/mesures_essais/data/repositories/mesures_essais_repository_impl.dart
import '../../domain/entities/mesures_essais_entities.dart';
import '../../domain/repositories/mesures_essais_repository.dart';
import '../datasources/mesures_essais_local_data_source.dart';
import '../mappers/mesures_essais_mapper.dart';

class MesuresEssaisRepositoryImpl implements MesuresEssaisRepository {
  final MesuresEssaisLocalDataSource localDataSource;

  MesuresEssaisRepositoryImpl({required this.localDataSource});

  @override
  Future<MesuresEssaisEntity> getOrCreateMesuresEssais(String missionId) async {
    final model = await localDataSource.getOrCreateMesuresEssais(missionId);
    return MesuresEssaisMapper.toEntity(model);
  }

  @override
  Future<void> saveMesuresEssais(MesuresEssaisEntity mesures) async {
    final model = MesuresEssaisMapper.toModel(mesures);
    await localDataSource.saveMesuresEssais(model);
  }
}
