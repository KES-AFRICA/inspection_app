// lib/utils/normative_reference_cleaner.dart

/// Utilitaire de nettoyage et standardisation des références normatives.
/// Permet de préserver les références multiples légitimes séparées par des point-virgules
/// tout en supprimant les commentaires, notes explicatives ou mentions parasites
/// (ex. "(complémentaire, non fournie)", "exigences détaillées...", "moyens d'extinction...").
class NormativeReferenceCleaner {
  /// Patterns de textes explicatifs purs à exclure
  static final List<RegExp> _explanatoryPatterns = [
    RegExp(r'^\s*les exigences détaillées', caseSensitive: false),
    RegExp(r'^\s*exigences? détaillées?', caseSensitive: false),
    RegExp(r'^\s*exigences? spécifiques?', caseSensitive: false),
    RegExp(r'^\s*moyens? d.extinction', caseSensitive: false),
    RegExp(r'^\s*vérification détaillée', caseSensitive: false),
    RegExp(r'^\s*thermographie non prescrite', caseSensitive: false),
    RegExp(r'^\s*prescriptions? du fabricant', caseSensitive: false),
    RegExp(r'^\s*réglementation applicable', caseSensitive: false),
    RegExp(r'^\s*dispositifs? d.alarme', caseSensitive: false),
    RegExp(r'^\s*à compléter par', caseSensitive: false),
    RegExp(r'^\s*à confirmer sur', caseSensitive: false),
  ];

  /// Parentheses parasites à nettoyer au sein d'une référence
  static final List<RegExp> _parenthesisToRemove = [
    RegExp(r'\s*\([^)]*complémentaire[^)]*\)', caseSensitive: false),
    RegExp(r'\s*\([^)]*non fournie[^)]*\)', caseSensitive: false),
    RegExp(r'\s*\([^)]*aspects accessibilité[^)]*\)', caseSensitive: false),
    RegExp(r'\s*\([^)]*habilitation[^)]*\)', caseSensitive: false),
    RegExp(r'\s*\([^)]*selon la nature[^)]*\)', caseSensitive: false),
    RegExp(r'\s*\([^)]*selon la mesure[^)]*\)', caseSensitive: false),
    RegExp(r'\s*\([^)]*selon puissance[^)]*\)', caseSensitive: false),
  ];

  /// Nettoie une chaîne brute de référence(s) normative(s).
  static String clean(String? raw) {
    if (raw == null) return '-';
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '-') return '-';

    // Remplacer les symboles de paragraphe '§' par 'art '
    String standardized = trimmed.replaceAll(RegExp(r'§\s*'), 'art ');

    // Diviser par ';' pour traiter chaque référence indépendamment
    final parts = standardized.split(';');
    final cleanedParts = <String>[];

    for (var part in parts) {
      String item = part.trim();
      if (item.isEmpty) continue;

      // Vérifier si la partie est une phrase explicative pure
      bool isExplanatory = false;
      for (final exp in _explanatoryPatterns) {
        if (exp.hasMatch(item)) {
          isExplanatory = true;
          break;
        }
      }
      if (isExplanatory) continue;

      // Nettoyer les parenthèses explicatives parasites
      for (final pRemove in _parenthesisToRemove) {
        item = item.replaceAll(pRemove, '').trim();
      }

      // Nettoyer les éventuels tirets orphelins ou espaces multiples en fin
      item = item.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

      if (item.isNotEmpty && item != '-') {
        cleanedParts.add(item);
      }
    }

    if (cleanedParts.isEmpty) {
      // Fallback de sécurité : renvoyer la chaîne d'origine si le nettoyage a tout vidé
      return trimmed.isNotEmpty ? trimmed : '-';
    }

    return cleanedParts.join(' ; ');
  }
}
