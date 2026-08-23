// lib/features/audit_installations/domain/entities/audit_installations_entities.dart

class ElementControleEntity {
  final String elementControle;
  final bool? conforme;
  final String? observation;
  final int? priorite;
  final List<String> photos;
  final String? referenceNormative;
  final bool estNA;
  final String? familleRisque;
  final String? criticite;

  const ElementControleEntity({
    required this.elementControle,
    this.conforme,
    this.observation,
    this.priorite,
    this.photos = const [],
    this.referenceNormative,
    this.estNA = false,
    this.familleRisque,
    this.criticite,
  });
}

class CelluleEntity {
  final String fonction;
  final String type;
  final String marqueModeleAnnee;
  final String tensionAssignee;
  final String pouvoirCoupure;
  final String numerotation;
  final String parafoudres;
  final List<ElementControleEntity> elementsVerifies;
  final List<String> photos;
  final String? gamme;
  final String? calibreDisjoncteur;
  final String? sectionCables;
  final String? natureReseau;
  final String? presenceIacm;
  final String? syncId;
  final List<ElementControleEntity>? observations;
  final String? nom;
  final String? photo;
  final String? repere;
  final String? marque;
  final String? modele;
  final String? annee;

  const CelluleEntity({
    required this.fonction,
    required this.type,
    required this.marqueModeleAnnee,
    required this.tensionAssignee,
    required this.pouvoirCoupure,
    required this.numerotation,
    required this.parafoudres,
    this.elementsVerifies = const [],
    this.photos = const [],
    this.gamme,
    this.calibreDisjoncteur,
    this.sectionCables,
    this.natureReseau,
    this.presenceIacm,
    this.syncId,
    this.observations,
    this.nom,
    this.photo,
    this.repere,
    this.marque,
    this.modele,
    this.annee,
  });

  CelluleEntity copyWith({
    String? fonction,
    String? type,
    String? marqueModeleAnnee,
    String? tensionAssignee,
    String? pouvoirCoupure,
    String? numerotation,
    String? parafoudres,
    List<ElementControleEntity>? elementsVerifies,
    List<String>? photos,
    String? gamme,
    String? calibreDisjoncteur,
    String? sectionCables,
    String? natureReseau,
    String? presenceIacm,
    String? syncId,
    List<ElementControleEntity>? observations,
    String? nom,
    String? photo,
    String? repere,
    String? marque,
    String? modele,
    String? annee,
  }) {
    return CelluleEntity(
      fonction: fonction ?? this.fonction,
      type: type ?? this.type,
      marqueModeleAnnee: marqueModeleAnnee ?? this.marqueModeleAnnee,
      tensionAssignee: tensionAssignee ?? this.tensionAssignee,
      pouvoirCoupure: pouvoirCoupure ?? this.pouvoirCoupure,
      numerotation: numerotation ?? this.numerotation,
      parafoudres: parafoudres ?? this.parafoudres,
      elementsVerifies: elementsVerifies ?? this.elementsVerifies,
      photos: photos ?? this.photos,
      gamme: gamme ?? this.gamme,
      calibreDisjoncteur: calibreDisjoncteur ?? this.calibreDisjoncteur,
      sectionCables: sectionCables ?? this.sectionCables,
      natureReseau: natureReseau ?? this.natureReseau,
      presenceIacm: presenceIacm ?? this.presenceIacm,
      syncId: syncId ?? this.syncId,
      observations: observations ?? this.observations,
      nom: nom ?? this.nom,
      photo: photo ?? this.photo,
      repere: repere ?? this.repere,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      annee: annee ?? this.annee,
    );
  }
}

class TransformateurMTBTEntity {
  final String typeTransformateur;
  final String marqueAnnee;
  final String puissanceAssignee;
  final String tensionPrimaireSecondaire;
  final String relaisBuchholz;
  final String typeRefroidissement;
  final String regimeNeutre;
  final List<ElementControleEntity> elementsVerifies;
  final List<String> photos;
  final String? calibreDisjoncteur;
  final String? sectionCables;
  final String? syncId;
  final List<ElementControleEntity>? observations;
  final String? intensiteNominale;
  final String? couplage;
  final String? typeReseau;
  final String? pccAmont;
  final String? puissanceUcc;
  final String? ik3Max;
  final String? nom;
  final String? photo;
  final String? repere;
  final String? marque;
  final String? anneeFabrication;

  const TransformateurMTBTEntity({
    required this.typeTransformateur,
    required this.marqueAnnee,
    required this.puissanceAssignee,
    required this.tensionPrimaireSecondaire,
    required this.relaisBuchholz,
    required this.typeRefroidissement,
    required this.regimeNeutre,
    this.elementsVerifies = const [],
    this.photos = const [],
    this.calibreDisjoncteur,
    this.sectionCables,
    this.syncId,
    this.observations,
    this.intensiteNominale,
    this.couplage,
    this.typeReseau,
    this.pccAmont,
    this.puissanceUcc,
    this.ik3Max,
    this.nom,
    this.photo,
    this.repere,
    this.marque,
    this.anneeFabrication,
  });

