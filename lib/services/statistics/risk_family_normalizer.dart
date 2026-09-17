/// Normalisateur de libellés pour les familles de risques réelles.
/// Unifie les variations typographiques (apostrophes courbes `’` vs droites `'`,
/// espaces multiples, normalisation des slashes) sans altérer la sémantique
/// métier ni créer de super-familles artificielles.
class RiskFamilyNormalizer {
  static final RegExp _multiSpace = RegExp(r'\s+');

  /// Normalise un libellé brut de famille de risque.
  static String normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Non spécifiée';
    }

    var s = raw.trim();

    // 1. Remplacement des apostrophes courbes/typographiques par l'apostrophe droite standard
    s = s.replaceAll('’', "'").replaceAll('`', "'");

    // 2. Normalisation des séparateurs slash " / "
    if (s.contains('/')) {
      final parts = s
          .split('/')
          .map((p) => p.trim().replaceAll(_multiSpace, ' '))
          .where((p) => p.isNotEmpty)
          .toList();
      s = parts.join(' / ');
    } else {
      s = s.replaceAll(_multiSpace, ' ');
    }

    // 3. Première lettre en majuscule si nécessaire
    if (s.isNotEmpty) {
      s = s[0].toUpperCase() + s.substring(1);
    }

    return s;
  }
}
