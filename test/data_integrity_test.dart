import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/dispositions_constructives_registry.dart';
import 'package:inspec_app/services/installation_fields_registry.dart';
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

    test('Test 7 — Rétrocompatibilité Cellule & Transformateur (anciennes missions)', () {
      final ancienneCellule = Cellule(
        fonction: 'Cellule Arrivée 1',
        type: 'IM',
        marqueModeleAnnee: 'Schneider SM6-24 2018',
        tensionAssignee: '24 kV',
        pouvoirCoupure: '12.5 kA',
        numerotation: 'C01',
        parafoudres: 'Oui',
      );

      expect(ancienneCellule.effectiveMarque, equals('Schneider SM6-24 2018'));
      expect(ancienneCellule.effectiveModele, isEmpty);
      expect(ancienneCellule.effectiveAnnee, isEmpty);
      expect(ancienneCellule.formattedMarqueModeleAnnee, equals('Schneider SM6-24 2018'));

      final ancienTransfo = TransformateurMTBT(
        typeTransformateur: 'Transformateur HTA/BT',
        marqueAnnee: 'France Transfo 2015',
        puissanceAssignee: '630 kVA',
        tensionPrimaireSecondaire: '20kV / 400V',
        relaisBuchholz: 'Oui',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'TN-S',
      );

      expect(ancienTransfo.effectiveMarque, equals('France Transfo 2015'));
      expect(ancienTransfo.effectiveAnneeFabrication, isEmpty);
      expect(ancienTransfo.formattedMarqueAnnee, equals('France Transfo 2015'));
    });

    test('Test 8 — Séparation des champs constructeur & mapping Clean Architecture', () {
      final nouvelleCellule = Cellule(
        fonction: 'Cellule Arrivée 1',
        type: 'IM',
        marqueModeleAnnee: 'Schneider / SM6-24 / 2024',
        marque: 'Schneider',
        modele: 'SM6-24',
        annee: '2024',
        tensionAssignee: '24 kV',
        pouvoirCoupure: '12.5 kA',
        numerotation: 'C01',
        parafoudres: 'Oui',
      );

      expect(nouvelleCellule.effectiveMarque, equals('Schneider'));
      expect(nouvelleCellule.effectiveModele, equals('SM6-24'));
      expect(nouvelleCellule.effectiveAnnee, equals('2024'));
      expect(nouvelleCellule.formattedMarqueModeleAnnee, equals('Schneider / SM6-24 / 2024'));

      final entityCellule = AuditInstallationsMapper.toCelluleEntity(nouvelleCellule);
      final rebuiltCellule = AuditInstallationsMapper.toCelluleModel(entityCellule);
      expect(rebuiltCellule.effectiveMarque, equals('Schneider'));
      expect(rebuiltCellule.effectiveModele, equals('SM6-24'));
      expect(rebuiltCellule.effectiveAnnee, equals('2024'));

      final nouveauTransfo = TransformateurMTBT(
        typeTransformateur: 'Transformateur HTA/BT',
        marqueAnnee: 'ABB / 2023',
        marque: 'ABB',
        anneeFabrication: '2023',
        puissanceAssignee: '1000 kVA',
        tensionPrimaireSecondaire: '20kV / 400V',
        relaisBuchholz: 'Oui',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'IT',
      );

      expect(nouveauTransfo.effectiveMarque, equals('ABB'));
      expect(nouveauTransfo.effectiveAnneeFabrication, equals('2023'));
      expect(nouveauTransfo.formattedMarqueAnnee, equals('ABB / 2023'));

      final entityTransfo = AuditInstallationsMapper.toTransformateurEntity(nouveauTransfo);
      final rebuiltTransfo = AuditInstallationsMapper.toTransformateurModel(entityTransfo);
      expect(rebuiltTransfo.effectiveMarque, equals('ABB'));
      expect(rebuiltTransfo.effectiveAnneeFabrication, equals('2023'));
    });

    test('Test 9 — Générateur dynamique d\'années (présence année courante et pas d\'années futures)', () {
      final years = InstallationFieldsRegistry.generateYearsList();
      final currentYearStr = DateTime.now().year.toString();
      final futureYearStr = (DateTime.now().year + 1).toString();

      expect(years, isNotEmpty);
      expect(years.first, equals(currentYearStr));
      expect(years.contains(futureYearStr), isFalse);
      expect(years.contains('1950'), isTrue);
    });

    test('Test 10 — Conservation 1-à-1 des conformités historiques sur l\'Inverseur de Source (sans collision)', () {
      final points = [
        PointVerification(
          pointVerification: "Présence et lisibilité du schéma unifilaire et du repérage des départs",
          conformite: "oui",
        ),
        PointVerification(
          pointVerification: "Identification complète des circuits",
          conformite: "non",
          observation: "Repérage incomplet des sources",
        ),
        PointVerification(
          pointVerification: "Présence d'écrans ou plastrons empêchant l'accès aux parties actives",
          conformite: "sans_objet",
        ),
      ];

      DispositionsConstructivesRegistry.ensureCompleteInverseurChecklist(points);

      final ptOui = points.firstWhere(
        (p) => p.pointVerification.contains("Présence et lisibilité du schéma unifilaire"),
      );
      final ptNon = points.firstWhere(
        (p) => p.pointVerification.contains("Identification complète des circuits"),
      );
      final ptNA = points.firstWhere(
        (p) => p.pointVerification.contains("Présence d'écrans ou plastrons"),
      );

      expect(ptOui.conformite, equals('oui'));
      expect(ptNon.conformite, equals('non'));
      expect(ptNon.observation, equals('Repérage incomplet des sources'));
      expect(ptNA.conformite, equals('sans_objet'));
    });
  });
}
