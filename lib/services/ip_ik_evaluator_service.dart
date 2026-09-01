import 'package:flutter/foundation.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/classement_locaux.dart';
import 'package:inspec_app/services/hive_service.dart';

class IpIkEvaluationResult {
  final String conformite; // 'oui' ou 'non'
  final String? observation;
  final String? repereIpIkFormatted;

  const IpIkEvaluationResult({
    required this.conformite,
    this.observation,
    this.repereIpIkFormatted,
  });
}

class ParsedIpIk {
  final String? ip; // ex: "IP55"
  final String? ik; // ex: "IK08"

  const ParsedIpIk({this.ip, this.ik});

  static ParsedIpIk parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const ParsedIpIk(ip: null, ik: null);
    }
    final s = raw.trim().toUpperCase();

    String? ipVal;
    String? ikVal;

    final ipMatch = RegExp(r'IP\s*([0-9]{2})').firstMatch(s);
    if (ipMatch != null) {
      ipVal = 'IP${ipMatch.group(1)}';
    }

    final ikMatch = RegExp(r'IK\s*([0-9]{2})').firstMatch(s);
    if (ikMatch != null) {
      ikVal = 'IK${ikMatch.group(1)}';
    }

    return ParsedIpIk(ip: ipVal, ik: ikVal);
  }

  bool get hasIpOrIk => ip != null || ik != null;

  @override
  String toString() {
    if (ip != null && ik != null) return '$ip / $ik';
    if (ip != null) return ip!;
    if (ik != null) return ik!;
    return '';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedIpIk &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          ik == other.ik;

  @override
  int get hashCode => ip.hashCode ^ ik.hashCode;
}

class IpIkEvaluatorService {
  /// Titres officiels des points de vérification IP/IK
  static const String coffretPointTitle =
      "Compatibilité du degré IP/IK avec l'environnement d'installation";
  static const String inverseurPointTitle =
      "Protection IP/IK adaptée au local d'installation";

  static bool isIpIkPoint(String title) {
    final t = title.trim();
    return t == coffretPointTitle ||
        t == inverseurPointTitle ||
        t.toLowerCase().contains("compatibilité du degré ip/ik") ||
        t.toLowerCase().contains("protection ip/ik adaptée");
  }

  /// Évalue automatiquement le degré IP/IK d'un équipement par rapport à son repère
  static IpIkEvaluationResult evaluate({
    required CoffretArmoire coffret,
    required String missionId,
    String? parentName,
  }) {
    // CAS A — L'équipement n'a pas d'indice IP/IK (vide, nul ou sans IP/IK exploitable)
    final equipParsed = ParsedIpIk.parse(coffret.indiceIpIk);
    if (!equipParsed.hasIpOrIk) {
      return const IpIkEvaluationResult(
        conformite: 'non',
        observation: "Absence de l'indice ip/ik",
      );
    }

    // CAS B & D — Recherche du repère et de son classement
    String? targetLocation = parentName;

    // Si parentName n'est pas fourni, le rechercher dans l'audit de la mission
    if (targetLocation == null || targetLocation.trim().isEmpty) {
      targetLocation = _findLocationForCoffret(coffret, missionId);
    }

    if (targetLocation == null || targetLocation.trim().isEmpty) {
      return const IpIkEvaluationResult(
        conformite: 'non',
        observation: "Absence d'indice ip/ik du repère",
      );
    }

    final ClassementEmplacement? emplacement =
        HiveService.getEmplacementByNom(missionId, targetLocation);

    if (emplacement == null) {
      return const IpIkEvaluationResult(
        conformite: 'non',
        observation: "Absence d'indice ip/ik du repère",
      );
    }

    final String? repereIpRaw = emplacement.ipEffective;
    final String? repereIkRaw = emplacement.ikEffective;

    final repereParsed = ParsedIpIk.parse(
      '${repereIpRaw ?? ''} ${repereIkRaw ?? ''}',
    );

    if (!repereParsed.hasIpOrIk) {
      return const IpIkEvaluationResult(
        conformite: 'non',
        observation: "Absence d'indice ip/ik du repère",
      );
    }

    final repereFormatted = repereParsed.toString();

    // CAS C1 — Présent + identique
    if (equipParsed == repereParsed) {
      return IpIkEvaluationResult(
        conformite: 'oui',
        observation: null,
        repereIpIkFormatted: repereFormatted,
      );
    }

    // CAS C2 — Présent + différent
    return IpIkEvaluationResult(
      conformite: 'non',
      observation: "Indice ip/ik différent de l'indice du repère",
      repereIpIkFormatted: repereFormatted,
    );
  }

  /// Retrouve le nom de l'emplacement (Local ou Zone) où est situé le coffret
  static String? _findLocationForCoffret(CoffretArmoire coffret, String missionId) {
    try {
      final audit = HiveService.getAuditInstallationsByMissionId(missionId);
      if (audit == null) return null;

      final eqId = coffret.equipmentId;

      // 1. Chercher dans les locaux MT direct
      for (final local in audit.moyenneTensionLocaux) {
        if (local.coffrets.any((c) => c.equipmentId == eqId || c.nom == coffret.nom)) {
          return local.nom;
        }
      }

      // 2. Chercher dans les zones MT
      for (final zone in audit.moyenneTensionZones) {
        if (zone.coffrets.any((c) => c.equipmentId == eqId || c.nom == coffret.nom)) {
          return zone.nom;
        }
        for (final local in zone.locaux) {
          if (local.coffrets.any((c) => c.equipmentId == eqId || c.nom == coffret.nom)) {
            return local.nom;
          }
        }
      }

      // 3. Chercher dans les zones BT
      for (final zone in audit.basseTensionZones) {
        if (zone.coffretsDirects.any((c) => c.equipmentId == eqId || c.nom == coffret.nom)) {
          return zone.nom;
        }
        for (final local in zone.locaux) {
          if (local.coffrets.any((c) => c.equipmentId == eqId || c.nom == coffret.nom)) {
            return local.nom;
          }
        }
      }

      // Fallback sur le champ repere du coffret s'il existe
      if (coffret.repere != null && coffret.repere!.trim().isNotEmpty) {
        return coffret.repere!.trim();
      }

      return null;
    } catch (e) {
      if (kDebugMode) print('❌ Erreur _findLocationForCoffret: $e');
      return null;
    }
  }
}
