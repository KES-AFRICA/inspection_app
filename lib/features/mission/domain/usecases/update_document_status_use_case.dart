// lib/features/mission/domain/usecases/update_document_status_use_case.dart
import '../repositories/mission_repository.dart';

class UpdateDocumentStatusUseCase {
  final MissionRepository repository;

  UpdateDocumentStatusUseCase({required this.repository});

  Future<bool> call({
    required String missionId,
    required String documentField,
    required bool value,
  }) {
    return repository.updateDocumentStatus(
      missionId: missionId,
      documentField: documentField,
      value: value,
    );
  }
}
