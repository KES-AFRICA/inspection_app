import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/features/audit_installations/domain/entities/audit_installations_entities.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Zones et Locaux à risque - Models & Backward Compatibility', () {
    test('Default value for isRiskZone should be false', () {
      final mtLocal = MoyenneTensionLocal(nom: 'Local MT 01', type: 'LOCAL_TRANSFORMATEUR');
      final mtZone = MoyenneTensionZone(nom: 'Zone MT Nord');
      final btZone = BasseTensionZone(nom: 'Zone BT Atelier');
      final btLocal = BasseTensionLocal(nom: 'Local TGBT', type: 'LOCAL_TGBT');

      expect(mtLocal.isRiskZone, isFalse);
      expect(mtZone.isRiskZone, isFalse);
      expect(btZone.isRiskZone, isFalse);
      expect(btLocal.isRiskZone, isFalse);
    });

    test('isRiskZone can be set to true and mapped to Entities and back', () {
      final mtLocalModel = MoyenneTensionLocal(nom: 'Salle Batteries', type: 'LOCAL_ELECTRIQUE', isRiskZone: true);
      final mtZoneModel = MoyenneTensionZone(nom: 'Stockage Hydrocarbures', isRiskZone: true);
      final btLocalModel = BasseTensionLocal(nom: 'Local Transfo MT/BT', type: 'LOCAL_TRANSFORMATEUR', isRiskZone: true);

      final mtLocalEntity = AuditInstallationsMapper.toMoyenneTensionLocalEntity(mtLocalModel);
      expect(mtLocalEntity.isRiskZone, isTrue);

      final backMtLocalModel = AuditInstallationsMapper.toMoyenneTensionLocalModel(mtLocalEntity);
      expect(backMtLocalModel.isRiskZone, isTrue);

      final mtZoneEntity = AuditInstallationsMapper.toMoyenneTensionZoneEntity(mtZoneModel);
      expect(mtZoneEntity.isRiskZone, isTrue);

      final btLocalEntity = AuditInstallationsMapper.toBasseTensionLocalEntity(btLocalModel);
      expect(btLocalEntity.isRiskZone, isTrue);
    });
  });

  group('Zones et Locaux à risque - Dynamic PDF Collection Logic', () {
    test('Should return empty list when no risk zone or local is flagged', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'mission_no_risk',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [MoyenneTensionLocal(nom: 'Local Normal', type: 'LOCAL_ELECTRIQUE', isRiskZone: false)],
        moyenneTensionZones: [MoyenneTensionZone(nom: 'Zone standard', isRiskZone: false)],
        basseTensionZones: [BasseTensionZone(nom: 'Zone bureau', isRiskZone: false)],
      );

      final result = PdfReportService.collectRiskZonesAndLocauxForTesting(audit);
      expect(result, isEmpty);
    });

    test('Should collect and format risk zones and locales in logical order', () {
      final audit = AuditInstallationsElectriques(
        missionId: 'mission_with_risk',
        updatedAt: DateTime.now(),
        moyenneTensionLocaux: [
          MoyenneTensionLocal(nom: 'MT Poste Source', type: 'LOCAL_ELECTRIQUE', isRiskZone: true),
        ],
        moyenneTensionZones: [
          MoyenneTensionZone(
            nom: 'Zone hydrocarbures',
            isRiskZone: true,
            locaux: [
              MoyenneTensionLocal(nom: 'Local transformateur MT', type: 'LOCAL_TRANSFORMATEUR', isRiskZone: true),
            ],
          ),
        ],
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone stockage Gaz',
            isRiskZone: true,
            locaux: [
              BasseTensionLocal(nom: 'Salle des batteries', type: 'LOCAL_BT', isRiskZone: true),
            ],
          ),
        ],
      );

      final result = PdfReportService.collectRiskZonesAndLocauxForTesting(audit);
      expect(result.length, equals(5));
      expect(result[0], equals('Local MT Poste Source'));
      expect(result[1], equals('Zone hydrocarbures'));
      expect(result[2], equals('Local transformateur MT'));
      expect(result[3], equals('Zone stockage Gaz'));
      expect(result[4], equals('Salle des batteries'));
    });
  });
}
