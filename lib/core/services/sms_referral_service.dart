import 'package:android_sms_reader/android_sms_reader.dart';

/// SMS'lerden referral kodu çıkarmak için servis
/// İlk uygulama açılışında kullanılır (deferred deep linking)
class SmsReferralService {
  final SmsReader _smsReader = SmsReader();

  /// SMS'lerden ZIRA referral kodunu bul
  /// Son 24 saat içindeki mesajları tarar
  Future<String?> extractReferralFromSms() async {
    try {
      // 1. SMS izni var mı kontrol et/iste
      final hasPermission = await _requestSmsPermission();

      if (!hasPermission) {
        print('⚠️ SMS izni reddedildi - manuel giriş yapılacak');
        return null;
      }

      print('📱 SMS\'ler taranıyor (son 24 saat)...');

      // 2. SMS'leri al (son 20 mesaj yeterli)
      final messages = await _smsReader.fetchMessages(
        type: SmsType.inbox,
        count: 20,
      );

      // 3. Son 24 saat filtresi (timestamp olarak)
      final yesterdayTimestamp = DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch;

      // 4. Her SMS'i kontrol et
      for (var message in messages) {
        // Tarih kontrolü (24 saatten eski mesajları atla)
        // message.timestamp is int (milliseconds since epoch)
        if (message.timestamp < yesterdayTimestamp) {
          print('ℹ️ 24 saatten eski mesajlara ulaşıldı, durduruldu');
          break;
        }

        final body = message.body ?? '';

        // ZIRA formatını ara (regex)
        final regex = RegExp(r'ZIRA-[A-Z0-9]+');
        final match = regex.firstMatch(body);

        if (match != null) {
          final referralCode = match.group(0)!;

          print('✅ SMS\'den referral kod bulundu!');
          print('   Kod: $referralCode');
          print('   Gönderen: ${message.sender ?? "Bilinmiyor"}');
          print('   Tarih: ${message.timestamp}');
          print('   Mesaj önizleme: ${body.substring(0, body.length > 50 ? 50 : body.length)}...');

          return referralCode;
        }
      }

      print('ℹ️ SMS\'lerde ZIRA kodu bulunamadı - manuel giriş yapılacak');
      return null;

    } catch (e, stackTrace) {
      print('❌ SMS okuma hatası: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// SMS okuma izni iste (using android_sms_reader package)
  Future<bool> _requestSmsPermission() async {
    try {
      print('📋 SMS izni isteniyor...');

      // Use android_sms_reader's permission request
      final hasPermission = await _smsReader.requestPermissions();

      if (hasPermission) {
        print('✅ SMS izni verildi');
        return true;
      } else {
        print('⚠️ SMS izni reddedildi');
        return false;
      }
    } catch (e) {
      print('❌ SMS izni hatası: $e');
      return false;
    }
  }

  /// Test için: Son SMS'leri listele (debug)
  Future<void> debugListRecentSms() async {
    try {
      final messages = await _smsReader.fetchMessages(
        type: SmsType.inbox,
        count: 5,
      );

      print('📱 Son ${messages.length} SMS:');
      for (var i = 0; i < messages.length; i++) {
        final msg = messages[i];
        print('  ${i + 1}. ${msg.sender}: ${msg.body?.substring(0, 30)}...');
      }
    } catch (e) {
      print('❌ Debug SMS listesi hatası: $e');
    }
  }
}
