// TELEPHONY PLUGIN REMOVED - Causes camera permission crash
// SMS token scanner feature temporarily disabled
// import 'package:telephony/telephony.dart';

/// SMS Token Scanner Service
/// TEMPORARILY DISABLED - telephony plugin removed to fix camera permission crash
class SmsTokenScanner {
  /// Scan SMS inbox for dealer invitation tokens - DISABLED
  Future<String?> scanForInvitationToken() async {
    print('[SmsTokenScanner] ⚠️ SMS scanning temporarily disabled');
    print('[SmsTokenScanner] ℹ️ Telephony plugin removed to fix camera permission crash');
    print('[SmsTokenScanner] ℹ️ Please use deep links or manual token entry');
    return null;
  }

  /// Extract token from SMS body - DISABLED
  String? extractTokenFromSms(String smsBody) {
    print('[SmsTokenScanner] ⚠️ Token extraction temporarily disabled');
    return null;
  }
}
