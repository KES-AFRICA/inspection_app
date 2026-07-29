import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mission.dart';

void main() {
  group('Mission afficherTableauFoudre Tests', () {
    test('Default value for afficherTableauFoudre is false', () {
      final mission = Mission(
        id: 'test_m1',
        nomClient: 'Test Client',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
      );

      expect(mission.afficherTableauFoudre, isFalse);
    });

    test('fromJson defaults to false if key is missing', () {
      final json = {
        'id': 'test_m2',
        'nom_client': 'Test Client',
        'status': 'active',
      };

      final mission = Mission.fromJson(json);
      expect(mission.afficherTableauFoudre, isFalse);
    });

    test('fromJson parses true correctly when provided', () {
      final json = {
        'id': 'test_m3',
        'nom_client': 'Test Client',
        'status': 'active',
        'afficher_tableau_foudre': true,
      };

      final mission = Mission.fromJson(json);
      expect(mission.afficherTableauFoudre, isTrue);
    });

    test('toJson includes afficher_tableau_foudre field', () {
      final mission = Mission(
        id: 'test_m4',
        nomClient: 'Test Client',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
        afficherTableauFoudre: true,
      );

      final json = mission.toJson();
      expect(json['afficher_tableau_foudre'], isTrue);
    });
  });
}
