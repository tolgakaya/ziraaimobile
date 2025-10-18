import 'package:json_annotation/json_annotation.dart';

part 'sponsorship_metadata.g.dart';

/// Sponsorship metadata for farmer's analysis view
/// Farmer görünümünde sponsor bilgilerini ve izinleri gösterir
@JsonSerializable()
class SponsorshipMetadata {
  final String tierName;
  final int accessPercentage;
  final bool canMessage;
  final bool canViewLogo;
  final SponsorInfo sponsorInfo;
  final AccessibleFields accessibleFields;

  SponsorshipMetadata({
    required this.tierName,
    required this.accessPercentage,
    required this.canMessage,
    required this.canViewLogo,
    required this.sponsorInfo,
    required this.accessibleFields,
  });

  factory SponsorshipMetadata.fromJson(Map<String, dynamic> json) =>
      _$SponsorshipMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$SponsorshipMetadataToJson(this);
}

/// Sponsor display information for farmer
@JsonSerializable()
class SponsorInfo {
  final int sponsorId;
  final String companyName;
  final String? logoUrl;
  final String? websiteUrl;

  SponsorInfo({
    required this.sponsorId,
    required this.companyName,
    this.logoUrl,
    this.websiteUrl,
  });

  factory SponsorInfo.fromJson(Map<String, dynamic> json) =>
      _$SponsorInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SponsorInfoToJson(this);
}

/// Access permissions for farmer viewing analysis
@JsonSerializable()
class AccessibleFields {
  final bool canViewBasicInfo;
  final bool canViewHealthScore;
  final bool canViewImages;
  final bool canViewDetailedHealth;
  final bool canViewDiseases;
  final bool canViewNutrients;
  final bool canViewRecommendations;
  final bool canViewLocation;
  final bool canViewFarmerContact;
  final bool canViewFieldData;
  final bool canViewProcessingData;

  AccessibleFields({
    required this.canViewBasicInfo,
    required this.canViewHealthScore,
    required this.canViewImages,
    required this.canViewDetailedHealth,
    required this.canViewDiseases,
    required this.canViewNutrients,
    required this.canViewRecommendations,
    required this.canViewLocation,
    required this.canViewFarmerContact,
    required this.canViewFieldData,
    required this.canViewProcessingData,
  });

  factory AccessibleFields.fromJson(Map<String, dynamic> json) =>
      _$AccessibleFieldsFromJson(json);

  Map<String, dynamic> toJson() => _$AccessibleFieldsToJson(this);
}
