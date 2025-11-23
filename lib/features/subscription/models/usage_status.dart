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
  final String subscriptionStatus; // API status message
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
    required this.subscriptionStatus,
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
      // Backend sends 'tierName' not 'subscriptionTier'
      subscriptionTier: json['subscriptionTier'] ?? json['tierName'] ?? 'Ücretsiz',
      subscriptionStatus: json['subscriptionStatus'] ?? 'Abonelik yok',
      // Backend sends 'subscriptionEndDate' not 'nextRenewalDate'
      nextRenewalDate: json['nextRenewalDate'] ?? json['subscriptionEndDate'] ?? '',
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
      'subscriptionStatus': subscriptionStatus,
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
    } else if (hasActiveSubscription && subscriptionTier.toLowerCase() == 'trial') {
      // Trial users can upgrade even when they have available quota
      actions.addAll(['upgrade', 'sponsor_code']);
    } else {
      // Paid subscription users with available quota - only show sponsor code option
      actions.add('sponsor_code');
    }

    return actions;
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