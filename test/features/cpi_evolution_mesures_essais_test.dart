import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/features/mesures_essais/data/mappers/mesures_essais_mapper.dart';
import 'package:inspec_app/services/hive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cpi_evolution_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async => tempDir.path,
    );
    Hive.init(tempDir.path);
    await HiveService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('Évolution Test CPI dans Mesures et Essais', () {
    const testMissionId = 'mission_cpi_evolution_001';

    test('1. Modèle CpiTest, toMap / fromMap et copyWith préservent fidèlement toutes les données', () {
      final now = DateTime.utc(2026, 9, 8, 10, 0, 0);
      final model = CpiTest(
        id: 'cpi_101',
        equipmentId: 'eq_tgbt_01',
        equipmentNom: 'TGBT PRINCIPAL',
        repere: 'LOCAL TGBT',
        zone: 'ZONE USINE',
        transformateurId: 'tr_001',
        transformateurNom: 'TR1 630kVA',
        cpi: 'VIGILOHM XM200',
        essaiDeclenchement: 'Conforme',
        reportAlarme: 'Fonctionnel',
        createdAt: now,
        updatedAt: now,
      );

      final map = model.toMap();
      expect(map['id'], equals('cpi_101'));
      expect(map['equipmentId'], equals('eq_tgbt_01'));
      expect(map['equipmentNom'], equals('TGBT PRINCIPAL'));
      expect(map['repere'], equals('LOCAL TGBT'));
      expect(map['zone'], equals('ZONE USINE'));
      expect(map['transformateurId'], equals('tr_001'));
      expect(map['transformateurNom'], equals('TR1 630kVA'));
      expect(map['cpi'], equals('VIGILOHM XM200'));
      expect(map['essaiDeclenchement'], equals('Conforme'));
      expect(map['reportAlarme'], equals('Fonctionnel'));

      final restored = CpiTest.fromMap(map);
      expect(restored.id, equals(model.id));
      expect(restored.equipmentId, equals(model.equipmentId));
      expect(restored.equipmentNom, equals(model.equipmentNom));
      expect(restored.cpi, equals(model.cpi));
      expect(restored.essaiDeclenchement, equals(model.essaiDeclenchement));
      expect(restored.reportAlarme, equals(model.reportAlarme));

      final copied = model.copyWith(cpi: 'BENDER EDS460', essaiDeclenchement: 'Non conforme');
      expect(copied.cpi, equals('BENDER EDS460'));
      expect(copied.essaiDeclenchement, equals('Non conforme'));
      expect(copied.reportAlarme, equals('Fonctionnel'));
    });

    test('2. MesuresEssais intègre cpiTests et le mappe fidèlement dans MesuresEssaisEntity', () {
      final test1 = CpiTest(
        id: 'cpi_1',
        equipmentId: 'eq_1',
        cpi: 'Bender ISOMETER',
        essaiDeclenchement: 'Conforme',
        reportAlarme: 'Fonctionnel',
      );
      final test2 = CpiTest(
        id: 'cpi_2',
        equipmentId: 'eq_2',
        cpi: 'Schneider Vigilohm',
        essaiDeclenchement: 'Non Conforme',
        reportAlarme: 'Non Fonctionnel',
      );

      final mesures = MesuresEssais(
        missionId: testMissionId,
        updatedAt: DateTime.now(),
        cpiTests: [test1, test2],
      );

      final entity = MesuresEssaisMapper.toEntity(mesures);
      expect(entity.cpiTests.length, equals(2));
      expect(entity.cpiTests[0].cpi, equals('Bender ISOMETER'));
      expect(entity.cpiTests[1].cpi, equals('Schneider Vigilohm'));

      final backToModel = MesuresEssaisMapper.toModel(entity);
      expect(backToModel.cpiTests.length, equals(2));
      expect(backToModel.cpiTests[0].cpi, equals('Bender ISOMETER'));
      expect(backToModel.cpiTests[1].cpi, equals('Schneider Vigilohm'));
    });

    test('3. Filtrage dynamique d\'éligibilité : Régime IT vs TT/TN et Antériorité historique', () async {
      // Configuration de transformateurs
      final transfoIT = TransformateurMTBT(
        typeTransformateur: 'HUILE',
        marqueAnnee: 'SCHNEIDER 2022',
        puissanceAssignee: '800 kVA',
        tensionPrimaireSecondaire: '20kV / 400V',
        relaisBuchholz: 'Oui',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'IT',
        nom: 'TRANSFO IT USINE',
        syncId: 'transfo_it_id',
      );

      final transfoTN = TransformateurMTBT(
        typeTransformateur: 'SEC',
        marqueAnnee: 'ABB 2021',
        puissanceAssignee: '630 kVA',
        tensionPrimaireSecondaire: '20kV / 400V',
        relaisBuchholz: 'Non',
        typeRefroidissement: 'AN',
        regimeNeutre: 'TN-S',
        nom: 'TRANSFO TN ATELIER',
        syncId: 'transfo_tn_id',
      );

      final localMT = MoyenneTensionLocal(
        nom: 'LOCAL TRANSFOS',
        type: 'POSTE',
        transformateurs: [transfoIT, transfoTN],
      );

      // Équipement A: Relié au transfo IT -> DOIT ÊTRE ÉLIGIBLE
      final coffretIT = CoffretArmoire(
        qrCode: 'QR_IT_01',
        nom: 'TGBT SECONDAIRE IT',
        type: 'TGBT',
        alimenteeParTransformateur: true,
        transformateurId: 'transfo_it_id',
        transformateurNomComplet: 'TRANSFO IT USINE',
      );

      // Équipement B: Relié au transfo TN -> NE DOIT PAS ÊTRE ÉLIGIBLE
      final coffretTN = CoffretArmoire(
        qrCode: 'QR_TN_01',
        nom: 'ARMOIRE FORCE TN',
        type: 'ARMOIRE',
        alimenteeParTransformateur: true,
        transformateurId: 'transfo_tn_id',
        transformateurNomComplet: 'TRANSFO TN ATELIER',
      );

      // Équipement C: Sans transfo, créé AVANT la date de bascule (historique) -> DOIT ÊTRE ÉLIGIBLE
      final coffretHistorique = CoffretArmoire(
        qrCode: 'QR_HIST_01',
        nom: 'COFFRET ANCIEN HISTORIQUE',
        type: 'COFFRET',
        createdAt: DateTime.utc(2026, 9, 1), // Avant kCpiEvolutionCutoff (2026-09-08)
      );

      // Équipement D: Sans transfo, créé APRÈS la date de bascule (nouveau) -> NE DOIT PAS ÊTRE ÉLIGIBLE
      final coffretNouveauSansTransfo = CoffretArmoire(
        qrCode: 'QR_NEW_01',
        nom: 'COFFRET RECENT RECU',
        type: 'COFFRET',
        createdAt: DateTime.utc(2026, 9, 15), // Après kCpiEvolutionCutoff
      );

      final audit = AuditInstallationsElectriques(
        missionId: testMissionId,
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [localMT],
        moyenneTensionZones: [],
        basseTensionZones: [
          BasseTensionZone(
            nom: 'ZONE PRODUCTION',
            coffretsDirects: [
              coffretIT,
              coffretTN,
              coffretHistorique,
              coffretNouveauSansTransfo,
            ],
            locaux: [],
          ),
        ],
      );

      await HiveService.saveAuditInstallations(audit);

      // Appel de la méthode d'éligibilité
      final eligible = HiveService.getCpiEligibleEquipementsForMission(testMissionId);
      final eligibleIds = eligible.map((e) => e.id).toSet();

      // Vérifications rigoureuses
      expect(eligibleIds.contains('QR_IT_01'), isTrue,
          reason: 'L\'équipement relié au transformateur en régime IT doit être éligible');
      expect(eligibleIds.contains('QR_TN_01'), isFalse,
          reason: 'L\'équipement relié au transformateur en régime TN ne doit PAS être éligible');
      expect(eligibleIds.contains('QR_HIST_01'), isTrue,
          reason: 'L\'équipement historique créé avant la date de bascule doit rester éligible');
      expect(eligibleIds.contains('QR_NEW_01'), isFalse,
          reason: 'Le nouvel équipement créé après bascule sans transfo IT ne doit PAS être éligible');

      final itEquip = eligible.firstWhere((e) => e.id == 'QR_IT_01');
      expect(itEquip.isHistorical, isFalse);
      expect(itEquip.transformateurNom, equals('TRANSFO IT USINE'));

      final histEquip = eligible.firstWhere((e) => e.id == 'QR_HIST_01');
      expect(histEquip.isHistorical, isTrue);
      expect(histEquip.transformateurId, isNull);
    });

    test('4. Opérations CRUD complètes sur CpiTest via HiveService sans altération des coffrets audités', () async {
      // 1. Ajout de tests CPI
      final testA = CpiTest(
        id: 'cpi_crud_01',
        equipmentId: 'QR_IT_01',
        equipmentNom: 'TGBT SECONDAIRE IT',
        cpi: 'Bender 470',
        essaiDeclenchement: 'Conforme',
        reportAlarme: 'Fonctionnel',
        createdAt: DateTime.now(),
      );

      final testB = CpiTest(
        id: 'cpi_crud_02',
        equipmentId: 'QR_HIST_01',
        equipmentNom: 'COFFRET ANCIEN HISTORIQUE',
        cpi: 'Vigilohm XM',
        essaiDeclenchement: 'Sans objet',
        reportAlarme: 'Sans objet',
        createdAt: DateTime.now(),
      );

      final addResultA = await HiveService.addCpiTest(missionId: testMissionId, test: testA);
      final addResultB = await HiveService.addCpiTest(missionId: testMissionId, test: testB);
      expect(addResultA, isTrue);
      expect(addResultB, isTrue);

      // Lecture
      var tests = HiveService.getCpiTestsForMission(testMissionId);
      expect(tests.length, equals(2));
      expect(tests.any((t) => t.id == 'cpi_crud_01'), isTrue);
      expect(tests.any((t) => t.id == 'cpi_crud_02'), isTrue);

      // 2. Modification d'un test
      final updatedA = CpiTest(
        id: 'cpi_crud_01',
        equipmentId: 'QR_IT_01',
        equipmentNom: 'TGBT SECONDAIRE IT MODIFIÉ',
        cpi: 'Bender 470 Mis à jour',
        essaiDeclenchement: 'Non Conforme',
        reportAlarme: 'Non Fonctionnel',
      );

      final updateResult = await HiveService.updateCpiTest(missionId: testMissionId, test: updatedA);
      expect(updateResult, isTrue);

      tests = HiveService.getCpiTestsForMission(testMissionId);
      final testAUpdated = tests.firstWhere((t) => t.id == 'cpi_crud_01');
      expect(testAUpdated.cpi, equals('Bender 470 Mis à jour'));
      expect(testAUpdated.essaiDeclenchement, equals('Non Conforme'));

      // 3. Suppression d'un test
      final deleteResult = await HiveService.deleteCpiTest(missionId: testMissionId, testId: 'cpi_crud_01');
      expect(deleteResult, isTrue);

      tests = HiveService.getCpiTestsForMission(testMissionId);
      expect(tests.length, equals(1));
      expect(tests.first.id, equals('cpi_crud_02'));

      // 4. VÉRIFICATION D'INTÉGRITÉ : L'équipement d'origine existe toujours intact dans l'audit !
      final auditAfter = HiveService.getAuditInstallationsByMissionId(testMissionId);
      expect(auditAfter, isNotNull);
      final allCoffrets = auditAfter!.basseTensionZones.expand((z) => z.coffretsDirects).toList();
      expect(allCoffrets.any((c) => c.qrCode == 'QR_IT_01'), isTrue,
          reason: 'La suppression d\'un test CPI ne doit JAMAIS impacter l\'armoire / coffret audité');
    });

    test('5. Rétrocompatibilité : description_installations.cpi historique reste accessible', () {
      final desc = DescriptionInstallations(
        missionId: 'mission_retro_01',
        cpi: [
          InstallationItem(
            id: 'old_cpi_1',
            data: {
              'N°': '1',
              'Zone': 'Atelier',
              'Repère': 'Poste 1',
              'Transformateur': 'TR1',
              'Armoire': 'TGBT',
              'CPI': 'Ancien CPI Vigilohm',
              'Essais de déclenchement': 'Conforme',
              'Vérification du report d\'alarme': 'Fonctionnel',
            },
          ),
        ],
      );

      expect(desc.cpi, isNotNull);
      expect(desc.cpi.length, equals(1));
      expect(desc.cpi[0].data['CPI'], equals('Ancien CPI Vigilohm'));
    });
  });
}
