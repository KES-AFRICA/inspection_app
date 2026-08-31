import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Equipment Synthesis Table Enrichment Tests', () {
    test('Should extract verificationThermo and hasObservation dynamically for Armoire, TGBT, Coffret', () {
      final coffretThermoOui = CoffretArmoire(
        qrCode: 'QR001',
        nom: 'TGBT Principal',
        type: 'TGBT',
        repere: 'TGBT-1',
        verificationThermographie: true,
        description: 'Observation utilisateur sur le general',
      );

      final coffretThermoNon = CoffretArmoire(
        qrCode: 'QR002',
        nom: 'Coffret Divisionnaire',
        type: 'Coffret',
        repere: 'COFFRET-1',
        verificationThermographie: false,
        pointsVerification: [
          PointVerification(
            pointVerification: 'Interrupteur differentiel',
            conformite: 'non',
            observation: 'Defaut de serrage constate',
          ),
        ],
      );

      final coffretWithoutObs = CoffretArmoire(
        qrCode: 'QR003',
        nom: 'Armoire Climatisation',
        type: 'Armoire',
        repere: 'ARM-01',
        verificationThermographie: true,
        description: '',
        pointsVerification: [
          PointVerification(
            pointVerification: 'Presence pictogrammes',
            conformite: 'oui',
            observation: 'RAS',
          ),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'mission_equip_test',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Technique',
            coffretsDirects: [coffretThermoOui, coffretThermoNon, coffretWithoutObs],
          ),
        ],
      );

      final equipementsBT = PdfReportService.getEquipementsBTForTesting(audit, null);

      expect(equipementsBT.length, equals(3));

      // 1. TGBT Principal (Thermo Oui, Obs Slide 1 Oui)
      final eq1 = equipementsBT.firstWhere((e) => e.repere == 'TGBT-1');
      expect(eq1.verificationThermo, equals('Oui'));
      expect(eq1.hasObservation, equals('Oui'));

      // 2. Coffret Divisionnaire (Thermo Non, Obs Slide 5 Oui)
      final eq2 = equipementsBT.firstWhere((e) => e.repere == 'COFFRET-1');
      expect(eq2.verificationThermo, equals('Non'));
      expect(eq2.hasObservation, equals('Oui'));

      // 3. Armoire Climatisation (Thermo Oui, Obs RAS -> Non)
      final eq3 = equipementsBT.firstWhere((e) => e.repere == 'ARM-01');
      expect(eq3.verificationThermo, equals('Oui'));
      expect(eq3.hasObservation, equals('Non'));
    });

    test('Should only collect audited equipements from AuditInstallationsElectriques (DescriptionInstallations does not inject orphan equipements)', () {
      final desc = DescriptionInstallations.create('mission_inv_test');
      desc.inverseur = [
        InstallationItem(
          data: {
            'Marque': 'SOCOMEC',
            'Type': 'ATyS',
            'Vérification par thermographie': 'Oui',
            'Observations': 'Inverseur motorisé fonctionnel',
          },
        ),
      ];

      final equipementsBT = PdfReportService.getEquipementsBTForTesting(null, desc);
      expect(equipementsBT, isEmpty);
    });

    test('Should filter out system placeholders and neutral keywords from observation calculation', () {
      final coffretPlaceholder = CoffretArmoire(
        qrCode: 'QR004',
        nom: 'Coffret Test',
        type: 'Coffret',
        description: 'Observation équipement n°1', // System placeholder
        pointsVerification: [
          PointVerification(
            pointVerification: 'Fixation',
            conformite: 'oui',
            observation: 'Sans objet',
          ),
          PointVerification(
            pointVerification: 'Mise a la terre',
            conformite: 'oui',
            observation: '  ',
          ),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'mission_placeholder_test',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Test',
            coffretsDirects: [coffretPlaceholder],
          ),
        ],
      );

      final equipementsBT = PdfReportService.getEquipementsBTForTesting(audit, null);
      expect(equipementsBT.length, equals(1));
      expect(equipementsBT.first.hasObservation, equals('Non'));
    });
  });
}
