// lib/core/providers/jsa_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:inspec_app/features/jsa/domain/usecases/get_jsa_by_mission_use_case.dart';
import 'package:inspec_app/features/jsa/domain/usecases/save_jsa_use_case.dart';

final getJsaByMissionUseCaseProvider = Provider<GetJsaByMissionUseCase>((ref) {
  return GetIt.instance<GetJsaByMissionUseCase>();
});

final saveJsaUseCaseProvider = Provider<SaveJsaUseCase>((ref) {
  return GetIt.instance<SaveJsaUseCase>();
});
