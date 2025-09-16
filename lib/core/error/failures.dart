import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure({required String message, String? code}) : super(message: message, code: code);
}

class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'Network connection error', String? code}) : super(message: message, code: code);
}

class CacheFailure extends Failure {
  const CacheFailure({required String message, String? code}) : super(message: message, code: code);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required String message, String? code}) : super(message: message, code: code);
}

class ValidationFailure extends Failure {
  const ValidationFailure({required String message, String? code}) : super(message: message, code: code);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({String message = 'Unauthorized access', String? code}) : super(message: message, code: code);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({String message = 'Resource not found', String? code}) : super(message: message, code: code);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required String message, String? code}) : super(message: message, code: code);
}

class AuthorizationFailure extends Failure {
  const AuthorizationFailure({required String message, String? code}) : super(message: message, code: code);
}

class QuotaExceededFailure extends Failure {
  const QuotaExceededFailure({required String message, String? code}) : super(message: message, code: code);
}