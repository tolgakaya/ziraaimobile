import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Use case for user logout.
/// Handles token invalidation and cleanup of stored authentication data.
class LogoutUser implements UseCase<Unit, LogoutUserParams> {
  final AuthRepository repository;

  const LogoutUser(this.repository);

  @override
  Future<Either<Failure, Unit>> call(LogoutUserParams params) async {
    try {
      // Get stored tokens for logout request
      final storedTokens = await repository.getStoredTokens();
      
      // Perform logout on server
      final result = await repository.logout(
        refreshToken: storedTokens?.refreshToken ?? params.refreshToken,
        logoutFromAllDevices: params.logoutFromAllDevices,
      );
      
      // Always clear stored authentication data locally, even if server logout fails
      // This ensures user is logged out from the app regardless of server response
      await repository.clearStoredAuth();
      
      return result.fold(
        (failure) {
          // If server logout fails but local cleanup succeeded, 
          // we still consider it a successful logout from user perspective
          if (failure is NetworkFailure || failure is ServerFailure) {
            return const Right(unit);
          }
          return Left(failure);
        },
        (success) => Right(success),
      );
    } catch (e) {
      // Even if logout fails, clear local data
      await repository.clearStoredAuth();
      return Left(UnexpectedFailure('Logout process failed: ${e.toString()}'));
    }
  }
}

/// Parameters for the LogoutUser use case
class LogoutUserParams extends Equatable {
  final String? refreshToken;
  final bool logoutFromAllDevices;

  const LogoutUserParams({
    this.refreshToken,
    this.logoutFromAllDevices = false,
  });

  @override
  List<Object?> get props => [refreshToken, logoutFromAllDevices];

  @override
  String toString() {
    return 'LogoutUserParams(logoutFromAllDevices: $logoutFromAllDevices, hasRefreshToken: ${refreshToken != null})';
  }
}

/// Convenience factory for common logout scenarios
class LogoutUserParamsFactory {
  /// Creates params for standard logout (current device only)
  static LogoutUserParams standard() {
    return const LogoutUserParams();
  }
  
  /// Creates params for logout from all devices
  static LogoutUserParams allDevices() {
    return const LogoutUserParams(logoutFromAllDevices: true);
  }
  
  /// Creates params with specific refresh token
  static LogoutUserParams withToken(String refreshToken) {
    return LogoutUserParams(refreshToken: refreshToken);
  }
}