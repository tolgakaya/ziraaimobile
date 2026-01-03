import 'dart:async';
import 'package:sms_autofill/sms_autofill.dart';

/// OTP SMS auto-fill service using Google SMS Retriever API
/// NO PERMISSIONS REQUIRED - Fully compliant with Google Play Store policies
///
/// Features:
/// - Zero-permission SMS reading via SMS Retriever API
/// - Automatic code extraction (4-6 digit codes)
/// - Stream-based notification to UI
/// - Google Play Store compliant
///
/// Backend Integration Required:
/// SMS messages MUST include an 11-character hash code at the end:
/// Example: "Your ZiraAI verification code is 123456 <#> FA+9qCvUeDn"
///
/// How to get the hash code:
/// 1. Build and install the app on a device
/// 2. Call getAppSignature() method
/// 3. Add this hash to your backend SMS template
///
/// Usage:
/// 1. Initialize in app startup: OtpSmsListener().initialize()
/// 2. Subscribe to otpCodeStream in OTP verification screen
/// 3. Auto-fill OTP fields when code is received
class OtpSmsListener {
  static final OtpSmsListener _instance = OtpSmsListener._internal();
  factory OtpSmsListener() => _instance;
  OtpSmsListener._internal();

  final _otpCodeController = StreamController<String>.broadcast();

  /// Stream that emits OTP codes when received via SMS
  Stream<String> get otpCodeStream => _otpCodeController.stream;

  bool _isInitialized = false;
  String? _cachedAppSignature;

  /// Initialize OTP SMS listener
  /// Call this on app startup
  Future<void> initialize() async {
    if (_isInitialized) {
      print('[OTP_SMS] ⚠️ Already initialized, skipping...');
      return;
    }

    print('[OTP_SMS] 🚀 Initializing SMS Retriever API...');

    try {
      // Get and cache app signature for logging
      _cachedAppSignature = await getAppSignature();
      print('[OTP_SMS] 📱 App Signature Hash: $_cachedAppSignature');
      print('[OTP_SMS] ⚠️ IMPORTANT: Add this hash to your backend SMS template!');

      // Start listening - SMS Retriever API requires no permissions!
      await _startListening();

      _isInitialized = true;
      print('[OTP_SMS] ✅ SMS Retriever API initialized successfully');
    } catch (e) {
      print('[OTP_SMS] ❌ Initialization error: $e');
    }
  }

  /// Get the 11-character hash code for this app
  /// Backend must include this in SMS messages
  ///
  /// Example SMS format:
  /// "Your ZiraAI code is 123456 <#> FA+9qCvUeDn"
  Future<String?> getAppSignature() async {
    try {
      if (_cachedAppSignature != null) {
        return _cachedAppSignature;
      }

      final signature = await SmsAutoFill().getAppSignature;
      _cachedAppSignature = signature;

      print('[OTP_SMS] 📱 App Signature for SMS: $signature');
      print('[OTP_SMS] 📋 SMS Template: Your ZiraAI code is {{code}} <#> $signature');

      return signature;
    } catch (e) {
      print('[OTP_SMS] ❌ Error getting app signature: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    SmsAutoFill().unregisterListener();
    _otpCodeController.close();
    _isInitialized = false;
    print('[OTP_SMS] 🧹 SMS Retriever API listener disposed');
  }

  /// Start listening for incoming SMS messages via SMS Retriever API
  /// This method requires NO permissions!
  Future<void> _startListening() async {
    try {
      print('[OTP_SMS] 🎧 Starting SMS Retriever API listener...');

      // Listen for SMS code (works for 5 minutes per request)
      await SmsAutoFill().listenForCode();

      print('[OTP_SMS] 👂 SMS Retriever API listener started (active for 5 minutes)');
    } catch (e) {
      print('[OTP_SMS] ❌ Failed to start SMS listener: $e');
    }
  }

  /// Request SMS code - triggers 5-minute listening window
  /// Call this when user reaches OTP screen
  Future<void> requestSmsCode() async {
    try {
      print('[OTP_SMS] 📲 Starting SMS code listener (5-minute window)...');

      // Start listening for SMS code
      await SmsAutoFill().listenForCode();

      print('[OTP_SMS] 👂 SMS listener active - waiting for code...');
    } catch (e) {
      print('[OTP_SMS] ❌ Error starting SMS listener: $e');
    }
  }

  /// Get OTP code from current SMS input field (TextField integration)
  /// This provides real-time code extraction as SMS arrives
  Future<String?> getOtpFromSms() async {
    try {
      print('[OTP_SMS] 🔍 Getting OTP from SMS...');

      final code = await SmsAutoFill().hint;

      if (code != null && code.isNotEmpty) {
        print('[OTP_SMS] ✅ OTP code extracted: $code');
        return code;
      }

      print('[OTP_SMS] ℹ️ No OTP code found');
      return null;
    } catch (e) {
      print('[OTP_SMS] ❌ Error getting OTP: $e');
      return null;
    }
  }

  /// Get formatted phone number for SMS autofill
  /// This helps pre-fill the phone number field
  Future<String?> getPhoneHint() async {
    try {
      final phone = await SmsAutoFill().hint;
      return phone;
    } catch (e) {
      print('[OTP_SMS] ❌ Error getting phone hint: $e');
      return null;
    }
  }

  /// Manually extract OTP from SMS body (for custom formats)
  /// This is useful if backend SMS format doesn't match standard patterns
  String? extractOtpFromSms(String smsBody) {
    // Match 4-6 digit codes
    final otpRegex = RegExp(r'\b(\d{4,6})\b');
    final match = otpRegex.firstMatch(smsBody);

    if (match != null) {
      final code = match.group(1)!;
      print('[OTP_SMS] ✅ Extracted OTP: $code from SMS: $smsBody');
      return code;
    }

    print('[OTP_SMS] ⚠️ No OTP code found in SMS: $smsBody');
    return null;
  }

  /// Print integration instructions for backend team
  void printBackendInstructions() {
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('  SMS RETRIEVER API - BACKEND INTEGRATION GUIDE');
    print('═══════════════════════════════════════════════════════════');
    print('');
    print('App Signature Hash: $_cachedAppSignature');
    print('');
    print('SMS Template Format:');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Your ZiraAI verification code is {{OTP_CODE}}');
    print('<#> $_cachedAppSignature');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
    print('Requirements:');
    print('✓ Message must be under 140 characters');
    print('✓ Must contain <#> followed by 11-character hash');
    print('✓ Hash must be on same line or next line after code');
    print('✓ Code must be 4-6 digits');
    print('');
    print('Example Turkish SMS:');
    print('ZiraAI doğrulama kodunuz: 123456');
    print('<#> $_cachedAppSignature');
    print('');
    print('Example English SMS:');
    print('Your ZiraAI code is 123456 <#> $_cachedAppSignature');
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('');
  }
}
