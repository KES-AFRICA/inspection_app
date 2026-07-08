// lib/features/description_installations/domain/usecases/save_description_installations_use_case.dart
import '../entities/description_installations_entity.dart';
import '../repositories/description_installations_repository.dart';

class SaveDescriptionInstallationsUseCase {
  final DescriptionInstallationsRepository repository;

  SaveDescriptionInstallationsUseCase({required this.repository});

  Future<void> call(DescriptionInstallationsEntity desc) {
    return repository.saveDescriptionInstallations(desc);
  }
}
