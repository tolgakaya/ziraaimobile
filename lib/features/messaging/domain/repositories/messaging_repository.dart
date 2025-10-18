import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../entities/blocked_sponsor.dart';
import '../entities/message_quota.dart';

abstract class MessagingRepository {
  Future<Either<Failure, Message>> sendMessage({
    required int plantAnalysisId,
    required int toUserId,
    required String message,
    String? messageType,
    String? subject,
  });

  Future<Either<Failure, List<Message>>> getMessages({
    required int plantAnalysisId,
    required int farmerId,
  });

  Future<Either<Failure, Unit>> blockSponsor({
    required int sponsorId,
    String? reason,
  });

  Future<Either<Failure, Unit>> unblockSponsor(int sponsorId);

  Future<Either<Failure, List<BlockedSponsor>>> getBlockedSponsors();

  Future<Either<Failure, MessageQuota>> getRemainingQuota(int farmerId);
}
