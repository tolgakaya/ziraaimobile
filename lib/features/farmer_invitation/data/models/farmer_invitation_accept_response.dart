import 'package:json_annotation/json_annotation.dart';

part 'farmer_invitation_accept_response.g.dart';

/// Response model for accepting farmer invitation
///
/// API Endpoint: POST /api/v1/sponsorship/farmer/accept-invitation
///
/// Returned after successful invitation acceptance with activation details
@JsonSerializable()
class FarmerInvitationAcceptResponse {
  /// Indicates if acceptance was successful
  final bool success;

  /// User-friendly message about the acceptance result
  final String message;

  /// Number of codes that were activated
  final int activatedCodes;

  /// New subscription end date after code activation
  final DateTime subscriptionEndDate;

  FarmerInvitationAcceptResponse({
    required this.success,
    required this.message,
    required this.activatedCodes,
    required this.subscriptionEndDate,
  });

  /// Creates instance from JSON response
  factory FarmerInvitationAcceptResponse.fromJson(Map<String, dynamic> json) =>
      _$FarmerInvitationAcceptResponseFromJson(json);

  /// Converts instance to JSON
  Map<String, dynamic> toJson() =>
      _$FarmerInvitationAcceptResponseToJson(this);

  @override
  String toString() {
    return 'FarmerInvitationAcceptResponse('
        'success: $success, '
        'activatedCodes: $activatedCodes, '
        'subscriptionEndDate: $subscriptionEndDate'
        ')';
  }
}
