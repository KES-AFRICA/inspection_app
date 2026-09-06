// lib/features/audit_installations/data/datasources/audit_installations_local_data_source.dart
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/hive_service.dart';

abstract class AuditInstallationsLocalDataSource {
  Future<AuditInstallationsElectriques> getOrCreateAuditInstallations(String missionId);
  Future<bool> saveAuditInstallations(AuditInstallationsElectriques audit);
}

class AuditInstallationsLocalDataSourceImpl implements AuditInstallationsLocalDataSource {
  @override
  Future<AuditInstallationsElectriques> getOrCreateAuditInstallations(String missionId) async {
    return await HiveService.getOrCreateAuditInstallations(missionId);
  }

  @override
  Future<bool> saveAuditInstallations(AuditInstallationsElectriques audit) async {
    try {
      await HiveService.saveAuditInstallations(audit);
      return true;
    } catch (_) {
      return false;
    }
  }
}
