import 'package:json_annotation/json_annotation.dart';

part 'dealer_invitation_accept_response.g.dart';

/// Response model for dealer invitation acceptance
///
/// API Endpoint: POST /api/v1/sponsorship/dealer/accept-invitation
///
/// Version History:
/// - v1.0: Initial release (invitationId, dealerId, codesTransferred, dealerName, acceptedAt)
/// - v2.0: Added packageTier and transferredCodeIds (nullable for backward compatibility)
@JsonSerializable()
class DealerInvitationAcceptResponse {
  /// Unique invitation ID
  final int invitationId;

  /// ID of the dealer who accepted the invitation
  final int dealerId;

  /// Number of codes transferred to the dealer
  @JsonKey(name: 'transferredCodeCount')
  final int codesTransferred;

  /// Name of the dealer/company (nullable - backend may not return this)
  final String? dealerName;

  /// Success message from backend
  final String? message;

  /// Timestamp when invitation was accepted
  final DateTime acceptedAt;

  /// 🆕 v2.0: Package tier of transferred codes (S, M, L, XL)
  ///
  /// Nullable for backward compatibility with v1.0 responses
  /// Will be null if:
  /// - Invitation was created before v2.0
  /// - No tier filter was specified during invitation creation
  final String? packageTier;

  /// 🆕 v2.0: List of transferred code IDs
  ///
  /// Nullable for backward compatibility with v1.0 responses
  /// Useful for tracking which specific codes were assigned
  final List<int>? transferredCodeIds;

  DealerInvitationAcceptResponse({
    required this.invitationId,
    required this.dealerId,
    required this.codesTransferred,
    this.dealerName,
    required this.acceptedAt,
    this.packageTier,
    this.transferredCodeIds,
    this.message,
  });

  /// Creates instance from JSON response
  ///
  /// Handles both v1.0 and v2.0 API responses safely
  factory DealerInvitationAcceptResponse.fromJson(Map<String, dynamic> json) =>
      _$DealerInvitationAcceptResponseFromJson(json);

  /// Converts instance to JSON
  Map<String, dynamic> toJson() =>
      _$DealerInvitationAcceptResponseToJson(this);

  /// User-friendly message with code count
  String get successMessage =>
      message ?? '✅ Tebrikler! $codesTransferred adet kod hesabınıza transfer edildi.';

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

  @override
  String toString() {
    return 'DealerInvitationAcceptResponse('
        'invitationId: $invitationId, '
        'dealerId: $dealerId, '
        'codesTransferred: $codesTransferred, '
        'dealerName: $dealerName, '
        'acceptedAt: $acceptedAt, '
        'packageTier: $packageTier, '
        'transferredCodeIds: $transferredCodeIds'
        ')';
  }
}
