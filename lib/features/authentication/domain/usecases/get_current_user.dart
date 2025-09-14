import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting the current authenticated user.
/// Validates session and returns user information.
class GetCurrentUser implements UseCase<User, NoParams> {
  final AuthRepository repository;

  const GetCurrentUser(this.repository);

  @override
  Future<Either<Failure, User>> call(NoParams params) async {
    try {
      // Check if session is valid first
      final isValid = await repository.isSessionValid();
      if (!isValid) {
        return Left(AuthenticationFailure('Session is not valid'));
      }
      
      // Get current user
      final result = await repository.getCurrentUser();
      
      return result.fold(
        (failure) {
          // If getting user fails due to auth issues, clear stored auth
          if (failure is AuthenticationFailure) {
            repository.clearStoredAuth();
          }
          return Left(failure);
        },
        (user) async {
          // Verify user is active
          if (!user.isActive) {
            await repository.clearStoredAuth();
            return Left(AuthenticationFailure('User account is inactive'));
          }
          
          // Update last activity
          await repository.updateLastActivity();
          
          return Right(user);
        },
      );
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get current user: ${e.toString()}'));
    }
  }
}

/// Use case for getting current user without session validation.
/// Useful when you need user data and session validation is handled elsewhere.
class GetCurrentUserUnsafe implements UseCase<User, NoParams> {
  final AuthRepository repository;

  const GetCurrentUserUnsafe(this.repository);

  @override
  Future<Either<Failure, User>> call(NoParams params) async {
    try {
      return await repository.getCurrentUser();
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get current user: ${e.toString()}'));
    }
  }
}