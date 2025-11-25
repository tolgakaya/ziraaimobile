import 'dart:async';
import 'package:android_sms_reader/android_sms_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../services/navigation_service.dart';
import '../services/auth_service.dart';
import '../../features/dealer/presentation/screens/dealer_invitation_screen.dart';

/// SMS-based automatic dealer invitation service
/// Listens for incoming SMS with dealer invitation tokens and handles automatic navigation
///
/// Features:
/// - Real-time SMS listening (background)
/// - Token extraction: DEALER-[a-f0-9]{32}
/// - Persistent storage for deferred deep linking
/// - 7-day inbox scan for tokens received before app install
/// - Auto-navigation for logged-in users
///
/// Pattern: Exactly same as SponsorshipSmsListener
class DealerInvitationSmsListener {
  StreamSubscription<AndroidSMSMessage>? _smsSubscription;

  // Regex to match dealer invitation tokens
  // Format: DEALER-{32-char-hex-lowercase}
  // Example: DEALER-a1b2c3d4e5f67890a1b2c3d4e5f67890
  // CRITICAL: group(1) extracts only the 32-char hex part WITHOUT "DEALER-" prefix
  static final RegExp _tokenRegex = RegExp(
    r'DEALER-([a-f0-9]{32})',
    caseSensitive: false,
  );

  // Storage keys
  static const String _storageKeyToken = 'pending_dealer_invitation_token';
  static const String _storageKeyTimestamp = 'pending_dealer_invitation_timestamp';

  /// Initialize SMS listener
  /// Call this on app startup
  Future<void> initialize() async {
    print('[DealerInvitationSMS] 🚀 Initializing dealer invitation SMS listener...');

    // Request SMS permission
    final hasPermission = await _requestSmsPermission();
    if (!hasPermission) {
      print('[DealerInvitationSMS] ⚠️ SMS permission denied - manual entry required');
      return;
    }

    // Start listening for incoming SMS
    await _startListening();

    // Check for pending tokens from previous SMS (deferred deep linking)
    await _checkRecentSms();

    print('[DealerInvitationSMS] ✅ Dealer invitation SMS listener initialized successfully');
  }

  /// Dispose resources
  void dispose() {
    _smsSubscription?.cancel();
  }

  /// Request SMS permission from user using android_sms_reader package
  /// IMPORTANT: Silent check - don't prompt if not already granted
  Future<bool> _requestSmsPermission() async {
    try {
      print('[DealerInvitationSMS] 📋 Checking SMS permission...');

      // Request permissions using android_sms_reader's isolated permission system
      final hasPermission = await AndroidSMSReader.requestPermissions();

      if (hasPermission) {
        print('[DealerInvitationSMS] ✅ SMS permission granted');
        return true;
      } else {
        print('[DealerInvitationSMS] ⚠️ SMS permission not granted - skipping listener');
        return false;
      }
    } catch (e) {
      print('[DealerInvitationSMS] ❌ Permission error (silently ignored): $e');
      // Silently fail to prevent crash
      return false;
    }
  }

  /// Start listening for incoming SMS messages
  Future<void> _startListening() async {
    try {
      print('[DealerInvitationSMS] 🎧 Setting up SMS listener using stream...');

      // Use android_sms_reader's streaming API for real-time SMS
      _smsSubscription = AndroidSMSReader.observeIncomingMessages().listen(
        (AndroidSMSMessage message) async {
          print('[DealerInvitationSMS] 📱🔔 REAL-TIME SMS RECEIVED from ${message.address}');
          print('[DealerInvitationSMS] 📱🔔 Message body: ${message.body}');
          await _processSmsMessage(message.body);
        },
        onError: (error) {
          print('[DealerInvitationSMS] ❌ SMS stream error: $error');
        },
      );

      print('[DealerInvitationSMS] 👂 SMS stream listener started successfully');
    } catch (e) {
      print('[DealerInvitationSMS] ❌ Failed to start SMS listener: $e');
    }
  }

