// lib/features/backup/domain/models/mission_sync_state.dart

enum SyncStatus {
  neverBackedUp,      // Jamais sauvegardée sur le Cloud
  upToDate,           // Sauvegarde Cloud identique au travail local
  localModifications, // Modifications effectuées depuis la dernière sauvegarde
  syncing,            // Sauvegarde ou restauration en cours (avec progression %)
  failed,             // Échec du dernier transfert
  interrupted,        // Interrompu (reprise possible)
  paused,             // Sauvegarde automatique mise en pause par l'inspecteur
}

class MissionSyncState {
  final String missionId;
  final SyncStatus status;
  final double progress; // 0.0 -> 1.0
  final String? statusMessage;
  final DateTime? lastBackupDate;
  final int? remoteSizeBytes;
  final String? errorMessage;

  const MissionSyncState({
    required this.missionId,
    required this.status,
    this.progress = 0.0,
    this.statusMessage,
    this.lastBackupDate,
    this.remoteSizeBytes,
    this.errorMessage,
  });

  MissionSyncState copyWith({
    SyncStatus? status,
    double? progress,
    String? statusMessage,
    DateTime? lastBackupDate,
    int? remoteSizeBytes,
    String? errorMessage,
  }) {
    return MissionSyncState(
      missionId: missionId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      remoteSizeBytes: remoteSizeBytes ?? this.remoteSizeBytes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'missionId': missionId,
        'status': status.name,
        'progress': progress,
        'statusMessage': statusMessage,
        'lastBackupDate': lastBackupDate?.toIso8601String(),
        'remoteSizeBytes': remoteSizeBytes,
        'errorMessage': errorMessage,
      };

  factory MissionSyncState.fromJson(Map<String, dynamic> json) => MissionSyncState(
        missionId: json['missionId'] as String,
        status: SyncStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SyncStatus.neverBackedUp,
        ),
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        statusMessage: json['statusMessage'] as String?,
        lastBackupDate: json['lastBackupDate'] != null
            ? DateTime.tryParse(json['lastBackupDate'])
            : null,
        remoteSizeBytes: json['remoteSizeBytes'] as int?,
        errorMessage: json['errorMessage'] as String?,
      );
}
