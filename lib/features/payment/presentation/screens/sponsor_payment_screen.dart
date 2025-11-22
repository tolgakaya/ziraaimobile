import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../services/payment_service.dart';
import '../../data/models/payment_models.dart';
import 'payment_webview_screen.dart';

/// Sponsor Payment Screen for bulk subscription code purchases
///
/// Flow:
/// 1. Initialize payment with tier, quantity, and invoice data
/// 2. Open WebView with payment URL
/// 3. Handle payment callback
/// 4. Verify payment
/// 5. Show success/failure result
class SponsorPaymentScreen extends StatefulWidget {
  final int subscriptionTierId;
  final int quantity;
  final String currency;
  final String? companyName;
  final String? taxNumber;
  final String? invoiceAddress;

  const SponsorPaymentScreen({
    super.key,
    required this.subscriptionTierId,
    required this.quantity,
    this.currency = 'TRY',
    this.companyName,
    this.taxNumber,
    this.invoiceAddress,
  });

  @override
  State<SponsorPaymentScreen> createState() => _SponsorPaymentScreenState();
}

class _SponsorPaymentScreenState extends State<SponsorPaymentScreen> {
  final PaymentService _paymentService = GetIt.instance<PaymentService>();
  bool _isInitializing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-start payment initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePayment();
    });
  }

  Future<void> _initializePayment() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      // Initialize payment with sponsor bulk purchase flow
      print('💳 Payment: Initializing with invoice data...');
      print('💳 Payment: Company: ${widget.companyName}');
      print('💳 Payment: Tax Number: ${widget.taxNumber}');
      print('💳 Payment: Address: ${widget.invoiceAddress}');

      final response = await _paymentService.initializeSponsorPayment(
        subscriptionTierId: widget.subscriptionTierId,
        quantity: widget.quantity,
        currency: widget.currency,
        companyName: widget.companyName,
        taxNumber: widget.taxNumber,
        invoiceAddress: widget.invoiceAddress,
      );

      if (!mounted) return;

      // Open WebView with payment URL
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(
            paymentPageUrl: response.paymentPageUrl,
            paymentToken: response.paymentToken,
            callbackUrl: response.callbackUrl,
          ),
        ),
      );

      if (!mounted) return;

      // Handle WebView result
      if (result != null) {
        if (result['success'] == true) {
          final paymentToken = result['paymentToken'] as String;
          await _verifyPayment(paymentToken);
        } else if (result['cancelled'] == true) {
          _showCancelledDialog();
        } else if (result['error'] != null) {
          _showErrorDialog('Ödeme Hatası', result['error'] as String);
        }
      } else {
        // User dismissed WebView without completing payment
        _showCancelledDialog();
      }
    } on PaymentException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isInitializing = false;
        });
        _showErrorDialog('Ödeme Başlatılamadı', e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Beklenmeyen bir hata oluştu: $e';
          _isInitializing = false;
        });
        _showErrorDialog('Hata', 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.');
      }
    }
  }

  Future<void> _verifyPayment(String paymentToken) async {
    // Show verification loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Ödeme doğrulanıyor...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Verify payment
      final verifyResponse = await _paymentService.verifyPayment(paymentToken);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (verifyResponse.isSuccess) {
        // Payment successful
        final sponsorResult = verifyResponse.sponsorResult;
        _showSuccessDialog(sponsorResult);
      } else if (verifyResponse.isFailed) {
        // Payment failed
        _showErrorDialog(
          'Ödeme Başarısız',
          verifyResponse.errorMessage ?? 'Ödeme işlemi başarısız oldu.',
        );
      } else {
        // Payment still pending or other status
        _showErrorDialog(
          'Ödeme Durumu',
          'Ödeme durumu: ${verifyResponse.status}. Lütfen daha sonra kontrol edin.',
        );
      }
    } on PaymentException catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog('Doğrulama Hatası', e.message);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog('Hata', 'Ödeme doğrulanırken bir hata oluştu.');
      }
    }
  }

  void _showSuccessDialog(SponsorBulkPurchaseResult? result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Ödeme Başarılı'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ödemeniz başarıyla tamamlandı!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (result != null) ...[
                Text('Abonelik Paketi: ${result.subscriptionTierName}'),
                const SizedBox(height: 8),
                Text('Oluşturulan Kod Sayısı: ${result.codesGenerated}'),
                const SizedBox(height: 8),
                Text('Satın Alma ID: ${result.purchaseId}'),
              ],
              const SizedBox(height: 16),
              const Text(
                'Kodlarınız hesabınıza tanımlandı. Sponsorluk sayfasından erişebilirsiniz.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(true); // Close screen with success
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  void _showCancelledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ödeme İptal Edildi'),
          content: const Text('Ödeme işlemi iptal edildi. Tekrar denemek ister misiniz?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(false); // Close screen
              },
              child: const Text('Hayır'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _initializePayment(); // Retry payment
              },
              child: const Text('Evet, Tekrar Dene'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 32),
              const SizedBox(width: 12),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(false); // Close screen
              },
              child: const Text('Kapat'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _initializePayment(); // Retry payment
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sponsor Ödeme'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (_isInitializing) {
              // Show confirmation before closing during initialization
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Ödemeyi İptal Et'),
                  content: const Text('Ödeme işlemi devam ediyor. Çıkmak istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hayır'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(false); // Close screen
                      },
                      child: const Text('Evet, Çık'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.of(context).pop(false);
            }
          },
        ),
      ),
      body: Center(
        child: _isInitializing
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text(
                    'Ödeme hazırlanıyor...',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lütfen bekleyin',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              )
            : _errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Ödeme Başlatılamadı',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _initializePayment,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
