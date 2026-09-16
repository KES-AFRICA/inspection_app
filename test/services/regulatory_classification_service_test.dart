import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/regulatory_classification_service.dart';

void main() {
  group('RegulatoryClassificationService Tests', () {
    test('1. Les 4 classements officiels sont exactement ceux demandés', () {
      expect(RegulatoryClassificationService.classifications, equals([
        'Installations classées',
        'IGH',
        'ERP Établissements Généraux',
        'ERP Établissements Spécialisés',
      ]));
    });

    test('2. Comportement pour Installations classées: 1 type et aucune catégorie', () {
      const c = RegulatoryClassificationService.installationsClassees;
      final types = RegulatoryClassificationService.getTypesForClassification(c);
      final categories = RegulatoryClassificationService.getCategoriesForClassification(c);

      expect(types.length, equals(1));
      expect(types.first.code, equals('Usines, Ateliers, Dépôts, Chantiers'));
      expect(categories.isEmpty, isTrue);
      expect(RegulatoryClassificationService.isCategoryApplicable(c), isFalse);
    });

    test('3. Comportement pour IGH: 8 types exacts et aucune catégorie', () {
      const c = RegulatoryClassificationService.igh;
      final types = RegulatoryClassificationService.getTypesForClassification(c);
      final categories = RegulatoryClassificationService.getCategoriesForClassification(c);

      expect(types.length, equals(8));
      final codes = types.map((t) => t.code).toList();
      expect(codes, equals(['GHA', 'GHO', 'GHR', 'GHS', 'GHU', 'GHW1', 'GHW2', 'GHZ']));

      expect(RegulatoryClassificationService.getTypeDescription(c, 'GHA'),
          equals('pour les immeubles à usage d’habitation'));
      expect(RegulatoryClassificationService.getTypeDescription(c, 'GHZ'),
          equals('pour les immeubles à usage mixte'));

      expect(categories.isEmpty, isTrue);
      expect(RegulatoryClassificationService.isCategoryApplicable(c), isFalse);
    });

    test('4. Comportement pour ERP Établissements Généraux: 14 types et 5 catégories', () {
      const c = RegulatoryClassificationService.erpGeneraux;
      final types = RegulatoryClassificationService.getTypesForClassification(c);
      final categories = RegulatoryClassificationService.getCategoriesForClassification(c);

      expect(types.length, equals(14));
      expect(types.first.code, equals('Type J'));
      expect(types.first.description,
          equals('Structures d’accueil pour personnes âgées et personnes handicapées.'));
      expect(types.last.code, equals('Type Y'));
      expect(types.last.description, equals('Musée'));

      expect(categories.length, equals(5));
      expect(categories[0].title, equals('Première catégorie'));
      expect(categories[0].description, equals('au-dessus de 1500 personnes ;'));
      expect(categories[1].title, equals('Deuxième catégorie'));
      expect(categories[1].description, equals('de 701 à 1500 personnes ;'));
      expect(categories[2].title, equals('Troisième catégorie'));
      expect(categories[2].description, equals('de 301 à 700 personnes ;'));
      expect(categories[3].title, equals('Quatrième catégorie'));
      expect(categories[3].description,
          equals('300 personnes au maximum et hors cinquième catégorie ;'));
      expect(categories[4].title, equals('Cinquième catégorie'));
      expect(categories[4].description,
          equals('lorsque l’effectif du public est inférieur aux valeurs que nous indiquerons par la suite.'));

      expect(RegulatoryClassificationService.isCategoryApplicable(c), isTrue);
    });

    test('5. Comportement pour ERP Établissements Spécialisés: 8 types exacts (dont Type OA) et 5 catégories', () {
      const c = RegulatoryClassificationService.erpSpecialises;
      final types = RegulatoryClassificationService.getTypesForClassification(c);
      final categories = RegulatoryClassificationService.getCategoriesForClassification(c);

      expect(types.length, equals(8));
      final codes = types.map((t) => t.code).toList();
      expect(codes, equals([
        'Type PA',
        'Type CTS',
        'Type SG',
        'Type PS',
        'Type GA',
        'Type OA',
        'EF',
        'REF',
      ]));

      expect(RegulatoryClassificationService.getTypeDescription(c, 'Type OA'),
          equals('Hôtels et restaurants d’altitude'));
      expect(RegulatoryClassificationService.getTypeDescription(c, 'REF'),
          equals('Refuges de montagne'));

      expect(categories.length, equals(5));
      expect(RegulatoryClassificationService.isCategoryApplicable(c), isTrue);
    });

    test('6. Validation dynamique isTypeValid et isCategoryValid', () {
      // Type J valide pour ERP Généraux mais pas pour IGH
      expect(RegulatoryClassificationService.isTypeValid(
          RegulatoryClassificationService.erpGeneraux, 'Type J'), isTrue);
      expect(RegulatoryClassificationService.isTypeValid(
          RegulatoryClassificationService.erpGeneraux, 'J'), isTrue); // tolérance
      expect(RegulatoryClassificationService.isTypeValid(
          RegulatoryClassificationService.igh, 'Type J'), isFalse);

      // GHA valide pour IGH mais pas pour ERP
      expect(RegulatoryClassificationService.isTypeValid(
          RegulatoryClassificationService.igh, 'GHA'), isTrue);
      expect(RegulatoryClassificationService.isTypeValid(
          RegulatoryClassificationService.erpGeneraux, 'GHA'), isFalse);

      // Catégorie valide pour ERP mais pas pour IGH
      expect(RegulatoryClassificationService.isCategoryValid(
          RegulatoryClassificationService.erpGeneraux, 'Première catégorie'), isTrue);
      expect(RegulatoryClassificationService.isCategoryValid(
          RegulatoryClassificationService.igh, 'Première catégorie'), isFalse);
      expect(RegulatoryClassificationService.isCategoryValid(
          RegulatoryClassificationService.installationsClassees, 'Première catégorie'), isFalse);
    });

    test('7. Inférence et compatibilité avec les données historiques', () {
      // Mission historique avec type J sans classement
      expect(
        RegulatoryClassificationService.inferClassificationFromLegacy(type: 'J'),
        equals(RegulatoryClassificationService.erpGeneraux),
      );

      // Mission historique avec GHW1
      expect(
        RegulatoryClassificationService.inferClassificationFromLegacy(type: 'GHW1'),
        equals(RegulatoryClassificationService.igh),
      );

      // Mission historique avec Type OA
      expect(
        RegulatoryClassificationService.inferClassificationFromLegacy(type: 'Type OA'),
        equals(RegulatoryClassificationService.erpSpecialises),
      );

      // Mission historique avec catégorie seule
      expect(
        RegulatoryClassificationService.inferClassificationFromLegacy(category: '1ère catégorie'),
        equals(RegulatoryClassificationService.erpGeneraux),
      );
    });
  });
}
