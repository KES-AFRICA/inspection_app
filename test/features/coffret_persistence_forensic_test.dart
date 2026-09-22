import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/hive_service.dart';

void main() {
  group('Audit Forensique — Persistance et Cycle de vie des Équipements', () {
    test('1. Dédoublonnage : Deux équipements ayant le même nom textuel sont tous les deux conservés (Non-écrasement)', () {
      final coffretA = CoffretArmoire(
        id: 'equip_101',
        nom: 'Armoire Climatisation',
        type: 'ARMOIRE',
        qrCode: 'QR_CLIM_A',
      );

      final coffretB = CoffretArmoire(
        id: 'equip_102',
        nom: 'Armoire Climatisation', // Même nom exact !
        type: 'ARMOIRE',
        qrCode: 'QR_CLIM_B',
      );

      final list = [coffretA, coffretB];
      final result = HiveService.deduplicateCoffrets(list);

      expect(result.length, equals(2), reason: 'Deux équipements distincts portant le même libellé ne doivent jamais être fusionnés.');
      expect(result.map((c) => c.equipmentId).toSet(), containsAll(['equip_101', 'equip_102']));
    });

    test('2. Dédoublonnage : Deux instances du même équipement (même ID) sont fusionnées sans perte de données', () {
      final coffretBase = CoffretArmoire(
        id: 'equip_200',
        nom: 'TGBT',
        type: 'TGBT',
        qrCode: 'QR_TGBT',
        departures: [
          DepartEquipement(id: 'dep_1', identification: 'Départ Atelier'),
        ],
      );

      final coffretEnrichi = CoffretArmoire(
        id: 'equip_200', // Même ID
        nom: 'TGBT',
        type: 'TGBT',
        qrCode: 'QR_TGBT',
        departures: [
          DepartEquipement(id: 'dep_2', identification: 'Départ Bureaux'),
        ],
        photos: ['photo_tgbt_1.jpg'],
      );

      final result = HiveService.deduplicateCoffrets([coffretBase, coffretEnrichi]);

      expect(result.length, equals(1));
      final merged = result.first;
      expect(merged.equipmentId, equals('equip_200'));
      expect(merged.effectiveDepartures.length, equals(2), reason: 'Les départs doivent être fusionnés sans perte.');
      expect(merged.photos, contains('photo_tgbt_1.jpg'));
    });

    test('3. Stabilité des IDs : CoffretArmoire génère des IDs stables et reproductibles pour les anciennes missions', () {
      final fixedDate = DateTime.utc(2025, 1, 15, 10, 30);
      final coffretHistorique1 = CoffretArmoire(
        nom: 'Coffret Prises',
        type: 'COFFRET',
        qrCode: '',
        createdAt: fixedDate,
      );

      final id1 = coffretHistorique1.equipmentId;

      final coffretHistorique2 = CoffretArmoire(
        nom: 'Coffret Prises',
        type: 'COFFRET',
        qrCode: '',
        createdAt: fixedDate,
      );

      final id2 = coffretHistorique2.equipmentId;

      expect(id1, equals(id2), reason: 'Deux relectures successives d\'une même entité historique doivent produire un identifiant strictement identique.');
      expect(id1, isNotEmpty);
    });

    test('4. Stabilité des IDs : BasseTensionLocal et MoyenneTensionLocal ont des IDs stables sans microsecondes aléatoires', () {
      final fixedDate = DateTime.utc(2025, 2, 10, 8, 0);

      final localBT1 = BasseTensionLocal(
        nom: 'Local Compresseurs',
        type: 'LOCAL_TGBT',
        createdAt: fixedDate,
      );
      final localBT2 = BasseTensionLocal(
        nom: 'Local Compresseurs',
        type: 'LOCAL_TGBT',
        createdAt: fixedDate,
      );

      expect(localBT1.localId, equals(localBT2.localId), reason: 'L\'ID du local BT doit être déterministe et stable.');

      final localMT1 = MoyenneTensionLocal(
        nom: 'Sous-Station MT',
        type: 'LOCAL_TRANSFORMATEUR',
        createdAt: fixedDate,
      );
      final localMT2 = MoyenneTensionLocal(
        nom: 'Sous-Station MT',
        type: 'LOCAL_TRANSFORMATEUR',
        createdAt: fixedDate,
      );

      expect(localMT1.localId, equals(localMT2.localId), reason: 'L\'ID du local MT doit être déterministe et stable.');
    });

    test('5. Stabilité des IDs : BasseTensionZone et MoyenneTensionZone ont des IDs stables', () {
      final fixedDate = DateTime.utc(2025, 3, 1, 12, 0);

      final zoneBT1 = BasseTensionZone(
        nom: 'Zone Usine Nord',
        createdAt: fixedDate,
      );
      final zoneBT2 = BasseTensionZone(
        nom: 'Zone Usine Nord',
        createdAt: fixedDate,
      );

      expect(zoneBT1.zoneId, equals(zoneBT2.zoneId), reason: 'L\'ID de zone BT doit être déterministe et stable.');

      final zoneMT1 = MoyenneTensionZone(
        nom: 'Zone Poste Source',
        createdAt: fixedDate,
      );
      final zoneMT2 = MoyenneTensionZone(
        nom: 'Zone Poste Source',
        createdAt: fixedDate,
      );

      expect(zoneMT1.zoneId, equals(zoneMT2.zoneId), reason: 'L\'ID de zone MT doit être déterministe et stable.');
    });

    test('6. Stabilité des IDs MT : Cellule et TransformateurMTBT ont des syncId stables sans microsecondes aléatoires', () {
      final fixedDate = DateTime.utc(2025, 4, 20, 14, 0);

      final cellule1 = Cellule(
        fonction: 'Cellule Arrivée 1',
        type: 'ARRIVEE',
        marqueModeleAnnee: 'Schneider 2018',
        tensionAssignee: '20 kV',
        pouvoirCoupure: '16 kA',
        numerotation: '1',
        parafoudres: 'Non',
        createdAt: fixedDate,
      );
      final cellule2 = Cellule(
        fonction: 'Cellule Arrivée 1',
        type: 'ARRIVEE',
        marqueModeleAnnee: 'Schneider 2018',
        tensionAssignee: '20 kV',
        pouvoirCoupure: '16 kA',
        numerotation: '1',
        parafoudres: 'Non',
        createdAt: fixedDate,
      );

      expect(cellule1.syncId, equals(cellule2.syncId), reason: 'Le syncId de Cellule doit être déterministe et stable.');

      final transfo1 = TransformateurMTBT(
        typeTransformateur: 'Transformateur Huile',
        marqueAnnee: 'France Transfo 2015',
        puissanceAssignee: '630 kVA',
        tensionPrimaireSecondaire: '20kV / 400V',
        relaisBuchholz: 'Oui',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'TN-S',
        createdAt: fixedDate,
      );
      final transfo2 = TransformateurMTBT(
        typeTransformateur: 'Transformateur Huile',
        marqueAnnee: 'France Transfo 2015',
        puissanceAssignee: '630 kVA',
        tensionPrimaireSecondaire: '20kV / 400V',
        relaisBuchholz: 'Oui',
        typeRefroidissement: 'ONAN',
        regimeNeutre: 'TN-S',
        createdAt: fixedDate,
      );

      expect(transfo1.syncId, equals(transfo2.syncId), reason: 'Le syncId de TransformateurMTBT doit être déterministe et stable.');
    });
  });
}
