import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/features/description_installations/data/mappers/description_installations_mapper.dart';

void main() {
  group('Refonte FOUDRE & Paratonnerre', () {
    test('1. Progression & complétion paratonnerre cas Non', () {
      final desc = DescriptionInstallations(
        missionId: 'm1',
        presenceParatonnerre: 'Non',
        updatedAt: DateTime.now(),
      );

      expect(desc.isSectionComplete('paratonnerre'), isTrue);
    });

    test('2. Progression & complétion paratonnerre cas Oui', () {
      final desc = DescriptionInstallations(
        missionId: 'm1',
        presenceParatonnerre: 'Oui',
        analyseRisqueFoudre: 'Non',
        etudeTechniqueFoudre: 'Sans objet',
        updatedAt: DateTime.now(),
      );

      expect(desc.isSectionComplete('paratonnerre'), isTrue);
    });

    test('3. Non renseigné paratonnerre', () {
      final desc = DescriptionInstallations(
        missionId: 'm1',
        presenceParatonnerre: null,
        updatedAt: DateTime.now(),
      );

      expect(desc.isSectionComplete('paratonnerre'), isFalse);
    });

    test('4. Round-trip Clean Architecture Mapper avec foudreObservations', () {
      final obs = ObservationLibre(
        texte: 'Absence d\'étude technique foudre',
        pointVerificationKey: 'KEY_FOUDRE_01',
        referenceNormative: 'NF EN 62305-2',
        familleRisque: 'Risque foudre',
        criticite: 'Majeure',
        photos: ['/tmp/photo1.jpg'],
      );

      final model = DescriptionInstallations(
        missionId: 'm2',
        presenceParatonnerre: 'Oui',
        analyseRisqueFoudre: 'Non',
        etudeTechniqueFoudre: 'Non',
        foudreObservations: [obs],
        updatedAt: DateTime.now(),
      );

      final entity = DescriptionInstallationsMapper.toEntity(model);
      expect(entity.foudreObservations.length, 1);
      expect(entity.foudreObservations.first.texte, 'Absence d\'étude technique foudre');
      expect(entity.foudreObservations.first.referenceNormative, 'NF EN 62305-2');

      final mappedModel = DescriptionInstallationsMapper.toModel(entity);
      expect(mappedModel.foudreObservations.length, 1);
      expect(mappedModel.foudreObservations.first.referenceNormative, 'NF EN 62305-2');
    });
  });
}
