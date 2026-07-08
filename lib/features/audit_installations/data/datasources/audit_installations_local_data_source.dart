// lib/features/audit_installations/data/datasources/audit_installations_local_data_source.dart
import 'package:hive/hive.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

abstract class AuditInstallationsLocalDataSource {
  Future<AuditInstallationsElectriques> getOrCreateAuditInstallations(String missionId);
  Future<bool> saveAuditInstallations(AuditInstallationsElectriques audit);
}

class AuditInstallationsLocalDataSourceImpl implements AuditInstallationsLocalDataSource {
  static const String _boxName = 'audit_installations_electriques';

  Box<AuditInstallationsElectriques> get _box => Hive.box<AuditInstallationsElectriques>(_boxName);

  @override
  Future<AuditInstallationsElectriques> getOrCreateAuditInstallations(String missionId) async {
    final box = _box;
    final existingIndex = box.values.toList().indexWhere((element) => element.missionId == missionId);
    
    if (existingIndex != -1) {
      final audit = box.getAt(existingIndex);
      if (audit != null) {
        return audit;
      }
    }
    
    final newAudit = AuditInstallationsElectriques.create(missionId);
    await box.add(newAudit);
    return newAudit;
  }

  @override
  Future<bool> saveAuditInstallations(AuditInstallationsElectriques audit) async {
    try {
      final box = _box;
      if (audit.isInBox) {
        await audit.save();
        return true;
      } else {
        final existingIndex = box.values.toList().indexWhere((element) => element.missionId == audit.missionId);
        if (existingIndex != -1) {
          await box.putAt(existingIndex, audit);
        } else {
          await box.add(audit);
        }
        return true;
      }
    } catch (_) {
      return false;
    }
  }
}