  /// Check recent SMS for dealer invitation tokens (deferred deep linking)
  /// Useful when app is installed after SMS was received
  Future<void> _checkRecentSms() async {
    try {
      // Get SMS from last 7 days
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

      // Fetch recent messages (last 100 should be enough for 7 days)
      final messages = await AndroidSMSReader.fetchMessages(
        type: AndroidSMSType.inbox,
        count: 100,
      );

      // Filter by date (last 7 days)
      final recentMessages = messages.where(
        (msg) => msg.date >= cutoffDate.millisecondsSinceEpoch
      ).toList();

      print('[DealerInvitationSMS] 🔍 Checking ${recentMessages.length} recent SMS (last 7 days)');

      for (var message in recentMessages) {
        final body = message.body;

        // Check if message contains dealer invitation keywords
        if (_containsDealerInvitationKeywords(body)) {
          await _processSmsMessage(body);
          print('[DealerInvitationSMS] ✅ Found dealer invitation token in recent SMS');
          break; // Only process first match
        }
      }

      print('[DealerInvitationSMS] ✅ Recent SMS check completed');
    } catch (e) {
      print('[DealerInvitationSMS] ❌ Error checking recent SMS: $e');
    }
  }

  /// Check if SMS contains dealer invitation-related keywords
  bool _containsDealerInvitationKeywords(String messageBody) {
    final keywords = [
      'Bayilik Daveti',
      'bayilik',
      'DEALER-',
      'Davet Kodunuz:',
      'davet ediyor',
    ];

    return keywords.any((keyword) => messageBody.contains(keyword));
  }

  /// Process SMS message and extract dealer invitation token
  Future<void> _processSmsMessage(String messageBody) async {
    print('[DealerInvitationSMS] 🔎 Processing message: ${messageBody.length > 50 ? messageBody.substring(0, 50) : messageBody}...');

    // Extract dealer invitation token using regex
    final match = _tokenRegex.firstMatch(messageBody);
    if (match == null) {
      print('[DealerInvitationSMS] ℹ️ No dealer invitation token found in message');
      return;
    }

    // CRITICAL: group(1) extracts only the 32-char hex part WITHOUT "DEALER-" prefix
    final token = match.group(1)!;
    print('[DealerInvitationSMS] ✅ Dealer invitation token extracted: $token');

    // Save to persistent storage
    await _savePendingToken(token);

    // Check if user is logged in
    final isLoggedIn = await _isUserLoggedIn();

    if (isLoggedIn) {
      // Show notification and navigate
      print('[DealerInvitationSMS] 👤 User logged in - showing notification');
      await _showTokenNotification(token);
      _navigateToInvitation(token);
    } else {
      print('[DealerInvitationSMS] 👤 User not logged in - token saved for after login');
    }
  }

