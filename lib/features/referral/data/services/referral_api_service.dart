import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:injectable/injectable.dart';
import '../models/referral_generate_request.dart';
import '../models/referral_link_response.dart';
import '../models/referral_stats.dart';
import '../models/credit_breakdown.dart';
import '../models/referral_reward.dart';

part 'referral_api_service.g.dart';

/// Referral system API service
/// Handles referral link generation, statistics, and rewards
@RestApi()
@injectable
abstract class ReferralApiService {
  @factoryMethod
  factory ReferralApiService(Dio dio, {String baseUrl}) = _ReferralApiService;

  /// Generate referral link and optionally send via SMS/WhatsApp
  /// API: POST /api/v1/Referral/generate
  ///
  /// Delivery methods:
  /// - 1 = SMS only
  /// - 2 = WhatsApp only
  /// - 3 = Both SMS and WhatsApp
  ///
  /// Returns deep link in format: https://ziraai.com/ref/ZIRA-XXXXXX
  /// Link expires after configured time period (e.g., 30 days)
  @POST('/Referral/generate')
  Future<ReferralLinkResponse> generateReferralLink(
    @Body() ReferralGenerateRequest request,
    @Header('Authorization') String authorization,
  );

  /// Get referral statistics for current user
  /// API: GET /api/v1/Referral/stats
  ///
  /// Returns breakdown of referrals by status:
  /// - clicked: Users who clicked the link
  /// - registered: Users who completed registration
  /// - validated: Users who validated their phone
  /// - rewarded: Users who triggered reward for referrer
  @GET('/Referral/stats')
  Future<ReferralStatsResponse> getReferralStats(
    @Header('Authorization') String authorization,
  );

  /// Get credit breakdown for current user
  /// API: GET /api/v1/Referral/credits
  ///
  /// Returns:
  /// - totalEarned: Total credits earned from referrals
  /// - totalUsed: Credits used for plant analyses
  /// - currentBalance: Available credits
  @GET('/Referral/credits')
  Future<CreditBreakdownResponse> getCreditBreakdown(
    @Header('Authorization') String authorization,
  );

  /// Get list of referral rewards received
  /// API: GET /api/v1/Referral/rewards
  ///
  /// Returns history of credits earned when referred users completed actions
  /// Each reward includes:
  /// - refereeUserName: Name of user who was referred (NOT email)
  /// - creditAmount: Credits awarded for this referral
  /// - awardedAt: When the reward was granted
  @GET('/Referral/rewards')
  Future<ReferralRewardsResponse> getReferralRewards(
    @Header('Authorization') String authorization,
  );
}
