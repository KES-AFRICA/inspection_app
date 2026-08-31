import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PdfReportService.initFontsForTesting();
  });

  group('PDF Observations Synthesis Evolution — Unit Tests', () {
    test('1. Modèle _ObsRecap - Rétrocompatibilité et typage des champs', () {
      final obsExplicit = PdfReportService.createObsRecapForTesting(
        zoneName: 'Zone A',
        localName: 'Local 1',
        coffret: 'TGBT',
        observation: 'Défaut de terre',
        refNorm: 'art 12',
        priorite: '1',
      );

      expect(obsExplicit.zoneName, equals('Zone A'));
      expect(obsExplicit.localName, equals('Local 1'));
      expect(obsExplicit.localisation, equals('Zone A / Local 1'));

      final obsLegacy = PdfReportService.createObsRecapForTesting(
        localisation: 'Zone B / Local 2',
        coffret: 'Armoire 1',
        observation: 'Porte non fermée',
        refNorm: 'art 15',
        priorite: '2',
      );

      expect(obsLegacy.zoneName, equals('Zone B'));
      expect(obsLegacy.localName, equals('Local 2'));
      expect(obsLegacy.localisation, equals('Zone B / Local 2'));

      final obsLocalSeul = PdfReportService.createObsRecapForTesting(
        localName: 'Local Technique',
        coffret: 'Transformateur',
        observation: 'Absence d\'extincteur',
        refNorm: 'art 20',
        priorite: '1',
      );

      expect(obsLocalSeul.zoneName, equals(''));
      expect(obsLocalSeul.localName, equals('Local Technique'));
      expect(obsLocalSeul.localisation, equals('Local Technique'));
    });

    test('2. Groupement hiérarchique 3 niveaux (Zone -> Local -> Équipement)', () {
      final obsList = [
        // Case A : Zone Prod / Local 1 / TGBT-01 (2 obs)
        PdfReportService.createObsRecapForTesting(
          zoneName: 'Zone Production',
          localName: 'Local 1',
          coffret: 'TGBT-01',
          observation: 'Obs 1',
          refNorm: 'art 1',
          priorite: '1',
        ),
        PdfReportService.createObsRecapForTesting(
          zoneName: 'Zone Production',
          localName: 'Local 1',
          coffret: 'TGBT-01',
          observation: 'Obs 2',
          refNorm: 'art 2',
          priorite: '2',
        ),

        // Case B : Local hors zone (Zone '', Local 'Local Isolation', Poste HTA)
        PdfReportService.createObsRecapForTesting(
          zoneName: '',
          localName: 'Local Isolation',
          coffret: 'Poste HTA',
          observation: 'Obs 3',
          refNorm: 'art 3',
          priorite: '1',
        ),

        // Case C : Équipement direct en zone (Zone 'Zone Extérieure', Local '', Armoire Éclairage)
        PdfReportService.createObsRecapForTesting(
          zoneName: 'Zone Extérieure',
          localName: '',
          coffret: 'Armoire Éclairage',
          observation: 'Obs 4',
          refNorm: 'art 4',
          priorite: '3',
        ),
      ];

      final zoneGroups = PdfReportService.groupByZoneLocalEquipForTesting(obsList);

      // On s'attend à 3 ZoneGroups: 'Zone Production', '', 'Zone Extérieure'
      expect(zoneGroups.length, equals(3));

      // Zone Production
      final zg1 = zoneGroups[0];
      expect(zg1.zoneName, equals('Zone Production'));
      expect(zg1.localGroups.length, equals(1));
      expect(zg1.localGroups[0].localName, equals('Local 1'));
      expect(zg1.localGroups[0].equipGroups.length, equals(1));
      expect(zg1.localGroups[0].equipGroups[0].coffret, equals('TGBT-01'));
      expect(zg1.localGroups[0].equipGroups[0].items.length, equals(2));

      // Zone Hors Zone ('')
      final zg2 = zoneGroups[1];
      expect(zg2.zoneName, equals(''));
      expect(zg2.localGroups.length, equals(1));
      expect(zg2.localGroups[0].localName, equals('Local Isolation'));
      expect(zg2.localGroups[0].equipGroups[0].coffret, equals('Poste HTA'));
      expect(zg2.localGroups[0].equipGroups[0].items.length, equals(1));

      // Zone Extérieure
      final zg3 = zoneGroups[2];
      expect(zg3.zoneName, equals('Zone Extérieure'));
      expect(zg3.localGroups.length, equals(1));
      expect(zg3.localGroups[0].localName, equals(''));
      expect(zg3.localGroups[0].equipGroups[0].coffret, equals('Armoire Éclairage'));
      expect(zg3.localGroups[0].equipGroups[0].items.length, equals(1));
    });

    test('3. Rendu unifié des tableaux d\'observations MT et BT à 5 colonnes', () {
      final obsList = [
        PdfReportService.createObsRecapForTesting(
          zoneName: 'Zone Nord',
          localName: 'Local TGBT',
          coffret: 'TGBT Principal',
          observation: 'Schéma unifilaire manquant',
          refNorm: 'art 4-1',
          priorite: '1',
        ),
        PdfReportService.createObsRecapForTesting(
          zoneName: 'Zone Nord',
          localName: 'Local TGBT',
          coffret: 'TGBT Principal',
          observation: 'Plastron manquant',
          refNorm: 'art 4-2',
          priorite: '2',
        ),
      ];

      final widgets = PdfReportService.buildObsRecapTableUnifieForTesting(obsList);

      // On doit avoir 3 widgets (En-tête L1, En-tête L2, et Table du corps)
      expect(widgets.length, equals(3));
      expect(widgets[0], isA<pw.Table>());
      expect(widgets[1], isA<pw.Table>());
      expect(widgets[2], isA<pw.Table>());
    });
  });
}
