// test/features/description_installations_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/core/di/injection_container.dart' as di;
import 'package:inspec_app/features/description_installations/data/mappers/description_installations_mapper.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/get_description_installations_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/save_description_installations_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/add_installation_item_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/update_installation_item_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/remove_installation_item_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/update_description_selection_use_case.dart';
import 'package:inspec_app/models/description_installations.dart';

void main() {
  group('DescriptionInstallationsMapper Tests', () {
    test('Should map Model to Entity and vice versa without loss', () {
      final now = DateTime.now();
      final item = InstallationItem(
        data: {'courant': '10A', 'tension': '220V'},
        photoPaths: ['photo1.jpg', 'photo2.jpg'],
        createdAt: now,
      );

      final model = DescriptionInstallations(
        missionId: 'mission_123',
        alimentationMoyenneTension: [item],
        alimentationBasseTension: [],
        groupeElectrogene: [],
        alimentationCarburant: [],
        inverseur: [],
        stabilisateur: [],
        onduleurs: [],
        regimeNeutre: 'TT',
        regimeNeutreDetail: 'Neutre relié directement à la terre',
        eclairageSecurite: 'OK',
        modificationsInstallations: 'Aucune',
        noteCalcul: 'Conforme',
        registreSecurite: 'Absent',
        presenceParatonnerre: 'Oui',
        analyseRisqueFoudre: 'Faible',
        etudeTechniqueFoudre: 'Non requise',
        updatedAt: now,
      );

      // Vers l'entité
      final entity = DescriptionInstallationsMapper.toEntity(model);
      expect(entity.missionId, 'mission_123');
      expect(entity.alimentationMoyenneTension.length, 1);
      expect(entity.alimentationMoyenneTension.first.data['courant'], '10A');
      expect(entity.alimentationMoyenneTension.first.photoPaths.length, 2);
      expect(entity.alimentationMoyenneTension.first.photoPaths[1], 'photo2.jpg');
      expect(entity.regimeNeutre, 'TT');
      expect(entity.regimeNeutreDetail, 'Neutre relié directement à la terre');
      expect(entity.presenceParatonnerre, 'Oui');
      expect(entity.analyseRisqueFoudre, 'Faible');
      expect(entity.updatedAt, now);

      // Calculs de progression sur l'entité
      expect(entity.isSectionComplete('alimentation_moyenne_tension'), true);
      expect(entity.isSectionComplete('alimentation_basse_tension'), false);
      expect(entity.isSectionComplete('regime_neutre'), true);
      expect(entity.getProgress()['alimentation_moyenne_tension'], true);
      expect(entity.getProgress()['alimentation_basse_tension'], false);
      expect(entity.getCompletionPercentage() > 0, true);

      // Retour vers le modèle
      final mappedModel = DescriptionInstallationsMapper.toModel(entity);
      expect(mappedModel.missionId, 'mission_123');
      expect(mappedModel.alimentationMoyenneTension.length, 1);
      expect(mappedModel.alimentationMoyenneTension.first.data['tension'], '220V');
      expect(mappedModel.alimentationMoyenneTension.first.photoPaths.first, 'photo1.jpg');
      expect(mappedModel.regimeNeutre, 'TT');
      expect(mappedModel.regimeNeutreDetail, 'Neutre relié directement à la terre');
      expect(mappedModel.presenceParatonnerre, 'Oui');
      expect(mappedModel.analyseRisqueFoudre, 'Faible');
      expect(mappedModel.updatedAt, now);
    });
  });

  group('DescriptionInstallations DI Registration Tests', () {
    test('Should resolve DescriptionInstallations UseCases from get_it after di initialization', () async {
      await di.sl.reset();
      await di.init();

      expect(di.sl.isRegistered<GetDescriptionInstallationsUseCase>(), true);
      expect(di.sl.isRegistered<SaveDescriptionInstallationsUseCase>(), true);
      expect(di.sl.isRegistered<AddInstallationItemUseCase>(), true);
      expect(di.sl.isRegistered<UpdateInstallationItemUseCase>(), true);
      expect(di.sl.isRegistered<RemoveInstallationItemUseCase>(), true);
      expect(di.sl.isRegistered<UpdateDescriptionSelectionUseCase>(), true);
    });
  });
}
