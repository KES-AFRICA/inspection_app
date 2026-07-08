// lib/features/foudre/data/datasources/foudre_local_data_source.dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/models/mission.dart';

abstract class FoudreLocalDataSource {
  Future<List<Foudre>> getFoudreObservationsByMissionId(String missionId);
  Future<Foudre> createFoudreObservation({
    required String missionId,
    required String observation,
    required int niveauPriorite,
  });
  Future<bool> updateFoudreObservation({
    required dynamic foudreId,
    required String observation,
    required int niveauPriorite,
  });
  Future<bool> deleteFoudreObservation(dynamic foudreId);
}

class FoudreLocalDataSourceImpl implements FoudreLocalDataSource {
  static const String _foudreBox = 'foudre_observations';
  static const String _missionBox = 'missions';

  Box<Foudre> get _box => Hive.box<Foudre>(_foudreBox);
  Box<Mission> get _mBox => Hive.box<Mission>(_missionBox);

  @override
  Future<List<Foudre>> getFoudreObservationsByMissionId(String missionId) async {
    try {
      return _box.values.where((element) => element.missionId == missionId).toList();
    } catch (e) {
      if (kDebugMode) print('❌ Erreur getFoudreObservationsByMissionId: $e');
      return [];
    }
  }

  @override
  Future<Foudre> createFoudreObservation({
    required String missionId,
    required String observation,
    required int niveauPriorite,
  }) async {
    try {
      final foudre = Foudre.create(
        missionId: missionId,
        observation: observation,
        niveauPriorite: niveauPriorite,
      );
      await _box.add(foudre);

      await _updateFoudreReferenceInMission(missionId, foudre);

      return foudre;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur createFoudreObservation: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updateFoudreObservation({
    required dynamic foudreId,
    required String observation,
    required int niveauPriorite,
  }) async {
    try {
      final foudre = _box.get(foudreId);
      if (foudre == null) return false;

      foudre.observation = observation;
      foudre.niveauPriorite = niveauPriorite;
      foudre.updatedAt = DateTime.now();
      await foudre.save();

      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur updateFoudreObservation: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteFoudreObservation(dynamic foudreId) async {
    try {
      final foudre = _box.get(foudreId);
      if (foudre == null) return false;

      final missionId = foudre.missionId;
      await _removeFoudreReferenceFromMission(missionId, foudreId);
      await foudre.delete();

      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur deleteFoudreObservation: $e');
      return false;
    }
  }

  Future<void> _updateFoudreReferenceInMission(String missionId, Foudre foudre) async {
    try {
      final mission = _mBox.get(missionId);
      if (mission != null) {
        mission.foudreIds ??= [];
        final foudreIdStr = foudre.key.toString();
        if (!mission.foudreIds!.contains(foudreIdStr)) {
          mission.foudreIds!.add(foudreIdStr);
          mission.updatedAt = DateTime.now();
          await mission.save();
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur _updateFoudreReferenceInMission: $e');
    }
  }

  Future<void> _removeFoudreReferenceFromMission(String missionId, dynamic foudreId) async {
    try {
      final mission = _mBox.get(missionId);
      if (mission != null && mission.foudreIds != null) {
        mission.foudreIds!.remove(foudreId.toString());
        mission.updatedAt = DateTime.now();
        await mission.save();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erreur _removeFoudreReferenceFromMission: $e');
    }
  }
}
