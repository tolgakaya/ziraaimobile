import 'package:json_annotation/json_annotation.dart';

part 'phone_login_request.g.dart';

/// Request model for phone-based login (Step 1: Request OTP)
@JsonSerializable()
class PhoneLoginRequest {
  @JsonKey(name: 'mobilePhone')
  final String mobilePhone;

  PhoneLoginRequest({
    required this.mobilePhone,
  });

  factory PhoneLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$PhoneLoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PhoneLoginRequestToJson(this);
}
