// test/features/mappers_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/features/auth/domain/entities/verificateur_entity.dart';
import 'package:inspec_app/features/auth/data/mappers/verificateur_mapper.dart';
import 'package:inspec_app/features/mission/domain/entities/mission_entity.dart';
import 'package:inspec_app/features/mission/data/mappers/mission_mapper.dart';

void main() {
  group('VerificateurMapper Tests', () {
    test('Should map Model to Entity without loss', () {
      final now = DateTime.now();
      final model = Verificateur(
        id: '1',
        nom: 'Dupont',
        prenom: 'Jean',
        email: 'jean.dupont@kes.com',
        password: 'hash',
        matricule: 'M123',
        createdAt: now,
      );

      final entity = VerificateurMapper.toEntity(model);

      expect(entity.id, model.id);
      expect(entity.nom, model.nom);
      expect(entity.prenom, model.prenom);
      expect(entity.email, model.email);
      expect(entity.password, model.password);
      expect(entity.matricule, model.matricule);
      expect(entity.createdAt, model.createdAt);
      expect(entity.fullName, 'Jean Dupont');
    });

    test('Should map Entity to Model without loss', () {
      final now = DateTime.now();
      final entity = VerificateurEntity(
        id: '1',
        nom: 'Dupont',
        prenom: 'Jean',
        email: 'jean.dupont@kes.com',
        password: 'hash',
        matricule: 'M123',
        createdAt: now,
      );

      final model = VerificateurMapper.toModel(entity);

      expect(model.id, entity.id);
      expect(model.nom, entity.nom);
      expect(model.prenom, entity.prenom);
      expect(model.email, entity.email);
      expect(model.password, entity.password);
      expect(model.matricule, entity.matricule);
      expect(model.createdAt, entity.createdAt);
    });
  });

  group('MissionMapper Tests', () {
    test('Should map Model to Entity and vice versa without loss', () {
      final now = DateTime.now();
      final model = Mission(
        id: 'M-789',
        nomClient: 'Client A',
        activiteClient: 'Electricité',
        adresseClient: '12 rue Test',
        logoClient: 'logo.png',
        accompagnateurs: ['Acc 1'],
        verificateurs: [{'nom': 'Dupont'}],
        dgResponsable: 'Directeur',
        dateIntervention: now,
        dateRapport: now,
        natureMission: 'Audit',
        periodicite: 'Annuelle',
        dureeMissionJours: 2,
        docCahierPrescriptions: true,
        docNotesCalculs: false,
        createdAt: now,
        updatedAt: now,
        status: 'en_cours',
        installation: 'BT/MT Site Nord',
        autresDocuments: ['Doc Perso'],
      );

      // model -> entity
      final entity = MissionMapper.toEntity(model);
      expect(entity.id, model.id);
      expect(entity.nomClient, model.nomClient);
      expect(entity.installation, model.installation);
      expect(entity.autresDocuments, model.autresDocuments);

      // entity -> model
      final mappedModel = MissionMapper.toModel(entity);
      expect(mappedModel.id, model.id);
      expect(mappedModel.nomClient, model.nomClient);
      expect(mappedModel.installation, model.installation);
      expect(mappedModel.autresDocuments, model.autresDocuments);
    });
  });
}
