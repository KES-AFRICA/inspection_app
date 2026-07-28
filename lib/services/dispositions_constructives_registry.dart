/// Source de vérité unique pour les métadonnées des Dispositions Constructives et Conditions d'Exploitation du Local
import '../models/audit_installations_electriques.dart';
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

    // --- III. CELLULE MOYENNE TENSION ---
    "Schéma unifilaire affiché dans le local": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – §134",
      familleRisque: "Erreur de manœuvre",
      criticite: "Majeure",
    ),
    "Verrouillage mécanique": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – §464.1",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "Fonctionnement des interverrouillages électriques et mécaniques": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 511",
      familleRisque: "Non-conformité réglementaire",
      criticite: "Majeure",
    ),
    "Etat et serrage apparent des connexions accessibles": DispositionMetadata(
      referenceNormative: "Norme NF C 13-100 art 413",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Identification et lisibilité des plaques signalétiques": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 514",
      familleRisque: "Erreur d'exploitation",
      criticite: "Majeure",
    ),
    "Cellule correctement posée et fixée": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 411.3",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "Jonctions inter-cellules": DispositionMetadata(
      referenceNormative: "Norme NF C 13-200 art 542-544",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Canalisations et câbles d'arrivée / départ": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – §514",
      familleRisque: "Erreur d'exploitation",
      criticite: "Majeure",
    ),
    "État général de l'enveloppe, absence de corrosion et déformation": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 414",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "État des isolateurs et absence de traces d'amorçage": DispositionMetadata(
      referenceNormative: "NF EN 62271-102",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "Respect des distances de sécurité": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 414",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Voyants de position (O / F / T)": DispositionMetadata(
      referenceNormative: "NF C 13-200:2009 – § 133.4",
      familleRisque: "Erreur de comptage",
      criticite: "Majeure",
    ),
    "Présence et état des dispositifs de détection / indication de tension": DispositionMetadata(
      referenceNormative: "NF C 13-200:2009 – § 538",
      familleRisque: "Défaillance de protection",
      criticite: "Critique",
    ),
    "Terre de protection (PE) reliée à chaque cellule": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – Partie 5-54",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "Fonctionnement du sectionneur de terre et indication de position": DispositionMetadata(
      referenceNormative: "NF EN 62271-102",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "Continuité du circuit de terre de la cellule": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 413",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Conformité du pouvoir de coupure aux caractéristiques du réseau": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 312",
      familleRisque: "Défaillance d'exploitation",
      criticite: "Majeure",
    ),
    "Etat des fusibles, disjoncteurs et relais de protection": DispositionMetadata(
      referenceNormative: "Norme NF C 13-200 art 431-432",
      familleRisque: "Électrisation / électrocution / défaut d'isolement",
      criticite: "Critique",
    ),
    "Réglage et coordination des protections MT": DispositionMetadata(
      referenceNormative: "Norme NF C 13-100 art 542",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Commande manuelle / motorisée": DispositionMetadata(
      referenceNormative: "NF EN IEC 60974-4 – § 5",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Absence d'échauffement anormal contrôlée par thermographie infrarouge": DispositionMetadata(
      referenceNormative: "Norme NF C 13-100 art 32",
      familleRisque: "Brûlure / incendie",
      criticite: "Majeure",
    ),

    // --- IV. TRANSFORMATEUR MT/BT ---
    "Adapté au local et à la ventilation": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 512.2",
      familleRisque: "Protection mécanique / pénétration corps solides-liquides",
      criticite: "Majeure",
    ),
    "Vérification de la ventilation et des distances de dégagement": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 512.2",
      familleRisque: "Protection mécanique / pénétration corps solides-liquides",
      criticite: "Majeure",
    ),
    "État et dimensionnement du bac de rétention pour transformateur à huile": DispositionMetadata(
      referenceNormative: "NF C 15-211:2024 – § 3",
      familleRisque: "Sécurité patients / continuité de service",
      criticite: "Critique",
    ),
    "Plaque signalétique (puissance, tension, couplage)": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 538",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Raccordement des câbles MT et BT": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 544",
      familleRisque: "Électrisation / défaut de continuité de protection",
      criticite: "Critique",
    ),
    "État général du transformateur et absence de fuite d'huile": DispositionMetadata(
      referenceNormative: "Norme NF C 13-200 art 422",
      familleRisque: "Incendie",
      criticite: "Majeure",
    ),
    "État des traversées / isolateurs MT et BT": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 414",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "État des connexions et serrage des bornes MT et BT": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 526",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Bac de rétention (pour transfo à huile)": DispositionMetadata(
      referenceNormative: "NF C 13-200:2009 – Partie 5",
      familleRisque: "Incendie",
      criticite: "Critique",
    ),
    "Niveau d'huile conforme pour transformateur immergé": DispositionMetadata(
      referenceNormative: "NF C 13-200:2009 – Partie 5",
      familleRisque: "Incendie",
      criticite: "Critique",
    ),
    "Essais diélectriques": DispositionMetadata(
      referenceNormative: "Norme NF C 13-200 art 426.8",
      familleRisque: "Incendie",
      criticite: "Majeure",
    ),
    "Écran de câble MT relié à la terre": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 544",
      familleRisque: "Électrisation / défaut de continuité de protection",
      criticite: "Critique",
    ),
    "Distance entre transformateur": DispositionMetadata(
      referenceNormative: "Norme NF C 13-100 art 432",
      familleRisque: "Incendie",
      criticite: "Majeure",
    ),
    "État et fonctionnement des dispositifs de surveillance de température": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 465",
      familleRisque: "Sécurité des interventions / arrêt d'urgence",
      criticite: "Majeure",
    ),
    "Compatibilité de la puissance du transformateur avec la charge": DispositionMetadata(
      referenceNormative: "NF C 15-211:2024 – § 3",
      familleRisque: "Sécurité patients / continuité de service",
      criticite: "Critique",
    ),
    "Mise à la terre du neutre et de la carcasse": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 542",
      familleRisque: "Électrisation / défaut d'évacuation des courants de défaut",
      criticite: "Critique",
    ),
    "Continuité de la mise à la terre de la cuve et des masses": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 412.1",
      familleRisque: "Électrocution",
      criticite: "Critique",
    ),
    "Protection contre les contacts directs": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 414",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Protection contre les surintensités": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 430",
      familleRisque: "Incendie / échauffement / détérioration des conducteurs",
      criticite: "Critique",
    ),
    "Protection MT": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 512.2",
      familleRisque: "Protection mécanique / pénétration corps solides-liquides",
      criticite: "Majeure",
    ),
    "Protection BT (disjoncteur général, fusibles, relais thermique)": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 430",
      familleRisque: "Incendie / échauffement / détérioration des conducteurs",
      criticite: "Critique",
    ),
    "Fonctionnement des protections DGPT2 / Buchholz lorsqu'elles existent": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 112",
      familleRisque: "Perturbation réseau",
      criticite: "Critique",
    ),
    "Protection contre les surtensions côté MT et BT": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 414",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Contrôle thermographique des connexions, et protections": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 6.6.4.3.2",
      familleRisque: "Incendie / échauffement",
      criticite: "Majeure",
    ),
    "Mesure de la résistance d'isolement des enroulements": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 538",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Contrôle du rapport de transformation et du couplage": DispositionMetadata(
      referenceNormative: "NF C 13-100:2015 – § 134",
      familleRisque: "Non-conformité réglementaire",
      criticite: "Mineure",
    ),

    // --- V. DISPOSITIONS CONSTRUCTIVES & CONDITIONS GROUPE ÉLECTROGENE (Nouveaux points spécifiques) ---
    "Sol du local imperméable et formé comme une cuvette étanche, le seuil des baies étant surélevé d'au moins 0,10 mètre et toutes dispositions doivent être prises pour que le combustible accidentellement répandu ne puisse se déverser par les orifices placés dans le sol.": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Présence d'une rétention adaptée au stockage et aux fuites de combustible": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Canalisations du combustible": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Moyens d'extinction adaptés aux risques électriques et de carburant": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "État et étanchéité des conduites et raccords de combustible": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Évacuation des gaz d'échappement vers l'extérieur sans risque pour les occupants": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Protection des parties chaudes et du conduit d'échappement": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Ventilation suffisante pour le refroidissement et la combustion": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 512.2",
      familleRisque: "Échauffement / conditions d'environnement",
      criticite: "Majeure",
    ),
    "Mise à la terre du châssis du groupe électrogène": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 542 et § 543",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Critique",
    ),
    "Disponibilité des consignes de démarrage, arrêt normal et arrêt d'urgence": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 462, § 465 et § 537",
      familleRisque: "Sécurité des interventions / arrêt d'urgence",
      criticite: "Critique",
    ),
    "Disponibilité du schéma de raccordement et de l'inverseur de sources": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551",
      familleRisque: "Défaillance de la source de remplacement / continuité de service",
      criticite: "Majeure",
    ),
    "Contrôle du niveau de carburant, huile et liquide de refroidissement": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Absence de fuite de carburant ou d'huile lors de l'exploitation": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Essai périodique du démarrage automatique du groupe électrogène": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551",
      familleRisque: "Défaillance de la source de remplacement / continuité de service",
      criticite: "Majeure",
    ),
    "Traçabilité des essais périodiques et opérations de maintenance": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 561",
      familleRisque: "Évacuation / sécurité incendie",
      criticite: "Majeure",
    ),
    "Vérification du fonctionnement des alarmes et sécurités moteur": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551",
      familleRisque: "Défaillance de la source de remplacement / continuité de service",
      criticite: "Majeure",
    ),
  };

  /// Liste officielle des 21 points de vérification des Dispositions Constructives du Groupe Électrogène
  static const List<String> allGEDispositionsPoints = [
    "Sol du local imperméable et formé comme une cuvette étanche, le seuil des baies étant surélevé d'au moins 0,10 mètre et toutes dispositions doivent être prises pour que le combustible accidentellement répandu ne puisse se déverser par les orifices placés dans le sol.",
    'Signalisation visible "Local électrique – Accès réservé au personnel habilité"',
    "Dimensions",
    "Parois, plancher et plafond en matériaux non combustibles coupe-feu de degré 2 heures",
    "Présence d'une porte pleine coupe-feu de degré 1 heure, ouvrant vers l'extérieur, munie d'un dispositif antipanique",
    "Absence de communication directe avec les locaux à risque",
    "Absence de stockage d'objets non électriques",
    "Présence d'une rétention adaptée au stockage et aux fuites de combustible",
    "Présence d'un dispositif d'arrêt d'urgence accessible et identifié",
    "Canalisations du combustible",
    "Absence de canalisations étrangères",
    "Éclairage normal",
    "Éclairage de secours conforme",
    "Ventilation",
    "Moyens d'extinction adaptés aux risques électriques et de carburant",
    "État et étanchéité des conduites et raccords de combustible",
    "Évacuation des gaz d'échappement vers l'extérieur sans risque pour les occupants",
    "Protection des parties chaudes et du conduit d'échappement",
    "Ventilation suffisante pour le refroidissement et la combustion",
    "Mise à la terre de toutes les masses métalliques",
    "Mise à la terre du châssis du groupe électrogène",
  ];

  /// Liste officielle des 15 points de vérification des Conditions d'Exploitation du Groupe Électrogène
  static const List<String> allGEConditionsPoints = [
    "Accès réservé au personnel habilité (habilitation électrique à jour)",
    "Présence d'un dispositif de mise hors tension générale du local",
    "Présence et accessibilité des EPI électriques (gants, visière, tapis)",
    "Zone dégagée et propre, sans obstruction des voies d'accès",
    "Absence de stockage de matériaux inflammables",
    "Présence d'un plan d'intervention et de consignation affiché",
    "Disponibilité des consignes de démarrage, arrêt normal et arrêt d'urgence",
    "Disponibilité du schéma de raccordement et de l'inverseur de sources",
    "Contrôle du niveau de carburant, huile et liquide de refroidissement",
    "Absence de fuite de carburant ou d'huile lors de l'exploitation",
    "Essai périodique du démarrage automatique du groupe électrogène",
    "Traçabilité des essais périodiques et opérations de maintenance",
    "Vérification du fonctionnement des alarmes et sécurités moteur",
    "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible",
    "Extincteur CO₂ disponible et vérifié (date de validité à jour)",
  ];

  /// Registre spécifique des métadonnées pour le local Groupe Électrogène
  static final Map<String, DispositionMetadata> _geRegistry = {
    // --- DISPOSITIONS CONSTRUCTIVES GROUPE ÉLECTROGENE ---
    "Sol du local imperméable et formé comme une cuvette étanche, le seuil des baies étant surélevé d'au moins 0,10 mètre et toutes dispositions doivent être prises pour que le combustible accidentellement répandu ne puisse se déverser par les orifices placés dans le sol.": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    'Signalisation visible "Local électrique – Accès réservé au personnel habilité"': DispositionMetadata(
      referenceNormative: "NF C 15-100-7-729:2024 – § 729",
      familleRisque: "Accès non autorisé / risque électrique",
      criticite: "Majeure",
    ),
    "Dimensions": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 512.2",
      familleRisque: "Protection mécanique / pénétration corps solides-liquides",
      criticite: "Majeure",
    ),
    "Parois, plancher et plafond en matériaux non combustibles coupe-feu de degré 2 heures": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 421, § 422 et § 527",
      familleRisque: "Incendie / propagation du feu",
      criticite: "Majeure",
    ),
    "Présence d'une porte pleine coupe-feu de degré 1 heure, ouvrant vers l'extérieur, munie d'un dispositif antipanique": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 421, § 422 et § 527",
      familleRisque: "Incendie / propagation du feu",
      criticite: "Majeure",
    ),
    "Absence de communication directe avec les locaux à risque": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 512.2",
      familleRisque: "Protection mécanique / pénétration corps solides-liquides",
      criticite: "Majeure",
    ),
    "Absence de stockage d'objets non électriques": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 421, § 422 et § 527",
      familleRisque: "Incendie / propagation du feu",
      criticite: "Majeure",
    ),
    "Présence d'une rétention adaptée au stockage et aux fuites de combustible": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Présence d'un dispositif d'arrêt d'urgence accessible et identifié": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 462, § 465 et § 537",
      familleRisque: "Sécurité des interventions / arrêt d'urgence",
      criticite: "Critique",
    ),
    "Canalisations du combustible": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Absence de canalisations étrangères": DispositionMetadata(
      referenceNormative: "NF C 15-100-7-729:2024 – § 729",
      familleRisque: "Sécurité d'exploitation",
      criticite: "Majeure",
    ),
    "Éclairage normal": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 559",
      familleRisque: "Sécurité d'exploitation",
      criticite: "Majeure",
    ),
    "Éclairage de secours conforme": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – Partie 5-56",
      familleRisque: "Évacuation / continuité des installations de sécurité",
      criticite: "Majeure",
    ),
    "Ventilation": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 512.2",
      familleRisque: "Échauffement / conditions d'environnement",
      criticite: "Majeure",
    ),
    "Moyens d'extinction adaptés aux risques électriques et de carburant": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "État et étanchéité des conduites et raccords de combustible": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Évacuation des gaz d'échappement vers l'extérieur sans risque pour les occupants": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Protection des parties chaudes et du conduit d'échappement": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Ventilation suffisante pour le refroidissement et la combustion": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 512.2",
      familleRisque: "Échauffement / conditions d'environnement",
      criticite: "Majeure",
    ),
    "Mise à la terre de toutes les masses métalliques": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 542 et § 543",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Critique",
    ),
    "Mise à la terre du châssis du groupe électrogène": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 542 et § 543",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Critique",
    ),

    // --- CONDITIONS D'EXPLOITATION GROUPE ÉLECTROGENE ---
    "Accès réservé au personnel habilité (habilitation électrique à jour)": DispositionMetadata(
      referenceNormative: "NF C 18-510",
      familleRisque: "Sécurité des interventions / risque électrique",
      criticite: "Majeure",
    ),
    "Présence d'un dispositif de mise hors tension générale du local": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 462, § 465 et § 537",
      familleRisque: "Sécurité des interventions / arrêt d'urgence",
      criticite: "Critique",
    ),
    "Présence et accessibilité des EPI électriques (gants, visière, tapis)": DispositionMetadata(
      referenceNormative: "NF C 18-510",
      familleRisque: "Sécurité des interventions / risque électrique",
      criticite: "Majeure",
    ),
    "Zone dégagée et propre, sans obstruction des voies d'accès": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 513",
      familleRisque: "Accès / exploitation / intervention",
      criticite: "Majeure",
    ),
    "Absence de stockage de matériaux inflammables": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 421, § 422 et § 527",
      familleRisque: "Incendie / propagation du feu",
      criticite: "Majeure",
    ),
    "Présence d'un plan d'intervention et de consignation affiché": DispositionMetadata(
      referenceNormative: "NF C 18-510",
      familleRisque: "Sécurité des interventions / risque électrique",
      criticite: "Majeure",
    ),
    "Disponibilité des consignes de démarrage, arrêt normal et arrêt d'urgence": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 462, § 465 et § 537",
      familleRisque: "Sécurité des interventions / arrêt d'urgence",
      criticite: "Critique",
    ),
    "Disponibilité du schéma de raccordement et de l'inverseur de sources": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551",
      familleRisque: "Défaillance de la source de remplacement / continuité de service",
      criticite: "Majeure",
    ),
    "Contrôle du niveau de carburant, huile et liquide de refroidissement": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Absence de fuite de carburant ou d'huile lors de l'exploitation": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et prescriptions du fabricant",
      familleRisque: "Incendie / brûlure / fuite de combustible",
      criticite: "Critique",
    ),
    "Essai périodique du démarrage automatique du groupe électrogène": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551",
      familleRisque: "Défaillance de la source de remplacement / continuité de service",
      criticite: "Majeure",
    ),
    "Traçabilité des essais périodiques et opérations de maintenance": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 561",
      familleRisque: "Évacuation / sécurité incendie",
      criticite: "Majeure",
    ),
    "Vérification du fonctionnement des alarmes et sécurités moteur": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551",
      familleRisque: "Défaillance de la source de remplacement / continuité de service",
      criticite: "Majeure",
    ),
    "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible": DispositionMetadata(
      referenceNormative: "NF C 18-510",
      familleRisque: "Sécurité des interventions / risque électrique",
      criticite: "Majeure",
    ),
    "Extincteur CO₂ disponible et vérifié (date de validité à jour)": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 514",
      familleRisque: "Erreur d'exploitation / maintenance",
      criticite: "Majeure",
    ),
  };

  static final Map<String, String> _geDispositionsTitleAliases = {
    _normalizeKey("Parois, plancher et plafond en matériaux non combustibles"):
        "Parois, plancher et plafond en matériaux non combustibles coupe-feu de degré 2 heures",
    _normalizeKey("Parois, plancher et plafond en materiaux non combustibles"):
        "Parois, plancher et plafond en matériaux non combustibles coupe-feu de degré 2 heures",
    _normalizeKey("Présence d'une porte pleine, ouvrant vers l'extérieur, munie d'un dispositif anti-panique"):
        "Présence d'une porte pleine coupe-feu de degré 1 heure, ouvrant vers l'extérieur, munie d'un dispositif antipanique",
    _normalizeKey("Présence d'une porte pleine, ouvrant vers l'exterieur, munie d'un dispositif anti-panique"):
        "Présence d'une porte pleine coupe-feu de degré 1 heure, ouvrant vers l'extérieur, munie d'un dispositif antipanique",
    _normalizeKey("Présence de canalisations étrangères"):
        "Absence de canalisations étrangères",
    _normalizeKey("Présence de stockage d'objets non électriques"):
        "Absence de stockage d'objets non électriques",
    _normalizeKey("Ventilation / Climatisation"):
        "Ventilation",
  };

  static final Map<String, String> _geConditionsTitleAliases = {
    _normalizeKey("Présence de stockage de matériaux inflammables"):
        "Absence de stockage de matériaux inflammables",
    _normalizeKey("Presence de stockage de materiaux inflammables"):
        "Absence de stockage de matériaux inflammables",
    _normalizeKey("Identification et condamnation des accès aux parties sous tension"):
        "Accès réservé au personnel habilité (habilitation électrique à jour)",
    _normalizeKey("Disponibilité et mise à jour du schéma unifilaire de l'installation"):
        "Disponibilité du schéma de raccordement et de l'inverseur de sources",
    _normalizeKey("Affichage des consignes de manœuvre, secours et premiers soins"):
        "Présence d'un plan d'intervention et de consignation affiché",
    _normalizeKey("Disponibilité du matériel de mise à la terre et en court-circuit"):
        "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible",
  };

  /// Liste officielle des 23 points de vérification des Dispositions Constructives du Local Basse Tension (BT)
  static const List<String> allBTDispositionsPoints = [
    "Le local est exclusivement réservé à l'usage électrique",
    'Signalisation visible "Local électrique – Accès réservé au personnel habilité"',
    "Dimensions",
    "Parois, plancher et plafond en matériaux non combustibles",
    "Présence d'une porte pleine, ouvrant vers l'extérieur, munie d'un dispositif anti-panique",
    "Verrouillage empêchant tout accès non autorisé",
    "Absence de communication directe avec les locaux à risque",
    "Absence de stockage d'objets non électriques",
    "Accessibilité du local et dégagement permanent devant les tableaux",
    "Obturation des traversées et maintien du degré coupe-feu des parois",
    "Présence et lisibilité des consignes de sécurité",
    "Identification du schéma de liaison à la terre de l'installation",
    "Présence de canalisations étrangères",
    "Absence d'infiltration d'eau, humidité ou condensation",
    "Éclairage normal",
    "Éclairage de secours conforme",
    "Ventilation / Climatisation",
    "Revêtement de sol isolant ou antidérapant",
    "Présence d'un revêtement diélectrique ou isolant au sol",
    "Mise à la terre de toutes les masses métalliques",
    "Présence de la terre du neutre",
    "Présence de la terre des masses",
    "Continuité des liaisons équipotentielles principales",
  ];

  /// Liste officielle des 13 points de vérification des Conditions d'Exploitation du Local Basse Tension (BT)
  static const List<String> allBTConditionsPoints = [
    "Accès réservé au personnel habilité (habilitation électrique à jour)",
    "Présence d'un dispositif de mise hors tension générale du local",
    "Présence et accessibilité des EPI électriques (gants, visière, tapis)",
    "Zone dégagée et propre, sans obstruction des voies d'accès",
    "Absence de stockage de matériaux inflammables",
    "Accès permanent aux dispositifs de coupure d'urgence",
    "Absence de pièces nues sous tension accessibles",
    "Présence d'un plan d'intervention et de consignation affiché",
    "Disponibilité et mise à jour du schéma unifilaire",
    "Traçabilité des opérations de maintenance et des vérifications",
    "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible",
    "Extincteur CO₂ disponible et vérifié (date de validité à jour)",
    "Disponibilité d'une procédure de consignation électrique",
  ];

  /// Registre spécifique des métadonnées pour le local Basse Tension (BT)
  static final Map<String, DispositionMetadata> _btRegistry = {
    // --- DISPOSITIONS CONSTRUCTIVES BT ---
    "Le local est exclusivement réservé à l'usage électrique": DispositionMetadata(
      referenceNormative: "NF C 15-100-7-729:2024 – § 729",
      familleRisque: "Sécurité d'exploitation",
      criticite: "Majeure",
    ),
    'Signalisation visible "Local électrique – Accès réservé au personnel habilité"': DispositionMetadata(
      referenceNormative: "NF C 15-100-7-729:2024 – § 729",
      familleRisque: "Accès non autorisé / risque électrique",
      criticite: "Majeure",
    ),
    "Dimensions": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 512.2",
      familleRisque: "Protection mécanique / pénétration corps solides-liquides",
      criticite: "Majeure",
    ),
    "Parois, plancher et plafond en matériaux non combustibles": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 421, § 422 et § 527",
      familleRisque: "Incendie / propagation du feu",
      criticite: "Majeure",
    ),
    "Présence d'une porte pleine, ouvrant vers l'extérieur, munie d'un dispositif anti-panique": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 462",
      familleRisque: "Sécurité des interventions",
      criticite: "Majeure",
    ),
    "Verrouillage empêchant tout accès non autorisé": DispositionMetadata(
      referenceNormative: "NF C 15-100-7-729:2024 – § 729",
      familleRisque: "Accès non autorisé / risque électrique",
      criticite: "Majeure",
    ),
    "Absence de communication directe avec les locaux à risque": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 512.2",
      familleRisque: "Protection mécanique / pénétration corps solides-liquides",
      criticite: "Majeure",
    ),
    "Absence de stockage d'objets non électriques": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 421, § 422 et § 527",
      familleRisque: "Incendie / propagation du feu",
      criticite: "Majeure",
    ),
    "Accessibilité du local et dégagement permanent devant les tableaux": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 513",
      familleRisque: "Accès / exploitation / intervention",
      criticite: "Majeure",
    ),
    "Obturation des traversées et maintien du degré coupe-feu des parois": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 421, § 422 et § 527",
      familleRisque: "Incendie / propagation du feu",
      criticite: "Majeure",
    ),
    "Présence et lisibilité des consignes de sécurité": DispositionMetadata(
      referenceNormative: "NF C 18-510",
      familleRisque: "Sécurité des interventions / risque électrique",
      criticite: "Majeure",
    ),
    "Identification du schéma de liaison à la terre de l'installation": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 514",
      familleRisque: "Erreur d'exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Présence de canalisations étrangères": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 514",
      familleRisque: "Erreur d'exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Absence d'infiltration d'eau, humidité ou condensation": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 512.2 et § 522",
      familleRisque: "Humidité / défaut d'isolement / électrisation",
      criticite: "Critique",
    ),
    "Éclairage normal": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 559",
      familleRisque: "Sécurité d'exploitation",
      criticite: "Majeure",
    ),
    "Éclairage de secours conforme": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – Partie 5-56",
      familleRisque: "Évacuation / continuité des installations de sécurité",
      criticite: "Majeure",
    ),
    "Ventilation / Climatisation": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 512.2",
      familleRisque: "Échauffement / conditions d'environnement",
      criticite: "Majeure",
    ),
    "Revêtement de sol isolant ou antidérapant": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 555",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Présence d'un revêtement diélectrique ou isolant au sol": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 555",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Mise à la terre de toutes les masses métalliques": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 542 et § 543",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Critique",
    ),
    "Présence de la terre du neutre": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 542 et § 543",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Critique",
    ),
    "Présence de la terre des masses": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 542 et § 543",
      familleRisque: "Électrisation / défaut de mise à la terre",
      criticite: "Critique",
    ),
    "Continuité des liaisons équipotentielles principales": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 544",
      familleRisque: "Électrisation / défaut d'équipotentialité",
      criticite: "Critique",
    ),

    // --- CONDITIONS D'EXPLOITATION BT ---
    "Accès réservé au personnel habilité (habilitation électrique à jour)": DispositionMetadata(
      referenceNormative: "NF C 18-510",
      familleRisque: "Sécurité des interventions / risque électrique",
      criticite: "Majeure",
    ),
    "Présence d'un dispositif de mise hors tension générale du local": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 462, § 465 et § 537",
      familleRisque: "Sécurité des interventions / arrêt d'urgence",
      criticite: "Critique",
    ),
    "Présence et accessibilité des EPI électriques (gants, visière, tapis)": DispositionMetadata(
      referenceNormative: "NF C 18-510",
      familleRisque: "Sécurité des interventions / risque électrique",
      criticite: "Majeure",
    ),
    "Zone dégagée et propre, sans obstruction des voies d'accès": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 513",
      familleRisque: "Accès / exploitation / intervention",
      criticite: "Majeure",
    ),
    "Absence de stockage de matériaux inflammables": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 421, § 422 et § 527",
      familleRisque: "Incendie / propagation du feu",
      criticite: "Majeure",
    ),
    "Accès permanent aux dispositifs de coupure d'urgence": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 462, § 465 et § 537",
      familleRisque: "Sécurité des interventions / arrêt d'urgence",
      criticite: "Critique",
    ),
    "Absence de pièces nues sous tension accessibles": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 411 et Annexe 41A",
      familleRisque: "Électrisation / électrocution",
      criticite: "Critique",
    ),
    "Présence d'un plan d'intervention et de consignation affiché": DispositionMetadata(
      referenceNormative: "NF C 18-510",
      familleRisque: "Sécurité des interventions / risque électrique",
      criticite: "Majeure",
    ),
    "Disponibilité et mise à jour du schéma unifilaire": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 514",
      familleRisque: "Erreur d'exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Traçabilité des opérations de maintenance et des vérifications": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 561",
      familleRisque: "Évacuation / sécurité incendie",
      criticite: "Majeure",
    ),
    "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible": DispositionMetadata(
      referenceNormative: "NF C 18-510",
      familleRisque: "Sécurité des interventions / risque électrique",
      criticite: "Majeure",
    ),
    "Extincteur CO₂ disponible et vérifié (date de validité à jour)": DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 514",
      familleRisque: "Erreur d'exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Disponibilité d'une procédure de consignation électrique": DispositionMetadata(
      referenceNormative: "NF C 18-510",
      familleRisque: "Sécurité des interventions / risque électrique",
      criticite: "Majeure",
    ),
  };

  static final Map<String, String> _btDispositionsTitleAliases = {
    _normalizeKey("Accessibilité du local et dégagement permanent des accès"):
        "Accessibilité du local et dégagement permanent devant les tableaux",
    _normalizeKey("Obturation coupe-feu des traversées de câbles et canalisations"):
        "Obturation des traversées et maintien du degré coupe-feu des parois",
    _normalizeKey("Présence et lisibilité des consignes de sécurité et plaques de danger"):
        "Présence et lisibilité des consignes de sécurité",
    _normalizeKey("Absence de traces d'humidité, corrosion ou condensation"):
        "Absence d'infiltration d'eau, humidité ou condensation",
    _normalizeKey("Présence d'un éclairage de sécurité permettant les manœuvres et l'évacuation"):
        "Éclairage de secours conforme",
    _normalizeKey("État et continuité des liaisons équipotentielles du local"):
        "Continuité des liaisons équipotentielles principales",
  };

  static final Map<String, String> _btConditionsTitleAliases = {
    _normalizeKey("Présence de stockage de matériaux inflammables"):
        "Absence de stockage de matériaux inflammables",
    _normalizeKey("Disponibilité et mise à jour du schéma unifilaire de l'installation"):
        "Disponibilité et mise à jour du schéma unifilaire",
    _normalizeKey("Affichage des consignes de manœuvre, secours et premiers soins"):
        "Présence d'un plan d'intervention et de consignation affiché",
    _normalizeKey("Disponibilité du matériel de mise à la terre et en court-circuit"):
        "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible",
  };

  /// Assure l'exhaustivité et l'ordonnancement exact des points de contrôle pour un local Groupe Électrogène.
  static void ensureCompleteGELocalChecklists({
    required List<ElementControle> dispositionsConstructives,
    required List<ElementControle> conditionsExploitation,
  }) {
    // --- 1. MIGRATION DES DISPOSITIONS CONSTRUCTIVES GE ---
    final existingDispMap = <String, ElementControle>{};
    for (final el in dispositionsConstructives) {
      final normKey = _normalizeKey(el.elementControle);
      String targetTitle = el.elementControle;

      if (_geDispositionsTitleAliases.containsKey(normKey)) {
        targetTitle = _geDispositionsTitleAliases[normKey]!;
      } else {
        for (final refTitle in allGEDispositionsPoints) {
          if (_normalizeKey(refTitle) == normKey) {
            targetTitle = refTitle;
            break;
          }
        }
      }

      el.elementControle = targetTitle;
      final targetKey = _normalizeKey(targetTitle);

      if (!existingDispMap.containsKey(targetKey) ||
          (el.conforme != null && existingDispMap[targetKey]?.conforme == null) ||
          (el.observation?.isNotEmpty == true && existingDispMap[targetKey]?.observation?.isEmpty == true)) {
        existingDispMap[targetKey] = el;
      }
    }

    dispositionsConstructives.clear();
    for (final refTitle in allGEDispositionsPoints) {
      final targetKey = _normalizeKey(refTitle);
      if (existingDispMap.containsKey(targetKey)) {
        final el = existingDispMap[targetKey]!;
        el.elementControle = refTitle;
        dispositionsConstructives.add(el);
      } else {
        dispositionsConstructives.add(
          ElementControle(
            elementControle: refTitle,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }

    // --- 2. MIGRATION DES CONDITIONS D'EXPLOITATION GE ---
    final existingCondMap = <String, ElementControle>{};
    for (final el in conditionsExploitation) {
      final normKey = _normalizeKey(el.elementControle);
      String targetTitle = el.elementControle;

      if (_geConditionsTitleAliases.containsKey(normKey)) {
        targetTitle = _geConditionsTitleAliases[normKey]!;
      } else {
        for (final refTitle in allGEConditionsPoints) {
          if (_normalizeKey(refTitle) == normKey) {
            targetTitle = refTitle;
            break;
          }
        }
      }

      el.elementControle = targetTitle;
      final targetKey = _normalizeKey(targetTitle);

      if (!existingCondMap.containsKey(targetKey) ||
          (el.conforme != null && existingCondMap[targetKey]?.conforme == null) ||
          (el.observation?.isNotEmpty == true && existingCondMap[targetKey]?.observation?.isEmpty == true)) {
        existingCondMap[targetKey] = el;
      }
    }

    conditionsExploitation.clear();
    for (final refTitle in allGEConditionsPoints) {
      final targetKey = _normalizeKey(refTitle);
      if (existingCondMap.containsKey(targetKey)) {
        final el = existingCondMap[targetKey]!;
        el.elementControle = refTitle;
        conditionsExploitation.add(el);
      } else {
        conditionsExploitation.add(
          ElementControle(
            elementControle: refTitle,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }
  }

  /// Assure l'exhaustivité et l'ordonnancement exact des points de contrôle pour un local Basse Tension (BT).
  static void ensureCompleteBTLocalChecklists({
    required List<ElementControle> dispositionsConstructives,
    required List<ElementControle> conditionsExploitation,
  }) {
    // --- 1. MIGRATION DES DISPOSITIONS CONSTRUCTIVES BT ---
    final existingDispMap = <String, ElementControle>{};
    for (final el in dispositionsConstructives) {
      final normKey = _normalizeKey(el.elementControle);
      String targetTitle = el.elementControle;

      if (_btDispositionsTitleAliases.containsKey(normKey)) {
        targetTitle = _btDispositionsTitleAliases[normKey]!;
      } else {
        for (final refTitle in allBTDispositionsPoints) {
          if (_normalizeKey(refTitle) == normKey) {
            targetTitle = refTitle;
            break;
          }
        }
      }

      el.elementControle = targetTitle;
      final targetKey = _normalizeKey(targetTitle);

      if (!existingDispMap.containsKey(targetKey) ||
          (el.conforme != null && existingDispMap[targetKey]?.conforme == null) ||
          (el.observation?.isNotEmpty == true && existingDispMap[targetKey]?.observation?.isEmpty == true)) {
        existingDispMap[targetKey] = el;
      }
    }

    dispositionsConstructives.clear();
    for (final refTitle in allBTDispositionsPoints) {
      final targetKey = _normalizeKey(refTitle);
      final meta = getMetadata(refTitle, localType: 'LOCAL_BT');
      if (existingDispMap.containsKey(targetKey)) {
        final el = existingDispMap[targetKey]!;
        el.elementControle = refTitle;
        if (meta != null) {
          el.referenceNormative = meta.referenceNormative;
          el.familleRisque = meta.familleRisque;
          el.criticite = meta.criticite;
        }
        dispositionsConstructives.add(el);
      } else {
        dispositionsConstructives.add(
          ElementControle(
            elementControle: refTitle,
            referenceNormative: meta?.referenceNormative,
            familleRisque: meta?.familleRisque,
            criticite: meta?.criticite,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }

    // --- 2. MIGRATION DES CONDITIONS D'EXPLOITATION BT ---
    final existingCondMap = <String, ElementControle>{};
    for (final el in conditionsExploitation) {
      final normKey = _normalizeKey(el.elementControle);
      String targetTitle = el.elementControle;

      if (_btConditionsTitleAliases.containsKey(normKey)) {
        targetTitle = _btConditionsTitleAliases[normKey]!;
      } else {
        for (final refTitle in allBTConditionsPoints) {
          if (_normalizeKey(refTitle) == normKey) {
            targetTitle = refTitle;
            break;
          }
        }
      }

      el.elementControle = targetTitle;
      final targetKey = _normalizeKey(targetTitle);

      if (!existingCondMap.containsKey(targetKey) ||
          (el.conforme != null && existingCondMap[targetKey]?.conforme == null) ||
          (el.observation?.isNotEmpty == true && existingCondMap[targetKey]?.observation?.isEmpty == true)) {
        existingCondMap[targetKey] = el;
      }
    }

    conditionsExploitation.clear();
    for (final refTitle in allBTConditionsPoints) {
      final targetKey = _normalizeKey(refTitle);
      final meta = getMetadata(refTitle, localType: 'LOCAL_BT');
      if (existingCondMap.containsKey(targetKey)) {
        final el = existingCondMap[targetKey]!;
        el.elementControle = refTitle;
        if (meta != null) {
          el.referenceNormative = meta.referenceNormative;
          el.familleRisque = meta.familleRisque;
          el.criticite = meta.criticite;
        }
        conditionsExploitation.add(el);
      } else {
        conditionsExploitation.add(
          ElementControle(
            elementControle: refTitle,
            referenceNormative: meta?.referenceNormative,
            familleRisque: meta?.familleRisque,
            criticite: meta?.criticite,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }
  }

  /// Liste officielle des 29 points de vérification pour les Coffrets / Armoires / TGBT
  static const List<String> allCoffretPoints = [
    "Emplacement / Dégagement autour",
    "Compatibilité du degré IP/IK avec l'environnement d'installation",
    "Présence d'écrans ou plastrons empêchant l'accès aux parties actives",
    "Continuité de la mise à la terre des portes et parties métalliques",
    "Réserve disponible et obturation des emplacements non utilisés",
    "Présence d'une coupure générale clairement identifiée et accessible",
    "Identification complète des circuits",
    "Respect code couleur des câbles",
    "Présence et lisibilité du schéma unifilaire et du repérage des départs",
    "Etat du Coffret / Armoire / TGBT",
    "Câblage",
    "Répartiteur de circuit",
    "Absence de surcharge des répartiteurs, borniers et jeux de barres",
    "État, fixation et protection des jeux de barres",
    "Contrôle thermographique des connexions, et protections",
    "Répartition des circuits",
    "Continuité du conducteur de protection (PE)",
    "Contrôle du courant dans le conducteur neutre",
    "Protection contre les contacts directs (capots, caches, bornes protégées)",
    "Présence et fonctionnement des dispositifs de protection",
    "Adéquation des dispositifs de protection",
    "Section des câbles d'alimentation adaptée au courant nominal des disjoncteurs associés",
    "Coordination entre disjoncteurs et contacteurs",
    "Coordination entre disjoncteurs",
    "Protection contre les contacts indirects",
    "Sélectivité et coordination des protections (montée sélective des calibres)",
    "Présence et conformité du dispositif de protection contre les surtensions (parafoudre)",
    "Coordination du parafoudre avec les protections amont et aval",
    "Présence de double alimentation électrique",
  ];

  /// Registre spécifique des métadonnées pour Coffret / Armoire / TGBT
  static final Map<String, DispositionMetadata> _coffretRegistry = {
    "Emplacement / Dégagement autour": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 513",
      familleRisque: "Accès / exploitation / intervention",
      criticite: "Majeure",
    ),
    "Compatibilité du degré IP/IK avec l'environnement d'installation": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 512.2",
      familleRisque: "Contact électrique / influences externes / protection mécanique",
      criticite: "Majeure",
    ),
    "Présence d'écrans ou plastrons empêchant l'accès aux parties actives": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 411 et Annexe 41A",
      familleRisque: "Électrisation / électrocution",
      criticite: "Critique",
    ),
    "Continuité de la mise à la terre des portes et parties métalliques": const DispositionMetadata(
      referenceNormative: "NF C 15-100-7-729:2024 – § 729",
      familleRisque: "Sécurité d'exploitation",
      criticite: "Majeure",
    ),
    "Réserve disponible et obturation des emplacements non utilisés": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 411 et Annexe 41A",
      familleRisque: "Électrisation / contact avec parties actives",
      criticite: "Critique",
    ),
    "Présence d'une coupure générale clairement identifiée et accessible": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 462, § 465 et § 537",
      familleRisque: "Sécurité des interventions / arrêt d'urgence",
      criticite: "Critique",
    ),
    "Identification complète des circuits": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 514",
      familleRisque: "Erreur d'exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Respect code couleur des câbles": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 514",
      familleRisque: "Erreur d'exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Présence et lisibilité du schéma unifilaire et du repérage des départs": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 514",
      familleRisque: "Erreur d'exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Etat du Coffret / Armoire / TGBT": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – Annexe 41B",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Câblage": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – Partie 5-52",
      familleRisque: "Dégradation des canalisations / échauffement / court-circuit",
      criticite: "Majeure",
    ),
    "Répartiteur de circuit": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 526 et § 533",
      familleRisque: "Échauffement / surcharge / incendie",
      criticite: "Critique",
    ),
    "Absence de surcharge des répartiteurs, borniers et jeux de barres": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 526 et § 533",
      familleRisque: "Échauffement / surcharge / incendie",
      criticite: "Critique",
    ),
    "État, fixation et protection des jeux de barres": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 526 et § 533",
      familleRisque: "Échauffement / surcharge / incendie",
      criticite: "Critique",
    ),
    "Contrôle thermographique des connexions, et protections": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 6.6.4.3.2",
      familleRisque: "Incendie / échauffement",
      criticite: "Majeure",
    ),
    "Répartition des circuits": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 314",
      familleRisque: "Continuité de service / surcharge / exploitation",
      criticite: "Majeure",
    ),
    "Continuité du conducteur de protection (PE)": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 543 et § 6.4.3.2",
      familleRisque: "Électrisation / défaut de continuité de protection",
      criticite: "Critique",
    ),
    "Contrôle du courant dans le conducteur neutre": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 524.2",
      familleRisque: "Échauffement du neutre / harmoniques",
      criticite: "Majeure",
    ),
    "Protection contre les contacts directs (capots, caches, bornes protégées)": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 411 et Annexe 41A",
      familleRisque: "Électrisation / électrocution",
      criticite: "Critique",
    ),
    "Présence et fonctionnement des dispositifs de protection": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 430 à § 436 et § 533",
      familleRisque: "Surintensité / court-circuit / incendie",
      criticite: "Critique",
    ),
    "Adéquation des dispositifs de protection": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 430 à § 436 et § 533",
      familleRisque: "Surintensité / court-circuit / incendie",
      criticite: "Critique",
    ),
    "Section des câbles d'alimentation adaptée au courant nominal des disjoncteurs associés": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 523, § 524 et § 433",
      familleRisque: "Incendie / échauffement / surcharge des conducteurs",
      criticite: "Critique",
    ),
    "Coordination entre disjoncteurs et contacteurs": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 536",
      familleRisque: "Défaut de coordination / perte de sélectivité",
      criticite: "Majeure",
    ),
    "Coordination entre disjoncteurs": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 536",
      familleRisque: "Défaut de coordination / perte de sélectivité",
      criticite: "Majeure",
    ),
    "Protection contre les contacts indirects": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 411",
      familleRisque: "Électrisation / électrocution",
      criticite: "Critique",
    ),
    "Sélectivité et coordination des protections (montée sélective des calibres)": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 536",
      familleRisque: "Défaut de coordination / perte de sélectivité",
      criticite: "Majeure",
    ),
    "Présence et conformité du dispositif de protection contre les surtensions (parafoudre)": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 443 et § 534",
      familleRisque: "Surtension / foudre / détérioration des équipements",
      criticite: "Majeure",
    ),
    "Coordination du parafoudre avec les protections amont et aval": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 443 et § 534",
      familleRisque: "Surtension / foudre / détérioration des équipements",
      criticite: "Majeure",
    ),
    "Présence de double alimentation électrique": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 465",
      familleRisque: "Sécurité des interventions / arrêt d'urgence",
      criticite: "Majeure",
    ),
  };

  /// Table d'alias pour les points de vérification Coffrets / Armoires / TGBT
  static final Map<String, String> _coffretTitleAliases = {
    _normalizeKey("Dégagement autour de l'équipement"):
        "Emplacement / Dégagement autour",
    _normalizeKey("Dégagement autour du coffret / armoire"):
        "Emplacement / Dégagement autour",
    _normalizeKey("Protection IP/IK adaptée au local d'installation"):
        "Compatibilité du degré IP/IK avec l'environnement d'installation",
    _normalizeKey("Protection IP/IK adaptée au local"):
        "Compatibilité du degré IP/IK avec l'environnement d'installation",
    _normalizeKey("Présence d'écrans ou plastrons (IP2X/IP4X)"):
        "Présence d'écrans ou plastrons empêchant l'accès aux parties actives",
    _normalizeKey("Continuité de masse des portes et parties métalliques"):
        "Continuité de la mise à la terre des portes et parties métalliques",
    _normalizeKey("Continuité de masse"):
        "Continuité de la mise à la terre des portes et parties métalliques",
    _normalizeKey("Obturation des réservations et espaces libres"):
        "Réserve disponible et obturation des emplacements non utilisés",
    _normalizeKey("Présence d'un organe de coupure générale accessible"):
        "Présence d'une coupure générale clairement identifiée et accessible",
    _normalizeKey("Présence d'un organe de coupure générale"):
        "Présence d'une coupure générale clairement identifiée et accessible",
    _normalizeKey("Présence et fonctionnement des dispositifs de coupure / arrêt d'urgence"):
        "Présence d'une coupure générale clairement identifiée et accessible",
    _normalizeKey("Identification des départ/circuits"):
        "Identification complète des circuits",
    _normalizeKey("Identification des départs"):
        "Identification complète des circuits",
    _normalizeKey("Repérage des conducteurs / code couleur"):
        "Respect code couleur des câbles",
    _normalizeKey("Schéma électrique / unifilaire disponible sur site"):
        "Présence et lisibilité du schéma unifilaire et du repérage des départs",
    _normalizeKey("Schéma électrique disponible"):
        "Présence et lisibilité du schéma unifilaire et du repérage des départs",
    _normalizeKey("Etat du coffret / Armoire"):
        "Etat du Coffret / Armoire / TGBT",
    _normalizeKey("Etat du coffret"):
        "Etat du Coffret / Armoire / TGBT",
    _normalizeKey("Propreté et état général du coffret"):
        "Etat du Coffret / Armoire / TGBT",
    _normalizeKey("État des connexions et échauffement visuel"):
        "Contrôle thermographique des connexions, et protections",
    _normalizeKey("Section des câbles de départs adaptée au courant nominal des disjoncteurs associés"):
        "Section des câbles d'alimentation adaptée au courant nominal des disjoncteurs associés",
    _normalizeKey("Présence d'un parafoudre et état du voyant de d'état"):
        "Présence et conformité du dispositif de protection contre les surtensions (parafoudre)",
    _normalizeKey("Présence d'un parafoudre"):
        "Présence et conformité du dispositif de protection contre les surtensions (parafoudre)",
  };

  /// Obtenir la métadonnée normative pour un point de coffret ou d'inverseur
  static DispositionMetadata? getCoffretMetadata(String pointVerification, {String? coffretType}) {
    if (coffretType == 'INVERSEUR') {
      if (_inverseurRegistry.containsKey(pointVerification)) {
        return _inverseurRegistry[pointVerification];
      }
      final normKey = _normalizeKey(pointVerification);
      for (final entry in _inverseurRegistry.entries) {
        if (_normalizeKey(entry.key) == normKey) {
          return entry.value;
        }
      }
    }

    if (_coffretRegistry.containsKey(pointVerification)) {
      return _coffretRegistry[pointVerification];
    }
    final normKey = _normalizeKey(pointVerification);
    for (final entry in _coffretRegistry.entries) {
      if (_normalizeKey(entry.key) == normKey) {
        return entry.value;
      }
    }

    if (_inverseurRegistry.containsKey(pointVerification)) {
      return _inverseurRegistry[pointVerification];
    }
    for (final entry in _inverseurRegistry.entries) {
      if (_normalizeKey(entry.key) == normKey) {
        return entry.value;
      }
    }

    return null;
  }

  /// Liste officielle des 31 points de vérification pour l'Inverseur de Source
  static const List<String> allInverseurPoints = [
    "Emplacement / Dégagement autour",
    "Protection IP/IK adaptée au local d'installation",
    "Interverrouillage empêchant le couplage intempestif des deux sources",
    "Identification complète des circuits",
    "Respect code couleur des câbles",
    "Identification claire des deux sources et de la source prioritaire",
    "Signalisation de la position des sources et de l'état de l'inverseur",
    "Etat du coffret / Armoire",
    "Câblage",
    "Répartiteur de circuit",
    "Dispositif de connexion",
    "Serrage et état des connexions contrôlés",
    "Répartition des circuits",
    "Continuité du conducteur de protection (PE)",
    "Protection contre les contacts directs (capots, caches, bornes protégées)",
    "Présence et fonctionnement des dispositifs de protection",
    "Adéquation des dispositifs de protection",
    "Section des câbles d'alimentation adaptée au courant nominal des disjoncteurs associés",
    "Section des câbles de départs adaptée au courant nominal des disjoncteurs associés",
    "Calibre des disjoncteurs / fusibles adapté à la section des câbles et au courant de court-circuit présumé (Icc)",
    "Coordination entre disjoncteurs et contacteurs",
    "Coordination entre disjoncteurs",
    "Protection contre les contacts indirects",
    "Sélectivité et coordination des protections (montée sélective des calibres)",
    "Pouvoir de coupure et courant assigné adaptés à l'installation",
    "Protection contre les retours de tension vers une source indisponible",
    "Présence et fonctionnement des dispositifs de coupure / arrêt d'urgence",
    "Fonctionnement du transfert automatique et du retour à la source normale",
    "Temps de transfert compatible avec les équipements alimentés",
    "Commande manuelle de secours fonctionnelle",
    "Absence d'échauffement anormal par thermographie infrarouge",
  ];

  /// Registre spécifique des métadonnées pour Inverseur de Source
  static final Map<String, DispositionMetadata> _inverseurRegistry = {
    "Emplacement / Dégagement autour": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 513",
      familleRisque: "Accès / exploitation / intervention",
      criticite: "Majeure",
    ),
    "Protection IP/IK adaptée au local d'installation": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 512.2",
      familleRisque: "Protection mécanique / pénétration corps solides-liquides",
      criticite: "Majeure",
    ),
    "Interverrouillage empêchant le couplage intempestif des deux sources": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et § 536",
      familleRisque: "Couplage intempestif / retour de tension / perte de continuité",
      criticite: "Critique",
    ),
    "Identification complète des circuits": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 514",
      familleRisque: "Erreur d'exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Respect code couleur des câbles": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 514",
      familleRisque: "Erreur d'exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Identification claire des deux sources et de la source prioritaire": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 514",
      familleRisque: "Erreur d'exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Signalisation de la position des sources et de l'état de l'inverseur": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 514",
      familleRisque: "Erreur d'exploitation / maintenance",
      criticite: "Majeure",
    ),
    "Etat du coffret / Armoire": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – Annexe 41B",
      familleRisque: "Sécurité / conformité réglementaire",
      criticite: "Majeure",
    ),
    "Câblage": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – Partie 5-52",
      familleRisque: "Dégradation des canalisations / échauffement / court-circuit",
      criticite: "Majeure",
    ),
    "Répartiteur de circuit": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 526 et § 533",
      familleRisque: "Échauffement / surcharge / incendie",
      criticite: "Critique",
    ),
    "Dispositif de connexion": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 465",
      familleRisque: "Sécurité des interventions / arrêt d'urgence",
      criticite: "Majeure",
    ),
    "Serrage et état des connexions contrôlés": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 526",
      familleRisque: "Échauffement / mauvais contact / incendie",
      criticite: "Majeure",
    ),
    "Répartition des circuits": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 314",
      familleRisque: "Continuité de service / surcharge / exploitation",
      criticite: "Majeure",
    ),
    "Continuité du conducteur de protection (PE)": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 543 et § 6.4.3.2",
      familleRisque: "Électrisation / défaut de continuité de protection",
      criticite: "Critique",
    ),
    "Protection contre les contacts directs (capots, caches, bornes protégées)": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 411 et Annexe 41A",
      familleRisque: "Électrisation / électrocution",
      criticite: "Critique",
    ),
    "Présence et fonctionnement des dispositifs de protection": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 430 à § 436 et § 533",
      familleRisque: "Surintensité / court-circuit / incendie",
      criticite: "Critique",
    ),
    "Adéquation des dispositifs de protection": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 430 à § 436 et § 533",
      familleRisque: "Surintensité / court-circuit / incendie",
      criticite: "Critique",
    ),
    "Section des câbles d'alimentation adaptée au courant nominal des disjoncteurs associés": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 523, § 524 et § 433",
      familleRisque: "Incendie / échauffement / surcharge des conducteurs",
      criticite: "Critique",
    ),
    "Section des câbles de départs adaptée au courant nominal des disjoncteurs associés": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 523, § 524 et § 433",
      familleRisque: "Incendie / échauffement / surcharge des conducteurs",
      criticite: "Critique",
    ),
    "Calibre des disjoncteurs / fusibles adapté à la section des câbles et au courant de court-circuit présumé (Icc)": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 523, § 524 et § 433",
      familleRisque: "Incendie / échauffement / surcharge des conducteurs",
      criticite: "Critique",
    ),
    "Coordination entre disjoncteurs et contacteurs": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 536",
      familleRisque: "Défaut de coordination / perte de sélectivité",
      criticite: "Majeure",
    ),
    "Coordination entre disjoncteurs": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 536",
      familleRisque: "Défaut de coordination / perte de sélectivité",
      criticite: "Majeure",
    ),
    "Protection contre les contacts indirects": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 411",
      familleRisque: "Électrisation / électrocution",
      criticite: "Critique",
    ),
    "Sélectivité et coordination des protections (montée sélective des calibres)": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 536",
      familleRisque: "Défaut de coordination / perte de sélectivité",
      criticite: "Majeure",
    ),
    "Pouvoir de coupure et courant assigné adaptés à l'installation": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 434",
      familleRisque: "Court-circuit / destruction de l'appareillage / incendie",
      criticite: "Critique",
    ),
    "Protection contre les retours de tension vers une source indisponible": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et § 536",
      familleRisque: "Couplage intempestif / retour de tension / perte de continuité",
      criticite: "Critique",
    ),
    "Présence et fonctionnement des dispositifs de coupure / arrêt d'urgence": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 462, § 465 et § 537",
      familleRisque: "Sécurité des interventions / arrêt d'urgence",
      criticite: "Critique",
    ),
    "Fonctionnement du transfert automatique et du retour à la source normale": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et § 536",
      familleRisque: "Couplage intempestif / retour de tension / perte de continuité",
      criticite: "Critique",
    ),
    "Temps de transfert compatible avec les équipements alimentés": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et § 536",
      familleRisque: "Couplage intempestif / retour de tension / perte de continuité",
      criticite: "Critique",
    ),
    "Commande manuelle de secours fonctionnelle": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 551 et § 536",
      familleRisque: "Couplage intempestif / retour de tension / perte de continuité",
      criticite: "Critique",
    ),
    "Absence d'échauffement anormal par thermographie infrarouge": const DispositionMetadata(
      referenceNormative: "NF C 15-100-1:2024 – § 6.6.4.3.2",
      familleRisque: "Incendie / échauffement",
      criticite: "Majeure",
    ),
  };

  /// Table d'alias pour l'Inverseur de Source
  static final Map<String, String> _inverseurTitleAliases = {
    _normalizeKey("Protection IP/IK adaptée au local"):
        "Protection IP/IK adaptée au local d'installation",
    _normalizeKey("Compatibilité du degré IP/IK avec l'environnement d'installation"):
        "Protection IP/IK adaptée au local d'installation",
    _normalizeKey("Interverrouillage mécanique et électrique entre les deux sources"):
        "Interverrouillage empêchant le couplage intempestif des deux sources",
    _normalizeKey("Repérage des conducteurs / code couleur"):
        "Respect code couleur des câbles",
    _normalizeKey("Identification claire de la source prioritaire et de la source de secours"):
        "Identification claire des deux sources et de la source prioritaire",
    _normalizeKey("Signalisation claire de la position de l'inverseur (Normal / Secours)"):
        "Signalisation de la position des sources et de l'état de l'inverseur",
    _normalizeKey("Etat du coffret / Armoire"):
        "Etat du coffret / Armoire",
    _normalizeKey("Propreté et état général du coffret"):
        "Etat du coffret / Armoire",
    _normalizeKey("Serrage des connexions de puissance"):
        "Serrage et état des connexions contrôlés",
    _normalizeKey("Contrôle thermographique des connexions, et protections"):
        "Absence d'échauffement anormal par thermographie infrarouge",
    _normalizeKey("Thermographie infrarouge des connexions"):
        "Absence d'échauffement anormal par thermographie infrarouge",
  };

  /// Assure l'exhaustivité, la migration et l'ordonnancement exact (1 à 31) pour l'Inverseur de Source
  static void ensureCompleteInverseurChecklist(List<PointVerification> points) {
    final existingMap = <String, PointVerification>{};
    for (final pt in points) {
      final normKey = _normalizeKey(pt.pointVerification);
      String targetTitle = pt.pointVerification;

      if (_inverseurTitleAliases.containsKey(normKey)) {
        targetTitle = _inverseurTitleAliases[normKey]!;
      } else {
        for (final refTitle in allInverseurPoints) {
          if (_normalizeKey(refTitle) == normKey) {
            targetTitle = refTitle;
            break;
          }
        }
      }

      pt.pointVerification = targetTitle;
      final targetKey = _normalizeKey(targetTitle);

      final confNorm = pt.conformite.toLowerCase().trim();
      final isExistingNA = confNorm == 'na' || confNorm == 'non_applicable' || confNorm == 'sans_objet' || confNorm == 'n/a' || confNorm == 'sans objet';

      if (!existingMap.containsKey(targetKey) ||
          (!isExistingNA && (existingMap[targetKey]?.conformite == 'Sans objet' || existingMap[targetKey]?.conformite == 'non_applicable')) ||
          ((pt.observation?.isNotEmpty == true || pt.observations?.isNotEmpty == true) &&
              existingMap[targetKey]?.observation?.isEmpty == true)) {
        existingMap[targetKey] = pt;
      }
    }

    points.clear();
    for (final refTitle in allInverseurPoints) {
      final targetKey = _normalizeKey(refTitle);
      final meta = getCoffretMetadata(refTitle, coffretType: 'INVERSEUR');
      if (existingMap.containsKey(targetKey)) {
        final pt = existingMap[targetKey]!;
        pt.pointVerification = refTitle;
        if (meta != null) {
          pt.referenceNormative = meta.referenceNormative;
          pt.familleRisque = meta.familleRisque;
          pt.criticite = meta.criticite;
        }
        points.add(pt);
      } else {
        points.add(
          PointVerification(
            pointVerification: refTitle,
            referenceNormative: meta?.referenceNormative,
            familleRisque: meta?.familleRisque,
            criticite: meta?.criticite,
            conformite: 'Sans objet',
          ),
        );
      }
    }
  }

  /// Assure l'exhaustivité, la migration et l'ordonnancement exact (1 à 29) des points de vérification d'un coffret / armoire / TGBT
  static void ensureCompleteCoffretChecklist(List<PointVerification> points) {
    final existingMap = <String, PointVerification>{};
    for (final pt in points) {
      final normKey = _normalizeKey(pt.pointVerification);
      String targetTitle = pt.pointVerification;

      if (_coffretTitleAliases.containsKey(normKey)) {
        targetTitle = _coffretTitleAliases[normKey]!;
      } else {
        for (final refTitle in allCoffretPoints) {
          if (_normalizeKey(refTitle) == normKey) {
            targetTitle = refTitle;
            break;
          }
        }
      }

      pt.pointVerification = targetTitle;
      final targetKey = _normalizeKey(targetTitle);

      final confNorm = pt.conformite.toLowerCase().trim();
      final isExistingNA = confNorm == 'na' || confNorm == 'non_applicable' || confNorm == 'sans_objet' || confNorm == 'n/a' || confNorm == 'sans objet';

      if (!existingMap.containsKey(targetKey) ||
          (!isExistingNA && (existingMap[targetKey]?.conformite == 'Sans objet' || existingMap[targetKey]?.conformite == 'non_applicable')) ||
          ((pt.observation?.isNotEmpty == true || pt.observations?.isNotEmpty == true) &&
              existingMap[targetKey]?.observation?.isEmpty == true)) {
        existingMap[targetKey] = pt;
      }
    }

    points.clear();
    for (final refTitle in allCoffretPoints) {
      final targetKey = _normalizeKey(refTitle);
      final meta = getCoffretMetadata(refTitle);
      if (existingMap.containsKey(targetKey)) {
        final pt = existingMap[targetKey]!;
        pt.pointVerification = refTitle;
        if (meta != null) {
          pt.referenceNormative = meta.referenceNormative;
          pt.familleRisque = meta.familleRisque;
          pt.criticite = meta.criticite;
        }
        points.add(pt);
      } else {
        points.add(
          PointVerification(
            pointVerification: refTitle,
            referenceNormative: meta?.referenceNormative,
            familleRisque: meta?.familleRisque,
            criticite: meta?.criticite,
            conformite: 'Sans objet',
          ),
        );
      }
    }
  }

  /// Liste officielle des 25 points de vérification des Dispositions Constructives
  static const List<String> allDispositionsConstructives = [
    "Le local est exclusivement réservé à l'usage électrique",
    'Signalisation visible "Local électrique – Accès réservé au personnel habilité"',
    "Dimensions",
    "Parois, plancher et plafond en matériaux non combustibles",
    "Présence d'une porte pleine, ouvrant vers l'extérieur, munie d'un dispositif anti-panique",
    "Verrouillage empêchant tout accès non autorisé",
    "Absence de communication directe avec les locaux à risque",
    "Absence de stockage d'objets non électriques",
    "Accessibilité du local et dégagement permanent des accès",
    "État et continuité des liaisons équipotentielles du local",
    "Présence et lisibilité des consignes de sécurité et plaques de danger",
    "Présence de canalisations étrangères",
    "Présence d'un dispositif empêchant l'entrée d'eau et les infiltrations",
    "Obturation coupe-feu des traversées de câbles et canalisations",
    "Absence de traces d'humidité, corrosion ou condensation",
    "Éclairage normal",
    "Éclairage de secours conforme",
    "Ventilation / Climatisation",
    "Compatibilité de la ventilation avec les équipements installés",
    "Présence d'un éclairage de sécurité permettant les manœuvres et l'évacuation",
    "Revêtement de sol isolant ou antidérapant",
    "Présence d'un revêtement diélectrique ou isolant au sol",
    "Mise à la terre de toutes les masses métalliques",
    "Présence de la terre du neutre",
    "Présence de la terre des masses",
  ];

  /// Liste officielle des 16 points de vérification des Conditions d'Exploitation et de Sécurité
  static const List<String> allConditionsExploitation = [
    "Accès réservé au personnel habilité (habilitation électrique à jour)",
    "Présence d'un dispositif de mise hors tension générale du local",
    "Présence et accessibilité des EPI électriques (gants, visière, tapis)",
    "Zone dégagée et propre, sans obstruction des voies d'accès",
    "Absence de stockage de matériaux inflammables",
    "Identification et condamnation des accès aux parties sous tension",
    "Présence d'un plan d'intervention et de consignation affiché",
    "Disponibilité et mise à jour du schéma unifilaire de l'installation",
    "Affichage des consignes de manœuvre, secours et premiers soins",
    "Disponibilité du matériel de mise à la terre et en court-circuit",
    "Disponibilité d'un dispositif de vérification d'absence de tension adapté à la MT",
    "Contrôle périodique et traçabilité des EPI et équipements de sécurité",
    "Matériel de consignation (cadenas, étiquettes, détecteur de tension) disponible",
    "Extincteur CO₂ disponible et vérifié (date de validité à jour)",
    "Tenue d'un registre des opérations, incidents et maintenances",
    "Présence d'une procédure de consignation et déconsignation",
  ];

  /// Liste officielle des 21 points de vérification de la Cellule Moyenne Tension
  static const List<String> allCellulePoints = [
    "Schéma unifilaire affiché dans le local",
    "Verrouillage mécanique",
    "Fonctionnement des interverrouillages électriques et mécaniques",
    "Etat et serrage apparent des connexions accessibles",
    "Identification et lisibilité des plaques signalétiques",
    "Cellule correctement posée et fixée",
    "Jonctions inter-cellules",
    "Canalisations et câbles d'arrivée / départ",
    "État général de l'enveloppe, absence de corrosion et déformation",
    "État des isolateurs et absence de traces d'amorçage",
    "Respect des distances de sécurité",
    "Voyants de position (O / F / T)",
    "Présence et état des dispositifs de détection / indication de tension",
    "Terre de protection (PE) reliée à chaque cellule",
    "Fonctionnement du sectionneur de terre et indication de position",
    "Continuité du circuit de terre de la cellule",
    "Conformité du pouvoir de coupure aux caractéristiques du réseau",
    "Etat des fusibles, disjoncteurs et relais de protection",
    "Réglage et coordination des protections MT",
    "Commande manuelle / motorisée",
    "Absence d'échauffement anormal contrôlée par thermographie infrarouge",
  ];

  /// Liste officielle des 26 points de vérification du Transformateur MT/BT
  static const List<String> allTransformateurPoints = [
    "Adapté au local et à la ventilation",
    "Vérification de la ventilation et des distances de dégagement",
    "État et dimensionnement du bac de rétention pour transformateur à huile",
    "Plaque signalétique (puissance, tension, couplage)",
    "Raccordement des câbles MT et BT",
    "État général du transformateur et absence de fuite d'huile",
    "État des traversées / isolateurs MT et BT",
    "État des connexions et serrage des bornes MT et BT",
    "Bac de rétention (pour transfo à huile)",
    "Niveau d'huile conforme pour transformateur immergé",
    "Essais diélectriques",
    "Écran de câble MT relié à la terre",
    "Distance entre transformateur",
    "État et fonctionnement des dispositifs de surveillance de température",
    "Compatibilité de la puissance du transformateur avec la charge",
    "Mise à la terre du neutre et de la carcasse",
    "Continuité de la mise à la terre de la cuve et des masses",
    "Protection contre les contacts directs",
    "Protection contre les surintensités",
    "Protection MT",
    "Protection BT (disjoncteur général, fusibles, relais thermique)",
    "Fonctionnement des protections DGPT2 / Buchholz lorsqu'elles existent",
    "Protection contre les surtensions côté MT et BT",
    "Contrôle thermographique des connexions, et protections",
    "Mesure de la résistance d'isolement des enroulements",
    "Contrôle du rapport de transformation et du couplage",
  ];

  /// Assure l'exhaustivité des points de contrôle pour un local (auto-migration silencieuse).
  /// Les points manquants sont ajoutés à leur position de référence avec estNA = true ("Sans objet").
  static void ensureCompleteLocalChecklists({
    required List<ElementControle> dispositionsConstructives,
    required List<ElementControle> conditionsExploitation,
  }) {
    final existingDispKeys = dispositionsConstructives
        .map((e) => _normalizeKey(e.elementControle))
        .toSet();
    for (final refTitle in allDispositionsConstructives) {
      if (!existingDispKeys.contains(_normalizeKey(refTitle))) {
        dispositionsConstructives.add(
          ElementControle(
            elementControle: refTitle,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }

    final existingCondKeys = conditionsExploitation
        .map((e) => _normalizeKey(e.elementControle))
        .toSet();
    for (final refTitle in allConditionsExploitation) {
      if (!existingCondKeys.contains(_normalizeKey(refTitle))) {
        conditionsExploitation.add(
          ElementControle(
            elementControle: refTitle,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }
  }

  /// Assure l'exhaustivité des points de contrôle pour une cellule (auto-migration silencieuse).
  static void ensureCompleteCelluleChecklist(List<ElementControle> elementsVerifies) {
    final existingMap = <String, ElementControle>{};
    for (final el in elementsVerifies) {
      final normKey = _normalizeKey(el.elementControle);
      existingMap[normKey] = el;
    }

    elementsVerifies.clear();
    for (final refTitle in allCellulePoints) {
      final targetKey = _normalizeKey(refTitle);
      final meta = getMetadata(refTitle, localType: 'LOCAL_POSTE_HTA');
      if (existingMap.containsKey(targetKey)) {
        final el = existingMap[targetKey]!;
        el.elementControle = refTitle;
        if (meta != null) {
          el.referenceNormative = meta.referenceNormative;
          el.familleRisque = meta.familleRisque;
          el.criticite = meta.criticite;
        }
        elementsVerifies.add(el);
      } else {
        elementsVerifies.add(
          ElementControle(
            elementControle: refTitle,
            referenceNormative: meta?.referenceNormative,
            familleRisque: meta?.familleRisque,
            criticite: meta?.criticite,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }
  }

  /// Assure l'exhaustivité des points de contrôle pour un transformateur (auto-migration silencieuse).
  static void ensureCompleteTransformateurChecklist(List<ElementControle> elementsVerifies) {
    final existingMap = <String, ElementControle>{};
    for (final el in elementsVerifies) {
      final normKey = _normalizeKey(el.elementControle);
      existingMap[normKey] = el;
    }

    elementsVerifies.clear();
    for (final refTitle in allTransformateurPoints) {
      final targetKey = _normalizeKey(refTitle);
      final meta = getMetadata(refTitle, localType: 'LOCAL_POSTE_HTA');
      if (existingMap.containsKey(targetKey)) {
        final el = existingMap[targetKey]!;
        el.elementControle = refTitle;
        if (meta != null) {
          el.referenceNormative = meta.referenceNormative;
          el.familleRisque = meta.familleRisque;
          el.criticite = meta.criticite;
        }
        elementsVerifies.add(el);
      } else {
        elementsVerifies.add(
          ElementControle(
            elementControle: refTitle,
            referenceNormative: meta?.referenceNormative,
            familleRisque: meta?.familleRisque,
            criticite: meta?.criticite,
            conforme: null,
            estNA: true,
            priorite: 3,
          ),
        );
      }
    }
  }

  /// Vérifie si le type de local correspond à un local de la famille Basse Tension (BT, TGBT, Onduleur, Électrique...)
  static bool isBTLocal(String? localType) {
    if (localType == null) return true;
    return localType == 'LOCAL_BT' ||
        localType == 'LOCAL_TGBT' ||
        localType == 'LOCAL_ONDULEUR' ||
        localType == 'LOCAL_ELECTRIQUE' ||
        localType == 'LOCAL_SERVEUR' ||
        localType == 'LOCAL_BATTERIES' ||
        localType == 'LOCAL_CHAUTERIE' ||
        localType == 'LOCAL_AUTRE' ||
        (!['LOCAL_TRANSFORMATEUR', 'LOCAL_MTBT', 'LOCAL_GROUPE_ELECTROGENE'].contains(localType));
  }

  /// Récupère la métadonnée par le libellé de l'élément de contrôle (avec recherche insensible aux majuscules/espaces)
  static DispositionMetadata? getMetadata(String elementControle, {String? localType}) {
    if (localType == 'LOCAL_GROUPE_ELECTROGENE') {
      if (_geRegistry.containsKey(elementControle)) {
        return _geRegistry[elementControle];
      }
      final normKey = _normalizeKey(elementControle);
      for (final entry in _geRegistry.entries) {
        if (_normalizeKey(entry.key) == normKey) {
          return entry.value;
        }
      }
    }

    if (isBTLocal(localType)) {
      if (_btRegistry.containsKey(elementControle)) {
        return _btRegistry[elementControle];
      }
      final normKey = _normalizeKey(elementControle);
      for (final entry in _btRegistry.entries) {
        if (_normalizeKey(entry.key) == normKey) {
          return entry.value;
        }
      }
    }

    if (_registry.containsKey(elementControle)) {
      return _registry[elementControle];
    }
    final normalizedKey = _normalizeKey(elementControle);
    for (final entry in _registry.entries) {
      if (_normalizeKey(entry.key) == normalizedKey) {
        return entry.value;
      }
    }

    if (localType != 'LOCAL_GROUPE_ELECTROGENE') {
      if (_geRegistry.containsKey(elementControle)) {
        return _geRegistry[elementControle];
      }
      final normKey = _normalizeKey(elementControle);
      for (final entry in _geRegistry.entries) {
        if (_normalizeKey(entry.key) == normKey) {
          return entry.value;
        }
      }
    }

    if (!isBTLocal(localType)) {
      if (_btRegistry.containsKey(elementControle)) {
        return _btRegistry[elementControle];
      }
      final normKey = _normalizeKey(elementControle);
      for (final entry in _btRegistry.entries) {
        if (_normalizeKey(entry.key) == normKey) {
          return entry.value;
        }
      }
    }

    return null;
  }

  static String _normalizeKey(String key) {
    return key.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
