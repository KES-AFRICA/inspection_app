import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/features/mesures_essais/domain/entities/mesures_essais_entities.dart';
import 'package:inspec_app/features/mesures_essais/data/mappers/mesures_essais_mapper.dart';

void main() {
  group('Essais Isolement - Separation Display Label & Technical Identity', () {
    test('EquipementIsolementItem displayName formatting', () {
      // Cas 1 : Zone + Local + Nom
      const eq1 = EquipementIsolementItem(
        id: 'eq1',
        nom: 'ARMOIRE A',
        type: 'Armoire',
        repere: 'LOCAL ELEC',
        zone: 'ZONE 1',
      );
      expect(eq1.displayName, equals('ZONE 1 - LOCAL ELEC - ARMOIRE A'));

      // Cas 2 : Zone sans Local (ou repere == zone)
      const eq2 = EquipementIsolementItem(
        id: 'eq2',
        nom: 'COFFRET C1',
        type: 'Coffret',
        repere: 'ZONE 1',
        zone: 'ZONE 1',
      );
      expect(eq2.displayName, equals('ZONE 1 - COFFRET C1'));

      // Cas 3 : Local sans Zone
      const eq3 = EquipementIsolementItem(
        id: 'eq3',
        nom: 'TGBT PRINCIPAL',
        type: 'TGBT',
        repere: 'LOCAL TGBT',
        zone: '',
      );
      expect(eq3.displayName, equals('LOCAL TGBT - TGBT PRINCIPAL'));
    });

    test('EssaiIsolement snapshot resolution and display label', () {
      final essai = EssaiIsolement(
        syncId: 'iso_1',
        isolement: 50.0,
        appreciation: 'Satisfaisant',
        pointA: 'ZONE 1 - LOCAL ELEC - ARMOIRE A',
        pointB: 'ZONE 2 - LOCAL TECHNIQUE - COFFRET C1',
        equipmentPointASyncId: 'eqA_123',
        equipmentPointBSyncId: 'eqB_456',
        zonePointA: 'ZONE 1',
        reperePointA: 'LOCAL ELEC',
        nomEquipementPointA: 'ARMOIRE A',
        zonePointB: 'ZONE 2',
        reperePointB: 'LOCAL TECHNIQUE',
        nomEquipementPointB: 'COFFRET C1',
      );

      final infoA = essai.resolvePointAInfo();
      expect(infoA.equipmentId, equals('eqA_123'));
      expect(infoA.zone, equals('ZONE 1'));
      expect(infoA.repere, equals('LOCAL ELEC'));
      expect(infoA.nomEquipement, equals('ARMOIRE A'));
      expect(infoA.displayName, equals('ZONE 1 - LOCAL ELEC - ARMOIRE A'));

      final infoB = essai.resolvePointBInfo();
      expect(infoB.equipmentId, equals('eqB_456'));
      expect(infoB.zone, equals('ZONE 2'));
      expect(infoB.repere, equals('LOCAL TECHNIQUE'));
      expect(infoB.nomEquipement, equals('COFFRET C1'));
      expect(infoB.displayName, equals('ZONE 2 - LOCAL TECHNIQUE - COFFRET C1'));
    });

    test('Cas 4 & 15 : Legacy backward compatibility resolution without data loss', () {
      final legacyEssai = EssaiIsolement(
        syncId: 'iso_legacy_1',
        isolement: 100.0,
        appreciation: 'Satisfaisant',
        pointA: 'ZONE 1 - LOCAL ELEC - ARMOIRE A',
        pointB: 'ZONE 1 - LOCAL ELEC - COFFRET B',
      );

      final available = const [
        EquipementIsolementItem(
          id: 'eqA_real',
          nom: 'ARMOIRE A',
          type: 'Armoire',
          repere: 'LOCAL ELEC',
          zone: 'ZONE 1',
        ),
        EquipementIsolementItem(
          id: 'eqB_real',
          nom: 'COFFRET B',
          type: 'Coffret',
          repere: 'LOCAL ELEC',
          zone: 'ZONE 1',
        ),
      ];

      final infoA = legacyEssai.resolvePointAInfo(available);
      expect(infoA.equipmentId, equals('eqA_real'));
      expect(infoA.zone, equals('ZONE 1'));
      expect(infoA.repere, equals('LOCAL ELEC'));
      expect(infoA.nomEquipement, equals('ARMOIRE A'));

      // If no available equipment matches legacy string, fallback returns raw string as nomEquipement
      final infoUnmatched = legacyEssai.resolvePointAInfo([]);
      expect(infoUnmatched.nomEquipement, equals('ZONE 1 - LOCAL ELEC - ARMOIRE A'));
      expect(infoUnmatched.displayName, equals('ZONE 1 - LOCAL ELEC - ARMOIRE A'));
    });

    test('Cas 5 & 6 : Names and Locals containing dashes are preserved without bad splits', () {
      const eqWithDash = EquipementIsolementItem(
        id: 'eq_dash',
        nom: 'ARMOIRE-PRINCIPALE-A1',
        type: 'Armoire',
        repere: 'LOCAL-ELEC-CENTRAL',
        zone: 'ZONE-A',
      );

      expect(eqWithDash.displayName, equals('ZONE-A - LOCAL-ELEC-CENTRAL - ARMOIRE-PRINCIPALE-A1'));

      final essai = EssaiIsolement(
        syncId: 'iso_dash',
        isolement: 200.0,
        appreciation: 'Satisfaisant',
        equipmentPointASyncId: eqWithDash.id,
        zonePointA: eqWithDash.zone,
        reperePointA: eqWithDash.repere,
        nomEquipementPointA: eqWithDash.nom,
      );

      final infoA = essai.resolvePointAInfo();
      expect(infoA.zone, equals('ZONE-A'));
      expect(infoA.repere, equals('LOCAL-ELEC-CENTRAL'));
      expect(infoA.nomEquipement, equals('ARMOIRE-PRINCIPALE-A1'));
    });

    test('Cas 7 : Identical names resolved by unique equipmentId', () {
      const eq1 = EquipementIsolementItem(
        id: 'id_001',
        nom: 'COFFRET C1',
        type: 'Coffret',
        repere: 'LOCAL 1',
        zone: 'ZONE 1',
      );
      const eq2 = EquipementIsolementItem(
        id: 'id_002',
        nom: 'COFFRET C1',
        type: 'Coffret',
        repere: 'LOCAL 2',
        zone: 'ZONE 2',
      );

      final available = [eq1, eq2];

      final essai = EssaiIsolement(
        syncId: 'iso_dup',
        isolement: 10.0,
        appreciation: 'Satisfaisant',
        equipmentPointASyncId: 'id_002',
        pointA: 'ZONE 2 - LOCAL 2 - COFFRET C1',
      );

      final info = essai.resolvePointAInfo(available);
      expect(info.equipmentId, equals('id_002'));
      expect(info.zone, equals('ZONE 2'));
      expect(info.repere, equals('LOCAL 2'));
    });

    test('Cas 8 & 9 : Point A set, Point B empty and vice versa', () {
      final essaiOnlyA = EssaiIsolement(
        syncId: 'iso_only_a',
        isolement: 15.0,
        appreciation: 'Satisfaisant',
        equipmentPointASyncId: 'eq_a',
        zonePointA: 'ZONE 1',
        reperePointA: 'LOCAL 1',
        nomEquipementPointA: 'ARMOIRE A',
      );

      expect(essaiOnlyA.resolvePointAInfo().isNotEmpty, isTrue);
      expect(essaiOnlyA.resolvePointBInfo().isEmpty, isTrue);
      expect(essaiOnlyA.displayPointB, equals('-'));
    });

    test('Mapper & Domain Entity preservation of Point A / B location snapshots', () {
      final model = EssaiIsolement(
        syncId: 'iso_map_1',
        isolement: 45.0,
        appreciation: 'Satisfaisant',
        pointA: 'ZONE 1 - LOCAL 1 - TGBT',
        pointB: 'ZONE 1 - LOCAL 2 - ARMOIRE 2',
        equipmentPointASyncId: 'id_tgbt',
        equipmentPointBSyncId: 'id_arm2',
        zonePointA: 'ZONE 1',
        reperePointA: 'LOCAL 1',
        nomEquipementPointA: 'TGBT',
        zonePointB: 'ZONE 1',
        reperePointB: 'LOCAL 2',
        nomEquipementPointB: 'ARMOIRE 2',
      );

      final entity = MesuresEssaisMapper.toEntity(
        MesuresEssais(
          missionId: 'm1',
          updatedAt: DateTime.now(),
          essaisIsolement: [model],
        ),
      );

      final mappedIsoEntity = entity.essaisIsolement.first;
      expect(mappedIsoEntity.equipmentPointASyncId, equals('id_tgbt'));
      expect(mappedIsoEntity.zonePointA, equals('ZONE 1'));
      expect(mappedIsoEntity.reperePointA, equals('LOCAL 1'));
      expect(mappedIsoEntity.nomEquipementPointA, equals('TGBT'));

      final convertedModel = MesuresEssaisMapper.toModel(entity);
      final mappedIsoModel = convertedModel.essaisIsolement.first;
      expect(mappedIsoModel.equipmentPointASyncId, equals('id_tgbt'));
      expect(mappedIsoModel.zonePointA, equals('ZONE 1'));
      expect(mappedIsoModel.reperePointA, equals('LOCAL 1'));
      expect(mappedIsoModel.nomEquipementPointA, equals('TGBT'));
    });
  });
}
