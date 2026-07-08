// test/features/jsa_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/core/di/injection_container.dart' as di;
import 'package:inspec_app/features/jsa/data/mappers/jsa_mapper.dart';
import 'package:inspec_app/features/jsa/domain/usecases/get_jsa_by_mission_use_case.dart';
import 'package:inspec_app/features/jsa/domain/usecases/save_jsa_use_case.dart';
import 'package:inspec_app/models/jsa.dart';

void main() {
  group('JsaMapper Tests', () {
    test('Should map Model to Entity and vice versa without loss', () {
      final now = DateTime.now();
      final model = JSA(
        missionId: 'mission_123',
        operationEffectuer: 'Audit transformateur',
        inspecteurs: [
          JSAInspecteur(nom: 'Dupont', prenom: 'Jean', signature: 'sig_dupont'),
        ],
        planUrgence: JSAPlanUrgence(
          voiesIssuesIdentifiees: true,
          personneContactClient: 'Alice',
        ),
        dangers: JSADangers()..chocElectrique = true..bruit = true,
        exigencesGenerales: JSAExigencesGenerales()..extincteurs = true,
        epi: JSAEPI()..casqueSecurite = true..gantsIsolants = true,
        verificationFinale: JSAVerificationFinale()..travailTermineApplicable = true,
        updatedAt: now,
        currentSubCategory: 3,
      );

      // Vers l'entité
      final entity = JsaMapper.toEntity(model);
      expect(entity.missionId, 'mission_123');
      expect(entity.operationEffectuer, 'Audit transformateur');
      expect(entity.inspecteurs.length, 1);
      expect(entity.inspecteurs.first.nom, 'Dupont');
      expect(entity.planUrgence.voiesIssuesIdentifiees, true);
      expect(entity.planUrgence.personneContactClient, 'Alice');
      expect(entity.dangers.chocElectrique, true);
      expect(entity.dangers.bruit, true);
      expect(entity.dangers.chuteObjets, false);
      expect(entity.exigencesGenerales.extincteurs, true);
      expect(entity.epi.casqueSecurite, true);
      expect(entity.epi.gantsIsolants, true);
      expect(entity.verificationFinale.travailTermineApplicable, true);
      expect(entity.updatedAt, now);
      expect(entity.currentSubCategory, 3);

      // Retour vers le modèle
      final mappedModel = JsaMapper.toModel(entity);
      expect(mappedModel.missionId, 'mission_123');
      expect(mappedModel.operationEffectuer, 'Audit transformateur');
      expect(mappedModel.inspecteurs.length, 1);
      expect(mappedModel.inspecteurs.first.nom, 'Dupont');
      expect(mappedModel.planUrgence.voiesIssuesIdentifiees, true);
      expect(mappedModel.planUrgence.personneContactClient, 'Alice');
      expect(mappedModel.dangers.chocElectrique, true);
      expect(mappedModel.dangers.bruit, true);
      expect(mappedModel.exigencesGenerales.extincteurs, true);
      expect(mappedModel.epi.casqueSecurite, true);
      expect(mappedModel.epi.gantsIsolants, true);
      expect(mappedModel.verificationFinale.travailTermineApplicable, true);
      expect(mappedModel.updatedAt, now);
      expect(mappedModel.currentSubCategory, 3);
    });
  });

  group('Jsa DI Registration Tests', () {
    test('Should resolve JSA UseCases from get_it after di initialization', () async {
      await di.sl.reset();
      await di.init();

      expect(di.sl.isRegistered<GetJsaByMissionUseCase>(), true);
      expect(di.sl.isRegistered<SaveJsaUseCase>(), true);
    });
  });
}
