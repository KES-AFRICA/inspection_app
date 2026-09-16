import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/services/installation_description_sync_service.dart';
import 'package:inspec_app/services/pdf/builders/pdf_description_builder.dart';
import 'package:inspec_app/services/pdf/pdf_page_tracker.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('Régime de neutre - Normalisation & Extraction', () {
    test('Normalisation des 4 régimes standards', () {
      expect(InstallationDescriptionSyncService.normalizeRegimeNeutre('TT'), equals('TT'));
      expect(InstallationDescriptionSyncService.normalizeRegimeNeutre('tt'), equals('TT'));
      expect(InstallationDescriptionSyncService.normalizeRegimeNeutre('TN-C'), equals('TN-C'));
      expect(InstallationDescriptionSyncService.normalizeRegimeNeutre('TNC'), equals('TN-C'));
      expect(InstallationDescriptionSyncService.normalizeRegimeNeutre('TN-S'), equals('TN-S'));
      expect(InstallationDescriptionSyncService.normalizeRegimeNeutre('TNS'), equals('TN-S'));
      expect(InstallationDescriptionSyncService.normalizeRegimeNeutre('IT'), equals('IT'));
      expect(InstallationDescriptionSyncService.normalizeRegimeNeutre('it'), equals('IT'));
      expect(InstallationDescriptionSyncService.normalizeRegimeNeutre('Inconnu'), isNull);
    });

    test('Extraction depuis chaînes multiples avec détail TN', () {
      final res1 = InstallationDescriptionSyncService.extractRegimesFromText('TT, TN-S');
      expect(res1, containsAll(['TT', 'TN-S']));

      final res2 = InstallationDescriptionSyncService.extractRegimesFromText('TN', detail: 'S');
      expect(res2, contains('TN-S'));

      final res3 = InstallationDescriptionSyncService.extractRegimesFromText('TN', detail: 'C');
      expect(res3, contains('TN-C'));

      final res4 = InstallationDescriptionSyncService.extractRegimesFromText('TNC / IT, Autre Régime');
      expect(res4, containsAll(['TN-C', 'IT', 'Autre Régime']));

      final resEmpty = InstallationDescriptionSyncService.extractRegimesFromText('non renseigné');
      expect(resEmpty, isEmpty);
    });
  });

  group('Régime de neutre - Extraction depuis Transformateurs de l\'Audit', () {
    test('Collecte des régimes depuis locaux MT directs, zones MT et zones BT', () {
      final audit = AuditInstallationsElectriques.create('mission_transfo_test');

      // 1. Local MT direct avec un transfo TT
      audit.moyenneTensionLocaux.add(
        MoyenneTensionLocal(
          nom: 'Local MT 1',
          type: 'LOCAL',
          transformateurs: [
            TransformateurMTBT(
              marqueAnnee: 'Schneider',
              puissanceAssignee: '630',
              typeTransformateur: 'Huile',
              tensionPrimaireSecondaire: '20/0.4',
              relaisBuchholz: 'Oui',
              typeRefroidissement: 'ONAN',
              regimeNeutre: 'TT',
            ),
          ],
        ),
      );

      // 2. Zone MT avec transfo TN-S
      audit.moyenneTensionZones.add(
        MoyenneTensionZone(
          nom: 'Zone Usine',
          locaux: [
            MoyenneTensionLocal(
              nom: 'Local MT Usine',
              type: 'LOCAL',
              transformateurs: [
                TransformateurMTBT(
                  marqueAnnee: 'ABB',
                  puissanceAssignee: '1000',
                  typeTransformateur: 'Sec',
                  tensionPrimaireSecondaire: '20/0.4',
                  relaisBuchholz: 'Non',
                  typeRefroidissement: 'AN',
                  regimeNeutre: 'TN-S',
                ),
              ],
            ),
          ],
        ),
      );

      // 3. Zone BT avec transfo IT
      audit.basseTensionZones.add(
        BasseTensionZone(
          nom: 'Zone Hôpital',
          locaux: [
            BasseTensionLocal(
              nom: 'Local Secours',
              type: 'LOCAL',
              transformateurs: [
                TransformateurMTBT(
                  marqueAnnee: 'Legrand',
                  puissanceAssignee: '400',
                  typeTransformateur: 'Sec',
                  tensionPrimaireSecondaire: '20/0.4',
                  relaisBuchholz: 'Non',
                  typeRefroidissement: 'AN',
                  regimeNeutre: 'IT',
                ),
              ],
            ),
          ],
        ),
      );

      final regimesAudit = InstallationDescriptionSyncService.getRegimesNeutreFromAuditTransformers(audit);
      expect(regimesAudit, containsAll(['TT', 'TN-S', 'IT']));
      expect(regimesAudit.contains('TN-C'), isFalse);
    });
  });

  group('Régime de neutre - Règle séquentielle des 4 régimes (Automatisation)', () {
    test('Cas 1 : Formulaire description vide -> auto-complété depuis les transformateurs', () {
      final desc = DescriptionInstallations.create('mission_auto_1');
      desc.regimeNeutre = '';

      final audit = AuditInstallationsElectriques.create('mission_auto_1');
      audit.moyenneTensionLocaux.add(
        MoyenneTensionLocal(
          nom: 'Local MT 1',
          type: 'LOCAL',
          transformateurs: [
            TransformateurMTBT(
              marqueAnnee: 'Schneider',
              puissanceAssignee: '630',
              typeTransformateur: 'Huile',
              tensionPrimaireSecondaire: '20/0.4',
              relaisBuchholz: 'Oui',
              typeRefroidissement: 'ONAN',
              regimeNeutre: 'TT',
            ),
            TransformateurMTBT(
              marqueAnnee: 'Schneider',
              puissanceAssignee: '800',
              typeTransformateur: 'Huile',
              tensionPrimaireSecondaire: '20/0.4',
              relaisBuchholz: 'Oui',
              typeRefroidissement: 'ONAN',
              regimeNeutre: 'TN-C',
            ),
          ],
        ),
      );

      final effective = InstallationDescriptionSyncService.resolveEffectiveRegimes(
        desc: desc,
        audit: audit,
      );

      expect(effective, equals(['TT', 'TN-C']));
    });

    test('Cas 2 : Formulaire description a déjà un régime (IT) et transfo a TT -> combine les deux', () {
      final desc = DescriptionInstallations.create('mission_auto_2');
      desc.regimeNeutre = 'IT';

      final audit = AuditInstallationsElectriques.create('mission_auto_2');
      audit.moyenneTensionLocaux.add(
        MoyenneTensionLocal(
          nom: 'Local MT',
          type: 'LOCAL',
          transformateurs: [
            TransformateurMTBT(
              marqueAnnee: 'Schneider',
              puissanceAssignee: '630',
              typeTransformateur: 'Huile',
              tensionPrimaireSecondaire: '20/0.4',
              relaisBuchholz: 'Oui',
              typeRefroidissement: 'ONAN',
              regimeNeutre: 'TT',
            ),
          ],
        ),
      );

      final effective = InstallationDescriptionSyncService.resolveEffectiveRegimes(
        desc: desc,
        audit: audit,
      );

      // TT vient du transfo (non renseigné dans desc -> auto-coché)
      // IT vient de la description (déjà renseigné)
      expect(effective, containsAll(['TT', 'IT']));
      expect(effective.contains('TN-C'), isFalse);
      expect(effective.contains('TN-S'), isFalse);
    });

    test('Cas 3 : Conservation des régimes personnalisés "Autre"', () {
      final desc = DescriptionInstallations.create('mission_auto_3');
      desc.regimeNeutre = 'TN-S, Schéma spécial laboratoire';

      final audit = AuditInstallationsElectriques.create('mission_auto_3');
      audit.moyenneTensionLocaux.add(
        MoyenneTensionLocal(
          nom: 'Local MT',
          type: 'LOCAL',
          transformateurs: [
            TransformateurMTBT(
              marqueAnnee: 'Schneider',
              puissanceAssignee: '630',
              typeTransformateur: 'Huile',
              tensionPrimaireSecondaire: '20/0.4',
              relaisBuchholz: 'Oui',
              typeRefroidissement: 'ONAN',
              regimeNeutre: 'TT',
            ),
          ],
        ),
      );

      final effective = InstallationDescriptionSyncService.resolveEffectiveRegimes(
        desc: desc,
        audit: audit,
      );

      expect(effective, containsAll(['TT', 'TN-S', 'Schéma spécial laboratoire']));
    });

    test('Cas 4 : Aucun transformateur et description vide -> liste vide (génère absent dans PDF)', () {
      final desc = DescriptionInstallations.create('mission_auto_4');
      final audit = AuditInstallationsElectriques.create('mission_auto_4');

      final effective = InstallationDescriptionSyncService.resolveEffectiveRegimes(
        desc: desc,
        audit: audit,
      );

      expect(effective, isEmpty);
    });

    test('PDF Description Builder inclut automatiquement les régimes résolus', () async {
      final desc = DescriptionInstallations.create('mission_pdf_test');
      final audit = AuditInstallationsElectriques.create('mission_pdf_test');
      audit.moyenneTensionLocaux.add(
        MoyenneTensionLocal(
          nom: 'Poste MT',
          type: 'LOCAL',
          transformateurs: [
            TransformateurMTBT(
              marqueAnnee: 'Schneider',
              puissanceAssignee: '1250',
              typeTransformateur: 'Sec',
              tensionPrimaireSecondaire: '20/0.4',
              relaisBuchholz: 'Non',
              typeRefroidissement: 'AN',
              regimeNeutre: 'TN-S',
            ),
          ],
        ),
      );

      final trackedPages = <String, int>{};
      final widgets = PdfDescriptionBuilder.buildDescriptionInstallationsMulti(
        desc,
        audit,
        trackedPages,
      );

      expect(widgets.isNotEmpty, isTrue);

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          build: (context) => widgets,
        ),
      );
      await pdf.save();

      expect(trackedPages.containsKey('desc_regime_neutre'), isTrue);
    });
  });
}
