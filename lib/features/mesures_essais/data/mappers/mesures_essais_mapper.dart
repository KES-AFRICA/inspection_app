// lib/features/mesures_essais/data/mappers/mesures_essais_mapper.dart
import 'package:inspec_app/models/mesures_essais.dart';
import '../../domain/entities/mesures_essais_entities.dart';

class MesuresEssaisMapper {
  static MesuresEssaisEntity toEntity(MesuresEssais model) {
    return MesuresEssaisEntity(
      id: model.key,
      missionId: model.missionId,
      updatedAt: model.updatedAt,
      conditionMesure: ConditionMesureEntity(
        observation: model.conditionMesure.observation,
      ),
      essaiDemarrageAuto: EssaiDemarrageAutoEntity(
        observation: model.essaiDemarrageAuto.observation,
      ),
      testArretUrgence: TestArretUrgenceEntity(
        observation: model.testArretUrgence.observation,
      ),
      prisesTerre: model.prisesTerre.map((pt) {
        return PriseTerreEntity(
          localisation: pt.localisation,
          identification: pt.identification,
          conditionPriseTerre: pt.conditionPriseTerre,
          naturePriseTerre: pt.naturePriseTerre,
          methodeMesure: pt.methodeMesure,
          valeurMesure: pt.valeurMesure,
          observation: pt.observation,
        );
      }).toList(),
      avisMesuresTerre: AvisMesuresTerreEntity(
        satisfaisants: List<String>.from(model.avisMesuresTerre.satisfaisants),
        nonSatisfaisants: List<String>.from(model.avisMesuresTerre.nonSatisfaisants),
        observation: model.avisMesuresTerre.observation,
      ),
      essaisDeclenchement: model.essaisDeclenchement.map((ed) {
        return EssaiDeclenchementDifferentielEntity(
          localisation: ed.localisation,
          coffret: ed.coffret,
          designationCircuit: ed.designationCircuit,
          typeDispositif: ed.typeDispositif,
          reglageIAn: ed.reglageIAn,
          tempo: ed.tempo,
          isolement: ed.isolement,
          essai: ed.essai,
          observation: ed.observation,
        );
      }).toList(),
      continuiteResistances: model.continuiteResistances.map((cr) {
        return ContinuiteResistanceEntity(
          localisation: cr.localisation,
          designationTableau: cr.designationTableau,
          origineMesure: cr.origineMesure,
          observation: cr.observation,
        );
      }).toList(),
    );
  }

  static MesuresEssais toModel(MesuresEssaisEntity entity) {
    return MesuresEssais(
      missionId: entity.missionId,
      updatedAt: entity.updatedAt,
      conditionMesure: ConditionMesure(
        observation: entity.conditionMesure.observation,
      ),
      essaiDemarrageAuto: EssaiDemarrageAuto(
        observation: entity.essaiDemarrageAuto.observation,
      ),
      testArretUrgence: TestArretUrgence(
        observation: entity.testArretUrgence.observation,
      ),
      prisesTerre: entity.prisesTerre.map((pt) {
        return PriseTerre(
          localisation: pt.localisation,
          identification: pt.identification,
          conditionPriseTerre: pt.conditionPriseTerre,
          naturePriseTerre: pt.naturePriseTerre,
          methodeMesure: pt.methodeMesure,
          valeurMesure: pt.valeurMesure,
          observation: pt.observation,
        );
      }).toList(),
      avisMesuresTerre: AvisMesuresTerre(
        satisfaisants: List<String>.from(entity.avisMesuresTerre.satisfaisants),
        nonSatisfaisants: List<String>.from(entity.avisMesuresTerre.nonSatisfaisants),
        observation: entity.avisMesuresTerre.observation,
      ),
      essaisDeclenchement: entity.essaisDeclenchement.map((ed) {
        return EssaiDeclenchementDifferentiel(
          localisation: ed.localisation,
          coffret: ed.coffret,
          designationCircuit: ed.designationCircuit,
          typeDispositif: ed.typeDispositif,
          reglageIAn: ed.reglageIAn,
          tempo: ed.tempo,
          isolement: ed.isolement,
          essai: ed.essai,
          observation: ed.observation,
        );
      }).toList(),
      continuiteResistances: entity.continuiteResistances.map((cr) {
        return ContinuiteResistance(
          localisation: cr.localisation,
          designationTableau: cr.designationTableau,
          origineMesure: cr.origineMesure,
          observation: cr.observation,
        );
      }).toList(),
    );
  }
}
