# Sponsorluk SMS Redemption - Uçtan Uca Test Kılavuzu

## Hazırlık Adımları

### Gereksinimler
- Android Emulator (API 29+) veya fiziksel cihaz
- ADB (Android Debug Bridge) kurulu
- Flutter SDK kurulu
- ZiraAI Mobile uygulaması (staging flavor)

### Emulator Kontrolü
```bash
# Emulator'ün çalıştığını kontrol et
adb devices

# Beklenen çıktı:
# List of devices attached
# emulator-5554    device
```

## Senaryo 1: Uygulama Kurulu + Kullanıcı Giriş Yapmış

**Durum**: Kullanıcı uygulamayı yüklemiş ve giriş yapmış durumda

### Adım 1: Uygulamayı Çalıştır
```bash
cd ziraai_mobile
flutter run lib/main.dart -d emulator-5554 --flavor staging
```

### Adım 2: Giriş Yap
1. Uygulamada mevcut bir kullanıcı ile giriş yap
2. Dashboard'a ulaştığından emin ol

### Adım 3: SMS Gönder (Backend'den gönderilmiş gibi simüle et)
```bash
# Test SMS'i gönder
adb emu sms send 5551234567 "🎁 Chimera Tarım A.Ş. size Medium paketi hediye etti! Sponsorluk Kodunuz: AGRI-2025-52834B45. Uygulamayı indirin: https://play.google.com/store/apps/details?id=com.ziraai.app"
```

### Adım 4: SMS Loglarını İzle
```bash
# Flutter loglarını izle
adb logcat | grep -E "SMS|Sponsorship|AGRI"
```

### Beklenen Sonuç:
1. ✅ SMS alındığında log'da görülmeli:
   ```
   📱 SMS Listener: New SMS received from 5551234567
   ✅ SMS Listener: Extracted sponsorship code: AGRI-TEST123
   💾 SMS Listener: Stored pending code: AGRI-TEST123
   ```

2. ✅ Uygulama zaten açık ve kullanıcı giriş yapmış olduğu için:
   - Otomatik olarak `SponsorshipRedemptionScreen` açılmalı
   - Kod alanı otomatik doldurulmuş olmalı: `AGRI-TEST123`
   - Yeşil doğrulama işareti görünmeli

3. ✅ "Kodu Kullan" butonuna basınca:
   - API'ye istek gitmeli: `POST /api/v1/sponsorship/redeem`
   - Başarılı dialog görünmeli
   - Pending code SharedPreferences'dan silinmeli

---

## Senaryo 2: Uygulama Kurulu + Kullanıcı Giriş Yapmamış

**Durum**: Kullanıcı uygulamayı yüklemiş ama henüz giriş yapmamış

### Adım 1: Uygulamayı Temiz Başlat (Logout)
```bash
# Uygulamayı durdur
adb shell am force-stop com.ziraai.app.staging

# Uygulama verilerini temizle (logout için)
adb shell pm clear com.ziraai.app.staging

# Uygulamayı yeniden çalıştır
cd ziraai_mobile
flutter run lib/main.dart -d emulator-5554 --flavor staging
```

### Adım 2: SMS Gönder (Giriş yapmadan)
```bash
# Test SMS'i gönder
adb emu sms send 5551234567 "🎁 Chimera Tarım A.Ş. size Premium paketi hediye etti! Sponsorluk Kodunuz: AGRI-TEST456. Uygulamayı indirin: https://play.google.com/store/apps/details?id=com.ziraai.app"
```

### Adım 3: SMS Loglarını İzle
```bash
adb logcat | grep -E "SMS|Sponsorship|AGRI|pending"
```

### Beklenen Sonuç:
1. ✅ SMS alındığında log'da görülmeli:
   ```
   📱 SMS Listener: New SMS received from 5551234567
   ✅ SMS Listener: Extracted sponsorship code: AGRI-TEST456
   💾 SMS Listener: Stored pending code: AGRI-TEST456
   ```

2. ✅ Kullanıcı giriş yapmadığı için:
   - Kod SharedPreferences'a kaydedilir
   - Hiçbir ekran açılmaz (kullanıcı henüz login değil)

### Adım 4: Giriş Yap
1. Login ekranında telefon numarası gir
2. OTP kodunu gir
3. Başarılı giriş yap

### Adım 5: Post-Login Hook Kontrolü
```bash
# Login sonrası logları izle
adb logcat | grep -E "Login|pending|Redemption"
```

### Beklenen Sonuç:
1. ✅ Login başarılı olduktan sonra log'da görülmeli:
   ```
   [Login] 🔍 Checking for pending sponsorship code...
   [Login] ✅ Found pending code: AGRI-TEST456
   ```

2. ✅ Otomatik olarak `SponsorshipRedemptionScreen` açılmalı:
   - Kod alanı otomatik doldurulmuş: `AGRI-TEST456`
   - SnackBar görünmeli: "Sponsorluk kodu bulundu! SMS'den kod otomatik dolduruldu."
   - Yeşil doğrulama işareti

3. ✅ "Kodu Kullan" butonuna basınca redemption tamamlanmalı

