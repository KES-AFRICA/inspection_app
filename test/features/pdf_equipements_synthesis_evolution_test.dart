// test/features/pdf_equipements_synthesis_evolution_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/services/pdf/pdf_report_service.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  setUp(() {
    PdfReportService.initFontsForTesting();
  });

  group('Évolution Synthèse des Équipements — Validation des 10 Cas Métier', () {
    test('Cas 1 : Zone -> Local -> Plusieurs Équipements', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'm1',
        updatedAt: DateTime.now(),
        moyenneTensionZones: [
          MoyenneTensionZone(
            nom: 'Zone Production',
            locaux: [
              MoyenneTensionLocal(
                nom: 'TGBT Local 1',
                type: 'Poste HT',
                dispositionsConstructives: [],
                conditionsExploitation: [],
                coffrets: [
                  CoffretArmoire(qrCode: 'Q1', repere: 'TGBT-01', nom: 'TGBT-01', type: 'TGBT'),
                  CoffretArmoire(qrCode: 'Q2', repere: 'TGBT-02', nom: 'TGBT-02', type: 'TGBT'),
                ],
              ),
            ],
          ),
        ],
      );

      final items = PdfReportService.collectEquipementsMTForTesting(audit);
      expect(items.length, equals(2));
      expect(items[0].zoneName, equals('Zone Production'));
      expect(items[0].localName, equals('TGBT Local 1'));
      expect(items[0].repere, equals('TGBT-01'));
      expect(items[1].zoneName, equals('Zone Production'));
      expect(items[1].localName, equals('TGBT Local 1'));
      expect(items[1].repere, equals('TGBT-02'));
    });

    test('Cas 2 : Zone -> Plusieurs Locaux -> Plusieurs Équipements par local', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'm2',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone A',
            locaux: [
              BasseTensionLocal(
                nom: 'Local 1',
                type: 'Local Technique',
                dispositionsConstructives: [],
                conditionsExploitation: [],
                coffrets: [
                  CoffretArmoire(qrCode: 'Q1', repere: 'EQ-1', nom: 'Équipement 1', type: 'TGBT'),
                  CoffretArmoire(qrCode: 'Q2', repere: 'EQ-2', nom: 'Équipement 2', type: 'ARMOIRE_ELECTRIQUE'),
                ],
              ),
              BasseTensionLocal(
                nom: 'Local 2',
                type: 'Local Technique',
                dispositionsConstructives: [],
                conditionsExploitation: [],
                coffrets: [
                  CoffretArmoire(qrCode: 'Q3', repere: 'EQ-3', nom: 'Équipement 3', type: 'COFFRET_ELECTRIQUE'),
                  CoffretArmoire(qrCode: 'Q4', repere: 'EQ-4', nom: 'Équipement 4', type: 'COFFRET_ELECTRIQUE'),
                ],
              ),
            ],
          ),
        ],
      );

      final items = PdfReportService.getEquipementsBTForTesting(audit, null);
      expect(items.length, equals(4));
      expect(items[0].zoneName, equals('Zone A'));
      expect(items[0].localName, equals('Local 1'));
      expect(items[2].zoneName, equals('Zone A'));
      expect(items[2].localName, equals('Local 2'));
    });

    test('Cas 3 : Local hors zone -> Plusieurs Équipements (Zone vide)', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'm3',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'Local Électrique Isolation',
            type: 'Local Technique',
            dispositionsConstructives: [],
            conditionsExploitation: [],
            coffrets: [
              CoffretArmoire(qrCode: 'Q1', repere: 'TGBT-01', nom: 'TGBT-01', type: 'TGBT'),
            ],
          ),
        ],
      );

      final items = PdfReportService.collectEquipementsMTForTesting(audit);
      expect(items.length, equals(1));
      expect(items[0].zoneName, isEmpty);
      expect(items[0].localName, equals('Local Électrique Isolation'));
    });

    test('Cas 4 : Zone -> Équipement directement rattaché à la zone (Local vide)', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'm4',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Extérieure',
            coffretsDirects: [
              CoffretArmoire(qrCode: 'Q1', repere: 'Armoire-01', nom: 'Armoire-01', type: 'ARMOIRE_ELECTRIQUE'),
            ],
          ),
        ],
      );

      final items = PdfReportService.getEquipementsBTForTesting(audit, null);
      expect(items.length, equals(1));
      expect(items[0].zoneName, equals('Zone Extérieure'));
      expect(items[0].localName, isEmpty);
      expect(items[0].repere, equals('Armoire-01'));
    });

    test('Cas 5 & 8 : Génération de la table des équipements et construction sans crash', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'm5',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Principale',
            locaux: [
              BasseTensionLocal(
                nom: 'Local HT',
                type: 'Poste HT',
                dispositionsConstructives: [],
                conditionsExploitation: [],
                coffrets: [
                  CoffretArmoire(qrCode: 'Q1', repere: 'TGBT-MAIN', nom: 'TGBT Principal', type: 'TGBT'),
                ],
              ),
            ],
          ),
        ],
      );

      final items = PdfReportService.getEquipementsBTForTesting(audit, null);
      final widget = PdfReportService.buildEquipementsTableForTesting(items);
      expect(widget, isNotNull);
      expect(widget, isA<pw.Column>());
    });
  });
}
