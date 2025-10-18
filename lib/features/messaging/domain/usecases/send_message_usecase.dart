import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../repositories/messaging_repository.dart';

@lazySingleton
class SendMessageUseCase {
  final MessagingRepository repository;

  SendMessageUseCase(this.repository);

  Future<Either<Failure, Message>> call(SendMessageParams params) async {
    return await repository.sendMessage(
      plantAnalysisId: params.plantAnalysisId,
      toUserId: params.toUserId,
      message: params.message,
      messageType: params.messageType,
      subject: params.subject,
    );
  }
}

class SendMessageParams {
  final int plantAnalysisId;
  final int toUserId;
  final String message;
  final String? messageType;
  final String? subject;

  SendMessageParams({
    required this.plantAnalysisId,
    required this.toUserId,
    required this.message,
    this.messageType,
    this.subject,
  });
}
