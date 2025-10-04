import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

// Phone OTP Authentication States

class PhoneOtpSent extends AuthState {
  final String mobilePhone;
  final String? otpCode; // In dev environment, OTP is returned in response
  final bool isRegistration; // true for registration, false for login

  const PhoneOtpSent({
    required this.mobilePhone,
    this.otpCode,
    required this.isRegistration,
  });

  @override
  List<Object?> get props => [mobilePhone, otpCode, isRegistration];
}