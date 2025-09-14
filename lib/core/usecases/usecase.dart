import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

/// Base use case interface for all domain use cases.
/// Follows Clean Architecture principles with Either<Failure, Success> pattern.
abstract class UseCase<Type, Params> {
  /// Executes the use case with given parameters.
  /// Returns Either<Failure, Type> where:
  /// - Left side contains Failure if operation failed
  /// - Right side contains Type if operation succeeded
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case that doesn't require parameters
/// Use NoParams() when calling the use case
class NoParams extends Equatable {
  const NoParams();
  
  @override
  List<Object?> get props => [];
}

/// Use case for operations that don't return data (void operations)
/// Returns Unit on success which represents successful completion
abstract class VoidUseCase<Params> {
  Future<Either<Failure, Unit>> call(Params params);
}

/// Synchronous use case interface for operations that don't require async
abstract class SyncUseCase<Type, Params> {
  Either<Failure, Type> call(Params params);
}

/// Stream use case for operations that return streams of data
abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

/// Use case that returns a stream without failure handling
/// Useful for real-time data that doesn't need error wrapping
abstract class StreamDataUseCase<Type, Params> {
  Stream<Type> call(Params params);
}