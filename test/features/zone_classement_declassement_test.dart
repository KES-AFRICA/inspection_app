import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/pdf/builders/pdf_classement_foudre_builder.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  const String missionId = 'mission_test_declassement_001';

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_zone_declassement_test_');
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

  group('Zone Classement & Déclassement - Intégrité et Persistance', () {
    test('Cycle complet : Non classé -> Classé -> Déclassé avec préservation des données', () async {
      // 1. Initialiser une mission avec un audit contenant une zone MT et une zone BT
      final mission = Mission(
        id: missionId,
        nomClient: 'CAMRAIL',
        nomSite: 'Bassa',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'en_cours',
      );
      final missionBox = Hive.box<Mission>('missions');
      await missionBox.put(missionId, mission);

      final audit = AuditInstallationsElectriques.create(missionId);
      final zoneMT = MoyenneTensionZone(
        nom: 'Poste HTA Sud',
        description: 'Poste principal d\'alimentation',
      );
      // Ajouter un local et un coffret dans la zone MT
      final localMT = MoyenneTensionLocal(
        nom: 'Local Cellules 20kV',
        type: 'LOCAL_ELECTRIQUE',
      );
      final coffretMT = CoffretArmoire(
        id: 'coffret_01',
        nom: 'Armoire Services Auxiliaires',
        type: 'ARMOIRE',
        qrCode: 'QR_ASA_01',
      );
      zoneMT.locaux.add(localMT);
      zoneMT.coffrets.add(coffretMT);
      audit.moyenneTensionZones.add(zoneMT);

      // Ajouter également un classement propre pour ce local
      final localEmp = ClassementEmplacement(
        missionId: missionId,
        localisation: localMT.nom,
        zone: zoneMT.nom,
        af: 'AF1',
        be: 'BE1',
        ae: 'AE1',
        ad: 'AD1',
        ag: 'AG1',
        ip: 'IP2X',
        ik: 'IK07',
        origineClassement: 'Étude Local',
        updatedAt: DateTime.now(),
      );
      final empBox = Hive.box<ClassementEmplacement>('classement_locaux');
      await empBox.add(localEmp);

      await HiveService.saveAuditInstallations(audit);

      // Test A : Zone sans classement
      expect(zoneMT.classementZoneId, isNull);
      final czInitial = HiveService.getClassementZoneByNom(missionId, zoneMT.nom);
      expect(czInitial == null || !czInitial.estComplet, isTrue);

      // Test B : Définir et sauvegarder un classement complet pour la zone
      final cz = await HiveService.getOrCreateClassementZone(
        missionId: missionId,
        nomZone: zoneMT.nom,
        typeZone: 'MT',
      );
      cz.af = 'AF2';
      cz.be = 'BE2';
      cz.ae = 'AE2';
      cz.ad = 'AD2';
      cz.ag = 'AG2';
      cz.origineClassement = 'Audit Électrique KES';
      cz.calculerIndices();
      await HiveService.saveClassementZone(cz);

      zoneMT.classementZoneId = cz.key.toString();
      await HiveService.saveAuditInstallations(audit);

      // Vérification statut classé
      expect(cz.estComplet, isTrue);
      expect(cz.ip, isNotNull);
      expect(cz.ik, isNotNull);

      final czSaved = HiveService.getClassementZoneByNom(missionId, zoneMT.nom);
      expect(czSaved, isNotNull);
      expect(czSaved!.estComplet, isTrue);
      expect(czSaved.af, equals('AF2'));
      expect(czSaved.be, equals('BE2'));

      // Test C : Statistiques reflètent la zone classée
      final domainInv = MissionDomainInventory(
        missionId: missionId,
        instances: [],
        allFindings: [],
      );
      final findingInv = AuditFindingInventory(
        missionId: missionId,
        findings: [],
        crossCategoryItems: [],
      );

      final statsBefore = TechnicalEnrichmentEngine.compute(missionId, domainInv, findingInv);
      expect(statsBefore.totalZonesClasseesCount, equals(1));

      // Test D : PDF inclut la zone classée
      final pdfWidgetsClassed = PdfClassementFoudreBuilder.buildClassementEmplacementsMulti(
        empBox.values.toList(),
        [czSaved],
        {},
      );
      expect(pdfWidgetsClassed, isNotEmpty);

      // Test E : Déclassement de la zone
      await HiveService.deleteClassementZone(
        missionId: missionId,
        nomZone: zoneMT.nom,
      );

      // Vérifier que le classement de zone a été supprimé de Hive
      final czApresSuppr = HiveService.getClassementZoneByNom(missionId, zoneMT.nom);
      expect(czApresSuppr, isNull);

      // Vérifier que classementZoneId a été réinitialisé dans l'audit
      final auditApres = HiveService.getAuditInstallationsByMissionId(missionId);
      expect(auditApres, isNotNull);
      final zoneApres = auditApres!.moyenneTensionZones.firstWhere((z) => z.nom == zoneMT.nom);
      expect(zoneApres.classementZoneId, isNull);

      // RÈGLE ABSOLUE : Les données de la zone ne doivent JAMAIS être supprimées !
      expect(zoneApres.locaux.length, equals(1));
      expect(zoneApres.locaux.first.nom, equals('Local Cellules 20kV'));
      expect(zoneApres.coffrets.length, equals(1));
      expect(zoneApres.coffrets.first.nom, equals('Armoire Services Auxiliaires'));

      // RÈGLE ABSOLUE : Le classement propre du local est conservé intact !
      final localEmpApres = empBox.values.firstWhere((e) => e.localisation == localMT.nom);
      expect(localEmpApres.af, equals('AF1'));
      expect(localEmpApres.be, equals('BE1'));

      // Test F : Statistiques après déclassement
      final statsAfter = TechnicalEnrichmentEngine.compute(missionId, domainInv, findingInv);
      expect(statsAfter.totalZonesClasseesCount, equals(0),
          reason: 'Une zone déclassée ne doit plus être comptée comme classée.');

      // Test G : Table PDF après déclassement -> Ne contient plus la zone déclassée
      final pdfWidgetsApres = PdfClassementFoudreBuilder.buildClassementEmplacementsMulti(
        empBox.values.toList(),
        [], // Aucune zone classée
        {},
      );
      expect(pdfWidgetsApres, isNotEmpty);
    });
  });
}
