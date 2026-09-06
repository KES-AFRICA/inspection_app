import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/hive_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_forensic_test_');
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

  group('Forensic Stress & Data Integrity Tests - Départs & Circuits', () {
    test('Stress Test: Progressive insertion of 10, 50, 100, 250, 500, 1000 départs & circuits', () async {
      const missionId = 'mission_stress_01';
      final missionBox = Hive.box<Mission>('missions');
      final mission = Mission(
        id: missionId,
        nomClient: 'Client Test Forensic',
        status: 'en_cours',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await missionBox.put(missionId, mission);

      final audit = await HiveService.getOrCreateAuditInstallations(missionId);
      final local = BasseTensionLocal(nom: 'Local TGBT Principal', type: 'Technique');
      final coffret = CoffretArmoire(
        qrCode: 'QR_STRESS_01',
        nom: 'TGBT-STRESS-PRINCIPAL',
        type: 'TGBT',
      );
      local.coffrets.add(coffret);
      final zone = BasseTensionZone(nom: 'Zone Usine', locaux: [local]);
      audit.basseTensionZones.add(zone);
      await HiveService.saveAuditInstallations(audit);

      final tiers = [10, 50, 100, 250, 500, 1000];
      for (final targetCount in tiers) {
        final stopwatch = Stopwatch()..start();
        final departures = <DepartEquipement>[];
        final circuits = <CircuitTerminalEquipement>[];

        for (int i = 0; i < targetCount; i++) {
          departures.add(DepartEquipement(
            id: 'dep_${targetCount}_$i',
            identification: 'Départ Ligne $i Atelier Nord Usine Machine $i',
            typeProtection: 'Disjoncteur',
            marque: 'Schneider Electric',
            courbe: 'Courbe-C',
            pdcKA: '10',
            calibre: '${10 + (i % 63)}',
            sectionCable: '16 mm²',
            sectionCableNeutre: '16 mm²',
            ddr: '300',
          ));
          circuits.add(CircuitTerminalEquipement(
            id: 'circ_${targetCount}_$i',
            identification: 'Circuit Éclairage Prise Poste $i',
            typeProtection: 'Disjoncteur différentiel',
            marque: 'Legrand',
            courbe: 'Courbe-C',
            calibre: '16',
            sectionCable: '2.5 mm²',
            sectionCableNeutre: '2.5 mm²',
            ddr: '30',
          ));
        }

        final updatedCoffret = CoffretArmoire(
          id: coffret.equipmentId,
          qrCode: coffret.qrCode,
          nom: coffret.nom,
          type: coffret.type,
          departures: departures,
          terminalCircuits: circuits,
        );

        final updateOk = await HiveService.updateCoffretById(
          missionId: missionId,
          equipmentId: coffret.equipmentId,
          updatedCoffret: updatedCoffret,
        );
        stopwatch.stop();

        expect(updateOk, isTrue);
        print('⏱️ [BENCHMARK] Tier $targetCount elements: Save took ${stopwatch.elapsedMilliseconds}ms');

        // Verify direct reload from fresh Hive lookup
        final reloadedAudit = await HiveService.getOrCreateAuditInstallations(missionId);
        final reloadedCoffret = reloadedAudit.basseTensionZones.first.locaux.first.coffrets.first;

        expect(reloadedCoffret.effectiveDepartures.length, equals(targetCount));
        expect(reloadedCoffret.effectiveTerminalCircuits.length, equals(targetCount));

        // Check specific random items to verify no data corruption
        expect(reloadedCoffret.effectiveDepartures[0].identification, equals('Départ Ligne 0 Atelier Nord Usine Machine 0'));
        expect(reloadedCoffret.effectiveDepartures[targetCount - 1].identification, equals('Départ Ligne ${targetCount - 1} Atelier Nord Usine Machine ${targetCount - 1}'));
        expect(reloadedCoffret.effectiveTerminalCircuits[targetCount - 1].identification, equals('Circuit Éclairage Prise Poste ${targetCount - 1}'));
      }
    });

    test('Forensic Bug Reproduction: Empty list replacement flaw (line 4527-4528 pattern)', () async {
      // Simulation of line 4527 in ajouter_coffret_screen.dart:
      // target.departures = (newCoffret.departures?.isNotEmpty == true || target.departures == null) ? newCoffret.departures : target.departures;
      final existingDepartures = [DepartEquipement(identification: 'Old D1')];
      final emptyNewDepartures = <DepartEquipement>[];

      // Existing faulty logic:
      final resultDepartures = (emptyNewDepartures.isNotEmpty == true || existingDepartures.isEmpty)
          ? emptyNewDepartures
          : existingDepartures;

      // Demonstrating that deleting all departures fails to persist because it retains old departures!
      expect(resultDepartures.length, equals(1), reason: 'Line 4527 flaw prevents resetting or emptying list!');
    });

    test('Forensic Concurrency Test: Rapid unsynchronized concurrent saves overwrite newer data', () async {
      const missionId = 'mission_concurrency_01';
      final missionBox = Hive.box<Mission>('missions');
      await missionBox.put(missionId, Mission(id: missionId, nomClient: 'Client Concurrency', status: 'en_cours', createdAt: DateTime.now(), updatedAt: DateTime.now()));

      final audit = await HiveService.getOrCreateAuditInstallations(missionId);
      final local = BasseTensionLocal(nom: 'Local Test', type: 'Local');
      final coffret = CoffretArmoire(qrCode: 'QR_CONC_01', nom: 'Coffret Concurrency', type: 'COFFRET');
      local.coffrets.add(coffret);
      audit.basseTensionZones.add(BasseTensionZone(nom: 'Zone 1', locaux: [local]));
      await HiveService.saveAuditInstallations(audit);

      // Simulate inspector typing rapidly or adding departures in quick succession:
      // Save 1 starts with 10 departures
      final dep10 = List.generate(10, (i) => DepartEquipement(identification: 'Dep $i'));
      // Save 2 starts with 15 departures slightly later
      final dep15 = List.generate(15, (i) => DepartEquipement(identification: 'Dep $i'));

      // Launch both concurrently without queue/mutex
      final future1 = HiveService.updateCoffretById(
        missionId: missionId,
        equipmentId: coffret.equipmentId,
        updatedCoffret: CoffretArmoire(
          id: coffret.equipmentId,
          qrCode: coffret.qrCode,
          nom: coffret.nom,
          type: coffret.type,
          departures: dep10,
        ),
      );

      final future2 = HiveService.updateCoffretById(
        missionId: missionId,
        equipmentId: coffret.equipmentId,
        updatedCoffret: CoffretArmoire(
          id: coffret.equipmentId,
          qrCode: coffret.qrCode,
          nom: coffret.nom,
          type: coffret.type,
          departures: dep15,
        ),
      );

      await Future.wait([future1, future2]);

      final checkAudit = await HiveService.getOrCreateAuditInstallations(missionId);
      final finalCoffret = checkAudit.basseTensionZones.first.locaux.first.coffrets.first;
      print('ℹ️ Concurrent save result: final departures count = ${finalCoffret.effectiveDepartures.length}');
      // Without synchronization, race condition determines whether 10 or 15 won!
    });
  });
}
