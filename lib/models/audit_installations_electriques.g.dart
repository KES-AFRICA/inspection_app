// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_installations_electriques.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuditInstallationsElectriquesAdapter
    extends TypeAdapter<AuditInstallationsElectriques> {
  @override
  final int typeId = 3;

  @override
  AuditInstallationsElectriques read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuditInstallationsElectriques(
      missionId: fields[0] as String,
      updatedAt: fields[1] as DateTime,
      moyenneTensionLocaux: (fields[2] as List?)?.cast<MoyenneTensionLocal>(),
      moyenneTensionZones: (fields[3] as List?)?.cast<MoyenneTensionZone>(),
      basseTensionZones: (fields[4] as List?)?.cast<BasseTensionZone>(),
      photos: (fields[15] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, AuditInstallationsElectriques obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.missionId)
      ..writeByte(1)
      ..write(obj.updatedAt)
      ..writeByte(2)
      ..write(obj.moyenneTensionLocaux)
      ..writeByte(3)
      ..write(obj.moyenneTensionZones)
      ..writeByte(4)
      ..write(obj.basseTensionZones)
      ..writeByte(15)
      ..write(obj.photos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditInstallationsElectriquesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MoyenneTensionLocalAdapter extends TypeAdapter<MoyenneTensionLocal> {
  @override
  final int typeId = 4;

  @override
  MoyenneTensionLocal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoyenneTensionLocal(
      nom: fields[0] as String,
      type: fields[1] as String,
      dispositionsConstructives: (fields[2] as List?)?.cast<ElementControle>(),
      conditionsExploitation: (fields[3] as List?)?.cast<ElementControle>(),
      cellule: fields[4] as Cellule?,
      transformateur: fields[5] as TransformateurMTBT?,
      coffrets: (fields[6] as List?)?.cast<CoffretArmoire>(),
      observationsLibres: (fields[7] as List?)?.cast<ObservationLibre>(),
      photos: (fields[8] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, MoyenneTensionLocal obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.nom)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.dispositionsConstructives)
      ..writeByte(3)
      ..write(obj.conditionsExploitation)
      ..writeByte(4)
      ..write(obj.cellule)
      ..writeByte(5)
      ..write(obj.transformateur)
      ..writeByte(6)
      ..write(obj.coffrets)
      ..writeByte(7)
      ..write(obj.observationsLibres)
      ..writeByte(8)
      ..write(obj.photos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoyenneTensionLocalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MoyenneTensionZoneAdapter extends TypeAdapter<MoyenneTensionZone> {
  @override
  final int typeId = 5;

  @override
  MoyenneTensionZone read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoyenneTensionZone(
      nom: fields[0] as String,
      description: fields[1] as String?,
      coffrets: (fields[2] as List?)?.cast<CoffretArmoire>(),
      observationsLibres: (fields[3] as List?)?.cast<ObservationLibre>(),
      photos: (fields[4] as List?)?.cast<String>(),
      locaux: (fields[5] as List?)?.cast<MoyenneTensionLocal>(),
      classementZoneId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MoyenneTensionZone obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.nom)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.coffrets)
      ..writeByte(3)
      ..write(obj.observationsLibres)
      ..writeByte(4)
      ..write(obj.photos)
      ..writeByte(5)
      ..write(obj.locaux)
      ..writeByte(6)
      ..write(obj.classementZoneId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoyenneTensionZoneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BasseTensionZoneAdapter extends TypeAdapter<BasseTensionZone> {
  @override
  final int typeId = 6;

  @override
  BasseTensionZone read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BasseTensionZone(
      nom: fields[0] as String,
      description: fields[1] as String?,
      locaux: (fields[2] as List?)?.cast<BasseTensionLocal>(),
      coffretsDirects: (fields[3] as List?)?.cast<CoffretArmoire>(),
      observationsLibres: (fields[4] as List?)?.cast<ObservationLibre>(),
      photos: (fields[5] as List?)?.cast<String>(),
      classementZoneId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BasseTensionZone obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.nom)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.locaux)
      ..writeByte(3)
      ..write(obj.coffretsDirects)
      ..writeByte(4)
      ..write(obj.observationsLibres)
      ..writeByte(5)
      ..write(obj.photos)
      ..writeByte(6)
      ..write(obj.classementZoneId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BasseTensionZoneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BasseTensionLocalAdapter extends TypeAdapter<BasseTensionLocal> {
  @override
  final int typeId = 7;

  @override
  BasseTensionLocal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BasseTensionLocal(
      nom: fields[0] as String,
      type: fields[1] as String,
      dispositionsConstructives: (fields[2] as List?)?.cast<ElementControle>(),
      conditionsExploitation: (fields[3] as List?)?.cast<ElementControle>(),
      coffrets: (fields[4] as List?)?.cast<CoffretArmoire>(),
      observationsLibres: (fields[5] as List?)?.cast<ObservationLibre>(),
      photos: (fields[6] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, BasseTensionLocal obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.nom)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.dispositionsConstructives)
      ..writeByte(3)
      ..write(obj.conditionsExploitation)
      ..writeByte(4)
      ..write(obj.coffrets)
      ..writeByte(5)
      ..write(obj.observationsLibres)
      ..writeByte(6)
      ..write(obj.photos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BasseTensionLocalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ElementControleAdapter extends TypeAdapter<ElementControle> {
  @override
  final int typeId = 8;

  @override
  ElementControle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ElementControle(
      elementControle: fields[0] as String,
      conforme: fields[1] as bool?,
      observation: fields[2] as String?,
      priorite: fields[3] as int?,
      photos: (fields[4] as List?)?.cast<String>(),
      referenceNormative: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ElementControle obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.elementControle)
      ..writeByte(1)
      ..write(obj.conforme)
      ..writeByte(2)
      ..write(obj.observation)
      ..writeByte(3)
      ..write(obj.priorite)
      ..writeByte(4)
      ..write(obj.photos)
      ..writeByte(5)
      ..write(obj.referenceNormative);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElementControleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CelluleAdapter extends TypeAdapter<Cellule> {
  @override
  final int typeId = 9;

  @override
  Cellule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Cellule(
      fonction: fields[0] as String,
      type: fields[1] as String,
      marqueModeleAnnee: fields[2] as String,
      tensionAssignee: fields[3] as String,
      pouvoirCoupure: fields[4] as String,
      numerotation: fields[5] as String,
      parafoudres: fields[6] as String,
      elementsVerifies: (fields[7] as List?)?.cast<ElementControle>(),
      photos: (fields[8] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Cellule obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.fonction)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.marqueModeleAnnee)
      ..writeByte(3)
      ..write(obj.tensionAssignee)
      ..writeByte(4)
      ..write(obj.pouvoirCoupure)
      ..writeByte(5)
      ..write(obj.numerotation)
      ..writeByte(6)
      ..write(obj.parafoudres)
      ..writeByte(7)
      ..write(obj.elementsVerifies)
      ..writeByte(8)
      ..write(obj.photos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CelluleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransformateurMTBTAdapter extends TypeAdapter<TransformateurMTBT> {
  @override
  final int typeId = 10;

  @override
  TransformateurMTBT read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransformateurMTBT(
      typeTransformateur: fields[0] as String,
      marqueAnnee: fields[1] as String,
      puissanceAssignee: fields[2] as String,
      tensionPrimaireSecondaire: fields[3] as String,
      relaisBuchholz: fields[4] as String,
      typeRefroidissement: fields[5] as String,
      regimeNeutre: fields[6] as String,
      elementsVerifies: (fields[7] as List?)?.cast<ElementControle>(),
      photos: (fields[8] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, TransformateurMTBT obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.typeTransformateur)
      ..writeByte(1)
      ..write(obj.marqueAnnee)
      ..writeByte(2)
      ..write(obj.puissanceAssignee)
      ..writeByte(3)
      ..write(obj.tensionPrimaireSecondaire)
      ..writeByte(4)
      ..write(obj.relaisBuchholz)
      ..writeByte(5)
      ..write(obj.typeRefroidissement)
      ..writeByte(6)
      ..write(obj.regimeNeutre)
      ..writeByte(7)
      ..write(obj.elementsVerifies)
      ..writeByte(8)
      ..write(obj.photos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransformateurMTBTAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CoffretArmoireAdapter extends TypeAdapter<CoffretArmoire> {
  @override
  final int typeId = 11;

  @override
  CoffretArmoire read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CoffretArmoire(
      qrCode: fields[0] as String,
      nom: fields[1] as String,
      type: fields[2] as String,
      description: fields[3] as String?,
      repere: fields[4] as String?,
      zoneAtex: fields[5] as bool,
      domaineTension: fields[6] as String,
      identificationArmoire: fields[7] as bool,
      signalisationDanger: fields[8] as bool,
      presenceSchema: fields[9] as bool,
      presenceParafoudre: fields[10] as bool,
      verificationThermographie: fields[11] as bool,
      alimentations: (fields[12] as List?)?.cast<Alimentation>(),
      protectionTete: fields[13] as Alimentation?,
      pointsVerification: (fields[14] as List?)?.cast<PointVerification>(),
      observationsLibres: (fields[15] as List?)?.cast<ObservationLibre>(),
      photos: (fields[16] as List?)?.cast<String>(),
      statut: fields[18] as String,
      currentStep: fields[19] as int,
      numeroEquipement: fields[17] as String?,
      photosExternes: (fields[20] as List?)?.cast<String>(),
      photosInternes: (fields[21] as List?)?.cast<String>(),
      observationsParafoudre: (fields[22] as List?)?.cast<ObservationLibre>(),
    );
  }

  @override
  void write(BinaryWriter writer, CoffretArmoire obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.qrCode)
      ..writeByte(1)
      ..write(obj.nom)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.repere)
      ..writeByte(5)
      ..write(obj.zoneAtex)
      ..writeByte(6)
      ..write(obj.domaineTension)
      ..writeByte(7)
      ..write(obj.identificationArmoire)
      ..writeByte(8)
      ..write(obj.signalisationDanger)
      ..writeByte(9)
      ..write(obj.presenceSchema)
      ..writeByte(10)
      ..write(obj.presenceParafoudre)
      ..writeByte(11)
      ..write(obj.verificationThermographie)
      ..writeByte(12)
      ..write(obj.alimentations)
      ..writeByte(13)
      ..write(obj.protectionTete)
      ..writeByte(14)
      ..write(obj.pointsVerification)
      ..writeByte(15)
      ..write(obj.observationsLibres)
      ..writeByte(16)
      ..write(obj.photos)
      ..writeByte(17)
      ..write(obj.numeroEquipement)
      ..writeByte(18)
      ..write(obj.statut)
      ..writeByte(19)
      ..write(obj.currentStep)
      ..writeByte(20)
      ..write(obj.photosExternes)
      ..writeByte(21)
      ..write(obj.photosInternes)
      ..writeByte(22)
      ..write(obj.observationsParafoudre);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoffretArmoireAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlimentationAdapter extends TypeAdapter<Alimentation> {
  @override
  final int typeId = 12;

  @override
  Alimentation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Alimentation(
      typeProtection: fields[0] as String,
      pdcKA: fields[1] as String,
      calibre: fields[2] as String,
      sectionCable: fields[3] as String,
      photos: (fields[4] as List?)?.cast<String>(),
      source: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Alimentation obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.typeProtection)
      ..writeByte(1)
      ..write(obj.pdcKA)
      ..writeByte(2)
      ..write(obj.calibre)
      ..writeByte(3)
      ..write(obj.sectionCable)
      ..writeByte(4)
      ..write(obj.photos)
      ..writeByte(5)
      ..write(obj.source);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlimentationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PointVerificationAdapter extends TypeAdapter<PointVerification> {
  @override
  final int typeId = 13;

  @override
  PointVerification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PointVerification(
      pointVerification: fields[0] as String,
      conformite: fields[1] as String,
      observation: fields[2] as String?,
      referenceNormative: fields[3] as String?,
      priorite: fields[4] as int?,
      photos: (fields[5] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PointVerification obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.pointVerification)
      ..writeByte(1)
      ..write(obj.conformite)
      ..writeByte(2)
      ..write(obj.observation)
      ..writeByte(3)
      ..write(obj.referenceNormative)
      ..writeByte(4)
      ..write(obj.priorite)
      ..writeByte(5)
      ..write(obj.photos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointVerificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ObservationLibreAdapter extends TypeAdapter<ObservationLibre> {
  @override
  final int typeId = 24;

  @override
  ObservationLibre read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ObservationLibre(
      texte: fields[0] as String,
      photos: (fields[1] as List?)?.cast<String>(),
      dateCreation: fields[2] as DateTime?,
      dateModification: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ObservationLibre obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.texte)
      ..writeByte(1)
      ..write(obj.photos)
      ..writeByte(2)
      ..write(obj.dateCreation)
      ..writeByte(3)
      ..write(obj.dateModification);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObservationLibreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
