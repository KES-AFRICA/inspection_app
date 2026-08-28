// lib/features/backup/domain/models/mission_sync_state.dart

enum SyncStatus {
  neverBackedUp,      // Jamais sauvegardée (ni localement ni sur le cloud)
  localOnly,          // Protégée localement (en attente de réseau / en file d'attente cloud)
  pendingUpload,      // Dans la file d'attente de synchronisation cloud
  upToDate,           // Sauvegardée localement ET sur le cloud à jour
  localModifications, // Modifications effectuées depuis la dernière sauvegarde cloud
  syncing,            // Sauvegarde ou restauration en cours (avec progression %)
  failed,             // Échec du dernier transfert cloud (retry programmé)
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

  // Niveau 1 : Métadonnées de Sauvegarde Locale
  final bool hasLocalBackup;
  final DateTime? lastLocalBackupDate;
  final int? localSizeBytes;
  final String? localChecksum;

  const MissionSyncState({
    required this.missionId,
    required this.status,
    this.progress = 0.0,
    this.statusMessage,
    this.lastBackupDate,
    this.remoteSizeBytes,
    this.errorMessage,
    this.hasLocalBackup = false,
    this.lastLocalBackupDate,
    this.localSizeBytes,
    this.localChecksum,
  });

  MissionSyncState copyWith({
    SyncStatus? status,
    double? progress,
    String? statusMessage,
    DateTime? lastBackupDate,
    int? remoteSizeBytes,
    String? errorMessage,
    bool? hasLocalBackup,
    DateTime? lastLocalBackupDate,
    int? localSizeBytes,
    String? localChecksum,
  }) {
    return MissionSyncState(
      missionId: missionId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      remoteSizeBytes: remoteSizeBytes ?? this.remoteSizeBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      hasLocalBackup: hasLocalBackup ?? this.hasLocalBackup,
      lastLocalBackupDate: lastLocalBackupDate ?? this.lastLocalBackupDate,
      localSizeBytes: localSizeBytes ?? this.localSizeBytes,
      localChecksum: localChecksum ?? this.localChecksum,
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
        'hasLocalBackup': hasLocalBackup,
        'lastLocalBackupDate': lastLocalBackupDate?.toIso8601String(),
        'localSizeBytes': localSizeBytes,
        'localChecksum': localChecksum,
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
        hasLocalBackup: json['hasLocalBackup'] as bool? ?? false,
        lastLocalBackupDate: json['lastLocalBackupDate'] != null
            ? DateTime.tryParse(json['lastLocalBackupDate'])
            : null,
        localSizeBytes: json['localSizeBytes'] as int?,
        localChecksum: json['localChecksum'] as String?,
      );
}
