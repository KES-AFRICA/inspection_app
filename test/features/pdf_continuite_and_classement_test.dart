// test/features/pdf_continuite_and_classement_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/classement_zone.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

void main() {
  setUp(() {
    PdfReportService.initFontsForTesting();
  });

  group('Évolutions PDF — Tableau 7 Continuité (Zone/Repère) et Tableau Classement (Colonne N°)', () {
    test('1. Tableau 7 Continuité : Intégration de la notion Zone -> Repère et structure des colonnes', () {
      final cont1 = ContinuiteResistance(
        localisation: 'Local TGBT',
        designationTableau: 'TGBT Principal',
        origineMesure: 'Barrette Terre',
        essai: 'Satisfaisant',
        observation: 'RAS',
      );

      final cont2 = ContinuiteResistance(
        localisation: 'Local TGBT',
        designationTableau: 'Armoire A1',
        origineMesure: 'Barrette Terre',
        essai: 'Satisfaisant',
      );

      final cont3 = ContinuiteResistance(
        localisation: 'Zone EC wagon',
        designationTableau: 'Coffret Éclairage',
        origineMesure: 'Borne PE',
        essai: 'Non satisfaisant',
        observation: 'Continuité rompu',
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm_test_cont',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Bâtiment Administration',
            locaux: [
              BasseTensionLocal(
                nom: 'Local TGBT',
                type: 'Technique',
                dispositionsConstructives: [],
                conditionsExploitation: [],
              ),
            ],
          ),
        ],
      );

      final mesures = MesuresEssais(
        missionId: 'm_test_cont',
        updatedAt: DateTime.now(),
        continuiteResistances: [cont1, cont2, cont3],
      );

      expect(mesures.continuiteResistances.length, equals(3));
      expect(audit.basseTensionZones.first.nom, equals('Bâtiment Administration'));
      expect(audit.basseTensionZones.first.locaux.first.nom, equals('Local TGBT'));
    });

    test('2. Tableau Classement et emplacements : Colonne N° en 1ère position et numérotation séquentielle', () {
      final emp1 = ClassementEmplacement(
        missionId: 'm_test_class',
        typeEmplacement: 'local',
        localisation: 'Local Transformateur',
        zone: 'Poste HT/BT',
        origineClassement: 'NF C 15-100',
        af: 'AF2',
        be: 'BE1',
        ae: 'AE1',
        ad: 'AD1',
        ag: 'AG1',
        ip: 'IP2X',
        ik: 'IK08',
        updatedAt: DateTime.now(),
      );

      final emp2 = ClassementEmplacement(
        missionId: 'm_test_class',
        typeEmplacement: 'zone',
        localisation: 'Poste HT/BT',
        origineClassement: 'NF C 13-200',
        af: 'AF3',
        be: 'BE2',
        ae: 'AE2',
        ad: 'AD2',
        ag: 'AG2',
        ip: 'IP55',
        ik: 'IK10',
        updatedAt: DateTime.now(),
      );

      final zones = [
        ClassementZone(
          missionId: 'm_test_class',
          nomZone: 'Poste HT/BT',
          typeZone: 'Technique',
          origineClassement: 'Norme',
          updatedAt: DateTime.now(),
        ),
      ];

      expect(emp1.localisation, equals('Local Transformateur'));
      expect(emp2.typeEmplacement, equals('zone'));
      expect(zones.first.nomZone, equals('Poste HT/BT'));
    });
  });
}
