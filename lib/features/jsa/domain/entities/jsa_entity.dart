// lib/features/jsa/domain/entities/jsa_entity.dart

class JsaInspecteurEntity {
  final String nom;
  final String prenom;
  final String signature;

  const JsaInspecteurEntity({
    required this.nom,
    required this.prenom,
    this.signature = '',
  });
}

class JsaPlanUrgenceEntity {
  final bool voiesIssuesIdentifiees;
  final bool zonesRassemblementIdentifiees;
  final bool consignesSecuriteInternes;
  final String personneContactClient;
  final String personneContactKES;

  const JsaPlanUrgenceEntity({
    this.voiesIssuesIdentifiees = false,
    this.zonesRassemblementIdentifiees = false,
    this.consignesSecuriteInternes = false,
    this.personneContactClient = '',
    this.personneContactKES = '',
  });
}

class JsaDangersEntity {
  final bool chocElectrique;
  final bool bruit;
  final bool stressThermique;
  final bool eclairageInadapte;
  final bool zoneCirculationMalDefinie;
  final bool solAccidente;
  final bool emissionGazPoussiere;
  final bool espaceConfine;
  final String autreEnvironnement;
  final bool chuteObjets;
  final bool coactivite;
  final bool portCharge;
  final bool expositionProduitsChimiques;
  final bool chuteHauteur;
  final bool electrification;
  final bool incendiesExplosion;
  final bool mauvaisesPostures;
  final bool chutePlainPied;
  final String autrePhysique;

  const JsaDangersEntity({
    this.chocElectrique = false,
    this.bruit = false,
    this.stressThermique = false,
    this.eclairageInadapte = false,
    this.zoneCirculationMalDefinie = false,
    this.solAccidente = false,
    this.emissionGazPoussiere = false,
    this.espaceConfine = false,
    this.autreEnvironnement = '',
    this.chuteObjets = false,
    this.coactivite = false,
    this.portCharge = false,
    this.expositionProduitsChimiques = false,
    this.chuteHauteur = false,
    this.electrification = false,
    this.incendiesExplosion = false,
    this.mauvaisesPostures = false,
    this.chutePlainPied = false,
    this.autrePhysique = '',
  });
}

class JsaExigencesGeneralesEntity {
  final bool signaletiqueSecurite;
  final bool ficheDonneeSecuriteDisponible;
  final bool uneMinuteMaSecurite;
  final bool balise;
  final bool zoneTravailPropre;
  final bool toolboxMeeting;
  final bool permisTravail;
  final bool extincteurs;
  final bool outilsMaterielsIsolants;
  final bool boitePharmacie;
  final String autre;

  const JsaExigencesGeneralesEntity({
    this.signaletiqueSecurite = false,
    this.ficheDonneeSecuriteDisponible = false,
    this.uneMinuteMaSecurite = false,
    this.balise = false,
    this.zoneTravailPropre = false,
    this.toolboxMeeting = false,
    this.permisTravail = false,
    this.extincteurs = false,
    this.outilsMaterielsIsolants = false,
    this.boitePharmacie = false,
    this.autre = '',
  });
}

class JsaEpiEntity {
  final bool casqueSecurite;
  final bool bouchonsOreille;
  final bool lunettesProtection;
  final bool harnaisSecurite;
  final bool chaussureSecurite;
  final bool masqueSecurite;
  final bool combinaisonLongueManche;
  final bool gantsIsolants;
  final bool cacheNez;
  final bool gilet;
  final String autre;

  const JsaEpiEntity({
    this.casqueSecurite = false,
    this.bouchonsOreille = false,
    this.lunettesProtection = false,
    this.harnaisSecurite = false,
    this.chaussureSecurite = false,
    this.masqueSecurite = false,
    this.combinaisonLongueManche = false,
    this.gantsIsolants = false,
    this.cacheNez = false,
    this.gilet = false,
    this.autre = '',
  });
}

class JsaVerificationFinaleEntity {
  final bool travailTermineNA;
  final bool travailTermineApplicable;
  final bool consignationCadenasRetireNA;
  final bool consignationCadenasRetireApplicable;
  final bool absenceConsignataireProcedureNA;
  final bool absenceConsignataireProcedureApplicable;
  final bool consignataireAbsentProcedureAppliqueeNA;
  final bool consignataireAbsentProcedureAppliqueeApplicable;
  final bool materielEnleveZoneNettoyeeNA;
  final bool materielEnleveZoneNettoyeeApplicable;
  final bool risquesSupprimesEquipementPretNA;
  final bool risquesSupprimesEquipementPretApplicable;
  final String autresPoints;
  final String donneurOrdreSignature;
  final String chargeAffairesSignature;

  const JsaVerificationFinaleEntity({
    this.travailTermineNA = false,
    this.travailTermineApplicable = false,
    this.consignationCadenasRetireNA = false,
    this.consignationCadenasRetireApplicable = false,
    this.absenceConsignataireProcedureNA = false,
    this.absenceConsignataireProcedureApplicable = false,
    this.consignataireAbsentProcedureAppliqueeNA = false,
    this.consignataireAbsentProcedureAppliqueeApplicable = false,
    this.materielEnleveZoneNettoyeeNA = false,
    this.materielEnleveZoneNettoyeeApplicable = false,
    this.risquesSupprimesEquipementPretNA = false,
    this.risquesSupprimesEquipementPretApplicable = false,
    this.autresPoints = '',
    this.donneurOrdreSignature = '',
    this.chargeAffairesSignature = '',
  });
}

class JsaEntity {
  final String missionId;
  final String operationEffectuer;
  final List<JsaInspecteurEntity> inspecteurs;
  final JsaPlanUrgenceEntity planUrgence;
  final JsaDangersEntity dangers;
  final JsaExigencesGeneralesEntity exigencesGenerales;
  final JsaEpiEntity epi;
  final JsaVerificationFinaleEntity verificationFinale;
  final DateTime updatedAt;
  final int currentSubCategory;

  const JsaEntity({
    required this.missionId,
    this.operationEffectuer = '',
    this.inspecteurs = const [],
    this.planUrgence = const JsaPlanUrgenceEntity(),
    this.dangers = const JsaDangersEntity(),
    this.exigencesGenerales = const JsaExigencesGeneralesEntity(),
    this.epi = const JsaEpiEntity(),
    this.verificationFinale = const JsaVerificationFinaleEntity(),
    required this.updatedAt,
    this.currentSubCategory = 0,
  });
}
