// lib/features/mission/data/datasources/mission_local_data_source.dart
import 'package:hive/hive.dart';
import 'package:inspec_app/models/mission.dart';

abstract class MissionLocalDataSource {
  List<Mission> getMissionsByMatricule(String matricule);
}

class MissionLocalDataSourceImpl implements MissionLocalDataSource {
  static const String _missionBox = 'missions';

  @override
  List<Mission> getMissionsByMatricule(String matricule) {
    final box = Hive.box<Mission>(_missionBox);
    return box.values.where((mission) {
      if (mission.verificateurs == null) return false;
      return mission.verificateurs!.any((v) => v['matricule'] == matricule);
    }).toList();
  }
}
