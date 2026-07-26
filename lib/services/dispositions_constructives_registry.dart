/// Source de vérité unique pour les métadonnées des Dispositions Constructives et Conditions d'Exploitation du Local
class DispositionMetadata {
  final String referenceNormative;
  final String familleRisque;
  final String criticite;

  const DispositionMetadata({
    required this.referenceNormative,
    required this.familleRisque,
    required this.criticite,
  });
}

class DispositionsConstructivesRegistry {
  static const Map<String, DispositionMetadata> _registry = {
    // --- I. DISPOSITIONS CONSTRUCTIVES DU LOCAL TECHNIQUE MOYENNE TENSION ---
    "Le local est exclusivement réservé à l'usage électrique": DispositionMetadata(
      referenceNormative: "NF EN 62305-3",
      familleRisque: "Foudre",
      criticite: "Critique",
    ),
    'Signalisation visible "Local électrique – Accès réservé au personnel habilité"': DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 411.3",
      familleRisque: "Erreur de manœuvre",
      criticite: "Majeure",
    ),
    "Dimensions": DispositionMetadata(
      referenceNormative: "Norme NF C 13-200 art 542-544",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Parois, plancher et plafond en matériaux non combustibles": DispositionMetadata(
      referenceNormative: "Norme NF C 13-100 art 421-423",
      familleRisque: "Explosion / incendie",
      criticite: "Critique",
    ),
    "Présence d'une porte pleine, ouvrant vers l'extérieur, munie d'un dispositif anti-panique": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 112",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "Verrouillage empêchant tout accès non autorisé": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 464.1",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "Absence de communication directe avec les locaux à risque": DispositionMetadata(
      referenceNormative: "Norme NF C 13-100 art 32",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Absence de stockage d'objets non électriques": DispositionMetadata(
      referenceNormative: "Norme NF C 13-200 art 411",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Accessibilité du local et dégagement permanent des accès": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 112",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "État et continuité des liaisons équipotentielles du local": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 412.1",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "Présence et lisibilité des consignes de sécurité et plaques de danger": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 464.1",
      familleRisque: "Erreur de manœuvre",
      criticite: "Critique",
    ),
    "Présence de canalisations étrangères": DispositionMetadata(
      referenceNormative: "Norme NF C 13-200 art 411",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Présence d'un dispositif empêchant l'entrée d'eau et les infiltrations": DispositionMetadata(
      referenceNormative: "Norme NF C 13-200 art 514.2",
      familleRisque: "Explosion / incendie",
      criticite: "Critique",
    ),
    "Obturation coupe-feu des traversées de câbles et canalisations": DispositionMetadata(
      referenceNormative: "Norme NF C 13-200 art 411",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Absence de traces d'humidité, corrosion ou condensation": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 135",
      familleRisque: "Erreur de comptage",
      criticite: "Majeure",
    ),
    "Éclairage normal": DispositionMetadata(
      referenceNormative: "Norme NF C 13-200 art 541",
      familleRisque: "Électrisation / électrocution",
      criticite: "Critique",
    ),
    "Éclairage de secours conforme": DispositionMetadata(
      referenceNormative: "NF C 13-200:2009 – § 537",
      familleRisque: "Arc électrique",
      criticite: "Critique",
    ),
    "Ventilation / Climatisation": DispositionMetadata(
      referenceNormative: "Norme NF C 13-100 art 524",
      familleRisque: "Brûlure / incendie",
      criticite: "Majeure",
    ),
    "Compatibilité de la ventilation avec les équipements installés": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 311",
      familleRisque: "Surcharge",
      criticite: "Critique",
    ),
    "Présence d'un éclairage de sécurité permettant les manœuvres et l'évacuation": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 414",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Revêtement de sol isolant ou antidérapant": DispositionMetadata(
      referenceNormative: "NF EN IEC 60974-4 – § 5",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Présence d'un revêtement diélectrique ou isolant au sol": DispositionMetadata(
      referenceNormative: "Norme NF C 13-200 art 426.8",
      familleRisque: "Incendie",
      criticite: "Majeure",
    ),
    "Mise à la terre de toutes les masses métalliques": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 412.1",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "Présence de la terre du neutre": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 411.3",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "Présence de la terre des masses": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 411.3",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),

    // --- II. CONDITIONS D'EXPLOITATION ET DE SÉCURITÉ LOCAL MOYENNE TENSION ---
    "Accès réservé au personnel habilité (habilitation électrique à jour)": DispositionMetadata(
      referenceNormative: "Norme NF C 13-100 art 412",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Présence d'un dispositif de mise hors tension générale du local": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 112",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "Présence et accessibilité des EPI électriques (gants, visière, tapis)": DispositionMetadata(
      referenceNormative: "NF EN 61241-14",
      familleRisque: "Explosion",
      criticite: "Critique",
    ),
    "Zone dégagée et propre, sans obstruction des voies d'accès": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 134",
      familleRisque: "Non-conformité réglementaire",
      criticite: "Mineure",
    ),
    "Absence de stockage de matériaux inflammables": DispositionMetadata(
      referenceNormative: "Norme NF C 13-100 art 422",
      familleRisque: "Incendie",
      criticite: "Majeure",
    ),
    "Identification et condamnation des accès aux parties sous tension": DispositionMetadata(
      referenceNormative: "Norme NF C 13-100 art 541",
      familleRisque: "Électrisation / électrocution",
      criticite: "Critique",
    ),
    "Présence d'un plan d'intervention et de consignation affiché": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 134",
      familleRisque: "Non-conformité réglementaire",
      criticite: "Mineure",
    ),
    "Disponibilité et mise à jour du schéma unifilaire de l'installation": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – §134",
      familleRisque: "Erreur de manœuvre",
      criticite: "Majeure",
    ),
    "Affichage des consignes de manœuvre, secours et premiers soins": DispositionMetadata(
      referenceNormative: "NF EN 62305-3",
      familleRisque: "Foudre",
      criticite: "Critique",
    ),
    "Disponibilité du matériel de mise à la terre et en court-circuit": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 112",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "Disponibilité d'un dispositif de vérification d'absence de tension adapté à la MT": DispositionMetadata(
      referenceNormative: "Norme NF C 13-200 art 531-532",
      familleRisque: "Explosion / incendie",
      criticite: "Critique",
    ),
    "Contrôle périodique et traçabilité des EPI et équipements de sécurité": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 133",
      familleRisque: "Défaillance d'exploitation",
      criticite: "Majeure",
    ),
    "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible": DispositionMetadata(
      referenceNormative: "Norme NF C 13-200 art 412",
      familleRisque: "Électrisation / électrocution",
      criticite: "Critique",
    ),
    "Extincteur CO₂ disponible et vérifié (date de validité à jour)": DispositionMetadata(
      referenceNormative: "Norme NF C 13-100 art 421-423",
      familleRisque: "Explosion / incendie",
      criticite: "Critique",
    ),
    "Tenue d'un registre des opérations, incidents et maintenances": DispositionMetadata(
      referenceNormative: "Norme NF C 13-200 art 514.2",
      familleRisque: "Explosion / incendie",
      criticite: "Critique",
    ),
    "Présence d'une procédure de consignation et déconsignation": DispositionMetadata(
      referenceNormative: "Norme NF C 13-100 art 542",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
  };

  /// Récupère la métadonnée par le libellé de l'élément de contrôle (avec recherche insensible aux majuscules/espaces)
  static DispositionMetadata? getMetadata(String elementControle) {
    if (_registry.containsKey(elementControle)) {
      return _registry[elementControle];
    }
    final normalizedKey = _normalizeKey(elementControle);
    for (final entry in _registry.entries) {
      if (_normalizeKey(entry.key) == normalizedKey) {
        return entry.value;
      }
    }
    return null;
  }

  static String _normalizeKey(String key) {
    return key.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