---

## Senaryo 3: Uygulama Kurulu Değil (Deferred Deep Linking)

**Durum**: Kullanıcı uygulamayı henüz yüklememiş, SMS aldıktan sonra yükleyecek

### Adım 1: Uygulamayı Kaldır
```bash
# Uygulamayı tamamen kaldır
adb uninstall com.ziraai.app.staging
```

### Adım 2: SMS Gönder (Uygulama yüklü değilken)
```bash
# Test SMS'i gönder
adb emu sms send 5551234567 "🎁 Chimera Tarım A.Ş. size XL paketi hediye etti! Sponsorluk Kodunuz: SPONSOR-XYZ789. Uygulamayı indirin: https://play.google.com/store/apps/details?id=com.ziraai.app"
```

### Adım 3: Uygulamayı Yükle ve Çalıştır
```bash
# APK'yı build et
cd ziraai_mobile
flutter build apk --debug --flavor staging

# APK'yı yükle
adb install build/app/outputs/flutter-apk/app-staging-debug.apk

# Uygulamayı başlat
adb shell monkey -p com.ziraai.app.staging -c android.intent.category.LAUNCHER 1
```

### Adım 4: SMS İnbox Taramasını İzle
```bash
# Uygulama başladıktan sonra logları izle
adb logcat | grep -E "SMS|Inbox|SPONSOR|pending"
```

### Beklenen Sonuç:
1. ✅ Uygulama ilk açılışta son 7 gün içindeki SMS'leri taramalı:
   ```
   📱 SMS Listener: Initializing...
   📱 SMS Listener: Permission granted, starting SMS listener
   📱 SMS Listener: Checking recent SMS messages...
   📱 SMS Listener: Found 1 messages in last 7 days
   ✅ SMS Listener: Extracted sponsorship code: SPONSOR-XYZ789
   💾 SMS Listener: Stored pending code: SPONSOR-XYZ789
   ```

2. ✅ Kullanıcı henüz giriş yapmadığı için:
   - Kod SharedPreferences'a kaydedilir
   - Login ekranı görünür

### Adım 5: Kayıt Ol veya Giriş Yap
1. Yeni kullanıcı kaydı yap veya mevcut kullanıcı ile giriş yap
2. Başarılı authentication sonrası

### Adım 6: Post-Login Hook Kontrolü
```bash
adb logcat | grep -E "Login|Found pending|Redemption"
```

### Beklenen Sonuç:
1. ✅ Login sonrası pending code bulunmalı:
   ```
   [Login] 🔍 Checking for pending sponsorship code...
   [Login] ✅ Found pending code: SPONSOR-XYZ789
   ```

2. ✅ Otomatik redemption ekranı açılmalı ve kod doldurulmalı

---

## Senaryo 4: Deep Link ile Test (Bonus)

**Durum**: Backend'den gelen deep link ile doğrudan redemption ekranına gitme

### Test Komutu
```bash
# Deep link ile uygulamayı aç
adb shell am start -a android.intent.action.VIEW \
  -d "https://ziraai-api-sit.up.railway.app/redeem/AGRI-DEEPLINK99" \
  com.ziraai.app.staging
```

### Beklenen Sonuç:
1. ✅ Uygulama açılır ve deep link işlenir:
   ```
   📱 DeepLink: Incoming link received: https://ziraai-api-sit.up.railway.app/redeem/AGRI-DEEPLINK99
   ✅ DeepLink: Extracted sponsorship code from https: AGRI-DEEPLINK99
   ```

2. ✅ Eğer kullanıcı giriş yapmışsa:
   - Doğrudan `SponsorshipRedemptionScreen` açılır
   - Kod otomatik doldurulur: `AGRI-DEEPLINK99`

3. ✅ Eğer kullanıcı giriş yapmamışsa:
   - Login ekranı görünür
   - Kod SharedPreferences'a kaydedilir
   - Login sonrası redemption ekranı açılır

---

## Senaryo 5: Kod Süresi Dolmuş (7 Gün Üzeri)

**Durum**: SMS'ten 7 günden eski kod varsa otomatik silinmeli

### Test için Manuel SharedPreferences Manipülasyonu

#### Adım 1: Eski Tarihli Kod Ekle
```bash
# Uygulamayı durdur
adb shell am force-stop com.ziraai.app.staging

# SharedPreferences dosyasını bul
adb shell run-as com.ziraai.app.staging ls /data/data/com.ziraai.app.staging/shared_prefs/

# Not: Bu senaryoyu test etmek için kodu değiştirip 7 günlük süreyi 1 dakikaya düşürebiliriz
```

#### Alternatif: Kod Değişikliği ile Test
`lib/core/services/sponsorship_sms_listener.dart` dosyasında:
```dart
// Test için geçici değişiklik (SADECE TEST İÇİN!)
if (age.inDays > 7) {  // Bunu age.inSeconds > 60 yap (1 dakika)
  await clearPendingCode();
  return null;
}
```

### Beklenen Sonuç:
✅ Eski kod otomatik silinir ve redemption ekranı açılmaz

---

