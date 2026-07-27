import 'package:flutter/foundation.dart';

/// Source unique de vérité pour l'unification des champs, clés canoniques,
/// unités et listes de sélection (dropdowns) entre l'Audit des Installations 
/// (Cellule MT / Transformateur MT/BT) et la Description des Installations.
class InstallationFieldsRegistry {
  // ══════════════════════════════════════════════════════════════════════
  // CLÉS CANONIQUES — ALIMENTATION MOYENNE TENSION (CELLULE MT)
  // ══════════════════════════════════════════════════════════════════════
  static const String keyGammeCellule = 'Gamme De Cellule';
  static const String keyTypeCellule = 'Type De Cellule';
  static const String keyCalibreDisjoncteurMT = 'Calibre Du Disjoncteur';
  static const String keySectionCableMT = 'Section Du Cable';
  static const String keyNatureReseau = 'Nature Du Reseau';
  static const String keyPresenceIacm = 'PRESENCE IACM';
  static const String keyFonctionCellule = 'Fonction de la cellule';
  static const String keyMarqueModeleAnnee = 'Marque / Modèle / Année';
  static const String keyTensionAssignee = 'Tension assignée';
  static const String keyPouvoirCoupure = 'Pouvoir de coupure assigné';
  static const String keyNumerotationRepere = 'Numérotation / Repérage';
  static const String keyParafoudres = 'Parafoudres installés';
  static const String keyLocalisation = 'Localisation';
  static const String keyObservations = 'Observations';

  // ══════════════════════════════════════════════════════════════════════
  // CLÉS CANONIQUES — ALIMENTATION BASSE TENSION (TRANSFORMATEUR MT/BT)
  // ══════════════════════════════════════════════════════════════════════
  static const String keyTypeTransformateur = 'Type de transformateur';
  static const String keyPuissanceTransformateur = 'Puissance Transformateur';
  static const String keyTensionPrimaireSecondaire = 'Tension';
  static const String keyCalibreDisjoncteurBT = 'Calibre Du Disjoncteur Sortie Transformateur';
  static const String keySectionCableBT = 'Section Du Cable';
  static const String keyRelaisBuchholz = 'Présence du relais Buchholz';
  static const String keyTypeRefroidissement = 'Type de refroidissement';
  static const String keyRegimeNeutre = 'Régime du neutre';
  static const String keyMarqueAnneeTransfo = 'Marque / Année de fabrication';

  // ══════════════════════════════════════════════════════════════════════
  // REFERENTIELS D'OPTIONS DE SÉLECTION (SINGLE SOURCE OF TRUTH)
  // ══════════════════════════════════════════════════════════════════════
  static const List<String> natureReseauOptions = ['Aérien', 'Souterrain'];
  static const List<String> presenceIacmOptions = ['Présent', 'Absent'];
  static const List<String> relaisBuchholzOptions = ['Présent', 'Absent'];
  static const List<String> typeTransformateurOptions = [
    'Transformateur à huile minérale',
    'Transformateur sec / résine',
    'Autre',
  ];
  static const List<String> regimeNeutreOptions = ['TT', 'TN-S', 'TN-C', 'IT'];
  static const List<String> typeRefroidissementOptions = ['ONAN', 'ONAF', 'AN', 'ANAF'];

  // Map des unités par clé canonique
  static const Map<String, String> numericFieldsWithUnit = {
    keyCalibreDisjoncteurMT: 'A',
    keySectionCableMT: 'mm²',
    keyPuissanceTransformateur: 'kVA',
    keyCalibreDisjoncteurBT: 'A',
  };

  /// Normalisation d'une clé (suppression casse, accents, séparateurs)
  static String normalizeKey(String key) {
    return key
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .replaceAll("'", ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
