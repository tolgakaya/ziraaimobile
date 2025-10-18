import 'package:json_annotation/json_annotation.dart';

part 'message_quota_model.g.dart';

@JsonSerializable()
class MessageQuotaModel {
  final int todayCount;
  final int remainingMessages;
  final int dailyLimit;
  final DateTime resetTime;

  MessageQuotaModel({
    required this.todayCount,
    required this.remainingMessages,
    required this.dailyLimit,
    required this.resetTime,
  });

  factory MessageQuotaModel.fromJson(Map<String, dynamic> json) =>
      _$MessageQuotaModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageQuotaModelToJson(this);

  // Helper methods
  bool get canSendMessage => remainingMessages > 0;

  double get usagePercentage => todayCount / dailyLimit;

  String get quotaDisplay => '$remainingMessages/$dailyLimit mesaj kaldı';

  // Color coding for UI
  QuotaStatus get status {
    if (remainingMessages == 0) return QuotaStatus.depleted;
    if (remainingMessages <= 2) return QuotaStatus.critical;
    if (remainingMessages <= 6) return QuotaStatus.warning;
    return QuotaStatus.normal;
  }
}

enum QuotaStatus {
  normal,   // 7-10 remaining (green)
  warning,  // 3-6 remaining (orange)
  critical, // 1-2 remaining (red)
  depleted  // 0 remaining (red + disabled)
}