## Debug ve Sorun Giderme

### Logları Filtreleme
```bash
# Sadece sponsorship ile ilgili logları göster
adb logcat | grep -E "SMS|Sponsorship|Redemption|AGRI|SPONSOR"

# Hata loglarını göster
adb logcat | grep -E "ERROR|Exception|Failed"

# Specific component logları
adb logcat | grep "SponsorshipSmsListener"
```

### SharedPreferences Kontrolü
```bash
# Pending code'u kontrol et
adb shell run-as com.ziraai.app.staging cat /data/data/com.ziraai.app.staging/shared_prefs/FlutterSharedPreferences.xml | grep pending_sponsorship_code
```

### Uygulamayı Tamamen Sıfırla
```bash
# Tüm verileri temizle
adb shell pm clear com.ziraai.app.staging

# Uygulamayı kaldır ve yeniden yükle
adb uninstall com.ziraai.app.staging
cd ziraai_mobile
flutter run --flavor staging
```

---

## Test Sonuçları Kontrol Listesi

### ✅ Senaryo 1: Uygulama Kurulu + Giriş Yapmış
- [ ] SMS alındığında log görünüyor
- [ ] Kod SharedPreferences'a kaydediliyor
- [ ] Redemption ekranı otomatik açılıyor
- [ ] Kod otomatik doldurulmuş
- [ ] Redemption başarılı
- [ ] Pending code siliniyor

### ✅ Senaryo 2: Uygulama Kurulu + Giriş Yapmamış
- [ ] SMS alındığında kod kaydediliyor
- [ ] Login ekranı görünüyor
- [ ] Login sonrası pending code bulunuyor
- [ ] Redemption ekranı post-login açılıyor
- [ ] SnackBar görünüyor
- [ ] Redemption başarılı

### ✅ Senaryo 3: Uygulama Kurulu Değil
- [ ] Uygulama ilk açılışta inbox taraması yapıyor
- [ ] 7 gün içindeki SMS'lerden kod bulunuyor
- [ ] Kod SharedPreferences'a kaydediliyor
- [ ] Kayıt/giriş sonrası redemption ekranı açılıyor
- [ ] Kod otomatik doldurulmuş
- [ ] Redemption başarılı

### ✅ Senaryo 4: Deep Link
- [ ] Deep link URL işleniyor
- [ ] Sponsorship code extract ediliyor
- [ ] Eğer logged in: doğrudan redemption ekranı
- [ ] Eğer not logged in: kod kaydediliyor, post-login açılıyor

### ✅ Senaryo 5: Eski Kod
- [ ] 7 günden eski kod otomatik siliniyor
- [ ] Redemption ekranı açılmıyor
- [ ] Log'da temizleme mesajı görünüyor

---

## API Backend Testleri

### Redemption API Testi
```bash
# Test için cURL komutu (Token gerekli)
curl -X POST "https://ziraai-api-sit.up.railway.app/api/v1/sponsorship/redeem" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"code": "AGRI-TEST123"}'
```

### Validation API Testi
```bash
curl -X GET "https://ziraai-api-sit.up.railway.app/api/v1/sponsorship/validate/AGRI-TEST123" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## Notlar

1. **SMS Format**: Backend'den gelen gerçek SMS formatı:
   ```
   🎁 [Sponsor Şirket Adı] size [Paket Tier] paketi hediye etti!
   Sponsorluk Kodunuz: AGRI-XXXXXX
   Uygulamayı indirin: https://play.google.com/store/apps/details?id=com.ziraai.app
   ```

2. **Kod Formatları**:
   - `AGRI-[A-Z0-9]+` (Tarım sponsorlukları)
   - `SPONSOR-[A-Z0-9]+` (Genel sponsorluklar)

3. **Zaman Penceresi**: 7 gün (deferred deep linking için)

4. **Permissions**: SMS ve bildirim izinleri gerekli, uygulama otomatik istiyor

5. **Test Ortamı**: Staging flavor kullanılıyor, production için flavor değiştir

---

## Hızlı Test Komutları (Hepsi Bir Arada)

```bash
# 1. Senaryo 1 - Hızlı test
cd ziraai_mobile && flutter run lib/main.dart -d emulator-5554 --flavor staging &
sleep 10
adb emu sms send 5551234567 "🎁 Test: AGRI-TEST123"
adb logcat | grep "AGRI-TEST123"

# 2. Senaryo 3 - Deferred deep linking
adb uninstall com.ziraai.app.staging
adb emu sms send 5551234567 "🎁 Test: SPONSOR-XYZ789"
cd ziraai_mobile && flutter run lib/main.dart -d emulator-5554 --flavor staging
# Login yap ve pending code kontrolünü izle

# 3. Deep link testi
adb shell am start -a android.intent.action.VIEW \
  -d "https://ziraai-api-sit.up.railway.app/redeem/AGRI-LINK999" \
  com.ziraai.app.staging
```

---

**Test Dokümanı Versiyonu**: 1.0
**Oluşturulma Tarihi**: 2025-10-14
**Feature Branch**: `feature/sponsorship-code-distribution-enhancements`
