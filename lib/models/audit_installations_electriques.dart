// audit_installations_electriques.dart
import 'package:hive/hive.dart';
import '../services/dispositions_constructives_registry.dart';

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

  @HiveField(30)
  List<Cellule> cellules = [];
  
  @HiveField(31)
  List<TransformateurMTBT> transformateurs = [];

  @HiveField(32)
  bool accessible;

  @HiveField(33)
  bool aReverifier;

  @HiveField(34)
  bool isRiskZone;

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
    List<Cellule>? cellules,
    List<TransformateurMTBT>? transformateurs,
    bool? accessible,
    bool? aReverifier,
    bool? isRiskZone,
  })  : dispositionsConstructives = dispositionsConstructives ?? [],
        conditionsExploitation = conditionsExploitation ?? [],
        coffrets = coffrets ?? [],
        observationsLibres = observationsLibres ?? [],
        photos = photos ?? [],
        cellules = cellules ?? [],
        transformateurs = transformateurs ?? [],
        accessible = accessible ?? true,
        aReverifier = aReverifier ?? false,
        isRiskZone = isRiskZone ?? false;

  // MÉTHODE DE MIGRATION (préserve les données existantes)
  void migrateFromOldFields() {
    // Migrer l'ancienne cellule unique vers la liste
    if (cellule != null && cellules.isEmpty) {
      cellules.add(cellule!);
    }
    // Migrer l'ancien transformateur unique vers la liste
    if (transformateur != null && transformateurs.isEmpty) {
      transformateurs.add(transformateur!);
    }
    DispositionsConstructivesRegistry.ensureCompleteLocalChecklists(
      dispositionsConstructives: dispositionsConstructives,
      conditionsExploitation: conditionsExploitation,
    );
  }
  
  // GETTER POUR COMPATIBILITÉ (optionnel, peut être supprimé plus tard)
  Cellule? get primaryCellule => cellules.isNotEmpty ? cellules.first : cellule;
  TransformateurMTBT? get primaryTransformateur => transformateurs.isNotEmpty ? transformateurs.first : transformateur;

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

  @HiveField(7)
  bool isRiskZone;

  MoyenneTensionZone({
    required this.nom,
    this.description,
    List<CoffretArmoire>? coffrets,
    List<ObservationLibre>? observationsLibres,
    List<String>? photos,
    List<MoyenneTensionLocal>? locaux,
    this.classementZoneId,
    bool? isRiskZone,
  })  : coffrets = coffrets ?? [],
        observationsLibres = observationsLibres ?? [],
        photos = photos ?? [],
        locaux = locaux ?? [],
        isRiskZone = isRiskZone ?? false;
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

  @HiveField(7)
  bool isRiskZone;

  BasseTensionZone({
    required this.nom,
    this.description,
    List<BasseTensionLocal>? locaux,
    List<CoffretArmoire>? coffretsDirects,
    List<ObservationLibre>? observationsLibres,
    List<String>? photos,
    this.classementZoneId,
    bool? isRiskZone,
  })  : locaux = locaux ?? [],
        coffretsDirects = coffretsDirects ?? [],
        observationsLibres = observationsLibres ?? [],
        photos = photos ?? [],
        isRiskZone = isRiskZone ?? false;
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

  @HiveField(7)
  bool accessible;

  @HiveField(8)
  bool aReverifier;

  @HiveField(9)
  List<Cellule> cellules;

  @HiveField(10)
  List<TransformateurMTBT> transformateurs;

  @HiveField(11)
  bool isRiskZone;

  BasseTensionLocal({
    required this.nom,
    required this.type,
    List<ElementControle>? dispositionsConstructives,
    List<ElementControle>? conditionsExploitation,
    List<CoffretArmoire>? coffrets,
    List<ObservationLibre>? observationsLibres,
    List<String>? photos,
    bool? accessible,
    bool? aReverifier,
    List<Cellule>? cellules,
    List<TransformateurMTBT>? transformateurs,
    bool? isRiskZone,
  })  : dispositionsConstructives = dispositionsConstructives ?? [],
        conditionsExploitation = conditionsExploitation ?? [],
        coffrets = coffrets ?? [],
        observationsLibres = observationsLibres ?? [],
        photos = photos ?? [],
        accessible = accessible ?? true,
        aReverifier = aReverifier ?? false,
        cellules = cellules ?? [],
        transformateurs = transformateurs ?? [],
        isRiskZone = isRiskZone ?? false;
}

// STRUCTURES COMMUNES
@HiveType(typeId: 8)
class ElementControle {
  @HiveField(0)
  String elementControle;

  @HiveField(1)
  bool? conforme;

  @HiveField(2)
  String? observation;

  @HiveField(3)
  int? priorite; // 1, 2 ou 3

