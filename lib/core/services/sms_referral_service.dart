import 'package:android_sms_reader/android_sms_reader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SMS'lerden referral kodu çıkarmak için servis
/// İlk uygulama açılışında kullanılır (deferred deep linking)
class SmsReferralService {
  static const String _smsCheckedKey = 'sms_referral_checked';

  /// SMS'lerden ZIRA referral kodunu bul
  /// Son 24 saat içindeki mesajları tarar
  /// SADECE BİR KEZ ÇALIŞIR - sonraki açılışlarda atlanır
  Future<String?> extractReferralFromSms() async {
    try {
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

      // 3. Son 24 saat filtresi (timestamp olarak)
      final yesterdayTimestamp = DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch;

      // 4. Her SMS'i kontrol et
      for (var message in messages) {
        // Tarih kontrolü (24 saatten eski mesajları atla)
        // message.date is int (milliseconds since epoch)
        if (message.date < yesterdayTimestamp) {
          print('ℹ️ 24 saatten eski mesajlara ulaşıldı, durduruldu');
          break;
        }

        final body = message.body;

        // ZIRA formatını ara (regex)
        final regex = RegExp(r'ZIRA-[A-Z0-9]+');
        final match = regex.firstMatch(body);

        if (match != null) {
          final referralCode = match.group(0)!;

          print('✅ SMS\'den referral kod bulundu!');
          print('   Kod: $referralCode');
          print('   Gönderen: ${message.address}');
          print('   Tarih: ${message.date}');
          print('   Mesaj önizleme: ${body.substring(0, body.length > 50 ? 50 : body.length)}...');

          // Mark as checked to prevent future scans
          await prefs.setBool(_smsCheckedKey, true);

          return referralCode;
        }
      }

      print('ℹ️ SMS\'lerde ZIRA kodu bulunamadı - manuel giriş yapılacak');

      // Mark as checked even if no code found
      await prefs.setBool(_smsCheckedKey, true);

      return null;

    } catch (e, stackTrace) {
      print('❌ SMS okuma hatası: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// SMS okuma izni iste (using permission_handler package)
  Future<bool> _requestSmsPermission() async {
    try {
      print('📋 SMS izni isteniyor...');

      // Check current permission status
      final smsStatus = await Permission.sms.status;

      // If already granted, return true
      if (smsStatus.isGranted) {
        print('✅ SMS izni zaten verilmiş');
        return true;
      }

      // If permanently denied, can't request
      if (smsStatus.isPermanentlyDenied) {
        print('🚨 SMS izni kalıcı olarak reddedilmiş');
        return false;
      }

      // Request permission - will show dialog
      final newStatus = await Permission.sms.request();

      if (newStatus.isGranted) {
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
      final messages = await AndroidSMSReader.fetchMessages(
        type: AndroidSMSType.inbox,
        count: 5,
      );

      print('📱 Son ${messages.length} SMS:');
      for (var i = 0; i < messages.length; i++) {
        final msg = messages[i];
        print('  ${i + 1}. ${msg.address}: ${msg.body.substring(0, msg.body.length > 30 ? 30 : msg.body.length)}...');
      }
    } catch (e) {
      print('❌ Debug SMS listesi hatası: $e');
    }
  }
}
