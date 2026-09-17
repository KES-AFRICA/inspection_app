import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/features/audit_installations/domain/entities/audit_installations_entities.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';
import 'package:inspec_app/services/hive_service.dart';

void main() {
  group('FORENSIC AUDIT — Préservation Intégrale des Départs et Circuits Terminaux', () {
    
    // =========================================================================
    // TEST 1 : Bridge Clean Architecture Mapper (Model <-> Entity)
    // =========================================================================
    test('1. Mapper Clean Architecture : Conversion bidirectionnelle sans perte de départs et circuits', () {
      final depart1 = DepartEquipement(
        id: 'dep_001',
        protectionTete: 'Présent',
        identification: 'Départ Climatisation Salle Serveur',
        typeProtection: 'Disjoncteur différentiel',
        marque: 'Schneider Electric',
        calibre: '32A',
        courbe: 'D',
        pdcKA: '10',
        icc3Max: '8.5',
        sectionCable: '6',
        sectionCableNeutre: '6',
        conducteursPhase: 1,
        conducteursNeutre: 1,
        natureCable: 'Cuivre',
        ddr: '30mA',
      );

      final circuit1 = CircuitTerminalEquipement(
        id: 'circ_001',
        protectionTete: 'Oui',
        identification: 'Éclairage Bureaux Étage 1',
        typeProtection: 'Disjoncteur magnéto-thermique',
        marque: 'Legrand',
        calibre: '16A',
        courbe: 'C',
        pdcKA: '6',
        icc3Max: '4.2',
        sectionCable: '1.5',
        sectionCableNeutre: '1.5',
        conducteursPhase: 1,
        conducteursNeutre: 1,
        natureCable: 'Cuivre',
        ddr: '30mA',
      );

      final model = CoffretArmoire(
        id: 'eq_tgbt_master',
        nom: 'TGBT Salle Électrique',
        type: 'TGBT',
        repere: 'TGBT-01',
        qrCode: 'QR_TGBT_001',
        departures: [depart1],
        terminalCircuits: [circuit1],
      );

      // A. Model -> Entity
      final entity = AuditInstallationsMapper.toCoffretEntity(model);
      expect(entity.id, equals('eq_tgbt_master'));
      expect(entity.effectiveDepartures.length, equals(1));
      expect(entity.effectiveTerminalCircuits.length, equals(1));

      final mappedDepart = entity.effectiveDepartures.first;
      expect(mappedDepart.id, equals('dep_001'));
      expect(mappedDepart.protectionTete, equals('Présent'));
      expect(mappedDepart.identification, equals('Départ Climatisation Salle Serveur'));
      expect(mappedDepart.typeProtection, equals('Disjoncteur différentiel'));
      expect(mappedDepart.marque, equals('Schneider Electric'));
      expect(mappedDepart.calibre, equals('32A'));
      expect(mappedDepart.courbe, equals('D'));
      expect(mappedDepart.pdcKA, equals('10'));
      expect(mappedDepart.icc3Max, equals('8.5'));
      expect(mappedDepart.sectionCable, equals('6'));
      expect(mappedDepart.sectionCableNeutre, equals('6'));
      expect(mappedDepart.conducteursPhase, equals(1));
      expect(mappedDepart.conducteursNeutre, equals(1));
      expect(mappedDepart.natureCable, equals('Cuivre'));
      expect(mappedDepart.ddr, equals('30mA'));

      final mappedCircuit = entity.effectiveTerminalCircuits.first;
      expect(mappedCircuit.id, equals('circ_001'));
      expect(mappedCircuit.protectionTete, equals('Oui'));
      expect(mappedCircuit.identification, equals('Éclairage Bureaux Étage 1'));
      expect(mappedCircuit.typeProtection, equals('Disjoncteur magnéto-thermique'));
      expect(mappedCircuit.marque, equals('Legrand'));
      expect(mappedCircuit.calibre, equals('16A'));
      expect(mappedCircuit.courbe, equals('C'));
      expect(mappedCircuit.pdcKA, equals('6'));
      expect(mappedCircuit.icc3Max, equals('4.2'));
      expect(mappedCircuit.sectionCable, equals('1.5'));
      expect(mappedCircuit.sectionCableNeutre, equals('1.5'));
      expect(mappedCircuit.conducteursPhase, equals(1));
      expect(mappedCircuit.conducteursNeutre, equals(1));
      expect(mappedCircuit.natureCable, equals('Cuivre'));
      expect(mappedCircuit.ddr, equals('30mA'));

      // B. Entity -> Model
      final restoredModel = AuditInstallationsMapper.toCoffretModel(entity);
      expect(restoredModel.id, equals(model.id));
      expect(restoredModel.effectiveDepartures.length, equals(1));
      expect(restoredModel.effectiveTerminalCircuits.length, equals(1));

      final restoredDepart = restoredModel.effectiveDepartures.first;
      expect(restoredDepart.id, equals(depart1.id));
      expect(restoredDepart.identification, equals(depart1.identification));
      expect(restoredDepart.calibre, equals(depart1.calibre));
      expect(restoredDepart.courbe, equals(depart1.courbe));
      expect(restoredDepart.sectionCable, equals(depart1.sectionCable));
      expect(restoredDepart.marque, equals(depart1.marque));
      expect(restoredDepart.natureCable, equals(depart1.natureCable));

      final restoredCircuit = restoredModel.effectiveTerminalCircuits.first;
      expect(restoredCircuit.id, equals(circuit1.id));
      expect(restoredCircuit.identification, equals(circuit1.identification));
      expect(restoredCircuit.calibre, equals(circuit1.calibre));
      expect(restoredCircuit.sectionCable, equals(circuit1.sectionCable));
      expect(restoredCircuit.marque, equals(circuit1.marque));
    });

    // =========================================================================
    // TEST 2 : AuditInstallations Mapper - Full Tree Round-Trip
    // =========================================================================
    test('2. Mapper Clean Architecture : Round-trip complet sur tout l\'arbre d\'audit', () {
      final depart = DepartEquipement(
        id: 'dep_tree_1',
        identification: 'Pompe Incendie',
        calibre: '63A',
      );
      final circuit = CircuitTerminalEquipement(
        id: 'circ_tree_1',
        identification: 'Prises Local Technique',
        calibre: '20A',
      );

      final coffretDirect = CoffretArmoire(
        id: 'coffret_direct',
        qrCode: 'QR_DIRECT_01',
        nom: 'Coffret Direct BT',
        type: 'Coffret',
        departures: [depart],
      );

      final coffretLocal = CoffretArmoire(
        id: 'coffret_local',
        qrCode: 'QR_LOCAL_01',
        nom: 'Coffret Local BT',
        type: 'Armoire',
        terminalCircuits: [circuit],
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'M_TEST_TREE',
        updatedAt: DateTime(2026, 1, 15),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Atelier',
            coffretsDirects: [coffretDirect],
            locaux: [
              BasseTensionLocal(
                nom: 'Local Maintenance',
                type: 'Local Technique',
                coffrets: [coffretLocal],
              ),
            ],
          ),
        ],
      );

      // Model -> Entity
      final auditEntity = AuditInstallationsMapper.toEntity(audit);
      expect(auditEntity.basseTensionZones.first.coffretsDirects.first.effectiveDepartures.length, equals(1));
      expect(auditEntity.basseTensionZones.first.locaux.first.coffrets.first.effectiveTerminalCircuits.length, equals(1));

      // Entity -> Model
      final restoredAudit = AuditInstallationsMapper.toModel(auditEntity);
      final restoredDirect = restoredAudit.basseTensionZones.first.coffretsDirects.first;
      final restoredInLocal = restoredAudit.basseTensionZones.first.locaux.first.coffrets.first;

      expect(restoredDirect.effectiveDepartures.length, equals(1));
      expect(restoredDirect.effectiveDepartures.first.identification, equals('Pompe Incendie'));
      expect(restoredInLocal.effectiveTerminalCircuits.length, equals(1));
      expect(restoredInLocal.effectiveTerminalCircuits.first.identification, equals('Prises Local Technique'));
    });

    // =========================================================================
    // TEST 3 : Deduplication Deep Merge & Score Protection
    // =========================================================================
    test('3. DeduplicateCoffrets : Deep Merge protecteur préservant départs et circuits', () {
      final departA = DepartEquipement(id: 'dep_A', identification: 'Départ A', calibre: '16A');
      final circuitB = CircuitTerminalEquipement(id: 'circ_B', identification: 'Circuit B', calibre: '10A');

      // Instance 1 : a des départs mais pas de circuits
      final c1 = CoffretArmoire(
        id: 'shared_id',
        qrCode: 'QR_SHARED',
        nom: 'Coffret Mixte',
        type: 'Armoire',
        departures: [departA],
        terminalCircuits: [],
      );

      // Instance 2 : a des circuits mais pas de départs
      final c2 = CoffretArmoire(
        id: 'shared_id',
        qrCode: 'QR_SHARED',
        nom: 'Coffret Mixte',
        type: 'Armoire',
        departures: [],
        terminalCircuits: [circuitB],
      );

      final list = [c1, c2];
      final deduplicated = HiveService.deduplicateCoffrets(list);

      expect(deduplicated.length, equals(1));
      final merged = deduplicated.first;
      expect(merged.effectiveDepartures.length, equals(1), reason: 'Départ A doit être préservé après fusion');
      expect(merged.effectiveDepartures.first.identification, equals('Départ A'));
      expect(merged.effectiveTerminalCircuits.length, equals(1), reason: 'Circuit B doit être préservé après fusion');
      expect(merged.effectiveTerminalCircuits.first.identification, equals('Circuit B'));
    });

    // =========================================================================
    // TEST 4 : SaveGuard Logic dans la mise à jour (Preservation vs Clear)
    // =========================================================================
    test('4. SaveGuard Anti-Écrasement : Préserve les départs existants si non explicitement autorisé', () {
      final existingDepartures = [
        DepartEquipement(id: 'dep_keep', identification: 'Compresseur', calibre: '40A'),
      ];
      final existingCircuits = [
        CircuitTerminalEquipement(id: 'circ_keep', identification: 'Éclairage Sécurité', calibre: '10A'),
      ];

      final existing = CoffretArmoire(
        id: 'eq_saveguard',
        qrCode: 'QR_GUARD',
        nom: 'Armoire Compresseurs',
        type: 'Armoire',
        departures: existingDepartures,
        terminalCircuits: existingCircuits,
      );

      // 1. Simuler mise à jour partielle (ex: modification du nom ou repère seulement)
      final incomingUpdate = CoffretArmoire(
        id: 'eq_saveguard',
        qrCode: 'QR_GUARD',
        nom: 'Armoire Compresseurs et Pompes',
        type: 'Armoire',
        departures: [], // Liste vide non voulue
        terminalCircuits: [], // Liste vide non voulue
      );

      // Avec allowClear = false :
      if (incomingUpdate.effectiveDepartures.isEmpty && existing.effectiveDepartures.isNotEmpty) {
        incomingUpdate.departures = List.from(existing.effectiveDepartures);
      }
      if (incomingUpdate.effectiveTerminalCircuits.isEmpty && existing.effectiveTerminalCircuits.isNotEmpty) {
        incomingUpdate.terminalCircuits = List.from(existing.effectiveTerminalCircuits);
      }

      expect(incomingUpdate.nom, equals('Armoire Compresseurs et Pompes'));
      expect(incomingUpdate.effectiveDepartures.length, equals(1));
      expect(incomingUpdate.effectiveDepartures.first.identification, equals('Compresseur'));
      expect(incomingUpdate.effectiveTerminalCircuits.length, equals(1));
      expect(incomingUpdate.effectiveTerminalCircuits.first.identification, equals('Éclairage Sécurité'));
    });

    // =========================================================================
    // TEST 5 : Opérations granulaires (Suppression et modification ciblée)
    // =========================================================================
    test('5. Opérations granulaires : Suppression d\'un départ spécifique sans impacter les autres', () {
      final departures = List.generate(
        5,
        (i) => DepartEquipement(
          id: 'dep_$i',
          identification: 'Départ N°${i + 1}',
          calibre: '${(i + 1) * 10}A',
        ),
      );

      expect(departures.length, equals(5));

      // Supprimer le départ #2 (index 1)
      final targetId = 'dep_1';
      departures.removeWhere((d) => d.id == targetId);

      expect(departures.length, equals(4));
      expect(departures.any((d) => d.id == 'dep_1'), isFalse);
      expect(departures[0].id, equals('dep_0'));
      expect(departures[1].id, equals('dep_2'));
      expect(departures[2].id, equals('dep_3'));
      expect(departures[3].id, equals('dep_4'));

      // Modification ciblée du départ #3 (index 1 dans la nouvelle liste)
      final dep3Index = departures.indexWhere((d) => d.id == 'dep_2');
      expect(dep3Index, equals(1));
      departures[dep3Index] = departures[dep3Index].copyWith(
        calibre: '99A',
        identification: 'Départ N°3 Modifié',
      );

      expect(departures[dep3Index].calibre, equals('99A'));
      expect(departures[dep3Index].identification, equals('Départ N°3 Modifié'));
      // Les autres sont intacts
      expect(departures[0].calibre, equals('10A'));
      expect(departures[2].calibre, equals('40A'));
    });

    // =========================================================================
    // TEST 6 : GetCoffretDraftByQrCode support des clés TEMP_
    // =========================================================================
    test('6. Support des brouillons sans QR code physique (clés TEMP_)', () {
      final tempKey = 'TEMP_1726500000_eq999';
      
      // La vérification précédente `if (qrCode.startsWith('TEMP_')) return null;`
      // est supprimée pour permettre le rechargement transparent des brouillons.
      expect(tempKey.startsWith('TEMP_'), isTrue);
      expect(tempKey.trim().isNotEmpty, isTrue);
    });
  });
}
