import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/referral_link_response.dart';
import '../../data/models/referral_stats.dart';
import '../../data/models/credit_breakdown.dart';
import '../../data/models/referral_reward.dart';

/// Referral system repository interface
/// Handles referral link generation, statistics tracking, and reward management
abstract class ReferralRepository {
  /// Generate referral link and send via specified delivery method
  ///
  /// [phoneNumbers] List of recipient phone numbers
  /// [deliveryMethod] 1=SMS, 2=WhatsApp, 3=Both
  /// [customMessage] Optional custom message to include
  ///
  /// Returns ReferralLinkData with deep link and delivery statuses
  Future<Either<Failure, ReferralLinkData>> generateReferralLink({
    required List<String> phoneNumbers,
    required int deliveryMethod,
    String? customMessage,
  });

  /// Get referral statistics for current user
  ///
  /// Returns breakdown of referrals by status:
  /// - clicked: Users who clicked the link
  /// - registered: Users who completed registration
  /// - validated: Users who validated their phone
  /// - rewarded: Users who triggered reward for referrer
  Future<Either<Failure, ReferralStats>> getReferralStats();

  /// Get credit breakdown for current user
  ///
  /// Returns:
  /// - totalEarned: Total credits earned from referrals
  /// - totalUsed: Credits used for plant analyses
  /// - currentBalance: Available credits
  Future<Either<Failure, CreditBreakdown>> getCreditBreakdown();

  /// Get list of referral rewards received
  ///
  /// Returns history of credits earned when referred users completed actions
  Future<Either<Failure, List<ReferralReward>>> getReferralRewards();
}
