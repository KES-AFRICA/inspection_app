import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/equipment_number_service.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'dart:io';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_equipment_number_test');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(AuditInstallationsElectriquesAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MoyenneTensionLocalAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MoyenneTensionZoneAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(BasseTensionZoneAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(BasseTensionLocalAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ElementControleAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(CelluleAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(TransformateurMTBTAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(CoffretArmoireAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(AlimentationAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(PointVerificationAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(ObservationLibreAdapter());
  });

  setUp(() async {
    if (!Hive.isBoxOpen('audit_installations_electriques')) {
      await Hive.openBox<AuditInstallationsElectriques>('audit_installations_electriques');
    }
    if (!Hive.isBoxOpen('coffret_drafts')) {
      await Hive.openBox('coffret_drafts');
    }
    await Hive.box<AuditInstallationsElectriques>('audit_installations_electriques').clear();
    await Hive.box('coffret_drafts').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Refonte Architecturale Numérotation Équipements — QA Campagne', () {
    test('Test 1 — Création simple : Séquence globale unique (Armoire, TGBT, Coffret, Inverseur)', () {
      const missionId = 'mission_test_1';
      final audit = AuditInstallationsElectriques.create(missionId);

      final c1 = CoffretArmoire(qrCode: 'QR1', nom: 'Armoire Principale', type: 'ARMOIRE');
      EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, c1, audit: audit);
      expect(c1.numeroEquipement, equals('1'));
      audit.moyenneTensionLocaux.add(MoyenneTensionLocal(type: 'TRANSFORMATEUR', nom: 'Local 1', coffrets: [c1]));

      final c2 = CoffretArmoire(qrCode: 'QR2', nom: 'TGBT Général', type: 'TGBT');
      EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, c2, audit: audit);
      expect(c2.numeroEquipement, equals('2'));
      audit.basseTensionZones.add(BasseTensionZone(nom: 'Zone 1', coffretsDirects: [c2]));

      final c3 = CoffretArmoire(qrCode: 'QR3', nom: 'Coffret Secondaire', type: 'COFFRET');
      EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, c3, audit: audit);
      expect(c3.numeroEquipement, equals('3'));
      audit.basseTensionZones.first.coffretsDirects.add(c3);

      final c4 = CoffretArmoire(qrCode: 'QR4', nom: 'Inverseur Normal/Secours', type: 'INVERSEUR');
      EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, c4, audit: audit);
      expect(c4.numeroEquipement, equals('4'));

      expect(c1.numeroEquipement, equals('1'));
      expect(c2.numeroEquipement, equals('2'));
      expect(c3.numeroEquipement, equals('3'));
      expect(c4.numeroEquipement, equals('4'));
    });

    test('Test 2 — Création successive : Séquence continue sur 100 équipements', () async {
      const missionId = 'mission_test_2';
      final box = Hive.box<AuditInstallationsElectriques>('audit_installations_electriques');
      final audit = AuditInstallationsElectriques.create(missionId);
      await box.add(audit);

      final local = MoyenneTensionLocal(type: 'TRANSFORMATEUR', nom: 'Local MT', coffrets: []);
      audit.moyenneTensionLocaux.add(local);

      for (int i = 1; i <= 100; i++) {
        final c = CoffretArmoire(qrCode: 'QR_$i', nom: 'Équipement $i', type: 'ARMOIRE');
        EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, c, audit: audit);
        expect(c.numeroEquipement, equals(i.toString()));
        local.coffrets.add(c);
      }

      final nextNum = EquipmentNumberService.getNextEquipmentNumber(missionId);
      expect(nextNum, equals(101));
    });

    test('Test 3 — Brouillon abandonné : Aucun doublon lors de la création suivante', () async {
      const missionId = 'mission_test_3';
      final draftBox = Hive.box('coffret_drafts');

      // 1. Équipement 1 sauvegardé
      final c1 = CoffretArmoire(qrCode: 'QR1', nom: 'Coffret 1', type: 'COFFRET');
      EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, c1);
      expect(c1.numeroEquipement, equals('1'));

      final audit = AuditInstallationsElectriques.create(missionId);
      audit.moyenneTensionLocaux.add(MoyenneTensionLocal(type: 'TRANSFORMATEUR', nom: 'Local 1', coffrets: [c1]));
      await Hive.box<AuditInstallationsElectriques>('audit_installations_electriques').add(audit);

      // 2. Brouillon 2 créé
      final draft2 = CoffretArmoire(qrCode: 'TEMP_DRAFT_2', nom: 'Brouillon 2', type: 'COFFRET');
      EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, draft2);
      expect(draft2.numeroEquipement, equals('2'));
      await draftBox.put('TEMP_DRAFT_2', {
        'missionId': missionId,
        'coffret': draft2,
      });

      // 3. Prochain numéro généré prend en compte le brouillon
      final nextNum = EquipmentNumberService.getNextEquipmentNumber(missionId);
      expect(nextNum, equals(3));

      // 4. Abandon du brouillon 2
      await draftBox.delete('TEMP_DRAFT_2');

      // 5. Nouvel équipement 3 prend le numéro séquentiel sans doublon avec 1
      final c3 = CoffretArmoire(qrCode: 'QR3', nom: 'Coffret 3', type: 'COFFRET');
      EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, c3);
      expect(c3.numeroEquipement, equals('2'));
      expect(c3.numeroEquipement, isNot(equals(c1.numeroEquipement)));
    });

    test('Test 4 — Résistance à la suppression : Suppression de #5 ne renumérote pas les autres', () {
      const missionId = 'mission_test_4';
      final audit = AuditInstallationsElectriques.create(missionId);
      final local = MoyenneTensionLocal(type: 'TRANSFORMATEUR', nom: 'Local 1', coffrets: []);
      audit.moyenneTensionLocaux.add(local);

      final coffrets = <CoffretArmoire>[];
      for (int i = 1; i <= 10; i++) {
        final c = CoffretArmoire(qrCode: 'QR_$i', nom: 'Équipement $i', type: 'COFFRET');
        EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, c, audit: audit);
        coffrets.add(c);
        local.coffrets.add(c);
      }

      // Supprimer l'équipement #5 (index 4)
      local.coffrets.removeAt(4);
      expect(local.coffrets.length, equals(9));

      // Vérifier que les numéros des équipements 1..4 et 6..10 sont intacts
      expect(local.coffrets[0].numeroEquipement, equals('1'));
      expect(local.coffrets[3].numeroEquipement, equals('4'));
      expect(local.coffrets[4].numeroEquipement, equals('6'));
      expect(local.coffrets[8].numeroEquipement, equals('10'));

      // Le prochain numéro reste séquentiel au max (11)
      final newCoffret = CoffretArmoire(qrCode: 'QR_NEW', nom: 'Nouveau Coffret', type: 'COFFRET');
      EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, newCoffret, audit: audit);
      expect(newCoffret.numeroEquipement, equals('11'));
    });

    test('Test 5 — Persistance après redémarrage simulé de Hive', () async {
      const missionId = 'mission_test_5';
      final auditBox = Hive.box<AuditInstallationsElectriques>('audit_installations_electriques');
      final audit = AuditInstallationsElectriques.create(missionId);

      for (int i = 1; i <= 5; i++) {
        final c = CoffretArmoire(qrCode: 'QR_$i', nom: 'Coffret $i', type: 'COFFRET');
        EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, c, audit: audit);
        audit.moyenneTensionLocaux.add(MoyenneTensionLocal(type: 'TRANSFORMATEUR', nom: 'L_$i', coffrets: [c]));
      }

      await auditBox.add(audit);

      // Prochain numéro avant reboot
      expect(EquipmentNumberService.getNextEquipmentNumber(missionId), equals(6));

      // Simulation redémarrage
      await auditBox.close();
      await Hive.openBox<AuditInstallationsElectriques>('audit_installations_electriques');

      // Prochain numéro après reboot
      expect(EquipmentNumberService.getNextEquipmentNumber(missionId), equals(6));
    });

    test('Test 6 — Rétrocompatibilité : Import d\'une ancienne mission avec numéros valides', () {
      const missionId = 'mission_legacy_6';
      final audit = AuditInstallationsElectriques.create(missionId);

      final c1 = CoffretArmoire(qrCode: 'QR1', nom: 'Armoire 1', type: 'ARMOIRE', numeroEquipement: '10');
      final c2 = CoffretArmoire(qrCode: 'QR2', nom: 'TGBT 2', type: 'TGBT', numeroEquipement: '20');

      audit.moyenneTensionLocaux.add(MoyenneTensionLocal(type: 'TRANSFORMATEUR', nom: 'Local', coffrets: [c1, c2]));

      final report = EquipmentNumberService.auditAndFixMissionNumbers(audit);

      expect(c1.numeroEquipement, equals('10'));
      expect(c2.numeroEquipement, equals('20'));
      expect(report.duplicatesFixed, equals(0));
      expect(report.missingNumbersFixed, equals(0));
    });

    test('Test 7 — Audit et résolution non destructive des doublons historiques', () {
      const missionId = 'mission_legacy_7';
      final audit = AuditInstallationsElectriques.create(missionId);

      // Deux équipements ont accidentellement le même numéro '5'
      final c1 = CoffretArmoire(qrCode: 'QR1', nom: 'Armoire 1', type: 'ARMOIRE', numeroEquipement: '5');
      final c2 = CoffretArmoire(qrCode: 'QR2', nom: 'Armoire 2 (Doublon)', type: 'ARMOIRE', numeroEquipement: '5');
      final c3 = CoffretArmoire(qrCode: 'QR3', nom: 'Armoire 3 (Sans Numéro)', type: 'ARMOIRE', numeroEquipement: null);

      audit.moyenneTensionLocaux.add(MoyenneTensionLocal(type: 'TRANSFORMATEUR', nom: 'Local', coffrets: [c1, c2, c3]));

      final report = EquipmentNumberService.auditAndFixMissionNumbers(audit);

      expect(report.duplicatesFixed, equals(1));
      expect(report.missingNumbersFixed, equals(1));
      expect(c1.numeroEquipement, equals('5')); // Premier conserve '5'
      expect(c2.numeroEquipement, equals('1')); // Réattribution intelligente
      expect(c3.numeroEquipement, equals('2'));
      expect(c1.equipmentId, isNotEmpty);
      expect(c2.equipmentId, isNotEmpty);
      expect(c3.equipmentId, isNotEmpty);
    });

    test('Test 8 — Immutabilité lors des éditions de champs autres', () {
      const missionId = 'mission_test_8';
      final c1 = CoffretArmoire(qrCode: 'QR1', nom: 'Armoire Initiale', type: 'ARMOIRE');
      EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, c1);
      final initialId = c1.equipmentId;
      final initialNum = c1.numeroEquipement;

      // Modification de champs métier
      c1.nom = 'Armoire Modifiée';
      c1.type = 'TGBT';
      c1.repere = 'REP-001';
      c1.zoneAtex = true;

      // Ré-exécution de la garantie
      EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, c1);

      expect(c1.equipmentId, equals(initialId));
      expect(c1.numeroEquipement, equals(initialNum));
    });

    test('Test 9 — Alternance et non-contamination entre équipements', () {
      const missionId = 'mission_test_9';
      final audit = AuditInstallationsElectriques.create(missionId);
      final local = MoyenneTensionLocal(type: 'TRANSFORMATEUR', nom: 'Local', coffrets: []);
      audit.moyenneTensionLocaux.add(local);

      final c1 = CoffretArmoire(qrCode: 'QR1', nom: 'Armoire Alpha', type: 'ARMOIRE');
      EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, c1, audit: audit);
      local.coffrets.add(c1);

      final c2 = CoffretArmoire(qrCode: 'QR2', nom: 'TGBT Beta', type: 'TGBT');
      EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, c2, audit: audit);
      local.coffrets.add(c2);

      final c3 = CoffretArmoire(qrCode: 'QR3', nom: 'Coffret Gamma', type: 'COFFRET');
      EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, c3, audit: audit);
      local.coffrets.add(c3);

      expect(c1.numeroEquipement, equals('1'));
      expect(c2.numeroEquipement, equals('2'));
      expect(c3.numeroEquipement, equals('3'));

      // Modification c1
      c1.nom = 'Armoire Alpha V2';
      expect(c2.numeroEquipement, equals('2'));
      expect(c3.numeroEquipement, equals('3'));

      // Modification c2
      c2.nom = 'TGBT Beta V2';
      expect(c1.numeroEquipement, equals('1'));
      expect(c3.numeroEquipement, equals('3'));
    });

    test('Test 10 — Gros volume (200 équipements) : Performance, unicité et persistance', () async {
      const missionId = 'mission_volume_10';
      final auditBox = Hive.box<AuditInstallationsElectriques>('audit_installations_electriques');
      final audit = AuditInstallationsElectriques.create(missionId);
      final local = MoyenneTensionLocal(type: 'TRANSFORMATEUR', nom: 'Grand Local MT', coffrets: []);
      audit.moyenneTensionLocaux.add(local);

      final numbersSet = <String>{};
      final idsSet = <String>{};

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 200; i++) {
        final c = CoffretArmoire(qrCode: 'QR_VOL_$i', nom: 'Équipement $i', type: 'COFFRET');
        EquipmentNumberService.ensureEquipmentIdentityAndNumber(missionId, c, audit: audit);
        local.coffrets.add(c);

        expect(numbersSet.add(c.numeroEquipement!), isTrue, reason: 'Numéro ${c.numeroEquipement} doit être unique.');
        expect(idsSet.add(c.equipmentId), isTrue, reason: 'ID ${c.equipmentId} doit être unique.');
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(1000), reason: 'Génération de 200 équipements doit être rapide (< 1s).');

      await auditBox.add(audit);

      final loadedAudit = auditBox.values.firstWhere((a) => a.missionId == missionId);
      expect(loadedAudit.moyenneTensionLocaux.first.coffrets.length, equals(200));

      final report = EquipmentNumberService.auditAndFixMissionNumbers(loadedAudit);
      expect(report.duplicatesFixed, equals(0));
      expect(report.missingNumbersFixed, equals(0));
    });
  });
}
