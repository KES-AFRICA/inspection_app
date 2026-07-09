// lib/features/description_installations/presentation/providers/description_installations_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inspec_app/core/providers/description_installations_providers.dart';
import 'package:inspec_app/features/description_installations/data/mappers/description_installations_mapper.dart';
import 'package:inspec_app/models/description_installations.dart';

final descriptionInstallationsProvider = StateNotifierProvider.family
    .autoDispose<
      DescriptionInstallationsNotifier,
      AsyncValue<DescriptionInstallations>,
      String
    >((ref, missionId) {
      return DescriptionInstallationsNotifier(ref: ref, missionId: missionId);
    });

class DescriptionInstallationsNotifier
    extends StateNotifier<AsyncValue<DescriptionInstallations>> {
  final Ref ref;
  final String missionId;

  DescriptionInstallationsNotifier({required this.ref, required this.missionId})
    : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final getUseCase = ref.read(getDescriptionInstallationsUseCaseProvider);
      final entity = await getUseCase(missionId);
      final model = DescriptionInstallationsMapper.toModel(entity);
      state = AsyncValue.data(model);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> addInstallationItem(
    String sectionKey,
    InstallationItem item,
  ) async {
    final current = state.value;
    if (current == null) return false;

    try {
      final addUseCase = ref.read(addInstallationItemUseCaseProvider);
      final itemEntity = DescriptionInstallationsMapper.toItemEntity(item);
      final success = await addUseCase(
        missionId: missionId,
        section: sectionKey,
        item: itemEntity,
      );

      if (success) {
        await load();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateInstallationItem(
    String sectionKey,
    int index,
    InstallationItem item,
  ) async {
    final current = state.value;
    if (current == null) return false;

    try {
      final updateUseCase = ref.read(updateInstallationItemUseCaseProvider);
      final itemEntity = DescriptionInstallationsMapper.toItemEntity(item);
      final success = await updateUseCase(
        missionId: missionId,
        section: sectionKey,
        index: index,
        item: itemEntity,
      );

      if (success) {
        await load();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeInstallationItem(String sectionKey, int index) async {
    final current = state.value;
    if (current == null) return false;

    try {
      final removeUseCase = ref.read(removeInstallationItemUseCaseProvider);
      final success = await removeUseCase(
        missionId: missionId,
        section: sectionKey,
        index: index,
      );

      if (success) {
        await load();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateDescriptionSelection(String field, String value) async {
    final current = state.value;
    if (current == null) return false;

    try {
      final updateSelectionUseCase = ref.read(
        updateDescriptionSelectionUseCaseProvider,
      );
      final success = await updateSelectionUseCase(
        missionId: missionId,
        field: field,
        value: value,
      );

      if (success) {
        await load();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}
