// TELEPHONY PLUGIN REMOVED - Causes camera permission crash
// Sponsorship SMS listening feature temporarily disabled
// import 'package:telephony/telephony.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../services/navigation_service.dart';
import '../services/auth_service.dart';
import '../../features/sponsorship/presentation/screens/farmer/sponsorship_redemption_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// SMS-based automatic sponsorship code redemption service
/// TEMPORARILY DISABLED - telephony plugin removed to fix camera permission crash
class SponsorshipSmsListener {
  static FlutterLocalNotificationsPlugin? _notificationsPlugin;
  static final RegExp _codeRegex = RegExp(
    r'(AGRI-[A-Z0-9\-]+|SPONSOR-[A-Z0-9\-]+)',
    caseSensitive: true,
  );

  static const String _storageKeyCode = 'pending_sponsorship_code';
  static const String _storageKeyTimestamp = 'pending_sponsorship_code_timestamp';
  static const String _processedCodesKey = 'processed_sponsorship_codes';

  /// Initialize SMS listener - DISABLED
  Future<void> initialize() async {
    print('[SponsorshipSMS] ⚠️ SMS listener temporarily disabled');
    print('[SponsorshipSMS] ℹ️ Telephony plugin removed to fix camera permission crash');
    await _initializeNotifications();
  }

  /// Initialize local notifications for sponsorship codes
  Future<void> _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin?.initialize(initSettings);
  }

  /// Scan inbox for sponsorship codes - DISABLED
  Future<void> scanInboxForCodes() async {
    print('[SponsorshipSMS] ⚠️ Inbox scan temporarily disabled');
  }

  /// Clear all processed codes
  Future<void> clearProcessedCodes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_processedCodesKey);
    print('[SponsorshipSMS] 🗑️ Cleared processed codes list');
  }

  /// Static method to check for pending code - keeps existing behavior
  static Future<String?> checkPendingCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageKeyCode);
  }

  /// Static method to clear pending code - keeps existing behavior
  static Future<void> clearPendingCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKeyCode);
    await prefs.remove(_storageKeyTimestamp);
  }
}
