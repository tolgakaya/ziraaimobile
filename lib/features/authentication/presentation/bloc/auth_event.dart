import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirmPassword;
  final String? phoneNumber;

  const AuthRegisterRequested({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        email,
        password,
        confirmPassword,
        phoneNumber,
      ];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthCheckStatusRequested extends AuthEvent {
  const AuthCheckStatusRequested();
}

class AuthResetPasswordRequested extends AuthEvent {
  final String email;

  const AuthResetPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

// Phone-based OTP Authentication Events

class PhoneLoginOtpRequested extends AuthEvent {
  final String mobilePhone;

  const PhoneLoginOtpRequested({required this.mobilePhone});

  @override
  List<Object?> get props => [mobilePhone];
}

class PhoneLoginOtpVerifyRequested extends AuthEvent {
  final String mobilePhone;
  final int code;

  const PhoneLoginOtpVerifyRequested({
    required this.mobilePhone,
    required this.code,
  });

  @override
  List<Object?> get props => [mobilePhone, code];
}

class PhoneRegisterOtpRequested extends AuthEvent {
  final String mobilePhone;
  final String? referralCode;

  const PhoneRegisterOtpRequested({
    required this.mobilePhone,
    this.referralCode,
  });

  @override
  List<Object?> get props => [mobilePhone, referralCode];
}

class PhoneRegisterOtpVerifyRequested extends AuthEvent {
  final String mobilePhone;
  final int code;
  final String? referralCode;

  const PhoneRegisterOtpVerifyRequested({
    required this.mobilePhone,
    required this.code,
    this.referralCode,
  });

  @override
  List<Object?> get props => [mobilePhone, code, referralCode];
}