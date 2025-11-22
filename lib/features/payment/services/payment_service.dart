import 'package:dio/dio.dart';
import '../data/models/payment_models.dart';
import '../../../core/storage/secure_storage_service.dart';

/// Payment service for iyzico integration
/// Handles payment initialization, verification, and status queries
class PaymentService {
  final Dio _dio;
  final SecureStorageService _secureStorage;
  final String baseUrl;

  PaymentService({
    required Dio dio,
    required SecureStorageService secureStorage,
    required this.baseUrl,
  })  : _dio = dio,
        _secureStorage = secureStorage;

  /// Get stored access token
  Future<String?> _getAccessToken() async {
    try {
      // Use 'auth_token' key - same as TokenManager
      final token = await _secureStorage.read(key: 'auth_token');
      print('💳 Payment: Token check - ${token != null ? "Token exists" : "No token found"}');
      if (token != null) {
        print('💳 Payment: Token length: ${token.length}');
      }
      return token;
    } catch (e) {
      print('❌ Payment: Failed to read token from secure storage: $e');
      throw PaymentException('Failed to get access token: $e');
    }
  }

  /// Verify user is authenticated before making payment requests
  Future<void> _verifyAuthenticated() async {
    print('💳 Payment: Verifying authentication...');
    final token = await _getAccessToken();
    if (token == null || token.isEmpty) {
      print('❌ Payment: No valid token found - user not authenticated');
      throw PaymentException('User not authenticated');
    }
    print('✅ Payment: Authentication verified, token exists');
  }

