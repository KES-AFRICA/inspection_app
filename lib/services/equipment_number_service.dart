import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/audit_installations_electriques.dart';

/// Service centralisé responsable de la numérotation automatique,
/// déterministe et immuable des équipements de la mission d'inspection.
class EquipmentNumberService {
  static const String _auditBox = 'audit_installations_electriques';
  static const String _coffretDraftsBox = 'coffret_drafts';

  /// Parcourt tous les équipements d'un audit pour extraire la liste à plat de tous les [CoffretArmoire].
  static List<CoffretArmoire> _extractAllCoffretsFromAudit(AuditInstallationsElectriques audit) {
    final list = <CoffretArmoire>[];

    // Locaux MT directs
    for (final local in audit.moyenneTensionLocaux) {
      list.addAll(local.coffrets);
    }
    // Zones MT → coffrets directs + coffrets dans les locaux
    for (final zone in audit.moyenneTensionZones) {
      list.addAll(zone.coffrets);
      for (final local in zone.locaux) {
        list.addAll(local.coffrets);
      }
    }
    // Zones BT → coffrets directs + coffrets dans les locaux
    for (final zone in audit.basseTensionZones) {
      list.addAll(zone.coffretsDirects);
      for (final local in zone.locaux) {
        list.addAll(local.coffrets);
      }
    }

    return list;
  }

  /// Parcourt les brouillons ouverts pour la mission spécifiée.
  static List<CoffretArmoire> _extractAllCoffretsFromDrafts(String missionId) {
    final list = <CoffretArmoire>[];
    try {
      if (Hive.isBoxOpen(_coffretDraftsBox)) {
        final box = Hive.box(_coffretDraftsBox);
        for (final val in box.values) {
          if (val is Map && val['missionId'] == missionId && val['coffret'] is CoffretArmoire) {
            list.add(val['coffret'] as CoffretArmoire);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error reading drafts in EquipmentNumberService: $e');
      }
    }
    return list;
  }

  /// Extrait l'entier numérique pur de la chaîne [numeroEquipement].
  static int? parseNumericSequence(String? numeroStr) {
    if (numeroStr == null) return null;
    final str = numeroStr.trim();
    if (str.isEmpty) return null;
    final match = RegExp(r'\d+').firstMatch(str);
    if (match != null) {
      return int.tryParse(match.group(0)!);
    }
    return null;
  }

  /// Calcule le prochain numéro d'équipement disponible dans la séquence monotone de la mission.
  static int getNextEquipmentNumber(String missionId, {AuditInstallationsElectriques? audit}) {
    AuditInstallationsElectriques? targetAudit = audit;
    if (targetAudit == null) {
      try {
        if (Hive.isBoxOpen(_auditBox)) {
          targetAudit = Hive.box<AuditInstallationsElectriques>(_auditBox)
              .values
              .cast<AuditInstallationsElectriques?>()
              .firstWhere(
                (a) => a?.missionId == missionId,
                orElse: () => null,
              );
        }
      } catch (_) {}
    }

    int maxNum = 0;
    bool foundAny = false;

    void processCoffret(CoffretArmoire c) {
      final numVal = parseNumericSequence(c.numeroEquipement);
      if (numVal != null) {
        foundAny = true;
        if (numVal > maxNum) {
          maxNum = numVal;
        }
      }
    }

    if (targetAudit != null) {
      for (final c in _extractAllCoffretsFromAudit(targetAudit)) {
        processCoffret(c);
      }
    }

    for (final c in _extractAllCoffretsFromDrafts(missionId)) {
      processCoffret(c);
    }

    return foundAny ? maxNum + 1 : 1;
  }

  /// Garantit l'attribution immuable de l'ID technique (`equipmentId`) et du repère métier (`equipmentNumber`).
  ///
  /// Si [coffret.numeroEquipement] est null ou vide, réserve et attribue de façon permanente le prochain numéro.
  static void ensureEquipmentIdentityAndNumber(String missionId, CoffretArmoire coffret, {AuditInstallationsElectriques? audit}) {
    // 1. Garantir l'ID technique immuable
    final _ = coffret.equipmentId;

    // 2. Si le numéro métier est déjà présent et valide, ne pas y toucher
    if (coffret.numeroEquipement != null && coffret.numeroEquipement!.trim().isNotEmpty) {
      return;
    }

    // 3. Attribuer le prochain numéro dans la séquence monotone
    final nextNum = getNextEquipmentNumber(missionId, audit: audit);
    coffret.numeroEquipement = nextNum.toString();
  }

  /// Effectue un audit et un assainissement non destructif d'une mission.
  ///
  /// - Attribue un [equipmentId] immuable aux équipements legacy qui en manquent.
  /// - Conserve intacts tous les numéros métier uniques et valides.
  /// - Résout les numéros manquants ou dupliqués en réattribuant intelligemment
  ///   les numéros suivants dans la séquence, sans altérer aucune autre donnée métier.
  static AuditNumberReport auditAndFixMissionNumbers(AuditInstallationsElectriques audit) {
    final allCoffrets = _extractAllCoffretsFromAudit(audit);
    int missingIdsFixed = 0;
    int missingNumbersFixed = 0;
    int duplicatesFixed = 0;

    final usedNumbers = <int>{};
    final coffretsToAssign = <CoffretArmoire>[];

    // 1. Vérification des IDs et première passe sur les numéros
    for (final coffret in allCoffrets) {
      if (coffret.id == null || coffret.id!.trim().isEmpty) {
        coffret.equipmentId; // Auto-génération stable
        missingIdsFixed++;
      }

      final numVal = parseNumericSequence(coffret.numeroEquipement);
      if (numVal != null) {
        if (!usedNumbers.contains(numVal)) {
          usedNumbers.add(numVal);
        } else {
          // Doublon détecté ! Le premier conserve son numéro, le suivant sera réattribué.
          coffretsToAssign.add(coffret);
          duplicatesFixed++;
        }
      } else {
        // Numéro absent ou non numérique
        coffretsToAssign.add(coffret);
        missingNumbersFixed++;
      }
    }

    // 2. Attribution séquentielle intelligente des numéros manquants/dupliqués
    int currentCandidate = 1;
    for (final coffret in coffretsToAssign) {
      while (usedNumbers.contains(currentCandidate)) {
        currentCandidate++;
      }
      coffret.numeroEquipement = currentCandidate.toString();
      usedNumbers.add(currentCandidate);
    }

    if (kDebugMode && (missingIdsFixed > 0 || missingNumbersFixed > 0 || duplicatesFixed > 0)) {
      print('📊 Audit Numérotation Mission ${audit.missionId} : '
          '$missingIdsFixed IDs corrigés, '
          '$missingNumbersFixed numéros attribués, '
          '$duplicatesFixed doublons résolus.');
    }

    return AuditNumberReport(
      totalCoffrets: allCoffrets.length,
      missingIdsFixed: missingIdsFixed,
      missingNumbersFixed: missingNumbersFixed,
      duplicatesFixed: duplicatesFixed,
    );
  }
}

/// Rapport diagnostic de l'audit de numérotation d'une mission.
class AuditNumberReport {
  final int totalCoffrets;
  final int missingIdsFixed;
  final int missingNumbersFixed;
  final int duplicatesFixed;

  const AuditNumberReport({
    required this.totalCoffrets,
    required this.missingIdsFixed,
    required this.missingNumbersFixed,
    required this.duplicatesFixed,
  });

  bool get hasChanges => missingIdsFixed > 0 || missingNumbersFixed > 0 || duplicatesFixed > 0;
}
