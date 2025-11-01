import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

/// Service to handle deep links for referral, sponsorship, and dealer invitation systems using app_links package
/// Handles links in format:
/// Referral:
/// - https://ziraai.com/ref/ZIRA-XXXXXX (Production)
/// - https://ziraai-api-sit.up.railway.app/ref/ZIRA-XXXXXX (Staging)
/// - ziraai://ref/ZIRA-XXXXXX (Custom scheme fallback)
/// Sponsorship:
/// - https://ziraai.com/redeem/AGRI-XXXXXX (Production)
/// - https://ziraai-api-sit.up.railway.app/redeem/AGRI-XXXXXX (Staging)
/// - ziraai://redeem/AGRI-XXXXXX (Custom scheme fallback)
/// Dealer Invitation:
/// - https://ziraai.com/dealer-invitation/DEALER-abc123... (Production)
/// - https://ziraai-api-sit.up.railway.app/dealer-invitation/DEALER-abc123... (Staging)
/// - ziraai://dealer-invitation/DEALER-abc123... (Custom scheme fallback)
class DeepLinkService {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final StreamController<String> _referralCodeController =
      StreamController<String>.broadcast();
  final StreamController<String> _sponsorshipCodeController =
      StreamController<String>.broadcast();
  final StreamController<String> _dealerInvitationTokenController =
      StreamController<String>.broadcast();

  /// Stream of referral codes extracted from deep links
  Stream<String> get referralCodeStream => _referralCodeController.stream;

  /// Stream of sponsorship codes extracted from deep links
  Stream<String> get sponsorshipCodeStream => _sponsorshipCodeController.stream;

  /// Stream of dealer invitation tokens extracted from deep links
  Stream<String> get dealerInvitationTokenStream => _dealerInvitationTokenController.stream;

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

