// lib/features/jsa/data/mappers/jsa_mapper.dart
import 'package:inspec_app/models/jsa.dart';
import '../../domain/entities/jsa_entity.dart';

class JsaInspecteurMapper {
  static JsaInspecteurEntity toEntity(JSAInspecteur model) {
    return JsaInspecteurEntity(
      nom: model.nom,
      prenom: model.prenom,
      signature: model.signature,
    );
  }

  static JSAInspecteur toModel(JsaInspecteurEntity entity) {
    return JSAInspecteur(
      nom: entity.nom,
      prenom: entity.prenom,
      signature: entity.signature,
    );
  }
}

class JsaPlanUrgenceMapper {
  static JsaPlanUrgenceEntity toEntity(JSAPlanUrgence model) {
    return JsaPlanUrgenceEntity(
      voiesIssuesIdentifiees: model.voiesIssuesIdentifiees,
      zonesRassemblementIdentifiees: model.zonesRassemblementIdentifiees,
      consignesSecuriteInternes: model.consignesSecuriteInternes,
      personneContactClient: model.personneContactClient,
      personneContactKES: model.personneContactKES,
    );
  }

  static JSAPlanUrgence toModel(JsaPlanUrgenceEntity entity) {
    return JSAPlanUrgence(
      voiesIssuesIdentifiees: entity.voiesIssuesIdentifiees,
      zonesRassemblementIdentifiees: entity.zonesRassemblementIdentifiees,
      consignesSecuriteInternes: entity.consignesSecuriteInternes,
      personneContactClient: entity.personneContactClient,
      personneContactKES: entity.personneContactKES,
    );
  }
}

class JsaDangersMapper {
  static JsaDangersEntity toEntity(JSADangers model) {
    return JsaDangersEntity(
      chocElectrique: model.chocElectrique,
      bruit: model.bruit,
      stressThermique: model.stressThermique,
      eclairageInadapte: model.eclairageInadapte,
      zoneCirculationMalDefinie: model.zoneCirculationMalDefinie,
      solAccidente: model.solAccidente,
      emissionGazPoussiere: model.emissionGazPoussiere,
      espaceConfine: model.espaceConfine,
      autreEnvironnement: model.autreEnvironnement,
      chuteObjets: model.chuteObjets,
      coactivite: model.coactivite,
      portCharge: model.portCharge,
      expositionProduitsChimiques: model.expositionProduitsChimiques,
      chuteHauteur: model.chuteHauteur,
      electrification: model.electrification,
      incendiesExplosion: model.incendiesExplosion,
      mauvaisesPostures: model.mauvaisesPostures,
      chutePlainPied: model.chutePlainPied,
      autrePhysique: model.autrePhysique,
    );
  }

  static JSADangers toModel(JsaDangersEntity entity) {
    final model = JSADangers();
    model.chocElectrique = entity.chocElectrique;
    model.bruit = entity.bruit;
    model.stressThermique = entity.stressThermique;
    model.eclairageInadapte = entity.eclairageInadapte;
    model.zoneCirculationMalDefinie = entity.zoneCirculationMalDefinie;
    model.solAccidente = entity.solAccidente;
    model.emissionGazPoussiere = entity.emissionGazPoussiere;
    model.espaceConfine = entity.espaceConfine;
    model.autreEnvironnement = entity.autreEnvironnement;
    model.chuteObjets = entity.chuteObjets;
    model.coactivite = entity.coactivite;
    model.portCharge = entity.portCharge;
    model.expositionProduitsChimiques = entity.expositionProduitsChimiques;
    model.chuteHauteur = entity.chuteHauteur;
    model.electrification = entity.electrification;
    model.incendiesExplosion = entity.incendiesExplosion;
    model.mauvaisesPostures = entity.mauvaisesPostures;
    model.chutePlainPied = entity.chutePlainPied;
    model.autrePhysique = entity.autrePhysique;
    return model;
  }
}

