import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/services/pdf/builders/pdf_executive_summary_builder.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/competency_needs_engine.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AuditFinding createFinding({
    required String id,
    required TensionDomain tensionDomain,
    required String origin,
    required String objectType,
    required String tableName,
    required String verificationPoint,
    String criticality = 'Majeure',
    String riskFamily = 'Protection contre les chocs électriques',
  }) {
    return AuditFinding(
      id: id,
      missionId: 'm_test_pres',
      tensionDomain: tensionDomain,
      origin: origin,
      objectType: objectType,
      objectName: objectType,
      tableName: tableName,
      verificationPoint: verificationPoint,
      observationText: 'Observation sur $verificationPoint',
      conformity: 'non',
      criticality: criticality,
      riskFamily: riskFamily,
    );
  }

  group('Section 3 & Section 10 Presentation Tests', () {
    test('1. Section 3 — Tableau A Structure MT et BT', () {
      // Données de test MT
      const mtStats = LocauxFindingsStats(
        dispoConstructives: 4,
        conditionsExploitation: 6,
      );

      final tableMt = PdfExecutiveSummaryBuilder.buildLocauxStatsTableForTesting(
        mtStats,
        isHta: true,
      );

      // Le tableau MT doit contenir 3 TableRow : 1 en-tête + 1 ligne dispo + 1 ligne TOTAL
      expect(tableMt.children.length, equals(3));

      // Données de test BT avec séparation GE et BT
      const btStats = LocauxFindingsStats(
        dispoConstructives: 9,
        conditionsExploitation: 12,
        dispoConstructivesGe: 3,
        dispoConstructivesBt: 6,
      );

      final tableBt = PdfExecutiveSummaryBuilder.buildLocauxStatsTableForTesting(
        btStats,
        isHta: false,
      );

      // Le tableau BT doit contenir 4 TableRow : 1 en-tête + 1 ligne GE + 1 ligne BT + 1 ligne TOTAL
      expect(tableBt.children.length, equals(4));
    });

    test('2. Section 3 — Tableau B Catégories renommées et largeurs de colonnes équilibrées', () {
      final findings = <AuditFinding>[];
      final instances = <DomainEntityInstance>[];

      // Local MT : 1 condition d'exploitation
      final localMtInst = DomainEntityInstance(
        instanceId: 'loc_mt_1',
        category: DomainObjectType.localMT,
        name: 'Local HTA',
        tensionDomain: TensionDomain.mt,
        originPath: 'Zone MT',
      );
      final mtCe = createFinding(
        id: 'mt_ce_1',
        tensionDomain: TensionDomain.mt,
        origin: 'Local HTA',
        objectType: 'Local MT',
        tableName: 'Conditions d\'exploitation',
        verificationPoint: 'Propreté du local',
      );
      localMtInst.findings.add(mtCe);
      instances.add(localMtInst);
      findings.add(mtCe);

      // Local GE : 1 condition d'exploitation
      final localGeInst = DomainEntityInstance(
        instanceId: 'loc_ge_1',
        category: DomainObjectType.localGE,
        name: 'Local GE',
        tensionDomain: TensionDomain.bt,
        originPath: 'Zone BT',
      );
      final geCe = createFinding(
        id: 'ge_ce_1',
        tensionDomain: TensionDomain.bt,
        origin: 'Local GE',
        objectType: 'Local GE',
        tableName: 'Conditions d\'exploitation',
        verificationPoint: 'Ventilation du local GE',
      );
      localGeInst.findings.add(geCe);
      instances.add(localGeInst);
      findings.add(geCe);

      // Local BT : 1 condition d'exploitation
      final localBtInst = DomainEntityInstance(
        instanceId: 'loc_bt_1',
        category: DomainObjectType.localBT,
        name: 'Local TGBT',
        tensionDomain: TensionDomain.bt,
        originPath: 'Zone BT',
      );
      final btCe = createFinding(
        id: 'bt_ce_1',
        tensionDomain: TensionDomain.bt,
        origin: 'Local TGBT',
        objectType: 'Local BT',
        tableName: 'Conditions d\'exploitation',
        verificationPoint: 'Stockage matériel',
      );
      localBtInst.findings.add(btCe);
      instances.add(localBtInst);
      findings.add(btCe);

      final domainInventory = MissionDomainInventory(
        missionId: 'm_test_pres',
        instances: instances,
        allFindings: findings,
      );
      final findingInventory = AuditFindingInventory(
        missionId: 'm_test_pres',
        findings: findings,
      );

      final technical = TechnicalEnrichmentEngine.compute(
        'm_test_pres',
        domainInventory,
        findingInventory,
      );

      // Tableau B MT : La catégorie de local doit être 'Conditions d\'exploitation (Locaux Techniques MT)'
      final mtExploitLocalRow = technical.mtExploitationCrossRows.firstWhere(
        (r) => r.categoryName.contains('Locaux Techniques MT'),
      );
      expect(
        mtExploitLocalRow.categoryName,
        equals('Conditions d\'exploitation (Locaux Techniques MT)'),
      );
      expect(mtExploitLocalRow.ncCount, equals(1));

      // Tableau B BT : Les catégories doivent être 'Conditions d\'exploitation (Locaux Techniques GE)' et 'Conditions d\'exploitation (Locaux Techniques BT)'
      final btExploitGeRow = technical.btExploitationCrossRows.firstWhere(
        (r) => r.categoryName.contains('Locaux Techniques GE'),
      );
      expect(
        btExploitGeRow.categoryName,
        equals('Conditions d\'exploitation (Locaux Techniques GE)'),
      );
      expect(btExploitGeRow.ncCount, equals(1));

      final btExploitBtRow = technical.btExploitationCrossRows.firstWhere(
        (r) => r.categoryName.contains('Locaux Techniques BT'),
      );
      expect(
        btExploitBtRow.categoryName,
        equals('Conditions d\'exploitation (Locaux Techniques BT)'),
      );
      expect(btExploitBtRow.ncCount, equals(1));

      // Vérification des largeurs de colonnes dans _buildCategoryCrossTable
      final tableMtCross = PdfExecutiveSummaryBuilder.buildCategoryCrossTableForTesting(
        technical.mtExploitationCrossRows,
        technical.mtExploitationTotalCrossRow,
        'MT',
      ) as pw.Table;

      final colWidths = tableMtCross.columnWidths!;
      // Colonne Equipements a été élargie vers la gauche (1.5) pour éviter que le 's' ne passe à la ligne
      expect((colWidths[1] as pw.FlexColumnWidth).flex, equals(1.5));
      // Colonnes NC, Critiques, Majeures, Densité ont la même largeur (1.1)
      expect((colWidths[2] as pw.FlexColumnWidth).flex, equals(1.1));
      expect((colWidths[3] as pw.FlexColumnWidth).flex, equals(1.1));
      expect((colWidths[4] as pw.FlexColumnWidth).flex, equals(1.1));
      expect((colWidths[5] as pw.FlexColumnWidth).flex, equals(1.1));
      // Colonne Catégorie MT / Catégorie BT reste largement dimensionnée (5.1)
      expect((colWidths[0] as pw.FlexColumnWidth).flex, equals(5.1));
    });

    test('3. Section 10 — Texte dynamique introductif et thématiques de prévention', () {
      final findings = [
        createFinding(
          id: 'f1',
          tensionDomain: TensionDomain.bt,
          origin: 'Coffret 1',
          objectType: 'Coffret',
          tableName: 'Points de vérification',
          verificationPoint: 'Absence d\'obturateur',
          criticality: 'Majeure',
          riskFamily: 'Chocs électriques directs',
        ),
        createFinding(
          id: 'f2',
          tensionDomain: TensionDomain.bt,
          origin: 'Armoire 1',
          objectType: 'Armoire',
          tableName: 'Points de vérification',
          verificationPoint: 'Surcharge disjoncteur',
          criticality: 'Majeure',
          riskFamily: 'Échauffement et incendie',
        ),
      ];

      final result = CompetencyNeedsEngine.analyze(
        missionId: 'm_test_pres',
        findings: findings,
      );

      // Le texte narratif introductif dynamique est bien présent
      expect(result.introNarrative, isNotEmpty);
      expect(result.introNarrative, contains('non-conformité'));
      expect(result.introNarrative, contains('plan de renforcement des compétences'));

      // Les axes de familles de risque sont bien générés
      expect(result.riskFamilyAxes, isNotEmpty);
      expect(result.riskFamilyAxes.first.letter, equals('A.'));
      expect(result.riskFamilyAxes.length, equals(2));
    });
  });
}
