import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Payment WebView Screen for iyzico payment pages
///
/// Features:
/// - Loads iyzico payment page URL
/// - Detects deep link callbacks (ziraai://payment-callback)
/// - Shows loading states during page load
/// - Allows user to cancel payment
/// - Returns payment result to caller
class PaymentWebViewScreen extends StatefulWidget {
  final String paymentPageUrl;
  final String paymentToken;
  final String callbackUrl;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentPageUrl,
    required this.paymentToken,
    required this.callbackUrl,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Detect deep link callback
            if (request.url.startsWith('ziraai://payment-callback')) {
              _handlePaymentCallback(request.url);
              return NavigationDecision.prevent;
            }

            // Detect HTTP callback URL
            if (request.url.contains(widget.callbackUrl)) {
              _handlePaymentCallback(request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            _showErrorDialog(
              'Sayfa Yüklenemedi',
              'Ödeme sayfası yüklenirken bir hata oluştu. Lütfen tekrar deneyin.',
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentPageUrl));
  }

  void _handlePaymentCallback(String url) {
    // Parse callback URL to get payment token
    final uri = Uri.parse(url);
    final token = uri.queryParameters['token'] ?? widget.paymentToken;

    // Return success result with payment token
    Navigator.of(context).pop({
      'success': true,
      'paymentToken': token,
    });
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ödemeyi İptal Et'),
          content: const Text(
            'Ödeme işlemini iptal etmek istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Hayır'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop({
                  'success': false,
                  'cancelled': true,
                }); // Close WebView
              },
              child: const Text(
                'Evet, İptal Et',
                style: TextStyle(color: Colors.red),
              ),
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
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop({
                  'success': false,
                  'error': message,
                }); // Close WebView
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          _showCancelDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ödeme'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showCancelDialog,
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _loadingProgress > 0 ? _loadingProgress : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ödeme sayfası yükleniyor...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_loadingProgress > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${(_loadingProgress * 100).toInt()}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
