import 'package:telephony/telephony.dart';

/// SMS Token Scanner Service
///
/// Scans SMS inbox for dealer invitation tokens and extracts them
///
/// Pattern: DEALER-{32-char-hex-token}
/// Example: "DEALER-7fc679cd040c44509f961f2b9fb0f7b4"
class SmsTokenScanner {
  final Telephony telephony = Telephony.instance;

  /// Scan SMS inbox for dealer invitation tokens
  ///
  /// Returns list of unique tokens found in SMS messages
  /// Only returns tokens that match the valid pattern
  Future<List<String>> scanForDealerTokens() async {
    try {
      // Request SMS permission if not granted
      bool? hasPermission = await telephony.requestSmsPermissions;

      if (hasPermission != true) {
        print('[SmsTokenScanner] ❌ SMS permission not granted');
        return [];
      }

      print('[SmsTokenScanner] 🔍 Scanning SMS inbox for dealer tokens...');

      // Get all SMS messages
      List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      print('[SmsTokenScanner] Found ${messages.length} SMS messages');

      // Extract tokens using regex
      final tokenPattern = RegExp(r'DEALER-([a-f0-9]{32})', caseSensitive: false);
      final Set<String> tokens = {};

      for (var message in messages) {
        final match = tokenPattern.firstMatch(message.body ?? '');
        if (match != null) {
          final fullToken = match.group(0)!; // DEALER-abc123...
          final token = match.group(1)!; // abc123...

          tokens.add(token.toLowerCase());
          print('[SmsTokenScanner] Found token: ${token.substring(0, 8)}... in SMS from ${message.address}');
        }
      }

      print('[SmsTokenScanner] ✅ Extracted ${tokens.length} unique dealer tokens');
      return tokens.toList();
    } catch (e) {
      print('[SmsTokenScanner] ❌ Error scanning SMS: $e');
      return [];
    }
  }

  /// Check if SMS permission is granted
  Future<bool> hasPermission() async {
    try {
      bool? hasPermission = await telephony.requestSmsPermissions;
      return hasPermission ?? false;
    } catch (e) {
      print('[SmsTokenScanner] Error checking permission: $e');
      return false;
    }
  }

  /// Request SMS permission from user
  Future<bool> requestPermission() async {
    try {
      bool? granted = await telephony.requestSmsPermissions;
      return granted ?? false;
    } catch (e) {
      print('[SmsTokenScanner] Error requesting permission: $e');
      return false;
    }
  }
}
