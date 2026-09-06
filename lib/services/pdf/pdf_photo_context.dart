enum PdfPhotoContext {
  /// Grille photo 2x2 (Pages photographies dédiées)
  grid2x2(maxWidth: 500, maxHeight: 375, quality: 60),

  /// Photos d'équipements, coffrets, armoires et constats d'observations
  equipmentObs(maxWidth: 320, maxHeight: 240, quality: 55),

  /// Schémas d'exploitation, diagrammes et illustrations pleine largeur
  schema(maxWidth: 800, maxHeight: 600, quality: 70);

  final int maxWidth;
  final int maxHeight;
  final int quality;
  const PdfPhotoContext({
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
  });
}
