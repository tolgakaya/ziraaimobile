import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service to handle deep links for referral system
/// Handles links in format: https://ziraai.com/ref/ZIRA-XXXXXX
class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('app.channel.shared.data');

  StreamController<String>? _deepLinkController;
  Stream<String>? _deepLinkStream;

  /// Initialize deep link handling
  void initialize() {
    _deepLinkController = StreamController<String>.broadcast();
    _deepLinkStream = _deepLinkController!.stream;

    // Handle initial deep link (when app is opened via link)
    _handleInitialLink();

    // Handle deep links while app is running
    _handleIncomingLinks();
  }

  /// Get stream of deep links
  Stream<String>? get deepLinkStream => _deepLinkStream;

  /// Handle the initial deep link that opened the app
  Future<void> _handleInitialLink() async {
    try {
      final String? initialLink = await _channel.invokeMethod('getInitialLink');
      if (initialLink != null && initialLink.isNotEmpty) {
        print('📱 DeepLink: Initial link received: $initialLink');
        _deepLinkController?.add(initialLink);
      }
    } on PlatformException catch (e) {
      print('❌ DeepLink: Error getting initial link: ${e.message}');
    } on MissingPluginException catch (e) {
      print('⚠️ DeepLink: Native implementation not available yet: ${e.message}');
      // This is expected - native implementation will be added later
    } catch (e) {
      print('❌ DeepLink: Unexpected error: $e');
    }
  }

  /// Handle incoming deep links while app is running
  void _handleIncomingLinks() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'handleDeepLink') {
        final String link = call.arguments as String;
        print('📱 DeepLink: Incoming link received: $link');
        _deepLinkController?.add(link);
      }
    });
  }

  /// Extract referral code from deep link
  /// Format: https://ziraai.com/ref/ZIRA-XXXXXX or ziraai://ref/ZIRA-XXXXXX
  static String? extractReferralCode(String link) {
    try {
      final uri = Uri.parse(link);

      // Handle https://ziraai.com/ref/ZIRA-XXXXXX
      if (uri.scheme == 'https' && uri.host == 'ziraai.com') {
        final segments = uri.pathSegments;
        if (segments.length >= 2 && segments[0] == 'ref') {
          final code = segments[1];
          print('✅ DeepLink: Extracted referral code: $code');
          return code;
        }
      }

      // Handle ziraai://ref/ZIRA-XXXXXX
      if (uri.scheme == 'ziraai') {
        final segments = uri.pathSegments;
        if (segments.length >= 2 && segments[0] == 'ref') {
          final code = segments[1];
          print('✅ DeepLink: Extracted referral code: $code');
          return code;
        }
      }

      print('⚠️ DeepLink: No referral code found in link: $link');
      return null;
    } catch (e) {
      print('❌ DeepLink: Error extracting referral code: $e');
      return null;
    }
  }

  /// Check if a link is a referral deep link
  static bool isReferralLink(String link) {
    try {
      final uri = Uri.parse(link);

      if (uri.scheme == 'https' && uri.host == 'ziraai.com') {
        return uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'ref';
      }

      if (uri.scheme == 'ziraai') {
        return uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'ref';
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Dispose the service
  void dispose() {
    _deepLinkController?.close();
  }

  /// Handle deep link and navigate to appropriate screen
  static void handleDeepLink(BuildContext context, String link) {
    if (!isReferralLink(link)) {
      print('⚠️ DeepLink: Not a referral link, ignoring: $link');
      return;
    }

    final referralCode = extractReferralCode(link);
    if (referralCode == null) {
      print('❌ DeepLink: Failed to extract referral code from: $link');
      return;
    }

    // Show dialog or navigate to registration
    _showReferralDialog(context, referralCode);
  }

  static void _showReferralDialog(BuildContext context, String referralCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.green[600]),
            const SizedBox(width: 12),
            const Text('Davet Kodu'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Davet edildiniz! Kayıt olduğunuzda ücretsiz kredi kazanacaksınız.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                referralCode,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to phone registration with referral code
              // This will be implemented when integrating with app router
              _navigateToRegistration(context, referralCode);
            },
            child: const Text('Kayıt Ol'),
          ),
        ],
      ),
    );
  }

  static void _navigateToRegistration(BuildContext context, String referralCode) {
    // Import the phone number screen
    // This is a placeholder - actual implementation will use app router
    print('📱 DeepLink: Navigating to registration with code: $referralCode');

    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Davet kodu: $referralCode ile kayıt ekranına yönlendiriliyorsunuz'),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
