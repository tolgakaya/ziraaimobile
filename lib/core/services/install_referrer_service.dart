import 'dart:async';
import 'dart:io' show Platform;
import 'package:install_referrer/install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle Play Store Install Referrer for deferred deep linking
/// When app is installed from Play Store with referrer parameter,
/// this service extracts the referral code and stores it for registration
///
/// Example Play Store URL:
/// https://play.google.com/store/apps/details?id=com.ziraai.app&referrer=ZIRA-K5ZYZX
class InstallReferrerService {
  static const String _referralCodeKey = 'deferred_referral_code';
  static const String _referrerCheckedKey = 'install_referrer_checked';

  /// Check and extract referral code from Play Store install referrer
  /// This should be called ONCE on first app launch after installation
  Future<String?> checkInstallReferrer() async {
    // Only works on Android
    if (!Platform.isAndroid) {
      print('📦 InstallReferrer: iOS not supported, skipping');
      return null;
    }

    try {
      // Check if we already processed the install referrer
      final prefs = await SharedPreferences.getInstance();
      final alreadyChecked = prefs.getBool(_referrerCheckedKey) ?? false;

      if (alreadyChecked) {
        print('📦 InstallReferrer: Already checked before, skipping');
        return null;
      }

      print('📦 InstallReferrer: Checking Play Store install referrer...');

      // Get install referrer details
      final referrerDetails = await InstallReferrer.referrer;

      if (referrerDetails != null && referrerDetails.installReferrer != null && referrerDetails.installReferrer!.isNotEmpty) {
        final referrerString = referrerDetails.installReferrer!;
        print('📦 InstallReferrer: Raw referrer data: $referrerString');

        // Extract referral code from referrer string
        final referralCode = _extractReferralCode(referrerString);

        if (referralCode != null) {
          print('✅ InstallReferrer: Extracted referral code: $referralCode');

          // Store for later use in registration
          await prefs.setString(_referralCodeKey, referralCode);

          // Mark as checked to avoid repeated calls
          await prefs.setBool(_referrerCheckedKey, true);

          return referralCode;
        } else {
          print('⚠️ InstallReferrer: No referral code found in referrer data');
          // Still mark as checked even if no code found
          await prefs.setBool(_referrerCheckedKey, true);
        }
      } else {
        print('📦 InstallReferrer: No install referrer data available');
        // Mark as checked
        await prefs.setBool(_referrerCheckedKey, true);
      }
    } catch (e) {
      print('❌ InstallReferrer: Error getting install referrer: $e');
      // Don't mark as checked on error - allow retry
    }

    return null;
  }

  /// Extract ZIRA referral code from Play Store referrer string
  ///
  /// Expected formats:
  /// - "referrer=ZIRA-K5ZYZX"
  /// - "utm_source=google&utm_medium=cpc&referrer=ZIRA-K5ZYZX"
  /// - "ZIRA-K5ZYZX" (direct code)
  String? _extractReferralCode(String referrerString) {
    try {
      // Check if it's already a ZIRA code (direct format)
      if (referrerString.startsWith('ZIRA-')) {
        return referrerString;
      }

      // Parse as URL query parameters
      final uri = Uri.parse('?$referrerString');
      final referrerParam = uri.queryParameters['referrer'];

      if (referrerParam != null && referrerParam.startsWith('ZIRA-')) {
        return referrerParam;
      }

      // Try to find ZIRA code in the string using regex
      final regex = RegExp(r'ZIRA-[A-Z0-9]+');
      final match = regex.firstMatch(referrerString);

      if (match != null) {
        return match.group(0);
      }

      return null;
    } catch (e) {
      print('❌ InstallReferrer: Error extracting referral code: $e');
      return null;
    }
  }

  /// Get stored deferred referral code (from install referrer)
  /// Returns code and clears it after reading (one-time use)
  Future<String?> getDeferredReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_referralCodeKey);

      if (code != null) {
        print('📦 InstallReferrer: Retrieved deferred code: $code');

        // Clear after reading (one-time use)
        await prefs.remove(_referralCodeKey);

        return code;
      }

      return null;
    } catch (e) {
      print('❌ InstallReferrer: Error getting deferred code: $e');
      return null;
    }
  }

  /// Check if there's a pending deferred referral code
  Future<bool> hasDeferredReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_referralCodeKey);
    } catch (e) {
      print('❌ InstallReferrer: Error checking deferred code: $e');
      return false;
    }
  }

  /// Reset referrer check flag (for testing purposes only)
  Future<void> resetReferrerCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_referrerCheckedKey);
      await prefs.remove(_referralCodeKey);
      print('🔄 InstallReferrer: Reset successful (testing mode)');
    } catch (e) {
      print('❌ InstallReferrer: Reset error: $e');
    }
  }
}
