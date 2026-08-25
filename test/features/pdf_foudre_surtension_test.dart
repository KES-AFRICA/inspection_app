import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

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
      expect(rows.first.repere, equals('REP-01'));
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
      expect(rows[0].repere, equals('REP-02'));
      expect(rows[0].observation, equals('Parafoudre déconnecté suite à surtension'));
      expect(rows[1].repere, equals('REP-02'));
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

    test('Cas 4: Observation avec une seule photo -> format 📷 X', () {
      final photoRegistry = {'/path/photo1.jpg': 12};
      final photoLabel = PdfReportService.getFormattedPhotoLabelForTest(
        ['/path/photo1.jpg'],
        photoRegistry,
      );

      expect(photoLabel, equals('📷 12'));
    });

    test('Cas 5: Observation avec plusieurs photos -> format 📷 X, Y', () {
      final photoRegistry = {
        '/path/photo1.jpg': 5,
        '/path/photo2.jpg': 14,
      };
      final photoLabel = PdfReportService.getFormattedPhotoLabelForTest(
        ['/path/photo1.jpg', '/path/photo2.jpg'],
        photoRegistry,
      );

      expect(photoLabel, equals('📷 5, 14'));
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
      expect(rows[0].repere, equals('REP-A'));
      expect(rows[0].observation, equals('Défaut A1'));
      expect(rows[1].repere, equals('REP-B'));
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
      expect(rows.first.repere, equals('AG-01'));
      expect(rows.first.observation, contains('détérioré suite à un impact de foudre'));
    });
  });
}
