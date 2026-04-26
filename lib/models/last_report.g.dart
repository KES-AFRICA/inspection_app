// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_report.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LastReportAdapter extends TypeAdapter<LastReport> {
  @override
  final int typeId = 50;

  @override
  LastReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LastReport(
      missionId: fields[0] as String,
      filePath: fields[1] as String,
      fileName: fields[2] as String,
      generatedAt: fields[3] as DateTime,
      reportType: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LastReport obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.missionId)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.fileName)
      ..writeByte(3)
      ..write(obj.generatedAt)
      ..writeByte(4)
      ..write(obj.reportType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LastReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
