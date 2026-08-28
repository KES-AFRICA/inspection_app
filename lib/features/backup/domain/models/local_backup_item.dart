// lib/features/backup/domain/models/local_backup_item.dart

class LocalBackupItem {
  final String missionId;
  final String filePath;
  final String fileName;
  final int fileSizeBytes;
  final String sha256Checksum;
  final DateTime createdAt;
  final String appVersion;
  final bool isSyncedToCloud;
  final DateTime? syncedAt;

  const LocalBackupItem({
    required this.missionId,
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.sha256Checksum,
    required this.createdAt,
    required this.appVersion,
    this.isSyncedToCloud = false,
    this.syncedAt,
  });

  LocalBackupItem copyWith({
    String? missionId,
    String? filePath,
    String? fileName,
    int? fileSizeBytes,
    String? sha256Checksum,
    DateTime? createdAt,
    String? appVersion,
    bool? isSyncedToCloud,
    DateTime? syncedAt,
  }) {
    return LocalBackupItem(
      missionId: missionId ?? this.missionId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      sha256Checksum: sha256Checksum ?? this.sha256Checksum,
      createdAt: createdAt ?? this.createdAt,
      appVersion: appVersion ?? this.appVersion,
      isSyncedToCloud: isSyncedToCloud ?? this.isSyncedToCloud,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'missionId': missionId,
        'filePath': filePath,
        'fileName': fileName,
        'fileSizeBytes': fileSizeBytes,
        'sha256Checksum': sha256Checksum,
        'createdAt': createdAt.toIso8601String(),
        'appVersion': appVersion,
        'isSyncedToCloud': isSyncedToCloud,
        'syncedAt': syncedAt?.toIso8601String(),
      };

  factory LocalBackupItem.fromJson(Map<String, dynamic> json) => LocalBackupItem(
        missionId: json['missionId'] as String,
        filePath: json['filePath'] as String,
        fileName: json['fileName'] as String,
        fileSizeBytes: json['fileSizeBytes'] as int,
        sha256Checksum: json['sha256Checksum'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        appVersion: json['appVersion'] as String? ?? '4.0.0',
        isSyncedToCloud: json['isSyncedToCloud'] as bool? ?? false,
        syncedAt: json['syncedAt'] != null
            ? DateTime.tryParse(json['syncedAt'] as String)
            : null,
      );
}
