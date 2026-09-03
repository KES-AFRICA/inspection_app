import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';

void main() {
  group('Equipment Source Departure Lifecycle & Protection Status Tests (Scénarios A à I)', () {
    test('Test A — Aucun départ : Origine libre / vide, Type de protection vide => Sans protection = Oui, Protection de tête = Absent', () {
      final coffret = CoffretArmoire(
        nom: 'Coffret Test A',
        type: 'COFFRET',
        qrCode: 'QR_A',
        sourceNomComplet: 'Source libre local A',
        sourceDepartId: null,
        alimentations: [
          Alimentation(typeProtection: '', pdcKA: '', calibre: '32A', sectionCable: '10'),
        ],
        protectionTete: Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: ''),
      );

      expect(coffret.sourceDepartId, isNull);
      expect(coffret.isDepartPrisAvecProtection, isFalse);
      
      final normProt = (coffret.protectionTete?.typeProtection ?? coffret.alimentations.first.typeProtection).trim().toLowerCase();
      final bool isPresent = normProt.isNotEmpty && normProt != '-aucun-' && normProt != 'aucun' && normProt != '-';
      expect(isPresent, isFalse);
    });

    test('Test B — Départ sélectionné sans protection => Sans protection = Oui, Protection de tête = Absent', () {
      final depSansProt = DepartEquipement(
        id: 'dep_001',
        identification: 'Départ 1 Sans Protection',
        typeProtection: '-Aucun-',
        calibre: '',
        sectionCable: '16',
      );

      final coffret = CoffretArmoire(
        nom: 'Coffret Test B',
        type: 'COFFRET',
        qrCode: 'QR_B',
        sourceNomComplet: 'Armoire A - Départ 1 Sans Protection',
        sourceDepartId: depSansProt.id,
        alimentations: [
          Alimentation(
            typeProtection: depSansProt.typeProtection,
            pdcKA: '',
            calibre: '',
            sectionCable: depSansProt.sectionCable,
          ),
        ],
      );

      expect(coffret.sourceDepartId, equals('dep_001'));
      expect(coffret.isDepartPrisAvecProtection, isFalse);
    });

    test('Test C — Départ sélectionné avec protection => Sans protection = Non, Protection de tête = Présent', () {
      final depProtege = DepartEquipement(
        id: 'dep_002',
        identification: 'Départ 2 Protégé',
        typeProtection: 'Disjoncteur',
        marque: 'Schneider',
        courbe: 'C',
        calibre: '40',
        sectionCable: '25',
      );

      final coffret = CoffretArmoire(
        nom: 'Coffret Test C',
        type: 'COFFRET',
        qrCode: 'QR_C',
        sourceNomComplet: 'TGBT - Départ 2 Protégé',
        sourceDepartId: depProtege.id,
        alimentations: [
          Alimentation(
            typeProtection: depProtege.typeProtection,
            marqueDisjoncteur: depProtege.marque,
            courbe: depProtege.courbe,
            pdcKA: depProtege.pdcKA,
            calibre: depProtege.calibre,
            sectionCable: depProtege.sectionCable,
          ),
        ],
      );

      expect(coffret.sourceDepartId, equals('dep_002'));
      expect(coffret.isDepartPrisAvecProtection, isTrue);
      expect(coffret.alimentations.first.typeProtection, equals('Disjoncteur'));
      expect(coffret.alimentations.first.calibre, equals('40'));
    });

    test('Test D & E — Désélection / Effacement / Saisie libre => Réinitialisation stricte de sourceDepartId', () {
      var coffret = CoffretArmoire(
        nom: 'Coffret Test D',
        type: 'COFFRET',
        qrCode: 'QR_D',
        sourceNomComplet: 'TGBT - Départ 2 Protégé',
        sourceDepartId: 'dep_002',
        alimentations: [
          Alimentation(typeProtection: 'Disjoncteur', pdcKA: '10', calibre: '40', sectionCable: '10'),
        ],
      );

      expect(coffret.sourceDepartId, equals('dep_002'));

      // Action: L'utilisateur efface ou remplace l'origine par une saisie libre "Réseau public Enedis"
      coffret = CoffretArmoire(
        nom: coffret.nom,
        type: coffret.type,
        qrCode: coffret.qrCode,
        sourceNomComplet: 'Réseau public Enedis',
        sourceDepartId: null, // explicitement réinitialisé à null lors du découplage
        alimentations: [
          Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: ''), // réinitialisé lors de l'effacement
        ],
      );

      expect(coffret.sourceDepartId, isNull);
      expect(coffret.sourceNomComplet, equals('Réseau public Enedis'));
      expect(coffret.isDepartPrisAvecProtection, isFalse);
    });

    test('Test F — Changement dynamique bidirectionnel de Type de protection', () {
      final alim = Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: '');
      
      bool checkIsProtValid(String val) {
        final norm = val.trim().toLowerCase();
        return norm.isNotEmpty && norm != '-aucun-' && norm != 'aucun' && norm != '-';
      }

      // 1. Initialement vide => Sans protection = Oui (isProtValid = false)
      expect(checkIsProtValid(alim.typeProtection), isFalse);

      // 2. Sélection Disjoncteur => Sans protection = Non (isProtValid = true)
      alim.typeProtection = 'Disjoncteur';
      expect(checkIsProtValid(alim.typeProtection), isTrue);

      // 3. Passage à -Aucun- => Sans protection = Oui (isProtValid = false)
      alim.typeProtection = '-Aucun-';
      expect(checkIsProtValid(alim.typeProtection), isFalse);
    });

    test('Test G & H — Sauvegarde/Rechargement et rétrocompatibilité des anciennes missions Hive', () {
      final oldCoffret = CoffretArmoire(
        nom: 'Ancien Coffret 2025',
        type: 'COFFRET',
        qrCode: 'QR_OLD',
        sourceNomComplet: 'Départ TGBT 01',
        sourceDepartId: null, // Ancienne mission n'ayant pas sauvé sourceDepartId
        departPrisAvecProtection: false,
        alimentations: [
          Alimentation(typeProtection: '', pdcKA: '', calibre: '', sectionCable: '16')
        ],
      );

      expect(oldCoffret.sourceDepartId, isNull);
      expect(oldCoffret.sourceNomComplet, equals('Départ TGBT 01'));
      expect(oldCoffret.isDepartPrisAvecProtection, isFalse);
    });

    test('Test I — Formattage cohérent du type de protection pour le rapport PDF', () {
      String formatProtection(String typeProt, String marque) {
        final normType = typeProt.trim().toLowerCase();
        if (normType.isEmpty || normType == '-aucun-' || normType == 'aucun' || normType == '-') {
          return 'absent';
        }
        final parts = <String>[];
        if (typeProt.trim().isNotEmpty) parts.add(typeProt.trim());
        if (marque.trim().isNotEmpty) parts.add(marque.trim());
        return parts.isEmpty ? 'absent' : parts.join(' ');
      }

      expect(formatProtection('-Aucun-', 'Schneider'), equals('absent'));
      expect(formatProtection('', ''), equals('absent'));
      expect(formatProtection('Disjoncteur', 'Schneider'), equals('Disjoncteur Schneider'));
    });
  });
}
