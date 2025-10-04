import 'package:json_annotation/json_annotation.dart';

part 'referral_link_response.g.dart';

/// Response model for referral link generation
/// API: POST /api/v1/Referral/generate
@JsonSerializable()
class ReferralLinkResponse {
  @JsonKey(name: 'data')
  final ReferralLinkData data;

  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'message')
  final String message;

  ReferralLinkResponse({
    required this.data,
    required this.success,
    required this.message,
  });

  factory ReferralLinkResponse.fromJson(Map<String, dynamic> json) =>
      _$ReferralLinkResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralLinkResponseToJson(this);
}

@JsonSerializable()
class ReferralLinkData {
  @JsonKey(name: 'referralCode')
  final String referralCode;

  @JsonKey(name: 'deepLink')
  final String deepLink; // Format: "https://ziraai.com/ref/ZIRA-K5ZYZX"

  @JsonKey(name: 'playStoreLink')
  final String playStoreLink;

  @JsonKey(name: 'expiresAt')
  final String expiresAt; // ISO 8601 datetime

  @JsonKey(name: 'deliveryStatuses')
  final List<DeliveryStatus> deliveryStatuses;

  ReferralLinkData({
    required this.referralCode,
    required this.deepLink,
    required this.playStoreLink,
    required this.expiresAt,
    required this.deliveryStatuses,
  });

  factory ReferralLinkData.fromJson(Map<String, dynamic> json) =>
      _$ReferralLinkDataFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralLinkDataToJson(this);

  /// Parse expiration string to DateTime
  DateTime get expirationDateTime => DateTime.parse(expiresAt);

  /// Check if referral code is expired
  bool get isExpired => DateTime.now().isAfter(expirationDateTime);

  /// Extract referral code from deep link
  /// Deep link format: "https://ziraai.com/ref/ZIRA-K5ZYZX"
  static String? extractCodeFromDeepLink(String deepLink) {
    final uri = Uri.parse(deepLink);
    if (uri.host == 'ziraai.com' && uri.pathSegments.length >= 2) {
      if (uri.pathSegments[0] == 'ref') {
        return uri.pathSegments[1];
      }
    }
    return null;
  }
}

@JsonSerializable()
class DeliveryStatus {
  @JsonKey(name: 'phoneNumber')
  final String phoneNumber;

  @JsonKey(name: 'method')
  final String method; // "SMS" or "WhatsApp"

  @JsonKey(name: 'status')
  final String status; // "Sent", "Failed", etc.

  DeliveryStatus({
    required this.phoneNumber,
    required this.method,
    required this.status,
  });

  factory DeliveryStatus.fromJson(Map<String, dynamic> json) =>
      _$DeliveryStatusFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryStatusToJson(this);

  bool get isSuccess => status == 'Sent';
  bool get isFailed => status == 'Failed';
}
