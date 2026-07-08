// lib/features/description_installations/domain/usecases/update_description_selection_use_case.dart
import '../repositories/description_installations_repository.dart';

class UpdateDescriptionSelectionUseCase {
  final DescriptionInstallationsRepository repository;

  UpdateDescriptionSelectionUseCase({required this.repository});

  Future<bool> call({
    required String missionId,
    required String field,
    required String value,
  }) {
    return repository.updateSelection(
      missionId: missionId,
      field: field,
      value: value,
    );
  }
}
