import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/normative_search_service.dart';
import 'package:inspec_app/services/normative_matching/normative_matching_engine.dart';
import 'package:inspec_app/services/normative_matching/normative_matching_result.dart';
import 'package:inspec_app/services/normative_matching/mission_normative_batch_service.dart';

void main() {
  group('NormativeMatchingEngine Tests - Refonte Déterministe', () {
    test('1. Observation explicite -> Confiance VeryHigh (>= 80%) et auto-link autorisé', () {
      final obs = ObservationLibre(
        texte: "Absence de schéma unifilaire dans le tableau électrique",
      );

      final analysis = NormativeMatchingEngine.analyze(obs);

      expect(analysis.status, equals(MatchingConfidenceLevel.veryHigh));
      expect(analysis.confidenceScore, greaterThanOrEqualTo(80.0));
      expect(analysis.shouldAutoLink, isTrue);
      expect(analysis.bestMatch, isNotNull);
      expect(analysis.bestMatch!.referenceNormative, isNotEmpty);
      expect(obs.texte, equals("Absence de schéma unifilaire dans le tableau électrique"));
    });

    test('2. Observation technique spécifique avec faute de frappe / pluriel -> Correctement appariée', () {
      final obs = ObservationLibre(
        texte: "Defaut sur le parafoudre de tete",
      );

      final analysis = NormativeMatchingEngine.analyze(obs);

      expect(analysis.bestMatch, isNotNull);
      expect(analysis.bestMatch!.pointVerification.toLowerCase(), contains('parafoudre'));
      expect(analysis.confidenceScore, greaterThanOrEqualTo(60.0));
      expect(obs.texte, equals("Defaut sur le parafoudre de tete"));
    });

    test('3. Filtrage contextuel par type d\'équipement spécifié', () {
      final resultsMT = NormativeSearchService.search(
        "Absence de voyant de présence tension",
        equipmentType: "CELLULE_MT",
      );

      expect(resultsMT, isNotEmpty);
      final topMT = resultsMT.first;
      expect(topMT.score, greaterThan(0.0));
    });

    test('4. Observation très vague -> Confiance Low (< 40%) et AUCUN auto-link', () {
      final obs = ObservationLibre(
        texte: "Anomalie sur l'installation",
      );

      final analysis = NormativeMatchingEngine.analyze(obs);

      expect(analysis.status, equals(MatchingConfidenceLevel.low));
      expect(analysis.shouldAutoLink, isFalse);
      expect(obs.hasNormativeReference, isFalse);
    });

    test('5. Immuabilité et préservation absolue des métadonnées', () {
      final obs = ObservationLibre(
        texte: "Absence de schéma unifilaire dans le tableau électrique",
        photos: ["photo_1.jpg", "photo_2.jpg"],
        criticite: "Critique",
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

      expect(obs.texte, equals("Absence de schéma unifilaire dans le tableau électrique"));
      expect(obs.photos, contains("photo_1.jpg"));
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
          ObservationLibre(texte: "Absence de schéma unifilaire dans le tableau électrique"),
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
