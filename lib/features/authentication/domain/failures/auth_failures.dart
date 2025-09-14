import '../../../../core/errors/failures.dart';

/// Authentication-specific failure classes
/// Extends core Failure class with authentication domain context

/// Failed authentication due to invalid credentials
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([String message = 'Invalid email or password'])
      : super(message);

  @override
  List<Object> get props => [message];
}

/// Account is locked due to multiple failed login attempts
class AccountLockedFailure extends Failure {
  final DateTime? lockExpiresAt;
  final int remainingLockTimeMinutes;

  const AccountLockedFailure({
    String message = 'Account is temporarily locked',
    this.lockExpiresAt,
    this.remainingLockTimeMinutes = 0,
  }) : super(message);

  @override
  List<Object?> get props => [message, lockExpiresAt, remainingLockTimeMinutes];

  @override
  String toString() {
    if (remainingLockTimeMinutes > 0) {
      return '$message. Try again in $remainingLockTimeMinutes minutes.';
    }
    return message;
  }
}

/// User account is not verified (email or phone)
class UnverifiedAccountFailure extends Failure {
  final String verificationType; // 'email' or 'phone'
  
  const UnverifiedAccountFailure({
    this.verificationType = 'email',
    String message = 'Account verification required',
  }) : super(message);

  @override
  List<Object> get props => [message, verificationType];

  @override
  String toString() {
    return '$message. Please verify your $verificationType.';
  }
}

/// User account is suspended or deactivated
class SuspendedAccountFailure extends Failure {
  final String? reason;
  final DateTime? suspensionExpiresAt;
  
  const SuspendedAccountFailure({
    String message = 'Account is suspended',
    this.reason,
    this.suspensionExpiresAt,
  }) : super(message);

  @override
  List<Object?> get props => [message, reason, suspensionExpiresAt];

  @override
  String toString() {
    if (reason != null) {
      return '$message. Reason: $reason';
    }
    return message;
  }
}

/// Email address is already registered
class EmailAlreadyExistsFailure extends Failure {
  final String email;
  
  const EmailAlreadyExistsFailure(this.email)
      : super('Email address is already registered');

  @override
  List<Object> get props => [message, email];

  @override
  String toString() {
    return 'The email address "$email" is already registered. Please use a different email or try logging in.';
  }
}

/// Phone number is already registered
class PhoneAlreadyExistsFailure extends Failure {
  final String phoneNumber;
  
  const PhoneAlreadyExistsFailure(this.phoneNumber)
      : super('Phone number is already registered');

  @override
  List<Object> get props => [message, phoneNumber];

  @override
  String toString() {
    return 'The phone number "$phoneNumber" is already registered.';
  }
}

/// Token has expired and needs to be refreshed
class TokenExpiredFailure extends Failure {
  final String tokenType; // 'access', 'refresh', 'verification', 'reset'
  
  const TokenExpiredFailure({
    this.tokenType = 'access',
    String message = 'Token has expired',
  }) : super(message);

  @override
  List<Object> get props => [message, tokenType];

  @override
  String toString() {
    return '$tokenType token has expired. Please ${tokenType == 'access' ? 'refresh your session' : 'try again'}.';
  }
}

/// Invalid or malformed token
class InvalidTokenFailure extends Failure {
  final String tokenType;
  
  const InvalidTokenFailure({
    this.tokenType = 'token',
    String message = 'Invalid token',
  }) : super(message);

  @override
  List<Object> get props => [message, tokenType];

  @override
  String toString() {
    return 'Invalid $tokenType. Please try again.';
  }
}

/// Session has expired and user needs to log in again
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([String message = 'Session has expired. Please log in again.'])
      : super(message);

  @override
  List<Object> get props => [message];
}

/// Insufficient permissions for the requested operation
class InsufficientPermissionsFailure extends Failure {
  final String requiredRole;
  final String currentRole;
  
  const InsufficientPermissionsFailure({
    required this.requiredRole,
    required this.currentRole,
    String message = 'Insufficient permissions',
  }) : super(message);

  @override
  List<Object> get props => [message, requiredRole, currentRole];

  @override
  String toString() {
    return 'Access denied. Required role: $requiredRole, your role: $currentRole.';
  }
}

/// Two-factor authentication is required
class TwoFactorRequiredFailure extends Failure {
  final List<String> availableMethods; // ['sms', 'email', 'authenticator']
  
  const TwoFactorRequiredFailure({
    this.availableMethods = const ['sms'],
    String message = 'Two-factor authentication required',
  }) : super(message);

  @override
  List<Object> get props => [message, availableMethods];

  @override
  String toString() {
    return '$message. Available methods: ${availableMethods.join(', ')}';
  }
}

/// Invalid two-factor authentication code
class InvalidTwoFactorCodeFailure extends Failure {
  final int attemptsRemaining;
  
  const InvalidTwoFactorCodeFailure({
    this.attemptsRemaining = 0,
    String message = 'Invalid verification code',
  }) : super(message);

  @override
  List<Object> get props => [message, attemptsRemaining];

  @override
  String toString() {
    if (attemptsRemaining > 0) {
      return '$message. $attemptsRemaining attempts remaining.';
    }
    return message;
  }
}

/// Rate limiting - too many requests
class RateLimitExceededFailure extends Failure {
  final Duration retryAfter;
  final int requestsPerWindow;
  
  const RateLimitExceededFailure({
    required this.retryAfter,
    this.requestsPerWindow = 0,
    String message = 'Too many requests',
  }) : super(message);

  @override
  List<Object> get props => [message, retryAfter, requestsPerWindow];

  @override
  String toString() {
    final minutes = retryAfter.inMinutes;
    if (minutes > 0) {
      return '$message. Please try again in $minutes minutes.';
    }
    final seconds = retryAfter.inSeconds;
    return '$message. Please try again in $seconds seconds.';
  }
}