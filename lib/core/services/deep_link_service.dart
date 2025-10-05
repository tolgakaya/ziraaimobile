import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

/// Service to handle deep links for referral system using app_links package
/// Handles links in format:
/// - https://ziraai.com/ref/ZIRA-XXXXXX (Production)
/// - https://ziraai-api-sit.up.railway.app/ref/ZIRA-XXXXXX (Staging)
/// - ziraai://ref/ZIRA-XXXXXX (Custom scheme fallback)
class DeepLinkService {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final StreamController<String> _referralCodeController =
      StreamController<String>.broadcast();

  /// Stream of referral codes extracted from deep links
  Stream<String> get referralCodeStream => _referralCodeController.stream;

  /// Initialize deep link handling
  /// This should be called once in main.dart after app startup
  Future<void> initialize() async {
    print('📱 DeepLink: Initializing app_links service...');

    try {
      _appLinks = AppLinks();

      // Handle initial deep link (when app was closed and opened via link)
      await _handleInitialLink();

      // Listen for deep links while app is running
      _listenForLinks();

      print('✅ DeepLink: Service initialized successfully');
    } catch (e) {
      print('❌ DeepLink: Initialization error: $e');
    }
  }

  /// Handle the initial deep link that opened the app
  Future<void> _handleInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        final link = uri.toString();
        print('📱 DeepLink: Initial link received: $link');
        _processDeepLink(link);
      } else {
        print('📱 DeepLink: No initial link found');
      }
    } catch (e) {
      print('❌ DeepLink: Error getting initial link: $e');
    }
  }

  /// Listen for incoming deep links while app is running
  void _listenForLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        final link = uri.toString();
        print('📱 DeepLink: Incoming link received: $link');
        _processDeepLink(link);
      },
      onError: (err) {
        print('❌ DeepLink: Error in link stream: $err');
      },
    );
  }

  /// Process deep link and extract referral code
  void _processDeepLink(String link) {
    final referralCode = extractReferralCode(link);

    if (referralCode != null) {
      print('✅ DeepLink: Extracted referral code: $referralCode');
      _referralCodeController.add(referralCode);
    } else {
      print('⚠️ DeepLink: No referral code found in link: $link');
    }
  }

  /// Extract referral code from deep link
  /// Formats supported (all environments):
  /// - https://ziraai.com/ref/ZIRA-XXXXXX (Production)
  /// - https://ziraai-api-sit.up.railway.app/ref/ZIRA-XXXXXX (Staging)
  /// - https://localhost:5001/ref/ZIRA-XXXXXX (Development)
  /// - ziraai://ref/ZIRA-XXXXXX (Custom scheme fallback)
  static String? extractReferralCode(String link) {
    try {
      final uri = Uri.parse(link);

      // Handle HTTPS links (All environments)
      if (uri.scheme == 'https' || uri.scheme == 'http') {
        // Accept any host that contains 'ziraai' or localhost for development
        final isValidHost = uri.host.contains('ziraai') ||
                           uri.host.contains('localhost') ||
                           uri.host.contains('127.0.0.1');

        if (isValidHost && uri.pathSegments.isNotEmpty) {
          // Check if path starts with 'ref'
          if (uri.pathSegments.first == 'ref' && uri.pathSegments.length >= 2) {
            final code = uri.pathSegments[1];
            print('✅ DeepLink: Extracted code from ${uri.scheme}://${uri.host}: $code');
            return code;
          }
        }
      }

      // Handle custom scheme (ziraai://ref/ZIRA-XXXXXX)
      if (uri.scheme == 'ziraai') {
        if (uri.pathSegments.isNotEmpty) {
          if (uri.pathSegments.first == 'ref' && uri.pathSegments.length >= 2) {
            final code = uri.pathSegments[1];
            print('✅ DeepLink: Extracted code from custom scheme: $code');
            return code;
          }
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

      // Check HTTPS/HTTP links (all environments)
      if (uri.scheme == 'https' || uri.scheme == 'http') {
        final isValidHost = uri.host.contains('ziraai') ||
                           uri.host.contains('localhost') ||
                           uri.host.contains('127.0.0.1');
        return isValidHost &&
            uri.pathSegments.isNotEmpty &&
            uri.pathSegments.first == 'ref';
      }

      // Check custom scheme
      if (uri.scheme == 'ziraai') {
        return uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'ref';
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Dispose the service
  void dispose() {
    _linkSubscription?.cancel();
    _referralCodeController.close();
    print('📱 DeepLink: Service disposed');
  }
}
