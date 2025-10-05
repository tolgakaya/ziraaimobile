import 'package:json_annotation/json_annotation.dart';

part 'auth_token_response.g.dart';

/// Unified response model for authentication endpoints that return tokens
/// Used by:
/// - POST /api/v1/Auth/verify-phone-otp (Login)
/// - POST /api/v1/Auth/verify-phone-register (Registration)
@JsonSerializable()
class AuthTokenResponse {
  @JsonKey(name: 'data')
  final AuthTokenData data;

  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'message')
  final String? message;

  AuthTokenResponse({
    required this.data,
    required this.success,
    this.message,
  });

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthTokenResponseToJson(this);
}

@JsonSerializable()
class AuthTokenData {
  @JsonKey(name: 'provider')
  final String provider; // "Phone" for login, "Unknown" for registration

  @JsonKey(name: 'claims')
  final List<String>? claims; // Only present in registration response

  @JsonKey(name: 'token')
  final String token;

  @JsonKey(name: 'expiration')
  final String expiration; // ISO 8601 datetime string

  @JsonKey(name: 'refreshToken')
  final String refreshToken;

  AuthTokenData({
    required this.provider,
    this.claims,
    required this.token,
    required this.expiration,
    required this.refreshToken,
  });

  factory AuthTokenData.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenDataFromJson(json);

  Map<String, dynamic> toJson() => _$AuthTokenDataToJson(this);

  /// Parse expiration string to DateTime
  DateTime get expirationDateTime => DateTime.parse(expiration);

  /// Check if token is expired
  bool get isExpired => DateTime.now().isAfter(expirationDateTime);

  /// Check if token will expire soon (within 5 minutes)
  bool get willExpireSoon {
    final fiveMinutesFromNow = DateTime.now().add(Duration(minutes: 5));
    return fiveMinutesFromNow.isAfter(expirationDateTime);
  }
}
