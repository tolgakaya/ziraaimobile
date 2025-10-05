import 'package:json_annotation/json_annotation.dart';

part 'verify_phone_register_request.g.dart';

/// Request model for verifying phone registration OTP (Step 2: Complete Registration)
@JsonSerializable()
class VerifyPhoneRegisterRequest {
  @JsonKey(name: 'mobilePhone')
  final String mobilePhone;

  @JsonKey(name: 'code')
  final int code;

  @JsonKey(name: 'referralCode')
  final String? referralCode;

  VerifyPhoneRegisterRequest({
    required this.mobilePhone,
    required this.code,
    this.referralCode,
  });

  factory VerifyPhoneRegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyPhoneRegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyPhoneRegisterRequestToJson(this);
}
