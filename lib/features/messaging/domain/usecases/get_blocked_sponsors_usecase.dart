import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/blocked_sponsor.dart';
import '../repositories/messaging_repository.dart';

class GetBlockedSponsorsUseCase {
  final MessagingRepository repository;

  GetBlockedSponsorsUseCase(this.repository);

  Future<Either<Failure, List<BlockedSponsor>>> call() async {
    return await repository.getBlockedSponsors();
  }
}