  // PHOTO LIÉE À CET ÉLÉMENT
  @HiveField(4)
  List<String> photos; // Photos spécifiques pour cet élément de contrôle

  @HiveField(5)
  String? referenceNormative;

  @HiveField(6)
  bool estNA;

  @HiveField(7)
  String? familleRisque;

  @HiveField(8)
  String? criticite;

  ElementControle({
    required this.elementControle,
    required this.conforme,
    this.observation,
    this.priorite,
    List<String>? photos,
    this.referenceNormative,
    bool? estNA,
    this.familleRisque,
    this.criticite,
  })  : photos = photos ?? [],
        estNA = estNA ?? false;

  String? referenceNormativeEffectiveFor({String? localType}) {
    final meta = DispositionsConstructivesRegistry.getMetadata(elementControle, localType: localType);
    final raw = (meta?.referenceNormative != null && meta!.referenceNormative!.isNotEmpty)
        ? meta.referenceNormative
        : referenceNormative;
    return DispositionsConstructivesRegistry.normalizeNormativeReference(raw);
  }

  String? get referenceNormativeEffective => referenceNormativeEffectiveFor();

  String? familleRisqueEffectiveFor({String? localType}) {
    final meta = DispositionsConstructivesRegistry.getMetadata(elementControle, localType: localType);
    if (meta?.familleRisque != null && meta!.familleRisque!.isNotEmpty) {
      return meta.familleRisque;
    }
    return familleRisque;
  }

  String? get familleRisqueEffective => familleRisqueEffectiveFor();

  String? criticiteEffectiveFor({String? localType}) {
    final meta = DispositionsConstructivesRegistry.getMetadata(elementControle, localType: localType);
    if (meta?.criticite != null && meta!.criticite!.isNotEmpty) {
      return meta.criticite;
    }
    return criticite;
  }

  String? get criticiteEffective => criticiteEffectiveFor();
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

  @HiveField(9)
  String? gamme;

  @HiveField(10)
  String? calibreDisjoncteur;

  @HiveField(11)
  String? sectionCables;

  @HiveField(12)
  String? natureReseau;

  @HiveField(13)
  List<ElementControle>? observations;

  @HiveField(14)
  String? presenceIacm;

  @HiveField(15)
  String? syncId;

  @HiveField(16)
  String? tensionService;

  @HiveField(17)
  String? nom;

  @HiveField(18)
  String? photo;

  @HiveField(19)
  String? repere;

  @HiveField(20)
  String? marque;

  @HiveField(21)
  String? modele;

  @HiveField(22)
  String? annee;

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
    this.gamme,
    this.calibreDisjoncteur,
    this.sectionCables,
    this.natureReseau,
    List<ElementControle>? observations,
    this.presenceIacm,
    String? syncId,
    this.tensionService,
    this.nom,
    this.photo,
    this.repere,
    this.marque,
    this.modele,
    this.annee,
  })  : elementsVerifies = elementsVerifies ?? [],
        photos = photos ?? [],
        observations = observations ?? [],
        syncId = (syncId != null && syncId.isNotEmpty)
            ? syncId
            : 'cellule_${DateTime.now().microsecondsSinceEpoch}';

  /// Résout le repère effectif de la cellule (nom du local parent s'il est connu, sinon repere stocké)
  String getEffectiveRepere(String? parentLocalNom) {
    if (parentLocalNom != null && parentLocalNom.trim().isNotEmpty) {
      return parentLocalNom.trim();
    }
    if (repere != null && repere!.trim().isNotEmpty) {
      return repere!.trim();
    }
    return '';
  }

  /// Résout la marque effective avec fallback rétrocompatible
  String get effectiveMarque {
    if (marque != null && marque!.trim().isNotEmpty) {
      return marque!.trim();
    }
    return marqueModeleAnnee.trim();
  }

  /// Résout le modèle effectif avec fallback
  String get effectiveModele => modele?.trim() ?? '';

  /// Résout l'année effective avec fallback
  String get effectiveAnnee => annee?.trim() ?? '';

  /// Formate l'ensemble des informations constructeur
  String get formattedMarqueModeleAnnee {
    final m = effectiveMarque;
    final mod = effectiveModele;
    final a = effectiveAnnee;
    final parts = [m, mod, a].where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' / ');
    return marqueModeleAnnee;
  }

  Cellule copyWith({
    String? fonction,
    String? type,
    String? marqueModeleAnnee,
    String? tensionAssignee,
    String? pouvoirCoupure,
    String? numerotation,
    String? parafoudres,
    List<ElementControle>? elementsVerifies,
    List<String>? photos,
    String? gamme,
    String? calibreDisjoncteur,
    String? sectionCables,
    String? natureReseau,
    List<ElementControle>? observations,
    String? presenceIacm,
    String? syncId,
    String? tensionService,
    String? nom,
    String? photo,
    String? repere,
    String? marque,
    String? modele,
    String? annee,
  }) {
    return Cellule(
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
      observations: observations ?? this.observations,
      presenceIacm: presenceIacm ?? this.presenceIacm,
      syncId: syncId ?? this.syncId,
      tensionService: tensionService ?? this.tensionService,
      nom: nom ?? this.nom,
      photo: photo ?? this.photo,
      repere: repere ?? this.repere,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      annee: annee ?? this.annee,
    );
  }
}

