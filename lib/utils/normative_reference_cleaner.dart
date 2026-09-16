// lib/utils/normative_reference_cleaner.dart

/// Utilitaire de nettoyage et standardisation des références normatives.
/// Permet de préserver les références multiples légitimes séparées par des point-virgules
/// tout en supprimant radicalement les commentaires, notes explicatives ou mentions parasites
/// (ex. ", selon la mesure de protection retenue", "(pouvoir de coupure...)", "et prescriptions du fabricant").
class NormativeReferenceCleaner {
  /// Patterns de textes explicatifs purs à exclure (parties entières)
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

  /// Parentheses explicatives à nettoyer au sein d'une référence
  static final List<RegExp> _parenthesisToRemove = [
    RegExp(r'\s*\([^)]*[a-zà-ÿ]{2,}[^)]*\)', caseSensitive: false),
  ];

  /// Clauses de commentaires et mentions textuelles à supprimer
  static final List<RegExp> _inlineCommentsToRemove = [
    // Mentions "selon ..." (ex: ", selon la mesure de protection retenue")
    RegExp(r',?\s*\bselon\s+[^;]+', caseSensitive: false),
    // Mentions "pour les ..." (ex: ", pour les influences externes")
    RegExp(r',?\s*\bpour\s+(?:les|l\x27|la|le|des)\s+[^;]+', caseSensitive: false),
    // Mentions "en fonction de ..."
    RegExp(r',?\s*\ben fonction\s+[^;]+', caseSensitive: false),
    // Mentions "sous réserve de ..."
    RegExp(r',?\s*\bsous réserve\s+[^;]+', caseSensitive: false),
    // Mentions "et prescriptions du fabricant"
    RegExp(r',?\s*\bet prescriptions?\b[^;]*', caseSensitive: false),
    // Mentions "prescriptions du fabricant"
    RegExp(r',?\s*\bprescriptions?\s+du\s+fabricant\b[^;]*', caseSensitive: false),
    // Mentions "suivant ..."
    RegExp(r',?\s*\bsuivant\s+(?:les?|la|le|l\x27)\s+[^;]+', caseSensitive: false),
    // Mentions "conformément à ..."
    RegExp(r',?\s*\bconformément\s+[aà]\s+[^;]+', caseSensitive: false),
    // Mentions "si présence de..."
    RegExp(r',?\s*\bsi\s+présence\b[^;]+', caseSensitive: false),
    // Mentions "règles de distance..."
    RegExp(r',?\s*\brègles?\s+de\s+distance\b[^;]+', caseSensitive: false),
    // Mentions "pouvoir de coupure..."
    RegExp(r',?\s*\bpouvoir\s+de\s+coupure\b[^;]+', caseSensitive: false),
  ];

  /// Nettoie une chaîne brute de référence(s) normative(s).
  static String clean(String? raw) {
    if (raw == null) return '-';
    var trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '-') return '-';

    // Remplacer les symboles de paragraphe '§' par 'art '
    String standardized = trimmed.replaceAll(RegExp(r'§\s*'), 'art ');

    // Normaliser "Norme NF C" en "NF C" ou "Norme NF C 13-100 art 412" en "NF C 13-100 – art 412"
    standardized = standardized.replaceAll(RegExp(r'^\s*normes?\s+', caseSensitive: false), '');
    standardized = standardized.replaceAllMapped(
      RegExp(r'(\bNF\s+C\s+[0-9\-\:]+)\s+art\s+', caseSensitive: false),
      (m) => '${m[1]} – art ',
    );

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
      // Si une partie ne contient aucun chiffre ni mention de norme/art/décret, c'est du commentaire
      if (!isExplanatory &&
          !RegExp(r'\d').hasMatch(item) &&
          !RegExp(r'\b(?:NF|EN|CEI|ISO|UTE|art|décret|arrêté|code)\b', caseSensitive: false).hasMatch(item)) {
        isExplanatory = true;
      }
      if (isExplanatory) continue;

      // Nettoyer les parenthèses explicatives parasites (contenant des mots alphabétiques)
      for (final pRemove in _parenthesisToRemove) {
        item = item.replaceAll(pRemove, '').trim();
      }

      // Nettoyer les commentaires textuels in-line
      for (final commentRemove in _inlineCommentsToRemove) {
        item = item.replaceAll(commentRemove, '').trim();
      }

      // Supprimer toute queue de commentaire après une virgule qui contient du texte descriptif
      // (ex: ", selon la mesure de protection retenue", ", avec protection différentielle", etc.)
      item = item.replaceAllMapped(
        RegExp(
          r'(,\s*)(?!(?:art|§|partie|annexe|tableau|al\.?|tab\.?|\d)\b)[a-zA-ZÀ-ÿ\s\x27\u2019\(\)\-–]+$',
          caseSensitive: false,
        ),
        (m) => '',
      );

      // Nettoyer les ponctuations orphelines en fin (virgules, tirets, etc.)
      item = item.replaceAll(RegExp(r'[,;:\-\s]+$'), '').trim();
      // Nettoyer les espaces multiples
      item = item.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

      if (item.isNotEmpty && item != '-') {
        cleanedParts.add(item);
      }
    }

    if (cleanedParts.isEmpty) {
      return '-';
    }

    return cleanedParts.join(' ; ');
  }
}
