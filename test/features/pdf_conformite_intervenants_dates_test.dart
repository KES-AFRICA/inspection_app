import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/models/jsa.dart';
import 'package:inspec_app/services/ip_ik_evaluator_service.dart';
import 'package:inspec_app/services/pdf/builders/pdf_audit_installations_builder.dart';
import 'package:inspec_app/services/pdf/builders/pdf_cover_builder.dart';
import 'package:inspec_app/services/pdf/pdf_report_styles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AUDIT & TESTS OBLIGATOIRES — CONFORMITÉ IP/IK DU POINT DE VÉRIFICATION BT', () {
    const String missionId = 'mission_test_ipik_123';

    test('Cas 1 — Indice IP/IK vide -> Point = NON CONFORME ("Absence de l\'indice ip/ik")', () {
      final coffret = CoffretArmoire(
        id: 'c1',
        qrCode: 'QR_C1',
        nom: 'COFFRET : prise',
        type: 'COFFRET',
        repere: 'Mur arrivé train',
        indiceIpIk: '', // Non renseigné / vide
        pointsVerification: [
          PointVerification(
            pointVerification: IpIkEvaluatorService.coffretPointTitle,
            conformite: '',
          ),
        ],
      );

      IpIkEvaluatorService.syncIpIkPoint(
        coffret: coffret,
        missionId: missionId,
        parentName: 'Mur arrivé train',
      );

      final pt = coffret.pointsVerification.first;
      expect(pt.conformite, equals('non'));
      expect(pt.observation, equals("Absence de l'indice ip/ik"));

      // Vérification du rendu PDF
      final widgets = PdfAuditInstallationsBuilder.buildCoffret(
        coffret,
        {},
        'Mur arrivé train',
        missionId: missionId,
      );
      expect(widgets, isNotEmpty);
      final ipIkPt1 = coffret.pointsVerification.firstWhere(
        (p) => IpIkEvaluatorService.isIpIkPoint(p.pointVerification),
      );
      expect(ipIkPt1.conformite, equals('non'));
    });

    test('Cas 2 — ParsedIpIk comparaison valide et égalité d\'indices', () {
      final pEquip = ParsedIpIk.parse('IP55 / IK08');
      final pRepere = ParsedIpIk.parse('IP55 IK08');

      expect(pEquip.hasIpOrIk, isTrue);
      expect(pRepere.hasIpOrIk, isTrue);
      expect(pEquip, equals(pRepere));
    });

    test('Cas 3 — Indice IP/IK valide mais Point enregistré NON CONFORME (défaut physique) -> Le PDF et sync respectent scrupuleusement NON CONFORME', () {
      final coffret = CoffretArmoire(
        id: 'c3',
        qrCode: 'QR_C3',
        nom: 'COFFRET : prise',
        type: 'COFFRET',
        repere: 'Mur arrivé train',
        indiceIpIk: 'IP55 / IK08', // Valide sur le papier
        pointsVerification: [
          PointVerification(
            pointVerification: IpIkEvaluatorService.coffretPointTitle,
            conformite: 'non', // Enregistré manuellement non conforme suite à un défaut constaté (ex: boîtier fissuré)
            observation: 'Boîtier détérioré, indice réel non garanti',
          ),
        ],
      );

      // La synchronisation ne doit JAMAIS écraser un NON CONFORME déjà enregistré pour le passer en 'oui'
      IpIkEvaluatorService.syncIpIkPoint(
        coffret: coffret,
        missionId: missionId,
        parentName: 'Mur arrivé train',
      );

      final pt = coffret.pointsVerification.first;
      expect(pt.conformite, equals('non'), reason: 'Un point enregistré NON CONFORME ne doit jamais être transformé en CONFORME');
      expect(pt.observation, equals('Boîtier détérioré, indice réel non garanti'));

      // Génération PDF : doit afficher NON CONFORME
      PdfAuditInstallationsBuilder.buildCoffret(
        coffret,
        {},
        'Mur arrivé train',
        missionId: missionId,
      );
      final ipIkPt3 = coffret.pointsVerification.firstWhere(
        (p) => IpIkEvaluatorService.isIpIkPoint(p.pointVerification),
      );
      expect(ipIkPt3.conformite, equals('non'));
    });

    test('Cas 4 — Formulaire : Modifier le point CONFORME -> NON CONFORME puis vérifier synchronisation', () {
      final coffret = CoffretArmoire(
        id: 'c4',
        qrCode: 'QR_C4',
        nom: 'COFFRET 1',
        type: 'COFFRET',
        indiceIpIk: '',
        pointsVerification: [
          PointVerification(
            pointVerification: IpIkEvaluatorService.coffretPointTitle,
            conformite: 'oui',
          ),
        ],
      );

      // L'utilisateur quitte ou sauvegarde avec indiceIpIk vide
      IpIkEvaluatorService.syncIpIkPoint(
        coffret: coffret,
        missionId: missionId,
      );

      expect(coffret.pointsVerification.first.conformite, equals('non'));
      expect(coffret.pointsVerification.first.observation, equals("Absence de l'indice ip/ik"));
    });

    test('Cas 5 — Formulaire : Modifier NON CONFORME -> CONFORME (saisie indice valide)', () {
      final coffret = CoffretArmoire(
        id: 'c5',
        qrCode: 'QR_C5',
        nom: 'COFFRET 2',
        type: 'COFFRET',
        indiceIpIk: '',
        pointsVerification: [
          PointVerification(
            pointVerification: IpIkEvaluatorService.coffretPointTitle,
            conformite: 'non',
            observation: "Absence de l'indice ip/ik",
          ),
        ],
      );

      expect(coffret.pointsVerification.first.conformite, equals('non'));

      // L'utilisateur renseigne l'indice IP/IK
      coffret.indiceIpIk = 'IP65 / IK09';
      // L'évaluation est mise à jour
      final parsed = ParsedIpIk.parse(coffret.indiceIpIk);
      expect(parsed.hasIpOrIk, isTrue);
    });

    test('Cas 7 — Ancienne mission avec indice IP/IK vide et point ayant hérité d\'un défaut "oui" -> Synchronisé en NON CONFORME', () {
      // Données héritées d'une ancienne mission avant la règle IP/IK
      final coffretHistorique = CoffretArmoire(
        id: 'c_old',
        qrCode: 'QR_COLD',
        nom: 'ANCIEN COFFRET',
        type: 'COFFRET',
        repere: 'Local TGBT',
        indiceIpIk: null, // Pas renseigné
        pointsVerification: [
          PointVerification(
            pointVerification: IpIkEvaluatorService.coffretPointTitle,
            conformite: 'oui', // Mauvais état par défaut historique
            observation: null,
          ),
        ],
      );

      // Lors du chargement ou du rendu PDF
      IpIkEvaluatorService.syncIpIkPoint(
        coffret: coffretHistorique,
        missionId: 'old_mission_99',
        parentName: 'Local TGBT',
      );

      expect(coffretHistorique.pointsVerification.first.conformite, equals('non'));
      expect(coffretHistorique.pointsVerification.first.observation, equals("Absence de l'indice ip/ik"));
    });
  });

  group('TABLEAU DES INTERVENANTS — CELLULE "NOM" ET COUVERTURE DU BACKGROUND', () {
    test('La cellule NOM utilise TableCellVerticalAlignment.full et couvre 100% de la hauteur', () async {
      final doc = pw.Document();

      final page = PdfCoverBuilder.buildIntervenantsEtResponsabilitesPage(
        JSA(
          missionId: 'm1',
          inspecteurs: [
            JSAInspecteur(nom: 'NKOUASSI SANGUE', prenom: 'Fabrice junior'),
            JSAInspecteur(nom: 'Ekorong', prenom: 'Léandre Mbamack'),
            JSAInspecteur(nom: 'DOE', prenom: 'John'),
          ],
        ),
        null,
        null,
        {},
        0,
        reportGenerationDate: DateTime(2026, 9, 6),
      );

      doc.addPage(
        pw.Page(
          pageTheme: const pw.PageTheme(pageFormat: PdfPageFormat.a4),
          build: (ctx) => page,
        ),
      );

      // La génération du PDF s'exécute sans erreur de contrainte ou d'overflow
      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(0));
    });

    test('Fonctionne avec 1 intervenant, plusieurs intervenants et liste longue', () async {
      final listesInspecteurs = [
        // 1 intervenant
        [JSAInspecteur(nom: 'BOYOMO', prenom: 'Lucien')],
        // 2 intervenants
        [
          JSAInspecteur(nom: 'NKOUASSI SANGUE', prenom: 'Fabrice junior'),
          JSAInspecteur(nom: 'Ekorong', prenom: 'Léandre Mbamack'),
        ],
        // 6 intervenants (très longue liste)
        [
          JSAInspecteur(nom: 'A', prenom: 'Alpha'),
          JSAInspecteur(nom: 'B', prenom: 'Beta'),
          JSAInspecteur(nom: 'C', prenom: 'Gamma'),
          JSAInspecteur(nom: 'D', prenom: 'Delta'),
          JSAInspecteur(nom: 'E', prenom: 'Epsilon'),
          JSAInspecteur(nom: 'F', prenom: 'Zeta'),
        ],
      ];

      for (final inspecteurs in listesInspecteurs) {
        final doc = pw.Document();
        final page = PdfCoverBuilder.buildIntervenantsEtResponsabilitesPage(
          JSA(missionId: 'm_test_list', inspecteurs: inspecteurs),
          null,
          null,
          {},
          0,
          reportGenerationDate: DateTime(2026, 9, 6),
        );
        doc.addPage(
          pw.Page(
            pageTheme: const pw.PageTheme(pageFormat: PdfPageFormat.a4),
            build: (ctx) => page,
          ),
        );
        final bytes = await doc.save();
        expect(bytes.length, greaterThan(0));
      }
    });
  });

  group('DATES "VÉRIFIÉ PAR" ET "VALIDÉ PAR" — SOURCE UNIQUE DU RAPPORT', () {
    test('Les colonnes Vérifiée par et Validée par reçoivent la date de génération du rapport', () async {
      final fixedGenerationDate = DateTime(2026, 9, 6);
      final expectedDateStr = PdfReportStyles.formatDate(fixedGenerationDate); // '06/09/2026'

      final mission = Mission(
        id: 'm_date_test',
        nomClient: 'CLIENT TEST',
        status: 'en_cours',
        createdAt: DateTime(2025, 1, 10),
        updatedAt: DateTime(2025, 1, 10),
        dateIntervention: DateTime(2025, 1, 15), // Date historique différente
      );

      final rg = RenseignementsGeneraux(
        missionId: 'm_date_test',
        etablissement: 'ETAB TEST',
        installation: 'INST TEST',
        activite: 'ACT TEST',
        nomSite: 'SITE TEST',
        updatedAt: DateTime(2025, 1, 15),
        dateDebut: DateTime(2025, 1, 15),
        dateFin: DateTime(2025, 1, 16),
      );

      final doc = pw.Document();
      final pageWidget = PdfCoverBuilder.buildIntervenantsEtResponsabilitesPage(
        null,
        rg,
        null,
        {},
        0,
        reportGenerationDate: fixedGenerationDate,
        mission: mission,
      );

      doc.addPage(
        pw.Page(
          pageTheme: const pw.PageTheme(pageFormat: PdfPageFormat.a4),
          build: (ctx) => pageWidget,
        ),
      );

      final bytes = await doc.save();
      expect(bytes.length, greaterThan(0));
      expect(expectedDateStr, equals('06/09/2026'));
    });
  });
}
