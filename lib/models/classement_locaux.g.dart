// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classement_locaux.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClassementEmplacementAdapter extends TypeAdapter<ClassementEmplacement> {
  @override
  final int typeId = 14;

  @override
  ClassementEmplacement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassementEmplacement(
      missionId: fields[0] as String,
      localisation: fields[1] as String,
      zone: fields[2] as String?,
      origineClassement: fields[3] as String,
      af: fields[4] as String?,
      be: fields[5] as String?,
      ae: fields[6] as String?,
      ad: fields[7] as String?,
      ag: fields[8] as String?,
      ip: fields[9] as String?,
      ik: fields[10] as String?,
      updatedAt: fields[11] as DateTime,
      typeLocal: fields[12] as String?,
      typeEmplacement: fields[13] as String,
      heriteDeZone: fields[14] as bool,
      zoneParenteId: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ClassementEmplacement obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.missionId)
      ..writeByte(1)
      ..write(obj.localisation)
      ..writeByte(2)
      ..write(obj.zone)
      ..writeByte(3)
      ..write(obj.origineClassement)
      ..writeByte(4)
      ..write(obj.af)
      ..writeByte(5)
      ..write(obj.be)
      ..writeByte(6)
      ..write(obj.ae)
      ..writeByte(7)
      ..write(obj.ad)
      ..writeByte(8)
      ..write(obj.ag)
      ..writeByte(9)
      ..write(obj.ip)
      ..writeByte(10)
      ..write(obj.ik)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.typeLocal)
      ..writeByte(13)
      ..write(obj.typeEmplacement)
      ..writeByte(14)
      ..write(obj.heriteDeZone)
      ..writeByte(15)
      ..write(obj.zoneParenteId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassementEmplacementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
