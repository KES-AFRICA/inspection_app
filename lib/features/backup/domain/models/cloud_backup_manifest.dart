// lib/features/backup/domain/models/cloud_backup_manifest.dart

class CloudBackupManifest {
  final String missionId;
  final String missionName;
  final String clientName;
  final String fileName;
  final int fileSizeBytes;
  final String sha256Checksum;
  final DateTime backupCreatedAt;
  final String inspectorMatricule;
  final String inspectorName;
  final int photoCount;
  final int observationCount;

  const CloudBackupManifest({
    required this.missionId,
    required this.missionName,
    required this.clientName,
    required this.fileName,
    required this.fileSizeBytes,
    required this.sha256Checksum,
    required this.backupCreatedAt,
    required this.inspectorMatricule,
    required this.inspectorName,
    this.photoCount = 0,
    this.observationCount = 0,
  });

  factory CloudBackupManifest.fromJson(Map<String, dynamic> json) {
    return CloudBackupManifest(
      missionId: json['missionId'] as String? ?? '',
      missionName: json['missionName'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      sha256Checksum: json['sha256Checksum'] as String? ?? '',
      backupCreatedAt: json['backupCreatedAt'] != null
          ? DateTime.tryParse(json['backupCreatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      inspectorMatricule: json['inspectorMatricule'] as String? ?? '',
      inspectorName: json['inspectorName'] as String? ?? '',
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
      observationCount: (json['observationCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'missionId': missionId,
      'missionName': missionName,
      'clientName': clientName,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'sha256Checksum': sha256Checksum,
      'backupCreatedAt': backupCreatedAt.toIso8601String(),
      'inspectorMatricule': inspectorMatricule,
      'inspectorName': inspectorName,
      'photoCount': photoCount,
      'observationCount': observationCount,
    };
  }
}
