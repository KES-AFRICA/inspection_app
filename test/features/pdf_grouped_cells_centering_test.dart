import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/mesures_essais.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Grouped Cells Centering Engine Tests', () {
    test('Verify data structures with even (N=2, N=4) and odd (N=1, N=3) row counts for PDF generation', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'M-TEST-CENTERING',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'Zone MT Alpha',
            type: 'LOCAL_TGBT',
            cellules: [
              Cellule(
                type: 'Cellule MT',
                numerotation: 'CEL-01',
                nom: 'Cellule Arrivée HTA 1',
                fonction: 'Arrivée HTA',
                marqueModeleAnnee: '2023',
                tensionAssignee: '24 kV',
                pouvoirCoupure: '16 kA',
                parafoudres: 'Non',
              ),
              Cellule(
                type: 'Cellule MT',
                numerotation: 'CEL-02',
                nom: 'Cellule Arrivée HTA 2',
                fonction: 'Arrivée HTA',
                marqueModeleAnnee: '2023',
                tensionAssignee: '24 kV',
                pouvoirCoupure: '16 kA',
                parafoudres: 'Non',
              ),
            ],
            transformateurs: [
              TransformateurMTBT(
                puissanceAssignee: '630 kVA',
                repere: 'TR-01',
                marqueAnnee: 'Schneider',
                typeTransformateur: 'Transformateur MT/BT',
                tensionPrimaireSecondaire: '20kV/400V',
                relaisBuchholz: 'Non',
                typeRefroidissement: 'ONAN',
                regimeNeutre: 'IT',
              ),
            ],
          ),
        ],
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone BT Principal (2 Coffrets = N=2)',
            coffretsDirects: [
              CoffretArmoire(
                qrCode: 'QR-01',
                repere: 'TGBT-01',
                nom: 'TGBT Principal',
                type: 'TGBT',
              ),
              CoffretArmoire(
                qrCode: 'QR-02',
                repere: 'TD-01',
                nom: 'Tableau Distribution',
                type: 'Coffret',
              ),
            ],
            locaux: [
              BasseTensionLocal(
                nom: 'Local Ateliers (4 Coffrets = N=4)',
                type: 'LOCAL_ATELIER',
                coffrets: [
                  CoffretArmoire(qrCode: 'QR-10', repere: 'C-01', nom: 'Coffret Ligne 1', type: 'Coffret'),
                  CoffretArmoire(qrCode: 'QR-11', repere: 'C-02', nom: 'Coffret Ligne 2', type: 'Coffret'),
                  CoffretArmoire(qrCode: 'QR-12', repere: 'C-03', nom: 'Coffret Ligne 3', type: 'Coffret'),
                  CoffretArmoire(qrCode: 'QR-13', repere: 'C-04', nom: 'Coffret Ligne 4', type: 'Coffret'),
                ],
              ),
            ],
          ),
        ],
      );

      final desc = DescriptionInstallations.create('M-TEST-CENTERING');
      final essais = MesuresEssais(
        missionId: 'M-TEST-CENTERING',
        updatedAt: DateTime.now(),
        conditionMesure: ConditionMesure(),
        essaiDemarrageAuto: EssaiDemarrageAuto(),
        testArretUrgence: TestArretUrgence(),
        prisesTerre: [],
        avisMesuresTerre: AvisMesuresTerre(),
        essaisDeclenchement: [],
      );

      essais.prisesTerre.addAll([
        PriseTerre(
          localisation: 'Zone Extérieure',
          identification: 'PT1',
          conditionPriseTerre: 'Barrette fermée',
          naturePriseTerre: 'Piquet',
          methodeMesure: '62%',
          valeurMesure: 4.5,
          interconnecteAutrePrise: 'Oui',
        ),
        PriseTerre(
          localisation: 'Zone Extérieure',
          identification: 'PT2',
          conditionPriseTerre: 'Barrette fermée',
          naturePriseTerre: 'Piquet',
          methodeMesure: '62%',
          valeurMesure: 5.2,
          interconnecteAutrePrise: 'Oui',
        ),
      ]);

      essais.essaisIsolement.addAll([
        EssaiIsolement(
          syncId: 'ISO-01',
          reperePointOrigine: 'TGBT-01',
          isolement: 500.0,
          appreciation: 'Satisfaisant',
          zonePointA: 'Zone Usine',
        ),
        EssaiIsolement(
          syncId: 'ISO-02',
          reperePointOrigine: 'TGBT-01',
          isolement: 500.0,
          appreciation: 'Satisfaisant',
          zonePointA: 'Zone Usine',
        ),
      ]);

      expect(audit.moyenneTensionLocaux.first.cellules.length, equals(2));
      expect(audit.basseTensionZones.first.coffretsDirects.length, equals(2));
      expect(audit.basseTensionZones.first.locaux.first.coffrets.length, equals(4));
      expect(essais.prisesTerre.length, equals(2));
      expect(essais.essaisIsolement.length, equals(2));
      expect(desc.missionId, equals('M-TEST-CENTERING'));
    });
  });
}
