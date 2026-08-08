// lib/features/backup/domain/models/backup_preferences.dart

class BackupPreferences {
  final bool isAutoBackupEnabled;
  final int scheduleHour; // 17
  final int scheduleMinute; // 10
  final bool wifiOnly;
  final bool requiresCharging;
  final DateTime? recommendationLastShown;
  final int recommendationDismissCount;

  const BackupPreferences({
    this.isAutoBackupEnabled = true,
    this.scheduleHour = 17,
    this.scheduleMinute = 10,
    this.wifiOnly = false,
    this.requiresCharging = false,
    this.recommendationLastShown,
    this.recommendationDismissCount = 0,
  });

  BackupPreferences copyWith({
    bool? isAutoBackupEnabled,
    int? scheduleHour,
    int? scheduleMinute,
    bool? wifiOnly,
    bool? requiresCharging,
    DateTime? recommendationLastShown,
    int? recommendationDismissCount,
  }) {
    return BackupPreferences(
      isAutoBackupEnabled: isAutoBackupEnabled ?? this.isAutoBackupEnabled,
      scheduleHour: scheduleHour ?? this.scheduleHour,
      scheduleMinute: scheduleMinute ?? this.scheduleMinute,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      requiresCharging: requiresCharging ?? this.requiresCharging,
      recommendationLastShown: recommendationLastShown ?? this.recommendationLastShown,
      recommendationDismissCount: recommendationDismissCount ?? this.recommendationDismissCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'isAutoBackupEnabled': isAutoBackupEnabled,
        'scheduleHour': scheduleHour,
        'scheduleMinute': scheduleMinute,
        'wifiOnly': wifiOnly,
        'requiresCharging': requiresCharging,
        'recommendationLastShown': recommendationLastShown?.toIso8601String(),
        'recommendationDismissCount': recommendationDismissCount,
      };

  factory BackupPreferences.fromJson(Map<String, dynamic> json) => BackupPreferences(
        isAutoBackupEnabled: json['isAutoBackupEnabled'] as bool? ?? true,
        scheduleHour: (json['scheduleHour'] as num?)?.toInt() ?? 17,
        scheduleMinute: (json['scheduleMinute'] as num?)?.toInt() ?? 10,
        wifiOnly: json['wifiOnly'] as bool? ?? false,
        requiresCharging: json['requiresCharging'] as bool? ?? false,
        recommendationLastShown: json['recommendationLastShown'] != null
            ? DateTime.tryParse(json['recommendationLastShown'] as String)
            : null,
        recommendationDismissCount: (json['recommendationDismissCount'] as num?)?.toInt() ?? 0,
      );
}
