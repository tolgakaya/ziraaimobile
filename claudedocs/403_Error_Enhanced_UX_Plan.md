# 403 Forbidden Error - Enhanced UX Solution Plan

## 🎯 **CRITICAL PLAN - DO NOT LOSE**

### **Problem:**
Users get generic "Unexpected error during analysis submission" when they hit 403 due to:
- Daily usage limit exceeded (e.g., 5/5 used today)
- Monthly package limit exceeded (e.g., 200/200 used this month)
- No active subscription

### **✅ Available API Endpoints:**

#### 📊 **Subscription & Usage:**
- `GET /api/v1/subscriptions/my-subscription` - Current subscription details
- `GET /api/v1/subscriptions/usage-status` - **Daily + Monthly** remaining usage
- `GET /api/v1/subscriptions/tiers` - Available upgrade options

#### 🎁 **Sponsorship (Farmer Side):**
- `POST /api/v1/sponsorship/redeem` - Use sponsor code
- `GET /api/v1/sponsorship/validate/{code}` - Validate code

#### 💳 **Upgrade:**
- `POST /api/v1/subscriptions/subscribe` - Purchase subscription upgrade

### **❌ NOT Available/Usable:**
- `/api/v1/sponsorship/profile` - Only for sponsor companies
- `/api/v1/sponsorship/my-sponsor` - Mock, not implemented

---

## 🎯 **403 Error Scenarios:**

### **1. Daily Limit Exceeded:**
```
"Günlük analiz hakkınız dolmuştur 📅
Bugün: 5/5 analiz kullanıldı
Yarın saat 00:00'da yenilenecek
Paketiniz: Premium (150/200 aylık)"
```

### **2. Monthly Package Exceeded:**
```
"Aylık analiz hakkınız dolmuştur 📊
Bu ay: 200/200 analiz kullanıldı
Paketiniz: Premium
15 gün sonra yenilenecek"
```

### **3. No Subscription:**
```
"Analiz yapmak için abonelik gerekli 🔒
Mevcut paket: Ücretsiz (0 analiz)
Sponsor kodunuz varsa girebilirsiniz"
```

---

## 🏗️ **Implementation Plan:**

### **Phase 1: Mock Implementation**
1. **QuotaExceededException** - Detect 403 errors
2. **Mock Usage Status** models and service
3. **Subscription Status Screen** - Smart error display
4. **Sponsor Code Dialog** - Code input functionality

### **Phase 2: Real API Integration**
1. **Usage Status API** integration (`/api/v1/subscriptions/usage-status`)
2. **Subscription API** integration (`/api/v1/subscriptions/my-subscription`)
3. **Sponsor Redeem API** integration (`/api/v1/sponsorship/redeem`)
4. **Tier API** for upgrade options (`/api/v1/subscriptions/tiers`)

---

## 📱 **Usage Status API Response Structure:**
```json
{
  "dailyLimit": 5,
  "dailyUsed": 5,
  "dailyRemaining": 0,
  "dailyResetTime": "2025-09-16T00:00:00",
  "monthlyLimit": 200,
  "monthlyUsed": 45,
  "monthlyRemaining": 155,
  "subscriptionTier": "Premium",
  "nextRenewalDate": "2025-10-01"
}
```

## 🎨 **Smart Action Buttons Logic:**
- **Daily limit exceeded:** "Yarın tekrar dene" + "Upgrade" + "Sponsor Kodu"
- **Monthly limit exceeded:** "Upgrade" + "Sponsor Kodu"
- **No subscription:** "Abonelik Al" + "Sponsor Kodu"

## 🔄 **User Flow:**
```
Plant Analysis Request (403)
    ↓
Usage Status API Call
    ↓
📱 Smart Error Message Display
    ├─ 🚀 "Abonelik Yükselt" → Tier Selection
    ├─ 🎁 "Sponsor Kodu Gir" → Code Input Dialog
    └─ ⏰ "X saat sonra tekrar dene" → Timer Display
```

---

## 📝 **Implementation Priority:**
1. **Mock first** - Quick implementation and testing
2. **Real API** - Production-ready integration
3. **Error handling** - Comprehensive exception management
4. **UX polish** - Smooth transitions and feedback

**Status:** Ready for implementation - Mock phase first, then real API integration.