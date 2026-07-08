// lib/features/mission/data/datasources/renseignements_generaux_local_data_source.dart
import 'package:hive/hive.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/models/mission.dart';

abstract class RenseignementsGenerauxLocalDataSource {
  Future<RenseignementsGeneraux> getOrCreateRenseignementsGeneraux(String missionId);
  Future<void> saveRenseignementsGeneraux(RenseignementsGeneraux data);
}

class RenseignementsGenerauxLocalDataSourceImpl implements RenseignementsGenerauxLocalDataSource {
  static const String _renseignementsGenerauxBox = 'renseignements_generaux';
  static const String _missionBox = 'missions';

  @override
  Future<RenseignementsGeneraux> getOrCreateRenseignementsGeneraux(String missionId) async {
    final box = Hive.box<RenseignementsGeneraux>(_renseignementsGenerauxBox);
    try {
      final existing = box.values.firstWhere((r) => r.missionId == missionId);
      return existing;
    } catch (e) {
      final missionBox = Hive.box<Mission>(_missionBox);
      final mission = missionBox.get(missionId);

      final newData = RenseignementsGeneraux(
        missionId: missionId,
        etablissement: mission?.nomClient ?? '',
        installation: mission?.installation ?? '',
        activite: mission?.activiteClient ?? '',
        verificationType: mission?.natureMission,
        updatedAt: DateTime.now(),
        nomSite: mission?.nomSite ?? '',
        compteRendu: [],
        accompagnateurs: [],
        verificateurs: [],
      );

      await box.add(newData);

      // Mettre à jour la référence dans la mission
      if (mission != null) {
        mission.renseignementsGenerauxId = newData.key.toString();
        await mission.save();
      }

      return newData;
    }
  }

  @override
  Future<void> saveRenseignementsGeneraux(RenseignementsGeneraux data) async {
    final box = Hive.box<RenseignementsGeneraux>(_renseignementsGenerauxBox);
    data.updatedAt = DateTime.now();

    try {
      final existing = box.values.firstWhere((r) => r.missionId == data.missionId);
      await box.put(existing.key, data);
    } catch (e) {
      await box.add(data);
    }
  }
}
