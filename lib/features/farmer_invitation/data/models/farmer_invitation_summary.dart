import 'package:json_annotation/json_annotation.dart';

part 'farmer_invitation_summary.g.dart';

/// Summary model for farmer's invitation list
///
/// API Endpoint: GET /api/v1/sponsorship/farmer/my-invitations
///
/// Used in "My Invitations" screen to display pending and accepted invitations
@JsonSerializable()
class FarmerInvitationSummary {
  /// Unique invitation identifier
  final int invitationId;

  /// Invitation status: Pending, Accepted, Expired, Rejected
  final String status;

  /// Sponsor company name who sent the invitation
  final String sponsorCompanyName;

  /// Number of codes offered in this invitation
  final int codeCount;

  /// When the invitation was created
  final DateTime createdAt;

  /// When the invitation expires
  final DateTime expiresAt;

  FarmerInvitationSummary({
    required this.invitationId,
    required this.status,
    required this.sponsorCompanyName,
    required this.codeCount,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Creates instance from JSON response
  factory FarmerInvitationSummary.fromJson(Map<String, dynamic> json) =>
      _$FarmerInvitationSummaryFromJson(json);

  /// Converts instance to JSON
  Map<String, dynamic> toJson() => _$FarmerInvitationSummaryToJson(this);

  /// Check if invitation is still pending
  bool get isPending => status == 'Pending';

  /// Check if invitation is accepted
  bool get isAccepted => status == 'Accepted';

  /// Check if invitation is expired
  bool get isExpired => status == 'Expired';

  /// Check if invitation is rejected
  bool get isRejected => status == 'Rejected';

  /// Get status color for UI
  String get statusColor {
    switch (status) {
      case 'Pending':
        return 'orange';
      case 'Accepted':
        return 'green';
      case 'Expired':
        return 'red';
      case 'Rejected':
        return 'gray';
      default:
        return 'blue';
    }
  }

  @override
  String toString() {
    return 'FarmerInvitationSummary('
        'invitationId: $invitationId, '
        'status: $status, '
        'sponsorCompanyName: $sponsorCompanyName, '
        'codeCount: $codeCount'
        ')';
  }
}
