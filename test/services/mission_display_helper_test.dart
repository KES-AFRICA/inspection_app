import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/mission_display_helper.dart';

Mission _createMission({
  required String id,
  required String nomClient,
  String? nomSite,
  required DateTime createdAt,
}) {
  return Mission(
    id: id,
    nomClient: nomClient,
    nomSite: nomSite,
    createdAt: createdAt,
    updatedAt: createdAt,
    status: 'en_cours',
  );
}

void main() {
  group('MissionDisplayHelper Tests', () {
    test('Test 1: Memes clients mais sites differents -> aucun suffixe artificiel', () {
      final m1 = _createMission(
        id: 'm1',
        nomClient: 'CAMRAIL',
        nomSite: 'Bassa',
        createdAt: DateTime(2026, 1, 1, 10, 0),
      );
      final m2 = _createMission(
        id: 'm2',
        nomClient: 'CAMRAIL',
        nomSite: 'Yaoundé',
        createdAt: DateTime(2026, 1, 1, 11, 0),
      );

      final map = MissionDisplayHelper.computeDisplayNames([m1, m2]);
      expect(map[m1.id], equals('CAMRAIL'));
      expect(map[m2.id], equals('CAMRAIL'));
      expect(m1.nomClient, equals('CAMRAIL'));
      expect(m2.nomClient, equals('CAMRAIL'));
    });

    test('Test 2: Meme client et meme site -> suffixe deterministe (2)', () {
      final m1 = _createMission(
        id: 'm1',
        nomClient: 'CAMRAIL',
        nomSite: 'Bassa',
        createdAt: DateTime(2026, 1, 1, 10, 0),
      );
      final m2 = _createMission(
        id: 'm2',
        nomClient: 'CAMRAIL',
        nomSite: 'Bassa',
        createdAt: DateTime(2026, 1, 1, 12, 0),
      );

      final map = MissionDisplayHelper.computeDisplayNames([m1, m2]);
      expect(map[m1.id], equals('CAMRAIL'));
      expect(map[m2.id], equals('CAMRAIL (2)'));
      // Data in Hive remains untouched!
      expect(m1.nomClient, equals('CAMRAIL'));
      expect(m2.nomClient, equals('CAMRAIL'));
    });

    test('Test 3: Trois missions identiques (Client + Site) -> CAMRAIL, CAMRAIL (2), CAMRAIL (3)', () {
      final m1 = _createMission(
        id: 'm1',
        nomClient: 'CAMRAIL',
        nomSite: 'Bassa',
        createdAt: DateTime(2026, 1, 1, 10, 0),
      );
      final m2 = _createMission(
        id: 'm2',
        nomClient: 'CAMRAIL',
        nomSite: 'Bassa',
        createdAt: DateTime(2026, 1, 1, 12, 0),
      );
      final m3 = _createMission(
        id: 'm3',
        nomClient: 'CAMRAIL',
        nomSite: 'Bassa',
        createdAt: DateTime(2026, 1, 1, 14, 0),
      );

      final map = MissionDisplayHelper.computeDisplayNames([m3, m1, m2]); // Pass unsorted
      expect(map[m1.id], equals('CAMRAIL'));
      expect(map[m2.id], equals('CAMRAIL (2)'));
      expect(map[m3.id], equals('CAMRAIL (3)'));
    });

    test('Test 4: Casse et espaces normalises pour la comparaison interne', () {
      final m1 = _createMission(
        id: 'm1',
        nomClient: 'CAMRAIL',
        nomSite: 'Bassa',
        createdAt: DateTime(2026, 1, 1, 10, 0),
      );
      final m2 = _createMission(
        id: 'm2',
        nomClient: ' camrail ',
        nomSite: 'BASSA ',
        createdAt: DateTime(2026, 1, 1, 12, 0),
      );

      final map = MissionDisplayHelper.computeDisplayNames([m1, m2]);
      expect(map[m1.id], equals('CAMRAIL'));
      expect(map[m2.id], equals(' camrail  (2)'));
      // Data in Hive remains untouched!
      expect(m1.nomClient, equals('CAMRAIL'));
      expect(m2.nomClient, equals(' camrail '));
    });

    test('Test 5: Suppression d\'une mission -> recalcul dynamique propre', () {
      final m1 = _createMission(
        id: 'm1',
        nomClient: 'CAMRAIL',
        nomSite: 'Bassa',
        createdAt: DateTime(2026, 1, 1, 10, 0),
      );
      final m2 = _createMission(
        id: 'm2',
        nomClient: 'CAMRAIL',
        nomSite: 'Bassa',
        createdAt: DateTime(2026, 1, 1, 12, 0),
      );
      final m3 = _createMission(
        id: 'm3',
        nomClient: 'CAMRAIL',
        nomSite: 'Bassa',
        createdAt: DateTime(2026, 1, 1, 14, 0),
      );

      final mapBefore = MissionDisplayHelper.computeDisplayNames([m1, m2, m3]);
      expect(mapBefore[m2.id], equals('CAMRAIL (2)'));
      expect(mapBefore[m3.id], equals('CAMRAIL (3)'));

      // Si m2 est supprime de la liste
      final mapAfterDelete = MissionDisplayHelper.computeDisplayNames([m1, m3]);
      expect(mapAfterDelete[m1.id], equals('CAMRAIL'));
      expect(mapAfterDelete[m3.id], equals('CAMRAIL (2)'));
    });

    test('Test 6: Modification du site -> sortie automatique du groupe de doublons', () {
      final m1 = _createMission(
        id: 'm1',
        nomClient: 'CAMRAIL',
        nomSite: 'Bassa',
        createdAt: DateTime(2026, 1, 1, 10, 0),
      );
      final m2 = _createMission(
        id: 'm2',
        nomClient: 'CAMRAIL',
        nomSite: 'Douala', // Site modifié
        createdAt: DateTime(2026, 1, 1, 12, 0),
      );

      final map = MissionDisplayHelper.computeDisplayNames([m1, m2]);
      expect(map[m1.id], equals('CAMRAIL'));
      expect(map[m2.id], equals('CAMRAIL'));
    });

    test('Test 7: Mixte complexe (Exemple specification)', () {
      final m1 = _createMission(id: '1', nomClient: 'CAMRAIL', nomSite: 'Bassa', createdAt: DateTime(2026, 1, 1, 10));
      final m2 = _createMission(id: '2', nomClient: 'CAMRAIL', nomSite: 'Yaoundé', createdAt: DateTime(2026, 1, 1, 11));
      final m3 = _createMission(id: '3', nomClient: 'CAMRAIL', nomSite: 'Bassa', createdAt: DateTime(2026, 1, 1, 12));
      final m4 = _createMission(id: '4', nomClient: 'CIMENCAM', nomSite: 'Figuil', createdAt: DateTime(2026, 1, 1, 13));
      final m5 = _createMission(id: '5', nomClient: 'CAMRAIL', nomSite: 'Bassa', createdAt: DateTime(2026, 1, 1, 14));

      final map = MissionDisplayHelper.computeDisplayNames([m1, m2, m3, m4, m5]);
      expect(map[m1.id], equals('CAMRAIL'));
      expect(map[m2.id], equals('CAMRAIL')); // Unique CAMRAIL sur Yaoundé
      expect(map[m3.id], equals('CAMRAIL (2)'));
      expect(map[m4.id], equals('CIMENCAM'));
      expect(map[m5.id], equals('CAMRAIL (3)'));
    });
  });
}
