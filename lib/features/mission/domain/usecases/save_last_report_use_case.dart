// lib/features/mission/domain/usecases/save_last_report_use_case.dart
import 'package:inspec_app/models/last_report.dart';
import '../repositories/mission_repository.dart';

class SaveLastReportUseCase {
  final MissionRepository repository;

  SaveLastReportUseCase({required this.repository});

  Future<void> call(LastReport report) async {
    await repository.saveLastReport(report);
  }
}
