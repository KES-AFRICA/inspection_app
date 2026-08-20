import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/dispositions_constructives_registry.dart';
import 'package:inspec_app/features/audit_installations/data/mappers/audit_installations_mapper.dart';

void main() {
  group('Audit d\'Intégrité des Données & Protection des Conformités', () {
    test('Test 1 — Conformité existante Non + Observation reste intacte', () {
      final points = [
        PointVerification(
          pointVerification: "Etat du Coffret / Armoire / TGBT",
          conformite: "non",
          observation: "Porte déformée et serrure cassée",
          priorite: 3,
        ),
      ];

      DispositionsConstructivesRegistry.ensureCompleteCoffretChecklist(points);

      final pt = points.firstWhere(
        (p) => p.pointVerification == "Etat du Coffret / Armoire / TGBT",
      );
      expect(pt.conformite, equals('non'));
      expect(pt.observation, equals('Porte déformée et serrure cassée'));
      expect(pt.priorite, equals(3));
    });

    test('Test 2 — Pas d\'écrasement des points Oui/Non par Sans objet lors des mises à jour', () {
      final points = [
        PointVerification(
          pointVerification: "Identification complète des circuits",
          conformite: "oui",
        ),
        PointVerification(
          pointVerification: "Respect code couleur des câbles",
          conformite: "non",
          observation: "Couleur neutre non respectée",
        ),
      ];

      DispositionsConstructivesRegistry.ensureCompleteCoffretChecklist(points);

      final ptOui = points.firstWhere(
        (p) => p.pointVerification == "Identification complète des circuits",
      );
      final ptNon = points.firstWhere(
        (p) => p.pointVerification == "Respect code couleur des câbles",
      );

      expect(ptOui.conformite, equals('oui'));
      expect(ptNon.conformite, equals('non'));
      expect(ptNon.observation, equals('Couleur neutre non respectée'));
    });

    test('Test 3 — Migration d\'anciens titres et préservation des points orphelins', () {
      final points = [
        PointVerification(
          pointVerification: "Dégagement autour de l'équipement", // Ancien alias
          conformite: "non",
          observation: "Matériel entreposé devant le coffret",
        ),
        PointVerification(
          pointVerification: "Point Spécifique Custom Inspecteur", // Point orphelin
          conformite: "non",
          observation: "Câble de terre déconnecté",
        ),
      ];

      DispositionsConstructivesRegistry.ensureCompleteCoffretChecklist(points);

      final ptMigre = points.firstWhere(
        (p) => p.pointVerification == "Emplacement / Dégagement autour",
      );
      final ptOrphelin = points.firstWhere(
        (p) => p.pointVerification == "Point Spécifique Custom Inspecteur",
      );

      expect(ptMigre.conformite, equals('non'));
      expect(ptMigre.observation, equals('Matériel entreposé devant le coffret'));

      expect(ptOrphelin.conformite, equals('non'));
      expect(ptOrphelin.observation, equals('Câble de terre déconnecté'));
    });

    test('Test 4 — Modification d\'un autre champ ne touche pas aux conformités', () {
      final coffret = CoffretArmoire(
        qrCode: '',
        nom: "Armoire Principale BT",
        type: "ARMOIRE",
        description: "",
        repere: "TGBT-01",
        zoneAtex: false,
        domaineTension: "230/400",
        identificationArmoire: true,
        signalisationDanger: true,
        presenceSchema: true,
        presenceParafoudre: false,
        verificationThermographie: true,
        presenceDefautThermo: "Non",
        pointsVerification: [
          PointVerification(
            pointVerification: "Etat du Coffret / Armoire / TGBT",
            conformite: "non",
            observation: "Defaut d'isolement",
          ),
        ],
      );

      // Simulation de modification du nom
      coffret.nom = "Armoire Principale BT Modifiée";

      // Re-exécution de la complétude
      DispositionsConstructivesRegistry.ensureCompleteCoffretChecklist(coffret.pointsVerification);

      final pt = coffret.pointsVerification.firstWhere(
        (p) => p.pointVerification == "Etat du Coffret / Armoire / TGBT",
      );
      expect(pt.conformite, equals('non'));
      expect(pt.observation, equals('Defaut d\'isolement'));
    });

    test('Test 5 — ElementControle persistence (Cellules et Transformateurs)', () {
      final elements = [
        ElementControle(
          elementControle: "État général du transformateur et absence de fuite d'huile",
          conforme: false,
          estNA: false,
          observation: "Traces de fuite d'huile sous la cuve",
        ),
      ];

      DispositionsConstructivesRegistry.ensureCompleteTransformateurChecklist(elements);

      final el = elements.firstWhere(
        (e) => e.elementControle == "État général du transformateur et absence de fuite d'huile",
      );

      expect(el.conforme, isFalse);
      expect(el.estNA, isFalse);
      expect(el.observation, equals('Traces de fuite d\'huile sous la cuve'));
    });

    test('Test 6 — Mapping Clean Architecture (Round-trip AuditInstallationsMapper)', () {
      final model = PointVerification(
        pointVerification: "Présence d'écrans ou plastrons empêchant l'accès aux parties actives",
        conformite: "non",
        observation: "Plastron manquant rangée du bas",
        criticite: "Critique",
        familleRisque: "Contacts directs",
        observations: [
          ElementControle(
            elementControle: "Plastron rangée 2",
            conforme: false,
            observation: "Cassé",
          ),
        ],
      );

      final entity = AuditInstallationsMapper.toPointVerificationEntity(model);
      final rebuiltModel = AuditInstallationsMapper.toPointVerificationModel(entity);

      expect(rebuiltModel.pointVerification, equals(model.pointVerification));
      expect(rebuiltModel.conformite, equals('non'));
      expect(rebuiltModel.observation, equals('Plastron manquant rangée du bas'));
      expect(rebuiltModel.criticite, equals('Critique'));
      expect(rebuiltModel.familleRisque, equals('Contacts directs'));
      expect(rebuiltModel.observations, isNotNull);
      expect(rebuiltModel.observations!.length, equals(1));
      expect(rebuiltModel.observations!.first.observation, equals('Cassé'));
    });
  });
}
