// test/features/renseignements_generaux_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/core/di/injection_container.dart' as di;
import 'package:inspec_app/features/mission/data/mappers/renseignements_generaux_mapper.dart';
import 'package:inspec_app/features/mission/domain/usecases/get_renseignements_generaux_use_case.dart';
import 'package:inspec_app/features/mission/domain/usecases/save_renseignements_generaux_use_case.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';

void main() {
  group('RenseignementsGenerauxMapper Tests', () {
    test('Should map Model to Entity and vice versa without loss', () {
      final now = DateTime.now();
      final model = RenseignementsGeneraux(
        missionId: 'mission_456',
        etablissement: 'Centrale Solaire',
        installation: 'TGBT MT',
        activite: 'Production Énergie',
        dateDebut: now.subtract(const Duration(days: 2)),
        dateFin: now,
        dureeJours: 2,
        verificationType: 'Périodique',
        registreControle: 'Registre A',
        compteRendu: ['Revue TGBT OK', 'Défaut isolement sur câble BT'],
        accompagnateurs: [
          {'nom': 'Martin', 'fonction': 'HSE Client'},
        ],
        verificateurs: [
          {'nom': 'Dupont', 'matricule': 'V001'},
        ],
        updatedAt: now,
        nomSite: 'Site Ouest',
      );

      // Vers l'entité
      final entity = RenseignementsGenerauxMapper.toEntity(model);
      expect(entity.missionId, 'mission_456');
      expect(entity.etablissement, 'Centrale Solaire');
      expect(entity.installation, 'TGBT MT');
      expect(entity.activite, 'Production Énergie');
      expect(entity.dureeJours, 2);
      expect(entity.verificationType, 'Périodique');
      expect(entity.registreControle, 'Registre A');
      expect(entity.compteRendu.length, 2);
      expect(entity.compteRendu.first, 'Revue TGBT OK');
      expect(entity.accompagnateurs.length, 1);
      expect(entity.accompagnateurs.first['nom'], 'Martin');
      expect(entity.verificateurs.length, 1);
      expect(entity.verificateurs.first['matricule'], 'V001');
      expect(entity.updatedAt, now);
      expect(entity.nomSite, 'Site Ouest');

      // Retour vers le modèle
      final mappedModel = RenseignementsGenerauxMapper.toModel(entity);
      expect(mappedModel.missionId, 'mission_456');
      expect(mappedModel.etablissement, 'Centrale Solaire');
      expect(mappedModel.installation, 'TGBT MT');
      expect(mappedModel.activite, 'Production Énergie');
      expect(mappedModel.dureeJours, 2);
      expect(mappedModel.verificationType, 'Périodique');
      expect(mappedModel.registreControle, 'Registre A');
      expect(mappedModel.compteRendu.length, 2);
      expect(mappedModel.compteRendu[1], 'Défaut isolement sur câble BT');
      expect(mappedModel.accompagnateurs.length, 1);
      expect(mappedModel.accompagnateurs.first['fonction'], 'HSE Client');
      expect(mappedModel.verificateurs.length, 1);
      expect(mappedModel.verificateurs.first['nom'], 'Dupont');
      expect(mappedModel.updatedAt, now);
      expect(mappedModel.nomSite, 'Site Ouest');
    });
  });

  group('RenseignementsGeneraux DI Registration Tests', () {
    test('Should resolve RenseignementsGeneraux UseCases from get_it after di initialization', () async {
      await di.sl.reset();
      await di.init();

      expect(di.sl.isRegistered<GetRenseignementsGenerauxUseCase>(), true);
      expect(di.sl.isRegistered<SaveRenseignementsGenerauxUseCase>(), true);
    });
  });
}
