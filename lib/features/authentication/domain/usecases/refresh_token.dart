import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_tokens.dart';
import '../repositories/auth_repository.dart';

/// Use case for refreshing authentication tokens.
/// Handles automatic token renewal to maintain user session.
class RefreshToken implements UseCase<AuthTokens, RefreshTokenParams> {
  final AuthRepository repository;

  const RefreshToken(this.repository);

  @override
  Future<Either<Failure, AuthTokens>> call(RefreshTokenParams params) async {
    try {
      String? refreshToken = params.refreshToken;
      
      // If no refresh token provided, try to get from storage
      if (refreshToken == null) {
        final storedTokens = await repository.getStoredTokens();
        if (storedTokens == null) {
          return Left(AuthenticationFailure('No refresh token available'));
        }
        refreshToken = storedTokens.refreshToken;
      }
      
      // Validate refresh token format
      if (refreshToken.isEmpty) {
        return Left(ValidationFailure('Refresh token cannot be empty'));
      }
      
      // Perform token refresh
      final result = await repository.refreshToken(refreshToken);
      
      return result.fold(
        (failure) {
          // If refresh fails due to invalid token, clear stored auth
          if (failure is AuthenticationFailure) {
            repository.clearStoredAuth();
          }
          return Left(failure);
        },
        (newTokens) async {
          // Store new tokens if refresh successful
          await repository.storeTokens(newTokens);
          
          // Update last activity
          await repository.updateLastActivity();
          
          return Right(newTokens);
        },
      );
    } catch (e) {
      return Left(UnexpectedFailure('Token refresh failed: ${e.toString()}'));
    }
  }
}

/// Parameters for the RefreshToken use case
class RefreshTokenParams extends Equatable {
  final String? refreshToken;

  const RefreshTokenParams({this.refreshToken});

  @override
  List<Object?> get props => [refreshToken];

  @override
  String toString() {
    return 'RefreshTokenParams(hasRefreshToken: ${refreshToken != null})';
  }
}

/// Convenience factory for creating RefreshTokenParams
class RefreshTokenParamsFactory {
  /// Creates params using stored refresh token
  static RefreshTokenParams fromStorage() {
    return const RefreshTokenParams();
  }
  
  /// Creates params with specific refresh token
  static RefreshTokenParams withToken(String refreshToken) {
    return RefreshTokenParams(refreshToken: refreshToken);
  }
}