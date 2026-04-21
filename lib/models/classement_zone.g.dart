// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classement_zone.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClassementZoneAdapter extends TypeAdapter<ClassementZone> {
  @override
  final int typeId = 46;

  @override
  ClassementZone read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassementZone(
      missionId: fields[0] as String,
      nomZone: fields[1] as String,
      origineClassement: fields[2] as String,
      af: fields[3] as String?,
      be: fields[4] as String?,
      ae: fields[5] as String?,
      ad: fields[6] as String?,
      ag: fields[7] as String?,
      ip: fields[8] as String?,
      ik: fields[9] as String?,
      updatedAt: fields[10] as DateTime,
      typeZone: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ClassementZone obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.missionId)
      ..writeByte(1)
      ..write(obj.nomZone)
      ..writeByte(2)
      ..write(obj.origineClassement)
      ..writeByte(3)
      ..write(obj.af)
      ..writeByte(4)
      ..write(obj.be)
      ..writeByte(5)
      ..write(obj.ae)
      ..writeByte(6)
      ..write(obj.ad)
      ..writeByte(7)
      ..write(obj.ag)
      ..writeByte(8)
      ..write(obj.ip)
      ..writeByte(9)
      ..write(obj.ik)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.typeZone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassementZoneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
