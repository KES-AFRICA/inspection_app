// lib/features/foudre/presentation/providers/foudre_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/core/providers/foudre_providers.dart';
import 'package:inspec_app/features/foudre/data/mappers/foudre_mapper.dart';
import 'package:inspec_app/models/foudre.dart';

final foudreObservationsProvider = StateNotifierProvider.family
    .autoDispose<
      FoudreObservationsNotifier,
      AsyncValue<List<Foudre>>,
      String
    >((ref, missionId) {
      return FoudreObservationsNotifier(ref: ref, missionId: missionId);
    });

class FoudreObservationsNotifier extends StateNotifier<AsyncValue<List<Foudre>>> {
  final Ref ref;
  final String missionId;

  FoudreObservationsNotifier({required this.ref, required this.missionId})
    : super(const AsyncValue.loading()) {
    load();
  }

  Future<List<Foudre>> load() async {
    try {
      state = const AsyncValue.loading();
      final getUseCase = ref.read(getFoudreObservationsUseCaseProvider);
      final entities = await getUseCase(missionId);
      final models = entities.map(FoudreMapper.toModel).toList();
      state = AsyncValue.data(models);
      return models;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<bool> addObservation({
    required String observation,
    required int niveauPriorite,
  }) async {
    try {
      final createUseCase = ref.read(createFoudreObservationUseCaseProvider);
      await createUseCase(
        missionId: missionId,
        observation: observation,
        niveauPriorite: niveauPriorite,
      );
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateObservation({
    required dynamic foudreId,
    required String observation,
    required int niveauPriorite,
  }) async {
    try {
      final updateUseCase = ref.read(updateFoudreObservationUseCaseProvider);
      final success = await updateUseCase(
        foudreId: foudreId,
        observation: observation,
        niveauPriorite: niveauPriorite,
      );
      if (success) {
        await load();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeObservation(dynamic foudreId) async {
    try {
      final deleteUseCase = ref.read(deleteFoudreObservationUseCaseProvider);
      final success = await deleteUseCase(foudreId);
      if (success) {
        await load();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}
