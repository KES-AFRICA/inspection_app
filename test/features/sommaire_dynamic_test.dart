import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic Sommaire Sub-Sections & Hierarchy Tests', () {
    test('Sommaire entries should contain main sections and correct sub-sections', () {
      final entries = PdfReportService.getSommaireEntriesForTesting();
      expect(entries, isNotEmpty);

      final titles = entries.map((e) => (e as dynamic).titre as String).toList();

      // Sections principales
      expect(titles, contains("OBJET DE LA VÉRIFICATION"));
      expect(titles, contains("PERIMETRE DE LA MISSION"));
      expect(titles, contains("RAPPEL DES RESPONSABILITÉS DE L'EMPLOYEUR"));
      expect(titles, contains("MESURES DE SÉCURITÉ AUTOUR DES INSTALLATIONS"));
      expect(titles, contains("RESUME EXECUTIF"));
      expect(titles, contains("ANALYSE STATISTIQUE"));
      expect(titles, contains("RENSEIGNEMENTS GÉNÉRAUX DE L'ÉTABLISSEMENT"));
      expect(titles, contains("DESCRIPTION DES INSTALLATIONS"));
      expect(titles, contains("CLASSEMENT ET EMPLACEMENTS DES LOCAUX ET ZONES EN FONCTION DES INFLUENCES EXTERNES"));
      expect(titles, contains("FOUDRE ET SURTENSION"));
      expect(titles, contains("PHOTOS"));

      // Sous-sections du Résumé Exécutif (11 sections Word)
      expect(titles, contains("1. Contexte et périmètre de la mission"));
      expect(titles, contains("2. Synthèse des résultats"));
      expect(titles, contains("2.1. Indicateurs clés de la mission"));
      expect(titles, contains("2.2. Criticité"));
      expect(titles, contains("2.3. Facteurs de risque prépondérants"));
      expect(titles, contains("3. Répartition des non-conformités"));
      expect(titles, contains("3.1. Analyse Moyenne Tension (HTA)"));
      expect(titles, contains("3.2. Analyse Basse Tension (BT)"));
      expect(titles, contains("4. Diversification des marques des appareillages de protection"));
      expect(titles, contains("5. Courbes et protections"));
      expect(titles, contains("6. Adéquation ICC / PDC"));
      expect(titles, contains("7. Proportion type de câble par section"));
      expect(titles, contains("8. Adéquation classement des zones et indices des équipements"));
      expect(titles, contains("9. Renforcement des compétences"));
      expect(titles, contains("10. Recommandations prioritaires hiérarchisées"));
      expect(titles, contains("11. Appréciation globale"));

      // Sous-sections d'Analyse Statistique (7 sections Word)
      expect(titles, contains("1. Répartition des non conformités par domaine de tension"));
      expect(titles, contains("2. Non-conformités croisées par catégorie d'installation"));
      expect(titles, contains("2.1. Moyenne tension"));
      expect(titles, contains("2.2. Basse tension"));
      expect(titles, contains("3. Sécurité et traçabilité des tableaux Basse Tension"));
      expect(titles, contains("3.1. Identification des sources d’alimentation"));
      expect(titles, contains("3.2. Présence organe de coupure en tête d’installation"));
      expect(titles, contains("3.3. Présence parafoudre"));
      expect(titles, contains("4. Statistique par type de défaut : analyse de Pareto (corrigée)"));
      expect(titles, contains("5. Analyse comparative avec la visite précédente"));
      expect(titles, contains("6. Synthèse de l'analyse statistique"));
      expect(titles, contains("7. Recommandation pour le renforcement des capacités des agents d’entretien"));

      // Vérification que l'intitulé fictif/obsolète n'existe plus
      expect(titles, isNot(contains("Principales non-conformités et répartition")));

      // Vérification que MESURES DE SÉCURITÉ est un niveau 0 (main section box)
      final meSecuriteEntry = entries.firstWhere((e) => (e as dynamic).titre == "MESURES DE SÉCURITÉ AUTOUR DES INSTALLATIONS");
      expect((meSecuriteEntry as dynamic).level, equals(0));
    });

    test('Schema section should be included ONLY when schemaOption is Oui', () {
      final missionNoSchema = Mission(
        id: 'test_no_schema',
        nomClient: 'CLIENT TEST',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
        schemaOption: 'Non',
      );
      final entriesNoSchema = PdfReportService.getSommaireEntriesForTesting(mission: missionNoSchema);
      final titlesNoSchema = entriesNoSchema.map((e) => (e as dynamic).titre as String).toList();
      expect(titlesNoSchema, isNot(contains("SCHEMA DES INSTALLATIONS ELECTRIQUES")));

      final missionSchema = Mission(
        id: 'test_schema',
        nomClient: 'CLIENT TEST',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
        schemaOption: 'Oui',
      );
      final entriesSchema = PdfReportService.getSommaireEntriesForTesting(mission: missionSchema);
      final titlesSchema = entriesSchema.map((e) => (e as dynamic).titre as String).toList();
      expect(titlesSchema, contains("SCHEMA DES INSTALLATIONS ELECTRIQUES"));
    });
  });
}
