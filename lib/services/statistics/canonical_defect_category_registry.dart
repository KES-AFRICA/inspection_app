/// Registre canonique pour la normalisation et le regroupement métier des catégories de défauts (Pareto).
///
/// Assure une classification déterministe, traçable et sans fragmentation artificielle
/// des non-conformités issues des points de vérification et éléments de contrôle.
class CanonicalDefectCategoryRegistry {
  static const String identificationEtReperage = 'Identification, repérage et documentation des circuits';
  static const String cablagesEtCanalisations = 'Câblages, raccordements et canalisations';
  static const String envelopesEtArmoires = 'Intégrité des enveloppes, armoires et coffrets';
  static const String terreEtDifferentiel = 'Interconnexion à la terre et protections différentielles';
  static const String protectionSurintensites = 'Dispositifs de protection contre les surintensités';
  static const String consignationEtEpi = 'Organisation des interventions, consignation et EPI';
  static const String organesDeCoupure = 'Organes de coupure, d\'isolement et d\'urgence';
  static const String revetementDielectrique = 'Revêtement diélectrique et isolement des sols';
  static const String posteMoyenneTension = 'Poste et équipements Moyenne Tension';
  static const String eclairageSecurite = 'Éclairage de sécurité et secours';
  static const String repartitionEtRepartiteurs = 'Répartition des circuits et répartiteurs';
  static const String foudreEtParafoudres = 'Protection contre la foudre et surtensions';
  static const String conditionsAmbiance = 'Conditions d\'ambiance, ventilation et environnement';
  static const String autresAnomalies = 'Autres anomalies d\'exploitation';

  /// Liste ordonnée de toutes les catégories canoniques de référence.
  static const List<String> allCanonicalCategories = [
    identificationEtReperage,
    cablagesEtCanalisations,
    envelopesEtArmoires,
    terreEtDifferentiel,
    protectionSurintensites,
    consignationEtEpi,
    organesDeCoupure,
    revetementDielectrique,
    posteMoyenneTension,
    eclairageSecurite,
    repartitionEtRepartiteurs,
    foudreEtParafoudres,
    conditionsAmbiance,
    autresAnomalies,
  ];

