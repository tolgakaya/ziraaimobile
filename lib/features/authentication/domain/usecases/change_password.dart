import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';
import '../value_objects/password.dart';

/// Use case for changing user password.
/// Validates current password and sets new password with security requirements.
class ChangePassword implements UseCase<Unit, ChangePasswordParams> {
  final AuthRepository repository;

  const ChangePassword(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ChangePasswordParams params) async {
    try {
      // Validate current password is not empty
      if (params.currentPassword.isEmpty) {
        return Left(ValidationFailure('Current password cannot be empty'));
      }
      
      // Validate new password strength
      final newPassword = Password(params.newPassword);
      
      // Ensure new password is different from current password
      if (params.currentPassword == params.newPassword) {
        return Left(ValidationFailure('New password must be different from current password'));
      }
      
      // Create password objects
      final currentPassword = Password.unsafe(params.currentPassword);
      
      // Additional security check - ensure new password is strong enough
      if (!newPassword.isSecure) {
        return Left(ValidationFailure(
          'New password does not meet security requirements. '
          'Password strength: ${newPassword.strength.displayName}'
        ));
      }
      
      // Perform password change
      final result = await repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      return result.fold(
        (failure) => Left(failure),
        (unit) async {
          // Update last activity after successful password change
          await repository.updateLastActivity();
          
          return Right(unit);
        },
      );
    } on ArgumentError catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Password change failed: ${e.toString()}'));
    }
  }
}

/// Parameters for the ChangePassword use case
class ChangePasswordParams extends Equatable {
  final String currentPassword;
  final String newPassword;
  final String? confirmPassword;

  const ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
    this.confirmPassword,
  });

  /// Validates that new password and confirmation match
  bool get passwordsMatch {
    return confirmPassword == null || newPassword == confirmPassword;
  }

  /// Factory method with password confirmation validation
  factory ChangePasswordParams.withConfirmation({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    if (newPassword != confirmPassword) {
      throw ArgumentError('Password confirmation does not match');
    }
    
    return ChangePasswordParams(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  @override
  List<Object?> get props => [currentPassword, newPassword, confirmPassword];

  @override
  String toString() {
    return 'ChangePasswordParams(hasCurrentPassword: ${currentPassword.isNotEmpty}, '
           'hasNewPassword: ${newPassword.isNotEmpty}, '
           'hasConfirmation: ${confirmPassword != null})';
  }
}