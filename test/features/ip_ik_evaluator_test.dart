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
      expect(eval.observation, equals("Absence d'indice ip/ik du repère"));
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

    test('Test 5 — ParsedIpIk formatFromDigits et getters ipDigits / ikDigits', () {
      expect(ParsedIpIk.formatFromDigits('55', '08'), equals('IP55 / IK08'));
      expect(ParsedIpIk.formatFromDigits('55', ''), equals('IP55'));
      expect(ParsedIpIk.formatFromDigits('', '08'), equals('IK08'));
      expect(ParsedIpIk.formatFromDigits(null, null), equals(''));
      expect(ParsedIpIk.formatFromDigits('  ', null), equals(''));

      final parsed = ParsedIpIk.parse('IP55 / IK08');
      expect(parsed.ipDigits, equals('55'));
      expect(parsed.ikDigits, equals('08'));

      final parsedSingle = ParsedIpIk.parse('IP65');
      expect(parsedSingle.ipDigits, equals('65'));
      expect(parsedSingle.ikDigits, isNull);

      final parsedDigitsOnly = ParsedIpIk.parse('55');
      expect(parsedDigitsOnly.ip, equals('IP55'));
      expect(parsedDigitsOnly.ipDigits, equals('55'));
    });

    test('Test 6 — isAutomatedIpIkObservation détecte les observations automatiques du système', () {
      expect(IpIkEvaluatorService.isAutomatedIpIkObservation("Absence de l'indice ip/ik"), isTrue);
      expect(IpIkEvaluatorService.isAutomatedIpIkObservation("Absence d'indice ip/ik du repère"), isTrue);
      expect(IpIkEvaluatorService.isAutomatedIpIkObservation("Indice ip/ik différent de l'indice du repère"), isTrue);
      expect(IpIkEvaluatorService.isAutomatedIpIkObservation("Défaut physique constaté sur le boîtier"), isFalse);
      expect(IpIkEvaluatorService.isAutomatedIpIkObservation(null), isFalse);
    });

    test('Test 7 — syncIpIkPoint débloque une observation automatique quand l\'indice devient valide', () {
      final point = PointVerification(
        pointVerification: "Compatibilité du degré IP/IK avec l'environnement d'installation",
        conformite: 'non',
        observation: "Absence de l'indice ip/ik",
      );

      final coffret = CoffretArmoire(
        qrCode: 'QR123',
        nom: 'Coffret C',
        type: 'COFFRET',
        indiceIpIk: 'IP55',
        repere: 'REP_TEST',
        pointsVerification: [point],
      );

      // Sans repère classé, l'évaluation donne "Absence d'indice ip/ik du repère"
      IpIkEvaluatorService.syncIpIkPoint(
        coffret: coffret,
        missionId: 'm1',
      );

      // L'observation automatique précédente a été remplacée par celle du repère
      expect(point.conformite, equals('non'));
      expect(point.observation, equals("Absence d'indice ip/ik du repère"));
    });
  });
}
