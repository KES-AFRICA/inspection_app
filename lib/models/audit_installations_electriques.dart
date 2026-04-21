// audit_installations_electriques.dart
import 'package:hive/hive.dart';

part 'audit_installations_electriques.g.dart';

@HiveType(typeId: 3)
class AuditInstallationsElectriques extends HiveObject {
  @HiveField(0)
  String missionId;

  @HiveField(1)
  DateTime updatedAt;

  // MOYENNE TENSION
  @HiveField(2)
  List<MoyenneTensionLocal> moyenneTensionLocaux;

  @HiveField(3)
  List<MoyenneTensionZone> moyenneTensionZones;

  // BASSE TENSION
  @HiveField(4)
  List<BasseTensionZone> basseTensionZones;

  // PHOTOS GLOBALES DE L'AUDIT
  @HiveField(15)
  List<String> photos; // Chemins des photos générales de l'audit

  AuditInstallationsElectriques({
    required this.missionId,
    required this.updatedAt,
    List<MoyenneTensionLocal>? moyenneTensionLocaux,
    List<MoyenneTensionZone>? moyenneTensionZones,
    List<BasseTensionZone>? basseTensionZones,
    List<String>? photos,
  })  : moyenneTensionLocaux = moyenneTensionLocaux ?? [],
        moyenneTensionZones = moyenneTensionZones ?? [],
        basseTensionZones = basseTensionZones ?? [],
        photos = photos ?? [];

  factory AuditInstallationsElectriques.create(String missionId) {
    return AuditInstallationsElectriques(
      missionId: missionId,
      updatedAt: DateTime.now(),
      moyenneTensionLocaux: [],
      moyenneTensionZones: [],
      basseTensionZones: [],
      photos: [],
    );
  }
}

// STRUCTURES MOYENNE TENSION
@HiveType(typeId: 4)
class MoyenneTensionLocal {
  @HiveField(0)
  String nom;

  @HiveField(1)
  String type;

  // SECTIONS DU LOCAL
  @HiveField(2)
  List<ElementControle> dispositionsConstructives;

  @HiveField(3)
  List<ElementControle> conditionsExploitation;

  @HiveField(4)
  Cellule? cellule;

  @HiveField(5)
  TransformateurMTBT? transformateur;

  // COFFRETS DANS CE LOCAL
  @HiveField(6)
  List<CoffretArmoire> coffrets;

  @HiveField(7)
  List<ObservationLibre> observationsLibres; 

  // PHOTOS DU LOCAL
  @HiveField(8)
  List<String> photos; // Chemins des photos spécifiques à ce local

  MoyenneTensionLocal({
    required this.nom,
    required this.type,
    List<ElementControle>? dispositionsConstructives,
    List<ElementControle>? conditionsExploitation,
    this.cellule,
    this.transformateur,
    List<CoffretArmoire>? coffrets,
    List<ObservationLibre>? observationsLibres,
    List<String>? photos,
  })  : dispositionsConstructives = dispositionsConstructives ?? [],
        conditionsExploitation = conditionsExploitation ?? [],
        coffrets = coffrets ?? [],
        observationsLibres = observationsLibres ?? [],
        photos = photos ?? [];
}

@HiveType(typeId: 5)
class MoyenneTensionZone {
  @HiveField(0)
  String nom;

  @HiveField(1)
  String? description;

  @HiveField(2)
  List<CoffretArmoire> coffrets;

  @HiveField(3)
  List<ObservationLibre> observationsLibres; 

  // PHOTOS DE LA ZONE
  @HiveField(4)
  List<String> photos; // Chemins des photos de la zone

  @HiveField(5)
  List<MoyenneTensionLocal> locaux;

  @HiveField(6)
  String? classementZoneId;

  MoyenneTensionZone({
    required this.nom,
    this.description,
    List<CoffretArmoire>? coffrets,
    List<ObservationLibre>? observationsLibres,
    List<String>? photos,
    List<MoyenneTensionLocal>? locaux,
    this.classementZoneId,
  })  : coffrets = coffrets ?? [],
        observationsLibres = observationsLibres ?? [],
        photos = photos ?? [],
        locaux = locaux ?? [];
}

// STRUCTURES BASSE TENSION
@HiveType(typeId: 6)
class BasseTensionZone {
  @HiveField(0)
  String nom;

  @HiveField(1)
  String? description;

  @HiveField(2)
  List<BasseTensionLocal> locaux;

  @HiveField(3)
  List<CoffretArmoire> coffretsDirects;

  @HiveField(4)
  List<ObservationLibre> observationsLibres; 

  // PHOTOS DE LA ZONE
  @HiveField(5)
  List<String> photos; // Chemins des photos de la zone basse tension

  @HiveField(6)
  String? classementZoneId;

