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
      ref.keepAlive();
      return MesuresEssaisNotifier(ref: ref, missionId: missionId);
    });

class MesuresEssaisNotifier extends StateNotifier<AsyncValue<MesuresEssais>> {
  final Ref ref;
  final String missionId;

  MesuresEssaisNotifier({required this.ref, required this.missionId})
    : super(const AsyncValue.loading()) {
    // Différer le chargement initial pour éviter de modifier l'état durant la construction du widget tree
    Future.microtask(() {
      if (mounted) {
        load().catchError((_) => MesuresEssais.create(missionId));
      }
    });
  }

  Future<MesuresEssais> load() async {
    try {
      final getUseCase = ref.read(getMesuresEssaisUseCaseProvider);
      final entity = await getUseCase(missionId);
      final model = MesuresEssaisMapper.toModel(entity);
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

  Future<bool> saveMesures(MesuresEssais mesures) async {
    try {
      final saveUseCase = ref.read(saveMesuresEssaisUseCaseProvider);
      final entity = MesuresEssaisMapper.toEntity(mesures);
      await saveUseCase(entity);
      if (mounted) {
        state = AsyncValue.data(mesures);
      }
      return true;
    } catch (e, stackTrace) {
      print('❌ Erreur saveMesures pour mission $missionId: $e');
      print('📋 StackTrace: $stackTrace');
      return false;
    }
  }
}
