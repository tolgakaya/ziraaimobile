// TELEPHONY PLUGIN REMOVED - Causes camera permission crash
// Dealer invitation SMS listening feature temporarily disabled
// import 'package:telephony/telephony.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../services/navigation_service.dart';
import '../services/auth_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// SMS-based automatic dealer invitation code detection service
/// TEMPORARILY DISABLED - telephony plugin removed to fix camera permission crash
class DealerInvitationSmsListener {
  static FlutterLocalNotificationsPlugin? _notificationsPlugin;
  static final RegExp _invitationLinkRegex = RegExp(
    r'https?://[^\s]+/dealer-invitation/[a-zA-Z0-9]+',
    caseSensitive: false,
  );

  static const String _storageKeyToken = 'pending_dealer_invitation_token';
  static const String _storageKeyTimestamp = 'pending_dealer_invitation_timestamp';
  static const String _processedTokensKey = 'processed_dealer_invitation_tokens';

  /// Initialize SMS listener - DISABLED
  Future<void> initialize() async {
    print('[DealerInvitationSMS] ⚠️ SMS listener temporarily disabled');
    print('[DealerInvitationSMS] ℹ️ Telephony plugin removed to fix camera permission crash');
    await _initializeNotifications();
  }

  /// Initialize local notifications
  Future<void> _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin?.initialize(initSettings);
  }

  /// Scan inbox for dealer invitation links - DISABLED
  Future<void> scanInboxForInvitations() async {
    print('[DealerInvitationSMS] ⚠️ Inbox scan temporarily disabled');
  }

  /// Check for pending dealer invitation token
  Future<String?> getPendingToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageKeyToken);
  }

  /// Clear pending dealer invitation token
  Future<void> clearPendingToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKeyToken);
    await prefs.remove(_storageKeyTimestamp);
  }

  /// Clear all processed tokens
  Future<void> clearProcessedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_processedTokensKey);
    print('[DealerInvitationSMS] 🗑️ Cleared processed tokens list');
  }
}
