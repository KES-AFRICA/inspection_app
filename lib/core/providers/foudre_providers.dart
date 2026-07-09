// lib/core/providers/foudre_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:inspec_app/features/foudre/domain/usecases/create_foudre_observation_use_case.dart';
import 'package:inspec_app/features/foudre/domain/usecases/delete_foudre_observation_use_case.dart';
import 'package:inspec_app/features/foudre/domain/usecases/get_foudre_observations_use_case.dart';
import 'package:inspec_app/features/foudre/domain/usecases/update_foudre_observation_use_case.dart';

final getFoudreObservationsUseCaseProvider = Provider<GetFoudreObservationsUseCase>((ref) {
  return GetIt.instance<GetFoudreObservationsUseCase>();
});

final createFoudreObservationUseCaseProvider = Provider<CreateFoudreObservationUseCase>((ref) {
  return GetIt.instance<CreateFoudreObservationUseCase>();
});

final updateFoudreObservationUseCaseProvider = Provider<UpdateFoudreObservationUseCase>((ref) {
  return GetIt.instance<UpdateFoudreObservationUseCase>();
});

final deleteFoudreObservationUseCaseProvider = Provider<DeleteFoudreObservationUseCase>((ref) {
  return GetIt.instance<DeleteFoudreObservationUseCase>();
});