  /// Mappe n'importe quel libellé brut de point de vérification ou constat vers sa catégorie canonique normalisée.
  static String mapToCanonical(String? rawPoint, {String? riskFamily}) {
    final pointStr = (rawPoint ?? '').trim().toLowerCase();
    final riskStr = (riskFamily ?? '').trim().toLowerCase();
    final combined = '$pointStr $riskStr';

    if (combined.isEmpty) {
      return identificationEtReperage;
    }

    // 1. Protection foudre et parafoudres
    if (combined.contains('foudre') ||
        combined.contains('parafoudre') ||
        combined.contains('paratonnerre') ||
        combined.contains('conducteur de descente')) {
      return foudreEtParafoudres;
    }

    // 2. Interconnexion à la terre et protections différentielles
    if (combined.contains('terre') ||
        combined.contains('équipotentielle') ||
        combined.contains('différentiel') ||
        combined.contains('isolement') ||
        combined.contains('barette de coupure') ||
        combined.contains('mesure de terre') ||
        combined.contains('liaison équipotentielle') ||
        combined.contains('prise de terre') ||
        RegExp(r'\bpe\b').hasMatch(combined)) {
      return terreEtDifferentiel;
    }

    // 3. Organisation des interventions, consignation et EPI
    if (combined.contains('consignation') ||
        combined.contains('déconsignation') ||
        combined.contains('cadenas') ||
        combined.contains('condamnation') ||
        combined.contains('epi') ||
        combined.contains('protection individuelle') ||
        combined.contains('gant') ||
        combined.contains('visière') ||
        combined.contains('écran facial') ||
        combined.contains('vat') ||
        combined.contains('absence de tension') ||
        combined.contains('plan d\'intervention') ||
        combined.contains('procédure') ||
        combined.contains('habilitation')) {
      return consignationEtEpi;
    }

    // 4. Revêtement diélectrique et isolement des sols
    if (combined.contains('diélectrique') ||
        combined.contains('tapis isolant') ||
        combined.contains('tabouret isolant') ||
        combined.contains('revêtement') && combined.contains('sol') ||
        combined.contains('isolant au sol')) {
      return revetementDielectrique;
    }

    // 5. Poste et équipements Moyenne Tension (priorité sur disjoncteurs/protections génériques)
    if (combined.contains('cellule') ||
        combined.contains('moyenne tension') ||
        combined.contains('hta') ||
        combined.contains('transformateur') ||
        combined.contains('verrouillage') ||
        combined.contains('gaep') ||
        combined.contains('dgpt2') ||
        combined.contains('bac de rétention') ||
        combined.contains('manœuvre mt')) {
      return posteMoyenneTension;
    }

    // 6. Dispositifs de protection contre les surintensités
    if (combined.contains('surintensité') ||
        combined.contains('calibre') ||
        combined.contains('disjoncteur') ||
        combined.contains('fusible') ||
        combined.contains('pouvoir de coupure') ||
        combined.contains('coupe-circuit') ||
        combined.contains('dispositif de protection')) {
      return protectionSurintensites;
    }

    // 6. Organes de coupure, d'isolement et d'urgence
    if (combined.contains('coupure d\'urgence') ||
        combined.contains('coupure générale') ||
        combined.contains('arrêt d\'urgence') ||
        combined.contains('sectionneur') ||
        combined.contains('interrupteur') ||
        combined.contains('organe de coupure') ||
        combined.contains('organe de commande') ||
        combined.contains('manœuvre') ||
        combined.contains('déconnexion')) {
      return organesDeCoupure;
    }

    // 7. Répartition des circuits et répartiteurs
    if (combined.contains('répartiteur') ||
        combined.contains('répartition') ||
        combined.contains('jeu de barres') ||
        combined.contains('bornier') ||
        combined.contains('peigne')) {
      return repartitionEtRepartiteurs;
    }

    // 8. Identification, repérage et documentation des circuits
    if (combined.contains('repérage') ||
        combined.contains('identification') ||
        combined.contains('étiquetage') ||
        combined.contains('étiquette') ||
        combined.contains('schéma') ||
        combined.contains('unifilaire') ||
        combined.contains('signalisation') ||
        combined.contains('pictogramme') ||
        combined.contains('danger') ||
        combined.contains('marquage')) {
      return identificationEtReperage;
    }

    // 9. Câblages, raccordements et canalisations
    if (combined.contains('câblage') ||
        combined.contains('câble') ||
        combined.contains('cable') ||
        combined.contains('filerie') ||
        combined.contains('conducteur') && !combined.contains('conducteur pe') ||
        combined.contains('canalisation') ||
        combined.contains('raccordement') ||
        combined.contains('connexion') ||
        combined.contains('serrage') ||
        combined.contains('gaine') ||
        combined.contains('cheminement') ||
        combined.contains('presse-étoupe') ||
        combined.contains('passage de câble') ||
        combined.contains('protection mécanique')) {
      return cablagesEtCanalisations;
    }

    // 10. Intégrité des enveloppes, armoires et coffrets
    if (combined.contains('enveloppe') ||
        combined.contains('armoire') ||
        combined.contains('coffret') ||
        combined.contains('étanchéité') ||
        combined.contains('indice de protection') ||
        combined.contains('ip') ||
        combined.contains('ik') ||
        combined.contains('porte') ||
        combined.contains('serrure') ||
        combined.contains('obturation') ||
        combined.contains('obturateur') ||
        combined.contains('plastron') ||
        combined.contains('ouvertures')) {
      return envelopesEtArmoires;
    }

    // 11. Éclairage de sécurité et secours
    if (combined.contains('éclairage de sécurité') ||
        combined.contains('baes') ||
        combined.contains('bloc autonome') ||
        combined.contains('évacuation')) {
      return eclairageSecurite;
    }


    // 13. Conditions d'ambiance, ventilation et environnement
    if (combined.contains('ventilation') ||
        combined.contains('aération') ||
        combined.contains('atmosphère') ||
        combined.contains('atex') ||
        combined.contains('humidité') ||
        combined.contains('poussière') ||
        combined.contains('corrosion') ||
        combined.contains('température') ||
        combined.contains('encombrement')) {
      return conditionsAmbiance;
    }

    // Fallback propre : si le libellé brut est explicite (plus de 3 caractères), le conserver
    final cleaned = (rawPoint ?? '').trim();
    if (cleaned.length >= 3) {
      return cleaned;
    }
    return autresAnomalies;
  }
}
