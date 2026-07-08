// lib/features/audit_installations/domain/repositories/audit_installations_repository.dart
import '../entities/audit_installations_entities.dart';

abstract class AuditInstallationsRepository {
  Future<AuditInstallationsElectriquesEntity> getOrCreateAuditInstallations(String missionId);
  Future<bool> saveAuditInstallations(AuditInstallationsElectriquesEntity audit);
}
