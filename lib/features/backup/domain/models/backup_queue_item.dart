// lib/features/backup/domain/models/backup_queue_item.dart

enum BackupQueueStatus {
  pending,    // En attente dans la file
  processing, // Transfert en cours
  completed,  // Sauvegarde réussie
  failed,     // Échec (réattente backoff)
  paused,     // Mis en pause par l'inspecteur
}

class BackupQueueItem {
  final String missionId;
  final String matricule;
  final BackupQueueStatus status;
  final DateTime addedAt;
  final int attemptCount;
  final DateTime? nextRetryAt;
  final String? lastError;

  const BackupQueueItem({
    required this.missionId,
    required this.matricule,
    this.status = BackupQueueStatus.pending,
    required this.addedAt,
    this.attemptCount = 0,
    this.nextRetryAt,
    this.lastError,
  });

  BackupQueueItem copyWith({
    BackupQueueStatus? status,
    int? attemptCount,
    DateTime? nextRetryAt,
    String? lastError,
  }) {
    return BackupQueueItem(
      missionId: missionId,
      matricule: matricule,
      status: status ?? this.status,
      addedAt: addedAt,
      attemptCount: attemptCount ?? this.attemptCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'missionId': missionId,
        'matricule': matricule,
        'status': status.name,
        'addedAt': addedAt.toIso8601String(),
        'attemptCount': attemptCount,
        'nextRetryAt': nextRetryAt?.toIso8601String(),
        'lastError': lastError,
      };

  factory BackupQueueItem.fromJson(Map<String, dynamic> json) => BackupQueueItem(
        missionId: json['missionId'] as String,
        matricule: json['matricule'] as String? ?? '',
        status: BackupQueueStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => BackupQueueStatus.pending,
        ),
        addedAt: DateTime.parse(json['addedAt'] as String),
        attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
        nextRetryAt: json['nextRetryAt'] != null ? DateTime.parse(json['nextRetryAt'] as String) : null,
        lastError: json['lastError'] as String?,
      );
}
