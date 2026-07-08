// lib/features/foudre/data/mappers/foudre_mapper.dart
import 'package:inspec_app/models/foudre.dart';
import '../../domain/entities/foudre_entity.dart';

class FoudreMapper {
  static FoudreEntity toEntity(Foudre model) {
    return FoudreEntity(
      id: model.key,
      missionId: model.missionId,
      observation: model.observation,
      niveauPriorite: model.niveauPriorite,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  static Foudre toModel(FoudreEntity entity) {
    return Foudre(
      missionId: entity.missionId,
      observation: entity.observation,
      niveauPriorite: entity.niveauPriorite,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
