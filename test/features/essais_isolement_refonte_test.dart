import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/features/mesures_essais/data/mappers/mesures_essais_mapper.dart';

void main() {
  group('EssaisIsolementRefonteTest - Repère dérivé & Sections A/B', () {
    test('computeRepereDerive renvoie un repère unique quand A et B sont dans le même local', () {
      final repere = EssaiIsolement.computeRepereDerive('Local BT 1', 'Local BT 1');
      expect(repere, equals('Local BT 1'));
    });

    test('computeRepereDerive renvoie Repère A - Repère B quand les locaux sont différents', () {
      final repere = EssaiIsolement.computeRepereDerive('Local BT 1', 'Local MT 2');
      expect(repere, equals('Local BT 1 - Local MT 2'));
    });

    test('getters displaySectionPointA et B utilisent le fallback legacy si non définis', () {
      final essaiLegacy = EssaiIsolement(
        syncId: 'iso_1',
        isolement: 250.0,
        appreciation: 'Satisfaisant',
        sectionCable: '16 mm²',
      );

      expect(essaiLegacy.displaySectionPointA, equals('16 mm²'));
      expect(essaiLegacy.displaySectionPointB, equals('16 mm²'));

      final essaiNew = EssaiIsolement(
        syncId: 'iso_2',
        isolement: 300.0,
        appreciation: 'Satisfaisant',
        sectionCable: '16 mm²',
        sectionCablePointA: '25 mm²',
        sectionCablePointB: '35 mm²',
      );

      expect(essaiNew.displaySectionPointA, equals('25 mm²'));
      expect(essaiNew.displaySectionPointB, equals('35 mm²'));
    });

    test('MesuresEssaisMapper effectue un round-trip complet avec les nouveaux champs isolement', () {
      final model = EssaiIsolement(
        syncId: 'iso_100',
        equipmentSyncId: 'eq_A',
        pointControle: 'De EqA vers EqB',
        isolement: 500.0,
        appreciation: 'Satisfaisant',
        localisation: 'Local A - Local B',
        designation: 'EqA',
        reperePointOrigine: 'Local A - Local B',
        pointA: 'Local A - EqA',
        pointB: 'Local B - EqB',
        sectionCable: '16 mm²',
        nombreCablesTestes: 3,
        sectionCablePointA: '25 mm²',
        sectionCablePointB: '35 mm²',
        isSectionPointAManual: true,
        isSectionPointBManual: false,
        equipmentPointASyncId: 'eq_A',
        equipmentPointBSyncId: 'eq_B',
      );

      final entity = MesuresEssaisMapper.toEntity(
        MesuresEssais(
          missionId: 'm1',
          updatedAt: DateTime.now(),
          essaisIsolement: [model],
        ),
      );

      final eiEntity = entity.essaisIsolement.first;
      expect(eiEntity.sectionCablePointA, equals('25 mm²'));
      expect(eiEntity.sectionCablePointB, equals('35 mm²'));
      expect(eiEntity.isSectionPointAManual, isTrue);
      expect(eiEntity.isSectionPointBManual, isFalse);
      expect(eiEntity.equipmentPointASyncId, equals('eq_A'));
      expect(eiEntity.equipmentPointBSyncId, equals('eq_B'));

      final backToModel = MesuresEssaisMapper.toModel(entity).essaisIsolement.first;
      expect(backToModel.sectionCablePointA, equals('25 mm²'));
      expect(backToModel.sectionCablePointB, equals('35 mm²'));
      expect(backToModel.isSectionPointAManual, isTrue);
      expect(backToModel.isSectionPointBManual, isFalse);
      expect(backToModel.equipmentPointASyncId, equals('eq_A'));
      expect(backToModel.equipmentPointBSyncId, equals('eq_B'));
    });
  });
}
