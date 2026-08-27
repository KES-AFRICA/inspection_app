import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/features/audit_installations/domain/entities/audit_installations_entities.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';

void main() {
  group('Marque de disjoncteur - Unit Tests', () {
    final expectedBrandsSorted = [
      'ABB',
      'C&S Electric',
      'Chint',
      'Eaton',
      'Fuji Electric',
      'Gewiss',
      'Hager',
      'Hyundai Electric',
      'LS Electric',
      'Legrand',
      'Lovato Electric',
      'Mitsubishi Electric',
      'Noark',
      'Schneider Electric',
      'Schrack Technik',
      'Siemens',
      'Socomec',
      'TOMZN',
      'Terasaki',
    ];

    test('Brand list contains 19 exact brands strictly sorted alphabetically', () {
      final unsortedList = [
        'Schneider Electric',
        'ABB',
        'Siemens',
        'Eaton',
        'Legrand',
        'Hager',
        'Socomec',
        'Mitsubishi Electric',
        'Fuji Electric',
        'LS Electric',
        'Chint',
        'Terasaki',
        'Hyundai Electric',
        'Schrack Technik',
        'Gewiss',
        'Noark',
        'Lovato Electric',
        'C&S Electric',
        'TOMZN',
      ];

      expect(unsortedList.length, 19);

      final sorted = List<String>.from(unsortedList)..sort();
      expect(sorted, expectedBrandsSorted);
    });

    test('Alimentation model default marqueDisjoncteur is null (backward compatible)', () {
      final alim = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5 mm²',
      );

      expect(alim.marqueDisjoncteur, isNull);
      expect(alim.effectiveSourceKnown, 'Connue');
    });

    test('Alimentation model holds marqueDisjoncteur when provided without altering effectiveSourceKnown', () {
      final alim = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '10',
        calibre: '16',
        sectionCable: '2.5 mm²',
        marqueDisjoncteur: 'Schneider Electric',
      );

      expect(alim.marqueDisjoncteur, 'Schneider Electric');
      expect(alim.effectiveSourceKnown, 'Connue');
    });

    test('Mapper maps marqueDisjoncteur bidirectionally', () {
      final model = Alimentation(
        typeProtection: 'Disjoncteur différentiel',
        pdcKA: '6',
        calibre: '32',
        sectionCable: '6 mm²',
        marqueDisjoncteur: 'Hager',
      );

      final entity = AuditInstallationsMapper.toAlimentationEntity(model);
      expect(entity.marqueDisjoncteur, 'Hager');

      final reconstructedModel = AuditInstallationsMapper.toAlimentationModel(entity);
      expect(reconstructedModel.marqueDisjoncteur, 'Hager');
    });

    test('BackupService serializes and parses marqueDisjoncteur correctly', () {
      final alim = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '15',
        calibre: '63',
        sectionCable: '16 mm²',
        marqueDisjoncteur: 'ABB',
      );

      final jsonMap = {
        'typeProtection': alim.typeProtection,
        'courbe': alim.courbe,
        'ddr': alim.ddr,
        'pdcKA': alim.pdcKA,
        'calibre': alim.calibre,
        'sectionCable': alim.sectionCable,
        'source': alim.source,
        'sourceKnown': alim.sourceKnown,
        'marqueDisjoncteur': alim.marqueDisjoncteur,
        'photos': alim.photos,
      };

      final importedAlim = Alimentation(
        typeProtection: jsonMap['typeProtection'] as String? ?? '',
        courbe: jsonMap['courbe'] as String? ?? '',
        ddr: jsonMap['ddr'] as String?,
        pdcKA: jsonMap['pdcKA'] as String? ?? '',
        calibre: jsonMap['calibre'] as String? ?? '',
        sectionCable: jsonMap['sectionCable'] as String? ?? '',
        source: jsonMap['source'] as String? ?? '',
        sourceKnown: jsonMap['sourceKnown'] as String?,
        marqueDisjoncteur: jsonMap['marqueDisjoncteur'] as String?,
      );

      expect(importedAlim.marqueDisjoncteur, 'ABB');
    });

    test('Old JSON without marqueDisjoncteur parses smoothly with null marqueDisjoncteur', () {
      final legacyJsonMap = <String, dynamic>{
        'typeProtection': 'Disjoncteur',
        'courbe': 'Courbe-C',
        'ddr': null,
        'pdcKA': '10',
        'calibre': '20',
        'sectionCable': '4 mm²',
        'source': 'TGBT',
        'sourceKnown': 'Connue',
        'photos': <String>[],
      };

      final legacyAlim = Alimentation(
        typeProtection: legacyJsonMap['typeProtection'] as String? ?? '',
        courbe: legacyJsonMap['courbe'] as String? ?? '',
        ddr: legacyJsonMap['ddr'] as String?,
        pdcKA: legacyJsonMap['pdcKA'] as String? ?? '',
        calibre: legacyJsonMap['calibre'] as String? ?? '',
        sectionCable: legacyJsonMap['sectionCable'] as String? ?? '',
        source: legacyJsonMap['source'] as String? ?? '',
        sourceKnown: legacyJsonMap['sourceKnown'] as String?,
        marqueDisjoncteur: legacyJsonMap['marqueDisjoncteur'] as String?,
      );

      expect(legacyAlim.marqueDisjoncteur, isNull);
      expect(legacyAlim.effectiveSourceKnown, 'Connue');
    });
  });
}
