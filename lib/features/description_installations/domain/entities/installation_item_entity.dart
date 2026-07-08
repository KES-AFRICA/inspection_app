// lib/features/description_installations/domain/entities/installation_item_entity.dart

class InstallationItemEntity {
  final Map<String, String> data;
  final List<String> photoPaths;
  final DateTime createdAt;

  const InstallationItemEntity({
    required this.data,
    this.photoPaths = const [],
    required this.createdAt,
  });
}
