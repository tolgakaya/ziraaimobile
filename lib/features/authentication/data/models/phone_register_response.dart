import 'package:json_annotation/json_annotation.dart';

part 'phone_register_response.g.dart';

/// Response model for phone registration OTP request
/// API: POST /api/v1/Auth/register-phone
/// SMS is sent via real SMS service, no OTP code in response
@JsonSerializable()
class PhoneRegisterResponse {
  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'message')
  final String message;

  PhoneRegisterResponse({
    required this.success,
    required this.message,
  });

  factory PhoneRegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$PhoneRegisterResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PhoneRegisterResponseToJson(this);
}
