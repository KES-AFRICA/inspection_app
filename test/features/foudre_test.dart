// test/features/foudre_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/features/foudre/data/mappers/foudre_mapper.dart';
import 'package:inspec_app/features/foudre/domain/usecases/get_foudre_observations_use_case.dart';
import 'package:inspec_app/features/foudre/domain/usecases/create_foudre_observation_use_case.dart';
import 'package:inspec_app/features/foudre/domain/usecases/update_foudre_observation_use_case.dart';
import 'package:inspec_app/features/foudre/domain/usecases/delete_foudre_observation_use_case.dart';
import 'package:inspec_app/core/di/injection_container.dart' as di;

void main() {
  group('FoudreMapper Tests', () {
    test('Should map Model to Entity and vice versa without loss', () {
      final model = Foudre(
        missionId: 'mission_123',
        observation: 'Parafoudre hors service',
        niveauPriorite: 1,
        createdAt: DateTime(2026, 7, 8),
        updatedAt: DateTime(2026, 7, 8),
      );

      final entity = FoudreMapper.toEntity(model);
      expect(entity.missionId, model.missionId);
      expect(entity.observation, model.observation);
      expect(entity.niveauPriorite, model.niveauPriorite);
      expect(entity.createdAt, model.createdAt);
      expect(entity.updatedAt, model.updatedAt);

      final mappedModel = FoudreMapper.toModel(entity);
      expect(mappedModel.missionId, entity.missionId);
      expect(mappedModel.observation, entity.observation);
      expect(mappedModel.niveauPriorite, entity.niveauPriorite);
      expect(mappedModel.createdAt, entity.createdAt);
      expect(mappedModel.updatedAt, entity.updatedAt);
    });
  });

  group('DI Registrations', () {
    test('Should resolve Foudre UseCases from get_it after di initialization', () async {
      final getIt = GetIt.instance;
      await getIt.reset();

      await di.init();

      expect(getIt.isRegistered<GetFoudreObservationsUseCase>(), isTrue);
      expect(getIt.isRegistered<CreateFoudreObservationUseCase>(), isTrue);
      expect(getIt.isRegistered<UpdateFoudreObservationUseCase>(), isTrue);
      expect(getIt.isRegistered<DeleteFoudreObservationUseCase>(), isTrue);

      final getUseCase = getIt<GetFoudreObservationsUseCase>();
      final createUseCase = getIt<CreateFoudreObservationUseCase>();
      final updateUseCase = getIt<UpdateFoudreObservationUseCase>();
      final deleteUseCase = getIt<DeleteFoudreObservationUseCase>();

      expect(getUseCase, isNotNull);
      expect(createUseCase, isNotNull);
      expect(updateUseCase, isNotNull);
      expect(deleteUseCase, isNotNull);
    });
  });
}
