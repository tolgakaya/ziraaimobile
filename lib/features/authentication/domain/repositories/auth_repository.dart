import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  // Email-based authentication (existing)
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    String? phoneNumber,
  });

  // Phone-based OTP authentication (new)
  /// Request OTP for phone login
  /// Returns OTP code in development (extracted from message)
  Future<Either<Failure, String>> requestPhoneLoginOtp({
    required String mobilePhone,
  });

  /// Verify OTP and complete phone login
  /// Returns authenticated user on success
  Future<Either<Failure, UserEntity>> verifyPhoneLoginOtp({
    required String mobilePhone,
    required int code,
  });

  /// Request OTP for phone registration
  /// Optional referralCode for referral system integration
  /// Returns OTP code in development (extracted from message)
  Future<Either<Failure, String>> requestPhoneRegisterOtp({
    required String mobilePhone,
    String? referralCode,
  });

  /// Verify OTP and complete phone registration
  /// Returns newly created and authenticated user
  Future<Either<Failure, UserEntity>> verifyPhoneRegisterOtp({
    required String mobilePhone,
    required int code,
    String? referralCode,
  });

  // Common auth methods
  Future<Either<Failure, void>> logout();

  Future<Either<Failure, bool>> isLoggedIn();

  Future<Either<Failure, UserEntity>> getCurrentUser();
}