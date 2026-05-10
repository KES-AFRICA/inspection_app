// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'description_installations.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DescriptionInstallationsAdapter
    extends TypeAdapter<DescriptionInstallations> {
  @override
  final int typeId = 2;

  @override
  DescriptionInstallations read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DescriptionInstallations(
      missionId: fields[0] as String,
      alimentationMoyenneTension:
          (fields[1] as List?)?.cast<InstallationItem>(),
      alimentationBasseTension: (fields[2] as List?)?.cast<InstallationItem>(),
      groupeElectrogene: (fields[3] as List?)?.cast<InstallationItem>(),
      alimentationCarburant: (fields[4] as List?)?.cast<InstallationItem>(),
      inverseur: (fields[5] as List?)?.cast<InstallationItem>(),
      stabilisateur: (fields[6] as List?)?.cast<InstallationItem>(),
      onduleurs: (fields[7] as List?)?.cast<InstallationItem>(),
      regimeNeutre: fields[8] as String?,
      regimeNeutreDetail: fields[17] as String?,
      eclairageSecurite: fields[9] as String?,
      modificationsInstallations: fields[10] as String?,
      noteCalcul: fields[11] as String?,
      registreSecurite: fields[12] as String?,
      presenceParatonnerre: fields[13] as String?,
      analyseRisqueFoudre: fields[14] as String?,
      etudeTechniqueFoudre: fields[15] as String?,
      updatedAt: fields[16] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DescriptionInstallations obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.missionId)
      ..writeByte(1)
      ..write(obj.alimentationMoyenneTension)
      ..writeByte(2)
      ..write(obj.alimentationBasseTension)
      ..writeByte(3)
      ..write(obj.groupeElectrogene)
      ..writeByte(4)
      ..write(obj.alimentationCarburant)
      ..writeByte(5)
      ..write(obj.inverseur)
      ..writeByte(6)
      ..write(obj.stabilisateur)
      ..writeByte(7)
      ..write(obj.onduleurs)
      ..writeByte(8)
      ..write(obj.regimeNeutre)
      ..writeByte(17)
      ..write(obj.regimeNeutreDetail)
      ..writeByte(9)
      ..write(obj.eclairageSecurite)
      ..writeByte(10)
      ..write(obj.modificationsInstallations)
      ..writeByte(11)
      ..write(obj.noteCalcul)
      ..writeByte(12)
      ..write(obj.registreSecurite)
      ..writeByte(13)
      ..write(obj.presenceParatonnerre)
      ..writeByte(14)
      ..write(obj.analyseRisqueFoudre)
      ..writeByte(15)
      ..write(obj.etudeTechniqueFoudre)
      ..writeByte(16)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DescriptionInstallationsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InstallationItemAdapter extends TypeAdapter<InstallationItem> {
  @override
  final int typeId = 25;

  @override
  InstallationItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallationItem(
      data: (fields[0] as Map).cast<String, String>(),
      photoPaths: (fields[1] as List?)?.cast<String>(),
      createdAt: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, InstallationItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.data)
      ..writeByte(1)
      ..write(obj.photoPaths)
      ..writeByte(2)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
