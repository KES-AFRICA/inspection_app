import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/ip_ik_evaluator_service.dart';

void main() {
  group('IpIkEvaluatorService Tests', () {
    test('Test 1 — ParsedIpIk extraie correctement les indices IP et IK quelles que soient les variantes de casse et d\'espacement', () {
      final p1 = ParsedIpIk.parse('IP55 / IK08');
      final p2 = ParsedIpIk.parse('ip55/ik08');
      final p3 = ParsedIpIk.parse('IP 55 / IK 08');

      expect(p1.ip, equals('IP55'));
      expect(p1.ik, equals('IK08'));

      expect(p2.ip, equals('IP55'));
      expect(p2.ik, equals('IK08'));

      expect(p3.ip, equals('IP55'));
      expect(p3.ik, equals('IK08'));

      expect(p1, equals(p2));
      expect(p2, equals(p3));
    });

    test('Test 2 — Cas A : Équipement sans indice IP/IK -> Non conforme + "Absence de l\'indice ip/ik"', () {
      final coffret = CoffretArmoire(
        qrCode: 'QR123',
        nom: 'Coffret C1',
        type: 'COFFRET',
        indiceIpIk: null,
      );

      final eval = IpIkEvaluatorService.evaluate(
        coffret: coffret,
        missionId: 'm1',
      );

      expect(eval.conformite, equals('non'));
      expect(eval.observation, equals("Absence de l'indice ip/ik"));
    });

    test('Test 3 — Cas B & D : Équipement avec indice IP/IK mais repère introuvable/non classé -> Non conforme + "Absence d\'indice ip/ik du repere"', () {
      final coffret = CoffretArmoire(
        qrCode: 'QR123',
        nom: 'Coffret C2',
        type: 'COFFRET',
        indiceIpIk: 'IP55 / IK08',
      );

      final eval = IpIkEvaluatorService.evaluate(
        coffret: coffret,
        missionId: 'mission_inexistante',
      );

      expect(eval.conformite, equals('non'));
      expect(eval.observation, equals("Absence d'indice ip/ik du repere"));
    });

    test('Test 4 — Inclusion de l\'Inverseur dans la détection des points IP/IK', () {
      final isPointCoffret = IpIkEvaluatorService.isIpIkPoint(
        "Compatibilité du degré IP/IK avec l'environnement d'installation",
      );
      final isPointInverseur = IpIkEvaluatorService.isIpIkPoint(
        "Protection IP/IK adaptée au local d'installation",
      );

      expect(isPointCoffret, isTrue);
      expect(isPointInverseur, isTrue);
    });
  });
}
