import 'package:json_annotation/json_annotation.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  final bool success;
  final LoginData? data;
  final String? message;
  final String? errorCode;

  const LoginResponse({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

@JsonSerializable()
class LoginData {
  final String token;
  final String? refreshToken;
  final UserInfo? user;
  final DateTime? tokenExpiry;
  final List<String>? claims;
  final String? expiration;

  const LoginData({
    required this.token,
    this.refreshToken,
    this.user,
    this.tokenExpiry,
    this.claims,
    this.expiration,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) =>
      _$LoginDataFromJson(json);

  Map<String, dynamic> toJson() => _$LoginDataToJson(this);
}

@JsonSerializable()
class UserInfo {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phoneNumber;
  final bool? emailVerified;
  final String? tier;

  const UserInfo({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phoneNumber,
    this.emailVerified,
    this.tier,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}