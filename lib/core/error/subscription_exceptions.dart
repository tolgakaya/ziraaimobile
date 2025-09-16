/// Subscription-specific exceptions for error handling
/// These exceptions are thrown when subscription operations fail

/// Base subscription exception
abstract class SubscriptionException implements Exception {
  final String message;
  final String? errorCode;
  final Map<String, dynamic>? details;

  const SubscriptionException({
    required this.message,
    this.errorCode,
    this.details,
  });

  @override
  String toString() => 'SubscriptionException: $message';
}

/// Thrown when subscription tier operations fail
class SubscriptionTierException extends SubscriptionException {
  const SubscriptionTierException({
    required super.message,
    super.errorCode,
    super.details,
  });

  @override
  String toString() => 'SubscriptionTierException: $message';
}

/// Thrown when subscription purchase operations fail
class SubscriptionPurchaseException extends SubscriptionException {
  const SubscriptionPurchaseException({
    required super.message,
    super.errorCode,
    super.details,
  });

  @override
  String toString() => 'SubscriptionPurchaseException: $message';
}

/// Thrown when sponsorship redeem operations fail
class SponsorshipRedeemException extends SubscriptionException {
  const SponsorshipRedeemException({
    required super.message,
    super.errorCode,
    super.details,
  });

  @override
  String toString() => 'SponsorshipRedeemException: $message';
}

/// Thrown when user subscription info operations fail
class UserSubscriptionException extends SubscriptionException {
  const UserSubscriptionException({
    required super.message,
    super.errorCode,
    super.details,
  });

  @override
  String toString() => 'UserSubscriptionException: $message';
}

/// Thrown when subscription validation fails
class SubscriptionValidationException extends SubscriptionException {
  const SubscriptionValidationException({
    required super.message,
    super.errorCode,
    super.details,
  });

  @override
  String toString() => 'SubscriptionValidationException: $message';
}

/// Thrown when subscription limits are exceeded
class SubscriptionLimitException extends SubscriptionException {
  const SubscriptionLimitException({
    required super.message,
    super.errorCode,
    super.details,
  });

  @override
  String toString() => 'SubscriptionLimitException: $message';
}

/// Factory class to create subscription exceptions from API responses
class SubscriptionExceptionFactory {
  static SubscriptionException fromApiResponse(
    Map<String, dynamic> response,
    String operation,
  ) {
    final message = response['message'] ?? 'Unknown subscription error';
    final errorCode = response['errorCode'] ?? response['error'];
    final details = response['details'] ?? response;

    // Determine exception type based on operation and error code
    switch (operation.toLowerCase()) {
      case 'tiers':
      case 'get_tiers':
        return SubscriptionTierException(
          message: message,
          errorCode: errorCode,
          details: details,
        );

      case 'purchase':
      case 'subscribe':
        return SubscriptionPurchaseException(
          message: message,
          errorCode: errorCode,
          details: details,
        );

      case 'redeem':
      case 'sponsorship_redeem':
        return SponsorshipRedeemException(
          message: message,
          errorCode: errorCode,
          details: details,
        );

      case 'my_subscription':
      case 'user_subscription':
        return UserSubscriptionException(
          message: message,
          errorCode: errorCode,
          details: details,
        );

      default:
        return SubscriptionValidationException(
          message: message,
          errorCode: errorCode,
          details: details,
        );
    }
  }

  static SubscriptionException fromDioError(
    dynamic error,
    String operation,
  ) {
    String message = 'Network error occurred';
    String? errorCode;
    Map<String, dynamic>? details;

    if (error.response?.data != null) {
      final responseData = error.response!.data;
      if (responseData is Map<String, dynamic>) {
        message = responseData['message'] ?? message;
        errorCode = responseData['errorCode'];
        details = responseData;
      }
    } else {
      message = error.message ?? message;
    }

    return fromApiResponse({
      'message': message,
      'errorCode': errorCode,
      'details': details,
    }, operation);
  }
}