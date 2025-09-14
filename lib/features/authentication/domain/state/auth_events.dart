import 'package:equatable/equatable.dart';
import '../value_objects/user_role.dart';

/// Authentication events for state management
/// Represents all possible authentication actions/events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// App started - check for existing authentication session
class AuthCheckSession extends AuthEvent {
  const AuthCheckSession();
}

/// User initiated login
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String? deviceId;
  final bool rememberMe;
  
  const AuthLoginRequested({
    required this.email,
    required this.password,
    this.deviceId,
    this.rememberMe = false,
  });
  
  @override
  List<Object?> get props => [email, password, deviceId, rememberMe];
}

/// User initiated registration
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? phoneNumber;
  final String? deviceId;
  final Map<String, dynamic>? metadata;
  
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phoneNumber,
    this.deviceId,
    this.metadata,
  });
  
  @override
  List<Object?> get props => [
    email, password, firstName, lastName, role, 
    phoneNumber, deviceId, metadata
  ];
}

/// User initiated logout
class AuthLogoutRequested extends AuthEvent {
  final bool logoutFromAllDevices;
  
  const AuthLogoutRequested({this.logoutFromAllDevices = false});
  
  @override
  List<Object?> get props => [logoutFromAllDevices];
}

/// Force logout (due to security, admin action, etc.)
class AuthForceLogout extends AuthEvent {
  final String reason;
  
  const AuthForceLogout(this.reason);
  
  @override
  List<Object?> get props => [reason];
}

/// Token refresh needed (automatic or manual)
class AuthRefreshTokenRequested extends AuthEvent {
  final bool force;
  
  const AuthRefreshTokenRequested({this.force = false});
  
  @override
  List<Object?> get props => [force];
}

/// Session validation requested
class AuthValidateSessionRequested extends AuthEvent {
  final bool validateWithServer;
  
  const AuthValidateSessionRequested({this.validateWithServer = false});
  
  @override
  List<Object?> get props => [validateWithServer];
}

/// Password change requested
class AuthChangePasswordRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  final String? confirmPassword;
  
  const AuthChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
    this.confirmPassword,
  });
  
  @override
  List<Object?> get props => [currentPassword, newPassword, confirmPassword];
}

/// Password reset requested
class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  
  const AuthPasswordResetRequested(this.email);
  
  @override
  List<Object?> get props => [email];
}

/// Password reset confirmation
class AuthPasswordResetConfirmed extends AuthEvent {
  final String resetToken;
  final String newPassword;
  final String? confirmPassword;
  
  const AuthPasswordResetConfirmed({
    required this.resetToken,
    required this.newPassword,
    this.confirmPassword,
  });
  
  @override
  List<Object?> get props => [resetToken, newPassword, confirmPassword];
}

/// Email verification requested
class AuthVerifyEmailRequested extends AuthEvent {
  final String verificationToken;
  
  const AuthVerifyEmailRequested(this.verificationToken);
  
  @override
  List<Object?> get props => [verificationToken];
}

/// Resend email verification
class AuthResendEmailVerification extends AuthEvent {
  const AuthResendEmailVerification();
}

/// Phone verification requested
class AuthVerifyPhoneRequested extends AuthEvent {
  final String phoneNumber;
  final String verificationCode;
  
  const AuthVerifyPhoneRequested({
    required this.phoneNumber,
    required this.verificationCode,
  });
  
  @override
  List<Object?> get props => [phoneNumber, verificationCode];
}

/// Send phone verification code
class AuthSendPhoneVerification extends AuthEvent {
  final String phoneNumber;
  
  const AuthSendPhoneVerification(this.phoneNumber);
  
  @override
  List<Object?> get props => [phoneNumber];
}

/// Two-factor authentication code submitted
class AuthTwoFactorCodeSubmitted extends AuthEvent {
  final String code;
  final String method;
  
  const AuthTwoFactorCodeSubmitted({
    required this.code,
    required this.method,
  });
  
  @override
  List<Object?> get props => [code, method];
}

/// Profile update requested
class AuthUpdateProfileRequested extends AuthEvent {
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final Map<String, dynamic>? metadata;
  
  const AuthUpdateProfileRequested({
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profileImageUrl,
    this.metadata,
  });
  
  @override
  List<Object?> get props => [
    firstName, lastName, phoneNumber, profileImageUrl, metadata
  ];
}

/// Clear authentication error
class AuthClearError extends AuthEvent {
  const AuthClearError();
}

/// Update last activity timestamp
class AuthUpdateActivity extends AuthEvent {
  const AuthUpdateActivity();
}

/// Session timeout warning
class AuthSessionTimeoutWarning extends AuthEvent {
  final Duration remainingTime;
  
  const AuthSessionTimeoutWarning(this.remainingTime);
  
  @override
  List<Object?> get props => [remainingTime];
}

/// Session expired
class AuthSessionExpired extends AuthEvent {
  final String reason;
  
  const AuthSessionExpired(this.reason);
  
  @override
  List<Object?> get props => [reason];
}

/// Permission check requested
class AuthCheckPermissionRequested extends AuthEvent {
  final String permission;
  
  const AuthCheckPermissionRequested(this.permission);
  
  @override
  List<Object?> get props => [permission];
}

/// Biometric authentication requested (if supported)
class AuthBiometricAuthRequested extends AuthEvent {
  const AuthBiometricAuthRequested();
}

/// Biometric authentication result
class AuthBiometricAuthResult extends AuthEvent {
  final bool success;
  final String? error;
  
  const AuthBiometricAuthResult({
    required this.success,
    this.error,
  });
  
  @override
  List<Object?> get props => [success, error];
}

/// Reset authentication state to initial
class AuthReset extends AuthEvent {
  const AuthReset();
}