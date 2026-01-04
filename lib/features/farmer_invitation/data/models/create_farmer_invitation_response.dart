import 'package:json_annotation/json_annotation.dart';

part 'create_farmer_invitation_response.g.dart';

/// Response model for creating farmer invitation
///
/// API Endpoint: POST /api/v1/sponsorship/farmer/invite
///
/// Returned after successful invitation creation with deep link details
@JsonSerializable()
class CreateFarmerInvitationResponse {
  /// Indicates if invitation creation was successful
  final bool success;

  /// User-friendly message about the creation result
  final String message;

  /// 32-character hexadecimal invitation token
  final String invitationToken;

  /// Full deep link URL for the invitation (https://ziraai.com/farmer-invite/{token})
  final String invitationUrl;

  /// When the invitation expires
  final DateTime expiresAt;

  CreateFarmerInvitationResponse({
    required this.success,
    required this.message,
    required this.invitationToken,
    required this.invitationUrl,
    required this.expiresAt,
  });

  /// Creates instance from JSON response
  factory CreateFarmerInvitationResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateFarmerInvitationResponseFromJson(json);

  /// Converts instance to JSON
  Map<String, dynamic> toJson() =>
      _$CreateFarmerInvitationResponseToJson(this);

  @override
  String toString() {
    return 'CreateFarmerInvitationResponse('
        'success: $success, '
        'invitationToken: ${invitationToken.substring(0, 8)}..., '
        'invitationUrl: $invitationUrl'
        ')';
  }
}
