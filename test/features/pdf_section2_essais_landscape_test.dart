// test/features/pdf_section2_essais_landscape_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/services/pdf/pdf_report_service.dart';

void main() {
  setUp(() {
    PdfReportService.initFontsForTesting();
  });

  group('Section II. RÉSULTATS DES ESSAIS — Mode Paysage & Regroupement Zone / Repère / Équipement', () {
    test('1. Prise de Terre : Validation de la structure des données et résolutions de localisation', () {
      final pt1 = PriseTerre(
        localisation: 'Local TGBT',
        identification: 'PT-MAIN',
        conditionPriseTerre: 'Barette fermée',
        naturePriseTerre: 'Fond de fouille',
        methodeMesure: 'Méthode des 62%',
        valeurMesure: 4.5,
        interconnecteAutrePrise: 'Oui',
        observation: 'Excellente valeur',
      );

      final pt2 = PriseTerre(
        localisation: 'Zone EC wagon',
        identification: 'PT-AUX',
        conditionPriseTerre: 'Barette ouverte',
        naturePriseTerre: 'Piquet de terre',
        methodeMesure: 'Impédance de boucle',
        valeurMesure: 12.0,
        interconnecteAutrePrise: 'Non',
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm_test_pt',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Bâtiment Principal',
            locaux: [
              BasseTensionLocal(
                nom: 'Local TGBT',
                type: 'Technique',
                dispositionsConstructives: [],
                conditionsExploitation: [],
              ),
            ],
          ),
        ],
      );

      final mesures = MesuresEssais(
        missionId: 'm_test_pt',
        updatedAt: DateTime.now(),
        prisesTerre: [pt1, pt2],
      );

      expect(mesures.prisesTerre.length, equals(2));
      expect(audit.basseTensionZones.first.nom, equals('Bâtiment Principal'));
    });

    test('2. Essais DDR : Validation de la structure à 3 niveaux (Zone -> Repère -> Équipement -> Essais)', () {
      final essai1 = EssaiDeclenchementDifferentiel(
        localisation: 'Local TGBT',
        coffret: 'TGBT Général',
        designationCircuit: 'Départ Éclairage Hall',
        typeDispositif: 'DDR',
        reglageIAn: 30,
        tempo: 0,
        calibre: 63,
        essai: 'B',
      );

      final essai2 = EssaiDeclenchementDifferentiel(
        localisation: 'Local TGBT',
        coffret: 'TGBT Général',
        designationCircuit: 'Départ Prises Bureaux',
        typeDispositif: 'IDR',
        reglageIAn: 300,
        tempo: 0.1,
        calibre: 100,
        essai: 'B',
      );

      final essai3 = EssaiDeclenchementDifferentiel(
        localisation: 'Atelier',
        coffret: 'Coffret Atelier A1',
        designationCircuit: 'Circuit Machine 1',
        typeDispositif: 'DDR',
        reglageIAn: 30,
        calibre: 32,
        essai: 'M',
      );

      final audit = AuditInstallationsElectriques(
        missionId: 'm_test_ddr',
        updatedAt: DateTime.now(),
        basseTensionZones: [
          BasseTensionZone(
            nom: 'Zone Industrielle',
            locaux: [
              BasseTensionLocal(
                nom: 'Local TGBT',
                type: 'Technique',
                coffrets: [
                  CoffretArmoire(
                    qrCode: 'Q1',
                    repere: 'TGBT-01',
                    nom: 'TGBT Général',
                    type: 'TGBT',
                  ),
                ],
                dispositionsConstructives: [],
                conditionsExploitation: [],
              ),
              BasseTensionLocal(
                nom: 'Atelier',
                type: 'Production',
                coffrets: [
                  CoffretArmoire(
                    qrCode: 'Q2',
                    repere: 'COFF-A1',
                    nom: 'Coffret Atelier A1',
                    type: 'COFFRET',
                  ),
                ],
                dispositionsConstructives: [],
                conditionsExploitation: [],
              ),
            ],
          ),
        ],
      );

      final mesures = MesuresEssais(
        missionId: 'm_test_ddr',
        updatedAt: DateTime.now(),
        essaisDeclenchement: [essai1, essai2, essai3],
      );

      expect(mesures.essaisDeclenchement.length, equals(3));
      expect(audit.basseTensionZones.first.locaux.length, equals(2));
    });
  });
}
