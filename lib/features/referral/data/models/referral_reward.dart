import 'package:json_annotation/json_annotation.dart';

part 'referral_reward.g.dart';

/// Response model for referral rewards list
/// API: GET /api/v1/Referral/rewards
@JsonSerializable()
class ReferralRewardsResponse {
  @JsonKey(name: 'data')
  final List<ReferralReward> data;

  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'message')
  final String? message;

  ReferralRewardsResponse({
    required this.data,
    required this.success,
    this.message,
  });

  factory ReferralRewardsResponse.fromJson(Map<String, dynamic> json) =>
      _$ReferralRewardsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralRewardsResponseToJson(this);
}

@JsonSerializable()
class ReferralReward {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'refereeUserName')
  final String refereeUserName; // NOTE: Not refereeEmail!

  @JsonKey(name: 'creditAmount')
  final int creditAmount;

  @JsonKey(name: 'awardedAt')
  final String awardedAt; // ISO 8601 datetime

  ReferralReward({
    required this.id,
    required this.refereeUserName,
    required this.creditAmount,
    required this.awardedAt,
  });

  factory ReferralReward.fromJson(Map<String, dynamic> json) =>
      _$ReferralRewardFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralRewardToJson(this);

  /// Parse awardedAt string to DateTime
  DateTime get awardedDateTime => DateTime.parse(awardedAt);

  /// Check if reward was awarded today
  bool get isToday {
    final now = DateTime.now();
    final awarded = awardedDateTime;
    return now.year == awarded.year &&
        now.month == awarded.month &&
        now.day == awarded.day;
  }

  /// Get formatted date string
  String get formattedDate {
    final date = awardedDateTime;
    return '${date.day}/${date.month}/${date.year}';
  }
}
