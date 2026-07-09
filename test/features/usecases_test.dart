// test/features/usecases_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/core/di/injection_container.dart' as di;
import 'package:inspec_app/features/auth/domain/usecases/check_login_status_use_case.dart';
import 'package:inspec_app/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/get_missions_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/get_mission_by_id_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/update_document_status_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/add_document_personnalise_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/remove_document_personnalise_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/update_schema_option_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/update_mission_status_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/save_last_report_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/get_all_reports_for_mission_use_case.dart';

void main() {
  test('Should resolve use cases from get_it after di initialization', () async {
    // Réinitialiser GetIt avant le test
    await di.sl.reset();
    await di.init();

    // Vérifier l'enregistrement des Use Cases
    expect(di.sl.isRegistered<CheckLoginStatusUseCase>(), true);
    expect(di.sl.isRegistered<GetCurrentUserUseCase>(), true);
    expect(di.sl.isRegistered<GetMissionsUseCase>(), true);
    expect(di.sl.isRegistered<GetMissionByIdUseCase>(), true);
    expect(di.sl.isRegistered<UpdateDocumentStatusUseCase>(), true);
    expect(di.sl.isRegistered<AddDocumentPersonnaliseUseCase>(), true);
    expect(di.sl.isRegistered<RemoveDocumentPersonnaliseUseCase>(), true);
    expect(di.sl.isRegistered<UpdateSchemaOptionUseCase>(), true);
    expect(di.sl.isRegistered<UpdateMissionStatusUseCase>(), true);
    expect(di.sl.isRegistered<SaveLastReportUseCase>(), true);
    expect(di.sl.isRegistered<GetAllReportsForMissionUseCase>(), true);
  });
}
