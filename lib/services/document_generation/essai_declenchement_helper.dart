// lib/services/document_generation/essai_declenchement_helper.dart

import 'package:inspec_app/models/audit_installations_electriques.dart';

/// Énumération des blocs éligibles à un essai de déclenchement
enum BlocOrigineEssai {
  sortieInverseur,
  protectionTete,
  depart,
  circuit,
}

/// Helper centralisé pour la logique métier des essais de déclenchement
class EssaiDeclenchementHelper {
  // Précisions normatives uniques
  static const String precisionSortieInverseur = 'sortie inverseur';
  static const String precisionProtectionTete = 'protection de tête de départ';
  static const String precisionDepart = 'départ';
  static const String precisionCircuit = 'circuit';

  /// Règle centrale :
  /// Le bouton est visible UNIQUEMENT si :
  /// typeProtection = "Interrupteur différentiel" OU "Disjoncteur différentiel"
  /// ET
  /// DDR renseigné et exploitable (> 0 mA).
  static bool isEligibleForEssai({
    required String? typeProtection,
    required String? ddr,
  }) {
    if (typeProtection == null || ddr == null) return false;

    final normType = typeProtection.trim().toLowerCase();
    final isDiff = normType == 'interrupteur différentiel' ||
        normType == 'interrupteur differentiel' ||
        normType == 'disjoncteur différentiel' ||
        normType == 'disjoncteur differentiel';

    if (!isDiff) return false;

    final normDdr = ddr.trim();
    if (normDdr.isEmpty || normDdr == '-' || normDdr.toLowerCase() == 'aucun') {
      return false;
    }

    final cleanedDigits = normDdr.replaceAll(RegExp(r'[^0-9.]'), '');
    final numVal = double.tryParse(cleanedDigits);
    return numVal != null && numVal > 0;
  }

  /// Retourne la chaîne de précision selon le bloc d'origine (table unique)
  static String getPrecisionForBloc(BlocOrigineEssai bloc) {
    switch (bloc) {
      case BlocOrigineEssai.sortieInverseur:
        return precisionSortieInverseur;
      case BlocOrigineEssai.protectionTete:
        return precisionProtectionTete;
      case BlocOrigineEssai.depart:
        return precisionDepart;
      case BlocOrigineEssai.circuit:
        return precisionCircuit;
    }
  }

  /// Résout la zone et le repère d'un équipement à partir du modèle d'audit
  /// Règle :
  /// Équipement → Local → Zone
  /// Si équipement rattaché directement à une zone : Zone = nom de la zone, Repère = nom de la zone.
  static ({String zone, String repere}) resolveZoneAndRepere({
    required AuditInstallationsElectriques? audit,
    required String parentType,
    required int parentIndex,
    required int? zoneIndex,
    required bool isMoyenneTension,
    String? fallbackRepere,
  }) {
    String zoneName = '';
    String repereName = fallbackRepere?.trim() ?? '';

    if (audit == null) {
      return (zone: zoneName, repere: repereName);
    }

    if (parentType == 'local') {
      if (isMoyenneTension) {
        if (zoneIndex != null && zoneIndex < audit.moyenneTensionZones.length) {
          final z = audit.moyenneTensionZones[zoneIndex];
          zoneName = z.nom.trim();
          if (parentIndex < z.locaux.length) {
            repereName = z.locaux[parentIndex].nom.trim();
          }
        } else if (parentIndex < audit.moyenneTensionLocaux.length) {
          repereName = audit.moyenneTensionLocaux[parentIndex].nom.trim();
        }
      } else {
        if (zoneIndex != null && zoneIndex < audit.basseTensionZones.length) {
          final z = audit.basseTensionZones[zoneIndex];
          zoneName = z.nom.trim();
          if (parentIndex < z.locaux.length) {
            repereName = z.locaux[parentIndex].nom.trim();
          }
        }
      }
    } else if (parentType == 'zone_bt' || parentType == 'zone') {
      if (!isMoyenneTension && parentIndex < audit.basseTensionZones.length) {
        final z = audit.basseTensionZones[parentIndex];
        zoneName = z.nom.trim();
        repereName = zoneName;
      }
    } else if (parentType == 'zone_mt') {
      if (isMoyenneTension && parentIndex < audit.moyenneTensionZones.length) {
        final z = audit.moyenneTensionZones[parentIndex];
        zoneName = z.nom.trim();
        repereName = zoneName;
      }
    }

    if (repereName.isEmpty && zoneName.isNotEmpty) {
      repereName = zoneName;
    }

    return (zone: zoneName, repere: repereName);
  }
}
