// lib/features/description_installations/domain/usecases/add_installation_item_use_case.dart
import '../entities/installation_item_entity.dart';
import '../repositories/description_installations_repository.dart';

class AddInstallationItemUseCase {
  final DescriptionInstallationsRepository repository;

  AddInstallationItemUseCase({required this.repository});

  Future<bool> call({
    required String missionId,
    required String section,
    required InstallationItemEntity item,
  }) {
    return repository.addInstallationItemToSection(
      missionId: missionId,
      section: section,
      item: item,
    );
  }
}