  /// Process deep link and extract referral, sponsorship code, or dealer invitation token
  void _processDeepLink(String link) {
    // Check for referral code
    final referralCode = extractReferralCode(link);
    if (referralCode != null) {
      print('✅ DeepLink: Extracted referral code: $referralCode');
      _referralCodeController.add(referralCode);
      return;
    }

    // Check for sponsorship code
    final sponsorshipCode = extractSponsorshipCode(link);
    if (sponsorshipCode != null) {
      print('✅ DeepLink: Extracted sponsorship code: $sponsorshipCode');
      _sponsorshipCodeController.add(sponsorshipCode);
      return;
    }

    // Check for dealer invitation token
    final dealerToken = extractDealerInvitationToken(link);
    if (dealerToken != null) {
      print('✅ DeepLink: Extracted dealer invitation token: $dealerToken');
      _dealerInvitationTokenController.add(dealerToken);
      return;
    }

    print('⚠️ DeepLink: No referral, sponsorship, or dealer invitation found in link: $link');
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

  /// Extract sponsorship code from deep link
  /// Formats supported (all environments):
  /// - https://ziraai.com/redeem/AGRI-XXXXXX (Production)
  /// - https://ziraai-api-sit.up.railway.app/redeem/AGRI-XXXXXX (Staging)
  /// - https://localhost:5001/redeem/AGRI-XXXXXX (Development)
  /// - ziraai://redeem/AGRI-XXXXXX (Custom scheme fallback)
  static String? extractSponsorshipCode(String link) {
    try {
      final uri = Uri.parse(link);

      // Handle HTTPS links (All environments)
      if (uri.scheme == 'https' || uri.scheme == 'http') {
        // Accept any host that contains 'ziraai' or localhost for development
        final isValidHost = uri.host.contains('ziraai') ||
                           uri.host.contains('localhost') ||
                           uri.host.contains('127.0.0.1');

        if (isValidHost && uri.pathSegments.isNotEmpty) {
          // Check if path starts with 'redeem'
          if (uri.pathSegments.first == 'redeem' && uri.pathSegments.length >= 2) {
            final code = uri.pathSegments[1];
            print('✅ DeepLink: Extracted sponsorship code from ${uri.scheme}://${uri.host}: $code');
            return code;
          }
        }
      }

      // Handle custom scheme (ziraai://redeem/AGRI-XXXXXX)
      if (uri.scheme == 'ziraai') {
        if (uri.pathSegments.isNotEmpty) {
          if (uri.pathSegments.first == 'redeem' && uri.pathSegments.length >= 2) {
            final code = uri.pathSegments[1];
            print('✅ DeepLink: Extracted sponsorship code from custom scheme: $code');
            return code;
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ DeepLink: Error extracting sponsorship code: $e');
      return null;
    }
  }

  /// Check if a link is a sponsorship deep link
  static bool isSponsorshipLink(String link) {
    try {
      final uri = Uri.parse(link);

      // Check HTTPS/HTTP links (all environments)
      if (uri.scheme == 'https' || uri.scheme == 'http') {
        final isValidHost = uri.host.contains('ziraai') ||
                           uri.host.contains('localhost') ||
                           uri.host.contains('127.0.0.1');
        return isValidHost &&
            uri.pathSegments.isNotEmpty &&
            uri.pathSegments.first == 'redeem';
      }

      // Check custom scheme
      if (uri.scheme == 'ziraai') {
        return uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'redeem';
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Extract dealer invitation token from deep link
  /// Formats supported (all environments):
  /// - https://ziraai.com/dealer-invitation/DEALER-abc123... (Production)
  /// - https://ziraai-api-sit.up.railway.app/dealer-invitation/DEALER-abc123... (Staging)
  /// - https://localhost:5001/dealer-invitation/DEALER-abc123... (Development)
  /// - ziraai://dealer-invitation/DEALER-abc123... (Custom scheme fallback)
  ///
  /// CRITICAL: Returns only the 32-char hex token WITHOUT "DEALER-" prefix
  static String? extractDealerInvitationToken(String link) {
    try {
      final uri = Uri.parse(link);

      // Handle HTTPS links (All environments)
      if (uri.scheme == 'https' || uri.scheme == 'http') {
        // Accept any host that contains 'ziraai' or localhost for development
        final isValidHost = uri.host.contains('ziraai') ||
                           uri.host.contains('localhost') ||
                           uri.host.contains('127.0.0.1');

        if (isValidHost && uri.pathSegments.isNotEmpty) {
          // Check if path starts with 'dealer-invitation'
          if (uri.pathSegments.first == 'dealer-invitation' && uri.pathSegments.length >= 2) {
            final fullToken = uri.pathSegments[1]; // "DEALER-abc123..."

            // Remove "DEALER-" prefix if present
            if (fullToken.toUpperCase().startsWith('DEALER-')) {
              final token = fullToken.substring(7); // Remove "DEALER-" prefix (7 chars)
              print('✅ DeepLink: Extracted dealer token from ${uri.scheme}://${uri.host}: $token');
              return token.toLowerCase(); // Return only 32-char hex part
            } else {
              // Token already without prefix (direct 32-char hex)
              print('✅ DeepLink: Extracted dealer token (no prefix) from ${uri.scheme}://${uri.host}: $fullToken');
              return fullToken.toLowerCase();
            }
          }
        }
      }

      // Handle custom scheme (ziraai://dealer-invitation/DEALER-abc123...)
      if (uri.scheme == 'ziraai') {
        if (uri.pathSegments.isNotEmpty) {
          if (uri.pathSegments.first == 'dealer-invitation' && uri.pathSegments.length >= 2) {
            final fullToken = uri.pathSegments[1];

            // Remove "DEALER-" prefix if present
            if (fullToken.toUpperCase().startsWith('DEALER-')) {
              final token = fullToken.substring(7);
              print('✅ DeepLink: Extracted dealer token from custom scheme: $token');
              return token.toLowerCase();
            } else {
              print('✅ DeepLink: Extracted dealer token (no prefix) from custom scheme: $fullToken');
              return fullToken.toLowerCase();
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ DeepLink: Error extracting dealer invitation token: $e');
      return null;
    }
  }

  /// Check if a link is a dealer invitation deep link
  static bool isDealerInvitationLink(String link) {
    try {
      final uri = Uri.parse(link);

      // Check HTTPS/HTTP links (all environments)
      if (uri.scheme == 'https' || uri.scheme == 'http') {
        final isValidHost = uri.host.contains('ziraai') ||
                           uri.host.contains('localhost') ||
                           uri.host.contains('127.0.0.1');
        return isValidHost &&
            uri.pathSegments.isNotEmpty &&
            uri.pathSegments.first == 'dealer-invitation';
      }

      // Check custom scheme
      if (uri.scheme == 'ziraai') {
        return uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'dealer-invitation';
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
    _sponsorshipCodeController.close();
    _dealerInvitationTokenController.close();
    print('📱 DeepLink: Service disposed');
  }
}
