import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';
import 'package:inspec_app/services/pdf/builders/pdf_classement_foudre_builder.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Audit & Génération PDF — Section FOUDRE ET SURTENSION', () {
    test('Cas 1: Un équipement avec observation parafoudre Slide 3 -> 1 ligne générée', () {
      final coffret = CoffretArmoire(
        nom: 'Armoire Principale',
        type: 'Armoire MT',
        qrCode: 'QR001',
        repere: 'REP-01',
        presenceParafoudre: true,
        observationsParafoudre: [
          ObservationLibre(
            texte: 'Voyant parafoudre au rouge',
            photos: ['/path/photo1.jpg'],
          ),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm1',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'Local MT 1',
            type: 'Local',
            coffrets: [coffret],
          ),
        ],
      );

      final rows = PdfReportService.collectParafoudreRowsForTest(audit);

      expect(rows.length, equals(1));
      expect(rows.first.repere, contains('REP-01'));
      expect(rows.first.observation, equals('Voyant parafoudre au rouge'));
      expect(rows.first.photoPaths, contains('/path/photo1.jpg'));
    });

    test('Cas 2: Un équipement avec plusieurs observations dans Points de Vérification -> plusieurs lignes', () {
      final coffret = CoffretArmoire(
        nom: 'TGBT Principal',
        type: 'TGBT',
        qrCode: 'QR002',
        repere: 'REP-02',
        pointsVerification: [
          PointVerification(
            pointVerification: 'État des parafoudres BT',
            conformite: 'Non conforme',
            observation: 'Parafoudre déconnecté suite à surtension',
            photos: ['/path/photo_pv1.jpg'],
          ),
          PointVerification(
            pointVerification: 'Mise à la terre du limiteur de surtension',
            conformite: 'Non conforme',
            observation: 'Câble de terre du limiteur sectionné',
            photos: ['/path/photo_pv2.jpg'],
          ),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm1',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone BT 1',
            coffretsDirects: [coffret],
          ),
        ],
      );

      final rows = PdfReportService.collectParafoudreRowsForTest(audit);

      expect(rows.length, equals(2));
      expect(rows[0].repere, contains('REP-02'));
      expect(rows[0].observation, equals('Parafoudre déconnecté suite à surtension'));
      expect(rows[1].repere, contains('REP-02'));
      expect(rows[1].observation, equals('Câble de terre du limiteur sectionné'));
    });

    test('Cas 3: Cumul Slide 3 (Enrichie/Simple) + Points de vérification -> toutes les observations apparaissent', () {
      final coffret = CoffretArmoire(
        nom: 'Coffret Distribution',
        type: 'Coffret',
        qrCode: 'QR003',
        repere: 'REP-03',
        observationsParafoudreEnrichies: [
          ElementControle(
            elementControle: 'Parafoudre Type 2',
            conforme: false,
            observation: 'Cartouche usée',
            photos: ['/path/photo_pf.jpg'],
          ),
        ],
        pointsVerification: [
          PointVerification(
            pointVerification: 'Protection surtension',
            conformite: 'Non conforme',
            observation: 'Disjoncteur de déconnexion parafoudre absent',
          ),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm1',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone BT 1',
            coffretsDirects: [coffret],
          ),
        ],
      );

      final rows = PdfReportService.collectParafoudreRowsForTest(audit);

      expect(rows.length, equals(2));
      expect(rows[0].observation, equals('Cartouche usée'));
      expect(rows[1].observation, equals('Disjoncteur de déconnexion parafoudre absent'));
    });

    test('Cas 4: Observation avec une seule photo -> format Photo X', () {
      final photoRegistry = {'/path/photo1.jpg': 12};
      final photoLabel = PdfReportService.getFormattedPhotoLabelForTest(
        ['/path/photo1.jpg'],
        photoRegistry,
      );

      expect(photoLabel, equals('Photo 12'));
    });

    test('Cas 5: Observation avec plusieurs photos -> format Photos X, Y', () {
      final photoRegistry = {
        '/path/photo1.jpg': 5,
        '/path/photo2.jpg': 14,
      };
      final photoLabel = PdfReportService.getFormattedPhotoLabelForTest(
        ['/path/photo1.jpg', '/path/photo2.jpg'],
        photoRegistry,
      );

      expect(photoLabel, equals('Photos 5, 14'));
    });

    test('Cas 6: Observation sans photo -> tiret "-"', () {
      final photoRegistry = {'/path/other.jpg': 1};
      final photoLabel = PdfReportService.getFormattedPhotoLabelForTest(
        [],
        photoRegistry,
      );

      expect(photoLabel, equals('-'));
    });

    test('Cas 7: Plusieurs équipements avec observations -> ordre préservé et repères enregistrés', () {
      final c1 = CoffretArmoire(
        nom: 'Coffret A',
        type: 'Coffret',
        qrCode: 'QR_A',
        repere: 'REP-A',
        observationsParafoudre: [
          ObservationLibre(texte: 'Défaut A1'),
        ],
      );
      final c2 = CoffretArmoire(
        nom: 'Coffret B',
        type: 'Coffret',
        qrCode: 'QR_B',
        repere: 'REP-B',
        observationsParafoudre: [
          ObservationLibre(texte: 'Défaut B1'),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm1',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone BT',
            coffretsDirects: [c1, c2],
          ),
        ],
      );

      final rows = PdfReportService.collectParafoudreRowsForTest(audit);

      expect(rows.length, equals(2));
      expect(rows[0].repere, contains('REP-A'));
      expect(rows[0].observation, equals('Défaut A1'));
      expect(rows[1].repere, contains('REP-B'));
      expect(rows[1].observation, equals('Défaut B1'));
    });

    test('Cas 8: Rétrocompatibilité ancienne mission sans observation -> liste vide sans crash', () {
      final cLegacy = CoffretArmoire(
        nom: 'Ancien Coffret',
        type: 'Coffret',
        qrCode: 'QR_OLD',
        repere: 'REP-OLD',
        presenceParafoudre: false,
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm1',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'Local 1',
            type: 'Local',
            coffrets: [cLegacy],
          ),
        ],
      );

      final rows = PdfReportService.collectParafoudreRowsForTest(audit);
      expect(rows, isEmpty);
    });

    test('Cas 9: Tendance observation libre sur le parafoudre', () {
      final coffret = CoffretArmoire(
        nom: 'Armoire Générale',
        type: 'Armoire',
        qrCode: 'QR_AG',
        repere: 'AG-01',
        observationsLibres: [
          ObservationLibre(
            texte: 'Le parafoudre principal est détérioré suite à un impact de foudre',
            photos: ['/photo_foudre.jpg'],
          ),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm1',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone B',
            coffretsDirects: [coffret],
          ),
        ],
      );

      final rows = PdfReportService.collectParafoudreRowsForTest(audit);
      expect(rows.length, equals(1));
      expect(rows.first.repere, contains('AG-01'));
      expect(rows.first.observation, contains('détérioré suite à un impact de foudre'));
    });

    test('Cas 10: Consolidation Slide 3 + PV standard avec référence normative par défaut et criticité Majeure', () {
      final coffret = CoffretArmoire(
        nom: 'TGBT arrivée inverseur',
        type: 'TGBT',
        qrCode: 'QR_TGBT',
        repere: 'TGBT-INV',
        observationsParafoudre: [
          ObservationLibre(texte: 'Témoin parafoudre hors service'),
        ],
        pointsVerification: [
          PointVerification(
            pointVerification: 'Dispositif de protection contre les surtensions (parafoudre)',
            conformite: 'Non conforme',
            observation: 'Absence de protection amont du parafoudre',
          ),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm1',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Principale',
            locaux: [
              BasseTensionLocal(
                nom: 'Local TGBT',
                type: 'Local',
                coffrets: [coffret],
              ),
            ],
          ),
        ],
      );

      final rows = PdfReportService.collectParafoudreRowsForTest(audit);

      expect(rows.length, equals(2));
      // Ligne 1: Slide 3
      expect(rows[0].equipementName, equals('TGBT arrivée inverseur'));
      expect(rows[0].localName, equals('Local TGBT'));
      expect(rows[0].zoneName, equals('Zone Principale'));
      expect(rows[0].pointVerification, equals('Dispositif de protection contre les surtensions (parafoudre)'));
      expect(rows[0].referenceNormative, equals('NF C 15-100-1:2024 – art 443 et art 534'));
      expect(rows[0].criticite, equals('Majeure'));
      expect(rows[0].observation, equals('Témoin parafoudre hors service'));

      // Ligne 2: PV
      expect(rows[1].equipementName, equals('TGBT arrivée inverseur'));
      expect(rows[1].localName, equals('Local TGBT'));
      expect(rows[1].zoneName, equals('Zone Principale'));
      expect(rows[1].pointVerification, equals('Dispositif de protection contre les surtensions (parafoudre)'));
      expect(rows[1].referenceNormative, equals('NF C 15-100-1:2024 – art 443 et art 534'));
      expect(rows[1].criticite, equals('Majeure'));
      expect(rows[1].observation, equals('Absence de protection amont du parafoudre'));
    });

    test('Cas IX.1 & IX.2: Normalisation stricte de POINT DE VÉRIFICATION pour Slide 3 et Point de vérification', () {
      final coffretSlide3 = CoffretArmoire(
        nom: 'Coffret Éclairage',
        type: 'Coffret',
        qrCode: 'QR_C1',
        repere: 'COFF-01',
        observationsParafoudre: [
          ObservationLibre(texte: 'Parafoudre détérioré'),
        ],
      );

      final coffretPV = CoffretArmoire(
        nom: 'Coffret Force',
        type: 'Coffret',
        qrCode: 'QR_C2',
        repere: 'COFF-02',
        pointsVerification: [
          PointVerification(
            pointVerification: 'Dispositif de protection contre les surtensions (parafoudre)',
            conformite: 'Non conforme',
            observation: 'Cartouche rouge signalée',
          ),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm1',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Usine',
            coffretsDirects: [coffretSlide3, coffretPV],
          ),
        ],
      );

      final rows = PdfReportService.collectParafoudreRowsForTest(audit);

      expect(rows.length, equals(2));
      // Cas 1 (Slide 3)
      expect(rows[0].pointVerification, equals('Dispositif de protection contre les surtensions (parafoudre)'));
      expect(rows[0].observation, equals('Parafoudre détérioré'));
      // Cas 2 (PV)
      expect(rows[1].pointVerification, equals('Dispositif de protection contre les surtensions (parafoudre)'));
      expect(rows[1].observation, equals('Cartouche rouge signalée'));
    });

    test('Cas IX.3: Deux sources simultanément sur le même équipement sans perte ni déduplication', () {
      final coffret = CoffretArmoire(
        nom: 'Armoire Climatisation',
        type: 'Armoire',
        qrCode: 'QR_ARM_CLIM',
        repere: 'ARM-CLIM',
        observationsParafoudre: [
          ObservationLibre(texte: 'Défaut voyant parafoudre'),
        ],
        pointsVerification: [
          PointVerification(
            pointVerification: 'Dispositif de protection contre les surtensions (parafoudre)',
            conformite: 'Non conforme',
            observation: 'Défaut voyant parafoudre', // Même observation textuelle entre les deux sources
          ),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm1',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Technique',
            coffretsDirects: [coffret],
          ),
        ],
      );

      final rows = PdfReportService.collectParafoudreRowsForTest(audit);

      // Les 2 lignes doivent exister (non dédupliquées à tort malgré un texte identique)
      expect(rows.length, equals(2));
      expect(rows[0].pointVerification, equals('Dispositif de protection contre les surtensions (parafoudre)'));
      expect(rows[1].pointVerification, equals('Dispositif de protection contre les surtensions (parafoudre)'));
      expect(rows[0].observation, equals('Défaut voyant parafoudre'));
      expect(rows[1].observation, equals('Défaut voyant parafoudre'));
    });

    test('Cas IX.4: Plusieurs types d\'équipements (TGBT, Armoire, Coffret, Inverseur)', () {
      final equipements = <CoffretArmoire>[
        CoffretArmoire(
          nom: 'TGBT 1',
          type: 'TGBT',
          qrCode: 'QR_T1',
          repere: 'TGBT-1',
          observationsParafoudre: [ObservationLibre(texte: 'Obs TGBT')],
        ),
        CoffretArmoire(
          nom: 'Armoire 1',
          type: 'Armoire',
          qrCode: 'QR_A1',
          repere: 'ARM-1',
          observationsParafoudre: [ObservationLibre(texte: 'Obs Armoire')],
        ),
        CoffretArmoire(
          nom: 'Coffret 1',
          type: 'Coffret',
          qrCode: 'QR_CF1',
          repere: 'COF-1',
          observationsParafoudre: [ObservationLibre(texte: 'Obs Coffret')],
        ),
        CoffretArmoire(
          nom: 'Inverseur Normal/Secours',
          type: 'Inverseur',
          qrCode: 'QR_INV1',
          repere: 'INV-1',
          observationsParafoudre: [ObservationLibre(texte: 'Obs Inverseur')],
        ),
      ];

      final audit = AuditInstallationsElectriques(
        missionId: 'm1',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Principale',
            coffretsDirects: equipements,
          ),
        ],
      );

      final rows = PdfReportService.collectParafoudreRowsForTest(audit);

      expect(rows.length, equals(4));
      for (final r in rows) {
        expect(r.pointVerification, equals('Dispositif de protection contre les surtensions (parafoudre)'));
      }
      expect(rows[0].equipementName, equals('TGBT 1'));
      expect(rows[1].equipementName, equals('Armoire 1'));
      expect(rows[2].equipementName, equals('Coffret 1'));
      expect(rows[3].equipementName, equals('Inverseur Normal/Secours'));
    });

    test('Cas IX.6: Vérification de l\'en-tête de colonne DÉSIGNATION dans le tableau PDF', () {
      final coffret = CoffretArmoire(
        nom: 'TGBT Général',
        type: 'TGBT',
        qrCode: 'QR_TGEN',
        repere: 'TGBT-01',
        observationsParafoudre: [
          ObservationLibre(texte: 'Absence de parafoudre de tête'),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm1',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Électrique',
            coffretsDirects: [coffret],
          ),
        ],
      );

      final widgets = PdfClassementFoudreBuilder.buildFoudre(
        audit,
        [],
        {},
        afficherTableauFoudre: true,
      );

      // On recherche la table d'observation par équipement
      final tables = widgets.whereType<pw.Table>().toList();
      expect(tables.isNotEmpty, isTrue);

      final foudreTable = tables.last;
      final headerRow = foudreTable.children.first;

      // Extraire les textes de l'en-tête
      final headerTexts = <String>[];
      for (final cell in headerRow.children) {
        if (cell is pw.Container && cell.child is pw.Text) {
          headerTexts.add(((cell.child as pw.Text).text as pw.TextSpan).text ?? '');
        }
      }

      // Vérifier le libellé DÉSIGNATION (et l'absence de l'ancien libellé ÉQUIPEMENT)
      expect(headerTexts, contains('DÉSIGNATION'));
      expect(headerTexts, isNot(contains('ÉQUIPEMENT')));
      expect(headerTexts, contains('ZONE'));
      expect(headerTexts, contains('REPÈRE'));
      expect(headerTexts, contains('POINT DE VÉRIFICATION'));
      expect(headerTexts, contains('RÉF. NORMATIVE'));
      expect(headerTexts, contains('CRITICITÉ'));
      expect(headerTexts, contains('OBSERVATION'));
      expect(headerTexts, contains('PHOTO'));
    });
  });
}
