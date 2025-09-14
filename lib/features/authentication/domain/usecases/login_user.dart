import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import '../value_objects/email.dart';
import '../value_objects/password.dart';

/// Use case for user login with email and password.
/// Handles authentication validation and session creation.
class LoginUser implements UseCase<AuthSession, LoginUserParams> {
  final AuthRepository repository;

  const LoginUser(this.repository);

  @override
  Future<Either<Failure, AuthSession>> call(LoginUserParams params) async {
    try {
      // Validate email format
      final email = Email(params.email);
      
      // Validate password (basic check for empty password)
      if (params.password.isEmpty) {
        return Left(ValidationFailure('Password cannot be empty'));
      }
      
      final password = Password.unsafe(params.password); // Don't validate strength on login
      
      // Perform login
      final result = await repository.login(
        email: email,
        password: password,
        deviceId: params.deviceId,
        rememberMe: params.rememberMe,
      );
      
      return result.fold(
        (failure) => Left(failure),
        (session) async {
          // Store tokens if login successful and rememberMe is true
          if (params.rememberMe) {
            await repository.storeTokens(session.tokens);
          }
          
          // Update last activity
          await repository.updateLastActivity();
          
          return Right(session);
        },
      );
    } on ArgumentError catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Login failed: ${e.toString()}'));
    }
  }
}

/// Parameters for the LoginUser use case
class LoginUserParams extends Equatable {
  final String email;
  final String password;
  final String? deviceId;
  final bool rememberMe;

  const LoginUserParams({
    required this.email,
    required this.password,
    this.deviceId,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [email, password, deviceId, rememberMe];

  @override
  String toString() {
    return 'LoginUserParams(email: $email, rememberMe: $rememberMe, hasDeviceId: ${deviceId != null})';
  }
}