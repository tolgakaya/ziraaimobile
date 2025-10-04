import 'package:json_annotation/json_annotation.dart';

part 'phone_register_request.g.dart';

/// Request model for phone-based registration (Step 1: Request OTP)
@JsonSerializable()
class PhoneRegisterRequest {
  @JsonKey(name: 'mobilePhone')
  final String mobilePhone;

  @JsonKey(name: 'referralCode')
  final String? referralCode;

  PhoneRegisterRequest({
    required this.mobilePhone,
    this.referralCode,
  });

  factory PhoneRegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$PhoneRegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PhoneRegisterRequestToJson(this);
}
