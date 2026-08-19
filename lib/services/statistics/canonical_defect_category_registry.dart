/// Registre canonique pour la normalisation et le regroupement métier des catégories de défauts (Pareto).
class CanonicalDefectCategoryRegistry {
  static const String terreEtDifferentiel = 'Interconnexion à la terre et protections différentielles';
  static const String protectionSurintensites = 'Dispositifs de protection contre les surintensités';
  static const String repartitionEtRepartiteurs = 'Répartition des circuits et répartiteurs';
  static const String identificationEtReperage = 'Identification, repérage et documentation des circuits';
  static const String cablagesEtCanalisations = 'Câblages, raccordements et canalisations';
  static const String envelopesEtArmoires = 'Intégrité des enveloppes, armoires et coffrets';
  static const String organesDeCoupure = 'Organes de coupure, d\'isolement et d\'urgence';
  static const String eclairageSecurite = 'Éclairage de sécurité et secours';
  static const String posteMoyenneTension = 'Poste et équipements Moyenne Tension';
  static const String autresAnomalies = 'Autres anomalies d\'exploitation';

  /// Mappe n'importe quel libellé brut de point de vérification ou constat vers sa catégorie canonique normalisée.
  static String mapToCanonical(String? rawPoint, {String? riskFamily}) {
    final pointStr = (rawPoint ?? '').trim().toLowerCase();
    final riskStr = (riskFamily ?? '').trim().toLowerCase();
    final combined = '$pointStr $riskStr';

    if (combined.isEmpty) {
      return identificationEtReperage;
    }

    // 1. Interconnexion à la terre et protections différentielles
    if (combined.contains('terre') ||
        combined.contains('équipotentielle') ||
        combined.contains('différentiel') ||
        combined.contains('isolement') ||
        combined.contains('barette de coupure') ||
        combined.contains('mesure de terre') ||
        combined.contains('liaison équipotentielle') ||
        combined.contains('prise de terre') ||
        combined.contains('pe ')) {
      return terreEtDifferentiel;
    }

    // 2. Dispositifs de protection contre les surintensités
    if (combined.contains('surintensité') ||
        combined.contains('calibre') ||
        combined.contains('disjoncteur') ||
        combined.contains('fusible') ||
        combined.contains('pouvoir de coupure') ||
        combined.contains('coupe-circuit') ||
        combined.contains('dispositif de protection')) {
      return protectionSurintensites;
    }

    // 3. Répartition des circuits et répartiteurs
    if (combined.contains('répartiteur') ||
        combined.contains('répartition') ||
        combined.contains('jeu de barres') ||
        combined.contains('bornier') ||
        combined.contains('répartition de charge')) {
      return repartitionEtRepartiteurs;
    }

    // 4. Identification, repérage et documentation des circuits
    if (combined.contains('repérage') ||
        combined.contains('identification') ||
        combined.contains('étiquetage') ||
        combined.contains('schéma') ||
        combined.contains('unifilaire') ||
        combined.contains('signalisation') ||
        combined.contains('pictogramme') ||
        combined.contains('marquage')) {
      return identificationEtReperage;
    }

    // 5. Câblages, raccordements et canalisations
    if (combined.contains('câblage') ||
        combined.contains('canalisation') ||
        combined.contains('raccordement') ||
        combined.contains('connexion') ||
        combined.contains('serrage') ||
        combined.contains('gaine') ||
        combined.contains('cheminement') ||
        combined.contains('passage de câble') ||
        combined.contains('protection mécanique')) {
      return cablagesEtCanalisations;
    }

    // 6. Intégrité des enveloppes, armoires et coffrets
    if (combined.contains('enveloppe') ||
        combined.contains('armoire') ||
        combined.contains('coffret') ||
        combined.contains('étanchéité') ||
        combined.contains('indice de protection') ||
        combined.contains('ip') ||
        combined.contains('porte') ||
        combined.contains('obturation') ||
        combined.contains('plastron') ||
        combined.contains('ouvertures')) {
      return envelopesEtArmoires;
    }

    // 7. Organes de coupure, d'isolement et d'urgence
    if (combined.contains('coupure d\'urgence') ||
        combined.contains('sectionneur') ||
        combined.contains('interrupteur') ||
        combined.contains('organe de commande') ||
        combined.contains('manœuvre') ||
        combined.contains('arrêt d\'urgence')) {
      return organesDeCoupure;
    }

    // 8. Éclairage de sécurité et secours
    if (combined.contains('éclairage de sécurité') ||
        combined.contains('baes') ||
        combined.contains('bloc autonome') ||
        combined.contains('évacuation')) {
      return eclairageSecurite;
    }

    // 9. Poste et équipements Moyenne Tension
    if (combined.contains('cellule mt') ||
        combined.contains('transformateur') ||
        combined.contains('verrouillage') ||
        combined.contains('gaep') ||
        combined.contains('manœuvre mt')) {
      return posteMoyenneTension;
    }

    // Fallback propre
    final cleaned = (rawPoint ?? '').trim();
    if (cleaned.isNotEmpty) {
      return cleaned;
    }
    return autresAnomalies;
  }
}
