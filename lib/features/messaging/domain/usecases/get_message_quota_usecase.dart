import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message_quota.dart';
import '../repositories/messaging_repository.dart';

class GetMessageQuotaUseCase {
  final MessagingRepository repository;

  GetMessageQuotaUseCase(this.repository);

  Future<Either<Failure, MessageQuota>> call(int farmerId) async {
    return await repository.getRemainingQuota(farmerId);
  }
}
