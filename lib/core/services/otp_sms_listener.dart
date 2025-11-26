import 'dart:async';
import 'package:android_sms_reader/android_sms_reader.dart';
import 'package:permission_handler/permission_handler.dart';

/// OTP SMS auto-fill service
/// Listens for incoming SMS with OTP verification codes and auto-fills OTP screen
///
/// Features:
/// - Real-time SMS listening for OTP codes
/// - Code extraction: 6-digit numeric codes
/// - Automatic field population
/// - Works for both login and registration flows
/// - Stream-based notification to UI
///
/// Usage:
/// 1. Initialize in app startup: OtpSmsListener().initialize()
/// 2. Subscribe to otpCodeStream in OTP verification screen
/// 3. Auto-fill OTP fields when code is received
class OtpSmsListener {
  static final OtpSmsListener _instance = OtpSmsListener._internal();
  factory OtpSmsListener() => _instance;
  OtpSmsListener._internal();

  StreamSubscription<AndroidSMSMessage>? _smsSubscription;
  final _otpCodeController = StreamController<String>.broadcast();

  /// Stream that emits OTP codes when received via SMS
  Stream<String> get otpCodeStream => _otpCodeController.stream;

  /// Regex to match 6-digit OTP codes
  /// Matches patterns like:
  /// - "Your code is 123456"
  /// - "Doğrulama kodunuz: 123456"
  /// - "123456 kodunu kullanın"
  static final RegExp _otpRegex = RegExp(
    r'\b(\d{6})\b',
    caseSensitive: false,
  );

  /// Initialize OTP SMS listener
  /// Call this on app startup
  Future<void> initialize() async {
    print('[OTP_SMS] 🚀 Initializing OTP SMS listener...');

    // Request SMS permission
    final hasPermission = await _requestSmsPermission();
    if (!hasPermission) {
      print('[OTP_SMS] ⚠️ SMS permission denied - manual OTP entry required');
      return;
    }

    // Start listening for incoming SMS
    await _startListening();

    print('[OTP_SMS] ✅ OTP SMS listener initialized successfully');
  }

  /// Dispose resources
  void dispose() {
    _smsSubscription?.cancel();
    _otpCodeController.close();
    print('[OTP_SMS] 🧹 OTP SMS listener disposed');
  }

  /// Request SMS permission from user
  Future<bool> _requestSmsPermission() async {
    try {
      print('[OTP_SMS] 📋 Checking SMS permission...');

      // Check current permission status
      final smsStatus = await Permission.sms.status;
      print('[OTP_SMS] 🔍 Current SMS permission status: $smsStatus');

      // If already granted, return true
      if (smsStatus.isGranted) {
        print('[OTP_SMS] ✅ SMS permission already granted');
        return true;
      }

      // If permanently denied, can't request again
      if (smsStatus.isPermanentlyDenied) {
        print('[OTP_SMS] 🚨 SMS permission permanently denied');
        return false;
      }

      // Request permission - this will show dialog
      print('[OTP_SMS] 🔍 Requesting SMS permission (will show dialog)');
      final newStatus = await Permission.sms.request();
      print('[OTP_SMS] 🔍 Permission result: $newStatus');

      if (newStatus.isGranted) {
        print('[OTP_SMS] ✅ SMS permission granted by user');
        return true;
      }

      print('[OTP_SMS] ⚠️ SMS permission not granted');
      return false;
    } catch (e) {
      print('[OTP_SMS] ❌ Permission error: $e');
      return false;
    }
  }

  /// Start listening for incoming SMS messages
  Future<void> _startListening() async {
    try {
      print('[OTP_SMS] 🎧 Setting up SMS listener for OTP codes...');

      // Use android_sms_reader's streaming API for real-time SMS
      _smsSubscription = AndroidSMSReader.observeIncomingMessages().listen(
        (AndroidSMSMessage message) async {
          print('[OTP_SMS] 📱 SMS received from ${message.address}');
          print('[OTP_SMS] 📱 Message body: ${message.body}');
          await _processSmsMessage(message.body);
        },
        onError: (error) {
          print('[OTP_SMS] ❌ SMS stream error: $error');
        },
        onDone: () {
          print('[OTP_SMS] ⚠️ SMS stream closed unexpectedly');
        },
        cancelOnError: false,
      );

      print('[OTP_SMS] 👂 OTP SMS listener started successfully');
    } catch (e) {
      print('[OTP_SMS] ❌ Failed to start SMS listener: $e');
    }
  }

  /// Process SMS message and extract OTP code
  Future<void> _processSmsMessage(String messageBody) async {
    print('[OTP_SMS] 🔎 Processing message for OTP code...');

    // Check if message contains OTP-related keywords (Turkish + English)
    if (!_containsOtpKeywords(messageBody)) {
      print('[OTP_SMS] ℹ️ Message does not contain OTP keywords, skipping');
      return;
    }

    // Extract OTP code using regex
    final match = _otpRegex.firstMatch(messageBody);
    if (match == null) {
      print('[OTP_SMS] ℹ️ No 6-digit code found in message');
      return;
    }

    final otpCode = match.group(1)!;
    print('[OTP_SMS] ✅ OTP code extracted: $otpCode');

    // Emit code to stream for UI to consume
    _otpCodeController.add(otpCode);
    print('[OTP_SMS] 📤 OTP code emitted to stream');
  }

  /// Check if SMS contains OTP-related keywords
  bool _containsOtpKeywords(String messageBody) {
    final keywords = [
      'doğrulama',
      'kod',
      'verification',
      'code',
      'otp',
      'ZiraAI',
      'ziraai',
    ];

    final lowerBody = messageBody.toLowerCase();
    return keywords.any((keyword) => lowerBody.contains(keyword.toLowerCase()));
  }

  /// Check recent SMS for OTP codes (useful for testing or delayed processing)
  /// Scans last 5 SMS messages from last 5 minutes
  Future<String?> checkRecentSmsForOtp() async {
    try {
      print('[OTP_SMS] 🔍 Checking recent SMS for OTP codes...');

      // Get recent messages (last 5)
      final messages = await AndroidSMSReader.fetchMessages(
        type: AndroidSMSType.inbox,
        count: 5,
      );

      // Check messages from last 5 minutes only
      final cutoffTime = DateTime.now().subtract(const Duration(minutes: 5));

      for (var message in messages) {
        final messageDate = DateTime.fromMillisecondsSinceEpoch(message.date);

        // Skip old messages
        if (messageDate.isBefore(cutoffTime)) {
          continue;
        }

        final body = message.body;

        // Check if contains OTP keywords
        if (_containsOtpKeywords(body)) {
          final match = _otpRegex.firstMatch(body);
          if (match != null) {
            final otpCode = match.group(1)!;
            print('[OTP_SMS] ✅ Found OTP code in recent SMS: $otpCode');
            return otpCode;
          }
        }
      }

      print('[OTP_SMS] ℹ️ No recent OTP codes found');
      return null;
    } catch (e) {
      print('[OTP_SMS] ❌ Error checking recent SMS: $e');
      return null;
    }
  }

  /// Test OTP extraction with sample SMS
  static String? testOtpExtraction(String smsBody) {
    final match = _otpRegex.firstMatch(smsBody);
    return match?.group(1);
  }
}
