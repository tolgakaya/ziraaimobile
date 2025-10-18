import 'package:equatable/equatable.dart';
import '../../data/models/message_quota_model.dart';

class MessageQuota extends Equatable {
  final int todayCount;
  final int remainingMessages;
  final int dailyLimit;
  final DateTime resetTime;

  const MessageQuota({
    required this.todayCount,
    required this.remainingMessages,
    required this.dailyLimit,
    required this.resetTime,
  });

  factory MessageQuota.fromModel(MessageQuotaModel model) {
    return MessageQuota(
      todayCount: model.todayCount,
      remainingMessages: model.remainingMessages,
      dailyLimit: model.dailyLimit,
      resetTime: model.resetTime,
    );
  }

  bool get canSendMessage => remainingMessages > 0;

  double get usagePercentage => todayCount / dailyLimit;

  String get quotaDisplay => '$remainingMessages/$dailyLimit mesaj kaldı';

  QuotaStatus get status {
    if (remainingMessages == 0) return QuotaStatus.depleted;
    if (remainingMessages <= 2) return QuotaStatus.critical;
    if (remainingMessages <= 6) return QuotaStatus.warning;
    return QuotaStatus.normal;
  }

  @override
  List<Object?> get props => [
        todayCount,
        remainingMessages,
        dailyLimit,
        resetTime,
      ];
}

enum QuotaStatus {
  normal,   // 7-10 remaining (green)
  warning,  // 3-6 remaining (orange)
  critical, // 1-2 remaining (red)
  depleted  // 0 remaining (red + disabled)
}
