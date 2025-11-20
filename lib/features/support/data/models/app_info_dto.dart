/// Data Transfer Object for App Info (About Us)
class AppInfoDto {
  final String? companyName;
  final String? companyDescription;
  final String? appVersion;
  final String? address;
  final String? email;
  final String? phone;
  final String? websiteUrl;
  final String? facebookUrl;
  final String? instagramUrl;
  final String? youTubeUrl;
  final String? twitterUrl;
  final String? linkedInUrl;
  final String? termsOfServiceUrl;
  final String? privacyPolicyUrl;
  final String? cookiePolicyUrl;
  final DateTime updatedDate;

  AppInfoDto({
    this.companyName,
    this.companyDescription,
    this.appVersion,
    this.address,
    this.email,
    this.phone,
    this.websiteUrl,
    this.facebookUrl,
    this.instagramUrl,
    this.youTubeUrl,
    this.twitterUrl,
    this.linkedInUrl,
    this.termsOfServiceUrl,
    this.privacyPolicyUrl,
    this.cookiePolicyUrl,
    required this.updatedDate,
  });

  factory AppInfoDto.fromJson(Map<String, dynamic> json) {
    return AppInfoDto(
      companyName: json['companyName'],
      companyDescription: json['companyDescription'],
      appVersion: json['appVersion'],
      address: json['address'],
      email: json['email'],
      phone: json['phone'],
      websiteUrl: json['websiteUrl'],
      facebookUrl: json['facebookUrl'],
      instagramUrl: json['instagramUrl'],
      youTubeUrl: json['youTubeUrl'],
      twitterUrl: json['twitterUrl'],
      linkedInUrl: json['linkedInUrl'],
      termsOfServiceUrl: json['termsOfServiceUrl'],
      privacyPolicyUrl: json['privacyPolicyUrl'],
      cookiePolicyUrl: json['cookiePolicyUrl'],
      updatedDate: DateTime.parse(json['updatedDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'companyDescription': companyDescription,
      'appVersion': appVersion,
      'address': address,
      'email': email,
      'phone': phone,
      'websiteUrl': websiteUrl,
      'facebookUrl': facebookUrl,
      'instagramUrl': instagramUrl,
      'youTubeUrl': youTubeUrl,
      'twitterUrl': twitterUrl,
      'linkedInUrl': linkedInUrl,
      'termsOfServiceUrl': termsOfServiceUrl,
      'privacyPolicyUrl': privacyPolicyUrl,
      'cookiePolicyUrl': cookiePolicyUrl,
      'updatedDate': updatedDate.toIso8601String(),
    };
  }

  /// Check if social media links exist
  bool get hasSocialMedia =>
      facebookUrl != null ||
      instagramUrl != null ||
      youTubeUrl != null ||
      twitterUrl != null ||
      linkedInUrl != null;

  /// Check if contact info exists
  bool get hasContactInfo =>
      email != null || phone != null || websiteUrl != null;

  /// Check if legal links exist
  bool get hasLegalLinks =>
      termsOfServiceUrl != null ||
      privacyPolicyUrl != null ||
      cookiePolicyUrl != null;
}
