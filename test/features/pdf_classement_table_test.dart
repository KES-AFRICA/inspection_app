import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/classement_zone.dart';

void main() {
  group('Classement Table Rules (Cas A, Cas B, Cas C)', () {
    test('Cas A: Local dans une zone -> Zone = nom zone parente, Localisation = nom local', () {
      final emp = ClassementEmplacement(
        missionId: 'mission_1',
        localisation: 'Local TGBT Principal',
        zone: 'Zone Production',
        typeEmplacement: 'local',
        updatedAt: DateTime.now(),
      );

      final isZoneEmp = emp.typeEmplacement == 'zone';
      final zoneVal = isZoneEmp
          ? emp.localisation
          : (emp.zone != null && emp.zone!.trim().isNotEmpty ? emp.zone!.trim() : '');

      expect(zoneVal, equals('Zone Production'));
      expect(emp.localisation, equals('Local TGBT Principal'));
    });

    test('Cas B: Local hors zone -> Zone = "", Localisation = nom local', () {
      final emp = ClassementEmplacement(
        missionId: 'mission_1',
        localisation: 'Local Groupe Électrogène',
        zone: null,
        typeEmplacement: 'local',
        updatedAt: DateTime.now(),
      );

      final isZoneEmp = emp.typeEmplacement == 'zone';
      final zoneVal = isZoneEmp
          ? emp.localisation
          : (emp.zone != null && emp.zone!.trim().isNotEmpty ? emp.zone!.trim() : '');

      expect(zoneVal, equals(''));
      expect(emp.localisation, equals('Local Groupe Électrogène'));
    });

    test('Cas C: Élément classé de type Zone -> Zone = nom zone, Localisation = nom zone', () {
      final zone = ClassementZone(
        missionId: 'mission_1',
        nomZone: 'Zone Production',
        typeZone: 'MOYENNE_TENSION',
        updatedAt: DateTime.now(),
      );

      final empZone = ClassementEmplacement(
        missionId: 'mission_1',
        localisation: 'Zone Production',
        zone: null,
        typeEmplacement: 'zone',
        updatedAt: DateTime.now(),
      );

      // Testing zone object
      final zoneValFromZone = zone.nomZone;
      final locValFromZone = zone.nomZone;
      expect(zoneValFromZone, equals('Zone Production'));
      expect(locValFromZone, equals('Zone Production'));

      // Testing zone emplacement object
      final isZoneEmp = empZone.typeEmplacement == 'zone';
      final zoneValFromEmp = isZoneEmp
          ? empZone.localisation
          : (empZone.zone != null && empZone.zone!.trim().isNotEmpty ? empZone.zone!.trim() : '');
      expect(zoneValFromEmp, equals('Zone Production'));
      expect(empZone.localisation, equals('Zone Production'));
    });
  });
}
