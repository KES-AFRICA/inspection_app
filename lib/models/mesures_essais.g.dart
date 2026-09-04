// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mesures_essais.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MesuresEssaisAdapter extends TypeAdapter<MesuresEssais> {
  @override
  final int typeId = 16;

  @override
  MesuresEssais read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MesuresEssais(
      missionId: fields[0] as String,
      updatedAt: fields[1] as DateTime,
      createdAt: fields[20] as DateTime?,
      conditionMesure: fields[2] as ConditionMesure?,
      essaiDemarrageAuto: fields[3] as EssaiDemarrageAuto?,
      testArretUrgence: fields[4] as TestArretUrgence?,
      prisesTerre: (fields[5] as List?)?.cast<PriseTerre>(),
      avisMesuresTerre: fields[6] as AvisMesuresTerre?,
      essaisDeclenchement:
          (fields[7] as List?)?.cast<EssaiDeclenchementDifferentiel>(),
      essaisIsolement:
          fields[9] == null ? [] : (fields[9] as List?)?.cast<EssaiIsolement>(),
      continuiteResistances: (fields[8] as List?)?.cast<ContinuiteResistance>(),
    );
  }

  @override
  void write(BinaryWriter writer, MesuresEssais obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.missionId)
      ..writeByte(1)
      ..write(obj.updatedAt)
      ..writeByte(20)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.conditionMesure)
      ..writeByte(3)
      ..write(obj.essaiDemarrageAuto)
      ..writeByte(4)
      ..write(obj.testArretUrgence)
      ..writeByte(5)
      ..write(obj.prisesTerre)
      ..writeByte(6)
      ..write(obj.avisMesuresTerre)
      ..writeByte(7)
      ..write(obj.essaisDeclenchement)
      ..writeByte(9)
      ..write(obj.essaisIsolement)
      ..writeByte(8)
      ..write(obj.continuiteResistances);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MesuresEssaisAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConditionMesureAdapter extends TypeAdapter<ConditionMesure> {
  @override
  final int typeId = 17;

  @override
  ConditionMesure read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConditionMesure(
      observation: fields[0] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ConditionMesure obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.observation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConditionMesureAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EssaiDemarrageAutoAdapter extends TypeAdapter<EssaiDemarrageAuto> {
  @override
  final int typeId = 18;

  @override
  EssaiDemarrageAuto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EssaiDemarrageAuto(
      observation: fields[0] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EssaiDemarrageAuto obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.observation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EssaiDemarrageAutoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TestArretUrgenceAdapter extends TypeAdapter<TestArretUrgence> {
  @override
  final int typeId = 19;

  @override
  TestArretUrgence read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TestArretUrgence(
      observation: fields[0] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TestArretUrgence obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.observation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestArretUrgenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PriseTerreAdapter extends TypeAdapter<PriseTerre> {
  @override
  final int typeId = 20;

  @override
  PriseTerre read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PriseTerre(
      id: fields[20] as String?,
      localisation: fields[0] as String,
      identification: fields[1] as String,
      conditionPriseTerre: fields[2] as String,
      naturePriseTerre: fields[3] as String,
      methodeMesure: fields[4] as String,
      valeurMesure: fields[5] as double?,
      observation: fields[6] as String?,
      interconnecteAutrePrise: fields[7] as String?,
      photo: fields[8] as String?,
      createdAt: fields[21] as DateTime?,
      updatedAt: fields[22] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PriseTerre obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.localisation)
      ..writeByte(1)
      ..write(obj.identification)
      ..writeByte(2)
      ..write(obj.conditionPriseTerre)
      ..writeByte(3)
      ..write(obj.naturePriseTerre)
      ..writeByte(4)
      ..write(obj.methodeMesure)
      ..writeByte(5)
      ..write(obj.valeurMesure)
      ..writeByte(6)
      ..write(obj.observation)
      ..writeByte(7)
      ..write(obj.interconnecteAutrePrise)
      ..writeByte(8)
      ..write(obj.photo)
      ..writeByte(20)
      ..write(obj.id)
      ..writeByte(21)
      ..write(obj.createdAt)
      ..writeByte(22)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriseTerreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AvisMesuresTerreAdapter extends TypeAdapter<AvisMesuresTerre> {
  @override
  final int typeId = 21;

  @override
  AvisMesuresTerre read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AvisMesuresTerre(
      satisfaisants: (fields[0] as List?)?.cast<String>(),
      nonSatisfaisants: (fields[1] as List?)?.cast<String>(),
      observation: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AvisMesuresTerre obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.satisfaisants)
      ..writeByte(1)
      ..write(obj.nonSatisfaisants)
      ..writeByte(2)
      ..write(obj.observation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvisMesuresTerreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EssaiDeclenchementDifferentielAdapter
    extends TypeAdapter<EssaiDeclenchementDifferentiel> {
  @override
  final int typeId = 22;

  @override
  EssaiDeclenchementDifferentiel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EssaiDeclenchementDifferentiel(
      id: fields[20] as String?,
      localisation: fields[0] as String,
      coffret: fields[1] as String?,
      designationCircuit: fields[2] as String?,
      typeDispositif: fields[3] as String,
      reglageIAn: fields[4] as double?,
      tempo: fields[5] as double?,
      isolement: fields[6] as double?,
      essai: fields[7] as String,
      observation: fields[8] as String?,
      calibre: fields[9] as double?,
      tempoText: fields[10] as String?,
      createdAt: fields[21] as DateTime?,
      updatedAt: fields[22] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, EssaiDeclenchementDifferentiel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.localisation)
      ..writeByte(1)
      ..write(obj.coffret)
      ..writeByte(2)
      ..write(obj.designationCircuit)
      ..writeByte(3)
      ..write(obj.typeDispositif)
      ..writeByte(4)
      ..write(obj.reglageIAn)
      ..writeByte(5)
      ..write(obj.tempo)
      ..writeByte(6)
      ..write(obj.isolement)
      ..writeByte(7)
      ..write(obj.essai)
      ..writeByte(8)
      ..write(obj.observation)
      ..writeByte(9)
      ..write(obj.calibre)
      ..writeByte(10)
      ..write(obj.tempoText)
      ..writeByte(20)
      ..write(obj.id)
      ..writeByte(21)
      ..write(obj.createdAt)
      ..writeByte(22)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EssaiDeclenchementDifferentielAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContinuiteResistanceAdapter extends TypeAdapter<ContinuiteResistance> {
  @override
  final int typeId = 23;

  @override
  ContinuiteResistance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContinuiteResistance(
      id: fields[20] as String?,
      localisation: fields[0] as String,
      designationTableau: fields[1] as String,
      origineMesure: fields[2] as String,
      observation: fields[3] as String?,
      essai: fields[4] as String?,
      createdAt: fields[21] as DateTime?,
      updatedAt: fields[22] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ContinuiteResistance obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.localisation)
      ..writeByte(1)
      ..write(obj.designationTableau)
      ..writeByte(2)
      ..write(obj.origineMesure)
      ..writeByte(3)
      ..write(obj.observation)
      ..writeByte(4)
      ..write(obj.essai)
      ..writeByte(20)
      ..write(obj.id)
      ..writeByte(21)
      ..write(obj.createdAt)
      ..writeByte(22)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContinuiteResistanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EssaiIsolementAdapter extends TypeAdapter<EssaiIsolement> {
  @override
  final int typeId = 63;

  @override
  EssaiIsolement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EssaiIsolement(
      syncId: fields[0] as String,
      equipmentSyncId: fields[1] as String?,
      pointControle: fields[2] as String?,
      isolement: fields[3] as double,
      appreciation: fields[4] as String,
      localisation: fields[5] as String?,
      designation: fields[6] as String?,
      reperePointOrigine: fields[7] as String?,
      pointA: fields[8] as String?,
      pointB: fields[9] as String?,
      sectionCable: fields[10] as String?,
      nombreCablesTestes: fields[11] as int?,
      sectionCablePointA: fields[12] as String?,
      sectionCablePointB: fields[13] as String?,
      isSectionPointAManual: fields[14] as bool?,
      isSectionPointBManual: fields[15] as bool?,
      equipmentPointASyncId: fields[16] as String?,
      equipmentPointBSyncId: fields[17] as String?,
      zonePointA: fields[18] as String?,
      reperePointA: fields[19] as String?,
      nomEquipementPointA: fields[22] as String?,
      zonePointB: fields[23] as String?,
      reperePointB: fields[24] as String?,
      nomEquipementPointB: fields[25] as String?,
      createdAt: fields[20] as DateTime?,
      updatedAt: fields[21] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, EssaiIsolement obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.syncId)
      ..writeByte(1)
      ..write(obj.equipmentSyncId)
      ..writeByte(2)
      ..write(obj.pointControle)
      ..writeByte(3)
      ..write(obj.isolement)
      ..writeByte(4)
      ..write(obj.appreciation)
      ..writeByte(5)
      ..write(obj.localisation)
      ..writeByte(6)
      ..write(obj.designation)
      ..writeByte(7)
      ..write(obj.reperePointOrigine)
      ..writeByte(8)
      ..write(obj.pointA)
      ..writeByte(9)
      ..write(obj.pointB)
      ..writeByte(10)
      ..write(obj.sectionCable)
      ..writeByte(11)
      ..write(obj.nombreCablesTestes)
      ..writeByte(12)
      ..write(obj.sectionCablePointA)
      ..writeByte(13)
      ..write(obj.sectionCablePointB)
      ..writeByte(14)
      ..write(obj.isSectionPointAManual)
      ..writeByte(15)
      ..write(obj.isSectionPointBManual)
      ..writeByte(16)
      ..write(obj.equipmentPointASyncId)
      ..writeByte(17)
      ..write(obj.equipmentPointBSyncId)
      ..writeByte(18)
      ..write(obj.zonePointA)
      ..writeByte(19)
      ..write(obj.reperePointA)
      ..writeByte(22)
      ..write(obj.nomEquipementPointA)
      ..writeByte(23)
      ..write(obj.zonePointB)
      ..writeByte(24)
      ..write(obj.reperePointB)
      ..writeByte(25)
      ..write(obj.nomEquipementPointB)
      ..writeByte(20)
      ..write(obj.createdAt)
      ..writeByte(21)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EssaiIsolementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
