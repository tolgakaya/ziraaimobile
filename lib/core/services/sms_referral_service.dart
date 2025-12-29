// DISABLED: SMS reading feature removed due to Google Play Store policy compliance
// This feature required READ_SMS permission which is no longer allowed
// for apps targeting SDK 35+ unless core functionality requires it
//
// import 'package:android_sms_reader/android_sms_reader.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SMS'lerden referral kodu çıkarmak için servis
/// İlk uygulama açılışında kullanılır (deferred deep linking)
///
/// ⚠️ DISABLED: SMS reading functionality removed for Play Store compliance
/// Users must manually enter referral codes
class SmsReferralService {
  static const String _smsCheckedKey = 'sms_referral_checked';

  /// SMS'lerden ZIRA referral kodunu bul - DISABLED
  /// Son 24 saat içindeki mesajları tarar
  /// SADECE BİR KEZ ÇALIŞIR - sonraki açılışlarda atlanır
  ///
  /// ⚠️ Returns null - feature disabled for Play Store compliance
  Future<String?> extractReferralFromSms() async {
    try {
      print('⚠️ SmsReferral: Feature disabled - Play Store compliance (SMS permissions removed)');
      print('ℹ️ Users must manually enter referral codes');

      // Mark as checked to prevent future attempts
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_smsCheckedKey, true);

      return null;

      /* DISABLED CODE - Play Store Compliance
      // Check if we already checked SMS before
      final prefs = await SharedPreferences.getInstance();
      final alreadyChecked = prefs.getBool(_smsCheckedKey) ?? false;

      if (alreadyChecked) {
        print('📦 SmsReferral: Already checked before, skipping');
        return null;
      }
      // 1. SMS izni var mı kontrol et/iste
      final hasPermission = await _requestSmsPermission();

      if (!hasPermission) {
        print('⚠️ SMS izni reddedildi - manuel giriş yapılacak');
        return null;
      }

      print('📱 SMS\'ler taranıyor (son 24 saat)...');

      // 2. SMS'leri al (son 20 mesaj yeterli)
      final messages = await AndroidSMSReader.fetchMessages(
        type: AndroidSMSType.inbox,
        count: 20,
      );
      */
    } catch (e, stackTrace) {
      print('❌ SMS okuma hatası (disabled): $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /* DISABLED METHODS - Play Store Compliance

  /// SMS okuma izni iste (using permission_handler package) - DISABLED
  Future<bool> _requestSmsPermission() async {
    return false; // Always return false - feature disabled
  }

  /// Test için: Son SMS'leri listele (debug) - DISABLED
  Future<void> debugListRecentSms() async {
    print('⚠️ debugListRecentSms: Feature disabled - Play Store compliance');
  }
  */
}
