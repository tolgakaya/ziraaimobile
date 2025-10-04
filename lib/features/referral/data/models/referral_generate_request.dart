import 'package:json_annotation/json_annotation.dart';

part 'referral_generate_request.g.dart';

/// Request model for generating referral link
/// API: POST /api/v1/Referral/generate
@JsonSerializable()
class ReferralGenerateRequest {
  @JsonKey(name: 'deliveryMethod')
  final int deliveryMethod; // 1=SMS, 2=WhatsApp, 3=Both

  @JsonKey(name: 'phoneNumbers')
  final List<String> phoneNumbers;

  @JsonKey(name: 'customMessage')
  final String? customMessage;

  ReferralGenerateRequest({
    required this.deliveryMethod,
    required this.phoneNumbers,
    this.customMessage,
  });

  factory ReferralGenerateRequest.fromJson(Map<String, dynamic> json) =>
      _$ReferralGenerateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralGenerateRequestToJson(this);
}

/// Delivery method enum for better type safety
enum DeliveryMethod {
  sms(1),
  whatsApp(2),
  both(3);

  final int value;
  const DeliveryMethod(this.value);
}
