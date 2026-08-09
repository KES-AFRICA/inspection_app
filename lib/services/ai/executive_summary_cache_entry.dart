import 'dart:convert';
import 'executive_summary_data.dart';

/// Entrée de cache persistant pour le résumé exécutif d'une mission.
class ExecutiveSummaryCacheEntry {
  final String missionId;
  final String snapshotHash;
  final int promptVersion;
  final int schemaVersion;
  final String provider;
  final String model;
  final DateTime generatedAt;
  final ExecutiveSummaryData summaryData;

  ExecutiveSummaryCacheEntry({
    required this.missionId,
    required this.snapshotHash,
    required this.promptVersion,
    required this.schemaVersion,
    required this.provider,
    required this.model,
    required this.generatedAt,
    required this.summaryData,
  });

  Map<String, dynamic> toJson() {
    return {
      'missionId': missionId,
      'snapshotHash': snapshotHash,
      'promptVersion': promptVersion,
      'schemaVersion': schemaVersion,
      'provider': provider,
      'model': model,
      'generatedAt': generatedAt.toIso8601String(),
      'summaryData': summaryData.toJson(),
    };
  }

  factory ExecutiveSummaryCacheEntry.fromJson(Map<String, dynamic> json) {
    return ExecutiveSummaryCacheEntry(
      missionId: json['missionId'] as String? ?? '',
      snapshotHash: json['snapshotHash'] as String? ?? '',
      promptVersion: (json['promptVersion'] as num?)?.toInt() ?? 1,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      provider: json['provider'] as String? ?? 'gemini',
      model: json['model'] as String? ?? 'gemini-2.5-flash',
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      summaryData: ExecutiveSummaryData.fromJson(
        json['summaryData'] is Map<String, dynamic>
            ? json['summaryData'] as Map<String, dynamic>
            : (json['summaryData'] is String
                ? jsonDecode(json['summaryData'] as String)
                : {}),
      ),
    );
  }

  String encodeJson() => jsonEncode(toJson());

  factory ExecutiveSummaryCacheEntry.decodeJson(String source) {
    return ExecutiveSummaryCacheEntry.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }
}
