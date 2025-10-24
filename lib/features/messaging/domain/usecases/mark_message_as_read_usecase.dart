import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/messaging_repository.dart';

/// Mark a single message as read
///
/// This use case marks a message as read for the current user.
/// Only the recipient (toUserId) can mark a message as read.
///
/// Usage:
/// ```dart
/// final result = await markMessageAsReadUseCase(messageId: 123);
/// result.fold(
///   (failure) => print('Failed to mark as read'),
///   (_) => print('Message marked as read'),
/// );
/// ```
class MarkMessageAsReadUseCase {
  final MessagingRepository _repository;

  MarkMessageAsReadUseCase(this._repository);

  /// Call the use case to mark a single message as read
  ///
  /// Returns:
  /// - Right(unit) on success
  /// - Left(Failure) on error
  Future<Either<Failure, Unit>> call(int messageId) async {
    return await _repository.markMessageAsRead(messageId);
  }
}
