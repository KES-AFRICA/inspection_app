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
  static const String keyTensionAssigneeMT = 'TENSION ASSIGNEE(KV)';
  static const String keyTensionDeServiceMT = 'Tension de service';
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

  // NOUVELLES CLÉS CANONIQUES BT ÉVOLUÉES
  static const String keyIntensiteNominale = 'Intensité nominale';
  static const String keyCouplage = 'Couplage';
  static const String keyTypeReseau = 'Type de réseau';
  static const String keyPccAmont = 'PCC amont';
  static const String keyPuissanceUcc = 'Puissance UCC';
  static const String keyIk3Max = 'IK3 MAX';

  /// Génère dynamiquement la liste des années valides à partir de l'année actuelle jusqu'à [startYear].
  static List<String> generateYearsList({int startYear = 1950}) {
    final currentYear = DateTime.now().year;
    final List<String> years = [];
    for (int y = currentYear; y >= startYear; y--) {
      years.add(y.toString());
    }
    return years;
  }

  static const List<String> natureReseauOptions = ['Aérien', 'Souterrain'];
  static const List<String> fonctionCelluleOptions = [
    'Cellule arrivée câble',
    'Cellule départ câble',
    'Cellule protection transformateur',
    'Cellule disjoncteur',
    'Cellule comptage',
    'Cellule couplage de barres',
    'Cellule remontée de barres',
    'Cellule mise à la terre',
    'Cellule protection par fusibles',
    'Cellule transformateur de tension/courant',
  ];

  static const List<String> presenceIacmOptions = ['Présent', 'Absent'];
  static const List<String> relaisBuchholzOptions = ['Présent', 'Absent'];
  static const List<String> typeTransformateurOptions = [
    'SEC',
    'IMMERGÉ',
  ];
  static const List<String> regimeNeutreOptions = ['TT', 'TN-S', 'TN-C', 'IT'];
  static const List<String> typeRefroidissementOptions = ['ONAN', 'ONAF', 'AN', 'ANAF'];

  // NOUVEAUX RÉFÉRENTIELS ÉVOLUÉS
  static const List<String> couplageOptions = ['Dyn', 'Yyn', 'Yd'];
  static const List<String> typeReseauOptions = [
    'Réseau rural',
    'Réseau urbain',
    'Poste source',
    'Réseau industriel',
  ];
  static const List<String> puissanceTransformateurOptions = [
    '25',
    '50',
    '63',
    '100',
    '160',
    '250',
    '315',
    '400',
    '500',
    '630',
    '800',
    '1 000',
    '1 250',
    '1 600',
    '2 000',
    '2 500',
    '3 150',
    '4 000',
    '5 000',
    '6 300',
    '8 000',
    '10 000',
  ];
  static const List<String> puissanceUccOptions = ['4 %', '6 %', '8 %'];
  static const List<String> tensionDeServiceOptions = ['15', '20', '30', '33'];

  // Map des unités par clé canonique
  static const Map<String, String> numericFieldsWithUnit = {
    keyCalibreDisjoncteurMT: 'A',
    keySectionCableMT: 'mm²',
    keyTensionAssignee: 'kV',
    keyTensionDeServiceMT: 'kV',
    keyPuissanceTransformateur: 'kVA',
    keyCalibreDisjoncteurBT: 'A',
    keyIntensiteNominale: 'A',
    keyPccAmont: 'MVA',
    keyIk3Max: 'kA',
  };

  /// Logique déterministe pour le calcul du PCC amont selon le Type de réseau
  static String getPccAmontForTypeReseau(String typeReseau) {
    switch (typeReseau) {
      case 'Réseau rural':
        return '250';
      case 'Réseau urbain':
        return '500';
      case 'Poste source':
        return '1000';
      case 'Réseau industriel':
        return '';
      default:
        return '';
    }
  }

  /// Grille de correspondance officielle IK3 MAX (kA) selon Puissance (kVA) et UCC (%)
  static const Map<String, Map<String, String>> _ik3MaxTable = {
    '100': {'4 %': '3,55 kA', '6 %': '2,40 kA', '8 %': '1,81 kA'},
    '160': {'4 %': '5,66 kA', '6 %': '3,86 kA', '8 %': '2,91 kA'},
    '250': {'4 %': '8,78 kA', '6 %': '5,95 kA', '8 %': '4,49 kA'},
    '315': {'4 %': '11,01 kA', '6 %': '7,47 kA', '8 %': '5,64 kA'},
    '400': {'4 %': '13,92 kA', '6 %': '9,44 kA', '8 %': '7,13 kA'},
    '500': {'4 %': '17,23 kA', '6 %': '11,75 kA', '8 %': '8,89 kA'},
    '630': {'4 %': '21,55 kA', '6 %': '14,67 kA', '8 %': '11,11 kA'},
    '800': {'4 %': '27,15 kA', '6 %': '18,52 kA', '8 %': '14,05 kA'},
    '1000': {'4 %': '33,72 kA', '6 %': '23,03 kA', '8 %': '17,50 kA'},
    '1 000': {'4 %': '33,72 kA', '6 %': '23,03 kA', '8 %': '17,50 kA'},
    '1250': {'4 %': '41,90 kA', '6 %': '28,68 kA', '8 %': '21,83 kA'},
    '1 250': {'4 %': '41,90 kA', '6 %': '28,68 kA', '8 %': '21,83 kA'},
    '1600': {'4 %': '52,95 kA', '6 %': '36,31 kA', '8 %': '27,70 kA'},
    '1 600': {'4 %': '52,95 kA', '6 %': '36,31 kA', '8 %': '27,70 kA'},
    '2000': {'4 %': '65,75 kA', '6 %': '45,20 kA', '8 %': '34,55 kA'},
    '2 000': {'4 %': '65,75 kA', '6 %': '45,20 kA', '8 %': '34,55 kA'},
    '2500': {'4 %': '80,85 kA', '6 %': '55,70 kA', '8 %': '42,65 kA'},
    '2 500': {'4 %': '80,85 kA', '6 %': '55,70 kA', '8 %': '42,65 kA'},
    '3150': {'4 %': '99,90 kA', '6 %': '69,00 kA', '8 %': '52,90 kA'},
    '3 150': {'4 %': '99,90 kA', '6 %': '69,00 kA', '8 %': '52,90 kA'},
  };

  /// Calculateur déterministe pour IK3 MAX selon la puissance et l'UCC
  static String calculateIk3Max({
    required String puissanceKva,
    required String uccPercent,
  }) {
    final cleanP = puissanceKva.trim().replaceAll('kVA', '').replaceAll(' ', '');
    final cleanUcc = uccPercent.contains('%') ? uccPercent.trim() : '${uccPercent.trim()} %';

    if (_ik3MaxTable.containsKey(cleanP)) {
      final subMap = _ik3MaxTable[cleanP]!;
      if (subMap.containsKey(cleanUcc)) {
        return subMap[cleanUcc]!;
      }
    }
    return '';
  }

  /// Normalisation d'une clé (suppression casse, accents, séparateurs)
  static String normalizeKey(String key) {
    return key
        .toLowerCase()
        .replaceAll(RegExp(r'\([^)]*\)'), '')
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
