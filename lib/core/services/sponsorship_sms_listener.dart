import 'dart:async';
import 'package:android_sms_reader/android_sms_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/navigation_service.dart';
import '../services/auth_service.dart';
import '../../features/sponsorship/presentation/screens/farmer/sponsorship_redemption_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// SMS-based automatic sponsorship code redemption service
/// Listens for incoming SMS with sponsorship codes and auto-fills redemption screen
///
/// Features:
/// - Real-time SMS listening (background)
/// - Code extraction: AGRI-[A-Z0-9]+ or SPONSOR-[A-Z0-9]+
/// - Persistent storage for deferred deep linking
/// - 7-day inbox scan for codes received before app install
/// - Auto-navigation for logged-in users
/// - Local notifications for immediate user awareness
/// - Duplicate prevention: Processed codes are tracked to prevent re-notifications
///
/// Duplicate Prevention Strategy:
/// - Each processed code is stored in local SharedPreferences list
/// - Before showing notification, code is checked against processed list
/// - Once code is shown/used, it's marked as processed
/// - Prevents duplicate notifications on app restart or SMS re-scan
/// - Use clearProcessedCodes() for debugging/testing to reset list
class SponsorshipSmsListener {
  static FlutterLocalNotificationsPlugin? _notificationsPlugin;
  StreamSubscription<AndroidSMSMessage>? _smsSubscription;
  Timer? _healthCheckTimer;

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
  static const String _processedCodesKey = 'processed_sponsorship_codes';

  /// Initialize SMS listener
  /// Call this on app startup
  Future<void> initialize() async {
    print('[SponsorshipSMS] 🚀 Initializing sponsorship SMS listener...');
    print('[SponsorshipSMS] 🔍 DEBUG: Initialize method called');

    // Initialize local notifications
    print('[SponsorshipSMS] 🔍 DEBUG: Step 1/4 - Initializing notifications');
    await _initializeNotifications();

    // Request SMS permission
    print('[SponsorshipSMS] 🔍 DEBUG: Step 2/4 - Requesting SMS permission');
    final hasPermission = await _requestSmsPermission();
    if (!hasPermission) {
      print('[SponsorshipSMS] ⚠️ SMS permission denied - manual entry required');
      print('[SponsorshipSMS] 🚨 CRITICAL: Initialization aborted due to missing permission');
      return;
    }

    // Start listening for incoming SMS
    print('[SponsorshipSMS] 🔍 DEBUG: Step 3/4 - Starting SMS stream listener');
    await _startListening();

    // Check for pending codes from previous SMS (deferred deep linking)
    print('[SponsorshipSMS] 🔍 DEBUG: Step 4/4 - Checking recent SMS');
    await _checkRecentSms();

    // Start periodic health check (every 30 seconds)
    print('[SponsorshipSMS] 🔍 DEBUG: Starting periodic health check timer');
    _startHealthCheck();

    print('[SponsorshipSMS] ✅ Sponsorship SMS listener initialized successfully');
    print('[SponsorshipSMS] 🔍 DEBUG: Full initialization complete - listener should be active');
  }

  /// Start periodic health check to verify stream is still active
  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final isActive = _smsSubscription != null && !(_smsSubscription?.isPaused ?? true);
      print('[SponsorshipSMS] 🏥 Health Check: Stream subscription active = $isActive');