// TRANSFORMATEUR MT/BT
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

  @HiveField(9)
  String? calibreDisjoncteur;

  @HiveField(10)
  String? sectionCables;

  @HiveField(11)
  List<ElementControle>? observations;

  @HiveField(12)
  String? syncId;

  @HiveField(13)
  String? intensiteNominale;

  @HiveField(14)
  String? couplage;

  @HiveField(15)
  String? typeReseau;

  @HiveField(16)
  String? pccAmont;

  @HiveField(17)
  String? puissanceUcc;

  @HiveField(18)
  String? ik3Max;

  @HiveField(19)
  String? nom;

  @HiveField(20)
  String? photo;

  @HiveField(21)
  String? repere;

  @HiveField(22)
  String? marque;

  @HiveField(23)
  String? anneeFabrication;

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
    this.calibreDisjoncteur,
    this.sectionCables,
    List<ElementControle>? observations,
    String? syncId,
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
  })  : elementsVerifies = elementsVerifies ?? [],
        photos = photos ?? [],
        observations = observations ?? [],
        syncId = (syncId != null && syncId.isNotEmpty)
            ? syncId
            : 'transfo_${DateTime.now().microsecondsSinceEpoch}';

  /// Résout le repère effectif du transformateur (nom du local parent s'il est connu, sinon repere stocké)
  String getEffectiveRepere(String? parentLocalNom) {
    if (parentLocalNom != null && parentLocalNom.trim().isNotEmpty) {
      return parentLocalNom.trim();
    }
    if (repere != null && repere!.trim().isNotEmpty) {
      return repere!.trim();
    }
    return '';
  }

  /// Résout la marque effective avec fallback rétrocompatible
  String get effectiveMarque {
    if (marque != null && marque!.trim().isNotEmpty) {
      return marque!.trim();
    }
    return marqueAnnee.trim();
  }

  /// Résout l'année de fabrication effective avec fallback
  String get effectiveAnneeFabrication => anneeFabrication?.trim() ?? '';

  /// Formate l'ensemble des informations constructeur
  String get formattedMarqueAnnee {
    final m = effectiveMarque;
    final a = effectiveAnneeFabrication;
    final parts = [m, a].where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' / ');
    return marqueAnnee;
  }

  TransformateurMTBT copyWith({
    String? typeTransformateur,
    String? marqueAnnee,
    String? puissanceAssignee,
    String? tensionPrimaireSecondaire,
    String? relaisBuchholz,
    String? typeRefroidissement,
    String? regimeNeutre,
    List<ElementControle>? elementsVerifies,
    List<String>? photos,
    String? calibreDisjoncteur,
    String? sectionCables,
    List<ElementControle>? observations,
    String? syncId,
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
    return TransformateurMTBT(
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
      observations: observations ?? this.observations,
      syncId: syncId ?? this.syncId,
      intensiteNominale: intensiteNominale ?? this.intensiteNominale,
      couplage: couplage ?? this.couplage,
      typeReseau: typeReseau ?? this.typeReseau,
      pccAmont: pccAmont ?? this.pccAmont,
      puissanceUcc: puissanceUcc ?? this.puissanceUcc,
      ik3Max: ik3Max ?? this.ik3Max,
      nom: nom ?? this.nom,
      photo: photo ?? this.photo,
    );
  }
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
  @HiveField(5, defaultValue: false)
  bool zoneAtex;

  @HiveField(6, defaultValue: '')
  String domaineTension;

  @HiveField(7, defaultValue: false)
  bool identificationArmoire;

  @HiveField(8, defaultValue: false)
  bool signalisationDanger;

  @HiveField(9, defaultValue: false)
  bool presenceSchema;

  @HiveField(10, defaultValue: false)
  bool presenceParafoudre;

  @HiveField(11, defaultValue: false)
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

  @HiveField(22)
  List<ObservationLibre> observationsParafoudre;

  @HiveField(23)
  List<ElementControle>? observationsParafoudreEnrichies;

  @HiveField(24)
  String? presenceDefautThermo;

  @HiveField(25, defaultValue: true)
  bool? _accessible;

  @HiveField(26)
  bool? alimenteeParTransformateur;

  @HiveField(27)
  bool? presenceCPI;

  bool get accessible => _accessible ?? true;
  set accessible(bool value) => _accessible = value;

  /// Getter rétrocompatible pour interpréter l'état de la présence de défaut thermo.
  /// Rends 'Sans objet' pour les anciens équipements ayant la thermographie activée mais sans valeur enregistrée.
  String? get effectivePresenceDefautThermo {
    if (!verificationThermographie) return null;
    if (presenceDefautThermo != null && presenceDefautThermo!.isNotEmpty) {
      return presenceDefautThermo;
    }
    return 'Sans objet';
  }

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
    this.presenceDefautThermo,
    this.alimenteeParTransformateur,
    this.presenceCPI,
    bool? accessible,
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
    List<ObservationLibre>? observationsParafoudre,
    List<ElementControle>? observationsParafoudreEnrichies,
  })  : _accessible = accessible ?? true,
        alimentations = alimentations ?? [],
        pointsVerification = pointsVerification ?? [],
        observationsLibres = observationsLibres ?? [],
        photos = photos ?? [],
        photosExternes = photosExternes ?? [],
        photosInternes = photosInternes ?? [],
        observationsParafoudre = observationsParafoudre ?? [],
        observationsParafoudreEnrichies = observationsParafoudreEnrichies ?? [];

  /// Pour un Inverseur, retourne les alimentations d'entrée (Alimentation 1 & Alimentation 2)
  List<Alimentation> get alimentationsInverseurEntree {
    if (type != 'INVERSEUR') return alimentations;
    return alimentations.take(2).toList();
  }

  /// Pour un Inverseur, retourne la liste dynamique des sorties inverseur (éléments à partir de l'index 2)
  List<Alimentation> get sortiesInverseur {
    if (type != 'INVERSEUR') return [];
    if (alimentations.length <= 2) return [];
    return alimentations.skip(2).toList();
  }
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

  @HiveField(6)
  String? courbe;

  @HiveField(7)
  String? ddr;

  Alimentation({
    required this.typeProtection,
    this.courbe = '',
    this.ddr,
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

  @HiveField(6)
  List<ElementControle>? observations;

  @HiveField(7)
  String? criticite;

  @HiveField(8)
  String? familleRisque;

  PointVerification({
    required this.pointVerification,
    required this.conformite,
    this.observation,
    this.referenceNormative,
    this.priorite,
    List<String>? photos,
    List<ElementControle>? observations,
    this.criticite,
    this.familleRisque,
  }) : photos = photos ?? [],
       observations = observations ?? [];
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

  @HiveField(4)
  String? pointVerificationKey;

  @HiveField(5)
  String? referenceNormative;

  @HiveField(6)
  String? familleRisque;

  @HiveField(7)
  String? criticite;

  @HiveField(8)
  bool isAutoLinked;

  ObservationLibre({
    required this.texte,
    List<String>? photos,
    DateTime? dateCreation,
    DateTime? dateModification,
    this.pointVerificationKey,
    this.referenceNormative,
    this.familleRisque,
    this.criticite,
    this.isAutoLinked = false,
  })  : photos = photos ?? [],
        dateCreation = dateCreation ?? DateTime.now(),
        dateModification = dateModification ?? DateTime.now();

  bool get hasNormativeReference =>
      referenceNormative != null && referenceNormative!.trim().isNotEmpty;

  void linkToNormativePoint({
    required String key,
    required String refNormative,
    required String famille,
    required String crit,
    bool auto = false,
  }) {
    pointVerificationKey = key;
    referenceNormative = refNormative;
    familleRisque = famille;
    criticite = crit;
    isAutoLinked = auto;
    dateModification = DateTime.now();
  }

  void unlinkNormativePoint() {
    pointVerificationKey = null;
    referenceNormative = null;
    familleRisque = null;
    criticite = null;
    isAutoLinked = false;
    dateModification = DateTime.now();
  }

  ObservationLibre copyWith({
    String? texte,
    List<String>? photos,
    DateTime? dateCreation,
    DateTime? dateModification,
    String? pointVerificationKey,
    String? referenceNormative,
    String? familleRisque,
    String? criticite,
    bool? isAutoLinked,
  }) {
    return ObservationLibre(
      texte: texte ?? this.texte,
      photos: photos ?? this.photos,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      pointVerificationKey: pointVerificationKey ?? this.pointVerificationKey,
      referenceNormative: referenceNormative ?? this.referenceNormative,
      familleRisque: familleRisque ?? this.familleRisque,
      criticite: criticite ?? this.criticite,
      isAutoLinked: isAutoLinked ?? this.isAutoLinked,
    );
  }

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