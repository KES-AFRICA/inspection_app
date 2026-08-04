import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/features/mission/domain/entities/renseignements_generaux_entity.dart';
import 'package:inspec_app/features/mission/data/mappers/renseignements_generaux_mapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RenseignementsGeneraux Persistence & Mapping Tests', () {
    test('Model should hold activiteSurSite, classementReglementaireType and classementReglementaireCategorie', () {
      final rg = RenseignementsGeneraux(
        missionId: 'M123',
        etablissement: 'CAMWATER Yaoundé',
        installation: 'Bâtiment Principal',
        activite: 'Traitement d\'eau',
        activiteSurSite: 'Pompage et distribution',
        classementReglementaireType: 'M',
        classementReglementaireCategorie: '1ère catégorie',
        updatedAt: DateTime.now(),
        nomSite: 'Site A',
      );

      expect(rg.activiteSurSite, equals('Pompage et distribution'));
      expect(rg.classementReglementaireType, equals('M'));
      expect(rg.classementReglementaireCategorie, equals('1ère catégorie'));

      final map = rg.toMap();
      expect(map['activiteSurSite'], equals('Pompage et distribution'));
      expect(map['classementReglementaireType'], equals('M'));
      expect(map['classementReglementaireCategorie'], equals('1ère catégorie'));
    });

    test('Mapper toEntity and toModel should preserve activiteSurSite, classementReglementaireType and classementReglementaireCategorie', () {
      final model = RenseignementsGeneraux(
        missionId: 'M123',
        etablissement: 'CAMWATER Douala',
        installation: 'Station B',
        activite: 'Distribution',
        activiteSurSite: 'Bureaux et ateliers',
        classementReglementaireType: 'N',
        classementReglementaireCategorie: '2ème catégorie',
        updatedAt: DateTime.now(),
        nomSite: 'Site Douala',
      );

      final entity = RenseignementsGenerauxMapper.toEntity(model);
      expect(entity.activiteSurSite, equals('Bureaux et ateliers'));
      expect(entity.classementReglementaireType, equals('N'));
      expect(entity.classementReglementaireCategorie, equals('2ème catégorie'));

      final restoredModel = RenseignementsGenerauxMapper.toModel(entity);
      expect(restoredModel.activiteSurSite, equals('Bureaux et ateliers'));
      expect(restoredModel.classementReglementaireType, equals('N'));
      expect(restoredModel.classementReglementaireCategorie, equals('2ème catégorie'));
    });
  });
}
