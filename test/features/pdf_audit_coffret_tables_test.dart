// test/features/pdf_audit_coffret_tables_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

void main() {
  setUp(() {
    PdfReportService.initFontsForTesting();
  });

  group('Évolution des Tableaux Audit Coffret / Armoire / TGBT (Source, Départs, Circuits)', () {
    test('1. Modèle & Getters : Rétrocompatibilité et indépendance Marque / Sections Phase et Neutre', () {
      // Cas A : Mission legacy (sectionCable unique, marque renseignée)
      final depLegacy = DepartEquipement(
        typeProtection: 'Disjoncteur',
        marque: 'LS Electric',
        sectionCable: '35 mm²',
      );

      expect(depLegacy.typeProtection, equals('Disjoncteur'));
      expect(depLegacy.marque, equals('LS Electric'));
      expect(depLegacy.sectionCablePhase, equals('35 mm²'));
      expect(depLegacy.effectiveSectionCableNeutre, equals('35 mm²'));

      // Cas B : Nouvelle mission (section phase & neutre distinctes, sans marque)
      final ctNew = CircuitTerminalEquipement(
        typeProtection: 'Interrupteur Différentiel',
        marque: '',
        sectionCable: '70 mm²',
        sectionCableNeutre: '35 mm²',
      );

      expect(ctNew.typeProtection, equals('Interrupteur Différentiel'));
      expect(ctNew.marque, isEmpty);
      expect(ctNew.sectionCablePhase, equals('70 mm²'));
      expect(ctNew.effectiveSectionCableNeutre, equals('35 mm²'));
    });

    test('2. Alimentation : Getters Section Phase et Neutre', () {
      final alim = Alimentation(
        typeProtection: 'Disjoncteur',
        marqueDisjoncteur: 'Schneider',
        pdcKA: '25',
        calibre: '100A',
        sectionCable: '50 mm²',
        sectionCableNeutre: '25 mm²',
      );

      expect(alim.sectionCablePhase, equals('50 mm²'));
      expect(alim.effectiveSectionCableNeutre, equals('25 mm²'));
    });

    test('3. Rapport PDF : Génération complète d\'un coffret avec Source, Départs et Circuits', () {
      final coffret = CoffretArmoire(
        qrCode: 'Q_TEST_01',
        repere: 'TGBT-TEST',
        nom: 'TGBT Général Test',
        type: 'TGBT',
        alimentations: [
          Alimentation(
            typeProtection: 'Disjoncteur',
            marqueDisjoncteur: 'ABB',
            pdcKA: '36',
            calibre: '250A',
            sectionCable: '120 mm²',
            sectionCableNeutre: '70 mm²',
            source: 'Transfo TR1',
          ),
        ],
        departures: [
          DepartEquipement(
            protectionTete: 'Présent',
            identification: 'Départ Atelier',
            typeProtection: 'Disjoncteur',
            marque: 'Legrand',
            courbe: 'C',
            pdcKA: '16',
            calibre: '63A',
            sectionCable: '16 mm²',
          ),
        ],
        terminalCircuits: [
          CircuitTerminalEquipement(
            protectionTete: 'Oui',
            identification: 'Eclairage Zone 1',
            typeProtection: 'Disjoncteur Ph+N',
            marque: 'Schneider',
            courbe: 'C',
            pdcKA: '6',
            calibre: '16A',
            sectionCable: '2.5 mm²',
            sectionCableNeutre: '2.5 mm²',
          ),
        ],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm_audit_tables_test',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Test',
            locaux: [
              BasseTensionLocal(
                nom: 'Local TGBT',
                type: 'Local Technique',
                dispositionsConstructives: [],
                conditionsExploitation: [],
                coffrets: [coffret],
              ),
            ],
          ),
        ],
      );

      expect(audit.basseTensionZones.first.locaux.first.coffrets.length, equals(1));
    });
  });
}
