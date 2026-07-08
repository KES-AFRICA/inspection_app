// lib/features/description_installations/data/repositories/description_installations_repository_impl.dart
import '../../domain/entities/description_installations_entity.dart';
import '../../domain/entities/installation_item_entity.dart';
import '../../domain/repositories/description_installations_repository.dart';
import '../datasources/description_installations_local_data_source.dart';
import '../mappers/description_installations_mapper.dart';

class DescriptionInstallationsRepositoryImpl implements DescriptionInstallationsRepository {
  final DescriptionInstallationsLocalDataSource localDataSource;

  DescriptionInstallationsRepositoryImpl({required this.localDataSource});

  @override
  Future<DescriptionInstallationsEntity> getOrCreateDescriptionInstallations(String missionId) async {
    final model = await localDataSource.getOrCreateDescriptionInstallations(missionId);
    return DescriptionInstallationsMapper.toEntity(model);
  }

  @override
  Future<void> saveDescriptionInstallations(DescriptionInstallationsEntity desc) async {
    final model = DescriptionInstallationsMapper.toModel(desc);
    await localDataSource.saveDescriptionInstallations(model);
  }

  @override
  Future<bool> addInstallationItemToSection({
    required String missionId,
    required String section,
    required InstallationItemEntity item,
  }) {
    final modelItem = DescriptionInstallationsMapper.toItemModel(item);
    return localDataSource.addInstallationItemToSection(
      missionId: missionId,
      section: section,
      item: modelItem,
    );
  }

  @override
  Future<bool> updateInstallationItemInSection({
    required String missionId,
    required String section,
    required int index,
    required InstallationItemEntity item,
  }) {
    final modelItem = DescriptionInstallationsMapper.toItemModel(item);
    return localDataSource.updateInstallationItemInSection(
      missionId: missionId,
      section: section,
      index: index,
      item: modelItem,
    );
  }

  @override
  Future<bool> removeInstallationItemFromSection({
    required String missionId,
    required String section,
    required int index,
  }) {
    return localDataSource.removeInstallationItemFromSection(
      missionId: missionId,
      section: section,
      index: index,
    );
  }

  @override
  Future<bool> updateSelection({
    required String missionId,
    required String field,
    required String value,
  }) {
    return localDataSource.updateSelection(
      missionId: missionId,
      field: field,
      value: value,
    );
  }
}
