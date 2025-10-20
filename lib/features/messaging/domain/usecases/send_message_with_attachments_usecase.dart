import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../repositories/messaging_repository.dart';

@lazySingleton
class SendMessageWithAttachmentsUseCase {
  final MessagingRepository _repository;

  SendMessageWithAttachmentsUseCase(this._repository);

  Future<Either<Failure, Message>> call({
    required int plantAnalysisId,
    required int toUserId,
    required String message,
    required List<String> attachmentPaths,
  }) async {
    return await _repository.sendMessageWithAttachments(
      plantAnalysisId: plantAnalysisId,
      toUserId: toUserId,
      message: message,
      attachmentPaths: attachmentPaths,
    );
  }
}