class JsaExigencesGeneralesMapper {
  static JsaExigencesGeneralesEntity toEntity(JSAExigencesGenerales model) {
    return JsaExigencesGeneralesEntity(
      signaletiqueSecurite: model.signaletiqueSecurite,
      ficheDonneeSecuriteDisponible: model.ficheDonneeSecuriteDisponible,
      uneMinuteMaSecurite: model.uneMinuteMaSecurite,
      balise: model.balise,
      zoneTravailPropre: model.zoneTravailPropre,
      toolboxMeeting: model.toolboxMeeting,
      permisTravail: model.permisTravail,
      extincteurs: model.extincteurs,
      outilsMaterielsIsolants: model.outilsMaterielsIsolants,
      boitePharmacie: model.boitePharmacie,
      autre: model.autre,
    );
  }

  static JSAExigencesGenerales toModel(JsaExigencesGeneralesEntity entity) {
    final model = JSAExigencesGenerales();
    model.signaletiqueSecurite = entity.signaletiqueSecurite;
    model.ficheDonneeSecuriteDisponible = entity.ficheDonneeSecuriteDisponible;
    model.uneMinuteMaSecurite = entity.uneMinuteMaSecurite;
    model.balise = entity.balise;
    model.zoneTravailPropre = entity.zoneTravailPropre;
    model.toolboxMeeting = entity.toolboxMeeting;
    model.permisTravail = entity.permisTravail;
    model.extincteurs = entity.extincteurs;
    model.outilsMaterielsIsolants = entity.outilsMaterielsIsolants;
    model.boitePharmacie = entity.boitePharmacie;
    model.autre = entity.autre;
    return model;
  }
}

class JsaEpiMapper {
  static JsaEpiEntity toEntity(JSAEPI model) {
    return JsaEpiEntity(
      casqueSecurite: model.casqueSecurite,
      bouchonsOreille: model.bouchonsOreille,
      lunettesProtection: model.lunettesProtection,
      harnaisSecurite: model.harnaisSecurite,
      chaussureSecurite: model.chaussureSecurite,
      masqueSecurite: model.masqueSecurite,
      combinaisonLongueManche: model.combinaisonLongueManche,
      gantsIsolants: model.gantsIsolants,
      cacheNez: model.cacheNez,
      gilet: model.gilet,
      autre: model.autre,
    );
  }

  static JSAEPI toModel(JsaEpiEntity entity) {
    final model = JSAEPI();
    model.casqueSecurite = entity.casqueSecurite;
    model.bouchonsOreille = entity.bouchonsOreille;
    model.lunettesProtection = entity.lunettesProtection;
    model.harnaisSecurite = entity.harnaisSecurite;
    model.chaussureSecurite = entity.chaussureSecurite;
    model.masqueSecurite = entity.masqueSecurite;
    model.combinaisonLongueManche = entity.combinaisonLongueManche;
    model.gantsIsolants = entity.gantsIsolants;
    model.cacheNez = entity.cacheNez;
    model.gilet = entity.gilet;
    model.autre = entity.autre;
    return model;
  }
}

class JsaVerificationFinaleMapper {
  static JsaVerificationFinaleEntity toEntity(JSAVerificationFinale model) {
    return JsaVerificationFinaleEntity(
      travailTermineNA: model.travailTermineNA,
      travailTermineApplicable: model.travailTermineApplicable,
      consignationCadenasRetireNA: model.consignationCadenasRetireNA,
      consignationCadenasRetireApplicable: model.consignationCadenasRetireApplicable,
      absenceConsignataireProcedureNA: model.absenceConsignataireProcedureNA,
      absenceConsignataireProcedureApplicable: model.absenceConsignataireProcedureApplicable,
      consignataireAbsentProcedureAppliqueeNA: model.consignataireAbsentProcedureAppliqueeNA,
      consignataireAbsentProcedureAppliqueeApplicable: model.consignataireAbsentProcedureAppliqueeApplicable,
      materielEnleveZoneNettoyeeNA: model.materielEnleveZoneNettoyeeNA,
      materielEnleveZoneNettoyeeApplicable: model.materielEnleveZoneNettoyeeApplicable,
      risquesSupprimesEquipementPretNA: model.risquesSupprimesEquipementPretNA,
      risquesSupprimesEquipementPretApplicable: model.risquesSupprimesEquipementPretApplicable,
      autresPoints: model.autresPoints,
      donneurOrdreSignature: model.donneurOrdreSignature,
      chargeAffairesSignature: model.chargeAffairesSignature,
    );
  }

