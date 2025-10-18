import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/messaging_repository.dart';

class BlockSponsorUseCase {
  final MessagingRepository repository;

  BlockSponsorUseCase(this.repository);

  Future<Either<Failure, Unit>> call(BlockSponsorParams params) async {
    return await repository.blockSponsor(
      sponsorId: params.sponsorId,
      reason: params.reason,
    );
  }
}

class BlockSponsorParams {
  final int sponsorId;
  final String? reason;

  BlockSponsorParams({
    required this.sponsorId,
    this.reason,
  });
}
