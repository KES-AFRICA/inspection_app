import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/dispositions_constructives_registry.dart';

void main() {
  group('Coffret & Inverseur Data Preservation Tests', () {
    test('Test 1 — normalizedConformite résout correctement les différentes variantes historiques', () {
      final pOui1 = PointVerification(pointVerification: 'Test', conformite: 'Oui');
      final pOui2 = PointVerification(pointVerification: 'Test', conformite: 'oui');
      final pOui3 = PointVerification(pointVerification: 'Test', conformite: 'conforme');

      final pNon1 = PointVerification(pointVerification: 'Test', conformite: 'Non');
      final pNon2 = PointVerification(pointVerification: 'Test', conformite: 'non');
      final pNon3 = PointVerification(pointVerification: 'Test', conformite: 'non_conforme');
      final pNon4 = PointVerification(pointVerification: 'Test', conformite: 'non conforme');

      final pNA1 = PointVerification(pointVerification: 'Test', conformite: 'NA');
      final pNA2 = PointVerification(pointVerification: 'Test', conformite: 'Sans objet');
      final pNA3 = PointVerification(pointVerification: 'Test', conformite: 'sans_objet');
      final pNA4 = PointVerification(pointVerification: 'Test', conformite: 'non_acquis');

      final pVide = PointVerification(pointVerification: 'Test', conformite: '');

      expect(pOui1.normalizedConformite, equals('oui'));
      expect(pOui2.normalizedConformite, equals('oui'));
      expect(pOui3.normalizedConformite, equals('oui'));

      expect(pNon1.normalizedConformite, equals('non'));
      expect(pNon2.normalizedConformite, equals('non'));
      expect(pNon3.normalizedConformite, equals('non'));
      expect(pNon4.normalizedConformite, equals('non'));

      expect(pNA1.normalizedConformite, equals('na'));
      expect(pNA2.normalizedConformite, equals('na'));
      expect(pNA3.normalizedConformite, equals('na'));
      expect(pNA4.normalizedConformite, equals('na'));

      expect(pVide.normalizedConformite, isEmpty);
    });

    test('Test 2 — ensureCompleteCoffretChecklist préserve les conformités "Non" et observations historiques', () {
      final pointsHistoriques = [
        PointVerification(
          pointVerification: "Identification complète des circuits",
          conformite: "Non",
          observation: "Absence d'étiquetage sur les départs",
          observations: [
            ElementControle(
              elementControle: "Identification complète des circuits",
              conforme: false,
              priorite: 1,
              observation: "Absence d'étiquetage sur les départs",
            ),
          ],
        ),
        PointVerification(
          pointVerification: "Présence d'une coupure générale clairement identifiée et accessible",
          conformite: "Oui",
        ),
        PointVerification(
          pointVerification: "Dispositif de protection contre les surtensions (parafoudre)",
          conformite: "Sans objet",
        ),
      ];

      DispositionsConstructivesRegistry.ensureCompleteCoffretChecklist(pointsHistoriques);

      final ptNon = pointsHistoriques.firstWhere(
        (p) => p.pointVerification.contains("Identification complète des circuits"),
      );
      final ptOui = pointsHistoriques.firstWhere(
        (p) => p.pointVerification.contains("coupure générale"),
      );
      final ptNA = pointsHistoriques.firstWhere(
        (p) => p.pointVerification.contains("parafoudre"),
      );

      expect(ptNon.normalizedConformite, equals('non'));
      expect(ptNon.observation, equals("Absence d'étiquetage sur les départs"));
      expect(ptNon.observations, isNotNull);
      expect(ptNon.observations, isNotEmpty);
      expect(ptNon.observations!.first.observation, equals("Absence d'étiquetage sur les départs"));

      expect(ptOui.normalizedConformite, equals('oui'));
      expect(ptNA.normalizedConformite, equals('na'));
    });

    test('Test 3 — ensureCompleteInverseurChecklist conserve les conformités de l\'Inverseur sans reset à 100%', () {
      final pointsInverseur = [
        PointVerification(
          pointVerification: "Interverrouillage empêchant le couplage intempestif des deux sources",
          conformite: "non",
          observation: "Interverrouillage mécanique défaillant",
          priorite: 1,
        ),
        PointVerification(
          pointVerification: "Identification claire des deux sources et de la source prioritaire",
          conformite: "oui",
        ),
      ];

      DispositionsConstructivesRegistry.ensureCompleteInverseurChecklist(pointsInverseur);

      final ptNon = pointsInverseur.firstWhere(
        (p) => p.pointVerification.contains("Interverrouillage"),
      );
      expect(ptNon.normalizedConformite, equals('non'));
      expect(ptNon.observation, equals("Interverrouillage mécanique défaillant"));

      final countConformes = pointsInverseur.where((p) => p.normalizedConformite == 'oui').length;
      final countNonConformes = pointsInverseur.where((p) => p.normalizedConformite == 'non').length;

      expect(countNonConformes, greaterThanOrEqualTo(1));
      expect(countConformes, greaterThanOrEqualTo(1));

      final totalRenseignes = pointsInverseur.where((p) => p.normalizedConformite != 'na' && p.normalizedConformite.isNotEmpty).length;
      final ratio = countConformes / totalRenseignes;
      expect(ratio, lessThan(1.0)); // Garantit que le score ne cale PAS à 100% !
    });
  });
}
