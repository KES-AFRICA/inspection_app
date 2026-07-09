// lib/core/providers/audit_installations_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:inspec_app/features/audit_installations/domain/usecases/get_audit_installations_use_case.dart';
import 'package:inspec_app/features/audit_installations/domain/usecases/save_audit_installations_use_case.dart';

final getAuditInstallationsUseCaseProvider = Provider<GetAuditInstallationsUseCase>((ref) {
  return GetIt.instance<GetAuditInstallationsUseCase>();
});

final saveAuditInstallationsUseCaseProvider = Provider<SaveAuditInstallationsUseCase>((ref) {
  return GetIt.instance<SaveAuditInstallationsUseCase>();
});