  BasseTensionZone({
    required this.nom,
    this.description,
    List<BasseTensionLocal>? locaux,
    List<CoffretArmoire>? coffretsDirects,
    List<ObservationLibre>? observationsLibres,
    List<String>? photos,
    this.classementZoneId,
  })  : locaux = locaux ?? [],
        coffretsDirects = coffretsDirects ?? [],
        observationsLibres = observationsLibres ?? [],
        photos = photos ?? [];
}

@HiveType(typeId: 7)
class BasseTensionLocal {
  @HiveField(0)
  String nom;

  @HiveField(1)
  String type; // LOCAL_GROUPE_ELECTROGENE, LOCAL_TGBT, LOCAL_ONDULEUR, etc.

  // SECTIONS SPÉCIFIQUES PAR TYPE
  @HiveField(2)
  List<ElementControle>? dispositionsConstructives;

  @HiveField(3)
  List<ElementControle>? conditionsExploitation;

  // COFFRETS DANS CE LOCAL
  @HiveField(4)
  List<CoffretArmoire> coffrets;

  @HiveField(5)
  List<ObservationLibre> observationsLibres; 

  // PHOTOS DU LOCAL
  @HiveField(6)
  List<String> photos; // Chemins des photos spécifiques à ce local

  BasseTensionLocal({
    required this.nom,
    required this.type,
    List<ElementControle>? dispositionsConstructives,
    List<ElementControle>? conditionsExploitation,
    List<CoffretArmoire>? coffrets,
    List<ObservationLibre>? observationsLibres,
    List<String>? photos,
  })  : dispositionsConstructives = dispositionsConstructives ?? [],
        conditionsExploitation = conditionsExploitation ?? [],
        coffrets = coffrets ?? [],
        observationsLibres = observationsLibres ?? [],
        photos = photos ?? [];
}

// STRUCTURES COMMUNES
@HiveType(typeId: 8)
class ElementControle {
  @HiveField(0)
  String elementControle;

  @HiveField(1)
  bool conforme;

  @HiveField(2)
  String? observation;

  @HiveField(3)
  int? priorite; // 1, 2 ou 3

  // PHOTO LIÉE À CET ÉLÉMENT
  @HiveField(4)
  List<String> photos; // Photos spécifiques pour cet élément de contrôle

  @HiveField(5)
  String? referenceNormative;

  ElementControle({
    required this.elementControle,
    required this.conforme,
    this.observation,
    this.priorite,
    List<String>? photos,
    this.referenceNormative
  }) : photos = photos ?? [];
}

@HiveType(typeId: 9)
class Cellule {
  @HiveField(0)
  String fonction;

  @HiveField(1)
  String type;

  @HiveField(2)
  String marqueModeleAnnee;

  @HiveField(3)
  String tensionAssignee;

  @HiveField(4)
  String pouvoirCoupure;

  @HiveField(5)
  String numerotation;

  @HiveField(6)
  String parafoudres;

  @HiveField(7)
  List<ElementControle> elementsVerifies;

  // PHOTOS DE LA CELLULE
  @HiveField(8)
  List<String> photos; // Chemins des photos de la cellule

  

  Cellule({
    required this.fonction,
    required this.type,
    required this.marqueModeleAnnee,
    required this.tensionAssignee,
    required this.pouvoirCoupure,
    required this.numerotation,
    required this.parafoudres,
    List<ElementControle>? elementsVerifies,
    List<String>? photos,
  })  : elementsVerifies = elementsVerifies ?? [],
        photos = photos ?? [];
}

@HiveType(typeId: 10)
class TransformateurMTBT {
  @HiveField(0)
  String typeTransformateur;

  @HiveField(1)
  String marqueAnnee;

  @HiveField(2)
  String puissanceAssignee;

  @HiveField(3)
  String tensionPrimaireSecondaire;

  @HiveField(4)
  String relaisBuchholz;

  @HiveField(5)
  String typeRefroidissement;

  @HiveField(6)
  String regimeNeutre;

  @HiveField(7)
  List<ElementControle> elementsVerifies;

  // PHOTOS DU TRANSFORMATEUR
  @HiveField(8)
  List<String> photos; // Chemins des photos du transformateur

  TransformateurMTBT({
    required this.typeTransformateur,
    required this.marqueAnnee,
    required this.puissanceAssignee,
    required this.tensionPrimaireSecondaire,
    required this.relaisBuchholz,
    required this.typeRefroidissement,
    required this.regimeNeutre,
    List<ElementControle>? elementsVerifies,
    List<String>? photos,
  })  : elementsVerifies = elementsVerifies ?? [],
        photos = photos ?? [];
}

// COFFRETS/ARMOIRES
@HiveType(typeId: 11)
class CoffretArmoire {
  @HiveField(0)
  String qrCode; 

