// lib/features/audit_installations/domain/usecases/save_audit_installations_use_case.dart
import '../entities/audit_installations_entities.dart';
import '../repositories/audit_installations_repository.dart';

class SaveAuditInstallationsUseCase {
  final AuditInstallationsRepository repository;

  SaveAuditInstallationsUseCase({required this.repository});

  Future<bool> call(AuditInstallationsElectriquesEntity audit) async {
    return await repository.saveAuditInstallations(audit);
  }
}
