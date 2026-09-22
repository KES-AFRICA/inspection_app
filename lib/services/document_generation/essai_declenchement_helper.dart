// lib/services/document_generation/essai_declenchement_helper.dart

import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/mesures_essais.dart';

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

  /// Indique si le type de protection autorise la saisie d'un DDR (réservé aux différentiels)
  static bool isDdrApplicable(String? typeProtection) {
    if (typeProtection == null || typeProtection.trim().isEmpty) return false;
    final norm = typeProtection.trim().toLowerCase();
    return norm.contains('différentiel') ||
        norm.contains('differentiel') ||
        norm.contains('ddr') ||
        norm.contains('idr') ||
        norm == 'rd' ||
        norm.contains('relais diff');
  }

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
    final isDiff = normType.contains('différentiel') ||
        normType.contains('differentiel') ||
        normType.contains('ddr') ||
        normType.contains('idr') ||
        normType == 'rd' ||
        normType.contains('relais diff');

    if (!isDiff) return false;

    final normDdr = ddr.trim().replaceAll(',', '.');
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

  /// Vérifie si un essai existant correspond au même bloc (protection de tête, sortie inverseur, départ, circuit)
  static bool isSameBlock({
    required EssaiDeclenchementDifferentiel essai,
    String? targetId,
    String? targetElementId,
    String? equipementId,
    String? precision,
    String? circuitName,
  }) {
    // 1. Même id d'enregistrement dans la base
    if (targetId != null && targetId.trim().isNotEmpty && essai.id != null && essai.id == targetId) {
      return true;
    }

    // 2. Même identifiant d'élément unique (dep.id, ct.id, sortie_id, etc.)
    if (targetElementId != null &&
        targetElementId.trim().isNotEmpty &&
        essai.elementId != null &&
        essai.elementId!.trim().isNotEmpty &&
        essai.elementId == targetElementId) {
      return true;
    }

    // 3. Correspondance fonctionnelle par équipement + précision
    final eEquipId = essai.equipementId?.trim();
    final tEquipId = equipementId?.trim();
    final ePrec = essai.precision?.trim().toLowerCase();
    final tPrec = precision?.trim().toLowerCase();

    if (tEquipId != null && tEquipId.isNotEmpty && eEquipId != null && eEquipId.isNotEmpty && eEquipId == tEquipId) {
      if (tPrec != null && tPrec.isNotEmpty && ePrec != null && ePrec == tPrec) {
        // Pour la protection de tête : 1 seul bloc possible par équipement
        if (tPrec == precisionProtectionTete.toLowerCase()) {
          return true;
        }

        // Pour les départs, circuits terminaux ou sorties d'inverseur :
        final tCircuit = circuitName?.trim().toLowerCase();
        final eCircuit = essai.designationCircuit?.trim().toLowerCase();

        if (tCircuit != null && tCircuit.isNotEmpty && eCircuit != null && eCircuit.isNotEmpty) {
          if (tCircuit == eCircuit) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Déduplique la liste des essais pour garantir qu'un bloc n'a qu'un seul essai
  static void deduplicateEssais(List<EssaiDeclenchementDifferentiel> essais) {
    final indicesToRemove = <int>{};

    for (int i = 0; i < essais.length; i++) {
      if (indicesToRemove.contains(i)) continue;
      for (int j = i + 1; j < essais.length; j++) {
        if (indicesToRemove.contains(j)) continue;
        final a = essais[i];
        final b = essais[j];
        if (isSameBlock(
          essai: b,
          targetId: a.id,
          targetElementId: a.elementId,
          equipementId: a.equipementId,
          precision: a.precision,
          circuitName: a.designationCircuit,
        )) {
          // Doublon détecté : on conserve l'essai le plus récemment mis à jour
          final dateA = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          if (dateB.isAfter(dateA)) {
            indicesToRemove.add(i);
            break;
          } else {
            indicesToRemove.add(j);
          }
        }
      }
    }

    if (indicesToRemove.isNotEmpty) {
      final sortedIndices = indicesToRemove.toList()..sort((a, b) => b.compareTo(a));
      for (final idx in sortedIndices) {
        if (idx < essais.length) {
          essais.removeAt(idx);
        }
      }
    }
  }
}
