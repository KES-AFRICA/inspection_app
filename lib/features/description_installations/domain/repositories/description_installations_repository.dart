// lib/features/description_installations/domain/repositories/description_installations_repository.dart
import '../entities/description_installations_entity.dart';
import '../entities/installation_item_entity.dart';

abstract class DescriptionInstallationsRepository {
  Future<DescriptionInstallationsEntity> getOrCreateDescriptionInstallations(String missionId);
  Future<void> saveDescriptionInstallations(DescriptionInstallationsEntity desc);
  Future<bool> addInstallationItemToSection({
    required String missionId,
    required String section,
    required InstallationItemEntity item,
  });
  Future<bool> updateInstallationItemInSection({
    required String missionId,
    required String section,
    required int index,
    required InstallationItemEntity item,
  });
  Future<bool> removeInstallationItemFromSection({
    required String missionId,
    required String section,
    required int index,
  });
  Future<bool> updateSelection({
    required String missionId,
    required String field,
    required String value,
  });
}
