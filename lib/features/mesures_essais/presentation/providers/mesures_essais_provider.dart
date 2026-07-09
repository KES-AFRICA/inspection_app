// lib/features/mesures_essais/presentation/providers/mesures_essais_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/core/providers/mesures_essais_providers.dart';
import 'package:inspec_app/features/mesures_essais/data/mappers/mesures_essais_mapper.dart';
import 'package:inspec_app/models/mesures_essais.dart';

final mesuresEssaisProvider = StateNotifierProvider.family
    .autoDispose<
      MesuresEssaisNotifier,
      AsyncValue<MesuresEssais>,
      String
    >((ref, missionId) {
      return MesuresEssaisNotifier(ref: ref, missionId: missionId);
    });

class MesuresEssaisNotifier extends StateNotifier<AsyncValue<MesuresEssais>> {
  final Ref ref;
  final String missionId;

  MesuresEssaisNotifier({required this.ref, required this.missionId})
    : super(const AsyncValue.loading()) {
    load();
  }

  Future<MesuresEssais> load() async {
    try {
      state = const AsyncValue.loading();
      final getUseCase = ref.read(getMesuresEssaisUseCaseProvider);
      final entity = await getUseCase(missionId);
      final model = MesuresEssaisMapper.toModel(entity);
      state = AsyncValue.data(model);
      return model;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<bool> saveMesures(MesuresEssais mesures) async {
    try {
      final saveUseCase = ref.read(saveMesuresEssaisUseCaseProvider);
      final entity = MesuresEssaisMapper.toEntity(mesures);
      await saveUseCase(entity);
      state = AsyncValue.data(mesures);
      return true;
    } catch (e) {
      return false;
    }
  }
}