  static JSAVerificationFinale toModel(JsaVerificationFinaleEntity entity) {
    final model = JSAVerificationFinale();
    model.travailTermineNA = entity.travailTermineNA;
    model.travailTermineApplicable = entity.travailTermineApplicable;
    model.consignationCadenasRetireNA = entity.consignationCadenasRetireNA;
    model.consignationCadenasRetireApplicable = entity.consignationCadenasRetireApplicable;
    model.absenceConsignataireProcedureNA = entity.absenceConsignataireProcedureNA;
    model.absenceConsignataireProcedureApplicable = entity.absenceConsignataireProcedureApplicable;
    model.consignataireAbsentProcedureAppliqueeNA = entity.consignataireAbsentProcedureAppliqueeNA;
    model.consignataireAbsentProcedureAppliqueeApplicable = entity.consignataireAbsentProcedureAppliqueeApplicable;
    model.materielEnleveZoneNettoyeeNA = entity.materielEnleveZoneNettoyeeNA;
    model.materielEnleveZoneNettoyeeApplicable = entity.materielEnleveZoneNettoyeeApplicable;
    model.risquesSupprimesEquipementPretNA = entity.risquesSupprimesEquipementPretNA;
    model.risquesSupprimesEquipementPretApplicable = entity.risquesSupprimesEquipementPretApplicable;
    model.autresPoints = entity.autresPoints;
    model.donneurOrdreSignature = entity.donneurOrdreSignature;
    model.chargeAffairesSignature = entity.chargeAffairesSignature;
    return model;
  }
}

class JsaMapper {
  static JsaEntity toEntity(JSA model) {
    return JsaEntity(
      missionId: model.missionId,
      operationEffectuer: model.operationEffectuer,
      inspecteurs: model.inspecteurs.map(JsaInspecteurMapper.toEntity).toList(),
      planUrgence: JsaPlanUrgenceMapper.toEntity(model.planUrgence),
      dangers: JsaDangersMapper.toEntity(model.dangers),
      exigencesGenerales: JsaExigencesGeneralesMapper.toEntity(model.exigencesGenerales),
      epi: JsaEpiMapper.toEntity(model.epi),
      verificationFinale: JsaVerificationFinaleMapper.toEntity(model.verificationFinale),
      updatedAt: model.updatedAt,
      currentSubCategory: model.currentSubCategory,
    );
  }

  static JSA toModel(JsaEntity entity) {
    return JSA(
      missionId: entity.missionId,
      operationEffectuer: entity.operationEffectuer,
      inspecteurs: entity.inspecteurs.map(JsaInspecteurMapper.toModel).toList(),
      planUrgence: JsaPlanUrgenceMapper.toModel(entity.planUrgence),
      dangers: JsaDangersMapper.toModel(entity.dangers),
      exigencesGenerales: JsaExigencesGeneralesMapper.toModel(entity.exigencesGenerales),
      epi: JsaEpiMapper.toModel(entity.epi),
      verificationFinale: JsaVerificationFinaleMapper.toModel(entity.verificationFinale),
      updatedAt: entity.updatedAt,
      currentSubCategory: entity.currentSubCategory,
    );
  }
}
