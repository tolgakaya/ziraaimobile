import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get_it/get_it.dart';
import '../services/navigation_service.dart';
import '../../features/sponsorship/presentation/screens/farmer/sponsorship_redemption_screen.dart';

/// SMS-based automatic sponsorship code redemption service
/// Listens for incoming SMS with sponsorship codes and auto-fills redemption screen
///
/// Features:
/// - Real-time SMS listening (background)
/// - Code extraction: AGRI-[A-Z0-9]+ or SPONSOR-[A-Z0-9]+
/// - Persistent storage for deferred deep linking
/// - 7-day inbox scan for codes received before app install
/// - Auto-navigation for logged-in users
class SponsorshipSmsListener {
  final Telephony telephony = Telephony.instance;

  // Regex to match sponsorship codes
  // Format: AGRI-XXXX-XXXXXXXX or SPONSOR-XXXX-XXXXXXXX
  // Supports hyphens in code: AGRI-2025-52834B45
  static final RegExp _codeRegex = RegExp(
    r'(AGRI-[A-Z0-9\-]+|SPONSOR-[A-Z0-9\-]+)',
    caseSensitive: true,
  );

  // Storage keys
  static const String _storageKeyCode = 'pending_sponsorship_code';
  static const String _storageKeyTimestamp = 'pending_sponsorship_code_timestamp';

  /// Initialize SMS listener
  /// Call this on app startup
  Future<void> initialize() async {
    print('[SponsorshipSMS] 🚀 Initializing sponsorship SMS listener...');

    // Request SMS permission
    final hasPermission = await _requestSmsPermission();
    if (!hasPermission) {
      print('[SponsorshipSMS] ⚠️ SMS permission denied - manual entry required');
      return;
    }

    // Start listening for incoming SMS
    await _startListening();

    // Check for pending codes from previous SMS (deferred deep linking)
    await _checkRecentSms();

    print('[SponsorshipSMS] ✅ Sponsorship SMS listener initialized successfully');
  }

