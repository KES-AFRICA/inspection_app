// lib/features/foudre/data/repositories/foudre_repository_impl.dart
import '../../domain/entities/foudre_entity.dart';
import '../../domain/repositories/foudre_repository.dart';
import '../datasources/foudre_local_data_source.dart';
import '../mappers/foudre_mapper.dart';

class FoudreRepositoryImpl implements FoudreRepository {
  final FoudreLocalDataSource localDataSource;

  FoudreRepositoryImpl({required this.localDataSource});

  @override
  Future<List<FoudreEntity>> getFoudreObservationsByMissionId(String missionId) async {
    final list = await localDataSource.getFoudreObservationsByMissionId(missionId);
    return list.map(FoudreMapper.toEntity).toList();
  }

  @override
  Future<FoudreEntity> createFoudreObservation({
    required String missionId,
    required String observation,
    required int niveauPriorite,
  }) async {
    final model = await localDataSource.createFoudreObservation(
      missionId: missionId,
      observation: observation,
      niveauPriorite: niveauPriorite,
    );
    return FoudreMapper.toEntity(model);
  }

  @override
  Future<bool> updateFoudreObservation({
    required dynamic foudreId,
    required String observation,
    required int niveauPriorite,
  }) async {
    return await localDataSource.updateFoudreObservation(
      foudreId: foudreId,
      observation: observation,
      niveauPriorite: niveauPriorite,
    );
  }

  @override
  Future<bool> deleteFoudreObservation(dynamic foudreId) async {
    return await localDataSource.deleteFoudreObservation(foudreId);
  }
}
