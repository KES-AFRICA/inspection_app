// lib/features/description_installations/domain/usecases/update_installation_item_use_case.dart
import '../entities/installation_item_entity.dart';
import '../repositories/description_installations_repository.dart';

class UpdateInstallationItemUseCase {
  final DescriptionInstallationsRepository repository;

  UpdateInstallationItemUseCase({required this.repository});

  Future<bool> call({
    required String missionId,
    required String section,
    required int index,
    required InstallationItemEntity item,
  }) {
    return repository.updateInstallationItemInSection(
      missionId: missionId,
      section: section,
      index: index,
      item: item,
    );
  }
}
