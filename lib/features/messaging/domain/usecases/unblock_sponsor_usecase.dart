import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/messaging_repository.dart';

class UnblockSponsorUseCase {
  final MessagingRepository repository;

  UnblockSponsorUseCase(this.repository);

  Future<Either<Failure, Unit>> call(int sponsorId) async {
    return await repository.unblockSponsor(sponsorId);
  }
}
