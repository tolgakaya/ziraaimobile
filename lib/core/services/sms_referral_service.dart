// TELEPHONY PLUGIN REMOVED - Causes camera permission crash
// SMS referral feature temporarily disabled until alternative solution implemented
// import 'package:telephony/telephony.dart';

/// SMS'lerden referral kodu çıkarmak için servis
/// İlk uygulama açılışında kullanılır (deferred deep linking)
/// TEMPORARILY DISABLED - telephony plugin removed
class SmsReferralService {
  /// SMS'lerden ZIRA referral kodunu bul
  /// Son 24 saat içindeki mesajları tarar
  /// TEMPORARILY DISABLED - returns null until alternative solution
  Future<String?> extractReferralFromSms() async {
    print('⚠️ SMS referral feature temporarily disabled');
    print('ℹ️ Telephony plugin removed to fix camera permission crash');
    print('ℹ️ Please use deep links or manual code entry');
    return null;
  }

  /// Test için: Son SMS'leri listele (debug)
  /// TEMPORARILY DISABLED
  Future<void> debugListRecentSms() async {
    print('⚠️ SMS debug feature temporarily disabled');
  }
}
