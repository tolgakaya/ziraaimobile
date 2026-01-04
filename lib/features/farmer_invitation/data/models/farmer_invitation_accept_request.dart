import 'package:json_annotation/json_annotation.dart';

part 'farmer_invitation_accept_request.g.dart';

/// Request model for accepting farmer invitation
///
/// API Endpoint: POST /api/v1/sponsorship/farmer/accept-invitation
///
/// Sent by farmer to accept invitation and activate codes
@JsonSerializable()
class FarmerInvitationAcceptRequest {
  /// 32-character hexadecimal invitation token
  final String invitationToken;

  FarmerInvitationAcceptRequest({
    required this.invitationToken,
  });

  /// Creates instance from JSON
  factory FarmerInvitationAcceptRequest.fromJson(Map<String, dynamic> json) =>
      _$FarmerInvitationAcceptRequestFromJson(json);

  /// Converts instance to JSON for API request
  Map<String, dynamic> toJson() => _$FarmerInvitationAcceptRequestToJson(this);

  @override
  String toString() {
    return 'FarmerInvitationAcceptRequest(invitationToken: ${invitationToken.substring(0, 8)}...)';
  }
}
