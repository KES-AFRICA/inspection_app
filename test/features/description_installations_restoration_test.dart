import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/features/description_installations/data/mappers/description_installations_mapper.dart';
import 'package:inspec_app/features/description_installations/domain/entities/description_installations_entity.dart';
import 'package:inspec_app/features/description_installations/domain/entities/installation_item_entity.dart';

void main() {
  group('DescriptionInstallations Data Integrity & Restoration Tests', () {
    test('Older DescriptionInstallations records retain all existing fields when new MT site fields are null', () {
      final oldModel = DescriptionInstallations(
        missionId: 'mission_test_123',
        alimentationMoyenneTension: [
          InstallationItem(data: {'Gamme De Cellule': 'RM6', 'Type De Cellule': 'IQ'}),
        ],
        alimentationBasseTension: [
          InstallationItem(data: {'Puissance Transformateur': '400'}),
        ],
        groupeElectrogene: [
          InstallationItem(data: {'Marque': 'SDMO', 'Puissance (Kva)': '100'}),
        ],
        regimeNeutre: 'TT',
        eclairageSecurite: 'Présent',
      );

      // Verify legacy model fields are intact
      expect(oldModel.alimentationMoyenneTension.length, 1);
      expect(oldModel.alimentationMoyenneTension.first.data['Gamme De Cellule'], 'RM6');
      expect(oldModel.alimentationBasseTension.first.data['Puissance Transformateur'], '400');
      expect(oldModel.groupeElectrogene.first.data['Marque'], 'SDMO');
      expect(oldModel.regimeNeutre, 'TT');
      expect(oldModel.eclairageSecurite, 'Présent');

      // Verify new fields default to null without breaking existing fields
      expect(oldModel.natureReseauAlimentationSite, isNull);
      expect(oldModel.tensionAlimentationSite, isNull);
      expect(oldModel.nombreAlimentationSite, isNull);
      expect(oldModel.presenceIacmAlimentationSite, isNull);
    });

    test('Mapper bidirectionnellement préserve l’intégralité des données y compris les nouveaux champs MT site', () {
      final model = DescriptionInstallations(
        missionId: 'mission_test_456',
        natureReseauAlimentationSite: 'Souterrain',
        tensionAlimentationSite: '15',
        nombreAlimentationSite: '2',
        presenceIacmAlimentationSite: 'Oui',
        alimentationMoyenneTension: [
          InstallationItem(data: {'Type': 'SM6'}),
        ],
        alimentationBasseTension: [
          InstallationItem(data: {'Puissance': '630'}),
        ],
        regimeNeutre: 'TN',
      );

      final entity = DescriptionInstallationsMapper.toEntity(model);
      expect(entity.natureReseauAlimentationSite, 'Souterrain');
      expect(entity.tensionAlimentationSite, '15');
      expect(entity.nombreAlimentationSite, '2');
      expect(entity.presenceIacmAlimentationSite, 'Oui');
      expect(entity.isSectionComplete('alimentation_site_mt'), true);
      expect(entity.isSectionComplete('alimentation_moyenne_tension'), true);
      expect(entity.isSectionComplete('alimentation_basse_tension'), true);
      expect(entity.isSectionComplete('regime_neutre'), true);

      final remappedModel = DescriptionInstallationsMapper.toModel(entity);
      expect(remappedModel.natureReseauAlimentationSite, 'Souterrain');
      expect(remappedModel.alimentationMoyenneTension.first.data['Type'], 'SM6');
      expect(remappedModel.regimeNeutre, 'TN');
    });

    test('getProgress calcule correctement la complétion des sections existantes et de la nouvelle section MT site', () {
      final entity = DescriptionInstallationsEntity(
        missionId: 'mission_test_789',
        alimentationMoyenneTension: [
          InstallationItemEntity(data: {'Gamme': 'SM6'}, createdAt: DateTime.now()),
        ],
        regimeNeutre: 'TT',
        updatedAt: DateTime.now(),
      );

      final progress = entity.getProgress();
      expect(progress['alimentation_site_mt'], false);
      expect(progress['alimentation_moyenne_tension'], true);
      expect(progress['regime_neutre'], true);
      expect(progress['alimentation_basse_tension'], false);
    });
  });
}
