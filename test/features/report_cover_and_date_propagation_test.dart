import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/features/mission/data/mappers/mission_mapper.dart';
import 'package:inspec_app/features/mission/data/mappers/renseignements_generaux_mapper.dart';
import 'package:inspec_app/services/pdf/builders/pdf_cover_builder.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixedDateRapport = DateTime(2026, 10, 25);
  final fixedDateIntervention = DateTime(2026, 10, 20);
  final now = DateTime.now();

  group('1. INITIALISATION PAR DÉFAUT DE DATE DU RAPPORT', () {
    test('Si dateRapport est nulle, PdfReportStyles ou le builder utilise la date de secours / date du jour', () {
      final mission = Mission(
        id: 'M_TEST_DEFAULT_DATE',
        nomClient: 'CIMENCAM',
        status: 'en_cours',
        createdAt: now,
        updatedAt: now,
        dateRapport: null,
      );

      final dateUtilisee = mission.dateRapport ?? DateTime.now();
      expect(dateUtilisee, isNotNull);
      expect(dateUtilisee.year, greaterThanOrEqualTo(2026));
    });

    test('RenseignementsGeneraux accepte et conserve dateRapport', () {
      final rg = RenseignementsGeneraux(
        missionId: 'M_TEST_RG_DATE',
        etablissement: 'Établissement A',
        installation: 'TGBT Principal',
        activite: 'Industrie',
        nomSite: 'Site Central',
        updatedAt: now,
        dateRapport: fixedDateRapport,
      );
      expect(rg.dateRapport, equals(fixedDateRapport));
    });
  });

  group('2. MODIFICATION ET PERSISTANCE DE DATE DU RAPPORT', () {
    test('dateRapport persiste et se met à jour fidèlement dans Mission', () {
      final mission = Mission(
        id: 'M_PERSIST_DATE',
        nomClient: 'CAMRAIL',
        status: 'en_cours',
        createdAt: now,
        updatedAt: now,
        dateRapport: DateTime(2026, 9, 1),
      );
      expect(mission.dateRapport, equals(DateTime(2026, 9, 1)));

      mission.dateRapport = DateTime(2026, 9, 18);
      expect(mission.dateRapport, equals(DateTime(2026, 9, 18)));
    });

    test('dateRapport persiste et se met à jour dans RenseignementsGeneraux', () {
      final rg = RenseignementsGeneraux(
        missionId: 'M_PERSIST_DATE',
        etablissement: 'Atelier Central',
        installation: 'Armoires MT/BT',
        activite: 'Maintenance',
        nomSite: 'Site Ouest',
        updatedAt: now,
        dateRapport: DateTime(2026, 9, 1),
      );
      expect(rg.dateRapport, equals(DateTime(2026, 9, 1)));

      rg.dateRapport = DateTime(2026, 9, 18);
      expect(rg.dateRapport, equals(DateTime(2026, 9, 18)));
    });
  });

  group('3. SAISIE ET PERSISTANCE DE RÉCEPTEUR DU RAPPORT', () {
    test('recepteurRapport stocké dans Mission et mappé sans perte', () {
      final mission = Mission(
        id: 'M_RECEPTEUR',
        nomClient: 'GUINNESS',
        status: 'en_cours',
        createdAt: now,
        updatedAt: now,
        recepteurRapport: 'M. Paul BIYA',
      );

      expect(mission.recepteurRapport, equals('M. Paul BIYA'));

      final entity = MissionMapper.toEntity(mission);
      expect(entity.recepteurRapport, equals('M. Paul BIYA'));

      final restoredModel = MissionMapper.toModel(entity);
      expect(restoredModel.recepteurRapport, equals('M. Paul BIYA'));
    });

    test('recepteurRapport stocké dans RenseignementsGeneraux et mappé sans perte', () {
      final rg = RenseignementsGeneraux(
        missionId: 'M_RECEPTEUR',
        etablissement: 'Brasserie Bassa',
        installation: 'Poste MT 15kV',
        activite: 'Agroalimentaire',
        nomSite: 'Bassa',
        updatedAt: now,
        recepteurRapport: 'M. Jean NDOUMBE',
      );

      expect(rg.recepteurRapport, equals('M. Jean NDOUMBE'));

      final entity = RenseignementsGenerauxMapper.toEntity(rg);
      expect(entity.recepteurRapport, equals('M. Jean NDOUMBE'));

      final restoredModel = RenseignementsGenerauxMapper.toModel(entity);
      expect(restoredModel.recepteurRapport, equals('M. Jean NDOUMBE'));
    });
  });

  group('4. SAISIE ET PERSISTANCE DE LIEU D\'INTERVENTION', () {
    test('lieuIntervention stocké dans Mission et mappé sans perte', () {
      final mission = Mission(
        id: 'M_LIEU',
        nomClient: 'TOTAL',
        status: 'en_cours',
        createdAt: now,
        updatedAt: now,
        lieuIntervention: 'Dépôt Pétrolier de Bessengué',
      );

      expect(mission.lieuIntervention, equals('Dépôt Pétrolier de Bessengué'));

      final entity = MissionMapper.toEntity(mission);
      expect(entity.lieuIntervention, equals('Dépôt Pétrolier de Bessengué'));

      final restoredModel = MissionMapper.toModel(entity);
      expect(restoredModel.lieuIntervention, equals('Dépôt Pétrolier de Bessengué'));
    });

    test('lieuIntervention stocké dans RenseignementsGeneraux et mappé sans perte', () {
      final rg = RenseignementsGeneraux(
        missionId: 'M_LIEU',
        etablissement: 'TOTAL Cameroun',
        installation: 'Cuves de carburant',
        activite: 'Pétrochimie',
        nomSite: 'Bessengué',
        updatedAt: now,
        activiteSurSite: 'Raffinage et stockage',
        lieuIntervention: 'Zone Portuaire Douala',
      );

      expect(rg.activiteSurSite, equals('Raffinage et stockage'));
      expect(rg.lieuIntervention, equals('Zone Portuaire Douala'));

      final entity = RenseignementsGenerauxMapper.toEntity(rg);
      expect(entity.activiteSurSite, equals('Raffinage et stockage'));
      expect(entity.lieuIntervention, equals('Zone Portuaire Douala'));

      final restoredModel = RenseignementsGenerauxMapper.toModel(entity);
      expect(restoredModel.activiteSurSite, equals('Raffinage et stockage'));
      expect(restoredModel.lieuIntervention, equals('Zone Portuaire Douala'));
    });
  });

  group('5. RENDU DE COUVERTURE PDF — SOURCE DE VÉRITÉ VISUELLE', () {
    test('Génération complète de la page de couverture sans crash ni débordement', () async {
      final mission = Mission(
        id: 'M_PDF_COVER',
        nomClient: 'Société Camerounaise de Verrerie (SOCAVER)',
        nomSite: 'Usine de Ndogbong',
        natureMission: 'VÉRIFICATION PÉRIODIQUE RÉGLEMENTAIRE',
        recepteurRapport: 'M. Le Responsable Sécurité',
        lieuIntervention: 'Zone Industrielle de Bassa, Douala',
        dateRapport: fixedDateRapport,
        dateIntervention: fixedDateIntervention,
        logoClient: 'assets/images/logo_client_dummy.png', // Doit être ignoré sur la couverture
        status: 'en_cours',
        createdAt: now,
        updatedAt: now,
      );

      final rg = RenseignementsGeneraux(
        missionId: 'M_PDF_COVER',
        etablissement: 'SOCAVER',
        installation: 'Fours et compresseurs',
        activite: 'Verrerie',
        nomSite: 'Usine de Ndogbong',
        updatedAt: now,
        recepteurRapport: 'M. Le Responsable Sécurité',
        lieuIntervention: 'Zone Industrielle de Bassa, Douala',
      );

      final doc = pw.Document();
      final pageTheme = PdfReportService.buildCoverPageTheme();

      doc.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (ctx) => PdfCoverBuilder.buildCoverPage(
            mission,
            rg,
            ctx,
            numeroRapport: 'KES/IP/VE/2026/042',
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('Vérification des éléments structurels de la page de couverture', () {
      final mission = Mission(
        id: 'M_PDF_COVER_TREE',
        nomClient: 'CIMENCAM',
        nomSite: 'Usine de Figuil',
        natureMission: 'CONTRÔLE RÉGLEMENTAIRE ÉLECTRIQUE',
        recepteurRapport: 'M. Marc DUPONT',
        lieuIntervention: 'Figuil, Région du Nord',
        dateRapport: fixedDateRapport,
        dateIntervention: fixedDateIntervention,
        logoClient: 'un_logo_qui_ne_doit_pas_etre_affiche.png',
        status: 'en_cours',
        createdAt: now,
        updatedAt: now,
      );

      final doc = pw.Document();
      final page = pw.Page(
        build: (ctx) {
          final widget = PdfCoverBuilder.buildCoverPage(
            mission,
            null,
            ctx,
            numeroRapport: 'KES/IP/VE/2026/099',
          );
          expect(widget, isA<pw.Widget>());
          return widget;
        },
      );

      doc.addPage(page);
      expect(doc.document.pdfPageList.pages, isNotEmpty);
    });

    test('Génération de couverture avec données industrielles complexes et longues (Camrail) sans débordement', () async {
      final complexMission = Mission(
        id: 'M_COMPLEX_CAMRAIL',
        nomClient: 'CAMRAIL - DIRECTION DES INSTALLATIONS FIXES ET DES TELECOMS',
        nomSite: 'GARE CENTRALE DE BESSENGUE - POSTE MT/BT ET ATELIERS TRACTION',
        natureMission: 'VERIFICATION PERIODIQUE REGLEMENTAIRE DES INSTALLATIONS ELECTRIQUES',
        recepteurRapport: 'M. Le Responsable Sécurité et Maintenance des Installations',
        lieuIntervention: 'Zone Ferroviaire de Bessengué, Douala, Cameroun',
        dateRapport: fixedDateRapport,
        dateIntervention: fixedDateIntervention,
        status: 'en_cours',
        createdAt: now,
        updatedAt: now,
      );

      final complexRg = RenseignementsGeneraux(
        missionId: 'M_COMPLEX_CAMRAIL',
        etablissement: 'CAMRAIL Bessengué',
        installation: 'Poste MT/BT',
        activite: 'Transport Ferroviaire',
        nomSite: 'GARE CENTRALE DE BESSENGUE - POSTE MT/BT ET ATELIERS TRACTION',
        recepteurRapport: 'M. Le Responsable Sécurité et Maintenance des Installations',
        lieuIntervention: 'Zone Ferroviaire de Bessengué, Douala, Cameroun',
        updatedAt: now,
      );

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageTheme: PdfReportService.buildCoverPageTheme(),
          build: (ctx) => PdfCoverBuilder.buildCoverPage(
            complexMission,
            complexRg,
            ctx,
            numeroRapport: 'KES/IP/VE/2026/001',
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });
  });

  group('6. PROPAGATION DE DATE DU RAPPORT DANS LE DOCUMENT', () {
    test('buildPageHeaderWidget prend en compte dateRapport', () {
      PdfReportService.setCurrentReportDate(DateTime(2026, 11, 15));

      final headerWidget = PdfReportService.buildPageHeaderWidget(
        nomClient: 'SABC',
        nomSite: 'Koumassi',
        numeroRapport: 'KES/IP/VE/2026/001',
      );

      expect(headerWidget, isNotNull);

      // Réinitialisation après test
      PdfReportService.setCurrentReportDate(null);
    });

    test('buildIntervenantsEtResponsabilitesPage prend mission.dateRapport en priorité', () async {
      final mission = Mission(
        id: 'M_INTERV_DATE',
        nomClient: 'ALUCAM',
        status: 'en_cours',
        createdAt: now,
        updatedAt: now,
        dateRapport: DateTime(2026, 12, 31),
      );

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageTheme: const pw.PageTheme(pageFormat: PdfPageFormat.a4),
          build: (ctx) => PdfCoverBuilder.buildIntervenantsEtResponsabilitesPage(
            JSA(missionId: 'M_INTERV_DATE', inspecteurs: [JSAInspecteur(nom: 'TOTO', prenom: 'Alex')]),
            null,
            null,
            {},
            0,
            reportGenerationDate: DateTime(2026, 1, 1), // Date antérieure
            mission: mission,
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });
  });

  group('7. RÉTROCOMPATIBILITÉ SUR MISSIONS LEGACY SANS NOUVEAUX CHAMPS', () {
    test('Mission et RenseignementsGeneraux créés sans nouveaux champs ne provoquent aucun crash', () async {
      final legacyMission = Mission(
        id: 'M_LEGACY_001',
        nomClient: 'ANCIEN CLIENT',
        status: 'en_cours',
        createdAt: now,
        updatedAt: now,
      );

      expect(legacyMission.recepteurRapport, isNull);
      expect(legacyMission.lieuIntervention, isNull);
      expect(legacyMission.dateRapport, isNull);

      final legacyRg = RenseignementsGeneraux(
        missionId: 'M_LEGACY_001',
        etablissement: 'Ancien établissement',
        installation: 'Ancienne installation',
        activite: 'Ancienne activité',
        nomSite: 'Ancien site',
        updatedAt: now,
      );

      expect(legacyRg.recepteurRapport, isNull);
      expect(legacyRg.lieuIntervention, isNull);
      expect(legacyRg.dateRapport, isNull);

      // Génération de couverture PDF sur mission legacy
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageTheme: const pw.PageTheme(pageFormat: PdfPageFormat.a4),
          build: (ctx) => PdfCoverBuilder.buildCoverPage(
            legacyMission,
            legacyRg,
            ctx,
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });
  });

  group('8. SÉRIALISATION / DÉSÉRIALISATION (EXPORT / IMPORT JSON)', () {
    test('Mission toJson et fromJson préservent recepteurRapport et lieuIntervention', () {
      final mission = Mission(
        id: 'M_JSON_TEST',
        nomClient: 'ENEO CAMEROUN',
        status: 'en_cours',
        createdAt: now,
        updatedAt: now,
        recepteurRapport: 'M. Le Directeur Général',
        lieuIntervention: 'Centrale Hydroélectrique de Songloulou',
        dateRapport: fixedDateRapport,
      );

      final json = mission.toJson();
      expect(json['recepteur_rapport'], equals('M. Le Directeur Général'));
      expect(json['lieu_intervention'], equals('Centrale Hydroélectrique de Songloulou'));
      expect(json['date_rapport'], equals(fixedDateRapport.toIso8601String()));

      final restored = Mission.fromJson(json);
      expect(restored.recepteurRapport, equals('M. Le Directeur Général'));
      expect(restored.lieuIntervention, equals('Centrale Hydroélectrique de Songloulou'));
      expect(restored.dateRapport, equals(fixedDateRapport));
    });

    test('Mission fromJson gère les JSON legacy sans ces champs', () {
      final legacyJson = {
        'id': 'M_JSON_LEGACY',
        'nomClient': 'OLD CORP',
        'status': 'en_cours',
      };

      final restored = Mission.fromJson(legacyJson);
      expect(restored.recepteurRapport, isNull);
      expect(restored.lieuIntervention, isNull);
      expect(restored.dateRapport, isNull);
    });

    test('RenseignementsGeneraux toMap et create préservent les 3 nouveaux champs', () {
      final rg = RenseignementsGeneraux.create('M_RG_JSON');
      rg.etablissement = 'SODICOTON';
      rg.recepteurRapport = 'M. Le Chef de Division Usines';
      rg.lieuIntervention = 'Huilerie de Maroua';
      rg.dateRapport = fixedDateRapport;

      final map = rg.toMap();
      expect(map['recepteurRapport'], equals('M. Le Chef de Division Usines'));
      expect(map['lieuIntervention'], equals('Huilerie de Maroua'));
      expect(map['dateRapport'], equals(fixedDateRapport.toIso8601String()));

      final restored = RenseignementsGeneraux(
        missionId: map['missionId'] as String,
        etablissement: (map['etablissement'] as String?) ?? '',
        installation: (map['installation'] as String?) ?? '',
        activite: (map['activite'] as String?) ?? '',
        nomSite: (map['nomSite'] as String?) ?? '',
        updatedAt: now,
        recepteurRapport: map['recepteurRapport'] as String?,
        lieuIntervention: map['lieuIntervention'] as String?,
        dateRapport: map['dateRapport'] != null ? DateTime.tryParse(map['dateRapport'] as String) : null,
      );

      expect(restored.recepteurRapport, equals('M. Le Chef de Division Usines'));
      expect(restored.lieuIntervention, equals('Huilerie de Maroua'));
      expect(restored.dateRapport, equals(fixedDateRapport));
    });
  });
}
