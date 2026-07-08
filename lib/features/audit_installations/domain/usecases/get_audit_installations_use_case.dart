// lib/features/audit_installations/domain/usecases/get_audit_installations_use_case.dart
import '../entities/audit_installations_entities.dart';
import '../repositories/audit_installations_repository.dart';

class GetAuditInstallationsUseCase {
  final AuditInstallationsRepository repository;

  GetAuditInstallationsUseCase({required this.repository});

  Future<AuditInstallationsElectriquesEntity> call(String missionId) async {
    return await repository.getOrCreateAuditInstallations(missionId);
  }
}
