import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../entities/paginated_messages.dart';
import '../repositories/messaging_repository.dart';

@lazySingleton
class GetMessagesUseCase {
  final MessagingRepository repository;

  GetMessagesUseCase(this.repository);

  Future<Either<Failure, PaginatedMessages>> call({
    required int plantAnalysisId,
    required int otherUserId,
    int page = 1,
    int pageSize = 20,
  }) async {
    return await repository.getMessages(
      plantAnalysisId: plantAnalysisId,
      otherUserId: otherUserId,
      page: page,
      pageSize: pageSize,
    );
  }
}
