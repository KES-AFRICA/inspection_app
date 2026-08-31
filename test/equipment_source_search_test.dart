import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/equipment_source_search_service.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  group('EquipmentSourceSearchService Tests', () {
    test('normalizeString should strip accents, punctuation, and lowercase', () {
      expect(EquipmentSourceSearchService.normalizeString('TGBT Électrique #1!'), 'tgbt electrique 1');
      expect(EquipmentSourceSearchService.normalizeString('Armoire   ATEX -- 02'), 'armoire atex 02');
    });

    test('calculateSimilarityScore exact and partial matches', () {
      expect(EquipmentSourceSearchService.calculateSimilarityScore('TGBT PRINCIPAL', 'tgbt principal'), 1.0);
      expect(EquipmentSourceSearchService.calculateSimilarityScore('TGBT PRINCIPAL', 'tgbt'), 0.8);
      expect(EquipmentSourceSearchService.calculateSimilarityScore('ARMOIRE ATELIER', 'transformateur'), 0.0);
    });

    test('DepartEquipement model default values and copyWith', () {
      final dep = DepartEquipement(identification: 'D1', calibre: '16');
      expect(dep.identification, 'D1');
      expect(dep.calibre, '16');
      expect(dep.protectionTete, 'Présent');

      final copy = dep.copyWith(calibre: '32');
      expect(copy.identification, 'D1');
      expect(copy.calibre, '32');
    });

    test('CircuitTerminalEquipement model default values and copyWith', () {
      final ct = CircuitTerminalEquipement(identification: 'C1', sectionCable: '2.5 mm²');
      expect(ct.identification, 'C1');
      expect(ct.sectionCable, '2.5 mm²');
      expect(ct.protectionTete, 'Oui');

      final copy = ct.copyWith(sectionCable: '4 mm²');
      expect(copy.identification, 'C1');
      expect(copy.sectionCable, '4 mm²');
    });
  });
}
