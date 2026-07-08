// lib/features/jsa/data/repositories/jsa_repository_impl.dart
import '../../domain/entities/jsa_entity.dart';
import '../../domain/repositories/jsa_repository.dart';
import '../datasources/jsa_local_data_source.dart';
import '../mappers/jsa_mapper.dart';

class JsaRepositoryImpl implements JsaRepository {
  final JsaLocalDataSource jsaLocalDataSource;

  JsaRepositoryImpl({required this.jsaLocalDataSource});

  @override
  Future<JsaEntity> getOrCreateJSA(String missionId) async {
    final model = await jsaLocalDataSource.getOrCreateJSA(missionId);
    return JsaMapper.toEntity(model);
  }

  @override
  Future<void> saveJSA(JsaEntity jsa) async {
    final model = JsaMapper.toModel(jsa);
    await jsaLocalDataSource.saveJSA(model);
  }
}
