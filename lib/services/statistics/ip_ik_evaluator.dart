// lib/services/statistics/ip_ik_evaluator.dart

/// Statut d'adéquation de l'indice IP/IK d'un équipement par rapport à son repère (local ou zone).
enum IpIkAdequationStatus {
  /// L'indice observé est présent, l'indice requis est présent, et ils correspondent.
  adequat,

  /// L'indice observé est présent, l'indice requis est présent, mais ils diffèrent.
  presentDifferent,

  /// L'indice observé de l'équipement est absent / non renseigné.
  absent,

  /// L'indice requis du local/zone est absent (impossible d'évaluer la conformité).
  nonEvaluable,
}

/// Paire normalisée (IP, IK).
class IpIkPair {
  final String? ip;
  final String? ik;

  const IpIkPair({this.ip, this.ik});

  bool get isEmpty => (ip == null || ip!.isEmpty) && (ik == null || ik!.isEmpty);
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() {
    if (ip != null && ik != null) return '$ip / $ik';
    if (ip != null) return ip!;
    if (ik != null) return ik!;
    return 'Non renseigné';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! IpIkPair) return false;
    return other.ip == ip && other.ik == ik;
  }

  @override
  int get hashCode => Object.hash(ip, ik);
}

/// Moteur de normalisation et d'évaluation comparative des indices IP et IK.
///
/// Respecte strictement les normes NF EN 60529 (IP) et NF EN 62262 (IK) :
/// - Gère la tolérance aux variantes de format (espaces, minuscules/majuscules, séparateurs).
/// - Ne fusionne jamais des valeurs physiques distinctes (ex: IP55 != IP44).
class IpIkEvaluator {
  IpIkEvaluator._();

  static final RegExp _ipRegex = RegExp(r'IP\s*([0-9]{2})', caseSensitive: false);
  static final RegExp _ikRegex = RegExp(r'IK\s*([0-9]{2})', caseSensitive: false);

  /// Vérifie si une chaîne brute exprime une absence d'indice.
  static bool isAbsent(String? raw) {
    if (raw == null) return true;
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty ||
        trimmed == '-' ||
        trimmed == '/' ||
        trimmed == 'n/a' ||
        trimmed == 'na' ||
        trimmed == 'aucun' ||
        trimmed == 'sans' ||
        trimmed == 'non' ||
        trimmed == 'non renseigné' ||
        trimmed == 'inconnu' ||
        trimmed.contains('absent') ||
        trimmed.contains('non défini')) {
      return true;
    }
    return false;
  }

  /// Extrait une paire (IP, IK) normalisée depuis une chaîne de caractères libre.
  ///
  /// Exemples :
  /// - "IP55 / IK08" -> IpIkPair(ip: "IP55", ik: "IK08")
  /// - "ip 55 - ik 08" -> IpIkPair(ip: "IP55", ik: "IK08")
  /// - "IP20" -> IpIkPair(ip: "IP20", ik: null)
  /// - "IK 02" -> IpIkPair(ip: null, ik: "IK02")
  static IpIkPair parse(String? raw) {
    if (isAbsent(raw)) {
      return const IpIkPair();
    }

    String? ip;
    String? ik;

    final ipMatch = _ipRegex.firstMatch(raw!);
    if (ipMatch != null) {
      ip = 'IP${ipMatch.group(1)}';
    }

    final ikMatch = _ikRegex.firstMatch(raw);
    if (ikMatch != null) {
      ik = 'IK${ikMatch.group(1)}';
    }

    return IpIkPair(ip: ip, ik: ik);
  }

  /// Combine un indice IP requis et un indice IK requis en une paire normalisée.
  static IpIkPair combineRequired(String? reqIp, String? reqIk) {
    final parsedIp = parse(reqIp);
    final parsedIk = parse(reqIk);

    return IpIkPair(
      ip: parsedIp.ip ?? (isAbsent(reqIp) ? null : reqIp?.trim().toUpperCase()),
      ik: parsedIk.ik ?? (isAbsent(reqIk) ? null : reqIk?.trim().toUpperCase()),
    );
  }

  /// Évalue l'adéquation d'un équipement par rapport aux exigences du local ou de la zone.
  static IpIkAdequationStatus evaluate({
    required String? reqIp,
    required String? reqIk,
    required String? obsRaw,
  }) {
    // 1. Détection de l'absence de l'indice requis du repère (local ou zone)
    final requiredPair = combineRequired(reqIp, reqIk);
    if (requiredPair.isEmpty) {
      return IpIkAdequationStatus.nonEvaluable;
    }

    // 2. Détection de l'absence de l'indice observé sur l'équipement
    if (isAbsent(obsRaw)) {
      return IpIkAdequationStatus.absent;
    }

    // 3. Extraction et comparaison des indices observés
    final observedPair = parse(obsRaw);
    if (observedPair.isEmpty) {
      // Si la chaîne n'est pas vide mais ne contient aucun token IP ou IK valide
      return IpIkAdequationStatus.absent;
    }

    // Si le requis spécifie un IP, l'observé doit avoir le même IP
    if (requiredPair.ip != null) {
      if (observedPair.ip == null || observedPair.ip != requiredPair.ip) {
        return IpIkAdequationStatus.presentDifferent;
      }
    }

    // Si le requis spécifie un IK, l'observé doit avoir le même IK
    if (requiredPair.ik != null) {
      if (observedPair.ik == null || observedPair.ik != requiredPair.ik) {
        return IpIkAdequationStatus.presentDifferent;
      }
    }

    return IpIkAdequationStatus.adequat;
  }
}
