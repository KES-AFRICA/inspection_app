// lib/features/audit_installations/data/repositories/audit_installations_repository_impl.dart
import '../../domain/entities/audit_installations_entities.dart';
import '../../domain/repositories/audit_installations_repository.dart';
import '../datasources/audit_installations_local_data_source.dart';
import '../mappers/audit_installations_mapper.dart';

class AuditInstallationsRepositoryImpl implements AuditInstallationsRepository {
  final AuditInstallationsLocalDataSource localDataSource;

  AuditInstallationsRepositoryImpl({required this.localDataSource});

  @override
  Future<AuditInstallationsElectriquesEntity> getOrCreateAuditInstallations(String missionId) async {
    final model = await localDataSource.getOrCreateAuditInstallations(missionId);
    return AuditInstallationsMapper.toEntity(model);
  }

  @override
  Future<bool> saveAuditInstallations(AuditInstallationsElectriquesEntity audit) async {
    final model = AuditInstallationsMapper.toModel(audit);
    return await localDataSource.saveAuditInstallations(model);
  }
}
