import 'dart:async';

/// Mock payment service for testing payment flow
class MockPaymentService {
  /// Process payment with mock delay
  static Future<PaymentResult> processPayment({
    required String cardNumber,
    required String cardHolder,
    required String expiryDate,
    required String cvv,
    required double amount,
    required String currency,
    required int tierId,
  }) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock validation
    if (cardNumber.replaceAll(' ', '').length != 16) {
      return PaymentResult(
        success: false,
        message: 'Geçersiz kart numarası',
        errorCode: 'INVALID_CARD',
      );
    }
    
    // Mock 3D Secure simulation
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock success (90% success rate)
    final isSuccess = DateTime.now().millisecondsSinceEpoch % 10 != 0;
    
    if (isSuccess) {
      return PaymentResult(
        success: true,
        message: 'Ödeme başarıyla tamamlandı',
        transactionId: 'TRX${DateTime.now().millisecondsSinceEpoch}',
        invoiceUrl: 'https://mock-invoice.pdf',
      );
    } else {
      return PaymentResult(
        success: false,
        message: 'Ödeme işlemi başarısız. Lütfen tekrar deneyin.',
        errorCode: 'PAYMENT_FAILED',
      );
    }
  }
  
  /// Validate card number (Luhn algorithm)
  static bool validateCardNumber(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 13 || cleaned.length > 19) return false;
    
    // Simple Luhn check
    int sum = 0;
    bool alternate = false;
    for (int i = cleaned.length - 1; i >= 0; i--) {
      int n = int.parse(cleaned[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }
  
  /// Get card type from number
  static CardType getCardType(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleaned.startsWith('4')) return CardType.visa;
    if (cleaned.startsWith('5')) return CardType.mastercard;
    if (cleaned.startsWith('3')) return CardType.amex;
    if (cleaned.startsWith('6')) return CardType.discover;
    
    return CardType.unknown;
  }
  
  /// Generate mock invoice
  static Future<String> generateInvoice({
    required String transactionId,
    required double amount,
    required String customerName,
    required int tierId,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'https://mock-invoice-$transactionId.pdf';
  }
}

/// Payment result model
class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;
  final String? errorCode;
  final String? invoiceUrl;
  
  PaymentResult({
    required this.success,
    required this.message,
    this.transactionId,
    this.errorCode,
    this.invoiceUrl,
  });
}

/// Card types enum
enum CardType {
  visa,
  mastercard,
  amex,
  discover,
  unknown,
}

extension CardTypeExtension on CardType {
  String get displayName {
    switch (this) {
      case CardType.visa:
        return 'Visa';
      case CardType.mastercard:
        return 'Mastercard';
      case CardType.amex:
        return 'American Express';
      case CardType.discover:
        return 'Discover';
      case CardType.unknown:
        return 'Kart';
    }
  }
  
  String get iconPath {
    switch (this) {
      case CardType.visa:
        return 'assets/icons/visa.png';
      case CardType.mastercard:
        return 'assets/icons/mastercard.png';
      case CardType.amex:
        return 'assets/icons/amex.png';
      case CardType.discover:
        return 'assets/icons/discover.png';
      case CardType.unknown:
        return 'assets/icons/credit_card.png';
    }
  }
}