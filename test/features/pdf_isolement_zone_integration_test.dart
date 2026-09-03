import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  group('PDF Section II - Tableau 3 Essais Isolement - Intégration Zone', () {
    test('1. Vérification de l\'absence d\'essais -> Sans objet', () {
      final mesures = MesuresEssais(
        missionId: 'mission_1',
        updatedAt: DateTime.now(),
        essaisIsolement: [],
      );

      expect(mesures.essaisIsolement.isEmpty, isTrue);
    });

    test('2. Résolution des zones et regroupement multi-essais par Zone', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'mission_1',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone EC wagon',
            locaux: [
              BasseTensionLocal(nom: 'Local Arrivée Eneo', type: 'Technique', coffrets: []),
            ],
          ),
          BasseTensionZone(
            nom: 'SS-2 BV/DG',
            locaux: [
              BasseTensionLocal(nom: 'LOCAL TGBT', type: 'Technique', coffrets: []),
            ],
          ),
        ],
      );

      final essais = [
        EssaiIsolement(
          syncId: 'iso_1',
          reperePointOrigine: 'Zone EC wagon',
          pointA: 'ARMOIRE - TGBT EC',
          pointB: 'Coffret Prise Atelier EC',
          sectionCablePointA: '50 mm²',
          sectionCablePointB: '50 mm²',
          nombreCablesTestes: 1,
          isolement: 500,
          appreciation: 'Satisfaisant',
        ),
        EssaiIsolement(
          syncId: 'iso_2',
          reperePointOrigine: 'LOCAL TGBT',
          pointA: 'ARMOIRE - Coffret Départ Climatisation',
          pointB: 'Armoire Clim individuelle Zone 3',
          sectionCablePointA: '70 mm²',
          sectionCablePointB: '70 mm²',
          nombreCablesTestes: 100,
          isolement: 360,
          appreciation: 'Non satisfaisant',
        ),
        EssaiIsolement(
          syncId: 'iso_3',
          reperePointOrigine: 'SS-2 BV/DG',
          pointA: 'Armoire Clim individuelle Zone 3',
          pointB: 'ARMOIRE - E02',
          sectionCablePointA: '95 mm²',
          sectionCablePointB: '95 mm²',
          nombreCablesTestes: 2,
          isolement: 0,
          appreciation: 'Sans objet',
        ),
        EssaiIsolement(
          syncId: 'iso_4',
          reperePointOrigine: 'Local Arrivée Eneo - Zone EC wagon',
          pointA: 'Local Arrivée Eneo - Cellule Cellule Arrivée',
          pointB: 'Zone EC wagon - ARMOIRE - TGBT EC',
          sectionCablePointA: '-',
          sectionCablePointB: '-',
          nombreCablesTestes: 50,
          isolement: 2500,
          appreciation: 'Satisfaisant',
        ),
      ];

      final mesures = MesuresEssais(
        missionId: 'mission_1',
        updatedAt: DateTime.now(),
        essaisIsolement: essais,
      );

      expect(mesures.essaisIsolement.length, equals(4));
      expect(mesures.essaisIsolement[0].reperePointOrigine, equals('Zone EC wagon'));
      expect(mesures.essaisIsolement[1].reperePointOrigine, equals('LOCAL TGBT'));
      expect(audit.basseTensionZones[1].locaux[0].nom, equals('LOCAL TGBT'));
      expect(audit.basseTensionZones[1].nom, equals('SS-2 BV/DG'));
    });
  });
}
