import 'package:dio/dio.dart';
import '../../../core/network/network_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/error/plant_analysis_exceptions.dart';
import '../../../core/error/subscription_exceptions.dart';
import '../models/usage_status.dart';
import '../models/subscription_tier.dart';

/// Real subscription service that calls ZiraAI API
class SubscriptionService {
  final NetworkClient _networkClient;
  final SecureStorageService _storageService;

  SubscriptionService(this._networkClient, this._storageService);

  /// Get current user's usage status
  Future<UsageStatus?> getUsageStatus() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _networkClient.get(
        ApiConfig.usageStatus,
        options: Options(
          headers: ApiConfig.authHeader(token),
        ),
      );

      // IMPORTANT: Even if success is false (no active subscription),
      // we still return the data because it contains useful information
      final data = response.data['data'];
      if (data != null) {
        return UsageStatus.fromJson(data);
      } else {
        throw Exception(response.data['message'] ?? 'No usage status data received');
      }
    } catch (e) {
      print('Error getting usage status: $e');
      rethrow; // Re-throw so screen can show proper error
    }
  }

  /// Get current user's subscription info from real API
  Future<UserSubscription?> getMySubscription() async {
    try {
      print('🔵 SubscriptionService: Getting user subscription from API...');

      final token = await _storageService.getToken();
      if (token == null) {
        throw UserSubscriptionException(
          message: 'User not authenticated',
          errorCode: 'NO_AUTH_TOKEN',
        );
      }

      final response = await _networkClient.get(
        ApiConfig.mySubscription,
        options: Options(
          headers: ApiConfig.authHeader(token),
        ),
      );

      print('🔵 SubscriptionService: My subscription API response: ${response.statusCode}');
      print('🔵 SubscriptionService: Response data: ${response.data}');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null) {
          final subscription = UserSubscription.fromJson(data);
          print('✅ SubscriptionService: Successfully loaded user subscription: ${subscription.tierName}');
          return subscription;
        } else {
          // User may not have any subscription (free tier)
          print('⚠️ SubscriptionService: No subscription data - user may be on free tier');
          return null;
        }
      } else {
        throw UserSubscriptionException(
          message: response.data['message'] ?? 'Failed to get subscription info',
          errorCode: response.data['errorCode'] ?? 'API_ERROR',
          details: response.data,
        );
      }
    } on DioException catch (e) {
      print('❌ SubscriptionService: Dio error getting subscription: $e');
      throw SubscriptionExceptionFactory.fromDioError(e, 'my_subscription');
    } catch (e) {
      print('❌ SubscriptionService: Error getting user subscription: $e');
      if (e is UserSubscriptionException) {
        rethrow;
      }
      throw UserSubscriptionException(
        message: 'Failed to load subscription info: ${e.toString()}',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get available subscription tiers from real API
  Future<List<SubscriptionTier>> getSubscriptionTiers() async {
    try {
      print('🔵 SubscriptionService: Getting subscription tiers from API...');

      final token = await _storageService.getToken();
      if (token == null) {
        throw SubscriptionTierException(
          message: 'User not authenticated',
          errorCode: 'NO_AUTH_TOKEN',
        );
      }

      final response = await _networkClient.get(
        ApiConfig.subscriptionTiers,
        options: Options(
          headers: ApiConfig.authHeader(token),
        ),
      );

      print('🔵 SubscriptionService: Tiers API response: ${response.statusCode}');
      print('🔵 SubscriptionService: Response data: ${response.data}');

      if (response.data['success'] == true) {
        final data = response.data['data'] as List?;
        if (data != null) {
          final tiers = data.map((tier) => SubscriptionTier.fromJson(tier)).toList();
          print('✅ SubscriptionService: Successfully loaded ${tiers.length} tiers');
          return tiers;
        } else {
          throw SubscriptionTierException(
            message: 'No tiers data received from API',
            errorCode: 'NO_DATA',
          );
        }
      } else {
        throw SubscriptionTierException(
          message: response.data['message'] ?? 'Failed to get subscription tiers',
          errorCode: response.data['errorCode'] ?? 'API_ERROR',
          details: response.data,
        );
      }
    } on DioException catch (e) {
      print('❌ SubscriptionService: Dio error getting tiers: $e');
      throw SubscriptionExceptionFactory.fromDioError(e, 'tiers');
    } catch (e) {
      print('❌ SubscriptionService: Error getting subscription tiers: $e');
      if (e is SubscriptionTierException) {
        rethrow;
      }
      throw SubscriptionTierException(
        message: 'Failed to load subscription tiers: ${e.toString()}',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Subscribe to a tier (Real API call)
  /// Returns true if successful, throws exception if failed
  Future<bool> subscribeTo(int tierId, {
    int durationMonths = 1,
    bool autoRenew = true,
    String paymentMethod = 'CreditCard',
    String? paymentReference,
    double? paidAmount,
    String currency = 'TRY',
  }) async {
    try {
      print('🔵 SubscriptionService: Starting subscription process for tier: $tierId');

      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final requestData = {
        'subscriptionTierId': tierId,
        'durationMonths': durationMonths,
        'autoRenew': autoRenew,
        'paymentMethod': paymentMethod,
        'paymentReference': paymentReference,
        'paidAmount': paidAmount,
        'currency': currency,
      };

      print('🔵 SubscriptionService: Subscription request data: $requestData');

      final response = await _networkClient.post(
        ApiConfig.subscribe,
        data: requestData,
        options: Options(
          headers: ApiConfig.authHeader(token),
        ),
      );

      print('🔵 SubscriptionService: Subscription API response: ${response.statusCode}');
      print('🔵 SubscriptionService: Response data: ${response.data}');

      if (response.data['success'] == true) {
        print('✅ SubscriptionService: Subscription successful!');
        return true;
      } else {
        final errorMessage = response.data['message'] ?? 'Unknown subscription error';
        print('❌ SubscriptionService: Subscription failed: $errorMessage');
        throw SubscriptionPurchaseException(
          message: errorMessage,
          errorCode: 'SUBSCRIPTION_FAILED',
        );
      }
    } catch (e) {
      print('❌ SubscriptionService: Error subscribing: $e');
      // Re-throw if it's already a SubscriptionException
      if (e is SubscriptionException) {
        rethrow;
      }
      // Convert DioException to SubscriptionException
      throw SubscriptionExceptionFactory.fromDioError(e, 'subscribe');
    }
  }

  /// Redeem sponsor code with real API
  Future<bool> redeemSponsorCode(String code, {
    String? farmerName,
    String? farmerPhone,
    String? notes,
  }) async {
    try {
      print('🔵 SubscriptionService: Redeeming sponsor code: $code');

      final token = await _storageService.getToken();
      if (token == null) {
        throw SponsorshipRedeemException(
          message: 'User not authenticated',
          errorCode: 'NO_AUTH_TOKEN',
        );
      }

      // API expects just the code field based on Postman collection
      final requestData = {
        'code': code,
      };

      final response = await _networkClient.post(
        ApiConfig.sponsorshipRedeem,
        data: requestData,
        options: Options(
          headers: ApiConfig.authHeader(token),
        ),
      );

      print('🔵 SubscriptionService: Sponsor redeem API response: ${response.statusCode}');
      print('🔵 SubscriptionService: Response data: ${response.data}');

      if (response.data['success'] == true) {
        print('✅ SubscriptionService: Successfully redeemed sponsor code: $code');
        return true;
      } else {
        throw SponsorshipRedeemException(
          message: response.data['message'] ?? 'Failed to redeem sponsor code',
          errorCode: response.data['errorCode'] ?? 'REDEEM_FAILED',
          details: response.data,
        );
      }
    } on DioException catch (e) {
      print('❌ SubscriptionService: Dio error redeeming sponsor code: $e');
      throw SubscriptionExceptionFactory.fromDioError(e, 'sponsorship_redeem');
    } catch (e) {
      print('❌ SubscriptionService: Error redeeming sponsor code: $e');
      if (e is SponsorshipRedeemException) {
        rethrow;
      }
      throw SponsorshipRedeemException(
        message: 'Failed to redeem sponsor code: ${e.toString()}',
        errorCode: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Validate sponsor code (check if it exists and is valid)
  Future<bool> validateSponsorCode(String code) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _networkClient.get(
        '${ApiConfig.sponsorshipValidate}/$code',
        options: Options(
          headers: ApiConfig.authHeader(token),
        ),
      );

      return response.data['success'] == true && response.data['data']['isValid'] == true;
    } catch (e) {
      print('Error validating sponsor code: $e');
      return false;
    }
  }

  /// Parse 403 error response to get quota details
  static QuotaExceededException? parse403Error(DioException dioError) {
    try {
      if (dioError.response?.statusCode != 403) return null;

      final data = dioError.response?.data;
      if (data == null) return null;

      // Try to extract quota information from API response
      String quotaType = 'daily'; // default
      int? usedCount;
      int? limitCount;
      String? resetTime;
      String? subscriptionTier;

      // Check if response contains quota details
      if (data is Map<String, dynamic>) {
        // Look for quota information in the response
        if (data['quota'] != null) {
          final quota = data['quota'];
          quotaType = quota['type'] ?? 'daily';
          usedCount = quota['used'];
          limitCount = quota['limit'];
          resetTime = quota['resetTime'];
          subscriptionTier = quota['tier'];
        } else if (data['message'] != null) {
          // Try to determine quota type from error message
          final message = data['message'].toString().toLowerCase();
          if (message.contains('daily')) {
            quotaType = 'daily';
          } else if (message.contains('monthly')) {
            quotaType = 'monthly';
          }
        }
      }

      return QuotaExceededException(
        'Analysis quota exceeded',
        quotaType: quotaType,
        usedCount: usedCount,
        limitCount: limitCount,
        resetTime: resetTime,
        subscriptionTier: subscriptionTier,
        errorCode: '403',
        originalError: dioError,
      );
    } catch (e) {
      // Fallback to basic quota exception
      return QuotaExceededException(
        'Analysis quota exceeded',
        quotaType: 'daily',
        errorCode: '403',
        originalError: dioError,
      );
    }
  }

  /// Get subscription usage from API and determine scenario for mock screen
  Future<String> getUsageScenario() async {
    final usageStatus = await getUsageStatus();

    if (usageStatus == null) {
      return 'no_subscription';
    }

    if (!usageStatus.hasActiveSubscription) {
      return 'no_subscription';
    }

    if (usageStatus.isDailyQuotaExceeded) {
      return 'daily_exceeded';
    }

    if (usageStatus.isMonthlyQuotaExceeded) {
      return 'monthly_exceeded';
    }

    return 'basic_active';
  }
}