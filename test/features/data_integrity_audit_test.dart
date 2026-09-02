import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/backup_service.dart';
import 'package:inspec_app/services/ip_ik_evaluator_service.dart';

void main() {
  group('Data Integrity Audit Tests', () {
    test('CoffretArmoire effectiveDepartures and effectiveTerminalCircuits return valid non-null lists', () {
      final coffret = CoffretArmoire(
        qrCode: 'QR_123',
        nom: 'TGBT PRINCIPAL',
        type: 'TGBT',
        departures: [
          DepartEquipement(
            id: 'dep_1',
            typeProtection: 'Disjoncteur',
            calibre: '63A',
            sectionCable: '16 mm²',
          ),
        ],
        terminalCircuits: [
          CircuitTerminalEquipement(
            id: 'circ_1',
            identification: 'Éclairage Bureau',
            typeProtection: 'Disjoncteur',
            calibre: '16A',
            sectionCable: '2.5 mm²',
          ),
        ],
      );

      expect(coffret.effectiveDepartures.length, equals(1));
      expect(coffret.effectiveDepartures.first.calibre, equals('63A'));
      expect(coffret.effectiveTerminalCircuits.length, equals(1));
      expect(coffret.effectiveTerminalCircuits.first.identification, equals('Éclairage Bureau'));
    });

    test('PointVerification normalizedConformite accurately identifies non-conformities across historical string variations', () {
      final p1 = PointVerification(pointVerification: 'P1', conformite: 'Non conforme');
      final p2 = PointVerification(pointVerification: 'P2', conformite: 'non_conforme');
      final p3 = PointVerification(pointVerification: 'P3', conformite: 'Non');
      final p4 = PointVerification(pointVerification: 'P4', conformite: 'Oui');
      final p5 = PointVerification(pointVerification: 'P5', conformite: 'Conforme');

      expect(p1.normalizedConformite, equals('non'));
      expect(p2.normalizedConformite, equals('non'));
      expect(p3.normalizedConformite, equals('non'));
      expect(p4.normalizedConformite, equals('oui'));
      expect(p5.normalizedConformite, equals('oui'));
    });

    test('IpIkEvaluatorService automatic evaluation behaves correctly', () {
      final isIpIk = IpIkEvaluatorService.isIpIkPoint("Compatibilité du degré IP/IK avec l'environnement d'installation");
      expect(isIpIk, isTrue);

      final evalWithoutIpIk = IpIkEvaluatorService.evaluate(
        coffret: CoffretArmoire(qrCode: 'QR', nom: 'Coffret', type: 'COFFRET', indiceIpIk: ''),
        missionId: 'm1',
      );
      expect(evalWithoutIpIk.conformite, equals('non'));

      final evalWithIpIk = IpIkEvaluatorService.evaluate(
        coffret: CoffretArmoire(qrCode: 'QR', nom: 'Coffret', type: 'COFFRET', indiceIpIk: 'IP55 / IK08'),
        missionId: 'm1',
      );
      expect(evalWithIpIk.conformite, isNotNull);
    });

    test('BackupService serialization includes departures and terminalCircuits', () {
      final coffret = CoffretArmoire(
        qrCode: 'QR_999',
        nom: 'COFFRET DEPART',
        type: 'COFFRET',
        departures: [
          DepartEquipement(id: 'dep_100', calibre: '32A', sectionCable: '6 mm²'),
        ],
        terminalCircuits: [
          CircuitTerminalEquipement(id: 'circ_200', identification: 'Prises RDC', calibre: '20A'),
        ],
        sourceDepartId: 'dep_parent_123',
      );

      final jsonMap = BackupService.testSerializeCoffret(coffret);
      expect(jsonMap['departures'], isNotNull);
      expect((jsonMap['departures'] as List).length, equals(1));
      expect(jsonMap['terminalCircuits'], isNotNull);
      expect((jsonMap['terminalCircuits'] as List).length, equals(1));
      expect(jsonMap['sourceDepartId'], equals('dep_parent_123'));

      final restoredList = BackupService.testParseCoffrets([jsonMap]);
      expect(restoredList.length, equals(1));
      expect(restoredList.first.effectiveDepartures.length, equals(1));
      expect(restoredList.first.effectiveDepartures.first.id, equals('dep_100'));
      expect(restoredList.first.effectiveTerminalCircuits.length, equals(1));
      expect(restoredList.first.effectiveTerminalCircuits.first.identification, equals('Prises RDC'));
      expect(restoredList.first.sourceDepartId, equals('dep_parent_123'));
    });

    test('DepartEquipement and CircuitTerminalEquipement deletion by stable ID leaves other items intact', () {
      final dep1 = DepartEquipement(id: 'dep_1', identification: 'Départ 1', calibre: '16A');
      final dep2 = DepartEquipement(id: 'dep_2', identification: 'Départ 2', calibre: '32A');
      final dep3 = DepartEquipement(id: 'dep_3', identification: 'Départ 3', calibre: '63A');
      final list = [dep1, dep2, dep3];

      // Supprimer uniquement le départ 2
      list.removeWhere((d) => d.id == 'dep_2');

      expect(list.length, equals(2));
      expect(list[0].id, equals('dep_1'));
      expect(list[0].identification, equals('Départ 1'));
      expect(list[1].id, equals('dep_3'));
      expect(list[1].identification, equals('Départ 3'));
    });
  });
}
