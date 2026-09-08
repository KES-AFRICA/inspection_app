import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/pdf/builders/pdf_audit_installations_builder.dart';

void main() {
  group('PDF Conducteurs et Protection Tests', () {
    test('formatSectionWithConducteurs formate correctement les sections avec ou sans conducteurs', () {
      expect(
        PdfAuditInstallationsBuilder.formatSectionWithConducteurs('25 mm²', 2),
        equals('2 × 25'),
      );
      expect(
        PdfAuditInstallationsBuilder.formatSectionWithConducteurs('35', 1),
        equals('1 × 35'),
      );
      expect(
        PdfAuditInstallationsBuilder.formatSectionWithConducteurs('16 mm²', null),
        equals('16'),
      );
      expect(
        PdfAuditInstallationsBuilder.formatSectionWithConducteurs('16 mm²', 0),
        equals('16'),
      );
      expect(
        PdfAuditInstallationsBuilder.formatSectionWithConducteurs(null, 2),
        equals('-'),
      );
      expect(
        PdfAuditInstallationsBuilder.formatSectionWithConducteurs('', 2),
        equals('-'),
      );
      expect(
        PdfAuditInstallationsBuilder.formatSectionWithConducteurs('-', 2),
        equals('-'),
      );
    });

    test('formatTypeProtectionWithMarque gère absent, marque définie et marque non définie', () {
      expect(
        PdfAuditInstallationsBuilder.formatTypeProtectionWithMarque('Disjoncteur', 'Schneider'),
        equals('Disjoncteur\n(Schneider)'),
      );
      expect(
        PdfAuditInstallationsBuilder.formatTypeProtectionWithMarque('Disjoncteur', null),
        equals('Disjoncteur\n(Non défini)'),
      );
      expect(
        PdfAuditInstallationsBuilder.formatTypeProtectionWithMarque('Disjoncteur', ''),
        equals('Disjoncteur\n(Non défini)'),
      );
      expect(
        PdfAuditInstallationsBuilder.formatTypeProtectionWithMarque('', 'Schneider'),
        equals('absent'),
      );
      expect(
        PdfAuditInstallationsBuilder.formatTypeProtectionWithMarque('-', null),
        equals('absent'),
      );
    });

    test('buildProtectionCell retourne un widget avec (Non défini) en rouge si marque absente', () {
      final widgetSansMarque = PdfAuditInstallationsBuilder.buildProtectionCell('Disjoncteur', null);
      expect(widgetSansMarque, isA<pw.Container>());

      final container = widgetSansMarque as pw.Container;
      expect(container.child, isA<pw.Column>());
      final column = container.child as pw.Column;
      expect(column.children.length, equals(2));

      final typeText = column.children[0] as pw.Text;
      expect(typeText.text.toPlainText(), equals('Disjoncteur'));

      final marqueText = column.children[1] as pw.Text;
      expect(marqueText.text.toPlainText(), equals('(Non défini)'));
      final spanSansMarque = marqueText.text as pw.TextSpan;
      expect(spanSansMarque.style?.color, equals(PdfColors.red));

      // Avec marque
      final widgetAvecMarque = PdfAuditInstallationsBuilder.buildProtectionCell('Disjoncteur', 'Schneider');
      final colAvecMarque = (widgetAvecMarque as pw.Container).child as pw.Column;
      final marqueValText = colAvecMarque.children[1] as pw.Text;
      expect(marqueValText.text.toPlainText(), equals('(Schneider)'));
      final spanAvecMarque = marqueValText.text as pw.TextSpan;
      expect(spanAvecMarque.style?.color, isNull);

      // Absent
      final widgetAbsent = PdfAuditInstallationsBuilder.buildProtectionCell('', null);
      expect(widgetAbsent, isA<pw.Container>());
    });

    test('Cellule & Transformateur modèles : rétrocompatibilité et indépendance phase/neutre', () {
      // Cellule legacy
      final celluleLegacy = Cellule(
        fonction: 'Arrivée',
        type: 'Interrupteur',
        marqueModeleAnnee: 'Schneider 2018',
        tensionAssignee: '24',
        pouvoirCoupure: '16',
        numerotation: '1',
        parafoudres: 'Oui',
        sectionCables: '50 mm²',
      );
      expect(celluleLegacy.effectiveSectionCablePhase, equals('50 mm²'));
      expect(celluleLegacy.effectiveSectionCableNeutre, equals('50 mm²'));
      expect(celluleLegacy.effectiveConducteursPhase, equals(1));
      expect(celluleLegacy.effectiveConducteursNeutre, equals(1));

      // Cellule nouvelle
      final celluleNew = Cellule(
        fonction: 'Départ',
        type: 'Disjoncteur',
        marqueModeleAnnee: 'ABB 2023',
        tensionAssignee: '20',
        pouvoirCoupure: '25',
        numerotation: '2',
        parafoudres: 'Non',
        sectionCablePhase: '70 mm²',
        sectionCableNeutre: '50 mm²',
        conducteursPhase: 2,
        conducteursNeutre: 1,
      );
      expect(celluleNew.effectiveSectionCablePhase, equals('70 mm²'));
      expect(celluleNew.effectiveSectionCableNeutre, equals('50 mm²'));
      expect(celluleNew.effectiveConducteursPhase, equals(2));
      expect(celluleNew.effectiveConducteursNeutre, equals(1));

      // Transfo legacy
      final transfoLegacy = TransformateurMTBT(
        typeTransformateur: 'Huile',
        marqueAnnee: 'Schneider 2015',
        puissanceAssignee: '630',
        tensionPrimaireSecondaire: '20kV / 400V',
        relaisBuchholz: 'Oui',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'TT',
        sectionCables: '240 mm²',
      );
      expect(transfoLegacy.effectiveSectionCablePhase, equals('240 mm²'));
      expect(transfoLegacy.effectiveSectionCableNeutre, equals('240 mm²'));
      expect(transfoLegacy.effectiveConducteursPhase, equals(1));
      expect(transfoLegacy.effectiveConducteursNeutre, equals(1));

      // Transfo new
      final transfoNew = TransformateurMTBT(
        typeTransformateur: 'Sec',
        marqueAnnee: 'Legrand 2024',
        puissanceAssignee: '1000',
        tensionPrimaireSecondaire: '15kV / 400V',
        relaisBuchholz: 'Non',
        typeRefroidissement: 'AN',
        regimeNeutre: 'TNS',
        sectionCablePhase: '300 mm²',
        sectionCableNeutre: '150 mm²',
        conducteursPhase: 3,
        conducteursNeutre: 2,
      );
      expect(transfoNew.effectiveSectionCablePhase, equals('300 mm²'));
      expect(transfoNew.effectiveSectionCableNeutre, equals('150 mm²'));
      expect(transfoNew.effectiveConducteursPhase, equals(3));
      expect(transfoNew.effectiveConducteursNeutre, equals(2));
    });

    test('buildCelluleSection et buildTransformateurSection incluent le bandeau de conformité', () {
      final cellule = Cellule(
        fonction: 'Arrivée',
        type: 'Interrupteur',
        marqueModeleAnnee: 'Schneider',
        tensionAssignee: '24',
        pouvoirCoupure: '16',
        numerotation: '1',
        parafoudres: 'Oui',
        sectionCablePhase: '50 mm²',
        sectionCableNeutre: '50 mm²',
        conducteursPhase: 1,
        conducteursNeutre: 1,
      );

      final widgetsCellule = PdfAuditInstallationsBuilder.buildCelluleSection(cellule);
      expect(widgetsCellule.isNotEmpty, isTrue);

      // Vérifier présence du bandeau "VERIFICATION DE CONFORMITE DE LA CELLULE"
      bool foundCelluleBanner = false;
      for (final w in widgetsCellule) {
        if (w is pw.Container && w.child is pw.Text) {
          final txt = (w.child as pw.Text).text.toPlainText();
          if (txt == 'VERIFICATION DE CONFORMITE DE LA CELLULE') {
            foundCelluleBanner = true;
            break;
          }
        }
      }
      expect(foundCelluleBanner, isTrue);

      final transfo = TransformateurMTBT(
        typeTransformateur: 'Huile',
        marqueAnnee: 'Schneider',
        puissanceAssignee: '630',
        tensionPrimaireSecondaire: '20kV / 400V',
        relaisBuchholz: 'Oui',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'TT',
        sectionCablePhase: '240 mm²',
        sectionCableNeutre: '150 mm²',
        conducteursPhase: 2,
        conducteursNeutre: 1,
      );

      final widgetsTransfo = PdfAuditInstallationsBuilder.buildTransformateurSection(transfo);
      expect(widgetsTransfo.isNotEmpty, isTrue);

      // Vérifier présence du bandeau "VERIFICATION DE CONFORMITE DU TRANSFORMATEUR"
      bool foundTransfoBanner = false;
      for (final w in widgetsTransfo) {
        if (w is pw.Container && w.child is pw.Text) {
          final txt = (w.child as pw.Text).text.toPlainText();
          if (txt == 'VERIFICATION DE CONFORMITE DU TRANSFORMATEUR') {
            foundTransfoBanner = true;
            break;
          }
        }
      }
      expect(foundTransfoBanner, isTrue);
    });
  });
}
