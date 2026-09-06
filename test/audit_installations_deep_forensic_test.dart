import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/persistence_queue.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_deep_forensic_test_');
    Hive.init(tempDir.path);
    HiveService.registerAdapters();
    await Hive.openBox<Mission>('missions');
    await Hive.openBox<DescriptionInstallations>('description_installations');
    await Hive.openBox<AuditInstallationsElectriques>('audit_installations_electriques');
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Deep Forensic Hardening Tests - Zones, Locals & Equipment Hierarchy', () {
    test('PersistenceQueue Reentrancy: Nested enqueue calls must not deadlock', () async {
      const key = 'test_reentrancy_lock';
      bool innerExecuted = false;

      final result = await PersistenceQueue.enqueue(key, () async {
        // Nested enqueue with the same key
        final innerResult = await PersistenceQueue.enqueue(key, () async {
          innerExecuted = true;
          return 42;
        });
        return innerResult * 2;
      });

      expect(innerExecuted, isTrue);
      expect(result, equals(84));
    });

    test('Local Renaming without Duplication: Renaming a local preserves ID and children without duplicating', () async {
      const missionId = 'mission_rename_test';
      final missionBox = Hive.box<Mission>('missions');
      await missionBox.put(
        missionId,
        Mission(
          id: missionId,
          nomClient: 'Client Rename',
          status: 'en_cours',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final audit = await HiveService.getOrCreateAuditInstallations(missionId);
      final zone = BasseTensionZone(nom: 'Zone Principale');
      final local = BasseTensionLocal(nom: 'Ancien Nom Local', type: 'LOCAL_TGBT');
      final localId = local.localId;

      final coffret = CoffretArmoire(
        qrCode: 'QR_RENAME_01',
        nom: 'Armoire Climatisation',
        type: 'Armoire',
      );
      local.coffrets.add(coffret);
      zone.locaux.add(local);
      audit.basseTensionZones.add(zone);
      await HiveService.saveAuditInstallations(audit);

      // Verify initial setup
      var loadedAudit = await HiveService.getOrCreateAuditInstallations(missionId);
      expect(loadedAudit.basseTensionZones.first.locaux.length, equals(1));
      expect(loadedAudit.basseTensionZones.first.locaux.first.nom, equals('Ancien Nom Local'));
      expect(loadedAudit.basseTensionZones.first.locaux.first.coffrets.length, equals(1));

      // Now rename the local to "Nouveau Nom TGBT"
      final updatedLocal = BasseTensionLocal(
        id: localId,
        nom: 'Nouveau Nom TGBT',
        type: 'LOCAL_TGBT',
        coffrets: [], // simulate screen passing empty/stale coffrets list
      );

      final success = await HiveService.updateLocalById(
        missionId: missionId,
        localId: localId,
        updatedLocal: updatedLocal,
        isMoyenneTension: false,
        zoneId: zone.zoneId,
      );

      expect(success, isTrue);

      // Verify that local was renamed in-place, NOT duplicated
      loadedAudit = await HiveService.getOrCreateAuditInstallations(missionId);
      final z = loadedAudit.basseTensionZones.first;
      expect(z.locaux.length, equals(1), reason: 'Local must not be duplicated on rename');
      expect(z.locaux.first.nom, equals('Nouveau Nom TGBT'));
      expect(z.locaux.first.localId, equals(localId));
      expect(z.locaux.first.coffrets.length, equals(1), reason: 'Existing coffrets must be preserved');
      expect(z.locaux.first.coffrets.first.nom, equals('Armoire Climatisation'));
    });

    test('Stale Zone Snapshot Protection: Updating a zone preserves newly added locals in DB', () async {
      const missionId = 'mission_zone_protect_test';
      final missionBox = Hive.box<Mission>('missions');
      await missionBox.put(
        missionId,
        Mission(
          id: missionId,
          nomClient: 'Client Zone Protect',
          status: 'en_cours',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final audit = await HiveService.getOrCreateAuditInstallations(missionId);
      final zone = BasseTensionZone(nom: 'Zone Production');
      final zoneId = zone.zoneId;

      final local1 = BasseTensionLocal(nom: 'Local Machine 1', type: 'Technique');
      final local2 = BasseTensionLocal(nom: 'Local Machine 2', type: 'Technique');
      final coffretDirect = CoffretArmoire(
        qrCode: 'QR_DIRECT_01',
        nom: 'Coffret Direct Pompes',
        type: 'Coffret',
      );

      zone.locaux.addAll([local1, local2]);
      zone.coffretsDirects.add(coffretDirect);
      audit.basseTensionZones.add(zone);
      await HiveService.saveAuditInstallations(audit);

      // Now simulate a zone edit screen which was opened before locals were added,
      // having locaux: [] and coffretsDirects: [].
      final staleZoneSnapshot = BasseTensionZone(
        id: zoneId,
        nom: 'Zone Production - Renommée',
        locaux: [],
        coffretsDirects: [],
      );

      final success = await HiveService.updateZoneById(
        missionId: missionId,
        zoneId: zoneId,
        updatedZone: staleZoneSnapshot,
        isMoyenneTension: false,
      );

      expect(success, isTrue);

      final loadedAudit = await HiveService.getOrCreateAuditInstallations(missionId);
      final updatedZone = loadedAudit.basseTensionZones.firstWhere((z) => z.zoneId == zoneId);

      expect(updatedZone.nom, equals('Zone Production - Renommée'));
      expect(updatedZone.locaux.length, equals(2), reason: 'Child locaux must not be wiped out by stale zone update');
      expect(updatedZone.coffretsDirects.length, equals(1), reason: 'Direct coffrets must not be wiped out');
    });

    test('ID-aware Local Deletion: Deleting a local by ID succeeds even when order changes', () async {
      const missionId = 'mission_local_delete_test';
      final audit = await HiveService.getOrCreateAuditInstallations(missionId);
      final zone = BasseTensionZone(nom: 'Zone Stockage');
      final localA = BasseTensionLocal(nom: 'Local A', type: 'Stockage');
      final localB = BasseTensionLocal(nom: 'Local B', type: 'Stockage');
      final localC = BasseTensionLocal(nom: 'Local C', type: 'Stockage');

      zone.locaux.addAll([localA, localB, localC]);
      audit.basseTensionZones.add(zone);
      await HiveService.saveAuditInstallations(audit);

      // Delete Local B by its ID
      final success = await HiveService.deleteLocalFromZone(
        missionId: missionId,
        isMoyenneTension: false,
        zoneId: zone.zoneId,
        localId: localB.localId,
      );

      expect(success, isTrue);

      final loadedAudit = await HiveService.getOrCreateAuditInstallations(missionId);
      final remainingLocaux = loadedAudit.basseTensionZones.firstWhere((z) => z.zoneId == zone.zoneId).locaux;
      expect(remainingLocaux.length, equals(2));
      expect(remainingLocaux.any((l) => l.localId == localB.localId), isFalse);
      expect(remainingLocaux.any((l) => l.localId == localA.localId), isTrue);
      expect(remainingLocaux.any((l) => l.localId == localC.localId), isTrue);
    });

    test('High Concurrency Stress: 20 simultaneous writes through PersistenceQueue retain data integrity', () async {
      const missionId = 'mission_concurrency_stress';
      final audit = await HiveService.getOrCreateAuditInstallations(missionId);
      final zone = BasseTensionZone(nom: 'Zone Concurrence');
      audit.basseTensionZones.add(zone);
      await HiveService.saveAuditInstallations(audit);

      final futures = <Future<bool>>[];
      for (int i = 0; i < 20; i++) {
        final local = BasseTensionLocal(
          nom: 'Local Concurrent $i',
          type: 'Type_$i',
        );
        futures.add(
          HiveService.updateLocalById(
            missionId: missionId,
            localId: local.localId,
            updatedLocal: local,
            isMoyenneTension: false,
            zoneId: zone.zoneId,
          ),
        );
      }

      final results = await Future.wait(futures);
      expect(results.every((r) => r == true), isTrue);

      final loadedAudit = await HiveService.getOrCreateAuditInstallations(missionId);
      final z = loadedAudit.basseTensionZones.firstWhere((z) => z.zoneId == zone.zoneId);
      expect(z.locaux.length, equals(20), reason: 'All 20 concurrent local creations must be preserved in sequence');
    });
  });
}
