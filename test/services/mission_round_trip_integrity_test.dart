import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/features/mission/data/mappers/mission_mapper.dart';
import 'package:inspec_app/features/mission/domain/entities/mission_entity.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupService Forensic Integrity & Round-Trip Tests', () {
    test('1. _fixPathsRecursively re-routes audit_photos, client_logos, client_qrcodes correctly', () {
      const targetAppDir = '/data/user/0/com.kes.inspec_app/app_flutter';
      final sampleData = {
        'mission': {
          'id': 'm_test_1',
          'logoClient': '/old/device/path/client_logos/logo_entreprise.png',
          'qrCodeClient': r'C:\OldWindows\client_qrcodes\qr_site.png',
        },
        'audit': {
          'photos': [
            '/storage/emulated/0/Android/data/audit_photos/overview.jpg',
            '/storage/emulated/0/Android/data/audit_photos/sub_dir/detail.jpg',
          ],
          'unrelated_text': 'Texte normal sans chemin',
        },
        'coffret': {
          'photo': r'D:\OldPath\audit_photos\coffret_1.jpg',
        }
      };

      final fixed = BackupService.testFixPathsRecursively(sampleData, targetAppDir) as Map<String, dynamic>;

      // Vérification client_logos
      final logo = fixed['mission']['logoClient'] as String;
      expect(logo.startsWith(targetAppDir), isTrue);
      expect(logo.contains('client_logos'), isTrue);
      expect(logo.endsWith('logo_entreprise.png'), isTrue);

      // Vérification client_qrcodes
      final qr = fixed['mission']['qrCodeClient'] as String;
      expect(qr.startsWith(targetAppDir), isTrue);
      expect(qr.contains('client_qrcodes'), isTrue);
      expect(qr.endsWith('qr_site.png'), isTrue);

      // Vérification audit_photos dans une liste
      final auditPhotos = fixed['audit']['photos'] as List;
      expect(auditPhotos[0].toString().startsWith(targetAppDir), isTrue);
      expect(auditPhotos[0].toString().endsWith('overview.jpg'), isTrue);
      expect(auditPhotos[1].toString().startsWith(targetAppDir), isTrue);
      expect(auditPhotos[1].toString().endsWith('sub_dir/detail.jpg'), isTrue);

      // Vérification audit_photos Windows path
      final coffretPhoto = fixed['coffret']['photo'] as String;
      expect(coffretPhoto.startsWith(targetAppDir), isTrue);
      expect(coffretPhoto.endsWith('coffret_1.jpg'), isTrue);

      // Vérification que le texte normal n'a pas été altéré
      expect(fixed['audit']['unrelated_text'], equals('Texte normal sans chemin'));
    });

    test('2. CoffretArmoire Round-Trip: ID, NumeroEquipement, Départs, Parafoudres enrichis', () {
      final now = DateTime.now();
      final original = CoffretArmoire(
        id: 'coffret_stable_uuid_9999',
        qrCode: 'QR_COFFRET_9999',
        numeroEquipement: '42',
        nom: 'TGBT Principal Distribution',
        type: 'TGBT',
        statut: 'complet',
        sourceEquipementId: 'transfo_source_1',
        sourceNomComplet: 'Transfo TR1 MT/BT',
        sourceDepartId: 'depart_bt_01',
        createdAt: now,
        updatedAt: now,
        observationsParafoudreEnrichies: [
          ElementControle(
            elementControle: 'Parafoudre Type 1+2',
            conforme: false,
            observation: 'Cartouche rouge défectueuse à remplacer',
            priorite: 1,
            familleRisque: 'Risque Foudre / Surtension',
            criticite: 'Critique',
            referenceNormative: 'NF C 15-100 §443',
          ),
        ],
        departures: [
          DepartEquipement(
            id: 'dep_01',
            identification: 'Départ Climatisation T1',
            typeProtection: 'Disjoncteur',
            calibre: '63A',
            sectionCable: '16mm²',
            courbe: 'D',
            ddr: '300mA',
          ),
        ],
        terminalCircuits: [
          CircuitTerminalEquipement(
            id: 'circ_01',
            identification: 'Circuit Éclairage Hall',
            typeProtection: 'Disjoncteur',
            calibre: '16A',
            sectionCable: '2.5mm²',
            courbe: 'C',
            ddr: '30mA',
          ),
        ],
        pointsVerification: [
          PointVerification(
            pointVerification: 'Accessibilité et repérage',
            conformite: 'non',
            criticite: 'Majeure',
            familleRisque: 'Sécurité des personnes',
            priorite: 2,
            observations: [
              ElementControle(
                elementControle: 'Plastron manquant',
                conforme: false,
                observation: 'Conducteurs nus accessibles au toucher',
                criticite: 'Critique',
                familleRisque: 'Contact direct',
              ),
            ],
          ),
        ],
      );

      // Sérialisation
      final serialized = BackupService.testSerializeCoffret(original);

      // Désérialisation
      final deserializedList = BackupService.testParseCoffrets([serialized]);
      expect(deserializedList.length, equals(1));
      final deserialized = deserializedList.first;

      // Assertions d'intégrité absolue (A == B)
      expect(deserialized.id, equals('coffret_stable_uuid_9999'));
      expect(deserialized.qrCode, equals('QR_COFFRET_9999'));
      expect(deserialized.numeroEquipement, equals('42'));
      expect(deserialized.nom, equals('TGBT Principal Distribution'));
      expect(deserialized.sourceEquipementId, equals('transfo_source_1'));
      expect(deserialized.sourceNomComplet, equals('Transfo TR1 MT/BT'));
      expect(deserialized.sourceDepartId, equals('depart_bt_01'));

      // Observations parafoudre enrichies
      expect(deserialized.observationsParafoudreEnrichies, isNotNull);
      expect(deserialized.observationsParafoudreEnrichies!.length, equals(1));
      final para = deserialized.observationsParafoudreEnrichies!.first;
      expect(para.familleRisque, equals('Risque Foudre / Surtension'));
      expect(para.criticite, equals('Critique'));
      expect(para.observation, equals('Cartouche rouge défectueuse à remplacer'));

      // Départs
      expect(deserialized.departures, isNotNull);
      expect(deserialized.departures!.length, equals(1));
      expect(deserialized.departures!.first.id, equals('dep_01'));
      expect(deserialized.departures!.first.identification, equals('Départ Climatisation T1'));
      expect(deserialized.departures!.first.calibre, equals('63A'));

      // Circuits terminaux
      expect(deserialized.terminalCircuits, isNotNull);
      expect(deserialized.terminalCircuits!.length, equals(1));
      expect(deserialized.terminalCircuits!.first.id, equals('circ_01'));
      expect(deserialized.terminalCircuits!.first.calibre, equals('16A'));

      // Points de vérification et sous-observations
      expect(deserialized.pointsVerification.length, equals(1));
      final point = deserialized.pointsVerification.first;
      expect(point.criticite, equals('Majeure'));
      expect(point.familleRisque, equals('Sécurité des personnes'));
      expect(point.observations, isNotNull);
      expect(point.observations!.length, equals(1));
      expect(point.observations!.first.elementControle, equals('Plastron manquant'));
      expect(point.observations!.first.criticite, equals('Critique'));
      expect(point.observations!.first.familleRisque, equals('Contact direct'));
    });

    test('3. Cellule Round-Trip: syncId, tensionService, observations avec famille/criticité', () {
      final now = DateTime.now();
      final original = Cellule(
        nom: 'Cellule Arrivée HTA 1',
        fonction: 'Arrivée',
        type: 'Interrupteur',
        marqueModeleAnnee: 'Schneider SM6 2019',
        tensionAssignee: '24 kV',
        pouvoirCoupure: '16 kA',
        numerotation: '1',
        parafoudres: 'Non',
        syncId: 'cellule_sync_8888',
        tensionService: '20 kV',
        createdAt: now,
        updatedAt: now,
        elementsVerifies: [
          ElementControle(
            elementControle: 'Verrouillage mécanique inter-cellules',
            conforme: true,
          ),
        ],
        observations: [
          ElementControle(
            elementControle: 'Indicateur de présence de tension',
            conforme: false,
            observation: 'Voyant L1 éteint',
            priorite: 2,
            familleRisque: 'Risque MT / Haute Tension',
            criticite: 'Majeure',
            referenceNormative: 'NF C 13-100',
          ),
        ],
      );

      final serialized = BackupService.testSerializeCellule(original);
      final deserialized = BackupService.testParseCellule(serialized);

      expect(deserialized.nom, equals('Cellule Arrivée HTA 1'));
      expect(deserialized.fonction, equals('Arrivée'));
      expect(deserialized.syncId, equals('cellule_sync_8888'));
      expect(deserialized.tensionService, equals('20 kV'));
      expect(deserialized.createdAt, isNotNull);
      expect(deserialized.updatedAt, isNotNull);
      expect(deserialized.observations, isNotNull);
      expect(deserialized.observations!.length, equals(1));
      final obs = deserialized.observations!.first;
      expect(obs.elementControle, equals('Indicateur de présence de tension'));
      expect(obs.familleRisque, equals('Risque MT / Haute Tension'));
      expect(obs.criticite, equals('Majeure'));
    });

    test('4. TransformateurMTBT Round-Trip: syncId, observations, dates', () {
      final now = DateTime.now();
      final original = TransformateurMTBT(
        nom: 'Transfo 1250kVA Huile',
        typeTransformateur: 'Huile',
        marqueAnnee: 'Schneider 2018',
        puissanceAssignee: '1250 kVA',
        tensionPrimaireSecondaire: '20kV / 400V',
        relaisBuchholz: 'Oui',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'TN-S',
        syncId: 'transfo_sync_7777',
        createdAt: now,
        updatedAt: now,
        elementsVerifies: [],
        observations: [
          ElementControle(
            elementControle: 'Bac de rétention d\'huile',
            conforme: false,
            observation: 'Présence d\'eau de pluie dans le bac de rétention',
            priorite: 1,
            familleRisque: 'Risque Incendie / Environnemental',
            criticite: 'Critique',
          ),
        ],
      );

      final serialized = BackupService.testSerializeTransformateur(original);
      final deserialized = BackupService.testParseTransformateur(serialized);

      expect(deserialized.nom, equals('Transfo 1250kVA Huile'));
      expect(deserialized.typeTransformateur, equals('Huile'));
      expect(deserialized.syncId, equals('transfo_sync_7777'));
      expect(deserialized.regimeNeutre, equals('TN-S'));
      expect(deserialized.observations, isNotNull);
      expect(deserialized.observations!.length, equals(1));
      expect(deserialized.observations!.first.familleRisque, equals('Risque Incendie / Environnemental'));
      expect(deserialized.observations!.first.criticite, equals('Critique'));
    });

    test('5. ObservationLibre Round-Trip: isAutoLinked, familleRisque, criticite', () {
      final now = DateTime.now();
      final original = ObservationLibre(
        texte: 'Défaut de continuité du conducteur de protection PE',
        photos: ['photo_pe_1.jpg'],
        dateCreation: now,
        dateModification: now,
        pointVerificationKey: 'pe_key_1',
        referenceNormative: 'NF C 15-100 §543',
        familleRisque: 'Mise à la terre',
        criticite: 'Majeure',
        isAutoLinked: true,
      );

      final serialized = BackupService.testSerializeObs(original);
      final list = BackupService.testParseObs([serialized]);
      expect(list.length, equals(1));
      final deserialized = list.first;

      expect(deserialized.texte, equals('Défaut de continuité du conducteur de protection PE'));
      expect(deserialized.isAutoLinked, isTrue);
      expect(deserialized.familleRisque, equals('Mise à la terre'));
      expect(deserialized.criticite, equals('Majeure'));
      expect(deserialized.referenceNormative, equals('NF C 15-100 §543'));
    });

    test('6. RenseignementsGeneraux Round-Trip: formationHabilitationElectrique, createdAt', () {
      final now = DateTime.now();
      final original = RenseignementsGeneraux(
        missionId: 'm_test_rens',
        nomSite: 'Site Principal KES',
        etablissement: 'Usine Agroalimentaire KES',
        installation: 'Poste MT + TGBT',
        activite: 'Production industrielle',
        formationHabilitationElectrique: 'Conforme - Recyclage à jour 2025',
        createdAt: now,
        updatedAt: now,
      );

      final serialized = BackupService.testSerializeRenseignements(original);
      expect(serialized['formationHabilitationElectrique'], equals('Conforme - Recyclage à jour 2025'));
      expect(serialized['createdAt'], equals(now.toIso8601String()));
    });

    test('7. _remapMissionId propagates newId to all sub-modules including lighting_inspections', () {
      final inputData = {
        'mission': {
          'id': 'old_mission_id',
          'nom_client': 'Ancien Client SARL',
        },
        'audit': {
          'missionId': 'old_mission_id',
          'notes': 'test audit',
        },
        'description_installations': {
          'missionId': 'old_mission_id',
        },
        'mesures_essais': {
          'missionId': 'old_mission_id',
        },
        'jsa': {
          'missionId': 'old_mission_id',
        },
        'renseignements_generaux': {
          'missionId': 'old_mission_id',
        },
        'lighting_inspections': [
          {'id': 'l1', 'missionId': 'old_mission_id', 'zoneName': 'Atelier 1'},
          {'id': 'l2', 'missionId': 'old_mission_id', 'zoneName': 'Bureaux'},
        ],
        'foudre_observations': [
          {'id': 'f1', 'missionId': 'old_mission_id'},
        ],
        'trash_items': [
          {'id': 't1', 'missionId': 'old_mission_id'},
        ],
      };

      final remapped = BackupService.testRemapMissionId(
        inputData,
        'old_mission_id',
        'new_mission_id_456',
        'Nouveau Client SAS',
      );

      expect(remapped['mission']['id'], equals('new_mission_id_456'));
      expect(remapped['mission']['nom_client'], equals('Nouveau Client SAS'));
      expect(remapped['audit']['missionId'], equals('new_mission_id_456'));
      expect(remapped['description_installations']['missionId'], equals('new_mission_id_456'));
      expect(remapped['mesures_essais']['missionId'], equals('new_mission_id_456'));
      expect(remapped['jsa']['missionId'], equals('new_mission_id_456'));
      expect(remapped['renseignements_generaux']['missionId'], equals('new_mission_id_456'));

      final lightings = remapped['lighting_inspections'] as List;
      expect(lightings.length, equals(2));
      expect(lightings[0]['missionId'], equals('new_mission_id_456'));
      expect(lightings[1]['missionId'], equals('new_mission_id_456'));

      final foudres = remapped['foudre_observations'] as List;
      expect(foudres[0]['missionId'], equals('new_mission_id_456'));
    });

    test('8. MissionEntity & MissionMapper preserve afficherTableauFoudre bidirectionally', () {
      final now = DateTime.now();
      final entity = MissionEntity(
        id: 'mission_foudre_test',
        nomClient: 'Industrie Foudre SAS',
        status: 'en_cours',
        afficherTableauFoudre: true,
        createdAt: now,
        updatedAt: now,
      );

      // Entity -> Model
      final model = MissionMapper.toModel(entity);
      expect(model.afficherTableauFoudre, isTrue);

      // Model -> Entity
      final roundTripEntity = MissionMapper.toEntity(model);
      expect(roundTripEntity.afficherTableauFoudre, isTrue);

      // Test avec false
      final entityFalse = MissionEntity(
        id: 'mission_foudre_test_2',
        nomClient: 'Industrie Foudre SAS',
        status: 'en_cours',
        afficherTableauFoudre: false,
        createdAt: now,
        updatedAt: now,
      );
      final modelFalse = MissionMapper.toModel(entityFalse);
      expect(modelFalse.afficherTableauFoudre, isFalse);
      expect(MissionMapper.toEntity(modelFalse).afficherTableauFoudre, isFalse);
    });
  });
}
