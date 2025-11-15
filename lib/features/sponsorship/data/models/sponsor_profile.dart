/// Sponsor profil modeli
/// Backend endpoint: GET /api/sponsorship/profile
class SponsorProfile {
  final int id;
  final int sponsorId;
  final String companyName;
  final String? companyDescription;
  final String? contactEmail;
  final String? contactPhone;

  // Social Media URLs (NEW)
  final String? linkedInUrl;
  final String? twitterUrl;
  final String? facebookUrl;
  final String? instagramUrl;

  // Business Information (NEW)
  final String? taxNumber;
  final String? tradeRegistryNumber;
  final String? address;
  final String? city;
  final String? country;
  final String? postalCode;

  // System fields
  final bool isVerifiedCompany;
  final int totalPurchases;
  final int totalCodesGenerated;

  SponsorProfile({
    required this.id,
    required this.sponsorId,
    required this.companyName,
    this.companyDescription,
    this.contactEmail,
    this.contactPhone,
    this.linkedInUrl,
    this.twitterUrl,
    this.facebookUrl,
    this.instagramUrl,
    this.taxNumber,
    this.tradeRegistryNumber,
    this.address,
    this.city,
    this.country,
    this.postalCode,
    this.isVerifiedCompany = false,
    this.totalPurchases = 0,
    this.totalCodesGenerated = 0,
  });

  factory SponsorProfile.fromJson(Map<String, dynamic> json) {
    return SponsorProfile(
      id: json['id'] as int,
      sponsorId: json['sponsorId'] as int,
      companyName: json['companyName'] as String,
      companyDescription: json['companyDescription'] as String?,
      contactEmail: json['contactEmail'] as String?,
      contactPhone: json['contactPhone'] as String?,
      linkedInUrl: json['linkedInUrl'] as String?,
      twitterUrl: json['twitterUrl'] as String?,
      facebookUrl: json['facebookUrl'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      taxNumber: json['taxNumber'] as String?,
      tradeRegistryNumber: json['tradeRegistryNumber'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      isVerifiedCompany: json['isVerifiedCompany'] as bool? ?? false,
      totalPurchases: json['totalPurchases'] as int? ?? 0,
      totalCodesGenerated: json['totalCodesGenerated'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sponsorId': sponsorId,
      'companyName': companyName,
      'companyDescription': companyDescription,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'linkedInUrl': linkedInUrl,
      'twitterUrl': twitterUrl,
      'facebookUrl': facebookUrl,
      'instagramUrl': instagramUrl,
      'taxNumber': taxNumber,
      'tradeRegistryNumber': tradeRegistryNumber,
      'address': address,
      'city': city,
      'country': country,
      'postalCode': postalCode,
      'isVerifiedCompany': isVerifiedCompany,
      'totalPurchases': totalPurchases,
      'totalCodesGenerated': totalCodesGenerated,
    };
  }

  /// Check if any social media URL is available
  bool get hasSocialMedia =>
      linkedInUrl != null ||
      twitterUrl != null ||
      facebookUrl != null ||
      instagramUrl != null;

  /// Check if business information is complete
  bool get hasBusinessInfo =>
      taxNumber != null ||
      tradeRegistryNumber != null ||
      address != null ||
      city != null ||
      country != null ||
      postalCode != null;

  /// Check if profile is complete (basic info + contact)
  bool get isProfileComplete =>
      companyDescription != null &&
      contactEmail != null &&
      contactPhone != null;

  SponsorProfile copyWith({
    int? id,
    int? sponsorId,
    String? companyName,
    String? companyDescription,
    String? contactEmail,
    String? contactPhone,
    String? linkedInUrl,
    String? twitterUrl,
    String? facebookUrl,
    String? instagramUrl,
    String? taxNumber,
    String? tradeRegistryNumber,
    String? address,
    String? city,
    String? country,
    String? postalCode,
    bool? isVerifiedCompany,
    int? totalPurchases,
    int? totalCodesGenerated,
  }) {
    return SponsorProfile(
      id: id ?? this.id,
      sponsorId: sponsorId ?? this.sponsorId,
      companyName: companyName ?? this.companyName,
      companyDescription: companyDescription ?? this.companyDescription,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      taxNumber: taxNumber ?? this.taxNumber,
      tradeRegistryNumber: tradeRegistryNumber ?? this.tradeRegistryNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      isVerifiedCompany: isVerifiedCompany ?? this.isVerifiedCompany,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalCodesGenerated: totalCodesGenerated ?? this.totalCodesGenerated,
    );
  }
}