  TransformateurMTBTEntity copyWith({
    String? typeTransformateur,
    String? marqueAnnee,
    String? puissanceAssignee,
    String? tensionPrimaireSecondaire,
    String? relaisBuchholz,
    String? typeRefroidissement,
    String? regimeNeutre,
    List<ElementControleEntity>? elementsVerifies,
    List<String>? photos,
    String? calibreDisjoncteur,
    String? sectionCables,
    String? syncId,
    List<ElementControleEntity>? observations,
    String? intensiteNominale,
    String? couplage,
    String? typeReseau,
    String? pccAmont,
    String? puissanceUcc,
    String? ik3Max,
    String? nom,
    String? photo,
    String? repere,
    String? marque,
    String? anneeFabrication,
  }) {
    return TransformateurMTBTEntity(
      typeTransformateur: typeTransformateur ?? this.typeTransformateur,
      marqueAnnee: marqueAnnee ?? this.marqueAnnee,
      puissanceAssignee: puissanceAssignee ?? this.puissanceAssignee,
      tensionPrimaireSecondaire: tensionPrimaireSecondaire ?? this.tensionPrimaireSecondaire,
      relaisBuchholz: relaisBuchholz ?? this.relaisBuchholz,
      typeRefroidissement: typeRefroidissement ?? this.typeRefroidissement,
      regimeNeutre: regimeNeutre ?? this.regimeNeutre,
      elementsVerifies: elementsVerifies ?? this.elementsVerifies,
      photos: photos ?? this.photos,
      calibreDisjoncteur: calibreDisjoncteur ?? this.calibreDisjoncteur,
      sectionCables: sectionCables ?? this.sectionCables,
      syncId: syncId ?? this.syncId,
      observations: observations ?? this.observations,
      intensiteNominale: intensiteNominale ?? this.intensiteNominale,
      couplage: couplage ?? this.couplage,
      typeReseau: typeReseau ?? this.typeReseau,
      pccAmont: pccAmont ?? this.pccAmont,
      puissanceUcc: puissanceUcc ?? this.puissanceUcc,
      ik3Max: ik3Max ?? this.ik3Max,
      nom: nom ?? this.nom,
      photo: photo ?? this.photo,
      repere: repere ?? this.repere,
      marque: marque ?? this.marque,
      anneeFabrication: anneeFabrication ?? this.anneeFabrication,
    );
  }
}

class AlimentationEntity {
  final String typeProtection;
  final String? courbe;
  final String? ddr;
  final String pdcKA;
  final String calibre;
  final String sectionCable;
  final List<String> photos;
  final String source;

  const AlimentationEntity({
    required this.typeProtection,
    this.courbe = '',
    this.ddr,
    required this.pdcKA,
    required this.calibre,
    required this.sectionCable,
    this.photos = const [],
    this.source = '',
  });
}

class PointVerificationEntity {
  final String pointVerification;
  final String conformite; // "oui", "non", "non_acquis"
  final String? observation;
  final String? referenceNormative;
  final int? priorite;
  final List<String> photos;
  final List<ElementControleEntity>? observations;
  final String? criticite;
  final String? familleRisque;

  const PointVerificationEntity({
    required this.pointVerification,
    required this.conformite,
    this.observation,
    this.referenceNormative,
    this.priorite,
    this.photos = const [],
    this.observations,
    this.criticite,
    this.familleRisque,
  });
}

class ObservationLibreEntity {
  final String texte;
  final List<String> photos;
  final DateTime dateCreation;
  final DateTime dateModification;
  final String? pointVerificationKey;
  final String? referenceNormative;
  final String? familleRisque;
  final String? criticite;
  final bool isAutoLinked;

  const ObservationLibreEntity({
    required this.texte,
    this.photos = const [],
    required this.dateCreation,
    required this.dateModification,
    this.pointVerificationKey,
    this.referenceNormative,
    this.familleRisque,
    this.criticite,
    this.isAutoLinked = false,
  });
}

class CoffretArmoireEntity {
  final String qrCode;
  final String nom;
  final String type;
  final String? description;
  final String? repere;
  final bool zoneAtex;
  final String domaineTension;
  final bool identificationArmoire;
  final bool signalisationDanger;
  final bool presenceSchema;
  final bool presenceParafoudre;
  final bool verificationThermographie;
  final String? presenceDefautThermo;
  final bool? alimenteeParTransformateur;
  final bool? presenceCPI;
  final List<AlimentationEntity> alimentations;
  final AlimentationEntity? protectionTete;
  final List<PointVerificationEntity> pointsVerification;
  final List<ObservationLibreEntity> observationsLibres;
  final List<String> photos;
  final String? numeroEquipement;
  final String statut;
  final int currentStep;
  final List<String> photosExternes;
  final List<String> photosInternes;
  final List<ObservationLibreEntity> observationsParafoudre;
  final bool accessible;

