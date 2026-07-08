// lib/features/jsa/data/datasources/jsa_local_data_source.dart
import 'package:hive/hive.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/models/mission.dart';

abstract class JsaLocalDataSource {
  Future<JSA> getOrCreateJSA(String missionId);
  Future<void> saveJSA(JSA jsa);
}

class JsaLocalDataSourceImpl implements JsaLocalDataSource {
  static const String _jsaBox = 'jsa';
  static const String _missionBox = 'missions';

  @override
  Future<JSA> getOrCreateJSA(String missionId) async {
    final box = Hive.box<JSA>(_jsaBox);
    try {
      final existing = box.values.firstWhere((jsa) => jsa.missionId == missionId);
      return existing;
    } catch (e) {
      final newJSA = JSA.create(missionId);
      await box.add(newJSA);

      // Mettre à jour la référence dans la mission
      final missionBox = Hive.box<Mission>(_missionBox);
      final mission = missionBox.get(missionId);
      if (mission != null) {
        mission.jsaId = newJSA.key.toString();
        await mission.save();
      }

      return newJSA;
    }
  }

  @override
  Future<void> saveJSA(JSA jsa) async {
    final box = Hive.box<JSA>(_jsaBox);
    jsa.updatedAt = DateTime.now();
    
    try {
      // Trouver l'objet existant dans la boîte par son missionId pour obtenir sa clé
      final existing = box.values.firstWhere((element) => element.missionId == jsa.missionId);
      await box.put(existing.key, jsa);
    } catch (e) {
      // Si non trouvé, on l'ajoute à la boîte
      await box.add(jsa);
    }
  }
}
