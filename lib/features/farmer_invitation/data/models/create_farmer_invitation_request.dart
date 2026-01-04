import 'package:json_annotation/json_annotation.dart';

part 'create_farmer_invitation_request.g.dart';

/// Request model for creating farmer invitation
///
/// API Endpoint: POST /api/v1/sponsorship/farmer/invite
///
/// Sent by sponsor to create individual farmer invitation
@JsonSerializable()
class CreateFarmerInvitationRequest {
  /// Recipient's phone number (Turkish format: 05551234567)
  /// Serialized as "phone" for API (backend expects "phone", not "recipientPhone")
  @JsonKey(name: 'phone')
  final String recipientPhone;

  /// Number of codes to offer in the invitation
  final int codeCount;

  /// Whether to send invitation via SMS
  final bool sendViaSms;

  CreateFarmerInvitationRequest({
    required this.recipientPhone,
    required this.codeCount,
    required this.sendViaSms,
  });

  /// Creates instance from JSON
  factory CreateFarmerInvitationRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateFarmerInvitationRequestFromJson(json);

  /// Converts instance to JSON for API request
  Map<String, dynamic> toJson() =>
      _$CreateFarmerInvitationRequestToJson(this);

  @override
  String toString() {
    return 'CreateFarmerInvitationRequest('
        'recipientPhone: $recipientPhone, '
        'codeCount: $codeCount, '
        'sendViaSms: $sendViaSms'
        ')';
  }
}
