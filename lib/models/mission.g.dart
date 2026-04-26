// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MissionAdapter extends TypeAdapter<Mission> {
  @override
  final int typeId = 1;

  @override
  Mission read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Mission(
      id: fields[0] as String,
      nomClient: fields[1] as String,
      activiteClient: fields[2] as String?,
      adresseClient: fields[3] as String?,
      logoClient: fields[4] as String?,
      accompagnateurs: (fields[5] as List?)?.cast<String>(),
      verificateurs: (fields[6] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
      dgResponsable: fields[7] as String?,
      dateIntervention: fields[8] as DateTime?,
      dateRapport: fields[9] as DateTime?,
      natureMission: fields[10] as String?,
      periodicite: fields[11] as String?,
      dureeMissionJours: fields[12] as int?,
      docCahierPrescriptions: fields[13] as bool,
      docNotesCalculs: fields[14] as bool,
      docSchemasUnifilaires: fields[15] as bool,
      docPlanMasse: fields[16] as bool,
      docPlansArchitecturaux: fields[17] as bool,
      docDeclarationsCe: fields[18] as bool,
      docListeInstallations: fields[19] as bool,
      docPlanLocauxRisques: fields[20] as bool,
      docRapportAnalyseFoudre: fields[21] as bool,
      docRapportEtudeFoudre: fields[22] as bool,
      docRegistreSecurite: fields[23] as bool,
      docRapportDerniereVerif: fields[24] as bool,
      createdAt: fields[25] as DateTime,
      updatedAt: fields[26] as DateTime,
      status: fields[27] as String,
      descriptionInstallationsId: fields[28] as String?,
      auditInstallationsElectriquesId: fields[29] as String?,
      docAutre: fields[30] as bool,
      classementLocauxId: fields[31] as String?,
      foudreIds: (fields[32] as List?)?.cast<String>(),
      mesuresEssaisId: fields[33] as String?,
      nomSite: fields[35] as String?,
    )
      ..renseignementsGenerauxId = fields[34] as String?
      ..jsaId = fields[36] as String?
      ..schemaOption = fields[37] as String?;
  }

  @override
  void write(BinaryWriter writer, Mission obj) {
    writer
      ..writeByte(38)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nomClient)
      ..writeByte(2)
      ..write(obj.activiteClient)
      ..writeByte(3)
      ..write(obj.adresseClient)
      ..writeByte(4)
      ..write(obj.logoClient)
      ..writeByte(5)
      ..write(obj.accompagnateurs)
      ..writeByte(6)
      ..write(obj.verificateurs)
      ..writeByte(7)
      ..write(obj.dgResponsable)
      ..writeByte(8)
      ..write(obj.dateIntervention)
      ..writeByte(9)
      ..write(obj.dateRapport)
      ..writeByte(10)
      ..write(obj.natureMission)
      ..writeByte(11)
      ..write(obj.periodicite)
      ..writeByte(12)
      ..write(obj.dureeMissionJours)
      ..writeByte(13)
      ..write(obj.docCahierPrescriptions)
      ..writeByte(14)
      ..write(obj.docNotesCalculs)
      ..writeByte(15)
      ..write(obj.docSchemasUnifilaires)
      ..writeByte(16)
      ..write(obj.docPlanMasse)
      ..writeByte(17)
      ..write(obj.docPlansArchitecturaux)
      ..writeByte(18)
      ..write(obj.docDeclarationsCe)
      ..writeByte(19)
      ..write(obj.docListeInstallations)
      ..writeByte(20)
      ..write(obj.docPlanLocauxRisques)
      ..writeByte(21)
      ..write(obj.docRapportAnalyseFoudre)
      ..writeByte(22)
      ..write(obj.docRapportEtudeFoudre)
      ..writeByte(23)
      ..write(obj.docRegistreSecurite)
      ..writeByte(24)
      ..write(obj.docRapportDerniereVerif)
      ..writeByte(25)
      ..write(obj.createdAt)
      ..writeByte(26)
      ..write(obj.updatedAt)
      ..writeByte(27)
      ..write(obj.status)
      ..writeByte(28)
      ..write(obj.descriptionInstallationsId)
      ..writeByte(29)
      ..write(obj.auditInstallationsElectriquesId)
      ..writeByte(30)
      ..write(obj.docAutre)
      ..writeByte(31)
      ..write(obj.classementLocauxId)
      ..writeByte(32)
      ..write(obj.foudreIds)
      ..writeByte(33)
      ..write(obj.mesuresEssaisId)
      ..writeByte(34)
      ..write(obj.renseignementsGenerauxId)
      ..writeByte(35)
      ..write(obj.nomSite)
      ..writeByte(36)
      ..write(obj.jsaId)
      ..writeByte(37)
      ..write(obj.schemaOption);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
