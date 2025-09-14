import 'package:equatable/equatable.dart';

/// Represents JWT authentication tokens from the ZiraAI backend.
/// Includes access token, refresh token, and expiration information.
class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String tokenType;
  final List<String> scopes;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.tokenType = 'Bearer',
    this.scopes = const [],
  });

  /// Returns whether the access token is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Returns whether the token will expire within the given duration
  bool willExpireWithin(Duration duration) {
    return DateTime.now().add(duration).isAfter(expiresAt);
  }

  /// Returns the number of seconds until expiration
  int get secondsUntilExpiration {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0;
    return expiresAt.difference(now).inSeconds;
  }

  /// Creates a formatted authorization header value
  String get authorizationHeader => '$tokenType $accessToken';

  /// Creates a copy of this tokens object with updated values
  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? tokenType,
    List<String>? scopes,
  }) {
    return AuthTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      tokenType: tokenType ?? this.tokenType,
      scopes: scopes ?? this.scopes,
    );
  }

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        expiresAt,
        tokenType,
        scopes,
      ];

  @override
  String toString() {
    return 'AuthTokens(tokenType: $tokenType, expiresAt: $expiresAt, isExpired: $isExpired)';
  }
}