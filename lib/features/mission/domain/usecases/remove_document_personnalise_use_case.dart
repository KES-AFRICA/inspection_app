// lib/features/mission/domain/usecases/remove_document_personnalise_use_case.dart
import '../repositories/mission_repository.dart';

class RemoveDocumentPersonnaliseUseCase {
  final MissionRepository repository;

  RemoveDocumentPersonnaliseUseCase({required this.repository});

  Future<bool> call({
    required String missionId,
    required String documentName,
  }) {
    return repository.removeDocumentPersonnalise(
      missionId: missionId,
      documentName: documentName,
    );
  }
}
