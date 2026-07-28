import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/features/mission/domain/entities/mission_entity.dart';
import 'package:inspec_app/features/mission/data/mappers/mission_mapper.dart';
import 'package:inspec_app/models/create_mission_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Renseignements Généraux New Fields & Backward Compatibility Tests', () {
    test('Mission model should support new fields activiteSurSite and classementReglementaire', () {
      final mission = Mission(
        id: 'mission_rg_01',
        nomClient: 'CAMRAIL BESSENGUE',
        activiteClient: 'Société de transport',
        activiteSurSite: 'Atelier de maintenance ferroviaire',
        classementReglementaireType: 'T',
        classementReglementaireCategorie: '1ère catégorie',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
      );

      expect(mission.activiteSurSite, equals('Atelier de maintenance ferroviaire'));
      expect(mission.classementReglementaireType, equals('T'));
      expect(mission.classementReglementaireCategorie, equals('1ère catégorie'));

      final json = mission.toJson();
      expect(json['activite_sur_site'], equals('Atelier de maintenance ferroviaire'));
      expect(json['classement_reglementaire_type'], equals('T'));
      expect(json['classement_reglementaire_categorie'], equals('1ère catégorie'));

      final restored = Mission.fromJson(json);
      expect(restored.activiteSurSite, equals('Atelier de maintenance ferroviaire'));
      expect(restored.classementReglementaireType, equals('T'));
      expect(restored.classementReglementaireCategorie, equals('1ère catégorie'));
    });

    test('Legacy missions without new fields should deserialize smoothly as null (backward compatibility)', () {
      final legacyJson = {
        'id': 'legacy_01',
        'nom_client': 'ANCIEN CLIENT',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'status': 'active',
      };

      final legacyMission = Mission.fromJson(legacyJson);
      expect(legacyMission.activiteSurSite, isNull);
      expect(legacyMission.classementReglementaireType, isNull);
      expect(legacyMission.classementReglementaireCategorie, isNull);
    });

    test('MissionMapper should map new fields to MissionEntity and back without loss', () {
      final model = Mission(
        id: 'map_01',
        nomClient: 'CLIENT TEST',
        activiteSurSite: 'Usine Textile',
        classementReglementaireType: 'M',
        classementReglementaireCategorie: '2ème catégorie',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
      );

      final entity = MissionMapper.toEntity(model);
      expect(entity.activiteSurSite, equals('Usine Textile'));
      expect(entity.classementReglementaireType, equals('M'));
      expect(entity.classementReglementaireCategorie, equals('2ème catégorie'));

      final backToModel = MissionMapper.toModel(entity);
      expect(backToModel.activiteSurSite, equals('Usine Textile'));
      expect(backToModel.classementReglementaireType, equals('M'));
      expect(backToModel.classementReglementaireCategorie, equals('2ème catégorie'));
    });

    test('CreateMissionData should map new fields to Mission via toMission', () {
      final createData = CreateMissionData(
        nomClient: 'NOUVEAU CLIENT',
        nomSite: 'SITE PRINCIPAL',
        installation: 'Toutes les installations',
        activiteSurSite: 'Entrepôt Logistique',
        classementReglementaireType: 'W',
        classementReglementaireCategorie: '3ème catégorie',
      );

      final m = createData.toMission('m_id', 'VERIF_01');
      expect(m.activiteSurSite, equals('Entrepôt Logistique'));
      expect(m.classementReglementaireType, equals('W'));
      expect(m.classementReglementaireCategorie, equals('3ème catégorie'));
    });
  });
}
