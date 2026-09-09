import 'package:flutter_test/flutter_test.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/services/document_generation/essai_declenchement_helper.dart';

void main() {
  group('EssaiDeclenchementHelper Tests', () {
    test('isEligibleForEssai returns true only for differential devices with ddr > 0', () {
      // Differential switches / circuit breakers with valid DDR
      expect(
        EssaiDeclenchementHelper.isEligibleForEssai(
          typeProtection: 'Interrupteur différentiel',
          ddr: '30',
        ),
        isTrue,
      );
      expect(
        EssaiDeclenchementHelper.isEligibleForEssai(
          typeProtection: 'Disjoncteur différentiel',
          ddr: '300',
        ),
        isTrue,
      );
      expect(
        EssaiDeclenchementHelper.isEligibleForEssai(
          typeProtection: 'Disjoncteur différentiel',
          ddr: '500 mA',
        ),
        isTrue,
      );

      // Ineligible types
      expect(
        EssaiDeclenchementHelper.isEligibleForEssai(
          typeProtection: 'Disjoncteur',
          ddr: '300',
        ),
        isFalse,
      );
      expect(
        EssaiDeclenchementHelper.isEligibleForEssai(
          typeProtection: 'Interrupteur',
          ddr: '30',
        ),
        isFalse,
      );
      expect(
        EssaiDeclenchementHelper.isEligibleForEssai(
          typeProtection: 'Sectionneur',
          ddr: '300',
        ),
        isFalse,
      );

      // Ineligible DDR values
      expect(
        EssaiDeclenchementHelper.isEligibleForEssai(
          typeProtection: 'Disjoncteur différentiel',
          ddr: '0',
        ),
        isFalse,
      );
      expect(
        EssaiDeclenchementHelper.isEligibleForEssai(
          typeProtection: 'Disjoncteur différentiel',
          ddr: '-',
        ),
        isFalse,
      );
      expect(
        EssaiDeclenchementHelper.isEligibleForEssai(
          typeProtection: 'Disjoncteur différentiel',
          ddr: '',
        ),
        isFalse,
      );
      expect(
        EssaiDeclenchementHelper.isEligibleForEssai(
          typeProtection: 'Disjoncteur différentiel',
          ddr: null,
        ),
        isFalse,
      );
    });

    test('Precision constants conform to specification', () {
      expect(EssaiDeclenchementHelper.precisionSortieInverseur, 'sortie inverseur');
      expect(EssaiDeclenchementHelper.precisionProtectionTete, 'protection de tête de départ');
      expect(EssaiDeclenchementHelper.precisionDepart, 'départ');
      expect(EssaiDeclenchementHelper.precisionCircuit, 'circuit');
    });

    test('resolveZoneAndRepere resolves location information reliably', () {
      final dummyAudit = AuditInstallationsElectriques.create('mission_1');
      dummyAudit.basseTensionZones.add(
        BasseTensionZone(
          nom: 'Zone Industrielle',
          locaux: [
            BasseTensionLocal(nom: 'Atelier Central', type: 'Local technique'),
          ],
        ),
      );

      // Case 1: local in BT zone
      final r1 = EssaiDeclenchementHelper.resolveZoneAndRepere(
        audit: dummyAudit,
        parentType: 'local',
        parentIndex: 0,
        zoneIndex: 0,
        isMoyenneTension: false,
      );
      expect(r1.zone, 'Zone Industrielle');
      expect(r1.repere, 'Atelier Central');

      // Case 2: direct BT zone
      final r2 = EssaiDeclenchementHelper.resolveZoneAndRepere(
        audit: dummyAudit,
        parentType: 'zone_bt',
        parentIndex: 0,
        zoneIndex: null,
        isMoyenneTension: false,
      );
      expect(r2.zone, 'Zone Industrielle');
      expect(r2.repere, 'Zone Industrielle');

      // Case 3: fallback repere when audit is null
      final r3 = EssaiDeclenchementHelper.resolveZoneAndRepere(
        audit: null,
        parentType: 'local',
        parentIndex: 0,
        zoneIndex: null,
        isMoyenneTension: false,
        fallbackRepere: 'Coffret A',
      );
      expect(r3.zone, '');
      expect(r3.repere, 'Coffret A');
    });
  });

  group('MesuresEssais and Alimentation Model Evolution Tests', () {
    test('EssaiDeclenchementDifferentiel supports new fields and copyWith', () {
      final essai = EssaiDeclenchementDifferentiel(
        localisation: 'Local TGBT',
        elementId: 'dep_123',
        precision: 'Départ',
        equipementId: 'eq_456',
        zone: 'Bâtiment Principal',
        repere: 'Local TGBT',
        coffret: 'TGBT 1',
        typeDispositif: 'Disjoncteur différentiel',
        calibre: 63,
        reglageIAn: 300,
        tempoText: "Réglage d'origine.",
        essai: 'Satisfaisant',
        observation: 'Test effectué avec succès',
      );

      expect(essai.elementId, 'dep_123');
      expect(essai.precision, 'Départ');
      expect(essai.equipementId, 'eq_456');
      expect(essai.zone, 'Bâtiment Principal');
      expect(essai.repere, 'Local TGBT');
      expect(essai.tempoText, "Réglage d'origine.");

      final updated = essai.copyWith(
        essai: 'Non satisfaisant',
        observation: 'Défaut de déclenchement',
      );

      expect(updated.elementId, 'dep_123');
      expect(updated.precision, 'Départ');
      expect(updated.equipementId, 'eq_456');
      expect(updated.zone, 'Bâtiment Principal');
      expect(updated.repere, 'Local TGBT');
      expect(updated.essai, 'Non satisfaisant');
      expect(updated.observation, 'Défaut de déclenchement');
    });

    test('Alimentation model maintains stable identity id', () {
      final alim1 = Alimentation(
        typeProtection: 'Disjoncteur différentiel',
        calibre: '32',
        ddr: '30',
        pdcKA: '10',
        sectionCable: '16 mm²',
      );
      expect(alim1.alimentationId, isNotEmpty);

      final alim2 = alim1.copyWith(calibre: '40');
      expect(alim2.alimentationId, alim1.alimentationId);
    });

    test('PDF table values logic verification', () {
      // Test the precision fallback rule: es.precision ?? es.designationCircuit ?? '-'
      final newEssai = EssaiDeclenchementDifferentiel(
        localisation: 'Local A',
        typeDispositif: 'Disjoncteur différentiel',
        essai: 'Satisfaisant',
        precision: 'Départ',
        designationCircuit: 'Ancien circuit',
        calibre: 16,
      );
      final precision1 = (newEssai.precision != null && newEssai.precision!.trim().isNotEmpty)
          ? newEssai.precision!.trim()
          : (newEssai.designationCircuit != null && newEssai.designationCircuit!.trim().isNotEmpty
              ? newEssai.designationCircuit!.trim()
              : '-');
      expect(precision1, 'Départ');

      // Test vintage essai fallback (no precision field set)
      final vintageEssai = EssaiDeclenchementDifferentiel(
        localisation: 'Local B',
        typeDispositif: 'Disjoncteur différentiel',
        essai: 'Satisfaisant',
        designationCircuit: 'Circuit Prises',
        calibre: 32.5,
      );
      final precision2 = (vintageEssai.precision != null && vintageEssai.precision!.trim().isNotEmpty)
          ? vintageEssai.precision!.trim()
          : (vintageEssai.designationCircuit != null && vintageEssai.designationCircuit!.trim().isNotEmpty
              ? vintageEssai.designationCircuit!.trim()
              : '-');
      expect(precision2, 'Circuit Prises');

      // Test calibre display: numeric only without ' A' suffix
      final calibreDisplay1 = newEssai.calibre != null
          ? '${newEssai.calibre! % 1 == 0 ? newEssai.calibre!.toInt() : newEssai.calibre}'
          : '-';
      expect(calibreDisplay1, '16');

      final calibreDisplay2 = vintageEssai.calibre != null
          ? '${vintageEssai.calibre! % 1 == 0 ? vintageEssai.calibre!.toInt() : vintageEssai.calibre}'
          : '-';
      expect(calibreDisplay2, '32.5');
    });
  });
}
