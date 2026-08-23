import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

void main() {
  group('Audit Table Photo Reference Indicators', () {
    test('Format single photo number', () {
      final formatted = PdfReportService.formatPhotoNumbersForTest([12]);
      expect(formatted, equals('Photo 12'));
    });

    test('Format two photo numbers', () {
      final formatted = PdfReportService.formatPhotoNumbersForTest([12, 13]);
      expect(formatted, equals('Photos 12, 13'));
    });

    test('Format three consecutive photo numbers into range', () {
      final formatted = PdfReportService.formatPhotoNumbersForTest([12, 13, 14]);
      expect(formatted, equals('Photos 12–14'));
    });

    test('Format non-consecutive photo numbers', () {
      final formatted = PdfReportService.formatPhotoNumbersForTest([12, 15, 21]);
      expect(formatted, equals('Photos 12, 15, 21'));
    });

    test('Format mixed consecutive and non-consecutive photo numbers', () {
      final formatted = PdfReportService.formatPhotoNumbersForTest([1, 2, 3, 5, 8, 9, 10]);
      expect(formatted, equals('Photos 1–3, 5, 8–10'));
    });

    test('Build photo number registry with correct 1-indexed order matching photos section', () {
      final description = DescriptionInstallations.create('test_m1');
      description.alimentationMoyenneTension = [
        InstallationItem(data: {'nom': 'Arrivée MT'}, photoPaths: ['/path/desc_mt1.jpg']),
      ];

      final audit = AuditInstallationsElectriques.create('test_m1');
      audit.photos = ['/path/audit_gen1.jpg'];
      audit.moyenneTensionLocaux = [
        MoyenneTensionLocal(
          nom: 'Poste MT',
          type: 'Local MT',
          photos: ['/path/local_mt1.jpg'],
          dispositionsConstructives: [
            ElementControle(elementControle: 'Ventilation', conforme: false, photos: ['/path/obs_dc1.jpg']),
          ],
          cellules: [
            Cellule(
              fonction: 'Arrivée',
              type: 'Cellule MT',
              marqueModeleAnnee: 'Schneider',
              tensionAssignee: '24kV',
              pouvoirCoupure: '16kA',
              numerotation: 'C1',
              parafoudres: 'Non',
              elementsVerifies: [
                ElementControle(elementControle: 'Interrupteur', conforme: false, photos: ['/path/cell_obs1.jpg']),
              ],
            ),
          ],
        ),
      ];
      audit.basseTensionZones = [
        BasseTensionZone(
          nom: 'Atelier',
          photos: ['/path/zone_bt1.jpg'],
          observationsLibres: [
            ObservationLibre(texte: 'Câbles au sol', photos: ['/path/zone_obs1.jpg']),
          ],
          coffretsDirects: [
            CoffretArmoire(
              qrCode: 'QR1',
              nom: 'TGBT Principal',
              type: 'TGBT',
              pointsVerification: [
                PointVerification(
                  pointVerification: 'Fermeture à clé',
                  conformite: 'non',
                  observation: 'Serrure cassée',
                  photos: ['/path/coffret_pv1.jpg'],
                ),
              ],
            ),
          ],
        ),
      ];

      final registry = PdfReportService.buildPhotoNumberRegistryForTest(audit, description);

      expect(registry['/path/desc_mt1.jpg'], equals(1));
      expect(registry['/path/audit_gen1.jpg'], equals(2));
      expect(registry['/path/local_mt1.jpg'], equals(3));
      expect(registry['/path/obs_dc1.jpg'], equals(4));
      expect(registry['/path/cell_obs1.jpg'], equals(5));
      expect(registry['/path/zone_bt1.jpg'], equals(6));
      expect(registry['/path/zone_obs1.jpg'], equals(7));
      expect(registry['/path/coffret_pv1.jpg'], equals(8));
    });
  });
}
