// lib/features/mission/presentation/providers/renseignements_generaux_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/core/providers/auth_providers.dart';
import 'package:inspec_app/core/providers/mission_providers.dart';
import 'package:inspec_app/features/auth/data/mappers/verificateur_mapper.dart';
import 'package:inspec_app/features/mission/data/mappers/renseignements_generaux_mapper.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';

final renseignementsGenerauxProvider = StateNotifierProvider.family.autoDispose<
    RenseignementsGenerauxNotifier,
    AsyncValue<RenseignementsGeneraux>,
    String>((ref, missionId) {
  return RenseignementsGenerauxNotifier(ref: ref, missionId: missionId);
});

class RenseignementsGenerauxNotifier
    extends StateNotifier<AsyncValue<RenseignementsGeneraux>> {
  final Ref ref;
  final String missionId;

  RenseignementsGenerauxNotifier({required this.ref, required this.missionId})
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final getUseCase = ref.read(getRenseignementsGenerauxUseCaseProvider);
      final entity = await getUseCase(missionId);
      final model = RenseignementsGenerauxMapper.toModel(entity);

      // ✅ Ajouter le vérificateur courant si manquant
      final getCurrentUser = ref.read(getCurrentUserUseCaseProvider);
      final currentUserEntity = getCurrentUser();
      final currentUser = currentUserEntity != null
          ? VerificateurMapper.toModel(currentUserEntity)
          : null;

      if (currentUser != null) {
        if (model.verificateurs.isEmpty) {
          model.verificateurs = [];
        }
        final currentUserExists = model.verificateurs.any((v) =>
            v['nom'] == '${currentUser.prenom} ${currentUser.nom}' ||
            v['email'] == currentUser.email);

        if (!currentUserExists) {
          model.verificateurs.add({
            'nom': '${currentUser.prenom} ${currentUser.nom}',
            'email': currentUser.email,
          });
          final saveUseCase = ref.read(saveRenseignementsGenerauxUseCaseProvider);
          final saveEntity = RenseignementsGenerauxMapper.toEntity(model);
          await saveUseCase(saveEntity);
        }
      }

      state = AsyncValue.data(model);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateField({
    String? etablissement,
    String? installation,
    String? activite,
    String? nomSite,
    DateTime? dateDebut,
    DateTime? dateFin,
    int? dureeJours,
    String? verificationType,
    String? registreControle,
    List<String>? compteRendu,
    List<Map<String, String>>? accompagnateurs,
    List<Map<String, String>>? verificateurs,
  }) async {
    final currentData = state.value;
    if (currentData == null) return;

    if (etablissement != null) currentData.etablissement = etablissement;
    if (installation != null) currentData.installation = installation;
    if (activite != null) currentData.activite = activite;
    if (nomSite != null) currentData.nomSite = nomSite;
    if (dateDebut != null) currentData.dateDebut = dateDebut;
    if (dateFin != null) currentData.dateFin = dateFin;
    if (dureeJours != null) currentData.dureeJours = dureeJours;
    if (verificationType != null) currentData.verificationType = verificationType;
    if (registreControle != null) currentData.registreControle = registreControle;
    if (compteRendu != null) currentData.compteRendu = compteRendu;
    if (accompagnateurs != null) currentData.accompagnateurs = accompagnateurs;
    if (verificateurs != null) currentData.verificateurs = verificateurs;
    currentData.updatedAt = DateTime.now();

    // Notifier le changement d'état
    state = AsyncValue.data(currentData);

    // Sauvegarder asynchronement dans Hive
    final saveUseCase = ref.read(saveRenseignementsGenerauxUseCaseProvider);
    final entity = RenseignementsGenerauxMapper.toEntity(currentData);
    await saveUseCase(entity);
  }
}
