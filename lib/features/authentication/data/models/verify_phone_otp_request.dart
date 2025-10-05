import 'package:json_annotation/json_annotation.dart';

part 'verify_phone_otp_request.g.dart';

/// Request model for verifying phone OTP (Step 2: Login)
@JsonSerializable()
class VerifyPhoneOtpRequest {
  @JsonKey(name: 'mobilePhone')
  final String mobilePhone;

  @JsonKey(name: 'code')
  final int code;

  VerifyPhoneOtpRequest({
    required this.mobilePhone,
    required this.code,
  });

  factory VerifyPhoneOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyPhoneOtpRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyPhoneOtpRequestToJson(this);
}
