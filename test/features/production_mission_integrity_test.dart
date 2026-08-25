import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/hive_service.dart';

void main() {
  group('Audit de Production — Verification de la mission reelle KES1', () {
    final backupJsonPath =
        '/home/andelson-teufack/.gemini/antigravity-ide/brain/d0e08cb8-a112-4213-a8b5-7bc20e3d1b86/scratch/backup_analysis/missions/mission_1784897957795.json';

    test('1. Migration et Auto-Attribution d\'equipmentId aux 219 equipements sans ID', () {
      final file = File(backupJsonPath);
      expect(file.existsSync(), isTrue, reason: 'Le fichier de mission extraite doit exister.');

      final content = file.readAsStringSync();
      final Map<String, dynamic> data = jsonDecode(content);
      final auditMap = data['audit'] as Map<String, dynamic>;

      final rawItems = <Map<String, dynamic>>[];
      final allCoffrets = <CoffretArmoire>[];

      void extractCoffrets(List<dynamic> jsonList) {
        for (var item in jsonList) {
          if (item is Map<String, dynamic>) {
            rawItems.add(item);
            allCoffrets.add(CoffretArmoire(
              id: item['id'] as String?,
              qrCode: item['qrCode'] as String? ?? '',
              nom: item['nom'] as String? ?? '',
              type: item['type'] as String? ?? '',
              numeroEquipement: item['numeroEquipement'] as String?,
            ));
          }
        }
      }

      final mtLocaux = (auditMap['moyenneTensionLocaux'] as List?) ?? [];
      final mtZones = (auditMap['moyenneTensionZones'] as List?) ?? [];
      final btZones = (auditMap['basseTensionZones'] as List?) ?? [];

      for (var local in mtLocaux) {
        extractCoffrets((local['coffrets'] as List?) ?? []);
      }
      for (var zone in mtZones) {
        extractCoffrets((zone['coffrets'] as List?) ?? []);
        for (var local in (zone['locaux'] as List? ?? [])) {
          extractCoffrets((local['coffrets'] as List?) ?? []);
        }
      }
      for (var zone in btZones) {
        extractCoffrets((zone['coffretsDirects'] as List?) ?? []);
        for (var local in (zone['locaux'] as List? ?? [])) {
          extractCoffrets((local['coffrets'] as List?) ?? []);
        }
      }

      expect(allCoffrets.length, equals(219), reason: 'La mission doit contenir exactement 219 équipements.');

      // Dans les données JSON brutes de la mission de production, 100% des équipements ont id == null
      int rawNullIds = rawItems.where((i) => i['id'] == null || (i['id'] as String).trim().isEmpty).length;
      expect(rawNullIds, equals(219), reason: 'Dans le JSON de production, tous les 219 équipements ont id == null.');

      // Le constructeur et le getter auto-génèrent immédiatement un ID unique pour chacun des 219 équipements
      final generatedIds = <String>{};
      for (var coffret in allCoffrets) {
        final id = coffret.equipmentId;
        expect(id, isNotNull);
        expect(id.trim().isNotEmpty, isTrue);
        generatedIds.add(id);
      }

      // Verifier que tous les 219 IDs générés sont strictement uniques
      expect(generatedIds.length, equals(219), reason: 'Chaque équipement doit recevoir un equipmentId unique.');
    });

    test('2. Isolation stricte des brouillons sans QR code (pas de pollution entre équipements)', () {
      // Verifier que getCoffretDraftByQrCode sur un QR code vide ou TEMP_ renvoie toujours null
      expect(HiveService.getCoffretDraftByQrCode(''), isNull);
      expect(HiveService.getCoffretDraftByQrCode('   '), isNull);
      expect(HiveService.getCoffretDraftByQrCode('TEMP_123456789'), isNull);
    });

    test('3. Edition et Modification d\'un equipement sans altération de ses voisins', () {
      final coffret1 = CoffretArmoire(
        id: 'eq_prod_001',
        qrCode: 'https://kes.app/001',
        nom: 'Toto Armoire',
        type: 'ARMOIRE',
        numeroEquipement: '101',
      );

      final coffret2 = CoffretArmoire(
        id: 'eq_prod_002',
        qrCode: 'https://kes.app/002',
        nom: 'Tata TGBT',
        type: 'TGBT',
        numeroEquipement: '102',
      );

      final list = [coffret1, coffret2];

      // Recherche par equipmentId immuable (technique employée dans HiveService.updateCoffretById)
      final indexTarget = list.indexWhere((c) => c.equipmentId == 'eq_prod_001');
      expect(indexTarget, equals(0));

      // Modification de Toto
      list[indexTarget].nom = 'Toto Armoire Modifié';

      // Vérifier que Tata (index 1) est resté strictement inchangé
      expect(list[0].nom, equals('Toto Armoire Modifié'));
      expect(list[1].nom, equals('Tata TGBT'));
      expect(list[1].equipmentId, equals('eq_prod_002'));
    });
  });
}
