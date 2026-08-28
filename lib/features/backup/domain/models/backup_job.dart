// lib/features/backup/domain/models/backup_job.dart

enum BackupJobStatus {
  idle,                     // Inactif
  preparing,                // Génération du bundle .inspec local Niveau 1
  queued,                   // En file d'attente FIFO
  uploading,                // Envoi des chunks via Microsoft Graph
  paused,                   // Sauvegarde mise en pause par l'inspecteur
  waitingForNetwork,        // Connexion perdue, en attente du rétablissement réseau
  waitingForAuthentication, // Jeton expiré, en cours de rafraîchissement
  retrying,                 // Erreur serveur 5xx / 429, tentative automatique programmée
  completed,                // Sauvegarde terminée avec succès (Local + Cloud)
  failed,                   // Échec définitif (Quota dépassé, erreur fatale)
  cancelled,                // Sauvegarde annulée par l'utilisateur
}

class BackupJob {
  final String id;                    // Id unique (ex: job_m_123_1787123456)
  final String missionId;
  final String matricule;
  final BackupJobStatus status;
  final double progress;              // 0.0 -> 1.0 (uploadedBytes / totalBytes)
  final String? statusMessage;
  final String? localFilePath;        // Chemin du snapshot .inspec local
  final String? localFileName;
  final int totalBytes;               // Taille exacte du fichier .inspec
  final int uploadedBytes;            // Octets réellement confirmés par le serveur Graph
  final String? uploadSessionUrl;     // URL de la session Microsoft Graph
  final DateTime? sessionExpiration;  // Expiration de la session OneDrive
  final String? sha256Checksum;        // Empreinte du bundle
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? pausedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const BackupJob({
    required this.id,
    required this.missionId,
    required this.matricule,
    required this.status,
    this.progress = 0.0,
    this.statusMessage,
    this.localFilePath,
    this.localFileName,
    this.totalBytes = 0,
    this.uploadedBytes = 0,
    this.uploadSessionUrl,
    this.sessionExpiration,
    this.sha256Checksum,
    this.retryCount = 0,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
    this.pausedAt,
    this.completedAt,
    this.cancelledAt,
  });

  bool get isActive =>
      status == BackupJobStatus.preparing ||
      status == BackupJobStatus.queued ||
      status == BackupJobStatus.uploading ||
      status == BackupJobStatus.waitingForAuthentication ||
      status == BackupJobStatus.retrying;

  bool get isPaused => status == BackupJobStatus.paused;
  bool get isWaitingNetwork => status == BackupJobStatus.waitingForNetwork;
  bool get isFinished =>
      status == BackupJobStatus.completed ||
      status == BackupJobStatus.failed ||
      status == BackupJobStatus.cancelled;

  BackupJob copyWith({
    BackupJobStatus? status,
    double? progress,
    String? statusMessage,
    String? localFilePath,
    String? localFileName,
    int? totalBytes,
    int? uploadedBytes,
    String? uploadSessionUrl,
    DateTime? sessionExpiration,
    String? sha256Checksum,
    int? retryCount,
    String? lastError,
    DateTime? updatedAt,
    DateTime? pausedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
  }) {
    return BackupJob(
      id: id,
      missionId: missionId,
      matricule: matricule,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      localFilePath: localFilePath ?? this.localFilePath,
      localFileName: localFileName ?? this.localFileName,
      totalBytes: totalBytes ?? this.totalBytes,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      uploadSessionUrl: uploadSessionUrl ?? this.uploadSessionUrl,
      sessionExpiration: sessionExpiration ?? this.sessionExpiration,
      sha256Checksum: sha256Checksum ?? this.sha256Checksum,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      pausedAt: pausedAt ?? this.pausedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'missionId': missionId,
        'matricule': matricule,
        'status': status.name,
        'progress': progress,
        'statusMessage': statusMessage,
        'localFilePath': localFilePath,
        'localFileName': localFileName,
        'totalBytes': totalBytes,
        'uploadedBytes': uploadedBytes,
        'uploadSessionUrl': uploadSessionUrl,
        'sessionExpiration': sessionExpiration?.toIso8601String(),
        'sha256Checksum': sha256Checksum,
        'retryCount': retryCount,
        'lastError': lastError,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'pausedAt': pausedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'cancelledAt': cancelledAt?.toIso8601String(),
      };

  factory BackupJob.fromJson(Map<String, dynamic> json) => BackupJob(
        id: json['id'] as String,
        missionId: json['missionId'] as String,
        matricule: json['matricule'] as String,
        status: BackupJobStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => BackupJobStatus.idle,
        ),
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        statusMessage: json['statusMessage'] as String?,
        localFilePath: json['localFilePath'] as String?,
        localFileName: json['localFileName'] as String?,
        totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
        uploadedBytes: (json['uploadedBytes'] as num?)?.toInt() ?? 0,
        uploadSessionUrl: json['uploadSessionUrl'] as String?,
        sessionExpiration: json['sessionExpiration'] != null
            ? DateTime.tryParse(json['sessionExpiration'])
            : null,
        sha256Checksum: json['sha256Checksum'] as String?,
        retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
        lastError: json['lastError'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
        pausedAt: json['pausedAt'] != null ? DateTime.tryParse(json['pausedAt']) : null,
        completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
        cancelledAt: json['cancelledAt'] != null ? DateTime.tryParse(json['cancelledAt']) : null,
      );
}
