import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/dispositions_constructives_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dispositions Constructives MT Alignment & Order Tests', () {
    test('Should have exactly 25 ordered points matching the reference document', () {
      final points = DispositionsConstructivesRegistry.allDispositionsConstructives;
      expect(points.length, equals(25));

      // Verify key reference points
      expect(points[0], equals("Le local est exclusivement réservé à l'usage électrique"));
      expect(points[1], equals('Signalisation visible "Local électrique – Accès réservé au personnel habilité"'));
      expect(points[2], equals("Dimensions"));
      expect(points[3], equals("Parois, plancher et plafond en matériaux non combustibles"));
      expect(points[4], equals("Présence d'une porte pleine, ouvrant vers l'extérieur, munie d'un dispositif anti-panique"));
      expect(points[22], equals("Mise à la terre de toutes les masses métalliques"));
      expect(points[23], equals("Présence de la terre du neutre"));
      expect(points[24], equals("Présence de la terre des masses"));
    });

    test('All 25 points should have exact metadata resolved from DispositionsConstructivesRegistry', () {
      final points = DispositionsConstructivesRegistry.allDispositionsConstructives;

      for (final pt in points) {
        final meta = DispositionsConstructivesRegistry.getMetadata(pt, localType: 'LOCAL_POSTE_HTA');
        expect(meta, isNotNull, reason: 'Metadata missing for point "$pt"');
        expect(meta!.criticite, isNotEmpty);
        expect(meta.referenceNormative, isNotEmpty);
        expect(meta.familleRisque, isNotEmpty);
      }
    });

    test('ensureCompleteLocalChecklists should reorder scrambled points and auto-fill missing with estNA=true', () {
      // Create a scrambled list with only 3 items out of 25
      final scrambled = <ElementControle>[
        ElementControle(
          elementControle: "Dimensions",
          conforme: false,
          observation: "Hauteur insuffisante",
        ),
        ElementControle(
          elementControle: "Le local est exclusivement réservé à l'usage électrique",
          conforme: true,
        ),
      ];

      final conditions = <ElementControle>[];

      DispositionsConstructivesRegistry.ensureCompleteLocalChecklists(
        dispositionsConstructives: scrambled,
        conditionsExploitation: conditions,
      );

      // Must now have all 25 items in exact order
      expect(scrambled.length, equals(25));

      // Item 0 must be "Le local est exclusivement réservé à l'usage électrique" and conforme: true
      expect(scrambled[0].elementControle, equals("Le local est exclusivement réservé à l'usage électrique"));
      expect(scrambled[0].conforme, isTrue);
      expect(scrambled[0].estNA, isFalse);

      // Item 2 must be "Dimensions", conforme: false, with observation preserved
      expect(scrambled[2].elementControle, equals("Dimensions"));
      expect(scrambled[2].conforme, isFalse);
      expect(scrambled[2].observation, equals("Hauteur insuffisante"));
      expect(scrambled[2].estNA, isFalse);

      // Missing items (e.g. item 1 "Signalisation visible...") must be estNA: true and conforme: null
      expect(scrambled[1].elementControle, equals('Signalisation visible "Local électrique – Accès réservé au personnel habilité"'));
      expect(scrambled[1].estNA, isTrue);
      expect(scrambled[1].conforme, isNull);
    });

    test('MoyenneTensionLocal.migrateFromOldFields should automatically reorder and complete checklists', () {
      final local = MoyenneTensionLocal(
        nom: 'Poste HTA Principal',
        type: 'LOCAL_POSTE_HTA',
        dispositionsConstructives: [
          ElementControle(elementControle: "Dimensions", conforme: true),
        ],
      );

      local.migrateFromOldFields();

      expect(local.dispositionsConstructives.length, equals(25));
      expect(local.dispositionsConstructives[0].elementControle, equals("Le local est exclusivement réservé à l'usage électrique"));
      expect(local.dispositionsConstructives[0].estNA, isTrue);
      expect(local.dispositionsConstructives[2].elementControle, equals("Dimensions"));
      expect(local.dispositionsConstructives[2].conforme, isTrue);
    });
  });
}
