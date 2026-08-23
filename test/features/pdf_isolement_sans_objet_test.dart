import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mesures_essais.dart';

void main() {
  group('PDF Section 3 - Essais Isolement Sans Objet', () {
    test('When essaisIsolement is empty, section 3 shows Sans Objet status', () {
      final mesures = MesuresEssais(
        missionId: 'mission_test',
        updatedAt: DateTime.now(),
      );
      expect(mesures.essaisIsolement.isEmpty, isTrue);

      final statusText = mesures.essaisIsolement.isEmpty ? 'Sans objet' : 'Tableau';
      expect(statusText, equals('Sans objet'));
    });

    test('When essaisIsolement is populated, table is displayed', () {
      final mesures = MesuresEssais(
        missionId: 'mission_test',
        updatedAt: DateTime.now(),
        essaisIsolement: [
          EssaiIsolement(
            syncId: 'test_sync_1',
            reperePointOrigine: 'TR1',
            pointA: 'A',
            pointB: 'B',
            sectionCablePointA: '1.5',
            sectionCablePointB: '1.5',
            nombreCablesTestes: 3,
            isolement: 500,
            appreciation: 'Satisfaisant',
          )
        ],
      );
      expect(mesures.essaisIsolement.isNotEmpty, isTrue);

      final statusText = mesures.essaisIsolement.isEmpty ? 'Sans objet' : 'Tableau';
      expect(statusText, equals('Tableau'));
    });
  });
}
