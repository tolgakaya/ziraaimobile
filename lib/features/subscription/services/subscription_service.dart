import 'package:dio/dio.dart';
import '../../../core/network/network_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/error/plant_analysis_exceptions.dart';
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

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return UsageStatus.fromJson(data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get usage status');
      }
    } catch (e) {
      print('Error getting usage status: $e');
      return null;
    }
  }

  /// Get current user's subscription info (now points to correct endpoint)
  Future<UserSubscription?> getMySubscription() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _networkClient.get(
        ApiConfig.mySubscription, // This should be '/subscriptions/my-subscription'
        options: Options(
          headers: ApiConfig.authHeader(token),
        ),
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        return UserSubscription.fromJson(data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get subscription');
      }
    } catch (e) {
      print('Error getting subscription: $e');
      return null;
    }
  }

  /// Get available subscription tiers
  Future<List<SubscriptionTier>> getSubscriptionTiers() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await _networkClient.get(
        ApiConfig.subscriptionTiers,
        options: Options(
          headers: ApiConfig.authHeader(token),
        ),
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        return data.map((tier) => SubscriptionTier.fromJson(tier)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get tiers');
      }
    } catch (e) {
      print('Error getting subscription tiers: $e');
      return [];
    }
  }

  /// Subscribe to a tier
  Future<bool> subscribeTo(int tierId, {
    int durationMonths = 1,
    bool autoRenew = true,
    String paymentMethod = 'CreditCard',
    String? paymentReference,
    double? paidAmount,
    String currency = 'TRY',
  }) async {
    try {
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

      final response = await _networkClient.post(
        ApiConfig.subscribe,
        data: requestData,
        options: Options(
          headers: ApiConfig.authHeader(token),
        ),
      );

      return response.data['success'] == true;
    } catch (e) {
      print('Error subscribing: $e');
      return false;
    }
  }

  /// Redeem sponsor code
  Future<bool> redeemSponsorCode(String code, {
    String? farmerName,
    String? farmerPhone,
    String? notes,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final requestData = {
        'sponsorshipCode': code,
        'farmerName': farmerName,
        'farmerPhone': farmerPhone,
        'notes': notes,
      };

      final response = await _networkClient.post(
        ApiConfig.sponsorshipRedeem,
        data: requestData,
        options: Options(
          headers: ApiConfig.authHeader(token),
        ),
      );

      return response.data['success'] == true;
    } catch (e) {
      print('Error redeeming sponsor code: $e');
      return false;
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