// GENERATED CODE - MANUAL HIVE ADAPTER FOR TRASHITEM
part of 'trash_item.dart';

class TrashItemAdapter extends TypeAdapter<TrashItem> {
  @override
  final int typeId = 35;

  @override
  TrashItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrashItem(
      id: fields[0] as String,
      entityType: fields[1] as String,
      entityId: fields[2] as String,
      missionId: fields[3] as String?,
      title: fields[4] as String,
      subtitle: fields[5] as String?,
      deletedAt: fields[6] as DateTime,
      deletedBy: fields[7] as String?,
      parentEntityId: fields[8] as String?,
      parentEntityType: fields[9] as String?,
      serializedPayload: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TrashItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entityType)
      ..writeByte(2)
      ..write(obj.entityId)
      ..writeByte(3)
      ..write(obj.missionId)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.subtitle)
      ..writeByte(6)
      ..write(obj.deletedAt)
      ..writeByte(7)
      ..write(obj.deletedBy)
      ..writeByte(8)
      ..write(obj.parentEntityId)
      ..writeByte(9)
      ..write(obj.parentEntityType)
      ..writeByte(10)
      ..write(obj.serializedPayload);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrashItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
