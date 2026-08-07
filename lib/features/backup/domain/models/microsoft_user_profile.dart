// lib/features/backup/domain/models/microsoft_user_profile.dart

class MicrosoftUserProfile {
  final String id;
  final String displayName;
  final String email;
  final String? jobTitle;
  final String? officeLocation;

  const MicrosoftUserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.jobTitle,
    this.officeLocation,
  });

  factory MicrosoftUserProfile.fromJson(Map<String, dynamic> json) {
    return MicrosoftUserProfile(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Inspecteur KES',
      email: json['mail'] as String? ?? json['userPrincipalName'] as String? ?? '',
      jobTitle: json['jobTitle'] as String?,
      officeLocation: json['officeLocation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'mail': email,
      'jobTitle': jobTitle,
      'officeLocation': officeLocation,
    };
  }
}
