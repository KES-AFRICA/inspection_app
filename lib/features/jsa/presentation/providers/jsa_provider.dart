// lib/features/jsa/presentation/providers/jsa_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/core/providers/auth_providers.dart';
import 'package:inspec_app/core/providers/jsa_providers.dart';
import 'package:inspec_app/features/auth/data/mappers/verificateur_mapper.dart';
import 'package:inspec_app/features/jsa/data/mappers/jsa_mapper.dart';
import 'package:inspec_app/models/jsa.dart';

final jsaProvider = StateNotifierProvider.family.autoDispose<
    JsaNotifier,
    AsyncValue<JSA>,
    String>((ref, missionId) {
  return JsaNotifier(ref: ref, missionId: missionId);
});

class JsaNotifier extends StateNotifier<AsyncValue<JSA>> {
  final Ref ref;
  final String missionId;

  JsaNotifier({required this.ref, required this.missionId})
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final getUseCase = ref.read(getJsaByMissionUseCaseProvider);
      final entity = await getUseCase(missionId);
      final model = JsaMapper.toModel(entity);

      // ✅ Ajouter l'inspecteur courant connecté si la liste est vide
      final getCurrentUser = ref.read(getCurrentUserUseCaseProvider);
      final currentUserEntity = getCurrentUser();
      final currentUser = currentUserEntity != null
          ? VerificateurMapper.toModel(currentUserEntity)
          : null;

      if (currentUser != null) {
        if (model.inspecteurs.isEmpty) {
          model.inspecteurs = [];
        }
        final hasCurrentUser = model.inspecteurs.any((i) =>
            i.nom == currentUser.nom && i.prenom == currentUser.prenom);

        if (!hasCurrentUser) {
          model.inspecteurs.add(JSAInspecteur(
            nom: currentUser.nom,
            prenom: currentUser.prenom,
          ));
          final saveUseCase = ref.read(saveJsaUseCaseProvider);
          final saveEntity = JsaMapper.toEntity(model);
          await saveUseCase(saveEntity);
        }
      }

      state = AsyncValue.data(model);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateJsa(void Function(JSA current) update) async {
    final current = state.value;
    if (current == null) return;

    // Appliquer la modification
    update(current);
    current.updatedAt = DateTime.now();

    // Notifier le changement d'état
    state = AsyncValue.data(current);

    // Sauvegarder asynchronement dans Hive
    final saveUseCase = ref.read(saveJsaUseCaseProvider);
    final saveEntity = JsaMapper.toEntity(current);
    await saveUseCase(saveEntity);
  }
}
