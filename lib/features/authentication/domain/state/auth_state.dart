import 'package:equatable/equatable.dart';
import '../entities/auth_session.dart';
import '../entities/user.dart';
import '../../../../core/errors/failures.dart';

/// Authentication state for state management
/// Represents all possible authentication states in the application
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - app just started, checking for existing session
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state - authentication operation in progress
class AuthLoading extends AuthState {
  final String? message;
  
  const AuthLoading({this.message});
  
  @override
  List<Object?> get props => [message];
}

/// Authenticated state - user is logged in with valid session
class AuthAuthenticated extends AuthState {
  final AuthSession session;
  final DateTime lastActivity;
  
  const AuthAuthenticated({
    required this.session,
    required this.lastActivity,
  });
  
  /// Convenience getter for user
  User get user => session.user;
  
  /// Check if session needs refresh soon
  bool get needsRefresh => session.needsRefresh;
  
  /// Check if session is still valid
  bool get isValid => session.isValid;
  
  @override
  List<Object?> get props => [session, lastActivity];
}

/// Unauthenticated state - no valid session, user needs to log in
class AuthUnauthenticated extends AuthState {
  final String? message;
  final bool requiresAction; // true if user was logged out due to error
  
  const AuthUnauthenticated({
    this.message,
    this.requiresAction = false,
  });
  
  @override
  List<Object?> get props => [message, requiresAction];
}

/// Authentication failed state - login/register attempt failed
class AuthFailure extends AuthState {
  final Failure failure;
  final String operation; // 'login', 'register', 'refresh', etc.
  final bool canRetry;
  
  const AuthFailure({
    required this.failure,
    required this.operation,
    this.canRetry = true,
  });
  
  @override
  List<Object?> get props => [failure, operation, canRetry];
}

/// Token refresh in progress
class AuthRefreshing extends AuthState {
  final AuthSession currentSession;
  
  const AuthRefreshing(this.currentSession);
  
  @override
  List<Object?> get props => [currentSession];
}

/// Session expired - need to refresh or re-authenticate
class AuthSessionExpired extends AuthState {
  final String? message;
  final bool canRefresh;
  
  const AuthSessionExpired({
    this.message,
    this.canRefresh = true,
  });
  
  @override
  List<Object?> get props => [message, canRefresh];
}

/// Logout in progress
class AuthLoggingOut extends AuthState {
  final bool logoutFromAllDevices;
  
  const AuthLoggingOut({this.logoutFromAllDevices = false});
  
  @override
  List<Object?> get props => [logoutFromAllDevices];
}

/// Registration-specific states

/// Registration in progress
class AuthRegistering extends AuthState {
  final String email;
  final String role;
  
  const AuthRegistering({
    required this.email,
    required this.role,
  });
  
  @override
  List<Object?> get props => [email, role];
}

/// Registration completed but email verification required
class AuthRegistrationComplete extends AuthState {
  final String email;
  final String message;
  
  const AuthRegistrationComplete({
    required this.email,
    this.message = 'Registration successful. Please check your email for verification.',
  });
  
  @override
  List<Object?> get props => [email, message];
}

/// Password reset states

/// Password reset request sent
class AuthPasswordResetSent extends AuthState {
  final String email;
  final String message;
  
  const AuthPasswordResetSent({
    required this.email,
    this.message = 'Password reset instructions sent to your email.',
  });
  
  @override
  List<Object?> get props => [email, message];
}

/// Verification states

/// Email verification in progress
class AuthVerifyingEmail extends AuthState {
  final String token;
  
  const AuthVerifyingEmail(this.token);
  
  @override
  List<Object?> get props => [token];
}

/// Email verification successful
class AuthEmailVerified extends AuthState {
  final String message;
  
  const AuthEmailVerified({
    this.message = 'Email verified successfully.',
  });
  
  @override
  List<Object?> get props => [message];
}

/// Phone verification in progress
class AuthVerifyingPhone extends AuthState {
  final String phoneNumber;
  
  const AuthVerifyingPhone(this.phoneNumber);
  
  @override
  List<Object?> get props => [phoneNumber];
}

/// Two-factor authentication required
class AuthTwoFactorRequired extends AuthState {
  final List<String> availableMethods;
  final String? preferredMethod;
  
  const AuthTwoFactorRequired({
    required this.availableMethods,
    this.preferredMethod,
  });
  
  @override
  List<Object?> get props => [availableMethods, preferredMethod];
}

/// Helper extensions for state checking
extension AuthStateExtensions on AuthState {
  bool get isAuthenticated => this is AuthAuthenticated;
  bool get isUnauthenticated => this is AuthUnauthenticated;
  bool get isLoading => this is AuthLoading;
  bool get isInitial => this is AuthInitial;
  bool get hasError => this is AuthFailure;
  bool get isRefreshing => this is AuthRefreshing;
  bool get isSessionExpired => this is AuthSessionExpired;
  
  AuthSession? get session {
    if (this is AuthAuthenticated) {
      return (this as AuthAuthenticated).session;
    }
    return null;
  }
  
  User? get user => session?.user;
  
  Failure? get failure {
    if (this is AuthFailure) {
      return (this as AuthFailure).failure;
    }
    return null;
  }
}