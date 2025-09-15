/// User's current usage status for plant analysis
class UsageStatus {
  final int dailyLimit;
  final int dailyUsed;
  final int dailyRemaining;
  final String dailyResetTime;
  final int monthlyLimit;
  final int monthlyUsed;
  final int monthlyRemaining;
  final String subscriptionTier;
  final String nextRenewalDate;
  final bool hasActiveSubscription;

  UsageStatus({
    required this.dailyLimit,
    required this.dailyUsed,
    required this.dailyRemaining,
    required this.dailyResetTime,
    required this.monthlyLimit,
    required this.monthlyUsed,
    required this.monthlyRemaining,
    required this.subscriptionTier,
    required this.nextRenewalDate,
    required this.hasActiveSubscription,
  });

  factory UsageStatus.fromJson(Map<String, dynamic> json) {
    return UsageStatus(
      dailyLimit: json['dailyLimit'] ?? 0,
      dailyUsed: json['dailyUsed'] ?? 0,
      dailyRemaining: json['dailyRemaining'] ?? 0,
      dailyResetTime: json['dailyResetTime'] ?? '',
      monthlyLimit: json['monthlyLimit'] ?? 0,
      monthlyUsed: json['monthlyUsed'] ?? 0,
      monthlyRemaining: json['monthlyRemaining'] ?? 0,
      subscriptionTier: json['subscriptionTier'] ?? 'Free',
      nextRenewalDate: json['nextRenewalDate'] ?? '',
      hasActiveSubscription: json['hasActiveSubscription'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyLimit': dailyLimit,
      'dailyUsed': dailyUsed,
      'dailyRemaining': dailyRemaining,
      'dailyResetTime': dailyResetTime,
      'monthlyLimit': monthlyLimit,
      'monthlyUsed': monthlyUsed,
      'monthlyRemaining': monthlyRemaining,
      'subscriptionTier': subscriptionTier,
      'nextRenewalDate': nextRenewalDate,
      'hasActiveSubscription': hasActiveSubscription,
    };
  }

  /// Check if daily quota is exceeded
  bool get isDailyQuotaExceeded => dailyRemaining <= 0;

  /// Check if monthly quota is exceeded
  bool get isMonthlyQuotaExceeded => monthlyRemaining <= 0;

  /// Check if any quota is exceeded
  bool get isQuotaExceeded => isDailyQuotaExceeded || isMonthlyQuotaExceeded;

  /// Get quota type that is exceeded
  String? get exceededQuotaType {
    if (isDailyQuotaExceeded) return 'daily';
    if (isMonthlyQuotaExceeded) return 'monthly';
    return null;
  }

  /// Get user-friendly status message
  String getStatusMessage() {
    if (!hasActiveSubscription) {
      return 'Analiz yapmak için abonelik gerekli 🔒\nMevcut paket: Ücretsiz (0 analiz)\nSponsor kodunuz varsa girebilirsiniz';
    }

    if (isDailyQuotaExceeded) {
      return 'Günlük analiz hakkınız dolmuştur 📅\nBugün: $dailyUsed/$dailyLimit analiz kullanıldı\nYarın saat 00:00\'da yenilenecek\nPaketiniz: $subscriptionTier ($monthlyUsed/$monthlyLimit aylık)';
    }

    if (isMonthlyQuotaExceeded) {
      return 'Aylık analiz hakkınız dolmuştur 📊\nBu ay: $monthlyUsed/$monthlyLimit analiz kullanıldı\nPaketiniz: $subscriptionTier\n$nextRenewalDate tarihinde yenilenecek';
    }

    return 'Günlük: $dailyRemaining/$dailyLimit kaldı\nAylık: $monthlyRemaining/$monthlyLimit kaldı';
  }

  /// Get available action buttons based on status
  List<String> getAvailableActions() {
    List<String> actions = [];

    if (!hasActiveSubscription) {
      actions.addAll(['subscribe', 'sponsor_code']);
    } else if (isDailyQuotaExceeded) {
      actions.addAll(['wait_tomorrow', 'upgrade', 'sponsor_code']);
    } else if (isMonthlyQuotaExceeded) {
      actions.addAll(['upgrade', 'sponsor_code']);
    }

    return actions;
  }
}

/// Subscription tier information
class SubscriptionTier {
  final int id;
  final String name;
  final String displayName;
  final String description;
  final int dailyRequestLimit;
  final int monthlyRequestLimit;
  final double monthlyPrice;
  final String currency;
  final bool isActive;
  final List<String> features;

  SubscriptionTier({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.dailyRequestLimit,
    required this.monthlyRequestLimit,
    required this.monthlyPrice,
    required this.currency,
    required this.isActive,
    required this.features,
  });

  factory SubscriptionTier.fromJson(Map<String, dynamic> json) {
    return SubscriptionTier(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      description: json['description'] ?? '',
      dailyRequestLimit: json['dailyRequestLimit'] ?? 0,
      monthlyRequestLimit: json['monthlyRequestLimit'] ?? 0,
      monthlyPrice: (json['monthlyPrice'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'TRY',
      isActive: json['isActive'] ?? true,
      features: List<String>.from(json['features'] ?? []),
    );
  }
}

/// User's current subscription info
class UserSubscription {
  final int id;
  final int subscriptionTierId;
  final String tierName;
  final String status;
  final String startDate;
  final String endDate;
  final bool autoRenew;
  final bool isActive;

  UserSubscription({
    required this.id,
    required this.subscriptionTierId,
    required this.tierName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    required this.isActive,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] ?? 0,
      subscriptionTierId: json['subscriptionTierId'] ?? 0,
      tierName: json['tierName'] ?? 'Free',
      status: json['status'] ?? 'inactive',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      autoRenew: json['autoRenew'] ?? false,
      isActive: json['isActive'] ?? false,
    );
  }
}