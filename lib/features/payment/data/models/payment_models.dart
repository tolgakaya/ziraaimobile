// Payment Models for iyzico Integration
// ZiraAI Mobile - Real Payment API Integration

/// Exception thrown when payment operations fail
class PaymentException implements Exception {
  final String message;

  PaymentException(this.message);

  @override
  String toString() => message;
}

/// Response from payment initialization endpoint
class PaymentInitializeResponse {
  final int transactionId;
  final String paymentToken;
  final String paymentPageUrl;
  final String callbackUrl;
  final double amount;
  final String currency;
  final String expiresAt;
  final String status;
  final String conversationId;

  PaymentInitializeResponse({
    required this.transactionId,
    required this.paymentToken,
    required this.paymentPageUrl,
    required this.callbackUrl,
    required this.amount,
    required this.currency,
    required this.expiresAt,
    required this.status,
    required this.conversationId,
  });

  factory PaymentInitializeResponse.fromJson(Map<String, dynamic> json) {
    return PaymentInitializeResponse(
      transactionId: json['transactionId'] as int,
      paymentToken: json['paymentToken'] as String,
      paymentPageUrl: json['paymentPageUrl'] as String,
      callbackUrl: json['callbackUrl'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      expiresAt: json['expiresAt'] as String,
      status: json['status'] as String,
      conversationId: json['conversationId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'paymentToken': paymentToken,
      'paymentPageUrl': paymentPageUrl,
      'callbackUrl': callbackUrl,
      'amount': amount,
      'currency': currency,
      'expiresAt': expiresAt,
      'status': status,
      'conversationId': conversationId,
    };
  }
}

/// Response from payment verification endpoint
class PaymentVerifyResponse {
  final int transactionId;
  final String status;
  final String paymentId;
  final String paymentToken;
  final double amount;
  final String currency;
  final double paidAmount;
  final String completedAt;
  final String? errorMessage;
  final String flowType;
  final dynamic flowResult;

  PaymentVerifyResponse({
    required this.transactionId,
    required this.status,
    required this.paymentId,
    required this.paymentToken,
    required this.amount,
    required this.currency,
    required this.paidAmount,
    required this.completedAt,
    this.errorMessage,
    required this.flowType,
    this.flowResult,
  });

  factory PaymentVerifyResponse.fromJson(Map<String, dynamic> json) {
    return PaymentVerifyResponse(
      transactionId: json['transactionId'] as int,
      status: json['status'] as String,
      paymentId: json['paymentId'] as String,
      paymentToken: json['paymentToken'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      paidAmount: (json['paidAmount'] as num).toDouble(),
      completedAt: json['completedAt'] as String,
      errorMessage: json['errorMessage'] as String?,
      flowType: json['flowType'] as String,
      flowResult: json['flowResult'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'status': status,
      'paymentId': paymentId,
      'paymentToken': paymentToken,
      'amount': amount,
      'currency': currency,
      'paidAmount': paidAmount,
      'completedAt': completedAt,
      'errorMessage': errorMessage,
      'flowType': flowType,
      'flowResult': flowResult,
    };
  }

  // Helper methods
  bool get isSuccess => status == 'Success';
  bool get isFailed => status == 'Failed';
  bool get isPending => status == 'Pending';
  bool get isCancelled => status == 'Cancelled';
  bool get isExpired => status == 'Expired';

  SponsorBulkPurchaseResult? get sponsorResult {
    if (flowType == 'SponsorBulkPurchase' && flowResult != null) {
      return SponsorBulkPurchaseResult.fromJson(
        flowResult as Map<String, dynamic>,
      );
    }
    return null;
  }

  FarmerSubscriptionResult? get farmerResult {
    if (flowType == 'FarmerSubscription' && flowResult != null) {
      return FarmerSubscriptionResult.fromJson(
        flowResult as Map<String, dynamic>,
      );
    }
    return null;
  }
}

/// Result data for sponsor bulk purchase flow
class SponsorBulkPurchaseResult {
  final int purchaseId;
  final int codesGenerated;
  final String subscriptionTierName;

  SponsorBulkPurchaseResult({
    required this.purchaseId,
    required this.codesGenerated,
    required this.subscriptionTierName,
  });

  factory SponsorBulkPurchaseResult.fromJson(Map<String, dynamic> json) {
    return SponsorBulkPurchaseResult(
      purchaseId: json['purchaseId'] as int,
      codesGenerated: json['codesGenerated'] as int,
      subscriptionTierName: json['subscriptionTierName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchaseId': purchaseId,
      'codesGenerated': codesGenerated,
      'subscriptionTierName': subscriptionTierName,
    };
  }
}

/// Result data for farmer subscription flow
class FarmerSubscriptionResult {
  final int subscriptionId;
  final String startDate;
  final String endDate;
  final String subscriptionTierName;

  FarmerSubscriptionResult({
    required this.subscriptionId,
    required this.startDate,
    required this.endDate,
    required this.subscriptionTierName,
  });

  factory FarmerSubscriptionResult.fromJson(Map<String, dynamic> json) {
    return FarmerSubscriptionResult(
      subscriptionId: json['subscriptionId'] as int,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      subscriptionTierName: json['subscriptionTierName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'startDate': startDate,
      'endDate': endDate,
      'subscriptionTierName': subscriptionTierName,
    };
  }
}
