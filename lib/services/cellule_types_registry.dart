/// Registre centralisé pour le champ "Type de cellule" (Moyenne Tension).
/// Source de vérité unique pour les nouvelles cellules et la rétrocompatibilité des cellules historiques.
class CelluleTypesRegistry {
  /// Liste officielle des 14 types de cellule
  static const List<String> typesOfficiels = [
    'DM1 : Disjoncteur + protection',
    'DM1-A : Cellule disjoncteur',
    'DM2 : Double sectionnement / disjoncteur',
    'IM : Interrupteur-sectionneur',
    'CM : Cellule de comptage',
    'SM : Sectionneur de mise à la terre',
    'TM : Transformateur de mesure',
    'TT : Transformateur de tension',
    'TC : Transformateur de courant',
    'PF : Protection par fusibles',
    'PFA : Protection fusible-arrivée',
    'SAS : Sectionneur d\'arrivée/sortie',
    'TP : Transformateur de potentiel',
    'TSA : Transformateur de services auxiliaires',
  ];

  /// Retourne la liste des options pour le Select "Type de cellule".
  /// Si [currentType] est une valeur historique non présente dans les 14 types officiels,
  /// elle est ajoutée en tête de liste pour éviter toute perte d'information.
  static List<String> getAvailableTypes(String? currentType) {
    if (currentType == null || currentType.trim().isEmpty) {
      return typesOfficiels;
    }
    final trimmed = currentType.trim();
    if (typesOfficiels.contains(trimmed)) {
      return typesOfficiels;
    }
    return [trimmed, ...typesOfficiels];
  }
}
