// lib/core/providers/auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:inspec_app/features/auth/domain/usecases/check_login_status_use_case.dart';
import 'package:inspec_app/features/auth/domain/usecases/get_current_user_use_case.dart';

final checkLoginStatusUseCaseProvider = Provider<CheckLoginStatusUseCase>((ref) {
  return GetIt.instance<CheckLoginStatusUseCase>();
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetIt.instance<GetCurrentUserUseCase>();
});
