// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jsa.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JSAInspecteurAdapter extends TypeAdapter<JSAInspecteur> {
  @override
  final int typeId = 40;

  @override
  JSAInspecteur read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JSAInspecteur(
      nom: fields[0] as String,
      prenom: fields[1] as String,
      signature: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, JSAInspecteur obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.nom)
      ..writeByte(1)
      ..write(obj.prenom)
      ..writeByte(2)
      ..write(obj.signature);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JSAInspecteurAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class JSAPlanUrgenceAdapter extends TypeAdapter<JSAPlanUrgence> {
  @override
  final int typeId = 41;

  @override
  JSAPlanUrgence read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JSAPlanUrgence(
      voiesIssuesIdentifiees: fields[0] as bool,
      zonesRassemblementIdentifiees: fields[1] as bool,
      consignesSecuriteInternes: fields[2] as bool,
      personneContactClient: fields[3] as String,
      personneContactKES: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, JSAPlanUrgence obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.voiesIssuesIdentifiees)
      ..writeByte(1)
      ..write(obj.zonesRassemblementIdentifiees)
      ..writeByte(2)
      ..write(obj.consignesSecuriteInternes)
      ..writeByte(3)
      ..write(obj.personneContactClient)
      ..writeByte(4)
      ..write(obj.personneContactKES);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JSAPlanUrgenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class JSADangersAdapter extends TypeAdapter<JSADangers> {
  @override
  final int typeId = 42;

  @override
  JSADangers read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JSADangers()
      ..chocElectrique = fields[0] as bool
      ..bruit = fields[1] as bool
      ..stressThermique = fields[2] as bool
      ..eclairageInadapte = fields[3] as bool
      ..zoneCirculationMalDefinie = fields[4] as bool
      ..solAccidente = fields[5] as bool
      ..emissionGazPoussiere = fields[6] as bool
      ..espaceConfine = fields[7] as bool
      ..autreEnvironnement = fields[8] as String
      ..chuteObjets = fields[9] as bool
      ..coactivite = fields[10] as bool
      ..portCharge = fields[11] as bool
      ..expositionProduitsChimiques = fields[12] as bool
      ..chuteHauteur = fields[13] as bool
      ..electrification = fields[14] as bool
      ..incendiesExplosion = fields[15] as bool
      ..mauvaisesPostures = fields[16] as bool
      ..chutePlainPied = fields[17] as bool
      ..autrePhysique = fields[18] as String;
  }

  @override
  void write(BinaryWriter writer, JSADangers obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.chocElectrique)
      ..writeByte(1)
      ..write(obj.bruit)
      ..writeByte(2)
      ..write(obj.stressThermique)
      ..writeByte(3)
      ..write(obj.eclairageInadapte)
      ..writeByte(4)
      ..write(obj.zoneCirculationMalDefinie)
      ..writeByte(5)
      ..write(obj.solAccidente)
      ..writeByte(6)
      ..write(obj.emissionGazPoussiere)
      ..writeByte(7)
      ..write(obj.espaceConfine)
      ..writeByte(8)
      ..write(obj.autreEnvironnement)
      ..writeByte(9)
      ..write(obj.chuteObjets)
      ..writeByte(10)
      ..write(obj.coactivite)
      ..writeByte(11)
      ..write(obj.portCharge)
      ..writeByte(12)
      ..write(obj.expositionProduitsChimiques)
      ..writeByte(13)
      ..write(obj.chuteHauteur)
      ..writeByte(14)
      ..write(obj.electrification)
      ..writeByte(15)
      ..write(obj.incendiesExplosion)
      ..writeByte(16)
      ..write(obj.mauvaisesPostures)
      ..writeByte(17)
      ..write(obj.chutePlainPied)
      ..writeByte(18)
      ..write(obj.autrePhysique);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JSADangersAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class JSAExigencesGeneralesAdapter extends TypeAdapter<JSAExigencesGenerales> {
  @override
  final int typeId = 43;

  @override
  JSAExigencesGenerales read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JSAExigencesGenerales()
      ..signaletiqueSecurite = fields[0] as bool
      ..ficheDonneeSecuriteDisponible = fields[1] as bool
      ..uneMinuteMaSecurite = fields[2] as bool
      ..balise = fields[3] as bool
      ..zoneTravailPropre = fields[4] as bool
      ..toolboxMeeting = fields[5] as bool
      ..permisTravail = fields[6] as bool
      ..extincteurs = fields[7] as bool
      ..outilsMaterielsIsolants = fields[8] as bool
      ..boitePharmacie = fields[9] as bool
      ..autre = fields[10] as String;
  }

  @override
  void write(BinaryWriter writer, JSAExigencesGenerales obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.signaletiqueSecurite)
      ..writeByte(1)
      ..write(obj.ficheDonneeSecuriteDisponible)
      ..writeByte(2)
      ..write(obj.uneMinuteMaSecurite)
      ..writeByte(3)
      ..write(obj.balise)
      ..writeByte(4)
      ..write(obj.zoneTravailPropre)
      ..writeByte(5)
      ..write(obj.toolboxMeeting)
      ..writeByte(6)
      ..write(obj.permisTravail)
      ..writeByte(7)
      ..write(obj.extincteurs)
      ..writeByte(8)
      ..write(obj.outilsMaterielsIsolants)
      ..writeByte(9)
      ..write(obj.boitePharmacie)
      ..writeByte(10)
      ..write(obj.autre);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JSAExigencesGeneralesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class JSAEPIAdapter extends TypeAdapter<JSAEPI> {
  @override
  final int typeId = 44;

  @override
  JSAEPI read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JSAEPI()
      ..casqueSecurite = fields[0] as bool
      ..bouchonsOreille = fields[1] as bool
      ..lunettesProtection = fields[2] as bool
      ..harnaisSecurite = fields[3] as bool
      ..chaussureSecurite = fields[4] as bool
      ..masqueSecurite = fields[5] as bool
      ..combinaisonLongueManche = fields[6] as bool
      ..gantsIsolants = fields[7] as bool
      ..cacheNez = fields[8] as bool
      ..gilet = fields[9] as bool
      ..autre = fields[10] as String;
  }

  @override
  void write(BinaryWriter writer, JSAEPI obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.casqueSecurite)
      ..writeByte(1)
      ..write(obj.bouchonsOreille)
      ..writeByte(2)
      ..write(obj.lunettesProtection)
      ..writeByte(3)
      ..write(obj.harnaisSecurite)
      ..writeByte(4)
      ..write(obj.chaussureSecurite)
      ..writeByte(5)
      ..write(obj.masqueSecurite)
      ..writeByte(6)
      ..write(obj.combinaisonLongueManche)
      ..writeByte(7)
      ..write(obj.gantsIsolants)
      ..writeByte(8)
      ..write(obj.cacheNez)
      ..writeByte(9)
      ..write(obj.gilet)
      ..writeByte(10)
      ..write(obj.autre);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JSAEPIAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class JSAVerificationFinaleAdapter extends TypeAdapter<JSAVerificationFinale> {
  @override
  final int typeId = 45;

  @override
  JSAVerificationFinale read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JSAVerificationFinale()
      ..travailTermineNA = fields[0] as bool
      ..travailTermineApplicable = fields[1] as bool
      ..consignationCadenasRetireNA = fields[2] as bool
      ..consignationCadenasRetireApplicable = fields[3] as bool
      ..absenceConsignataireProcedureNA = fields[4] as bool
      ..absenceConsignataireProcedureApplicable = fields[5] as bool
      ..consignataireAbsentProcedureAppliqueeNA = fields[6] as bool
      ..consignataireAbsentProcedureAppliqueeApplicable = fields[7] as bool
      ..materielEnleveZoneNettoyeeNA = fields[8] as bool
      ..materielEnleveZoneNettoyeeApplicable = fields[9] as bool
      ..risquesSupprimesEquipementPretNA = fields[10] as bool
      ..risquesSupprimesEquipementPretApplicable = fields[11] as bool
      ..autresPoints = fields[12] as String
      ..donneurOrdreSignature = fields[13] as String
      ..chargeAffairesSignature = fields[14] as String;
  }

  @override
  void write(BinaryWriter writer, JSAVerificationFinale obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.travailTermineNA)
      ..writeByte(1)
      ..write(obj.travailTermineApplicable)
      ..writeByte(2)
      ..write(obj.consignationCadenasRetireNA)
      ..writeByte(3)
      ..write(obj.consignationCadenasRetireApplicable)
      ..writeByte(4)
      ..write(obj.absenceConsignataireProcedureNA)
      ..writeByte(5)
      ..write(obj.absenceConsignataireProcedureApplicable)
      ..writeByte(6)
      ..write(obj.consignataireAbsentProcedureAppliqueeNA)
      ..writeByte(7)
      ..write(obj.consignataireAbsentProcedureAppliqueeApplicable)
      ..writeByte(8)
      ..write(obj.materielEnleveZoneNettoyeeNA)
      ..writeByte(9)
      ..write(obj.materielEnleveZoneNettoyeeApplicable)
      ..writeByte(10)
      ..write(obj.risquesSupprimesEquipementPretNA)
      ..writeByte(11)
      ..write(obj.risquesSupprimesEquipementPretApplicable)
      ..writeByte(12)
      ..write(obj.autresPoints)
      ..writeByte(13)
      ..write(obj.donneurOrdreSignature)
      ..writeByte(14)
      ..write(obj.chargeAffairesSignature);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JSAVerificationFinaleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class JSAAdapter extends TypeAdapter<JSA> {
  @override
  final int typeId = 39;

  @override
  JSA read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JSA(
      missionId: fields[0] as String,
      operationEffectuer: fields[1] as String,
      inspecteurs: (fields[2] as List?)?.cast<JSAInspecteur>(),
      planUrgence: fields[3] as JSAPlanUrgence?,
      dangers: fields[4] as JSADangers?,
      exigencesGenerales: fields[5] as JSAExigencesGenerales?,
      epi: fields[6] as JSAEPI?,
      verificationFinale: fields[7] as JSAVerificationFinale?,
      updatedAt: fields[8] as DateTime?,
      currentSubCategory: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, JSA obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.missionId)
      ..writeByte(1)
      ..write(obj.operationEffectuer)
      ..writeByte(2)
      ..write(obj.inspecteurs)
      ..writeByte(3)
      ..write(obj.planUrgence)
      ..writeByte(4)
      ..write(obj.dangers)
      ..writeByte(5)
      ..write(obj.exigencesGenerales)
      ..writeByte(6)
      ..write(obj.epi)
      ..writeByte(7)
      ..write(obj.verificationFinale)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.currentSubCategory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JSAAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
