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

    test('Test 8 — Absence de récursion / Stack Overflow : syncIpIkPoint utilise parentName et audit en mémoire', () {
      final point = PointVerification(
        pointVerification: "Compatibilité du degré IP/IK avec l'environnement d'installation",
        conformite: 'non',
        observation: null,
      );

      final coffret = CoffretArmoire(
        qrCode: 'QR_RECURSION',
        nom: 'Coffret Test Recursion',
        type: 'COFFRET',
        indiceIpIk: 'IP55 / IK08',
        repere: 'LOCAL_TGBT',
        pointsVerification: [point],
      );

      final audit = AuditInstallationsElectriques.create('mission_recursion_test');
      final local = MoyenneTensionLocal(
        nom: 'Local MT 1',
        type: 'LOCAL_TRANSFORMATEUR',
        coffrets: [coffret],
      );
      audit.moyenneTensionLocaux.add(local);

      // Exécution de la synchronisation en passant audit et parentName
      expect(() {
        for (int i = 0; i < 50; i++) {
          IpIkEvaluatorService.syncIpIkPoint(
            coffret: coffret,
            missionId: audit.missionId,
            parentName: local.nom,
            audit: audit,
          );
        }
      }, returnsNormally);

      expect(point.conformite, equals('non'));
      expect(point.observation, equals("Absence d'indice ip/ik du repère"));
    });

    test('Test 9 — normaliserIndiceIpIk standardise correctement tous les formats', () {
      expect(IpIkEvaluatorService.normaliserIndiceIpIk('IP55 / IK08'), equals('IP55 / IK08'));
      expect(IpIkEvaluatorService.normaliserIndiceIpIk('ip 55   ik 08'), equals('IP55 / IK08'));
      expect(IpIkEvaluatorService.normaliserIndiceIpIk('IP65'), equals('IP65'));
      expect(IpIkEvaluatorService.normaliserIndiceIpIk('IK10'), equals('IK10'));
      expect(IpIkEvaluatorService.normaliserIndiceIpIk(''), equals(''));
      expect(IpIkEvaluatorService.normaliserIndiceIpIk(null), equals(''));
    });

    test('Test 10 — comparerIndicesIpIk effectue une comparaison stricte et déterministe', () {
      // Égalité parfaite IP + IK
      expect(IpIkEvaluatorService.comparerIndicesIpIk('IP55 / IK08', 'IP55 / IK08'), isTrue);
      expect(IpIkEvaluatorService.comparerIndicesIpIk('ip55/ik08', 'IP 55 / IK 08'), isTrue);

      // Différence IP ou IK
      expect(IpIkEvaluatorService.comparerIndicesIpIk('IP54 / IK08', 'IP55 / IK08'), isFalse);
      expect(IpIkEvaluatorService.comparerIndicesIpIk('IP55 / IK07', 'IP55 / IK08'), isFalse);

      // Repère avec IP seul
      expect(IpIkEvaluatorService.comparerIndicesIpIk('IP55 / IK08', 'IP55'), isTrue);
      expect(IpIkEvaluatorService.comparerIndicesIpIk('IP54 / IK08', 'IP55'), isFalse);
      expect(IpIkEvaluatorService.comparerIndicesIpIk('IP55', 'IP55'), isTrue);

      // Repère avec IK seul
      expect(IpIkEvaluatorService.comparerIndicesIpIk('IP55 / IK08', 'IK08'), isTrue);
      expect(IpIkEvaluatorService.comparerIndicesIpIk('IP55 / IK07', 'IK08'), isFalse);
      expect(IpIkEvaluatorService.comparerIndicesIpIk('IK08', 'IK08'), isTrue);

      // Repère ou équipement absent
      expect(IpIkEvaluatorService.comparerIndicesIpIk('IP55 / IK08', ''), isFalse);
      expect(IpIkEvaluatorService.comparerIndicesIpIk('IP55 / IK08', null), isFalse);
      expect(IpIkEvaluatorService.comparerIndicesIpIk('', 'IP55 / IK08'), isFalse);
      expect(IpIkEvaluatorService.comparerIndicesIpIk(null, 'IP55 / IK08'), isFalse);
    });

    test('Test 11 — resolveRepereIpIk résout depuis repère, local parent ou arborescence', () {
      final coffretAvecRepere = CoffretArmoire(
        qrCode: 'QR_1',
        nom: 'TGBT 1',
        type: 'TGBT',
        repere: 'LOCAL_INEXISTANT',
      );

      // Si le repère n'existe pas dans Hive, renvoie un ParsedIpIk vide
      final resolvedVide = IpIkEvaluatorService.resolveRepereIpIk(
        missionId: 'mission_dummy',
        coffret: coffretAvecRepere,
      );
      expect(resolvedVide.hasIpOrIk, isFalse);
    });

    test('Test 12 — CoffretArmoire copyWith et compatibilité indiceIpIkRepere', () {
      final c1 = CoffretArmoire(
        qrCode: 'QR_COPY',
        nom: 'Inverseur Normal/Secours',
        type: 'INVERSEUR',
        indiceIpIk: 'IP55 / IK08',
      );

      expect(c1.indiceIpIkRepere, isNull);

      final c2 = c1.copyWith(
        indiceIpIkRepere: 'IP65 / IK08',
      );

      expect(c2.qrCode, equals('QR_COPY'));
      expect(c2.nom, equals('Inverseur Normal/Secours'));
      expect(c2.type, equals('INVERSEUR'));
      expect(c2.indiceIpIk, equals('IP55 / IK08')); // Valeur inspecteur inchangée
      expect(c2.indiceIpIkRepere, equals('IP65 / IK08')); // Valeur repère
    });
  });
}
