import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/services/document_generation/essai_declenchement_helper.dart';

void main() {
  group('Restriction DDR conditionnelle (isDdrApplicable)', () {
    test('Identifie correctement les dispositifs différentiels autorisant le champ DDR', () {
      final validTypes = [
        'Interrupteur différentiel',
        'Disjoncteur différentiel',
        'DISJONCTEUR DIFFERENTIEL',
        'interrupteur differentiel',
        'DDR',
        'Bloc DDR',
        'Relais différentiel',
        'Disjoncteur + DDR',
        'Interrupteur + DDR',
      ];

      for (final type in validTypes) {
        expect(
          EssaiDeclenchementHelper.isDdrApplicable(type),
          isTrue,
          reason: 'Le type "$type" doit être reconnu comme différentiel et autoriser la saisie du DDR',
        );
      }
    });

    test('Bloque le DDR pour les dispositifs non-différentiels', () {
      final nonDdrTypes = [
        'Disjoncteur',
        'Disjoncteur magnéto-thermique',
        'Disjoncteur magnétique',
        'Fusible',
        'Sectionneur',
        'Interrupteur',
        'Contacteur',
        'Sans protection',
        '',
        '   ',
        null,
      ];

      for (final type in nonDdrTypes) {
        expect(
          EssaiDeclenchementHelper.isDdrApplicable(type),
          isFalse,
          reason: 'Le type "$type" NE doit PAS autoriser la saisie du DDR',
        );
      }
    });

    test('Préservation des données historiques sans perte de valeur DDR', () {
      // Une ancienne mission avait enregistré un DDR sur un disjoncteur classique
      final dep = DepartEquipement(
        id: 'dep_legacy_test',
        identification: 'Départ Machines Atelier',
        typeProtection: 'Disjoncteur magnéto-thermique',
        calibre: '63',
        ddr: '300', // valeur historique saisie antérieurement
      );

      expect(dep.ddr, equals('300'), reason: 'La valeur historique du DDR doit être préservée intacte dans le modèle');
      expect(EssaiDeclenchementHelper.isDdrApplicable(dep.typeProtection), isFalse,
          reason: 'L\'interface doit griser/verrouiller le champ sans écraser la donnée persistée');
    });

    test('CoffretArmoire expose correctement les listes effectives pour l\'onglet Départs & Circuits', () {
      final coffret = CoffretArmoire(
        nom: 'TGBT PRINCIPAL',
        type: 'TGBT',
        qrCode: 'qr_test',
        departures: [
          DepartEquipement(
            id: 'dep_1',
            identification: 'Départ Éclairage',
            typeProtection: 'Disjoncteur différentiel',
            calibre: '16',
            ddr: '30',
          ),
          DepartEquipement(
            id: 'dep_2',
            identification: 'Départ TGBT Secondaire',
            typeProtection: 'Disjoncteur',
            calibre: '125',
          ),
        ],
        terminalCircuits: [
          CircuitTerminalEquipement(
            id: 'ct_1',
            identification: 'Prises RDC',
            typeProtection: 'Disjoncteur différentiel',
            calibre: '20',
            ddr: '30',
          ),
        ],
      );

      expect(coffret.effectiveDepartures.length, equals(2));
      expect(coffret.effectiveTerminalCircuits.length, equals(1));
      expect(coffret.effectiveDepartures.length + coffret.effectiveTerminalCircuits.length, equals(3));
    });
  });
}
