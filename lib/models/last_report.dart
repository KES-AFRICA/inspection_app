// lib/models/last_report.dart
import 'package:hive/hive.dart';

part 'last_report.g.dart';

@HiveType(typeId: 50)
class LastReport extends HiveObject {
  @HiveField(0)
  String missionId;
  
  @HiveField(1)
  String filePath;
  
  @HiveField(2)
  String fileName;
  
  @HiveField(3)
  DateTime generatedAt;
  
  @HiveField(4)
  String reportType; // 'pdf' ou 'docx'

  LastReport({
    required this.missionId,
    required this.filePath,
    required this.fileName,
    required this.generatedAt,
    required this.reportType,
  });
}