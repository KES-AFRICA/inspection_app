import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  group('Évolution Section de Câble (Phase / Neutre) & Nombre de câble', () {
    test('Ancienne mission (legacy) : Section de câble unique est interprétée comme Phase ET Neutre', () {
      final legacyAlim = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '10',
        calibre: '32',
        sectionCable: '16 mm²',
      );

      // Pour une ancienne mission, nombreCables est null
      expect(legacyAlim.nombreCables, isNull);

      // La section phase correspond à la section historique
      expect(legacyAlim.sectionCablePhase, equals('16 mm²'));

      // La section neutre retombe automatiquement (fallback) sur la section historique
      expect(legacyAlim.effectiveSectionCableNeutre, equals('16 mm²'));
    });

    test('Nouvelle mission : Sections Phase et Neutre sont totalement indépendantes', () {
      final newAlim = Alimentation(
        typeProtection: 'Disjoncteur',
        pdcKA: '10',
        calibre: '32',
        sectionCable: '16 mm²',
        sectionCableNeutre: '10 mm²',
        nombreCables: '3',
      );

      expect(newAlim.nombreCables, equals('3'));
      expect(newAlim.sectionCablePhase, equals('16 mm²'));
      expect(newAlim.effectiveSectionCableNeutre, equals('10 mm²'));

      // Modification de la section phase ne modifie pas le neutre
      newAlim.sectionCablePhase = '25 mm²';
      expect(newAlim.sectionCablePhase, equals('25 mm²'));
      expect(newAlim.effectiveSectionCableNeutre, equals('10 mm²'));
    });

    test('DepartEquipement : Rétrocompatibilité legacy et indépendance phase/neutre', () {
      final legacyDep = DepartEquipement(
        identification: 'Départ Bâtiment A',
        typeProtection: 'Disjoncteur',
        sectionCable: '50 mm²',
      );

      expect(legacyDep.nombreCables, isNull);
      expect(legacyDep.sectionCablePhase, equals('50 mm²'));
      expect(legacyDep.effectiveSectionCableNeutre, equals('50 mm²'));

      final copyDep = legacyDep.copyWith(
        nombreCables: '4',
        sectionCableNeutre: '35 mm²',
      );

      expect(copyDep.nombreCables, equals('4'));
      expect(copyDep.sectionCablePhase, equals('50 mm²'));
      expect(copyDep.effectiveSectionCableNeutre, equals('35 mm²'));
    });

    test('CircuitTerminalEquipement : Rétrocompatibilité legacy et indépendance phase/neutre', () {
      final legacyCt = CircuitTerminalEquipement(
        identification: 'Éclairage bureau 1',
        typeProtection: 'Disjoncteur',
        sectionCable: '1.5 mm²',
      );

      expect(legacyCt.nombreCables, isNull);
      expect(legacyCt.sectionCablePhase, equals('1.5 mm²'));
      expect(legacyCt.effectiveSectionCableNeutre, equals('1.5 mm²'));

      final newCt = legacyCt.copyWith(
        nombreCables: '1',
        sectionCableNeutre: '2.5 mm²',
      );

      expect(newCt.nombreCables, equals('1'));
      expect(newCt.sectionCablePhase, equals('1.5 mm²'));
      expect(newCt.effectiveSectionCableNeutre, equals('2.5 mm²'));
    });
  });
}