  /// Initialize payment for sponsor bulk purchase
  ///
  /// [subscriptionTierId] - Tier ID (1-4)
  /// [quantity] - Number of codes to purchase (10-10000)
  /// [companyName] - Company name for invoice (optional)
  /// [taxNumber] - Tax number for invoice (optional)
  /// [invoiceAddress] - Invoice address (optional)
  /// [currency] - Currency code (default: TRY)
  Future<PaymentInitializeResponse> initializeSponsorPayment({
    required int subscriptionTierId,
    required int quantity,
    String? companyName,
    String? taxNumber,
    String? invoiceAddress,
    String currency = 'TRY',
  }) async {
    try {
      await _verifyAuthenticated();
      final url = '$baseUrl/payments/initialize';

      final Map<String, dynamic> flowData = {
        'subscriptionTierId': subscriptionTierId,
        'quantity': quantity,
      };

      // Add invoice fields if provided
      if (companyName != null && companyName.trim().isNotEmpty) {
        flowData['companyName'] = companyName.trim();
      }
      if (taxNumber != null && taxNumber.trim().isNotEmpty) {
        flowData['taxNumber'] = taxNumber.trim();
      }
      if (invoiceAddress != null && invoiceAddress.trim().isNotEmpty) {
        flowData['invoiceAddress'] = invoiceAddress.trim();
      }

      final body = {
        'flowType': 'SponsorBulkPurchase',
        'flowData': flowData,
        'currency': currency,
      };

      print('💳 Payment: Initializing sponsor payment...');
      print('💳 Payment: URL: $url');
      print('💳 Payment: Body: $body');
      print('💳 Payment: Invoice fields: ${flowData.containsKey("companyName") ? "✅ Included" : "❌ Not included"}');

      final response = await _dio.post(
        url,
        data: body,  // Don't use jsonEncode, let Dio handle it
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return PaymentInitializeResponse.fromJson(data['data']);
        } else {
          throw PaymentException(data['message'] ?? 'Payment initialization failed');
        }
      } else {
        final error = response.data;
        throw PaymentException(error['message'] ?? 'Payment initialization failed');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw PaymentException('User not authenticated');
      } else if (e.response?.statusCode == 403) {
        throw PaymentException('You are not authorized to access this resource');
      } else if (e.response != null) {
        final error = e.response!.data;
        throw PaymentException(error['message'] ?? 'Payment initialization failed');
      } else {
        throw PaymentException('Network error: ${e.message}');
      }
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException('Unexpected error: $e');
    }
  }

  /// Initialize payment for farmer subscription
  ///
  /// [subscriptionTierId] - Tier ID (1-4)
  /// [durationMonths] - Subscription duration in months (1-12)
  /// [currency] - Currency code (default: TRY)
  Future<PaymentInitializeResponse> initializeFarmerPayment({
    required int subscriptionTierId,
    int durationMonths = 1,
    String currency = 'TRY',
  }) async {
    try {
      await _verifyAuthenticated();
      final url = '$baseUrl/payments/initialize';

      final body = {
        'flowType': 'FarmerSubscription',
        'flowData': {
          'subscriptionTierId': subscriptionTierId,
          'durationMonths': durationMonths,
        },
        'currency': currency,
      };

      print('💳 Payment: Initializing farmer payment...');
      print('💳 Payment: URL: $url');
      print('💳 Payment: Body: $body');

      final response = await _dio.post(
        url,
        data: body,  // Don't use jsonEncode, let Dio handle it
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return PaymentInitializeResponse.fromJson(data['data']);
        } else {
          throw PaymentException(data['message'] ?? 'Payment initialization failed');
        }
      } else {
        final error = response.data;
        throw PaymentException(error['message'] ?? 'Payment initialization failed');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw PaymentException('User not authenticated');
      } else if (e.response?.statusCode == 403) {
        throw PaymentException('You are not authorized to access this resource');
      } else if (e.response != null) {
        final error = e.response!.data;
        throw PaymentException(error['message'] ?? 'Payment initialization failed');
      } else {
        throw PaymentException('Network error: ${e.message}');
      }
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException('Unexpected error: $e');
    }
  }

  /// Verify payment after completion
  ///
  /// [paymentToken] - Payment token from initialize response or deep link
  Future<PaymentVerifyResponse> verifyPayment(String paymentToken) async {
    try {
      await _verifyAuthenticated();
      final url = '$baseUrl/payments/verify';

      final body = {
        'paymentToken': paymentToken,
      };

      print('💳 Payment: Verifying payment...');
      print('💳 Payment: Token: $paymentToken');

      final response = await _dio.post(
        url,
        data: body,  // Don't use jsonEncode, let Dio handle it
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return PaymentVerifyResponse.fromJson(data['data']);
        } else {
          throw PaymentException(data['message'] ?? 'Payment verification failed');
        }
      } else {
        final error = response.data;
        throw PaymentException(error['message'] ?? 'Payment verification failed');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final error = e.response!.data;
        throw PaymentException(error['message'] ?? 'Payment failed');
      } else if (e.response?.statusCode == 401) {
        throw PaymentException('User not authenticated');
      } else if (e.response?.statusCode == 404) {
        throw PaymentException('Payment transaction not found');
      } else if (e.response != null) {
        final error = e.response!.data;
        throw PaymentException(error['message'] ?? 'Payment verification failed');
      } else {
        throw PaymentException('Network error: ${e.message}');
      }
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException('Unexpected error: $e');
    }
  }

  /// Get payment status by token
  ///
  /// [paymentToken] - Payment token to query
  Future<PaymentVerifyResponse> getPaymentStatus(String paymentToken) async {
    try {
      await _verifyAuthenticated();
      final url = '$baseUrl/payments/status/$paymentToken';

      print('💳 Payment: Getting payment status...');
      print('💳 Payment: Token: $paymentToken');

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return PaymentVerifyResponse.fromJson(data['data']);
        } else {
          throw PaymentException(data['message'] ?? 'Failed to get payment status');
        }
      } else {
        final error = response.data;
        throw PaymentException(error['message'] ?? 'Failed to get payment status');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw PaymentException('User not authenticated');
      } else if (e.response?.statusCode == 404) {
        throw PaymentException('Payment transaction not found');
      } else if (e.response != null) {
        final error = e.response!.data;
        throw PaymentException(error['message'] ?? 'Failed to get payment status');
      } else {
        throw PaymentException('Network error: ${e.message}');
      }
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException('Unexpected error: $e');
    }
  }
}
