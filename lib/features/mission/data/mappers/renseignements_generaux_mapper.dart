// lib/features/mission/data/mappers/renseignements_generaux_mapper.dart
import 'package:inspec_app/models/renseignements_generaux.dart';
import '../../domain/entities/renseignements_generaux_entity.dart';

class RenseignementsGenerauxMapper {
  static RenseignementsGenerauxEntity toEntity(RenseignementsGeneraux model) {
    return RenseignementsGenerauxEntity(
      missionId: model.missionId,
      etablissement: model.etablissement,
      installation: model.installation,
      activite: model.activite,
      dateDebut: model.dateDebut,
      dateFin: model.dateFin,
      dureeJours: model.dureeJours,
      verificationType: model.verificationType,
      registreControle: model.registreControle,
      compteRendu: List<String>.from(model.compteRendu),
      accompagnateurs: List<Map<String, String>>.from(
        model.accompagnateurs.map((m) => Map<String, String>.from(m)),
      ),
      verificateurs: List<Map<String, String>>.from(
        model.verificateurs.map((m) => Map<String, String>.from(m)),
      ),
      updatedAt: model.updatedAt,
      nomSite: model.nomSite,
    );
  }

  static RenseignementsGeneraux toModel(RenseignementsGenerauxEntity entity) {
    return RenseignementsGeneraux(
      missionId: entity.missionId,
      etablissement: entity.etablissement,
      installation: entity.installation,
      activite: entity.activite,
      dateDebut: entity.dateDebut,
      dateFin: entity.dateFin,
      dureeJours: entity.dureeJours,
      verificationType: entity.verificationType,
      registreControle: entity.registreControle,
      compteRendu: List<String>.from(entity.compteRendu),
      accompagnateurs: List<Map<String, String>>.from(
        entity.accompagnateurs.map((m) => Map<String, String>.from(m)),
      ),
      verificateurs: List<Map<String, String>>.from(
        entity.verificateurs.map((m) => Map<String, String>.from(m)),
      ),
      updatedAt: entity.updatedAt,
      nomSite: entity.nomSite,
    );
  }
}
