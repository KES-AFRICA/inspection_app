import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

void main() {
  setUp(() {
    PdfReportService.initFontsForTesting();
  });

  group('Règle de Fallback Zone -> Repère sans réciproque', () {
    test('1. Quand Zone existe mais pas de Repère : Repère prend le nom de la Zone', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'm_fallback_1',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone EC wagon',
            coffretsDirects: [
              CoffretArmoire(nom: 'Armoire Directe 1', type: 'Armoire', qrCode: 'QR1'),
            ],
          ),
        ],
      );

      final pt = PriseTerre(
        localisation: 'Zone EC wagon',
        identification: 'PT-EC',
        conditionPriseTerre: 'Barette fermée',
        naturePriseTerre: 'Fond de fouille',
        methodeMesure: '62%',
        valeurMesure: 5.0,
      );

      final ddr = EssaiDeclenchementDifferentiel(
        localisation: 'Zone EC wagon',
        coffret: 'Armoire Directe 1',
        designationCircuit: 'Éclairage',
        typeDispositif: 'DDR',
        essai: 'OK',
      );

      final iso = EssaiIsolement(
        syncId: 'iso_direct',
        reperePointOrigine: 'Zone EC wagon',
        pointA: 'Armoire Directe 1',
        pointB: 'Prise 1',
        sectionCablePointA: '16 mm²',
        sectionCablePointB: '16 mm²',
        nombreCablesTestes: 1,
        isolement: 500,
        appreciation: 'Satisfaisant',
      );

      final cont = ContinuiteResistance(
        localisation: 'Zone EC wagon',
        designationTableau: 'Armoire Directe 1',
        origineMesure: 'Barrette terre',
      );

      final mesures = MesuresEssais(
        missionId: 'm_fallback_1',
        updatedAt: DateTime.now(),
        prisesTerre: [pt],
        essaisDeclenchement: [ddr],
        essaisIsolement: [iso],
        continuiteResistances: [cont],
      );

      expect(mesures.prisesTerre.length, equals(1));
      expect(mesures.essaisDeclenchement.length, equals(1));
      expect(mesures.essaisIsolement.length, equals(1));
      expect(mesures.continuiteResistances.length, equals(1));
    });

    test('2. L\'INVERSE N\'EST PAS POSSIBLE : Si Repère existe mais pas de Zone, Zone ne prend PAS le nom du Repère', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'm_fallback_2',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'Local MT Isolement',
            type: 'Technique',
            coffrets: [
              CoffretArmoire(nom: 'Cellule Arrivée', type: 'Cellule', qrCode: 'QR2'),
            ],
          ),
        ],
      );

      final ddr = EssaiDeclenchementDifferentiel(
        localisation: 'Local MT Isolement',
        coffret: 'Cellule Arrivée',
        designationCircuit: 'Disjoncteur MT',
        typeDispositif: 'DDR',
        essai: 'OK',
      );

      final cont = ContinuiteResistance(
        localisation: 'Local MT Isolement',
        designationTableau: 'Cellule Arrivée',
        origineMesure: 'Masses métalliques',
      );

      final mesures = MesuresEssais(
        missionId: 'm_fallback_2',
        updatedAt: DateTime.now(),
        essaisDeclenchement: [ddr],
        continuiteResistances: [cont],
      );

      // On s'assure que pour 'Local MT Isolement', le resolver renvoie zoneName = '' et repereName = 'Local MT Isolement'
      final locDdr = PdfReportService.resolveLocationForTesting(audit, localisationStr: ddr.localisation, coffretStr: ddr.coffret);
      expect(locDdr.zoneName, equals(''));
      expect(locDdr.repereName, equals('Local MT Isolement'));
    });
  });
}
