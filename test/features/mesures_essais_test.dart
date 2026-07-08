// test/features/mesures_essais_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/features/mesures_essais/data/mappers/mesures_essais_mapper.dart';
import 'package:inspec_app/features/mesures_essais/domain/usecases/get_mesures_essais_use_case.dart';
import 'package:inspec_app/features/mesures_essais/domain/usecases/save_mesures_essais_use_case.dart';
import 'package:inspec_app/core/di/injection_container.dart' as di;

void main() {
  group('MesuresEssaisMapper Tests', () {
    test('Should map Model to Entity and vice versa without loss', () {
      final model = MesuresEssais(
        missionId: 'mission_456',
        updatedAt: DateTime(2026, 7, 8),
        conditionMesure: ConditionMesure(observation: 'Sol humide'),
        essaiDemarrageAuto: EssaiDemarrageAuto(observation: 'Démarrage en 3s'),
        testArretUrgence: TestArretUrgence(observation: 'Arrêt immédiat'),
        prisesTerre: [
          PriseTerre(
            localisation: 'Local transfo',
            identification: 'PT1',
            conditionPriseTerre: 'Barrette ouverte',
            naturePriseTerre: 'Piquet de terre',
            methodeMesure: 'Méthode des 3 pôles',
            valeurMesure: 12.5,
            observation: 'Satisfaisant',
          ),
        ],
        avisMesuresTerre: AvisMesuresTerre(
          satisfaisants: ['PT1'],
          nonSatisfaisants: [],
          observation: 'Tout est OK',
        ),
        essaisDeclenchement: [
          EssaiDeclenchementDifferentiel(
            localisation: 'Local transfo',
            coffret: 'Armoire générale',
            designationCircuit: 'Circuit Clim',
            typeDispositif: 'DDR',
            reglageIAn: 300.0,
            tempo: 0.1,
            isolement: 100.0,
            essai: 'B',
            observation: 'RAS',
          ),
        ],
        continuiteResistances: [
          ContinuiteResistance(
            localisation: 'Local transfo',
            designationTableau: 'TGBT',
            origineMesure: 'Borne terre',
            observation: 'RAS',
          ),
        ],
      );

      final entity = MesuresEssaisMapper.toEntity(model);
      expect(entity.missionId, model.missionId);
      expect(entity.conditionMesure.observation, model.conditionMesure.observation);
      expect(entity.essaiDemarrageAuto.observation, model.essaiDemarrageAuto.observation);
      expect(entity.testArretUrgence.observation, model.testArretUrgence.observation);
      
      expect(entity.prisesTerre.length, 1);
      expect(entity.prisesTerre[0].localisation, 'Local transfo');
      expect(entity.prisesTerre[0].valeurMesure, 12.5);
      
      expect(entity.avisMesuresTerre.satisfaisants, ['PT1']);
      expect(entity.essaisDeclenchement.length, 1);
      expect(entity.essaisDeclenchement[0].typeDispositif, 'DDR');
      expect(entity.continuiteResistances.length, 1);
      expect(entity.continuiteResistances[0].designationTableau, 'TGBT');

      final mappedModel = MesuresEssaisMapper.toModel(entity);
      expect(mappedModel.missionId, entity.missionId);
      expect(mappedModel.conditionMesure.observation, entity.conditionMesure.observation);
      expect(mappedModel.essaiDemarrageAuto.observation, entity.essaiDemarrageAuto.observation);
      expect(mappedModel.testArretUrgence.observation, entity.testArretUrgence.observation);
      expect(mappedModel.prisesTerre.length, 1);
      expect(mappedModel.avisMesuresTerre.satisfaisants, ['PT1']);
      expect(mappedModel.essaisDeclenchement.length, 1);
      expect(mappedModel.continuiteResistances.length, 1);
    });
  });

  group('DI Registrations', () {
    test('Should resolve MesuresEssais UseCases from get_it after di initialization', () async {
      final getIt = GetIt.instance;
      await getIt.reset();

      await di.init();

      expect(getIt.isRegistered<GetMesuresEssaisUseCase>(), isTrue);
      expect(getIt.isRegistered<SaveMesuresEssaisUseCase>(), isTrue);

      final getUseCase = getIt<GetMesuresEssaisUseCase>();
      final saveUseCase = getIt<SaveMesuresEssaisUseCase>();

      expect(getUseCase, isNotNull);
      expect(saveUseCase, isNotNull);
    });
  });
}
