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
            print('💳 WebView: Page started - $url');
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
            print('💳 WebView: Page finished - $url');
            setState(() {
              _isLoading = false;
            });

            // Check for iyzico error page
            _checkForIyzicoError();
          },
          onNavigationRequest: (NavigationRequest request) {
            print('💳 WebView: Navigation request - ${request.url}');

            // Detect deep link callback (SUCCESS case)
            if (request.url.startsWith('ziraai://payment-callback')) {
              print('💳 WebView: Deep link callback detected');
              _handlePaymentCallback(request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView: Resource error - ${error.description}');
            _showErrorDialog(
              'Sayfa Yüklenemedi',
              'Ödeme sayfası yüklenirken bir hata oluştu. Lütfen tekrar deneyin.',
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentPageUrl));
  }

  /// Check if current page shows iyzico error
  Future<void> _checkForIyzicoError() async {
    try {
      // Inject JavaScript to read page content
      final pageContent = await _controller.runJavaScriptReturningResult(
        'document.body.innerText',
      ) as String;

      print('💳 WebView: Page content check - ${pageContent.substring(0, pageContent.length > 100 ? 100 : pageContent.length)}');

      // Check for error indicators in page content
      if (pageContent.contains('"status":"failure"') ||
          pageContent.contains('errorCode') ||
          pageContent.contains('Gecersiz') ||
          pageContent.contains('başarısız')) {

        print('❌ WebView: Error detected in page content');

        // Try to extract error details
        String errorMessage = 'Ödeme işlemi başarısız oldu';

        if (pageContent.contains('errorMessage')) {
          // Parse JSON error
          try {
            final errorStart = pageContent.indexOf('"errorMessage"');
            if (errorStart != -1) {
              final errorEnd = pageContent.indexOf('"', errorStart + 17);
              if (errorEnd != -1) {
                errorMessage = pageContent.substring(errorStart + 17, errorEnd);
              }
            }
          } catch (e) {
            print('❌ WebView: Failed to parse error message - $e');
          }
        }

        // Close WebView with error result
        if (mounted) {
          Navigator.of(context).pop({
            'success': false,
            'error': errorMessage,
          });
        }
      }
    } catch (e) {
      print('❌ WebView: Failed to check page content - $e');
      // Don't show error, just log it - page might be loading normally
    }
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
