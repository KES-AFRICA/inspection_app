// lib/features/mesures_essais/domain/entities/mesures_essais_entities.dart

class ConditionMesureEntity {
  final String? observation;

  const ConditionMesureEntity({this.observation});
}

class EssaiDemarrageAutoEntity {
  final String? observation;

  const EssaiDemarrageAutoEntity({this.observation});
}

class TestArretUrgenceEntity {
  final String? observation;

  const TestArretUrgenceEntity({this.observation});
}

class PriseTerreEntity {
  final String localisation;
  final String identification;
  final String conditionPriseTerre;
  final String naturePriseTerre;
  final String methodeMesure;
  final double? valeurMesure;
  final String? observation;

  const PriseTerreEntity({
    required this.localisation,
    required this.identification,
    required this.conditionPriseTerre,
    required this.naturePriseTerre,
    required this.methodeMesure,
    this.valeurMesure,
    this.observation,
  });
}

class AvisMesuresTerreEntity {
  final List<String> satisfaisants;
  final List<String> nonSatisfaisants;
  final String? observation;

  const AvisMesuresTerreEntity({
    required this.satisfaisants,
    required this.nonSatisfaisants,
    this.observation,
  });
}

class EssaiDeclenchementDifferentielEntity {
  final String localisation;
  final String? coffret;
  final String? designationCircuit;
  final String typeDispositif;
  final double? reglageIAn;
  final double? tempo;
  final double? isolement;
  final String essai;
  final String? observation;

  const EssaiDeclenchementDifferentielEntity({
    required this.localisation,
    this.coffret,
    this.designationCircuit,
    required this.typeDispositif,
    this.reglageIAn,
    this.tempo,
    this.isolement,
    required this.essai,
    this.observation,
  });
}

class ContinuiteResistanceEntity {
  final String localisation;
  final String designationTableau;
  final String origineMesure;
  final String? observation;

  const ContinuiteResistanceEntity({
    required this.localisation,
    required this.designationTableau,
    required this.origineMesure,
    this.observation,
  });
}

class MesuresEssaisEntity {
  final dynamic id;
  final String missionId;
  final DateTime updatedAt;
  final ConditionMesureEntity conditionMesure;
  final EssaiDemarrageAutoEntity essaiDemarrageAuto;
  final TestArretUrgenceEntity testArretUrgence;
  final List<PriseTerreEntity> prisesTerre;
  final AvisMesuresTerreEntity avisMesuresTerre;
  final List<EssaiDeclenchementDifferentielEntity> essaisDeclenchement;
  final List<ContinuiteResistanceEntity> continuiteResistances;

  const MesuresEssaisEntity({
    this.id,
    required this.missionId,
    required this.updatedAt,
    required this.conditionMesure,
    required this.essaiDemarrageAuto,
    required this.testArretUrgence,
    required this.prisesTerre,
    required this.avisMesuresTerre,
    required this.essaisDeclenchement,
    required this.continuiteResistances,
  });
}
