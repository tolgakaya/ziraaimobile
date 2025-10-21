import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../entities/blocked_sponsor.dart';
import '../entities/message_quota.dart';
import '../entities/paginated_messages.dart';
import '../entities/messaging_features.dart';

abstract class MessagingRepository {
  Future<Either<Failure, Message>> sendMessage({
    required int plantAnalysisId,
    required int toUserId,
    required String message,
    String? messageType,
    String? subject,
  });

  Future<Either<Failure, PaginatedMessages>> getMessages({
    required int plantAnalysisId,
    required int otherUserId,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, Unit>> blockSponsor({
    required int sponsorId,
    String? reason,
  });

  Future<Either<Failure, Unit>> unblockSponsor(int sponsorId);

  Future<Either<Failure, List<BlockedSponsor>>> getBlockedSponsors();

  Future<Either<Failure, MessageQuota>> getRemainingQuota(int farmerId);

  /// Send message with image/file attachments
  /// fromUserId is automatically extracted from JWT token by backend
  Future<Either<Failure, Message>> sendMessageWithAttachments({
    required int plantAnalysisId,
    required int toUserId,
    required String message,
    required List<String> attachmentPaths,
  });

  /// Send voice message (XL tier only)
  Future<Either<Failure, Message>> sendVoiceMessage({
    required int toUserId,
    required int plantAnalysisId,
    required File voiceFile,
    required int duration,
    List<double>? waveform,
  });

  /// Get user's available messaging features based on tier
  /// ⚠️ BREAKING CHANGE: Now requires plantAnalysisId to get features for specific analysis
  Future<Either<Failure, MessagingFeatures>> getAvailableFeatures({required int plantAnalysisId});
}
