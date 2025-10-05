import 'package:json_annotation/json_annotation.dart';

part 'referral_stats.g.dart';

/// Response model for referral statistics
/// API: GET /api/v1/Referral/stats
@JsonSerializable()
class ReferralStatsResponse {
  @JsonKey(name: 'data')
  final ReferralStats data;

  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'message')
  final String? message;

  ReferralStatsResponse({
    required this.data,
    required this.success,
    this.message,
  });

  factory ReferralStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$ReferralStatsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralStatsResponseToJson(this);
}

@JsonSerializable()
class ReferralStats {
  @JsonKey(name: 'totalReferrals')
  final int totalReferrals;

  @JsonKey(name: 'successfulReferrals')
  final int successfulReferrals;

  @JsonKey(name: 'pendingReferrals')
  final int pendingReferrals;

  @JsonKey(name: 'totalCreditsEarned')
  final int totalCreditsEarned;

  @JsonKey(name: 'referralBreakdown')
  final ReferralBreakdown referralBreakdown;

  ReferralStats({
    required this.totalReferrals,
    required this.successfulReferrals,
    required this.pendingReferrals,
    required this.totalCreditsEarned,
    required this.referralBreakdown,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) =>
      _$ReferralStatsFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralStatsToJson(this);

  /// Calculate conversion rate from clicked to registered
  double get clickToRegisterRate {
    if (referralBreakdown.clicked == 0) return 0.0;
    return (referralBreakdown.registered / referralBreakdown.clicked) * 100;
  }

  /// Calculate conversion rate from registered to rewarded
  double get registerToRewardRate {
    if (referralBreakdown.registered == 0) return 0.0;
    return (referralBreakdown.rewarded / referralBreakdown.registered) * 100;
  }
}

@JsonSerializable()
class ReferralBreakdown {
  @JsonKey(name: 'clicked')
  final int clicked;

  @JsonKey(name: 'registered')
  final int registered;

  @JsonKey(name: 'validated')
  final int validated;

  @JsonKey(name: 'rewarded')
  final int rewarded;

  ReferralBreakdown({
    required this.clicked,
    required this.registered,
    required this.validated,
    required this.rewarded,
  });

  factory ReferralBreakdown.fromJson(Map<String, dynamic> json) =>
      _$ReferralBreakdownFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralBreakdownToJson(this);
}
