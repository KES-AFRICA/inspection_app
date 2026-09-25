// lib/services/pdf/q18/q18_data_snapshot.dart

import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/models/description_installations.dart';
import 'package:inspec_app/models/foudre.dart';
import 'package:inspec_app/models/mesures_essais.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/models/renseignements_generaux.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/services/pdf/builders/pdf_photos_schemas_builder.dart';

/// Niveau de gravité standardisé selon le référentiel APSAD D18
enum Q18DangerLevel {
  dangerAvere, // Risque direct d'incendie/explosion
  degradation, // Risque différé / vieillissement
  horsPerimetreApsad, // Écart réglementaire ne relevant pas directement du feu/explosion
  pointSensible, // Observation / bonne pratique
}

extension Q18DangerLevelExtension on Q18DangerLevel {
  String get label {
    switch (this) {
      case Q18DangerLevel.dangerAvere:
        return 'Danger avéré';
      case Q18DangerLevel.degradation:
        return 'Dégradation';
      case Q18DangerLevel.horsPerimetreApsad:
        return 'Non-conformité hors périmètre APSAD';
      case Q18DangerLevel.pointSensible:
        return 'Point sensible / observation';
    }
  }
}

/// Élément individuel de danger constaté répertorié dans la section 10 du Q18
class Q18DangerItem {
  final int index;
  final String zone;
  final String repere;
  final String designation;
  final String dangerConstate;
  final String familleDeRisque;
  final Q18DangerLevel niveau;
  final List<String> photos;

  const Q18DangerItem({
    required this.index,
    required this.zone,
    required this.repere,
    required this.designation,
    required this.dangerConstate,
    required this.familleDeRisque,
    required this.niveau,
    this.photos = const [],
  });
}

/// Élément du périmètre de vérification (Section 5)
class Q18PerimetreItem {
  final String zone;
  final String repere;
  final String equipements;
  final bool isCouvert;
  final String motifExclusion;

  const Q18PerimetreItem({
    required this.zone,
    required this.repere,
    required this.equipements,
    required this.isCouvert,
    this.motifExclusion = '',
  });
}

/// Statut de disponibilité d'un document consulté (Section 6)
class Q18DocumentConsulteItem {
  final int index;
  final String titre;
  final bool isDisponible;
  final String? statutCustom;

  const Q18DocumentConsulteItem({
    required this.index,
    required this.titre,
    required this.isDisponible,
    this.statutCustom,
  });
}


/// Données quantitatives de la présentation des installations (Section 4)
class Q18InstallationsQuantities {
  final int nbLocauxTechniquesHTA;
  final int nbTransformateurs;
  final String transformateursPuissanceText;
  final int nbCellules;
  final int nbLocauxGE;
  final int nbGroupesElectrogenes;
  final String groupesPuissanceText;
  final int nbInverseurs;
  final int nbLocauxTechniquesBT;
  final int nbTGBT;
  final int nbArmoires;
  final int nbCoffrets;
  final bool presenceParatonnerre;
  final String presenceParafoudreInverseur;
  final String presenceParafoudreTGBT;
  final String presenceParafoudreArmoire;
  final String presenceParafoudreCoffret;
  final String presenceCentralePhotovoltaique;

  const Q18InstallationsQuantities({
    required this.nbLocauxTechniquesHTA,
    required this.nbTransformateurs,
    required this.transformateursPuissanceText,
    required this.nbCellules,
    required this.nbLocauxGE,
    required this.nbGroupesElectrogenes,
    required this.groupesPuissanceText,
    required this.nbInverseurs,
    required this.nbLocauxTechniquesBT,
    required this.nbTGBT,
    required this.nbArmoires,
    required this.nbCoffrets,
    required this.presenceParatonnerre,
    required this.presenceParafoudreInverseur,
    required this.presenceParafoudreTGBT,
    required this.presenceParafoudreArmoire,
    required this.presenceParafoudreCoffret,
    required this.presenceCentralePhotovoltaique,
  });
}

/// Snapshot immuable complet de toutes les données nécessaires à l'édition certifiée du rapport Q18
class Q18DataSnapshot {
  final Mission mission;
  final RenseignementsGeneraux? renseignements;
  final DescriptionInstallations? description;
  final AuditInstallationsElectriques? audit;
  final MesuresEssais? mesures;
  final List<Foudre>? foudre;
  final Verificateur? currentUser;

  // Métadonnées & numérotations officielles
  final String numeroRapportQ18;
  final String numeroRapportVerifElec;
  final DateTime dateRapportEffective;
  final DateTime dateProchaineVisite;
  final String lieuIntervention;
  // Identification & Métadonnées d'intervention normalisées
  final List<String> intervenantsNoms;
  final String dateVisiteLabel;
  final String dateVisiteValue;
  final String clientName;
  final String siteName;
  final String adresseSite;
  final String typeMission;

  // Données de sections
  final Q18InstallationsQuantities quantities;
  final List<Q18PerimetreItem> perimetreCouverts;
  final List<Q18PerimetreItem> exclusionsPerimetre;
  final List<Q18DocumentConsulteItem> documentsConsultes;
  final List<Q18DangerItem> dangers;

  // Synthèse statistique (Section 11)
  final int countDangerAvere;
  final int countDegradation;
  final int countHorsPerimetre;
  final int countPointSensible;

  // Avis global & Conclusion (Section 12)
  final bool hasDangerAvere;
  final String appreciationGlobale; // 'Satisfaisant', 'Acceptable', 'Insuffisant'
  final String avisSyntheseText;

  // Photos récapitulatives pour la planche photographique (Section 16)
  final List<PdfPhotoEntry> photoEntries;

  const Q18DataSnapshot({
    required this.mission,
    this.renseignements,
    this.description,
    this.audit,
    this.mesures,
    this.foudre,
    this.currentUser,
    required this.numeroRapportQ18,
    required this.numeroRapportVerifElec,
    required this.dateRapportEffective,
    required this.dateProchaineVisite,
    required this.lieuIntervention,
    this.intervenantsNoms = const [],
    this.dateVisiteLabel = 'Date de la visite de vérification',
    this.dateVisiteValue = '',
    this.clientName = '',
    this.siteName = '',
    this.adresseSite = '',
    this.typeMission = 'Vérification périodique',
    required this.quantities,
    required this.perimetreCouverts,
    required this.exclusionsPerimetre,
    required this.documentsConsultes,
    required this.dangers,
    required this.countDangerAvere,
    required this.countDegradation,
    required this.countHorsPerimetre,
    required this.countPointSensible,
    required this.hasDangerAvere,
    required this.appreciationGlobale,
    required this.avisSyntheseText,
    required this.photoEntries,
  });
}

