import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/normative_matching/normative_matching_engine.dart';
import 'package:inspec_app/services/normative_matching/normative_matching_result.dart';
import 'package:inspec_app/services/normative_matching/mission_normative_batch_service.dart';

void main() {
  group('NormativeMatchingEngine Tests', () {
    test('1. Observation exacte -> Score certifié (Certain)', () {
      final obs = ObservationLibre(
        texte: "Présence d'une porte pleine, ouvrant vers l'extérieur, munie d'un dispositif anti-panique",
      );

      final analysis = NormativeMatchingEngine.analyze(obs);

      expect(analysis.status, equals(MatchingConfidenceLevel.certain));
      expect(analysis.confidenceScore, greaterThanOrEqualTo(30.0));
      expect(analysis.bestMatch, isNotNull);
      expect(analysis.bestMatch!.referenceNormative, contains("NF C"));
    });

    test('2. Mot-clé pertinent (porte anti-panique) -> Score >= 30% et Rattachement certifié', () {
      final obs = ObservationLibre(
        texte: "Porte accès sans dispositif anti-panique",
      );

      final analysis = NormativeMatchingEngine.analyze(obs);

      expect(analysis.status, equals(MatchingConfidenceLevel.certain));
      expect(analysis.confidenceScore, greaterThanOrEqualTo(30.0));
      expect(analysis.bestMatch!.referenceNormative, contains("NF C"));
    });

    test('3. Texte hors sujet ou trop générique -> Score < 30% (Incertain)', () {
      final obs = ObservationLibre(
        texte: "Rien a signaler sur cet endroit",
      );

      final analysis = NormativeMatchingEngine.analyze(obs);

      expect(analysis.status, equals(MatchingConfidenceLevel.uncertain));
      expect(analysis.confidenceScore, lessThan(30.0));
    });

    test('4. Immuabilité du texte, des photos et des dates', () {
      final obs = ObservationLibre(
        texte: "Porte sans anti-panique dans le local",
        photos: ["/path/photo1.jpg"],
      );
      final initialDate = obs.dateCreation;

      final analysis = NormativeMatchingEngine.analyze(obs);
      if (analysis.shouldAutoLink && analysis.bestMatch != null) {
        obs.linkToNormativePoint(
          key: analysis.bestMatch!.key,
          refNormative: analysis.bestMatch!.referenceNormative,
          famille: analysis.bestMatch!.familleRisque,
          crit: analysis.bestMatch!.criticite,
          auto: true,
        );
      }

      expect(obs.texte, equals("Porte sans anti-panique dans le local"));
      expect(obs.photos, contains("/path/photo1.jpg"));
      expect(obs.dateCreation, equals(initialDate));
      expect(obs.isAutoLinked, isTrue);
      expect(obs.hasNormativeReference, isTrue);
    });
  });

  group('MissionNormativeBatchService Tests', () {
    test('Traitement batch automatique d\'une mission complète', () {
      final audit = AuditInstallationsElectriques.create('mission_test_123');

      final local = MoyenneTensionLocal(
        nom: 'Poste MT 1',
        type: 'LOCAL_POSTE_HTA',
        observationsLibres: [
          ObservationLibre(texte: "Porte d'accès sans barre anti-panique"),
          ObservationLibre(texte: "Une petite remarque sans correspondance"),
        ],
      );

      audit.moyenneTensionLocaux.add(local);

      final report = MissionNormativeBatchService.processAudit(audit);

      expect(report.totalObservationsAnalysed, equals(2));
      expect(report.autoLinkedCount, equals(1));
      expect(local.observationsLibres.first.hasNormativeReference, isTrue);
      expect(local.observationsLibres.first.isAutoLinked, isTrue);
      expect(local.observationsLibres.last.hasNormativeReference, isFalse);
    });
  });
}
