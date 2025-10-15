# Hızlı Test: SMS Sponsorship Redemption

## Test Hazırlığı

### 1. Uygulamayı Çalıştır
```bash
cd ziraai_mobile
flutter run lib/main.dart -d emulator-5554 --flavor staging
```

### 2. Ayrı Terminal'de Logları İzle
```bash
adb logcat | grep -E "Sponsorship|AGRI|OTP|pending"
```

---

## Senaryo 1: En Hızlı Test (Uygulama Açık + Login)

### Adımlar:
1. **Uygulamada login yap**
   - Telefon: `05411111112`
   - OTP kodunu gir (log'da görünecek)

2. **Dashboard'dayken SMS gönder**
   ```bash
   adb emu sms send 5551234567 "🎁 Chimera Tarım A.Ş. size Medium paketi hediye etti! Sponsorluk Kodunuz: AGRI-TEST123. Uygulamayı indirin: https://play.google.com/store/apps/details?id=com.ziraai.app"
   ```

3. **Beklenen Sonuç:**
   - Log'da görülmeli:
     ```
     [SponsorshipSMS] 📱 New SMS received from 5551234567
     [SponsorshipSMS] ✅ Sponsorship code extracted: AGRI-TEST123
     [SponsorshipSMS] 💾 Code saved to storage: AGRI-TEST123
     ```
   - **SORUN**: Şu anda real-time navigation çalışmıyor (app context eksik)
   - Kod SharedPreferences'a kaydedilir
   - Bir sonraki login'de otomatik açılır

---

## Senaryo 2: Deferred Deep Linking (Gerçek Dünya)

Bu senaryoda kullanıcı önce SMS alıyor, sonra uygulamayı yükleyip login oluyor.

### Adım 1: Uygulamayı Kapat ve SMS Gönder
```bash
# Uygulamayı kapat
adb shell am force-stop com.ziraai.app.staging

# SMS gönder (uygulama kapalıyken)
adb emu sms send 5551234567 "🎁 Test Sponsor size Premium paketi hediye etti! Sponsorluk Kodunuz: SPONSOR-XYZ789"
```

### Adım 2: Uygulamayı Aç ve Login Yap
```bash
# Uygulamayı tekrar başlat
adb shell monkey -p com.ziraai.app.staging -c android.intent.category.LAUNCHER 1
```

1. Uygulama açılacak
2. Login ekranına git
3. Telefon numarası gir: `05411111112`
4. OTP kodunu gir

### Adım 3: Beklenen Sonuçlar

**Log'da Görülecekler:**
```
[SponsorshipSMS] 🚀 Initializing sponsorship SMS listener...
[SponsorshipSMS] ✅ SMS permission already granted
[SponsorshipSMS] 👂 Background SMS listener started
[SponsorshipSMS] 🔍 Checking recent SMS (last 7 days)
[SponsorshipSMS] ✅ Found sponsorship code in recent SMS
[SponsorshipSMS] ✅ Sponsorship code extracted: SPONSOR-XYZ789
[SponsorshipSMS] 💾 Code saved to storage: SPONSOR-XYZ789
```

**OTP Verification Sonrası:**
```
[OTP] 🔍 Checking for pending sponsorship code...
[OTP] ✅ Found pending code: SPONSOR-XYZ789
[OTP] Navigating to redemption screen...
```

**Ekranda Görülecekler:**
1. Dashboard yerine önce **Redemption Screen** açılır
2. Kod alanı otomatik doldurulmuş: `SPONSOR-XYZ789`
3. Yeşil SnackBar: "Sponsorluk kodu bulundu! SMS'den kod otomatik dolduruldu."
4. "Kodu Kullan" butonuna bas
5. Backend'e gönderilir ve sponsorluk aktive edilir

---

## Sorun Giderme

### Log'da "0 recent SMS" görünüyorsa:
SMS'ler emulator'de kayıtlı değil. Manuel SMS gönder:
```bash
# Önce SMS gönder
adb emu sms send 5551234567 "🎁 Sponsor Kodu: AGRI-QUICK123"

# Sonra uygulamayı başlat
flutter run lib/main.dart -d emulator-5554 --flavor staging
```

### SMS Listener hatası (onBackgroundMessage):
✅ **FIXED!** Artık `onBackgroundMessage` callback'i var.

### Login sonrası kod kontrolü yapılmıyor:
✅ **FIXED!** `otp_verification_screen.dart` artık `_checkPendingSponsorshipCode()` çağırıyor.

### SharedPreferences'ı Manuel Kontrol:
```bash
adb shell run-as com.ziraai.app.staging cat /data/data/com.ziraai.app.staging/shared_prefs/FlutterSharedPreferences.xml | grep pending_sponsorship_code
```

---

## Hızlı Debug Komutları

```bash
# 1. Log filtreleme (sadece sponsorship)
adb logcat | grep "Sponsorship"

# 2. Log filtreleme (geniş)
adb logcat | grep -E "Sponsorship|AGRI|SPONSOR|OTP|pending"

# 3. Uygulamayı temizle ve yeniden başlat
adb shell pm clear com.ziraai.app.staging
flutter run lib/main.dart -d emulator-5554 --flavor staging

# 4. SMS gönder ve hemen log izle
adb emu sms send 5551234567 "Kod: AGRI-TEST999" && adb logcat | grep "AGRI"
```

---

## Kritik Noktalar

### ✅ Düzeltildi:
1. `onBackgroundMessage` callback eklendi
2. OTP verification screen'de post-login check eklendi
3. Background SMS listener çalışıyor

### ⚠️ Bilinen Sınırlamalar:
1. **Real-time navigation**: SMS alındığında uygulama açıksa, kod kaydediliyor ama ekran otomatik açılmıyor
   - **Neden**: App context'e erişim yok (navigation için context gerekli)
   - **Çözüm**: Bir sonraki login'de otomatik açılır (deferred deep linking)

2. **Emulator SMS Limiti**: Emulator'de çok fazla SMS gönderirsen inbox dolu olabilir

### 🎯 Başarı Kriterleri:
- [x] SMS alındığında kod extract ediliyor
- [x] SharedPreferences'a kaydediliyor
- [x] Login sonrası pending code bulunuyor
- [x] Redemption ekranı otomatik açılıyor
- [x] Kod otomatik doldurulmuş
- [x] SnackBar görünüyor
- [ ] Real-time navigation (app açıkken SMS gelirse - future improvement)

---

**Test Durumu**: ✅ **READY FOR TESTING**
**Son Güncelleme**: 2025-10-14
**Branch**: `feature/sponsorship-code-distribution-enhancements`
