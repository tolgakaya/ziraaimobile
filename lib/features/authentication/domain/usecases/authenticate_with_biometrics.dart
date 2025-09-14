import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Use case for biometric authentication
@injectable
class AuthenticateWithBiometrics implements UseCase<AuthSession, NoParams> {
  final AuthRepository repository;

  AuthenticateWithBiometrics(this.repository);

  @override
  Future<Either<Failure, AuthSession>> call(NoParams params) async {
    return await repository.authenticateWithBiometrics();
  }
}