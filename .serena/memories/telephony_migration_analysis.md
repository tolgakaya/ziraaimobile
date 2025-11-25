# Telephony Plugin Migration Analysis - Session 2025-01-24

## Problem Summary
**Critical Issue**: Camera permission request crashes app with "Reply already submitted" error
**Root Cause**: telephony plugin v0.2.0's SmsMethodCallHandler intercepts ALL permission callbacks globally, conflicting with permission_handler plugin

## Crash Details
```
E/AndroidRuntime: Caused by: java.lang.IllegalStateException: Reply already submitted
at com.shounakmulay.telephony.sms.SmsMethodCallHandler.execute(SmsMethodCallHandler.kt:169)
at com.shounakmulay.telephony.sms.SmsMethodCallHandler.onRequestPermissionsResult(SmsMethodCallHandler.kt:374)
```

## Critical SMS Business Flows (MUST NOT BREAK)
1. SMS referral code extraction (24-hour history scan)
2. SMS sponsorship code detection (real-time listening, 7-day scan)
3. SMS dealer invitation tokens (pattern: DEALER-[a-f0-9]{32})
4. Background SMS monitoring

## Recommended Solution: android_sms_reader

### Why This Package
- **Isolated Permission System**: Uses `SmsReader.requestPermissions()` - won't conflict with permission_handler
- **Feature Complete**: Inbox reading, real-time streaming, background support
- **Recently Updated**: July 2024 (actively maintained)
- **No MainActivity Changes**: Drop-in replacement, no FragmentActivity requirement
- **No Documented Conflicts**: Research found no issues with other plugins

### Feature Mapping

| Feature | telephony (old) | android_sms_reader (new) |
|---------|----------------|-------------------------|
| Inbox Reading | `telephony.getInboxSms()` | `SmsReader.fetchMessages(type: SmsType.inbox)` |
| Real-time Streaming | `telephony.listenIncomingSms()` | `SmsReader.observeIncomingMessages().listen()` |
| Permission Request | `telephony.requestSmsPermissions` | `SmsReader.requestPermissions()` |
| Background Listening | `listenInBackground: true` | Stream works in background |
| Date Filtering | `SmsFilter.where(SmsColumn.DATE)` | `start: DateTime` parameter |

### Migration Impact

**Files to Update** (4 files):
1. `lib/core/services/sms_referral_service.dart` - Referral code extraction
2. `lib/core/services/sponsorship_sms_listener.dart` - Sponsorship code detection
3. `lib/core/services/dealer_invitation_sms_listener.dart` - Dealer invitation tokens
4. `lib/features/dealer/data/sms_token_scanner.dart` - Token scanning

**Estimated Time**: 1-1.5 hours
**Risk Level**: LOW (isolated change, no MainActivity modifications)

### Alternative Packages Evaluated

**sms_advanced**:
- ❌ Requires FragmentActivity change (MainActivity modification)
- ❓ Unknown permission conflict risk
- ✅ Feature-complete

**flutter_sms**:
- ❌ Has documented conflict with permission packages (GitHub Issue #37)
- Not recommended

**sms_receiver**:
- ❌ Limited to "expected" SMS only (5-minute timeout)
- ❌ Cannot scan inbox history (7-day scan required for dealer tokens)
- Not suitable for our use case

## Expected Outcome
- ✅ Camera permission works without crashes
- ✅ All 4 SMS business flows continue working
- ✅ No permission conflicts between plugins
- ✅ Cleaner, more modern API

## User Decision
User explicitly rejected forking telephony package: "hayır fork istemiyorum başka bir paket yok mu bunun için"
Recommended android_sms_reader as the best alternative - awaiting approval to proceed with migration.
