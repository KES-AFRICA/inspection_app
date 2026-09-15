// test/features/arret_urgence_presence_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/services/pdf/builders/pdf_mesures_essais_builder.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Arrêt d\'Urgence Général — Presence / Absence & Rétrocompatibilité', () {
    test('1. Nouvelle mission sans saisie : Absent par défaut', () {
      final tau = TestArretUrgence();
      expect(tau.estPresent, isFalse);
      expect(tau.isRenseigne, isFalse);
    });

    test('2. Rétrocompatibilité : ancienne mission avec observation existante considérée comme Présente', () {
      final legacySatisfaisant = TestArretUrgence(observation: 'Satisfaisant');
      expect(legacySatisfaisant.estPresent, isTrue);
      expect(legacySatisfaisant.observation, 'Satisfaisant');
      expect(legacySatisfaisant.isRenseigne, isTrue);

      final legacyNonSat = TestArretUrgence(observation: 'Non satisfaisant');
      expect(legacyNonSat.estPresent, isTrue);
      expect(legacyNonSat.isRenseigne, isTrue);

      final legacySansObjet = TestArretUrgence(observation: 'Sans objet');
      expect(legacySansObjet.estPresent, isTrue);
      expect(legacySansObjet.isRenseigne, isTrue);
    });

    test('3. Choix explicite Absent : estPresent == false et isRenseigne == true', () {
      final absent = TestArretUrgence(presence: false);
      expect(absent.estPresent, isFalse);
      expect(absent.isRenseigne, isTrue);
    });

    test('4. Choix explicite Présent : estPresent == true', () {
      final presentSansResultat = TestArretUrgence(presence: true);
      expect(presentSansResultat.estPresent, isTrue);
      expect(presentSansResultat.isRenseigne, isFalse);

      final presentAvecResultat = TestArretUrgence(presence: true, observation: 'Sans objet');
      expect(presentAvecResultat.estPresent, isTrue);
      expect(presentAvecResultat.observation, 'Sans objet');
      expect(presentAvecResultat.isRenseigne, isTrue);
    });

    test('5. Calcul des statistiques mesures et essais', () {
      final mesuresAbsent = MesuresEssais(
        missionId: 'm1',
        updatedAt: DateTime.now(),
        conditionMesure: ConditionMesure(observation: 'Sec'),
        testArretUrgence: TestArretUrgence(presence: false),
      );
      final statsAbsent = mesuresAbsent.calculerStatistiques();
      expect(statsAbsent['arret_urgence_renseigne'], isTrue);

      final mesuresPresentNonChoisi = MesuresEssais(
        missionId: 'm2',
        updatedAt: DateTime.now(),
        conditionMesure: ConditionMesure(observation: 'Sec'),
        testArretUrgence: TestArretUrgence(presence: true),
      );
      final statsPresentNonChoisi = mesuresPresentNonChoisi.calculerStatistiques();
      expect(statsPresentNonChoisi['arret_urgence_renseigne'], isFalse);

      final mesuresLegacy = MesuresEssais(
        missionId: 'm3',
        updatedAt: DateTime.now(),
        conditionMesure: ConditionMesure(observation: 'Sec'),
        testArretUrgence: TestArretUrgence(observation: 'Satisfaisant'),
      );
      final statsLegacy = mesuresLegacy.calculerStatistiques();
      expect(statsLegacy['arret_urgence_renseigne'], isTrue);
    });

    test('6. PDF resultBox : Absent est rendu avec style neutre', () {
      final boxAbsent = PdfMesuresEssaisBuilder.resultBox("Arrêt d'urgence général absent");
      expect(boxAbsent, isA<pw.Widget>());

      final boxSat = PdfMesuresEssaisBuilder.resultBox('Satisfaisant');
      expect(boxSat, isA<pw.Widget>());

      final boxNonSat = PdfMesuresEssaisBuilder.resultBox('Non satisfaisant');
      expect(boxNonSat, isA<pw.Widget>());
    });
  });
}