      if (!isActive) {
        print('[SponsorshipSMS] 🚨 CRITICAL: Stream subscription is not active!');
        print('[SponsorshipSMS] 🚨 Subscription null: ${_smsSubscription == null}');
        print('[SponsorshipSMS] 🚨 Subscription paused: ${_smsSubscription?.isPaused}');
      } else {
        print('[SponsorshipSMS] ✅ Health Check: Listener is healthy and active');
      }
    });
  }

  /// Dispose resources
  void dispose() {
    _healthCheckTimer?.cancel();
    _smsSubscription?.cancel();
    print('[SponsorshipSMS] 🧹 Resources disposed (subscription and health check timer cancelled)');
  }

  /// Initialize local notifications
  static Future<void> _initializeNotifications() async {
    try {
      _notificationsPlugin = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin?.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channel (required for Android 8.0+)
      const androidChannel = AndroidNotificationChannel(
        'sponsorship_codes',
        'Sponsorluk Kodları',
        description: 'Sponsorluk kodu bildirimleri',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notificationsPlugin
          ?.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      print('[SponsorshipSMS] ✅ Local notifications initialized with channel');
    } catch (e) {
      print('[SponsorshipSMS] ⚠️ Failed to initialize notifications: $e');
    }
  }

  /// Handle notification tap - navigate to redemption screen
  static void _onNotificationTapped(NotificationResponse response) async {
    try {
      final code = response.payload;
      if (code == null || code.isEmpty) {
        print('[SponsorshipSMS] ⚠️ No code in notification payload');
        return;
      }

      print('[SponsorshipSMS] 🎯 Notification tapped, navigating with code: $code');

      // Mark as processed (if not already) to prevent duplicate navigation
      await _markCodeAsProcessed(code);

      // Navigate using NavigationService
      final navigationService = GetIt.instance<NavigationService>();
      if (navigationService.isReady) {
        await navigationService.navigateTo(
          SponsorshipRedemptionScreen(autoFilledCode: code),
        );

        // Clear pending code after navigation
        await clearPendingCode();
      } else {
        print('[SponsorshipSMS] ⚠️ Navigation not ready, code remains in storage');
      }
    } catch (e) {
      print('[SponsorshipSMS] ❌ Error handling notification tap: $e');
    }
  }

  /// Request SMS permission from user using permission_handler
  /// This will show the system permission dialog if not granted
  Future<bool> _requestSmsPermission() async {
    try {
      print('[SponsorshipSMS] 📋 Checking SMS permission...');
      print('[SponsorshipSMS] 🔍 DEBUG: Checking current SMS permission status');

      // Check current permission status
      final smsStatus = await Permission.sms.status;
      print('[SponsorshipSMS] 🔍 DEBUG: Current SMS permission status: $smsStatus');

      // If already granted, return true
      if (smsStatus.isGranted) {
        print('[SponsorshipSMS] ✅ SMS permission already granted');
        return true;
      }

      // If permanently denied, can't request again
      if (smsStatus.isPermanentlyDenied) {
        print('[SponsorshipSMS] 🚨 CRITICAL: SMS permission permanently denied by user');
        print('[SponsorshipSMS] ℹ️ User must enable SMS permission in Settings manually');
        return false;
      }

      // Request permission - this will show dialog
      print('[SponsorshipSMS] 🔍 DEBUG: Requesting SMS permission from user (will show dialog)');
      final newStatus = await Permission.sms.request();
      print('[SponsorshipSMS] 🔍 DEBUG: Permission request result: $newStatus');

      if (newStatus.isGranted) {
        print('[SponsorshipSMS] ✅ SMS permission granted by user');
        return true;
      } else if (newStatus.isDenied) {
        print('[SponsorshipSMS] ⚠️ User denied SMS permission');
        return false;
      } else if (newStatus.isPermanentlyDenied) {
        print('[SponsorshipSMS] 🚨 User permanently denied SMS permission');
        return false;
      }

      print('[SponsorshipSMS] ⚠️ SMS permission not granted - skipping listener');
      return false;
    } catch (e, stackTrace) {
      print('[SponsorshipSMS] ❌ Permission error (silently ignored): $e');
      print('[SponsorshipSMS] 🔍 DEBUG: Stack trace: $stackTrace');
      // Silently fail to prevent crash
      return false;
    }
  }

  /// Start listening for incoming SMS messages
  Future<void> _startListening() async {
    try {
      print('[SponsorshipSMS] 🎧 Setting up SMS listener using stream...');
      print('[SponsorshipSMS] 🔍 DEBUG: About to call AndroidSMSReader.observeIncomingMessages()');

      // Use android_sms_reader's streaming API for real-time SMS
      _smsSubscription = AndroidSMSReader.observeIncomingMessages().listen(
        (AndroidSMSMessage message) async {
          print('[SponsorshipSMS] 📱🔔 REAL-TIME SMS RECEIVED from ${message.address}');
          print('[SponsorshipSMS] 📱🔔 Message body: ${message.body}');
          print('[SponsorshipSMS] 🔍 DEBUG: Processing SMS in listener callback');
          await _processSmsMessage(message.body);
        },
        onError: (error, stackTrace) {
          print('[SponsorshipSMS] ❌ SMS stream error: $error');
          print('[SponsorshipSMS] 🔍 DEBUG: Error stack trace: $stackTrace');
        },
        onDone: () {
          print('[SponsorshipSMS] ⚠️ SMS stream closed/completed unexpectedly');
        },
        cancelOnError: false, // Keep listening even if there's an error
      );

      print('[SponsorshipSMS] 👂 SMS stream listener started successfully');
      print('[SponsorshipSMS] 🔍 DEBUG: Stream subscription created: ${_smsSubscription != null}');
      print('[SponsorshipSMS] 🔍 DEBUG: Stream subscription is active: ${_smsSubscription?.isPaused == false}');
    } catch (e, stackTrace) {
      print('[SponsorshipSMS] ❌ Failed to start SMS listener: $e');
      print('[SponsorshipSMS] 🔍 DEBUG: Stack trace: $stackTrace');
    }
  }

  /// Check recent SMS for sponsorship codes (deferred deep linking)
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

      print('[SponsorshipSMS] 🔍 Checking ${recentMessages.length} recent SMS (last 7 days)');

      for (var message in recentMessages) {
        final body = message.body;

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

    // Check if code has already been processed
    final isProcessed = await _isCodeProcessed(code);
    if (isProcessed) {
      print('[SponsorshipSMS] ⏭️ Skipping already processed code: $code');
      return;
    }

    // Save to persistent storage
    await _savePendingCode(code);

    // Check if user is logged in
    final isLoggedIn = await _isUserLoggedIn();

    if (isLoggedIn) {
      // Show notification - user can tap to open redemption screen
      print('[SponsorshipSMS] 👤 User logged in - showing notification');
      await _showCodeNotification(code);

      // Mark code as processed after showing notification
      await _markCodeAsProcessed(code);
    } else {
      print('[SponsorshipSMS] 👤 User not logged in - code saved for after login');
      // Don't mark as processed yet - will be processed after login
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

  /// Check if user is logged in by checking SecureStorage token
  Future<bool> _isUserLoggedIn() async {
    try {
      // Check if user has valid token in SecureStorage via AuthService
      final authService = GetIt.instance<AuthService>();
      final isAuthenticated = await authService.isAuthenticated();

      if (isAuthenticated) {
        print('[SponsorshipSMS] ✅ User logged in (token found in SecureStorage)');
        return true;
      }

      print('[SponsorshipSMS] ℹ️ User not logged in - no token');
      return false;
    } catch (e) {
      print('[SponsorshipSMS] ❌ Error checking login status: $e');
      return false;
    }
  }

  /// Check if sponsorship code has already been processed
  /// Returns true if code was already processed (notification shown or redeemed)
  static Future<bool> _isCodeProcessed(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final processedCodes = prefs.getStringList(_processedCodesKey) ?? [];
      final isProcessed = processedCodes.contains(code);

      if (isProcessed) {
        print('[SponsorshipSMS] 🔍 Code already processed: $code');
      }

      return isProcessed;
    } catch (e) {
      print('[SponsorshipSMS] ❌ Error checking processed codes: $e');
      return false; // Fail-safe: if error, allow processing
    }
  }

  /// Mark sponsorship code as processed to prevent duplicate notifications
  /// Call this after showing notification or navigating to redemption screen
  static Future<void> _markCodeAsProcessed(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final processedCodes = prefs.getStringList(_processedCodesKey) ?? [];

      if (!processedCodes.contains(code)) {
        processedCodes.add(code);
        await prefs.setStringList(_processedCodesKey, processedCodes);
        print('[SponsorshipSMS] ✅ Code marked as processed: $code');
      }
    } catch (e) {
      print('[SponsorshipSMS] ❌ Error marking code as processed: $e');
    }
  }

  /// Clear all processed codes (for debugging/testing or user request)
  static Future<void> clearProcessedCodes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_processedCodesKey);
      print('[SponsorshipSMS] 🗑️ All processed codes cleared');
    } catch (e) {
      print('[SponsorshipSMS] ❌ Error clearing processed codes: $e');
    }
  }

  /// Show notification to user about received code
  static Future<void> _showCodeNotification(String code) async {
    try {
      if (_notificationsPlugin == null) {
        print('[SponsorshipSMS] ⚠️ Notifications not initialized');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'sponsorship_codes',
        'Sponsorluk Kodları',
        channelDescription: 'Sponsorluk kodu bildirimleri',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin?.show(
        0, // notification id
        '🎁 Sponsorluk Kodu Alındı!',
        'Kod: $code - Kullanmak için tıklayın',
        notificationDetails,
        payload: code, // Pass code to notification tap handler
      );

      print('[SponsorshipSMS] 🎁 Notification shown for code: $code');
    } catch (e) {
      print('[SponsorshipSMS] ❌ Failed to show notification: $e');
    }
  }


  /// Public method: Check for pending code after login
  /// Returns code if found and not too old (7 days max) and not already processed
  static Future<String?> checkPendingCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_storageKeyCode);
      final timestamp = prefs.getInt(_storageKeyTimestamp);

      if (code == null || timestamp == null) {
        print('[SponsorshipSMS] ℹ️ No pending code found');
        return null;
      }

      // Check if code has already been processed
      final isProcessed = await _isCodeProcessed(code);
      if (isProcessed) {
        print('[SponsorshipSMS] ⏭️ Pending code already processed: $code');
        await clearPendingCode(); // Clear from pending storage
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

      // Mark as processed since we're returning it for redemption
      await _markCodeAsProcessed(code);

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
      final messages = await AndroidSMSReader.fetchMessages(
        type: AndroidSMSType.inbox,
        count: 10,
      );

      print('[SponsorshipSMS] 📱 Debug: Recent SMS (${messages.length} total)');
      for (var i = 0; i < messages.length; i++) {
        final msg = messages[i];
        final preview = msg.body.substring(0, msg.body.length > 50 ? 50 : msg.body.length);
        print('  ${i + 1}. ${msg.address}: $preview...');

        // Check if contains code
        if (_codeRegex.hasMatch(msg.body)) {
          final code = _codeRegex.firstMatch(msg.body)?.group(0);
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
