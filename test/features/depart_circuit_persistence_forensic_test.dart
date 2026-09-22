import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/hive_service.dart';

void main() {
  group('Forensic Depart & Circuit Persistence Tests', () {
    test('DepartEquipement génère un ID déterministe et stable quand id est absent', () {
      final dep1 = DepartEquipement(
        identification: 'Départ TGBT Usine',
        calibre: '63',
        typeProtection: 'Disjoncteur',
        sectionCable: '16',
      );

      final dep2 = DepartEquipement(
        identification: 'Départ TGBT Usine',
        calibre: '63',
        typeProtection: 'Disjoncteur',
        sectionCable: '16',
      );

      // Les deux instances dérivent exactement le même ID pérenne
      expect(dep1.id, isNotEmpty);
      expect(dep1.id.startsWith('dep_legacy_'), isTrue);
      expect(dep1.id, equals(dep2.id));

      // Si un ID explicite est fourni, il est scrupuleusement respecté
      final depExplicit = DepartEquipement(
        id: 'dep_custom_12345',
        identification: 'Départ TGBT Usine',
      );
      expect(depExplicit.id, equals('dep_custom_12345'));
    });

    test('CircuitTerminalEquipement génère un ID déterministe et stable quand id est absent', () {
      final ct1 = CircuitTerminalEquipement(
        identification: 'Éclairage Bureau',
        calibre: '10',
        typeProtection: 'Disjoncteur',
        sectionCable: '1.5',
      );

      final ct2 = CircuitTerminalEquipement(
        identification: 'Éclairage Bureau',
        calibre: '10',
        typeProtection: 'Disjoncteur',
        sectionCable: '1.5',
      );

      expect(ct1.id, isNotEmpty);
      expect(ct1.id.startsWith('ct_legacy_'), isTrue);
      expect(ct1.id, equals(ct2.id));

      final ctExplicit = CircuitTerminalEquipement(
        id: 'ct_custom_999',
        identification: 'Éclairage Bureau',
      );
      expect(ctExplicit.id, equals('ct_custom_999'));
    });

    test('deduplicateCoffrets préserve les départs homonymes aux spécifications techniques distinctes', () {
      // Coffret de base avec un départ "Éclairage" de 10A
      final baseCoffret = CoffretArmoire(
        id: 'coffret_tgbt_01',
        qrCode: 'QR_TGBT_01',
        nom: 'TGBT Principal',
        type: 'TGBT',
        departures: [
          DepartEquipement(
            id: 'dep_ecl_10a',
            identification: 'Éclairage',
            calibre: '10',
            typeProtection: 'Disjoncteur',
            courbe: 'C',
            ddr: '30',
          ),
        ],
      );

      // Coffret donateur avec un second départ distinct également nommé "Éclairage" mais de 16A
      final donorCoffret = CoffretArmoire(
        id: 'coffret_tgbt_01',
        qrCode: 'QR_TGBT_01',
        nom: 'TGBT Principal',
        type: 'TGBT',
        departures: [
          DepartEquipement(
            id: 'dep_ecl_16a',
            identification: 'Éclairage',
            calibre: '16',
            typeProtection: 'Disjoncteur',
            courbe: 'D',
            ddr: '300',
          ),
        ],
      );

      final deduplicated = HiveService.deduplicateCoffrets([baseCoffret, donorCoffret]);

      expect(deduplicated.length, equals(1));
      final merged = deduplicated.first;
      // Les deux départs "Éclairage" doivent être tous les deux conservés (aucune disparition !)
      expect(merged.effectiveDepartures.length, equals(2));
      final calibres = merged.effectiveDepartures.map((d) => d.calibre).toList();
      expect(calibres, containsAll(['10', '16']));
    });

    test('deduplicateCoffrets réconcilie les vrais doublons identiques (clones stricts)', () {
      final baseCoffret = CoffretArmoire(
        id: 'coffret_01',
        qrCode: 'QR_CLIM_01',
        nom: 'Armoire Climatisation',
        type: 'ARMOIRE',
        departures: [
          DepartEquipement(
            id: 'dep_clim_01',
            identification: 'Groupe Froid',
            calibre: '32',
            typeProtection: 'Disjoncteur',
            courbe: 'D',
            ddr: '300',
            pdcKA: '',
          ),
        ],
      );

      final donorCoffret = CoffretArmoire(
        id: 'coffret_01',
        qrCode: 'QR_CLIM_01',
        nom: 'Armoire Climatisation',
        type: 'ARMOIRE',
        departures: [
          DepartEquipement(
            id: 'dep_clim_01', // Même ID
            identification: 'Groupe Froid',
            calibre: '32',
            typeProtection: 'Disjoncteur',
            courbe: 'D',
            ddr: '300',
            pdcKA: '10', // Champ enrichi
          ),
        ],
      );

      final deduplicated = HiveService.deduplicateCoffrets([baseCoffret, donorCoffret]);

      expect(deduplicated.length, equals(1));
      final merged = deduplicated.first;
      // 1 seul départ conservé et enrichi
      expect(merged.effectiveDepartures.length, equals(1));
      expect(merged.effectiveDepartures.first.pdcKA, equals('10'));
    });

    test('deduplicateCoffrets préserve les circuits terminaux homonymes aux calibres distincts', () {
      final baseCoffret = CoffretArmoire(
        id: 'coffret_02',
        qrCode: 'QR_PC_02',
        nom: 'Coffret Prises',
        type: 'COFFRET',
        terminalCircuits: [
          CircuitTerminalEquipement(
            id: 'ct_pc_16a',
            identification: 'Prises Bureaux',
            calibre: '16',
            typeProtection: 'Disjoncteur',
            courbe: 'C',
            ddr: '30',
          ),
        ],
      );

      final donorCoffret = CoffretArmoire(
        id: 'coffret_02',
        qrCode: 'QR_PC_02',
        nom: 'Coffret Prises',
        type: 'COFFRET',
        terminalCircuits: [
          CircuitTerminalEquipement(
            id: 'ct_pc_20a',
            identification: 'Prises Bureaux',
            calibre: '20',
            typeProtection: 'Disjoncteur',
            courbe: 'C',
            ddr: '30',
          ),
        ],
      );

      final deduplicated = HiveService.deduplicateCoffrets([baseCoffret, donorCoffret]);

      expect(deduplicated.length, equals(1));
      final merged = deduplicated.first;
      expect(merged.effectiveTerminalCircuits.length, equals(2));
      final calibres = merged.effectiveTerminalCircuits.map((c) => c.calibre).toList();
      expect(calibres, containsAll(['16', '20']));
    });

    test('Vidage volontaire des départs : target.departures reflète fidèlement la liste vide', () {
      final existingCoffret = CoffretArmoire(
        id: 'coffret_to_clear',
        qrCode: 'QR_CLEAR_01',
        nom: 'Coffret Passage',
        type: 'COFFRET',
        departures: [
          DepartEquipement(identification: 'Départ Ancien', calibre: '20'),
        ],
      );

      final updatedCoffret = existingCoffret.copyWith(
        departures: [],
      );

      // Simulation de l'assignation corrigée dans _updateCoffret
      existingCoffret.departures = List.from(updatedCoffret.effectiveDepartures);

      expect(existingCoffret.effectiveDepartures, isEmpty);
      expect(existingCoffret.effectiveDepartures.length, equals(0));
    });
  });
}
