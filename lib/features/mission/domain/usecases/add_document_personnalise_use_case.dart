// lib/features/mission/domain/usecases/add_document_personnalise_use_case.dart
import '../repositories/mission_repository.dart';

class AddDocumentPersonnaliseUseCase {
  final MissionRepository repository;

  AddDocumentPersonnaliseUseCase({required this.repository});

  Future<bool> call({
    required String missionId,
    required String documentName,
  }) {
    return repository.addDocumentPersonnalise(
      missionId: missionId,
      documentName: documentName,
    );
  }
}
