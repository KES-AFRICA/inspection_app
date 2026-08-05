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
      expect(titles, contains("FOUDRE"));
      expect(titles, contains("PHOTOS"));

      // Sous-sections d'Analyse Statistique
      expect(titles, contains("Non-conformités de l'année passée"));
      expect(titles, contains("Comparaison avec celles de cette année"));
      expect(titles, contains("Taux de mise en conformité"));
      expect(titles, contains("Inventaire chiffré des installations et équipements"));

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
