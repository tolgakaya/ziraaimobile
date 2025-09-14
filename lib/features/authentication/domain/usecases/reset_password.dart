import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';
import '../value_objects/email.dart';

/// Use case for requesting password reset.
/// Sends password reset email to user's registered email address.
class ResetPassword implements UseCase<Unit, ResetPasswordParams> {
  final AuthRepository repository;

  const ResetPassword(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ResetPasswordParams params) async {
    try {
      // Validate email format
      final email = Email(params.email);
      
      // Request password reset
      final result = await repository.requestPasswordReset(email);
      
      return result;
    } on ArgumentError catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Password reset request failed: ${e.toString()}'));
    }
  }
}

/// Parameters for password reset request
class ResetPasswordParams extends Equatable {
  final String email;

  const ResetPasswordParams({required this.email});

  @override
  List<Object?> get props => [email];

  @override
  String toString() {
    return 'ResetPasswordParams(email: $email)';
  }
}