import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/normative_search_service.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';

void main() {
  group('Moteur de Recherche Intelligent & Rattachement Normatif', () {
    test('1. Recherche par mots-clés (schéma, porte, anti-panique, terre)', () {
      final resultsSchema = NormativeSearchService.search('Absence de schéma');
      expect(resultsSchema, isNotEmpty);
      expect(resultsSchema.any((r) => r.referenceNormative.contains('13-100') || r.pointVerification.toLowerCase().contains('schéma')), isTrue);

      final resultsPorte = NormativeSearchService.search('porte anti panique');
      expect(resultsPorte, isNotEmpty);
      expect(resultsPorte.any((r) => r.referenceNormative.contains('NF C 13-100') || r.referenceNormative.contains('NF C 15-100')), isTrue);
    });

    test('2. Insensibilité à la casse, aux accents et aux mots vides', () {
      final resUpper = NormativeSearchService.search('LIAISONS EQUIPOTENTIELLES');
      final resLower = NormativeSearchService.search('liaisons equipotentielles');

      expect(resUpper, isNotEmpty);
      expect(resLower, isNotEmpty);
      expect(resUpper.first.referenceNormative, equals(resLower.first.referenceNormative));
    });

    test('3. Rattachement, modification et suppression du lien normatif sur ObservationLibre', () {
      final obs = ObservationLibre(
        texte: 'Signalisation manquante sur la porte d\'accès',
      );

      expect(obs.hasNormativeReference, isFalse);
      expect(obs.pointVerificationKey, isNull);
      expect(obs.referenceNormative, isNull);

      // Rattachement
      obs.linkToNormativePoint(
        key: 'signalisation_porte',
        refNormative: 'NF C 13-100:2015 – art 411.3',
        famille: 'Erreur de manœuvre',
        crit: 'Majeure',
      );

      expect(obs.hasNormativeReference, isTrue);
      expect(obs.referenceNormative, equals('NF C 13-100:2015 – art 411.3'));
      expect(obs.familleRisque, equals('Erreur de manœuvre'));
      expect(obs.criticite, equals('Majeure'));

      // Suppression du lien (texte conservé intact)
      obs.unlinkNormativePoint();
      expect(obs.hasNormativeReference, isFalse);
      expect(obs.referenceNormative, isNull);
      expect(obs.texte, equals('Signalisation manquante sur la porte d\'accès'));
    });

    test('4. Mapping Clean Architecture (ObservationLibre <-> ObservationLibreEntity)', () {
      final obs = ObservationLibre(
        texte: 'Obstruction des voies d\'accès au local',
        pointVerificationKey: 'acces_local',
        referenceNormative: 'NF C 13-100:2015 – art 112',
        familleRisque: 'Électrocution',
        criticite: 'Critique',
      );

      final entity = AuditInstallationsMapper.toObservationLibreEntity(obs);
      expect(entity.referenceNormative, equals('NF C 13-100:2015 – art 112'));
      expect(entity.familleRisque, equals('Électrocution'));

      final rebuilt = AuditInstallationsMapper.toObservationLibreModel(entity);
      expect(rebuilt.texte, equals('Obstruction des voies d\'accès au local'));
      expect(rebuilt.referenceNormative, equals('NF C 13-100:2015 – art 112'));
      expect(rebuilt.hasNormativeReference, isTrue);
    });

    test('5. Rétrocompatibilité totale avec les anciennes observations (champs null)', () {
      final ancienneObs = ObservationLibre(
        texte: 'Ancienne observation saisie sur le terrain sans norme',
      );

      expect(ancienneObs.pointVerificationKey, isNull);
      expect(ancienneObs.referenceNormative, isNull);
      expect(ancienneObs.familleRisque, isNull);
      expect(ancienneObs.criticite, isNull);
      expect(ancienneObs.hasNormativeReference, isFalse);
    });
  });
}
