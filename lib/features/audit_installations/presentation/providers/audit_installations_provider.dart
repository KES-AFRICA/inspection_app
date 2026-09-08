// lib/features/audit_installations/presentation/providers/audit_installations_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/core/providers/audit_installations_providers.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

final auditInstallationsProvider = StateNotifierProvider.family
    .autoDispose<
      AuditInstallationsNotifier,
      AsyncValue<AuditInstallationsElectriques>,
      String
    >((ref, missionId) {
      ref.keepAlive();
      return AuditInstallationsNotifier(ref: ref, missionId: missionId);
    });

class AuditInstallationsNotifier
    extends StateNotifier<AsyncValue<AuditInstallationsElectriques>> {
  final Ref ref;
  final String missionId;

  AuditInstallationsNotifier({required this.ref, required this.missionId})
    : super(const AsyncValue.loading()) {
    load().then<void>((_) {}, onError: (_, __) {});
  }

  Future<AuditInstallationsElectriques> load() async {
    try {
      if (mounted) {
        state = const AsyncValue.loading();
      }
      final getUseCase = ref.read(getAuditInstallationsUseCaseProvider);
      final entity = await getUseCase(missionId);
      final model = AuditInstallationsMapper.toModel(entity);
      if (mounted) {
        state = AsyncValue.data(model);
      }
      return model;
    } catch (e, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
      rethrow;
    }
  }

  Future<bool> saveAudit(AuditInstallationsElectriques audit) async {
    try {
      final saveUseCase = ref.read(saveAuditInstallationsUseCaseProvider);
      final entity = AuditInstallationsMapper.toEntity(audit);
      final success = await saveUseCase(entity);
      if (success && mounted) {
        state = AsyncValue.data(audit);
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}
