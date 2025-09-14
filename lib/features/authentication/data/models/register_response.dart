import 'package:json_annotation/json_annotation.dart';

part 'register_response.g.dart';

@JsonSerializable()
class RegisterResponse {
  final bool success;
  final RegisterData? data;
  final String? message;
  final String? errorCode;

  const RegisterResponse({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterResponseToJson(this);
}

@JsonSerializable()
class RegisterData {
  final String userId;
  final String email;
  final String message;

  const RegisterData({
    required this.userId,
    required this.email,
    required this.message,
  });

  factory RegisterData.fromJson(Map<String, dynamic> json) =>
      _$RegisterDataFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterDataToJson(this);
}