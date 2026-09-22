// test/features/mt_bt_equipment_separation_forensic_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/services/pdf/builders/pdf_equipements_synthesis_builder.dart';
import 'package:inspec_app/services/statistics/audit_finding.dart';
import 'package:inspec_app/services/statistics/domain_entity_instance.dart';
import 'package:inspec_app/services/statistics/mission_domain_inventory_engine.dart';
import 'package:inspec_app/services/statistics/technical_enrichment_engine.dart';

Mission _createMission(String id) {
  final now = DateTime.now();
  return Mission(
    id: id,
    nomClient: 'Client Test',
    createdAt: now,
    updatedAt: now,
    status: 'en_cours',
  );
}

AuditInstallationsElectriques _createAudit({
  required String missionId,
  List<MoyenneTensionLocal>? moyenneTensionLocaux,
  List<MoyenneTensionZone>? moyenneTensionZones,
  List<BasseTensionZone>? basseTensionZones,
}) {
  return AuditInstallationsElectriques(
    missionId: missionId,
    updatedAt: DateTime.now(),
    moyenneTensionLocaux: moyenneTensionLocaux,
    moyenneTensionZones: moyenneTensionZones,
    basseTensionZones: basseTensionZones,
  );
}

Cellule _createCellule({
  required String type,
  required String fonction,
  String numerotation = '1',
  List<ElementControle>? elementsVerifies,
}) {
  return Cellule(
    fonction: fonction,
    type: type,
    marqueModeleAnnee: 'Schneider 2020',
    tensionAssignee: '20 kV',
    pouvoirCoupure: '16 kA',
    numerotation: numerotation,
    parafoudres: 'Oui',
    elementsVerifies: elementsVerifies,
  );
}

TransformateurMTBT _createTransformateur({
  required String typeTransformateur,
  required String puissanceAssignee,
  String repere = 'TR-1',
  List<ElementControle>? elementsVerifies,
}) {
  return TransformateurMTBT(
    typeTransformateur: typeTransformateur,
    marqueAnnee: 'France Transfo 2020',
    puissanceAssignee: puissanceAssignee,
    tensionPrimaireSecondaire: '20 kV / 400 V',
    relaisBuchholz: 'Oui',
    typeRefroidissement: 'ONAN',
    regimeNeutre: 'TN-S',
    repere: repere,
    elementsVerifies: elementsVerifies,
  );
}

