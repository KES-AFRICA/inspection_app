import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';
import 'package:inspec_app/services/backup_service.dart';

void main() {
  group('Alimentation Courbe & Backward Compatibility Tests', () {
    test('Should instantiate Alimentation with optional courbe defaulting to empty string', () {
      final alim = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5 mm²',
      );

      expect(alim.courbe, equals(''));
      expect(alim.typeProtection, equals('Disjoncteur'));
    });

    test('Should map Alimentation to AlimentationEntity and vice versa including courbe', () {
      final alim = Alimentation(
        typeProtection: 'Disjoncteur',
        courbe: 'C',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5 mm²',
      );

      final entity = AuditInstallationsMapper.toAlimentationEntity(alim);
      expect(entity.courbe, equals('C'));

      final backToModel = AuditInstallationsMapper.toAlimentationModel(entity);
      expect(backToModel.courbe, equals('C'));
    });

    test('Should handle backup serialization & deserialization of Alimentation with courbe', () {
      final alim = Alimentation(
        typeProtection: 'Disjoncteur',
        courbe: 'D',
        pdcKA: '25',
        calibre: '32',
        sectionCable: '6 mm²',
        source: 'TGBT',
      );

      // Serialize
      final jsonMap = {
        'typeProtection': alim.typeProtection,
        'courbe': alim.courbe,
        'pdcKA': alim.pdcKA,
        'calibre': alim.calibre,
        'sectionCable': alim.sectionCable,
        'source': alim.source,
        'photos': alim.photos,
      };

      // Deserialization with legacy missing courbe field
      final legacyJson = Map<String, dynamic>.from(jsonMap)..remove('courbe');
      final legacyAlim = Alimentation(
        typeProtection: legacyJson['typeProtection'] as String? ?? '',
        courbe: legacyJson['courbe'] as String? ?? '',
        pdcKA: legacyJson['pdcKA'] as String? ?? '',
        calibre: legacyJson['sectionCable'] as String? ?? '',
        sectionCable: legacyJson['sectionCable'] as String? ?? '',
      );

      expect(legacyAlim.courbe, equals(''));
    });
  });
}
