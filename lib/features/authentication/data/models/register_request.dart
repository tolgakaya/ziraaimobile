import 'package:json_annotation/json_annotation.dart';

part 'register_request.g.dart';

@JsonSerializable()
class RegisterRequest {
  final String email;
  final String password;
  final String fullName;
  final String? mobilePhones;
  final String role; // "Farmer" or "Sponsor"

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    this.mobilePhones,
    required this.role,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}