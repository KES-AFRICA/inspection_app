import 'package:hive/hive.dart';

part 'trash_item.g.dart';

@HiveType(typeId: 35)
class TrashItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String entityType; // 'mission', 'jsa', 'lighting_inspection', 'zone', 'local', 'equipement', 'foudre', 'mesures'

  @HiveField(2)
  String entityId;

  @HiveField(3)
  String? missionId;

  @HiveField(4)
  String title;

  @HiveField(5)
  String? subtitle;

  @HiveField(6)
  DateTime deletedAt;

  @HiveField(7)
  String? deletedBy;

  @HiveField(8)
  String? parentEntityId;

  @HiveField(9)
  String? parentEntityType;

  @HiveField(10)
  String? serializedPayload;

  TrashItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.missionId,
    required this.title,
    this.subtitle,
    required this.deletedAt,
    this.deletedBy,
    this.parentEntityId,
    this.parentEntityType,
    this.serializedPayload,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType,
        'entityId': entityId,
        'missionId': missionId,
        'title': title,
        'subtitle': subtitle,
        'deletedAt': deletedAt.toIso8601String(),
        'deletedBy': deletedBy,
        'parentEntityId': parentEntityId,
        'parentEntityType': parentEntityType,
        'serializedPayload': serializedPayload,
      };

  factory TrashItem.fromJson(Map<String, dynamic> json) => TrashItem(
        id: json['id'] as String,
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as String,
        missionId: json['missionId'] as String?,
        title: json['title'] as String? ?? 'Élément supprimé',
        subtitle: json['subtitle'] as String?,
        deletedAt: json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'] as String)
            : DateTime.now(),
        deletedBy: json['deletedBy'] as String?,
        parentEntityId: json['parentEntityId'] as String?,
        parentEntityType: json['parentEntityType'] as String?,
        serializedPayload: json['serializedPayload'] as String?,
      );
}
