// lib/features/description_installations/domain/usecases/get_description_installations_use_case.dart
import '../entities/description_installations_entity.dart';
import '../repositories/description_installations_repository.dart';

class GetDescriptionInstallationsUseCase {
  final DescriptionInstallationsRepository repository;

  GetDescriptionInstallationsUseCase({required this.repository});

  Future<DescriptionInstallationsEntity> call(String missionId) {
    return repository.getOrCreateDescriptionInstallations(missionId);
  }
}
