// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'renseignements_generaux.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RenseignementsGenerauxAdapter
    extends TypeAdapter<RenseignementsGeneraux> {
  @override
  final int typeId = 34;

  @override
  RenseignementsGeneraux read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RenseignementsGeneraux(
      missionId: fields[0] as String,
      etablissement: fields[1] as String,
      installation: fields[2] as String,
      activite: fields[3] as String,
      dateDebut: fields[4] as DateTime?,
      dateFin: fields[5] as DateTime?,
      dureeJours: fields[6] as int,
      verificationType: fields[7] as String?,
      registreControle: fields[8] as String,
      compteRendu: (fields[9] as List?)?.cast<String>(),
      accompagnateurs: (fields[10] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, String>())
          ?.toList(),
      verificateurs: (fields[11] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, String>())
          ?.toList(),
      updatedAt: fields[12] as DateTime,
      nomSite: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RenseignementsGeneraux obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.missionId)
      ..writeByte(1)
      ..write(obj.etablissement)
      ..writeByte(2)
      ..write(obj.installation)
      ..writeByte(3)
      ..write(obj.activite)
      ..writeByte(4)
      ..write(obj.dateDebut)
      ..writeByte(5)
      ..write(obj.dateFin)
      ..writeByte(6)
      ..write(obj.dureeJours)
      ..writeByte(7)
      ..write(obj.verificationType)
      ..writeByte(8)
      ..write(obj.registreControle)
      ..writeByte(9)
      ..write(obj.compteRendu)
      ..writeByte(10)
      ..write(obj.accompagnateurs)
      ..writeByte(11)
      ..write(obj.verificateurs)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.nomSite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RenseignementsGenerauxAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
