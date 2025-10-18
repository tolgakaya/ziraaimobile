import '../../../../core/error/failures.dart';

/// Messaging-specific failure classes
/// Extends core Failure class with messaging domain context

/// Rate limit exceeded for messaging
class RateLimitFailure extends Failure {
  const RateLimitFailure({super.message = 'Rate limit exceeded', super.code});

  @override
  List<Object?> get props => [message, code];
}

/// Request was cancelled by user
class CancelFailure extends Failure {
  const CancelFailure({super.message = 'Request cancelled', super.code});

  @override
  List<Object?> get props => [message, code];
}
