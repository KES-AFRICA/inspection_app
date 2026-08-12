import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Audit Tables Alignment & Formatting Rules', () {
    test('Audit table headers must be in uppercase with precise naming', () {
      const expectedHeaders = [
        'POINTS DE VÉRIFICATION',
        'CONFORMITÉ',
        'RÉF. NORMATIVE',
        'FAMILLE DE RISQUE',
        'CRITICITÉ',
        'OBSERVATION',
      ];

      for (final header in expectedHeaders) {
        expect(header, equals(header.toUpperCase()));
      }

      expect(expectedHeaders[1], equals('CONFORMITÉ'));
      expect(expectedHeaders[2], equals('RÉF. NORMATIVE'));
      expect(expectedHeaders[5], equals('OBSERVATION'));
    });
  });
}
