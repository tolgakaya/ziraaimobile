import '../models/usage_status.dart';

/// Mock subscription service for testing 403 error handling
class MockSubscriptionService {

  /// Get mock usage status - can simulate different scenarios
  static UsageStatus getMockUsageStatus({String scenario = 'daily_exceeded'}) {
    switch (scenario) {
      case 'daily_exceeded':
        return UsageStatus(
          dailyLimit: 5,
          dailyUsed: 5,
          dailyRemaining: 0,
          dailyResetTime: '2025-09-16T00:00:00',
          monthlyLimit: 200,
          monthlyUsed: 45,
          monthlyRemaining: 155,
          subscriptionTier: 'Premium',
          nextRenewalDate: '2025-10-01',
          hasActiveSubscription: true,
        );

      case 'monthly_exceeded':
        return UsageStatus(
          dailyLimit: 5,
          dailyUsed: 2,
          dailyRemaining: 3,
          dailyResetTime: '2025-09-16T00:00:00',
          monthlyLimit: 200,
          monthlyUsed: 200,
          monthlyRemaining: 0,
          subscriptionTier: 'Premium',
          nextRenewalDate: '2025-10-01',
          hasActiveSubscription: true,
        );

      case 'no_subscription':
        return UsageStatus(
          dailyLimit: 0,
          dailyUsed: 0,
          dailyRemaining: 0,
          dailyResetTime: '2025-09-16T00:00:00',
          monthlyLimit: 0,
          monthlyUsed: 0,
          monthlyRemaining: 0,
          subscriptionTier: 'Free',
          nextRenewalDate: '',
          hasActiveSubscription: false,
        );

      case 'basic_active':
        return UsageStatus(
          dailyLimit: 3,
          dailyUsed: 1,
          dailyRemaining: 2,
          dailyResetTime: '2025-09-16T00:00:00',
          monthlyLimit: 50,
          monthlyUsed: 15,
          monthlyRemaining: 35,
          subscriptionTier: 'Basic',
          nextRenewalDate: '2025-10-01',
          hasActiveSubscription: true,
        );

      default:
        return getMockUsageStatus(scenario: 'daily_exceeded');
    }
  }

  /// Get mock subscription tiers
  static List<SubscriptionTier> getMockSubscriptionTiers() {
    return [
      SubscriptionTier(
        id: 1,
        name: 'basic',
        displayName: 'Temel Plan',
        description: 'Bireysel çiftçiler için ideal',
        dailyRequestLimit: 3,
        monthlyRequestLimit: 50,
        monthlyPrice: 99.99,
        currency: 'TRY',
        isActive: true,
        features: [
          '3 günlük analiz',
          '50 aylık analiz',
          'Temel raporlar',
          'Email destek'
        ],
      ),
      SubscriptionTier(
        id: 2,
        name: 'premium',
        displayName: 'Premium Plan',
        description: 'Küçük işletmeler için',
        dailyRequestLimit: 10,
        monthlyRequestLimit: 200,
        monthlyPrice: 299.99,
        currency: 'TRY',
        isActive: true,
        features: [
          '10 günlük analiz',
          '200 aylık analiz',
          'Detaylı raporlar',
          'Öncelikli destek',
          'Geçmiş analiz erişimi'
        ],
      ),
      SubscriptionTier(
        id: 3,
        name: 'enterprise',
        displayName: 'Kurumsal Plan',
        description: 'Büyük işletmeler için',
        dailyRequestLimit: 50,
        monthlyRequestLimit: 1000,
        monthlyPrice: 999.99,
        currency: 'TRY',
        isActive: true,
        features: [
          '50 günlük analiz',
          '1000 aylık analiz',
          'Kapsamlı raporlar',
          '7/24 destek',
          'API erişimi',
          'Özel entegrasyonlar'
        ],
      ),
    ];
  }

  /// Get mock user subscription
  static UserSubscription getMockUserSubscription({bool hasSubscription = true}) {
    if (!hasSubscription) {
      return UserSubscription(
        id: 0,
        subscriptionTierId: 0,
        tierName: 'Free',
        status: 'inactive',
        startDate: '',
        endDate: '',
        autoRenew: false,
        isActive: false,
      );
    }

    return UserSubscription(
      id: 1,
      subscriptionTierId: 2,
      tierName: 'Premium',
      status: 'active',
      startDate: '2025-09-01T00:00:00',
      endDate: '2025-10-01T00:00:00',
      autoRenew: true,
      isActive: true,
    );
  }

  /// Mock sponsor code validation
  static Future<bool> validateSponsorCode(String code) async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 1));

    // Mock validation logic
    const validCodes = ['DEMO2025', 'FARMER123', 'PREMIUM30'];
    return validCodes.contains(code.toUpperCase());
  }

  /// Mock sponsor code redemption
  static Future<bool> redeemSponsorCode(String code) async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 2));

    // Validate first
    final isValid = await validateSponsorCode(code);
    if (!isValid) return false;

    // Mock successful redemption
    return true;
  }

  /// Get time until next reset (for daily quota)
  static String getTimeUntilDailyReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final difference = tomorrow.difference(now);

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    return '${hours}h ${minutes}m';
  }

  /// Get days until subscription renewal
  static int getDaysUntilRenewal(String renewalDate) {
    try {
      final renewal = DateTime.parse(renewalDate);
      final now = DateTime.now();
      return renewal.difference(now).inDays;
    } catch (e) {
      return 0;
    }
  }
}