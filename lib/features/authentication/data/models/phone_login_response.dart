import 'package:json_annotation/json_annotation.dart';

part 'phone_login_response.g.dart';

/// Response model for phone login OTP request
/// API: POST /api/v1/Auth/login-phone
/// SMS is sent via real SMS service, no OTP code in response
@JsonSerializable()
class PhoneLoginResponse {
  @JsonKey(name: 'data')
  final PhoneLoginData? data;

  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'message')
  final String? message;

  PhoneLoginResponse({
    this.data,
    required this.success,
    this.message,
  });

  factory PhoneLoginResponse.fromJson(Map<String, dynamic> json) =>
      _$PhoneLoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PhoneLoginResponseToJson(this);
}

@JsonSerializable()
class PhoneLoginData {
  @JsonKey(name: 'status')
  final String status;

  @JsonKey(name: 'message')
  final String message;

  PhoneLoginData({
    required this.status,
    required this.message,
  });

  factory PhoneLoginData.fromJson(Map<String, dynamic> json) =>
      _$PhoneLoginDataFromJson(json);

  Map<String, dynamic> toJson() => _$PhoneLoginDataToJson(this);
}
