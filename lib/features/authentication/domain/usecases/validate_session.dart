import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Use case for validating current authentication session.
/// Returns true if session is valid, false otherwise.
class ValidateSession implements UseCase<bool, NoParams> {
  final AuthRepository repository;

  const ValidateSession(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    try {
      // Check if session is valid
      final isValid = await repository.isSessionValid();
      return Right(isValid);
    } catch (e) {
      return Left(UnexpectedFailure('Session validation failed: ${e.toString()}'));
    }
  }
}