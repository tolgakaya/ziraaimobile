import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String? message;

  const Failure({this.message});

  @override
  List<Object?> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure({String? message}) : super(message: message);
}

class NetworkFailure extends Failure {
  const NetworkFailure({String? message}) : super(message: message ?? 'Network connection error');
}

class CacheFailure extends Failure {
  const CacheFailure({String? message}) : super(message: message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure({String? message}) : super(message: message);
}

class ValidationFailure extends Failure {
  const ValidationFailure({String? message}) : super(message: message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({String? message}) : super(message: message ?? 'Unauthorized access');
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({String? message}) : super(message: message ?? 'Resource not found');
}