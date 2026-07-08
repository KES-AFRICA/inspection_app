// lib/features/description_installations/data/mappers/description_installations_mapper.dart
import 'package:inspec_app/models/description_installations.dart';
import '../../domain/entities/description_installations_entity.dart';
import '../../domain/entities/installation_item_entity.dart';

class DescriptionInstallationsMapper {
  static InstallationItemEntity toItemEntity(InstallationItem model) {
    return InstallationItemEntity(
      data: Map<String, String>.from(model.data),
      photoPaths: List<String>.from(model.photoPaths),
      createdAt: model.createdAt,
    );
  }

  static InstallationItem toItemModel(InstallationItemEntity entity) {
    return InstallationItem(
      data: Map<String, String>.from(entity.data),
      photoPaths: List<String>.from(entity.photoPaths),
      createdAt: entity.createdAt,
    );
  }

  static DescriptionInstallationsEntity toEntity(DescriptionInstallations model) {
    return DescriptionInstallationsEntity(
      missionId: model.missionId,
      alimentationMoyenneTension: model.alimentationMoyenneTension.map(toItemEntity).toList(),
      alimentationBasseTension: model.alimentationBasseTension.map(toItemEntity).toList(),
      groupeElectrogene: model.groupeElectrogene.map(toItemEntity).toList(),
      alimentationCarburant: model.alimentationCarburant.map(toItemEntity).toList(),
      inverseur: model.inverseur.map(toItemEntity).toList(),
      stabilisateur: model.stabilisateur.map(toItemEntity).toList(),
      onduleurs: model.onduleurs.map(toItemEntity).toList(),
      regimeNeutre: model.regimeNeutre,
      regimeNeutreDetail: model.regimeNeutreDetail,
      eclairageSecurite: model.eclairageSecurite,
      modificationsInstallations: model.modificationsInstallations,
      noteCalcul: model.noteCalcul,
      registreSecurite: model.registreSecurite,
      presenceParatonnerre: model.presenceParatonnerre,
      analyseRisqueFoudre: model.analyseRisqueFoudre,
      etudeTechniqueFoudre: model.etudeTechniqueFoudre,
      updatedAt: model.updatedAt,
    );
  }

  static DescriptionInstallations toModel(DescriptionInstallationsEntity entity) {
    return DescriptionInstallations(
      missionId: entity.missionId,
      alimentationMoyenneTension: entity.alimentationMoyenneTension.map(toItemModel).toList(),
      alimentationBasseTension: entity.alimentationBasseTension.map(toItemModel).toList(),
      groupeElectrogene: entity.groupeElectrogene.map(toItemModel).toList(),
      alimentationCarburant: entity.alimentationCarburant.map(toItemModel).toList(),
      inverseur: entity.inverseur.map(toItemModel).toList(),
      stabilisateur: entity.stabilisateur.map(toItemModel).toList(),
      onduleurs: entity.onduleurs.map(toItemModel).toList(),
      regimeNeutre: entity.regimeNeutre,
      regimeNeutreDetail: entity.regimeNeutreDetail,
      eclairageSecurite: entity.eclairageSecurite,
      modificationsInstallations: entity.modificationsInstallations,
      noteCalcul: entity.noteCalcul,
      registreSecurite: entity.registreSecurite,
      presenceParatonnerre: entity.presenceParatonnerre,
      analyseRisqueFoudre: entity.analyseRisqueFoudre,
      etudeTechniqueFoudre: entity.etudeTechniqueFoudre,
      updatedAt: entity.updatedAt,
    );
  }
}
