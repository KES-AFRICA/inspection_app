import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/services/pdf/builders/pdf_regulatory_builder.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Centrage vertical uniquement pour Missions et Vérificateur(s) dans le tableau Périmètre', () {
    test('Plusieurs vérificateurs (> 1) : label "Vérificateurs" avec s et centrage vertical (aligné à gauche)', () async {
      final mission = Mission(
        id: 'm_test_perimetre_multi',
        nomClient: 'TEST CLIENT',
        createdAt: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
        status: 'en_cours',
        perimetreMission: [
          'Vérification électrique',
          'Analyse du risque foudre et étude technique foudre',
          'Audit foudre',
          'Vérification thermographie infrarouge',
        ],
      );

      final rg = RenseignementsGeneraux(
        missionId: mission.id,
        etablissement: 'Site Test',
        installation: 'Installation BT',
        activite: 'Tertiaire',
        nomSite: 'Site Central',
        updatedAt: DateTime(2026, 9, 21),
        dateDebut: DateTime(2026, 7, 8),
        dateFin: DateTime(2026, 7, 9),
        accompagnateurs: [
          {'nom': 'KOLOTO', 'prenom': ''}
        ],
        compteRendu: ['KOLOTO'],
      );

      final jsa = JSA(
        missionId: mission.id,
        inspecteurs: [
          JSAInspecteur(nom: 'NKOUASSI', prenom: 'Fabrice'),
          JSAInspecteur(nom: 'NDI MA\'A', prenom: 'Vanelle'),
          JSAInspecteur(nom: 'TEUFACK', prenom: 'Andelson'),
        ],
      );

      final tableWidget = PdfRegulatoryBuilder.buildPerimetreTable(
        mission,
        rg,
        jsa: jsa,
      );

      expect(tableWidget, isA<pw.Table>());
      final table = tableWidget as pw.Table;

      // Row 0 : Missions (centré verticalement, aligné à gauche)
      final rowMissions = table.children[0];
      expect(rowMissions.verticalAlignment, equals(pw.TableCellVerticalAlignment.middle));
      final missionCell = rowMissions.children[0];
      expect(missionCell, isA<pw.Padding>());
      final missionsPadding = missionCell as pw.Padding;
      expect(missionsPadding.child, isA<pw.Text>());
      final missionsText = missionsPadding.child as pw.Text;
      expect((missionsText.text as pw.TextSpan).text, equals('Missions'));

      // Row 6 : Vérificateurs (au pluriel car 3 intervenants, centré verticalement, aligné à gauche)
      final rowVerificateurs = table.children[6];
      expect(rowVerificateurs.verticalAlignment, equals(pw.TableCellVerticalAlignment.middle));
      final verifCell = rowVerificateurs.children[0];
      expect(verifCell, isA<pw.Padding>());
      final verifPadding = verifCell as pw.Padding;
      expect(verifPadding.child, isA<pw.Text>());
      final verifText = verifPadding.child as pw.Text;
      expect((verifText.text as pw.TextSpan).text, equals('Vérificateurs'));

      // Vérification de la génération du document sans overflow
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => tableWidget,
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });

    test('Un seul vérificateur (== 1) : label "Vérificateur" sans s et centrage vertical', () async {
      final mission = Mission(
        id: 'm_test_perimetre_solo',
        nomClient: 'TEST CLIENT',
        createdAt: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
        status: 'en_cours',
        perimetreMission: ['Vérification électrique'],
      );

      final rg = RenseignementsGeneraux(
        missionId: mission.id,
        etablissement: 'Site Test',
        installation: 'Installation BT',
        activite: 'Tertiaire',
        nomSite: 'Site Central',
        updatedAt: DateTime(2026, 9, 21),
      );

      final jsa = JSA(
        missionId: mission.id,
        inspecteurs: [
          JSAInspecteur(nom: 'NKOUASSI', prenom: 'Fabrice'),
        ],
      );

      final tableWidget = PdfRegulatoryBuilder.buildPerimetreTable(
        mission,
        rg,
        jsa: jsa,
      );

      final table = tableWidget as pw.Table;

      // Row 6 : Vérificateur (au singulier car 1 seul intervenant)
      final rowVerificateurs = table.children[6];
      expect(rowVerificateurs.verticalAlignment, equals(pw.TableCellVerticalAlignment.middle));
      final verifCell = rowVerificateurs.children[0];
      expect(verifCell, isA<pw.Padding>());
      final verifPadding = verifCell as pw.Padding;
      final verifText = verifPadding.child as pw.Text;
      expect((verifText.text as pw.TextSpan).text, equals('Vérificateur'));

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => tableWidget,
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });
  });
}
