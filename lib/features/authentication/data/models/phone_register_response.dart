import 'package:json_annotation/json_annotation.dart';

part 'phone_register_response.g.dart';

/// Response model for phone registration OTP request
/// API: POST /api/v1/Auth/register-phone
/// NOTE: This endpoint does NOT return a 'data' field, only success and message
@JsonSerializable()
class PhoneRegisterResponse {
  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'message')
  final String message; // Format: "OTP sent to 05321111120. Code: 409024 (dev mode)"

  PhoneRegisterResponse({
    required this.success,
    required this.message,
  });

  factory PhoneRegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$PhoneRegisterResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PhoneRegisterResponseToJson(this);

  /// Extract OTP code from message (development mode only)
  /// Message format: "OTP sent to 05321111120. Code: 409024 (dev mode)"
  String? get otpCode {
    final codeMatch = RegExp(r'Code:\s*(\d{6})').firstMatch(message);
    return codeMatch?.group(1);
  }

  /// Extract phone number from message
  String? get phoneNumber {
    final phoneMatch = RegExp(r'to\s*(05\d{9})').firstMatch(message);
    return phoneMatch?.group(1);
  }
}
