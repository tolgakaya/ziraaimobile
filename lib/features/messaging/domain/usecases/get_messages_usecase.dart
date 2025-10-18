import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../repositories/messaging_repository.dart';

@lazySingleton
class GetMessagesUseCase {
  final MessagingRepository repository;

  GetMessagesUseCase(this.repository);

  Future<Either<Failure, List<Message>>> call({
    required int plantAnalysisId,
    required int farmerId,
  }) async {
    return await repository.getMessages(
      plantAnalysisId: plantAnalysisId,
      farmerId: farmerId,
    );
  }
}
