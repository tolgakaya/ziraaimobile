import 'package:json_annotation/json_annotation.dart';

part 'farmer_invitation_details.g.dart';

/// Response model for farmer invitation details
///
/// API Endpoint: GET /api/v1/sponsorship/farmer/invitation-details?token={token}
///
/// Contains information about the sponsorship invitation before acceptance
@JsonSerializable()
class FarmerInvitationDetails {
  /// Sponsor company name
  final String sponsorCompanyName;

  /// Number of codes being offered
  final int codeCount;

  /// Package tier (S, M, L, XL) - nullable for backward compatibility
  final String? packageTier;

  /// Remaining validity days for the invitation
  final int remainingDays;

  /// Farmer email address
  final String dealerEmail;

  /// Optional custom invitation message from sponsor
  final String? invitationMessage;

  /// When the invitation was created
  final DateTime createdAt;

  /// When the invitation expires
  final DateTime expiresAt;

  FarmerInvitationDetails({
    required this.sponsorCompanyName,
    required this.codeCount,
    this.packageTier,
    required this.remainingDays,
    required this.dealerEmail,
    this.invitationMessage,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Creates instance from JSON response
  factory FarmerInvitationDetails.fromJson(Map<String, dynamic> json) =>
      _$FarmerInvitationDetailsFromJson(json);

  /// Converts instance to JSON
  Map<String, dynamic> toJson() => _$FarmerInvitationDetailsToJson(this);

  /// User-friendly welcome message
  String get welcomeMessage =>
      invitationMessage ??
      '🎉 $sponsorCompanyName sizi çiftçi ağına katılmaya davet ediyor!';

  /// Tier display name for UI
  String? get tierDisplayName {
    if (packageTier == null) return null;

    switch (packageTier!) {
      case 'S':
        return 'Small (1 analiz/gün)';
      case 'M':
        return 'Medium (2 analiz/gün)';
      case 'L':
        return 'Large (5 analiz/gün)';
      case 'XL':
        return 'Extra Large (10 analiz/gün)';
      default:
        return packageTier;
    }
  }

  /// Check if invitation is about to expire
  bool get isExpiringSoon => remainingDays <= 2;

  @override
  String toString() {
    return 'FarmerInvitationDetails('
        'sponsorCompanyName: $sponsorCompanyName, '
        'codeCount: $codeCount, '
        'packageTier: $packageTier, '
        'remainingDays: $remainingDays, '
        'dealerEmail: $dealerEmail'
        ')';
  }
}
