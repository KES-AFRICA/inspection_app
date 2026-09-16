import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/features/mission/data/mappers/mission_mapper.dart';
import 'package:inspec_app/features/mission/data/mappers/renseignements_generaux_mapper.dart';
import 'package:inspec_app/services/backup_service.dart';
import 'package:inspec_app/services/regulatory_classification_service.dart';

void main() {
  group('Regulatory Classification Persistence & Mapping Tests', () {
    test('Mission model to/from JSON roundtrip preserves classementReglementaire', () {
      final mission = Mission(
        id: 'test_mission_1',
        nomClient: 'KES Africa Test',
        status: 'en_cours',
        classementReglementaire: RegulatoryClassificationService.erpSpecialises,
        classementReglementaireType: 'Type OA',
        classementReglementaireCategorie: 'Première catégorie',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = mission.toJson();
      expect(json['classement_reglementaire'], equals('ERP Établissements Spécialisés'));
      expect(json['classement_reglementaire_type'], equals('Type OA'));
      expect(json['classement_reglementaire_categorie'], equals('Première catégorie'));

      final restored = Mission.fromJson(json);
      expect(restored.classementReglementaire, equals('ERP Établissements Spécialisés'));
      expect(restored.classementReglementaireType, equals('Type OA'));
      expect(restored.classementReglementaireCategorie, equals('Première catégorie'));
    });

    test('Mission entity mapper roundtrip preserves classementReglementaire', () {
      final mission = Mission(
        id: 'test_mission_2',
        nomClient: 'KES Africa Test 2',
        status: 'en_cours',
        classementReglementaire: RegulatoryClassificationService.igh,
        classementReglementaireType: 'GHA',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final entity = MissionMapper.toEntity(mission);
      expect(entity.classementReglementaire, equals('IGH'));
      expect(entity.classementReglementaireType, equals('GHA'));

      final restored = MissionMapper.toModel(entity);
      expect(restored.classementReglementaire, equals('IGH'));
      expect(restored.classementReglementaireType, equals('GHA'));
    });

    test('RenseignementsGeneraux toMap roundtrip preserves classementReglementaire', () {
      final rg = RenseignementsGeneraux(
        missionId: 'm123',
        etablissement: 'Usine Douala',
        nomSite: 'Site Bonabéri',
        installation: 'TGBT & Postes',
        activite: 'Cimenterie',
        classementReglementaire: RegulatoryClassificationService.installationsClassees,
        classementReglementaireType: 'Usines, Ateliers, Dépôts, Chantiers',
        classementReglementaireCategorie: null,
        updatedAt: DateTime.now(),
      );

      final map = rg.toMap();
      expect(map['classementReglementaire'], equals('Installations classées'));
      expect(map['classementReglementaireType'], equals('Usines, Ateliers, Dépôts, Chantiers'));
      expect(map['classementReglementaireCategorie'], isNull);
    });

    test('RenseignementsGeneraux entity mapper roundtrip preserves classementReglementaire', () {
      final rg = RenseignementsGeneraux(
        missionId: 'm456',
        etablissement: 'Hôtel Yaoundé',
        nomSite: 'Site Centre',
        installation: 'Basse Tension',
        activite: 'Hôtellerie',
        classementReglementaire: RegulatoryClassificationService.erpGeneraux,
        classementReglementaireType: 'Type O',
        classementReglementaireCategorie: 'Deuxième catégorie',
        updatedAt: DateTime.now(),
      );

      final entity = RenseignementsGenerauxMapper.toEntity(rg);
      expect(entity.classementReglementaire, equals('ERP Établissements Généraux'));
      expect(entity.classementReglementaireType, equals('Type O'));
      expect(entity.classementReglementaireCategorie, equals('Deuxième catégorie'));

      final restored = RenseignementsGenerauxMapper.toModel(entity);
      expect(restored.classementReglementaire, equals('ERP Établissements Généraux'));
      expect(restored.classementReglementaireType, equals('Type O'));
      expect(restored.classementReglementaireCategorie, equals('Deuxième catégorie'));
    });

    test('BackupService serialization includes classementReglementaire', () {
      final rg = RenseignementsGeneraux(
        missionId: 'm789',
        etablissement: 'Test Backup',
        nomSite: 'Site Akwa',
        installation: 'Installation BT',
        activite: 'Tertiaire',
        classementReglementaire: RegulatoryClassificationService.erpGeneraux,
        classementReglementaireType: 'Type W',
        classementReglementaireCategorie: 'Troisième catégorie',
        updatedAt: DateTime.now(),
      );

      final serialized = BackupService.testSerializeRenseignements(rg);
      expect(serialized['classementReglementaire'], equals('ERP Établissements Généraux'));
      expect(serialized['classementReglementaireType'], equals('Type W'));
      expect(serialized['classementReglementaireCategorie'], equals('Troisième catégorie'));
    });

    test('Historical legacy mission without classementReglementaire loads without crash and infers parent', () {
      // Données historiques legacy
      final legacyJson = {
        'id': 'legacy_1',
        'nomClient': 'Client Historique',
        'status': 'en_cours',
        'classementReglementaireType': 'J',
        'classementReglementaireCategorie': '1ère catégorie',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final mission = Mission.fromJson(legacyJson);
      expect(mission.classementReglementaire, isNull);
      expect(mission.classementReglementaireType, equals('J'));
      expect(mission.classementReglementaireCategorie, equals('1ère catégorie'));

      // Inférence intelligente
      final inferred = RegulatoryClassificationService.inferClassificationFromLegacy(
        type: mission.classementReglementaireType,
        category: mission.classementReglementaireCategorie,
      );
      expect(inferred, equals(RegulatoryClassificationService.erpGeneraux));
    });
  });
}