  @HiveField(1)
  String nom;

  @HiveField(2)
  String type; // TUR, INVERSEUR, TGBT, etc.

  @HiveField(3)
  String? description;

  @HiveField(4)
  String? repere;

  // INFORMATIONS GÉNÉRALES (Oui/Non)
  @HiveField(5)
  bool zoneAtex;

  @HiveField(6)
  String domaineTension;

  @HiveField(7)
  bool identificationArmoire;

  @HiveField(8)
  bool signalisationDanger;

  @HiveField(9)
  bool presenceSchema;

  @HiveField(10)
  bool presenceParafoudre;

  @HiveField(11)
  bool verificationThermographie;

  // ALIMENTATIONS (dépend du type)
  @HiveField(12)
  List<Alimentation> alimentations;

  // PROTECTION DE TÊTE
  @HiveField(13)
  Alimentation? protectionTete;

  // POINTS DE VÉRIFICATION
  @HiveField(14)
  List<PointVerification> pointsVerification;

  @HiveField(15)
  List<ObservationLibre> observationsLibres; 

  // PHOTOS DU COFFRET/ARMOIRE
  @HiveField(16)
  List<String> photos; // Chemins des photos du coffret/armoire

  @HiveField(17)
  String? numeroEquipement;

  @HiveField(18)
  String statut; // 'complet' ou 'incomplet'

  //Étape courante pour reprise
  @HiveField(19)
  int currentStep;

  @HiveField(20)
  List<String> photosExternes;

  @HiveField(21)
  List<String> photosInternes;

  CoffretArmoire({
    required this.qrCode, // Ajouté dans le constructeur
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
    List<Alimentation>? alimentations,
    this.protectionTete,
    List<PointVerification>? pointsVerification,
    List<ObservationLibre>? observationsLibres,
    List<String>? photos,
    this.statut = 'incomplet',
    this.currentStep = 0,
    this.numeroEquipement,
    List<String>? photosExternes,
    List<String>? photosInternes,
  })  : alimentations = alimentations ?? [],
        pointsVerification = pointsVerification ?? [],
        observationsLibres = observationsLibres ?? [],
        photos = photos ?? [],
        photosExternes = photosExternes ?? [],
        photosInternes = photosInternes ?? [];
}

@HiveType(typeId: 12)
class Alimentation {
  @HiveField(0)
  String typeProtection;

  @HiveField(1)
  String pdcKA;

  @HiveField(2)
  String calibre;

  @HiveField(3)
  String sectionCable;

  // PHOTO DE L'ALIMENTATION (schéma, étiquette)
  @HiveField(4)
  List<String> photos; // Photos de l'étiquette ou de l'installation

  @HiveField(5)
  String source;

  Alimentation({
    required this.typeProtection,
    required this.pdcKA,
    required this.calibre,
    required this.sectionCable,
    List<String>? photos,
    this.source = '',
  }) : photos = photos ?? [];
}

@HiveType(typeId: 13)
class PointVerification {
  @HiveField(0)
  String pointVerification;

  @HiveField(1)
  String conformite; // "oui", "non", "non_acquis"

  @HiveField(2)
  String? observation;

  @HiveField(3)
  String? referenceNormative;

  @HiveField(4)
  int? priorite; // 1, 2 ou 3

  // PHOTO DU POINT DE VÉRIFICATION
  @HiveField(5)
  List<String> photos; // Photos illustrant ce point spécifique

  PointVerification({
    required this.pointVerification,
    required this.conformite,
    this.observation,
    this.referenceNormative,
    this.priorite,
    List<String>? photos,
  }) : photos = photos ?? [];
}

@HiveType(typeId: 24)
class ObservationLibre {
  @HiveField(0)
  String texte;
  
  @HiveField(1)
  List<String> photos; // Photos associées à cette observation
  
  @HiveField(2)
  DateTime dateCreation;
  
  @HiveField(3)
  DateTime dateModification;
  
  ObservationLibre({
    required this.texte,
    List<String>? photos,
    DateTime? dateCreation,
    DateTime? dateModification,
  })  : photos = photos ?? [],
        dateCreation = dateCreation ?? DateTime.now(),
        dateModification = dateModification ?? DateTime.now();
  
  // Méthode pour ajouter une photo
  void addPhoto(String cheminPhoto) {
    photos.add(cheminPhoto);
    dateModification = DateTime.now();
  }
  
  // Méthode pour supprimer une photo
  void removePhoto(String cheminPhoto) {
    photos.remove(cheminPhoto);
    dateModification = DateTime.now();
  }
  
  // Méthode pour mettre à jour le texte
  void updateTexte(String nouveauTexte) {
    texte = nouveauTexte;
    dateModification = DateTime.now();
  }
}