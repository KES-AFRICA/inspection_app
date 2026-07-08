// lib/features/mesures_essais/data/datasources/mesures_essais_local_data_source.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/models/mission.dart';

abstract class MesuresEssaisLocalDataSource {
  Future<MesuresEssais> getOrCreateMesuresEssais(String missionId);
  Future<void> saveMesuresEssais(MesuresEssais mesures);
}

class MesuresEssaisLocalDataSourceImpl implements MesuresEssaisLocalDataSource {
  static const String _mesuresEssaisBox = 'mesures_essais';
  static const String _missionBox = 'missions';

  Box<MesuresEssais> get _box => Hive.box<MesuresEssais>(_mesuresEssaisBox);
  Box<Mission> get _mBox => Hive.box<Mission>(_missionBox);

  @override
  Future<MesuresEssais> getOrCreateMesuresEssais(String missionId) async {
    try {
      return _box.values.firstWhere((mesures) => mesures.missionId == missionId);
    } catch (e) {
      final newMesures = MesuresEssais.create(missionId);
      await _box.add(newMesures);

      final mission = _mBox.get(missionId);
      if (mission != null) {
        mission.mesuresEssaisId = newMesures.key.toString();
        await mission.save();
      }

      if (kDebugMode) print('✅ MesuresEssais créé pour mission: $missionId');
      return newMesures;
    }
  }

  @override
  Future<void> saveMesuresEssais(MesuresEssais mesures) async {
    try {
      mesures.updatedAt = DateTime.now();
      await mesures.save();
      if (kDebugMode) print('✅ MesuresEssais sauvegardé pour mission: ${mesures.missionId}');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur saveMesuresEssais: $e');
      rethrow;
    }
  }
}