  /// Request SMS permission from user
  Future<bool> _requestSmsPermission() async {
    try {
      // Already granted?
      if (await Permission.sms.isGranted) {
        print('[SponsorshipSMS] ✅ SMS permission already granted');
        return true;
      }

      print('[SponsorshipSMS] 📋 Requesting SMS permission...');

      // Request permission
      final status = await Permission.sms.request();

      if (status.isGranted) {
        print('[SponsorshipSMS] ✅ SMS permission granted');
        return true;
      } else if (status.isDenied) {
        print('[SponsorshipSMS] ⚠️ SMS permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        print('[SponsorshipSMS] ⚠️ SMS permission permanently denied');
        print('   User must enable manually from settings');
        // Open app settings
        await openAppSettings();
        return false;
      }

      return false;
    } catch (e) {
      print('[SponsorshipSMS] ❌ Permission error: $e');
      return false;
    }
  }

  /// Start listening for incoming SMS messages
  Future<void> _startListening() async {
    try {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) async {
          print('[SponsorshipSMS] 📱 New SMS received from ${message.address}');
          await _processSmsMessage(message.body ?? '');
        },
        onBackgroundMessage: _onBackgroundMessage,
        listenInBackground: true,
      );

      print('[SponsorshipSMS] 👂 Background SMS listener started');
    } catch (e) {
      print('[SponsorshipSMS] ❌ Failed to start SMS listener: $e');
    }
  }

  /// Background message handler (must be static or top-level)
  static Future<void> _onBackgroundMessage(SmsMessage message) async {
    print('[SponsorshipSMS] 📱 Background SMS received from ${message.address}');

    final messageBody = message.body ?? '';
    final match = _codeRegex.firstMatch(messageBody);

    if (match != null) {
      final code = match.group(0)!;
      print('[SponsorshipSMS] ✅ Background code extracted: $code');

      // Save to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageKeyCode, code);
        await prefs.setInt(
          _storageKeyTimestamp,
          DateTime.now().millisecondsSinceEpoch,
        );
        print('[SponsorshipSMS] 💾 Background code saved: $code');
      } catch (e) {
        print('[SponsorshipSMS] ❌ Background save error: $e');
      }
    }
  }

  /// Check recent SMS for sponsorship codes (deferred deep linking)
  /// Useful when app is installed after SMS was received
  Future<void> _checkRecentSms() async {
    try {
      // Get SMS from last 7 days
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      final messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.DATE)
            .greaterThan(cutoffDate.millisecondsSinceEpoch.toString()),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      print('[SponsorshipSMS] 🔍 Checking ${messages.length} recent SMS (last 7 days)');

      for (var message in messages) {
        final body = message.body ?? '';

        // Check if message contains sponsorship code
        if (_containsSponsorshipKeywords(body)) {
          await _processSmsMessage(body);
          print('[SponsorshipSMS] ✅ Found sponsorship code in recent SMS');
          break; // Only process first match
        }
      }

      print('[SponsorshipSMS] ✅ Recent SMS check completed');
    } catch (e) {
      print('[SponsorshipSMS] ❌ Error checking recent SMS: $e');
    }
  }

  /// Check if SMS contains sponsorship-related keywords
  bool _containsSponsorshipKeywords(String messageBody) {
    final keywords = [
      'Sponsorluk Kodunuz',
      'sponsorluk',
      'paketi hediye',
      'AGRI-',
      'SPONSOR-',
    ];

    return keywords.any((keyword) => messageBody.contains(keyword));
  }

  /// Process SMS message and extract sponsorship code
  Future<void> _processSmsMessage(String messageBody) async {
    print('[SponsorshipSMS] 🔎 Processing message: ${messageBody.length > 50 ? messageBody.substring(0, 50) : messageBody}...');

    // Extract sponsorship code using regex
    final match = _codeRegex.firstMatch(messageBody);
    if (match == null) {
      print('[SponsorshipSMS] ℹ️ No sponsorship code found in message');
      return;
    }

    final code = match.group(0)!;
    print('[SponsorshipSMS] ✅ Sponsorship code extracted: $code');

    // Save to persistent storage
    await _savePendingCode(code);

    // Check if user is logged in
    final isLoggedIn = await _isUserLoggedIn();

    if (isLoggedIn) {
      // Show notification and navigate
      print('[SponsorshipSMS] 👤 User logged in - showing notification');
      await _showCodeNotification(code);
      _navigateToRedemption(code);
    } else {
      print('[SponsorshipSMS] 👤 User not logged in - code saved for after login');
    }
  }

  /// Save sponsorship code to SharedPreferences
  Future<void> _savePendingCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKeyCode, code);
      await prefs.setInt(
        _storageKeyTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
      print('[SponsorshipSMS] 💾 Code saved to storage: $code');
    } catch (e) {
      print('[SponsorshipSMS] ❌ Error saving code: $e');
    }
  }

  /// Check if user is logged in
  Future<bool> _isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('[SponsorshipSMS] ❌ Error checking login status: $e');
      return false;
    }
  }

  /// Show notification to user about received code
  Future<void> _showCodeNotification(String code) async {
    // TODO: Implement with flutter_local_notifications if needed
    // For now, using simple print
    print('[SponsorshipSMS] 🎁 Notification: Sponsorship code $code received!');
  }

  /// Navigate to sponsorship redemption screen using global navigation service
  void _navigateToRedemption(String code) {
    try {
      print('[SponsorshipSMS] 🧭 Attempting to navigate to redemption screen with code: $code');

      // Get navigation service from GetIt
      final navigationService = GetIt.instance<NavigationService>();

      if (!navigationService.isReady) {
        print('[SponsorshipSMS] ⚠️ Navigation service not ready - code saved for later');
        return;
      }

      // Navigate to redemption screen with auto-filled code
      navigationService.navigateTo(
        SponsorshipRedemptionScreen(autoFilledCode: code),
      );

      print('[SponsorshipSMS] ✅ Successfully navigated to redemption screen');
    } catch (e) {
      print('[SponsorshipSMS] ❌ Navigation error: $e');
      print('[SponsorshipSMS] 💾 Code is saved in storage and will be available after login');
    }
  }

  /// Public method: Check for pending code after login
  /// Returns code if found and not too old (7 days max)
  static Future<String?> checkPendingCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_storageKeyCode);
      final timestamp = prefs.getInt(_storageKeyTimestamp);

      if (code == null || timestamp == null) {
        print('[SponsorshipSMS] ℹ️ No pending code found');
        return null;
      }

      // Check if code is not too old (7 days max)
      final codeDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(codeDate);

      if (age.inDays > 7) {
        print('[SponsorshipSMS] ⏰ Code too old (${age.inDays} days), ignoring');
        await clearPendingCode();
        return null;
      }

      print('[SponsorshipSMS] ✅ Found pending code: $code (${age.inHours}h old)');
      return code;
    } catch (e) {
      print('[SponsorshipSMS] ❌ Error checking pending code: $e');
      return null;
    }
  }

  /// Clear pending code from storage
  static Future<void> clearPendingCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKeyCode);
      await prefs.remove(_storageKeyTimestamp);
      print('[SponsorshipSMS] 🗑️ Pending code cleared');
    } catch (e) {
      print('[SponsorshipSMS] ❌ Error clearing code: $e');
    }
  }

  /// Debug: List recent SMS messages
  Future<void> debugListRecentSms() async {
    try {
      final messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      print('[SponsorshipSMS] 📱 Debug: Recent SMS (${messages.length} total)');
      for (var i = 0; i < messages.take(10).length; i++) {
        final msg = messages[i];
        final preview = msg.body?.substring(0, msg.body!.length > 50 ? 50 : msg.body!.length) ?? '';
        print('  ${i + 1}. ${msg.address}: $preview...');

        // Check if contains code
        if (_codeRegex.hasMatch(msg.body ?? '')) {
          final code = _codeRegex.firstMatch(msg.body!)?.group(0);
          print('     ✅ Contains code: $code');
        }
      }
    } catch (e) {
      print('[SponsorshipSMS] ❌ Debug list error: $e');
    }
  }

  /// Test code extraction with sample SMS
  static String? testCodeExtraction(String smsBody) {
    final match = _codeRegex.firstMatch(smsBody);
    return match?.group(0);
  }
}
