// test/services/intervenants_service_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/intervenants_service.dart';
import 'package:inspec_app/services/pdf/builders/pdf_cover_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_regulatory_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('intervenants_test_');
    Hive.init(tempDir.path);

    // Enregistrer les adaptateurs nécessaires
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(VerificateurAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MissionAdapter());
    if (!Hive.isAdapterRegistered(34)) Hive.registerAdapter(RenseignementsGenerauxAdapter());
    if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(JSAInspecteurAdapter());
    if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(JSAPlanUrgenceAdapter());
    if (!Hive.isAdapterRegistered(42)) Hive.registerAdapter(JSADangersAdapter());
    if (!Hive.isAdapterRegistered(43)) Hive.registerAdapter(JSAExigencesGeneralesAdapter());
    if (!Hive.isAdapterRegistered(44)) Hive.registerAdapter(JSAEPIAdapter());
    if (!Hive.isAdapterRegistered(45)) Hive.registerAdapter(JSAVerificationFinaleAdapter());
    if (!Hive.isAdapterRegistered(39)) Hive.registerAdapter(JSAAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await Hive.openBox<Verificateur>('verificateurs');
    await Hive.openBox<Mission>('missions');
    await Hive.openBox<RenseignementsGeneraux>('renseignements_generaux');
    await Hive.openBox<JSA>('jsa');
    await Hive.openBox('current_user');
    await Hive.openBox('app_settings');
  });

  tearDown(() async {
    await Hive.box<Verificateur>('verificateurs').clear();
    await Hive.box<Mission>('missions').clear();
    await Hive.box<RenseignementsGeneraux>('renseignements_generaux').clear();
    await Hive.box<JSA>('jsa').clear();
    await Hive.box('current_user').clear();
    await Hive.box('app_settings').clear();
  });

  Future<void> setCurrentUser(Verificateur user) async {
    final vBox = Hive.box<Verificateur>('verificateurs');
    await vBox.put(user.email, user);
    final curBox = Hive.box('current_user');
    await curBox.put('email', user.email);
    await curBox.put('isLoggedIn', true);
  }

  Mission createTestMission(
    String id,
    String nomClient, {
    List<Map<String, dynamic>>? verificateurs,
  }) {
    return Mission(
      id: id,
      nomClient: nomClient,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: 'en_cours',
      verificateurs: verificateurs,
    );
  }

  RenseignementsGeneraux createTestRg(
    String missionId, {
    List<Map<String, dynamic>>? verificateurs,
  }) {
    final list = verificateurs?.map((m) => m.map((k, v) => MapEntry(k, v.toString()))).toList();
    return RenseignementsGeneraux(
      missionId: missionId,
      etablissement: 'Site Principal',
      installation: 'Installation BT',
      activite: 'Tertiaire',
      nomSite: 'Site Central',
      updatedAt: DateTime.now(),
      verificateurs: list ?? [],
    );
  }

  group('Unification Intervenants - JSA Source Unique de Vérité', () {
    final userA = Verificateur(
      id: 'usr_a',
      nom: 'ESSAME',
      prenom: 'Patrick',
      email: 'p.essame@kes-africa.com',
      password: 'hash',
      matricule: 'KES-001',
      createdAt: DateTime.now(),
    );

    final userB = Verificateur(
      id: 'usr_b',
      nom: 'TEUFACK',
      prenom: 'Andelson',
      email: 'a.teufack@kes-africa.com',
      password: 'hash',
      matricule: 'KES-002',
      createdAt: DateTime.now(),
    );

    final userC = Verificateur(
      id: 'usr_c',
      nom: 'FOKOU',
      prenom: 'Christian',
      email: 'c.fokou@kes-africa.com',
      password: 'hash',
      matricule: 'KES-003',
      createdAt: DateTime.now(),
    );

    test('Scénario 1 : Création de mission par A -> JSA contient uniquement [A]', () async {
      await setCurrentUser(userA);
      const missionId = 'mission_101';

      final mission = createTestMission(missionId, 'CIMENCAM');
      await HiveService.saveMission(mission);

      // Simulation de l'enrôlement lors de la création
      await IntervenantsService.ensureCurrentUserInJSA(missionId);

      final jsa = HiveService.getJSAByMissionId(missionId);
      expect(jsa, isNotNull);
      expect(jsa!.inspecteurs.length, equals(1));
      expect(jsa.inspecteurs.first.nom, equals('ESSAME'));
      expect(jsa.inspecteurs.first.prenom, equals('Patrick'));
      expect(jsa.inspecteurs.first.matricule, equals('KES-001'));
    });

    test('Scénario 2 : Réouverture répétée par A -> Aucun doublon [A]', () async {
      await setCurrentUser(userA);
      const missionId = 'mission_102';

      final mission = createTestMission(missionId, 'GUINNESS');
      await HiveService.saveMission(mission);

      // Première ouverture
      await IntervenantsService.ensureCurrentUserInJSA(missionId);
      // Réouverture 1
      await IntervenantsService.ensureCurrentUserInJSA(missionId);
      // Réouverture 2
      await IntervenantsService.ensureCurrentUserInJSA(missionId);

      final jsa = HiveService.getJSAByMissionId(missionId);
      expect(jsa!.inspecteurs.length, equals(1));
      expect(jsa.inspecteurs.first.matricule, equals('KES-001'));
    });

    test('Scénario 3 : Export par A puis Import par B -> JSA contient [A, B]', () async {
      // 1. A crée la mission
      await setCurrentUser(userA);
      const missionId = 'mission_103';
      final mission = createTestMission(missionId, 'CAMRAIL');
      await HiveService.saveMission(mission);
      await IntervenantsService.ensureCurrentUserInJSA(missionId);

      // 2. B se connecte et importe la mission
      await setCurrentUser(userB);
      await IntervenantsService.ensureCurrentUserInJSA(
        missionId,
        fallbackMatricule: userB.matricule,
        fallbackNom: userB.nom,
        fallbackPrenom: userB.prenom,
      );

      final jsa = HiveService.getJSAByMissionId(missionId);
      expect(jsa!.inspecteurs.length, equals(2));
      expect(jsa.inspecteurs[0].matricule, equals('KES-001'));
      expect(jsa.inspecteurs[1].matricule, equals('KES-002'));
    });

    test('Scénario 4 : Réouverture multiple par B -> Reste strictement [A, B]', () async {
      await setCurrentUser(userA);
      const missionId = 'mission_104';
      final mission = createTestMission(missionId, 'ALUCAM');
      await HiveService.saveMission(mission);
      await IntervenantsService.ensureCurrentUserInJSA(missionId);

      await setCurrentUser(userB);
      await IntervenantsService.ensureCurrentUserInJSA(missionId);
      // Re-ouvertures par B
      await IntervenantsService.ensureCurrentUserInJSA(missionId);
      await IntervenantsService.ensureCurrentUserInJSA(missionId);

      final jsa = HiveService.getJSAByMissionId(missionId);
      expect(jsa!.inspecteurs.length, equals(2));
      expect(jsa.inspecteurs[0].matricule, equals('KES-001'));
      expect(jsa.inspecteurs[1].matricule, equals('KES-002'));
    });

    test('Scénario 5 : Réimport multiple par B -> Reste [A, B] (idempotence absolue)', () async {
      await setCurrentUser(userA);
      const missionId = 'mission_105';
      final mission = createTestMission(missionId, 'SABC');
      await HiveService.saveMission(mission);
      await IntervenantsService.ensureCurrentUserInJSA(missionId);

      // B simule 3 imports successifs du même fichier
      await setCurrentUser(userB);
      await IntervenantsService.ensureCurrentUserInJSA(
        missionId,
        fallbackMatricule: userB.matricule,
        fallbackNom: userB.nom,
        fallbackPrenom: userB.prenom,
      );
      await IntervenantsService.ensureCurrentUserInJSA(
        missionId,
        fallbackMatricule: userB.matricule,
        fallbackNom: userB.nom,
        fallbackPrenom: userB.prenom,
      );

      final jsa = HiveService.getJSAByMissionId(missionId);
      expect(jsa!.inspecteurs.length, equals(2));
    });

    test('Scénario 6 : Troisième intervenant C importe -> JSA contient [A, B, C]', () async {
      const missionId = 'mission_106';
      // A crée
      await setCurrentUser(userA);
      final mission = createTestMission(missionId, 'ENEO');
      await HiveService.saveMission(mission);
      await IntervenantsService.ensureCurrentUserInJSA(missionId);

      // B importe
      await setCurrentUser(userB);
      await IntervenantsService.ensureCurrentUserInJSA(missionId);

      // C importe
      await setCurrentUser(userC);
      await IntervenantsService.ensureCurrentUserInJSA(missionId);

      final jsa = HiveService.getJSAByMissionId(missionId);
      expect(jsa!.inspecteurs.length, equals(3));
      expect(jsa.inspecteurs.map((i) => i.matricule).toList(),
          equals(['KES-001', 'KES-002', 'KES-003']));
    });

    test('Scénario 7 : Retour chez A -> JSA conserve [A, B, C] sans ré-ajouter A', () async {
      const missionId = 'mission_107';
      final mission = createTestMission(missionId, 'TOTAL ENERGIES');
      await HiveService.saveMission(mission);

      // JSA existante contenant A, B, C
      final jsa = await HiveService.getOrCreateJSA(missionId);
      JSAUtils.addInspectorIfAbsent(jsa.inspecteurs, 'ESSAME', 'Patrick', matricule: 'KES-001');
      JSAUtils.addInspectorIfAbsent(jsa.inspecteurs, 'TEUFACK', 'Andelson', matricule: 'KES-002');
      JSAUtils.addInspectorIfAbsent(jsa.inspecteurs, 'FOKOU', 'Christian', matricule: 'KES-003');
      await HiveService.saveJSA(jsa);

      // A réimporte ou réouvre la mission
      await setCurrentUser(userA);
      await IntervenantsService.ensureCurrentUserInJSA(missionId);

      final reloadedJsa = HiveService.getJSAByMissionId(missionId);
      expect(reloadedJsa!.inspecteurs.length, equals(3));
      expect(reloadedJsa.inspecteurs.map((i) => i.matricule).toList(),
          equals(['KES-001', 'KES-002', 'KES-003']));
    });

    test('Scénario 8 : Alignement strict des rapports PDF (Intervenants & Périmètre)', () async {
      const missionId = 'mission_108';
      final mission = createTestMission(missionId, 'ORANGE CAMEROUN');
      await HiveService.saveMission(mission);

      final jsa = await HiveService.getOrCreateJSA(missionId);
      JSAUtils.addInspectorIfAbsent(jsa.inspecteurs, 'ESSAME', 'Patrick', matricule: 'KES-001');
      JSAUtils.addInspectorIfAbsent(jsa.inspecteurs, 'TEUFACK', 'Andelson', matricule: 'KES-002');
      await HiveService.saveJSA(jsa);

      final rg = createTestRg(missionId);

      // Récupération des inspecteurs pour Périmètre de la mission
      final perimetreInspecteurs = IntervenantsService.getMissionIntervenantsNoms(
        missionId,
        mission: mission,
        rg: rg,
        jsa: jsa,
        uppercase: true,
      );

      // Récupération des inspecteurs pour Intervenants et Responsabilités
      final responsabilitesInspecteurs = IntervenantsService.getMissionIntervenantsNoms(
        missionId,
        mission: mission,
        rg: rg,
        jsa: jsa,
        uppercase: true,
      );

      expect(perimetreInspecteurs, equals(responsabilitesInspecteurs));
      expect(perimetreInspecteurs, equals(['PATRICK ESSAME', 'ANDELSON TEUFACK']));

      // Vérification que les builders PDF s'exécutent sans exception
      final perimetreWidget = PdfRegulatoryBuilder.buildPerimetreTable(
        mission,
        rg,
        jsa: jsa,
      );
      expect(perimetreWidget, isNotNull);

      final intervenantsWidget = PdfCoverBuilder.buildIntervenantsEtResponsabilitesPage(
        jsa,
        rg,
        userA,
        {},
        0,
        mission: mission,
      );
      expect(intervenantsWidget, isNotNull);
    });

    test('Scénario 9 : Ancienne mission legacy sans JSA -> Migration non destructive', () async {
      const missionId = 'mission_legacy_99';
      final mission = createTestMission(
        missionId,
        'LEGACY CLIENT',
        verificateurs: [
          {'nom': 'ANCIEN', 'prenom': 'Inspecteur', 'matricule': 'LEG-01', 'role': 'Lead'},
          {'nom': 'SECOND', 'prenom': 'Vérificateur', 'matricule': 'LEG-02', 'role': 'Tech'},
        ],
      );
      await HiveService.saveMission(mission);

      final rg = createTestRg(
        missionId,
        verificateurs: [
          {'nom': 'ANCIEN', 'prenom': 'Inspecteur', 'fonction': 'Lead'},
        ],
      );
      await HiveService.saveRenseignementsGeneraux(rg);

      // Avant appel, aucune JSA n'existe
      expect(HiveService.getJSAByMissionId(missionId), isNull);

      // Résolution des intervenants à chaud
      final intervenants = IntervenantsService.getMissionIntervenants(missionId, mission: mission, rg: rg);
      expect(intervenants.length, equals(2));
      expect(intervenants[0].nom, equals('ANCIEN'));
      expect(intervenants[1].nom, equals('SECOND'));

      // Appel de l'enrôlement avec un nouvel utilisateur
      await setCurrentUser(userC);
      await IntervenantsService.ensureCurrentUserInJSA(missionId);

      final jsa = HiveService.getJSAByMissionId(missionId);
      expect(jsa, isNotNull);
      // Contient les 2 intervenants legacy migrés + l'utilisateur courant C !
      expect(jsa!.inspecteurs.length, equals(3));
      expect(jsa.inspecteurs[0].matricule, equals('LEG-01'));
      expect(jsa.inspecteurs[1].matricule, equals('LEG-02'));
      expect(jsa.inspecteurs[2].matricule, equals('KES-003'));
    });

    test('Scénario 10 : Déduplication robuste face aux variations de casse et espaces', () {
      final list = <JSAInspecteur>[];

      // Ajout initial
      final added1 = JSAUtils.addInspectorIfAbsent(
        list,
        'ESSAME',
        'Patrick',
        matricule: 'KES-001',
        email: 'p.essame@kes-africa.com',
      );
      expect(added1, isTrue);
      expect(list.length, equals(1));

      // Même personne avec minuscules et espaces superflus
      final added2 = JSAUtils.addInspectorIfAbsent(
        list,
        '  essame  ',
        '  patrick  ',
        matricule: 'kes-001',
      );
      expect(added2, isFalse);
      expect(list.length, equals(1));

      // Même personne avec matricule identique mais nom légèrement différent (enrichissement)
      final added3 = JSAUtils.addInspectorIfAbsent(
        list,
        'ESSAME ESSAME',
        'Patrick',
        matricule: 'KES-001',
        role: 'Chef de Mission',
      );
      expect(added3, isFalse);
      expect(list.length, equals(1));
      expect(list.first.role, equals('Chef de Mission'));

      // Personne distincte ayant un prénom similaire mais nom et matricule différents
      final added4 = JSAUtils.addInspectorIfAbsent(
        list,
        'DUPONT',
        'Patrick',
        matricule: 'KES-999',
      );
      expect(added4, isTrue);
      expect(list.length, equals(2));
    });
  });
}
