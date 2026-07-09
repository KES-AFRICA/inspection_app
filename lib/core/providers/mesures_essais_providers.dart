// lib/core/providers/mesures_essais_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:inspec_app/features/mesures_essais/domain/usecases/get_mesures_essais_use_case.dart';
import 'package:inspec_app/features/mesures_essais/domain/usecases/save_mesures_essais_use_case.dart';

final getMesuresEssaisUseCaseProvider = Provider<GetMesuresEssaisUseCase>((ref) {
  return GetIt.instance<GetMesuresEssaisUseCase>();
});

final saveMesuresEssaisUseCaseProvider = Provider<SaveMesuresEssaisUseCase>((ref) {
  return GetIt.instance<SaveMesuresEssaisUseCase>();
});
