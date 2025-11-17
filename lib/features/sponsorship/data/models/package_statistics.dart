/// Data model for package statistics endpoint response
class PackageStatistics {
  final int totalCodesPurchased;
  final int totalCodesDistributed;
  final int totalCodesRedeemed;
  final int codesNotDistributed;
  final int codesDistributedNotRedeemed;
  final double distributionRate;
  final double redemptionRate;
  final double overallSuccessRate;
  final List<PackageBreakdown> packageBreakdowns;
  final List<TierBreakdown> tierBreakdowns;
  final List<ChannelBreakdown> channelBreakdowns;

  PackageStatistics({
    required this.totalCodesPurchased,
    required this.totalCodesDistributed,
    required this.totalCodesRedeemed,
    required this.codesNotDistributed,
    required this.codesDistributedNotRedeemed,
    required this.distributionRate,
    required this.redemptionRate,
    required this.overallSuccessRate,
    required this.packageBreakdowns,
    required this.tierBreakdowns,
    required this.channelBreakdowns,
  });

  factory PackageStatistics.fromJson(Map<String, dynamic> json) {
    return PackageStatistics(
      totalCodesPurchased: json['totalCodesPurchased'] as int,
      totalCodesDistributed: json['totalCodesDistributed'] as int,
      totalCodesRedeemed: json['totalCodesRedeemed'] as int,
      codesNotDistributed: json['codesNotDistributed'] as int,
      codesDistributedNotRedeemed: json['codesDistributedNotRedeemed'] as int,
      distributionRate: (json['distributionRate'] as num).toDouble(),
      redemptionRate: (json['redemptionRate'] as num).toDouble(),
      overallSuccessRate: (json['overallSuccessRate'] as num).toDouble(),
      packageBreakdowns: (json['packageBreakdowns'] as List)
          .map((item) => PackageBreakdown.fromJson(item))
          .toList(),
      tierBreakdowns: (json['tierBreakdowns'] as List)
          .map((item) => TierBreakdown.fromJson(item))
          .toList(),
      channelBreakdowns: (json['channelBreakdowns'] as List)
          .map((item) => ChannelBreakdown.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCodesPurchased': totalCodesPurchased,
      'totalCodesDistributed': totalCodesDistributed,
      'totalCodesRedeemed': totalCodesRedeemed,
      'codesNotDistributed': codesNotDistributed,
      'codesDistributedNotRedeemed': codesDistributedNotRedeemed,
      'distributionRate': distributionRate,
      'redemptionRate': redemptionRate,
      'overallSuccessRate': overallSuccessRate,
      'packageBreakdowns': packageBreakdowns.map((e) => e.toJson()).toList(),
      'tierBreakdowns': tierBreakdowns.map((e) => e.toJson()).toList(),
      'channelBreakdowns': channelBreakdowns.map((e) => e.toJson()).toList(),
    };
  }
}

/// Individual package purchase breakdown
class PackageBreakdown {
  final int purchaseId;
  final DateTime purchaseDate;
  final String tierName;
  final int codesPurchased;
  final int codesDistributed;
  final int codesRedeemed;
  final int codesNotDistributed;
  final int codesDistributedNotRedeemed;
  final double distributionRate;
  final double redemptionRate;
  final double totalAmount;
  final String currency;

  PackageBreakdown({
    required this.purchaseId,
    required this.purchaseDate,
    required this.tierName,
    required this.codesPurchased,
    required this.codesDistributed,
    required this.codesRedeemed,
    required this.codesNotDistributed,
    required this.codesDistributedNotRedeemed,
    required this.distributionRate,
    required this.redemptionRate,
    required this.totalAmount,
    required this.currency,
  });

  factory PackageBreakdown.fromJson(Map<String, dynamic> json) {
    return PackageBreakdown(
      purchaseId: json['purchaseId'] as int,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      tierName: json['tierName'] as String,
      codesPurchased: json['codesPurchased'] as int,
      codesDistributed: json['codesDistributed'] as int,
      codesRedeemed: json['codesRedeemed'] as int,
      codesNotDistributed: json['codesNotDistributed'] as int,
      codesDistributedNotRedeemed: json['codesDistributedNotRedeemed'] as int,
      distributionRate: (json['distributionRate'] as num).toDouble(),
      redemptionRate: (json['redemptionRate'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      currency: json['currency'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchaseId': purchaseId,
      'purchaseDate': purchaseDate.toIso8601String(),
      'tierName': tierName,
      'codesPurchased': codesPurchased,
      'codesDistributed': codesDistributed,
      'codesRedeemed': codesRedeemed,
      'codesNotDistributed': codesNotDistributed,
      'codesDistributedNotRedeemed': codesDistributedNotRedeemed,
      'distributionRate': distributionRate,
      'redemptionRate': redemptionRate,
      'totalAmount': totalAmount,
      'currency': currency,
    };
  }

  /// Get formatted purchase date
  String get formattedPurchaseDate {
    final months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return '${purchaseDate.day} ${months[purchaseDate.month - 1]} ${purchaseDate.year}';
  }

  /// Get formatted total amount
  String get formattedTotalAmount {
    return '${totalAmount.toStringAsFixed(2)} $currency';
  }
}

/// Statistics breakdown by tier
class TierBreakdown {
  final String tierName;
  final String tierDisplayName;
  final int codesPurchased;
  final int codesDistributed;
  final int codesRedeemed;
  final double distributionRate;
  final double redemptionRate;

  TierBreakdown({
    required this.tierName,
    required this.tierDisplayName,
    required this.codesPurchased,
    required this.codesDistributed,
    required this.codesRedeemed,
    required this.distributionRate,
    required this.redemptionRate,
  });

  factory TierBreakdown.fromJson(Map<String, dynamic> json) {
    return TierBreakdown(
      tierName: json['tierName'] as String,
      tierDisplayName: json['tierDisplayName'] as String,
      codesPurchased: json['codesPurchased'] as int,
      codesDistributed: json['codesDistributed'] as int,
      codesRedeemed: json['codesRedeemed'] as int,
      distributionRate: (json['distributionRate'] as num).toDouble(),
      redemptionRate: (json['redemptionRate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tierName': tierName,
      'tierDisplayName': tierDisplayName,
      'codesPurchased': codesPurchased,
      'codesDistributed': codesDistributed,
      'codesRedeemed': codesRedeemed,
      'distributionRate': distributionRate,
      'redemptionRate': redemptionRate,
    };
  }
}

/// Statistics breakdown by distribution channel
class ChannelBreakdown {
  final String channel;
  final int codesDistributed;
  final int codesDelivered;
  final int codesRedeemed;
  final double deliveryRate;
  final double redemptionRate;

  ChannelBreakdown({
    required this.channel,
    required this.codesDistributed,
    required this.codesDelivered,
    required this.codesRedeemed,
    required this.deliveryRate,
    required this.redemptionRate,
  });

  factory ChannelBreakdown.fromJson(Map<String, dynamic> json) {
    return ChannelBreakdown(
      channel: json['channel'] as String,
      codesDistributed: json['codesDistributed'] as int,
      codesDelivered: json['codesDelivered'] as int,
      codesRedeemed: json['codesRedeemed'] as int,
      deliveryRate: (json['deliveryRate'] as num).toDouble(),
      redemptionRate: (json['redemptionRate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel': channel,
      'codesDistributed': codesDistributed,
      'codesDelivered': codesDelivered,
      'codesRedeemed': codesRedeemed,
      'deliveryRate': deliveryRate,
      'redemptionRate': redemptionRate,
    };
  }
}
