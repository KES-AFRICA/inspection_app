// lib/features/description_installations/domain/usecases/remove_installation_item_use_case.dart
import '../repositories/description_installations_repository.dart';

class RemoveInstallationItemUseCase {
  final DescriptionInstallationsRepository repository;

  RemoveInstallationItemUseCase({required this.repository});

  Future<bool> call({
    required String missionId,
    required String section,
    required int index,
  }) {
    return repository.removeInstallationItemFromSection(
      missionId: missionId,
      section: section,
      index: index,
    );
  }
}