  /// Save dealer invitation token to SharedPreferences
  Future<void> _savePendingToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKeyToken, token);
      await prefs.setInt(
        _storageKeyTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
      print('[DealerInvitationSMS] 💾 Token saved to storage: $token');
    } catch (e) {
      print('[DealerInvitationSMS] ❌ Error saving token: $e');
    }
  }

  /// Check if user is logged in by checking SecureStorage token
  Future<bool> _isUserLoggedIn() async {
    try {
      // Check if user has valid token in SecureStorage via AuthService
      final authService = GetIt.instance<AuthService>();
      final isAuthenticated = await authService.isAuthenticated();

      if (isAuthenticated) {
        print('[DealerInvitationSMS] ✅ User logged in (token found in SecureStorage)');
        return true;
      }

      print('[DealerInvitationSMS] ℹ️ User not logged in - no token');
      return false;
    } catch (e) {
      print('[DealerInvitationSMS] ❌ Error checking login status: $e');
      return false;
    }
  }

  /// Show notification to user about received token
  Future<void> _showTokenNotification(String token) async {
    // TODO: Implement with flutter_local_notifications if needed
    // For now, using simple print
    print('[DealerInvitationSMS] 🎁 Notification: Dealer invitation token $token received!');
  }

  /// Navigate to dealer invitation screen using global navigation service
  void _navigateToInvitation(String token, {int retryCount = 0}) {
    try {
      print('[DealerInvitationSMS] 🧭 Attempting to navigate to dealer invitation screen with token: $token (retry: $retryCount)');

      // Get navigation service from GetIt
      final navigationService = GetIt.instance<NavigationService>();

      if (!navigationService.isReady) {
        // Navigation context not ready yet - retry after delay
        if (retryCount < 5) {
          final delayMs = 500 * (retryCount + 1); // Increasing delay: 500ms, 1000ms, 1500ms...
          print('[DealerInvitationSMS] ⚠️ Navigation service not ready - retrying in ${delayMs}ms (attempt ${retryCount + 1}/5)');

          Future.delayed(Duration(milliseconds: delayMs), () {
            _navigateToInvitation(token, retryCount: retryCount + 1);
          });
        } else {
          print('[DealerInvitationSMS] ⚠️ Navigation service not ready after 5 retries - token saved for later');
        }
        return;
      }

      // Navigate to dealer invitation screen with auto-filled token
      navigationService.navigateTo(
        DealerInvitationScreen(token: token),
      );

      print('[DealerInvitationSMS] ✅ Successfully navigated to dealer invitation screen');
    } catch (e) {
      print('[DealerInvitationSMS] ❌ Navigation error: $e');
      print('[DealerInvitationSMS] 💾 Token is saved in storage and will be available after login');
    }
  }

  /// Public method: Check for pending token after login
  /// Returns token if found and not too old (7 days max)
  static Future<String?> checkPendingToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_storageKeyToken);
      final timestamp = prefs.getInt(_storageKeyTimestamp);

      if (token == null || timestamp == null) {
        print('[DealerInvitationSMS] ℹ️ No pending token found');
        return null;
      }

      // Check if token is not too old (7 days max)
      final tokenDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(tokenDate);

      if (age.inDays > 7) {
        print('[DealerInvitationSMS] ⏰ Token too old (${age.inDays} days), ignoring');
        await clearPendingToken();
        return null;
      }

      print('[DealerInvitationSMS] ✅ Found pending token: $token (${age.inHours}h old)');
      return token;
    } catch (e) {
      print('[DealerInvitationSMS] ❌ Error checking pending token: $e');
      return null;
    }
  }

  /// Clear pending token from storage
  static Future<void> clearPendingToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKeyToken);
      await prefs.remove(_storageKeyTimestamp);
      print('[DealerInvitationSMS] 🗑️ Pending token cleared');
    } catch (e) {
      print('[DealerInvitationSMS] ❌ Error clearing token: $e');
    }
  }

  /// Debug: List recent SMS messages
  Future<void> debugListRecentSms() async {
    try {
      final messages = await AndroidSMSReader.fetchMessages(
        type: AndroidSMSType.inbox,
        count: 10,
      );

      print('[DealerInvitationSMS] 📱 Debug: Recent SMS (${messages.length} total)');
      for (var i = 0; i < messages.length; i++) {
        final msg = messages[i];
        final preview = msg.body.substring(0, msg.body.length > 50 ? 50 : msg.body.length);
        print('  ${i + 1}. ${msg.address}: $preview...');

        // Check if contains token
        if (_tokenRegex.hasMatch(msg.body)) {
          final token = _tokenRegex.firstMatch(msg.body)?.group(1);
          print('     ✅ Contains token: $token');
        }
      }
    } catch (e) {
      print('[DealerInvitationSMS] ❌ Debug list error: $e');
    }
  }

  /// Test token extraction with sample SMS
  static String? testTokenExtraction(String smsBody) {
    final match = _tokenRegex.firstMatch(smsBody);
    return match?.group(1); // Return only 32-char hex part (WITHOUT "DEALER-" prefix)
  }
}
