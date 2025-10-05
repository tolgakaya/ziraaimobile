import 'package:json_annotation/json_annotation.dart';

part 'credit_breakdown.g.dart';

/// Response model for credit breakdown
/// API: GET /api/v1/Referral/credits
@JsonSerializable()
class CreditBreakdownResponse {
  @JsonKey(name: 'data')
  final CreditBreakdown data;

  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'message')
  final String? message;

  CreditBreakdownResponse({
    required this.data,
    required this.success,
    this.message,
  });

  factory CreditBreakdownResponse.fromJson(Map<String, dynamic> json) =>
      _$CreditBreakdownResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreditBreakdownResponseToJson(this);
}

@JsonSerializable()
class CreditBreakdown {
  @JsonKey(name: 'totalEarned')
  final int totalEarned;

  @JsonKey(name: 'totalUsed')
  final int totalUsed;

  @JsonKey(name: 'currentBalance')
  final int currentBalance;

  CreditBreakdown({
    required this.totalEarned,
    required this.totalUsed,
    required this.currentBalance,
  });

  factory CreditBreakdown.fromJson(Map<String, dynamic> json) =>
      _$CreditBreakdownFromJson(json);

  Map<String, dynamic> toJson() => _$CreditBreakdownToJson(this);

  /// Calculate usage percentage
  double get usagePercentage {
    if (totalEarned == 0) return 0.0;
    return (totalUsed / totalEarned) * 100;
  }

  /// Check if user has credits available
  bool get hasCredits => currentBalance > 0;

  /// Check if user has used any credits
  bool get hasUsedCredits => totalUsed > 0;
}
