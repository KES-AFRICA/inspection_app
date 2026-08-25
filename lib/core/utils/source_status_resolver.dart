import 'package:flutter/foundation.dart';

/// Centralized status resolver for equipment power supply sources.
///
/// Rules:
/// - If [typeProtection] is null, empty, or an explicit none option (e.g. "-Aucun-", "Aucun", "-"),
///   the source status is 'Inconnue'.
/// - If [typeProtection] is a valid recognized protection type, the source status is 'Connue'.
/// - Unrecognized historical or corrupt strings default to 'Inconnue'.
abstract class SourceStatusResolver {
  static const String statusConnue = 'Connue';
  static const String statusInconnue = 'Inconnue';

  /// Official recognized protection types
  static const Set<String> _validProtectionTypes = {
    'disjoncteur',
    'sectionneur',
    'interrupteur',
    'interrupteur sectionneur',
    'interrupteur differentiel',
    'interrupteur différentiel',
    'disjoncteur differentiel',
    'disjoncteur différentiel',
    'sectionneur porte-fusible',
    'sectionneur porte fusible',
    'coupe-circuit(porte-fusible)',
    'coupe circuit(porte fusible)',
    'coupe-circuit',
    'coupe circuit',
    'fusible',
    'rg',
    'tgbt',
    'transformateur',
  };

  /// Explicit "none" / empty options
  static const Set<String> _noneOptions = {
    '',
    '-',
    'none',
    'aucun',
    '-aucun-',
    '- aucun -',
    'n/a',
    'non répertorié',
    'non repertorie',
    'non renseigné',
    'non renseigne',
    'inconnu',
    'inconnue',
  };

  /// Resolves the source status ("Connue" vs "Inconnue") based on [typeProtection].
  static String resolve(String? typeProtection) {
    if (typeProtection == null) return statusInconnue;

    final trimmed = typeProtection.trim();
    if (trimmed.isEmpty) return statusInconnue;

    final normalized = _normalize(trimmed);
    if (_noneOptions.contains(normalized)) {
      return statusInconnue;
    }

    // Check against official valid protection types
    if (_validProtectionTypes.contains(normalized)) {
      return statusConnue;
    }

    // Check if the normalized string contains any core protection keyword
    if (normalized.contains('disjoncteur') ||
        normalized.contains('sectionneur') ||
        normalized.contains('interrupteur') ||
        normalized.contains('fusible') ||
        normalized.contains('coupe-circuit') ||
        normalized.contains('coupe circuit')) {
      return statusConnue;
    }

    // Any unrecognized / invalid historical string defaults to 'Inconnue'
    return statusInconnue;
  }

  /// Helper returning true if source status is 'Connue'.
  static bool isKnown(String? typeProtection) =>
      resolve(typeProtection) == statusConnue;

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
