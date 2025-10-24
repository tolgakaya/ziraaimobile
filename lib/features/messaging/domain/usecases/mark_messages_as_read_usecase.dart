import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/messaging_repository.dart';

/// Mark multiple messages as read (bulk operation)
///
/// This use case marks multiple messages as read in a single API call.
/// Only the recipient (toUserId) can mark messages as read.
///
/// This is more efficient than marking messages one by one when:
/// - Opening a conversation with multiple unread messages
/// - Scrolling through unread messages
/// - "Mark all as read" action
///
/// Usage:
/// ```dart
/// final result = await markMessagesAsReadUseCase([123, 124, 125]);
/// result.fold(
///   (failure) => print('Failed to mark as read'),
///   (count) => print('$count messages marked as read'),
/// );
/// ```
class MarkMessagesAsReadUseCase {
  final MessagingRepository _repository;

  MarkMessagesAsReadUseCase(this._repository);

  /// Call the use case to mark multiple messages as read
  ///
  /// Parameters:
  /// - messageIds: List of message IDs to mark as read
  ///
  /// Returns:
  /// - Right(int) - Number of messages successfully marked as read
  /// - Left(Failure) - Error if operation fails
  Future<Either<Failure, int>> call(List<int> messageIds) async {
    if (messageIds.isEmpty) {
      return const Right(0);
    }

    return await _repository.markMessagesAsRead(messageIds);
  }
}
