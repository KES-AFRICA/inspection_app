import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  group('PDF Photo Section — Separation Bars & Zone Grouping', () {
    test('Zones and Locaux photo groups maintain exact hierarchy', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'mission_test',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Production',
            photos: ['/tmp/zone1.jpg'],
            locaux: [
              BasseTensionLocal(
                nom: 'Local TGBT',
                type: 'local',
                photos: ['/tmp/local1.jpg'],
                coffrets: [
                  CoffretArmoire(
                    qrCode: 'QR_1',
                    nom: 'TGBT Main',
                    type: 'Armoire',
                    photosExternes: ['/tmp/c1_ext.jpg'],
                  )
                ],
              )
            ],
          )
        ],
      );

      final zone = audit.basseTensionZones.first;
      expect(zone.nom, equals('Zone Production'));
      expect(zone.photos, contains('/tmp/zone1.jpg'));

      final local = zone.locaux.first;
      expect(local.nom, equals('Local TGBT'));
      expect(local.photos, contains('/tmp/local1.jpg'));

      final coffret = local.coffrets.first;
      expect(coffret.nom, equals('TGBT Main'));
      expect(coffret.photosExternes, contains('/tmp/c1_ext.jpg'));
    });
  });
}
