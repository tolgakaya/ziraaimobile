import 'package:json_annotation/json_annotation.dart';

part 'dealer_invitation_details.g.dart';

/// Response model for dealer invitation details
///
/// API Endpoint: GET /api/v1/sponsorship/dealer/invitation-details?token={token}
///
/// Contains information about the sponsorship invitation before acceptance
@JsonSerializable()
class DealerInvitationDetails {
  /// Sponsor company name
  final String sponsorCompanyName;

  /// Number of codes being offered
  final int codeCount;

  /// Package tier (S, M, L, XL) - nullable for backward compatibility
  final String? packageTier;

  /// Remaining validity days for the invitation
  final int remainingDays;

  /// Dealer email address
  final String dealerEmail;

  /// Optional custom invitation message from sponsor
  final String? invitationMessage;

  /// Sponsor user ID who created the invitation (nullable - not always returned by backend)
  final int? sponsorUserId;

  /// When the invitation was created
  final DateTime createdAt;

  /// When the invitation expires
  final DateTime expiresAt;

  /// 🆕 v2.0: Invitation ID
  final int? invitationId;

  /// 🆕 v2.0: Invitation status (Pending, Accepted, Rejected, Expired)
  final String? status;

  /// 🆕 v2.0: Dealer phone number
  final String? dealerPhone;

  DealerInvitationDetails({
    required this.sponsorCompanyName,
    required this.codeCount,
    this.packageTier,
    required this.remainingDays,
    required this.dealerEmail,
    this.invitationMessage,
    this.sponsorUserId,
    required this.createdAt,
    required this.expiresAt,
    this.invitationId,
    this.status,
    this.dealerPhone,
  });

  /// Creates instance from JSON response
  factory DealerInvitationDetails.fromJson(Map<String, dynamic> json) =>
      _$DealerInvitationDetailsFromJson(json);

  /// Converts instance to JSON
  Map<String, dynamic> toJson() => _$DealerInvitationDetailsToJson(this);

  /// User-friendly welcome message
  String get welcomeMessage =>
      invitationMessage ??
      '🎉 $sponsorCompanyName sizi bayilik ağına katılmaya davet ediyor!';

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
    return 'DealerInvitationDetails('
        'sponsorCompanyName: $sponsorCompanyName, '
        'codeCount: $codeCount, '
        'packageTier: $packageTier, '
        'remainingDays: $remainingDays, '
        'dealerEmail: $dealerEmail'
        ')';
  }
}