CoffretArmoire _createCoffret({
  required String nom,
  required String type,
  String? repere,
  String qrCode = 'QR_CODE_TEST',
  List<PointVerification>? pointsVerification,
}) {
  return CoffretArmoire(
    nom: nom,
    type: type,
    repere: repere,
    qrCode: qrCode,
    pointsVerification: pointsVerification,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Forensic MT / BT Equipment Separation Tests', () {
    test('Scénario 1 — Local MT pur : uniquement Cellules et Transformateurs', () {
      final mission = _createMission('mission_mt_pure');

      final localMT = MoyenneTensionLocal(
        nom: 'Poste MT Principal',
        type: 'LOCAL_POSTE_HTA',
        cellules: [
          _createCellule(type: 'ARRIVEE', fonction: 'Arrivée HTA', numerotation: '1'),
          _createCellule(type: 'PROTECTION', fonction: 'Protection Transfo', numerotation: '2'),
        ],
        transformateurs: [
          _createTransformateur(
            typeTransformateur: 'HUILE',
            puissanceAssignee: '630 kVA',
            repere: 'TR1',
          ),
        ],
      );

      final audit = _createAudit(
        missionId: mission.id,
        moyenneTensionLocaux: [localMT],
      );

      final inventory = MissionDomainInventoryEngine.buildInventory(
        mission.id,
        audit: audit,
      );

      final findingInventory = AuditFindingInventory(
        missionId: mission.id,
        findings: inventory.pertinentFindings,
      );

      final tech = TechnicalEnrichmentEngine.compute(
        mission.id,
        inventory,
        findingInventory,
      );

      // Vérification des populations MT
      expect(tech.totalCellules, equals(2));
      expect(tech.totalTransformateurs, equals(1));
      expect(tech.totalEquipementsMT, equals(3));
      expect(tech.totalEquipementsBT, equals(0));
      expect(tech.totalEquipementsElectriques, equals(3));

      // Vérification des catégories croisées MT
      final mtRowNames = tech.mtCategoriesCrossRows.map((r) => r.categoryName).toList();
      expect(mtRowNames, contains('Locaux techniques'));
      expect(mtRowNames, contains('Cellules'));
      expect(mtRowNames, contains('Transformateurs'));
      expect(mtRowNames, isNot(contains('Armoires / Coffrets MT')));

      // Parité avec PdfEquipementsSynthesisBuilder
      final synthMT = PdfEquipementsSynthesisBuilder.collectEquipementsMT(audit);
      final synthBT = PdfEquipementsSynthesisBuilder.collectEquipementsBT(audit, null);
      expect(synthMT.length, equals(3));
      expect(synthBT.length, equals(0));
    });

    test('Scénario 2 — Local BT pur : uniquement TGBT, Armoires et Coffrets', () {
      final mission = _createMission('mission_bt_pure');

      final localBT = BasseTensionLocal(
        nom: 'Local TGBT Usine',
        type: 'LOCAL_TGBT',
        coffrets: [
          _createCoffret(
            nom: 'TGBT Principal',
            type: 'TGBT',
            repere: 'TGBT-1',
            qrCode: 'QR_TGBT1',
          ),
          _createCoffret(
            nom: 'Armoire Climatisation',
            type: 'Armoire',
            repere: 'ARM-CLIM',
            qrCode: 'QR_ARMCLIM',
          ),
          _createCoffret(
            nom: 'Coffret Éclairage',
            type: 'Coffret',
            repere: 'COF-ECL',
            qrCode: 'QR_COFECL',
          ),
        ],
      );

      final audit = _createAudit(
        missionId: mission.id,
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Production',
            locaux: [localBT],
          ),
        ],
      );

      final inventory = MissionDomainInventoryEngine.buildInventory(
        mission.id,
        audit: audit,
      );

      final findingInventory = AuditFindingInventory(
        missionId: mission.id,
        findings: inventory.pertinentFindings,
      );

      final tech = TechnicalEnrichmentEngine.compute(
        mission.id,
        inventory,
        findingInventory,
      );

      // Vérification des populations
      expect(tech.totalEquipementsMT, equals(0));
      expect(tech.totalTgbt, equals(1));
      expect(tech.totalArmoires, equals(1));
      expect(tech.totalCoffrets, equals(1));
      expect(tech.totalEquipementsBT, equals(3));
      expect(tech.totalEquipementsElectriques, equals(3));

      // Parité avec PdfEquipementsSynthesisBuilder
      final synthMT = PdfEquipementsSynthesisBuilder.collectEquipementsMT(audit);
      final synthBT = PdfEquipementsSynthesisBuilder.collectEquipementsBT(audit, null);
      expect(synthMT.length, equals(0));
      expect(synthBT.length, equals(3));
    });

    test('Scénario 3 — Local mixte critique : reproduction analytique sans contamination', () {
      final mission = _createMission('mission_mixte');

      // Un local MT qui contient physiquement des équipements MT ET des équipements BT
      final localPoste = MoyenneTensionLocal(
        nom: 'Poste HTA Bessengué',
        type: 'LOCAL_POSTE_HTA',
        cellules: [
          _createCellule(
            type: 'ARRIVEE',
            fonction: 'Arrivée',
            numerotation: '1',
            elementsVerifies: [
              ElementControle(
                elementControle: 'Verrouillage mécanique HTA',
                conforme: false,
                criticite: 'Majeure',
                priorite: 2,
              ),
            ],
          ),
        ],
        transformateurs: [
          _createTransformateur(
            typeTransformateur: 'HUILE',
            puissanceAssignee: '1000 kVA',
            repere: 'TR-01',
            elementsVerifies: [
              ElementControle(
                elementControle: 'Bac de rétention d\'huile',
                conforme: false,
                criticite: 'Critique',
                priorite: 1,
              ),
            ],
          ),
        ],
        coffrets: [
          _createCoffret(
            nom: 'TGBT Général',
            type: 'TGBT',
            repere: 'TGBT-GEN',
            qrCode: 'QR_TGBTGEN',
            pointsVerification: [
              PointVerification(
                pointVerification: 'Identification des circuits départs',
                conformite: 'Non conforme',
                criticite: 'Majeure',
                priorite: 2,
              ),
            ],
          ),
          _createCoffret(
            nom: 'Armoire Services Auxiliaires',
            type: 'Armoire',
            repere: 'ARM-AUX',
            qrCode: 'QR_ARMAUX',
            pointsVerification: [
              PointVerification(
                pointVerification: 'Repérage des conducteurs',
                conformite: 'Non conforme',
                criticite: 'Mineure',
                priorite: 3,
              ),
            ],
          ),
        ],
      );

      final audit = _createAudit(
        missionId: mission.id,
        moyenneTensionLocaux: [localPoste],
      );

      final inventory = MissionDomainInventoryEngine.buildInventory(
        mission.id,
        audit: audit,
      );

      // 1. Contrôle des domaines des instances d'équipements
      final celluleInstance = inventory.instances.firstWhere((i) => i.category == DomainObjectType.celluleMT);
      final transfoInstance = inventory.instances.firstWhere((i) => i.category == DomainObjectType.transformateurMTBT);
      final tgbtInstance = inventory.instances.firstWhere((i) => i.category == DomainObjectType.tgbt);
      final armoireInstance = inventory.instances.firstWhere((i) => i.category == DomainObjectType.armoire);

      expect(celluleInstance.tensionDomain, equals(TensionDomain.mt));
      expect(transfoInstance.tensionDomain, equals(TensionDomain.mt));
      expect(tgbtInstance.tensionDomain, equals(TensionDomain.bt));
      expect(armoireInstance.tensionDomain, equals(TensionDomain.bt));

      // 2. Contrôle des parents : le local d'accueil physique est fidèlement conservé
      expect(tgbtInstance.parentLocal, equals('Poste HTA Bessengué'));
      expect(armoireInstance.parentLocal, equals('Poste HTA Bessengué'));

      // 3. Contrôle des domaines des non-conformités (Findings)
      final mtFindings = inventory.pertinentFindings.where((f) => f.tensionDomain == TensionDomain.mt).toList();
      final btFindings = inventory.pertinentFindings.where((f) => f.tensionDomain == TensionDomain.bt).toList();

      expect(mtFindings.length, equals(2), reason: 'Uniquement Verrouillage Cellule et Bac Transfo');
      expect(btFindings.length, equals(2), reason: 'Uniquement TGBT et Armoire Auxiliaire');

      // Vérifier qu'aucune NC de TGBT ou d'armoire n'est contaminée en MT
      for (final f in mtFindings) {
        expect(f.objectType, isNot(equals('TGBT')));
        expect(f.objectType, isNot(equals('Armoire')));
        expect(f.objectType, isNot(equals('Coffret')));
        expect(f.objectType, isNot(equals('Inverseur')));
      }

      // 4. Contrôle des totaux techniques
      final findingInventory = AuditFindingInventory(
        missionId: mission.id,
        findings: inventory.pertinentFindings,
      );

      final tech = TechnicalEnrichmentEngine.compute(
        mission.id,
        inventory,
        findingInventory,
      );

      expect(tech.totalCellules, equals(1));
      expect(tech.totalTransformateurs, equals(1));
      expect(tech.totalEquipementsMT, equals(2));

      expect(tech.totalTgbt, equals(1));
      expect(tech.totalArmoires, equals(1));
      expect(tech.totalCoffrets, equals(0));
      expect(tech.totalInverseurs, equals(0));
      expect(tech.totalEquipementsBT, equals(2));

      expect(tech.totalEquipementsElectriques, equals(4));

      // Le tableau MT ne doit JAMAIS contenir de ligne Armoires/Coffrets MT
      final mtRowNames = tech.mtCategoriesCrossRows.map((r) => r.categoryName).toList();
      expect(mtRowNames, isNot(contains('Armoires / Coffrets MT')));

      // Le tableau BT contient le TGBT et l'Armoire
      final tgbtRow = tech.btCategoriesCrossRows.firstWhere((r) => r.categoryName == 'TGBT');
      final armoireRow = tech.btCategoriesCrossRows.firstWhere((r) => r.categoryName == 'Armoires');
      expect(tgbtRow.equipementsCount, equals(1));
      expect(armoireRow.equipementsCount, equals(1));

      // 5. Parité stricte avec PdfEquipementsSynthesisBuilder
      final synthMT = PdfEquipementsSynthesisBuilder.collectEquipementsMT(audit);
      final synthBT = PdfEquipementsSynthesisBuilder.collectEquipementsBT(audit, null);

      expect(synthMT.length, equals(2));
      expect(synthBT.length, equals(2));

      // Dans la synthèse BT, les équipements ont le local physique 'Poste HTA Bessengué'
      expect(synthBT.every((e) => e.localName == 'Poste HTA Bessengué'), isTrue);
      expect(synthBT.every((e) => e.isMT == false), isTrue);
    });

    test('Scénario 4 — Équipement BT dans une zone MT : le domaine reste strictement BT', () {
      final mission = _createMission('mission_zone_mt');

      final audit = _createAudit(
        missionId: mission.id,
        moyenneTensionZones: [
          MoyenneTensionZone(
            nom: 'Zone Sous-Station MT',
            coffrets: [
              _createCoffret(
                nom: 'Coffret Prises Zone MT',
                type: 'Coffret',
                repere: 'COF-PC',
                qrCode: 'QR_COFPC',
              ),
            ],
          ),
        ],
      );

      final inventory = MissionDomainInventoryEngine.buildInventory(
        mission.id,
        audit: audit,
      );

      final findingInventory = AuditFindingInventory(
        missionId: mission.id,
        findings: inventory.pertinentFindings,
      );

      final tech = TechnicalEnrichmentEngine.compute(
        mission.id,
        inventory,
        findingInventory,
      );

      expect(tech.totalEquipementsMT, equals(0));
      expect(tech.totalCoffrets, equals(1));
      expect(tech.totalEquipementsBT, equals(1));

      final synthMT = PdfEquipementsSynthesisBuilder.collectEquipementsMT(audit);
      final synthBT = PdfEquipementsSynthesisBuilder.collectEquipementsBT(audit, null);
      expect(synthMT.length, equals(0));
      expect(synthBT.length, equals(1));
      expect(synthBT.first.zoneName, equals('Zone Sous-Station MT'));
      expect(synthBT.first.isMT, isFalse);
    });

    test('Scénario 5 — Matrice de vérification unifiée : concordance de tous les indicateurs', () {
      final mission = _createMission('mission_matrice');

      final audit = _createAudit(
        missionId: mission.id,
        moyenneTensionLocaux: [
          MoyenneTensionLocal(
            nom: 'Poste 1',
            type: 'LOCAL_POSTE_HTA',
            cellules: [_createCellule(type: 'ARRIVEE', fonction: 'Cellule 1')],
            transformateurs: [
              _createTransformateur(
                typeTransformateur: 'HUILE',
                puissanceAssignee: '400 kVA',
              ),
            ],
            coffrets: [
              _createCoffret(nom: 'TGBT 1', type: 'TGBT', qrCode: 'QR_1'),
              _createCoffret(nom: 'Inverseur Normal/Secours', type: 'Inverseur', qrCode: 'QR_2'),
            ],
          ),
        ],
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone B',
            locaux: [
              BasseTensionLocal(
                nom: 'Local B1',
                type: 'LOCAL_TGBT',
                coffrets: [
                  _createCoffret(nom: 'Armoire Distribution', type: 'Armoire', qrCode: 'QR_3'),
                  _createCoffret(nom: 'Coffret Éclairage', type: 'Coffret', qrCode: 'QR_4'),
                ],
              ),
            ],
          ),
        ],
      );

      final inventory = MissionDomainInventoryEngine.buildInventory(
        mission.id,
        audit: audit,
      );

      final findingInventory = AuditFindingInventory(
        missionId: mission.id,
        findings: inventory.pertinentFindings,
      );

      final tech = TechnicalEnrichmentEngine.compute(
        mission.id,
        inventory,
        findingInventory,
      );

      // Total MT = 1 Cellule + 1 Transformateur = 2
      expect(tech.totalEquipementsMT, equals(2));
      // Total BT = 1 TGBT + 1 Inverseur + 1 Armoire + 1 Coffret = 4
      expect(tech.totalEquipementsBT, equals(4));
      // Total Global = 6
      expect(tech.totalEquipementsElectriques, equals(6));

      // Vérification de parité absolue avec la Synthèse
      final synthMT = PdfEquipementsSynthesisBuilder.collectEquipementsMT(audit);
      final synthBT = PdfEquipementsSynthesisBuilder.collectEquipementsBT(audit, null);

      expect(synthMT.length, equals(tech.totalEquipementsMT));
      expect(synthBT.length, equals(tech.totalEquipementsBT));
      expect(synthMT.length + synthBT.length, equals(tech.totalEquipementsElectriques));
    });
  });
}
