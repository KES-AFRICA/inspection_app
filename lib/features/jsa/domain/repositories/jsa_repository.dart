// lib/features/jsa/domain/repositories/jsa_repository.dart
import '../entities/jsa_entity.dart';

abstract class JsaRepository {
  Future<JsaEntity> getOrCreateJSA(String missionId);
  Future<void> saveJSA(JsaEntity jsa);
}
