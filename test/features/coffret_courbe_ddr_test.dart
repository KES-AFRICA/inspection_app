import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';
import 'package:inspec_app/features/audit_installations/domain/entities/audit_installations_entities.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/backup_service.dart';

void main() {
  group('Coffret & Alimentation - Courbe & DDR Features', () {
    test('Alimentation should initialize with ddr as null by default', () {
      final alim = Alimentation(
        typeProtection: 'Disjoncteurs magnétothermiques',
        pdcKA: '10',
        calibre: '32',
        sectionCable: '6 mm²',
      );

      expect(alim.courbe, equals(''));
      expect(alim.ddr, isNull);
    });

    test('Alimentation should accept and retain Courbe and DDR values', () {
      final alim = Alimentation(
        typeProtection: 'Disjoncteurs différentiels',
        courbe: 'Courbe-C',
        ddr: '30',
        pdcKA: '10',
        calibre: '32',
        sectionCable: '6 mm²',
      );

      expect(alim.courbe, equals('Courbe-C'));
      expect(alim.ddr, equals('30'));
    });

    test('AuditInstallationsMapper should map ddr between Model and Entity bidirectionally', () {
      final model = Alimentation(
        typeProtection: 'Disjoncteurs différentiels',
        courbe: 'Courbe-D',
        ddr: '300',
        pdcKA: '25',
        calibre: '63',
        sectionCable: '16 mm²',
      );

      final entity = AuditInstallationsMapper.toAlimentationEntity(model);
      expect(entity.courbe, equals('Courbe-D'));
      expect(entity.ddr, equals('300'));

      final backToModel = AuditInstallationsMapper.toAlimentationModel(entity);
      expect(backToModel.courbe, equals('Courbe-D'));
      expect(backToModel.ddr, equals('300'));
    });

    test('BackupService serialization and deserialization should preserve ddr and remain backwards compatible', () {
      final alim = Alimentation(
        typeProtection: 'Disjoncteurs magnétothermiques',
        courbe: 'Courbe-K',
        ddr: '500',
        pdcKA: '15',
        calibre: '40',
        sectionCable: '10 mm²',
      );

      // Sérialisation
      final jsonMap = {
        'typeProtection': alim.typeProtection,
        'courbe': alim.courbe,
        'ddr': alim.ddr,
        'pdcKA': alim.pdcKA,
        'calibre': alim.calibre,
        'sectionCable': alim.sectionCable,
        'source': alim.source,
        'photos': alim.photos,
      };

      expect(jsonMap['ddr'], equals('500'));
      expect(jsonMap['courbe'], equals('Courbe-K'));

      // Désérialisation avec legacy JSON (sans le champ ddr)
      final legacyJson = Map<String, dynamic>.from(jsonMap)..remove('ddr');
      final legacyAlim = Alimentation(
        typeProtection: legacyJson['typeProtection'] as String? ?? '',
        courbe: legacyJson['courbe'] as String? ?? '',
        ddr: legacyJson['ddr'] as String?,
        pdcKA: legacyJson['pdcKA'] as String? ?? '',
        calibre: legacyJson['calibre'] as String? ?? '',
        sectionCable: legacyJson['sectionCable'] as String? ?? '',
        source: legacyJson['source'] as String? ?? '',
      );

      expect(legacyAlim.ddr, isNull);
      expect(legacyAlim.courbe, equals('Courbe-K'));
    });
  });
}
