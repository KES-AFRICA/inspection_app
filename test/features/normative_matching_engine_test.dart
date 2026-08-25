import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/normative_search_service.dart';
import 'package:inspec_app/services/normative_matching/normative_matching_engine.dart';
import 'package:inspec_app/services/normative_matching/normative_matching_result.dart';

void main() {
  group('Audit & Unit Tests - Moteur de Rattachement Normatif (ObservationNormativeMatcher)', () {

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

    test('2. Observation technique spécifique avec faute de frappe / pluriel -> Correctement appariée avec IDF', () {
      final obs = ObservationLibre(
        texte: "Defaut sur le parafoudre de tete",
      );

      final analysis = NormativeMatchingEngine.analyze(obs);

      expect(analysis.bestMatch, isNotNull);
      expect(analysis.bestMatch!.pointVerification.toLowerCase(), contains('parafoudre'));
      expect(analysis.confidenceScore, greaterThanOrEqualTo(60.0));
      // Le texte original reste strictement intact
      expect(obs.texte, equals("Defaut sur le parafoudre de tete"));
    });

    test('3. Observation avec contexte d\'équipement spécifié (Armoire / Coffret / Cellule)', () {
      final resultsMT = NormativeSearchService.search(
        "Absence de voyant de présence tension",
        equipmentType: "CELLULE_MT",
      );

      expect(resultsMT, isNotEmpty);
      final topMT = resultsMT.first;
      expect(topMT.score, greaterThan(0.0));
    });

    test('4. Observation très vague ("Anomalie sur installation") -> Confiance Low (< 40%) et AUCUN auto-link', () {
      final obs = ObservationLibre(
        texte: "Anomalie sur l'installation",
      );

      final analysis = NormativeMatchingEngine.analyze(obs);

      expect(analysis.status, equals(MatchingConfidenceLevel.low));
      expect(analysis.shouldAutoLink, isFalse);
      expect(obs.hasNormativeReference, isFalse);
    });

    test('5. Preservation absolue des métadonnées de l\'observation (photos, criticité, etc.)', () {
      final obs = ObservationLibre(
        texte: "Obturateur manquant sur réserve d'armoire",
        photos: ["photo_1.jpg", "photo_2.jpg"],
        criticite: "Critique",
      );

      final analysis = NormativeMatchingEngine.analyze(obs);

      if (analysis.bestMatch != null) {
        obs.linkToNormativePoint(
          key: analysis.bestMatch!.key,
          refNormative: analysis.bestMatch!.referenceNormative,
          famille: analysis.bestMatch!.familleRisque,
          crit: analysis.bestMatch!.criticite,
          auto: true,
        );
      }

      // Vérifications de non-destruction
      expect(obs.texte, equals("Obturateur manquant sur réserve d'armoire"));
      expect(obs.photos, equals(["photo_1.jpg", "photo_2.jpg"]));
      expect(obs.criticite, equals("Critique"));
      expect(obs.hasNormativeReference, isTrue);
      expect(obs.isAutoLinked, isTrue);
    });
  });
}
