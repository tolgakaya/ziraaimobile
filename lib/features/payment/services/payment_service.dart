import 'dart:convert';
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
      return await _secureStorage.read(key: 'access_token');
    } catch (e) {
      throw PaymentException('Failed to get access token: $e');
    }
  }

  /// Get common headers with authorization
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAccessToken();

    if (token == null) {
      throw PaymentException('User not authenticated');
    }

    return {
      'Content-Type': 'application/json',
      'x-dev-arch-version': '1.0',
      'Authorization': 'Bearer $token',
    };
  }

  /// Initialize payment for sponsor bulk purchase
  ///
  /// [subscriptionTierId] - Tier ID (1-4)
  /// [quantity] - Number of codes to purchase (10-10000)
  /// [currency] - Currency code (default: TRY)
  Future<PaymentInitializeResponse> initializeSponsorPayment({
    required int subscriptionTierId,
    required int quantity,
    String currency = 'TRY',
  }) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/api/v1/payments/initialize';

      final body = {
        'flowType': 'SponsorBulkPurchase',
        'flowData': {
          'subscriptionTierId': subscriptionTierId,
          'quantity': quantity,
        },
        'currency': currency,
      };

      final response = await _dio.post(
        url,
        data: jsonEncode(body),
        options: Options(headers: headers),
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
      final headers = await _getHeaders();
      final url = '$baseUrl/api/v1/payments/initialize';

      final body = {
        'flowType': 'FarmerSubscription',
        'flowData': {
          'subscriptionTierId': subscriptionTierId,
          'durationMonths': durationMonths,
        },
        'currency': currency,
      };

      final response = await _dio.post(
        url,
        data: jsonEncode(body),
        options: Options(headers: headers),
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
      final headers = await _getHeaders();
      final url = '$baseUrl/api/v1/payments/verify';

      final body = {
        'paymentToken': paymentToken,
      };

      final response = await _dio.post(
        url,
        data: jsonEncode(body),
        options: Options(headers: headers),
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
      final headers = await _getHeaders();
      final url = '$baseUrl/api/v1/payments/status/$paymentToken';

      final response = await _dio.get(
        url,
        options: Options(headers: headers),
      );

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
