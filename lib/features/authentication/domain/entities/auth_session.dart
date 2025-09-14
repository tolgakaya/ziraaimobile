import 'package:equatable/equatable.dart';
import 'user.dart';
import 'auth_tokens.dart';

/// Represents a complete authentication session combining user and tokens.
/// This is the primary entity returned after successful authentication.
class AuthSession extends Equatable {
  final User user;
  final AuthTokens tokens;
  final DateTime loginTime;
  final String? deviceId;
  final String? ipAddress;
  final Map<String, dynamic>? sessionMetadata;

  const AuthSession({
    required this.user,
    required this.tokens,
    required this.loginTime,
    this.deviceId,
    this.ipAddress,
    this.sessionMetadata,
  });

  /// Returns whether the session is valid (tokens not expired and user active)
  bool get isValid => !tokens.isExpired && user.isActive;

  /// Returns whether the session needs token refresh
  bool get needsRefresh => tokens.willExpireWithin(const Duration(minutes: 5));

  /// Returns the duration since login
  Duration get sessionDuration => DateTime.now().difference(loginTime);

  /// Creates a copy with updated tokens (typically after refresh)
  AuthSession copyWithTokens(AuthTokens newTokens) {
    return AuthSession(
      user: user,
      tokens: newTokens,
      loginTime: loginTime,
      deviceId: deviceId,
      ipAddress: ipAddress,
      sessionMetadata: sessionMetadata,
    );
  }

  /// Creates a copy with updated user (typically after profile update)
  AuthSession copyWithUser(User newUser) {
    return AuthSession(
      user: newUser,
      tokens: tokens,
      loginTime: loginTime,
      deviceId: deviceId,
      ipAddress: ipAddress,
      sessionMetadata: sessionMetadata,
    );
  }

  /// Creates a copy of this session with updated values
  AuthSession copyWith({
    User? user,
    AuthTokens? tokens,
    DateTime? loginTime,
    String? deviceId,
    String? ipAddress,
    Map<String, dynamic>? sessionMetadata,
  }) {
    return AuthSession(
      user: user ?? this.user,
      tokens: tokens ?? this.tokens,
      loginTime: loginTime ?? this.loginTime,
      deviceId: deviceId ?? this.deviceId,
      ipAddress: ipAddress ?? this.ipAddress,
      sessionMetadata: sessionMetadata ?? this.sessionMetadata,
    );
  }

  @override
  List<Object?> get props => [
        user,
        tokens,
        loginTime,
        deviceId,
        ipAddress,
        sessionMetadata,
      ];

  @override
  String toString() {
    return 'AuthSession(userId: ${user.id}, role: ${user.role.name}, isValid: $isValid)';
  }
}