  String? get effectivePresenceDefautThermo {
    if (!verificationThermographie) return null;
    if (presenceDefautThermo != null && presenceDefautThermo!.isNotEmpty) {
      return presenceDefautThermo;
    }
    return 'Sans objet';
  }

  const CoffretArmoireEntity({
    required this.qrCode,
    required this.nom,
    required this.type,
    this.description,
    this.repere,
    this.zoneAtex = false,
    this.domaineTension = '',
    this.identificationArmoire = false,
    this.signalisationDanger = false,
    this.presenceSchema = false,
    this.presenceParafoudre = false,
    this.verificationThermographie = false,
    this.presenceDefautThermo,
    this.alimenteeParTransformateur,
    this.presenceCPI,
    this.accessible = true,
    this.alimentations = const [],
    this.protectionTete,
    this.pointsVerification = const [],
    this.observationsLibres = const [],
    this.photos = const [],
    this.numeroEquipement,
    this.statut = 'incomplet',
    this.currentStep = 0,
    this.photosExternes = const [],
    this.photosInternes = const [],
    this.observationsParafoudre = const [],
  });
}

class MoyenneTensionLocalEntity {
  final String nom;
  final String type;
  final List<ElementControleEntity> dispositionsConstructives;
  final List<ElementControleEntity> conditionsExploitation;
  final List<CoffretArmoireEntity> coffrets;
  final List<ObservationLibreEntity> observationsLibres;
  final List<String> photos;
  final List<CelluleEntity> cellules;
  final List<TransformateurMTBTEntity> transformateurs;
  final bool accessible;
  final bool aReverifier;
  final bool isRiskZone;

  const MoyenneTensionLocalEntity({
    required this.nom,
    required this.type,
    this.dispositionsConstructives = const [],
    this.conditionsExploitation = const [],
    this.coffrets = const [],
    this.observationsLibres = const [],
    this.photos = const [],
    this.cellules = const [],
    this.transformateurs = const [],
    this.accessible = true,
    this.aReverifier = false,
    this.isRiskZone = false,
  });
}

class MoyenneTensionZoneEntity {
  final String nom;
  final String? description;
  final List<CoffretArmoireEntity> coffrets;
  final List<ObservationLibreEntity> observationsLibres;
  final List<String> photos;
  final List<MoyenneTensionLocalEntity> locaux;
  final String? classementZoneId;
  final bool isRiskZone;

  const MoyenneTensionZoneEntity({
    required this.nom,
    this.description,
    this.coffrets = const [],
    this.observationsLibres = const [],
    this.photos = const [],
    this.locaux = const [],
    this.classementZoneId,
    this.isRiskZone = false,
  });
}

class BasseTensionLocalEntity {
  final String nom;
  final String type;
  final List<ElementControleEntity> dispositionsConstructives;
  final List<ElementControleEntity> conditionsExploitation;
  final List<CoffretArmoireEntity> coffrets;
  final List<ObservationLibreEntity> observationsLibres;
  final List<String> photos;
  final bool accessible;
  final bool aReverifier;
  final List<CelluleEntity> cellules;
  final List<TransformateurMTBTEntity> transformateurs;
  final bool isRiskZone;

  const BasseTensionLocalEntity({
    required this.nom,
    required this.type,
    this.dispositionsConstructives = const [],
    this.conditionsExploitation = const [],
    this.coffrets = const [],
    this.observationsLibres = const [],
    this.photos = const [],
    this.accessible = true,
    this.aReverifier = false,
    this.cellules = const [],
    this.transformateurs = const [],
    this.isRiskZone = false,
  });
}

class BasseTensionZoneEntity {
  final String nom;
  final String? description;
  final List<BasseTensionLocalEntity> locaux;
  final List<CoffretArmoireEntity> coffretsDirects;
  final List<ObservationLibreEntity> observationsLibres;
  final List<String> photos;
  final String? classementZoneId;
  final bool isRiskZone;

  const BasseTensionZoneEntity({
    required this.nom,
    this.description,
    this.locaux = const [],
    this.coffretsDirects = const [],
    this.observationsLibres = const [],
    this.photos = const [],
    this.classementZoneId,
    this.isRiskZone = false,
  });
}

class AuditInstallationsElectriquesEntity {
  final String missionId;
  final DateTime updatedAt;
  final List<MoyenneTensionLocalEntity> moyenneTensionLocaux;
  final List<MoyenneTensionZoneEntity> moyenneTensionZones;
  final List<BasseTensionZoneEntity> basseTensionZones;
  final List<String> photos;

  const AuditInstallationsElectriquesEntity({
    required this.missionId,
    required this.updatedAt,
    this.moyenneTensionLocaux = const [],
    this.moyenneTensionZones = const [],
    this.basseTensionZones = const [],
    this.photos = const [],
  });
}
